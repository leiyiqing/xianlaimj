

local gt = cc.exports.gt

local FinalReport = class("FinalReport", function()
	return cc.Layer:create()
end)

function FinalReport:ctor(roomPlayers, rptMsgTbl, playerSeatIdx, paramTbl)
	-- 注册节点事件
	self:registerScriptHandler(handler(self, self.onNodeEvent))

	local csbNode = cc.CSLoader:createNode("FinalReport.csb")
	csbNode:setAnchorPoint(0.5, 0.5)
	csbNode:setPosition(gt.winCenter)
	self:addChild(csbNode)
	self.rootNode = csbNode

	gt.dump(rptMsgTbl)
	-- gt.dump(paramTbl)
	gt.log("-------55---")
	local sprtilewin = gt.seekNodeByName(csbNode, "Spr_tilewin")
	local sprtilefail = gt.seekNodeByName(csbNode, "Spr_tilefail")

	
	local scoreTable = {}
	local playerHeadMgr = require("app/PlayerHeadManager"):create()
	--赣州三人玩法
	self.maxPlayer = 4
	if paramTbl.m_jxPlayType == 5 then
		self.maxPlayer = 3
		local bgNode = gt.seekNodeByName(csbNode , "Spr_playerbg4")
		bgNode:setVisible(false)
	end
	for i = 1, self.maxPlayer  do
		local bgNode = gt.seekNodeByName(csbNode , "Spr_playerbg" .. i)
		local spr_winner = gt.seekNodeByName(bgNode,"Spr_winner")
		spr_winner:setVisible(false)
		local roomPlayer  =  roomPlayers[i]
		local txt_name = gt.seekNodeByName(bgNode, "Txt_name")
		local txt_id = gt.seekNodeByName(bgNode, "Txt_id")
		local spr_head = gt.seekNodeByName(bgNode, "Spr_head")
		if roomPlayer.sex == 1 then	--2:女 1:男
			spr_head:setTexture("sd/images/otherImages/head_m001.png")
		else
			spr_head:setTexture("sd/images/otherImages/head_m002.png")
		end
		txt_name:setString(roomPlayer.nickname)
		txt_name:setColor(cc.c3b(102, 38, 0))
		txt_id:setString("ID: " .. rptMsgTbl.m_id[i])
		txt_id:setColor(cc.c3b(102, 38, 0))

		playerHeadMgr:attach(spr_head, roomPlayer.uid, roomPlayer.headURL)
		
		--if index == i then
			--spr_winner:setVisible(true)
		--end 

		local sumscore = 0
		--for j = 11, 18 do
			--local score = gt.seekNodeByName(bgNode, "Txt_totalscore_" .. j)
			--score:setString(rptMsgTbl["m_result" .. i][j - 10])
			--sumscore = sumscore + tonumber(rptMsgTbl["m_result" .. i][j - 10])
		local list_score = gt.seekNodeByName(bgNode, "ListView_final")

		
		for j = 1, rptMsgTbl.m_rnum do
			local msgData = {}
			msgData.score = rptMsgTbl["m_result" .. i][j]
			local historyItem = self:createItem(j, msgData.score)
			list_score:pushBackCustomItem(historyItem)
			sumscore = sumscore + tonumber(msgData.score)
		end
	
		table.insert(scoreTable, sumscore)
		local txt_totalscore = gt.seekNodeByName(bgNode, "Txt_totalscore")
		txt_totalscore:setString(sumscore)
	end
	local max_score = -9999
	local index = 0
	for i = 1 , #scoreTable do
		if tonumber(scoreTable[i]) > tonumber(max_score) then
			max_score = scoreTable[i]
			--index = i
		end
	end

	--赣州3人特殊处理
	if self.maxPlayer == 3 then
		local bgNode1 = gt.seekNodeByName(csbNode , "Spr_playerbg1")
		local bgNode2 = gt.seekNodeByName(csbNode , "Spr_playerbg2")
		local bgNode3 = gt.seekNodeByName(csbNode , "Spr_playerbg3")
		local bgNode4 = gt.seekNodeByName(csbNode , "Spr_playerbg4")
		bgNode3:setPosition(bgNode4:getPosition())
		local tempPos1 = cc.p(bgNode1:getPosition())
		local tempPos2 = cc.p(bgNode4:getPosition())
		bgNode2:setPosition((tempPos1.x+tempPos2.x)/2, tempPos1.y)
	end

	for i = 1, 4 do
		local bgNode = gt.seekNodeByName(csbNode , "Spr_playerbg" .. i)
		local spr_winner = gt.seekNodeByName(bgNode,"Spr_winner")
		spr_winner:setVisible(false)
		if max_score == scoreTable[i] and max_score > 0 then
			spr_winner:setVisible(true)
		end 
	end

	-- 返回游戏大厅
	local backBtn = gt.seekNodeByName(csbNode, "Btn_back")
	gt.addBtnPressedListener(backBtn, function()
		gt.dispatchEvent(gt.EventType.BACK_MAIN_SCENE)
	end)
	
	-- 分享
	local shareBtn = gt.seekNodeByName(csbNode, "Btn_shard")
	gt.addBtnPressedListener(shareBtn, function()
		shareBtn:setEnabled(false)
		self:screenshotShareToWX()
	end)

	if gt.isIOSPlatform() and gt.isInReview then
		shareBtn:setVisible(false)
	else
		shareBtn:setVisible(true)
	end


