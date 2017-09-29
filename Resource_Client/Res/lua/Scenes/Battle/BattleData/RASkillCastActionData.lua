--pb数据存储
RARequire('extern')
local RABattleActionData = RARequire('RABattleActionData')
local RASkillCastActionData = class('RASkillCastActionData',RABattleActionData)
--[[
// 施放技能行为
message SkillCastAction
{
	required int32 skillId = 1;
	optional UnitPos firePos = 2;
	optional UnitPos targetPos = 3;
	optional int32 skillPoint = 4; // 技能点数同步
	optional int32 skillUid = 5;
	optional int32 waitTime = 6; //技能生效等待时间
}
]]
function RASkillCastActionData:initByPb(pb)
	self.super.initByPb(self,pb)
	self.skillId = pb.skillCast.skillId

	if pb.skillCast:HasField("targetPos") then 
		self.targetPos = RACcp (pb.skillCast.targetPos.x,pb.skillCast.targetPos.y)
	else
		assert(false,"do not has the targetPos")
		self.targetPos = nil
	end 
	if pb.skillCast:HasField("skillPoint") then 
		self.skillPoint = pb.skillCast.skillPoint
	else
		assert(false,"do not has the skillPoint")
		self.skillPoint = 0
	end

	if pb.skillCast:HasField("waitTime") then 
		self.waitTime = pb.skillCast.waitTime * 0.001
	else
		assert(false,"do not has the waitTime")
		self.waitTime = 0
	end

	if pb.skillCast:HasField("skillUid") then 
		self.skillUid = pb.skillCast.skillUid
	else
		assert(false,"do not has the skillUid")
		self.skillUid = 0
	end
	
	if pb.skillCast:HasField("firePos") then 
		self.firePos = pb.skillCast.firePos
	else
		assert(false,"do not has the firePos")
		self.firePos = nil
	end

	if #pb.skillCast.bombInfo > 0 then 
		self.bombInfo = {}
		for i=1,#pb.skillCast.bombInfo do
			local oneBombInfo = {}
			oneBombInfo.startTime = pb.skillCast.bombInfo[i].startTime * 0.001
			oneBombInfo.flyTime = pb.skillCast.bombInfo[i].flyTime * 0.001
			oneBombInfo.bombPos = RACcp(pb.skillCast.bombInfo[i].bombPos.x, pb.skillCast.bombInfo[i].bombPos.y)
			self.bombInfo[#self.bombInfo+1] = oneBombInfo
		end
	else		
		self.bombInfo = nil
	end	

end

return RASkillCastActionData