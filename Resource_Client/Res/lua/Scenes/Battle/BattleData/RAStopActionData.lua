--pb数据存储
RARequire('extern')
local RABattleActionData = RARequire('RABattleActionData')
local RAStopActionData = class('RAStopActionData',RABattleActionData)


function RAStopActionData:initByPb(pb)
	self.super.initByPb(self,pb)
	self.curPos = RACcp(pb.stop.curPos.x,pb.stop.curPos.y)
end

return RAStopActionData