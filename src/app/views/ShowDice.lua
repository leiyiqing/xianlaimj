--[[
	create by xxx
	time 2016-10-31
	description
		掷骰子界面,需要将消息传递进来
]]--
local gt = cc.exports.gt

local ShowDice = class("ShowDice", function()
	return cc.LayerColor:create(cc.c4b(0, 0, 0, 0), gt.winSize.width, gt.winSize.height)
end)

function ShowDice:ctor(msg, playerSeatIdx)
	self.playerSeatIdx = playerSeatIdx
	gt.log("----xxx----ShowDice----playerSeatIdx--->", playerSeatIdx)
	self.timeCount = 4
	-- 注册节点事件
	self:registerScriptHandler(handler(self, self.onNodeEvent))

	--初始化界面
	local csbNode = cc.CSLoader:createNode("ShowDice.csb")
	self:addChild(csbNode)
	self.rootNode = csbNode
	self.msgTbl = msg
	-- gt.dump(self.msgTbl)

	--给按钮添加回调函数
	local btn_dice = gt.seekNodeByName(self.rootNode, "Button_1")
	gt.addBtnPressedListener(btn_dice, function()
		--发消息通知服务端
		btn_dice:removeFromParent()
		local msgToSend = {}
		msgToSend.m_msgId = gt.CG_SHOW_DICE
		msgToSend.m_type = self.msgTbl.m_type + 1
		gt.socketClient:sendMessage(msgToSend)
		self:removeFromParent()
	end)
	
end

function ShowDice:updateMsg()
	self:resetView()
	if self.msgTbl.m_isReconect == 0 and self.msgTbl.m_OffLinePos + 1 ~= self.playerSeatIdx then
		gt.log("我不是断线重连消息，不处理消息..msgTbl.m_isReconect = 0")
		self:removeFromParent()
		return
	end
	--决定按钮的位置
	if self.msgTbl.m_type == 1 then
		local csbNode, animation = gt.createCSAnimation("paijukaishi.csb")
		csbNode:setTag(123)
		self:addChild(csbNode)
		animation:play("paijukaishi", false)
		self:runAction(cc.Sequence:create(cc.DelayTime:create(1.5) ,cc.CallFunc:create(
			function()
				self:getChildByTag(123):removeFromParent()
				self:updateView()
			end)))
	end

	if self.msgTbl.m_type == 3 then
		self:updateView()
	end

	--播放掷骰子动画
	if self.msgTbl.m_type == 2 or self.msgTbl.m_type == 4 then
		self:showAnimationOld()
	end
end

function ShowDice:showAnimationOld()
	self:showMaskLayer()
	local first_node = cc.Sprite:create()
	self:addChild(first_node)
	first_node:setPosition(cc.p(-80, 0))
	local second_node = cc.Sprite:create()
	self:addChild(second_node)
	second_node:setPosition(cc.p(80, 0))
	for j = 1 ,  2  do
		local animation = cc.Animation:create()
		local name = nil
		for i = 1, 10 do
			if i < 10 then
				name = "images/otherImages/shaizi/touzi_00" .. i .. ".png"
			else
				name = "images/otherImages/shaizi/touzi_0" .. i .. ".png"
			end
			animation:addSpriteFrameWithFile(name)
		end
		animation:setDelayPerUnit(2/20)
		animation:setRestoreOriginalFrame(true)
		animation:setLoops(2)
		local action = cc.Animate:create(animation)
		if j == 1 then
			first_node:runAction(action)
		elseif j == 2  then
			local function showShaiziCallBack( ... )
				first_node:removeFromParent()
				second_node:removeFromParent()
				local first_spr = cc.Sprite:create("images/otherImages/shaizi/touzi" .. self.msgTbl.m_number1 .. ".png")
				self:addChild(first_spr, 5)
				first_spr:setPosition(cc.p(-80, 0))
				local second_spr = cc.Sprite:create("images/otherImages/shaizi/touzi" .. self.msgTbl.m_number2 .. ".png")
				self:addChild(second_spr,5)
				second_spr:setPosition(cc.p(80, 0))
				
				local function startPlayCardCallBack()
					first_spr:removeFromParent()
					second_spr:removeFromParent()
					--删除界面
					--发消息
					--如果是本人发送，其他人不发送
					gt.log("动画播放完成-----self.msgTbl.m_userpos-----" .. self.msgTbl.m_userpos)
					gt.log("动画播放完成-----self.playerSeatIdx-----" .. self.playerSeatIdx)
					if self.msgTbl.m_userpos + 1 == self.playerSeatIdx then
						gt.log("我是操作者，要发送消息到服务端。。。。。。。。")
						local msgToSend = {}
						msgToSend.m_msgId = gt.CG_SHOW_DICE
						msgToSend.m_type = self.msgTbl.m_type + 1
						gt.socketClient:sendMessage(msgToSend)
					end
					self:hideMaskLayer()
					self:removeFromParent()
				end
				self:runAction(cc.Sequence:create(cc.DelayTime:create(1), cc.CallFunc:create(startPlayCardCallBack)))
			end
			second_node:runAction(cc.Sequence:create(action,cc.CallFunc:create(showShaiziCallBack)))
		end
	end
