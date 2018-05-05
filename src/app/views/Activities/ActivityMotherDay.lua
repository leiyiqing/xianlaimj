local ActivityMotherDay = class("ActivityMotherDay", function()
	return gt.createMaskLayer()
end)

ActivityMotherDay.m_isRun = false
ActivityMotherDay.MAX_SPEED = 30
ActivityMotherDay.m_count = 12

-- local activityMotherDayLayer = require("app/views/Activities/ActivityMotherDay"):create()
-- self:addChild(activityMotherDayLayer, 8)

ActivityMotherDay.m_startSpeed = 5 -- 初始速度
ActivityMotherDay.m_aSpeed = 5 -- 帧加速度
ActivityMotherDay.m_dSpeed = 0.3 -- 减速度
ActivityMotherDay.m_maxSpeed = 40 -- 最大速度
ActivityMotherDay.m_curSpeed = 0 -- 当前速度
ActivityMotherDay.m_isStart = false -- 是否开始加速
ActivityMotherDay.m_isStop = true -- 是否停止
ActivityMotherDay.m_isCal = false -- 是否开始计算坐标
ActivityMotherDay.m_maxSpeedTime = 0 -- 最大速度持续时间
ActivityMotherDay.m_curSpeedTime = 0 -- 当前最大速度时间
ActivityMotherDay.m_result = 1
ActivityMotherDay.m_oneAngle = 360 / 12
ActivityMotherDay.m_stopAngle = 270
ActivityMotherDay.m_curAngle = 0
ActivityMotherDay.m_saveTime = 3

ActivityMotherDay.m_listName = {
	"话费10元", -- 1
	"话费20元", -- 2
	"500元京东卡", -- 3
	"房卡10张", -- 4
	"话费100元", -- 5
	"房卡1张", -- 6
	"乐视3D电视", -- 7
	"ipad pro", -- 8
	"苹果笔记本", -- 9
	"50元话费", -- 10
	"房卡15张", -- 11
	"iPhone6s", -- 12
}

ActivityMotherDay.m_huafeiList = {
	-- [1] = true,
	-- [2] = true,
	-- [5] = true,
	-- [10] = true,
}
ActivityMotherDay.m_wxhao = {
	"xianlai2345",
	"xianlai1937",
	"xianlai727",
	"majiang633",
	"xianlai633",
	"xianlai729",
	"xianlai728",

}

ActivityMotherDay.m_iconName = {
	"turntable_1.png",
	"turntable_2.png",
	"turntable_3.png", -- 500元京东卡
	"turntable_4.png",
	"turntable_5.png",
	"turntable_6.png",
	"turntable_7.png", -- 乐视3D电视
	"turntable_8.png", -- ipad pro
	"turntable_9.png", -- 苹果笔记本
	"turntable_10.png",
	"turntable_11.png", -- 房卡15张
	"turntable_12.png", -- iphone6s
}

ActivityMotherDay.m_itemIcon = {
	
}

