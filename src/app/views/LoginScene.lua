local gt = cc.exports.gt

require("app/DefineConfig")

local LoginScene = class("LoginScene", function()
	return cc.Scene:create()
end)

function LoginScene:ctor(isReset)
	-- 重新设置搜索路径

	local writePath = cc.FileUtils:getInstance():getWritablePath()
	local resSearchPaths = {
		writePath,
		writePath .. "src_et/",
		writePath .. "src/",
		writePath .. "res/sd/",
		writePath .. "res/",
		"src_et/",
		"src/",
		"res/sd/",
		"res/"
	}
	cc.FileUtils:getInstance():setSearchPaths(resSearchPaths)
	gt.soundManager = require("app/SoundManager")
	
	gt.isInReview = false
	--首次进入是否显示弹窗
	gt.firstanchuang = true
	-- 是否显示机器人和调牌狂
	gt.isShowRoot = false 
	if gt.localVersion or gt.localapk then
		gt.isShowRoot = true
	end
	--活动相关
	gt.isInit = 0
	gt.shareWeb = "www.xianlaihy.com/mahjongjx"
	self.needLoginWXState = 0 -- 本地微信登录状态
	-- 注册节点事件
	self:registerScriptHandler(handler(self, self.onNodeEvent))

	local csbNode = cc.CSLoader:createNode("Login.csb")
	csbNode:setPosition(gt.winCenter)
	self:addChild(csbNode)
	self.rootNode = csbNode

	--微信登录ip
	self.wxLoginIP = {"101.226.212.27","183.61.49.149","183.57.48.62","120.204.0.120","101.227.162.120","58.246.220.31","140.207.119.12"}
	
	self.isReset = isReset
	--更新检测
	-- self:updateAppVersion()

	--modify by xxx
	--微信二维码存储路径
	gt.WXErWeiMaPath = cc.FileUtils:getInstance():getWritablePath().. "share_wx_erweima" ..".png"

	-- 初始化Socket网络通信
	
	gt.socketClient = require("app/SocketClient"):create()

	if gt.isIOSPlatform() then
		self.luaBridge = require("cocos/cocos2d/luaoc")
	elseif gt.isAndroidPlatform() then
		self.luaBridge = require("cocos/cocos2d/luaj")
	end

	-- 微信登录
	local wxLoginBtn = gt.seekNodeByName(csbNode, "Btn_wxLogin")

	
	-- 游客输入用户名
	local userNameNode = gt.seekNodeByName(csbNode, "Node_userName")
	if gt.localVersion then
		if gt.isIOSPlatform() and gt.isInReview then
			userNameNode:setVisible(false)
		else
			userNameNode:setVisible(true)
		end
	else
		userNameNode:setVisible(false)
	end
	local textfield = gt.seekNodeByName(userNameNode, "TxtField_userName")

	-- -- 如果是正式包,那么取ip
	-- if gt.localVersion == false then
	-- 	local isRightIp = false
	-- 	if gt.isIOSPlatform() then
	-- 		for i=1,3 do
	-- 			local ok, ret = self.luaBridge.callStaticMethod("AppController", "getYunIP",{ipKey = "xianlai1.u0qr4x4wk3.aliyungf.com"})
	-- 			local ipTab = string.split(ret, ".")
	-- 			if #ipTab == 4 then -- 正确的ip地址
	-- 				isRightIp = true
	-- 				gt.LoginServer.ip = ret
	-- 				break
	-- 			end
	-- 		end
	-- 		-- 如果三次都有错误,那么不做任何处理,继续使用原先的域名去连接服务器
	-- 		-- ...
	-- 	elseif gt.isAndroidPlatform() then
	-- 		for i=1,3 do
	-- 			local ok, ret = self.luaBridge.callStaticMethod("org/cocos2dx/lua/AppActivity", "getIP", nil, "()Ljava/lang/String;")
	-- 			local ipTab = string.split(ret, ".")
	-- 			if #ipTab == 4 then -- 正确的ip地址
	-- 				isRightIp = true
	-- 				gt.LoginServer.ip = ret
	-- 				break
	-- 			end
	-- 		end
	-- 		-- 如果三次都有错误,那么不做任何处理,继续使用原先的域名去连接服务器
	-- 		-- ...
	-- 	end
	-- else
	-- 	-- 如果是本地版本,那么应该用测试服
	-- 	gt.LoginServer = gt.TestLoginServer
	-- end


	--gt.LoginServer = gt.TestLoginServer
	local openUDID = "99992"


	-- 游客登录
	local travelerLoginBtn = gt.seekNodeByName(csbNode, "Btn_travelerLogin")

	if gt.localVersion == true then
		travelerLoginBtn:setVisible(true)
		openUDID = textfield:getStringValue()
		gt.LoginServer = gt.TestLoginServer
	else
		travelerLoginBtn:setVisible(false)
	end
	
	gt.addBtnPressedListener(travelerLoginBtn, function()
		
		if not self:checkAgreement() then
			return
		end
	
		gt.showLoadingTips(gt.getLocationString("LTKey_0003"))

		-- local ok, ret = self.luaBridge.callStaticMethod("AppController", "getOpenUDID")
		local openUDID = "855899"

		-- local ok, ret = self.luaBridge.callStaticMethod("AppController", "getOpenUDID")

		-- 获取名字
		--[[
		local openUDID = textfield:getStringValue()
		if string.len(openUDID)==0 then -- 没有填写用户名
			openUDID = cc.UserDefault:getInstance():getStringForKey("openUDID_TIME")
			if string.len(openUDID) == 0 then
				openUDID = tostring(os.time())
				cc.UserDefault:getInstance():setStringForKey("openUDID_TIME", openUDID)
			end
		end
		--]]
	
		openUDID = textfield:getStringValue()

		if not openUDID or openUDID == "" then
			openUDID = "855899"
		end

		local nickname = cc.UserDefault:getInstance():getStringForKey("openUDID")
		if string.len(nickname) == 0 then
			nickname = "游客:" .. gt.getRangeRandom(1, 9999)

			cc.UserDefault:getInstance():setStringForKey("openUDID", nickname)
		end

		gt.socketClient:connect(gt.LoginServer.ip, gt.LoginServer.port, true)
		local msgToSend = {}
		msgToSend.m_msgId = gt.CG_LOGIN
		msgToSend.m_openId = openUDID
		msgToSend.m_nike = nickname
		msgToSend.m_sign = 123987
		msgToSend.m_plate = "local"
		msgToSend.m_severID = 12001
		

		msgToSend.m_uuid = msgToSend.m_openId
		msgToSend.m_sex = 1
		msgToSend.m_nikename = nickname

		msgToSend.m_imageUrl = ""
		
		gt.socketClient:sendMessage(msgToSend)

		-- 保存sex,nikename,headimgurl,uuid,serverid等内容
		cc.UserDefault:getInstance():setStringForKey( "WX_Sex", tostring(1) )
		cc.UserDefault:getInstance():setStringForKey( "WX_Uuid", msgToSend.m_uuid )
		gt.wxNickName = msgToSend.m_nikename
		cc.UserDefault:getInstance():setStringForKey( "WX_ImageUrl", msgToSend.m_imageUrl )

	end)




	-- 判断是否安装微信客户端
	local isWXAppInstalled = false
	if gt.isIOSPlatform() then
		local ok, ret = self.luaBridge.callStaticMethod("AppController", "isWXAppInstalled")
		isWXAppInstalled = ret
	elseif gt.isAndroidPlatform() then
		local ok, ret = self.luaBridge.callStaticMethod("org/cocos2dx/lua/AppActivity", "isWXAppInstalled", nil, "()Z")
		isWXAppInstalled = ret
	end


	
	if gt.isIOSPlatform() and gt.isInReview then
		-- 苹果设备在评审状态没有安装微信情况下显示游客登录
		gt.LoginServer = gt.TestLoginServer
		travelerLoginBtn:setVisible(true)
		wxLoginBtn:setVisible(false)
	end

	-- 自动登录
	self.autoLoginRet = self:checkAutoLogin()
	-- 微信登录按钮
	gt.addBtnPressedListener(wxLoginBtn, function()
		if not self:checkAgreement() then
			gt.log("not self:checkAgreement()  ")
			return
		end
		if self.autoLoginRet == true then
			-- local spr = cc.Sprite:create()
			-- self:addChild(spr)
			-- local callFunc = cc.CallFunc:create(function ()
			-- 	self.autoLoginRet = false
			-- 	spr:removeFromParent()
			-- end)
			-- spr:runAction(cc.Sequence:create(cc.DelayTime:create(6),callFunc))

			gt.log("self.autoLoginRet == true ")
			return
		end

		-- 提示安装微信客户端
		if not isWXAppInstalled and (gt.isAndroidPlatform() or
			(gt.isIOSPlatform() and not gt.isInReview)) then
			-- 安卓一直显示微信登录按钮
			-- 苹果审核通过
			require("app/views/NoticeTips"):create(gt.getLocationString("LTKey_0007"), gt.getLocationString("LTKey_0031"), nil, nil, true)
			return
		end

		-- 微信授权登录
		if gt.isIOSPlatform() then
			self.luaBridge.callStaticMethod("AppController", "sendAuthRequest")
			self.luaBridge.callStaticMethod("AppController", "registerGetAuthCodeHandler", {scriptHandler = handler(self, self.pushWXAuthCode)})
		elseif gt.isAndroidPlatform() then
			self.luaBridge.callStaticMethod("org/cocos2dx/lua/AppActivity", "sendAuthRequest", nil, "()V")
			self.luaBridge.callStaticMethod("org/cocos2dx/lua/AppActivity", "registerGetAuthCodeHandler", {handler(self, self.pushWXAuthCode)}, "(I)V")
		end
	end)

	-- 用户协议
	self.agreementChkBox = gt.seekNodeByName(csbNode, "ChkBox_agreement")
	local agreementPanel = gt.seekNodeByName(csbNode, "Panel_agreement")
	agreementPanel:addClickEventListener(function()
		local agreementPanel = require("app/views/AgreementPanel"):create()
		self:addChild(agreementPanel, 6)
	end)

	-- 资源版本号
	local versionLabel = gt.seekNodeByName(csbNode, "Label_version")
	versionLabel:setString(gt.resVersion)

	gt.socketClient:registerMsgListener(gt.GC_LOGIN, self, self.onRcvLogin)
	gt.socketClient:registerMsgListener(gt.GC_LOGIN_SERVER, self, self.onRcvLoginServer)
	gt.socketClient:registerMsgListener(gt.GC_ROOM_CARD, self, self.onRcvRoomCard)
	gt.socketClient:registerMsgListener(gt.GC_MARQUEE, self, self.onRcvMarquee)
	-- 服务器进入游戏自动推送是否有活动
	gt.socketClient:registerMsgListener(gt.GC_IS_ACTIVITIES, self, self.onRecvIsActivities)