--展示玩法类型

	if paramTbl then
		local playname = ""
		local ncname = ""
		local description = ""
		local playtype = ""
		if tonumber(paramTbl.totulType) == 1 then
			playname = "南昌麻将"
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
			description = string.format("%s %s",playname,ncname)
			playtype = string.format("%s %s\n%s %s",dianpao,difen,bawang,qjname)
		elseif tonumber(paramTbl.totulType) == 2 then 
			playname = "抚州包杠"
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
			
			description = string.format("%s %s",playname,lanjie)
			playtype = string.format("%s",fanshu)
		elseif tonumber(paramTbl.totulType) == 3 then 
			playname = "萍乡258"
			local difen = ""
			if tonumber(paramTbl.m_pxDifen) == 1 then
				difen = "底分：1"
			elseif tonumber(paramTbl.m_pxDifen) == 2 then
				difen = "底分：5"

			elseif tonumber(paramTbl.m_pxDifen) == 3 then
				difen = "底分：10"
			end
			description = string.format("萍乡258")
			playtype = string.format("%s",difen)
		elseif tonumber(paramTbl.totulType) == 4 then 
			playname = "赣州冲关"
			local  dianpao = ""
			if tonumber(paramTbl.dianpaoType) == 1 then
				dianpao = "点炮三家付"
			elseif tonumber(paramTbl.dianpaoType) == 2 then
				dianpao = "点炮一家付"
			end
			local fanshu = ""
			if tonumber(paramTbl.m_fanshu) == 1 then
				fanshu = "8番起步"
			elseif tonumber(paramTbl.m_fanshu) == 2 then
				fanshu = "可平胡"
			end

			local liuju = ""
			if tonumber(paramTbl.m_zhuangAddFive) == 1 then
				liuju = "流局+5"
			end

			local a_haha = ""
			if paramTbl.m_ncPlayType == 2 then
				a_haha = "上下左右翻"
			elseif paramTbl.m_ncPlayType == 1 then
				a_haha = "上下翻精"
			end

			description = string.format("%s %s", playname, a_haha)
			playtype = string.format("%s\n%s %s",dianpao,fanshu ,liuju)
		end

		gt.log("---------->" ..description)
		local label_type1 = gt.seekNodeByName(csbNode, "label_type1")
		label_type1:setString(description)
		local label_type2 = gt.seekNodeByName(csbNode, "label_type2")
		label_type2:setString(playtype)

		if gt.isInReview then
			label_type1:setVisible(false)
			label_type2:setVisible(false)
		end


	end
end

