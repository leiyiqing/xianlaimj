

local gt = cc.exports.gt

local PlayerInfoTips = class("PlayerInfoTips", function()
	return cc.LayerColor:create(cc.c4b(85, 85, 85, 85), gt.winSize.width, gt.winSize.height)
end)

function PlayerInfoTips:ctor(playerData)
	-- 注册节点事件
	self:registerScriptHandler(handler(self, self.onNodeEvent))

	local csbNode = cc.CSLoader:createNode("PlayerInfoTips.csb")
	csbNode:setPosition(gt.winCenter)
	self:addChild(csbNode)

	-- 头像
	local headSpr = gt.seekNodeByName(csbNode, "Spr_head")
	local t_name = string.format("%shead_img_%d.png", cc.FileUtils:getInstance():getWritablePath(), playerData.uid)

	if cc.FileUtils:getInstance():isFileExist(t_name) == true then
		headSpr:setTexture(t_name)
	else
		if playerData.sex == 1 then	--2:女 1:男
			headSpr:setTexture("sd/images/otherImages/head_m001.png")
		else
			headSpr:setTexture("sd/images/otherImages/head_m002.png")
		end

	end

	-- 性别
	local sexSpr = gt.seekNodeByName(csbNode, "Spr_sex")
	-- 默认男
	local sexFrameName = "sex_female"
	if playerData.sex == 1 then
		-- 女
		sexFrameName = "sex_male"
	end
	sexSpr:setSpriteFrame(sexFrameName .. ".png")

	-- 昵称
	local nicknameLabel = gt.seekNodeByName(csbNode, "Label_nickname")
	nicknameLabel:setString(playerData.nickname)

	-- ID
	local uidLabel = gt.seekNodeByName(csbNode, "Label_uid")
	uidLabel:setString("ID: " .. playerData.uid)

	-- ip
	local ipLabel = gt.seekNodeByName(csbNode, "Label_ip")
	ipLabel:setString("IP: " .. playerData.ip)
end

function PlayerInfoTips:onNodeEvent(eventName)
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

function PlayerInfoTips:onTouchBegan(touch, event)
	return true
end

function PlayerInfoTips:onTouchEnded(touch, event)
	self:removeFromParent()
end

return PlayerInfoTips