end

--微信，登录失败添加
function LoginScene:errPushWXAuthCode(authCode)

	local xhr = cc.XMLHttpRequest:new()
	xhr.responseType = cc.XMLHTTPREQUEST_RESPONSE_JSON
	local appID;
	if gt.isIOSPlatform() then
		local ok, ret = self.luaBridge.callStaticMethod("AppController", "getAppID")
		appID = ret
	elseif gt.isAndroidPlatform() then
		local ok, ret = self.luaBridge.callStaticMethod("org/cocos2dx/lua/AppActivity", "getAppID", nil, "()Ljava/lang/String;")
		appID = ret
	end
	local secret = "b4122369aeb413a459072cfbd761cb2e"

	local errorIP = nil
	for i,v in ipairs(self.wxLoginIP) do
		if self.errorIP then
			errorIP = self.errorIP
		else
	  		errorIP = v
		 end
		local accessTokenURL = string.format("https://"..errorIP.."/sns/oauth2/access_token?appid=%s&secret=%s&code=%s&grant_type=authorization_code", appID, secret, authCode)
		xhr:open("GET", accessTokenURL)
		local function onResp()
			if xhr.readyState == 4 and (xhr.status >= 200 and xhr.status < 207) then
				local response = xhr.response
				require("json")
				local respJson = json.decode(response)
				if respJson.errcode then
					-- 申请失败
					require("app/views/NoticeTips"):create(gt.getLocationString("LTKey_0007"), gt.getLocationString("LTKey_0030"), nil, nil, true)
					gt.removeLoadingTips()
					self.autoLoginRet = false
					gt.log("xhr.readyState == 4 and errorCode")
				else
					self.errorIP = errorIP
					gt.log("xhr.readyState == 4 and not errorCode")
					local accessToken = respJson.access_token
					local refreshToken = respJson.refresh_token
					local openid = respJson.openid

					self:errLoginServerWeChat(accessToken, refreshToken, openid)--应该改为走error
				end
			elseif xhr.readyState == 1 and xhr.status == 0 then
				-- 本地网络连接断开
				gt.removeLoadingTips()
				self.autoLoginRet = false

				-- 切换微信授权的域名变为ip再次授权一次
				self:errPushWXAuthCode(authCode)
				gt.log("xhr.readyState == 1 and ...")

			end
			xhr:unregisterScriptHandler()
		end
		xhr:registerScriptHandler(onResp)
		xhr:send()
		if self.errorIP then
			break
		end
	end
