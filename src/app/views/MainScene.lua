
local gt = cc.exports.gt

local MainScene = class("MainScene", function()
	return cc.Scene:create()
end)

MainScene.ZOrder = {
	HISTORY_RECORD			= 5,
	CREATE_ROOM				= 6,
	JOIN_ROOM				= 7,
	PLAYER_INFO_TIPS		= 9,
}
MainScene.JOINROOMLAYER_TAG = 10
function MainScene:ctor(isNewPlayer, isRoomCreater, roomID)
	self.isNewPlayer = isNewPlayer

	-- 注册节点事件
	self:registerScriptHandler(handler(self, self.onNodeEvent))

	local csbNode = cc.CSLoader:createNode("MainScene.csb")
	csbNode:setAnchorPoint(0.5, 0.5)
	csbNode:setPosition(gt.winCenter)
	self:addChild(csbNode)
	self.rootNode = csbNode

	local playerData = gt.playerData

	if gt.isIOSPlatform() then
		self.luaBridge = require("cocos/cocos2d/luaoc")
	elseif gt.isAndroidPlatform() then
		self.luaBridge = require("cocos/cocos2d/luaj")
	end

	-- 玩家信息
	local playerInfoNode = gt.seekNodeByName(csbNode, "Node_playerInfo")
	-- 头像
	local headSpr = gt.seekNodeByName(playerInfoNode, "Spr_head")
	local t_name = string.format("%shead_img_%d.png", cc.FileUtils:getInstance():getWritablePath(), playerData.uid)

	if cc.FileUtils:getInstance():isFileExist(t_name) == true then
		headSpr:setTexture(t_name)
	else
		if playerData.sex == 1 then	--2:女 1:男
			headSpr:setTexture("sd/images/otherImages/head_m001.png")
		else
			headSpr:setTexture("sd/images/otherImages/head_m002.png")
		end

	end

	local playerHeadMgr = require("app/PlayerHeadManager"):create()
	playerHeadMgr:attach(headSpr, playerData.uid, playerData.headURL)
	self:addChild(playerHeadMgr)
	-- ID
	local playerID = gt.seekNodeByName(csbNode, "Label_ID")
	playerID:setString("ID:" .. playerData.uid)
	-- 昵称
	gt.log("=========playerData.nickname=====" .. playerData.nickname)
	local nicknameLabel = gt.seekNodeByName(playerInfoNode, "Label_nickname")
	nicknameLabel:setString(playerData.nickname)




	-- 点击头像显示信息
	local headFrameBtn = gt.seekNodeByName(playerInfoNode, "Btn_headFrame")
	gt.addBtnPressedListener(headFrameBtn, function()
		local playerInfoTips = require("app/views/PlayerInfoTips"):create(gt.playerData)
		self:addChild(playerInfoTips, MainScene.ZOrder.PLAYER_INFO_TIPS)
	end)


    local ttf_eight = gt.seekNodeByName(playerInfoNode, "Txt_numbereight")
	ttf_eight:setString(playerData.roomCardsCount[2])
	--local ttf_sixteen = gt.seekNodeByName(playerInfoNode, "Text_numbersixteen")
	--ttf_sixteen:setString(playerData.roomCardsCount[3])
	-- 房卡信息底图
	local Spr_cardBg = gt.seekNodeByName(playerInfoNode, "Spr_cardBg")
	-- 8局16局图片
	--local Spr_numbereight = gt.seekNodeByName(playerInfoNode, "Spr_numbereight")
	--local Spr_numbersixteen = gt.seekNodeByName(playerInfoNode, "Spr_numbersixteen")
	if gt.isIOSPlatform() and gt.isInReview then
		Spr_cardBg:setVisible(false)
		ttf_eight:setVisible(false)
		--ttf_sixteen:setVisible(false)
		--Spr_numbereight:setVisible(false)
		--Spr_numbersixteen:setVisible(false)
	else
		Spr_cardBg:setVisible(true)
		ttf_eight:setVisible(true)
		--ttf_sixteen:setVisible(true)
		--Spr_numbereight:setVisible(true)
		--Spr_numbersixteen:setVisible(true)
	end

	
	local spr_fangkatile = gt.seekNodeByName(csbNode, "Spr_fangkatile")
	local buyCardBtn = gt.seekNodeByName(playerInfoNode, "Btn_buyCard")
	gt.addBtnPressedListener(buyCardBtn, function()
		-- 弹出房卡购买提示
		--require("app/views/BuyCard"):create(gt.getLocationString("LTKey_0007"), gt.roomCardBuyInfo, nil, nil, true)
		gt.log("==========gt.roomCardBuyInfo====")
		dump(gt.roomCardBuyInfo)
		require("app/views/BuyCard"):create("1", gt.roomCardBuyInfo)
	end)
	if (gt.isInReview) then
		local nanchanggonggao_1 = gt.seekNodeByName(csbNode, "nanchanggonggao_1")
		nanchanggonggao_1:setVisible(false)
		buyCardBtn:setVisible(false)
		spr_fangkatile:setVisible(false)
	else
		spr_fangkatile:setVisible(true)
		buyCardBtn:setVisible(true)
	end

	
	-- 跑马灯
	local marqueeNode = gt.seekNodeByName(csbNode, "Node_marquee")
	local marqueeMsg = require("app/MarqueeMsg"):create()
	marqueeNode:addChild(marqueeMsg)
	self.marqueeMsg = marqueeMsg
	if gt.marqueeMsgTemp then
		self.marqueeMsg:showMsg(gt.marqueeMsgTemp)
		-- gt.marqueeMsgTemp = nil
	end

	-- 创建/返回房间
	local createRoomPanel = gt.seekNodeByName(csbNode, "Panel_createRoom")
	createRoomPanel:addClickEventListener(function()
		if isRoomCreater then
			-- 房主返回房间
			-- 发送进入房间消息
			gt.showLoadingTips(gt.getLocationString("LTKey_0006"))

			local msgToSend = {}
			msgToSend.m_msgId = gt.CG_JOIN_ROOM
			msgToSend.m_deskId = roomID
			gt.socketClient:sendMessage(msgToSend)
		else
			local createRoomLayer = require("app/views/CreateRoom"):create()
			self:addChild(createRoomLayer, MainScene.ZOrder.CREATE_ROOM)
		end
	end)

	
	-- 创建房间
	local createRoomSpr = gt.seekNodeByName(createRoomPanel, "Spr_createRoom")
	-- 返回房间
	local backRoomSpr = gt.seekNodeByName(createRoomPanel, "Spr_backRoom")

	if isRoomCreater then
		createRoomSpr:setVisible(false)
		backRoomSpr:setVisible(true)
	else
		createRoomSpr:setVisible(true)
		backRoomSpr:setVisible(false)
	end

	--modify by xxx
	--进入分享界面
	self.shareBtn = gt.seekNodeByName(self.rootNode, "share_wx")
    gt.addBtnPressedListener(self.shareBtn, function()
		local panel = require("app/views/QRcode"):create(playerData.uid)
		self:addChild(panel, 15)
	end)
	if gt.isInReview then
		self.shareBtn:setVisible(false)
	end
	self.shareBtn:setVisible(false)
	-- 进入房间
	local joinRoomPanel = gt.seekNodeByName(csbNode, "Panel_joinRoom")
	joinRoomPanel:addClickEventListener(function()
		local joinRoomLayer = require("app/views/JoinRoom"):create()
		self:addChild(joinRoomLayer, MainScene.ZOrder.JOIN_ROOM)
		joinRoomLayer:setTag(MainScene.JOINROOMLAYER_TAG)
	end)
	-- 进入房间
	gt.socketClient:registerMsgListener(gt.GC_ENTER_ROOM, self, self.onRcvEnterRoom)

	local btnBundleNode = gt.seekNodeByName(csbNode, "Node_btnBundle")


	-- 消息
	local messageBtn = gt.seekNodeByName(btnBundleNode, "Btn_message")
	gt.addBtnPressedListener(messageBtn, function()
		local joinRoomLayer = require("app/views/ActivityMsg"):create()
		self:addChild(joinRoomLayer, MainScene.ZOrder.JOIN_ROOM)

		-- self.msgShowSp:setVisible( false )
		cc.UserDefault:getInstance():setStringForKey("msgShowFlag", "1")
	end)


	-- 设置
	local setBtn = gt.seekNodeByName(btnBundleNode, "Btn_set")
	gt.addBtnPressedListener(setBtn, function()
		local settingPanel = require("app/views/Setting"):create("exit")
		self:addChild(settingPanel, 5)
	end)
	
	if gt.isIOSPlatform() and gt.isInReview then
		setBtn:setVisible(false)
	else
		setBtn:setVisible(true)
	end

	-- 战绩
	local historyBtn = gt.seekNodeByName(btnBundleNode, "Btn_history")
	gt.addBtnPressedListener(historyBtn, function()
		if gt.isGM == 1 then
			local checkHistory = require("app/views/GMCheckHistory"):create()
			self:addChild(checkHistory, MainScene.ZOrder.HISTORY_RECORD)
		else
			local historyRecord = require("app/views/HistoryRecord"):create()
			self:addChild(historyRecord, MainScene.ZOrder.HISTORY_RECORD)
		end
	end)
 
	-- 玩法
	local helpBtn = gt.seekNodeByName(btnBundleNode, "Btn_help")
	gt.addBtnPressedListener(helpBtn, function()
		local helpLayer = require("app/views/HelpScene"):create()
		self:addChild(helpLayer, 8)
	end)

		-- 分享
	local helpBtn = gt.seekNodeByName(btnBundleNode, "Btn_share")
	gt.addBtnPressedListener(helpBtn, function()
		-- local description = "江西人都爱玩的麻将游戏，简单好玩，随时随地组局，亲们快快加入吧！猛戳下载！"
		-- if gt.isIOSPlatform() then
		-- 	local luaoc = require("cocos/cocos2d/luaoc")
		-- 	local ok = luaoc.callStaticMethod("AppController", "shareURLToWX",
		-- 		{url = "http://www.ixianlai.com/", title = "【闲来南昌麻将】", description = description})
		-- elseif gt.isAndroidPlatform() then
		-- 	local luaj = require("cocos/cocos2d/luaj")
		-- 	local ok = luaj.callStaticMethod("org/cocos2dx/lua/AppActivity", "shareURLToWX",
		-- 		{"http://www.ixianlai.com/", "【闲来南昌麻将】", description}, 
		-- 		"(Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;)V")
		-- end
		local description = "闲来江西麻将是一款江西地方棋牌游戏！"
		local title = "【闲来江西麻将】"
		local shareSelect = require("app/views/ShareSelect"):create(description, title, gt.shareWeb)
		self:addChild(shareSelect, 8)
	end)

	if gt.isIOSPlatform() and gt.isInReview then
		helpBtn:setVisible(false)
	else
		helpBtn:setVisible(true)
	end
	

	gt.isSendActivities = false
	-- 活动按钮
	self.m_activityBtn = gt.seekNodeByName(btnBundleNode, "Btn_activity")
	if self.m_activityBtn then
		gt.addBtnPressedListener(self.m_activityBtn, function()
			if not gt.isSendActivities then
				gt.isSendActivities = true
				self:sendGetActivities()
			end
		end)
		self.m_activityBtn:setContentSize(cc.size(110, 112))
		local scaleToAction1 = cc.ScaleTo:create(0.9, 1.2)
		local scaleToAction2 = cc.DelayTime:create(0.2)
		local scaleToAction3 = cc.ScaleTo:create(0.9, 1)
		local seqAction = cc.Sequence:create(scaleToAction1, scaleToAction2, scaleToAction3)
		self.m_activityBtn:runAction(cc.RepeatForever:create(seqAction))
		if gt.m_activeID and gt.m_activeID > -1 then
			self.m_activityBtn:setVisible(true)
		else
			self.m_activityBtn:setVisible(false)
		end
	end

	
	local otherMahjong = { "fujian", "doudizhu", "paodekuai"}
	local urlSite = {"mahjongfujian", "ddz", "mahjonghnpdk"}
	--隐藏
	-- local otherMahjong = {"sichuan", "more","paohuzi"}
	table.foreach(otherMahjong, function(i, name)
		local button = gt.seekNodeByName(csbNode, "Button_" .. name)
		if button then
			if (gt.isInReview) then
				button:setVisible(false)
			else
				button:setVisible(true)
			end	
			--modify by xxx
			--需求：屏蔽按钮
			button:setVisible(false)
					
			gt.addBtnPressedListener(button, function()
				-- local url = gt.shareWeb
				local url = "http://a.app.qq.com/o/simple.jsp?pkgname=com.xianlai." .. urlSite[i]
				if gt.isIOSPlatform() then
					self.luaBridge = require("cocos/cocos2d/luaoc")
				elseif gt.isAndroidPlatform() then
					self.luaBridge = require("cocos/cocos2d/luaj")
				end
				if gt.isIOSPlatform() then
					local ok = self.luaBridge.callStaticMethod("AppController", "openWebURL",
						{webURL = url})
				elseif gt.isAndroidPlatform() then
					local ok = self.luaBridge.callStaticMethod("org/cocos2dx/lua/AppActivity", "openWebURL",
						{url}, "(Ljava/lang/String;)V")
				end
			end)
		end
	end)

	-- 实名认证
	

	self.confirmBtn = gt.seekNodeByName(btnBundleNode, "idconfirm")
    gt.addBtnPressedListener(self.confirmBtn, function()
    	if true then
			local panel = require("app/views/IDConfirm"):create()
			self:addChild(panel)
		end
	end)


    self:onConfirmID()
	-- gt.registerEventListener(gt.EventType.BACK_MAIN_SCENE, self, self.onConfirmID)

	-- 反馈
	local feedbackBtn = gt.seekNodeByName(csbNode, "feedback_btn")
	if gt.isInReview then
		feedbackBtn:setVisible(false)
	else
		feedbackBtn:setVisible(true)
	end		
 	local function okCallback()
		if gt.isIOSPlatform() then
			local okJump = self.luaBridge.callStaticMethod("AppController", "openWebURL",
				{webURL = gt.shareWeb})
		elseif gt.isAndroidPlatform() then
			local okJump = self.luaBridge.callStaticMethod("org/cocos2dx/lua/AppActivity", "openWebURL",
				{gt.shareWeb}, "(Ljava/lang/String;)V")
		end	
 	end	
	gt.addBtnPressedListener(feedbackBtn, function()
		if self:checkVersion(1, 0, 6) then
			-- 反馈代码
			if gt.isIOSPlatform() then
				local luaoc = require("cocos/cocos2d/luaoc")
				local ok, ret = luaoc.callStaticMethod("AppController", "startFeedBack")
			elseif gt.isAndroidPlatform() then
				local luaoj = require("cocos/cocos2d/luaj")
				local ok, ret = luaoj.callStaticMethod("org/cocos2dx/lua/AppActivity", "openFeedback", nil, "()V")
			end			
		else
			local appUpdateLayer = require("app/views/UpdateVersion"):create("当前版本不支持此功能,是否前往下载新版本?", 1)
	 		self:addChild(appUpdateLayer, 100)
		end

	end)	
	-- 反馈数
	self.m_feedbackBg = gt.seekNodeByName(feedbackBtn, "feedback_num_bg")
	self.m_feedbackBg:setVisible(false)
	self.m_feedbackNum = gt.seekNodeByName(csbNode, "feedback_num")
	
	-- 服务器推送活动信息
	gt.socketClient:registerMsgListener(gt.GC_LOTTERY, self, self.onRecvLotteryInfo)
	-- 服务器进入游戏自动推送是否有活动
	gt.socketClient:registerMsgListener(gt.GC_IS_ACTIVITIES, self, self.onRecvIsActivities)




	-- 注册消息回调
	gt.socketClient:registerMsgListener(gt.GC_LOGIN_SERVER, self, self.onRcvLoginServer)
	gt.socketClient:registerMsgListener(gt.GC_ROOM_CARD, self, self.onRcvRoomCard)
	gt.socketClient:registerMsgListener(gt.GC_MARQUEE, self, self.onRcvMarquee)

	gt.registerEventListener(gt.EventType.GM_CHECK_HISTORY, self, self.gmCheckHistoryEvt)
	gt.socketClient:registerMsgListener(gt.GC_GET_FANGKAACTIVITIES, self, self.openactivitymsg)


	-- 断线重连
	gt.socketClient:registerMsgListener(gt.GC_LOGIN, self, self.onRcvLogin)
