local RABattleEndState =
{
	fightInfo = nil
}

local UIExtend = RARequire('UIExtend')
local RABattleConfig = RARequire('RABattleConfig')
local common = RARequire('common')

function RABattleEndState:new(owner)
	local o = {}

    setmetatable(o, self)
    self.__index = self

    o.owner = owner
    
    return o
end

function RABattleEndState:Enter(fightInfo)
	self.fightInfo = fightInfo
	local isAttackerWin = fightInfo.result.isAttackerWin
	if isAttackerWin then
		self:_attackerWin(fightInfo)
	else
		self:_attackerLose()
	end
	self.owner:Exit()
end

function RABattleEndState:Exit()
	local stanceNode = self.fightInfo.stanceNode
	if stanceNode then
		stanceNode:removeFromParentAndCleanup(true)
	end
	self.fightInfo.attacker:Destroy()
	self.fightInfo.defenser:Destroy()
end

function RABattleEndState:_attackerWin(fightInfo)
	-- local targetPos = fightInfo.target.viewPos
	-- local parentNode = fightInfo.fightLayer

	-- local ccbName = RABattleConfig.Explode_CCBFile[fightInfo.battleType]
	-- if ccbName then
	-- 	local explodeNode = UIExtend.loadCCBFile(ccbName, {
	-- 		owner = self.owner,
	-- 		OnAnimationDone = function (self, node)
	-- 			node:removeFromParentAndCleanup(true)
	-- 			if self.owner then
	-- 				self.owner:Exit()
	-- 			end
	-- 		end
	-- 	})
	-- 	explodeNode:setPosition(targetPos.x, targetPos.y)
	-- 	parentNode:addChild(explodeNode)

	-- 	common:playEffect(RABattleConfig.SoundEffect_Result.Explode)
	-- end
		
	-- local RAWorldBuildingManager = RARequire('RAWorldBuildingManager')
	-- RAWorldBuildingManager:changeBuildingState(fightInfo.target.mapPos, BUILDING_ANIMATION_TYPE.BROKEN_MAP)

	-- performWithDelay(explodeNode, function ()
	-- 	local burnNode = UIExtend.loadCCBFile(RABattleConfig.Burn_CCBFile, {
	-- 		OnAnimationDone = function (self, node)
	-- 		-- node:removeFromParentAndCleanup(true)
	-- 		end
	-- 	})
	-- 	burnNode:setPosition(targetPos.x, targetPos.y)
	-- 	parentNode:addChild(burnNode)

	-- end, 0.5)

	-- common:playEffect(RABattleConfig.SoundEffect_Result.Win)
	common:playEffect(RABattleConfig.SoundEffect_Result.Cheer)
end

function RABattleEndState:_attackerLose()
	-- body
end

return RABattleEndState