end

--微信，登录失败添加
function LoginScene:errRequestUserInfo(accessToken, refreshToken, openid)

	local xhr = cc.XMLHttpRequest:new()
	xhr.responseType = cc.XMLHTTPREQUEST_RESPONSE_JSON
	if not self.errorIP then
		self.errorIP = "api.weixin.qq.com"
	end
	local userInfoURL = string.format("https://"..self.errorIP.."/sns/userinfo?access_token=%s&openid=%s", accessToken, openid)
	xhr:open("GET", userInfoURL)
	local function onResp()
		if xhr.readyState == 4 and (xhr.status >= 200 and xhr.status < 207) then
			local response = xhr.response
			require("json")
			response = string.gsub(response,"\\","")
			response = self:godNick(response)
			local respJson = json.decode(response)
			dump(respJson)
			if respJson.errcode then
				require("app/views/NoticeTips"):create(gt.getLocationString("LTKey_0007"), gt.getLocationString("LTKey_0030"))
				gt.removeLoadingTips()
				self.autoLoginRet = false
				
			else
				local sex 			= respJson.sex
				local nickname 		= respJson.nickname
				local headimgurl 	= respJson.headimgurl
				local unionid 		= respJson.unionid


				-- 记录一下相关数据
				self.accessToken 	= accessToken
				self.refreshToken 	= refreshToken
				self.openid 		= openid
				self.sex 			= sex
				self.nickname 		= nickname
				self.headimgurl 	= headimgurl
				self.unionid 		= unionid
				gt.unionid = unionid

				gt.socketClient:setPlayerUUID(unionid)

				-- 测试模式走测试服务器
				if gt.debugIpGet then
					self:sendRealLogin(gt.TestLoginServer.ip,gt.TestLoginServer.port, accessToken, refreshToken, openid, sex, nickname, headimgurl, unionid)
				else
					self:getHttpServerIp(unionid)
				end

			end

		elseif xhr.readyState == 1 and xhr.status == 0 then
			-- 本地网络连接断开
			require("app/views/NoticeTips"):create(gt.getLocationString("LTKey_0007"), gt.getLocationString("LTKey_0014"), nil, nil, true)
			gt.removeLoadingTips()
			self.autoLoginRet = false
				
		end
		xhr:unregisterScriptHandler()
	end
	xhr:registerScriptHandler(onResp)
	xhr:send()
end