end

--是否热更
function MainScene:openactivitymsg( msgTbl )
	if msgTbl.m_flag == 3 then
		self:clearLoadedFiles()
		self.NoticeTips = require("app/views/NoticeTips"):create(gt.getLocationString("LTKey_0007"),
		"您需要更新等到最新版本。",
		function()
			if gt.socketClient.scheduleHandler then
				gt.scheduler:unscheduleScriptEntry( gt.socketClient.scheduleHandler )
			end
			gt.socketClient:close()
			local loginScene = require("app/views/LogoScene"):create()
			cc.Director:getInstance():replaceScene(loginScene)
		end, nil, true)
	end
end
-- 服务器推送活动信息
function MainScene:onRecvLotteryInfo( msgTbl )
	if self.m_activityBtn then
		self.m_activityBtn:setVisible(true)
	end
	gt.lotteryInfoTab	= {}
	gt.lotteryInfoTab.m_activeID 		= msgTbl.m_activeID
	gt.lotteryInfoTab.m_RewardID  		= msgTbl.m_RewardID
	gt.lotteryInfoTab.m_LastJoinDate 	= msgTbl.m_LastJoinDate
	gt.lotteryInfoTab.m_LastGiftState 	= msgTbl.m_LastGiftState
	gt.lotteryInfoTab.m_NeedPhoneNum 	= msgTbl.m_NeedPhoneNum
	if gt.isInit == 0 then
		if gt.lotteryInfoTab.m_LastGiftState == 0 then
			local activityMotherDayLayer = require("app/views/Activities/ActivityMotherDay"):create()
			self:addChild(activityMotherDayLayer, 8)
			
		else

		end
		gt.isInit = 1
	else
		local activityMotherDayLayer = require("app/views/Activities/ActivityMotherDay"):create()
		self:addChild(activityMotherDayLayer, 8)
	end
