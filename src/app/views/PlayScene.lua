

local gt = cc.exports.gt

local PlayScene = class("PlayScene", function()
	return cc.Scene:create()
end)

--[[
Ming bar 明杠
touch tickets 摸牌
明杠与暗杠：杠牌分为名杠与暗杠两种。
Bright bars and dark bars: bar card classified as bars and dark bar two
self-drawn 自摸
--]]

PlayScene.DecisionType = {
	-- 接炮胡
	TAKE_CANNON_WIN				= 1,
	-- 自摸胡
	SELF_DRAWN_WIN				= 2,
	-- 明杠
	BRIGHT_BAR					= 3,
	-- 暗杠
	DARK_BAR					= 4,
	-- 碰
	PUNG						= 5
}

PlayScene.ZOrder = {
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
}

function PlayScene:ctor(enterRoomMsgTbl)
	-- 注册节点事件
	self:registerScriptHandler(handler(self, self.onNodeEvent))

	-- 加载界面资源
	local csbNode, animation = gt.createCSAnimation("PlayScene.csb")
	-- animation:play("run", true)
	csbNode:setAnchorPoint(0.5, 0.5)
	csbNode:setPosition(gt.winCenter)
	self:addChild(csbNode)
	self.rootNode = csbNode

	-- 房间号
	local roomIDLabel = gt.seekNodeByName(self.rootNode, "Label_roomID")
	roomIDLabel:setString(gt.getLocationString("LTKey_0013", enterRoomMsgTbl.m_deskId))

	-- 玩法
	-- 玩法类型
	self.playType = enterRoomMsgTbl.m_state
	local playTypeDesc = "点炮胡"
	if self.playType == 0 then
		playTypeDesc = "自摸胡"
	elseif self.playType == 2 then
		playTypeDesc = "可抢杠胡"
	end
	local playTypeLabel = gt.seekNodeByName(self.rootNode, "Label_playType")
	playTypeLabel:setString(playTypeDesc)

	-- 刚进入房间,隐藏玩家信息节点
	for i = 1, 4 do
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
	self.rootNode:reorderChild(decisionBtnNode, PlayScene.ZOrder.DECISION_BTN)
	decisionBtnNode:setVisible(false)
	-- 隐藏自摸决策暗杠，碰转明杠，自摸胡
	local selfDrawnDcsNode = gt.seekNodeByName(self.rootNode, "Node_selfDrawnDecision")
	self.rootNode:reorderChild(selfDrawnDcsNode, PlayScene.ZOrder.DECISION_BTN)
	selfDrawnDcsNode:setVisible(false)
	-- 隐藏游戏中设置按钮
	local playBtnsNode = gt.seekNodeByName(self.rootNode, "Node_playBtns")
	playBtnsNode:setVisible(false)
	-- 隐藏准备按钮
	local readyBtn = gt.seekNodeByName(self.rootNode, "Btn_ready")
	readyBtn:setVisible(false)
	gt.addBtnPressedListener(readyBtn, handler(self, self.readyBtnClickEvt))
	-- 隐藏所有玩家聊天对话框
	local chatBgNode = gt.seekNodeByName(self.rootNode, "Node_chatBg")
	self.rootNode:reorderChild(chatBgNode, PlayScene.ZOrder.CHAT)
	chatBgNode:setVisible(false)
	-- 设置按钮
	local settingBtn = gt.seekNodeByName(playBtnsNode, "Btn_setting")
	gt.addBtnPressedListener(settingBtn, function()
		local settingPanel = require("app/views/Setting"):create(enterRoomMsgTbl.m_pos)
		self:addChild(settingPanel, PlayScene.ZOrder.SETTING)
	end)
	-- 消息按钮
	local messageBtn = gt.seekNodeByName(playBtnsNode, "Btn_message")
	gt.addBtnPressedListener(messageBtn, function()
		local chatPanel = require("app/views/ChatPanel"):create()
		self:addChild(chatPanel, PlayScene.ZOrder.CHAT)
	end)

	-- 麻将层
	local playMjLayer = cc.Layer:create()
	self.rootNode:addChild(playMjLayer, PlayScene.ZOrder.MJTILES)
	self.playMjLayer = playMjLayer

	-- 出的牌标识动画
	local outMjtileSignNode, outMjtileSignAnime = gt.createCSAnimation("animation/OutMjtileSign.csb")
	outMjtileSignAnime:play("run", true)
	outMjtileSignNode:setVisible(false)
	self.rootNode:addChild(outMjtileSignNode, PlayScene.ZOrder.OUTMJTILE_SIGN)
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
	local paramTbl = {}
	paramTbl.roomID = enterRoomMsgTbl.m_deskId
	paramTbl.playerSeatPos = enterRoomMsgTbl.m_pos
	paramTbl.playTypeDesc = playTypeDesc
	paramTbl.roundMaxCount = enterRoomMsgTbl.m_maxCircle
	self.readyPlay = require("app/views/ReadyPlay"):create(csbNode, paramTbl)

	-- 解散房间
	self.applyDimissRoom = require("app/views/ApplyDismissRoom"):create(self.roomPlayers, self.playerSeatIdx)
	self:addChild(self.applyDimissRoom, PlayScene.ZOrder.DISMISS_ROOM)

	if gt.isIOSPlatform() then
		self.luaBridge = require("cocos/cocos2d/luaoc")
	elseif gt.isAndroidPlatform() then
		self.luaBridge = require("cocos/cocos2d/luaj")
	end

	-- 接收消息分发函数
	gt.socketClient:registerMsgListener(gt.GC_ROOM_CARD, self, self.onRcvRoomCard)
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
end