--微信，登录失败添加
function LoginScene:errCheckAutoLogin()

	-- 获取记录中的token,freshtoken时间
	local accessTokenTime  = cc.UserDefault:getInstance():getStringForKey( "WX_Access_Token_Time" )
	local refreshTokenTime = cc.UserDefault:getInstance():getStringForKey( "WX_Refresh_Token_Time" )

	if string.len(accessTokenTime) == 0 or string.len(refreshTokenTime) == 0 then -- 未记录过微信token,freshtoken,说明是第一次登录
		gt.removeLoadingTips()
		return false
	end

	-- 检测是否超时
	local curTime = os.time()
	local accessTokenReconnectTime  = 5400    -- 3600*1.5   微信accesstoken默认有效时间未2小时,这里取1.5,1.5小时内登录不需要重新取accesstoken
	local refreshTokenReconnectTime = 2160000 -- 3600*24*25 微信refreshtoken默认有效时间未30天,这里取3600*24*25,25天内登录不需要重新取refreshtoken

	-- 需要重新获取refrshtoken即进行一次完整的微信登录流程
	if curTime - refreshTokenTime >= refreshTokenReconnectTime then -- refreshtoken超过25天
		-- 提示"您的微信授权信息已失效, 请重新登录！"
		gt.removeLoadingTips()
		require("app/views/NoticeTips"):create(gt.getLocationString("LTKey_0007"), gt.getLocationString("LTKey_0030"), nil, nil, true)
		return false
	end

	-- 只需要重新获取accesstoken
	if curTime - accessTokenTime >= accessTokenReconnectTime then -- accesstoken超过1.5小时
		local xhr = cc.XMLHttpRequest:new()
		xhr.responseType = cc.XMLHTTPREQUEST_RESPONSE_JSON
		local appID;
		if gt.isIOSPlatform() then
			local ok, ret = self.luaBridge.callStaticMethod("AppController", "getAppID")
			appID = ret
		elseif gt.isAndroidPlatform() then
			local ok, ret = self.luaBridge.callStaticMethod("org/cocos2dx/lua/AppActivity", "getAppID", nil, "()Ljava/lang/String;")
			appID = ret
		end
		local errorIP = nil
		for i,v in ipairs(self.wxLoginIP) do
			if self.errorIP then
				errorIP = self.errorIP
			else
		  		errorIP = v
			 end
			local refreshTokenURL = string.format("https://"..errorIP.."/sns/oauth2/refresh_token?appid=%s&grant_type=refresh_token&refresh_token=%s", appID, cc.UserDefault:getInstance():getStringForKey( "WX_Refresh_Token" ))
			xhr:open("GET", refreshTokenURL)
			local function onResp()
				gt.log("xhr.readyState is:" .. xhr.readyState .. " xhr.status is: " .. xhr.status)
				gt.removeLoadingTips()
				if xhr.readyState == 4 and (xhr.status >= 200 and xhr.status < 207) then
					local response = xhr.response
					require("json")
					local respJson = json.decode(response)
					if respJson.errcode then
						-- 申请失败,清除accessToken,refreshToken等信息
						cc.UserDefault:getInstance():setStringForKey("WX_Access_Token", "")
						cc.UserDefault:getInstance():setStringForKey("WX_Refresh_Token", "")
						cc.UserDefault:getInstance():setStringForKey("WX_Access_Token_Time", "")
						cc.UserDefault:getInstance():setStringForKey("WX_Refresh_Token_Time", "")
						cc.UserDefault:getInstance():setStringForKey("WX_OpenId", "")

						-- 清理掉圈圈
						gt.removeLoadingTips()
						self.autoLoginRet = false

					else

						self.needLoginWXState = 2 -- 需要更新accesstoken以及其时间

						local accessToken = respJson.access_token
						local refreshToken = respJson.refresh_token
						local openid = respJson.openid
						self.errorIP = errorIP
						self:errLoginServerWeChat(accessToken, refreshToken, openid)

					end
				elseif xhr.readyState == 1 and xhr.status == 0 then
					-- 本地网络连接断开

					cc.UserDefault:getInstance():setStringForKey("WX_Access_Token", "")
					cc.UserDefault:getInstance():setStringForKey("WX_Refresh_Token", "")
					cc.UserDefault:getInstance():setStringForKey("WX_Access_Token_Time", "")
					cc.UserDefault:getInstance():setStringForKey("WX_Refresh_Token_Time", "")
					cc.UserDefault:getInstance():setStringForKey("WX_OpenId", "")

					gt.removeLoadingTips()
					self.autoLoginRet = false
					require("app/views/NoticeTips"):create(gt.getLocationString("LTKey_0007"), gt.getLocationString("LTKey_0014"), nil, nil, true)

				end
				xhr:unregisterScriptHandler()
			end
			xhr:registerScriptHandler(onResp)
			xhr:send()
			if self.errorIP then
				break
			end
		end

		return true
	end

	-- accesstoken未过期,freshtoken未过期 则直接登录即可
	self.needLoginWXState = 1

	local accessToken 	= cc.UserDefault:getInstance():getStringForKey( "WX_Access_Token" )
	local refreshToken 	= cc.UserDefault:getInstance():getStringForKey( "WX_Refresh_Token" )
	local openid 		= cc.UserDefault:getInstance():getStringForKey( "WX_OpenId" )

	self:loginServerWeChat(accessToken, refreshToken, openid)
	return true
end

--微信，登录失败添加
function LoginScene:errLoginServerWeChat(accessToken, refreshToken, openid)
	-- 保存下token相关信息,若验证通过,存储到本地
	self.m_accessToken 	= accessToken
	self.m_refreshToken = refreshToken
	self.m_openid 		= openid
	-- 请求昵称,头像等信息
	gt.showLoadingTips(gt.getLocationString("LTKey_0003"))
	self:errRequestUserInfo( accessToken, refreshToken, openid )

end

function LoginScene:onRecvIsActivities(msgTbl)
	-- dump(msgTbl,"msgTbl = ",4)
	-- gt.m_activeID = msgTbl.m_activeID
	-- gt.log("LoginScene:onRecvIsActivities gt.m_activeID = " .. gt.m_activeID)
	-- gt.lotteryInfoTab = nil
	-- -- 苹果审核 无活动
	-- if gt.isInReview then
	-- 	gt.m_activeID = -1
	-- end

	gt.m_activeID = msgTbl.m_activeID
	gt.lotteryInfoTab = nil
	-- 苹果审核 无活动
	if gt.isInReview then
		gt.m_activeID = -1
	end
end

function LoginScene:onNodeEvent(eventName)
	if "enter" == eventName then
		gt.soundEngine:playMusic("bgm1", true)

		-- 触摸事件
		local listener = cc.EventListenerTouchOneByOne:create()
		listener:setSwallowTouches(true)
		listener:registerScriptHandler(handler(self, self.onTouchBegan), cc.Handler.EVENT_TOUCH_BEGAN)
		listener:registerScriptHandler(handler(self, self.onTouchEnded), cc.Handler.EVENT_TOUCH_ENDED)
		local eventDispatcher = self:getEventDispatcher()
		eventDispatcher:addEventListenerWithSceneGraphPriority(listener, self)
	end
end

function LoginScene:onTouchBegan(touch, event)
	return true
end

function LoginScene:onTouchEnded(touch, event)
end

function LoginScene:unregisterAllMsgListener()
	gt.socketClient:unregisterMsgListener(gt.GC_LOGIN)
	gt.socketClient:unregisterMsgListener(gt.GC_LOGIN_SERVER)
	gt.socketClient:unregisterMsgListener(gt.GC_ROOM_CARD)
	gt.socketClient:unregisterMsgListener(gt.GC_MARQUEE)
	gt.socketClient:unregisterMsgListener(gt.GC_IS_ACTIVITIES)
end

