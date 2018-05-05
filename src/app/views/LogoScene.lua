
local gt = cc.exports.gt

local LogoScene = class("LogoScene", function()
	return cc.Scene:create()
end)


function LogoScene:ctor()
	-- 注册节点事件
	self:registerScriptHandler(handler(self, self.onNodeEvent))
end

function LogoScene:onNodeEvent(eventName)
	if "enter" == eventName then
		if gt.isAndroidPlatform() then
			local delayAction = cc.FadeIn:create(1)
			local fadeOutAction = cc.FadeOut:create(1)
			local callFunc = cc.CallFunc:create(function(sender)
				-- 动画播放完毕之后再走这些内容
				if gt.localVersion then
					local loginScene = require("app/views/LoginScene"):create()
					cc.Director:getInstance():replaceScene(loginScene)
				else
					local updateScene = require("app/views/UpdateScene"):create()
					cc.Director:getInstance():replaceScene(updateScene)
				end

				-- 30s启动Lua垃圾回收器
				gt.scheduler:scheduleScriptFunc(function(delta)
					local preMem = collectgarbage("count")
					-- 调用lua垃圾回收器
					for i = 1, 3 do
						collectgarbage("collect")
					end
					local curMem = collectgarbage("count")
					gt.log(string.format("Collect lua memory:[%d] cur cost memory:[%d]", (curMem - preMem), curMem))
					local luaMemLimit = 30720
					if curMem > luaMemLimit then
						gt.log("Lua memory limit exceeded!")
					end
				end, 30, false)
			end)
			local seqAction = cc.Sequence:create(delayAction, fadeOutAction, callFunc)
			local logoSpr = cc.Sprite:create("res/sd/images/otherImages/logo.jpg")
			logoSpr:runAction(seqAction)
			self:addChild( logoSpr )
			logoSpr:setPosition( display.cx, display.cy )
		else
			-- 动画播放完毕之后再走这些内容
			if gt.localVersion then
				local loginScene = require("app/views/LoginScene"):create()
				cc.Director:getInstance():replaceScene(loginScene)
			else
				local updateScene = require("app/views/UpdateScene"):create()
				cc.Director:getInstance():replaceScene(updateScene)
			end

			-- 30s启动Lua垃圾回收器
			gt.scheduler:scheduleScriptFunc(function(delta)
				local preMem = collectgarbage("count")
				-- 调用lua垃圾回收器
				for i = 1, 3 do
					collectgarbage("collect")
				end
				local curMem = collectgarbage("count")
				gt.log(string.format("Collect lua memory:[%d] cur cost memory:[%d]", (curMem - preMem), curMem))
				local luaMemLimit = 30720
				if curMem > luaMemLimit then
					gt.log("Lua memory limit exceeded!")
				end
			end, 30, false)
		end
	end
end


return LogoScene