function PlayScene:unregisterAllMsgListener()
	gt.socketClient:unregisterMsgListener(gt.GC_ROOM_CARD)
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
end

function PlayScene:onNodeEvent(eventName)
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

		gt.soundEngine:playMusic("bgm1", true)
	end
end

function PlayScene:onTouchBegan(touch, event)
	if gt.isIOSPlatform() then
		-- writePath/uid-time.mp3
		local savePath = string.format("%s%s-%s.mp3", cc.FileUtils:getInstance():getWritablePath(), gt.playerData.uid, os.time())
		self.savePath = savePath
		local ok, ret = self.luaBridge.callStaticMethod("AppController", "startRecording", {filePath = savePath})
	elseif gt.isAndroidPlatform() then
		-- local ok, ret = self.luaBridge.callStaticMethod("org/cocos2dx/lua/AppActivity", "isWXAppInstalled", nil, "()Z")
	end

	-- gt.log(string.format("isPlayerShow:[%s] isPlayerDecision:[%s]", tostring(self.isPlayerShow), tostring(self.isPlayerDecision)))
	if not self.isPlayerShow or self.isPlayerDecision then
		return false
	end

	local touchMjTile, mjTileIdx = self:touchPlayerMjTiles(touch)
	if not touchMjTile then
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

function PlayScene:onTouchMoved(touch, event)
	local touchPoint = self.playMjLayer:convertTouchToNodeSpace(touch)
	self.chooseMjTile.mjTileSpr:setPosition(touchPoint)

	self.isTouchMoved = true
end

function PlayScene:onTouchEnded(touch, event)
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
			local moveAction = cc.MoveTo:create(0.25, cc.p(mjTilePos.x, mjTilePos.y + 26))  -- 在 0.25秒之内就是双击。
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
		msgToSend.m_flag = 1
		msgToSend.m_color = self.chooseMjTile.mjColor
		msgToSend.m_number = self.chooseMjTile.mjNumber
		gt.socketClient:sendMessage(msgToSend)
		self.isPlayerShow = false
		self.preClickMjTile = nil
		-- 停止倒计时音效
		if self.playCDAudioID then
			gt.soundEngine:stopEffect(self.playCDAudioID)
			self.playCDAudioID = nil
		end
	end
end

function PlayScene:update(delta)
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
-- @description 接收房卡信息
-- @param msgTbl 消息体
-- end --
function PlayScene:onRcvRoomCard(msgTbl)
	gt.playerData.roomCardsCount = {msgTbl.m_card1, msgTbl.m_card2, msgTbl.m_card3}
end

-- start --
--------------------------------
-- @class function
-- @description 进入房间
-- @param msgTbl 消息体
-- end --
function PlayScene:onRcvEnterRoom(msgTbl)
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
function PlayScene:onRcvAddPlayer(msgTbl)
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

	-- 房间添加玩家
	self:roomAddPlayer(roomPlayer)
end

-- start --
--------------------------------
-- @class function
-- @description 从房间移除一个玩家
-- @param msgTbl 消息体
-- end --
function PlayScene:onRcvRemovePlayer(msgTbl)
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
	self.playerHeadMgr:detach(headSpr)

	-- 去除数据
	self.roomPlayers[seatIdx] = nil
end

-- start --
--------------------------------
-- @class function
-- @description 断线重连
-- end --
function PlayScene:onRcvSyncRoomState(msgTbl)
	if msgTbl.m_state == 1 then
		-- 等待状态
		return
	end

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
	-- 显示游戏中按钮（消息，设置）
	local playBtnsNode = gt.seekNodeByName(self.rootNode, "Node_playBtns")
	playBtnsNode:setVisible(true)

	if msgTbl.m_pos then
		-- 显示当前出牌座位标示
		local seatIdx = msgTbl.m_pos + 1
		self:setTurnSeatSign(seatIdx)
		if seatIdx == self.playerSeatIdx then
			-- 玩家选择出牌
			self.isPlayerShow = true
		end
	end

	-- 牌局状态,剩余牌
	local roundStateNode = gt.seekNodeByName(self.rootNode, "Node_roundState")
	local remainTilesLabel = gt.seekNodeByName(roundStateNode, "Label_remainTiles")
	remainTilesLabel:setString(tostring(msgTbl.m_dCount))

	-- 庄家座位号
	local bankerSeatIdx = msgTbl.m_zhuang + 1

	-- 其他玩家牌
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
		-- 麻将放置参考点
		roomPlayer.mjTilesReferPos = self:setPlayerMjTilesReferPos(roomPlayer.displaySeatIdx)
		-- 剩余持有牌数量
		roomPlayer.mjTilesRemainCount = msgTbl.m_CardCount[seatIdx]
		if roomPlayer.seatIdx == self.playerSeatIdx then
			-- 玩家持有牌
			if msgTbl.m_myCard then
				for _, v in ipairs(msgTbl.m_myCard) do
					self:addMjTileToPlayer(v[1], v[2])
				end
				-- 根据花色大小排序并重新放置位置
				self:sortPlayerMjTiles()
			end
		else
			local mjTilesReferPos = roomPlayer.mjTilesReferPos
			local mjTilePos = mjTilesReferPos.holdStart
			local maxCount = roomPlayer.mjTilesRemainCount + 1
			for i = 1, maxCount do
				local mjTileName = string.format("tbgs_%d.png", roomPlayer.displaySeatIdx)
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

		-- 暗杠
		local darkBarArray = msgTbl["m_aCard" .. turnPos]
		if darkBarArray then
			for _, v in ipairs(darkBarArray) do
				self:addMjTileBar(seatIdx, v[1], v[2], false)
			end
		end

		-- 明杠
		local brightBarArray = msgTbl["m_mCard" .. turnPos]
		if brightBarArray then
			for _, v in ipairs(brightBarArray) do
				self:addMjTileBar(seatIdx, v[1], v[2], true)
			end
		end

		-- 碰
		local pungArray = msgTbl["m_pCard" .. turnPos]
		if pungArray then
			for _, v in ipairs(pungArray) do
				self:addMjTilePung(seatIdx, v[1], v[2])
			end
		end
	end
