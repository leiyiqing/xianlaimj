
local gt = cc.exports.gt

local Setting = class("Setting", function()
	return cc.LayerColor:create(cc.c4b(85, 85, 85, 85), gt.winSize.width, gt.winSize.height)
end)

function Setting:ctor(playerSeatPos)
	-- 注册节点事件
	self:registerScriptHandler(handler(self, self.onNodeEvent))

	local csbNode = cc.CSLoader:createNode("Setting.csb")
	csbNode:setPosition(gt.winCenter)
	self:addChild(csbNode)
	self.rootNode = csbNode

	self.isShowDiceNum = tostring(cc.UserDefault:getInstance():getStringForKey("show_dice1"))
	
	if self.isShowDiceNum ~= "" then
		gt.log("------------isShowDiceNum----111->" .. self.isShowDiceNum)
		self.isShowDiceNum = tonumber(self.isShowDiceNum)
	else
		gt.log("------------isShowDiceNum---222-->" .. self.isShowDiceNum)
		self.isShowDiceNum = 2
	end
	cc.UserDefault:getInstance():setStringForKey("show_dice1", tostring(self.isShowDiceNum))
	--掷骰子按钮功能
	self.showDice = gt.seekNodeByName(self, "showDice")
	if playerSeatPos ~= "exit" then
		self.showDice:setVisible(false)
	else
		self.showDice:setVisible(true)
	end
	
	--不显示方言
	local CheckBox_btn1 = gt.seekNodeByName(self, "CheckBox_btn1")
	CheckBox_btn1:setVisible(false)
	local Spr_nchfy1 = gt.seekNodeByName(self, "Spr_nchfy")
	Spr_nchfy1:setVisible(false)

	local checkBox_dice = gt.seekNodeByName(self, "CheckBox_btn3")
	gt.log("------------isShowDiceNum----->" .. self.isShowDiceNum)
	if checkBox_dice then
		if self.isShowDiceNum == 2 then
			checkBox_dice:setSelected(false)
		else
			checkBox_dice:setSelected(true)
		end
		checkBox_dice:addEventListener(handler(self, self.chooseShowDiceEvt))
	end

	-- local Spr_nchfangyan = gt.seekNodeByName(self, "Spr_nchfangyan")
	-- Spr_nchfangyan:setVisible(false)
	-- local Spr_nchfy = gt.seekNodeByName(self, "Spr_nchfy")
	-- Spr_nchfy:setVisible(true)

	local CheckBox_btn1 = gt.seekNodeByName(self, "CheckBox_btn1")
	CheckBox_btn1:setTouchEnabled(false)

	-- 局数选择
	for i = 1, 2 do
		local  playTypeChkBox = gt.seekNodeByName(self, "CheckBox_btn" .. i)
		playTypeChkBox:setTag(i)
		playTypeChkBox:addEventListener(handler(self, self.choosePlayTypeEvt))
	end
	self.playType = 1

	-- 关闭按钮
	local closeBtn = gt.seekNodeByName(csbNode, "Btn_close")
	gt.addBtnPressedListener(closeBtn, function()

		--self.playType = 1
		self:removeFromParent()
	end)
    --[[
	local dismissRoomBtn = gt.seekNodeByName(csbNode, "Btn_dismissRoom")
	if playerSeatPos ~= "exit" then
		-- 解散按钮
		gt.addBtnPressedListener(dismissRoomBtn, function()
			self:removeFromParent()

			-- require("app/views/NoticeTips"):create(
			-- 	gt.getLocationString("LTKey_0011"),
			-- 	gt.getLocationString("LTKey_0021", gt.playerData.nickname),
			-- 	function()
			-- 		-- 发送申请解散房间消息
			-- 		local msgToSend = {}
			-- 		msgToSend.m_msgId = gt.CG_DISMISS_ROOM
			-- 		msgToSend.m_pos = playerSeatPos
			-- 		gt.socketClient:sendMessage(msgToSend)
			-- 	end)

			-- 发送申请解散房间消息
			local msgToSend = {}
			msgToSend.m_msgId = gt.CG_DISMISS_ROOM
			msgToSend.m_pos = playerSeatPos
			gt.socketClient:sendMessage(msgToSend)
		end)
	else
		dismissRoomBtn:setVisible(false)
	end
	--]]

	local dismissRoomBtn = gt.seekNodeByName(csbNode, "Btn_dismissRoom")
	local exit = gt.seekNodeByName(csbNode, "Btn_exit")
	if playerSeatPos ~= "exit" then
		dismissRoomBtn:setVisible(true)
		exit:setVisible(false)
		gt.addBtnPressedListener(dismissRoomBtn, function()
			self:removeFromParent()

			-- require("app/views/NoticeTips"):create(
			-- 	gt.getLocationString("LTKey_0011"),
			-- 	gt.getLocationString("LTKey_0021", gt.playerData.nickname),
			-- 	function()
			-- 		-- 发送申请解散房间消息
			-- 		local msgToSend = {}
			-- 		msgToSend.m_msgId = gt.CG_DISMISS_ROOM
			-- 		msgToSend.m_pos = playerSeatPos
			-- 		gt.socketClient:sendMessage(msgToSend)
			-- 	end)

			-- 发送申请解散房间消息
			local msgToSend = {}
			msgToSend.m_msgId = gt.CG_DISMISS_ROOM
			msgToSend.m_pos = playerSeatPos
			gt.socketClient:sendMessage(msgToSend)
		end)
	else
		dismissRoomBtn:setVisible(false)
		exit:setVisible(true)
		gt.addBtnPressedListener(exit, function()
			self:removeFromParent()
			if gt.socketClient.scheduleHandler then
				gt.scheduler:unscheduleScriptEntry( gt.socketClient.scheduleHandler )
			end
			gt.socketClient:close()

			cc.UserDefault:getInstance():setStringForKey("WX_Access_Token", "")
			cc.UserDefault:getInstance():setStringForKey("WX_Refresh_Token", "")
			cc.UserDefault:getInstance():setStringForKey("WX_Access_Token_Time", "")
			cc.UserDefault:getInstance():setStringForKey("WX_Refresh_Token_Time", "")
			cc.UserDefault:getInstance():setStringForKey("WX_OpenId", "")
			cc.UserDefault:getInstance():setStringForKey("WX_uuId", "")
			
			local loginScene = require("app/views/LoginScene"):create(true)
			cc.Director:getInstance():replaceScene(loginScene)
		end)
	end
	

	-- 音效调节
	local soundEftSlider = gt.seekNodeByName(csbNode, "Slider_soundEffect")
	local soundEftPercent = gt.soundEngine:getSoundEffectVolume()
	soundEftPercent = math.floor(soundEftPercent)
	soundEftSlider:setPercent(soundEftPercent)
	

	-- 音乐调节
	local musicSlider = gt.seekNodeByName(csbNode, "Slider_music")
	local musicPercent = gt.soundEngine:getMusicVolume()
	musicPercent = math.floor(musicPercent)
	musicSlider:setPercent(musicPercent)
	

	local Btn_minSound = gt.seekNodeByName(csbNode, "Btn_minSound")
	local Btn_maxSound = gt.seekNodeByName(csbNode, "Btn_maxSound")
	gt.addBtnPressedListener(Btn_minSound, function()
		soundEftSlider:setPercent(100)
		gt.soundEngine:setSoundEffectVolume(100)
		Btn_minSound:setVisible(false)
		Btn_maxSound:setVisible(true)
	end)


	gt.addBtnPressedListener(Btn_maxSound, function()
		soundEftSlider:setPercent(0)
		gt.soundEngine:setSoundEffectVolume(0)
		Btn_minSound:setVisible(true)
		Btn_maxSound:setVisible(false)
	end)

	local Btn_minSound1 = gt.seekNodeByName(csbNode, "Btn_minSound1")
	local Btn_maxSound1 = gt.seekNodeByName(csbNode, "Btn_maxSound1")
	gt.addBtnPressedListener(Btn_minSound1, function()
		musicSlider:setPercent(100)
		gt.soundEngine:setMusicVolume(100)
		Btn_minSound1:setVisible(false)
		Btn_maxSound1:setVisible(true)	
	end)

	
	gt.addBtnPressedListener(Btn_maxSound1, function()
		musicSlider:setPercent(0)
		gt.soundEngine:setMusicVolume(0)
		Btn_minSound1:setVisible(true)
		Btn_maxSound1:setVisible(false)
	end)

	
	if soundEftPercent <= 1 then
		Btn_minSound:setVisible(true)
		Btn_maxSound:setVisible(false)
	else
		Btn_minSound:setVisible(false)
		Btn_maxSound:setVisible(true)
	end

	if musicPercent <= 1 then
		Btn_minSound1:setVisible(true)
		Btn_maxSound1:setVisible(false)
	else
		Btn_minSound1:setVisible(false)
		Btn_maxSound1:setVisible(true)
	end

	soundEftSlider:addEventListener(function(sender, eventType)
		if eventType == ccui.SliderEventType.percentChanged then
			local soundEftPercent = soundEftSlider:getPercent()
			gt.soundEngine:setSoundEffectVolume(soundEftPercent)
			if soundEftPercent < 1 then
				Btn_minSound:setVisible(true)
				Btn_maxSound:setVisible(false)
			else
				Btn_minSound:setVisible(false)
				Btn_maxSound:setVisible(true)
			end
		end
	end)

	musicSlider:addEventListener(function(sender, eventType)
		if eventType == ccui.SliderEventType.percentChanged then
			local musicPercent = musicSlider:getPercent()
			gt.soundEngine:setMusicVolume(musicPercent)
			if musicPercent < 1 then
				Btn_minSound1:setVisible(true)
				Btn_maxSound1:setVisible(false)
			else
				Btn_minSound1:setVisible(false)
				Btn_maxSound1:setVisible(true)
			end
		end
	end)

