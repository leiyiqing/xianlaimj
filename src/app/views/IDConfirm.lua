
local gt = cc.exports.gt

local IDConfirm = class("IDConfirm", function()
	return cc.LayerColor:create(cc.c4b(85, 85, 85, 85), gt.winSize.width, gt.winSize.height)
end)

function IDConfirm:ctor()
	-- 注册节点事件
	self:registerScriptHandler(handler(self, self.onNodeEvent))

	local csbNode = cc.CSLoader:createNode("IDConfirm.csb")
	csbNode:setPosition(gt.winCenter)
	self:addChild(csbNode)
	self.rootNode = csbNode

	self.name = self.rootNode:getChildByName("name")
	self.id = self.rootNode:getChildByName("id")
	
	-- 关闭按钮
	local closeBtn = gt.seekNodeByName(csbNode, "Btn_close")
	gt.addBtnPressedListener(closeBtn, function()
		self:Remove()
	end)

	local submit = self.rootNode:getChildByName("confirm")
	gt.addBtnPressedListener(submit, function()
		local id = self.id:getString()
		if string.match(id,"%d+[Xx]?") ~= id or (#id ~= 15 and #id ~= 18) then
			require("app/views/NoticeTips"):create("提示", "身份证号填写错误!", nil, nil, true)
			return
		end
		-------------------------------------------
		local name = self.name:getString()
		local count = 0
		for v in name:gfind('[%z\1-\127\194-\244][\128-\191]*') do
			if #v == 1 then
				require("app/views/NoticeTips"):create("提示", "姓名格式填写错误!", nil, nil, true)
				return
			else
				count = count + 1
			end
		end
		if count <= 1 or count > 5 then
			require("app/views/NoticeTips"):create("提示", "姓名格式填写错误!", nil, nil, true)
			return
		end
		self:onRcv(id, name)
	end)
end

function IDConfirm:onRcv(id, name)
	cc.UserDefault:getInstance():setIntegerForKey("id_sure", 1)
	--cc.UserDefault:getInstance():setStringForKey("member_real_id", id)
	--cc.UserDefault:getInstance():setStringForKey("member_real_name", name)
	require("app/views/NoticeTips"):create("提示", "实名认证成功！", nil, nil, true)
	self:Remove()
end

function IDConfirm:Remove()
	self:removeFromParent()
	gt.dispatchEvent(gt.EventType.BACK_MAIN_SCENE)
end

function IDConfirm:onNodeEvent(eventName)
	if "enter" == eventName then
		local listener = cc.EventListenerTouchOneByOne:create()
		listener:setSwallowTouches(true)
		listener:registerScriptHandler(handler(self, self.onTouchBegan), cc.Handler.EVENT_TOUCH_BEGAN)
		local eventDispatcher = self:getEventDispatcher()
		eventDispatcher:addEventListenerWithSceneGraphPriority(listener, self)
	elseif "exit" == eventName then
		local eventDispatcher = self:getEventDispatcher()
		eventDispatcher:removeEventListenersForTarget(self)
	end
end

function IDConfirm:onTouchBegan(touch, event)
	return true
end

return IDConfirm