end

-- start --
--------------------------------
-- @class function
-- @description 玩家准备手势
-- @param msgTbl 消息体
-- end --
function PlayScene:onRcvReady(msgTbl)
	local seatIdx = msgTbl.m_pos + 1
	self:playerGetReady(seatIdx)
end

-- start --
--------------------------------
-- @class function
-- @description 玩家在线标识
-- @param msgTbl 消息体
-- end --
function PlayScene:onRcvOffLineState(msgTbl)
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
function PlayScene:onRcvRoundState(msgTbl)
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
function PlayScene:onRcvStartGame(msgTbl)
	self:onRcvSyncRoomState(msgTbl)
end

-- start --
--------------------------------
-- @class function
-- @description 通知玩家出牌
-- @param msgTbl 消息体
-- end --
function PlayScene:onRcvTurnShowMjTile(msgTbl)
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

		local decisionTypes = {}
		if msgTbl.m_canHu == 1 then
			-- 自摸胡
			local decisionData = {}
			decisionData.flag = 0
			decisionData.mjColor = msgTbl.m_color
			decisionData.mjNumber = msgTbl.m_number
			table.insert(decisionTypes, decisionData)
		end
		if msgTbl.m_aCard then
			-- 暗杠
			for _, v in ipairs(msgTbl.m_aCard) do
				local decisionData = {}
				decisionData.flag = 2
				decisionData.mjColor = v[1]
				decisionData.mjNumber = v[2]
				table.insert(decisionTypes, decisionData)
			end
		end
		if msgTbl.m_mCard then
			-- 明杠
			for _, v in ipairs(msgTbl.m_mCard) do
				local decisionData = {}
				decisionData.flag = 3
				decisionData.mjColor = v[1]
				decisionData.mjNumber = v[2]
				table.insert(decisionTypes, decisionData)
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
						end
						-- 过,漏胡提示
						-- if msgTbl.m_canHu == 1 then
						-- 	require("app/views/NoticeTips"):create(gt.getLocationString("LTKey_0007"),
						-- 		gt.getLocationString("LTKey_0043"), passDecision)
						-- else
							passDecision()
						-- end
					end)
				else
					decisionBtn:setVisible(false)
				end
			end
			local barCount = 1
			for idx, decisionData in ipairs(decisionTypes) do
				local decisionBtn = nil
				if decisionData.flag == 0 then
					-- 自摸胡
					decisionBtn = gt.seekNodeByName(selfDrawnDcsNode, "Btn_decisionWin")
				else
					-- 明暗杠
					decisionBtn = gt.seekNodeByName(selfDrawnDcsNode, "Btn_decisionBar_" .. barCount)

					barCount = barCount + 1
				end
				-- 显示杠胡牌
				local mjTileSpr = gt.seekNodeByName(decisionBtn, "Spr_mjTile")
				if mjTileSpr then
					mjTileSpr:setSpriteFrame(string.format("p4s%d_%d.png", decisionData.mjColor, decisionData.mjNumber))
				end
				decisionBtn:setVisible(true)
				decisionBtn:setTag(idx)
				gt.addBtnPressedListener(decisionBtn, function(sender)
					self.isPlayerDecision = false

					local selfDrawnDcsNode = gt.seekNodeByName(self.rootNode, "Node_selfDrawnDecision")
					selfDrawnDcsNode:setVisible(false)

					-- 发送消息
					local btnTag = sender:getTag()
					local decisionData = decisionTypes[sender:getTag()]
					local msgToSend = {}
					msgToSend.m_msgId = gt.CG_SHOW_MJTILE
					msgToSend.m_flag = decisionData.flag
					msgToSend.m_color = decisionData.mjColor
					msgToSend.m_number = decisionData.mjNumber
					gt.socketClient:sendMessage(msgToSend)
				end)
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
			if dn == 2 or dn == -2 then
				vv:setPosition( cc.pAdd(mjTilePos,cc.p(-15,0)) )			
			elseif dn == -1 or dn == 3 then
				vv:setPosition( cc.pAdd(mjTilePos,cc.p(0,30)) )									
			elseif dn == 1 or dn == -3 then
				vv:setPosition( cc.pAdd(mjTilePos,cc.p(0,-40)) )							
			end
		end
	end
