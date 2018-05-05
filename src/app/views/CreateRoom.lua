
local gt = cc.exports.gt

local CreateRoom = class("CreateRoom", function()
	return gt.createMaskLayer()
end)

function CreateRoom:ctor()

	--大标签玩法个数
	self.maxtype = 5 

	local csbNode = cc.CSLoader:createNode("CreateRoom.csb")
	csbNode:setAnchorPoint(0.5, 0.5)
	csbNode:setPosition(gt.winCenter)
	self:addChild(csbNode)


	local t1 = gt.seekNodeByName(csbNode, "t1")
	local t2 = gt.seekNodeByName(csbNode, "t2")
	local m1 = gt.seekNodeByName(csbNode, "m1")
	local m2 = gt.seekNodeByName(csbNode, "m2")
	t1:setVisible(false)
	t2:setVisible(false)
	m1:setVisible(false)
	m2:setVisible(false)

	

	if gt.isShowRoot then
		t1:setVisible(true)
		t2:setVisible(true)
		m1:setVisible(true)
		m2:setVisible(true)
	end

	local spr_selectRounds = gt.seekNodeByName(self, "Spr_selectRounds")
	local node_roundType_2 = gt.seekNodeByName(self, "Node_roundType_2")
	local node_roundType_1 = gt.seekNodeByName(self, "Node_roundType_1")
	local text_2 = gt.seekNodeByName(self, "Text_2")
	local Nc_difen1 = gt.seekNodeByName(self, "Nc_difen1")
	local Nc_difen2 = gt.seekNodeByName(self, "Nc_difen2")
	local Text_43 = gt.seekNodeByName(self, "Text_43")

	if gt.isIOSPlatform() and gt.isInReview then
		spr_selectRounds:setVisible(false)
		node_roundType_1:setVisible(false)
		node_roundType_2:setVisible(false)
		text_2:setVisible(false)

		Nc_difen1:setVisible(false)
		Nc_difen2:setVisible(false)
		Text_43:setVisible(false)

		local bg = gt.seekNodeByName(self, "Image_12")
		bg:setVisible(false)
	else
		spr_selectRounds:setVisible(true)
		node_roundType_1:setVisible(true)
		node_roundType_2:setVisible(true)
		text_2:setVisible(true)
	end

		
	
	--大标签玩法选择
	--modify by xxx
	--time 2016-10-17
	--新增赣州麻将，赣州三人
	for i = 1 , self.maxtype do
		local PlayTypeChkBox = gt.seekNodeByName(self, "T_Di_tongyong_" .. i)
		PlayTypeChkBox:setTag(i)
		gt.addBtnPressedListener(PlayTypeChkBox,handler(self, self.chooseGameTypeEvt))
	end

	gt.log("开始加载3人赣州模块")
	self:initGanZhou3Ren()
	gt.log("3人赣州加载完毕")

	local Type = cc.UserDefault:getInstance():getStringForKey("majiang_playtype")
	if Type ~= "" then
		self.playType = tonumber(Type)
	else
		self.playType = 1
	end

	self:choseT_DiType(self.playType)


	--初始化番型
	local FanType = cc.UserDefault:getInstance():getStringForKey("majiang_fantype")
	if FanType ~= "" then
		self.FanType = tonumber(FanType)
	else
		self.FanType = 1
	end

	--初始化一家付或者3家付方式
	local Fu_Type = cc.UserDefault:getInstance():getStringForKey("majiang_yisan")
	if Fu_Type ~= "" then
		self.Fu_Type = tonumber(Fu_Type)
	else
		self.Fu_Type = 1
	end

	--初始化赣州一家付3家付
	local GanZhouFu_Type = cc.UserDefault:getInstance():getStringForKey("majiang_ganzhoufu")
	if GanZhouFu_Type ~= "" then
		self.GanZhouFu_Type = tonumber(GanZhouFu_Type)
	else
		self.GanZhouFu_Type = 1
	end

	--初始化赣州番型
	-- local GanFan_Type = cc.UserDefault:getInstance():getStringForKey("majiang_ganzhoufan")
	-- if GanFan_Type ~= "" then
	-- 	self.GanFan_Type = tonumber(GanFan_Type)
	-- else
		self.GanFan_Type = 1
	-- end

	--初始化霸王精
	local Bw_Type = cc.UserDefault:getInstance():getStringForKey("majiang_bawang")
	if Bw_Type ~= "" then
		self.Bw_Type = tonumber(Bw_Type)
	else
		self.Bw_Type = 1
	end

	--初始化南昌底分
	local NcDifen_Type = cc.UserDefault:getInstance():getStringForKey("nc_difen")
	if NcDifen_Type ~= "" then
		self.Nc_difen = tonumber(NcDifen_Type)
	else
		self.Nc_difen = 1
	end
	self.Nc_difen = 2


	--赣州流局加分
	local gan_liujuType = cc.UserDefault:getInstance():getStringForKey("gan_liujuType")
	if gan_liujuType ~= "" then
		self.gan_liujuType = tonumber(gan_liujuType)
	else
		self.gan_liujuType = 1
	end
	local gan_playtype = cc.UserDefault:getInstance():getStringForKey("gan_playtype")
	if gan_playtype ~= "" then
		self.gan_playtype = tonumber(gan_playtype)
	else
		self.gan_playtype = 1
	end




	-- 局数选择
	for i = 1, 2 do
		local roundTypeChkBox = gt.seekNodeByName(self, "ChkBox_roundType_" .. i)
		roundTypeChkBox:setTag(i)
		roundTypeChkBox:addEventListener(handler(self, self.chooseRoundTypeEvt))
		self:addTouchForLabel("Label_round_", i, "ChkBox_roundType_", handler(self, self.chooseRoundTypeEvt))
	end
	self.roundType = 1
	self:SetRoundTypeColor(self.roundType,true)


	--[[
		modify by xxx
		time 2016-10-17
		descriptioin
		赣州玩法
			选择8番起步，平胡屁打
			选择轮庄制，抢庄制
	--]]
	--一家付，3家付，赣州
	for i = 1, 2 do
		local roundTypeChkBox = gt.seekNodeByName(self, "ganzhou_ChkBox_Gan_type" .. i)
		roundTypeChkBox:setTag(i)
		roundTypeChkBox:addEventListener(handler(self, self.chooseGanZhouFuTypeEvt))
		self:addTouchForLabel("ganzhou_Label_Gan_Type", i, "ganzhou_ChkBox_Gan_type", handler(self, self.chooseGanZhouFuTypeEvt))
		if i == self.GanZhouFu_Type then
			self:SetPlayTypeColor(i,true,"ganzhou_Label_Gan_Type")
			roundTypeChkBox:setSelected(true)
		else
			self:SetPlayTypeColor(i,false,"ganzhou_Label_Gan_Type")
			roundTypeChkBox:setSelected(false)
		end
	end


	--赣州流局+5

	local roundTypeChkBox = gt.seekNodeByName(self, "ganzhou_ChkBox_liuju_type1")
	roundTypeChkBox:addEventListener(handler(self, self.chooseGanZhouLiujuTypeEvt))
	self:addTouchForLabel("ganzhou_Label_liuju_Type", 1, "ganzhou_ChkBox_liuju_type", handler(self, self.chooseGanZhouLiujuTypeEvt),true)
	if 1 == self.gan_liujuType then
		self:SetPlayTypeColor(1,true,"ganzhou_Label_liuju_Type")
		roundTypeChkBox:setSelected(true)
	else
		self:SetPlayTypeColor(1,false,"ganzhou_Label_liuju_Type")
		roundTypeChkBox:setSelected(false)
	end



	--南昌底分
	for i = 1, 2 do
		local roundTypeChkBox = gt.seekNodeByName(self, "ChkBox_Nc_type" .. i)
		roundTypeChkBox:setTag(i)
		roundTypeChkBox:addEventListener(handler(self, self.chooseNcDifenTypeEvt))
		-- self:addTouchForLabel("Label_Nc_Type", i, "ChkBox_Nc_type", handler(self, self.chooseNcDifenTypeEvt))
		if i == self.Nc_difen then
			self:SetPlayTypeColor(i,true,"Label_Nc_Type")
			roundTypeChkBox:setSelected(true)
		else
			self:SetPlayTypeColor(i,false,"Label_Nc_Type")
			roundTypeChkBox:setSelected(false)
		end
		if i == 1 then
			roundTypeChkBox:setEnabled(false)
			local label = gt.seekNodeByName(self, "Label_Nc_Type1")
			label:setTextColor(cc.c4b(85,85,85,255))
		end

	end



	--番型，赣州
	for i = 1, 2 do
		local roundChkBox = gt.seekNodeByName(self, "ganzhou_ChkBox_Fan_type"..i)
		roundChkBox:setTag(i)
		roundChkBox:addEventListener(handler(self, self.chooseGanZhouFanTypeEvt))
		if i == self.GanFan_Type then
			self:SetPlayTypeColor(i,true,"ganzhou_Label_Fan_Type")
			roundChkBox:setSelected(true)
		else
			self:SetPlayTypeColor(i,false,"ganzhou_Label_Fan_Type")
			roundChkBox:setSelected(false)
		end
		if i == 2 then
			roundChkBox:setEnabled(false)
			local label = gt.seekNodeByName(self, "ganzhou_Label_Fan_Type2")
			label:setTextColor(cc.c4b(85,85,85,255))
		else
			self:addTouchForLabel("ganzhou_Label_Fan_Type", i, "ganzhou_ChkBox_Fan_type", handler(self, self.chooseGanZhouFanTypeEvt))
		end
	end


	--上下翻，上下左右翻，赣州
	for i = 1, 2 do
		--上下左右翻，暂时不可用
		local roundChkBox = gt.seekNodeByName(self, "ganzhou_ChkBox_FanJing_type"..i)
		roundChkBox:setTag(i)
		self:SetPlayTypeColor(i,true,"ganzhou_Label_FanJing_Type")
		roundChkBox:addEventListener(handler(self, self.chooseGanZhouJingTypeEvt))
		self:addTouchForLabel("ganzhou_Label_FanJing_Type", i, "ganzhou_ChkBox_FanJing_type", handler(self, self.chooseGanZhouJingTypeEvt))
		if i == self.gan_playtype then
			self:SetPlayTypeColor(i,true,"ganzhou_Label_FanJing_Type")
			roundChkBox:setSelected(true)
		else
			self:SetPlayTypeColor(i,false,"ganzhou_Label_FanJing_Type")
			roundChkBox:setSelected(false)
		end
	end

	--空中拦截无空中拦截
	for i = 1, 2 do
		local roundTypeChkBox = gt.seekNodeByName(self, "fuzhou_ChkBox_Fu_type" .. i)
		roundTypeChkBox:setTag(i)
		roundTypeChkBox:addEventListener(handler(self, self.chooseKongzhongTypeEvt))
	end

	local Type = cc.UserDefault:getInstance():getStringForKey("majiang_kongzhong")
	if Type ~= "" then
		self.Kongzhong = tonumber(Type)
	else
		self.Kongzhong = 1
	end

	for i = 1, 2 do
		local roundTypeChkBox = gt.seekNodeByName(self, "fuzhou_ChkBox_Fu_type" .. i)
		if i == self.Kongzhong then
			roundTypeChkBox:setSelected(true)
			self:SetPlayTypeColor(i,true,"fuzhou_Label_Fu_Type")
		else
			roundTypeChkBox:setSelected(false)
			self:SetPlayTypeColor(i,false,"fuzhou_Label_Fu_Type")
		end
	end


	--选择几番
	for i = 1, 2 do
		local roundTypeChkBox = gt.seekNodeByName(self, "fuzhou_ChkBox_Fan_type" .. i)
		roundTypeChkBox:setTag(i)
		roundTypeChkBox:addEventListener(handler(self, self.chooseFanTypeEvt))
		self:addTouchForLabel("fuzhou_Label_Fan_Type", i, "fuzhou_ChkBox_Fan_type", handler(self, self.chooseFanTypeEvt))
	end
	
	for i = 1, 2 do
		local roundTypeChkBox = gt.seekNodeByName(self, "fuzhou_ChkBox_Fan_type" .. i)
		if i == self.FanType then
			roundTypeChkBox:setSelected(true)
			self:SetPlayTypeColor(i,true,"fuzhou_Label_Fan_Type")
		else
			roundTypeChkBox:setSelected(false)
			self:SetPlayTypeColor(i,false,"fuzhou_Label_Fan_Type")
		end
	end


	--萍乡选择底分
	for i = 1, 3 do
		local roundTypeChkBox = gt.seekNodeByName(self, "px_ChkBox_Di_type" .. i)
		roundTypeChkBox:setTag(i)
		roundTypeChkBox:addEventListener(handler(self, self.chooseDiTypeEvt))
	end

	local DiType = cc.UserDefault:getInstance():getStringForKey("majiang_pxdi")
	if DiType ~= "" then
		self.DiType = tonumber(DiType)
	else
		self.DiType = 1
	end

	for i = 1, 3 do
		local roundTypeChkBox = gt.seekNodeByName(self, "px_ChkBox_Di_type" .. i)
		if i == self.DiType then
			roundTypeChkBox:setSelected(true)
			self:SetPlayTypeColor(i,true,"px_Label_Di_Type")
		else
			roundTypeChkBox:setSelected(false)
			self:SetPlayTypeColor(i,false,"px_Label_Di_Type")
		end
	end



	--点炮一家三家
	for i = 1, 2 do
		local roundTypeChkBox = gt.seekNodeByName(self, "ChkBox_Fu_type" .. i)
		roundTypeChkBox:setTag(i)
		roundTypeChkBox:addEventListener(handler(self, self.chooseFuTypeEvt))
		self:addTouchForLabel("Label_Fu_Type", i, "ChkBox_Fu_type", handler(self, self.chooseFuTypeEvt))
		roundTypeChkBox:setSelected(false)
	end

	
	self:SetPlayTypeColor(self.Fu_Type,true,"Label_Fu_Type")
	local playTypeChkBox = gt.seekNodeByName(self, "ChkBox_Fu_type" .. self.Fu_Type)
	playTypeChkBox:setSelected(true)



	--霸王
	for i = 1, 2 do
		local roundTypeChkBox = gt.seekNodeByName(self, "ChkBox_bw_type" .. i)
		roundTypeChkBox:setTag(i)
		roundTypeChkBox:addEventListener(handler(self, self.chooseBwTypeEvt))
		self:addTouchForLabel("Label_bw_Type", i, "ChkBox_bw_type", handler(self, self.chooseBwTypeEvt))
		roundTypeChkBox:setSelected(false)
	end
	
	local Bw_Type = cc.UserDefault:getInstance():getStringForKey("majiang_bawang")
	if Bw_Type ~= "" then
		self.Bw_Type = tonumber(Bw_Type)
	else
		self.Bw_Type = 1
	end

	self:SetPlayTypeColor(self.Bw_Type,true,"Label_bw_Type")
	local playTypeChkBox = gt.seekNodeByName(self, "ChkBox_bw_type" .. self.Bw_Type)
	playTypeChkBox:setSelected(true)




	--算精
	for i = 1, 2 do
		local roundTypeChkBox = gt.seekNodeByName(self, "ChkBox_jing_type" .. i)
		roundTypeChkBox:setTag(i)
		roundTypeChkBox:addEventListener(handler(self, self.chooseJingTypeEvt))
		self:addTouchForLabel("Label_jing_Type", i, "ChkBox_jing_type", handler(self, self.chooseJingTypeEvt))
		roundTypeChkBox:setSelected(false)
	end
	local Jing_Type = cc.UserDefault:getInstance():getStringForKey("majiang_jing")
	if Jing_Type ~= "" then
		self.Jing_Type = tonumber(Jing_Type)
	else
		self.Jing_Type = 1
	end

	self:SetPlayTypeColor(self.Jing_Type,true,"Label_jing_Type")
	local playTypeChkBox = gt.seekNodeByName(self, "ChkBox_jing_type" .. self.Jing_Type)
	playTypeChkBox:setSelected(true)


	-- 南昌玩法点炮类型
	for i = 1, 5 do
		local playTypeChkBox = gt.seekNodeByName(self, "ChkBox_playType_" .. i)
		self.playTypeChkBox = playTypeChkBox
		playTypeChkBox:setTag(i)
		playTypeChkBox:addEventListener(handler(self, self.choosePlayTypeEvt))
		self:addTouchForLabel("Label_playType_", i, "ChkBox_playType_", handler(self, self.choosePlayTypeEvt))

		-- local function touchilabel(senderBtn, eventType)
		-- 	gt.log("##########====" .. eventType)
		-- end

		-- local Label_playType = gt.seekNodeByName(self, "Label_playType_" .. i)
		-- Label_playType:setTouchEnabled(true)
		-- Label_playType:addEventListener(touchilabel)


		-- if i == 4 then
		-- 	playTypeChkBox:setTouchEnabled(false)
		-- 	local Label_roundChild = gt.seekNodeByName(self, "Label_playType_4")
		-- 	Label_roundChild:setTextColor(cc.c4b(96,96,96,255))
		-- end
	end
	
	-- 默认是可抢杠胡玩法（埋地雷）
	self.majiang_type = cc.UserDefault:getInstance():getStringForKey("majiang_type")
	
	if self.majiang_type ~= "" then
		self.prePlayType = tonumber(self.majiang_type)
	else
		self.prePlayType = 2
	end
	self:SetPlayTypeColor(self.prePlayType,true,"Label_playType_")

	local playTypeChkBox = gt.seekNodeByName(self, "ChkBox_playType_" .. self.prePlayType)
	playTypeChkBox:setSelected(true)


	for i = 1 , 5 do
		if i ~= self.prePlayType then
			local playTypeChkBox = gt.seekNodeByName(self, "ChkBox_playType_"..i)
			playTypeChkBox:setSelected(false)
			-- self:addTouchForLabel("Label_playType_", i, "ChkBox_playType_")
		end
	end
	local fuzhou_playtype_2 = gt.seekNodeByName(self, "fuzhou_playtype_2")
	fuzhou_playtype_2:setVisible(false)
	
	
	local createBtn = gt.seekNodeByName(self, "Btn_create")
	gt.addBtnPressedListener(createBtn, function()
		--保存选择麻将类型
		cc.UserDefault:getInstance():setStringForKey("majiang_type", self.prePlayType)
		cc.UserDefault:getInstance():setStringForKey("majiang_playtype", self.playType)
		cc.UserDefault:getInstance():setStringForKey("majiang_kongzhong", self.Kongzhong)
		cc.UserDefault:getInstance():setStringForKey("majiang_fantype", self.FanType)
		cc.UserDefault:getInstance():setStringForKey("majiang_pxdi", self.DiType)
		cc.UserDefault:getInstance():setStringForKey("majiang_yisan", self.Fu_Type)
		cc.UserDefault:getInstance():setStringForKey("majiang_bawang", self.Bw_Type)
		cc.UserDefault:getInstance():setStringForKey("majiang_jing", self.Jing_Type)
		cc.UserDefault:getInstance():setStringForKey("majiang_ganzhoufan", self.GanFan_Type)
		cc.UserDefault:getInstance():setStringForKey("majiang_ganzhoufu", self.GanZhouFu_Type)
		cc.UserDefault:getInstance():setStringForKey("nc_difen", self.Nc_difen)
		cc.UserDefault:getInstance():setStringForKey("nc_zxtype", self.Nc_zxtype)
		cc.UserDefault:getInstance():setStringForKey("nc_zjtype", self.Nc_zjtype)
		cc.UserDefault:getInstance():setStringForKey("gan_playtype", self.gan_playtype)
		cc.UserDefault:getInstance():setStringForKey("gan_liujuType", self.gan_liujuType)
		cc.UserDefault:getInstance():setStringForKey("ganzhou3ren_bawang", self.ganzhou3ren_bawangType)
		cc.UserDefault:getInstance():setStringForKey("ganzhou3ren_fanjing", self.ganzhou3renFanjingType)

		local roundType = 2
		if self.roundType == 1 then --局数选择
			roundType = 2
		else
			roundType = 3
		end
		-- 发送创建房间消息
		local msgToSend = {}
		msgToSend.m_msgId = gt.CG_CREATE_ROOM
		msgToSend.m_flag = roundType
		msgToSend.m_secret = "123456"
		gt.log("=========self.prePlayType====22==" .. self.prePlayType)
		msgToSend.m_ncPlayType = self.prePlayType         --玩法选择
		msgToSend.m_gold = 1
		msgToSend.m_state = self.playType
		msgToSend.m_dianPao = self.Fu_Type
		
		if self.playType == 4 then
			msgToSend.m_dianPao = self.GanZhouFu_Type
			msgToSend.m_ncPlayType = self.gan_playtype
			msgToSend.m_zhuangAddFive = self.gan_liujuType
		end

		msgToSend.m_anGangFanShu = self.FanType
		msgToSend.m_kongZhongLanJie = self.Kongzhong
		msgToSend.m_pxDi = self.DiType
		msgToSend.m_baWang = self.Bw_Type
		msgToSend.m_outCardJing = self.Jing_Type
		msgToSend.m_fanShu = self.GanFan_Type

		msgToSend.m_ncDi = self.Nc_difen
		
		if self.playType == 5 then
			-- msgToSend.m_dianPao = self.GanZhouFu_Type
			msgToSend.m_ncPlayType = self.ganzhou3renFanjingType
			msgToSend.m_hasBWJ = self.ganzhou3ren_bawangType
			msgToSend.m_zhuangAddFive = self.ganzhou3ren_zhuangjia5
			gt.log("hahahahaha-----m_zhuangAddFive->" .. self.ganzhou3ren_zhuangjia5)
		end
		if gt.isIOSPlatform() and gt.isInReview then
			msgToSend.m_robotNum = 3
		end
		--添加掷骰子的参数
		msgToSend.m_IsShowShaiZi = tonumber(cc.UserDefault:getInstance():getStringForKey("show_dice1") or 2)
		if gt.isShowRoot then
			local senTab = {}
			local cardNum = t1:getStringValue()
			if string.len(cardNum) ~= 0 then
				local subStrs = string.split(cardNum, ",")

				for i,v in ipairs(subStrs) do
					local carTab = {}
					carTab[1] = math.floor(tonumber(v)/10)
					carTab[2] = tonumber(v)%10
					senTab[#senTab+1] = carTab
				end
			end
			dump(senTab)
			gt.log("======44==")
			self.m_robotNum = t2:getStringValue()

			msgToSend.m_robotNum = tonumber(self.m_robotNum)
			msgToSend.m_cardValue = senTab
		end
		gt.socketClient:sendMessage(msgToSend)
		-- 等待提示
		gt.showLoadingTips(gt.getLocationString("LTKey_0005"))
	end)

	-- 接收创建房间消息
	gt.socketClient:registerMsgListener(gt.GC_CREATE_ROOM, self, self.onRcvCreateRoom)

	-- 返回按键
	local backBtn = gt.seekNodeByName(self, "Btn_back")
	gt.addBtnPressedListener(backBtn, function()
		self:removeFromParent()
	end)
end

--赣州三人，玩法初始化,有无霸王精,二选一
--初始化玩法.庄家＋5，抄庄，可抢杠胡，打精冲关1包3。可同时选择
--上下翻精，上下左右翻，上下左左右右翻精。三选一
function CreateRoom:initGanZhou3Ren()
	--初始化  有无霸王精
	local ganzhou3ren_bawang = cc.UserDefault:getInstance():getStringForKey("ganzhou3ren_bawang")
	if ganzhou3ren_bawang ~= "" then
		self.ganzhou3ren_bawangType = tonumber(ganzhou3ren_bawang)
	else
		self.ganzhou3ren_bawangType = 1
	end

	for i = 1, 2 do
		local tempBawang = gt.seekNodeByName(self, "ganzhou3ren_ChkBox_Gan_type" .. i)
		tempBawang:setTag(i)
		tempBawang:addEventListener(handler(self, self.chooseGanzhou3RenBawangEvt))
		self:addTouchForLabel("ganzhou3ren_Label_Gan_Type", i, "ganzhou3ren_ChkBox_Gan_type", handler(self, self.chooseGanzhou3RenBawangEvt))
		if self.ganzhou3ren_bawangType == i then
			tempBawang:setSelected(true)
			self:SetPlayTypeColor(i,true,"ganzhou3ren_Label_Gan_Type")
		else
			tempBawang:setSelected(false)
			self:SetPlayTypeColor(i,false,"ganzhou3ren_Label_Gan_Type")
		end
	end

	--初始化 流局庄＋5
	self:addEvtForOneCheckBox("ganzhou3ren_zhuangjia5", "ganzhou3ren_zhaungjia5", "ganzhou3ren_Label_liuju_Type", "ganzhou3ren_ChkBox_liuju_type", 1)
	--初始化 抄庄
	self:addEvtForOneCheckBox("ganzhou3renChaoZhuang", "ganzhou3ren_chaozhuang", "ganzhou3ren_Label_liuju_Type", "ganzhou3ren_ChkBox_liuju_type", 2)
	--初始化 抢杠胡
	self:addEvtForOneCheckBox("ganzhou3renQiangGang", "ganzhou3ren_qiangganghu", "ganzhou3ren_Label_qiang13_", "ganzhou3ren_ChkBox_qiang13_", 1)
	--初始化打精冲关1包3
	self:addEvtForOneCheckBox("ganzhou3renChongGuan13", "ganzhou3ren_chongguan1bao3", "ganzhou3ren_Label_qiang13_", "ganzhou3ren_ChkBox_qiang13_", 2)	

	--初始化 玩法 上下翻精 上下左右翻精 上下左左右右翻精
	local ganzhou3ren_fanjing = cc.UserDefault:getInstance():getStringForKey("ganzhou3ren_fanjing")
	if ganzhou3ren_fanjing ~= "" then
		self.ganzhou3renFanjingType = tonumber(ganzhou3ren_fanjing)
	else
		self.ganzhou3renFanjingType = 1
	end

	for i = 1, 3 do
		local tempBawang = gt.seekNodeByName(self, "ganzhou3ren_ChkBox_FanJing_type" .. i)
		tempBawang:setTag(i)
		tempBawang:addEventListener(handler(self, self.chooseGanzhou3RenFanjingEvt))
		self:addTouchForLabel("ganzhou3ren_Label_FanJing_Type", i, "ganzhou3ren_ChkBox_FanJing_type", handler(self, self.chooseGanzhou3RenFanjingEvt))
		if self.ganzhou3renFanjingType == i then
			tempBawang:setSelected(true)
			self:SetPlayTypeColor(i,true,"ganzhou3ren_Label_FanJing_Type")
		else
			tempBawang:setSelected(false)
			self:SetPlayTypeColor(i,false,"ganzhou3ren_Label_FanJing_Type")
		end
	end

	--屏蔽一堆玩法
	self:unEnableCheckBox("ganzhou3ren_Label_qiang13_1", "ganzhou3ren_ChkBox_qiang13_1")
	self:unEnableCheckBox("ganzhou3ren_Label_liuju_Type2", "ganzhou3ren_ChkBox_liuju_type2")
	self:unEnableCheckBox("ganzhou3ren_Label_qiang13_2", "ganzhou3ren_ChkBox_qiang13_2")
	self:unEnableCheckBox("ganzhou3ren_Label_FanJing_Type3", "ganzhou3ren_ChkBox_FanJing_type3")
end

--用来屏蔽checkbox
function CreateRoom:unEnableCheckBox(labelName, checkBoxName)
	local tempLabel = gt.seekNodeByName(self, labelName)
	local roundChkBox = gt.seekNodeByName(self, checkBoxName)
	roundChkBox:setSelected(false)
	roundChkBox:setEnabled(false)
	tempLabel:getParent():getChildByTag(123):removeFromParent()
	tempLabel:removeAllChildren()
	tempLabel:setTextColor(cc.c4b(85,85,85,255))
end

--针对单个的checkbox的绑定封装
--包含初始化
--参数的含义    全局的名字  存储的名字  csb中的label  checkbox的名字  index值
function CreateRoom:addEvtForOneCheckBox(MaxName, localName, labelName, checkBoxName, index)
	gt.log("初始化------" .. localName)
	--初始化  全局变量
	local ganzhou3ren_zhuangjia5 = cc.UserDefault:getInstance():getStringForKey(localName)
	if ganzhou3ren_zhuangjia5 ~= "" then
		self[MaxName] = tonumber(ganzhou3ren_zhuangjia5)
	else
		self[MaxName] = 1
	end

	local function jia5callback (senderBtn, eventType)
		if eventType == ccui.CheckBoxEventType.selected then
			self[MaxName] = 1
			senderBtn:setSelected(true)
			self:SetPlayTypeColor(index, true, labelName)
			gt.log("选择了赣州3人流局+5，self.ganzhou3ren_bawangType = 1")
		elseif eventType == ccui.CheckBoxEventType.unselected then
			self[MaxName] = 2
			senderBtn:setSelected(false)
			self:SetPlayTypeColor(index, false, labelName)
			gt.log("没有选择了赣州3人流局+5，self.ganzhou3ren_bawangType = 0")
		end
	end
	
	local tempZhuangjia5 = gt.seekNodeByName(self, checkBoxName .. index)
	tempZhuangjia5:addEventListener(jia5callback)
	self:addTouchForLabel(labelName, index, checkBoxName, jia5callback)
	if self[MaxName] == 1 then
		tempZhuangjia5:setSelected(true)
		self:SetPlayTypeColor(index, true, labelName)
	else
		tempZhuangjia5:setSelected(false)
		self:SetPlayTypeColor(index, false, labelName)
	end
	gt.log("初始化------" .. localName .. "完成")
end

--modify by xxx
--time 2016-10-14
--description 给checkbox边上的label上加一个btn点击label相当于点击checkbox
function CreateRoom:addTouchForLabel(labelName, index, checkBoxName, callBack, isfuxuan)
	local label = gt.seekNodeByName(self, labelName..index)
	local btn = ccui.Button:create()
	btn:setTouchEnabled(true)
	btn:setScale9Enabled(true)
	btn:setOpacity(0)
    btn:loadTextures("res/sd/images/otherImages/yuyin.png", "res/sd/images/otherImages/yuyin.png", "")
	label:getParent():addChild(btn)
	btn:setTag(123)
	btn:setContentSize(label:getContentSize())
	btn:setAnchorPoint(label:getAnchorPoint())
	btn:setPosition(label:getPositionX(), label:getPositionY())
	gt.addBtnPressedListener(btn,function()
		local checkbox = gt.seekNodeByName(self, checkBoxName..index)
		if not checkbox:isSelected() then
			callBack(checkbox, ccui.CheckBoxEventType.selected)
			checkbox:setSelected(true)
		else
			callBack(checkbox, ccui.CheckBoxEventType.unselected)
			if isfuxuan then
				checkbox:setSelected(false)
			end
		end
	end)
end

--点炮一家三家
--赣州麻将
function CreateRoom:chooseGanZhouFuTypeEvt(senderBtn, eventType)
	gt.log('----xxx----chooseGanZhouFuTypeEvt0' .. self.GanZhouFu_Type)
	if eventType == ccui.CheckBoxEventType.selected then
		local btnTag = senderBtn:getTag()
			if self.GanZhouFu_Type ~= btnTag then
				-- 恢复上一个玩法未选中状态
				local roundChkBox = gt.seekNodeByName(self, "ganzhou_ChkBox_Gan_type" .. self.GanZhouFu_Type)
				self:SetPlayTypeColor(self.GanZhouFu_Type,false,"ganzhou_Label_Gan_Type")
				roundChkBox:setSelected(false)
				self.GanZhouFu_Type = btnTag
				self:SetPlayTypeColor(self.GanZhouFu_Type,true,"ganzhou_Label_Gan_Type")
			end
	elseif eventType == ccui.CheckBoxEventType.unselected then
		senderBtn:setSelected(true)
	end
end

--赣州3人玩法，霸王精回调函数
function CreateRoom:chooseGanzhou3RenBawangEvt(senderBtn, eventType)
	gt.log("onClick霸王精----senderBtn.tag = " .. senderBtn:getTag())
	if eventType == ccui.CheckBoxEventType.selected then
		local btnTag = senderBtn:getTag()
			if self.ganzhou3ren_bawangType ~= btnTag then
				-- 恢复上一个玩法未选中状态
				local roundChkBox = gt.seekNodeByName(self, "ganzhou3ren_ChkBox_Gan_type" .. self.ganzhou3ren_bawangType)
				self:SetPlayTypeColor(self.ganzhou3ren_bawangType,false,"ganzhou3ren_Label_Gan_Type")
				roundChkBox:setSelected(false)
				self.ganzhou3ren_bawangType = btnTag
				self:SetPlayTypeColor(self.ganzhou3ren_bawangType,true,"ganzhou3ren_Label_Gan_Type")
			end
	elseif eventType == ccui.CheckBoxEventType.unselected then
		senderBtn:setSelected(true)
		-- self:SetPlayTypeColor(senderBtn:getTag(),true,"ganzhou3ren_Label_Gan_Type")
	end
end

--赣州3人玩法，上下左右翻精，上下翻精，上下左左右右翻精
function CreateRoom:chooseGanzhou3RenFanjingEvt(senderBtn, eventType)
	if eventType == ccui.CheckBoxEventType.selected then
		gt.log("name: = " .. senderBtn:getName() .. " selected"..senderBtn:getTag())
		local btnTag = senderBtn:getTag()
		--if btnTag == 1 or btnTag == 2 then
			-- 自摸胡和可抢杠胡玩法互斥
			if self.ganzhou3renFanjingType ~= btnTag then
				-- 恢复上一个玩法未选中状态
				local playTypeChkBox = gt.seekNodeByName(self, "ganzhou3ren_ChkBox_FanJing_type" .. self.ganzhou3renFanjingType)
				playTypeChkBox:setSelected(false)
				self:SetPlayTypeColor(self.ganzhou3renFanjingType, false, "ganzhou3ren_Label_FanJing_Type")
				self.ganzhou3renFanjingType = btnTag
				self:SetPlayTypeColor(self.ganzhou3renFanjingType, true, "ganzhou3ren_Label_FanJing_Type")
			end
		--end
	elseif eventType == ccui.CheckBoxEventType.unselected then
		local playTypeChkBox = gt.seekNodeByName(self, "ganzhou3ren_ChkBox_FanJing_type" .. self.ganzhou3renFanjingType)
		playTypeChkBox:setSelected(true)
	end
end

--赣州流局+5
function CreateRoom:chooseGanZhouLiujuTypeEvt(senderBtn, eventType)
	if eventType == ccui.CheckBoxEventType.selected then
		self.gan_liujuType = 1
		self:SetPlayTypeColor(1,true,"ganzhou_Label_liuju_Type")
	elseif eventType == ccui.CheckBoxEventType.unselected then
		self.gan_liujuType = 2 
		self:SetPlayTypeColor(1,false,"ganzhou_Label_liuju_Type")
	end
end

function CreateRoom:chooseNcDifenTypeEvt(senderBtn, eventType)
	if eventType == ccui.CheckBoxEventType.selected then
		local btnTag = senderBtn:getTag()
			if self.Nc_difen ~= btnTag then
				-- 恢复上一个玩法未选中状态
				local roundChkBox = gt.seekNodeByName(self, "ChkBox_Nc_type" .. self.Nc_difen)
				self:SetPlayTypeColor(self.Nc_difen,false,"Label_Nc_Type")
				roundChkBox:setSelected(false)
				self.Nc_difen = btnTag
				self:SetPlayTypeColor(self.Nc_difen,true,"Label_Nc_Type")
			end
	elseif eventType == ccui.CheckBoxEventType.unselected then
		senderBtn:setSelected(true)
	end
end

--番型选择，8番起步  8，平番屁胡  4
--赣州麻将
function CreateRoom:chooseGanZhouFanTypeEvt(senderBtn, eventType)
	if eventType == ccui.CheckBoxEventType.selected then
		local btnTag = senderBtn:getTag()
			if self.GanFan_Type ~= btnTag then
				-- 恢复上一个玩法未选中状态
				local roundChkBox = gt.seekNodeByName(self, "ganzhou_ChkBox_Fan_type" .. self.GanFan_Type)
				self:SetPlayTypeColor(self.GanFan_Type,false,"ganzhou_Label_Fan_Type")
				roundChkBox:setSelected(false)
				self.GanFan_Type = btnTag
				self:SetPlayTypeColor(self.GanFan_Type,true,"ganzhou_Label_Fan_Type")
			end
	elseif eventType == ccui.CheckBoxEventType.unselected then
		senderBtn:setSelected(true)
	end
end

--赣州玩法，上下左右翻，上下翻
--暂时不做处理，因为客户端不需要发消息
function CreateRoom:chooseGanZhouJingTypeEvt(senderBtn, eventType)
	-- local btnTag = senderBtn:getTag()
	-- local roundChkBox = gt.seekNodeByName(self, "ganzhou_ChkBox_FanJing_type" .. btnTag)
	-- roundChkBox:setSelected(true)
	-- self:SetPlayTypeColor(btnTag,true,"ganzhou_Label_FanJing_Type")

	if eventType == ccui.CheckBoxEventType.selected then
		local btnTag = senderBtn:getTag()
			if self.gan_playtype ~= btnTag then
				-- 恢复上一个玩法未选中状态
				local roundChkBox = gt.seekNodeByName(self, "ganzhou_ChkBox_FanJing_type" .. self.gan_playtype)
				self:SetPlayTypeColor(self.gan_playtype,false,"ganzhou_Label_FanJing_Type")
				roundChkBox:setSelected(false)
				self.gan_playtype = btnTag
				self:SetPlayTypeColor(self.gan_playtype,true,"ganzhou_Label_FanJing_Type")
			end
	elseif eventType == ccui.CheckBoxEventType.unselected then
		senderBtn:setSelected(true)
	end


end

-- function addtouchlister(name)
	
-- 	local Label = gt.seekNodeByName(self,name)
-- 	local function onTouchBegan(touch,eventType)

--     	return true
--     end
-- 	local listener = cc.EventListenerTouchOneByOne:create()
-- 	listener:registerScriptHandler(onTouchBegan, cc.Handler.EVENT_TOUCH_BEGAN)
-- 	listener:setSwallowTouches(true)
-- 	local eventDispatcher = Label:getEventDispatcher()
-- 	eventDispatcher:addEventListenerWithSceneGraphPriority(listener, Label)
-- end



function CreateRoom:chooseRoundTypeEvt(senderBtn, eventType)
	if eventType == ccui.CheckBoxEventType.selected then
		local btnTag = senderBtn:getTag()
		--if btnTag == 1 or btnTag == 2 then
			-- 自摸胡和可抢杠胡玩法互斥
			if self.roundType ~= btnTag then
				-- 恢复上一个玩法未选中状态
				local roundChkBox = gt.seekNodeByName(self, "ChkBox_roundType_" .. self.roundType)
				self:SetRoundTypeColor(self.roundType,false)
				roundChkBox:setSelected(false)
				self.roundType = btnTag
				self:SetRoundTypeColor(self.roundType,true)
			end
		--end
	elseif eventType == ccui.CheckBoxEventType.unselected then
		local roundChkBox = gt.seekNodeByName(self, "ChkBox_roundType_" .. self.roundType)
		roundChkBox:setSelected(true)
	end
end

--玩法选择南昌麻将，抚州麻将，萍乡麻将，赣州麻将
function CreateRoom:chooseGameTypeEvt(senderBtn)
	local btnTag = senderBtn:getTag()
	if self.playType ~= btnTag then
		-- 恢复上一个玩法未选中状态
		local roundChkBox = gt.seekNodeByName(self, "T_Di_tongyong_" .. self.playType)
		self:choseT_DiType(btnTag)
		self.playType = btnTag
	end
end

function CreateRoom:choseT_DiType(choosetype)
	local shangraobg = gt.seekNodeByName(self, "shangraobg")
	shangraobg:setVisible(false)

	self["bg2"] = gt.seekNodeByName(self, "fuzhou_bg")
	self["bg3"] =gt.seekNodeByName(self, "pingxiangbg")
	self["bg4"]= gt.seekNodeByName(self, "ganzhoubg")
	self["bg5"]= gt.seekNodeByName(self, "ganzhou3renbg")
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


--点炮一家三家
function CreateRoom:chooseFuTypeEvt(senderBtn, eventType)
	if eventType == ccui.CheckBoxEventType.selected then
		local btnTag = senderBtn:getTag()
		--if btnTag == 1 or btnTag == 2 then
			-- 自摸胡和可抢杠胡玩法互斥
			if self.Fu_Type ~= btnTag then
				-- 恢复上一个玩法未选中状态
				local roundChkBox = gt.seekNodeByName(self, "ChkBox_Fu_type" .. self.Fu_Type)
				self:SetPlayTypeColor(self.Fu_Type,false,"Label_Fu_Type")
				roundChkBox:setSelected(false)
				self.Fu_Type = btnTag
				self:SetPlayTypeColor(self.Fu_Type,true,"Label_Fu_Type")
			end
		--end
	elseif eventType == ccui.CheckBoxEventType.unselected then
		local roundChkBox = gt.seekNodeByName(self, "ChkBox_Fu_type" .. self.Fu_Type)
		roundChkBox:setSelected(true)
	end
end


--霸王
function CreateRoom:chooseBwTypeEvt(senderBtn, eventType)
	if eventType == ccui.CheckBoxEventType.selected or eventType == "haha" then
		local btnTag = senderBtn:getTag()
		--if btnTag == 1 or btnTag == 2 then
			-- 自摸胡和可抢杠胡玩法互斥
			if self.Bw_Type ~= btnTag then
				-- 恢复上一个玩法未选中状态
				local roundChkBox = gt.seekNodeByName(self, "ChkBox_bw_type" .. self.Bw_Type)
				self:SetPlayTypeColor(self.Bw_Type,false,"Label_bw_Type")
				roundChkBox:setSelected(false)
				self.Bw_Type = btnTag
				self:SetPlayTypeColor(self.Bw_Type,true,"Label_bw_Type")
			end
		--end
	elseif eventType == ccui.CheckBoxEventType.unselected then
		local roundChkBox = gt.seekNodeByName(self, "ChkBox_bw_type" .. self.Bw_Type)
		roundChkBox:setSelected(true)
	end
end

--算精
function CreateRoom:chooseJingTypeEvt(senderBtn, eventType)
	if eventType == ccui.CheckBoxEventType.selected or eventType == "haha" then
		local btnTag = senderBtn:getTag()
		--if btnTag == 1 or btnTag == 2 then
			-- 自摸胡和可抢杠胡玩法互斥
			if self.Jing_Type ~= btnTag then
				-- 恢复上一个玩法未选中状态
				local roundChkBox = gt.seekNodeByName(self, "ChkBox_jing_type" .. self.Jing_Type)
				self:SetPlayTypeColor(self.Jing_Type,false,"Label_jing_Type")
				roundChkBox:setSelected(false)
				self.Jing_Type = btnTag
				self:SetPlayTypeColor(self.Jing_Type,true,"Label_jing_Type")
			end
		--end
	elseif eventType == ccui.CheckBoxEventType.unselected then
		local roundChkBox = gt.seekNodeByName(self, "ChkBox_jing_type" .. self.Jing_Type)
		roundChkBox:setSelected(true)
	end
end


--空中拦截
function CreateRoom:chooseKongzhongTypeEvt(senderBtn, eventType)
	if eventType == ccui.CheckBoxEventType.selected then
		local btnTag = senderBtn:getTag()
		--if btnTag == 1 or btnTag == 2 then
			-- 自摸胡和可抢杠胡玩法互斥
			if self.Kongzhong ~= btnTag then
				-- 恢复上一个玩法未选中状态
				local roundChkBox = gt.seekNodeByName(self, "fuzhou_ChkBox_Fu_type" .. self.Kongzhong)
				self:SetPlayTypeColor(self.Kongzhong,false,"fuzhou_Label_Fu_Type")
				roundChkBox:setSelected(false)
				self.Kongzhong = btnTag
				self:SetPlayTypeColor(self.Kongzhong,true,"fuzhou_Label_Fu_Type")
			end
		--end
	elseif eventType == ccui.CheckBoxEventType.unselected then
		local roundChkBox = gt.seekNodeByName(self, "fuzhou_ChkBox_Fu_type" .. self.Kongzhong)
		roundChkBox:setSelected(true)
	end
end

--番数选择
function CreateRoom:chooseFanTypeEvt(senderBtn, eventType)
	if eventType == ccui.CheckBoxEventType.selected then
		local btnTag = senderBtn:getTag()
		--if btnTag == 1 or btnTag == 2 then
			-- 自摸胡和可抢杠胡玩法互斥
			if self.FanType ~= btnTag then
				-- 恢复上一个玩法未选中状态
				local roundChkBox = gt.seekNodeByName(self, "fuzhou_ChkBox_Fan_type" .. self.FanType)
				self:SetPlayTypeColor(self.FanType,false,"fuzhou_Label_Fan_Type")
				roundChkBox:setSelected(false)
				self.FanType = btnTag
				self:SetPlayTypeColor(self.FanType,true,"fuzhou_Label_Fan_Type")
			end
		--end
	elseif eventType == ccui.CheckBoxEventType.unselected then
		local roundChkBox = gt.seekNodeByName(self, "fuzhou_ChkBox_Fan_type" .. self.FanType)
		roundChkBox:setSelected(true)
	end
end

--番数选择
function CreateRoom:chooseDiTypeEvt(senderBtn, eventType)
	if eventType == ccui.CheckBoxEventType.selected then
		local btnTag = senderBtn:getTag()
		--if btnTag == 1 or btnTag == 2 then
			-- 自摸胡和可抢杠胡玩法互斥
			if self.DiType ~= btnTag then
				-- 恢复上一个玩法未选中状态
				local roundChkBox = gt.seekNodeByName(self, "px_ChkBox_Di_type" .. self.DiType)
				self:SetPlayTypeColor(self.DiType,false,"px_Label_Di_Type")
				roundChkBox:setSelected(false)
				self.DiType = btnTag
				self:SetPlayTypeColor(self.DiType,true,"px_Label_Di_Type")
			end
		--end
	elseif eventType == ccui.CheckBoxEventType.unselected then
		local roundChkBox = gt.seekNodeByName(self, "px_ChkBox_Di_type" .. self.DiType)
		roundChkBox:setSelected(true)
	end
end


-- start --
--------------------------------
-- @class function
-- @description 选择玩法
-- @param senderBtn 触发事件按钮
-- @param eventType 事件类型
-- end --

function CreateRoom:choosePlayTypeEvt(senderBtn, eventType)
	if eventType == ccui.CheckBoxEventType.selected then
		gt.log("name: = " .. senderBtn:getName() .. " selected"..senderBtn:getTag())
		local btnTag = senderBtn:getTag()
		--if btnTag == 1 or btnTag == 2 then
			-- 自摸胡和可抢杠胡玩法互斥
			if self.prePlayType ~= btnTag then
				-- 恢复上一个玩法未选中状态
				local playTypeChkBox = gt.seekNodeByName(self, "ChkBox_playType_" .. self.prePlayType)
				playTypeChkBox:setSelected(false)
				self:SetPlayTypeColor(self.prePlayType,false,"Label_playType_")
				self.prePlayType = btnTag
				self:SetPlayTypeColor(self.prePlayType,true,"Label_playType_")
			end
		--end
	elseif eventType == ccui.CheckBoxEventType.unselected then
		gt.log("name: = " .. senderBtn:getName() .. " unselected")
		local playTypeChkBox = gt.seekNodeByName(self, "ChkBox_playType_" .. self.prePlayType)
		playTypeChkBox:setSelected(true)
	end
end



function CreateRoom:setGray(target, open)

    if open == 1 then
		local grey_shader = cc.GLProgram:create("shaders/grayscaleShader.vsh","shaders/greyScale.fsh")
		grey_shader:bindAttribLocation(cc.ATTRIBUTE_NAME_POSITION,cc.VERTEX_ATTRIB_POSITION)
		grey_shader:bindAttribLocation(cc.ATTRIBUTE_NAME_TEX_COORD,cc.VERTEX_ATTRIB_TEX_COORD)
		grey_shader:link()
		grey_shader:updateUniforms()
        local glprogramstate = cc.GLProgramState:getOrCreateWithGLProgram(grey_shader)
        if target then
            target:setGLProgramState(glprogramstate)
        end
		grey_shader = nil
    else
		local grey_default_shader = cc.GLProgram:create("shaders/defualtShader.vsh","shaders/defualtShader.fsh")
	    grey_default_shader:bindAttribLocation(cc.ATTRIBUTE_NAME_POSITION,cc.VERTEX_ATTRIB_POSITION)
	    grey_default_shader:bindAttribLocation(cc.ATTRIBUTE_NAME_TEX_COORD,cc.VERTEX_ATTRIB_TEX_COORD)
	    grey_default_shader:link()
	    grey_default_shader:updateUniforms()
        local glprogramstate = cc.GLProgramState:getOrCreateWithGLProgram(grey_default_shader)
        if target then
            target:setGLProgramState(glprogramstate)
        end    
		grey_default_shader = nil   
    end
end
-- start --
--------------------------------
-- @class function
-- @description 创建房间消息
-- @param msgTbl 消息体
-- end --
function CreateRoom:onRcvCreateRoom(msgTbl)
	if msgTbl.m_errorCode ~= 0 then
		-- 创建失败
		gt.removeLoadingTips()

		-- 房卡不足提示
		require("app/views/BuyCard"):create("1", gt.roomCardBuyInfo)
		--require("app/views/BuyCard"):create("2")
	end
end

function CreateRoom:SetRoundTypeColor(choostype,red)
	local Label_round = gt.seekNodeByName(self, "Label_round_" .. choostype)
	local Label_roundChild = gt.seekNodeByName(self, "Label_round_" .. choostype .. "_" ..choostype)
	if red then
		Label_round:setTextColor(cc.c4b(255,54,0,255))
		Label_roundChild:setTextColor(cc.c4b(255,54,0,255))
	else
		Label_round:setTextColor(cc.c4b(156,92,57,255))
		Label_roundChild:setTextColor(cc.c4b(156,92,57,255))
	end
end




function CreateRoom:SetPlayTypeColor(choostype,red,name)
	local Label_round = gt.seekNodeByName(self, name .. choostype)
	if red then
		Label_round:setTextColor(cc.c4b(255,54,0,255))
	else
		Label_round:setTextColor(cc.c4b(156,92,57,255))
	end
end
return CreateRoom


