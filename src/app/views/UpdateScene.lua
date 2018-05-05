local gt = cc.exports.gt

local projectmanifest_filename = "project.manifest"
local ver_filename  = "version.manifest"
local writePath = cc.FileUtils:getInstance():getWritablePath()
local downList      = {}

local InitText = {}
InitText[1] = "加载中,请稍候……"
InitText[2] = "加载中,请稍候……"
InitText[3] = "正在启动游戏，请稍候……"
InitText[4] = "触摸屏幕开始"
InitText[5] = "读取manifest[%s]文件错误"
InitText[6] = "已是最新版无需更新"
InitText[7] = "创建目录失败"
InitText[8] = "下载文件错误"
InitText[9] = "正在更新文件"
InitText[10] = "更新配置文件格式错误"
InitText[11] = "更新完成"
InitText[12] = "正在检查文件"
InitText[13] = "正在写入文件"


local function hex(s)
    s=string.gsub(s,"(.)",function (x) return string.format("%02X",string.byte(x)) end)
    -- print("====数值",s)
    return s, string.len(s)
end

-- 读取文件
local function readFile( path )
    local file = io.open( path, "rb" )
    if file then
        local content = file:read( "*all" )
        io.close(file)
        return content
    end

    return nil
end

local function checkDirOK( path )
    local cpath = cc.FileUtils:getInstance():isFileExist(path)
    if cpath then
        return true
    end

    return cc.FileUtils:getInstance():createDirectory( path )
end

-- 比较获取需要下载的文件名字
local function compManifest( oList, newList )
    local oldList = {}
    for k,v in pairs(oList) do
        oldList[k] = v["md5"]
    end

    local list = {}
    for k,v in pairs(newList) do
        local name = k
        if v["md5"] ~= oldList[k] then
            local saveTab = {}
            saveTab.name    = name
            saveTab.md5code = v["md5"]
            table.insert( list, saveTab )
        end
    end

    return list
end

local function checkFile( fileName, cryptoCode )
    if not io.exists(fileName) then -- 测试fileName文件是否存在
        return false -- 如果文件不存在,那么返回false
    end

    local data = readFile(fileName)
    if data == nil then
        return false
    end

    if cryptoCode == nil then
        return true
    end
    local needMd5Str, needLen = hex(data)
    local ms = cc.UtilityExtension:generateMD5( needMd5Str, needLen )
    if ms==cryptoCode then
        return true
    end

    -- print("md5差异Error:", fileName, cryptoCode, ms)
    return false
end

local function checkCacheDirOK( root_dir, path )
    path = string.gsub( string.trim(path), "\\", "/" )
    local info = io.pathinfo(path)
    if not checkDirOK(root_dir..info.dirname) then
        return false
    end

    return true
end

local function removeFile( path )
    --print("removeFile---------------> " .. path)
    io.writefile(path, "")
    if device.platform == "windows" then
        os.remove(string.gsub(path, '/', '\\'))
    else
        cc.FileUtils:getInstance():removeFile( path )
    end
end

local function renameFile(path, newPath)
    removeFile(newPath)
    os.rename(path, newPath)
    -- print("renameFile---------------> " .. path .. "  ==> " .. newPath)
end


-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------
-- UpdateScene类
-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------
local UpdateScene = class("UpdateScene", function()
    return cc.Scene:create()
end)