end

-- start --
--------------------------------
-- @class function
-- @description 广播玩家出牌
-- end --
function PlayScene:onRcvSyncShowMjTile(msgTbl)
	if msgTbl.m_errorCode ~= 0 then
		return
	end

	local seatIdx = msgTbl.m_pos + 1
	local roomPlayer = self.roomPlayers[seatIdx]
	if msgTbl.m_flag == 0 then
		-- 自摸胡
		self:showDecisionAnimation(seatIdx, PlayScene.DecisionType.SELF_DRAWN_WIN)
	elseif msgTbl.m_flag == 1 then

		-- 出牌动作
		local mjTilesReferPos = roomPlayer.mjTilesReferPos
		local mjTilePos = mjTilesReferPos.holdStart
		local realpos = cc.pAdd(mjTilePos, cc.pMul(mjTilesReferPos.holdSpace, roomPlayer.mjTilesRemainCount))

		-- 显示出的牌
		if self.startMjTileAnimation ~= nil then
			self.startMjTileAnimation:stopAllActions()
			self.startMjTileAnimation:removeFromParent()
			self.startMjTileAnimation = nil
			self:addAlreadyOutMjTiles(self.preShowSeatIdx, self.startMjTileColor, self.startMjTileNumber)
		end
		if seatIdx ~= self.playerSeatIdx then
			self:showMjTileAnimation(seatIdx, realpos, msgTbl.m_color, msgTbl.m_number,function()				
				-- 显示出的牌
				self:addAlreadyOutMjTiles(seatIdx, msgTbl.m_color, msgTbl.m_number)
				-- 显示出的牌箭头标识
				self:showOutMjtileSign(seatIdx)		
			end)
		else
			self:showMjTileAnimation(seatIdx, cc.p(self.chooseMjTile.mjTileSpr:getPositionX(),self.chooseMjTile.mjTileSpr:getPositionY()), msgTbl.m_color, msgTbl.m_number,function()				
				-- 显示出的牌
				self:addAlreadyOutMjTiles(seatIdx, msgTbl.m_color, msgTbl.m_number)
				-- 显示出的牌箭头标识
				self:showOutMjtileSign(seatIdx)		
			end)
		end
		
		if seatIdx == self.playerSeatIdx then
			-- 玩家持有牌中去除打出去的牌
			local mjTile = roomPlayer.holdMjTiles[self.chooseMjTileIdx]
			mjTile.mjTileSpr:removeFromParent()
			table.remove(roomPlayer.holdMjTiles, self.chooseMjTileIdx)

			self:sortPlayerMjTiles()
		else
			roomPlayer.holdMjTiles[roomPlayer.mjTilesRemainCount].mjTileSpr:setVisible(false)
			roomPlayer.mjTilesRemainCount = roomPlayer.mjTilesRemainCount - 1
		end
		
		-- 记录出牌的上家
		self.preShowSeatIdx = seatIdx

		if roomPlayer.sex == 1 then
			-- 男性
			gt.soundEngine:playEffect(string.format("man/mjt%d_%d", msgTbl.m_color, msgTbl.m_number))
		else
			-- 女性
			gt.soundEngine:playEffect(string.format("woman/mjt%d_%d", msgTbl.m_color, msgTbl.m_number))
		end
	elseif msgTbl.m_flag == 2 then
		-- 暗杠
		self:addMjTileBar(seatIdx, msgTbl.m_color, msgTbl.m_number, false)
		self:hideOtherPlayerMjTiles(seatIdx, true, false)
		self:showDecisionAnimation(seatIdx, PlayScene.DecisionType.DARK_BAR)
	elseif msgTbl.m_flag == 3 then
		-- 碰转明杠
		self:changePungToBrightBar(seatIdx, msgTbl.m_color, msgTbl.m_number)
		self:showDecisionAnimation(seatIdx, PlayScene.DecisionType.BRIGHT_BAR)
	end
end