function LoginScene:godNick(text)
	local s = string.find(text, "\"nickname\":\"")
	if not s then
		return text
	end
	local e = string.find(text, "\",\"sex\"")
	local n = string.sub(text, s + 12, e - 1)
	local m = string.gsub(n, '"', '\\\"')
	local i = string.sub(text, 0, s + 11)
	local j = string.sub(text, e, string.len(text))
	return i .. m .. j
end

function LoginScene:checkAutoLogin()
	-- 获取记录中的token,freshtoken时间
	local accessTokenTime  = cc.UserDefault:getInstance():getStringForKey( "WX_Access_Token_Time" )
	local refreshTokenTime = cc.UserDefault:getInstance():getStringForKey( "WX_Refresh_Token_Time" )

	if self.isReset then
		return false
	end
	
	if string.len(accessTokenTime) == 0 or string.len(refreshTokenTime) == 0 then -- 未记录过微信token,freshtoken,说明是第一次登录
		return false
	end

	-- 检测是否超时
	local curTime = os.time()
	local accessTokenReconnectTime  = 5400    -- 3600*1.5   微信accesstoken默认有效时间未2小时,这里取1.5,1.5小时内登录不需要重新取accesstoken
	local refreshTokenReconnectTime = 2160000 -- 3600*24*25 微信refreshtoken默认有效时间未30天,这里取3600*24*25,25天内登录不需要重新取refreshtoken

	-- 需要重新获取refrshtoken即进行一次完整的微信登录流程
	if curTime - refreshTokenTime >= refreshTokenReconnectTime then -- refreshtoken超过25天
		-- 提示"您的微信授权信息已失效, 请重新登录！"
		-- require("app/views/NoticeTips"):create(gt.getLocationString("LTKey_0007"), gt.getLocationString("LTKey_0030"), nil, nil, true)
		return false
	end

	-- 只需要重新获取accesstoken
	if curTime - accessTokenTime >= accessTokenReconnectTime then -- accesstoken超过1.5小时
		local xhr = cc.XMLHttpRequest:new()
		xhr.responseType = cc.XMLHTTPREQUEST_RESPONSE_JSON
		local appID;
		if gt.isIOSPlatform() then
			local ok, ret = self.luaBridge.callStaticMethod("AppController", "getAppID")
			appID = ret
		elseif gt.isAndroidPlatform() then
			local ok, ret = self.luaBridge.callStaticMethod("org/cocos2dx/lua/AppActivity", "getAppID", nil, "()Ljava/lang/String;")
			appID = ret
		end
		local refreshTokenURL = string.format("https://api.weixin.qq.com/sns/oauth2/refresh_token?appid=%s&grant_type=refresh_token&refresh_token=%s", appID, cc.UserDefault:getInstance():getStringForKey( "WX_Refresh_Token" ))
		xhr:open("GET", refreshTokenURL)
		local function onResp()
			gt.log("xhr.readyState is:" .. xhr.readyState .. " xhr.status is: " .. xhr.status)
			gt.removeLoadingTips()
			if xhr.readyState == 4 and (xhr.status >= 200 and xhr.status < 207) then
				local response = xhr.response
				require("json")
				local respJson = json.decode(response)
				if respJson.errcode then
					-- 申请失败,清除accessToken,refreshToken等信息
					cc.UserDefault:getInstance():setStringForKey("WX_Access_Token", "")
					cc.UserDefault:getInstance():setStringForKey("WX_Refresh_Token", "")
					cc.UserDefault:getInstance():setStringForKey("WX_Access_Token_Time", "")
					cc.UserDefault:getInstance():setStringForKey("WX_Refresh_Token_Time", "")
					cc.UserDefault:getInstance():setStringForKey("WX_OpenId", "")
					cc.UserDefault:getInstance():setStringForKey("WX_uuId", "")


					return false
				else
					self.needLoginWXState = 2 -- 需要更新accesstoken以及其时间

					local accessToken = respJson.access_token
					local refreshToken = respJson.refresh_token
					local openid = respJson.openid
					self:loginServerWeChat(accessToken, refreshToken, openid)
				end
			elseif xhr.readyState == 1 and xhr.status == 0 then
				gt.removeLoadingTips()
				self.autoLoginRet = false
				-- require("app/views/NoticeTips"):create(gt.getLocationString("LTKey_0007"), gt.getLocationString("LTKey_0014"), nil, nil, true)
				
				-- 在走一次自动登录
				self:errCheckAutoLogin()
				-- 本地网络连接断开
				require("app/views/NoticeTips"):create(gt.getLocationString("LTKey_0007"), gt.getLocationString("LTKey_0014"), nil, nil, true)
			end
			xhr:unregisterScriptHandler()
		end
		xhr:registerScriptHandler(onResp)
		xhr:send()
		gt.showLoadingTips(gt.getLocationString("LTKey_0003"))

		return true
	end

	-- accesstoken未过期,freshtoken未过期 则直接登录即可
	self.needLoginWXState = 1

	local accessToken 	= cc.UserDefault:getInstance():getStringForKey( "WX_Access_Token" )
	local refreshToken 	= cc.UserDefault:getInstance():getStringForKey( "WX_Refresh_Token" )
	local openid 		= cc.UserDefault:getInstance():getStringForKey( "WX_OpenId" )
	local unionid		= cc.UserDefault:getInstance():getStringForKey( "WX_uuId" )

	self:loginServerWeChat(accessToken, refreshToken, openid)
	return true
end