end

-- 当有活动时,向服务器请求活动信息
function MainScene:sendGetActivities()
	if gt.lotteryInfoTab then
		local activityMotherDayLayer = require("app/views/Activities/ActivityMotherDay"):create()
		self:addChild(activityMotherDayLayer, 8)
	else
		if gt.m_activeID and gt.m_activeID ~= -1 then
			local msgToSend = {}
			msgToSend.m_msgId = gt.CG_GET_ACTIVITIES
			msgToSend.m_activeID = gt.m_activeID
			gt.socketClient:sendMessage(msgToSend)
			gt.log("#######请求信的活动信息##########")
		else
			require("app/views/NoticeTips"):create("提示", "无活动信息", nil, nil, true)
		end
	end
end

-- 进入游戏 服务器推送是否有活动
function MainScene:onRecvIsActivities(msgTbl)
	gt.m_activeID = msgTbl.m_activeID
	gt.lotteryInfoTab = nil
	-- 苹果审核 无活动
	if gt.isInReview then
		gt.m_activeID = -1
	end
	if gt.m_activeID > -1 and self.m_activityBtn then
		self.m_activityBtn:setVisible(true)
	end
end

-- 断线重连,走一次登录流程
function MainScene:reLogin()
	-- print("========重连登录1")
	-- local accessToken 	= cc.UserDefault:getInstance():getStringForKey( "WX_Access_Token" )
	-- local refreshToken 	= cc.UserDefault:getInstance():getStringForKey( "WX_Refresh_Token" )
	-- local openid 		= cc.UserDefault:getInstance():getStringForKey( "WX_OpenId" )

	-- local unionid 		= cc.UserDefault:getInstance():getStringForKey( "WX_Uuid" )
	-- local sex 			= cc.UserDefault:getInstance():getStringForKey( "WX_Sex" )
	-- local nickname 		= gt.nickname
	-- local headimgurl 	= cc.UserDefault:getInstance():getStringForKey( "WX_ImageUrl" )

	-- local loginscenes = require("app/views/LoginScene")
	-- loginscenes:getHttpServerIp(accessToken, refreshToken, openid, sex, nickname, headimgurl, unionid)	
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


