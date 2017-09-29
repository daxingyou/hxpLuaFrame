--pb数据存储
RARequire('extern')
local RABattleActionData = RARequire('RABattleActionData')
local RABombDamageActionData = class('RABombDamageActionData',RABattleActionData)


function RABombDamageActionData:initByPb(pb)
	self.super.initByPb(self,pb)
	
	local RAUnitDamageData = RARequire('RAUnitDamageData')
	self.damage = {}
	for i=1,#pb.bombDamage.damage do
		local damageData = RAUnitDamageData.new(pb.bombDamage.damage[i])
		self.damage[#self.damage+1] = damageData
	end
end

return RABombDamageActionData