--pb数据存储
RARequire('extern')
local RABattleActionData = RARequire('RABattleActionData')
local RABuildingDisableActionData = class('RABuildingDisableActionData',RABattleActionData)

function RABuildingDisableActionData:initByPb(pb)
	self.super.initByPb(self,pb)
	self.troopType = pb.buildingDisable.troopType
end

return RABuildingDisableActionData