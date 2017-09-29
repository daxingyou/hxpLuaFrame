--pb数据存储
RARequire('extern')
local RABattleActionData = RARequire('RABattleActionData')
local RABuffDmgActionData = class('RABuffDmgActionData',RABattleActionData)


function RABuffDmgActionData:initByPb(pb)
	self.super.initByPb(self,pb)
	local RAUnitDamageData = RARequire('RAUnitDamageData')
	local damageData = RAUnitDamageData.new(pb.buffDmg.damage)

	self.buff = pb.buffDmg.buff
	self.damage = damageData
end

return RABuffDmgActionData