function ActivityMotherDay:ctor()

	math.randomseed(os.time())  
	-- local csbNode = cc.CSLoader:createNode("res/ActivityMotherDay.csb")
	local csbNode, action = gt.createCSAnimation("res/ActivityMotherDay.csb")
	action:play("run", true)
	csbNode:setPosition(gt.winCenter)
	self:addChild(csbNode)
	gt.lotteryInfoTab.m_gifts = {
				{m_type = 2, m_count = 1, m_name = "话费10元", m_iconId = "turntable_1"},
				{m_type = 2, m_count = 1, m_name = "话费20元", m_iconId = "turntable_2"},
				{m_type = 1, m_count = 0, m_name = "500元京东卡", m_iconId = "turntable_3"},
				{m_type = 3, m_count = 10, m_name = "房卡10张", m_iconId = "turntable_4"},
				{m_type = 2, m_count = 1, m_name = "话费100元", m_iconId = "turntable_5"},
				{m_type = 3, m_count = 1, m_name = "房卡1张", m_iconId = "turntable_6"},
				{m_type = 1, m_count = 0, m_name = "乐视3D电视", m_iconId = "turntable_7"},
				{m_type = 1, m_count = 0, m_name = "ipad pro", m_iconId = "turntable_8"},
				{m_type = 1, m_count = 1, m_name = "苹果笔记本电脑", m_iconId = "turntable_9"},
				{m_type = 2, m_count = 1, m_name = "话费50元", m_iconId = "turntable_10"},
				{m_type = 3, m_count = 15, m_name = "房卡15张", m_iconId = "turntable_11"},
				{m_type = 1, m_count = 1, m_name = "iphone 6s手机", m_iconId = "turntable_12"},
		}
	for k,v in pairs(gt.lotteryInfoTab.m_gifts) do
		gt.log("值值", v.m_listName, v.m_iconId)
		self.m_listName[k] = v.m_name
		-- self.m_iconName[k] = v.m_iconId
		self.m_itemIcon[k] = v.m_iconId
		if v.m_type == 2 then
			self.m_huafeiList[k] = true
		end
	end


	-- 获取控件对象
	self:initControl()
	-- 将不需要的隐藏
	self:setAllVisible()
	-- -- 显示可以抽奖下标
	-- self:showJiangPinNumber()
	
	-- -- 抽奖按钮设置
	if gt.lotteryInfoTab.m_LastGiftState == 0 then
		self:showFenXiangChouJiang()
	else
		self:showNoNum()
	end
	if gt.lotteryInfoTab.m_NeedPhoneNum == 1 then
		self:showFenXiangHuaFei()
	end

	-- 开始抽奖
	gt.addBtnPressedListener(self.m_button_Start, handler(self, self.startCallback))
	-- 退出
	gt.addBtnPressedListener(self.m_button_exit, handler(self, self.exitCallback))
	-- 活动规则
	gt.addBtnPressedListener(self.m_button_explain, handler(self, self.explainCallback))
	-- 抽奖记录
	gt.addBtnPressedListener(self.m_button_record, handler(self, self.recordCallback))

	-- 分享给好友
	gt.addBtnPressedListener(self.m_button_fxghy, handler(self, self.wxFenXiangGetHaoYou))
	-- 分享领取
	gt.addBtnPressedListener(self.m_button_fxlq, handler(self, self.wxFenXiangLingQu))
	-- 关闭历史奖励
	gt.addBtnPressedListener(self.m_button_back1, handler(self, self.backCallback1))
	-- 关闭抽奖规则
	gt.addBtnPressedListener(self.m_button_back2, handler(self, self.backCallback2))
	-- 领取奖励
	gt.addBtnPressedListener(self.m_button_lqjl, handler(self, self.lingquCallback))
	-- 奖励记录分享给好友
	gt.addBtnPressedListener(self.m_button_2, handler(self, self.recordFenXiangCallback))
	
	

	gt.socketClient:registerMsgListener(gt.GC_RET_GETLOTTERY, self, self.onRecvRetGetLottery)
	gt.socketClient:registerMsgListener(gt.GC_SAVE_PHONENUM, self, self.onRecvSavePhoneNum)
	gt.socketClient:registerMsgListener(gt.GC_GET_GETLOTTERYRESULT, self, self.onRecvGetLotteryResult)
	
	gt.isSendActivities = false

	self:registerScriptHandler(handler(self, self.onNodeEvent))
end

function ActivityMotherDay:onNodeEvent(eventName)
	if "enter" == eventName then
		self.scheduleHandler = gt.scheduler:scheduleScriptFunc(handler(self, self.update), 0, false)
	elseif "exit" == eventName then
		gt.scheduler:unscheduleScriptEntry(self.scheduleHandler)

		gt.socketClient:unregisterMsgListener(gt.GC_RET_GETLOTTERY)
		gt.socketClient:unregisterMsgListener(gt.GC_SAVE_PHONENUM)
		gt.socketClient:unregisterMsgListener(gt.GC_GET_GETLOTTERYRESULT)
	end
end

