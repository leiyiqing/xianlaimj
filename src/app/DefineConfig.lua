
local gt = cc.exports.gt

-- 测试服

gt.TestLoginServer		= {ip = "120.27.188.74", port = "5009"}
-- gt.TestLoginServer		= {ip = "192.168.62.22", port = "5003"}
-- 正式服
gt.LoginServer		= {ip = "120.27.188.74", port = "5009"}
-- gt.LoginServer		= {ip = "192.168.62.22", port = "5003"}

gt.GateServer		= {}


-- 通用弹出面板
gt.CommonZOrder = {
	LOADING_TIPS				= 66,
	NOTICE_TIPS					= 67,
	TOUCH_MASK					= 68
}

gt.PlayZOrder = {
	MJTABLE						= 1,
	PLAYER_INFO					= 2,
	MJTILES_LAYER				= 6,
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
	HAIDILAOYUE					= 23
}

gt.EventType = {
	NETWORK_ERROR				= 1,
	BACK_MAIN_SCENE				= 2,
	APPLY_DIMISS_ROOM			= 3,
	GM_CHECK_HISTORY			= 4,
}

gt.DecisionType = {
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
	--眀补
	BRIGHT_BU                   = 7,
	--暗补
	DARK_BU                     = 8
}

gt.StartDecisionType = {
	-- 缺一色
	TYPE_QUEYISE				= 1,
	-- 板板胡
	TYPE_BANBANHU				= 2,
	-- 四喜
	TYPE_DASIXI					= 3,
	-- 六六顺
	TYPE_LIULIUSHUN				= 4
}

gt.ChatType = {
	FIX_MSG						= 1,
	INPUT_MSG					= 2,
	EMOJI						= 3,
	VOICE_MSG					= 4,
}

gt.RoomType = {
	ROOM_ZHUANZHUAN				= 0,   --转转麻将
	ROOM_CHANGSHA				= 3	   --长沙麻将
}
