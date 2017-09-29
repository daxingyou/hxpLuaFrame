--pb数据存储
RARequire('extern')
local RABattleActionData = RARequire('RABattleActionData')
local RASkillPointSyncActionData = class('RASkillPointSyncActionData',RABattleActionData)

function RASkillPointSyncActionData:initByPb(pb)
	self.super.initByPb(self,pb)
	
	self.troopType = pb.skillPointSync.troopType
	self.skillPoint = pb.skillPointSync.skillPoint
end

return RASkillPointSyncActionData