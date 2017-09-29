--pb数据存储
RARequire('extern')
local RABattleActionData = RARequire('RABattleActionData')
local RADeadActionData = class('RADeadActionData',RABattleActionData)


function RADeadActionData:initByPb(pb)
	self.super.initByPb(self,pb)
	self.count = pb.dead.count
	self.hp = pb.dead.hp
end

return RADeadActionData