function UpdateScene:ctor()
    -- checkFile("/Users/developer/Develop/work/client/release/mahjong_changsha_testfornewmd5/103/res/ReadyPlay.luac.upd")

    self:registerScriptHandler(handler(self, self.onNodeEvent))

    local csbNode = cc.CSLoader:createNode("Update.csb")
    csbNode:setPosition(gt.winCenter)
    if display.autoscale == "FIXED_HEIGHT" then
        csbNode:setScale(0.75)
        gt.seekNodeByName(csbNode, "bg"):setScaleY(1280/960)   
    end
    self.csbNode = csbNode
    self:addChild(csbNode)

    -- 是否更新成功,更新失败会有tip提示
    self.updateSuccess = false
    -- 接收到的数据
    self.dataRecv   = nil
    -- 下载url
    self.updateURL  = nil

    -- 显示更新状态
    local progressLabel = gt.seekNodeByName(csbNode, "Label_progress")
    progressLabel:setString(gt.getLocationString("LTKey_0033"))
    self.progressLabel = progressLabel
    local fadeOut = cc.FadeOut:create(1)
    local fadeIn = cc.FadeIn:create(1)
    local seqAction = cc.Sequence:create(fadeOut, fadeIn)
    progressLabel:runAction(cc.RepeatForever:create(seqAction))

    if gt.isIOSPlatform() and gt.isInReview then
        progressLabel:setVisible(true)
    end

    -- 更新进度条
    self.updateSlider = gt.seekNodeByName(csbNode, "Slider_update")
    if self.updateSlider then
        self.updateSlider:setVisible( true )
        self.updateSlider:setPercent(0)
        -- if gt.isIOSPlatform() and gt.isInReview then -- 苹果审核状态,不显示更新进度条
        --     self.updateSlider:setVisible( false )
        --     self.updateSlider:setPercent(0)
        -- else
        --     self.updateSlider:setVisible( true )
        --     self.updateSlider:setPercent(0)
        -- end
    end
end

function UpdateScene:onNodeEvent(eventName)
    if "enter" == eventName then
        -- 逻辑更新定时器
        self.scheduleHandler = gt.scheduler:scheduleScriptFunc(handler(self, self.updateFunc), 0, false)

        -- 临时存储project.manifest的文件名字
        self.projectManifestFileUPD  = writePath .. projectmanifest_filename .. "upd"

        self.fileList = nil
        --从初始目录读文件列表
        local cpath = cc.FileUtils:getInstance():isFileExist(projectmanifest_filename)
        if cpath then
            -- print("本地目录找到了project.manifest文件了")
            if self.fileList == nil then -- 如果没有读取到目录文件的内容
                local fileData = cc.FileUtils:getInstance():getStringFromFile(projectmanifest_filename)
                require("json")
                self.fileList = json.decode(fileData)
            end
        end

        -- 未找到project.manifest文件,则重新下载一遍所有的资源
        if not self.fileList then
            self.fileList.version               = "1.0.0"
            self.fileList.remoteVersionUrl      = "http://www.ixianlai.com/client/version.manifest"
            self.fileList.remoteManifestUrl     = "http://www.ixianlai.com/client/project.manifest"
            self.fileList.assets                = {}
        end

        -- 记录一下版本号
        gt.resVersion = self.fileList.version

        -- 请求版本号
        self:requestVer()
    end
end

