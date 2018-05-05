
local gt = cc.exports.gt

local ReadyPlay = class("ReadyPlay")

function ReadyPlay:ctor(csbNode, paramTbl, cardType)
	gt.cardType = cardType
	self.isRoomCreater = false
	if paramTbl.playerSeatPos == 0 then
		-- 0位置是房主
		self.isRoomCreater = true
	end

	-- 房间号
	self.roomID = paramTbl.roomID

	-- 准备节点（子节点：邀请好友，解散房间，返回大厅）
	local readyPlayNode = gt.seekNodeByName(csbNode, "Node_readyPlay")

	-- 邀请好友
	local inviteFriendBtn = gt.seekNodeByName(readyPlayNode, "Btn_inviteFriend")
	gt.addBtnPressedListener(inviteFriendBtn, function()
		local description = ""
		--if gt.roomType ~= gt.RoomType.ROOM_CHANGSHA then -- 转转麻将
			--description = string.format("【转转麻将】房号:[%d]，%d局，%s，速度来玩吧!", self.roomID, paramTbl.roundMaxCount, paramTbl.playTypeDesc)
		--else -- 长沙麻将
		local playname = ""
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
			description = string.format("%s，%s，%s，%s，%s玩法!",dianpao,bawang,qjname,difen,ncname)
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
			
			description = string.format("%s，%s玩法!",fanshu,lanjie)
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
			description = string.format("%s，萍乡258玩法!",difen)
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

			local ganzhou_playType = ""
			if tonumber(paramTbl.m_ncPlayType) == 1 then
				ganzhou_playType = "上下翻精"
			elseif tonumber(paramTbl.m_ncPlayType) == 2 then
				ganzhou_playType = "上下左右翻"
			end

			description = string.format("%s，%s，%s，%s玩法!", dianpao,fanshu,liuju,ganzhou_playType)
		elseif tonumber(paramTbl.totulType) == 5 then
			playname = "赣州三人"
			local ganzhou_playType = ""
			if tonumber(paramTbl.m_ncPlayType) == 1 then
				ganzhou_playType = "上下翻精"
			elseif tonumber(paramTbl.m_ncPlayType) == 2 then
				ganzhou_playType = "上下左右翻"
			end
			local liuju = ""
			if tonumber(paramTbl.m_zhuangAddFive) == 1 then
				liuju = "流局+5"
			end
			description = string.format("%s，%s玩法!", liuju,ganzhou_playType)
		end

		local  wxtitle = string.format("%s,房号：%d(%d局)",playname,self.roomID, paramTbl.roundMaxCount)

		--end

		-- local description = string.format("房号:[%d]%d局%s速度来啊! 闲来麻将", self.roomID, paramTbl.roundMaxCount, paramTbl.playTypeDesc)
		if gt.isIOSPlatform() then
			local luaoc = require("cocos/cocos2d/luaoc")
			local ok = luaoc.callStaticMethod("AppController", "shareURLToWX",
				{url = gt.shareWeb, title = wxtitle, description = description})
		elseif gt.isAndroidPlatform() then
			local luaj = require("cocos/cocos2d/luaj")
			local ok = luaj.callStaticMethod("org/cocos2dx/lua/AppActivity", "shareURLToWX",
				{gt.shareWeb, wxtitle, description},
				"(Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;)V")
		end
	end)

	if gt.isIOSPlatform() and gt.isInReview then
		inviteFriendBtn:setVisible(false)
	else
		inviteFriendBtn:setVisible(true)
	end

	-- 返回大厅
	local backSalaBtn = gt.seekNodeByName(readyPlayNode, "Btn_outRoom")
	gt.addBtnPressedListener(backSalaBtn, function()
		-- 返回大厅提示
		local tipsContentKey = "LTKey_0019"
		if self.isRoomCreater then
			tipsContentKey = "LTKey_0010"
		end
		require("app/views/NoticeTips"):create(
			gt.getLocationString("LTKey_0009"),
			gt.getLocationString(tipsContentKey),
			function()
				gt.showLoadingTips(gt.getLocationString("LTKey_0016"))

				local msgToSend = {}
				msgToSend.m_msgId = gt.CG_QUIT_ROOM
				msgToSend.m_pos = paramTbl.playerSeatPos
				gt.socketClient:sendMessage(msgToSend)
			end)
	end)
	gt.socketClient:registerMsgListener(gt.GC_QUIT_ROOM, self, self.onRcvQuitRoom)

	-- 解散房间
	local dimissRoomBtn = gt.seekNodeByName(readyPlayNode, "Btn_dimissRoom")

	local ls_12 = gt.getLocationString("LTKey_0012")
	if gt.isIOSPlatform() and gt.isInReview then
		ls_12 = gt.getLocationString("LTKey_0012_1")
	end

	gt.addBtnPressedListener(dimissRoomBtn, function()
		require("app/views/NoticeTips"):create(
			gt.getLocationString("LTKey_0011"),
			ls_12,
			function()
				local msgToSend = {}
				msgToSend.m_msgId = gt.CG_DISMISS_ROOM
				msgToSend.m_pos = paramTbl.playerSeatPos
				gt.socketClient:sendMessage(msgToSend)
			end)
	end)
	gt.socketClient:registerMsgListener(gt.GC_DISMISS_ROOM, self, self.onRcvDismissRoom)

	-- 隐藏非房主无法操作的按钮
	if not self.isRoomCreater then
		dimissRoomBtn:setVisible(false)
	end
end

-- start --
--------------------------------
-- @class function
-- @description 返回大厅
-- end --
function ReadyPlay:onRcvQuitRoom(msgTbl)
	gt.removeLoadingTips()

	if msgTbl.m_errorCode == 0 then
		gt.dispatchEvent(gt.EventType.BACK_MAIN_SCENE, self.isRoomCreater, self.roomID)
	else
		-- 提示返回大厅失败
		require("app/views/NoticeTips"):create(gt.getLocationString("LTKey_0007"), gt.getLocationString("LTKey_0045"), nil, nil, true)
	end
end

-- start --
--------------------------------
-- @class function
-- @description 房间创建者解散房间
-- end --
function ReadyPlay:onRcvDismissRoom(msgTbl)
	if msgTbl.m_errorCode == 1 then
		-- 游戏未开始解散成功
		gt.dispatchEvent(gt.EventType.BACK_MAIN_SCENE)
	else
		-- 游戏中玩家申请解散房间
		gt.log("解散房间--------------------")
		gt.dispatchEvent(gt.EventType.APPLY_DIMISS_ROOM, msgTbl)
	end
end

return ReadyPlay


