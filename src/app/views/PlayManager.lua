
local gt = cc.exports.gt

local PlayManager = class("PlayManager")

-- shuffle洗牌，cut切牌，deal发牌，sort理牌，draw摸牌，play打出，discard弃牌

function PlayManager:ctor(rootNode, paramTbl, turnCard)
	self.rootNode = rootNode
	self.turnCard = turnCard
	-- 房间号
	self.roomID = paramTbl.roomID

	-- 玩法类型
	self.playType = paramTbl.playType
	-- 玩法描述
	self.Gametype =  paramTbl.GameType 
	local playTypeDesc = "点炮胡"
	if paramTbl.GameType == 1 then
		if self.playType == 1 then
			playTypeDesc = "无下精"
		elseif self.playType == 2 then
			playTypeDesc = "埋地雷"
		elseif self.playType == 3 then
			playTypeDesc = "回头一笑"
		elseif self.playType == 4 then
			playTypeDesc = "回头上下翻"
		elseif self.playType == 5 then
			playTypeDesc = "同一首歌"
		end
	elseif paramTbl.GameType == 2 then
		if paramTbl.fu_type == 1 then
			playTypeDesc = "空中拦截"
		elseif paramTbl.fu_type == 2 then
			playTypeDesc = "无空中拦截"
		end
	elseif paramTbl.GameType == 3 then
		playTypeDesc = "萍乡258"
	elseif paramTbl.GameType == 4 then
		playTypeDesc = "赣州冲关"
	end
	self.playTypeDesc = playTypeDesc

	-- 玩家显示固定座位号
	self.playerDisplayIdx = 4
	self.playerSeatIdx = paramTbl.playerSeatIdx

	if paramTbl.GameType == 5 then
		self.playerDisplayIdx = 3
	end

	-- 头像下载管理器
	local playerHeadMgr = require("app/PlayerHeadManager"):create()
	self.rootNode:addChild(playerHeadMgr)
	self.playerHeadMgr = playerHeadMgr

	self:initUI()
end

function PlayManager:initUI()
	-- 隐藏玩家麻将参考位置
	local playNode = gt.seekNodeByName(self.rootNode, "Node_play")
	playNode:setVisible(false)

	-- 房间号
	local roomIDLabel = gt.seekNodeByName(self.rootNode, "Label_roomID")
	roomIDLabel:setString(gt.getLocationString("LTKey_0013", self.roomID))

	-- 玩法描述
	local playTypeLabel = gt.seekNodeByName(self.rootNode, "Label_playType")
	playTypeLabel:setString(self.playTypeDesc)

	-- 麻将层
	local playMjLayer = cc.Layer:create()
	self.rootNode:addChild(playMjLayer, gt.PlayZOrder.MJTILES_LAYER)
	self.playMjLayer = playMjLayer

	-- 出的牌标识动画
	local outMjtileSignNode, outMjtileSignAnime = gt.createCSAnimation("animation/OutMjtileSign.csb")
	outMjtileSignAnime:play("run", true)
	outMjtileSignNode:setVisible(false)
	self.rootNode:addChild(outMjtileSignNode, gt.PlayZOrder.OUTMJTILE_SIGN)
	self.outMjtileSignNode = outMjtileSignNode

	-- 逻辑座位和显示座位偏移量(从0编号开始)
	local seatOffset = self.playerDisplayIdx - self.playerSeatIdx
	self.seatOffset = seatOffset
	-- 旋转座次标识,座次方位和显示对应
	local turnPosBgSpr = gt.seekNodeByName(self.rootNode, "Spr_turnPosBg")
	turnPosBgSpr:setRotation(-seatOffset * 90)
	for _, turnPosSpr in ipairs(turnPosBgSpr:getChildren()) do
		turnPosSpr:setVisible(false)
	end
end

-- start --
--------------------------------
-- @class function
-- @description 房间添加玩家
-- @param playerData 玩家数据
-- end --
function PlayManager:roomAddPlayer(roomPlayer)
	-- 玩家自己
	roomPlayer.isOneself = false
	if roomPlayer.seatIdx == self.playerSeatIdx then
		roomPlayer.isOneself = true
	end
	-- 显示索引
	roomPlayer.displayIdx = (roomPlayer.seatIdx + self.seatOffset - 1) % 4 + 1
	if self.Gametype == 5 then
		roomPlayer.displayIdx = (roomPlayer.seatIdx + self.seatOffset - 1) % 3 + 1
		if roomPlayer.displayIdx == 2 then
			roomPlayer.displayIdx = 3
		elseif roomPlayer.displayIdx == 3 then
			roomPlayer.displayIdx = 4
		end
	end

	-- 玩家信息
	local playerInfoNode = gt.seekNodeByName(self.rootNode, "Node_playerInfo_" .. roomPlayer.displayIdx)
	playerInfoNode:setVisible(true)
	-- 头像
	roomPlayer.headURL = string.sub(roomPlayer.headURL, 1, string.lastString(roomPlayer.headURL, "/")) .. "96"
	local headSpr = gt.seekNodeByName(playerInfoNode, "Spr_head")
	self.playerHeadMgr:attach(headSpr, roomPlayer.uid, roomPlayer.headURL)
	-- 昵称
	local nicknameLabel = gt.seekNodeByName(playerInfoNode, "Label_nickname")
	nicknameLabel:setString(roomPlayer.nickname)
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
	-- 明补
	roomPlayer.mjTileBrightBu = {}
	-- 暗补
	roomPlayer.mjTileDarkBu = {}
	-- 麻将放置参考点
	roomPlayer.mjTilesReferPos = self:getPlayerMjTilesReferPos(roomPlayer.displayIdx)

	-- 添加入缓冲
	if not self.roomPlayers then
		self.roomPlayers = {}
	end
	self.roomPlayers[roomPlayer.seatIdx] = roomPlayer