function MainScene:onRcvLogin(msgTbl)
	-- print("========重连登录3")
	if msgTbl.m_errorCode == 5 then
		-- 去掉转圈
		gt.removeLoadingTips()
		require("app/views/NoticeTips"):create("提示",	"您尚未在"..msgTbl.m_errorMsg.."退出游戏，请先退出后再登陆此游戏！", nil, nil, true)
		return
	end
	-- print("========重连登录4")
	-- 去掉转圈
	gt.removeLoadingTips()

	-- 发送登录gate消息
	gt.loginSeed 		= msgTbl.m_seed
	gt.GateServer.ip 	= gt.socketClient.serverIp
	gt.GateServer.port 	= tostring(msgTbl.m_gatePort)

	gt.socketClient:close()
	-- print("===走这里,那么ip port是什么?",gt.GateServer.ip, gt.GateServer.port)
	gt.socketClient:connect(gt.GateServer.ip, gt.GateServer.port, true)
	local msgToSend = {}
	msgToSend.m_msgId = gt.CG_LOGIN_SERVER
	msgToSend.m_seed = msgTbl.m_seed
	msgToSend.m_id = msgTbl.m_id
	local catStr = tostring(gt.loginSeed)
	msgToSend.m_md5 = cc.UtilityExtension:generateMD5(catStr, string.len(catStr))
	gt.socketClient:sendMessage(msgToSend)
	-- print("========重连登录5")