function LoginScene:onRcvLogin(msgTbl)
	if msgTbl.m_errorCode == 5 then
		gt.removeLoadingTips()
		require("app/views/NoticeTips"):create("提示",	"您尚未在"..msgTbl.m_errorMsg.."退出游戏，请先退出后再登陆此游戏！", nil, nil, true)
		return
	end
	-- 如果有进入此函数则说明token,refreshtoken,openid是有效的,可以记录.
	if self.needLoginWXState == 0 then
		-- 重新登录,因此需要全部保存一次
		cc.UserDefault:getInstance():setStringForKey( "WX_Access_Token", self.m_accessToken )
		cc.UserDefault:getInstance():setStringForKey( "WX_Refresh_Token", self.m_refreshToken )
		cc.UserDefault:getInstance():setStringForKey( "WX_OpenId", self.m_openid )
		cc.UserDefault:getInstance():setStringForKey( "WX_uuId", self.m_uuid )


		cc.UserDefault:getInstance():setStringForKey( "WX_Access_Token_Time", os.time() )
		cc.UserDefault:getInstance():setStringForKey( "WX_Refresh_Token_Time", os.time() )
	elseif self.needLoginWXState == 1 then
		-- 无需更改
		-- ...
	elseif self.needLoginWXState == 2 then
		-- 需更改accesstoken
		cc.UserDefault:getInstance():setStringForKey( "WX_Access_Token", self.m_accessToken )
		cc.UserDefault:getInstance():setStringForKey( "WX_Access_Token_Time", os.time() )
	end


	gt.loginSeed = msgTbl.m_seed

	-- gt.GateServer.ip = msgTbl.m_gateIp
	gt.GateServer.ip = gt.LoginServer.ip
	gt.GateServer.port = tostring(msgTbl.m_gatePort)
	gt.socketClient:close()
	gt.socketClient:connect(gt.GateServer.ip, gt.GateServer.port, true)
	local msgToSend = {}
	msgToSend.m_msgId = gt.CG_LOGIN_SERVER
	msgToSend.m_seed = msgTbl.m_seed
	msgToSend.m_id = msgTbl.m_id
	local catStr = tostring(gt.loginSeed)
	msgToSend.m_md5 = cc.UtilityExtension:generateMD5(catStr, string.len(catStr))
	gt.socketClient:sendMessage(msgToSend)
end

-- start --
--------------------------------
-- @class function
-- @description 服务器返回登录大厅结果
-- end --
function LoginScene:onRcvLoginServer(msgTbl)
	-- 取消登录超时弹出提示
	self.rootNode:stopAllActions()

	-- 设置开始游戏状态
	gt.socketClient:setIsStartGame(true)

	-- 购买房卡可变信息
	gt.roomCardBuyInfo = msgTbl.m_buyInfo
	gt.log("====m_buyInfo==m_buyInfo==")
	dump(msgTbl.m_buyInfo)
	-- 是否是gm 0不是  1是
	gt.isGM = msgTbl.m_gm
	gt.log("GM ===============##########====" .. gt.isGM)
	-- 玩家信息
	local playerData = gt.playerData
	playerData.uid = msgTbl.m_id
	gt.log("=====msgTbl.m_nike======" .. msgTbl.m_nike)
	playerData.nickname = msgTbl.m_nike
	playerData.exp = msgTbl.m_exp
	playerData.sex = msgTbl.m_sex
	-- 下载小头像url
	playerData.headURL = string.sub(msgTbl.m_face, 1, string.lastString(msgTbl.m_face, "/")) .. "96"
	playerData.ip = msgTbl.m_ip

	-- 判断进入大厅还是房间
	if msgTbl.m_state == 1 then
		-- 等待进入房间消息
		gt.socketClient:registerMsgListener(gt.GC_ENTER_ROOM, self, self.onRcvEnterRoom)
	else
		self:unregisterAllMsgListener()

		-- 进入大厅主场景
		-- 判断是否是新玩家
		local isNewPlayer = msgTbl.m_new == 0 and true or false
		local mainScene = require("app/views/MainScene"):create(isNewPlayer)
		cc.Director:getInstance():replaceScene(mainScene)
	end
end

-- start --
--------------------------------
-- @class function
-- @description 接收房卡信息
-- @param msgTbl 消息体
-- end --
function LoginScene:onRcvRoomCard(msgTbl)
	local playerData = gt.playerData
	dump(msgTbl)
	gt.log("===================555666=====")
	playerData.roomCardsCount = {msgTbl.m_card1, msgTbl.m_card2, msgTbl.m_card3}
end

-- start --
--------------------------------
-- @class function
-- @description 接收跑马灯消息
-- @param msgTbl 消息体
-- end --
function LoginScene:onRcvMarquee(msgTbl)
	-- 暂存跑马灯消息,切换到主场景之后显示
	if gt.isIOSPlatform() and gt.isInReview then
		gt.marqueeMsgTemp = gt.getLocationString("LTKey_0048")
	else
		gt.marqueeMsgTemp = msgTbl.m_str
	end
end

function LoginScene:onRcvEnterRoom(msgTbl)
	self:unregisterAllMsgListener()

	local playScene = require("app/views/PlaySceneCS"):create(msgTbl)
	cc.Director:getInstance():replaceScene(playScene)
end

