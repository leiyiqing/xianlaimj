
local gt = cc.exports.gt

local RoundReport = class("RoundReport", function()
	return cc.Layer:create()
end)

function RoundReport:ctor(msgTbl, roomPlayers, playerSeatIdx, seatOffset, islast, paramTbl)
	self.seatOffset = seatOffset
	-- 注册节点事件
	self:registerScriptHandler(handler(self, self.onNodeEvent))

	local csbNode = cc.CSLoader:createNode("RoundReport.csb")
	csbNode:setAnchorPoint(0.5, 0.5)
	csbNode:setPosition(gt.winCenter)
	self:addChild(csbNode)

	gt.dump(msgTbl)
	gt.log("-------55---")
	local sprtilewin = gt.seekNodeByName(csbNode, "Spr_winTitle")
	local sprtilefail = gt.seekNodeByName(csbNode, "Spr_loseTitle")
	local sprtileliuju = gt.seekNodeByName(csbNode, "Spr_liujuTitle")
	sprtilewin:setVisible(false)
	sprtilefail:setVisible(true)
	sprtileliuju:setVisible(false)
	if msgTbl.m_result == 2 then
		-- 流局
		sprtileliuju:setVisible(true)
		sprtilewin:setVisible(false)
		sprtilefail:setVisible(false)
	else
		for i = 1, 4 do
			if playerSeatIdx == i and (msgTbl.m_win[i] == 1  or msgTbl.m_win[i] == 2) then
				sprtilewin:setVisible(true)
				sprtilefail:setVisible(false)
				sprtileliuju:setVisible(false)
				break
			end
		end
	end




	if paramTbl then
		local typename = ""
		local ncname = ""
		local description = ""
		local playtype = ""
		
		if tonumber(paramTbl.totulType) == 1 then
			typename = "南昌麻将 "
			local dianpao = ""
			if tonumber(paramTbl.dianpaoType) == 1 then
				dianpao = "点炮三家付"
			elseif tonumber(paramTbl.dianpaoType) == 2 then
				dianpao = "点炮一家付"
			end

			local bawang = ""
			if tonumber(paramTbl.bawang) == 1 then
				bawang = "霸王+10"
			elseif tonumber(paramTbl.bawang) == 2 then
				bawang = "霸王x2"
			end

			local qjname = ""
			if tonumber(paramTbl.qjtype) == 1 then
				qjname = "打出精牌不算分"
			elseif tonumber(paramTbl.qjtype) == 2 then
				qjname = "打出精牌算分"
			end

			
			if tonumber(gt.cardType) == 1 then
				ncname = "无下精"
				-- description = string.format("【闲来南昌麻将】房号:[%d]，%d局，%s，%s，%s，无下精玩法!", self.roomID, paramTbl.roundMaxCount, "闲来南昌麻将",dianpao)
			elseif tonumber(gt.cardType) == 2 then
				ncname = "埋地雷"
				-- description = string.format("【闲来南昌麻将】房号:[%d]，%d局，%s，%s，埋地雷玩法!", self.roomID, paramTbl.roundMaxCount, "闲来南昌麻将",dianpao)
			elseif tonumber(gt.cardType) == 3 then
					ncname = "回头一笑"
				-- description = string.format("【闲来南昌麻将】房号:[%d]，%d局，%s，%s，回头一笑玩法!", self.roomID, paramTbl.roundMaxCount, "闲来南昌麻将",dianpao)
			elseif tonumber(gt.cardType) == 4 then
					ncname = "回头上下翻"
				-- description = string.format("【闲来南昌麻将】房号:[%d]，%d局，%s，%s，回头上下翻玩法!", self.roomID, paramTbl.roundMaxCount, "闲来南昌麻将",dianpao)
			elseif tonumber(gt.cardType) == 5 then
					ncname = "同一首歌"
				-- description = string.format("【闲来南昌麻将】房号:[%d]，%d局，%s，%s，同一首歌玩法!", self.roomID, paramTbl.roundMaxCount, "闲来南昌麻将",dianpao)
			end
			local difen = ""
			
			if tonumber(paramTbl.m_ncDi) == 1 then
				difen = "底分：1"
			elseif tonumber(paramTbl.m_ncDi) == 2 then
				difen = "底分：4"
			end
			playtype = string.format("%s %s\n%s %s",dianpao,difen,bawang,qjname)
			typename = typename .. ncname
		elseif tonumber(paramTbl.totulType) == 2 then 
				typename = "抚州包杠 "
			local fanshu = ""
			if tonumber(paramTbl.m_anGangFanShu) == 1 then
				fanshu = "两番杠"
			elseif tonumber(paramTbl.m_anGangFanShu) == 2 then
				fanshu = "三番杠"
			end
			local lanjie = ""
			if tonumber(paramTbl.m_kongZhongLanJie) == 1 then
				lanjie = "空中拦截"
			elseif tonumber(paramTbl.m_kongZhongLanJie) == 2 then
				lanjie = "无空中拦截"
			end
			
			playtype = string.format("%s",fanshu)
			typename = typename .. lanjie
		elseif tonumber(paramTbl.totulType) == 3 then 
				typename = "萍乡258"
			local difen = ""
			if tonumber(paramTbl.m_pxDifen) == 1 then
				difen = "底分：1"
			elseif tonumber(paramTbl.m_pxDifen) == 2 then
				difen = "底分：5"

			elseif tonumber(paramTbl.m_pxDifen) == 3 then
				difen = "底分：10"
			end
			playtype = string.format("%s",difen)
		elseif tonumber(paramTbl.totulType) == 4 then 
				typename = "赣州冲关"
			local  dianpao = ""
			if tonumber(paramTbl.dianpaoType) == 1 then
				dianpao = "点炮三家付"
			elseif tonumber(paramTbl.dianpaoType) == 2 then
				dianpao = "点炮一家付"
			end
			local fanshu = ""
			if tonumber(paramTbl.m_fanshu) == 1 then
				fanshu = "必精吊"
			elseif tonumber(paramTbl.m_fanshu) == 2 then
				fanshu = "可平胡"
			end
			playtype = string.format("%s\n%s",dianpao,fanshu)
			typename = typename .. " 上下翻精"
		elseif tonumber(paramTbl.totulType) == 5 then 
			typename = "赣州三人"
		end

		local gametitle = gt.seekNodeByName(csbNode, "gametitle")
		gametitle:setString(playtype)
		local Label_gametype = gt.seekNodeByName(csbNode, "gametype")


		Label_gametype:setString(typename)

	end
	
	

	local Spr_upmj = gt.seekNodeByName(csbNode, "Spr_upmj")
	local Img_upcard = gt.seekNodeByName(csbNode, "Img_upcard")
	local Img_downcard = gt.seekNodeByName(csbNode, "Img_downcard")
	local Img_huitou = gt.seekNodeByName(csbNode, "Img_huitou")
	local Img_xiafan_2 = gt.seekNodeByName(csbNode, "Img_xiafan_2")
	local Spr_downmj = gt.seekNodeByName(csbNode, "Spr_downmj")
	local Img_xiafan = gt.seekNodeByName(csbNode, "Img_xiafan")
	local Spr_xiafan = gt.seekNodeByName(csbNode, "Spr_xiafan")
	local Img_tongyishouge = gt.seekNodeByName(csbNode, "Img_tongyishouge")
	

	local Label_gametype = gt.seekNodeByName(csbNode, "gametype")


	if gt.playType == 1 then
		if gt.cardType == 1 then
			Label_gametype:setString("无下精")
		elseif gt.cardType == 2 then
			Label_gametype:setString("埋地雷")
		elseif gt.cardType == 3 then
			Label_gametype:setString("回头一笑")
		elseif gt.cardType == 4 then
			Label_gametype:setString("回头上下翻")
		elseif gt.cardType == 5 then
			Label_gametype:setString("同一首歌")
		end
		
	elseif gt.playType == 2 then
		if gt.fuzhouType == 1 then
			Label_gametype:setString("空中拦截")
		elseif gt.fuzhouType == 2 then
			Label_gametype:setString("无空中拦截")
		end
	
	elseif gt.playType == 3 then
		Label_gametype:setString("萍乡258")

	elseif gt.playType == 4 then 
		if paramTbl.m_ncPlayType == 2 then
			Label_gametype:setString("上下左右翻")
		elseif paramTbl.m_ncPlayType == 1 then
			Label_gametype:setString("上下翻精")
		end
	elseif gt.playType == 5 then 
		if paramTbl.m_ncPlayType == 2 then
			Label_gametype:setString("上下左右翻")
		elseif paramTbl.m_ncPlayType == 1 then
			Label_gametype:setString("上下翻精")
		end
	end

	Img_downcard:setVisible(false)
	Img_huitou:setVisible(false)
	Img_xiafan_2:setVisible(false)
	Spr_downmj:setVisible(false)
	Img_xiafan:setVisible(false)
	Spr_xiafan:setVisible(false)
	Img_tongyishouge:setVisible(false)
	if gt.playType ~=1 and gt.playType ~= 4 and gt.playType ~= 5 then
		gt.cardType = 0
		msgTbl.m_jcard = {}
		Spr_upmj:setVisible(false)
		Img_upcard:setVisible(false)
	end
	if #msgTbl.m_jcard > 0 then
		Spr_upmj:setSpriteFrame(string.format("p4s%d_%d.png", msgTbl.m_jcard[1][1], msgTbl.m_jcard[1][2]))
		Spr_upmj:setScale(0.7)
	end
	if gt.cardType == 1 then
	elseif gt.cardType == 2 then
		Spr_downmj:setVisible(true)
		Img_downcard:setVisible(true)
		--原来的逻辑
		if #msgTbl.m_jcard > 0 then
			Spr_downmj:setSpriteFrame(string.format("p4s%d_%d.png", msgTbl.m_jcard[3][1], msgTbl.m_jcard[3][2]))
			Spr_downmj:setScale(0.7)
		end

	elseif gt.cardType == 3 then
		if # msgTbl.m_backYourEyeCards > 0 and msgTbl.m_backYourEyeCards[1][1] ~= 0 then
			Img_huitou:setVisible(true)
			Spr_downmj:setVisible(true)
			Spr_downmj:setSpriteFrame(string.format("p4s%d_%d.png", msgTbl.m_backYourEyeCards[1][1], msgTbl.m_backYourEyeCards[1][2]))
			Spr_downmj:setScale(0.7)
		end
	elseif gt.cardType == 4 then
		if # msgTbl.m_backYourEyeCards > 0 and msgTbl.m_backYourEyeCards[1][1] ~= 0 then
			Img_huitou:setVisible(true)
			Spr_downmj:setVisible(true)
			Spr_downmj:setSpriteFrame(string.format("p4s%d_%d.png", msgTbl.m_backYourEyeCards[1][1], msgTbl.m_backYourEyeCards[1][2]))
			Spr_downmj:setScale(0.7)
			if # msgTbl.m_backYourEyeCards_sx > 0 and msgTbl.m_backYourEyeCards_sx[1][1] ~= 0 then
				Img_xiafan:setVisible(true)
				Spr_xiafan:setVisible(true)
				Spr_xiafan:setSpriteFrame(string.format("p4s%d_%d.png", msgTbl.m_backYourEyeCards_sx[1][1], msgTbl.m_backYourEyeCards_sx[1][2]))
				Spr_xiafan:setScale(0.7)

				Img_upcard:setPosition(cc.p(866.84,681.64))
				Spr_upmj:setPosition(cc.p(939.72,681.64))
				Img_huitou:setPosition(cc.p(1012.81,681.64))
				Img_huitou:setAnchorPoint(0.5,0.5)
				Spr_downmj:setPosition(cc.p(1084.48,681.64))
				Img_xiafan:setPosition(cc.p(1158.92,681.64))
				Spr_xiafan:setPosition(cc.p(1231.24,681.64))
			end
		else
			Img_xiafan_2:setVisible(true)
			Spr_downmj:setVisible(true)
			if # msgTbl.m_backYourEyeCards_sx > 0 and msgTbl.m_backYourEyeCards_sx[1][1] ~= 0 then
				Spr_downmj:setSpriteFrame(string.format("p4s%d_%d.png", msgTbl.m_backYourEyeCards_sx[1][1], msgTbl.m_backYourEyeCards_sx[1][2]))
				Spr_downmj:setScale(0.7)
			end
		end
		local Img_downcard = gt.seekNodeByName(csbNode, "Img_downcard")
		Img_downcard:setVisible(false)
	elseif gt.cardType == 5 then
		if #msgTbl["m_theSongJCard1"] > 0 and msgTbl["m_theSongJCard1"][1][1] ~= 0 then

			Img_tongyishouge:setVisible(true)
			Spr_xiafan:setVisible(true)
			Spr_xiafan:setSpriteFrame(string.format("p4s%d_%d.png", msgTbl["m_theSongJCard1"][1][1], msgTbl["m_theSongJCard1"][1][2]))
			Spr_xiafan:setScale(0.7)
		end
	end

	--刷新最上方，精牌的展示
	if (paramTbl.m_jxPlayType == 4 or paramTbl.m_jxPlayType == 5) and paramTbl.m_ncPlayType == 2 then
		gt.log("*****************s我要进行上下左右翻")
		--设置界面的显示
		local node = gt.seekNodeByName(self, "tile_node_ganzhou")
		node:setVisible(true)

		local Img_upcard = gt.seekNodeByName(self, "Img_upcard")
		Img_upcard:setVisible(false)
		local Spr_downmj = gt.seekNodeByName(self, "Spr_downmj")
		Spr_downmj:setVisible(false)
		local Spr_upmj = gt.seekNodeByName(self, "Spr_upmj")
		Spr_upmj:setVisible(false)
		local Img_downcard = gt.seekNodeByName(self, "Img_downcard")
		Img_downcard:setVisible(false)
		
		--数据刷新
		local Spr_shang_gan_zhou = gt.seekNodeByName(node, "Spr_shang")
		-- local a_shang = cc.Sprite:createWithSpriteFrameName(string.format("p4s%d_%d.png", msgTbl.m_jcard[1][1], msgTbl.m_jcard[1][2]))
		-- Spr_shang_gan_zhou:addChild(a_shang)
		Spr_shang_gan_zhou:setSpriteFrame(cc.SpriteFrameCache:getInstance():getSpriteFrame(string.format("p4s%d_%d.png", msgTbl.m_jcard[1][1], msgTbl.m_jcard[1][2])))
		Spr_shang_gan_zhou:setScale(0.7)

		local Spr_xia_gan_zhou = gt.seekNodeByName(node, "Spr_xia")
		-- local a_xia = cc.Sprite:createWithSpriteFrameName(string.format("p4s%d_%d.png", msgTbl.m_shangXiaZuoYouJCard1[1][1], msgTbl.m_shangXiaZuoYouJCard1[1][2]))
		-- Spr_xia_gan_zhou:addChild(a_xia)
		Spr_xia_gan_zhou:setSpriteFrame(cc.SpriteFrameCache:getInstance():getSpriteFrame(string.format("p4s%d_%d.png", msgTbl.m_shangXiaZuoYouJCard1[1][1], msgTbl.m_shangXiaZuoYouJCard1[1][2])))
		Spr_xia_gan_zhou:setScale(0.7)
		
		local Spr_zuo_gan_zhou = gt.seekNodeByName(node, "Spr_zuo")
		-- local a_zuo = cc.Sprite:createWithSpriteFrameName(string.format("p4s%d_%d.png", msgTbl.m_shangXiaZuoYouJCard2[1][1], msgTbl.m_shangXiaZuoYouJCard2[1][2]))
		-- Spr_zuo_gan_zhou:addChild(a_zuo)
		Spr_zuo_gan_zhou:setSpriteFrame(cc.SpriteFrameCache:getInstance():getSpriteFrame(string.format("p4s%d_%d.png", msgTbl.m_shangXiaZuoYouJCard2[1][1], msgTbl.m_shangXiaZuoYouJCard2[1][2])))
		Spr_zuo_gan_zhou:setScale(0.7)

		local Spr_you_gan_zhou = gt.seekNodeByName(node, "Spr_you")
		-- local a_you = cc.Sprite:createWithSpriteFrameName(string.format("p4s%d_%d.png", msgTbl.m_shangXiaZuoYouJCard3[1][1], msgTbl.m_shangXiaZuoYouJCard3[1][2]))
		-- Spr_you_gan_zhou:addChild(a_you)
		Spr_you_gan_zhou:setSpriteFrame(cc.SpriteFrameCache:getInstance():getSpriteFrame(string.format("p4s%d_%d.png", msgTbl.m_shangXiaZuoYouJCard3[1][1], msgTbl.m_shangXiaZuoYouJCard3[1][2])))
		Spr_you_gan_zhou:setScale(0.7)
	elseif (paramTbl.m_jxPlayType == 4 or paramTbl.m_jxPlayType == 5) and paramTbl.m_ncPlayType == 1 then
		gt.log("*********我是上下翻精")
		--设置界面的显示
		local node = gt.seekNodeByName(self, "tile_node_ganzhou")
		node:setVisible(false)
		local Img_upcard = gt.seekNodeByName(self, "Img_upcard")
		Img_upcard:setVisible(true)
		local Spr_downmj = gt.seekNodeByName(self, "Spr_downmj")
		Spr_downmj:setVisible(true)
		local Spr_upmj = gt.seekNodeByName(self, "Spr_upmj")
		Spr_upmj:setVisible(true)
		local Img_downcard = gt.seekNodeByName(self, "Img_downcard")
		Img_downcard:setVisible(true)
		--刷新数据
		
		Spr_upmj:setSpriteFrame(cc.SpriteFrameCache:getInstance():getSpriteFrame(string.format("p4s%d_%d.png", msgTbl.m_jcard[1][1], msgTbl.m_jcard[1][2])))
		Spr_upmj:setScale(0.7)
		Spr_downmj:setSpriteFrame(cc.SpriteFrameCache:getInstance():getSpriteFrame(string.format("p4s%d_%d.png", msgTbl.m_jcard[3][1], msgTbl.m_jcard[3][2])))
		Spr_downmj:setScale(0.7)
	else
		gt.log("***********我不是赣州*******")
		--设置界面的显示
		local node = gt.seekNodeByName(self, "tile_node_ganzhou")
		node:setVisible(false)
		-- local Img_upcard = gt.seekNodeByName(self, "Img_upcard")
		-- Img_upcard:setVisible(true)
		-- local Spr_downmj = gt.seekNodeByName(self, "Spr_downmj")
		-- Spr_downmj:setVisible(true)
		-- local Spr_upmj = gt.seekNodeByName(self, "Spr_upmj")
		-- Spr_upmj:setVisible(true)
		-- local Img_downcard = gt.seekNodeByName(self, "Img_downcard")
		-- Img_downcard:setVisible(true)
	end

	self.maxPlayer = 4
	if paramTbl.m_jxPlayType == 5 then
		self.maxPlayer = 3
		local node_playerReport = gt.seekNodeByName(csbNode, "Node_playerReport_4")
		node_playerReport:setVisible(false)
	end

	for i = 1, self.maxPlayer  do
		local node_playerReport = gt.seekNodeByName(csbNode, "Node_playerReport_" .. i)
		local majong_bg = gt.seekNodeByName(node_playerReport, "majong_bg")
		local holdmj = msgTbl["array" .. (i - 1)]
		--玩家名字
		local roomPlayer  =  roomPlayers[i]
		local nickname = gt.seekNodeByName(node_playerReport, "Label_nickname")
		nickname:setString(roomPlayer.nickname)

		--庄
		local zhuang = gt.seekNodeByName(node_playerReport, "Spr_bankerSign")
		if msgTbl.m_zhuangPos == i - 1 then
			zhuang:setVisible(true)
		else
			zhuang:setVisible(false)
		end

		--玩家分数
		local score = gt.seekNodeByName(node_playerReport, "Label_score")
		local scorenum = ""
		if gt.playType == 1 or gt.playType == 3 or gt.playType == 4 or gt.playType == 5 then
			scorenum = msgTbl.m_scoreSum[i]
		elseif gt.playType == 2 then
			scorenum = msgTbl.m_fuZhouScoreSum[i]
		end

		if tonumber(scorenum) > 0 then
			score:setString("+" .. scorenum)
		else
			score:setString(scorenum)
		end

		local spr_winSign = gt.seekNodeByName(node_playerReport, "Spr_winSign")
		
		
		local node_info = gt.seekNodeByName(node_playerReport , "Node_info")
		local Txt_hupaifen = gt.seekNodeByName(node_info, "Txt_hupaifen")
		Txt_hupaifen:setString("")
		if tonumber(msgTbl.m_huScoreSum[i]) >= 0 then
			Txt_hupaifen:setString("+" .. msgTbl.m_huScoreSum[i])
		else
			Txt_hupaifen:setString(msgTbl.m_huScoreSum[i])
		end
	
		local Txt_shang = gt.seekNodeByName(node_info, "Txt_shang")
		Txt_shang:setString("")
		if tonumber(msgTbl.m_shangJings[i]) >= 0 then
			Txt_shang:setString("+" .. msgTbl.m_shangJings[i])
		else
			Txt_shang:setString(msgTbl.m_shangJings[i])
		end

		local Txt_xia = gt.seekNodeByName(node_info, "Txt_xia")
		Txt_xia:setString("")
		local Txt_reward = gt.seekNodeByName(node_info, "Txt_reward")
		Txt_reward:setString("")
		local Spr_huitou_sx = gt.seekNodeByName(node_info, "Spr_huitou_sx")
		Spr_huitou_sx:setVisible(false)

		local Spr_huitou = gt.seekNodeByName(node_info, "Spr_huitou")
		Spr_huitou:setVisible(false)

		local Spr_xia = gt.seekNodeByName(node_info, "Spr_xia")
		Spr_xia:setVisible(false)

		local Spr_sange = gt.seekNodeByName(node_info, "Spr_sange")
		Spr_sange:setVisible(false)

		local Spr_sige = gt.seekNodeByName(node_info, "Spr_sige")
		Spr_sige:setVisible(false)

		-- local mahjongBg = gt.seekNodeByName(node_playerReport, "majong_bg")
		-- mahjongBg:setVisible(false)

		if gt.playType ~= 1 and gt.playType ~= 4 and gt.playType ~= 5 then
			local Spr_shang = gt.seekNodeByName(node_info, "Spr_shang")
			Spr_shang:setVisible(false)
			local Txt_shang = gt.seekNodeByName(node_info, "Txt_shang")
			Txt_shang:setVisible(false)
			local Spr_reward = gt.seekNodeByName(node_info, "Spr_reward")
			Spr_reward:setVisible(false)
			local Txt_reward = gt.seekNodeByName(node_info, "Txt_reward")
			Txt_reward:setVisible(false)

			local Spr_hupaifen = gt.seekNodeByName(node_info, "Spr_hupaifen")
			Spr_hupaifen:setVisible(false)
			local Txt_hupaifen = gt.seekNodeByName(node_info, "Txt_hupaifen")
			Txt_hupaifen:setVisible(false)
			local Label_score = gt.seekNodeByName(node_playerReport, "Label_score")
			Label_score:setPosition(cc.p(1082,510))

		end

		if gt.cardType == 1 then
			
		elseif gt.cardType == 2 then
			Spr_xia:setVisible(true)
			local Spr_reward = gt.seekNodeByName(node_info, "Spr_reward")
			if tonumber(msgTbl.m_xiaJings[i]) >= 0 then
				Txt_xia:setString("+" .. msgTbl.m_xiaJings[i])
			else
				Txt_xia:setString(msgTbl.m_xiaJings[i])
			end
		elseif gt.cardType == 3 then
			Spr_huitou:setVisible(true)
			if tonumber(msgTbl.m_backYourEyeScores[i]) >= 0 then
				Txt_xia:setString("+" .. msgTbl.m_backYourEyeScores[i])
			else
				Txt_xia:setString(msgTbl.m_backYourEyeScores[i])
			end
		elseif gt.cardType == 4 then
			Spr_huitou_sx:setVisible(true)
			Spr_huitou_sx:setPosition(cc.p(-193.00,-66.02))

			local Spr_shang = gt.seekNodeByName(node_info, "Spr_shang")
			Spr_shang:setPosition(cc.p(-169.43,-31.02))

			local score1 = nil
			local score2 = nil
			if tonumber(msgTbl.m_backYourEyeScores[i]) >= 0 then
				score1 = "+" .. msgTbl.m_backYourEyeScores[i] 
			else
				score1 = "" .. msgTbl.m_backYourEyeScores[i] 
			end


			if tonumber(msgTbl.m_backYourEyeScores_sx[i]) >= 0 then
				score2 = " +" .. msgTbl.m_backYourEyeScores_sx[i] 
			else
				score2 = " " .. msgTbl.m_backYourEyeScores_sx[i] 
			end

			Txt_xia:setString(score1 .. score2)
		elseif gt.cardType == 5 then
			gt.log("====="..# msgTbl["m_theSongJCard1"])
			gt.log("====="..msgTbl["m_theSongJCard1"][1][1])
			if # msgTbl["m_theSongJCard1"] > 0 and msgTbl["m_theSongJCard1"][1][1] ~= 4 then
				Spr_sange:setVisible(true)
			else
				Spr_sige:setVisible(true)
			end
			if tonumber(msgTbl.m_theSongScores[i]) >= 0 then
				Txt_xia:setString("+" .. msgTbl.m_theSongScores[i])
			else
				Txt_xia:setString(msgTbl.m_theSongScores[i])
			end
		end
		
		if tonumber(msgTbl.m_jingScoreSum[i]) >= 0 then
			Txt_reward:setString("+" .. msgTbl.m_jingScoreSum[i])
		else
			Txt_reward:setString(msgTbl.m_jingScoreSum[i])
		end

		local width = 60
		local distance = 35
		--持有牌
		if #holdmj > 0 then
			for j = 1, #holdmj do
				local mjTileName = string.format("p4s%d_%d.png", holdmj[j][1], holdmj[j][2])
				local mjTileSpr = cc.Sprite:createWithSpriteFrameName(mjTileName)
				mjTileSpr:setScale(0.7)
				mjTileSpr:setPosition(cc.p(width, mjTileSpr:getContentSize().height * 0.4))
				width = width + distance
				majong_bg:addChild(mjTileSpr)
			end
		end


		--吃
		local m_ccards = msgTbl["m_ccards" .. (i - 1)]
		if #m_ccards > 0 then
			width = width + 20
			for j = 1, #m_ccards do
				local mjTileName = string.format("p4s%d_%d.png", m_ccards[j][1], m_ccards[j][2])
				local mjTileSpr = cc.Sprite:createWithSpriteFrameName(mjTileName)
				mjTileSpr:setScale(0.7)
				mjTileSpr:setPosition(cc.p(width, mjTileSpr:getContentSize().height * 0.4))
				if j % 3 == 0 and j ~= #m_ccards then
					width = width + distance + 20
				else
					width = width + distance
				end
				majong_bg:addChild(mjTileSpr)
			end
		end


		--碰
		local m_pcards = msgTbl["m_pcards" .. (i - 1)]
		if #m_pcards > 0 then
			width = width + 20
			for j = 1, #m_pcards do
				local mjTileName = string.format("p4s%d_%d.png", m_pcards[j][1], m_pcards[j][2])
				local mjTileSpr = cc.Sprite:createWithSpriteFrameName(mjTileName)
				mjTileSpr:setScale(0.7)
				mjTileSpr:setPosition(cc.p(width, mjTileSpr:getContentSize().height * 0.4))
				if j ~= #m_pcards and j % 3 == 0 then
					width = width + distance + 20
				else
					width = width + distance
				end
				majong_bg:addChild(mjTileSpr)
			end
		end

		--暗杠
		local m_acards = msgTbl["m_acards" .. (i - 1)]
		if #m_acards > 0 then
			width = width + 20
			for j = 1, #m_acards do
				local mjTileName = string.format("p4s%d_%d.png", m_acards[j][1], m_acards[j][2])
				local mjTileSpr = cc.Sprite:createWithSpriteFrameName(mjTileName)
				mjTileSpr:setScale(0.7)
				mjTileSpr:setPosition(cc.p(width, mjTileSpr:getContentSize().height * 0.4))
				if j ~= #m_acards and j % 4 == 0 then
					width = width + distance + 20
				else
					width = width + distance
				end
				majong_bg:addChild(mjTileSpr)
			end
		end
		--明杠
		local m_mcards = msgTbl["m_mcards" .. (i - 1)]
		if #m_mcards > 0 then
			width = width + 20
			for j = 1, #m_mcards do
				local mjTileName = string.format("p4s%d_%d.png", m_mcards[j][1], m_mcards[j][2])
				local mjTileSpr = cc.Sprite:createWithSpriteFrameName(mjTileName)
				mjTileSpr:setScale(0.7)
				mjTileSpr:setPosition(cc.p(width, mjTileSpr:getContentSize().height * 0.4))
				if j ~= #m_mcards and j % 4 == 0 then
					width = width + distance + 20
				else
					width = width + distance
				end
				majong_bg:addChild(mjTileSpr)
			end
		end	

		if tonumber(msgTbl.m_win[i]) == 2 or tonumber(msgTbl.m_win[i]) == 1 then
			spr_winSign:setVisible(true)
			
			if #msgTbl.m_hucards > 0 then
				local mjTileName = string.format("p4s%d_%d.png", msgTbl.m_hucards[1][1], msgTbl.m_hucards[1][2])
				local mjTileSpr = cc.Sprite:createWithSpriteFrameName(mjTileName)
				mjTileSpr:setScale(0.7)
				mjTileSpr:setPosition(cc.p(width + distance, mjTileSpr:getContentSize().height * 0.4))
				majong_bg:addChild(mjTileSpr)
				mjTileSpr:setColor(cc.c3b(255,255,0))
				spr_winSign:setPosition(cc.p(width + distance * 4 + 40, 514.38))
				gt.log("x=====" .. width + distance * 2 + 20 .. "======".. width + distance)
			end
		else
			spr_winSign:setVisible(false)
		end

		local label_detail = gt.seekNodeByName(node_playerReport, "Label_detail")
		local node = cc.Node:create()
		local info_width = 10
		
		for m = 1, #msgTbl["m_huScore" .. i] do
			
			local str = ""
			if msgTbl["m_huScore" .. i][m][1] == 1 then
				--label:setString("平胡")
				str = "平胡"
			elseif msgTbl["m_huScore" .. i][m][1] == 2 then
				--label:setString("小七对")
				str = "小七对"
			elseif msgTbl["m_huScore" .. i][m][1] == 3 then
				--label:setString("大七对")
				str = "大七对"
			elseif msgTbl["m_huScore" .. i][m][1] == 4 then
				--label:setString("杠上开花")
				str = "杠上开花"
			elseif msgTbl["m_huScore" .. i][m][1] == 5 then
				--label:setString("抢杠胡")
				str = "抢杠胡"
			elseif msgTbl["m_huScore" .. i][m][1] == 6 then
				--label:setString("天胡")
				str = "天胡"
			elseif msgTbl["m_huScore" .. i][m][1] == 7 then
				--label:setString("地胡")
				str = "地胡"
			elseif msgTbl["m_huScore" .. i][m][1] == 8 then
				--label:setString("十三烂")
				str = "十三烂"
			elseif msgTbl["m_huScore" .. i][m][1] == 9 then
				--label:setString("七星十三烂")
				str = "七星十三烂"
			elseif msgTbl["m_huScore" .. i][m][1] == 10 then
				--label:setString("德国")
				str = "德国"
			elseif msgTbl["m_huScore" .. i][m][1] == 11 then
				--label:setString("德中德")
				str = "德中德"
			elseif msgTbl["m_huScore" .. i][m][1] == 12 then
				--label:setString("精吊")
				str = "精吊"
			elseif msgTbl["m_huScore" .. i][m][1] == 501 then
				--label:setString("明杠")
				str = "明杠"
			elseif msgTbl["m_huScore" .. i][m][1] == 502 then
				--label:setString("暗杠")
				str = "暗杠"
			elseif msgTbl["m_huScore" .. i][m][1] == 503 then
				--label:setString("抄庄")
				str = "抄庄"
			elseif msgTbl["m_huScore" .. i][m][1] == 505 then
				--label:setString("抄庄")
				str = "碰杠"
			elseif msgTbl["m_huScore" .. i][m][1] == 506 then
				--label:setString("抄庄")
				str = "点杠"
			elseif msgTbl["m_huScore" .. i][m][1] == 101 then
				--label:setString("自摸")
				str = "自摸"
			elseif msgTbl["m_huScore" .. i][m][1] == 102 then
				--label:setString("接炮")
				str = "接炮"
			elseif msgTbl["m_huScore" .. i][m][1] == 103 then
				--label:setString("点炮")
				str = "点炮"
			elseif msgTbl["m_huScore" .. i][m][1] == 103 then
				--label:setString("点炮")
				str = "点炮"
			elseif msgTbl["m_huScore" .. i][m][1] == 508 then
				str = "清一色"
			elseif msgTbl["m_huScore" .. i][m][1] == 509 then
				str = "七对子"
			elseif msgTbl["m_huScore" .. i][m][1] == 510 then
				str = "对对胡"
			elseif msgTbl["m_huScore" .. i][m][1] == 511 then
				str = "乱将"
			elseif msgTbl["m_huScore" .. i][m][1] == 512 then
				str = "一条龙"
			elseif msgTbl["m_huScore" .. i][m][1] == 513 then
				str = "清一色真将"
			elseif msgTbl["m_huScore" .. i][m][1] == 514 then
				str = "龙七"
			elseif msgTbl["m_huScore" .. i][m][1] == 515 then
				str = "字一色"
			elseif msgTbl["m_huScore" .. i][m][1] == 516 then
				str = "清一色对对胡"
			elseif msgTbl["m_huScore" .. i][m][1] == 517 then
				str = "清一色七对"
			elseif msgTbl["m_huScore" .. i][m][1] == 518 then
				str = "将一色七对"
			elseif msgTbl["m_huScore" .. i][m][1] == 519 then
				str = "将一色对对胡"
			elseif msgTbl["m_huScore" .. i][m][1] == 520 then
				str = "清一色对对胡真将"
			elseif msgTbl["m_huScore" .. i][m][1] == 521 then
				str = "双龙七"
			elseif msgTbl["m_huScore" .. i][m][1] == 522 then
				str = "字一色对对胡"
			elseif msgTbl["m_huScore" .. i][m][1] == 523 then
				str = "清一色一条龙"
			elseif msgTbl["m_huScore" .. i][m][1] == 524 then
				str = "三龙七"
			elseif msgTbl["m_huScore" .. i][m][1] == 525 then
				str = "十八罗汉"
			elseif msgTbl["m_huScore" .. i][m][1] == 677 then
				str = "杠吊"
			elseif msgTbl["m_huScore" .. i][m][1] == 678 then
				str = "七对精吊"
			elseif msgTbl["m_huScore" .. i][m][1] == 679 then
				str = "大七精吊"
			elseif msgTbl["m_huScore" .. i][m][1] == 680 then
				str = "大七杠开"
			elseif msgTbl["m_huScore" .. i][m][1] == 681 then
				str = "大七杠吊"
			elseif msgTbl["m_huScore" .. i][m][1] == 682 then
				str = "地胡杠吊"
			elseif msgTbl["m_huScore" .. i][m][1] == 683 then
				str = "德国自摸"
			elseif msgTbl["m_huScore" .. i][m][1] == 684 then
				str = "德国精吊"
			elseif msgTbl["m_huScore" .. i][m][1] == 685 then
				str = "德国杠开"
			elseif msgTbl["m_huScore" .. i][m][1] == 686 then
				str = "德国七对"
			elseif msgTbl["m_huScore" .. i][m][1] == 687 then
				str = "德国七对精吊"
			elseif msgTbl["m_huScore" .. i][m][1] == 688 then
				str = "德国十三烂"	
			elseif msgTbl["m_huScore" .. i][m][1] == 689 then
				str = "德国七星十三烂"
			elseif msgTbl["m_huScore" .. i][m][1] == 690 then
				str = "德国杠吊"	
			elseif msgTbl["m_huScore" .. i][m][1] == 691 then
				str = "德国大七对"	
			elseif msgTbl["m_huScore" .. i][m][1] == 692 then
				str = "德国大七对精吊"
			elseif msgTbl["m_huScore" .. i][m][1] == 693 then
				str = "德国接炮"	
			elseif msgTbl["m_huScore" .. i][m][1] == 695 then
				str = "流局"	
			elseif msgTbl["m_huScore" .. i][m][1] == 696 then
				str = "地胡德国"	
			elseif msgTbl["m_huScore" .. i][m][1] == 697 then
				str = "地胡德国精吊"	
			elseif msgTbl["m_huScore" .. i][m][1] == 698 then
				str = "地胡精吊"	
			end

			local label = nil
			if tonumber(msgTbl["m_huScore" .. i][m][2]) > 0 then
				if tonumber(msgTbl["m_huScore" .. i][m][2]) < 10 then
					label = gt.createTTFLabel(str .. "  +" .. msgTbl["m_huScore" .. i][m][2], 24)
				else
					label = gt.createTTFLabel(str .. " +" .. msgTbl["m_huScore" .. i][m][2], 24)
				end
			else
				if msgTbl["m_huScore" .. i][m][2] >-10 then
					label = gt.createTTFLabel(str .. "  " .. msgTbl["m_huScore" .. i][m][2], 24)
				else
					label = gt.createTTFLabel(str .. " " .. msgTbl["m_huScore" .. i][m][2], 24)
				end
			end

			if gt.playType == 3 and (msgTbl["m_huScore" .. i][m][1] == 102 or msgTbl["m_huScore" .. i][m][1] == 103)  then
				label = gt.createTTFLabel(str .. "  ", 24)
			end

			node:addChild(label)
			label:setPosition(cc.p(info_width + label:getContentSize().width / 2, 0))
			label:setColor(cc.c3b(150, 229, 131))

			--if str == "" then
				--info_width = info_width + label:getContentSize().width + 40
			--else
			info_width = info_width + label:getContentSize().width + 28
			--end
		end
		
		node_playerReport:addChild(node,20)
		node:setPosition(cc.p(label_detail:getPosition()))
		roomPlayer.score = tonumber(roomPlayer.score) + tonumber(scorenum)

		--上下左右翻
		if (paramTbl.m_jxPlayType == 4 or paramTbl.m_jxPlayType == 5) and paramTbl.m_ncPlayType == 2 then
			gt.log("我是上下左右翻")
			--设置不显示
			local shang_txt = gt.seekNodeByName(node_playerReport, "Txt_shang")
			shang_txt:setVisible(false)
			local xia_txt = gt.seekNodeByName(node_playerReport, "Txt_xia")
			xia_txt:setVisible(false)
			local shang_sp = gt.seekNodeByName(node_playerReport, "Spr_shang")
			shang_sp:setVisible(false)
			local xia_sp = gt.seekNodeByName(node_playerReport, "Spr_xia")
			xia_sp:setVisible(false)
			
			--设置显示

			local Txt_zuo_gan = gt.seekNodeByName(node_playerReport, "Txt_zuo_gan")
			Txt_zuo_gan:setVisible(true)
			local Txt_xia_gan = gt.seekNodeByName(node_playerReport, "Txt_xia_gan")
			Txt_xia_gan:setVisible(true)
			local Txt_shang_gan = gt.seekNodeByName(node_playerReport, "Txt_shang_gan")
			Txt_shang_gan:setVisible(true)
			local Txt_you_gan = gt.seekNodeByName(node_playerReport, "Txt_you_gan")
			Txt_you_gan:setVisible(true)

			local Spr_you_gan = gt.seekNodeByName(node_playerReport, "Spr_you_gan")
			Spr_you_gan:setVisible(true)
			local Spr_zuo_gan = gt.seekNodeByName(node_playerReport, "Spr_zuo_gan")
			Spr_zuo_gan:setVisible(true)
			local Spr_xia_gan = gt.seekNodeByName(node_playerReport, "Spr_xia_gan")
			Spr_xia_gan:setVisible(true)
			local Spr_shang_gan = gt.seekNodeByName(node_playerReport, "Spr_shang_gan")
			Spr_shang_gan:setVisible(true)

			--数据刷新
			if tonumber(msgTbl.m_shangJings[i]) > 0 then
				Txt_shang_gan:setString("+" .. msgTbl.m_shangJings[i] .. " ")
			else
				Txt_shang_gan:setString(msgTbl.m_shangJings[i] .. " ")
			end	

			if tonumber(msgTbl.m_ShangXiaZuoYouSingleCores1[i]) > 0 then
				Txt_xia_gan:setString("+" .. msgTbl.m_ShangXiaZuoYouSingleCores1[i] .. " ")
			else
				Txt_xia_gan:setString(msgTbl.m_ShangXiaZuoYouSingleCores1[i] .. " ")
			end	

			if tonumber(msgTbl.m_ShangXiaZuoYouSingleCores2[i]) > 0 then
				Txt_zuo_gan:setString("+" .. msgTbl.m_ShangXiaZuoYouSingleCores2[i] .. " ")
			else
				Txt_zuo_gan:setString(msgTbl.m_ShangXiaZuoYouSingleCores2[i] .. " ")
			end	

			if tonumber(msgTbl.m_ShangXiaZuoYouSingleCores3[i]) > 0 then
				Txt_you_gan:setString("+" .. msgTbl.m_ShangXiaZuoYouSingleCores3[i] .. " ")
			else
				Txt_you_gan:setString(msgTbl.m_ShangXiaZuoYouSingleCores3[i] .. " ")
			end	
		elseif (paramTbl.m_jxPlayType == 4 or paramTbl.m_jxPlayType == 5) and paramTbl.m_ncPlayType == 1 then
			gt.log("********我是上下翻精")
			--设置不显示
			local Txt_zuo_gan = gt.seekNodeByName(node_playerReport, "Txt_zuo_gan")
			Txt_zuo_gan:setVisible(false)
			local Txt_xia_gan = gt.seekNodeByName(node_playerReport, "Txt_xia_gan")
			Txt_xia_gan:setVisible(false)
			local Txt_shang_gan = gt.seekNodeByName(node_playerReport, "Txt_shang_gan")
			Txt_shang_gan:setVisible(false)
			local Txt_you_gan = gt.seekNodeByName(node_playerReport, "Txt_you_gan")
			Txt_you_gan:setVisible(false)
			local Spr_you_gan = gt.seekNodeByName(node_playerReport, "Spr_you_gan")
			Spr_you_gan:setVisible(false)
			local Spr_zuo_gan = gt.seekNodeByName(node_playerReport, "Spr_zuo_gan")
			Spr_zuo_gan:setVisible(false)
			local Spr_xia_gan = gt.seekNodeByName(node_playerReport, "Spr_xia_gan")
			Spr_xia_gan:setVisible(false)
			local Spr_shang_gan = gt.seekNodeByName(node_playerReport, "Spr_shang_gan")
			Spr_shang_gan:setVisible(false)

			--设置显示
			local shang_txt = gt.seekNodeByName(node_playerReport, "Txt_shang")
			shang_txt:setVisible(true)
			local xia_txt = gt.seekNodeByName(node_playerReport, "Txt_xia")
			xia_txt:setVisible(true)
			local shang_sp = gt.seekNodeByName(node_playerReport, "Spr_shang")
			shang_sp:setVisible(true)
			local xia_sp = gt.seekNodeByName(node_playerReport, "Spr_xia")
			xia_sp:setVisible(true)

			--刷新数据
			if tonumber(msgTbl.m_shangJings[i]) > 0 then
				shang_txt:setString("+" .. msgTbl.m_shangJings[i])
			else
				shang_txt:setString(msgTbl.m_shangJings[i])
			end
			if tonumber(msgTbl.m_xiaJings[i]) > 0 then
				xia_txt:setString("+" .. msgTbl.m_xiaJings[i])
			else
				xia_txt:setString(msgTbl.m_xiaJings[i])
			end
		else
			gt.log("我不是赣州")
			--设置显示
			-- local shang_txt = gt.seekNodeByName(node_playerReport, "Txt_shang")
			-- shang_txt:setVisible(true)
			-- local xia_txt = gt.seekNodeByName(node_playerReport, "Txt_xia")
			-- xia_txt:setVisible(true)
			-- local shang_sp = gt.seekNodeByName(node_playerReport, "Spr_shang")
			-- shang_sp:setVisible(true)
			-- local xia_sp = gt.seekNodeByName(node_playerReport, "Spr_xia")
			-- xia_sp:setVisible(true)
			--设置不显示

			local Txt_zuo_gan = gt.seekNodeByName(node_playerReport, "Txt_zuo_gan")
			Txt_zuo_gan:setVisible(false)
			local Txt_xia_gan = gt.seekNodeByName(node_playerReport, "Txt_xia_gan")
			Txt_xia_gan:setVisible(false)
			local Txt_shang_gan = gt.seekNodeByName(node_playerReport, "Txt_shang_gan")
			Txt_shang_gan:setVisible(false)
			local Txt_you_gan = gt.seekNodeByName(node_playerReport, "Txt_you_gan")
			Txt_you_gan:setVisible(false)

			local Spr_you_gan = gt.seekNodeByName(node_playerReport, "Spr_you_gan")
			Spr_you_gan:setVisible(false)
			local Spr_zuo_gan = gt.seekNodeByName(node_playerReport, "Spr_zuo_gan")
			Spr_zuo_gan:setVisible(false)
			local Spr_xia_gan = gt.seekNodeByName(node_playerReport, "Spr_xia_gan")
			Spr_xia_gan:setVisible(false)
			local Spr_shang_gan = gt.seekNodeByName(node_playerReport, "Spr_shang_gan")
			Spr_shang_gan:setVisible(false)
		end
		
	end

	local startGameBtn = gt.seekNodeByName(csbNode, "But_startgame")
	local btn_endgame = gt.seekNodeByName(csbNode, "Btn_endgame")
	-- 开始下一局
	gt.addBtnPressedListener(startGameBtn, function()
		self:removeFromParent()

		local msgToSend = {}
		msgToSend.m_msgId = gt.CG_READY
		msgToSend.m_pos = playerSeatIdx - 1
		gt.socketClient:sendMessage(msgToSend)
	end)

		-- 展示总局结算
	gt.addBtnPressedListener(btn_endgame, function()
		self:removeFromParent()
	end)

	if islast == 0 then
		startGameBtn:setVisible(true)
		btn_endgame:setVisible(false)
	else
		startGameBtn:setVisible(false)
		btn_endgame:setVisible(true)
	end

	-- 关闭按钮
	local closeBtn = gt.seekNodeByName(csbNode, "Btn_back")
	closeBtn:setVisible(false)
	gt.addBtnPressedListener(closeBtn, function()
		self:removeFromParent()
	end)
end

function RoundReport:onNodeEvent(eventName)
	if "enter" == eventName then
		local listener = cc.EventListenerTouchOneByOne:create()
		listener:setSwallowTouches(true)
		listener:registerScriptHandler(handler(self, self.onTouchBegan), cc.Handler.EVENT_TOUCH_BEGAN)
		local eventDispatcher = self:getEventDispatcher()
		eventDispatcher:addEventListenerWithSceneGraphPriority(listener, self)
	elseif "exit" == eventName then
		local eventDispatcher = self:getEventDispatcher()
		eventDispatcher:removeEventListenersForTarget(self)
	end
end

function RoundReport:onTouchBegan(touch, event)
	return true
end

return RoundReport

