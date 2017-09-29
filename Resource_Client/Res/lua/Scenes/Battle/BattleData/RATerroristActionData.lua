--pb数据存储
RARequire('extern')
local RABattleActionData = RARequire('RABattleActionData')
local RATerroristActionData = class('RATerroristActionData',RABattleActionData)

function RATerroristActionData:initByPb(pb)
	self.super.initByPb(self,pb)
    self.targetId = pb.terrorist.targetId
end

return RATerroristActionData