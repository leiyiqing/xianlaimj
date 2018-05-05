

local gt = cc.exports.gt

local UpdateVersion = class("UpdateVersion", function()
	return gt.createMaskLayer()
end)

function UpdateVersion:ctor(msg,state)

	local csbNode = cc.CSLoader:createNode("UpdateAppScene.csb")
	csbNode:setAnchorPoint(0.5, 0.5)
	csbNode:setPosition(gt.winCenter)
	self:addChild(csbNode)
	self.rootNode = csbNode

	if gt.isIOSPlatform() then
		self.luaBridge = require("cocos/cocos2d/luaoc")
	elseif gt.isAndroidPlatform() then
		self.luaBridge = require("cocos/cocos2d/luaj")
	end

	--更新文本
	local textLabel = gt.seekNodeByName(csbNode,"Text_label")
	textLabel:setString(msg)

	local qianNode = gt.seekNodeByName(csbNode,"Node_qiangzhi")
	local chooseNode = gt.seekNodeByName(csbNode,"Node_choose")
	local qianBtn = gt.seekNodeByName(qianNode,"Button_ok")
	local chooseCancelBtn = gt.seekNodeByName(chooseNode,"Button_cancel")
	local chooseOkBtn = gt.seekNodeByName(chooseNode,"Button_ok")
	gt.addBtnPressedListener(qianBtn, function()
		--打开系统的浏览器
		if gt.isIOSPlatform() then
			local ok = self.luaBridge.callStaticMethod("AppController", "openWebURL", {webURL = "https://itunes.apple.com/cn/app/xian-lai-nan-chang-ma-jiang/id1114285005?mt=8"})				
		elseif gt.isAndroidPlatform() then
			local ok = self.luaBridge.callStaticMethod("org/cocos2dx/lua/AppActivity", "openWebURL", {"http://www.ixianlai.com/jx_nc"}, "(Ljava/lang/String;)V")
		end
	end)
	gt.addBtnPressedListener(chooseCancelBtn,function()
		-- 取消
		self:removeFromParent()
	end)
	gt.addBtnPressedListener(chooseOkBtn,function()
		--打开系统的浏览器
		if gt.isIOSPlatform() then
			local ok = self.luaBridge.callStaticMethod("AppController", "openWebURL", {webURL = "https://itunes.apple.com/cn/app/xian-lai-nan-chang-ma-jiang/id1114285005?mt=8"})				
		elseif gt.isAndroidPlatform() then
			local ok = self.luaBridge.callStaticMethod("org/cocos2dx/lua/AppActivity", "openWebURL", {"http://www.ixianlai.com/jx_nc"}, "(Ljava/lang/String;)V")
		end
	end)
	if tonumber(state) == 0 then
		--强制更新
		qianNode:setVisible(true)
		chooseNode:setVisible(false)
	elseif tonumber(state) == 1 then
		--可选择更新
		qianNode:setVisible(false)
		chooseNode:setVisible(true)
	end

end


return UpdateVersion


