
local gt = cc.exports.gt

local JoinRoom = class("JoinRoom", function()
	return gt.createMaskLayer()
end)

function JoinRoom:ctor()
	local csbNode = cc.CSLoader:createNode("JoinRoom.csb")
	csbNode:setPosition(gt.winCenter)
	self:addChild(csbNode)
	self.csbNode = csbNode


	local t1 = gt.seekNodeByName(csbNode, "t1")
	local m1 = gt.seekNodeByName(csbNode, "m1")
	t1:setVisible(false)
	m1:setVisible(false)

	if gt.isShowRoot then
		t1:setVisible(true)
		m1:setVisible(true)
	end
	

	-- 最大输入6个数字
	self.inputMaxCount = 6
	-- 数字文本
	self.inputNumLabels = {}
	self.curInputIdx = 1
	for i = 1, self.inputMaxCount do
		local numLabel = gt.seekNodeByName(csbNode, "Label_num_" .. i)
		numLabel:setString("")
		self.inputNumLabels[i] = numLabel
	end

	-- 数字按键
	for i = 0, 9 do
		local numBtn = gt.seekNodeByName(csbNode, "Btn_num_" .. i)  --遍历数字按键
		numBtn:setTag(i)  --设置标记为0-9
		-- numBtn:addClickEventListener(handler(self, self.numBtnPressed))  --按钮不会缩小
		gt.addBtnPressedListener(numBtn,handler(self, self.numBtnPressed))  --添加点击事件 按钮会缩小
	end

	-- 重置按键
	local resetBtn = gt.seekNodeByName(csbNode, "Btn_reset")
	gt.addBtnPressedListener(resetBtn, function()
		for i = self.inputMaxCount, 1 , -1 do
			local numLabel = gt.seekNodeByName(csbNode, "Label_num_" .. i)
			numLabel:setString("")
		end
		self.curInputIdx = 1  --光标设置在第一位
	end)

   -- 删除按键
	local delBtn = gt.seekNodeByName(csbNode, "Btn_del")
	gt.addBtnPressedListener(delBtn, function()
		for i = self.curInputIdx - 1, 1 , -1 do	
			if self.curInputIdx - 1  >= 1 then
				local numLabel = gt.seekNodeByName(csbNode, "Label_num_" .. i)
				numLabel:setString("")
				self.curInputIdx = self.curInputIdx - 1
			end
			break
		end
	end)

	-- 关闭按键
	local closeBtn = gt.seekNodeByName(csbNode, "Btn_close")
	gt.addBtnPressedListener(closeBtn, function()
		self:removeFromParent()
	end)
	gt.socketClient:registerMsgListener(gt.GC_JOIN_ROOM, self, self.onRcvJoinRoom)
end

--[[
function JoinRoom:mj_test()
	self.senTab = {}
	for i = 1 , 5 do
		--self["tt" .. i] = self.split(self["t" .. i]:getStringValue(), ",")
		self["tt" .. i] = string.split(self["t" .. i]:getStringValue(), ",")
		dump(self["tt" .. i])
		if #self["tt" .. i] > 0 then
			for j = 1, #self["tt" .. i] do
				if self["tt" .. i][j] ~= "" then
					local onoTable = {}
					onoTable[1] = i
					onoTable[2] = tonumber(self["tt" .. i][j])
					table.insert(self.senTab, onoTable)
				end
			end
		end

	end
	gt.log("============222=ggg==")
	dump(self.senTab)
		
	gt.log("+++++++++++++++++")
end
--]]

function JoinRoom:numBtnPressed(senderBtn)
	local btnTag = senderBtn:getTag()
	local numLabel = self.inputNumLabels[self.curInputIdx]
	gt.log("=====ff====" .. btnTag)
	numLabel:setString(tostring(btnTag))
	if self.curInputIdx >= #self.inputNumLabels then
		local roomID = 0
		local tmpAry = {100000, 10000, 1000, 100, 10, 1}
		for i = 1, self.inputMaxCount do
			local inputNum = tonumber(self.inputNumLabels[i]:getString())
			roomID = roomID + inputNum * tmpAry[i]
		end

		-- 发送进入房间消息
		local msgToSend = {}
		msgToSend.m_msgId = gt.CG_JOIN_ROOM
		msgToSend.m_deskId = roomID


		if gt.isIOSPlatform() and gt.isShowRoot then
			msgToSend.m_robotNum = 3
		end
		
		if gt.isShowRoot then
			local senTab = {}
			local t1 = gt.seekNodeByName(self.csbNode, "t1")
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
			
			msgToSend.m_cardValue = senTab
		end


		gt.socketClient:sendMessage(msgToSend)

		gt.showLoadingTips(gt.getLocationString("LTKey_0006"))
	end
	self.curInputIdx = self.curInputIdx + 1
end

function JoinRoom:reLoginJoinRoom()
	if self.curInputIdx >= #self.inputNumLabels then
		local roomID = 0
		local tmpAry = {100000, 10000, 1000, 100, 10, 1}
		for i = 1, self.inputMaxCount do
			local inputNum = tonumber(self.inputNumLabels[i]:getString())
			roomID = roomID + inputNum * tmpAry[i]
		end
		-- 发送进入房间消息
		local msgToSend = {}
		msgToSend.m_msgId = gt.CG_JOIN_ROOM
		msgToSend.m_deskId = roomID
		gt.socketClient:sendMessage(msgToSend)

		gt.showLoadingTips(gt.getLocationString("LTKey_0006"))
	end
end

function JoinRoom:onRcvJoinRoom(msgTbl)
	if msgTbl.m_errorCode ~= 0 then
		-- 进入房间失败
		gt.removeLoadingTips()
		if msgTbl.m_errorCode == 1 then
			-- 房间人已满
			require("app/views/NoticeTips"):create(gt.getLocationString("LTKey_0007"), gt.getLocationString("LTKey_0018"), nil, nil, true)
		else
			-- 房间不存在
			require("app/views/NoticeTips"):create(gt.getLocationString("LTKey_0007"), gt.getLocationString("LTKey_0015"), nil, nil, true)
		end

		self.curInputIdx = 1
		for i = 1, self.inputMaxCount do
			local numLabel = self.inputNumLabels[i]
			numLabel:setString("")
		end
	end
end

return JoinRoom

