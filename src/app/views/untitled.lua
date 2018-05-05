unction PlaySceneCS:showGangShaizi(seatIdx，msgTbl, state)
	-- 杠牌动画
	gt.log("===========000000====" .. seatIdx)
	self:showDecisionAnimation(seatIdx, PlaySceneCS.DecisionType.BRIGHT_BAR)

	self.shaizi_number = 8
	local numberArr = {}
	for i = 1, 6 do 
		for j = 1, 6 do 
			if i + j == self.shaizi_number then
				local number = {}
				table.insert(number,i)
				table.insert(number,j)
				table.insert(numberArr,number)
			end
		end
	end
	gt.log("================5====" .. #numberArr)
	local finalNumber  = math.random(1,#numberArr)
	local first_number = numberArr[finalNumber][1]
	local second_number =  numberArr[finalNumber][2]
    gt.log("================5====" .. first_number .. second_number)
	
	
	local first_node = cc.Sprite:create()
	self.playMjLayer:addChild(first_node, 5)
	first_node:setPosition(gt.winSize.width / 2 - 80, gt.winSize.height / 2)
	local second_node = cc.Sprite:create()
	self.playMjLayer:addChild(second_node,5)
	second_node:setPosition(gt.winSize.width / 2 + 80, gt.winSize.height / 2)

	self:showMaskLayer()
	
	for j = 1 ,  2  do
		local animation = cc.Animation:create()
		local name = nil
		for i = 1, 10 do
			if i < 10 then
				name = "images/otherImages/shaizi/touzi_00" .. i .. ".png"
			else
				name = "images/otherImages/shaizi/touzi_0" .. i .. ".png"
			end
			animation:addSpriteFrameWithFile(name)
		end
		animation:setDelayPerUnit(2/20)
		animation:setRestoreOriginalFrame(true)
		animation:setLoops(2)
		local action = cc.Animate:create(animation)
	
		if j == 1 then
			first_node:runAction(action)
		elseif j == 2  then
			local function showShaiziCallBack( ... )
				first_node:removeFromParent()
				second_node:removeFromParent()
				
				local first_spr = cc.Sprite:create("images/otherImages/shaizi/touzi" .. first_number .. ".png")
				self.playMjLayer:addChild(first_spr, 5)
				first_spr:setPosition(gt.winSize.width / 2 - 80, gt.winSize.height / 2)
				local second_spr = cc.Sprite:create("images/otherImages/shaizi/touzi" .. second_number .. ".png")
				self.playMjLayer:addChild(second_spr,5)
				second_spr:setPosition(gt.winSize.width / 2 + 80, gt.winSize.height / 2)
				
				local function startPlayCardCallBack()
					first_spr:removeFromParent()
					second_spr:removeFromParent()
					self:hideMaskLayer()

					if state == 1 then

						if (next(msgTbl.m_think) ~= nil) then
							local  mj_color = msgTbl.m_think[1][1]
							local  mj_number = msgTbl.m_think[1][2]
							self:addMjTileBar(seatIdx, mj_color, mj_number, false)
							self:hideOtherPlayerMjTiles(seatIdx, true, false)
							--self:showDecisionAnimation(seatIdx, PlaySceneCS.DecisionType.DARK_BAR)
						end
					else
						 -- 明杠
						self:addMjTileBar(seatIdx, msgTbl.m_color, msgTbl.m_number, true)
						
						-- 隐藏持有牌中打出的牌
						self:hideOtherPlayerMjTiles(seatIdx, true, true)
						-- 移除上家打出的牌
						self:removePreRoomPlayerOutMjTile()
					end
				end
				self:runAction(cc.Sequence:create(cc.DelayTime:create(1), cc.CallFunc:create(startPlayCardCallBack)))
			end
			second_node:runAction(cc.Sequence:create(action,cc.CallFunc:create(showShaiziCallBack)))
		end
	end		
end