end


function MainScene:onNodeEvent(eventName)
	if "enter" == eventName then
		if self.isNewPlayer then
			-- 显示新玩家奖励牌提示
			local str_des = string.format("第一次登陆送房卡%d张",gt.playerData.roomCardsCount[2])
			if gt.isIOSPlatform() and gt.isInReview then
				str_des = gt.getLocationString("LTKey_0029_1")
			end
			require("app/views/NoticeTips"):create(gt.getLocationString("LTKey_0007"),
				str_des, nil, nil, true)
		end
		--进入主界面发消息
		local msgToSend = {}
		msgToSend.m_msgId = gt.CG_GET_FANGKAACTIVITIES
		msgToSend.m_flag = 2


		gt.socketClient:sendMessage(msgToSend)
		if not gt.firstdenglu and gt.firstanchuang then
			gt.firstdenglu = true
			gt.log("---------gt.firstanchuang----------")
			-- local appUpdateLayer = require("app/views/UpdateVersion"):create("当前版本过低,是否前往下载新版本?", 1)
	 	-- 	self:addChild(appUpdateLayer, 100)
	 		-- require("app/views/NoticeTips"):create("firstdenglu",nil, nil, nil, nil)
			local str_des = "1.更新掷骰子动画的选项设置,在设置中进行选择     \n2.更新赣州冲关的上下左右翻玩法"
	 		require("app/views/NoticeTips"):create("更新通知",
				str_des, nil, nil, true)
		end
		-- 逻辑更新定时器
		if self:checkVersion(1, 0, 7) then
			self.scheduleHandler = gt.scheduler:scheduleScriptFunc(handler(self, self.update), 7, false)
		else
			gt.log("需要下新包")
		end
	elseif "exit" == eventName then
		if self:checkVersion(1, 0, 7) then
			gt.scheduler:unscheduleScriptEntry(self.scheduleHandler)
		end
	end
