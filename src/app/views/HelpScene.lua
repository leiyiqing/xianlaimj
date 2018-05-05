
local gt = cc.exports.gt

local HelpScene = class("HelpScene", function()
	return gt.createMaskLayer()
end)

function HelpScene:ctor()
	local csbNode = cc.CSLoader:createNode("HelpScene.csb")
	csbNode:setAnchorPoint(0.5, 0.5)
	csbNode:setPosition(gt.winCenter)
	self:addChild(csbNode)

	self.maxtype = 4
	self.csbNode = csbNode
	if gt.isIOSPlatform() and gt.isInReview then
		local spr = gt.seekNodeByName(csbNode, "Image_5")
		if spr then
			spr:setVisible(false)
		end
	end

	self.playType = 1
	self:choseT_DiType(self.playType)

	for i = 1 , self.maxtype do
		local PlayTypeChkBox = gt.seekNodeByName(self, "T_Di_tongyong_" .. i)
		PlayTypeChkBox:setTag(i)
		gt.addBtnPressedListener(PlayTypeChkBox,handler(self, self.chooseGameTypeEvt))
	end
	
	-- 返回按键
	local backBtn = gt.seekNodeByName(self, "Btn_back")
	gt.addBtnPressedListener(backBtn, function()
		self:removeFromParent()
	end)
end


--玩法选择南昌麻将，抚州麻将，萍乡麻将，赣州麻将
function HelpScene:chooseGameTypeEvt(senderBtn)
	local btnTag = senderBtn:getTag()
	if self.playType ~= btnTag then
		-- 恢复上一个玩法未选中状态
		local roundChkBox = gt.seekNodeByName(self, "T_Di_tongyong_" .. self.playType)
		self:choseT_DiType(btnTag)
		self.playType = btnTag
	end
end

function HelpScene:choseT_DiType(choosetype)
	self["bg1"] = gt.seekNodeByName(self, "ScrollView_help_cs")
	self["bg2"] = gt.seekNodeByName(self, "ScrollView_help_zz")
	self["bg3"] =gt.seekNodeByName(self, "ScrollView_help_px")
	self["bg4"]= gt.seekNodeByName(self, "ScrollView_help_gz")
	for i = 1 , self.maxtype do
		local spr = gt.seekNodeByName(self, "T_Di_" .. i)
		if i == choosetype then
			spr:setVisible(true)
			if self["bg" .. i ] then
				self["bg" .. i ]:setVisible(true)
			end		
		else
			spr:setVisible(false)
			if self["bg" .. i ] then
				self["bg" .. i ]:setVisible(false)
			end
		end
	end
end

return HelpScene