end

-- start --
--------------------------------
-- @class function
-- @description 设置座位编号标识
-- @param seatIdx 座位编号
-- end --
function PlayManager:setTurnSeatSign(seatIdx)
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

function PlayManager:drawMjTile(seatIdx, mjColor, mjNumber)
	local roomPlayer = self.roomPlayers[seatIdx]

	-- 添加牌放在末尾
	local mjTilesReferPos = roomPlayer.mjTilesReferPos
	local mjTilePos = mjTilesReferPos.holdStart
	mjTilePos = cc.pAdd(mjTilePos, cc.pMul(mjTilesReferPos.holdSpace, #roomPlayer.holdMjTiles))
	mjTilePos = cc.pAdd(mjTilePos, mjTilesReferPos.drawSpace)
	gt.log("========8======")
	dump(roomPlayer)
	gt.log("---------9999--")
	local mjTile = self:addMjTile(roomPlayer, mjColor, mjNumber)
	mjTile.mjTileSpr:setPosition(mjTilePos)
	self.playMjLayer:reorderChild(mjTile.mjTileSpr, (gt.winSize.height - mjTilePos.y))
end

-- start --
--------------------------------
-- @class function
-- @description 给玩家添加牌
-- @param seatIdx 座位号
-- @param mjColor 花色
-- @param mjNumber 编号
-- end --
function PlayManager:addMjTile(roomPlayer, mjColor, mjNumber)
	-- local roomPlayer = self.roomPlayers[seatIdx]

	local mjTileName = ""
	if roomPlayer.isOneself then
		-- 玩家自己
		mjTileName = string.format("p%db%d_%d.png", roomPlayer.displayIdx, mjColor, mjNumber)
	else
		if roomPlayer.isHidden then
			-- 持有牌隐藏
			mjTileName = string.format("tbgs_%d.png", roomPlayer.displayIdx)
		else
			mjTileName = string.format("p%ds%d_%d.png", roomPlayer.displayIdx, mjColor, mjNumber)
		end
	end
	local mjTileSpr = cc.Sprite:createWithSpriteFrameName(mjTileName)
	gt.log("=====23232=" .. mjColor, mjNumber)
	dump(roomPlayer)
	gt.log("=====2323200000====")
	self:showflag(roomPlayer, mjColor, mjNumber, mjTileSpr)
	self.playMjLayer:addChild(mjTileSpr)

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
-- @description 出牌
-- @param
-- @param
-- @param
-- @return
-- end --
function PlayManager:playOutMjTile(seatIdx, mjColor, mjNumber)
	local roomPlayer = self.roomPlayers[seatIdx]

	-- 持有牌删除对应麻将
	self:removeHoldMjTiles(roomPlayer, mjColor, mjNumber, 1)

	-- 显示出牌动画
	self:showOutMjTileAnimation(roomPlayer, mjColor, mjNumber, function()
		-- 添加出牌
		self:outMjTile(roomPlayer, mjColor, mjNumber)

		-- 显示出牌标识
		self:showOutMjtileSign(roomPlayer)
	end)

	-- 记录出牌的上家
	self.prePlaySeatIdx = seatIdx

	-- dj revise
	gt.soundManager:PlayCardSound(roomPlayer.sex, mjColor, mjNumber)
	if roomPlayer.sex == 1 then
		-- 男性
		gt.soundEngine:playEffect(string.format("man/mjt%d_%d", mjColor, mjNumber))
	else
		-- 女性
		gt.soundEngine:playEffect(string.format("woman/mjt%d_%d", mjColor, mjNumber))
	end
end

-- 快速出牌
function PlayManager:playOutMjTileQuick(seatIdx, mjColor, mjNumber)
	local roomPlayer = self.roomPlayers[seatIdx]

	-- 持有牌删除对应麻将
	self:removeHoldMjTiles(roomPlayer, mjColor, mjNumber, 1)

	-- 添加出牌
	self:outMjTile(roomPlayer, mjColor, mjNumber)

	-- 显示出牌标识
	self:showOutMjtileSign(roomPlayer)

	-- 记录出牌的上家
	self.prePlaySeatIdx = seatIdx
end


-- start --
--------------------------------
-- @class function
-- @description 添加已出牌
-- @param seatIdx 座位号
-- @param mjColor 花色
-- @param mjNumber 编号
-- end --
function PlayManager:outMjTile(roomPlayer, mjColor, mjNumber)
	-- 添加到已出牌
	-- local roomPlayer = self.roomPlayers[seatIdx]

	local mjTileName = string.format("p%ds%d_%d.png", roomPlayer.displayIdx, mjColor, mjNumber)
	local mjTileSpr = cc.Sprite:createWithSpriteFrameName(mjTileName)
	self:showflag(roomPlayer, mjColor, mjNumber, mjTileSpr)

	local mjTile = {}
	mjTile.mjTileSpr = mjTileSpr
	mjTile.mjColor = mjColor
	mjTile.mjNumber = mjNumber
	table.insert(roomPlayer.outMjTiles, mjTile)

	-- 缩小玩家已出牌
	if roomPlayer.isOneself then
		mjTileSpr:setScale(0.66)
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

-- start --
--------------------------------
-- @class function
-- @description 碰牌
-- @param seatIdx 座位编号
-- @param mjColor 花色
-- @param mjNumber 编号
-- end --
function PlayManager:addMjTilePung(seatIdx, mjColor, mjNumber)
	local roomPlayer = self.roomPlayers[seatIdx]

	local pungData = {}
	pungData.mjColor = mjColor
	pungData.mjNumber = mjNumber
	table.insert(roomPlayer.mjTilePungs, pungData)

	pungData.groupNode = self:pungBarReorderMjTiles(roomPlayer, mjColor, mjNumber, false)
end

-- start --
--------------------------------
-- @class function
-- @description 杠牌
-- @param seatIdx 座位编号
-- @param mjColor 花色
-- @param mjNumber 编号
-- @param isBrightBar 明杠或者暗杠
-- end --
function PlayManager:addMjTileBar(seatIdx, mjColor, mjNumber, isBrightBar)
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

	barData.groupNode = self:pungBarReorderMjTiles(roomPlayer, mjColor, mjNumber, true, isBrightBar)
end

function PlayManager:getPlayerMjTilesReferPos(displayIdx)
	local mjTilesReferPos = {}

	local playNode = gt.seekNodeByName(self.rootNode, "Node_play")
	local mjTilesReferNode = gt.seekNodeByName(playNode, "Node_playerMjTiles_" .. displayIdx)

	-- 持有牌数据
	local mjTileHoldSprF = gt.seekNodeByName(mjTilesReferNode, "Spr_mjTileHold_1")
	local mjTileHoldSprS = gt.seekNodeByName(mjTilesReferNode, "Spr_mjTileHold_2")
	mjTilesReferPos.holdStart = cc.p(mjTileHoldSprF:getPosition())
	mjTilesReferPos.holdSpace = cc.pSub(cc.p(mjTileHoldSprS:getPosition()), cc.p(mjTileHoldSprF:getPosition()))

	-- 摸牌偏移
	local drawSpaces = {{x = -16,	y = 0},
						{x = 0,		y = -16},
						{x = 16,	y = 0},
						{x = 32,	y = 0}}
	mjTilesReferPos.drawSpace = drawSpaces[displayIdx]

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
	if displayIdx == 1 or displayIdx == 3 then
		mjTilesReferPos.groupSpace = cc.p(0, groupSize.height + 8)
		if displayIdx == 3 then
			mjTilesReferPos.groupSpace.y = -mjTilesReferPos.groupSpace.y
		end
	else
		mjTilesReferPos.groupSpace = cc.p(groupSize.width + 8, 0)
		if displayIdx == 2 then
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
-- @description 玩家麻将牌根据花色，编号重新排序
-- end --
function PlayManager:sortHoldMjTiles(roomPlayer)
	-- local roomPlayer = self.roomPlayers[seatIdx]

	-- 玩家持有牌不能看,不用排序
	if not roomPlayer.isHidden then
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
		roomPlayer.holdMjTiles = transMjTiles
	end

	-- 更新摆放位置
	local mjTilesReferPos = roomPlayer.mjTilesReferPos
	local mjTilePos = mjTilesReferPos.holdStart
	for _, mjTile in ipairs(roomPlayer.holdMjTiles) do
		mjTile.mjTileSpr:setPosition(mjTilePos)
		self.playMjLayer:reorderChild(mjTile.mjTileSpr, (gt.winSize.height - mjTilePos.y))
		mjTilePos = cc.pAdd(mjTilePos, mjTilesReferPos.holdSpace)
	end
end

function PlayManager:removeHoldMjTiles(roomPlayer, mjColor, mjNumber, mjTilesCount)
	local transMjTiles = {}
	local count = 0
	for _, mjTile in ipairs(roomPlayer.holdMjTiles) do
		if roomPlayer.isHidden then
			if count < mjTilesCount then
				mjTile.mjTileSpr:removeFromParent()
				count = count + 1
			else
				table.insert(transMjTiles, mjTile)
			end
		else
			if count < mjTilesCount and mjTile.mjColor == mjColor and mjTile.mjNumber == mjNumber then
				mjTile.mjTileSpr:removeFromParent()
				count = count + 1
			else
				-- 保存其它牌
				table.insert(transMjTiles, mjTile)
			end
		end
	end
	roomPlayer.holdMjTiles = transMjTiles

	self:sortHoldMjTiles(roomPlayer)
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
function PlayManager:pungBarReorderMjTiles(roomPlayer, mjColor, mjNumber, isBar, isBrightBar)
	-- local roomPlayer = self.roomPlayers[seatIdx]
	local groupNode = nil
	-- if self.playType ~= gt.RoomType.ROOM_CHANGSHA then
	-- 	if type(roomPlayer) == "number" then
	-- 		roomPlayer = self.roomPlayers[roomPlayer]
	-- 	end

	-- 	local mjTilesReferPos = roomPlayer.mjTilesReferPos
	-- 	-- 显示碰杠牌
	-- 	local groupMjTilesPos = mjTilesReferPos.groupMjTilesPos
	-- 	groupNode = cc.Node:create()
	-- 	groupNode:setPosition(mjTilesReferPos.groupStartPos)
	-- 	self.playMjLayer:addChild(groupNode)
	-- 	local mjTilesCount = 3
	-- 	if isBar then
	-- 		mjTilesCount = 4
	-- 	end
	-- 	for i = 1, mjTilesCount do
	-- 		local mjTileName = string.format("p%ds%d_%d.png", roomPlayer.displayIdx, mjColor, mjNumber)
	-- 		if isBar and not isBrightBar and i <= 3 then
	-- 			-- 暗杠前三张牌扣着
	-- 			mjTileName = string.format("tdbgs_%d.png", roomPlayer.displayIdx)
	-- 		end
	-- 		local mjTileSpr = cc.Sprite:createWithSpriteFrameName(mjTileName)
	-- 		self:showflag(roomPlayer, mjColor, mjNumber, mjTileSpr)
	-- 		mjTileSpr:setPosition(groupMjTilesPos[i])
	-- 		groupNode:addChild(mjTileSpr)
	-- 	end
	-- 	mjTilesReferPos.groupStartPos = cc.pAdd(mjTilesReferPos.groupStartPos, mjTilesReferPos.groupSpace)
	-- 	mjTilesReferPos.holdStart = cc.pAdd(mjTilesReferPos.holdStart, mjTilesReferPos.groupSpace)

	-- 	-- 更新持有牌
	-- 	-- 碰2张
	-- 	local mjTilesCount = 2
	-- 	if isBar then
	-- 		-- 明杠3张
	-- 		mjTilesCount = 3
	-- 		-- 暗杠4张
	-- 		if not isBrightBar then
	-- 			mjTilesCount = 4
	-- 		end
	-- 	end
	-- 	self:removeHoldMjTiles(roomPlayer, mjColor, mjNumber, mjTilesCount)
	-- else
		local isEat = false
		if type(roomPlayer) == "number" then
			roomPlayer = self.roomPlayers[roomPlayer]
			isEat = true
		end

		local mjTilesReferPos = roomPlayer.mjTilesReferPos
		-- 显示碰杠牌
		local groupMjTilesPos = mjTilesReferPos.groupMjTilesPos
		groupNode = cc.Node:create()
		groupNode:setPosition(mjTilesReferPos.groupStartPos)
		self.playMjLayer:addChild(groupNode)
		local mjTilesCount = 3
		if isBar then
			mjTilesCount = 4
		end
		if isEat == true then
			for i = 1, mjTilesCount do
				local mjTileName = string.format("p%ds%d_%d.png", roomPlayer.displayIdx, mjColor, mjNumber[i][1])
				local mjTileSpr = cc.Sprite:createWithSpriteFrameName(mjTileName)
				self:showflag(roomPlayer, mjColor, mjNumber[i][1], mjTileSpr)
				mjTileSpr:setPosition(groupMjTilesPos[i])
				groupNode:addChild(mjTileSpr)
			end
			mjTilesReferPos.groupStartPos = cc.pAdd(mjTilesReferPos.groupStartPos, mjTilesReferPos.groupSpace)
			mjTilesReferPos.holdStart = cc.pAdd(mjTilesReferPos.holdStart, mjTilesReferPos.groupSpace)

			-- 更新持有牌
			self:removeHoldMjTiles(roomPlayer, mjColor, mjNumber[1][1], 1)
			self:removeHoldMjTiles(roomPlayer, mjColor, mjNumber[3][1], 1)
		else
			for i = 1, mjTilesCount do
				local mjTileName = string.format("p%ds%d_%d.png", roomPlayer.displayIdx, mjColor, mjNumber)
				if isBar and not isBrightBar and i <= 3 then
					-- 暗杠前三张牌扣着
					mjTileName = string.format("tdbgs_%d.png", roomPlayer.displayIdx)
				end
				local mjTileSpr = cc.Sprite:createWithSpriteFrameName(mjTileName)
				
				if isBar and not isBrightBar and i <= 3 then
				else 
					self:showflag(roomPlayer, mjColor, mjNumber, mjTileSpr)
				end
				mjTileSpr:setPosition(groupMjTilesPos[i])
				groupNode:addChild(mjTileSpr)
			end
			mjTilesReferPos.groupStartPos = cc.pAdd(mjTilesReferPos.groupStartPos, mjTilesReferPos.groupSpace)
			mjTilesReferPos.holdStart = cc.pAdd(mjTilesReferPos.holdStart, mjTilesReferPos.groupSpace)

			-- 更新持有牌
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
			self:removeHoldMjTiles(roomPlayer, mjColor, mjNumber, mjTilesCount)
		end
	-- end

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
function PlayManager:changePungToBrightBar(seatIdx, mjColor, mjNumber)
	local roomPlayer = self.roomPlayers[seatIdx]
	-- 从持有牌中移除
	self:removeHoldMjTiles(roomPlayer, mjColor, mjNumber, 1)

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

	-- 添加到明杠列表
	if brightBarData then
		-- 加入杠牌第4个牌
		local mjTilesReferPos = roomPlayer.mjTilesReferPos
		local groupMjTilesPos = mjTilesReferPos.groupMjTilesPos
		local mjTileName = string.format("p%ds%d_%d.png", roomPlayer.displayIdx, mjColor, mjNumber)
		local mjTileSpr = cc.Sprite:createWithSpriteFrameName(mjTileName)
		self:showflag(roomPlayer, mjColor, mjNumber, mjTileSpr)
		mjTileSpr:setPosition(groupMjTilesPos[4])
		brightBarData.groupNode:addChild(mjTileSpr)
		table.insert(roomPlayer.mjTileBrightBars, brightBarData)
	end
end

function PlayManager:showflag(roomPlayer, mjColor, mjNumber, mjTileSpr)
	gt.log("##########" .. self.Gametype)
	if self.Gametype ~= 1 and self.Gametype ~= 4 then
		return
	end
	if self.turnCard and #self.turnCard > 0 then
		local turnTile = nil
		if #self.turnCard > 2 and self.playType  == 2 then
			if  (mjColor == self.turnCard[1][1] and mjNumber == self.turnCard[1][2]) or (mjColor == self.turnCard[2][1] and  mjNumber == self.turnCard[2][2]) or (mjColor == self.turnCard[3][1] and mjNumber == self.turnCard[3][2]) or (mjColor == self.turnCard[4][1] and mjNumber == self.turnCard[4][2]) then
				dump(roomPlayer)
				self:showMjFlag(turnTile, roomPlayer, mjColor, mjNumber, mjTileSpr)
			end
		elseif #self.turnCard > 2 and self.playType  == 5 then
			if  (mjColor == self.turnCard[1][1] and mjNumber == self.turnCard[1][2]) or (mjColor == self.turnCard[2][1] and  mjNumber == self.turnCard[2][2])  then
				self:showMjFlag(turnTile, roomPlayer, mjColor, mjNumber, mjTileSpr)
			end

			if mjColor == self.turnCard[3][1] and (self.turnCard[3][1] == 4 or self.turnCard[3][1] == 5)then
				self:showMjFlag(turnTile, roomPlayer, mjColor, mjNumber, mjTileSpr)
			elseif (mjNumber == self.turnCard[3][2] or mjNumber == self.turnCard[4][2]) and self.turnCard[3][1]~=4  and self.turnCard[3][1] ~= 5 and mjColor ~= 4 and mjColor ~= 5 then
				self:showMjFlag(turnTile, roomPlayer, mjColor, mjNumber, mjTileSpr)
			end

		else -- 无下精
			if (mjColor == self.turnCard[1][1] and mjNumber == self.turnCard[1][2]) or (mjColor == self.turnCard[2][1] and  mjNumber == self.turnCard[2][2]) then
				gt.log("======33333===" .. mjColor .. mjNumber, roomPlayer.displaySeatIdx)
				dump(roomPlayer)
				self:showMjFlag(turnTile, roomPlayer, mjColor, mjNumber, mjTileSpr)
			end
		end
	end
end


function PlayManager:showMjFlag(turnTile,roomPlayer, mjColor, mjNumber, mjTileSpr)

	 if roomPlayer.displayIdx == 1 then
		turnTile = cc.Sprite:create("images/otherImages/sanjiao1.png")
		turnTile:setPosition(cc.p(turnTile:getContentSize().width / 2, mjTileSpr:getContentSize().height - turnTile:getContentSize().height / 2))
	elseif roomPlayer.displayIdx == 2 then
		turnTile = cc.Sprite:create("images/otherImages/sanjiao2.png")
		turnTile:setPosition(cc.p(turnTile:getContentSize().width / 2,turnTile:getContentSize().height / 2))
	elseif roomPlayer.displayIdx == 3 then
		turnTile = cc.Sprite:create("images/otherImages/sanjiao3.png")
		turnTile:setPosition(cc.p(mjTileSpr:getContentSize().width - turnTile:getContentSize().width / 2, turnTile:getContentSize().height / 2))
	elseif roomPlayer.displayIdx == 4 then	
		turnTile = cc.Sprite:create("images/otherImages/s_sanjiao.png")
		turnTile:setPosition(cc.p(mjTileSpr:getContentSize().width - turnTile:getContentSize().width / 2, mjTileSpr:getContentSize().height - turnTile:getContentSize().height / 2))
	end


	mjTileSpr:addChild(turnTile)
end
-- start --
--------------------------------
-- @class function
-- @description 移除上家被下家，杠打出的牌
-- end --
function PlayManager:removePrePlayerOutMjTile()
	-- 移除上家打出的牌
	if self.prePlaySeatIdx then
		local roomPlayer = self.roomPlayers[self.prePlaySeatIdx]
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
-- @description 显示玩家接炮胡，自摸胡，明杠，暗杠，碰动画显示
-- @param seatIdx 座位索引
-- @param decisionType 决策类型
-- end --
function PlayManager:showDecisionAnimation(seatIdx, decisionType)
	-- if self.playType == gt.RoomType.ROOM_CHANGSHA then
		gt.log("出牌类型是：")
		gt.log(decisionType)
		-- 接炮胡，自摸胡，明杠，暗杠，碰文件后缀
		local decisionSuffixs = {1, 4, 2, 2, 3, 5, 6, 6}
		local decisionSfx = {"hu", "zimo", "gang", "gang", "peng" ,"chi", "buzhang", "buzhang" }
		-- 显示决策标识
		local roomPlayer = self.roomPlayers[seatIdx]
		local decisionSignSpr = cc.Sprite:createWithSpriteFrameName(string.format("decision_sign_cs_%d.png", decisionSuffixs[decisionType]))
		decisionSignSpr:setPosition(roomPlayer.mjTilesReferPos.showMjTilePos)
		self.rootNode:addChild(decisionSignSpr, gt.PlayZOrder.DECISION_SHOW)
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
		if decisionType == gt.DecisionType.BRIGHT_BAR then
			if not self.brightBarAnimateNode then
				local brightBarAnimateNode, brightBarAnimate = gt.createCSAnimation("animation/BrightBar.csb")
				self.brightBarAnimateNode = brightBarAnimateNode
				self.brightBarAnimate = brightBarAnimate
				self.rootNode:addChild(brightBarAnimateNode, gt.PlayZOrder.MJBAR_ANIMATION)
			end
			self.brightBarAnimate:play("run", false)
		elseif decisionType == gt.DecisionType.DARK_BAR then
			if not self.darkBarAnimateNode then
				local darkBarAnimateNode, darkBarAnimate = gt.createCSAnimation("animation/DarkBar.csb")
				self.darkBarAnimateNode = darkBarAnimateNode
				self.darkBarAnimate = darkBarAnimate
				self.rootNode:addChild(darkBarAnimateNode, gt.PlayZOrder.MJBAR_ANIMATION)
			end
			self.darkBarAnimate:play("run", false)
		end

		-- dj revise
		gt.soundManager:PlaySpeakSound(roomPlayer.sex, decisionSfx[decisionType])
		-- -- 播放音效
		if roomPlayer.sex == 1 then
			-- 男性
			gt.soundEngine:playEffect(string.format("changsha/man/%s", decisionSfx[decisionType]))
		else
			-- 女性
			gt.soundEngine:playEffect(string.format("changsha/woman/%s", decisionSfx[decisionType]))
		end
	-- else
	-- 	local roomPlayer = self.roomPlayers[seatIdx]

	-- 	if decisionType == 7 then
	-- 		decisionType = 3
	-- 	end
	-- 	if decisionType == 8 then
	-- 		decisionType = 4
	-- 	end
	-- 	-- 接炮胡，自摸胡，明杠，暗杠，碰文件后缀
	-- 	local decisionSuffixs = {1, 4, 2, 2, 3}
	-- 	local decisionSfx = {"hu", "zimo", "gang", "angang", "peng"}
	-- 	-- 显示决策标识
	-- 	local decisionSignSpr = cc.Sprite:createWithSpriteFrameName(string.format("decision_sign_%d.png", decisionSuffixs[decisionType]))
	-- 	decisionSignSpr:setPosition(roomPlayer.mjTilesReferPos.showMjTilePos)
	-- 	self.rootNode:addChild(decisionSignSpr, gt.PlayZOrder.DECISION_SHOW)
	-- 	-- 标识显示动画
	-- 	decisionSignSpr:setScale(0)
	-- 	local scaleToAction = cc.ScaleTo:create(0.2, 1)
	-- 	local easeBackAction = cc.EaseBackOut:create(scaleToAction)
	-- 	local fadeOutAction = cc.FadeOut:create(0.5)
	-- 	local callFunc = cc.CallFunc:create(function(sender)
	-- 		-- 播放完后移除
	-- 		sender:removeFromParent()
	-- 	end)
	-- 	local seqAction = cc.Sequence:create(easeBackAction, fadeOutAction, callFunc)
	-- 	decisionSignSpr:runAction(seqAction)

	-- 	-- 播放全屏动画
	-- 	if decisionType == gt.DecisionType.BRIGHT_BAR then
	-- 		if not self.brightBarAnimateNode then
	-- 			local brightBarAnimateNode, brightBarAnimate = gt.createCSAnimation("animation/BrightBar.csb")
	-- 			self.brightBarAnimateNode = brightBarAnimateNode
	-- 			self.brightBarAnimate = brightBarAnimate
	-- 			self.rootNode:addChild(brightBarAnimateNode, gt.PlayZOrder.MJBAR_ANIMATION)
	-- 		end
	-- 		self.brightBarAnimate:play("run", false)
	-- 	elseif decisionType == gt.DecisionType.DARK_BAR then
	-- 		if not self.darkBarAnimateNode then
	-- 			local darkBarAnimateNode, darkBarAnimate = gt.createCSAnimation("animation/DarkBar.csb")
	-- 			self.darkBarAnimateNode = darkBarAnimateNode
	-- 			self.darkBarAnimate = darkBarAnimate
	-- 			self.rootNode:addChild(darkBarAnimateNode, gt.PlayZOrder.MJBAR_ANIMATION)
	-- 		end
	-- 		self.darkBarAnimate:play("run", false)
	-- 	end

	-- 	-- dj revise
	-- 	gt.soundManager:PlaySpeakSound(roomPlayer.sex, decisionSfx[decisionType])

	-- 	-- -- 播放音效
	-- 	if roomPlayer.sex == 1 then
	-- 		-- 男性
	-- 		gt.soundEngine:playEffect(string.format("man/%s", decisionSfx[decisionType]))
	-- 	else
	-- 		-- 女性
	-- 		gt.soundEngine:playEffect(string.format("woman/%s", decisionSfx[decisionType]))
	-- 	end
	-- end
end

-- start --
--------------------------------
-- @class function
-- @description 展示杠两张牌
-- end --
function PlayManager:showBarTwoCardAnimation(seatIdx,cardList)
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
	self.rootNode:addChild(image_bg,gt.PlayZOrder.HAIDILAOYUE)
	image_bg:setScale(0)
	-- 设置坐标位置
	local  m_curPos_x = 1
	local  m_curPos_y = 1
	if roomPlayer.displayIdx == 1 or roomPlayer.displayIdx == 3 then
		m_curPos_x = roomPlayer.mjTilesReferPos.holdStart.x
		m_curPos_y = roomPlayer.mjTilesReferPos.showMjTilePos.y
	elseif roomPlayer.displayIdx == 2 or roomPlayer.displayIdx == 4 then
		m_curPos_x = roomPlayer.mjTilesReferPos.showMjTilePos.x
		m_curPos_y = roomPlayer.mjTilesReferPos.showMjTilePos.y
	end

	-- image_bg:setPosition(roomPlayer.mjTilesReferPos.showMjTilePos)
	image_bg:setPosition(cc.p(m_curPos_x,m_curPos_y))

	-- 添加两个麻将
	gt.log("添加两个麻将")
	dump(cardList)
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

function PlayManager:discardsOneCard(seatIdx,mjColor,mjNumber)
	gt.log("先出一张牌")
	-- gt.log(seatIdx)
	-- gt.log(mjColor)
	-- gt.log(mjNumber)
	local roomPlayer = self.roomPlayers[seatIdx]
	-- gt.log("roomPlayer")
	-- dump(roomPlayer)
	local mjTilesReferPos = roomPlayer.mjTilesReferPos
	-- gt.log("mjTilesReferPos")
	-- dump(mjTilesReferPos)
	local mjTilePos = mjTilesReferPos.holdStart
	-- gt.log("mjTilePos")
	-- dump(mjTilePos)
	-- print(mjTilesReferPos.holdSpace)
	-- print(roomPlayer.mjTilesRemainCount)
	-- local realpos = cc.pAdd(mjTilePos, cc.pMul(mjTilesReferPos.holdSpace, roomPlayer.mjTilesRemainCount))

	-- gt.log("realpos")
	-- dump(realpos)
	-- 显示出的牌
	self:outMjTile(roomPlayer, mjColor, mjNumber)
	-- 显示出的牌箭头标识
	self:showOutMjtileSign(roomPlayer)

	-- 记录出牌的上家
	self.preShowSeatIdx = seatIdx

	-- dj revise
	gt.soundManager:PlayCardSound(roomPlayer.sex, mjColor, mjNumber)

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
function PlayManager:showStartDecisionAnimation(seatIdx, decisionType, showCard)
	-- 接炮胡，自摸胡，明杠，暗杠，碰文件后缀
	local decisionSuffixs = {1, 4, 2, 2, 3}
	local decisionSfx = {"queyise", "banbanhu", "sixi", "liuliushun"}
	-- 显示决策标识
	local roomPlayer = self.roomPlayers[seatIdx]
	local decisionSignSpr = cc.Sprite:createWithSpriteFrameName(string.format("tile_cs_%s.png", decisionSfx[decisionType]))
	decisionSignSpr:setPosition(roomPlayer.mjTilesReferPos.showMjTilePos)
	self.rootNode:addChild(decisionSignSpr, gt.PlayZOrder.DECISION_SHOW)
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

	-- 展示起手胡牌型
	local copyNum = 1
	if decisionType == gt.StartDecisionType.TYPE_QUEYISE then
		copyNum = 1
	elseif decisionType == gt.StartDecisionType.TYPE_BANBANHU then
		copyNum = 1
	elseif decisionType == gt.StartDecisionType.TYPE_DASIXI then
		copyNum = 4
	elseif decisionType == gt.StartDecisionType.TYPE_LIULIUSHUN then
		copyNum = 3
	end

	local groupNode = cc.Node:create()
	groupNode:setCascadeOpacityEnabled( true )
	groupNode:setPosition( roomPlayer.mjTilesReferPos.showMjTilePos )
	self.playMjLayer:addChild(groupNode)

	local mjTilesReferPos = roomPlayer.mjTilesReferPos
	local demoSpr = cc.Sprite:createWithSpriteFrameName(string.format("p%ds%d_%d.png", roomPlayer.displayIdx, 1, 1))
	local tileWidthX = 0
	local tileWidthY = 0
	if roomPlayer.displayIdx == 1 then
		tileWidthX = 0
		tileWidthY = mjTilesReferPos.outSpaceH.y--demoSpr:getContentSize().height
	elseif roomPlayer.displayIdx == 2 then
		tileWidthX = -demoSpr:getContentSize().width
		tileWidthY = 0
	elseif roomPlayer.displayIdx == 3 then
		tileWidthX = 0
		tileWidthY = -mjTilesReferPos.outSpaceH.y--demoSpr:getContentSize().height
	elseif roomPlayer.displayIdx == 4 then
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
		local mjTileName = string.format("p%ds%d_%d.png", roomPlayer.displayIdx, v[1], v[2])
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
	-- dj revise
	gt.soundManager:PlaySpeakSound(roomPlayer.sex, decisionSfx[decisionType])
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
-- @description 显示指示出牌标识箭头动画
-- @param seatIdx 座次
-- end --
function PlayManager:showOutMjtileSign(roomPlayer)
	-- local roomPlayer = self.roomPlayers[seatIdx]
	local endIdx = #roomPlayer.outMjTiles
	local outMjTile = roomPlayer.outMjTiles[endIdx]
	self.outMjtileSignNode:setVisible(true)
	self.outMjtileSignNode:setPosition(outMjTile.mjTileSpr:getPosition())
end

-- start --
--------------------------------
-- @class function
-- @description 显示出牌动画
-- @param seatIdx 座次
-- end --
function PlayManager:showOutMjTileAnimation(roomPlayer, mjColor, mjNumber, cbFunc)
	local rotateAngle = {-90, 180, 90, 0}

	local mjTileName = string.format("p4s%d_%d.png", mjColor, mjNumber)
	local mjTileSpr = cc.Sprite:createWithSpriteFrameName(mjTileName)
	self.rootNode:addChild(mjTileSpr, 98)

	-- 出牌位置
	local mjTilesReferPos = roomPlayer.mjTilesReferPos
	local mjTilePos = mjTilesReferPos.holdStart
	mjTilePos = cc.pAdd(mjTilePos, cc.pMul(mjTilesReferPos.holdSpace, #roomPlayer.holdMjTiles))
	mjTilePos = cc.pAdd(mjTilePos, mjTilesReferPos.drawSpace)
	mjTileSpr:setPosition(mjTilePos)
	mjTileSpr:setRotation(rotateAngle[roomPlayer.displayIdx])
	local moveToAc_1 = cc.MoveTo:create(0.3, roomPlayer.mjTilesReferPos.showMjTilePos)
	local rotateToAc_1 = cc.RotateTo:create(0.15, 0)

	local delayTime = cc.DelayTime:create(0.3)

	local mjTilesReferPos = roomPlayer.mjTilesReferPos
	local mjTilePos = mjTilesReferPos.outStart
	local mjTilesCount = #roomPlayer.outMjTiles + 1
	local lineCount = math.ceil(mjTilesCount / 10) - 1
	local lineIdx = mjTilesCount - lineCount * 10 - 1
	mjTilePos = cc.pAdd(mjTilePos, cc.pMul(mjTilesReferPos.outSpaceV, lineCount))
	mjTilePos = cc.pAdd(mjTilePos, cc.pMul(mjTilesReferPos.outSpaceH, lineIdx))

	local moveToAc_2 = cc.MoveTo:create(0.3, mjTilePos)
	local rotateToAc_2 = cc.RotateTo:create(0.15, rotateAngle[roomPlayer.displayIdx])
	local callFunc = cc.CallFunc:create(function(sender)
		sender:removeFromParent()

		cbFunc()
	end)
	mjTileSpr:runAction(cc.Sequence:create(cc.Spawn:create(moveToAc_1, rotateToAc_1),
										delayTime,
										cc.Spawn:create(moveToAc_2, rotateToAc_2),
										callFunc));
end

return PlayManager

