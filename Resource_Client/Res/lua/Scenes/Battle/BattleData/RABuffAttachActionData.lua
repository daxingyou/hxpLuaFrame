--pb数据存储
RARequire('extern')
local RABattleActionData = RARequire('RABattleActionData')
local RABuffAttachActionData = class('RABuffAttachActionData',RABattleActionData)


function RABuffAttachActionData:initByPb(pb)
	self.super.initByPb(self,pb)
	self.buff = pb.buffAttach.buff
	self.period = pb.buffAttach.period
end

return RABuffAttachActionData