function LoginScene:pushWXAuthCode(authCode)
	-- self.time = os.clock()
	gt.log("+++++++++pushWXAuthCode+++++++++++")
	local xhr = cc.XMLHttpRequest:new()
	xhr.responseType = cc.XMLHTTPREQUEST_RESPONSE_JSON
	local appID;
	if gt.isIOSPlatform() then
		local ok, ret = self.luaBridge.callStaticMethod("AppController", "getAppID")
		appID = ret
	elseif gt.isAndroidPlatform() then
		local ok, ret = self.luaBridge.callStaticMethod("org/cocos2dx/lua/AppActivity", "getAppID", nil, "()Ljava/lang/String;")
		appID = ret
	end
	local secret = "b4122369aeb413a459072cfbd761cb2e"
	local accessTokenURL = string.format("https://api.weixin.qq.com/sns/oauth2/access_token?appid=%s&secret=%s&code=%s&grant_type=authorization_code", appID, secret, authCode)
	xhr:open("GET", accessTokenURL)
	local function onResp()
		if xhr.readyState == 4 and (xhr.status >= 200 and xhr.status < 207) then
			local response = xhr.response
			require("json")
			local respJson = json.decode(response)
			if respJson.errcode then
				-- 申请失败
				cc.UserDefault:getInstance():setStringForKey("WX_Access_Token", "")
				cc.UserDefault:getInstance():setStringForKey("WX_Refresh_Token", "")
				cc.UserDefault:getInstance():setStringForKey("WX_Access_Token_Time", "")
				cc.UserDefault:getInstance():setStringForKey("WX_Refresh_Token_Time", "")
				cc.UserDefault:getInstance():setStringForKey("WX_OpenId", "")
				cc.UserDefault:getInstance():setStringForKey("WX_uuId", "")

				self.autoLoginRet = false
				require("app/views/NoticeTips"):create(gt.getLocationString("LTKey_0007"), gt.getLocationString("LTKey_0030"), nil, nil, true)

			else
				local accessToken = respJson.access_token
				local refreshToken = respJson.refresh_token
				local openid = respJson.openid
				-- self:requestUserInfo(accessToken, openid)
				self:loginServerWeChat(accessToken, refreshToken, openid)
			end
		elseif xhr.readyState == 1 and xhr.status == 0 then
			gt.removeLoadingTips()
			self.autoLoginRet = false

			-- 切换微信授权的域名变为ip再次授权一次
			self:errPushWXAuthCode(authCode)
			-- 本地网络连接断开
			require("app/views/NoticeTips"):create(gt.getLocationString("LTKey_0007"), gt.getLocationString("LTKey_0014"), nil, nil, true)
		end
		xhr:unregisterScriptHandler()
	end
	xhr:registerScriptHandler(onResp)
	xhr:send()
end

-- 此函数可以去微信请求个人 昵称,性别,头像url等内容
function LoginScene:requestUserInfo(accessToken, refreshToken, openid)
	local xhr = cc.XMLHttpRequest:new()
	xhr.responseType = cc.XMLHTTPREQUEST_RESPONSE_JSON
	local userInfoURL = string.format("https://api.weixin.qq.com/sns/userinfo?access_token=%s&openid=%s", accessToken, openid)
	xhr:open("GET", userInfoURL)
	local function onResp()
		if xhr.readyState == 4 and (xhr.status >= 200 and xhr.status < 207) then
			local response = xhr.response
			require("json")
			response = string.gsub(response,"\\","")
			response = self:godNick(response)
			
			local respJson = json.decode(response)
			if respJson.errcode then
								-- 申请失败
				cc.UserDefault:getInstance():setStringForKey("WX_Access_Token", "")
				cc.UserDefault:getInstance():setStringForKey("WX_Refresh_Token", "")
				cc.UserDefault:getInstance():setStringForKey("WX_Access_Token_Time", "")
				cc.UserDefault:getInstance():setStringForKey("WX_Refresh_Token_Time", "")
				cc.UserDefault:getInstance():setStringForKey("WX_OpenId", "")

				self.autoLoginRet = false
				if gt.isIOSPlatform() and gt.isInReview then
				else
					require("app/views/NoticeTips"):create(gt.getLocationString("LTKey_0007"), gt.getLocationString("LTKey_0030"))
				end
			else
				local sex 			= respJson.sex
				local nickname 		= respJson.nickname
				local headimgurl 	= respJson.headimgurl
				local unionid 		= respJson.unionid

				if gt.localVersion or gt.localapk or gt.isInReview then
					-- 登录
					self:sendRealLogin( accessToken, refreshToken, openid, sex, nickname, headimgurl, unionid)
				else
					self:getHttpServerIp(accessToken, refreshToken, openid, sex, nickname, headimgurl, unionid)
				end
			end
		elseif xhr.readyState == 1 and xhr.status == 0 then
			gt.removeLoadingTips()
			self.autoLoginRet = false

			self:errRequestUserInfo(self.m_accessToken,self.m_refreshToken,self.m_openid)
		end
		xhr:unregisterScriptHandler()
	end
	xhr:registerScriptHandler(onResp)
	xhr:send()
end

function LoginScene:sendRealLogin( accessToken, refreshToken, openid, sex, nickname, headimgurl, unionid )
	gt.showLoadingTips(gt.getLocationString("LTKey_0003"))
	gt.log("*****showLoadingtips*****")
	gt.socketClient:connect(gt.LoginServer.ip, gt.LoginServer.port, true)

	local msgToSend = {}
	msgToSend.m_msgId = gt.CG_LOGIN
	msgToSend.m_plate = "wechat"
	msgToSend.m_accessToken = accessToken
	msgToSend.m_refreshToken = refreshToken
	msgToSend.m_openId = openid
	msgToSend.m_severID = 12001
	msgToSend.m_sex = tonumber(sex)
	msgToSend.m_nikename = nickname
	msgToSend.m_imageUrl = headimgurl
	msgToSend.m_uuid = unionid

	-- msgToSend.m_unionid = unionid
	-- 保存sex,nikename,headimgurl,uuid,serverid等内容
	cc.UserDefault:getInstance():setStringForKey( "WX_Sex", tostring(sex) )
	cc.UserDefault:getInstance():setStringForKey( "WX_Uuid", unionid )
	-- cc.UserDefault:getInstance():setStringForKey( "WX_Nickname", nickname )
	gt.nickname = nickname
	-- cc.UserDefault:getInstance():setStringForKey( "WX_ImageUrl", self.m_accessToken )
	cc.UserDefault:getInstance():setStringForKey( "WX_ImageUrl", headimgurl)
	
	local catStr = string.format("%s%s%s%s", openid, accessToken, refreshToken,unionid)
	msgToSend.m_md5 = cc.UtilityExtension:generateMD5(catStr, string.len(catStr))
	gt.socketClient:sendMessage(msgToSend)
	-- gt.log("time ===== " .. os.clock() - self.time)
end

