--pb数据存储
RARequire('extern')
local RABattleActionData = RARequire('RABattleActionData')
local RADisappearActionData = class('RADisappearActionData',RABattleActionData)


function RADisappearActionData:initByPb(pb)
	self.super.initByPb(self,pb)
end

return RADisappearActionData