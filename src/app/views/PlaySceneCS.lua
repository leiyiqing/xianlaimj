

local gt = cc.exports.gt

local PlaySceneCS = class("PlaySceneCS", function()
	return cc.Scene:create()
end)

--[[
Ming bar 明杠
touch tickets 摸牌
明杠与暗杠：杠牌分为名杠与暗杠两种。
Bright bars and dark bars: bar card classified as bars and dark bar two
self-drawn 自摸
--]]
PlaySceneCS.DecisionType = {
	-- 接炮胡
	TAKE_CANNON_WIN				= 1,
	-- 自摸胡
	SELF_DRAWN_WIN				= 2,
	-- 明杠
	BRIGHT_BAR					= 3,
	-- 暗杠
	DARK_BAR					= 4,
	-- 碰
	PUNG						= 5,
	-- 吃
	EAT					        = 6,
}

PlaySceneCS.ZOrder = {
	MJTABLE						= 1,
	PLAYER_INFO					= 2,
	MJTILES						= 6,
	OUTMJTILE_SIGN				= 7,
	DECISION_BTN				= 8,
	DECISION_SHOW				= 9,
	PLAYER_INFO_TIPS			= 10,
	REPORT						= 16,
	DISMISS_ROOM				= 17,
	SETTING						= 18,
	CHAT						= 20,
	MJBAR_ANIMATION				= 21,
	FLIMLAYER           	    = 16,
	HAIDILAOYUE					= 23,

	ROUND_REPORT				= 66 -- 单局结算界面显示在总结算界面之上
}

PlaySceneCS.FLIMTYPE = {
	FLIMLAYER_BAR				= 1,
	FLIMLAYER_BU				= 2,
}

PlaySceneCS.TAG = {
	FLIMLAYER_BAR				= 50,
	FLIMLAYER_BU				= 51,
}

PlaySceneCS.firstShow = nil -- 控制是否是第一张发牌，如果第一张发的牌，要等翻精完成后才能显示精的标记
PlaySceneCS.removePlayers = nil --用于记录删除人物的数组
PlaySceneCS.showReport = nil -- 显示一轮的结果


function PlaySceneCS:ctor(enterRoomMsgTbl)
	-- 第一次出牌
	self.firstShow = false
	self.showReport = false

	gt.cardType = tonumber(enterRoomMsgTbl.m_ncPlayType)
	gt.fuzhouType =  tonumber(enterRoomMsgTbl.m_kongZhongLanJie)
	-- 房间内删除人
	self.removePlayers = {}

	self.maxPlayer = 4

	self.onlytouch = false

	--活动相关
	gt.isInit = 1
	-- 注册节点事件
	self:registerScriptHandler(handler(self, self.onNodeEvent))
	local csbNode = nil
	local animation = nil
	if tonumber(enterRoomMsgTbl.m_jxPlayType) == 5 then
		-- 加载界面资源，三人麻将
		csbNode, animation = gt.createCSAnimation("PlaySceneCS_0.csb")
		csbNode:setAnchorPoint(0.5, 0.5)
		csbNode:setPosition(gt.winCenter)
		self:addChild(csbNode)
		self.rootNode = csbNode
	else
		-- 加载界面资源
		csbNode, animation = gt.createCSAnimation("PlaySceneCS.csb")
		csbNode:setAnchorPoint(0.5, 0.5)
		csbNode:setPosition(gt.winCenter)
		self:addChild(csbNode)
		self.rootNode = csbNode
	end

	-- -- 加载界面资源
	-- local csbNode, animation = gt.createCSAnimation("PlaySceneCS.csb")
	-- csbNode:setAnchorPoint(0.5, 0.5)
	-- csbNode:setPosition(gt.winCenter)
	-- self:addChild(csbNode)
	-- self.rootNode = csbNode

	-- 房间号
	local roomIDLabel = gt.seekNodeByName(self.rootNode, "Label_roomID")
	roomIDLabel:setString(gt.getLocationString("LTKey_0013", enterRoomMsgTbl.m_deskId))
	
	--玩法

	if enterRoomMsgTbl.m_jxPlayType then
		gt.log("----create: m_jxPlayType----" .. enterRoomMsgTbl.m_jxPlayType)
		gt.playType = tonumber(enterRoomMsgTbl.m_jxPlayType)
	end

	local playType = ""
	if enterRoomMsgTbl.m_jxPlayType == 1 then
		if enterRoomMsgTbl.m_ncPlayType == 1 then
			playType = "无下精"
		elseif enterRoomMsgTbl.m_ncPlayType == 2 then
			playType = "埋地雷"
		elseif enterRoomMsgTbl.m_ncPlayType == 3 then
			playType = "回头一笑"
		elseif enterRoomMsgTbl.m_ncPlayType == 4 then
			playType = "回头上下翻"
		elseif enterRoomMsgTbl.m_ncPlayType == 5 then
			playType = "同一首歌"
		end
	elseif enterRoomMsgTbl.m_jxPlayType == 2 then
		if enterRoomMsgTbl.m_kongZhongLanJie == 1 then
			playType = "空中拦截"
		elseif enterRoomMsgTbl.m_kongZhongLanJie == 2 then
			playType = "无空中拦截"
		end
	elseif enterRoomMsgTbl.m_jxPlayType == 3 then
		playType = "萍乡258"

	elseif enterRoomMsgTbl.m_jxPlayType == 4 then
		if enterRoomMsgTbl.m_ncPlayType == 1 then
			playType = "上下翻精"
		elseif enterRoomMsgTbl.m_ncPlayType == 2 then
			playType = "上下左右翻"
		end
	elseif enterRoomMsgTbl.m_jxPlayType == 5 then
		playType = "赣州三人"
		-- if enterRoomMsgTbl.m_ncPlayType == 1 then
		-- 	playType = "上下翻精"
		-- elseif enterRoomMsgTbl.m_ncPlayType == 2 then
		-- 	playType = "上下左右翻"
		-- elseif enterRoomMsgTbl.m_ncPlayType == 3 then
		-- 	playType = "上下左左右右翻"
		-- end
	end

	if enterRoomMsgTbl.m_jxPlayType == 5 then
		self.maxPlayer = 3
	end

	local Spr_playType = gt.seekNodeByName(self.rootNode, "Spr_playType")
	Spr_playType:setString(playType)
	

	--self:updatePlayerInfo()
	-- 隐藏精牌背景
	self.mahjong_table = gt.seekNodeByName(self.rootNode, "mahjong_table")
    self.Img_turnbg1 = gt.seekNodeByName(self.rootNode, "Img_turnbg1")
	self.Spr_turnup1 = gt.seekNodeByName(self.rootNode, "Spr_turnup1")
	self.Spr_turnup2 = gt.seekNodeByName(self.rootNode, "Spr_turnup2")
	
	self.Img_turnbg2 = gt.seekNodeByName(self.rootNode, "Img_turnbg2")
	self.Spr_downtile = gt.seekNodeByName(self.Img_turnbg2, "Spr_downtile")
	self.Spr_turndown = gt.seekNodeByName(self.Img_turnbg2, "Spr_turndown")
	local Img_turnbg4 = gt.seekNodeByName(self.rootNode, "Img_turnbg4")
	Img_turnbg4:setVisible(false)
	local Img_turnbg5 = gt.seekNodeByName(self.rootNode, "Img_turnbg5")
	if Img_turnbg5 then
		Img_turnbg5:setVisible(false)
	end
	if gt.cardType == 5 then
		self.Img_turnbg2:setVisible(false)
		self.Img_turnbg2 = gt.seekNodeByName(self.rootNode, "Img_turnbg4")
		self.Spr_downtile = gt.seekNodeByName(self.Img_turnbg2, "Spr_downtile")
		self.Spr_turndown = gt.seekNodeByName(self.Img_turnbg2, "Spr_turndown")
	end


	self.Img_turnbg3 = gt.seekNodeByName(self.rootNode, "Img_turnbg3")
	self.Spr_turndown1 = gt.seekNodeByName(self.rootNode, "Spr_turndown1")
	self.Spr_turndown2 = gt.seekNodeByName(self.rootNode, "Spr_turndown2")
	for i = 1, 2 do 
		self["Spr_turnup" .. i .. "_posx"] = self["Spr_turnup" .. i]:getPositionX()
		self["Spr_turnup" .. i .. "_posy"] = self["Spr_turnup" .. i]:getPositionY()
		
		self["Spr_turndown" .. i .. "_posx"] = self["Spr_turndown" .. i]:getPositionX()
		self["Spr_turndown" .. i .. "_posy"] = self["Spr_turndown" .. i]:getPositionY()
	end
	self.Img_turnbg1:setVisible(false)
	self.Spr_turnup1:setVisible(false)
	self.Spr_turnup2:setVisible(false)
	self.Img_turnbg2:setVisible(false)
	self.Spr_downtile:setVisible(true)
	self.Spr_turndown:setVisible(false)
	self.Img_turnbg3:setVisible(false)
	self.Spr_turndown1:setVisible(false)
	self.Spr_turndown2:setVisible(false)
    

	for i = 1, 5 do
		local xinhao = gt.seekNodeByName(self.rootNode, "xinhao" .. i)
		if i == 4 then
			if gt.isIOSPlatform() and gt.isInReview then
				local xinhao0 = gt.seekNodeByName(self.rootNode, "xinhao0")
				xinhao:setVisible(false)
				xinhao0:setVisible(false)
				
			else
				xinhao:setVisible(true)
				xinhao:setZOrder(100)
			end
		else
			xinhao:setVisible(false)
		end
	end

		--语音提示
	local yuyinNode =  gt.seekNodeByName(self.rootNode, "Node_yy")
	if yuyinNode then
		yuyinNode:setVisible(false)
		self.yuyinNode = yuyinNode
	end




	--语音按钮
	local yuyinBtn = gt.seekNodeByName(self.rootNode, "Voice_Btn")
	if yuyinBtn then
		yuyinBtn:setVisible(true)
		self.yuyinBtn = yuyinBtn
	end
	gt.addBtnPressedListener(yuyinBtn, function()
		 if eventType == ccui.TouchEventType.began then
            self.sendVocie = false
	        gt.soundEngine:pauseAllSound()
	        self.sendVocie = true
	        self.yuyinNode:setVisible(true)
	        self.rootNode:reorderChild(self.yuyinNode, 100)
	        self:startAudio()
        elseif eventType == ccui.TouchEventType.moved then

        elseif eventType == ccui.TouchEventType.ended then
		    self.yuyinNode:setVisible(false)
	    	gt.soundEngine:resumeAllSound()
	    	self:stopAudio()
        elseif eventType == ccui.TouchEventType.canceled then
        	self.yuyinNode:setVisible(false)
            gt.soundEngine:resumeAllSound()
		    self:cancelAudio()
        end
	end)

	
	local yuyinChatNode = gt.seekNodeByName(self.rootNode, "Node_Yuyin_Dlg")
    
	if yuyinChatNode then
		yuyinChatNode:setVisible(false)
		self.yuyinChatNode = yuyinChatNode
	end


	-- -- 正式包点击回调
	-- local function touchEvent(sender,eventType)
 --        if eventType == ccui.TouchEventType.began then
 --            self.sendVocie = false
	--         gt.soundEngine:pauseAllSound()
	--         self.sendVocie = true
	--         self.yuyinNode:setVisible(true)
	--         self.rootNode:reorderChild(self.yuyinNode, 100)
	--         self:startAudio()
 --        elseif eventType == ccui.TouchEventType.moved then

 --        elseif eventType == ccui.TouchEventType.ended then
	-- 	    self.yuyinNode:setVisible(false)
	--     	gt.soundEngine:resumeAllSound()
	--     	self:stopAudio()
 --        elseif eventType == ccui.TouchEventType.canceled then
 --        	self.yuyinNode:setVisible(false)
 --            gt.soundEngine:resumeAllSound()
	-- 	    self:cancelAudio()
 --        end
 --    end

    -- 正式包点击语音按钮回调函数
	self.starAudioTime = 0
	local function touchEvent(sender,eventType)
        if eventType == ccui.TouchEventType.began then
        	
            self.sendVocie = false
	        gt.soundEngine:pauseAllSound()
	        self.sendVocie = true
	        self.yuyinNode:setVisible(true)
	        self.rootNode:reorderChild(self.yuyinNode, 100)
	        self:startAudio()
	        self.starAudioTime = os.time()
        elseif eventType == ccui.TouchEventType.moved then

        elseif eventType == ccui.TouchEventType.ended then
		    self.yuyinNode:setVisible(false)
	    	gt.soundEngine:resumeAllSound()
	    	local time = os.time()
	    	if time - self.starAudioTime > 1 then
	    		self:stopAudio()
	    	else
	    		self:cancelAudio()
	    		require("app/views/NoticeTips"):create("提示",	"语音时间小于".. 1 .."秒，不能发送。", nil, nil, true)
	    	end
        elseif eventType == ccui.TouchEventType.canceled then

        	self.yuyinNode:setVisible(false)
            gt.soundEngine:resumeAllSound()
		    self:cancelAudio()
        end
    end

    local button = ccui.Button:create()
    button:setTouchEnabled(true)
    button:loadTextures("res/sd/images/otherImages/yuyin.png", "res/sd/images/otherImages/yuyin.png", "")
	button:addTouchEventListener(touchEvent)

    

    self.yuyinBtn = button
   -- self.yuyinBtn:setPosition(cc.p(yuyinBtn:getPositionX(),yuyinBtn:getPositionY() + 15))
    button:setScale( 1.5 )
    yuyinBtn:addChild(self.yuyinBtn)
    self.yuyinBtn:setVisible(true)

	-- dump(enterRoomMsgTbl)
	gt.log("=====8===enterRoomMsgTbl==")
	--是否有下精
	if gt.cardType == 1 or gt.cardType == 3 or gt.cardType == 4 then
		self.havexiaJing = false
	else
		self.havexiaJing = true
	end

	if (gt.playType == 4 or gt.playType == 5) then  
		--是否有下精
		if gt.cardType == 2 then
			self.havexiaJing = false
		else
			self.havexiaJing = true
		end
	end


	local playTypeLabel = gt.seekNodeByName(self.rootNode, "Label_playType")
	playTypeLabel:setString("")

	-- 刚进入房间,隐藏玩家信息节点
	for i = 1, self.maxPlayer do
		local playerNode = gt.seekNodeByName(self.rootNode, "Node_playerInfo_" .. i)
		playerNode:setVisible(false)
	end
	
	self:hidePlayersReadySign()
	-- 隐藏玩家麻将参考位置（麻将参考位置父节点，pos(0，0）)
	local playNode = gt.seekNodeByName(self.rootNode, "Node_play")
	playNode:setVisible(false)
	-- 隐藏轮换位置标识（东南西北信息）
	local turnPosBgSpr = gt.seekNodeByName(self.rootNode, "Spr_turnPosBg")
	turnPosBgSpr:setVisible(false)
	-- 隐藏牌局状态（倒计时，剩余牌局，剩余牌数）
	local roundStateNode = gt.seekNodeByName(self.rootNode, "Node_roundState")
	roundStateNode:setVisible(false)
	-- 倒计时
	self.playTimeCDLabel = gt.seekNodeByName(roundStateNode, "Label_playTimeCD")
	self.playTimeCDLabel:setString("0")
	-- 隐藏玩家决策按钮（碰，杠，胡，过的父节点）
	local decisionBtnNode = gt.seekNodeByName(self.rootNode, "Node_decisionBtn")
	self.rootNode:reorderChild(decisionBtnNode, PlaySceneCS.ZOrder.DECISION_BTN)
	decisionBtnNode:setVisible(false)
	-- 隐藏自摸决策暗杠，碰转明杠，自摸胡
	local selfDrawnDcsNode = gt.seekNodeByName(self.rootNode, "Node_selfDrawnDecision")
	self.rootNode:reorderChild(selfDrawnDcsNode, PlaySceneCS.ZOrder.DECISION_BTN)
	selfDrawnDcsNode:setVisible(false)
	-- 隐藏游戏中设置按钮
	local playBtnsNode = gt.seekNodeByName(self.rootNode, "Node_playBtns")
	playBtnsNode:setVisible(false)
	-- 隐藏准备按钮
	local readyBtn = gt.seekNodeByName(self.rootNode, "Btn_ready")
	readyBtn:setVisible(false)
	gt.addBtnPressedListener(readyBtn, handler(self, self.readyBtnClickEvt))
	-- 隐藏所有玩家对话框
	local chatBgNode = gt.seekNodeByName(self.rootNode, "Node_chatBg")
	self.rootNode:reorderChild(chatBgNode, PlaySceneCS.ZOrder.CHAT)
	chatBgNode:setVisible(false)
	-- 隐藏开始胡牌决策按钮
	local decisionBtnNode = gt.seekNodeByName(self.rootNode, "Node_start_decisionBtn")
	if decisionBtnNode then
		decisionBtnNode:setVisible( false )
	end
	-- 胡牌字隐藏
	local huBtnNode = gt.seekNodeByName(self.rootNode, "Sprite_for_cshupaitype")
	if huBtnNode then
		huBtnNode:setVisible( false )
	end

	local settingBtn = gt.seekNodeByName(playBtnsNode, "Btn_setting")

	gt.addBtnPressedListener(settingBtn, function()
		local settingPanel = require("app/views/Setting"):create(enterRoomMsgTbl.m_pos)
		self:addChild(settingPanel, PlaySceneCS.ZOrder.HAIDILAOYUE)
	end)
	local messageBtn = gt.seekNodeByName(playBtnsNode, "Btn_message")
	gt.addBtnPressedListener(messageBtn, function()
		local chatPanel = require("app/views/ChatPanel"):create()
		self:addChild(chatPanel, PlaySceneCS.ZOrder.CHAT)
	end)

	-- 麻将层
	local playMjLayer = cc.Layer:create()
	self.rootNode:addChild(playMjLayer, PlaySceneCS.ZOrder.MJTILES)
	self.playMjLayer = playMjLayer


	-- 出的牌标识动画
	local outMjtileSignNode, outMjtileSignAnime = gt.createCSAnimation("animation/OutMjtileSign.csb")
	outMjtileSignAnime:play("run", true)
	outMjtileSignNode:setVisible(false)
	self.rootNode:addChild(outMjtileSignNode, PlaySceneCS.ZOrder.OUTMJTILE_SIGN)
	self.outMjtileSignNode = outMjtileSignNode

	-- 头像下载管理器
	local playerHeadMgr = require("app/PlayerHeadManager"):create()
	self.rootNode:addChild(playerHeadMgr)
	self.playerHeadMgr = playerHeadMgr
	-- 玩家进入房间
	self:playerEnterRoom(enterRoomMsgTbl)

	-- 最大局数
	self.roundMaxCount = enterRoomMsgTbl.m_maxCircle
	-- 准备界面逻辑
	self.paramTbl = {}
	self.paramTbl.roomID = enterRoomMsgTbl.m_deskId
	self.paramTbl.playerSeatPos = enterRoomMsgTbl.m_pos
	self.paramTbl.playTypeDesc = playTypeDesc
	self.paramTbl.roundMaxCount = enterRoomMsgTbl.m_maxCircle

	self.paramTbl.totulType = enterRoomMsgTbl.m_jxPlayType
	self.paramTbl.dianpaoType = enterRoomMsgTbl.m_dianPaoType
	self.paramTbl.m_anGangFanShu = enterRoomMsgTbl.m_anGangFanShu
	self.paramTbl.m_kongZhongLanJie = enterRoomMsgTbl.m_kongZhongLanJie
	self.paramTbl.m_pxDifen = enterRoomMsgTbl.m_pxDi
	self.paramTbl.m_fanshu = enterRoomMsgTbl.m_fanshu
	self.paramTbl.m_fanshu = enterRoomMsgTbl.m_fanshu
	self.paramTbl.bawang = enterRoomMsgTbl.m_baWang
	self.paramTbl.qjtype = enterRoomMsgTbl.m_outCardJing
	self.paramTbl.m_ncDi = enterRoomMsgTbl.m_ncDi
	self.paramTbl.m_zhuangAddFive = enterRoomMsgTbl.m_zhuangAddFive
	--赣州 上下左右翻
	self.paramTbl.m_jxPlayType = enterRoomMsgTbl.m_jxPlayType
	self.paramTbl.m_ncPlayType = enterRoomMsgTbl.m_ncPlayType

	self.readyPlay = require("app/views/ReadyPlay"):create(self.rootNode, self.paramTbl, enterRoomMsgTbl.m_ncPlayType)

	local paramTbl = self.paramTbl
	local playname = ""
	local description = ""
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
		local ncname = ""
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

			-- description = string.format("%s，%s，%s，%s玩法!",ncname,dianpao,bawang,qjname)
			description = string.format("%s %s %s %s",dianpao,bawang,qjname,difen)
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
		
		description = string.format("%s",fanshu)
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
		description = string.format("%s",difen)
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

		description = string.format("%s %s %s", dianpao,fanshu,liuju)
	elseif tonumber(paramTbl.totulType) == 5 then 
		-- gt.log("-----------赣州三人------------------")
		-- gt.dump(paramTbl)
		playname = "赣州三人"
		local  dianpao = ""
		if tonumber(enterRoomMsgTbl.m_hasBWJ) == 1 then
			dianpao = "有霸王"
		elseif tonumber(enterRoomMsgTbl.m_hasBWJ) == 2 then
			dianpao = "无霸王"
		end
		local liuju = ""
		if tonumber(paramTbl.m_zhuangAddFive) == 1 then
			liuju = "流局+5"
		end
		description = string.format("%s %s", dianpao,liuju)
	end
	local label_playtype = gt.seekNodeByName(self.rootNode, "label_playtype")
	label_playtype:setString(description)

	if gt.isIOSPlatform() and gt.isInReview then
		label_playtype:setVisible(false)
	end


	-- 解散房间
	self.applyDimissRoom = require("app/views/ApplyDismissRoom"):create(self.roomPlayers, self.playerSeatIdx)
	self:addChild(self.applyDimissRoom, PlaySceneCS.ZOrder.DISMISS_ROOM)

	if gt.isIOSPlatform() then
		self.luaBridge = require("cocos/cocos2d/luaoc")
	elseif gt.isAndroidPlatform() then
		self.luaBridge = require("cocos/cocos2d/luaj")
	end

	-- 接收消息分发函数
	gt.socketClient:registerMsgListener(gt.GC_ROOM_CARD, self, self.onRcvRoomCard)
	--GC_SHOW_DICE 掷骰子消息。服务端推送
	gt.socketClient:registerMsgListener(gt.GC_SHOW_DICE, self, self.onRcvShowDice)
	gt.socketClient:registerMsgListener(gt.GC_ENTER_ROOM, self, self.onRcvEnterRoom)
	gt.socketClient:registerMsgListener(gt.GC_ADD_PLAYER, self, self.onRcvAddPlayer)
	gt.socketClient:registerMsgListener(gt.GC_REMOVE_PLAYER, self, self.onRcvRemovePlayer)
	gt.socketClient:registerMsgListener(gt.GC_SYNC_ROOM_STATE, self, self.onRcvSyncRoomState)
	gt.socketClient:registerMsgListener(gt.GC_READY, self, self.onRcvReady)
	gt.socketClient:registerMsgListener(gt.GC_OFF_LINE_STATE, self, self.onRcvOffLineState)
	gt.socketClient:registerMsgListener(gt.GC_ROUND_STATE, self, self.onRcvRoundState)
	gt.socketClient:registerMsgListener(gt.GC_START_GAME, self, self.onRcvStartGame)
	gt.socketClient:registerMsgListener(gt.GC_TURN_SHOW_MJTILE, self, self.onRcvTurnShowMjTile)
	gt.socketClient:registerMsgListener(gt.GC_SYNC_SHOW_MJTILE, self, self.onRcvSyncShowMjTile)
	gt.socketClient:registerMsgListener(gt.GC_MAKE_DECISION, self, self.onRcvMakeDecision)
	gt.socketClient:registerMsgListener(gt.GC_SYNC_MAKE_DECISION, self, self.onRcvSyncMakeDecision)
	gt.socketClient:registerMsgListener(gt.GC_CHAT_MSG, self, self.onRcvChatMsg)
	gt.socketClient:registerMsgListener(gt.GC_ROUND_REPORT, self, self.onRcvRoundReport)
	gt.socketClient:registerMsgListener(gt.GC_FINAL_REPORT, self, self.onRcvFinalReport)

	gt.registerEventListener(gt.EventType.BACK_MAIN_SCENE, self, self.backMainSceneEvt)

	gt.socketClient:registerMsgListener(gt.GC_SYNC_START_PLAYER_DECISION, self, self.onRcvSyncStartDecision)
	gt.socketClient:registerMsgListener(gt.GC_SYNC_BAR_TWOCARD, self, self.onRcvSyncBarTwoCard)

	gt.socketClient:registerMsgListener(gt.CG_TURN_HAIDI, self, self.showHaidiInLayer)

	gt.socketClient:registerMsgListener(gt.GC_LOGIN, self, self.onRcvLogin)
	gt.socketClient:registerMsgListener(gt.GC_LOGIN_SERVER, self, self.onRcvLoginServer)

	--翻精牌
	gt.socketClient:registerMsgListener(gt.GC_TURNOVER, self, self.onShowTurnover)
end


function  PlaySceneCS:updatePlayerInfo()
	--dump(self.roomPlayers)
	-- if self.maxPlayer == 3 then
	-- 	local playerNode = gt.seekNodeByName(self.rootNode, "Node_playerInfo_4")
	-- 	playerNode:setVisible(false)
	-- end
	for i = 1, self.maxPlayer do
		--赣州三人
		-- if self.maxPlayer == 3 and i == 3 then
		-- 	i = 4
		-- end
		local playerInfoNode = gt.seekNodeByName(self.rootNode, "Node_playerInfo_" .. i)
		local scoreLabel = gt.seekNodeByName(playerInfoNode, "Label_score")
		for j = 1 , self.maxPlayer  do 
			--赣州三人
			-- if self.maxPlayer == 3 and j == 3 then
			-- 	j = 4
			-- end
			if self.roomPlayers[j].displaySeatIdx == i then    
				if self.roomPlayers ~= nil and self.roomPlayers[j] ~= nil then
					local roomPlayer = self.roomPlayers[j]
					if roomPlayer.score ~= nil then
						scoreLabel:setString(tostring(roomPlayer.score))
					end
				end

			end
		end
		
	end
end

function PlaySceneCS:unregisterAllMsgListener()
	gt.socketClient:unregisterMsgListener(gt.GC_ROOM_CARD)
	--gt.GC_SHOW_DICE 掷骰子消息，服务端推送
	gt.socketClient:unregisterMsgListener(gt.GC_SHOW_DICE)
	gt.socketClient:unregisterMsgListener(gt.GC_ENTER_ROOM)
	gt.socketClient:unregisterMsgListener(gt.GC_ADD_PLAYER)
	gt.socketClient:unregisterMsgListener(gt.GC_REMOVE_PLAYER)
	gt.socketClient:unregisterMsgListener(gt.GC_SYNC_ROOM_STATE)
	gt.socketClient:unregisterMsgListener(gt.GC_READY)
	gt.socketClient:unregisterMsgListener(gt.GC_OFF_LINE_STATE)
	gt.socketClient:unregisterMsgListener(gt.GC_ROUND_STATE)
	gt.socketClient:unregisterMsgListener(gt.GC_START_GAME)
	gt.socketClient:unregisterMsgListener(gt.GC_TURN_SHOW_MJTILE)
	gt.socketClient:unregisterMsgListener(gt.GC_SYNC_SHOW_MJTILE)
	gt.socketClient:unregisterMsgListener(gt.GC_MAKE_DECISION)
	gt.socketClient:unregisterMsgListener(gt.GC_SYNC_MAKE_DECISION)
	gt.socketClient:unregisterMsgListener(gt.GC_CHAT_MSG)
	gt.socketClient:unregisterMsgListener(gt.GC_ROUND_REPORT)
	gt.socketClient:unregisterMsgListener(gt.GC_FINAL_REPORT)
	
	gt.socketClient:unregisterMsgListener(gt.GC_SYNC_START_PLAYER_DECISION)
	gt.socketClient:unregisterMsgListener(gt.GC_SYNC_BAR_TWOCARD)

	gt.socketClient:unregisterMsgListener(gt.CG_SYNC_HAIDI)
	gt.socketClient:unregisterMsgListener(gt.CG_TURN_HAIDI)

	gt.socketClient:unregisterMsgListener(gt.GC_TURNOVER)
	gt.socketClient:unregisterMsgListener(gt.GC_LOGIN_SERVER)
