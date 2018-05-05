
local gt = cc.exports.gt

local NoticeTips = class("NoticeTips", function()
	return gt.createMaskLayer()
end)

function NoticeTips:ctor(titleText, tipsText, okFunc, cancelFunc, singleBtn)
	self:setName("NoticeTips")

	local csbNode = cc.CSLoader:createNode("NoticeTips.csb")
	if titleText == "firstdenglu" then
		csbNode = cc.CSLoader:createNode("FirstTip.csb")
		titleText = nil
		local okBtn = gt.seekNodeByName(csbNode, "Btn_ok")
		okBtn:setVisible(false)
	end
	csbNode:setPosition(gt.winCenter)
	self:addChild(csbNode)

	if titleText then
		local titleLabel = gt.seekNodeByName(csbNode, "Label_title")
		titleLabel:setString(titleText)
	end

	if tipsText then
		local tipsLabel = gt.seekNodeByName(csbNode, "Label_tips")
		tipsLabel:setString(tipsText)
		if titleText  == "补偿公告" then
			tipsLabel:setFontSize(28)
		end
	end

	local okBtn = gt.seekNodeByName(csbNode, "Btn_ok")
	gt.addBtnPressedListener(okBtn, function()
		self:removeFromParent()
		if okFunc then
			okFunc()
		end
	end)

	local cancelBtn = gt.seekNodeByName(csbNode, "Btn_cancel")
	gt.addBtnPressedListener(cancelBtn, function()
		self:removeFromParent()
		if cancelFunc then
			cancelFunc()
		end
	end)

	if singleBtn then
		okBtn:setPositionX(0)
		cancelBtn:setVisible(false)
	end

	if titleText == "firstdenglu" then
		local okBtn = gt.seekNodeByName(csbNode, "Btn_ok")
		okBtn:setVisible(false)
		cancelBtn:setVisible(true)
	end

	local runningScene = cc.Director:getInstance():getRunningScene()
	if runningScene then
		runningScene:addChild(self, gt.CommonZOrder.NOTICE_TIPS)
	end
end

return NoticeTips