function UpdateScene:updateFunc(delta)
    if self.dataRecv then -- 如果已经收到了数据
        if self.requesting == ver_filename then -- 如果是请求版本号的服务器返回消息
            require("json")
            self.dataRecv = json.decode(self.dataRecv)
            if self.dataRecv.version ~= self.fileList.version then -- 如果服务器 客户端 版本不同, 那么请求project.manifest
                gt.log("需要请求版本")
                self.fileList.remoteManifestUrl = self.dataRecv.remoteManifestUrl
                self.dataRecv = nil
                self:requestProjectManifest()
                -- gt.isUpdate = true
            else
                gt.log("==无需更新版本")
                self.dataRecv = nil
                self.updateSuccess = true
                self:endProcess( InitText[6] ) -- 如果版本相同 InitText[6] = "已是最新版无需更新"
            end
            return
        end
        if self.requesting == projectmanifest_filename then
            local ret = io.writefile( writePath..self.newListFile, self.dataRecv ) -- 将收到的需要更新的文件存放到self.newListFile文件中
            self.dataRecv = nil

            local newList = cc.FileUtils:getInstance():getStringFromFile(writePath..self.newListFile)
            if newList == nil then
                self:endProcess( string.format(InitText[5], writePath..self.newListFile))
                return
            end

            require("json")
            newList = json.decode(newList)
            self.lastProMani = newList -- 记录一下从服务器下载的project.manifest内容
            -- 记录从服务器下载的url地址(更新地址)
            self.updateURL = newList.packageUrl
            if newList.version == self.fileList.version then
                self:endProcess( InitText[6] ) -- 如果版本相同 InitText[6] = "已是最新版无需更新"
                return
            end
            -- 通过比较获得需要更新的文件
            self.needUpdateList = compManifest( self.fileList.newassets, newList.newassets )
            -- -- 打印一下需要更新的文件的名字
            -- for i,v in ipairs(self.needUpdateList) do
            --     print( v.name, v.md5code )
            -- end

            -- 向服务器请求文件了,消息类型变成了"files"
            self.numFileCheck   = 0
            self.requesting     = "files"
            self:reqNextFile()
            return
        end

        if self.requesting == "files" then
            local fn = writePath..self.curStageFile.name..".upd"
            --检查并创建多级目录(存储下载文件的目录)
            if not checkCacheDirOK( writePath, self.curStageFile.name ) then
                self:endProcess( InitText[7] ) -- InitText[7] = "创建目录失败"
                return
            end
            local ret = io.writefile(fn, self.dataRecv) -- 保存文件
            self.dataRecv = nil
            if checkFile( fn, self.curStageFile.md5code ) then -- 下载正确,那么继续下载下一个文件
                table.insert(downList, fn) -- 下载正确的话,就存到downList表中.
                self:reqNextFile()
            else
                --错误
                self:endProcess( InitText[8] ) -- InitText[8] = "下载文件错误"
            end
            return
        end
    end
end

-- 请求版本号
function UpdateScene:requestVer()
    self.requesting     = ver_filename
    self.dataRecv       = nil
    self:requestFromServer( self.fileList.remoteVersionUrl )
end
-- 如果请求的版本和本地的版本不同的话,需要请求目录
function UpdateScene:requestProjectManifest()
    self.requesting     = projectmanifest_filename
    self.newListFile    = projectmanifest_filename..".upd"
    self.dataRecv       = nil
    self:requestFromServer( self.fileList.remoteManifestUrl )
end

function UpdateScene:getFileFromServer( needurl, cbFunc )
    if self.xhr then
        self.xhr.responseType = cc.XMLHTTPREQUEST_RESPONSE_JSON
        local refreshTokenURL = needurl
        self.xhr:open("GET", refreshTokenURL)
        self.xhr:registerScriptHandler( handler(self,self.onResp) )
        self.xhr:send()
        return
    end
    self.xhr = cc.XMLHttpRequest:new()
    self.xhr:retain()
    self.xhr.timeout = 30 -- 设置超时时间
    self.xhr.responseType = cc.XMLHTTPREQUEST_RESPONSE_JSON
    local refreshTokenURL = needurl
    self.xhr:open("GET", refreshTokenURL)
    self.xhr:registerScriptHandler( handler(self,self.onResp) )
    self.xhr:send()
end

function UpdateScene:onResp()
    if self.xhr.readyState == 4 and (self.xhr.status >= 200 and self.xhr.status < 207) then
        self.dataRecv = self.xhr.response -- 获取到数据
    elseif self.xhr.readyState == 1 and self.xhr.status == 0 then
        -- 网络问题,异常断开
        self:endProcess( InitText[8] )
    end
    self.xhr:unregisterScriptHandler()
end

-- 向服务器发送请求消息
function UpdateScene:requestFromServer( needurl, waittime )
    self:getFileFromServer( needurl )
end