-- start --
--------------------------------
-- @class function
-- @description 通知玩家决策
-- end --
function PlayScene:onRcvMakeDecision(msgTbl)
	if msgTbl.m_flag == 1 then
		-- 玩家决策
		self.isPlayerDecision = true

		-- 决策倒计时
		self:playTimeCDStart(msgTbl.m_time)

		-- 玩家决策
		local decisionTypes = msgTbl.array
		-- 最后加入决策"过"选项
		table.insert(decisionTypes, 0)
		local isCanWin = false
		for _, v in ipairs(decisionTypes) do
			if v == 1 then
				isCanWin = true
				break
			end
		end

		-- 显示对应的决策按键
		local decisionBtnNode = gt.seekNodeByName(self.rootNode, "Node_decisionBtn")
		decisionBtnNode:setVisible(true)
		for _, decisionBtn in ipairs(decisionBtnNode:getChildren()) do
			decisionBtn:setVisible(false)
		end
		local decisionBtn = gt.seekNodeByName(decisionBtnNode, "Btn_decision_3")
		local btnSize = decisionBtn:getContentSize()
		local btnSpace = btnSize.width * 1.5
		local width = #decisionTypes * btnSpace - btnSize.width * 0.5
		local leftSpace = (gt.winSize.width - width) * 0.5
		local btnPos = cc.p(leftSpace + btnSize.width * 0.5, decisionBtn:getPositionY())
		for _, v in ipairs(decisionTypes) do
			local decisionBtn = gt.seekNodeByName(decisionBtnNode, "Btn_decision_" .. v)
			decisionBtn:setTag(v)
			decisionBtn:setVisible(true)
			decisionBtn:setPosition(btnPos)
			btnPos = cc.pAdd(btnPos, cc.p(btnSpace, 0))

			-- 显示要碰，杠，胡的牌
			local mjTileSpr = gt.seekNodeByName(decisionBtn, "Spr_mjTile")
			if mjTileSpr then
				mjTileSpr:setSpriteFrame(string.format("p4s%d_%d.png", msgTbl.m_color, msgTbl.m_number))
			end

			-- 响应决策按键事件
			gt.addBtnPressedListener(decisionBtn, function(sender)
				local function makeDecision(decisionType)
					self.isPlayerDecision = false

					-- 隐藏决策按键
					local decisionBtnNode = gt.seekNodeByName(self.rootNode, "Node_decisionBtn")
					decisionBtnNode:setVisible(false)

					-- 发送决策消息
					local msgToSend = {}
					msgToSend.m_msgId = gt.CG_PLAYER_DECISION
					msgToSend.m_think = decisionType
					gt.socketClient:sendMessage(msgToSend)
				end

				local decisionType = sender:getTag()
				-- if decisionType == 0 and isCanWin then
				-- 	-- 漏胡提示
				-- 	require("app/views/NoticeTips"):create(gt.getLocationString("LTKey_0007"),
				-- 		gt.getLocationString("LTKey_0043"),
				-- 		function()
				-- 			makeDecision(decisionType)
				-- 		end)
				-- else
					makeDecision(decisionType)
				-- end
			end)
		end
	end
end

-- start --
--------------------------------
-- @class function
-- @description 广播决策结果
-- end --
function PlayScene:onRcvSyncMakeDecision(msgTbl)
	if msgTbl.m_errorCode ~= 0 then
		return
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
	if msgTbl.m_think == 1 then
		-- 接炮胡
		self:showDecisionAnimation(seatIdx, PlayScene.DecisionType.TAKE_CANNON_WIN)
	elseif msgTbl.m_think == 2 then
		-- 明杠
		self:addMjTileBar(seatIdx, msgTbl.m_color, msgTbl.m_number, true)
		-- 杠牌动画
		self:showDecisionAnimation(seatIdx, PlayScene.DecisionType.BRIGHT_BAR)

		-- 隐藏持有牌中打出的牌
		self:hideOtherPlayerMjTiles(seatIdx, true, true)
		-- 移除上家打出的牌
		self:removePreRoomPlayerOutMjTile()
	elseif msgTbl.m_think == 3 then
		-- 碰牌
		self:addMjTilePung(seatIdx, msgTbl.m_color, msgTbl.m_number)
		-- 碰牌动画
		self:showDecisionAnimation(seatIdx, PlayScene.DecisionType.PUNG)

		-- 隐藏持有牌中打出的牌
		self:hideOtherPlayerMjTiles(seatIdx, false)
		-- 移除上家打出的牌
		self:removePreRoomPlayerOutMjTile()
	end
end

function PlayScene:onRcvChatMsg(msgTbl)
	local chatBgNode = gt.seekNodeByName(self.rootNode, "Node_chatBg")
	chatBgNode:setVisible(true)
	local seatIdx = msgTbl.m_pos + 1
	for i = 1, 4 do
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

function PlayScene:onRcvRoundReport(msgTbl)
	-- 显示准备按钮
	local readyBtn = gt.seekNodeByName(self.rootNode, "Btn_ready")
	readyBtn:setVisible(true)

	-- 停止未完成动作
	if self.startMjTileAnimation ~= nil then
		self.startMjTileAnimation:stopAllActions()
		self.startMjTileAnimation:removeFromParent()
		self.startMjTileAnimation = nil
	end

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

	-- 弹出局结算界面
	local roundReport = require("app/views/RoundReport"):create(self.roomPlayers, self.playerSeatIdx, msgTbl)
	self:addChild(roundReport, PlayScene.ZOrder.REPORT)
end

function PlayScene:onRcvFinalReport(msgTbl)
	local finalReport = require("app/views/FinalReport"):create(self.roomPlayers, msgTbl)
	self:addChild(finalReport, PlayScene.ZOrder.REPORT)
end

-- start --
--------------------------------
-- @class function
-- @description 更新当前时间
-- end --
function PlayScene:updateCurrentTime()
	local timeLabel = gt.seekNodeByName(self, "Label_time")
	local curTimeStr = os.date("%X", os.time())
	local timeSections = string.split(curTimeStr, ":")
	-- 时:分
	timeLabel:setString(string.format("%s:%s", timeSections[1], timeSections[2]))
end

