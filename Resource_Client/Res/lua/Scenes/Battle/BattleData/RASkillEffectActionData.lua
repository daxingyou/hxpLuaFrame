--pb数据存储
RARequire('extern')
local RABattleActionData = RARequire('RABattleActionData')
local RASkillEffectActionData = class('RASkillEffectActionData',RABattleActionData)

--[[
// 施放效果行为
message SkillEffectAction
{
	required int32 skillId = 1;
	optional UnitPos firePos = 2;
	optional UnitPos targetPos = 3;
	repeated UnitDamage damage = 4;	// 伤害列表同步	
	optional int32 effectIndex = 5; // 生效次数
	optional int32 skillUid = 6;
}
]]
function RASkillEffectActionData:initByPb(pb)
	self.super.initByPb(self,pb)
	self.skillId = pb.skillEffect.skillId

	if pb.skillEffect:HasField("targetPos") then 
		self.targetPos = RACcp (pb.skillEffect.targetPos.x,pb.skillEffect.targetPos.y)
	else
		assert(false,"do not has the targetPos")
		self.targetPos = nil
	end 

	if pb.skillEffect:HasField("firePos") then 
		self.firePos = RACcp (pb.skillEffect.firePos.x,pb.skillEffect.firePos.y)
	else
		assert(false,"do not has the firePos")
		self.firePos = nil
	end 

	self.damage = {}
	local RAUnitDamageData = RARequire("RAUnitDamageData")
	for i=1,#pb.skillEffect.damage do
		local damageData = RAUnitDamageData.new(pb.skillEffect.damage[i])
		self.damage[#self.damage+1] = damageData
	end

	if pb.skillEffect:HasField("effectIndex") then 
		self.effectIndex = pb.skillEffect.effectIndex
	else
		self.effectIndex = 0
	end

	if pb.skillEffect:HasField("skillUid") then 
		self.skillUid = pb.skillEffect.skillUid
	else
		self.skillUid = 0
	end
end

return RASkillEffectActionData