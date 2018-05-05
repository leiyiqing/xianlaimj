
local gt = cc.exports.gt

local AgreementPanel = class("AgreementPanel", function()
	return cc.LayerColor:create(cc.c4b(85, 85, 85, 85), gt.winSize.width, gt.winSize.height)
end)

function AgreementPanel:ctor()
	-- 注册节点事件
	self:registerScriptHandler(handler(self, self.onNodeEvent))

	local csbNode = cc.CSLoader:createNode("AgreementPanel.csb")
	csbNode:setAnchorPoint(0.5, 0.5)
	csbNode:setPosition(gt.winCenter)
	self:addChild(csbNode)
	self.rootNode = csbNode

	local closeBtn = gt.seekNodeByName(csbNode, "Btn_close")
	gt.addBtnPressedListener(closeBtn, function()
		self:removeFromParent()
	end)
end

function AgreementPanel:onNodeEvent(eventName)
	if "enter" == eventName then
		local listener = cc.EventListenerTouchOneByOne:create()
		listener:setSwallowTouches(true)
		listener:registerScriptHandler(handler(self, self.onTouchBegan), cc.Handler.EVENT_TOUCH_BEGAN)
		local eventDispatcher = self:getEventDispatcher()
		eventDispatcher:addEventListenerWithSceneGraphPriority(listener, self)

		self:requestAgreement()
	elseif "exit" == eventName then
		local eventDispatcher = self:getEventDispatcher()
		eventDispatcher:removeEventListenersForTarget(self)

		if self.xhr then
			self.xhr:unregisterScriptHandler()
			self.xhr = nil
		end
	end
end

function AgreementPanel:onTouchBegan(touch, event)
	return true
end

function AgreementPanel:requestAgreement()
	local xhr = cc.XMLHttpRequest:new()
	xhr.responseType = cc.XMLHTTPREQUEST_RESPONSE_STRING
	xhr:open("GET", "http://www.ixianlai.com/client/jx_mahjongjx/agreement.txt")
	local function onReadyStateChanged()
		if xhr.readyState == 4 and (xhr.status >= 200 and xhr.status < 207) then
			-- gt.log(xhr.response)
		else
			gt.log("xhr.readyState is:" .. xhr.readyState .. " xhr.status is: " .. xhr.status)
		end
		xhr:unregisterScriptHandler()
		self.xhr = nil

		local agreementScrollVw = gt.seekNodeByName(self.rootNode, "ScrollVw_agreement")
		local scrollVwSize = agreementScrollVw:getContentSize()
		local agreementLabel = gt.createTTFLabel(xhr.response, 30)
		agreementLabel:setAnchorPoint(0.5, 1)
		agreementLabel:setVerticalAlignment(cc.VERTICAL_TEXT_ALIGNMENT_TOP)
		agreementLabel:setWidth(scrollVwSize.width)
		local labelSize = agreementLabel:getContentSize()
		agreementLabel:setPosition(scrollVwSize.width * 0.5, labelSize.height)
		agreementScrollVw:addChild(agreementLabel)
		agreementScrollVw:setInnerContainerSize(labelSize)
	end
	xhr:registerScriptHandler(onReadyStateChanged)
	xhr:send()

	self.xhr = xhr
end

return AgreementPanel