function PlayScene:checkPlayName( str )
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
function PlayScene:roomAddPlayer(roomPlayer)
	gt.dump(roomPlayer)

	local playerInfoNode = gt.seekNodeByName(self.rootNode, "Node_playerInfo_" .. roomPlayer.displaySeatIdx)
	playerInfoNode:setVisible(true)
	-- 头像
	local headSpr = gt.seekNodeByName(playerInfoNode, "Spr_head")
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
	if #self.roomPlayers == 4 then
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
function PlayScene:playerEnterRoom(msgTbl)
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
	roomPlayer.displaySeatIdx = 4
	roomPlayer.readyState = msgTbl.m_ready
	roomPlayer.score = msgTbl.m_score
	-- 添加玩家自己
	self:roomAddPlayer(roomPlayer)

	-- 房间编号
	self.roomID = msgTbl.m_deskId
	-- 玩家座位编号
	self.playerSeatIdx = roomPlayer.seatIdx
	-- 玩家显示固定座位号
	self.playerFixDispSeat = 4
	-- 逻辑座位和显示座位偏移量(从0编号开始)
	local seatOffset = (self.playerFixDispSeat - 1) - msgTbl.m_pos
	self.seatOffset = seatOffset
	-- 旋转座次标识
	local turnPosBgSpr = gt.seekNodeByName(self.rootNode, "Spr_turnPosBg")
	turnPosBgSpr:setRotation(-seatOffset * 90)
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
function PlayScene:readyBtnClickEvt()
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
function PlayScene:playerGetReady(seatIdx)
	local roomPlayer = self.roomPlayers[seatIdx]

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

		-- 隐藏微信分享按钮
		-- 隐藏解散房间按钮
		-- 如果是房主隐藏解散房间按钮
		-- local readyPlayNode = gt.seekNodeByName(self.rootNode, "Node_readyPlay")
		-- readyPlayNode:setVisible(false)
	end
end

-- start --
--------------------------------
-- @class function
-- @description 隐藏所有玩家准备手势标识
-- end --
function PlayScene:hidePlayersReadySign()
	for i = 1, 4 do
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
function PlayScene:showPlayerInfo(sender)
	local senderTag = sender:getTag()
	local roomPlayer = self.roomPlayers[senderTag]
	if not roomPlayer then
		return
	end

	local playerInfoTips = require("app/views/PlayerInfoTips"):create(roomPlayer)
	self:addChild(playerInfoTips, PlayScene.ZOrder.PLAYER_INFO_TIPS)
end

-- start --
--------------------------------
-- @class function
-- @description 设置玩家麻将基础参考位置
-- @param displaySeatIdx 显示座位编号
-- @return 玩家麻将基础参考位置
-- end --
function PlayScene:setPlayerMjTilesReferPos(displaySeatIdx)
	local mjTilesReferPos = {}

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
function PlayScene:setTurnSeatSign(seatIdx)
	-- 显示轮到的玩家座位标识
	local turnPosBgSpr = gt.seekNodeByName(self.rootNode, "Spr_turnPosBg")
	-- 显示当先座位标识
	local turnPosSpr = gt.seekNodeByName(turnPosBgSpr, "Spr_turnPos_" .. seatIdx)
	turnPosSpr:setVisible(true)
	if self.preTurnSeatIdx and self.preTurnSeatIdx ~= seatIdx then
		-- 隐藏上次座位标识
		local turnPosSpr = gt.seekNodeByName(turnPosBgSpr, "Spr_turnPos_" .. self.preTurnSeatIdx)
		turnPosSpr:setVisible(false)
	end
	self.preTurnSeatIdx = seatIdx
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
function PlayScene:playTimeCDStart(timeDuration)
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
function PlayScene:playTimeCDUpdate(delta)
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
function PlayScene:addMjTileToPlayer(mjColor, mjNumber)
	local mjTileName = string.format("p%db%d_%d.png", self.playerFixDispSeat, mjColor, mjNumber)
	local mjTileSpr = cc.Sprite:createWithSpriteFrameName(mjTileName)
	self.playMjLayer:addChild(mjTileSpr)

	local roomPlayer = self.roomPlayers[self.playerSeatIdx]
	local mjTile = {}
	mjTile.mjTileSpr = mjTileSpr
	mjTile.mjColor = mjColor
	mjTile.mjNumber = mjNumber
	table.insert(roomPlayer.holdMjTiles, mjTile)

	return mjTile
end

-- start --
--------------------------------
-- @class function
-- @description 玩家麻将牌根据花色，编号重新排序
-- end --
function PlayScene:sortPlayerMjTiles()
	local roomPlayer = self.roomPlayers[self.playerSeatIdx]
	-- 按照花色分类
	local colorsMjTiles = {}
	for _, mjTile in ipairs(roomPlayer.holdMjTiles) do
		if not colorsMjTiles[mjTile.mjColor] then
			colorsMjTiles[mjTile.mjColor] = {}
		end
		table.insert(colorsMjTiles[mjTile.mjColor], mjTile)
	end
	-- dump(colorsMjTiles)

	-- 同花色从小到大排序
	local transMjTiles = {}
	for _, sameColorMjTiles in pairs(colorsMjTiles) do
		table.sort(sameColorMjTiles, function(a, b)
			return a.mjNumber < b.mjNumber
		end)
		for _, mjTile in ipairs(sameColorMjTiles) do
			table.insert(transMjTiles, mjTile)
		end
	end
	-- dump(transMjTiles)

	-- 重新放置位置
	local mjTilesReferPos = roomPlayer.mjTilesReferPos
	local mjTilePos = mjTilesReferPos.holdStart
	for _, mjTile in ipairs(transMjTiles) do
		mjTile.mjTileSpr:setPosition(mjTilePos)
		self.playMjLayer:reorderChild(mjTile.mjTileSpr, (gt.winSize.height - mjTilePos.y))
		mjTilePos = cc.pAdd(mjTilePos, mjTilesReferPos.holdSpace)
	end
	-- dump(transMjTiles)

	roomPlayer.holdMjTiles = transMjTiles
