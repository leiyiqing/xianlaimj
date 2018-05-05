
local gt = cc.exports.gt

local HistoryRecord = class("HistoryRecord", function()
	return cc.Layer:create()
end)

function HistoryRecord:ctor(uid)
	gt.log("===00000==")
	-- 注册节点事件
	self:registerScriptHandler(handler(self, self.onNodeEvent))

	local csbNode = cc.CSLoader:createNode("HistoryRecord.csb")
	csbNode:setAnchorPoint(0.5, 0.5)
	csbNode:setPosition(gt.winCenter)
	self:addChild(csbNode)
	self.rootNode = csbNode


	if gt.isIOSPlatform() and gt.isInReview then
		local spr = gt.seekNodeByName(csbNode, "bg")
		if spr then
			spr:setVisible(false)
		end
	end

	-- 战绩标题
	local titleRoomNode = gt.seekNodeByName(csbNode, "Node_titleRoom")
	titleRoomNode:setVisible(false)

	-- 无战绩提示
	local emptyLabel = gt.seekNodeByName(csbNode, "Label_empty")
	emptyLabel:setVisible(false)

	-- 返回按钮
	local backBtn = gt.seekNodeByName(csbNode, "Btn_back")
	gt.addBtnPressedListener(backBtn, function()
		local historyListVw = gt.seekNodeByName(self.rootNode, "ListVw_content")
		if historyListVw:isVisible() then
			-- 移除消息回调
			gt.socketClient:unregisterMsgListener(gt.GC_HISTORY_RECORD)
			gt.socketClient:unregisterMsgListener(gt.GC_REPLAY)

			-- 移除界面,返回主界面
			self:removeFromParent()
		else
			-- 隐藏详细信息
			local titleRoomNode = gt.seekNodeByName(csbNode, "Node_titleRoom")
			titleRoomNode:setVisible(false)
			historyListVw:setVisible(true)
			local historyDetailNode = gt.seekNodeByName(self.rootNode, "Node_historyDetail")
			historyDetailNode:removeAllChildren()
		end
	end)

	--  底部背景条
	--local Spr_btmTips = gt.seekNodeByName(self, "Spr_btmTips")
	--  底部背景条上描述文字
	--local Spr_btmTips_text = gt.seekNodeByName(self, "Text_1")
	--if gt.isIOSPlatform() and gt.isInReview then
		--Spr_btmTips_text:setVisible(false)
	--else
		--Spr_btmTips_text:setVisible(true)
	--end

	-- 发送请求战绩消息
	local msgToSend = {}
	msgToSend.m_msgId = gt.CG_HISTORY_RECORD
	msgToSend.m_time = 123456
	if gt.isGM then
		msgToSend.m_userId = tonumber(uid)
	end
	gt.log("==========" .. type(uid))
	gt.socketClient:sendMessage(msgToSend)

	-- 注册消息回调
	gt.socketClient:registerMsgListener(gt.GC_HISTORY_RECORD, self, self.onRcvHistoryRecord)
	gt.socketClient:registerMsgListener(gt.GC_REPLAY, self, self.onRcvReplay)
end

function HistoryRecord:onNodeEvent(eventName)
	if "enter" == eventName then
		-- 触摸事件
		local listener = cc.EventListenerTouchOneByOne:create()
		listener:setSwallowTouches(true)
		listener:registerScriptHandler(handler(self, self.onTouchBegan), cc.Handler.EVENT_TOUCH_BEGAN)
		local eventDispatcher = self:getEventDispatcher()
		eventDispatcher:addEventListenerWithSceneGraphPriority(listener, self)
	elseif "exit" == eventName then
		-- 移除触摸事件
		local eventDispatcher = self:getEventDispatcher()
		eventDispatcher:removeEventListenersForTarget(self)
	end
end

function HistoryRecord:onTouchBegan(touch, event)
	return true
end

function HistoryRecord:onRcvHistoryRecord(msgTbl)
	if #msgTbl.m_data == 0 then
		-- 没有战绩
		local emptyLabel = gt.seekNodeByName(self.rootNode, "Label_empty")
		emptyLabel:setVisible(true)
	else
		-- 显示战绩列表
		self.historyMsgTbl = msgTbl

		local historyListVw = gt.seekNodeByName(self.rootNode, "ListVw_content")
		for i, cellData in ipairs(msgTbl.m_data) do
			if cellData then
				local historyItem = self:createHistoryItem(i, cellData)
				if historyItem then
					historyListVw:pushBackCustomItem(historyItem)
				end
			end
		end
	end
end

function HistoryRecord:onRcvReplay(msgTbl)
	gt.log("---------22-33----4-4---5--")
	local replayLayer = require("app/views/ReplayLayer"):create(msgTbl)
	self:addChild(replayLayer, 6)
end


