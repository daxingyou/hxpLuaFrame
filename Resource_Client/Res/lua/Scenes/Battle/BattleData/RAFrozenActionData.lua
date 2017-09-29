--pb数据存储
RARequire('extern')
local RABattleActionData = RARequire('RABattleActionData')
local RAFrozenActionData = class('RAFrozenActionData',RABattleActionData)

function RAFrozenActionData:initByPb(pb)
	self.super.initByPb(self,pb)
    self.targetId = pb.frozen.targetId
end

return RAFrozenActionData