end

-- start --
--------------------------------
-- @class function
-- @description 选中玩家麻将牌
-- @return 选中的麻将牌
-- end --
function PlayScene:touchPlayerMjTiles(touch)
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
function PlayScene:addAlreadyOutMjTiles(seatIdx, mjColor, mjNumber, isHide)
	-- 添加到已出牌列表
	local roomPlayer = self.roomPlayers[seatIdx]
	local mjTileSpr = cc.Sprite:createWithSpriteFrameName(string.format("p%ds%d_%d.png", roomPlayer.displaySeatIdx, mjColor, mjNumber))
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
	mjTilePos = cc.pAdd(mjTilePos, cc.pMul(mjTilesReferPos.outSpaceV, lineCount)) -- 相乘
	mjTilePos = cc.pAdd(mjTilePos, cc.pMul(mjTilesReferPos.outSpaceH, lineIdx))
	mjTileSpr:setPosition(mjTilePos)
	self.playMjLayer:addChild(mjTileSpr, (gt.winSize.height - mjTilePos.y))
end

-- start --
--------------------------------
-- @class function
-- @description 移除上家被下家，杠打出的牌
-- end --
function PlayScene:removePreRoomPlayerOutMjTile()
	-- 移除上家打出的牌
	if self.preShowSeatIdx then
		local roomPlayer = self.roomPlayers[self.preShowSeatIdx]
		local endIdx = #roomPlayer.outMjTiles
		local outMjTile = roomPlayer.outMjTiles[endIdx]
		outMjTile.mjTileSpr:removeFromParent()
		table.remove(roomPlayer.outMjTiles, endIdx)

		-- 隐藏出牌标识箭头
		self.outMjtileSignNode:setVisible(false)
	end
end

-- start --
--------------------------------
-- @class function
-- @description 显示指示出牌标识箭头动画
-- @param seatIdx 座次
-- end --
function PlayScene:showOutMjtileSign(seatIdx)
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
function PlayScene:hideOtherPlayerMjTiles(seatIdx, isBar, isBrightBar)
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
	for i = 1, mjTilesCount do
		local mjTile = roomPlayer.holdMjTiles[idx]
		mjTile.mjTileSpr:setVisible(false)

		idx = idx + 1
	end
	-- for _, mjTile in ipairs(roomPlayer.holdMjTiles) do
	-- 	gt.log("mjTile.mjTileSpr visible:" .. tostring(mjTile.mjTileSpr:isVisible()))
	-- end
	roomPlayer.mjTilesRemainCount = roomPlayer.mjTilesRemainCount - mjTilesCount
end

-- start --
--------------------------------
-- @class function
-- @description 碰牌
-- @param seatIdx 座位编号
-- @param mjColor 麻将牌花色
-- @param mjNumber 麻将牌编号
-- end --
function PlayScene:addMjTilePung(seatIdx, mjColor, mjNumber)
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
function PlayScene:addMjTileBar(seatIdx, mjColor, mjNumber, isBrightBar)
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
	dump(barData)

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
function PlayScene:pungBarReorderMjTiles(seatIdx, mjColor, mjNumber, isBar, isBrightBar)
	local roomPlayer = self.roomPlayers[seatIdx]
	local mjTilesReferPos = roomPlayer.mjTilesReferPos
	-- 显示碰杠牌
	local groupMjTilesPos = mjTilesReferPos.groupMjTilesPos
	local groupNode = cc.Node:create()
	groupNode:setPosition(mjTilesReferPos.groupStartPos)
	self.playMjLayer:addChild(groupNode)
	local mjTilesCount = 3
	if isBar then
		mjTilesCount = 4
	end
	for i = 1, mjTilesCount do
		local mjTileName = string.format("p%ds%d_%d.png", roomPlayer.displaySeatIdx, mjColor, mjNumber)
		if isBar and not isBrightBar and i <= 3 then
			-- 暗杠前三张牌扣着
			mjTileName = string.format("tdbgs_%d.png", roomPlayer.displaySeatIdx)
		end
		local mjTileSpr = cc.Sprite:createWithSpriteFrameName(mjTileName)
		mjTileSpr:setPosition(groupMjTilesPos[i])
		groupNode:addChild(mjTileSpr)
	end
	mjTilesReferPos.groupStartPos = cc.pAdd(mjTilesReferPos.groupStartPos, mjTilesReferPos.groupSpace)
	mjTilesReferPos.holdStart = cc.pAdd(mjTilesReferPos.holdStart, mjTilesReferPos.groupSpace)

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
		local filterMjTilesCount = 0
		local transMjTiles = {}
		for i, mjTile in ipairs(roomPlayer.holdMjTiles) do
			if filterMjTilesCount < mjTilesCount
				and mjTile.mjColor == mjColor and mjTile.mjNumber == mjNumber then
				mjTile.mjTileSpr:removeFromParent()
				filterMjTilesCount = filterMjTilesCount + 1
			else
				-- 保存其它牌,去除碰杠牌
				table.insert(transMjTiles, mjTile)
			end
		end
		roomPlayer.holdMjTiles = transMjTiles
		dump(transMjTiles)

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

