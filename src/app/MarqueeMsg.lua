
-- Creator ArthurSong
-- Create Time 2016/2/23

local gt = cc.exports.gt

local MarqueeMsg = class("MarqueeMsg", function()
	return cc.CSLoader:createNode("MarqueeBar.csb")
end)

function MarqueeMsg:ctor()
	self:registerScriptHandler(handler(self, self.onNodeEvent))

	self.msgTextCache = {}
	self.showNextMsg = true
end

function MarqueeMsg:onNodeEvent(eventName)
	if "enter" == eventName then
		self.scheduleHandler = gt.scheduler:scheduleScriptFunc(handler(self, self.update), 0, false)
	elseif "exit" == eventName then
		gt.scheduler:unscheduleScriptEntry(self.scheduleHandler)
	end
end

function MarqueeMsg:update(delta)
	if not self.showNextMsg then
		return
	end
	
	if #self.msgTextCache == 0 then
		return
	end

	self.showNextMsg = false

	local msgText = self.msgTextCache[1]
	-- table.remove(self.msgTextCache, 1)

	local msgBarPanel = gt.seekNodeByName(self, "Panel_bar")
	local barSize = msgBarPanel:getContentSize()
	local msgContentLabel = gt.createTTFLabel(msgText, 28)
	local textWidth = msgContentLabel:getContentSize().width
	msgContentLabel:setPosition(barSize.width + textWidth * 0.5, barSize.height * 0.5)
	msgBarPanel:addChild(msgContentLabel)

	msgContentLabel:stopAllActions()
	local moveToAction = cc.MoveTo:create(40, cc.p(-textWidth * 0.5, barSize.height * 0.5))
	local callFunc = cc.CallFunc:create(function(sender)
		self.showNextMsg = true
		sender:removeFromParent()
	end)
	msgContentLabel:runAction(cc.Sequence:create(moveToAction, callFunc))
end

function MarqueeMsg:showMsg(msgText)
	if not msgText or string.len(msgText) == 0 then
		return
	end

	table.insert(self.msgTextCache, msgText)
end

return MarqueeMsg