function  FinalReport:createItem(tag, score)
	local cellNode = cc.CSLoader:createNode("FinalScoreCell.csb")
	-- 序号
	local numLabel = gt.seekNodeByName(cellNode, "Label_name")
	local Image_bg1 = gt.seekNodeByName(cellNode, "Image_bg1")
	local Image_bg2 = gt.seekNodeByName(cellNode, "Image_bg2")
	if tag % 2 == 0 then
		Image_bg1:setVisible(true)
		Image_bg2:setVisible(false)
	end
	local str = 0
	if tag == 1 then
		str = "一"
	elseif tag == 2 then
		str = "二"
	elseif tag == 3 then
		str = "三"
	elseif tag == 4 then
		str = "四"
	elseif tag == 5 then
		str = "五"
	elseif tag == 6 then
		str = "六"
	elseif tag == 7 then
		str = "七"
	elseif tag == 8 then
		str = "八"
	elseif tag == 9 then
		str = "九"
	elseif tag == 10 then
		str = "十"
	elseif tag == 11 then
		str = "十一"
	elseif tag == 12 then
		str = "十二"
	elseif tag == 13 then
		str = "十三"
	elseif tag == 14 then
		str = "十四"
	elseif tag == 15 then
		str = "十五"
	elseif tag == 16 then
		str = "十六"
	end
	numLabel:setString("第" .. str .. "局")
	-- 房间号
	local roomIDLabel = gt.seekNodeByName(cellNode, "Label_score")
	roomIDLabel:setString(tostring(score))
	--[[
	if i % 2 ~= 0 then
		Image_bg1:setVisible(true)
		Image_bg1:setVisible(false)
	end

	local cellSize = cellNode:getContentSize()
	local cellItem = ccui.Widget:create()
	cellItem:setTag(tag)
	cellItem:setTouchEnabled(true)
	cellItem:setContentSize(cellSize)
	cellItem:addChild(cellNode)
	--cellItem:addClickEventListener(handler(self, self.historyItemClickEvent))
	--]]
	local cellSize = cellNode:getContentSize()
	local cellItem = ccui.Widget:create()
	cellItem:setTag(tag)
	cellItem:setTouchEnabled(true)
	cellItem:setContentSize(cellSize)
	cellItem:addChild(cellNode)
	return cellItem
end


function FinalReport:screenshotShareToWX()
	local layerSize = self.rootNode:getContentSize()

	--RenderTexture * RenderTexture::create(int w ,int h, Texture2D::PixelFormat eFormat,
	--GLuint uDepthStencilFormat)
	--local GL_DEPTH24_STENCIL8 = 0x88F0
	local gl_depth24_stencil8 = 0x88F0
	local eFormat = 2
	local screenshot = cc.RenderTexture:create(layerSize.width, layerSize.height, eFormat, gl_depth24_stencil8)

	screenshot:begin()
	self.rootNode:visit()
	screenshot:endToLua()

	local screenshotFileName = string.format("wx-%s.jpg", os.date("%Y-%m-%d_%H:%M:%S", os.time()))
	screenshot:saveToFile(screenshotFileName, cc.IMAGE_FORMAT_JPEG, false)

	self.shareImgFilePath = cc.FileUtils:getInstance():getWritablePath() .. screenshotFileName
	self.scheduleHandler = gt.scheduler:scheduleScriptFunc(handler(self, self.update), 0, false)
end

function FinalReport:update()
	if self.shareImgFilePath and cc.FileUtils:getInstance():isFileExist(self.shareImgFilePath) then
		gt.scheduler:unscheduleScriptEntry(self.scheduleHandler)
		local shareBtn = gt.seekNodeByName(self.rootNode, "Btn_shard")
		shareBtn:setEnabled(true)

		if gt.isIOSPlatform() then
			local luaoc = require("cocos/cocos2d/luaoc")
			luaoc.callStaticMethod("AppController", "shareImageToWX", {imgFilePath = self.shareImgFilePath})
		elseif gt.isAndroidPlatform() then
			local luaj = require("cocos/cocos2d/luaj")
			luaj.callStaticMethod("org/cocos2dx/lua/AppActivity", "shareImageToWX", {self.shareImgFilePath}, "(Ljava/lang/String;)V")
		end
		self.shareImgFilePath = nil
	end
end

function FinalReport:onNodeEvent(eventName)
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

function FinalReport:onTouchBegan(touch, event)
	return true
end

return FinalReport


