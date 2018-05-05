local gt = cc.exports.gt

local BuyCard = class("BuyCard", function()
	return gt.createMaskLayer()
end)

function BuyCard:ctor(state, tipsText)
	self:setName("BuyCard")
	gt.log("==4====")
	local csbNode = cc.CSLoader:createNode("BuyCard.csb")
	gt.log("==555===")
	csbNode:setPosition(gt.winCenter)
	self:addChild(csbNode, 100)
	
	local spr_buyCardTile1 = gt.seekNodeByName(csbNode, "Spr_buyCardTile1")
	local spr_buyCardTile2 = gt.seekNodeByName(csbNode, "Spr_buyCardTile2")

	local Label_buyCard1 = gt.seekNodeByName(csbNode, "Label_buyCard1")
	local Label_buyCard2 = gt.seekNodeByName(csbNode, "Label_buyCard2")

	if state == "1"then
		spr_buyCardTile1:setVisible(false)
		Label_buyCard1:setVisible(false)
		spr_buyCardTile2:setVisible(true)
		Label_buyCard2:setVisible(true)
		if tipsText then
			local strTab = string.split(tipsText, ",")
			local Label_4 = gt.seekNodeByName(Label_buyCard2, "Label_4")
			local Label_5 = gt.seekNodeByName(Label_buyCard2, "Label_5")
			local Label_6 = gt.seekNodeByName(Label_buyCard2, "Label_6")

			local str = nil
			math.randomseed(os.time())
			local n = math.random(0,50)
			if n < 10 then
				str = "xianlai102【官方微信】"
			elseif n < 20 then
				str = "jxmj588【官方微信】"
			elseif n < 30 then
				str = "majiang633【官方微信】"
			elseif n < 40 then
				str = "xianlai729【官方微信】"
			elseif n < 50 then
				str = "xianlai181【官方微信】"
			else
				str = "xianlai181【官方微信】"
			end



			
			local str1 = nil
			local n = math.random(0,70)
			if n < 10 then
				str1 = "【微信】xianlai727"
			elseif n < 20 then
				str1 = "【微信】xianlai2345"
			elseif n < 30 then
				str1 = "【微信】xianlai633"
			elseif n < 40 then
				str1 = "【微信】xianlai1937"
			elseif n < 50 then
				str1 = "【微信】xianlai728"
			elseif n < 60 then
				str1 = "【微信】majiang633"
			else
				str1 = "【微信】xianlai729"
			end


			local str2 = nil
			local n = math.random(0,70)
			if n < 10 then
				str2 = "【微信】xianlai727"
			elseif n < 20 then
				str2 = "【微信】xianlai2345"
			elseif n < 30 then
				str2 = "【微信】xianlai633"
			elseif n < 40 then
				str2 = "【微信】xianlai1937"
			elseif n < 50 then
				str2 = "【微信】xianlai728"
			elseif n < 60 then
				str2 = "【微信】majiang633"
			else
				str2 = "【微信】xianlai729"
			end

			-- strTab = {str1,str,str2}
			-- if strTab[1] then
			-- 	Label_4:setString("购卡微信:" .. strTab[1])
			-- else
			-- 	Label_4:setString("")
			-- end
			if strTab[1] then
				Label_4:setString("代理咨询: " .. str)
			else
				Label_4:setString("")
			end
			if strTab[2] then
				Label_5:setString("代理咨询:" .. str)
			else
				Label_5:setString("")
			end
			Label_5:setString("房卡问题咨询: xlncmj666【微信公众号】")
			-- Label_5:setVisible(false)
			if strTab[3] then
				Label_6:setString("投诉举报: " .. strTab[3])
			else
				Label_6:setString("")
			end
		end
	else
		spr_buyCardTile1:setVisible(true)
		Label_buyCard1:setVisible(true)
		spr_buyCardTile2:setVisible(false)
		Label_buyCard2:setVisible(false)
	end

	-- if tipsText then
	-- 	local tipsLabel = gt.seekNodeByName(csbNode, "Label_tips")
	-- 	tipsLabel:setString(tipsText)
	-- end

	local but_back = gt.seekNodeByName(csbNode, "But_back")
	gt.addBtnPressedListener(but_back, function()
		self:removeFromParent()
		
	end)

	local btn_buyCard = gt.seekNodeByName(csbNode, "Btn_buyCard")
	gt.addBtnPressedListener(btn_buyCard, function()
		gt.log("-----3----")
		
	end)


	local runningScene = cc.Director:getInstance():getRunningScene()
	if runningScene then
		runningScene:addChild(self, gt.CommonZOrder.NOTICE_TIPS)
	end
	
end

return BuyCard

