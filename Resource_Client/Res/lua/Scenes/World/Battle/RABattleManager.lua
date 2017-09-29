local RABattleManager =
{
	mRootNode = nil,
	battleMap = {}
}

local RABattleEntity = RARequire('RABattleEntity')

function RABattleManager:Init(rootNode)
	self.mRootNode = rootNode
end

function RABattleManager:Execute()
	for _, entity in pairs(self.battleMap) do
		if entity then
			entity:Execute()
		end
	end
end

function RABattleManager:Clear()
	for _, entity in pairs(self.battleMap) do
		if entity then
			entity:Clear()
		end
	end
	self.battleMap = {}
end

function RABattleManager:Remove(marchId)
	self.battleMap[marchId] = nil
end

function RABattleManager:onBattleRsp(attackerInfo, defenserInfo, isAttackerWin, isDefenserDead, marchId)
	if self.battleMap[marchId] then return end

	local result =
	{
		attacker = attackerInfo,
		defenser = defenserInfo,
		isAttackerWin = isAttackerWin,
		isDefenserDead = isDefenserDead
	}
	local battleEntity = RABattleEntity:new(self.mRootNode, marchId, result)
	
	self.battleMap[marchId] = battleEntity
	
	-- get info from march
	local RAMarchManager = RARequire('RAMarchManager')
	local endPos, tilePos = RAMarchManager:GetMarchMovePos(marchId)

	-- TODO
	-- if tilePos == nil then return end

	battleEntity:Fight(tilePos, endPos, startPos)
end

return RABattleManager