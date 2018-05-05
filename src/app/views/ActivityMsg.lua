
local gt = cc.exports.gt

local ActivityMsg = class("ActivityMsg", function()
	return gt.createMaskLayer()
end)

function ActivityMsg:ctor()
	local csbNode = cc.CSLoader:createNode("ActivityMsg.csb")
	csbNode:setAnchorPoint(0.5, 0.5)
	csbNode:setPosition(gt.winCenter)
	self:addChild(csbNode)

	
	if gt.isIOSPlatform() and gt.isInReview then
		local spr = gt.seekNodeByName(csbNode, "Image_2")
		if spr then
			spr:setVisible(false)
		end
	end

	-- 返回按键
	local backBtn = gt.seekNodeByName(self, "Btn_back")
	gt.addBtnPressedListener(backBtn, function()
		self:removeFromParent()
	end)

	-- 暂无消息 :)
	local emptyLabel = gt.seekNodeByName(self, "Label_empty")
	if emptyLabel then
		emptyLabel:setVisible( false )
	end

	local scrollView_txt = gt.seekNodeByName(self, "ScrollView_msg")
	if scrollView_txt then
		-- scrollView_txt:setVisible( false )
	end
	local msgTxt = gt.seekNodeByName(scrollView_txt, "Text_msg")
	-- local showStr = "                	5.1玩家巨惠充值活动\n\n为了庆祝劳动节，感谢辛勤劳动的广大人民，4月30日-5月2日期间，我们推出玩家充值赠送活动。\n\n此活动不论在官方或者推广员那里充值都有效。\n\n单次充值10张－19张，赠送您3张房卡\n\n单次充值20张-29张，赠送6张房卡\n\n单次充值30张-39张，赠送9张房卡\n\n以此类推，单次充值1000张，赠送300张房卡。\n\n所有玩家均可参与此次活动，不设上限，活动日期仅限4月30日至5月2日。最终解释权归闲来所有"
	local showStr = "亲爱的玩家：\n\n    近期有玩家担心闲来麻将有游戏外挂，闲来麻将在此声明，本游戏绝无任何外挂，请各位玩家放心使用，切勿上当受骗； 请玩家文明游戏，远离赌博。\n\n    祝您在闲来麻将玩的开心！"
	msgTxt:setString(showStr)
end

return ActivityMsg