function ActivityMotherDay:showJiangPinNumber()
	if gt.localVersion then
		-- self.m_sprite_roulette:setRotation(330)
		local radius = 250
		local cx = self.m_sprite_roulette:getPositionX()
		local cy = self.m_sprite_roulette:getPositionY()
		cx = cx / 1.5
		cy = cy / 1.2
		local angle = self:getAngle()
	    for i = 1, self.m_count do
	    	local label = gt.createTTFLabel(tostring(i), 28)
	    	local x = cx + radius * math.sin(angle * i)
	    	local y = cy + radius * math.cos(angle * i)
	    	label:setPosition(cc.p(x, y))
	    	label:setTextColor(cc.BLACK)
	    	label:setRotation(30 * i)
	    	self.m_sprite_roulette:addChild(label)
	    end
	end
end

-- 关闭历史奖励
function ActivityMotherDay:backCallback1()
	self.m_panel_2:setVisible(false)
end

-- 关闭活动规则
function ActivityMotherDay:backCallback2()
	self.m_panel_3:setVisible(false)
end

-- 显示历史奖励
function ActivityMotherDay:recordCallback()
	self:sendLotteryResult()
end
-- 显示活动规则
function ActivityMotherDay:explainCallback()
	self.m_panel_3:setVisible(true)
end



function ActivityMotherDay:initControl()
	-- visible
	self.m_button_Start = gt.seekNodeByName(self, "Button_Start") -- 抽奖
	self.m_sprite_arrow = gt.seekNodeByName(self, "Sprite_arrow") -- 抽奖指针
	self.m_sprite_guang = gt.seekNodeByName(self, "Sprite_guang") -- 指针光效
	self.m_node_effect = gt.seekNodeByName(self, "Node_effect") -- 光爆节点
    self.m_text_count = gt.seekNodeByName(self, "Text_count") -- 抽奖次数
    self.m_button_explain = gt.seekNodeByName(self, "Button_explain") -- 活动说明
    self.m_button_exit = gt.seekNodeByName(self, "Button_exit") -- 退出
    self.m_sprite_roulette = gt.seekNodeByName(self, "Sprite_roulette_node") -- 奖品轮盘
    self.m_button_record = gt.seekNodeByName(self, "Button_record") -- 我的奖励

    self.m_button_2 = gt.seekNodeByName(self, "Button_2") -- 历史记录分享给朋友

    self.m_listView_content = gt.seekNodeByName(self, "ListView_content") -- 历史记录容器

    -- panel2
    self.m_panel_2 = gt.seekNodeByName(self, "Panel_2") -- 历史奖励
    self.m_button_back1 = gt.seekNodeByName(self, "Button_back1")

    -- panel3
    self.m_panel_3 = gt.seekNodeByName(self, "Panel_3") -- 活动规则
    self.m_button_back2 = gt.seekNodeByName(self, "Button_back2")

    -- not visible
	self.m_text_msg = gt.seekNodeByName(self, "Text_msg1") -- 抽奖提示
	self.m_button_fxlq = gt.seekNodeByName(self, "Button_fxlq") -- 分享领取
    self.m_button_fxghy = gt.seekNodeByName(self, "Button_fxghy") -- 分享给好友
    self.m_button_lqjl = gt.seekNodeByName(self, "Button_lqjl") -- 领取奖励
    self.m_node_huode = gt.seekNodeByName(self, "Node_huode")--获奖提示容器
    self.m_text_msg2 = gt.seekNodeByName(self, "Text_msg2") -- 获奖提示
    self.m_text_4_0 = gt.seekNodeByName(self, "Text_4_0") -- 获奖提示
    self.m_text_4_0_0 = gt.seekNodeByName(self, "Text_4_0_0") -- 获奖提示
    self.m_text_4_1 = gt.seekNodeByName(self, "Text_4_1") -- 获奖提示
    
    self.m_textField_phone = gt.seekNodeByName(self, "TextField_phone") -- 手机输入
    self.m_sprite_phone_bg = gt.seekNodeByName(self, "Sprite_phone_bg") -- 手机输入背景
    self.m_text_msg3 = gt.seekNodeByName(self, "Text_msg3") -- 领取话费结束提示
    self.m_text_msg3_0 = gt.seekNodeByName(self, "Text_msg3_0") -- 领取话费结束提示
    self.m_text_msg3_1 = gt.seekNodeByName(self, "Text_msg3_1") -- 领取话费结束提示
    self.m_text_msg3_0_0 = gt.seekNodeByName(self, "Text_msg3_0_0") -- 领取话费结束提示


    for k,v in pairs(self.m_itemIcon) do
    	local itemNode = gt.seekNodeByName(self, "item_node_" .. k)
    	local itemIcon = gt.seekNodeByName(itemNode, "item_icon")
    	gt.log("icon的名称", v)
    	if v ~= "icon" then
    		itemIcon:setSpriteFrame(v .. ".png")
    	end
    end

    -- 抽奖次数
