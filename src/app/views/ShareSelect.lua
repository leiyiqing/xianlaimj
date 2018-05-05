local ShareSelect = class("ShareSelect", function()
	return cc.LayerColor:create(cc.c4b(85, 85, 85, 85), gt.winSize.width, gt.winSize.height)
end)

local gt = cc.exports.gt

function ShareSelect:ctor(description, title, url)
	-- 注册节点事件
	self:registerScriptHandler(handler(self, self.onNodeEvent))

	local csbNode = cc.CSLoader:createNode("ShareSelect.csb")
	csbNode:setPosition(gt.winCenter)
	self:addChild(csbNode)
	self.rootNode = csbNode

	if gt.isIOSPlatform() then
		self.luaBridge = require("cocos/cocos2d/luaoc")
	elseif gt.isAndroidPlatform() then
		self.luaBridge = require("cocos/cocos2d/luaj")
	end

	self.description = description
	self.title = title
	self.url = url
	self.androidParam = "(Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;)V"
	
	local btn_haoyou = gt.seekNodeByName(self.rootNode, "Button_haoyou")
	gt.addBtnPressedListener(btn_haoyou, function()
		if gt.isIOSPlatform() then
			if self:checkVersion(1, 0, 6) then
				local ok = self.luaBridge.callStaticMethod("AppController", "shareURLToWX",
					{url = self.url, title = self.title, description = self.description, scriptHandler = handler(self, self.pushShareCodeHY)})
			else
				local ok = self.luaBridge.callStaticMethod("AppController", "shareURLToWX",
					{url = self.url, title = self.title, description = self.description})
			end

		elseif gt.isAndroidPlatform() then
			local luaj = require("cocos/cocos2d/luaj")
			if self:checkVersion(1, 0, 6) then
				luaj.callStaticMethod("org/cocos2dx/lua/AppActivity", "registerGetAuthCodeHandler", {handler(self, self.pushShareCodeHY)}, "(I)V")
			else

			end
			local ok = self.luaBridge.callStaticMethod("org/cocos2dx/lua/AppActivity", "shareURLToWX",
				{self.url, self.title, self.description},
				self.androidParam)
		end
		self:removeFromParent()
	end)

	local btn_pengyou = gt.seekNodeByName(self.rootNode, "Button_pengyou")
	gt.addBtnPressedListener(btn_pengyou, function()
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
	 		-- local PyqUrl = "http://a.app.qq.com/o/simple.jsp?pkgname=com.xianlai.mahjongjx"
			if gt.isIOSPlatform() then
				if self:checkVersion(1, 0, 6) then
					local ok = self.luaBridge.callStaticMethod("AppController", "shareURLToWXPYQ",
						{url = self.url, title = self.title .. self.description, description = "", scriptHandler = handler(self, self.pushShareCodePYQ)})
				else
				local ok = self.luaBridge.callStaticMethod("AppController", "shareURLToWXPYQ",
					{url = self.url, title = self.title .. self.description, description = ""})
				end

			elseif gt.isAndroidPlatform() then
				local luaj = require("cocos/cocos2d/luaj")
				if self:checkVersion(1, 0, 6) then
					luaj.callStaticMethod("org/cocos2dx/lua/AppActivity", "registerGetAuthCodeHandler", {handler(self, self.pushShareCodePYQ)}, "(I)V")			
				else

				end
				local ok = self.luaBridge.callStaticMethod("org/cocos2dx/lua/AppActivity", "shareURLToWXPYQ",
					{self.url, self.title .. self.description, ""},
					self.androidParam)
			end
			self:removeFromParent()
		end
	end)
end

function ShareSelect:pushShareCodePYQ(authCode)
	gt.log("====================PYQ", authCode, type(authCode))
	-- local loginScene = require("app/views/LogoScene"):create()
	-- cc.Director:getInstance():replaceScene(loginScene)
end

function ShareSelect:pushShareCodeHY(authCode)
	gt.log("===================HY", authCode, type(authCode))
	-- local loginScene = require("app/views/LogoScene"):create()
	-- cc.Director:getInstance():replaceScene(loginScene)	
end

function ShareSelect:onNodeEvent(eventName)
	if "enter" == eventName then
		local listener = cc.EventListenerTouchOneByOne:create()
		listener:setSwallowTouches(true)
		listener:registerScriptHandler(handler(self, self.onTouchBegan), cc.Handler.EVENT_TOUCH_BEGAN)
		listener:registerScriptHandler(handler(self, self.onTouchEnded), cc.Handler.EVENT_TOUCH_ENDED)
		local eventDispatcher = self:getEventDispatcher()
		eventDispatcher:addEventListenerWithSceneGraphPriority(listener, self)
	elseif "exit" == eventName then
		local eventDispatcher = self:getEventDispatcher()
		eventDispatcher:removeEventListenersForTarget(self)
	end
end

function ShareSelect:onTouchBegan(touch, event)
	return true
end

function ShareSelect:onTouchEnded(touch, event)
	local bg = gt.seekNodeByName(self.rootNode, "Img_bg")
	if bg then
		local point = bg:convertToNodeSpace(touch:getLocation())
		local rect = cc.rect(0, 0, bg:getContentSize().width, bg:getContentSize().height)
		if not cc.rectContainsPoint(rect, cc.p(point.x, point.y)) then
			self:removeFromParent()
		end
	end
end

function ShareSelect:checkVersion(_bai, _shi, _ge)
	local ok, appVersion = nil
	if gt.isIOSPlatform() then
		ok, appVersion = self.luaBridge.callStaticMethod("AppController", "getVersionName")
	elseif gt.isAndroidPlatform() then
		ok, appVersion = self.luaBridge.callStaticMethod("org/cocos2dx/lua/AppActivity", "getAppVersionName", nil, "()Ljava/lang/String;")
	end
	local versionNumber = string.split(appVersion, '.')
	gt.log("=======  " .. versionNumber[1]..versionNumber[2]..versionNumber[3])
	if tonumber(versionNumber[1]) > _bai
		or tonumber(versionNumber[2]) > _shi
		or tonumber(versionNumber[3]) > _ge then
		gt.log("checkVersion true")
		return true
	end
	gt.log("checkVersion false")
	return false
end

return ShareSelect