end

function Setting:chooseShowDiceEvt(senderBtn, eventType)
	if eventType == ccui.CheckBoxEventType.selected then
		gt.log("我要掷骰子")
		cc.UserDefault:getInstance():setStringForKey("show_dice1", tostring(1))
		senderBtn:setSelected(true)
	elseif eventType == ccui.CheckBoxEventType.unselected then
		gt.log("我不要掷骰子")
		cc.UserDefault:getInstance():setStringForKey("show_dice1", tostring(2))
		senderBtn:setSelected(false)
	end
end

function Setting:choosePlayTypeEvt(senderBtn, eventType)
	if eventType == ccui.CheckBoxEventType.selected then
		gt.log("name: = " .. senderBtn:getName() .. " selected")
		local btnTag = senderBtn:getTag()
		--if btnTag == 1 or btnTag == 2 then
			-- 自摸胡和可抢杠胡玩法互斥
			if self.playType ~= btnTag then
				-- 恢复上一个玩法未选中状态
				local typeChkBox = gt.seekNodeByName(self, "CheckBox_btn" .. self.playType)
				typeChkBox:setSelected(false)
				
				self.playType = btnTag
			
			end
		--end
	elseif eventType == ccui.CheckBoxEventType.unselected then
		gt.log("name: = " .. senderBtn:getName() .. " unselected")
	end
end



function Setting:onNodeEvent(eventName)
	if "enter" == eventName then
		local listener = cc.EventListenerTouchOneByOne:create()
		listener:setSwallowTouches(true)
		listener:registerScriptHandler(handler(self, self.onTouchBegan), cc.Handler.EVENT_TOUCH_BEGAN)
		-- listener:registerScriptHandler(handler(self, self.onTouchEnded), cc.Handler.EVENT_TOUCH_ENDED)
		local eventDispatcher = self:getEventDispatcher()
		eventDispatcher:addEventListenerWithSceneGraphPriority(listener, self)
	elseif "exit" == eventName then
		local eventDispatcher = self:getEventDispatcher()
		eventDispatcher:removeEventListenersForTarget(self)
	end
end

function Setting:onTouchBegan(touch, event)
	return true
end

-- function Setting:onTouchEnded(touch, event)
-- 	self:removeFromParent()
-- end

return Setting