end


function PlaySceneCS:startAudio()
	--测试录音
	if gt.isIOSPlatform() then
		local ok, ret = self.luaBridge.callStaticMethod("AppController", "startVoice")
	elseif gt.isAndroidPlatform() then
		local ok, ret = self.luaBridge.callStaticMethod("org/cocos2dx/lua/AppActivity", "startVoice",nil,"()Z")
	end

end

function PlaySceneCS:onRcvLoginServer(msgTbl)
	if gt.socketClient then
		gt.socketClient:sendHeartbeat(true)
	end
	-- 去除正在返回游戏提示
	gt.removeLoadingTips()

end

function PlaySceneCS:showMaskLayer()
    local function onTouchBegan()
    	return true
    end
	self.maskLayer = cc.LayerColor:create(cc.c4b(85,85,85,85))
	self.playMjLayer:addChild(self.maskLayer,80000)
	local listener = cc.EventListenerTouchOneByOne:create()
	listener:registerScriptHandler(onTouchBegan, cc.Handler.EVENT_TOUCH_BEGAN)
	listener:setSwallowTouches(true)
	local eventDispatcher = self:getEventDispatcher()
	eventDispatcher:addEventListenerWithSceneGraphPriority(listener, self.maskLayer)
end

function PlaySceneCS:hideMaskLayer()
    if self.maskLayer then
    	self.maskLayer:removeFromParent()
		self.maskLayer = nil
    end
end



function PlaySceneCS:onNodeEvent(eventName)
	if "enter" == eventName then
		-- 计算更新当前时间倒计时
		local curTimeStr = os.date("%X", os.time())
		local timeSections = string.split(curTimeStr, ":")
		local secondTime = tonumber(timeSections[3])
		self.updateTimeCD = 60 - secondTime
		self:updateCurrentTime()

		-- 触摸事件
		local listener = cc.EventListenerTouchOneByOne:create()
		listener:registerScriptHandler(handler(self, self.onTouchBegan), cc.Handler.EVENT_TOUCH_BEGAN)
		listener:registerScriptHandler(handler(self, self.onTouchMoved), cc.Handler.EVENT_TOUCH_MOVED)
		listener:registerScriptHandler(handler(self, self.onTouchEnded), cc.Handler.EVENT_TOUCH_ENDED)
		local eventDispatcher = self.playMjLayer:getEventDispatcher()
		eventDispatcher:addEventListenerWithSceneGraphPriority(listener, self.playMjLayer)

		-- 逻辑更新定时器
		self.scheduleHandler = gt.scheduler:scheduleScriptFunc(handler(self, self.update), 0, false)

		gt.soundEngine:playMusic("bgm2", true)
	elseif "exit" == eventName then
		local eventDispatcher = self.playMjLayer:getEventDispatcher()
		eventDispatcher:removeEventListenersForTarget(self.playMjLayer)

		gt.scheduler:unscheduleScriptEntry(self.scheduleHandler)

		if self.voiceUrlScheduleHandler then
			gt.scheduler:unscheduleScriptEntry(self.voiceUrlScheduleHandler)
			self.voiceUrlScheduleHandler = nil
		end

		gt.soundEngine:playMusic("bgm1", true)
	end
end




function PlaySceneCS:onTouchBegan(touch, event)

	-- gt.log(string.format("isPlayerShow:[%s] isPlayerDecision:[%s]", tostring(self.isPlayerShow), tostring(self.isPlayerDecision)))
	if not self.isPlayerShow or self.isPlayerDecision or self.onlytouch then
		return false
	end

	local touchMjTile, mjTileIdx = self:touchPlayerMjTiles(touch)
	if not touchMjTile then
		return false
	end
	self.onlytouch = true
	-- 杠之后只能出最后刚摸到的牌
	local roomPlayer = self.roomPlayers[self.playerSeatIdx]
	if not roomPlayer then
		return false
	end


	-- 记录原始位置
	self.playMjLayer:reorderChild(touchMjTile.mjTileSpr, gt.winSize.height)
	self.chooseMjTile = touchMjTile
	self.chooseMjTileIdx = mjTileIdx
	self.mjTileOriginPos = cc.p(touchMjTile.mjTileSpr:getPosition())
	self.preTouchPoint = self.playMjLayer:convertTouchToNodeSpace(touch)
	self.isTouchMoved = false

	return true
end

function PlaySceneCS:onTouchMoved(touch, event)
	local touchPoint = self.playMjLayer:convertTouchToNodeSpace(touch)
	self.chooseMjTile.mjTileSpr:setPosition(touchPoint)

	self.isTouchMoved = true
end

function PlaySceneCS:onTouchEnded(touch, event)
	local isShowMjTile = false
	-- 拖拽出牌
	local touchPoint = self.playMjLayer:convertTouchToNodeSpace(touch)
	if cc.pDistanceSQ(self.preTouchPoint, touchPoint) > 400 then
		-- 拖拽距离大于20判断为拖动
		local roomPlayer = self.roomPlayers[self.playerSeatIdx]
		local limitPosY = roomPlayer.mjTilesReferPos.outStart.y
		if touchPoint.y > limitPosY then
			-- 拖动位置大于上限认为出牌
			isShowMjTile = true
		end
	else
		-- 点击麻将牌
		-- 点中弹出
		if self.chooseMjTile ~= self.preClickMjTile then
			local mjTilePos = cc.p(self.chooseMjTile.mjTileSpr:getPosition())
			local moveAction = cc.MoveTo:create(0.25, cc.p(mjTilePos.x, mjTilePos.y + 26))
			self.chooseMjTile.mjTileSpr:runAction(moveAction)

			-- 上一次点中的复位
			if self.preClickMjTile then
				mjTilePos = cc.p(self.preClickMjTile.mjTileSpr:getPosition())
				local moveAction = cc.MoveTo:create(0.25, cc.p(mjTilePos.x, mjTilePos.y - 26))
				self.preClickMjTile.mjTileSpr:runAction(moveAction)
			end
		end

		-- 判断双击
		if self.preClickMjTile and self.preClickMjTile == self.chooseMjTile then
			isShowMjTile = true
		end
		self.preClickMjTile = self.chooseMjTile
	end

	if self.isTouchMoved and not isShowMjTile then
		-- 放回原来的位置,不出牌
		self.chooseMjTile.mjTileSpr:setPosition(self.mjTileOriginPos)
		self.playMjLayer:reorderChild(self.chooseMjTile.mjTileSpr, self.mjTileOriginPos.y)
	end

	if isShowMjTile then
		-- 发送出牌消息
		local msgToSend = {}
		msgToSend.m_msgId = gt.CG_SHOW_MJTILE
		-- 出牌标识
		msgToSend.m_type = 1
		msgToSend.m_think = {}

		local think_temp = {self.chooseMjTile.mjColor,self.chooseMjTile.mjNumber}
		table.insert(msgToSend.m_think,think_temp)
		gt.socketClient:sendMessage(msgToSend)

		gt.log("出牌")
		-- dump(msgToSend)

		self.isPlayerShow = false
		self.preClickMjTile = nil
		-- 停止倒计时音效
		if self.playCDAudioID then
			gt.soundEngine:stopEffect(self.playCDAudioID)
			self.playCDAudioID = nil
		end
	end
	self.onlytouch = false
end

function PlaySceneCS:update(delta)
	self.updateTimeCD = self.updateTimeCD - delta
	if self.updateTimeCD <= 0 then
		self.updateTimeCD = 60
		self:updateCurrentTime()
	end

	-- 更新倒计时
	self:playTimeCDUpdate(delta)
end

-- start --
--------------------------------
-- @class function
-- @description 接收掷骰子消息
-- @param msgTbl 消息体
-- end --
function PlaySceneCS:onRcvShowDice(msgTbl)
	self:hidePlayersReadySign()
	local csbNode, animation = require("app/views/ShowDice"):create(msgTbl, self.playerSeatIdx)
	self:addChild(csbNode)
	csbNode:updateMsg()
	csbNode:setAnchorPoint(0.5, 0.5)
	csbNode:setPosition(gt.winCenter)
end

-- start --
--------------------------------
-- @class function
-- @description 接收房卡信息
-- @param msgTbl 消息体
-- end --
function PlaySceneCS:onRcvRoomCard(msgTbl)
	gt.playerData.roomCardsCount = {msgTbl.m_card1, msgTbl.m_card2, msgTbl.m_card3}
end

-- start --
--------------------------------
-- @class function
-- @description 进入房间
-- @param msgTbl 消息体
-- end --
function PlaySceneCS:onRcvEnterRoom(msgTbl)
	gt.removeLoadingTips()

	self.playMjLayer:removeAllChildren()
	self:playerEnterRoom(msgTbl)
end

-- start --
--------------------------------
-- @class function
-- @description 接收房间添加玩家消息
-- @param msgTbl 消息体
-- end --
function PlaySceneCS:onRcvAddPlayer(msgTbl)
	-- 封装消息数据放入到房间玩家表中
	local roomPlayer = {}
	roomPlayer.uid = msgTbl.m_userId
	roomPlayer.nickname = msgTbl.m_nike
	roomPlayer.headURL = string.sub(msgTbl.m_face, 1, string.lastString(msgTbl.m_face, "/")) .. "96"
	roomPlayer.sex = msgTbl.m_sex
	roomPlayer.ip = msgTbl.m_ip
	-- 服务器位置从0开始
	-- 客户端位置从1开始
	roomPlayer.seatIdx = msgTbl.m_pos + 1
	-- 显示座位编号
	roomPlayer.displaySeatIdx = (msgTbl.m_pos + self.seatOffset) % 4 + 1
	roomPlayer.readyState = msgTbl.m_ready
	roomPlayer.score = msgTbl.m_score
	--赣州三人
	if self.maxPlayer == 3 then
		if self.playerSeatIdx == 1 then
			gt.log("PlaySceneCS:onRcvAddPlayer----self.playerSeatIdx == 1")
			if msgTbl.m_pos == 0 then
				roomPlayer.displaySeatIdx = 3
			elseif msgTbl.m_pos == 1 then
				roomPlayer.displaySeatIdx = 1
			elseif msgTbl.m_pos == 2 then
				roomPlayer.displaySeatIdx = 2
			end
		elseif self.playerSeatIdx == 2 then
			gt.log("PlaySceneCS:onRcvAddPlayer----self.playerSeatIdx == 2")
			if msgTbl.m_pos == 0 then
				roomPlayer.displaySeatIdx = 2
			elseif msgTbl.m_pos == 1 then
				roomPlayer.displaySeatIdx = 3
			elseif msgTbl.m_pos == 2 then
				roomPlayer.displaySeatIdx = 1
			end
		elseif self.playerSeatIdx == 3 then
			gt.log("PlaySceneCS:onRcvAddPlayer----self.playerSeatIdx == 3")
			if msgTbl.m_pos == 0 then
				roomPlayer.displaySeatIdx = 1
			elseif msgTbl.m_pos == 1 then
				roomPlayer.displaySeatIdx = 2
			elseif msgTbl.m_pos == 2 then
				roomPlayer.displaySeatIdx = 3
			end
		end
	end
	-- 房间添加玩家
	self:roomAddPlayer(roomPlayer)
end

-- start --
--------------------------------
-- @class function
-- @description 从房间移除一个玩家
-- @param msgTbl 消息体
-- end --
function PlaySceneCS:onRcvRemovePlayer(msgTbl)
	gt.log("-====================删除玩家")
	table.insert(self.removePlayers,msgTbl)
	if not self.showReport then
		self:removePlayerForRoom()
	end
end

-- 从房间移除要给玩家
function PlaySceneCS:removePlayerForRoom()
	if #self.removePlayers == 0 then
		return
	end
	for _, msgTbl in pairs(self.removePlayers) do
		local seatIdx = msgTbl.m_pos + 1
		local roomPlayer = self.roomPlayers[seatIdx]
		-- 隐藏玩家信息
		local playerInfoNode = gt.seekNodeByName(self.rootNode, "Node_playerInfo_" .. roomPlayer.displaySeatIdx)
		playerInfoNode:setVisible(false)

		-- 隐藏玩家准备手势
		local readySignNode = gt.seekNodeByName(self.rootNode, "Node_readySign")
		local readySignSpr = gt.seekNodeByName(readySignNode, "Spr_readySign_" .. roomPlayer.displaySeatIdx)
		readySignSpr:setVisible(false)

		-- 取消头像下载监听
		local headSpr = gt.seekNodeByName(playerInfoNode, "Spr_head")
		if self.playerHeadMgr then
			self.playerHeadMgr:detach(headSpr)
		end

		-- 去除数据
		self.roomPlayers[seatIdx] = nil
	end
	self.removePlayers = {}
end

-- start --
--------------------------------
-- @class function
-- @description 断线重连
-- end --
function PlaySceneCS:onRcvSyncRoomState(msgTbl)
	self.onlytouch = false
	if msgTbl.m_state == 1 then
		--local roundReport = require("app/views/RoundReport"):create(self.roomPlayers, self.playerSeatIdx, msgTbl, msgTbl.m_end)
		--self:addChild(roundReport, PlaySceneCS.ZOrder.ROUND_REPORT)
		-- 等待状态
		return
	end
	--移除精牌背景下的子类
	self:removeImgChild() 
	--总标签
	if msgTbl.m_jxPlayType then
		gt.playType = tonumber(msgTbl.m_jxPlayType)
	end

	if gt.playType ~= 1 and gt.playType ~= 4 and gt.playType ~= 5 then
		self.Img_turnbg1:setVisible(false)
		self.Img_turnbg2:setVisible(false)
		self.Img_turnbg3:setVisible(false)
	end

	 if msgTbl.m_kongZhongLanJie and gt.playType == 2 then  
		gt.fuzhouType = tonumber(msgTbl.m_kongZhongLanJie)
	end


	--如果有玩法类型则负责
    if msgTbl.m_ncPlayType and gt.playType == 1 then  
    	gt.log("---msgTbl.m_ncPlayType----" .. msgTbl.m_ncPlayType)
		gt.cardType = tonumber(msgTbl.m_ncPlayType)
		
		--是否有下精
		if gt.cardType == 1 or gt.cardType == 3 or gt.cardType == 4 then
			self.havexiaJing = false
		else
			self.havexiaJing = true
		end
	end
	
	--赣州玩法
	if (gt.playType == 4 or gt.playType == 5) then  
		--是否有下精
		if gt.cardType == 2 then
			self.havexiaJing = false
		else
			self.havexiaJing = true
		end
	end

	--点炮一家点炮三家
	if msgTbl.m_dianPaoType then
		gt.log("----m_jxPlayType----" .. msgTbl.m_dianPaoType)
		gt.dianpaoType = tonumber(msgTbl.m_dianPaoType)
	end

	--初始化精牌
	gt.turnCard = {}
	if msgTbl.m_jCard and  (gt.playType == 1 or gt.playType == 4 or gt.playType == 5) then
		gt.turnCard = msgTbl.m_jCard
		self.Img_turnbg2:setVisible(true)
		--self.Spr_downtile:setVisible(true)
		gt.log("###############")
		self.Spr_turndown:setVisible(true)
		self:showUpDownTurnCard("up")
	end


	--是否是断线重连
	self.pung = true

	
	-- 隐藏等待界面元素
	local readyPlayNode = gt.seekNodeByName(self.rootNode, "Node_readyPlay")
	readyPlayNode:setVisible(false)
	-- 游戏开始后隐藏准备标识
	self:hidePlayersReadySign()
	local readyBtn = gt.seekNodeByName(self.rootNode, "Btn_ready")
	readyBtn:setVisible(false)

	-- 显示轮转座位标识
	local turnPosBgSpr = gt.seekNodeByName(self.rootNode, "Spr_turnPosBg")
	turnPosBgSpr:setVisible(true)
	self.turnPosBgSpr = turnPosBgSpr
	
	
	-- 显示游戏中按钮
	local playBtnsNode = gt.seekNodeByName(self.rootNode, "Node_playBtns")
	playBtnsNode:setVisible(true)

	--如果有方位
	if msgTbl.m_pos then
		-- 显示当前出牌方位标示
		local seatIdx = msgTbl.m_pos + 1
		self:setTurnSeatSign(seatIdx)
		if seatIdx == self.playerSeatIdx then
			gt.log("=========11111==")
			-- 如果是玩家自己玩家选择出牌 标识设置true
			self.isPlayerShow = true
		end
	end

	-- 牌局状态,剩余牌
	local roundStateNode = gt.seekNodeByName(self.rootNode, "Node_roundState")
	local remainTilesLabel = gt.seekNodeByName(roundStateNode, "Label_remainTiles")
	remainTilesLabel:setString(tostring(msgTbl.m_dCount))

	-- 庄家座位号
	local bankerSeatIdx = msgTbl.m_zhuang + 1
	self.zhuang = bankerSeatIdx
	--显示精牌
	--self:showTurnResult("up")

	--拷贝玩家数组
	self.curRoomPlayers = {}
	self.curRoomPlayers = self:copyTab(self.roomPlayers)
	
	-- 遍历家牌
	for seatIdx, roomPlayer in ipairs(self.roomPlayers) do
		-- 庄家标识
		local playerInfoNode = gt.seekNodeByName(self.rootNode, "Node_playerInfo_" .. roomPlayer.displaySeatIdx)
		local bankerSignSpr = gt.seekNodeByName(playerInfoNode, "Spr_bankerSign")
		roomPlayer.isBanker = false
		bankerSignSpr:setVisible(false)
		if bankerSeatIdx == seatIdx then
			roomPlayer.isBanker = true
			bankerSignSpr:setVisible(true)
		end

		-- 玩家持有牌
		roomPlayer.holdMjTiles = {}
		-- 玩家已出牌
		roomPlayer.outMjTiles = {}
		-- 碰
		roomPlayer.mjTilePungs = {}
		-- 明杠
		roomPlayer.mjTileBrightBars = {}
		-- 暗杠
		roomPlayer.mjTileDarkBars = {}
		--吃
		roomPlayer.mjTileEat = {}
	
		-- 麻将放置参考点
		roomPlayer.mjTilesReferPos = self:setPlayerMjTilesReferPos(roomPlayer.displaySeatIdx)
		-- 剩余持有牌数量
		roomPlayer.mjTilesRemainCount = msgTbl.m_CardCount[seatIdx] --当前玩家持有牌数量
		--如果是玩家自己
		-- gt.log("我的本地ID---------->" .. self.playerSeatIdx)
		if roomPlayer.seatIdx == self.playerSeatIdx then
			-- 玩家持有牌
			if msgTbl.m_myCard then
				--self.m_mCard = msgTbl.m_mCard
				for _, v in ipairs(msgTbl.m_myCard) do
					gt.log("========" .. v[1] .. v[2])

					self:addMjTileToPlayer(v[1], v[2])
				end
				-- 根据花色大小排序并重新放置位置
				gt.log("=================66====")
				self:sortPlayerMjTiles()

			end
		else
			local mjTilesReferPos = roomPlayer.mjTilesReferPos
			local mjTilePos = mjTilesReferPos.holdStart
			local maxCount = roomPlayer.mjTilesRemainCount + 1
			for i = 1, maxCount do
				local mjTileName = string.format("tbgs_%d.png", roomPlayer.displaySeatIdx)
				--赣州三人，特殊处理
				if self.maxPlayer == 3 and roomPlayer.displaySeatIdx == 2 then
					mjTileName = string.format("tbgs_%d.png", 3)
				-- elseif self.maxPlayer == 3 and roomPlayer.displaySeatIdx == 3 then
				-- 	mjTileName = string.format("tbgs_%d.png", 4)
				end
				local mjTileSpr = cc.Sprite:createWithSpriteFrameName(mjTileName)
				mjTileSpr:setPosition(mjTilePos)
				self.playMjLayer:addChild(mjTileSpr, (gt.winSize.height - mjTilePos.y))
				mjTilePos = cc.pAdd(mjTilePos, mjTilesReferPos.holdSpace)

				local mjTile = {}
				mjTile.mjTileSpr = mjTileSpr
				table.insert(roomPlayer.holdMjTiles, mjTile)

				-- 隐藏多产生的牌
				if i > roomPlayer.mjTilesRemainCount then
					mjTileSpr:setVisible(false)
				end
			end
		end

		-- 服务器座次编号
		local turnPos = seatIdx - 1
		-- 已出牌
		local outMjTilesAry = msgTbl["m_oCard" .. turnPos]
		if outMjTilesAry then
			for _, v in ipairs(outMjTilesAry) do
				self:addAlreadyOutMjTiles(seatIdx, v[1], v[2])
			end
		end

		-- 如果是重连进来的话，需要记住最后出牌人出的牌
		if msgTbl.m_pos then
			if turnPos == msgTbl.m_pos then
				self.preShowSeatIdx = seatIdx
			end
		end

		-- 暗杠
		local darkBarArray = msgTbl["m_aCard" .. turnPos]
		if darkBarArray then
			for _, v in ipairs(darkBarArray) do
				if v[1] ~= 0 and v[2] ~= 0 then
					self:addMjTileBar(seatIdx, v[1], v[2], false)
				end
			end
		end

		-- 明杠
		local brightBarArray = msgTbl["m_mCard" .. turnPos]
		if brightBarArray then
			for _, v in ipairs(brightBarArray) do
				if v[1] ~= 0 and v[2] ~= 0 then
					self:addMjTileBar(seatIdx, v[1], v[2], true)
				end
			end
		end

		-- 碰
		local pungArray = msgTbl["m_pCard" .. turnPos]
		if pungArray then
			for _, v in ipairs(pungArray) do
				self:addMjTilePung(seatIdx, v[1], v[2])
			end
		end

		--吃
		local eatArray = msgTbl["m_eCard" .. turnPos]
		if eatArray then
			local eatTable = {}
			local group1 = {}
			local group2 = {}
			local group3 = {}
			local group4 = {}
			for i, v in ipairs(eatArray) do
				if v[1] ~= 0 and v[2] ~= 0 then
					local endTag = nil
					if i <= 3 then
						table.insert(group1,{v[2],1,v[1]}) --牌号，手中牌标识，颜色
						if i == 3 then
							table.insert(eatTable,group1)
							table.insert(roomPlayer.mjTileEat,group1)
						end
					elseif i > 3 and i <= 6 then
						table.insert(group2,{v[2],1,v[1]})
						if i == 6 then
							table.insert(eatTable,group2)
							table.insert(roomPlayer.mjTileEat,group2)
						end
					elseif i > 6 and i <= 9  then
						table.insert(group3,{v[2],1,v[1]})
						if i == 9 then
							table.insert(eatTable,group3)
							table.insert(roomPlayer.mjTileEat,group3)
						end
					elseif i > 9 and i <= 12  then
						table.insert(group4,{v[2],1,v[1]})
						if i == 12 then
							table.insert(eatTable,group4)
							table.insert(roomPlayer.mjTileEat,group4)
						end
					end
				end
			end

			for j, eatTile in pairs(eatTable) do
				self:pungBarReorderMjTiles(seatIdx, eatTile[j][3], eatTile)
			end
		end
	end
	self.pung = false
end

-- start --
--------------------------------
-- @class function
-- @description 玩家准备手势
-- @param msgTbl 消息体
-- end --
function PlaySceneCS:onRcvReady(msgTbl)
	-- dump(msgTbl)
	self:updatePlayerInfo()
	local seatIdx = msgTbl.m_pos + 1
	self:playerGetReady(seatIdx)
end


function PlaySceneCS:showUpDownTurnCard(cardType)
	
	if gt.turnCard and #gt.turnCard > 0 then
		if cardType == "up" then
			self.Img_turnbg1:setVisible(true)

			gt.log("-----888")
			--self.Spr_turnup1:setVisible(true)
			--self.Spr_turnup2:setVisible(true)
			self.Img_turnbg3:setVisible(false)
			if not self.havexiaJing  then
				self.Img_turnbg2:setVisible(false)			
			end

		elseif cardType == "down" then
			self.Img_turnbg2:setVisible(false)
			if not self.havexiaJing then
				self.Img_turnbg3:setVisible(false)
			else
				self.Img_turnbg3:setVisible(true)
			end
		end

		for i = 1, 2 do
			
			gt.log("---uuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuuu--888")
			local mjTileName = nil
			if cardType == "up" then
				if self.Img_turnbg1:getChildByTag(80 + i) then
					self.Img_turnbg1:getChildByTag(80 + i):removeFromParent()
				end
				mjTileName = string.format("p4s%d_%d.png", gt.turnCard[i][1], gt.turnCard[i][2])
			elseif cardType == "down" then
				if self.Img_turnbg3:getChildByTag(80 + i) then
					self.Img_turnbg3:getChildByTag(80 + i):removeFromParent()
				end
				mjTileName = string.format("p4s%d_%d.png", gt.turnCard[(i + 2)][1], gt.turnCard[(i + 2)][2])
			end

			local Spr_turnup = cc.Sprite:createWithSpriteFrameName(mjTileName)
			Spr_turnup:setScale(0.66)
			
			if cardType == "up" then
				self.Img_turnbg1:addChild(Spr_turnup, 8, 80 + i)
			elseif cardType == "down" then
				self.Img_turnbg3:addChild(Spr_turnup, 8, 80 + i)
			end
			--Spr_turnup:setPosition(cc.p(self["Spr_turn" .. cardType .. i]:getPositionX() - 40, self["Spr_turn" .. cardType .. i]:getPositionY() - 40))
			Spr_turnup:setPosition(self["Spr_turn" .. cardType .. i .. "_posx"], self["Spr_turn" .. cardType .. i .. "_posy"])
			
			
			
			local turnTile = nil
			if i == 1 then
				turnTile = cc.Sprite:create("images/otherImages/zheng.png")
				turnTile:setPosition(cc.p(0, Spr_turnup:getContentSize().height))
			elseif i == 2 then
				turnTile = cc.Sprite:create("images/otherImages/fu.png")
				turnTile:setPosition(cc.p(Spr_turnup:getContentSize().width, Spr_turnup:getContentSize().height))
			end
			--turnTile:setScale(1.34)
			Spr_turnup:addChild(turnTile)	
		end
	end
end

function PlaySceneCS:showDownTurnCard()
	if gt.turnCard and #gt.turnCard > 0 then
		self.Img_turnbg2:setVisible(false)
		self.Spr_turndown:setVisible(false)
			
		self.Img_turnbg3:setVisible(true)
		--self.Spr_turndown1:setVisible(false)
		--self.Spr_turndown2:setVisible(false)
		
		for i = 1, 2 do
			local mjTileName = string.format("p4s%d_%d.png", gt.turnCard[(i + 2)][1], gt.turnCard[(i + 2)][2])
			local Spr_turndown = cc.Sprite:createWithSpriteFrameName(mjTileName)
			--Spr_turndown:setScale(0.66)
			self.Img_turnbg3:addChild(Spr_turndown)
			Spr_turndown:setPosition(self["Spr_turndown" .. i]:getPosition())
			--local turnTile = cc.Sprite:create("images/otherImages/turntile.png")
			local turnTile = nil
			if i == 1 then
				turnTile = cc.Sprite:create("images/otherImages/fu.png")
				turnTile:setPosition(cc.p(0, Spr_turndown:getContentSize().height ))
			elseif i == 2 then
				turnTile = cc.Sprite:create("images/otherImages/zheng.png")
				turnTile:setPosition(cc.p(Spr_turndown:getContentSize().width, Spr_turndown:getContentSize().height))
			end

			Spr_turndown:addChild(turnTile)
			--turnTile:setPosition(cc.p(turnTile:getContentSize().width / 2, Spr_turndown:getContentSize().height - turnTile:getContentSize().height / 2))
		end

	end
end

