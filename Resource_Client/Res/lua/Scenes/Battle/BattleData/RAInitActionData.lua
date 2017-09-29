--pb数据存储
RARequire('extern')
local RABattleActionData = RARequire('RABattleActionData')
local RAInitActionData = class('RAInitActionData',RABattleActionData)


function RAInitActionData:initByPb(pb)
	self.super.initByPb(self,pb)
	self.pos = RACcp(pb.init.pos.x,pb.init.pos.y)
end

return RAInitActionData