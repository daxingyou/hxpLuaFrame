--pb数据存储
RARequire('extern')
local RABattleActionData = RARequire('RABattleActionData')
local RAFlyActionData = class('RAFlyActionData',RABattleActionData)

function RAFlyActionData:initByPb(pb)
	self.super.initByPb(self,pb)
	self.fromPos = RACcp(pb.fly.fromPos.x,pb.fly.fromPos.y)

	if pb.fly:HasField("targetId") then 
		self.targetId = pb.fly.targetId
	end 

	self.targetPos = RACcp(pb.fly.targetPos.x,pb.fly.targetPos.y)
	self.flyTime = pb.fly.flyTime
	self.flyDist = pb.fly.flyDist
end

return RAFlyActionData