-- start --
--------------------------------
-- @class function
-- @description 创建战绩条目
-- @param cellData 条目数据
-- end --
function HistoryRecord:createHistoryItem(tag, cellData)
	local cellNode = cc.CSLoader:createNode("HistoryCell.csb")
	-- 序号
	local numLabel = gt.seekNodeByName(cellNode, "Label_num")
	numLabel:setString(tostring(tag))
	-- 房间号
	local roomIDLabel = gt.seekNodeByName(cellNode, "Label_roomID")
	roomIDLabel:setString(cellData.m_deskId)
	-- 对战时间
	local timeLabel = gt.seekNodeByName(cellNode, "Label_time")
	local timeTbl = os.date("*t", cellData.m_time)
	timeLabel:setString(gt.getLocationString("LTKey_0040", timeTbl.year, timeTbl.month, timeTbl.day, timeTbl.hour, timeTbl.min, timeTbl.sec))
	-- 玩家昵称+分数
	for i, v in ipairs(cellData.m_nike) do
		local nicknameLabel = gt.seekNodeByName(cellNode, "Label_nickname_" .. i)
		nicknameLabel:setString(v)
		local scoreLabel = gt.seekNodeByName(cellNode, "Label_score_" .. i)
		scoreLabel:setString(tostring(cellData.m_score[i]))
	end

	local cellSize = cellNode:getContentSize()
	local cellItem = ccui.Widget:create()
	cellItem:setTag(tag)
	cellItem:setTouchEnabled(true)
	cellItem:setContentSize(cellSize)
	cellItem:addChild(cellNode)
	cellItem:addClickEventListener(handler(self, self.historyItemClickEvent))

	return cellItem
end

function HistoryRecord:historyItemClickEvent(sender, eventType)
	-- 隐藏历史记录
	local historyListVw = gt.seekNodeByName(self.rootNode, "ListVw_content")
	historyListVw:setVisible(false)
	-- 切换标题
	local titleRoomNode = gt.seekNodeByName(self.rootNode, "Node_titleRoom")
	titleRoomNode:setVisible(true)

	local itemTag = sender:getTag()
	local cellData = self.historyMsgTbl.m_data[itemTag]
	local historyDetailNode = gt.seekNodeByName(self.rootNode, "Node_historyDetail")
	local detailPanel = cc.CSLoader:createNode("HistoryDetail.csb")
	detailPanel:setAnchorPoint(0.5, 0.5)
	historyDetailNode:addChild(detailPanel)
	-- 玩家昵称
	for i, v in ipairs(cellData.m_nike) do
		local nicknameLabel = gt.seekNodeByName(detailPanel, "Label_nickname_" .. i)
		nicknameLabel:setString(v)
	end
	-- 对应详细记录信息
	local contentListVw = gt.seekNodeByName(detailPanel, "ListVw_content")
	gt.log("===========555==")
	dump(cellData.m_match)
	for i, v in ipairs(cellData.m_match) do
		local detailCellNode = cc.CSLoader:createNode("HistoryDetailCell.csb")
		if i % 2 == 0 then
			local bg = gt.seekNodeByName(detailCellNode, "Image_history")
			bg:setVisible(false)
		else
			local bg = gt.seekNodeByName(detailCellNode, "Image_history_1")
			bg:setVisible(false)
		end
		-- 序号
		local numLabel = gt.seekNodeByName(detailCellNode, "Label_num")
		numLabel:setString(tostring(i))
		-- 对战时间
		local timeLabel = gt.seekNodeByName(detailCellNode, "Label_time")
		local timeTbl = os.date("*t", v.m_time)
		timeLabel:setString(string.format("%d-%d %d:%d", timeTbl.month, timeTbl.day, timeTbl.hour, timeTbl.min))
		-- 对战分数
		for j, score in ipairs(v.m_score) do
			local scoreLabel = gt.seekNodeByName(detailCellNode, "Label_score_" .. j)
			scoreLabel:setString(tostring(score))
			scoreLabel:setVisible(true)
		end

		-- 查牌按钮
		local replayBtn = gt.seekNodeByName(detailCellNode, "Btn_replay")
		-- replayBtn:setVisible(false)
		replayBtn.videoId = v.m_videoId
		gt.addBtnPressedListener(replayBtn, function(sender)
			local btnTag = sender:getTag()

			-- 请求打牌回放数据
			local msgToSend = {}
			msgToSend.m_msgId = gt.CG_REPLAY
			msgToSend.m_videoId = replayBtn.videoId
			gt.socketClient:sendMessage(msgToSend)
		end)

		local cellSize = detailCellNode:getContentSize()
		local detailItem = ccui.Widget:create()
		detailItem:setContentSize(cellSize)
		detailItem:addChild(detailCellNode)
		contentListVw:pushBackCustomItem(detailItem)
	end
end

return HistoryRecord