-- start --
--------------------------------
-- @class function
-- @description 玩家在线标识
-- @param msgTbl 消息体
-- end --
function PlaySceneCS:onRcvOffLineState(msgTbl)
	local seatIdx = msgTbl.m_pos + 1
	local roomPlayer = self.roomPlayers[seatIdx]
	local playerInfoNode = gt.seekNodeByName(self.rootNode, "Node_playerInfo_" .. roomPlayer.displaySeatIdx)
	-- 离线标示
	local offLineSignSpr = gt.seekNodeByName(playerInfoNode, "Spr_offLineSign")
	if msgTbl.m_flag == 0 then
		-- 掉线了
		offLineSignSpr:setVisible(true)
	elseif msgTbl.m_flag == 1 then
		-- 回来了
		offLineSignSpr:setVisible(false)
	end
end

-- start --
--------------------------------
-- @class function
-- @description 当前局数/最大局数量
-- @param msgTbl 消息体
-- end --
function PlaySceneCS:onRcvRoundState(msgTbl)
	--测试代码
	--msgTbl.m_curCircle = msgTbl.m_curMaxCircle
	-- 牌局状态,剩余牌
	local roundStateNode = gt.seekNodeByName(self.rootNode, "Node_roundState")
	roundStateNode:setVisible(true)
	local remainTilesLabel = gt.seekNodeByName(roundStateNode, "Label_remainRounds")
	remainTilesLabel:setString(string.format("%d/%d", (msgTbl.m_curCircle + 1), msgTbl.m_curMaxCircle))
end

-- start --
--------------------------------
-- @class function
-- @description 游戏开始
-- @param msgTbl 消息体
-- end --
function PlaySceneCS:onRcvStartGame(msgTbl)
	self.firstShow = true
	self:onRcvSyncRoomState(msgTbl)
end