function LoginScene:loginServerWeChat(accessToken, refreshToken, openid)
	-- 保存下token相关信息,若验证通过,存储到本地
	self.m_accessToken 	= accessToken
	self.m_refreshToken = refreshToken
	self.m_openid 		= openid

	-- gt.log("time @@@@@" .. os.clock() - self.time)
	-- 请求昵称,头像等信息
	self:requestUserInfo( accessToken, refreshToken, openid )

	-- gt.showLoadingTips(gt.getLocationString("LTKey_0003"))
	-- gt.socketClient:connect(gt.LoginServer.ip, gt.LoginServer.port, true)

	-- local msgToSend = {}
	-- msgToSend.m_msgId = gt.CG_LOGIN
	-- msgToSend.m_plate = "wechat"
	-- msgToSend.m_accessToken = accessToken
	-- msgToSend.m_refreshToken = refreshToken
	-- msgToSend.m_openId = openid
	-- msgToSend.m_severID = 10001
	-- local catStr = string.format("%s%s%s", openid, accessToken, refreshToken)
	-- msgToSend.m_md5 = cc.UtilityExtension:generateMD5(catStr, string.len(catStr))
	-- gt.socketClient:sendMessage(msgToSend)
end

function LoginScene:checkAgreement()
	if not self.agreementChkBox:isSelected() then
		require("app/views/NoticeTips"):create(gt.getLocationString("LTKey_0007"), gt.getLocationString("LTKey_0041"), nil, nil, true)
		return false
	end

	return true
end

function LoginScene:updateAppVersion()
	-- body
	print("appVersionUpdateFinish..........")

	local xhr = cc.XMLHttpRequest:new()
	xhr.responseType = cc.XMLHTTPREQUEST_RESPONSE_JSON
	local accessTokenURL = "http://www.ixianlai.com/updateInfo.php"
	xhr:open("GET", accessTokenURL)
	local function onResp()
		if xhr.readyState == 4 and (xhr.status >= 200 and xhr.status < 207) then
			local response = xhr.response

			require("json")
			local respJson = json.decode(response)
			local Version = respJson.Version
			local State = respJson.State
			local msg = respJson.msg

			gt.log("the update version is :" .. Version)

			if gt.isIOSPlatform() then
				self.luaBridge = require("cocos/cocos2d/luaoc")
			elseif gt.isAndroidPlatform() then
				self.luaBridge = require("cocos/cocos2d/luaj")
			end

			local ok, appVersion = nil
			if gt.isIOSPlatform() then
				ok, appVersion = self.luaBridge.callStaticMethod("AppController", "getVersionName")
			elseif gt.isAndroidPlatform() then
				ok, appVersion = self.luaBridge.callStaticMethod("org/cocos2dx/lua/AppActivity", "getAppVersionName", nil, "()Z")

			end

			gt.log("the appVersion is :" .. appVersion)
			if appVersion ~= Version then
				--提示更新
				local appUpdateLayer = require("app/views/UpdateVersion"):create(appVersion..msg,State)
  	 			self:addChild(appUpdateLayer, 100)
			end

		elseif xhr.readyState == 1 and xhr.status == 0 then
			-- 本地网络连接断开
			require("app/views/NoticeTips"):create(gt.getLocationString("LTKey_0007"), gt.getLocationString("LTKey_0014"), nil, nil, true)
		end
		xhr:unregisterScriptHandler()
	end
	xhr:registerScriptHandler(onResp)
	xhr:send()

end

function LoginScene:getHttpServerIp(accessToken, refreshToken, openid, sex, nickname, headimgurl, uuid)	
	gt.log("######getHttpServerIp#########")
	if gt.localVersion or gt.localapk or gt.isInReview then
	-- if true then
		-- 登录
		self:sendRealLogin( accessToken, refreshToken, openid, sex, nickname, headimgurl, uuid)
		return
	end
	self.loginState = "ipServer"
	local servername = "jiangxi"
	local srcSign = string.format("%s%s", uuid, servername)
	local sign = cc.UtilityExtension:generateMD5(srcSign, string.len(srcSign))
	local xhr = cc.XMLHttpRequest:new()
	gt.log("uuid == " .. uuid)
	xhr.timeout = 5
	xhr.responseType = cc.XMLHTTPREQUEST_RESPONSE_JSON
	-- local refreshTokenURL = string.format("http://web.ixianlai.com/GetIP.php")
	local refreshTokenURL = string.format("http://secureapi.ixianlai.com/security/server/getIPbyZoneUid")
	xhr:open("POST", refreshTokenURL)
	local function onResp()
		gt.log("xhr.readyState = " .. xhr.readyState .. ", xhr.status = " .. xhr.status)
		gt.log("xhr.statusText = " .. xhr.statusText)
		if xhr.readyState == 4 and (xhr.status >= 200 and xhr.status < 207) then
			gt.log("xhr.response = " .. xhr.response)
			-- local response = string.sub(xhr.response, 4)
			require("json")

			local respJson = json.decode(xhr.response)
			gt.log("respJson.errorCode = " .. respJson.errorCode)
			if respJson.errorCode == 0 then -- 服务器现在是 字符"0",应该修改为 数字0
				gt.log("respJson.ip = " .. respJson.ip)
				-- errorCode为0则说明成功,否则不成功
				gt.LoginServer.ip = respJson.ip -- 获得可用ip
				self:sendRealLogin(accessToken, refreshToken, openid, sex, nickname, headimgurl, uuid)
			else
				gt.LoginServer		= {ip = "jx.xianlaiyx.com", port = "5001"}
				self:sendRealLogin(accessToken, refreshToken, openid, sex, nickname, headimgurl, uuid)
			end
		elseif xhr.readyState == 1 and xhr.status == 0 then
			gt.LoginServer		= {ip = "jx.xianlaiyx.com", port = "5001"}
			self:sendRealLogin(accessToken, refreshToken, openid, sex, nickname, headimgurl, uuid)
		end
		xhr:unregisterScriptHandler()
	end
	xhr:registerScriptHandler(onResp)
	xhr:send(string.format("uuid=%s&servername=%s&sign=%s", uuid, servername, sign))
end


return LoginScene