end

function ShowDice:showMaskLayer()
    local function onTouchBegan()
    	return true
    end
	self.maskLayer = cc.LayerColor:create(cc.c4b(85,85,85,85))
	self:addChild(self.maskLayer,80000)
	self.maskLayer:setAnchorPoint(cc.p(0.5, 0.5))
	self.maskLayer:setPosition(cc.p(-gt.winSize.width * 0.5, -gt.winSize.height * 0.5))
	local listener = cc.EventListenerTouchOneByOne:create()
	listener:registerScriptHandler(onTouchBegan, cc.Handler.EVENT_TOUCH_BEGAN)
	listener:setSwallowTouches(true)
	local eventDispatcher = self:getEventDispatcher()
	eventDispatcher:addEventListenerWithSceneGraphPriority(listener, self.maskLayer)
end

function ShowDice:hideMaskLayer()
    if self.maskLayer then
    	self.maskLayer:removeFromParent()
		self.maskLayer = nil
    end
end

--播放骰子动画，根据消息决定播放哪一个动画和点数
-- function ShowDice:showAnimation()
-- 	local seatId = self.msgTbl.m_userpos
-- 	local csbNode, animation = gt.createCSAnimation("show_dice_animation_"..seatId..".csb")
-- 	csbNode:setTag(123)
-- 	self:addChild(csbNode)
-- 	animation:play("dabao", false)
-- 	local function callBack()
-- 		--添加最后的停止时的两个精灵
-- 		local dice1 = gt.seekNodeByName(csbNode, "dice1")
-- 		dice1:setVisible(false)
-- 		local sp1 = cc.Sprite:create("images/otherImages/showDice" .. self.msgTbl.m_number1 .. ".png")
-- 		csbNode:addChild(sp1)
-- 		sp1:setPosition(dice1:getPositionX(), dice1:getPositionY())
-- 		sp1:setAnchorPoint(0.5,0.5)
-- 		sp1:setScale(0.8)
-- 		local dice2 = gt.seekNodeByName(csbNode, "dice2")
-- 		dice2:setVisible(false)
-- 		local sp2 = cc.Sprite:create("images/otherImages/showDice" .. self.msgTbl.m_number2 .. ".png")
-- 		csbNode:addChild(sp2)
-- 		sp2:setAnchorPoint(0.5,0.5)
-- 		sp2:setScale(0.8)
-- 		sp2:setPosition(dice2:getPositionX(), dice2:getPositionY())
-- 		sp2:runAction(cc.Sequence:create(cc.DelayTime:create(1), cc.CallFunc:create(
-- 			function()
-- 				--发消息
-- 				local msgToSend = {}
-- 				msgToSend.m_msgId = gt.CG_SHOW_DICE
-- 				msgToSend.m_type = self.msgTbl.m_type + 1
-- 				gt.socketClient:sendMessage(msgToSend)
-- 				gt.log("发消息到服务端----------" .. self.msgTbl.m_type + 1)
-- 				self:getChildByTag(123):removeFromParent()
-- 				self:getChildByTag(124):removeFromParent()
-- 				self:removeFromParent()
-- 			end	
-- 		)))
		
-- 	end
-- 	local a = cc.Sprite:create()
-- 	a:setTag(124)
-- 	self:addChild(a)
-- 	a:runAction(cc.Sequence:create(cc.DelayTime:create(0.8), cc.CallFunc:create(callBack)))
-- end

