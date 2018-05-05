local gt = cc.exports.gt

local QRcode = class("QRcode", function()
    return gt.createMaskLayer()
end)


function QRcode:ctor(id)
    self.rootNode = cc.CSLoader:createNode("ShareLayer.csb")
    self.rootNode:setAnchorPoint(0.5, 0.5)
    self.rootNode:setPosition(gt.winCenter)
    self:addChild(self.rootNode)
    self.id = tonumber(id)
    local unionid  = cc.UserDefault:getInstance():getStringForKey( "WX_Uuid" )
    -- self.shareURL = string.format("http://shoptest.ixianlai.com/shopping_new/wxcenter/fxImage?userid=%d&app_id=%s",self.id,"gh_541b5c006d5b")
    -- -- gt.log("--------zhulei----->url == " .. self.shareURL )
    -- if gt.localapk then
  
    --     self.shareURL = string.format("http://114.55.84.16:9000/shopping_new/wxcenter/fxImage?userid=%d&app_id=%s",self.id,"gh_541b5c006d5b")
    -- else
      -- gt.log("_---------->" .. self.shareURL)
    self.shareURL = string.format("http://www.deleba365.com/wxcenter/fxImage?userid=%d&app_id=%s",self.id,"gh_3c294a41b716")
    -- end
    --只分享微信传回来的二维码
    -- self:getTOKEN(unionid)
    -- self.shareURL = cc.UserDefault:getInstance():getStringForKey("refreshTokenURL")

    if gt.isIOSPlatform() then
        self.luaBridge = require("cocos/cocos2d/luaoc")
    elseif gt.isAndroidPlatform() then
        self.luaBridge = require("cocos/cocos2d/luaj")
    end

    --给分享按钮绑定回调事件,分享到好友
    local QRcodeshare_btn = gt.seekNodeByName(self, "Btn_shard_hy")
    gt.addBtnPressedListener(QRcodeshare_btn, function()
        --调用微信接口
        self:shareToWXHaoYou()
    end)

    --分享到朋友圈
    local QRcodeshare_btn = gt.seekNodeByName(self, "Btn_shard_pyq")
    gt.addBtnPressedListener(QRcodeshare_btn, function()
        --调用微信接口
        self:shareToWXPengYouQuan()
    end)

    --返回按钮
    local QRcodebackBtn = gt.seekNodeByName(self, "Btn_back")
    gt.addBtnPressedListener(QRcodebackBtn, function()
        self:removeFromParent()
    end)

end


--分享到朋友圈回调
function QRcode:shareToWXPengYouQuan()
    local ok, appVersion = nil
    if gt.isIOSPlatform() then
        ok, appVersion = self.luaBridge.callStaticMethod("AppController", "getVersionName")
    elseif gt.isAndroidPlatform() then
        ok, appVersion = self.luaBridge.callStaticMethod("org/cocos2dx/lua/AppActivity", "getAppVersionName", nil, "()Ljava/lang/String;")
    end
    local versionNumber = string.split(appVersion, '.')
    if tonumber(versionNumber[3]) < 7 then
        --提示更新
        local appUpdateLayer = require("app/views/UpdateVersion"):create("当前版本不支持此功能,是否前往下载新版本?", 1)
        self:addChild(appUpdateLayer, 100)
    else
        -- local PyqUrl = cc.UserDefault:getInstance():getStringForKey("refreshTokenURL")
        local PyqUrl = self.shareURL
        local share_title = "玩游戏抢600元现金"
        local share_description = "玩游戏一起领现金"
        if gt.isIOSPlatform() then
            -- if self:checkVersion(1, 0, 6) then
            --     local ok = self.luaBridge.callStaticMethod("AppController", "shareURLToWXPYQ",
            --         {url = PyqUrl, title = share_title, description = share_description, scriptHandler = handler(self, self.pushShareCodePYQ)})
            -- else
            local ok = self.luaBridge.callStaticMethod("AppController", "shareURLToWXPYQ",
                {url = PyqUrl, title = share_title .. share_description, description = ""})
            -- end

        elseif gt.isAndroidPlatform() then
            -- local luaj = require("cocos/cocos2d/luaj")
            -- if self:checkVersion(1, 0, 6) then
            --     luaj.callStaticMethod("org/cocos2dx/lua/AppActivity", "registerGetAuthCodeHandler", {handler(self, self.pushShareCodePYQ)}, "(I)V")         
            -- else

            -- end
            local ok = self.luaBridge.callStaticMethod("org/cocos2dx/lua/AppActivity", "shareURLToWXPYQ",
                {PyqUrl, share_title .. share_description, ""},
                "(Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;)V")
        end
        -- self:removeFromParent()
    end
end

