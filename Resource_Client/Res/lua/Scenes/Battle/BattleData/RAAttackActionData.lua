--pb数据存储
RARequire('extern')
local RABattleActionData = RARequire('RABattleActionData')
local RAAttackActionData = class('RAAttackActionData',RABattleActionData)


function RAAttackActionData:initByPb(pb)
	self.super.initByPb(self,pb)

	local RAUnitDamageData = RARequire('RAUnitDamageData')
	self.targetId = pb.attack.targetId
	self.targetPos = RACcp(pb.attack.targetPos.x,pb.attack.targetPos.y)

	if pb.attack:HasField("jumpToPos") then 
		self.targetPos = RACcp(pb.attack.jumpToPos.x,pb.attack.jumpToPos.y)
	end 

	self.damage = {}
	for i=1,#pb.attack.damage do
		local damageData = RAUnitDamageData.new(pb.attack.damage[i])
		damageData.attackerId = self.unitId
		self.damage[#self.damage+1] = damageData
	end
end

return RAAttackActionData