end

function ActivityMotherDay:setAllVisible()
    self.m_button_fxlq:setVisible(false)
	self.m_button_fxghy:setVisible(false)
	self.m_button_lqjl:setVisible(false)
	self.m_node_huode:setVisible(false)
	self.m_text_msg:setVisible(false)
	self.m_textField_phone:setVisible(false)
	self.m_sprite_phone_bg:setVisible(false)
	self.m_text_msg3:setVisible(false)
	self.m_text_msg3_0:setVisible(false)
	self.m_text_msg3_1:setVisible(false)
	self.m_text_msg3_0_0:setVisible(false)

	self.m_text_4_0:setVisible(false)
	self.m_text_4_0_0:setVisible(false)
	self.m_text_4_1:setVisible(false)

	self.m_sprite_guang:setVisible(false)

    self.m_panel_2:setVisible(false)
    self.m_panel_3:setVisible(false)
    self.m_button_2:setVisible(false)
end

-- 奖励记录分享给玩家
function ActivityMotherDay:recordFenXiangCallback()
	self:showFenXiangMessage("闲来南昌麻将发奖啦,iPhone,话费通通有,大家快来抢啊!!点击参与!")
end

function ActivityMotherDay:wxFenXiangLingQu()
	self.m_button_fxlq:setEnabled(false)
	local delayTime = cc.DelayTime:create(0.5)
	local function openFunc()
		self.m_button_fxlq:setEnabled(true)
	end
	local callBack = cc.CallFunc:create(openFunc)
	self.m_button_fxlq:runAction(cc.Sequence:create(delayTime,callBack))
	self:showFenXiangMessage(string.format(
		"我通过闲来南昌麻将获得了%s,百分百中奖,赶紧来拿奖吧!点击参与!",
		self.m_listName[gt.lotteryInfoTab.m_RewardID]))
	-- self:showLingQuHuaFei()
	self:sendSavePhoneNum()
end

function ActivityMotherDay:wxFenXiangGetHaoYou()
	print("wxFenXiangGetHaoYou-------")
	if gt.lotteryInfoTab.m_LastGiftState == 0 then
		self:showFenXiangMessage("闲来南昌麻将发奖啦,iPhone,话费通通有,大家快来抢啊!!点击参与!")
	else
		self:showFenXiangMessage(string.format(
			"我通过闲来南昌麻将获得了%s,百分百中奖,赶紧来拿奖吧!点击参与!",
			self.m_listName[gt.lotteryInfoTab.m_RewardID]))
	end
end

-- 领取话费卡奖励
function ActivityMotherDay:lingquCallback()
	self:sendSavePhoneNum()
end

-- 还未抽奖
function ActivityMotherDay:showFenXiangChouJiang()
	self:setAllVisible()
	self.m_text_msg:setVisible(true)
	self.m_text_msg:setString("亲,恭喜您\n获得抽奖活动资格")
	-- self.m_button_fxghy:setVisible(true)
end