function UpdateScene:reqNextFile()
    self.numFileCheck = self.numFileCheck + 1
    self.curStageFile = self.needUpdateList[self.numFileCheck]

    if self.curStageFile then
        local filename = io.pathinfo(self.curStageFile.name).filename
        local fn = writePath..self.curStageFile.name

        -- 进度条
        if self.updateSlider then
            local percent = (self.numFileCheck-1)/(#self.needUpdateList) * 100
            self.progressLabel:setString( "正在更新游戏资源".." "..math.floor(percent).."%")
            self.updateSlider:setPercent( percent )
        end

        -- 如果文件已经存在了(例如MainScene.luac文件),检查此文件是否是已经下载过的文件(比较md5值)
        if checkFile( fn, self.curStageFile.md5code ) then
            self:reqNextFile()
            return
        end

        -- 查看是否有已经存在的.udp文件(如果存在并且md5值相同,说明是上次已经更新过的,但是由于某些原因并未完全更新成功)
        fn = fn..".upd"
        if checkFile( fn, self.curStageFile.md5code ) then -- 如果文件存在
            -- table.insert(downList, fn)
            -- self:reqNextFile()
            -- return
            removeFile( writePath..fn )
        end

        -- 向服务器发送消息请求self.curStageFile.name文件
        self:requestFromServer( self.updateURL .. "/" .. self.curStageFile.name )
        return
    end

    --下载完成
    self.updateSuccess = true
    self:updateFiles()
end

-- 下载完毕之后,需要修改后缀名等操作
function UpdateScene:updateFiles()
    local data = readFile( writePath..projectmanifest_filename..".upd" ) -- 从服务器得到的更新目录文件project.manifest.upd  upd  是临时文件。
    local ret  = io.writefile( writePath..projectmanifest_filename, data ) -- project.manifest文件中去

    -- 删除project.manifest.upd文件
    removeFile( writePath..projectmanifest_filename..".upd" )

    -- 修改资源中.upd名字
    for i,v in ipairs(downList) do
        --去掉.upd
        local fn = string.sub(v, 1, -5)
        -- 重新命名
        renameFile(v, fn)
    end

    gt.resVersion = self.lastProMani.version
    self:endProcess( InitText[11] )
end

function UpdateScene:endProcess( endInfo )
    if endInfo then
        print("更新结束,原因: "..endInfo)
    end

    if self.updateSuccess == false then
        require("app/views/NoticeTipsForUpdate"):create("更新失败", "更新失败,请检查您的网络连接", handler(self,self.endError), nil, true)
        return
    end

   self:endCB()
end

function UpdateScene:endCB()
    if self.scheduleHandler then
        gt.scheduler:unscheduleScriptEntry(self.scheduleHandler)
    end

    gt.log("resVersion:" .. gt.resVersion)

    local loginScene = require("app/views/LoginScene"):create()
    cc.Director:getInstance():replaceScene(loginScene)
end

function UpdateScene:endError()
    gt.log("更新失败  提示后回调的函数........")
    if self.scheduleHandler then
        gt.scheduler:unscheduleScriptEntry(self.scheduleHandler)
    end

    -- 重新初始化一下  
    -- 是否更新成功,更新失败会有tip提示
    self.updateSuccess = false
    -- 接收到的数据
    self.dataRecv   = nil
    -- 下载url
    self.updateURL  = nil

    -- 显示更新状态
    local progressLabel = gt.seekNodeByName(self.csbNode, "Label_progress")
    progressLabel:setString(gt.getLocationString("LTKey_0033"))
    self.progressLabel = progressLabel
    local fadeOut = cc.FadeOut:create(1)
    local fadeIn = cc.FadeIn:create(1)
    local seqAction = cc.Sequence:create(fadeOut, fadeIn)
    progressLabel:runAction(cc.RepeatForever:create(seqAction))

    if gt.isIOSPlatform() and gt.isInReview then
        progressLabel:setVisible(true)
    end

    -- 更新进度条
    self.updateSlider = gt.seekNodeByName(self.csbNode, "Slider_update")
    if self.updateSlider then
        self.updateSlider:setVisible( true )
        self.updateSlider:setPercent(0)
        -- if gt.isIOSPlatform() and gt.isInReview then -- 苹果审核状态,不显示更新进度条
        --     self.updateSlider:setVisible( false )
        --     self.updateSlider:setPercent(0)
        -- else
        --     self.updateSlider:setVisible( true )
        --     self.updateSlider:setPercent(0)
        -- end
    end

    self:onNodeEvent("enter")

end

return UpdateScene