--分享到朋友圈，微信回调
function QRcode:pushShareCodePYQ(authCode)
    gt.log("====================PYQ", authCode, type(authCode))
    -- local loginScene = require("app/views/LogoScene"):create()
    -- cc.Director:getInstance():replaceScene(loginScene)
end


--分享回调
function QRcode:shareToWXHaoYou()
    --分享链接给好友
    local share_title = "玩游戏抢600元现金"
    local share_description = "玩游戏一起领现金"
    -- local share_url = cc.UserDefault:getInstance():getStringForKey("refreshTokenURL")
    local share_url = self.shareURL
    if type(share_url) ~= nil then
        if gt.isIOSPlatform() then
            local luaoc = require("cocos/cocos2d/luaoc")
            local ok = luaoc.callStaticMethod("AppController", "shareURLToWX",
                {url = share_url, title = share_title, description = share_description})
        elseif gt.isAndroidPlatform() then
            local luaj = require("cocos/cocos2d/luaj")
            local ok = luaj.callStaticMethod("org/cocos2dx/lua/AppActivity", "shareURLToWX",
                {share_url, share_title, share_description},
                "(Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;)V")
        end
    end
end



--从后台获取token
function QRcode:getTOKEN(uuid)
    --最终确定的appid
    local app_id = "gh_3c294a41b716"
    -- if gt.localapk then
    --     app_id = "gh_541b5c006d5b"
    -- end

    local userid = uuid
    local srcSign = string.format("%s%s", app_id, userid)
    local sign = cc.UtilityExtension:generateMD5(srcSign, string.len(srcSign))
    local xhr = cc.XMLHttpRequest:new()
    xhr.timeout = 5
    xhr.responseType = cc.XMLHTTPREQUEST_RESPONSE_JSON
    --最终确定的网址
    local refreshTokenURL = string.format("http://www.deleba365.com/wxcenter/getToken")
    
    xhr:open("POST", refreshTokenURL)
    local function onResp()
        if xhr.readyState == 4 and (xhr.status >= 200 and xhr.status < 207) then
            dump(xhr.response)
            -- -- local response = string.sub(xhr.response, 4)
            require("json")

            local respJson = json.decode(xhr.response)

            if tonumber(respJson.errorCode) == 0 then -- 服务器现在是 字符"0",应该修改为 数字0
                self:getTicket(respJson.token)
            else
            
            end
        elseif xhr.readyState == 1 and xhr.status == 0 then
            --请求失败
        end
        xhr:unregisterScriptHandler()
    end
    xhr:registerScriptHandler(onResp)
    xhr:send(string.format("app_id=%s&userid=%s&sign=%s", app_id, userid, sign))
end


--从微信获取ticket
function QRcode:getTicket(TOKEN)
    local xhr = cc.XMLHttpRequest:new()
    xhr.timeout = 5
    xhr.responseType = cc.XMLHTTPREQUEST_RESPONSE_JSON
    -- local refreshTokenURL = string.format("http://web.ixianlai.com/GetIP.php")
    local refreshTokenURL = string.format("https://api.weixin.qq.com/cgi-bin/qrcode/create?access_token=%s",TOKEN)
    xhr:open("POST", refreshTokenURL)
    local function onResp()
        if xhr.readyState == 4 and (xhr.status >= 200 and xhr.status < 207) then
            require("json")
            local x = string.gsub(xhr.response, '\\','')
            local respJson = json.decode(x)
            if type(respJson.ticket) ~= nil then
                self:getQEcode(respJson.ticket)
            else
                print("fuck you ticket is error because server is a pig!!!!")
            end
        elseif xhr.readyState == 1 and xhr.status == 0 then
            --请求失败
        end
        xhr:unregisterScriptHandler()
    end
    xhr:registerScriptHandler(onResp)
    local str = {expire_seconds = 2592000 ,action_name="QR_SCENE", action_info={scene={scene_id=self.id}}}
    local params = json.encode(str)
    xhr:send(params)
end

--保存微信返回的图片
function QRcode:getQEcode(ticket)
    local tickets = ticket

    local refreshTokenURL = string.format("https://mp.weixin.qq.com/cgi-bin/showqrcode?ticket=%s",tickets)
    cc.UserDefault:getInstance():setStringForKey("refreshTokenURL", refreshTokenURL)
    --优化版本  
    local xhr = cc.XMLHttpRequest:new()
    xhr.timeout = 5
    xhr.responseType = cc.XMLHTTPREQUEST_RESPONSE_JSON
    
    xhr:open("GET", refreshTokenURL)
    local function onResp()
        if xhr.readyState == 4 and (xhr.status >= 200 and xhr.status < 207) then
            io.writefile(gt.WXErWeiMaPath, xhr.response)
        end
        xhr:unregisterScriptHandler()
    end
    xhr:registerScriptHandler(onResp)
    xhr:send()
end



return QRcode