end

function MainScene:onRcvLoginServer(msgTbl)
	-- 去除正在返回游戏提示
	gt.removeLoadingTips()
	local child = self:getChildByTag(MainScene.JOINROOMLAYER_TAG)
	if child then
		child:reLoginJoinRoom()
	end
end

-- start --
--------------------------------
-- @class function
-- @description 进入房间消息
-- @param msgTbl 消息体
-- end --
function MainScene:onRcvEnterRoom(msgTbl)
	gt.removeLoadingTips()

	gt.socketClient:unregisterMsgListener(gt.GC_LOGIN_SERVER)
	gt.socketClient:unregisterMsgListener(gt.GC_ENTER_ROOM)
	gt.socketClient:unregisterMsgListener(gt.GC_ROOM_CARD)
	gt.socketClient:unregisterMsgListener(gt.GC_MARQUEE)
	gt.socketClient:unregisterMsgListener(gt.GC_GET_FANGKAACTIVITIES)


	


	gt.removeTargetAllEventListener(self)

	local playScene = require("app/views/PlaySceneCS"):create(msgTbl)
	cc.Director:getInstance():replaceScene(playScene)
end

-- start --
--------------------------------
-- @class function
-- @description 接收房卡信息
-- @param msgTbl 消息体
-- end --
function MainScene:onRcvRoomCard(msgTbl)
	local playerData = gt.playerData
	playerData.roomCardsCount = {msgTbl.m_card1, msgTbl.m_card2, msgTbl.m_card3}
	-- 玩家信息
	local playerInfoNode = gt.seekNodeByName(self.rootNode, "Node_playerInfo")
	-- 房卡信息
	-- local roomCardLabel = gt.seekNodeByName(playerInfoNode, "Label_cardInfo")
	-- roomCardLabel:setString(gt.getLocationString("LTKey_0004", playerData.roomCardsCount[2], playerData.roomCardsCount[3]))
	local ttf_eight = gt.seekNodeByName(playerInfoNode, "Txt_numbereight")
	ttf_eight:setString("  " .. playerData.roomCardsCount[2])
	gt.log("========6666==" .. playerData.roomCardsCount[2])
	--local ttf_sixteen = gt.seekNodeByName(playerInfoNode, "Text_numbersixteen")
	--ttf_sixteen:setString(playerData.roomCardsCount[3])