--每秒回调一次
function ShowDice:update()
	if self.msgTbl.m_userpos + 1 ~= self.playerSeatIdx then
		if self.scheduleHandler then
			gt.scheduler:unscheduleScriptEntry(self.scheduleHandler)
			self.scheduleHandler = nil
		end
		return
	end
	local sp = gt.seekNodeByName(self.rootNode, "Image_1")
	self.timeCount = self.timeCount - 1
	if sp:getChildByTag(125) then
		sp:getChildByTag(125):setString(self.timeCount)
	else
		local label1 = gt.createTTFLabel("", 48)
		label1:setAnchorPoint(cc.p(0.5, 0.5))
		label1:setTextColor(cc.c4b(255,248,190,255))
		gt.setTTFLabelStroke(label1, cc.c4b(158, 72, 24, 255), 2)
		sp:addChild(label1)
		label1:setPosition(sp:getPositionX()+125, sp:getPositionY()+10)
		label1:setTag(125)
		label1:setString(self.timeCount)
	end
	if self.timeCount <= 0 then
		--发消息通知服务端
		local msgToSend = {}
		msgToSend.m_msgId = gt.CG_SHOW_DICE
		msgToSend.m_type = self.msgTbl.m_type + 1
		gt.socketClient:sendMessage(msgToSend)
		if self.scheduleHandler then
			gt.scheduler:unscheduleScriptEntry(self.scheduleHandler)
			self.scheduleHandler = nil
		end
		self:removeFromParent()
	end
end


function ShowDice:updateView()
	local seatId = self.msgTbl.m_userpos + 1
	if seatId == self.playerSeatIdx then
		--自己掷骰子
		self.btn_node:setVisible(true)
		self.label_node:setVisible(false)
	else
		--不是自己掷骰子
		self.label_node:setVisible(true)
		self.btn_node:setVisible(false)
		local temp = gt.seekNodeByName(self.label_node, "show_dice_" .. self.msgTbl.m_userpos)
		temp:setVisible(true)
		temp:runAction(cc.Sequence:create(cc.DelayTime:create(4),cc.CallFunc:create(
			function()
				self:removeFromParent()
			end)))
	end

end

function ShowDice:resetView()
    --掷骰子按钮跟节点
	local btn_node = gt.seekNodeByName(self.rootNode, "btn_node")
	if btn_node then
		self.btn_node = btn_node
		btn_node:setVisible(false)
	end
	--显示跟节点
	local label_node = gt.seekNodeByName(self.rootNode, "label_node")
	if label_node then
		self.label_node = label_node
		label_node:setVisible(false)
	end
	--子节点不显示
	for i = 0, 3 do
		local temp = gt.seekNodeByName(self.rootNode, "show_dice_" .. i)
		if temp then
			temp:setVisible(false)
		end
	end
	local Sprite_2 = gt.seekNodeByName(self.rootNode, "Sprite_2")
	if Sprite_2 then
		Sprite_2:setVisible(false)
	end
end


function ShowDice:onNodeEvent(eventName)
	if "enter" == eventName then
		gt.log("----xxx----掷骰子消息协议----加载掷骰子模块---->")
		local listener = cc.EventListenerTouchOneByOne:create()
		listener:setSwallowTouches(true)
		listener:registerScriptHandler(handler(self, self.onTouchBegan), cc.Handler.EVENT_TOUCH_BEGAN)
		local eventDispatcher = self:getEventDispatcher()
		eventDispatcher:addEventListenerWithSceneGraphPriority(listener, self)
		self.scheduleHandler = gt.scheduler:scheduleScriptFunc(handler(self, self.update), 1, false)
	elseif "exit" == eventName then
		gt.log("----xxx----掷骰子消息协议----卸载掷骰子模块---->")
		local eventDispatcher = self:getEventDispatcher()
		eventDispatcher:removeEventListenersForTarget(self)
		if self.scheduleHandler then
			gt.scheduler:unscheduleScriptEntry(self.scheduleHandler)
			self.scheduleHandler = nil
		end
	end
end

function ShowDice:onTouchBegan(touch, event)
	return true
end

return ShowDice