-- 抽到房卡
function ActivityMotherDay:showFenXiangJieGuo()
	self:setAllVisible()
	self.m_node_huode:setVisible(true)
	self.m_text_msg2:setString(self.m_listName[gt.lotteryInfoTab.m_RewardID])
	local localName = self:getWXKF()


	self.m_text_4_0:setString(localName)
	-- self.m_button_fxghy:setVisible(true)
	self.m_text_4_0:setVisible(true)
	self.m_text_4_0_0:setVisible(true)
	self.m_text_4_1:setVisible(true)

end
--获取客服信息
function ActivityMotherDay:getWXKF()
	if not gt.activity then
		gt.activity = true
		cc.UserDefault:getInstance():setStringForKey("weixinkefu2", "")
	end
	local localName = cc.UserDefault:getInstance():getStringForKey("weixinkefu2")
	local tempNum = math.random(#self.m_wxhao)
	if localName and localName ~= "" then
	else
		localName = self.m_wxhao[tempNum]
		cc.UserDefault:getInstance():setStringForKey("weixinkefu2",localName)
	end
	return localName
end

-- 抽到话费
function ActivityMotherDay:showFenXiangHuaFei()
	self:setAllVisible()
	-- self:showLingQuHuaFeiFenXiang()
	-- 获得话费
	self.m_node_huode:setVisible(true)
	self.m_text_msg2:setString(self.m_listName[gt.lotteryInfoTab.m_RewardID])
	-- 输入手机号
	self.m_textField_phone:setVisible(true)
	self.m_sprite_phone_bg:setVisible(true)
	-- 分享领取
	self.m_button_fxlq:setVisible(true)
	
end

-- 领取话费
function ActivityMotherDay:showLingQuHuaFei()
	self:setAllVisible()
	self.m_node_huode:setVisible(true)
	self.m_textField_phone:setVisible(true)
	self.m_sprite_phone_bg:setVisible(true)
	self.m_button_lqjl:setVisible(true)
	self.m_text_msg2:setString(self.m_listName[gt.lotteryInfoTab.m_RewardID])
end

-- 领取话费分享
function ActivityMotherDay:showLingQuHuaFeiFenXiang()
	self:setAllVisible()
	-- self.m_button_fxghy:setVisible(true)
	self.m_text_msg3:setVisible(true)
	self.m_text_msg3_0:setVisible(true)
	self.m_text_msg3_1:setVisible(true)
	self.m_text_msg3_0_0:setVisible(true)
	self.m_text_msg3_0_0:setString("赠"..self.m_listName[gt.lotteryInfoTab.m_RewardID])
	local localName = self:getWXKF()
	self.m_text_msg3_0:setString(localName)
end

-- 无抽奖机会
function ActivityMotherDay:showNoNum()
	self:setAllVisible()

	local rewardId = gt.lotteryInfoTab.m_RewardID
	if rewardId then
		if self.m_huafeiList[rewardId] then -- 上次是话费
			self:showLingQuHuaFeiFenXiang()
		else
			self:showFenXiangJieGuo()
		end
	end
	self.m_text_count:setString("还有0次抽奖机会")
end

function ActivityMotherDay:showFenXiangMessage(text)
	if gt.isIOSPlatform() then
		print("gt.isIOSPlatform() = ")
		local luaoc = require("cocos/cocos2d/luaoc")
		local ok = luaoc.callStaticMethod("AppController", "shareURLToWX",
			{url = gt.shareWeb, title = "闲来南昌麻将", description = text})
	elseif gt.isAndroidPlatform() then
		print("gt.isAndroidPlatform()")
		local luaj = require("cocos/cocos2d/luaj")
		local ok = luaj.callStaticMethod("org/cocos2dx/lua/AppActivity", "shareURLToWX",
			{gt.shareWeb, "闲来南昌麻将", text},
			"(Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;)V")
	end
end

-- 服务器推送抽奖结果 96
function ActivityMotherDay:onRecvRetGetLottery(msgTbl)

	gt.log("errorCode = " .. msgTbl.m_errorCode
		.. ", data = " .. msgTbl.m_date
		.. ", rewardId = " .. msgTbl.m_RewardID
		.. ", m_NeedPhoneNum = " .. msgTbl.m_NeedPhoneNum)

	if msgTbl.m_errorCode == 0 then
		-- require("app/views/NoticeTips"):create("提示", "抽奖成功", nil, nil, true)
	elseif msgTbl.m_errorCode == 1 then
		require("app/views/NoticeTips"):create("提示", "已参与", nil, nil, true)
		gt.removeLoadingTips()
		return false
	elseif msgTbl.m_errorCode == 2 then
		require("app/views/NoticeTips"):create("提示", "活动结束", nil, nil, true)
		gt.removeLoadingTips()
		return false
	end
	gt.lotteryInfoTab.m_LastJoinDate = msgTbl.m_date
	gt.lotteryInfoTab.m_RewardID = msgTbl.m_RewardID
	gt.lotteryInfoTab.m_NeedPhoneNum = msgTbl.m_NeedPhoneNum

	gt.lotteryInfoTab.m_LastGiftState = 1

	self:start(gt.lotteryInfoTab.m_RewardID)

	gt.removeLoadingTips()
	self.m_button_Start:setEnabled(false)
end

function ActivityMotherDay:start(_result)
	self.m_curSpeed = 0
	self.m_curAngle = 0
	self.m_isStart = true
	self.m_isCal = false
	self.m_isStop = false
	self.m_curSpeedTime = 0
	self.m_saveTime = 3
	self.m_sprite_arrow:setRotation(0)
	self.m_sprite_guang:setRotation(0)
	self.m_sprite_guang:setVisible(true)
	self.m_result = _result
	gt.log("result = " .. _result)
	return true
end

function ActivityMotherDay:stop()
	self.m_curSpeed = 0
	self.m_isStop = true
	self.m_sprite_guang:setVisible(false)

	local csbNode, action = gt.createCSAnimation("zhuanpan2.csb")
	action:play("zhuanpan2", false)
	csbNode:setRotation(self.m_curAngle)
	self.m_node_effect:addChild(csbNode)

	local delayTime = cc.DelayTime:create(action:getEndFrame() / 60)
	local callFunc = cc.CallFunc:create(function(sender)
		sender:removeFromParent()
		self:wupinfeichu()
	end)
	local seqAction = cc.Sequence:create(delayTime, callFunc)
	csbNode:runAction(seqAction)

	self:showNoNum()
	if gt.lotteryInfoTab.m_NeedPhoneNum == 1 then
		self:showFenXiangHuaFei()
	end
end

function ActivityMotherDay:onTouchBegan()
	return true
end
function ActivityMotherDay:wupinfeichu()
	-- 背后蒙版, 阻止触摸
	self.m_maskLayer = cc.LayerColor:create(cc.c4b(85, 85, 85, 200), gt.winSize.width, gt.winSize.height)
	self:addChild(self.m_maskLayer)

	local function onTouchBegan()
		return true
	end
	local listener = cc.EventListenerTouchOneByOne:create()
	listener:registerScriptHandler(onTouchBegan, cc.Handler.EVENT_TOUCH_BEGAN)
	listener:setSwallowTouches(true)
	local eventDispatcher = self.m_maskLayer:getEventDispatcher()
	eventDispatcher:addEventListenerWithSceneGraphPriority(listener, self.m_maskLayer)

	-- 物品飞出前的光爆
	local wupinfeichu, action = gt.createCSAnimation("wupinfeichu.csb")
	action:play("wupinfeichu", false)
	wupinfeichu:setPosition(cc.p(display.cx, display.cy))
	self:addChild(wupinfeichu)

	local delayTime = cc.DelayTime:create(action:getEndFrame() / 60)
	local callFunc = cc.CallFunc:create(function(sender)
		sender:removeFromParent()
	end)
	local seqAction = cc.Sequence:create(delayTime, callFunc)
	wupinfeichu:runAction(seqAction)

	-- 物品飞出的物品栏
	self:setWuPin()
end

function ActivityMotherDay:setWuPin()
	local wupinfeichu2, action2 = gt.createCSAnimation("wupinfeichu2.csb")
	action2:play("wupinfeichu2", true)
	wupinfeichu2:setPosition(cc.p(display.cx, display.cy))
	self:addChild(wupinfeichu2)

	local wupinIconName = self.m_iconName[self.m_result]
	if wupinIconName ~= "" then
		cc.SpriteFrameCache:getInstance():addSpriteFrames("images/activity_icon.plist")
		local wupinIcon = cc.Sprite:createWithSpriteFrameName(wupinIconName)
		wupinfeichu2:addChild(wupinIcon)
	end

	local wupinName = self.m_listName[self.m_result]
	if wupinName then
		local Text_number = gt.seekNodeByName(wupinfeichu2, "Text_number")
		if Text_number then
			Text_number:setString(wupinName)
		end
	end

	local queding = gt.seekNodeByName(wupinfeichu2, "queding_16")
	gt.addBtnPressedListener(queding, function()
		self:removeChild(self.m_maskLayer)
		wupinfeichu2:removeFromParent()
		self.m_button_Start:setEnabled(true)
	end)
end

-- 服务器推送写入电话 98
function ActivityMotherDay:onRecvSavePhoneNum(msgTbl)
	if msgTbl.m_errorCode == 0 then
		require("app/views/NoticeTips"):create("提示", "成功", nil, nil, true)
	elseif msgTbl.m_errorCode == 1 then
		require("app/views/NoticeTips"):create("提示", "未找到记录", nil, nil, true)
	elseif msgTbl.m_errorCode == 2 then
		require("app/views/NoticeTips"):create("提示", "活动结束", nil, nil, true)
	end
	self.m_phoneNum = msgTbl.m_phoneNum
	self:showLingQuHuaFeiFenXiang()
	gt.lotteryInfoTab.m_NeedPhoneNum = 0
end

-- 服务器推送抽奖信息 100
function ActivityMotherDay:onRecvGetLotteryResult(msgTbl)
	if msgTbl.m_DrawInfo then

		self.m_listView_content:removeSelf()
		local listViewNode = cc.CSLoader:createNode("res/ActivityListView.csb")
		self.m_listView_content = gt.seekNodeByName(listViewNode, "ListView_content")
		self.m_panel_2:addChild(listViewNode)

		table.foreach(msgTbl.m_DrawInfo, function(i, v)
			local name = self.m_listName[v[1]]
			local date = string.format("%s年%s月%s日", string.sub(v[2], 1, 4), string.sub(v[2], 5, 6), string.sub(v[2], 7, 8))
			local item1 = ccui.Text:create()
			item1:setString(date)
			item1:setTextColor(cc.BLACK)
			item1:setFontSize(32)
			self.m_listView_content:addChild(item1)

			local item2 = ccui.Text:create()
			item2:setString(name)
			item2:setTextColor(cc.BLACK)
			item2:setFontSize(32)
			self.m_listView_content:addChild(item2)
		end)
	end
	self.m_panel_2:setVisible(true)
end

-- 发送请求抽奖 95
function ActivityMotherDay:sendGetLottery()
	local msgToSend = {}
	msgToSend.m_msgId = gt.CG_GET_GETLOTTERY
	gt.socketClient:sendMessage(msgToSend)

	gt.showLoadingTips("正在获取抽奖结果...")
end

-- 发送请求写入电话 97
function ActivityMotherDay:sendSavePhoneNum()
	local phoneNum = self.m_textField_phone:getString()
	if not phoneNum or not tonumber(phoneNum) then
		require("app/views/NoticeTips"):create("提示", "手机号格式错误!", nil, nil, true)
		return false
	end
	if string.len(phoneNum) ~= 11 then
		require("app/views/NoticeTips"):create("提示", "手机号长度错误!", nil, nil, true)
		return false
	end
	local msgToSend = {}
	msgToSend.m_msgId = gt.CG_SAVE_PHONENUM
	msgToSend.m_activeID = gt.lotteryInfoTab.m_activeID
	msgToSend.m_date = gt.lotteryInfoTab.m_LastJoinDate
	msgToSend.m_phoneNum = phoneNum
	gt.socketClient:sendMessage(msgToSend)
end

-- 发送请求抽奖信息 98
function ActivityMotherDay:sendLotteryResult()
	local msgToSend = {}
	msgToSend.m_msgId = gt.CG_GET_GETLOTTERYRESULT
	gt.socketClient:sendMessage(msgToSend)
end

-- 开始抽奖
function ActivityMotherDay:startCallback()
	if gt.lotteryInfoTab.m_LastGiftState > 0 then
		require("app/views/NoticeTips"):create("提示", "抽奖次数已用尽!", nil, nil, true)
	else
		self.m_isRun = true
		self:sendGetLottery()
	end
end

function ActivityMotherDay:exitCallback()
	self.m_button_fxlq:stopAllActions()
	self:removeSelf()
end

function ActivityMotherDay:getAngle()
	return 360 / self.m_count * math.pi / 180
end

function ActivityMotherDay:update(delta)
	if self.m_isStop then
		return false
	end
	if self.m_isStart then -- 开始加速
		self.m_curSpeed = self.m_curSpeed + self.m_aSpeed
		if self.m_curSpeed > self.m_maxSpeed then -- 达到最大速度
			self.m_curSpeed = self.m_maxSpeed
			self.m_curSpeedTime = self.m_curSpeedTime + delta
			if self.m_curSpeedTime > self.m_maxSpeedTime then -- 达到最大速度持续时间
				self.m_isStart = false
				if self.m_result > 6 then
					self.m_isCal = true
				end
			end
		end
	elseif self.m_isCal then
		self.m_saveTime = self.m_saveTime - 1
		if self.m_saveTime < 0 then
			self.m_isCal = false
		end
	else -- 开始减速
		if self.m_curSpeed < 3 then
			local stopRoatation = self.m_result * self.m_oneAngle
			if self.m_result == 12 then
				if self.m_curAngle > 355 or self.m_curAngle < 15 then
					self:stop()
					gt.log("奖品 : " .. self.m_listName[self.m_result])
				end
			else
				if self.m_curAngle > stopRoatation and self.m_curAngle < stopRoatation + 30 then
					self:stop()
					gt.log("奖品 : " .. self.m_listName[self.m_result])
				end
			end
		else
			self.m_curSpeed = self.m_curSpeed - self.m_dSpeed
		end
	end
	if self.m_curSpeed > 0 then
		self.m_curAngle = self.m_curAngle + self.m_curSpeed
		if self.m_curAngle > 360 then
			self.m_curAngle = 0
		end
		self.m_sprite_arrow:setRotation(self.m_curAngle)
		self.m_sprite_guang:setRotation(math.modf(self.m_curAngle / 30) * 30)
	end

	-- if not self.m_isRun then
	-- 	return false
	-- end

	-- local rouletteAngle = self.m_sprite_roulette:getRotation()
	-- rouletteAngle = rouletteAngle + self.MAX_SPEED
	-- if rouletteAngle > 360 then
	-- 	rouletteAngle = rouletteAngle - 360
	-- end
	-- self.m_sprite_roulette:setRotation(rouletteAngle)

	-- if self.m_stopIndex == 0 then
	-- 	return false
	-- end

	-- local stopAngle = 360 - (360 / self.m_count * self.m_stopIndex)

	-- if stopAngle == rouletteAngle then
	-- 	self.m_stopIndex = 0
	-- 	self.m_isRun = false
	-- 	if gt.lotteryInfoTab.m_LastGiftState == 0 then
	-- 		self.m_button_Start:setEnabled(true)
	-- 	end

	-- 	local result = self.m_listName[gt.lotteryInfoTab.m_RewardID]
	-- 	if string.find(result, "房卡") then
	-- 		self:showFenXiangJieGuo()
	-- 	elseif string.find(result, "话费") then
	-- 		self:showFenXiangHuaFei()
	-- 	end
	-- end
end

return ActivityMotherDay