end

-- start --
--------------------------------
-- @class function
-- @description 接收跑马灯消息
-- @param msgTbl 消息体
-- end --
function MainScene:onRcvMarquee(msgTbl)
	if gt.isIOSPlatform() and gt.isInReview then
		local str_des = gt.getLocationString("LTKey_0048")
		self.marqueeMsg:showMsg(str_des)
	else
		self.marqueeMsg:showMsg(msgTbl.m_str)
		gt.marqueeMsgTemp = msgTbl.m_str
	end
end

function MainScene:gmCheckHistoryEvt(eventType, uid)
	local historyRecord = require("app/views/HistoryRecord"):create(uid)
	self:addChild(historyRecord, MainScene.ZOrder.HISTORY_RECORD)
end

function MainScene:checkVersion(_bai, _shi, _ge)
	local ok, appVersion = nil
	if gt.isIOSPlatform() then
		ok, appVersion = self.luaBridge.callStaticMethod("AppController", "getVersionName")
	elseif gt.isAndroidPlatform() then
		ok, appVersion = self.luaBridge.callStaticMethod("org/cocos2dx/lua/AppActivity", "getAppVersionName", nil, "()Ljava/lang/String;")
	end
	local versionNumber = string.split(appVersion, '.')
	if tonumber(versionNumber[1]) > _bai
		or tonumber(versionNumber[2]) > _shi
		or tonumber(versionNumber[3]) > _ge then
		gt.log("checkVersion true")
		return true
	end
	gt.log("checkVersion false")
	return false
end

function MainScene:update()
	-- 反馈条数
	local feebackNumber = 0
	if gt.isIOSPlatform() then
		local luaoc = require("cocos/cocos2d/luaoc")
		local ok, ret = luaoc.callStaticMethod("AppController", "actionUnreadCountFetch", {userId = ""})
		gt.log("IOS反馈数", ret)
		feebackNumber = ret
	elseif gt.isAndroidPlatform() then
		local luaoj = require("cocos/cocos2d/luaj")
		local ok, ret = self.luaBridge.callStaticMethod("org/cocos2dx/lua/AppActivity", "actionUnreadCountFetch", {""}, "(Ljava/lang/String;)Ljava/lang/String;")
		gt.log("反馈数", tonumber(ret))
		feebackNumber = tonumber(ret)
	end			
	if feebackNumber > 0 then
		self.m_feedbackBg:setVisible(true)
		gt.log("反馈数的类型", type(feebackNumber))
		self.m_feedbackNum:setString(feebackNumber)
	else
		self.m_feedbackBg:setVisible(false)
	end
end

function MainScene:onConfirmID()
	local show = cc.UserDefault:getInstance():getIntegerForKey("id_sure")
    self.confirmBtn:setVisible(show ~= 1)
    
    if gt.isInReview then
    	self.confirmBtn:setVisible(false)
    end
end


function MainScene:clearLoadedFiles()
	for k, v in pairs(package.loaded) do
		if string.sub(k, 1, 4) == "app/" then
			package.loaded[k] = nil
		end 
	end

	cc.SpriteFrameCache:getInstance():removeSpriteFrames()
	cc.Director:getInstance():getTextureCache():removeAllTextures()
end

return MainScene


