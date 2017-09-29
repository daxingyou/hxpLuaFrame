--pb数据存储
RARequire('extern')
local RABattleActionData = RARequire('RABattleActionData')
local RAFinishActionData = class('RAFinishActionData',RABattleActionData)


function RAFinishActionData:initByPb(pb)
	self.super.initByPb(self,pb)
	self.winTroop = pb.finish.winTroop
end

return RAFinishActionData