-- start --
--------------------------------
-- @class function
-- @description 通知玩家出牌
-- @param msgTbl 消息体
-- end --
function PlaySceneCS:onRcvTurnShowMjTile(msgTbl)
	-- 测试代码  第一张牌
	-- msgTbl.m_color = 1
	-- msgTbl.m_number = 1

	gt.log("通知玩家出牌")
	-- dump(msgTbl)
	-- 牌局状态,剩余牌
	local roundStateNode = gt.seekNodeByName(self.rootNode, "Node_roundState")
	local remainTilesLabel = gt.seekNodeByName(roundStateNode, "Label_remainTiles")
	remainTilesLabel:setString(tostring(msgTbl.m_dCount))
	local seatIdx = msgTbl.m_pos + 1
	-- 当前出牌座位
	self:setTurnSeatSign(seatIdx)

	-- 出牌倒计时
	self:playTimeCDStart(msgTbl.m_time)
	local roomPlayer = self.roomPlayers[seatIdx]
	-- 该玩家是否杠过（0-没杠过，1-杠过了）
	--roomPlayer.m_gang = msgTbl.m_gang
	if seatIdx == self.playerSeatIdx then
		-- 轮到玩家出牌
		self.isPlayerShow = true
		-- 摸牌
		if msgTbl.m_flag == 0 then
			-- 添加牌放在末尾
			local mjTilesReferPos = roomPlayer.mjTilesReferPos
			local mjTilePos = mjTilesReferPos.holdStart
			mjTilePos = cc.pAdd(mjTilePos, cc.pMul(mjTilesReferPos.holdSpace, #roomPlayer.holdMjTiles))
			mjTilePos = cc.pAdd(mjTilePos, cc.p(36, 0))

			local mjTile = self:addMjTileToPlayer(msgTbl.m_color, msgTbl.m_number)
			mjTile.mjTileSpr:setPosition(mjTilePos)
			self.playMjLayer:reorderChild(mjTile.mjTileSpr, (gt.winSize.height - mjTilePos.y))
		end


		local haidiWinType = false
		local decisionTypes = {}
		if msgTbl.m_think then
			for _,value in ipairs(msgTbl.m_think) do
				local think_m_type = value[1]
				local think_m_cardList = {}
				think_m_cardList = value[2]

				if think_m_type == 2 then
					-- 胡
					haidiWinType = true
					-- b_isHu = true
					local decisionData = {}
					decisionData.flag = 2
					decisionData.mjColor = msgTbl.m_color
					decisionData.mjNumber = msgTbl.m_number
					table.insert(decisionTypes,decisionData)
					gt.log("胡")
				end
				if think_m_type == 3 then
					-- 暗杠
					local decisionData = {}
					decisionData.flag = 3
					decisionData.cardList = {}
					for _,v in ipairs(think_m_cardList) do
						local card = {}
						card.mjColor = v[1]
						card.mjNumber = v[2]
						table.insert(decisionData.cardList,card)
					end
					table.insert(decisionTypes,decisionData)
					gt.log("暗杠")
				end
				if think_m_type == 4 then
					-- 明杠
					local decisionData = {}
					decisionData.flag = 4
					decisionData.cardList = {}
					for _,v in ipairs(think_m_cardList) do
						local card = {}
						card.mjColor = v[1]
						card.mjNumber = v[2]
						table.insert(decisionData.cardList,card)
					end
					table.insert(decisionTypes,decisionData)
					gt.log("明杠")
				end
				if think_m_type == 7 then
					-- 暗补
					local decisionData = {}
					decisionData.flag = 7
					decisionData.cardList = {}
					for _,v in ipairs(think_m_cardList) do
						local card = {}
						card.mjColor = v[1]
						card.mjNumber = v[2]
						table.insert(decisionData.cardList,card)
					end
					table.insert(decisionTypes,decisionData)
					gt.log("暗补")
				end
				if think_m_type == 8 then
					-- 明补
					local decisionData = {}
					decisionData.flag = 8
					decisionData.cardList = {}
					for _,v in ipairs(think_m_cardList) do
						local card = {}
						card.mjColor = v[1]
						card.mjNumber = v[2]
						table.insert(decisionData.cardList,card)
					end
					table.insert(decisionTypes,decisionData)
					gt.log("明补")
				end
			end
		end



		-- 按钮排列
		if #decisionTypes > 0 then
			-- 自摸类型决策
			self.isPlayerDecision = true

			local selfDrawnDcsNode = gt.seekNodeByName(self.rootNode, "Node_selfDrawnDecision")
			selfDrawnDcsNode:setVisible(true)

			for _, decisionBtn in ipairs(selfDrawnDcsNode:getChildren()) do
				local nodeName = decisionBtn:getName()
				if nodeName == "Btn_decisionPass" then
					-- 设置不存在的索引值
					decisionBtn:setTag(0)
					gt.addBtnPressedListener(decisionBtn, function()
						local function passDecision()
							self.isPlayerDecision = false

							local selfDrawnDcsNode = gt.seekNodeByName(self.rootNode, "Node_selfDrawnDecision")
							selfDrawnDcsNode:setVisible(false)
							-- 删除弹出框（杠）
							self:removeFlimLayer(PlaySceneCS.FLIMTYPE.FLIMLAYER_BAR)
							-- 删除弹出框（补）
							self:removeFlimLayer(PlaySceneCS.FLIMTYPE.FLIMLAYER_BU)
						end
							passDecision()
					end)
				else
					decisionBtn:setVisible(false)
				end
			end

			local decisionBtn_pass = gt.seekNodeByName(selfDrawnDcsNode, "Btn_decisionPass")
			local beginPos = cc.p(decisionBtn_pass:getPosition())
			local btnSpace = decisionBtn_pass:getContentSize().width * 3

			-- 获取可以杠的数据和可补的数据
			local cardList_bar = {}
			local cardList_bu = {}
			for idx, decisionData in ipairs(decisionTypes) do
				if decisionData.flag == 3 or decisionData.flag == 4 or  decisionData.flag == 7  then
					-- 明暗杠
					for _,v in ipairs(decisionData.cardList) do
						local card_bar = {}
						card_bar.flag = decisionData.flag
						card_bar.mjColor = v.mjColor
						card_bar.mjNumber = v.mjNumber
						table.insert(cardList_bar,card_bar)
					end
				-- elseif decisionData.flag == 7 or decisionData.flag == 8 then
				-- 	-- 明暗补
				-- 	for _,v in ipairs(decisionData.cardList) do
				-- 		local card_bu = {}
				-- 		card_bu.flag = decisionData.flag
				-- 		card_bu.mjColor = v.mjColor
				-- 		card_bu.mjNumber = v.mjNumber
				-- 		table.insert(cardList_bu,card_bu)
				-- 	end
				end
			end
			gt.log("杠的次数",#cardList_bar)
			gt.log("补的次数",#cardList_bu)
			-- dump( decisionTypes )

			local btn_presentList = {}
			for idx, decisionData in ipairs(decisionTypes) do
				local decisionBtn = nil

				if decisionData.flag == 2 then
					-- 胡
					decisionBtn = gt.seekNodeByName(selfDrawnDcsNode, "Btn_decisionWin")

					-- 杠的显示优先级为1
					table.insert(btn_presentList,{1,decisionBtn})
					gt.log("qqqqqqqqqqqqqqqq")
				elseif decisionData.flag == 3 or decisionData.flag == 4  or decisionData.flag == 7 then
					-- print("===============111111111111111")
					-- 明暗杠
					local btn_bar_name = "Btn_decisionBar"
					
					decisionBtn = gt.seekNodeByName(selfDrawnDcsNode, btn_bar_name)
					local isExistBarBtn = false
					for _,v in ipairs(btn_presentList) do
						-- 杠的显示优先级为2
						if v[1] == 2 then
							isExistBarBtn = true
							break
						end
					end
					if not isExistBarBtn then
						table.insert(btn_presentList,{2,decisionBtn})
					end
					-- 显示杠胡牌
					local mjTileSpr = gt.seekNodeByName(decisionBtn, "Spr_mjTile")
					if mjTileSpr then
						if #cardList_bar == 1 then
							mjTileSpr:setSpriteFrame(string.format("p4s%d_%d.png", cardList_bar[1].mjColor, cardList_bar[1].mjNumber))
							mjTileSpr:setVisible(true)
						else
							mjTileSpr:setVisible(false)
						end
					end

				-- elseif decisionData.flag == 7 or decisionData.flag == 8 then
				-- 	-- 明暗补
				-- 	decisionBtn = gt.seekNodeByName(selfDrawnDcsNode, "Btn_decisionBu")
				-- 	local isExistBarBu = false
				-- 	-- dump(btn_presentList)
				-- 	for _,v in ipairs(btn_presentList) do
				-- 		-- 补的显示优先级为3
				-- 		if v[1] == 3 then
				-- 			isExistBarBu = true
				-- 			break
				-- 		end
				-- 	end
				-- 	if not isExistBarBu then
				-- 		table.insert(btn_presentList,{3,decisionBtn})
				-- 	end
				-- 	-- 显示补
				-- 	local mjTileSpr = gt.seekNodeByName(decisionBtn, "Spr_mjTile")
				-- 	if mjTileSpr then
				-- 		if #cardList_bu == 1 then
				-- 			mjTileSpr:setSpriteFrame(string.format("p4s%d_%d.png", cardList_bu[1].mjColor, cardList_bu[1].mjNumber))
				-- 			mjTileSpr:setVisible(true)
				-- 		else
				-- 			mjTileSpr:setVisible(false)
				-- 		end
				-- 	end
				else
					--
				end

				decisionBtn:setVisible(true)
				decisionBtn:setTag(idx)

				-- 可杠
				if decisionData.flag == 3 or decisionData.flag == 4 or decisionData.flag == 7 then
					if #cardList_bar == 1 then
						gt.addBtnPressedListener(decisionBtn, function(sender)
							self.isPlayerDecision = false

							local selfDrawnDcsNode = gt.seekNodeByName(self.rootNode, "Node_selfDrawnDecision")
							selfDrawnDcsNode:setVisible(false)

							-- 删除弹出框（杠）
							self:removeFlimLayer(PlaySceneCS.FLIMTYPE.FLIMLAYER_BAR)
							-- 删除弹出框（补）
							self:removeFlimLayer(PlaySceneCS.FLIMTYPE.FLIMLAYER_BU)
							gt.log("显示杠发送的数据")
							-- 发送消息
							local btnTag = sender:getTag()
							local decisionData = decisionTypes[sender:getTag()]
							local msgToSend = {}
							msgToSend.m_msgId = gt.CG_SHOW_MJTILE
							msgToSend.m_type = decisionData.flag
							msgToSend.m_think = {}
							-- if self.playType ~= gt.RoomType.ROOM_CHANGSHA then
							-- 	if msgToSend.m_type == 3 then
							-- 		msgToSend.m_type = 7
							-- 		elseif msgToSend.m_type == 4 then
							-- 		msgToSend.m_type = 8
							-- 	end
							-- end
							local think_temp = {decisionData.cardList[1].mjColor,decisionData.cardList[1].mjNumber}
							table.insert(msgToSend.m_think,think_temp)
							gt.socketClient:sendMessage(msgToSend)

							--if self.playType == gt.RoomType.ROOM_CHANGSHA then
								self.isPlayerShow = false
							--end

							-- dump(msgToSend)
							-- dump(decisionData)

						end)
					else
						gt.addBtnPressedListener(decisionBtn, function(sender)
							-- 删除弹出框（杠）
							self:removeFlimLayer(PlaySceneCS.FLIMTYPE.FLIMLAYER_BAR)
							-- 删除弹出框（补）
							self:removeFlimLayer(PlaySceneCS.FLIMTYPE.FLIMLAYER_BU)
							-- add new
							local flimLayer = self:createFlimLayer(PlaySceneCS.FLIMTYPE.FLIMLAYER_BAR,cardList_bar)
							self:addChild(flimLayer,PlaySceneCS.ZOrder.FLIMLAYER,PlaySceneCS.TAG.FLIMLAYER_BAR)
							flimLayer:ignoreAnchorPointForPosition(false)
							flimLayer:setAnchorPoint(0.5,0)
							local pos_x = 0
							if decisionBtn:getPositionX()+flimLayer:getContentSize().width/2 > gt.winSize.width then
								flimLayer:setPositionX(gt.winSize.width-flimLayer:getContentSize().width/2)
							elseif decisionBtn:getPositionX()-flimLayer:getContentSize().width/2 < 0 then
								flimLayer:setPositionX(flimLayer:getContentSize().width/2)
							else
							flimLayer:setPositionX(decisionBtn:getPositionX())
							end
							flimLayer:setPositionY(decisionBtn:getPositionY()+flimLayer:getContentSize().height/2)
						end)
					end
				-- elseif decisionData.flag == 7 or decisionData.flag == 8 then   -- 补张
				-- 	if #cardList_bu == 1 then
				-- 		gt.addBtnPressedListener(decisionBtn, function(sender)
				-- 		self.isPlayerDecision = false

				-- 		local selfDrawnDcsNode = gt.seekNodeByName(self.rootNode, "Node_selfDrawnDecision")
				-- 		selfDrawnDcsNode:setVisible(false)

				-- 		-- 删除弹出框（杠）
				-- 		self:removeFlimLayer(PlaySceneCS.FLIMTYPE.FLIMLAYER_BAR)
				-- 		-- 删除弹出框（补）
				-- 		self:removeFlimLayer(PlaySceneCS.FLIMTYPE.FLIMLAYER_BU)

				-- 		-- 发送消息
				-- 		local btnTag = sender:getTag()
				-- 		local decisionData = decisionTypes[sender:getTag()]
				-- 		local msgToSend = {}
				-- 		msgToSend.m_msgId = gt.CG_SHOW_MJTILE
				-- 		msgToSend.m_type = decisionData.flag
				-- 		msgToSend.m_think = {}

				-- 		local think_temp = {decisionData.cardList[1].mjColor,decisionData.cardList[1].mjNumber}
				-- 		table.insert(msgToSend.m_think,think_temp)
				-- 		gt.socketClient:sendMessage(msgToSend)
				-- 		end)
				-- 	else
				-- 		gt.addBtnPressedListener(decisionBtn, function(sender)
				-- 			-- 删除弹出框（杠）
				-- 			self:removeFlimLayer(PlaySceneCS.FLIMTYPE.FLIMLAYER_BAR)
				-- 			-- 删除弹出框（补）
				-- 			self:removeFlimLayer(PlaySceneCS.FLIMTYPE.FLIMLAYER_BU)
				-- 			-- add new
				-- 			local flimLayer = self:createFlimLayer(PlaySceneCS.FLIMTYPE.FLIMLAYER_BU,cardList_bu)
				-- 			self:addChild(flimLayer,PlaySceneCS.ZOrder.FLIMLAYER,PlaySceneCS.TAG.FLIMLAYER_BU)
				-- 			flimLayer:ignoreAnchorPointForPosition(false)
				-- 			flimLayer:setAnchorPoint(0.5,0)
				-- 			local pos_x = 0
				-- 			if decisionBtn:getPositionX()+flimLayer:getContentSize().width/2 > gt.winSize.width then
				-- 				flimLayer:setPositionX(gt.winSize.width-flimLayer:getContentSize().width/2)
				-- 			elseif decisionBtn:getPositionX()-flimLayer:getContentSize().width/2 < 0 then
				-- 				flimLayer:setPositionX(flimLayer:getContentSize().width/2)
				-- 			else
				-- 				flimLayer:setPositionX(decisionBtn:getPositionX())
				-- 			end
				-- 			flimLayer:setPositionY(decisionBtn:getPositionY()+flimLayer:getContentSize().height/2)
				-- 			gt.log(flimLayer:getPositionX())
				-- 		end)
				-- 	end
				else
					gt.addBtnPressedListener(decisionBtn, function(sender)
						self.isPlayerDecision = false

						local selfDrawnDcsNode = gt.seekNodeByName(self.rootNode, "Node_selfDrawnDecision")
						selfDrawnDcsNode:setVisible(false)

						-- 删除弹出框（杠）
						self:removeFlimLayer(PlaySceneCS.FLIMTYPE.FLIMLAYER_BAR)
						-- 删除弹出框（补）
						self:removeFlimLayer(PlaySceneCS.FLIMTYPE.FLIMLAYER_BU)

						-- 发送消息
						local btnTag = sender:getTag()
						local decisionData = decisionTypes[sender:getTag()]
						local msgToSend = {}
						msgToSend.m_msgId = gt.CG_SHOW_MJTILE

						msgToSend.m_type = decisionData.flag
						msgToSend.m_think = {}

						local think_temp = {decisionData.mjColor,decisionData.mjNumber}
						table.insert(msgToSend.m_think,think_temp)
						gt.socketClient:sendMessage(msgToSend)
					end)
				end
			end

			-- 根据显示优先级进行排序
			table.sort(btn_presentList, function(a, b)
				return a[1] < b[1]
			end)
			-- 根据排序好的优先级进行显示按钮
			for _,v in ipairs(btn_presentList) do
				beginPos = cc.p(beginPos.x - btnSpace , beginPos.y)
				v[2]:setPosition(beginPos)
			end

		end
	else
		-- 摸牌
		-- 添加牌
		if msgTbl.m_flag == 0 then
			-- roomPlayer.mjTilesRemainCount = roomPlayer.mjTilesRemainCount + 1
			-- roomPlayer.holdMjTiles[roomPlayer.mjTilesRemainCount].mjTileSpr:setVisible(true)
			local mjTilesReferPos = roomPlayer.mjTilesReferPos
			local mjTilePos = mjTilesReferPos.holdStart
			mjTilePos = cc.pAdd(mjTilePos, cc.pMul(mjTilesReferPos.holdSpace, roomPlayer.mjTilesRemainCount))
			roomPlayer.mjTilesRemainCount = roomPlayer.mjTilesRemainCount + 1
			local vv = roomPlayer.holdMjTiles[roomPlayer.mjTilesRemainCount].mjTileSpr
			vv:setVisible(true)
			local dn = self.playerSeatIdx-seatIdx
			if self.maxPlayer == 4 then
				if dn == 2 or dn == -2 then
					vv:setPosition( cc.pAdd(mjTilePos,cc.p(-15,0)) )
				elseif dn == -1 or dn == 3 then
					vv:setPosition( cc.pAdd(mjTilePos,cc.p(0,30)) )
				elseif dn == 1 or dn == -3 then
					vv:setPosition( cc.pAdd(mjTilePos,cc.p(0,-40)) )
				end
			elseif self.maxPlayer == 3 then 
				if dn == 2 or dn == -2 then
					vv:setPosition( cc.pAdd(mjTilePos,cc.p(0,0)) )
				elseif dn == -1 or dn == 3 then
					vv:setPosition( cc.pAdd(mjTilePos,cc.p(0,30)) )
				elseif dn == 1 or dn == -3 then
					vv:setPosition( cc.pAdd(mjTilePos,cc.p(0,-40)) )
				end
			end
		end
	end
end

-- start --
--------------------------------
-- @class function
-- @description 广播玩家出牌
-- end --
function PlaySceneCS:onRcvSyncShowMjTile(msgTbl)
	gt.log("广播玩家出牌——onRcvSyncShowMjTile")
	-- dump(msgTbl)
	if msgTbl.m_errorCode ~= 0 then
		return
	end
	-- 座位号（1，2，3，4）
	local seatIdx = msgTbl.m_pos + 1
	local roomPlayer = self.roomPlayers[seatIdx]
	if msgTbl.m_type == 2 then
		-- 自摸胡, 为什么会有这种类型。
		self:showDecisionAnimation(seatIdx, PlaySceneCS.DecisionType.SELF_DRAWN_WIN, msgTbl.m_hu)
	elseif msgTbl.m_type == 1 then
		-- 显示出的牌
		if self.startMjTileAnimation ~= nil then
			self.startMjTileAnimation:stopAllActions()
			self.startMjTileAnimation:removeFromParent()
			self.startMjTileAnimation = nil
			self:addAlreadyOutMjTiles(self.preShowSeatIdx, self.startMjTileColor, self.startMjTileNumber)
		end

		-- 出牌动作
		local mjTilesReferPos = roomPlayer.mjTilesReferPos
		local mjTilePos = mjTilesReferPos.holdStart
		local realpos = cc.pAdd(mjTilePos, cc.pMul(mjTilesReferPos.holdSpace, roomPlayer.mjTilesRemainCount))

		if seatIdx ~= self.playerSeatIdx then
			if (next(msgTbl.m_think) ~= nil) then
					local  mj_color = msgTbl.m_think[1][1]
					local  mj_number = msgTbl.m_think[1][2]
					self:showMjTileAnimation(seatIdx, realpos, mj_color, mj_number,function()
						-- 显示出的牌
						self:addAlreadyOutMjTiles(seatIdx, mj_color, mj_number)
						-- 显示出的牌箭头标识
						self:showOutMjtileSign(seatIdx)
					end)
			end
		else
			if (next(msgTbl.m_think) ~= nil) then
					local  mj_color = msgTbl.m_think[1][1]
					local  mj_number = msgTbl.m_think[1][2]
					self:showMjTileAnimation(seatIdx, cc.p(self.chooseMjTile.mjTileSpr:getPositionX(),self.chooseMjTile.mjTileSpr:getPositionY()), mj_color, mj_number,function()
						-- 显示出的牌
						self:addAlreadyOutMjTiles(seatIdx, mj_color, mj_number)
						-- 显示出的牌箭头标识
						self:showOutMjtileSign(seatIdx)
					end)
			end
		end

		-- if seatIdx == self.playerSeatIdx then
		-- 	-- 玩家持有牌中去除打出去的牌
		-- 	local mjTile = roomPlayer.holdMjTiles[self.chooseMjTileIdx]
		-- 	mjTile.mjTileSpr:removeFromParent()
		-- 	table.remove(roomPlayer.holdMjTiles, self.chooseMjTileIdx)

		-- 	self:sortPlayerMjTiles()
		-- else
		-- 	roomPlayer.holdMjTiles[roomPlayer.mjTilesRemainCount].mjTileSpr:setVisible(false)
		-- 	roomPlayer.mjTilesRemainCount = roomPlayer.mjTilesRemainCount - 1
		-- end

		if seatIdx == self.playerSeatIdx then
			-- 玩家持有牌中去除打出去的牌

			if (next(msgTbl.m_think) ~= nil) then
				-- local isRemove = false
				local  mj_color = msgTbl.m_think[1][1]
				local  mj_number = msgTbl.m_think[1][2]
				for i = #roomPlayer.holdMjTiles, 1, -1 do
					local mjTile = roomPlayer.holdMjTiles[i]
					if mjTile.mjColor == mj_color and mjTile.mjNumber == mj_number then
						mjTile.mjTileSpr:removeFromParent()
						table.remove(roomPlayer.holdMjTiles, i)
						-- isRemove = true
						break
					end
				end
				-- if not isRemove then
				-- 	local mjTile = roomPlayer.holdMjTiles[self.chooseMjTileIdx]
				-- 	if mjTile and mjTile.mjTileSpr then
				-- 		mjTile.mjTileSpr:removeFromParent()
				-- 		table.remove(roomPlayer.holdMjTiles, self.chooseMjTileIdx)
				-- 	end
				-- end
			end
			self:sortPlayerMjTiles()
			
		else
			roomPlayer.holdMjTiles[roomPlayer.mjTilesRemainCount].mjTileSpr:setVisible(false)
			roomPlayer.mjTilesRemainCount = roomPlayer.mjTilesRemainCount - 1
		end

		-- 记录出牌的上家
		self.preShowSeatIdx = seatIdx

		if (next(msgTbl.m_think) ~= nil) then
			local  mj_color = msgTbl.m_think[1][1]
			local  mj_number = msgTbl.m_think[1][2]
			if roomPlayer.sex == 1 then
				-- 男性
				gt.soundEngine:playEffect(string.format("man/mjt%d_%d", mj_color, mj_number))
			else
				-- 女性
				gt.soundEngine:playEffect(string.format("woman/mjt%d_%d", mj_color, mj_number))
			end
		end
	elseif msgTbl.m_type == 3 then
		-- 暗杠
		gt.log("     暗杠     ")
		if (next(msgTbl.m_think) ~= nil) then
			local msgTable = {}
			msgTable.m_color = msgTbl.m_think[1][1]
			msgTable.m_number = msgTbl.m_think[1][2]
			
			self:showDecisionAnimation(seatIdx, PlaySceneCS.DecisionType.DARK_BAR)
			self:addMjTileBar(seatIdx, msgTable.m_color, msgTable.m_number, false)
			self:hideOtherPlayerMjTiles(seatIdx, true, false)
			
			self:sortPlayerMjTiles()
		end
	-- elseif msgTbl.m_type == 7 then
	-- 	-- 直杠
	-- 	gt.log("   抚州碰转明杠       ")
	-- 	if (next(msgTbl.m_think) ~= nil) then
	-- 		local  mj_color = msgTbl.m_think[1][1]
	-- 		local  mj_number = msgTbl.m_think[1][2]
	-- 		self:addMjTileBar(seatIdx, mj_color, mj_number, false)
	-- 		self:hideOtherPlayerMjTiles(seatIdx, true, true)
	-- 		self:showDecisionAnimation(seatIdx, PlaySceneCS.DecisionType.BRIGHT_BAR)
	-- 	end
	elseif msgTbl.m_type == 4 or msgTbl.m_type == 7 then
		-- 碰转明杠
		gt.log("     碰转明杠     ")
		if (next(msgTbl.m_think) ~= nil) then
			local  mj_color = msgTbl.m_think[1][1]
			local  mj_number = msgTbl.m_think[1][2]
			self:changePungToBrightBar(seatIdx, mj_color, mj_number)
			self:showDecisionAnimation(seatIdx, PlaySceneCS.DecisionType.BRIGHT_BAR)
			self:sortPlayerMjTiles()
		end
	elseif msgTbl.m_type == 8 then
		-- 明补
		gt.log("     明补     ")
		if (next(msgTbl.m_think) ~= nil) then
			local  mj_color = msgTbl.m_think[1][1]
			local  mj_number = msgTbl.m_think[1][2]
			self:changePungToBrightBar(seatIdx, mj_color, mj_number)
			self:showDecisionAnimation(seatIdx, PlaySceneCS.DecisionType.BRIGHT_BU)
		end
	end
end


-- start --
--------------------------------
-- @class function
-- @description 广播玩家杠2张牌
-- end --
function PlaySceneCS:onRcvSyncBarTwoCard(msgTbl)

	local seatIdx = msgTbl.m_pos + 1
	-- 是否自摸（0:没有 1：自摸）
	local flag = msgTbl.m_flag
	-- 如果胡了则不需要展示
	if flag == 1 then
		return
	end
	-- 显示杠后两张牌
	self:showBarTwoCardAnimation(seatIdx,msgTbl.m_card)
end

-- start --
--------------------------------
-- @class function
-- @description 展示杠两张牌
-- end --
function PlaySceneCS:showBarTwoCardAnimation(seatIdx,cardList)
	local roomPlayer = self.roomPlayers[seatIdx]

	local mjTileName = string.format("p4s%d_%d.png", 2, 2)
	local mjTileSpr = cc.Sprite:createWithSpriteFrameName(mjTileName)
	local width_oneMJ = mjTileSpr:getContentSize().width
	local width = 30+mjTileSpr:getContentSize().width*(#cardList)
	local height = 24+mjTileSpr:getContentSize().height
	-- 添加半透明底
	local image_bg = ccui.ImageView:create()
	image_bg:loadTexture("images/otherImages/laoyue_bg.png")
	image_bg:setScale9Enabled(true)
	image_bg:setCapInsets(cc.rect(10,10,1,1))
	image_bg:setContentSize(cc.size(width,height))
	image_bg:setAnchorPoint(cc.p(0.5,0.5))
	self:addChild(image_bg,PlaySceneCS.ZOrder.HAIDILAOYUE)
	image_bg:setScale(0)
	-- 设置坐标位置
	local  m_curPos_x = 1
	local  m_curPos_y = 1
	if roomPlayer.displaySeatIdx == 1 or roomPlayer.displaySeatIdx == 3 then
		m_curPos_x = roomPlayer.mjTilesReferPos.holdStart.x
		m_curPos_y = roomPlayer.mjTilesReferPos.showMjTilePos.y
	elseif roomPlayer.displaySeatIdx == 2 or roomPlayer.displaySeatIdx == 4 then
		m_curPos_x = roomPlayer.mjTilesReferPos.showMjTilePos.x
		m_curPos_y = roomPlayer.mjTilesReferPos.showMjTilePos.y
	end

	-- image_bg:setPosition(roomPlayer.mjTilesReferPos.showMjTilePos)
	image_bg:setPosition(cc.p(m_curPos_x,m_curPos_y))

	-- 添加两个麻将
	-- dump(cardList)
	for _,v in pairs(cardList) do
		gt.log("88888888888")
		gt.log(v[1])
		gt.log(v[2])
		local mjSprName = string.format("p4s%d_%d.png", v[1], v[2])
		local image_mj = ccui.Button:create()
		image_mj:loadTextures(mjSprName,mjSprName,"",ccui.TextureResType.plistType)
    	image_mj:setAnchorPoint(cc.p(0,0))
    	image_mj:setPosition(cc.p(15+width_oneMJ*(_-1), 10))
   		image_bg:addChild(image_mj)
	end

	-- 播放动画
	local scaleToAction = cc.ScaleTo:create(0.2, 1)
	local easeBackAction = cc.EaseBackOut:create(scaleToAction)
	local present_delayTime = cc.DelayTime:create(1.5)
	local fadeOutAction = cc.FadeOut:create(0.5)
	local callFunc_dontPresent = cc.CallFunc:create(function(sender)
		-- 播放完后隐藏
		sender:setVisible(false)
	end)
	local callFunc_present_first = cc.CallFunc:create(function(sender)
		-- 打出第一张牌
		gt.log("打出第一张牌")
		for idx,data in pairs(cardList) do
			if 1 == idx then
   				self:discardsOneCard(seatIdx,data[1], data[2])
   				break
   			end
		end
	end)
	local delayTime_f_s = cc.DelayTime:create(0.7)
	local callFunc_present_second = cc.CallFunc:create(function(sender)
		-- 打出第二张牌
		gt.log("打出第二张牌")
		for idx,data in pairs(cardList) do
			if 2 == idx then
   				self:discardsOneCard(seatIdx,data[1], data[2])
   				break
   			end
		end
	end)
	local callFunc_remove = cc.CallFunc:create(function(sender)
		-- 播放完后移除
		sender:removeFromParent()
	end)
	local seqAction = cc.Sequence:create(easeBackAction, present_delayTime, fadeOutAction, callFunc_dontPresent,
		callFunc_present_first, delayTime_f_s, callFunc_present_second,callFunc_remove)
	image_bg:runAction(seqAction)

end

function PlaySceneCS:discardsOneCard(seatIdx,mjColor,mjNumber)
	gt.log("先出一张牌")
	gt.log(seatIdx)
	gt.log(mjColor)
	gt.log(mjNumber)
	local roomPlayer = self.roomPlayers[seatIdx]
	gt.log("roomPlayer")
	-- dump(roomPlayer)
	local mjTilesReferPos = roomPlayer.mjTilesReferPos
	gt.log("mjTilesReferPos")
	-- dump(mjTilesReferPos)
	local mjTilePos = mjTilesReferPos.holdStart
	gt.log("mjTilePos")
	-- dump(mjTilePos)
	local realpos = cc.pAdd(mjTilePos, cc.pMul(mjTilesReferPos.holdSpace, roomPlayer.mjTilesRemainCount))
	gt.log("realpos")
	-- dump(realpos)
	-- 显示出的牌
	self:addAlreadyOutMjTiles(seatIdx, mjColor, mjNumber)
	-- 显示出的牌箭头标识
	self:showOutMjtileSign(seatIdx)

	-- 记录出牌的上家
	self.preShowSeatIdx = seatIdx

	if roomPlayer.sex == 1 then
		-- 男性
		gt.soundEngine:playEffect(string.format("man/mjt%d_%d", mjColor, mjNumber))
	else
		-- 女性
		gt.soundEngine:playEffect(string.format("woman/mjt%d_%d", mjColor, mjNumber))
	end
end

-- start --
--------------------------------
-- @class function
-- @description 显示玩家开局胡牌动画,比如 1-缺一色 2-板板胡 3-大四喜 4-六六顺
-- @param seatIdx 座位索引
-- @param decisionType 决策类型
-- end --
function PlaySceneCS:showStartDecisionAnimation(seatIdx, decisionType, showCard)
	-- 接炮胡，自摸胡，明杠，暗杠，碰文件后缀
	local decisionSuffixs = {1, 4, 2, 2, 3}
	local decisionSfx = {"queyise", "banbanhu", "sixi", "liuliushun"}
	-- 显示决策标识
	local roomPlayer = self.roomPlayers[seatIdx]
	local decisionSignSpr = cc.Sprite:createWithSpriteFrameName(string.format("tile_cs_%s.png", decisionSfx[decisionType]))
	decisionSignSpr:setPosition(roomPlayer.mjTilesReferPos.showMjTilePos)
	self.rootNode:addChild(decisionSignSpr, PlaySceneCS.ZOrder.DECISION_SHOW)
	-- 标识显示动画
	decisionSignSpr:setScale(0)
	local scaleToAction = cc.ScaleTo:create(0.2, 1)
	local easeBackAction = cc.EaseBackOut:create(scaleToAction)
	local fadeOutAction = cc.FadeOut:create(0.5)
	local callFunc = cc.CallFunc:create(function(sender)
		-- 播放完后移除
		sender:removeFromParent()
	end)
	local seqAction = cc.Sequence:create(easeBackAction, fadeOutAction, callFunc)
	decisionSignSpr:runAction(seqAction)

	local groupNode = cc.Node:create()
	groupNode:setCascadeOpacityEnabled( true )
	groupNode:setPosition( roomPlayer.mjTilesReferPos.showMjTilePos )
	self.playMjLayer:addChild(groupNode)

	local mjTilesReferPos = roomPlayer.mjTilesReferPos

	
	local demoSpr = cc.Sprite:createWithSpriteFrameName( string.format("p%ds%d_%d.png", roomPlayer.displaySeatIdx, 1, 1) )
	local tileWidthX = 0
	local tileWidthY = 0
	if roomPlayer.displaySeatIdx == 1 then
		tileWidthX = 0
		tileWidthY = mjTilesReferPos.outSpaceH.y--demoSpr:getContentSize().height
	elseif roomPlayer.displaySeatIdx == 2 then
		tileWidthX = -demoSpr:getContentSize().width
		tileWidthY = 0
	elseif roomPlayer.displaySeatIdx == 3 then
		tileWidthX = 0
		tileWidthY = -mjTilesReferPos.outSpaceH.y--demoSpr:getContentSize().height
	elseif roomPlayer.displaySeatIdx == 4 then
		tileWidthX = demoSpr:getContentSize().width
		tileWidthY = 0
	end

	-- -- 自己测试走这里
	-- local totalWidthX = (#showCard*copyNum)*tileWidthX
	-- local totalWidthY = (#showCard*copyNum)*tileWidthY
	-- for i,v in ipairs(showCard) do
	-- 	for j=1,copyNum do
	-- 		local mjTileName = string.format("p%ds%d_%d.png", roomPlayer.displaySeatIdx, v[1], v[2])
	-- 		local mjTileSpr = cc.Sprite:createWithSpriteFrameName( mjTileName )
	-- 		mjTileSpr:setPosition( cc.p(tileWidthX*(j-1)+(i-1)*copyNum*tileWidthX,tileWidthY*(j-1)+(i-1)*copyNum*tileWidthY) )
	-- 		groupNode:addChild( mjTileSpr, (gt.winSize.height - mjTileSpr:getPositionY()) )
	-- 	end
	-- end
	-- groupNode:setPosition( cc.pAdd( roomPlayer.mjTilesReferPos.showMjTilePos, cc.p(-totalWidthX/2,-totalWidthY/2) ) )

	-- 服务器返回消息
	local totalWidthX = (#showCard)*tileWidthX
	local totalWidthY = (#showCard)*tileWidthY
	for i,v in ipairs(showCard) do
		local mjTileName = string.format("p%ds%d_%d.png", roomPlayer.displaySeatIdx, v[1], v[2])
		local mjTileSpr = cc.Sprite:createWithSpriteFrameName( mjTileName )
		mjTileSpr:setPosition( cc.p(tileWidthX*(i-1),tileWidthY*(i-1)) )
		groupNode:addChild( mjTileSpr, (gt.winSize.height - mjTileSpr:getPositionY()) )
	end
	groupNode:setPosition( cc.pAdd( roomPlayer.mjTilesReferPos.showMjTilePos, cc.p(-totalWidthX/2,-totalWidthY/2) ) )

	-- 显示3s,渐隐消失
	local delayTime = cc.DelayTime:create(3)
	local fadeOutAction = cc.FadeOut:create(2)
	local callFunc = cc.CallFunc:create(function(sender)
		sender:removeFromParent()
	end)
	groupNode:runAction(cc.Sequence:create(delayTime, fadeOutAction, callFunc))

	-- 播放音效,没有资源,暂时用暗杠来代替
	if roomPlayer.sex == 1 then
		-- 男性
		gt.soundEngine:playEffect(string.format("changsha/man/%s", decisionSfx[decisionType]))
	else
		-- 女性
		gt.soundEngine:playEffect(string.format("changsha/woman/%s", decisionSfx[decisionType]))
	end
end

-- start --
--------------------------------
-- @class function
-- @description 通知玩家决策
-- end --
function PlaySceneCS:onRcvMakeDecision(msgTbl)
	-- dump(msgTbl,"_____通知玩家决策____")

	self.isShowEat = false
	if msgTbl.m_flag == 1 then
		-- 玩家决策
		self.isPlayerDecision = true

		-- 决策倒计时
		self:playTimeCDStart(msgTbl.m_time)

		-- 玩家决策
		local decisionTypes = msgTbl.m_think --玩家决策类型
		-- 最后加入决策"过"选项
		--table.insert(decisionTypes, 0)  --插入过类型
		local pass = {0,{}}
		table.insert(decisionTypes, pass)
		-- 显示对应的决策按键
		local decisionBtnNode = gt.seekNodeByName(self.rootNode, "Node_decisionBtn") --显示所有的按键决策
		decisionBtnNode:setVisible(true)

		for _, decisionBtn in ipairs(decisionBtnNode:getChildren()) do
			decisionBtn:setVisible(false)
		end
		local Btn_decision_0 = gt.seekNodeByName(decisionBtnNode, "Btn_decision_0")
		local startPosX = Btn_decision_0:getPositionX()
		local posY = Btn_decision_0:getPositionY()

		local noSame = {}
		for i, v in ipairs(decisionTypes) do
			local isExist = false
			-- 这儿为什么会重复？？
			table.foreach(noSame, function(k, m)
				if m[1] == v[1] then
					isExist = true
					return false
				end
			end)
			if not isExist then
				table.insert(noSame, v)
			end
		end
		-- dump(noSame)
		local posTag = #noSame
		--self.result1 = nil
		--self.result2 = nil
		for i, v in ipairs(noSame) do
			-- 1-出牌 2-胡，3-暗杠 4-明杠，5-碰，6-吃，7-暗补、8-明补
			local m_type = nil
			if v[1] == 0 then
				m_type = 0
			elseif v[1] == 2 then
				m_type = 1
			elseif v[1] == 3 or v[1] == 4 then
				m_type = 2
			elseif v[1] == 5 then
				m_type = 3
			elseif v[1] == 6 then
				m_type = 4
			elseif v[1] == 7  then
				m_type = 2
			end
			-- if self.playType ~= gt.RoomType.ROOM_CHANGSHA and m_type == 5 then
			-- 	m_type = 2
			-- end
			posTag = posTag - 1
			local decisionBtn = gt.seekNodeByName(decisionBtnNode, "Btn_decision_" .. m_type)

			if decisionBtn:getChildByTag(5) then
				decisionBtn:getChildByTag(5):removeFromParent()
			end
			decisionBtn:setTag(v[1])
			decisionBtn:setVisible(true)

			decisionBtn:setPosition(cc.p(startPosX - posTag * Btn_decision_0:getContentSize().width * 2, posY))
			-- 显示要碰，杠，胡的牌
			local mjTileSpr = gt.seekNodeByName(decisionBtn, "Spr_mjTile")
		
			if mjTileSpr then
				mjTileSpr:setSpriteFrame(string.format("p4s%d_%d.png", msgTbl.m_color, msgTbl.m_number))
				if gt.turnCard and #gt.turnCard > 0 then
					mjTileSpr:removeAllChildren()
					local turnTile = nil
					if  msgTbl.m_color == gt.turnCard[1][1] and msgTbl.m_number == gt.turnCard[1][2] then
						turnTile = cc.Sprite:create("images/otherImages/s_sanjiao.png")
						mjTileSpr:addChild(turnTile)
						turnTile:setPosition(cc.p(mjTileSpr:getContentSize().width - turnTile:getContentSize().width / 2, mjTileSpr:getContentSize().height - turnTile:getContentSize().height / 2))
						--turnTile:setPosition(cc.p(turnTile:getContentSize().width / 2, mjTileSpr:getContentSize().height - turnTile:getContentSize().height / 2))
						--turnTile:setPosition(cc.p(mjTileSpr:getContentSize().width / 2, mjTileSpr:getContentSize().height / 2 + 20))
					elseif msgTbl.m_color == gt.turnCard[2][1] and  msgTbl.m_number == gt.turnCard[2][2] then
						turnTile = cc.Sprite:create("images/otherImages/s_sanjiao.png")
						mjTileSpr:addChild(turnTile)
						turnTile:setPosition(cc.p(mjTileSpr:getContentSize().width - turnTile:getContentSize().width / 2, mjTileSpr:getContentSize().height - turnTile:getContentSize().height / 2))
						--turnTile:setPosition(cc.p(mjTileSpr:getContentSize().width / 2, mjTileSpr:getContentSize().height / 2 - 20))
						--turnTile:setPosition(cc.p(turnTile:getContentSize().width / 2, mjTileSpr:getContentSize().height - turnTile:getContentSize().height / 2))
					end
				end
				mjTileSpr:setVisible(true)
			end
			

			-- 响应决策按键事件
			gt.addBtnPressedListener(decisionBtn, function(sender)
				local function makeDecision(decisionType, m_type)

					self.isPlayerDecision = false
					self.isShowEat = false

					-- 隐藏决策按键
					local decisionBtnNode = gt.seekNodeByName(self.rootNode, "Node_decisionBtn")
					decisionBtnNode:setVisible(false)
					-- 发送决策消息
					local msgToSend = {}

					msgToSend.m_msgId = gt.CG_PLAYER_DECISION
					msgToSend.m_type = decisionType
					msgToSend.m_think = {{msgTbl.m_color,msgTbl.m_number}}
					gt.socketClient:sendMessage(msgToSend)
				end

				local decisionType = sender:getTag()
				gt.log("=======3333333==",decisionType,self.isShowEat)
				if decisionType == 6 then  --吃牌

					local function sendEatMssage(result1, result2)
						self.isPlayerDecision = false --决策标识为false
						self.isShowEat = false
						-- 隐藏决策按键
						local decisionBtnNode = gt.seekNodeByName(self.rootNode, "Node_decisionBtn")
						decisionBtnNode:setVisible(false)

						-- 发送决策消息
						local msgToSend = {}
						msgToSend.m_msgId = gt.CG_PLAYER_DECISION
						msgToSend.m_type = 6
						msgToSend.m_think = {{msgTbl.m_color,result1},{msgTbl.m_color,result2}} -- wxg msgTbl.m_color又是哪里来的?
						gt.socketClient:sendMessage(msgToSend)
					end


					if self.isShowEat then
						-- 为什么这个地方会是true

						-- if self.result1 ~= nil  and self.result2 ~= nil then
						-- 	sendEatMssage(self.result1, self.result2)
						-- end
						return
					end
					self.isShowEat = true
					local showMjEatTable = {} --要显示的吃的牌
					for _, m in pairs(decisionTypes) do
						if m[1] == 6 then
							table.insert(showMjEatTable, {m[2][1][2], msgTbl.m_number, m[2][2][2]})
						end
					end
					-- dump(showMjEatTable)
					
					local eatBg = cc.Scale9Sprite:create("images/otherImages/tipsbg.png")
					eatBg:setContentSize(cc.size(#showMjEatTable * 3 * mjTileSpr:getContentSize().width + #showMjEatTable * 25, decisionBtn:getContentSize().height))
					local menu = cc.Menu:create()

					local pos = 0
					local mjWidth = 0

					for i, mjNumber in pairs(showMjEatTable) do
						pos = pos + 1

						for j = 1, 3 do
							local mjTileName = string.format("p4s%d_%d.png", msgTbl.m_color, mjNumber[j]) --获取图片
							local mjTileSpr = cc.Sprite:createWithSpriteFrameName(mjTileName)  --创建精灵
							if tonumber(mjNumber[j]) == tonumber(msgTbl.m_number) then
								mjTileSpr:setColor(cc.c3b(255,255,0))
							end

							if gt.turnCard and #gt.turnCard > 0 then
								gt.log("======1112233==" .. gt.turnCard[1][1])
								local turnTile = nil
								if  msgTbl.m_color == gt.turnCard[1][1] and mjNumber[j] == gt.turnCard[1][2] then
									gt.log("======33333===")
									turnTile = cc.Sprite:create("images/otherImages/s_sanjiao.png")
									mjTileSpr:addChild(turnTile)
									turnTile:setPosition(cc.p(mjTileSpr:getContentSize().width - turnTile:getContentSize().width / 2, mjTileSpr:getContentSize().height - turnTile:getContentSize().height / 2))
									--turnTile:setPosition(cc.p(turnTile:getContentSize().width / 2, mjTileSpr:getContentSize().height - turnTile:getContentSize().height / 2))
									--turnTile:setPosition(cc.p(mjTileSpr:getContentSize().width / 2, mjTileSpr:getContentSize().height / 2 + 20))
								elseif msgTbl.m_color == gt.turnCard[2][1] and  mjNumber[j] == gt.turnCard[2][2] then
									turnTile = cc.Sprite:create("images/otherImages/s_sanjiao.png")
									mjTileSpr:addChild(turnTile)
									turnTile:setPosition(cc.p(mjTileSpr:getContentSize().width - turnTile:getContentSize().width / 2, mjTileSpr:getContentSize().height - turnTile:getContentSize().height / 2))
									--turnTile:setPosition(cc.p(turnTile:getContentSize().width / 2, mjTileSpr:getContentSize().height - turnTile:getContentSize().height / 2))
									--turnTile:setPosition(cc.p(mjTileSpr:getContentSize().width / 2, mjTileSpr:getContentSize().height / 2 - 20))
								end
							end
							

							local menuItem = cc.MenuItemSprite:create(mjTileSpr,mjTileSpr) --创建菜单项
							menuItem:setTag(i)

							-- if (#showMjEatTable == 1) and (i == 1) and (j == 3) then
							-- 	local showResult = {}
							-- 	for n = 1, 3 do
							-- 		if msgTbl.m_number ~= showMjEatTable[1][n] then
							-- 			table.insert(showResult,showMjEatTable[1][n])
							-- 		end
							-- 	end
							-- 	self.result1 = showResult[1]
							-- 	self.result2 = showResult[2]
							-- end

							local function menuCallBack(i, sender)
								local result = {}
								for m, eat in pairs(showMjEatTable) do
									if m == i then
										for n = 1, 3 do
											if msgTbl.m_number ~= showMjEatTable[m][n] then
												table.insert(result,showMjEatTable[m][n])
											end
										end
									end
								end
								sendEatMssage(result[1], result[2])
							end
							menuItem:registerScriptTapHandler(menuCallBack)

							menuItem:setPosition(cc.p(mjWidth  + (pos - 1) * 10, eatBg:getContentSize().height / 2))
							menu:addChild(menuItem)
							mjWidth = mjWidth + mjTileSpr:getContentSize().width

						end
					end
					eatBg:addChild(menu)
					--menu:setPosition(eatBg:getContentSize().width * 0.5 - mjWidth * 0.5 + #showMjEatTable / 3 * 15,0)
					if pos == 1 then
						menu:setPosition(eatBg:getContentSize().width * 0.5 - mjWidth * 0.5 + mjTileSpr:getContentSize().width * 0.5 ,0)
					elseif pos == 2 then
						menu:setPosition(eatBg:getContentSize().width * 0.5 - mjWidth * 0.5 + mjTileSpr:getContentSize().width * 0.4 ,0)
					else
						menu:setPosition(eatBg:getContentSize().width * 0.5 - mjWidth * 0.5 + mjTileSpr:getContentSize().width * 0.3 ,0)
					end
					--menu:setPosition(0,0)
					sender:addChild(eatBg , -10, 5) -- wxg 这里作为sender的子类,当menuCallBack回调的时候,并没有销毁这个eatBg,导致下次再吃牌时
												 -- 这玩意还会被显示出来,表象即上次吃的牌类型,显示在了上面..
												 -- 记得在发送吃消息的时候,把eatBg删除掉
					eatBg:setPosition(0,eatBg:getContentSize().height * 1.5)
						
					--end
				elseif decisionType == 2 then --胡牌
					for _, m in pairs(decisionTypes) do
						if m[1] == 2 then
							self.isPlayerDecision = false
							-- 隐藏决策按键
							local decisionBtnNode = gt.seekNodeByName(self.rootNode, "Node_decisionBtn")
							decisionBtnNode:setVisible(false)
							-- 发送决策消息
							local msgToSend = {}
							msgToSend.m_msgId = gt.CG_PLAYER_DECISION
							msgToSend.m_type = decisionType
							msgToSend.m_think = m[2]
							gt.socketClient:sendMessage(msgToSend)
						end
					end
				else
					makeDecision(decisionType, 0)
				end

			end)
		end
	end

end

-- start --
--------------------------------
-- @class function
-- @description 广播决策结果
-- end --
function PlaySceneCS:onRcvSyncMakeDecision(msgTbl)

	if msgTbl.m_errorCode ~= 0 then
		return
	end

	dump(msgTbl,"____广播决策 结果____")
	-- 隐藏决策按键
	local decisionBtnNode = gt.seekNodeByName(self.rootNode, "Node_decisionBtn")
	if decisionBtnNode:isVisible() == true then

		local isCanHuFlag = false
		for _, decisionBtn in ipairs(decisionBtnNode:getChildren()) do
			if  decisionBtn:getName() == "Btn_decision_1" then
				if decisionBtn:isVisible() == true then
					isCanHuFlag = true
					break
				end

			end
		end

		if isCanHuFlag == true then -- 有胡
			for _, decisionBtn in ipairs(decisionBtnNode:getChildren()) do
				 if decisionBtn:getName() == "Btn_decision_0" or decisionBtn:getName() == "Btn_decision_1" then
					decisionBtn:setVisible(true)
				else
					decisionBtn:setVisible(false)
				end
			end
		end

		if isCanHuFlag == false then
			self.isPlayerDecision = false

			decisionBtnNode:setVisible( false )
		end

	end


	if msgTbl.m_think ~= 0 then -- 吃,碰,杠,胡
		if self.startMjTileAnimation ~= nil then
			self.startMjTileAnimation:stopAllActions()
			self.startMjTileAnimation:removeFromParent()
			self.startMjTileAnimation = nil
			self:addAlreadyOutMjTiles(self.preShowSeatIdx, self.startMjTileColor, self.startMjTileNumber, true)
		end
	end

	local seatIdx = msgTbl.m_pos + 1
	-- if self.maxPlayer == 3 and msgTbl.m_pos == 1 then
	-- 	seatIdx = 3
	-- elseif self.maxPlayer == 3 and msgTbl.m_pos == 2 then
	-- 	seatIdx = 4
	-- end

	if msgTbl.m_think[1] == 2 then
		-- 接炮胡
		self:showDecisionAnimation(seatIdx, PlaySceneCS.DecisionType.TAKE_CANNON_WIN, msgTbl.m_hu)
	elseif msgTbl.m_think[1] == 3 or  msgTbl.m_think[1] == 4 or  msgTbl.m_think[1] == 7 then
		
		self:addMjTileBar(seatIdx, msgTbl.m_color, msgTbl.m_number, true)
		-- 杠牌动画
		self:showDecisionAnimation(seatIdx, PlaySceneCS.DecisionType.BRIGHT_BAR)

		-- 隐藏持有牌中打出的牌
		self:hideOtherPlayerMjTiles(seatIdx, true, true)
		-- 移除上家打出的牌
		self:removePreRoomPlayerOutMjTile(msgTbl.m_color, msgTbl.m_number)
		
	elseif msgTbl.m_think[1] == 5 then
		-- 碰牌
		self:addMjTilePung(seatIdx, msgTbl.m_color, msgTbl.m_number)
		--self:addMjTilePung(seatIdx, msgTbl.m_color, msgTbl.m_think[1])
		-- 碰牌动画
		self:showDecisionAnimation(seatIdx, PlaySceneCS.DecisionType.PUNG)

		-- 隐藏持有牌中打出的牌
		self:hideOtherPlayerMjTiles(seatIdx, false)
		-- 移除上家打出的牌
		self:removePreRoomPlayerOutMjTile(msgTbl.m_color, msgTbl.m_number)
	elseif msgTbl.m_think[1] == 6 then
		local eatGroup = {}
		table.insert(eatGroup,{msgTbl.m_think[2][1][2], 0, msgTbl.m_color})
		table.insert(eatGroup,{msgTbl.m_number, 1, msgTbl.m_color})
		table.insert(eatGroup,{msgTbl.m_think[2][2][2], 0, msgTbl.m_color})

		-- 吃牌
		local roomPlayer = self.roomPlayers[seatIdx]
		table.insert(roomPlayer.mjTileEat, eatGroup)

		self:pungBarReorderMjTiles(seatIdx, msgTbl.m_color, eatGroup)
		-- 碰牌动画
		self:showDecisionAnimation(seatIdx, PlaySceneCS.DecisionType.EAT)

		-- 隐藏持有牌中打出的牌
		self:hideOtherPlayerMjTiles(seatIdx, false)
		-- 移除上家打出的牌
		self:removePreRoomPlayerOutMjTile(msgTbl.m_color, msgTbl.m_number)
	end
end


function PlaySceneCS:onRcvChatMsg(msgTbl)
	if msgTbl.m_type == 4 then
		--语音
		gt.soundEngine:pauseAllSound()
		require("json")

			local curUrl = string.gsub(msgTbl.m_musicUrl,"\\","")
			local respJson = json.decode(curUrl)--msgTbl.m_musicUrl
			local url = respJson.url
			local videoTime = respJson.duration
			gt.log("the play voide url is .." .. url)

			if gt.isIOSPlatform() then
				local ok = self.luaBridge.callStaticMethod("AppController", "playVoice", {voiceUrl = url})
			elseif gt.isAndroidPlatform() then
				local ok = self.luaBridge.callStaticMethod("org/cocos2dx/lua/AppActivity", "playVoice", {url}, "(Ljava/lang/String;)V")
			end

			self.yuyinChatNode:setVisible(true)
			self.rootNode:reorderChild(self.yuyinChatNode, 110)

			local seatIdx = msgTbl.m_pos + 1
			for i = 1, 4 do
				local chatBgImg = gt.seekNodeByName(self.yuyinChatNode, "Image_" .. i)
				chatBgImg:setVisible(false)
			end
			local roomPlayer = self.roomPlayers[seatIdx]
			local chatBgImg = gt.seekNodeByName(self.yuyinChatNode, "Image_" .. roomPlayer.displaySeatIdx)
			chatBgImg:setVisible(true)
			self.yuyinChatNode:stopAllActions()
			local fadeInAction = cc.FadeIn:create(0.5)
			local delayTime = cc.DelayTime:create(videoTime)
			local fadeOutAction = cc.FadeOut:create(0.5)
			local callFunc = cc.CallFunc:create(function(sender)
				sender:setVisible(false)
				gt.soundEngine:resumeAllSound()
			end)
			self.yuyinChatNode:runAction(cc.Sequence:create(fadeInAction, delayTime, fadeOutAction, callFunc))
		-- end
	else
		local chatBgNode = gt.seekNodeByName(self.rootNode, "Node_chatBg")
		chatBgNode:setVisible(true)
		local seatIdx = msgTbl.m_pos + 1
		for i = 1, self.maxPlayer do
			local chatBgImg = gt.seekNodeByName(chatBgNode, "Img_playerChatBg_" .. i)
			chatBgImg:setVisible(false)
		end
		local roomPlayer = self.roomPlayers[seatIdx]
		local chatBgImg = gt.seekNodeByName(chatBgNode, "Img_playerChatBg_" .. roomPlayer.displaySeatIdx)
		chatBgImg:setVisible(true)
		local msgLabel = gt.seekNodeByName(chatBgImg, "Label_msg")
		local emojiSpr = gt.seekNodeByName(chatBgImg, "Spr_emoji")
		local isTextMsg = false
		if msgTbl.m_type == gt.ChatType.FIX_MSG then
			msgLabel:setString(gt.getLocationString("LTKey_0028_" .. msgTbl.m_id))
			isTextMsg = true

			if roomPlayer.sex == 1 then
				-- 男性
				gt.soundEngine:playEffect("man/fix_msg_" .. msgTbl.m_id)
			else
				-- 女性
				gt.soundEngine:playEffect("woman/fix_msg_" .. msgTbl.m_id)
			end
		elseif msgTbl.m_type == gt.ChatType.INPUT_MSG then
			msgLabel:setString(msgTbl.m_msg)
			isTextMsg = true
		elseif msgTbl.m_type == gt.ChatType.EMOJI then
			emojiSpr:setSpriteFrame(msgTbl.m_msg)
			isTextMsg = false
		elseif msgTbl.m_type == gt.ChatType.VOICE_MSG then
		end

		msgLabel:setVisible(isTextMsg)
		emojiSpr:setVisible(not isTextMsg)
		local chatBgSize = chatBgImg:getContentSize()
		local bgWidth = chatBgSize.width
		if isTextMsg then
			local labelSize = msgLabel:getContentSize()
			bgWidth = labelSize.width + 30
			msgLabel:setPositionX(bgWidth * 0.5)
		else
			local emojiSize = emojiSpr:getContentSize()
			bgWidth = emojiSize.width + 50
			emojiSpr:setPositionX(bgWidth * 0.5)
		end
		chatBgImg:setContentSize(cc.size(bgWidth, chatBgSize.height))

		chatBgNode:stopAllActions()
		local fadeInAction = cc.FadeIn:create(0.5)
		local delayTime = cc.DelayTime:create(2)
		local fadeOutAction = cc.FadeOut:create(0.5)
		local callFunc = cc.CallFunc:create(function(sender)
			sender:setVisible(false)
		end)
		chatBgNode:runAction(cc.Sequence:create(fadeInAction, delayTime, fadeOutAction, callFunc))
	end

end

function PlaySceneCS:onRcvRoundReport(msgTbl)
	self.roundReportMsg = msgTbl
	self.showReport = true
	if gt.playType ~= 1 and gt.playType ~= 4 and gt.playType ~= 5 then
		local spr = cc.Sprite:create()
		self:addChild(spr)
		local callFunc = cc.CallFunc:create(function ()
			self:showRcvRoundReport(self.roundReportMsg)
			spr:removeFromParent()
		end)
		spr:runAction(cc.Sequence:create(cc.DelayTime:create(1),callFunc))
		return
	end

	gt.log("_______调用函数___onRcvRoundReport")
    self:showMaskLayer()
  
	if gt.cardType == 5 then
		self:setTYSGmsg(msgTbl)
	end

	if (gt.playType == 4 or gt.playType == 5) and gt.cardType == 2 then
		self:setSXZY(msgTbl)
	end


	self:showTurnResult("up")
end

--处理上下左右翻数据
function PlaySceneCS:setSXZY(msgTbl)

	
	local paramTbl = {}
	for i = 1 , 3 do
		paramTbl[i] = {}
		paramTbl[i].cgstring = {}
		paramTbl[i].jing = msgTbl["m_shangXiaZuoYouJCard"..i]
		paramTbl[i].num = {}
		if i == 1 then
			paramTbl[i].title = "images/otherImages/xiajing4.png"
		elseif i == 2 then
			paramTbl[i].title = "images/otherImages/zuofanzi.png"
		elseif i == 3 then
			paramTbl[i].title = "images/otherImages/youfanzi.png"
		end


		for j = 1 , self.maxPlayer do 
			if self.maxPlayer == 3 and j == 3 then
				j = 4 
			end
			paramTbl[i].cgstring[j] = ""
			local chongguan = msgTbl["m_shangXiaZuoYouChongGuan"..i][j]
			if chongguan > 1 then
				paramTbl[i].cgstring[j] = paramTbl[i].cgstring[j] .. "冲关 X" .. chongguan
			end
			local bawang = msgTbl["m_shangXiaZuoYouPos"][i]

			if j - 1 == bawang then
				paramTbl[i].cgstring[j] = paramTbl[i].cgstring[j] .. "  霸王" 
			end

			local gangjin =  msgTbl["m_shangXiaZuoYouGangJing"..i][j]
			if gangjin ~= 0 then
				paramTbl[i].cgstring[j] = paramTbl[i].cgstring[j] .. "  杠精 X" .. gangjin
			end

			local zheng =  msgTbl["m_shangXiaZuoYouZhengJing"..i][j]
			paramTbl[i].num[j] = {}
			paramTbl[i].num[j][1] = zheng 

			local fu =  msgTbl["m_shangXiaZuoYouFuJing"..i][j]
			paramTbl[i].num[j][2] = fu 

		end

	end
	self.sxzy_paramTbl = paramTbl

end


function PlaySceneCS:setTYSGmsg(msgTbl)
	--同一首歌数据处理
  	  	self.TYSG_bawang = msgTbl.m_theSongPos
		self.TYSG_chongguan = {}
		self.TYSG_jcard = {}
		self.TYSG_shangJingNum = {} 
		self.TYSG_xiaJingNum = {}
		self.TYSG_gangjing = {}
    for i = 1 , 4 do 
		if msgTbl["m_theSongChongGuan" .. i] and  msgTbl["m_theSongChongGuan" .. i]~= 0 then
			self.TYSG_chongguan[i] = msgTbl["m_theSongChongGuan" .. i]
		end

		if msgTbl["m_theSongJCard" .. i] and  msgTbl["m_theSongJCard" .. i][1][1]~= 0 then
			self.TYSG_jcard[i] = msgTbl["m_theSongJCard" .. i]
		end

		if msgTbl["m_theSongShangJing" .. i] and  msgTbl["m_theSongShangJing" .. i]~= 0 then
			self.TYSG_shangJingNum[i] = msgTbl["m_theSongShangJing" .. i]
		end
		if msgTbl["m_theSongXiaJing" .. i] and  msgTbl["m_theSongXiaJing" .. i]~= 0 then
			self.TYSG_xiaJingNum[i] = msgTbl["m_theSongXiaJing" .. i]
		end
		
		if msgTbl["m_theSongGangJing" .. i] and  msgTbl["m_theSongGangJing" .. i]~= 0 then
			self.TYSG_gangjing[i] = msgTbl["m_theSongGangJing" .. i]
		end
	end
end

function PlaySceneCS:showRcvRoundReport(msgTbl)
	gt.log("______调用这个函数____showRcvRoundRepor---------")
	-- 显示准备按钮
	local readyBtn = gt.seekNodeByName(self.rootNode, "Btn_ready")
	readyBtn:setVisible(true)
	

	-- 停止未完成动作
	if self.startMjTileAnimation ~= nil then
		self.startMjTileAnimation:stopAllActions()
		self.startMjTileAnimation:removeFromParent()
		self.startMjTileAnimation = nil
	end
	
	self.Img_turnbg1:setVisible(false)
	self.Img_turnbg2:setVisible(false)
	self.Img_turnbg3:setVisible(false)
	gt.turnCard = {}
	if self.upNode then
		self.upNode:removeFromParent()
		self.upNode = nil
	end
	
	if self.upNode then
		self.downNode:removeFromParent()
		self.downNode = nil
	end
	
	self:removeImgChild()
	
	-- 停止倒计时音效
	self.playTimeCD = nil

	-- 移除所有麻将
	self.playMjLayer:removeAllChildren()

	-- 玩家准备手势隐藏
	self:hidePlayersReadySign()

	-- 隐藏座次标识
	local turnPosBgSpr = gt.seekNodeByName(self.rootNode, "Spr_turnPosBg")
	turnPosBgSpr:setVisible(false)

	-- 隐藏牌局状态
	local roundStateNode = gt.seekNodeByName(self.rootNode, "Node_roundState")
	roundStateNode:setVisible(false)

	-- 隐藏倒计时
	self.playTimeCDLabel:setVisible(false)

	-- 隐藏出牌标识
	self.outMjtileSignNode:setVisible(false)

	-- 隐藏决策
	local decisionBtnNode = gt.seekNodeByName(self.rootNode, "Node_decisionBtn")
	decisionBtnNode:setVisible(false)

	local selfDrawnDcsNode = gt.seekNodeByName(self.rootNode, "Node_selfDrawnDecision")
	selfDrawnDcsNode:setVisible(false)
	
	--local finalReport = require("app/views/FinalReport"):create(self.roomPlayers, msgTbl)
	--self:addChild(finalReport, PlaySceneCS.ZOrder.REPORT)
	
	self.showReport = false
	self:removePlayerForRoom()

	-- 弹出局结算界面
	if msgTbl.m_end == 0 then -- 不是最后一局
		self.curRoomPlayers = {}
		self.curRoomPlayers = self:copyTab(self.roomPlayers)
		local roundReport = require("app/views/RoundReport"):create(msgTbl, self.roomPlayers, self.playerSeatIdx, self.seatOffset, 0,self.paramTbl)
		--self:addChild(roundReport, PlaySceneCS.ZOrder.ROUND_REPORT)
		self:addChild(roundReport, 20)
	else
		if self.finalReport then
			self.finalReport:setVisible(true)
		end
		local roundReport = require("app/views/RoundReport"):create(msgTbl, self.curRoomPlayers, self.playerSeatIdx, self.seatOffset, 1,self.paramTbl)
		--self:addChild(roundReport, PlaySceneCS.ZOrder.ROUND_REPORT)
		self:addChild(roundReport, 20)
	end
end

function PlaySceneCS:copyTab(st)
    local tab = {}
    for k, v in pairs(st or {}) do
        if type(v) ~= "table" then
            tab[k] = v
        else
            tab[k] = self:copyTab(v)
        end
    end
    return tab
end

function PlaySceneCS:onRcvFinalReport(msgTbl)
	self.finalReport = require("app/views/FinalReport"):create(self.curRoomPlayers, msgTbl, self.playerSeatIdx,self.paramTbl)
	self:addChild(self.finalReport, 15)
	if msgTbl.m_isPlaying == 1 then
		self.finalReport:setVisible(false)
	elseif msgTbl.m_isPlaying == 0 then
		self.finalReport:setVisible(true)
	end
	if gt.playType ~= 1 and gt.playType ~= 4 and gt.playType ~= 5 then
		local spr = cc.Sprite:create()
		self:addChild(spr)
		local callFunc = cc.CallFunc:create(function ()
			self.finalReport:setVisible(true)
			gt.log("22222222")
			spr:removeFromParent()
		end)
		spr:runAction(cc.Sequence:create(cc.DelayTime:create(1),callFunc))
		gt.log("11111")
	end
end

-- start --
--------------------------------
-- @class function
-- @description 更新当前时间
-- end --
function PlaySceneCS:updateCurrentTime()
	local timeLabel = gt.seekNodeByName(self, "Label_time")
	local curTimeStr = os.date("%X", os.time())
	local timeSections = string.split(curTimeStr, ":")
	-- 时:分
	timeLabel:setString(string.format("%s:%s", timeSections[1], timeSections[2]))
end

function PlaySceneCS:checkPlayName( str )
	local retStr = ""
	local num = 0
	local lenInByte = #str
	local x = 1
	for i=1,lenInByte do
		i = x
	    local curByte = string.byte(str, x)
	    local byteCount = 1;
	    if curByte>0 and curByte<=127 then
	        byteCount = 1
	    elseif curByte>127 and curByte<240 then
	        byteCount = 3
	    elseif curByte>=240 and curByte<=247 then
	        byteCount = 4
	    end
	    local curStr = string.sub(str, i, i+byteCount-1)
	    retStr = retStr .. curStr
	    x = x + byteCount
	    if x >= lenInByte then
	    	return retStr
	    end
	    num = num + 1
	    if num >= 4 then
	    	return retStr
	    end
    end

    return retStr
end

-- start --
--------------------------------
-- @class function
-- @description 房间添加玩家
-- @param roomPlayer 玩家信息
-- end --
function PlaySceneCS:roomAddPlayer(roomPlayer)
	gt.log("PlaySceneCS:roomAddPlayer－－－－－进入房间的玩家信息－－－")
	gt.dump(roomPlayer)
	-- 赣州三人
	local nodeIndex = roomPlayer.displaySeatIdx
	-- if self.maxPlayer == 3 and roomPlayer.displaySeatIdx == 3 then
	-- 	nodeIndex = 4
	-- elseif elf.maxPlayer == 3 and roomPlayer.displaySeatIdx == 2 then
	-- 	nodeIndex = 3
	-- end

	local playerInfoNode = gt.seekNodeByName(self.rootNode, "Node_playerInfo_" .. tostring(nodeIndex))
	playerInfoNode:setVisible(true)

	-- 取消头像下载监听
	local headSpr = gt.seekNodeByName(playerInfoNode, "Spr_head")
	if roomPlayer.sex == 1 then	--2:女 1:男
		headSpr:setTexture("sd/images/otherImages/head_m001.png")
	else
		headSpr:setTexture("sd/images/otherImages/head_m002.png")
	end

	if self.playerHeadMgr then
		self.playerHeadMgr:detach(headSpr)
	end
	
	self.playerHeadMgr:attach(headSpr, roomPlayer.uid, roomPlayer.headURL)
	-- 昵称
	local nicknameLabel = gt.seekNodeByName(playerInfoNode, "Label_nickname")
	-- 名字只取四个字,并且清理掉其中的空格
	local nickname = string.gsub(roomPlayer.nickname," ","")
	nickname = string.gsub(nickname,"　","")
	nicknameLabel:setString( self:checkPlayName(nickname) )
	-- 积分
	
	
	local scoreLabel = gt.seekNodeByName(playerInfoNode, "Label_score")
	scoreLabel:setString(tostring(roomPlayer.score))
	roomPlayer.scoreLabel = scoreLabel
	--roomPlayer.scoreLabel:setVisible(false)
	-- 离线标示
	local offLineSignSpr = gt.seekNodeByName(playerInfoNode, "Spr_offLineSign")
	offLineSignSpr:setVisible(false)
	-- 庄家
	local bankerSignSpr = gt.seekNodeByName(playerInfoNode, "Spr_bankerSign")
	bankerSignSpr:setVisible(false)

	-- 点击头像显示信息
	local headFrameBtn = gt.seekNodeByName(playerInfoNode, "Btn_headFrame")
	headFrameBtn:setTag(roomPlayer.seatIdx)
	headFrameBtn:addClickEventListener(handler(self, self.showPlayerInfo))

	-- 添加入缓冲
	self.roomPlayers[roomPlayer.seatIdx] = roomPlayer
	
	-- 准备标示
	if roomPlayer.readyState == 1 then
		self:playerGetReady(roomPlayer.seatIdx)
	end

	-- 如果已经四个人了,隐藏微信分享按钮,显示聊天,设置按钮
	if #self.roomPlayers == self.maxPlayer then
		-- 隐藏等待界面元素
		local readyPlayNode = gt.seekNodeByName(self.rootNode, "Node_readyPlay")
		readyPlayNode:setVisible(false)
		-- 显示游戏中按钮（消息，设置）
		local playBtnsNode = gt.seekNodeByName(self.rootNode, "Node_playBtns")
		playBtnsNode:setVisible(true)
	end
end

-- start --
--------------------------------
-- @class function
-- @description 玩家自己进入房间
-- @param msgTbl 消息体
-- end --
function PlaySceneCS:playerEnterRoom(msgTbl)
	gt.log("================playerEnterRoom 自己加入房间==")
	-- 房间中的玩家
	self.roomPlayers = {}
	-- 玩家自己放入到房间玩家中
	local roomPlayer = {}
	roomPlayer.uid = gt.playerData.uid
	roomPlayer.nickname = gt.playerData.nickname
	roomPlayer.headURL = gt.playerData.headURL
	roomPlayer.sex = gt.playerData.sex
	roomPlayer.ip = gt.playerData.ip
	roomPlayer.seatIdx = msgTbl.m_pos + 1
	-- 玩家座位显示位置
	roomPlayer.displaySeatIdx = self.maxPlayer
	-- if self.maxPlayer == 3 and msgTbl.m_pos
	roomPlayer.readyState = msgTbl.m_ready
	roomPlayer.score = msgTbl.m_score
	gt.log("==-roomPlayer.score---" .. roomPlayer.score)
	-- 添加玩家自己
	self:roomAddPlayer(roomPlayer)

	-- 房间编号
	self.roomID = msgTbl.m_deskId
	-- 玩家方位编号
	self.playerSeatIdx = roomPlayer.seatIdx
	-- 玩家显示固定座位号
	self.playerFixDispSeat = 4
	-- 逻辑座位和显示座位偏移量(从0编号开始)
	local seatOffset = (self.playerFixDispSeat - 1) - msgTbl.m_pos
	self.seatOffset = seatOffset
	-- 旋转座次标识
	local turnPosBgSpr = gt.seekNodeByName(self.rootNode, "Spr_turnPosBg")
	
	if self.maxPlayer == 4 then
		turnPosBgSpr:setRotation(-seatOffset * 90)	
	end
	
	for _, turnPosSpr in ipairs(turnPosBgSpr:getChildren()) do
		turnPosSpr:setVisible(false)
	end
	-- 玩家出牌类型
	self.isPlayerShow = false
	self.isPlayerDecision = false

	if roomPlayer.readyState == 0 then
		-- 未准备显示准备按钮
		local readyBtn = gt.seekNodeByName(self.rootNode, "Btn_ready")
		readyBtn:setVisible(true)
	end
end

-- start --
--------------------------------
-- @class function
-- @description 发送玩家准备请求消息
-- end --
function PlaySceneCS:readyBtnClickEvt()
	local readyBtn = gt.seekNodeByName(self.rootNode, "Btn_ready")
	readyBtn:setVisible(false)

	local msgToSend = {}
	msgToSend.m_msgId = gt.CG_READY
	msgToSend.m_pos = self.playerSeatIdx - 1
	gt.socketClient:sendMessage(msgToSend)
end

-- start --
--------------------------------
-- @class function
-- @description 玩家进入准备状态
-- @param seatIdx 座次
-- end --
function PlaySceneCS:playerGetReady(seatIdx)
	local roomPlayer = self.roomPlayers[seatIdx]
	gt.log("PlaySceneCS:playerGetReady-------")
	gt.dump(self.roomPlayers)
	local playerInfoNode = gt.seekNodeByName(self.rootNode, "Node_playerInfo_" .. roomPlayer.displaySeatIdx)
	playerInfoNode:setVisible(true)

	-- if ()

	-- 积分
	local scoreLabel = gt.seekNodeByName(playerInfoNode, "Label_score")
	gt.log("==========playerGetReady==",seatIdx,roomPlayer.score)
	if roomPlayer.score ~= nil then
		scoreLabel:setString(tostring(roomPlayer.score))
	end

	self.Img_turnbg1:setVisible(false)
	--self.Spr_turnup1:setVisible(false)
	--self.Spr_turnup2:setVisible(false)
	self.Img_turnbg2:setVisible(false)
	self.Spr_turndown:setVisible(false)
			
	self.Img_turnbg3:setVisible(false)
		

	-- 显示玩家准备手势
	local readySignNode = gt.seekNodeByName(self.rootNode, "Node_readySign")
	local readySignSpr = gt.seekNodeByName(readySignNode, "Spr_readySign_" .. roomPlayer.displaySeatIdx)
	readySignSpr:setVisible(true)

	-- 玩家本身
	if seatIdx == self.playerSeatIdx then
		-- 隐藏准备按钮
		local readyBtn = gt.seekNodeByName(self.rootNode, "Btn_ready")
		readyBtn:setVisible(false)

		-- 隐藏牌局状态
		local roundStateNode = gt.seekNodeByName(self.rootNode, "Node_roundState")
		roundStateNode:setVisible(false)
	end
end

-- start --
--------------------------------
-- @class function
-- @description 隐藏所有玩家准备手势标识
-- end --
function PlaySceneCS:hidePlayersReadySign()
	for i = 1, self.maxPlayer do
		local readySignNode = gt.seekNodeByName(self.rootNode, "Node_readySign")
		local readySignSpr = gt.seekNodeByName(readySignNode, "Spr_readySign_" .. i)
		readySignSpr:setVisible(false)
	end
end

-- start --
--------------------------------
-- @class function
-- @description 显示玩家具体信息面板
-- @param sender
-- end --
function PlaySceneCS:showPlayerInfo(sender)
	local senderTag = sender:getTag()
	local roomPlayer = self.roomPlayers[senderTag]
	if not roomPlayer then
		return
	end

	local playerInfoTips = require("app/views/PlayerInfoTips"):create(roomPlayer)
	self:addChild(playerInfoTips, PlaySceneCS.ZOrder.PLAYER_INFO_TIPS)
end

-- start --
--------------------------------
-- @class function
-- @description 设置玩家麻将基础参考位置
-- @param displaySeatIdx 显示座位编号
-- @return 玩家麻将基础参考位置
-- end --
function PlaySceneCS:setPlayerMjTilesReferPos(displaySeatIdx)
	local mjTilesReferPos = {}
	
	gt.log("PlayerInfoTipsySceneCS:setPlayerMjTilesReferPos----displaySeatIdx-->" .. displaySeatIdx)
	local playNode = gt.seekNodeByName(self.rootNode, "Node_play")
	local mjTilesReferNode = gt.seekNodeByName(playNode, "Node_playerMjTiles_" .. displaySeatIdx)

	-- 持有牌数据
	local mjTileHoldSprF = gt.seekNodeByName(mjTilesReferNode, "Spr_mjTileHold_1")
	local mjTileHoldSprS = gt.seekNodeByName(mjTilesReferNode, "Spr_mjTileHold_2")
	mjTilesReferPos.holdStart = cc.p(mjTileHoldSprF:getPosition())
	mjTilesReferPos.holdSpace = cc.pSub(cc.p(mjTileHoldSprS:getPosition()), cc.p(mjTileHoldSprF:getPosition()))

	-- 打出牌数据
	local mjTileOutSprF = gt.seekNodeByName(mjTilesReferNode, "Spr_mjTileOut_1")
	local mjTileOutSprS = gt.seekNodeByName(mjTilesReferNode, "Spr_mjTileOut_2")
	local mjTileOutSprT = gt.seekNodeByName(mjTilesReferNode, "Spr_mjTileOut_3")
	mjTilesReferPos.outStart = cc.p(mjTileOutSprF:getPosition())
	mjTilesReferPos.outSpaceH = cc.pSub(cc.p(mjTileOutSprS:getPosition()), cc.p(mjTileOutSprF:getPosition()))
	mjTilesReferPos.outSpaceV = cc.pSub(cc.p(mjTileOutSprT:getPosition()), cc.p(mjTileOutSprF:getPosition()))

	-- 碰，杠牌数据
	local mjTileGroupPanel = gt.seekNodeByName(mjTilesReferNode, "Panel_mjTileGroup")
	local groupMjTilesPos = {}
	for _, groupTileSpr in ipairs(mjTileGroupPanel:getChildren()) do
		table.insert(groupMjTilesPos, cc.p(groupTileSpr:getPosition()))
	end
	mjTilesReferPos.groupMjTilesPos = groupMjTilesPos
	mjTilesReferPos.groupStartPos = cc.p(mjTileGroupPanel:getPosition())
	local groupSize = mjTileGroupPanel:getContentSize()
	--四人处理
	if displaySeatIdx == 1 or displaySeatIdx == 3 then
		mjTilesReferPos.groupSpace = cc.p(0, groupSize.height + 8)
		if displaySeatIdx == 3 then
			mjTilesReferPos.groupSpace.y = -mjTilesReferPos.groupSpace.y
		end
	else
		mjTilesReferPos.groupSpace = cc.p(groupSize.width + 8, 0)
		if displaySeatIdx == 2 then
			mjTilesReferPos.groupSpace.x = -mjTilesReferPos.groupSpace.x
		end
	end
	--赣州3人的位置坐标处理
	if self.maxPlayer == 3 and (displaySeatIdx == 1 or displaySeatIdx == 3) then
		-- gt.log("这时候3人的位置，我是----->" .. displaySeatIdx)
		mjTilesReferPos.groupSpace = cc.p(0, groupSize.height + 8)
		--控制我的坐标的位置，碰杠之后，赣州三人
		if displaySeatIdx == 3 then
			mjTilesReferPos.groupSpace.x = groupSize.width + 8
			mjTilesReferPos.groupSpace.y = 0
		end
	elseif self.maxPlayer == 3 and displaySeatIdx == 2 then
		-- gt.log("这时候3人的位置，我是----->" .. displaySeatIdx)
		mjTilesReferPos.groupSpace = cc.p(groupSize.width + 8, groupSize.height)
		if displaySeatIdx == 2 then
			mjTilesReferPos.groupSpace.x = -mjTilesReferPos.groupSpace.x
		end
	end

	-- 当前出牌展示位置
	local showMjTileNode = gt.seekNodeByName(mjTilesReferNode, "Node_showMjTile")
	mjTilesReferPos.showMjTilePos = cc.p(showMjTileNode:getPosition())

	return mjTilesReferPos
end

-- start --
--------------------------------
-- @class function
-- @description 设置座位编号标识
-- @param seatIdx 座位编号
-- end --
function PlaySceneCS:setTurnSeatSign(seatIdx)
	-- 显示轮到的玩家座位标识（标识亮起）
	local turnPosBgSpr = gt.seekNodeByName(self.rootNode, "Spr_turnPosBg")
	-- 显示当先座位标识
	local rotate = seatIdx
	if self.maxPlayer == 4 then
		local turnPosSpr = gt.seekNodeByName(turnPosBgSpr, "Spr_turnPos_" .. seatIdx)
		turnPosSpr:setVisible(true)
		-- if self.maxPlayer == 3 then
		-- 	turnPosSpr:setVisible(false)
		-- end
		if self.preTurnSeatIdx and self.preTurnSeatIdx ~= seatIdx then
			-- 隐藏上次座位标识
			local turnPosSpr = gt.seekNodeByName(turnPosBgSpr, "Spr_turnPos_" .. self.preTurnSeatIdx)
			turnPosSpr:setVisible(false)
		end
		self.preTurnSeatIdx = seatIdx
	elseif self.maxPlayer == 3 then
		local m_pos = seatIdx - 1
		local displaySeatIdx = 1
		if self.playerSeatIdx == 1 then
			gt.log("PlaySceneCS:onRcvAddPlayer----self.playerSeatIdx == 1")
			if m_pos == 0 then
				displaySeatIdx = 3
			elseif m_pos == 1 then
				displaySeatIdx = 1
			elseif m_pos == 2 then
				displaySeatIdx = 2
			end
		elseif self.playerSeatIdx == 2 then
			gt.log("PlaySceneCS:onRcvAddPlayer----self.playerSeatIdx == 2")
			if m_pos == 0 then
				displaySeatIdx = 2
			elseif m_pos == 1 then
				displaySeatIdx = 3
			elseif m_pos == 2 then
				displaySeatIdx = 1
			end
		elseif self.playerSeatIdx == 3 then
			gt.log("PlaySceneCS:onRcvAddPlayer----self.playerSeatIdx == 3")
			if m_pos == 0 then
				displaySeatIdx = 1
			elseif m_pos == 1 then
				displaySeatIdx = 2
			elseif m_pos == 2 then
				displaySeatIdx = 3
			end
		end
		local turnPosSpr = gt.seekNodeByName(turnPosBgSpr, "Spr_turnPos_" .. displaySeatIdx)
		turnPosSpr:setVisible(true)
		-- if self.maxPlayer == 3 then
		-- 	turnPosSpr:setVisible(false)
		-- end
		if self.preTurnSeatIdx and self.preTurnSeatIdx ~= displaySeatIdx then
			-- 隐藏上次座位标识
			local turnPosSpr = gt.seekNodeByName(turnPosBgSpr, "Spr_turnPos_" .. self.preTurnSeatIdx)
			turnPosSpr:setVisible(false)
		end
		self.preTurnSeatIdx = displaySeatIdx
	end
end

-- start --
--------------------------------
-- @class function
-- @description 出牌倒计时
-- @param
-- @param
-- @param
-- @return
-- end --
function PlaySceneCS:playTimeCDStart(timeDuration)
	self.playTimeCD = timeDuration

	self.isVibrateAlarm = false
	self.playTimeCDLabel:setVisible(true)
	self.playTimeCDLabel:setString(tostring(timeDuration))
end

-- start --
--------------------------------
-- @class function
-- @description 更新出牌倒计时
-- @param delta 定时器周期
-- end --
function PlaySceneCS:playTimeCDUpdate(delta)
	if not self.playTimeCD then
		return
	end

	self.playTimeCD = self.playTimeCD - delta
	if self.playTimeCD < 0 then
		self.playTimeCD = 0
	end
	if (self.isPlayerShow or self.isPlayerDecision) and self.playTimeCD <= 3 and not self.isVibrateAlarm then
		-- 剩余3s开始播放警报声音+震动一下手机
		self.isVibrateAlarm = true

		-- 播放声音
		self.playCDAudioID = gt.soundEngine:playEffect("common/timeup_alarm")

		-- 震动提醒
		cc.Device:vibrate(1)
	end
	local timeCD = math.ceil(self.playTimeCD)
	self.playTimeCDLabel:setString(tostring(timeCD))
end


-- start --
--------------------------------
-- @class function
-- @description 给玩家发牌
-- @param mjColor
-- @param mjNumber
-- end --
function PlaySceneCS:addMjTileToPlayer(mjColor, mjNumber)
	local mjTileName = string.format("p%db%d_%d.png", self.playerFixDispSeat, mjColor, mjNumber)
	local mjTileSpr = cc.Sprite:createWithSpriteFrameName(mjTileName)
	self.playMjLayer:addChild(mjTileSpr)

	if not self.firstShow then -- 新开局时，需要等翻精完成才能展示精牌
		if gt.turnCard and #gt.turnCard > 0 then
			--dump(gt.turnCard)
			gt.log("======1112233==" .. mjColor .. mjNumber)
			local turnTile = nil
			if  mjColor == gt.turnCard[1][1] and mjNumber == gt.turnCard[1][2] then
				gt.log("======33333===")
				turnTile = cc.Sprite:create("images/otherImages/s_sanjiao.png")
				mjTileSpr:addChild(turnTile)
				turnTile:setPosition(cc.p(mjTileSpr:getContentSize().width - turnTile:getContentSize().width / 2, mjTileSpr:getContentSize().height - turnTile:getContentSize().height / 2))
				--turnTile:setPosition(cc.p(turnTile:getContentSize().width / 2, mjTileSpr:getContentSize().height - turnTile:getContentSize().height / 2))
				--turnTile:setPosition(cc.p(mjTileSpr:getContentSize().width / 2, mjTileSpr:getContentSize().height / 2 + 20))
			elseif mjColor == gt.turnCard[2][1] and  mjNumber == gt.turnCard[2][2] then
				turnTile = cc.Sprite:create("images/otherImages/s_sanjiao.png")
				mjTileSpr:addChild(turnTile)
				gt.log("==============4frfgggg==")
				turnTile:setPosition(cc.p(mjTileSpr:getContentSize().width - turnTile:getContentSize().width / 2, mjTileSpr:getContentSize().height - turnTile:getContentSize().height / 2))
				--turnTile:setPosition(cc.p(turnTile:getContentSize().width / 2, mjTileSpr:getContentSize().height - turnTile:getContentSize().height / 2))
				--turnTile:setPosition(cc.p(mjTileSpr:getContentSize().width / 2, mjTileSpr:getContentSize().height / 2 - 20))
			end
		end
	end

	local roomPlayer = self.roomPlayers[self.playerSeatIdx]
	local mjTile = {}
	mjTile.mjTileSpr = mjTileSpr
	mjTile.mjColor = mjColor
	mjTile.mjNumber = mjNumber
	table.insert(roomPlayer.holdMjTiles, mjTile)

	return mjTile
end


-- 断线重连,走一次登录流程
function PlaySceneCS:reLogin()
	print("========重连登录2")
	local accessToken 	= cc.UserDefault:getInstance():getStringForKey( "WX_Access_Token" )
	local refreshToken 	= cc.UserDefault:getInstance():getStringForKey( "WX_Refresh_Token" )
	local openid 		= cc.UserDefault:getInstance():getStringForKey( "WX_OpenId" )

	local unionid 		= cc.UserDefault:getInstance():getStringForKey( "WX_Uuid" )
	local sex 			= cc.UserDefault:getInstance():getStringForKey( "WX_Sex" )
	local nickname 		= gt.nickname
	local headimgurl 	= cc.UserDefault:getInstance():getStringForKey( "WX_ImageUrl" )

	local msgToSend = {}
	msgToSend.m_msgId = gt.CG_LOGIN
	msgToSend.m_plate = "wechat"
	msgToSend.m_accessToken = accessToken
	msgToSend.m_refreshToken = refreshToken
	msgToSend.m_openId = openid
	msgToSend.m_severID = 12001
	msgToSend.m_uuid = unionid
	msgToSend.m_sex = tonumber(sex)
	msgToSend.m_nikename = nickname
	msgToSend.m_imageUrl = headimgurl

	local catStr = string.format("%s%s%s%s", openid, accessToken, refreshToken, unionid)
	msgToSend.m_md5 = cc.UtilityExtension:generateMD5(catStr, string.len(catStr))
	gt.socketClient:sendMessage(msgToSend)
end



function PlaySceneCS:onRcvLogin(msgTbl)
	print("========重连登录3")
	if msgTbl.m_errorCode == 5 then
		-- 去掉转圈
		gt.removeLoadingTips()
		require("app/views/NoticeTips"):create("提示",	"您尚未在"..msgTbl.m_errorMsg.."退出游戏，请先退出后再登陆此游戏！", nil, nil, true)
		return
	end
	print("========重连登录4")
	-- 去掉转圈
	gt.removeLoadingTips()

	-- 发送登录gate消息
	gt.loginSeed 		= msgTbl.m_seed
	gt.GateServer.ip 	= gt.socketClient.serverIp
	gt.GateServer.port 	= tostring(msgTbl.m_gatePort)

	gt.socketClient:close()
	print("===走这里,那么ip port是什么?",gt.GateServer.ip, gt.GateServer.port)
	gt.socketClient:connect(gt.GateServer.ip, gt.GateServer.port, true)
	local msgToSend = {}
	msgToSend.m_msgId = gt.CG_LOGIN_SERVER
	msgToSend.m_seed = msgTbl.m_seed
	msgToSend.m_id = msgTbl.m_id
	local catStr = tostring(gt.loginSeed)
	msgToSend.m_md5 = cc.UtilityExtension:generateMD5(catStr, string.len(catStr))
	gt.socketClient:sendMessage(msgToSend)
	print("========重连登录5")
end

-- start --
--------------------------------
-- @class function
-- @description 玩家麻将牌根据花色，编号重新排序
-- end --
function PlaySceneCS:sortPlayerMjTiles(isbegan)
	local roomPlayer = self.roomPlayers[self.playerSeatIdx]
	--单独处理精牌
	for k , v in ipairs(roomPlayer.holdMjTiles) do
		if gt.turnCard and #gt.turnCard > 0 and v.mjColor == gt.turnCard[1][1] and v.mjNumber == gt.turnCard[1][2] then
			v.jing = 1
		elseif gt.turnCard and #gt.turnCard > 0 and v.mjColor == gt.turnCard[2][1] and v.mjNumber == gt.turnCard[2][2] then
			v.jing = 2
		else
			v.jing = 3
		end
	end

	-- 按照花色分类

	table.sort(roomPlayer.holdMjTiles, function(a, b)
		if a.jing ~= b.jing then
			return a.jing < b.jing
		end	
		if a.mjColor ~= b.mjColor then
			return a.mjColor < b.mjColor
		else
			return a.mjNumber < b.mjNumber
		end
	end)
	
	-- 重新放置位置
	local mjTilesReferPos = roomPlayer.mjTilesReferPos
	local mjTilePos = mjTilesReferPos.holdStart
	for _, mjTile in ipairs(roomPlayer.holdMjTiles) do
		mjTile.mjTileSpr:stopAllActions()
		mjTile.mjTileSpr:setPosition(mjTilePos)
		self.playMjLayer:reorderChild(mjTile.mjTileSpr, (gt.winSize.height - mjTilePos.y))
		mjTilePos = cc.pAdd(mjTilePos, mjTilesReferPos.holdSpace)
		
	end
	if isbegan then
		local mjSpr = roomPlayer.holdMjTiles[#roomPlayer.holdMjTiles].mjTileSpr
		local mjTilesReferPos = roomPlayer.mjTilesReferPos
		local mjTilePos = mjTilesReferPos.holdStart
		mjTilePos = cc.pAdd(mjTilePos, cc.pMul(mjTilesReferPos.holdSpace, #roomPlayer.holdMjTiles - 1))
		mjTilePos = cc.pAdd(mjTilePos, cc.p(36, 0))
		mjSpr:setPosition(mjTilePos)
	end

end

-- start --
--------------------------------
-- @class function
-- @description 选中玩家麻将牌
-- @return 选中的麻将牌
-- end --
function PlaySceneCS:touchPlayerMjTiles(touch)
	if #self.playMjLayer:getChildren() == 0 then 
		return
	end
	local roomPlayer = self.roomPlayers[self.playerSeatIdx]
	for idx, mjTile in ipairs(roomPlayer.holdMjTiles) do
		local touchPoint = mjTile.mjTileSpr:convertTouchToNodeSpace(touch)
		local mjTileSize = mjTile.mjTileSpr:getContentSize()
		local mjTileRect = cc.rect(0, 0, mjTileSize.width, mjTileSize.height)
		if cc.rectContainsPoint(mjTileRect, touchPoint) then
			gt.soundEngine:playEffect("common/audio_card_click")
			return mjTile, idx
		end
	end

	return nil
end

-- start --
--------------------------------
-- @class function
-- @description 显示已出牌
-- @param seatIdx 座位号
-- @param mjColor 麻将花色
-- @param mjNumber 麻将编号
-- end --
function PlaySceneCS:addAlreadyOutMjTiles(seatIdx, mjColor, mjNumber, isHide)
	-- 添加到已出牌列表
	local roomPlayer = self.roomPlayers[seatIdx]
	local mjname = string.format("p%ds%d_%d.png", roomPlayer.displaySeatIdx, mjColor, mjNumber)
	if self.maxPlayer == 3 and roomPlayer.displaySeatIdx == 2 then
		mjname = string.format("p%ds%d_%d.png", 3, mjColor, mjNumber)
	elseif self.maxPlayer == 3 and roomPlayer.displaySeatIdx == 3 then
		mjname = string.format("p%ds%d_%d.png", 4, mjColor, mjNumber)
	end
	local mjTileSpr = cc.Sprite:createWithSpriteFrameName(mjname)
	
	if gt.turnCard and #gt.turnCard > 0 then
		local turnTile = nil
		
		if  (mjColor == gt.turnCard[1][1] and mjNumber == gt.turnCard[1][2]) or (mjColor == gt.turnCard[2][1] and  mjNumber == gt.turnCard[2][2]) then
			if self.maxPlayer == 4 then
				if roomPlayer.displaySeatIdx == 1 then
					turnTile = cc.Sprite:create("images/otherImages/sanjiao1.png")
					turnTile:setPosition(cc.p(turnTile:getContentSize().width / 2, mjTileSpr:getContentSize().height - turnTile:getContentSize().height / 2))
				elseif roomPlayer.displaySeatIdx == 2 then
					turnTile = cc.Sprite:create("images/otherImages/sanjiao2.png")
					turnTile:setPosition(cc.p(turnTile:getContentSize().width / 2,turnTile:getContentSize().height / 2))
				elseif roomPlayer.displaySeatIdx == 3 then
					turnTile = cc.Sprite:create("images/otherImages/sanjiao3.png")
					turnTile:setPosition(cc.p(mjTileSpr:getContentSize().width - turnTile:getContentSize().width / 2, turnTile:getContentSize().height / 2))
				elseif roomPlayer.displaySeatIdx == 4 then
					turnTile = cc.Sprite:create("images/otherImages/sanjiao.png")
					turnTile:setPosition(cc.p(mjTileSpr:getContentSize().width - turnTile:getContentSize().width / 2, mjTileSpr:getContentSize().height - turnTile:getContentSize().height / 2))
				end
				mjTileSpr:addChild(turnTile)
			elseif self.maxPlayer == 3 then
				gt.log("精牌角标的添加----roomPlayer.displaySeatIdx---->" .. roomPlayer.displaySeatIdx)
				mjTileSpr:setColor(cc.c4b(255,226,67,20))
			end
		end
	end
	
	local mjTile = {}
	mjTile.mjTileSpr = mjTileSpr
	mjTile.mjColor = mjColor
	mjTile.mjNumber = mjNumber
	table.insert(roomPlayer.outMjTiles, mjTile)

	-- 玩家已出牌缩小
	if self.playerSeatIdx == seatIdx then
		mjTileSpr:setScale(0.66)
	end

	if isHide then
		mjTileSpr:setVisible( false )
	end

	-- 显示已出牌
	local mjTilesReferPos = roomPlayer.mjTilesReferPos
	local mjTilePos = mjTilesReferPos.outStart
	local lineCount = math.ceil(#roomPlayer.outMjTiles / 10) - 1
	local lineIdx = #roomPlayer.outMjTiles - lineCount * 10 - 1
	mjTilePos = cc.pAdd(mjTilePos, cc.pMul(mjTilesReferPos.outSpaceV, lineCount))
	mjTilePos = cc.pAdd(mjTilePos, cc.pMul(mjTilesReferPos.outSpaceH, lineIdx))
	mjTileSpr:setPosition(mjTilePos)
	self.playMjLayer:addChild(mjTileSpr, (gt.winSize.height - mjTilePos.y))
end


function PlaySceneCS:updateOutMjTilesPosition(seatIdx)
	local roomPlayer = self.roomPlayers[seatIdx]
	local mjTilesReferPos = roomPlayer.mjTilesReferPos
	local mjTilePos = mjTilesReferPos.outStart
	for k, v in pairs(roomPlayer.outMjTiles) do
		-- 显示已出牌
		local lineCount = math.ceil(k / 10) - 1
		local lineIdx = k - lineCount * 10 - 1
		local tilePos = cc.pAdd(mjTilePos, cc.pMul(mjTilesReferPos.outSpaceV, lineCount))
		tilePos = cc.pAdd(tilePos, cc.pMul(mjTilesReferPos.outSpaceH, lineIdx))
		v.mjTileSpr:setPosition(tilePos)
		self.playMjLayer:reorderChild(v.mjTileSpr, (gt.winSize.height - tilePos.y))
	end
end

-- start --
--------------------------------
-- @class function
-- @description 移除上家被下家，杠打出的牌
-- end --
function PlaySceneCS:removePreRoomPlayerOutMjTile(color,number)
	-- 移除上家打出的牌
	-- if self.preShowSeatIdx then
	-- 	local roomPlayer = self.roomPlayers[self.preShowSeatIdx]
	-- 	local endIdx = #roomPlayer.outMjTiles
	-- 	local outMjTile = roomPlayer.outMjTiles[endIdx]
	-- 	outMjTile.mjTileSpr:removeFromParent()
	-- 	table.remove(roomPlayer.outMjTiles, endIdx)

	-- 	-- 隐藏出牌标识箭头
	-- 	self.outMjtileSignNode:setVisible(false)
	-- end

	-- 移除上家打出的牌
	if self.preShowSeatIdx then
		local roomPlayer = self.roomPlayers[self.preShowSeatIdx]
		for i = #roomPlayer.outMjTiles, 1, -1 do
			local outMjTile = roomPlayer.outMjTiles[i]
			if outMjTile.mjColor == color and outMjTile.mjNumber == number then
				outMjTile.mjTileSpr:removeFromParent()
				table.remove(roomPlayer.outMjTiles, i)
				self:updateOutMjTilesPosition(self.preShowSeatIdx)
				break
			end
		end

		-- 隐藏出牌标识箭头
		self.outMjtileSignNode:setVisible(false)
		if self.outMjtileSignNodeAction then
			self.outMjtileSignNode:stopAction(self.outMjtileSignNodeAction)
		end
	end

end

-- start --
--------------------------------
-- @class function
-- @description 显示指示出牌标识箭头动画
-- @param seatIdx 座次
-- end --
function PlaySceneCS:showOutMjtileSign(seatIdx)
	local roomPlayer = self.roomPlayers[seatIdx]
	local endIdx = #roomPlayer.outMjTiles
	local outMjTile = roomPlayer.outMjTiles[endIdx]
	self.outMjtileSignNode:setVisible(true)
	self.outMjtileSignNode:setPosition(outMjTile.mjTileSpr:getPosition())
end

-- start --
--------------------------------
-- @class function
-- @description 隐藏碰，杠牌
-- @param seatIdx 座次
-- @param isBar 杠
-- @param isBrightBar 明杠
-- end --
function PlaySceneCS:hideOtherPlayerMjTiles(seatIdx, isBar, isBrightBar)
	if seatIdx == self.playerSeatIdx then
		return
	end

	-- 持有牌隐藏已经碰杠牌
	-- 碰2张
	local mjTilesCount = 2
	if isBar then
		-- 明杠3张
		mjTilesCount = 3
		-- 暗杠4张
		if not isBrightBar then
			mjTilesCount = 4
		end
	end
	local roomPlayer = self.roomPlayers[seatIdx]
	local idx = roomPlayer.mjTilesRemainCount - mjTilesCount + 1
	-- gt.log(string.format("mjTilesRemainCount:[%d] mjTilesCount:[%d] idx:[%d] roomPlayer.holdMjTiles:[%d]", roomPlayer.mjTilesRemainCount, mjTilesCount, idx, #roomPlayer.holdMjTiles))
	if mjTilesCount > 2 then
		gt.log("___222222___有杠牌时",seatIdx,roomPlayer.mjTilesRemainCount,mjTilesCount)
	end
	for i = 1, mjTilesCount do
		local mjTile = roomPlayer.holdMjTiles[idx]
		mjTile.mjTileSpr:setVisible(false)

		idx = idx + 1
	end

	roomPlayer.mjTilesRemainCount = roomPlayer.mjTilesRemainCount - mjTilesCount
	self:sortPlayerMjTiles()
end

-- start --
--------------------------------
-- @class function
-- @description 碰牌
-- @param seatIdx 座位编号
-- @param mjColor 麻将牌花色
-- @param mjNumber 麻将牌编号
-- end --
function PlaySceneCS:addMjTilePung(seatIdx, mjColor, mjNumber)
	local roomPlayer = self.roomPlayers[seatIdx]
	local pungData = {}
	pungData.mjColor = mjColor
	pungData.mjNumber = mjNumber
	table.insert(roomPlayer.mjTilePungs, pungData)

	pungData.groupNode = self:pungBarReorderMjTiles(seatIdx, mjColor, mjNumber)
end


-- start --
--------------------------------
-- @class function
-- @description 杠牌
-- @param seatIdx 座位编号
-- @param mjColor 麻将牌花色
-- @param mjNumber 麻将牌编号
-- @param isBrightBar 明杠或者暗杠
-- end --
function PlaySceneCS:addMjTileBar(seatIdx, mjColor, mjNumber, isBrightBar)
	local roomPlayer = self.roomPlayers[seatIdx]

	-- 加入到列表中
	local barData = {}
	barData.mjColor = mjColor
	barData.mjNumber = mjNumber
	if isBrightBar then
		-- 明杠
		table.insert(roomPlayer.mjTileBrightBars, barData)
	else
		-- 暗杠
		table.insert(roomPlayer.mjTileDarkBars, barData)
	end
	-- dump(barData)

	barData.groupNode = self:pungBarReorderMjTiles(seatIdx, mjColor, mjNumber, true, isBrightBar)
end

-- start --
--------------------------------
-- @class function
-- @description 碰杠重新排序麻将牌,显示碰杠
-- @param seatIdx
-- @param mjColor
-- @param mjNumber
-- @param isBar
-- @param isBrightBar
-- @return
-- end --
function PlaySceneCS:pungBarReorderMjTiles(seatIdx, mjColor, mjNumber, isBar, isBrightBar)
	gt.log("碰杠重新排序-----------seatId-->" .. seatIdx)
	gt.dump(self.roomPlayers)
	local roomPlayer = self.roomPlayers[seatIdx]
	local mjTilesReferPos = roomPlayer.mjTilesReferPos
	-- 显示碰杠牌
	local groupMjTilesPos = mjTilesReferPos.groupMjTilesPos  --杠的位置点
	local groupNode = cc.Node:create()
	groupNode:setPosition(mjTilesReferPos.groupStartPos)
	self.playMjLayer:addChild(groupNode)
	local mjTilesCount = 3
	if isBar then
		mjTilesCount = 4
	end
	local funcSeatIdx = roomPlayer.displaySeatIdx
	--赣州三人坐标处理
	if self.maxPlayer ==  3 and roomPlayer.displaySeatIdx == 2 and seatIdx == 3 then
		funcSeatIdx = 3
		-- roomPlayer.displaySeatIdx = 3
	-- elseif self.maxPlayer ==  3 and roomPlayer.displaySeatIdx == 3 and seatIdx == 1 then
	-- 	roomPlayer.displaySeatIdx = 1
	elseif self.maxPlayer ==  3 and roomPlayer.displaySeatIdx == 3 and seatIdx == 1 then
		-- roomPlayer.displaySeatIdx = 4
		funcSeatIdx = 4
	end

	for i = 1, mjTilesCount do
		local mjTileName = nil
		local mjTileSpr = nil
		if isBar and not isBrightBar and i <= 3 then
			-- 暗杠前三张牌扣着
			-- mjTileName = string.format("tdbgs_%d.png", roomPlayer.displaySeatIdx)
			mjTileName = string.format("tdbgs_%d.png", funcSeatIdx)
			mjTileSpr = cc.Sprite:createWithSpriteFrameName(mjTileName)
		else
			--如果不是吃
			if type(mjNumber) == "number"  then
				-- mjTileName = string.format("p%ds%d_%d.png", roomPlayer.displaySeatIdx, mjColor, mjNumber)
				mjTileName = string.format("p%ds%d_%d.png", funcSeatIdx, mjColor, mjNumber)
				mjTileSpr = cc.Sprite:createWithSpriteFrameName(mjTileName)
				self:showSanjiao(roomPlayer,mjTileSpr, mjColor, mjNumber)
			else
				-- mjTileName = string.format("p%ds%d_%d.png", roomPlayer.displaySeatIdx, mjColor, mjNumber[i][1])
				mjTileName = string.format("p%ds%d_%d.png", funcSeatIdx, mjColor, mjNumber[i][1])
				mjTileSpr = cc.Sprite:createWithSpriteFrameName(mjTileName)
				self:showSanjiao(roomPlayer,mjTileSpr, mjColor, mjNumber[i][1])
			end
		end
		mjTileSpr:setPosition(groupMjTilesPos[i])
		groupNode:addChild(mjTileSpr)
	end
	if self.maxPlayer == 4 then
		mjTilesReferPos.groupStartPos = cc.pAdd(mjTilesReferPos.groupStartPos, mjTilesReferPos.groupSpace)
		mjTilesReferPos.holdStart = cc.pAdd(mjTilesReferPos.holdStart, mjTilesReferPos.groupSpace)
	elseif self.maxPlayer == 3 then
		if roomPlayer.displaySeatIdx == 2 then
			mjTilesReferPos.groupStartPos = cc.pSub(mjTilesReferPos.groupStartPos, cc.p(0, mjTilesReferPos.groupSpace.y))
			mjTilesReferPos.holdStart = cc.pSub(mjTilesReferPos.holdStart,  cc.p(0, mjTilesReferPos.groupSpace.y))
		else
			mjTilesReferPos.groupStartPos = cc.pAdd(mjTilesReferPos.groupStartPos, mjTilesReferPos.groupSpace)
			mjTilesReferPos.holdStart = cc.pAdd(mjTilesReferPos.holdStart, mjTilesReferPos.groupSpace)
		end

	end
	-- 更新持有牌显示位置
	if seatIdx == self.playerSeatIdx then
		-- 玩家自己
		-- 碰2张
		local mjTilesCount = 2
		if isBar then
			-- 明杠3张
			mjTilesCount = 3
			-- 暗杠4张
			if not isBrightBar then
				mjTilesCount = 4
			end
		end
		if type(mjNumber) == "number" then

			if not self.pung then
				local filterMjTilesCount = 0
				local transMjTiles = {}
				for i, mjTile in ipairs(roomPlayer.holdMjTiles) do
					if filterMjTilesCount < mjTilesCount and mjTile.mjColor == mjColor and mjTile.mjNumber == mjNumber then
						mjTile.mjTileSpr:removeFromParent()
						filterMjTilesCount = filterMjTilesCount + 1
					else
						-- 保存其它牌,去除碰杠牌
						table.insert(transMjTiles, mjTile)
					end
				end
				roomPlayer.holdMjTiles = transMjTiles
			end
		else
			local removeTable = {}
			for j = 1, 3 do
				if tonumber(mjNumber[j][2]) ~= tonumber(1) then
					table.insert(removeTable, {mjNumber[j][1], mjNumber[j][3]})
				end
			end

			if #removeTable > 0 then
				for i, mjTile in ipairs(roomPlayer.holdMjTiles) do
					if mjTile.mjNumber == removeTable[1][1] and  mjTile.mjColor == removeTable[1][2] then
						mjTile.mjTileSpr:removeFromParent()
						table.remove(roomPlayer.holdMjTiles, i)
						break
					end
				end
				for i, mjTile in ipairs(roomPlayer.holdMjTiles) do
						if mjTile.mjNumber == removeTable[2][1] and mjTile.mjColor == removeTable[2][2] then
							mjTile.mjTileSpr:removeFromParent()
							table.remove(roomPlayer.holdMjTiles, i)
						break
					end
				end
			end
		end
		-- 重新排序现持有牌
		self:sortPlayerMjTiles()
	else
		local mjTilesReferPos = roomPlayer.mjTilesReferPos
		local mjTilePos = mjTilesReferPos.holdStart
		for _, mjTile in ipairs(roomPlayer.holdMjTiles) do
			mjTile.mjTileSpr:setPosition(mjTilePos)
			self.playMjLayer:reorderChild(mjTile.mjTileSpr, (gt.winSize.height - mjTilePos.y))

			mjTilePos = cc.pAdd(mjTilePos, mjTilesReferPos.holdSpace)
		end
	end

	return groupNode
end


function PlaySceneCS:showSanjiao(roomPlayer,mjTileSpr, mjColor, mjNumber)
	if gt.turnCard and #gt.turnCard > 0 then
		local turnTile = nil
		if  (mjColor == gt.turnCard[1][1] and mjNumber == gt.turnCard[1][2]) or (mjColor == gt.turnCard[2][1] and  mjNumber == gt.turnCard[2][2]) then
			if self.maxPlayer == 4 then
				if roomPlayer.displaySeatIdx == 1 then
					turnTile = cc.Sprite:create("images/otherImages/sanjiao1.png")
					turnTile:setPosition(cc.p(turnTile:getContentSize().width / 2, mjTileSpr:getContentSize().height - turnTile:getContentSize().height / 2))
				elseif roomPlayer.displaySeatIdx == 2 then
					turnTile = cc.Sprite:create("images/otherImages/sanjiao2.png")
					turnTile:setPosition(cc.p(turnTile:getContentSize().width / 2,turnTile:getContentSize().height / 2))
				elseif roomPlayer.displaySeatIdx == 3 then
					turnTile = cc.Sprite:create("images/otherImages/sanjiao3.png")
					turnTile:setPosition(cc.p(mjTileSpr:getContentSize().width - turnTile:getContentSize().width / 2, turnTile:getContentSize().height / 2))
				elseif roomPlayer.displaySeatIdx == 4 then
					turnTile = cc.Sprite:create("images/otherImages/sanjiao.png")
					turnTile:setPosition(cc.p(mjTileSpr:getContentSize().width - turnTile:getContentSize().width / 2, mjTileSpr:getContentSize().height - turnTile:getContentSize().height / 2))
				end
				mjTileSpr:removeAllChildren()
				mjTileSpr:addChild(turnTile)
			elseif self.maxPlayer == 3 then
				mjTileSpr:setColor(cc.c4b(255,226,67,20))
			end
				
		end
	end
end

function PlaySceneCS:removeImgChild()
	for i = 1, 2 do 
		if self.Img_turnbg1:getChildByTag(80 + i) then
			self.Img_turnbg1:getChildByTag(80 + i):removeFromParent()
		end

		if self.Img_turnbg3:getChildByTag(80 + i) then
			self.Img_turnbg3:getChildByTag(80 + i):removeFromParent()
		end
	end
end
-- start --
--------------------------------
-- @class function
-- @description 自摸碰变成明杠
-- @param seatIdx
-- @param mjColor
-- @param mjNumber
-- end --
function PlaySceneCS:changePungToBrightBar(seatIdx, mjColor, mjNumber)
	local roomPlayer = self.roomPlayers[seatIdx]
	if seatIdx == self.playerSeatIdx then
		for i, mjTile in ipairs(roomPlayer.holdMjTiles) do
			if mjTile.mjColor == mjColor and mjTile.mjNumber == mjNumber then
				mjTile.mjTileSpr:removeFromParent()
				table.remove(roomPlayer.holdMjTiles, i)
				break
			end
		end
	else
		roomPlayer.holdMjTiles[roomPlayer.mjTilesRemainCount].mjTileSpr:setVisible(false)
		roomPlayer.mjTilesRemainCount = roomPlayer.mjTilesRemainCount - 1
	end

	-- 查找碰牌
	local brightBarData = nil
	for i, pungData in ipairs(roomPlayer.mjTilePungs) do
		if pungData.mjColor == mjColor and pungData.mjNumber == mjNumber then
			-- 从碰牌列表中删除
			brightBarData = pungData
			table.remove(roomPlayer.mjTilePungs, i)
			break
		end
	end
	self:sortPlayerMjTiles()
	-- 添加到明杠列表
	if brightBarData then
		-- 加入杠牌第4个牌
		local mjTilesReferPos = roomPlayer.mjTilesReferPos
		local groupMjTilesPos = mjTilesReferPos.groupMjTilesPos
		local mjTileName = string.format("p%ds%d_%d.png", roomPlayer.displaySeatIdx, mjColor, mjNumber)
		if self.maxPlayer == 3 and roomPlayer.displaySeatIdx == 3 then
			 mjTileName = string.format("p%ds%d_%d.png", 4, mjColor, mjNumber)
		elseif self.maxPlayer == 3 and roomPlayer.displaySeatIdx == 2 then
			 mjTileName = string.format("p%ds%d_%d.png", 3, mjColor, mjNumber)
		end

		local mjTileSpr = cc.Sprite:createWithSpriteFrameName(mjTileName)
		mjTileSpr:setPosition(groupMjTilesPos[4])
		self:showSanjiao(roomPlayer,mjTileSpr,mjColor, mjNumber)
		brightBarData.groupNode:addChild(mjTileSpr)
		table.insert(roomPlayer.mjTileBrightBars, brightBarData)
	end
end


-- start --
--------------------------------
-- @class function
-- @description 显示玩家接炮胡，自摸胡，明杠，暗杠，碰动画显示
-- @param seatIdx 座位索引
-- @param decisionType 决策类型
-- end --
function PlaySceneCS:showDecisionAnimation(seatIdx, decisionType, huCard)
	
	if huCard~=nil then
	 	-- 长沙麻将
		-- 接炮胡，自摸胡，明杠，暗杠，碰文件后缀
		local decisionSuffixs = {1, 4, 2, 2, 3, 5, 6, 6}
		local decisionSfx = {"hu", "zimo", "gang", "gang", "peng" ,"chi", "buzhang", "buzhang" }
		-- 显示决策标识
		local roomPlayer = self.roomPlayers[seatIdx]

		local groupNode = cc.Node:create()
		groupNode:setCascadeOpacityEnabled( true )
		groupNode:setPosition( roomPlayer.mjTilesReferPos.showMjTilePos )
		self.rootNode:addChild( groupNode, PlaySceneCS.ZOrder.DECISION_SHOW )

		local nextX = 0
		local nextY = 0
		local totoalX = 0
		local totoalY = 0
		local xoffset = 0
		local yoffset = 0
		huCard = {2}
		for i,v in ipairs(huCard) do -- 创建要显示的图片文字
			gt.log("==tttttttttttttt=" .. v)
			local decisionSignSpr = cc.Sprite:createWithSpriteFrameName(string.format("decision_sign_cs_1.png", v))
			decisionSignSpr:setPosition( cc.p(nextX,nextY) )
			groupNode:addChild( decisionSignSpr )
			if roomPlayer.displaySeatIdx == 1 or roomPlayer.displaySeatIdx == 3 then -- 左右两边竖着显示
				decisionSignSpr:setAnchorPoint( 0, 1 )
				nextY = nextY + decisionSignSpr:getContentSize().height
				totoalY = totoalY + decisionSignSpr:getContentSize().height
				xoffset = decisionSignSpr:getContentSize().width / 2
			else
				-- 上线两边左右显示
				decisionSignSpr:setAnchorPoint( 0, 0 )
				nextX = nextX + decisionSignSpr:getContentSize().width
				totoalX = totoalX + decisionSignSpr:getContentSize().width
				yoffset = decisionSignSpr:getContentSize().height/2
			end
		end

		if roomPlayer.displaySeatIdx == 1 or roomPlayer.displaySeatIdx == 3 then -- 左右两边竖着显示
			groupNode:setPosition( cc.pAdd( roomPlayer.mjTilesReferPos.showMjTilePos, cc.p(-xoffset,totoalY/2) ) )
		else
			groupNode:setPosition( cc.pAdd( roomPlayer.mjTilesReferPos.showMjTilePos, cc.p(-totoalX/2,-yoffset) ) )
		end

		-- 标识显示动画
		groupNode:setScale(0)
		local scaleToAction = cc.ScaleTo:create(0.5, 1)
		local easeBackAction = cc.EaseBackOut:create(scaleToAction)
		local fadeOutAction = cc.FadeOut:create(1)
		local callFunc = cc.CallFunc:create(function(sender)
			-- 播放完后移除
			sender:removeFromParent()
		end)
		local seqAction = cc.Sequence:create(easeBackAction, fadeOutAction, callFunc)
		groupNode:runAction(seqAction)

		-- 播放全屏动画
		if decisionType == PlaySceneCS.DecisionType.BRIGHT_BAR then
			if not self.brightBarAnimateNode then
				local brightBarAnimateNode, brightBarAnimate = gt.createCSAnimation("animation/BrightBar.csb")
				self.brightBarAnimateNode = brightBarAnimateNode
				self.brightBarAnimate = brightBarAnimate
				self.rootNode:addChild(brightBarAnimateNode, PlaySceneCS.ZOrder.MJBAR_ANIMATION)
			end
			self.brightBarAnimate:play("run", false)
		elseif decisionType == PlaySceneCS.DecisionType.DARK_BAR then
			if not self.darkBarAnimateNode then
				local darkBarAnimateNode, darkBarAnimate = gt.createCSAnimation("animation/DarkBar.csb")
				self.darkBarAnimateNode = darkBarAnimateNode
				self.darkBarAnimate = darkBarAnimate
				self.rootNode:addChild(darkBarAnimateNode, PlaySceneCS.ZOrder.MJBAR_ANIMATION)
			end
			self.darkBarAnimate:play("run", false)
		end

		if roomPlayer.sex == 1 then
			-- 男性
			gt.soundEngine:playEffect(string.format("changsha/man/%s", decisionSfx[decisionType]))
		else
			-- 女性
			gt.soundEngine:playEffect(string.format("changsha/woman/%s", decisionSfx[decisionType]))
		end
	else
		gt.log("==jjjjjjjj=13333333=")
		-- 接炮胡，自摸胡，明杠，暗杠，碰文件后缀
		local decisionSuffixs = {1, 4, 2, 2, 3, 5, 6, 6}
		local decisionSfx = {"hu", "zimo", "gang", "gang", "peng" ,"chi", "buzhang", "buzhang" }
		-- 显示决策标识
		local roomPlayer = self.roomPlayers[seatIdx]
		local decisionSignSpr = cc.Sprite:createWithSpriteFrameName(string.format("decision_sign_cs_%d.png", decisionSuffixs[decisionType]))
		decisionSignSpr:setPosition(roomPlayer.mjTilesReferPos.showMjTilePos)
		self.rootNode:addChild(decisionSignSpr, PlaySceneCS.ZOrder.DECISION_SHOW)
		-- 标识显示动画
		decisionSignSpr:setScale(0)
		local scaleToAction = cc.ScaleTo:create(0.5, 1)
		local easeBackAction = cc.EaseBackOut:create(scaleToAction)
		local fadeOutAction = cc.FadeOut:create(1)
		local callFunc = cc.CallFunc:create(function(sender)
			-- 播放完后移除
			sender:removeFromParent()
		end)
		local seqAction = cc.Sequence:create(easeBackAction, fadeOutAction, callFunc)
		decisionSignSpr:runAction(seqAction)

		-- 播放全屏动画
		if decisionType == PlaySceneCS.DecisionType.BRIGHT_BAR then
			if not self.brightBarAnimateNode then
				local brightBarAnimateNode, brightBarAnimate = gt.createCSAnimation("animation/BrightBar.csb")
				self.brightBarAnimateNode = brightBarAnimateNode
				self.brightBarAnimate = brightBarAnimate
				self.rootNode:addChild(brightBarAnimateNode, PlaySceneCS.ZOrder.MJBAR_ANIMATION)
			end
			self.brightBarAnimate:play("run", false)
		elseif decisionType == PlaySceneCS.DecisionType.DARK_BAR then
			if not self.darkBarAnimateNode then
				local darkBarAnimateNode, darkBarAnimate = gt.createCSAnimation("animation/DarkBar.csb")
				self.darkBarAnimateNode = darkBarAnimateNode
				self.darkBarAnimate = darkBarAnimate
				self.rootNode:addChild(darkBarAnimateNode, PlaySceneCS.ZOrder.MJBAR_ANIMATION)
			end
			self.darkBarAnimate:play("run", false)
		end

		if roomPlayer.sex == 1 then
			-- 男性
			gt.soundEngine:playEffect(string.format("changsha/man/%s", decisionSfx[decisionType]))
		else
			-- 女性
			gt.soundEngine:playEffect(string.format("changsha/woman/%s", decisionSfx[decisionType]))
		end
	end

end

-- start --
--------------------------------
-- @class function
-- @description 显示出牌动画
-- @param seatIdx 座次
-- end --
function PlaySceneCS:showMjTileAnimation(seatIdx, startPos, mjColor, mjNumber, cbFunc)

	local mjTilePos = startPos

	local roomPlayer = self.roomPlayers[seatIdx]
	local rotateAngle = {-90, 180, 90, 0}

	local mjTileName = string.format("p4s%d_%d.png", mjColor, mjNumber)
	local mjTileSpr = cc.Sprite:createWithSpriteFrameName(mjTileName)
	self.rootNode:addChild(mjTileSpr, 98)

	self.startMjTileAnimation = mjTileSpr
	self.startMjTileColor = mjColor
	self.startMjTileNumber	= mjNumber

	mjTileSpr:setPosition(mjTilePos)
	local totalTime = 0.05
	local moveToAc_1 = cc.MoveTo:create(totalTime, roomPlayer.mjTilesReferPos.showMjTilePos)
	local rotateToAc_1 = cc.ScaleTo:create(totalTime, 1.5)

	local delayTime = cc.DelayTime:create(0.8)

	local mjTilesReferPos = roomPlayer.mjTilesReferPos
	local mjTilePos = mjTilesReferPos.outStart
	local mjTilesCount = #roomPlayer.outMjTiles + 1
	local lineCount = math.ceil(mjTilesCount / 10) - 1
	local lineIdx = mjTilesCount - lineCount * 10 - 1
	mjTilePos = cc.pAdd(mjTilePos, cc.pMul(mjTilesReferPos.outSpaceV, lineCount))
	mjTilePos = cc.pAdd(mjTilePos, cc.pMul(mjTilesReferPos.outSpaceH, lineIdx))

	local moveToAc_2 = cc.MoveTo:create(totalTime, mjTilePos)
	-- local rotateToAc_2 = cc.RotateTo:create(0.3, rotateAngle[roomPlayer.displaySeatIdx])
	local rotateToAc_2 = cc.ScaleTo:create(totalTime, 1.0)

	local callFunc = cc.CallFunc:create(function(sender)
		sender:removeFromParent()
		self.startMjTileAnimation = nil
		cbFunc()
	end)
	mjTileSpr:runAction(cc.Sequence:create(cc.Spawn:create(moveToAc_1, rotateToAc_1),
										delayTime,
										-- setro,
										cc.Spawn:create(moveToAc_2, rotateToAc_2),
										callFunc));
end

function PlaySceneCS:reset()
	-- 玩家手势隐藏
	self:hidePlayersReadySign()

	self.playMjLayer:removeAllChildren()
end

function PlaySceneCS:backMainSceneEvt(eventType, isRoomCreater, roomID)
	-- 事件回调
	gt.removeTargetAllEventListener(self)
	-- 消息回调
	self:unregisterAllMsgListener()

	local mainScene = require("app/views/MainScene"):create(false, isRoomCreater, roomID)
	cc.Director:getInstance():replaceScene(mainScene)
end

function PlaySceneCS:createFlimLayer(flimLayerType,cardList)
	-- 一个麻将
	local mjTileName = string.format("p4s%d_%d.png", 2, 2)
	local mjTileSpr = cc.Sprite:createWithSpriteFrameName(mjTileName)
	local width_oneMJ = mjTileSpr:getContentSize().width
	local space_gang = 20
	local width = 30+mjTileSpr:getContentSize().width*4*(#cardList)+space_gang*(#cardList-1)
	local height = 24+mjTileSpr:getContentSize().height

	local flimLayer = cc.LayerColor:create(cc.c4b(85, 85, 85, 0), width, height)
	flimLayer:setContentSize(cc.size(width,height))
	local function onTouchBegan(touch, event)
		return true
	end

	-- 添加半透明底
	local image_bg = ccui.ImageView:create()
	image_bg:loadTexture("images/otherImages/laoyue_bg.png")
	image_bg:setScale9Enabled(true)
	image_bg:setCapInsets(cc.rect(10,10,1,1))
	image_bg:setContentSize(cc.size(width,height))
	image_bg:setAnchorPoint(cc.p(0,0))
	flimLayer:addChild(image_bg)

	-- 创建麻将
	for idx,value in ipairs(cardList) do
		local flag = value.flag
		local mjColor = value.mjColor
		local mjNumber = value.mjNumber

		local mjSprName = string.format("p4s%d_%d.png", mjColor, mjNumber)
		for i=1,4 do
			local button = ccui.Button:create()
			button:loadTextures(mjSprName,mjSprName,"",ccui.TextureResType.plistType)
			button:setTouchEnabled(true)
    		button:setAnchorPoint(cc.p(0,0))
    		button:setPosition(cc.p(15+space_gang*(idx-1)+width_oneMJ*(i-1)+width_oneMJ*4*(idx-1), 10))
   			button:setTag(idx)
   			flimLayer:addChild(button)

    		local function touchEvent(ref, type)
       			if type == ccui.TouchEventType.ended then
        		 	self.isPlayerDecision = false

					local selfDrawnDcsNode = gt.seekNodeByName(self.rootNode, "Node_selfDrawnDecision")
					selfDrawnDcsNode:setVisible(false)

					-- 发送消息
					local cardData = cardList[ref:getTag()]
					local msgToSend = {}
					msgToSend.m_msgId = gt.CG_SHOW_MJTILE
					msgToSend.m_type = cardData.flag
					msgToSend.m_think = {}

					local think_temp = {cardData.mjColor,cardData.mjNumber}
					table.insert(msgToSend.m_think,think_temp)
					gt.socketClient:sendMessage(msgToSend)

					self.isPlayerShow = false

					-- 删除弹出框（杠）
					self:removeFlimLayer(PlaySceneCS.FLIMTYPE.FLIMLAYER_BAR)
					-- 删除弹出框（补）
					self:removeFlimLayer(PlaySceneCS.FLIMTYPE.FLIMLAYER_BU)
       		 	end
  	  		end
   	 		button:addTouchEventListener(touchEvent)
		end
	end
	return flimLayer
end

function PlaySceneCS:removeFlimLayer(flimLayerType)
	local child = self:getChildByTag(PlaySceneCS.TAG.FLIMLAYER_BAR)

	if flimLayerType == PlaySceneCS.FLIMTYPE.FLIMLAYER_BAR then
		child = self:getChildByTag(PlaySceneCS.TAG.FLIMLAYER_BAR)
	elseif flimLayerType == PlaySceneCS.FLIMTYPE.FLIMLAYER_BU then
		child = self:getChildByTag(PlaySceneCS.TAG.FLIMLAYER_BU)
	else

	end

	if not child then
		return
	end

	child:removeFromParent()

end

function PlaySceneCS:showHaidiInLayer(msgTbl)
	-- body
	self.isPlayerDecision = true
	self.haveHaidiPai = true
	local dipaiNode = gt.seekNodeByName(self.rootNode, "Node_HaidiPai")
	dipaiNode:setVisible( true )
	local spr = gt.seekNodeByName(dipaiNode, "Sprite_pai")
	spr:setSpriteFrame(string.format("p4s%d_%d.png", msgTbl.m_color, msgTbl.m_number))


	self:stopAllActions()
	local delayTime = cc.DelayTime:create(1.5)
	local callFunc = cc.CallFunc:create(function(sender)

		if self.roundReportMsg then
			self.isPlayerDecision = false
			self.haveHaidiPai = false
			dipaiNode:setVisible( false )
			self:onRcvRoundReport(self.roundReportMsg)
		end
	end)

	local seqAction = cc.Sequence:create(delayTime, callFunc)
	self:runAction(seqAction)

end

--初始化上精
function PlaySceneCS:initUpTurnNode()
	if self.upNode then
		self.upNode:removeFromParent()
		self.upNode = nil
	end
	self.upNode = cc.Node:create()
	
	self.upSpriteTitle = cc.Sprite:create("images/otherImages/turnup2.png") --标题
	self.upNode:addChild(self.upSpriteTitle)
	self.upSpriteTitle:setPosition(0, self.upSpriteTitle:getContentSize().height / 2)
	
	self.upNode1 = cc.Node:create()
	for i = 1 , 2  do
		if i == 1 then
			self["upSprite" .. i] = cc.Sprite:create("images/otherImages/turnmj.png")  --麻将背面
			self["upSprite" .. i]:setVisible(true)
		else
			local mjTileName = string.format("p4s%d_%d.png", gt.turnCard[1][1], gt.turnCard[1][2]) --要翻的牌
			self["upSprite" .. i] = cc.Sprite:createWithSpriteFrameName(mjTileName)
			self["upSprite" .. i]:setFlipX(true)

			self.turnUpTile = cc.Sprite:create("images/otherImages/zheng.png")
			self.turnUpTile:setFlipX(true)

			self["upSprite" .. i]:addChild(self.turnUpTile)
			self.turnUpTile:setPosition(cc.p(self["upSprite" .. i]:getContentSize().width, self["upSprite" .. i]:getContentSize().height))
			self["upSprite" .. i]:setVisible(false)
		end
		
		self.upNode1:addChild(self["upSprite" .. i], 5)
		self["upSprite" .. i]:setPosition(0, 0)
	end

	--负精
	local mjTileName = string.format("p4s%d_%d.png", gt.turnCard[2][1], gt.turnCard[2][2])
	self.nextUpTurnSpr = cc.Sprite:createWithSpriteFrameName(mjTileName)
	self.nextUpTurnSpr:setVisible(false)
	self.upNode1:addChild(self.nextUpTurnSpr)
	self.nextUpTurnSpr:setPosition(0,0)
	local turnTile = cc.Sprite:create("images/otherImages/fu.png")
	self.nextUpTurnSpr:addChild(turnTile)
	turnTile:setPosition(cc.p(self.nextUpTurnSpr:getContentSize().width, self.nextUpTurnSpr:getContentSize().height))


	self.upNode:addChild(self.upNode1)
	self.upNode1:setPosition(0, -self.nextUpTurnSpr:getContentSize().height / 2)

	self.playMjLayer:addChild(self.upNode,5)
	self.upNode:setPosition(self.playMjLayer:getContentSize().width / 2, self.playMjLayer:getContentSize().height / 2)
	--end
end

function PlaySceneCS:initDownTurnNode()
	self.downNode = cc.Node:create()
	local path = nil
	if gt.cardType == 2 then
		path = "images/otherImages/turndown2.png"
	elseif gt.cardType == 5 then
		path = "images/otherImages/thesong2.png"
	elseif gt.playType == 4 then
		path = "images/otherImages/turndown2.png"
	elseif gt.playType == 5 then
		path = "images/otherImages/turndown2.png"
	end
	self.downSpriteTitle = cc.Sprite:create(path)

	self.downNode:addChild(self.downSpriteTitle)
	self.downSpriteTitle:setPosition(0, self.downSpriteTitle:getContentSize().height / 2)

	self.downNode1 = cc.Node:create()
	for i = 1 , 2  do
		if i == 1 then
			self["downSprite" .. i] = cc.Sprite:create("images/otherImages/turnmj.png")
			--self.upSpriteTitle:addChild(self["upSprite" .. i], 5)
			self.downNode1:addChild(self["downSprite" .. i], 5)
			self["downSprite" .. i]:setVisible(true)
		else
			local mjTileName = string.format("p4s%d_%d.png", gt.turnCard[3][1], gt.turnCard[3][2])
			self["downSprite" .. i] = cc.Sprite:createWithSpriteFrameName(mjTileName)
			self["downSprite" .. i]:setFlipX(true)

			self.turndownTile = cc.Sprite:create("images/otherImages/zheng.png")
			self.turndownTile:setFlipX(true)

			self["downSprite" .. i]:addChild(self.turndownTile)
			self.turndownTile:setPosition(cc.p(self["downSprite" .. i]:getContentSize().width, self["downSprite" .. i]:getContentSize().height))

			self.downNode1:addChild(self["downSprite" .. i], 5)
			self["downSprite" .. i]:setVisible(false)
		end
		self["downSprite" .. i]:setPosition(0, 0)
	end

	local mjTileName = string.format("p4s%d_%d.png", gt.turnCard[4][1], gt.turnCard[4][2])
	local turnTile = cc.Sprite:create("images/otherImages/fu.png")
	self.nextDownTurnSpr = cc.Sprite:createWithSpriteFrameName(mjTileName)
	self.nextDownTurnSpr:addChild(turnTile)
	self.nextDownTurnSpr:setVisible(false)
	self.nextDownTurnSpr:setPosition(0,0)

	turnTile:setPosition(cc.p(self.nextDownTurnSpr:getContentSize().width, self.nextDownTurnSpr:getContentSize().height))
	self.downNode1:addChild(self.nextDownTurnSpr)
	
	self.downNode:addChild(self.downNode1)
	self.downNode1:setPosition(0, -self.nextDownTurnSpr:getContentSize().height / 2)

	self.playMjLayer:addChild(self.downNode,5)
	self.downNode:setPosition(self.playMjLayer:getContentSize().width / 2, self.playMjLayer:getContentSize().height / 2)
end

--下精移动到右上角
function PlaySceneCS:downDownTurn(args)
	local function  turnCallBack(sender, card)
		self.downSpriteTitle:setVisible(true)
		self:turnCallBack(card)
	end
	
	--展示负精
	local function showNextTurnCard(sender, card)
		self:showNextTurnCard(card)
	end
	--隐藏模态
	local function hideMaskLayer( ... )
		self.Img_turnbg2:setVisible(true)
		self.Spr_turndown:setVisible(true)
		self.downNode:setVisible(false)
		self:hideMaskLayer()
	end

	local function showTurnDownResultCallBack()
		self.downNode:setVisible(false)
		self:showUpDownTurnCard("down")
		if gt.cardType == 5 then
			self:showTurnResult("tongyishouge",1)
		else
			self:showTurnResult("down")
		end
	end

	local arg  =  args[1]
	if arg == 1 then  --牌局开始下精动作
		self:initDownTurnNode(true)
		local function hideDownCard()
			self.downSpriteTitle:setVisible(false)
		end
		
		self.downNode:runAction(cc.Sequence:create(cc.DelayTime:create(1),cc.CallFunc:create(hideDownCard), cc.MoveTo:create(0.5, cc.p(self.Img_turnbg2:getPositionX(),self.Img_turnbg2:getPositionY() + self.Img_turnbg2:getContentSize().height / 5)),cc.CallFunc:create(hideMaskLayer)))
		--self.downNode:runAction(cc.Sequence:create(cc.DelayTime:create(1),cc.CallFunc:create(hideDownCard), cc.Spawn:create(cc.ScaleTo:create(1,0.5),cc.MoveTo:create(1, cc.p(self.Img_turnbg2:getPositionX(),self.Img_turnbg2:getPositionY()))),cc.CallFunc:create(hideMaskLayer), cc.DelayTime:create(3), cc.CallFunc:create(aaa)))
		--self.downNode:runAction(cc.Sequence:create(cc.DelayTime:create(1), cc.MoveTo:create(1, cc.p(gt.playMjLayer.width - self.downSprite1:getContentSize().height, gt.playMjLayer.height - self.downSprite1:getContentSize().width)),cc.CallFunc:create(hideMaskLayer)))
	elseif arg == 2 then --牌局结束下精动作
		self.Spr_turndown:setVisible(false)
		--self.downNode:setVisible(true)
		self.downSpriteTitle:setVisible(false)
		self.downNode:runAction(cc.Sequence:create(cc.DelayTime:create(1), cc.MoveTo:create(0.5, cc.p(gt.winSize.width / 2, gt.winSize.height / 2)), cc.CallFunc:create(turnCallBack, {"downSprite"}), cc.DelayTime:create(1.5)
		, cc.CallFunc:create(showNextTurnCard, {"downSprite"}), cc.DelayTime:create(1), cc.Spawn:create(cc.ScaleTo:create(1,0.6), cc.MoveTo:create(0.5, cc.p(self.Img_turnbg3:getPositionX(), self.Img_turnbg3:getPositionY()))), cc.CallFunc:create(showTurnDownResultCallBack)))
	end
end

--翻牌
function PlaySceneCS:turnCallBack(card)
	local card = card[1]
	local seq = cc.Sequence:create(cc.DelayTime:create(1), cc.Hide:create(), cc.DelayTime:create(1))
	--持续时间、半径初始值、半径增量、仰角初始值、仰角增量、离x轴的偏移角、离x轴的偏移角的增量
	local orbit = cc.OrbitCamera:create(1, 1, 0, 0, -90, 0, 0)
	local spawn  = cc.Spawn:create(seq, orbit)
	self[card .. 1]:runAction(spawn)

	local seq1 = cc.Sequence:create(cc.DelayTime:create(1), cc.Show:create(), cc.DelayTime:create(1))
	--持续时间、半径初始值、半径增量、仰角初始值、仰角增量、离x轴的偏移角、离x轴的偏移角的增量
	local orbit1 = cc.OrbitCamera:create(1.5, 1, 0, 0, -180, 0, 0)
	local spawn1  = cc.Spawn:create(seq1, orbit1)
	self[card .. 2]:runAction(spawn1)
end

--推出负精
function PlaySceneCS:showNextTurnCard(card)
	local card = card[1]
	if card == "upSprite" then
		self.nextUpTurnSpr:setVisible(true)
		self.nextUpTurnSpr:runAction(cc.MoveBy:create(0.5, cc.p(self.nextUpTurnSpr:getContentSize().width / 2 + 10, 0)))
		self["upSprite2"]:runAction(cc.MoveBy:create(0.5, cc.p(-self.nextUpTurnSpr:getContentSize().width / 2 - 10, 0)))
	elseif card == "downSprite" then
		self.Img_turnbg2:setVisible(false)
		self.Spr_turndown:setVisible(false)
			
		self.Img_turnbg3:setVisible(true)

		self.nextDownTurnSpr:setVisible(true)
		self.nextDownTurnSpr:runAction(cc.MoveBy:create(0.5, cc.p(self.nextDownTurnSpr:getContentSize().width / 2 + 10, 0)))
		self["downSprite2"]:runAction(cc.MoveBy:create(0.5, cc.p(-self.nextDownTurnSpr:getContentSize().width / 2 - 10, 0)))
	end
end

--翻精消息回调
function PlaySceneCS:onShowTurnover(msgTbl)
	local delaytime = 1.5
	local function startPlayCard( ... )	
	    self.Img_turnbg1:setVisible(true)

		if self.havexiaJing then
			self.Img_turnbg2:setVisible(true)
		else
			self.Img_turnbg2:setVisible(false)
		end
		self.Spr_turndown:setVisible(false)
		self.Img_turnbg3:setVisible(false)
	  
		--展示负精
		local function showNextTurnCard(sender, card)
			self:showNextTurnCard(card)
		end

		--正负局精展示后移动到左上角
		local function moveByCallBack()
			local function setTurnTileCallBack()
			    self.upNode:removeFromParent()
				self.upNode = nil
				self:showUpDownTurnCard("up")
				
				if self.havexiaJing then	
					self.Img_turnbg2:setVisible(true)
				else
					self.Img_turnbg2:setVisible(false)
				end
				self.Spr_turndown:setVisible(false)
				self:updateHoldMjTiles()
				if self.isPlayerShow and self.playerSeatIdx == self.zhuang then
					self:sortPlayerMjTiles(true)
				else
					self:sortPlayerMjTiles()
				end

			end
			self.upSpriteTitle:setVisible(false)
			self.upNode:runAction(cc.Sequence:create(cc.Spawn:create(cc.ScaleTo:create(1,0.66),cc.MoveTo:create(0.5, cc.p(self.Img_turnbg1:getPositionX(), self.Img_turnbg1:getPositionY() + 20))), cc.CallFunc:create(setTurnTileCallBack)))
		
		end

		--翻上精牌
		local function  turnCallBack(sender, card)
			self:turnCallBack(card)
		end
		
		--初始化上精
		local function showUpTurn()
			
			self:initUpTurnNode(true)
	    end

		local function downDownTurn(sender, args)
			if gt.cardType == 1 and gt.playType == 1 then
				self:hideMaskLayer()
			elseif gt.playType == 1 and (gt.cardType == 2 or gt.cardType == 5)then
				self:downDownTurn(args)
			elseif gt.cardType == 3 then
				--回头一笑
				if self.huitou_jcard and self.huitou_jcard[1][1] == 0 then
					self:hideMaskLayer()
				else	
					self:showTurnResult("huitou")
				end
			elseif gt.cardType == 4 then
				if self.huitou_jcard and self.huitou_jcard[1][1] == 0 then
					self:showTurnResult("huitousx")
				else	
					self:showTurnResult("huitou")
				end
			elseif (gt.playType == 4 or gt.playType == 5) and gt.cardType == 1 then
				self:downDownTurn(args)
			elseif (gt.playType == 4 or gt.playType == 5) and gt.cardType == 2 then
				self:hideMaskLayer()
			end		
			-- 翻精结束，就可以显示精牌的标记了
			self.firstShow = false
		end
		
		self:runAction(cc.Sequence:create(cc.CallFunc:create(showUpTurn), cc.CallFunc:create(turnCallBack, {"upSprite"}), cc.DelayTime:create(delaytime)
		, cc.CallFunc:create(showNextTurnCard, {"upSprite"}), cc.DelayTime:create(delaytime - 1), cc.CallFunc:create(moveByCallBack),cc.DelayTime:create(delaytime - 0.5)
		, cc.CallFunc:create(downDownTurn, {1})))
	end

	local numberArr = {}
	for i = 1, 6 do 
		for j = 1, 6 do 
			if i + j == msgTbl.m_number then
				local number = {}
				table.insert(number,i)
				table.insert(number,j)
				table.insert(numberArr,number)
			end
		end
	end
	local finalNumber  = math.random(1,#numberArr)
	local first_number = numberArr[finalNumber][1]
	local second_number =  numberArr[finalNumber][2]
	
	local first_node = cc.Sprite:create()
	self.playMjLayer:addChild(first_node, 5)
	first_node:setPosition(gt.winSize.width / 2 - 80, gt.winSize.height / 2)
	local second_node = cc.Sprite:create()
	self.playMjLayer:addChild(second_node,5)
	second_node:setPosition(gt.winSize.width / 2 + 80, gt.winSize.height / 2)
	--精牌
	gt.turnCard = msgTbl.m_myCard
	--回头精 回头上下翻回头精
	self.huitou_bawang = msgTbl.m_pos
	self.huitou_chongguan = msgTbl.m_chongGuan
	self.huitou_jcard = msgTbl.m_myCardBack
	self.m_shangJingNum = msgTbl.m_shangJingNum
	self.m_xiaJingNum = msgTbl.m_xiaJingNum
	--回头上下翻下翻
	self.huitou_bawang_sx = msgTbl.m_pos_sx
	self.huitou_chongguan_sx = msgTbl.m_chongGuan_sx
	self.huitou_jcard_sx = msgTbl.m_myCardBack_sx
	self.m_shangJingNum_sx = msgTbl.m_shangJingNum_sx
	self.m_xiaJingNum_sx = msgTbl.m_xiaJingNum_sx


	self:showMaskLayer()
	
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
				
				local first_spr = cc.Sprite:create("images/otherImages/shaizi/touzi" .. first_number .. ".png")
				self.playMjLayer:addChild(first_spr, 5)
				first_spr:setPosition(gt.winSize.width / 2 - 80, gt.winSize.height / 2)
				local second_spr = cc.Sprite:create("images/otherImages/shaizi/touzi" .. second_number .. ".png")
				self.playMjLayer:addChild(second_spr,5)
				second_spr:setPosition(gt.winSize.width / 2 + 80, gt.winSize.height / 2)
				
				local function startPlayCardCallBack()
					first_spr:removeFromParent()
					second_spr:removeFromParent()
					startPlayCard()
				end
				self:runAction(cc.Sequence:create(cc.DelayTime:create(1), cc.CallFunc:create(startPlayCardCallBack)))
			end
			second_node:runAction(cc.Sequence:create(action,cc.CallFunc:create(showShaiziCallBack)))
		end
	end
end


function PlaySceneCS:updateHoldMjTiles()
	for seatIdx, roomPlayer in ipairs(self.roomPlayers) do
		if roomPlayer.seatIdx == self.playerSeatIdx then
			for _, mjTile in ipairs(roomPlayer.holdMjTiles) do
				if gt.turnCard and #gt.turnCard > 0 then
					local turnTile = nil
					if  mjTile.mjColor == gt.turnCard[1][1] and mjTile.mjNumber == gt.turnCard[1][2] then
						turnTile = cc.Sprite:create("images/otherImages/s_sanjiao.png")
						mjTile.mjTileSpr:removeAllChildren()
						mjTile.mjTileSpr:addChild(turnTile)
						turnTile:setPosition(cc.p(mjTile.mjTileSpr:getContentSize().width - turnTile:getContentSize().width / 2, mjTile.mjTileSpr:getContentSize().height - turnTile:getContentSize().height / 2))
						--turnTile:setPosition(cc.p(turnTile:getContentSize().width / 2, mjTile.mjTileSpr:getContentSize().height - turnTile:getContentSize().height / 2))
					elseif mjTile.mjColor == gt.turnCard[2][1] and  mjTile.mjNumber == gt.turnCard[2][2] then
						turnTile = cc.Sprite:create("images/otherImages/s_sanjiao.png")
						mjTile.mjTileSpr:removeAllChildren()
						mjTile.mjTileSpr:addChild(turnTile)
						turnTile:setPosition(cc.p(mjTile.mjTileSpr:getContentSize().width - turnTile:getContentSize().width / 2, mjTile.mjTileSpr:getContentSize().height - turnTile:getContentSize().height / 2))
						--turnTile:setPosition(cc.p(turnTile:getContentSize().width / 2, mjTile.mjTileSpr:getContentSize().height - turnTile:getContentSize().height / 2))
					end
				end
			end
		end
	end
end

--赣州上下左右翻精
function PlaySceneCS:Gan_SXZYJing(num)
	-- body
	
	local node_layer = self:playJingAnmiation(self.sxzy_paramTbl[num])
	node_layer:setAnchorPoint(0.5, 0.5)
	-- node_layer:setPosition(gt.winCenter)
	-- self:addChild(node_layer)
	self.playMjLayer:addChild(node_layer,10000)
	node_layer:setPosition(cc.p(self.mahjong_table:getContentSize().width / 2, self.mahjong_table:getContentSize().height / 2))
	



	local function turncardSprOutCallBack(sender)
		sender:removeFromParent()
		if num == 1 then
			self:Gan_SXZYJing(2)
		elseif num == 2 then
			self:Gan_SXZYJing(3)
		elseif num == 3 then
			self:hideMaskLayer()
			self:showRcvRoundReport(self.roundReportMsg)
		end

	end

	node_layer:runAction(cc.Sequence:create(cc.DelayTime:create(1.4), cc.FadeOut:create(1.2), cc.CallFunc:create(turncardSprOutCallBack)))

end



function PlaySceneCS:showTurnResult(state,num)
	local fadeOutTime = 1.2
	local turncardSpr = nil
	local index = 1
	if state == "up" then
		index = 1
		turncardSpr = cc.Sprite:create("images/otherImages/turnup1.png")
	elseif state == "down" then
		index = 2
		turncardSpr = cc.Sprite:create("images/otherImages/xiajing4.png")
	elseif state == "huitou" then
		index = 3
		turncardSpr = cc.Sprite:create("images/otherImages/turnhuitou.png")
	elseif state == "huitousx" then
		index = 4
		turncardSpr = cc.Sprite:create("images/otherImages/turndown1.png")
	elseif state == "tongyishouge" then
		index = 5
		turncardSpr = cc.Sprite:create("images/otherImages/thesong3.png")
	end
	self.playMjLayer:addChild(turncardSpr)
	turncardSpr:setPosition(cc.p(self.mahjong_table:getContentSize().width / 2, self.mahjong_table:getContentSize().height / 2))
	

	for i = 1 , self.maxPlayer do
		self["achieve" .. state .. i] = {}
		if index == 3  then -- 回头一笑 
			if self.huitou_bawang == i - 1 then
				local achieve = {}
				table.insert(achieve, 1)--霸王
				table.insert(achieve, 0)
				table.insert(self["achieve" .. state .. i], achieve)
			end

			if self.huitou_chongguan[i] > 1 then
				local achieve = {}
				table.insert(achieve, 2)--冲关
				table.insert(achieve, self.huitou_chongguan[i])
				table.insert(self["achieve".. state .. i], achieve)
			end
		elseif index == 4 then --回头上下翻
			if self.huitou_bawang_sx == i - 1 then
				local achieve = {}
				table.insert(achieve, 1)--霸王
				table.insert(achieve, 0)
				table.insert(self["achieve" .. state .. i], achieve)
			end

			if self.huitou_chongguan_sx[i] > 1 then
				local achieve = {}
				table.insert(achieve, 2)--冲关
				table.insert(achieve, self.huitou_chongguan_sx[i])
				table.insert(self["achieve".. state .. i], achieve)
			end
		elseif index == 5 then
			if self.TYSG_bawang[num] == i - 1 then
				local achieve = {}
				table.insert(achieve, 1)--霸王
				table.insert(achieve, 0)
				table.insert(self["achieve" .. state .. i], achieve)
			end

			if self.TYSG_chongguan[num] and self.TYSG_chongguan[num][i] > 1 then
				local achieve = {}
				table.insert(achieve, 2)--冲关
				table.insert(achieve, self.TYSG_chongguan[num][i])
				table.insert(self["achieve".. state .. i], achieve)
			end

			if self.TYSG_gangjing[num] and self.TYSG_gangjing[num][i] > 0 then
				local achieve = {}
				table.insert(achieve, 3)--杠精
				table.insert(achieve, self.TYSG_gangjing[num][i])
				table.insert(self["achieve" .. state .. i], achieve)
			end
		else
			if self.roundReportMsg["m_pos" .. index] == i - 1 then
				local achieve = {}
				table.insert(achieve, 1)--霸王
				table.insert(achieve, 0)
				table.insert(self["achieve" .. state .. i], achieve)
			end
			
			if self.roundReportMsg["m_chongGuan" .. index][i] > 1 then 
				local achieve = {}
				table.insert(achieve, 2)--冲关
				table.insert(achieve, self.roundReportMsg["m_chongGuan" .. index][i])
				table.insert(self["achieve".. state .. i], achieve)
			end

			if self.roundReportMsg["m_gangJing" .. index][i] > 0 then 
				local achieve = {}
				table.insert(achieve, 3)--杠精
				table.insert(achieve, self.roundReportMsg["m_gangJing" .. index][i])
				table.insert(self["achieve" .. state .. i], achieve)
			end
		end
	
	end	
	
	local index = self.playerSeatIdx
	local posTable = {cc.p(self.mahjong_table:getContentSize().width - self.mahjong_table:getContentSize().width / 5.5, self.mahjong_table:getContentSize().height / 2),
						cc.p(self.mahjong_table:getContentSize().width / 2, self.mahjong_table:getContentSize().height - self.mahjong_table:getContentSize().height / 5),
						cc.p(self.mahjong_table:getContentSize().width / 5.5, self.mahjong_table:getContentSize().height / 2),
						cc.p(self.mahjong_table:getContentSize().width / 2, self.mahjong_table:getContentSize().height / 5)}

	for i = 1, self.maxPlayer do 
		self[state .. i] = cc.Scale9Sprite:create("images/otherImages/resultbg.png")
		self[state .. i]:setContentSize(cc.size(400, 240))
		self[state .. i]:setScale(0.7)
		self.playMjLayer:addChild(self[state .. i], i * 10000)

		local index_pos = (i + self.seatOffset) % 4 
		if index_pos == 0 then
			index_pos = 4
		end
		if i ==  1 then
			self[state .. i]:setPosition(posTable[index_pos])
		elseif i == 2 then
			self[state .. i]:setPosition(posTable[index_pos])
		elseif i == 3 then
			self[state .. i]:setPosition(posTable[index_pos])
		elseif i == 4 then
			self[state .. i]:setPosition(posTable[index_pos])
		end
			
		if self.maxPlayer == 3 and i == 3 then
			self[state..i]:setPosition(posTable[(4 + self.seatOffset) % 4 ])
		end

		local width = 50
		for m = 1, #self["achieve" .. state .. i] do
			if self["achieve" .. state .. i][m][1] == 1 then
				local bawang = gt.createTTFLabel("", 28)
				bawang:setString("霸王")
				self[state .. i]:addChild(bawang)
				bawang:setPosition(cc.p(bawang:getContentSize().width / 2 + width, 40))
				width = bawang:getContentSize().width  +  width + 20
			elseif self["achieve" .. state .. i][m][1] == 2 then
				local chongguan = gt.createTTFLabel("", 28)
				chongguan:setString("冲关X" .. self["achieve" .. state .. i][m][2])
				self[state .. i]:addChild(chongguan)
				chongguan:setPosition(cc.p(chongguan:getContentSize().width / 2+ width, 40))
				width = chongguan:getContentSize().width  + width + 20
			elseif self["achieve" .. state .. i][m][1] == 3 then
				local gangjing = gt.createTTFLabel("", 28)
				gangjing:setString("杠精X" .. self["achieve" .. state .. i][m][2])
				self[state .. i]:addChild(gangjing)
				gangjing:setPosition(cc.p(gangjing:getContentSize().width / 2 + width, 40))
				width = gangjing:getContentSize().width  + width + 20
			end
		end
		
		
		for j = 1, 2 do
			if gt.turnCard and #gt.turnCard > 0 then
				local mjTileName = nil
				if state == "up" then
					mjTileName = string.format("p4b%d_%d.png", gt.turnCard[j][1], gt.turnCard[j][2])
				elseif state == "down" then
					mjTileName = string.format("p4b%d_%d.png", gt.turnCard[j + 2][1], gt.turnCard[j + 2][2])
				elseif state == "huitou" then
					if j == 1 then
						mjTileName = string.format("p4b%d_%d.png", self.huitou_jcard[1][1], self.huitou_jcard[1][2]) --回头精
					else
						mjTileName = string.format("p4b%d_%d.png", self.huitou_jcard[2][1], self.huitou_jcard[2][2])
					end
				elseif state == "huitousx" then
					if j == 1 then
						mjTileName = string.format("p4b%d_%d.png", self.huitou_jcard_sx[1][1], self.huitou_jcard_sx[1][2]) --回头精
					else
						mjTileName = string.format("p4b%d_%d.png", self.huitou_jcard_sx[2][1], self.huitou_jcard_sx[2][2])
					end
				elseif state == "tongyishouge" then
					if j == 1 then
						mjTileName = string.format("p4b%d_%d.png", self.TYSG_jcard[num][1][1], self.TYSG_jcard[num][1][2]) --同一首歌
					else
						mjTileName = string.format("p4b%d_%d.png", self.TYSG_jcard[num][2][1], self.TYSG_jcard[num][2][2])
					end
				end
				local mjSpr = cc.Sprite:createWithSpriteFrameName(mjTileName)
				self[state .. i]:addChild(mjSpr)
				mjSpr:setPosition(mjSpr:getContentSize().width / 3 + 50 + (j - 1) * 180, self[state .. i]:getContentSize().height / 2 + 10)
				gt.log("-------zhu---------" ..  self[state .. i]:getContentSize().height / 2 + 10 )

				local mjSprNumber = gt.createTTFLabel("", 28)
				if j == 1 then
					if state == "up" then
						mjSprNumber:setString(" X " .. self.roundReportMsg.m_shangJing[i])
					elseif state == "down" then
						mjSprNumber:setString(" X " .. self.roundReportMsg.m_xiaJing[i])
					elseif state == "huitou" then
						mjSprNumber:setString(" X " .. self.m_shangJingNum[i])
					elseif state == "huitousx" then
						mjSprNumber:setString(" X " .. self.m_shangJingNum_sx[i])
					elseif state == "tongyishouge" then
						mjSprNumber:setString(" X " .. self.TYSG_shangJingNum[num][i])
					end
				else
					if state == "up" then
						mjSprNumber:setString(" X " .. tonumber(self.roundReportMsg.m_shangJing[(4 + i)]))
					elseif state == "down" then
						mjSprNumber:setString(" X " .. tonumber(self.roundReportMsg.m_xiaJing[(4 + i)]))
					elseif state == "huitou" then
						mjSprNumber:setString(" X " .. self.m_xiaJingNum[i])
					elseif state == "huitousx" then
						mjSprNumber:setString(" X " .. self.m_xiaJingNum_sx[i])
					elseif state == "tongyishouge" then
						mjSprNumber:setString(" X " .. self.TYSG_xiaJingNum[num][i])
					end
				end
				self[state .. i]:addChild(mjSprNumber)
				mjSprNumber:setPosition(mjSpr:getContentSize().width * 1.5+ (j - 1) * 180 + 20, self[state .. i]:getContentSize().height / 2 - mjSpr:getContentSize().width / 2)
			end
		end
	end
			
	local function outCallBack()
		gt.log("#####outCallBack num ==" .. state)
		for i = 1, self.maxPlayer  do
			local objArr = self[state .. i]:getChildren()
			for j = 1, table.getn(objArr) do 
				local function objOutCallBack(sender)
					sender:removeFromParent()
				end
				local pObject = objArr[j]
				pObject:runAction(cc.Sequence:create(cc.FadeOut:create(fadeOutTime), cc.CallFunc:create(objOutCallBack)))
			end

			local function fatherObjOutCallBack( ... )
				gt.log("fatheroutcallback")
				self[state .. i]:removeFromParent()
			end
			self[state .. i]:runAction(cc.Sequence:create(cc.FadeOut:create(fadeOutTime), cc.CallFunc:create(fatherObjOutCallBack)))
		end

	end
	self:runAction(cc.Sequence:create(cc.DelayTime:create(1.4), cc.CallFunc:create(outCallBack)))

	local function turncardSprOutCallBack()
		turncardSpr:removeFromParent()
		if state == "up" then
			gt.log("--------xxx---上下".. gt.playType.. gt.cardType)
			if (gt.playType == 4 or gt.playType == 5) and gt.cardType == 2  then 
				gt.log("--------xxx---上下".. gt.playType.. gt.cardType)
			-- if true then
				self:Gan_SXZYJing(1)
				return
			end  


			if not self.havexiaJing then
				self:hideMaskLayer()
				self:showRcvRoundReport(self.roundReportMsg)
			--跳转到结算界面
			else
				self:initDownTurnNode(true)
				self.downNode:setPosition( cc.p(self.Img_turnbg2:getPositionX(),self.Img_turnbg2:getPositionY() + self.Img_turnbg2:getContentSize().height / 5))
				self:downDownTurn({2})
			end

		elseif state == "down" then
			self:hideMaskLayer()
			self:showRcvRoundReport(self.roundReportMsg)
			--跳转到结算界面
		elseif state == "huitou" then
			if gt.cardType == 4 then
				self:showTurnResult("huitousx")
			else
				self:hideMaskLayer()
			end
		elseif state == "huitousx" then
			self:hideMaskLayer()
		elseif state == "tongyishouge" then
			if num < #self.TYSG_jcard then
				self:showTurnResult("tongyishouge",num + 1)
				gt.log("next=======" ..  #self.TYSG_jcard)
			else
				self:hideMaskLayer()
				self:showRcvRoundReport(self.roundReportMsg)
			end
		end
	end
	turncardSpr:runAction(cc.Sequence:create(cc.DelayTime:create(1.4), cc.FadeOut:create(fadeOutTime), cc.DelayTime:create(0.2),cc.CallFunc:create(turncardSprOutCallBack)))
end

--黑框动画
--jing 正副精的color number
--num 正副精个数
--cgstring 钢精冲关的label
function PlaySceneCS:playJingAnmiation(paramTbl)
	-- body
	gt.log("--------zhulei--------")
	dump(paramTbl)
	local csbNode = cc.CSLoader:createNode("GanzhouJing.csb")
	csbNode:setAnchorPoint(0.5, 0.5)
	if self.maxPlayer == 3 then
		local image = gt.seekNodeByName(csbNode, "Image_3")
		image:setVisible(false)
	end
	for i = 1 , self.maxPlayer do
		if self.maxPlayer == 3 and i == 3 then
			i = 4
		end
		local image = gt.seekNodeByName(csbNode, "Image_" .. i)
		local zheng = gt.seekNodeByName(image, "zheng")
		zheng:setSpriteFrame(string.format("p4b%d_%d.png", paramTbl.jing[1][1], paramTbl.jing[1][2]))

		local fu = gt.seekNodeByName(image, "fu")
		fu:setSpriteFrame(string.format("p4b%d_%d.png", paramTbl.jing[2][1], paramTbl.jing[2][2]))

		local num1 = gt.seekNodeByName(image, "num1")
		num1:setString(" X " .. paramTbl.num[i][1])

		local num2 = gt.seekNodeByName(image, "num2")
		num2:setString(" X " .. paramTbl.num[i][2])

		local labelchongguan = gt.seekNodeByName(image, "labelchongguan")
		labelchongguan:setString(paramTbl.cgstring[i])
	end

	local spr = cc.Sprite:create(paramTbl.title)
	spr:setPosition(640,360)
	csbNode:addChild(spr)

	return csbNode
end

function PlaySceneCS:stopAudio()
	--停止录音
	--self:getLuaBridge()
	if gt.isIOSPlatform() then
		local ok, ret = self.luaBridge.callStaticMethod("AppController", "stopVoice")
	elseif gt.isAndroidPlatform() then
		local ok, ret = self.luaBridge.callStaticMethod("org/cocos2dx/lua/AppActivity", "stopVoice",nil,"()Z")
	end

	local getUrl = function ()
		-- body
		--self:getLuaBridge()
		local ok, ret
		if gt.isIOSPlatform() then
			ok, ret = self.luaBridge.callStaticMethod("AppController", "getVoiceUrl")
		elseif gt.isAndroidPlatform() then
			ok, ret = self.luaBridge.callStaticMethod("org/cocos2dx/lua/AppActivity", "getVoiceUrl", nil, "()Ljava/lang/String;")
			gt.log("the ret is .." .. ret)
		end

		if string.len(ret) > 0 and self.checkVoiceUrlType then

			self.checkVoiceUrlType = false

			--获得到地址上传给服务器
			local msgToSend = {}
			msgToSend.m_msgId = gt.CG_CHAT_MSG
			msgToSend.m_type = 4 -- 语音聊天
			msgToSend.m_musicUrl = ret
			gt.socketClient:sendMessage(msgToSend)

			gt.scheduler:unscheduleScriptEntry(self.voiceUrlScheduleHandler)
			--self.voiceUrlScheduleHandler = nil
		end
	end
	self.checkVoiceUrlType = true
	--if self.voiceUrlScheduleHandler then
		--gt.scheduler:unscheduleScriptEntry(self.voiceUrlScheduleHandler)
		--self.voiceUrlScheduleHandler = nil
	--end
	self.voiceUrlScheduleHandler = gt.scheduler:scheduleScriptFunc(getUrl, 0, false)

end

function PlaySceneCS:cancelAudio()
	--self:getLuaBridge()
	if gt.isIOSPlatform() then
		local ok, ret = self.luaBridge.callStaticMethod("AppController", "cancelVoice")
	elseif gt.isAndroidPlatform() then
		local ok, ret = self.luaBridge.callStaticMethod("org/cocos2dx/lua/AppActivity", "cancelVoice",nil,"()Z")
	end
end

return PlaySceneCS