-- start --
--------------------------------
-- @class function
-- @description 自摸碰变成明杠
-- @param seatIdx
-- @param mjColor
-- @param mjNumber
-- end --
function PlayScene:changePungToBrightBar(seatIdx, mjColor, mjNumber)
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
		local mjTileSpr = cc.Sprite:createWithSpriteFrameName(mjTileName)
		mjTileSpr:setPosition(groupMjTilesPos[4])
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
function PlayScene:showDecisionAnimation(seatIdx, decisionType)
	-- 接炮胡，自摸胡，明杠，暗杠，碰文件后缀
	local decisionSuffixs = {1, 4, 2, 2, 3}
	local decisionSfx = {"hu", "zimo", "gang", "angang", "peng"}
	-- 显示决策标识
	local roomPlayer = self.roomPlayers[seatIdx]
	-- local readySignNode = gt.seekNodeByName(self.rootNode, "Node_readySign")
	-- local readySignSpr = gt.seekNodeByName(readySignNode, "Spr_readySign_" .. roomPlayer.displaySeatIdx)
	local decisionSignSpr = cc.Sprite:createWithSpriteFrameName(string.format("decision_sign_%d.png", decisionSuffixs[decisionType]))
	decisionSignSpr:setPosition(roomPlayer.mjTilesReferPos.showMjTilePos)
	self.rootNode:addChild(decisionSignSpr, PlayScene.ZOrder.DECISION_SHOW)
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

	-- 播放全屏动画
	if decisionType == PlayScene.DecisionType.BRIGHT_BAR then
		if not self.brightBarAnimateNode then
			local brightBarAnimateNode, brightBarAnimate = gt.createCSAnimation("animation/BrightBar.csb")
			self.brightBarAnimateNode = brightBarAnimateNode
			self.brightBarAnimate = brightBarAnimate
			self.rootNode:addChild(brightBarAnimateNode, PlayScene.ZOrder.MJBAR_ANIMATION)
		end
		self.brightBarAnimate:play("run", false)
	elseif decisionType == PlayScene.DecisionType.DARK_BAR then
		if not self.darkBarAnimateNode then
			local darkBarAnimateNode, darkBarAnimate = gt.createCSAnimation("animation/DarkBar.csb")
			self.darkBarAnimateNode = darkBarAnimateNode
			self.darkBarAnimate = darkBarAnimate
			self.rootNode:addChild(darkBarAnimateNode, PlayScene.ZOrder.MJBAR_ANIMATION)
		end
		self.darkBarAnimate:play("run", false)
	end

	-- 播放音效
	if roomPlayer.sex == 1 then
		-- 男性
		gt.soundEngine:playEffect(string.format("man/%s", decisionSfx[decisionType]))
	else
		-- 女性
		gt.soundEngine:playEffect(string.format("woman/%s", decisionSfx[decisionType]))
	end
end

-- start --
--------------------------------
-- @class function
-- @description 显示出牌动画
-- @param seatIdx 座次
-- end --
function PlayScene:showMjTileAnimation(seatIdx, startPos, mjColor, mjNumber, cbFunc)
	-- local roomPlayer = self.roomPlayers[seatIdx]

	-- local mjTileRotateAngle = {-90, 180, 90, 0}
	-- local mjTileName = string.format("p4s%d_%d.png", mjColor, mjNumber)
	-- local mjTileSpr = cc.Sprite:createWithSpriteFrameName(mjTileName)
	-- self.rootNode:addChild(mjTileSpr, 98)
	-- mjTileSpr:setPosition(startPos)
	-- mjTileSpr:setRotation(mjTileRotateAngle[roomPlayer.displaySeatIdx])
	-- local moveOutAc = cc.MoveTo:create(0.5, roomPlayer.mjTilesReferPos.showMjTilePos)
	-- local rotateOutAc = cc.RotateTo:create(0.5, 0)
	-- local moveBackAc = cc.MoveTo:create(0.5, startPos)
	-- local rotateBackAc = cc.RotateTo:create(0.5, mjTileRotateAngle[roomPlayer.displaySeatIdx])
	-- mjTileSpr:runAction(cc.Sequence:create(cc.Spawn:create(moveOutAc, rotateOutAc),
	-- 										cc.Spawn:create(moveBackAc, rotateBackAc)))

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
	-- mjTileSpr:setRotation(rotateAngle[roomPlayer.displaySeatIdx])
	local moveToAc_1 = cc.MoveTo:create(totalTime, roomPlayer.mjTilesReferPos.showMjTilePos)
	--local rotateToAc_1 = cc.RotateTo:create(5.15, 0)
	local rotateToAc_1 = cc.ScaleTo:create(totalTime, 1.5)

	local delayTime = cc.DelayTime:create(0.8)

	-- local setro = cc.RotateTo:create(0.01, rotateAngle[roomPlayer.displaySeatIdx])

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

function PlayScene:reset()
	-- 玩家手势隐藏
	self:hidePlayersReadySign()

	self.playMjLayer:removeAllChildren()
end

function PlayScene:backMainSceneEvt(eventType, isRoomCreater, roomID)
	-- 事件回调
	gt.removeTargetAllEventListener(self)
	-- 消息回调
	self:unregisterAllMsgListener()

	local mainScene = require("app/views/MainScene"):create(false, isRoomCreater, roomID)
	cc.Director:getInstance():replaceScene(mainScene)
end

return PlayScene



