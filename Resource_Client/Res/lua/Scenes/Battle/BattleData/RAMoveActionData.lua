--pb数据存储
RARequire('extern')
local RABattleActionData = RARequire('RABattleActionData')
local RAMoveActionData = class('RAMoveActionData',RABattleActionData)

function RAMoveActionData:initByPb(pb)
	if pb == nil then 
		return 
	end 

	self.super.initByPb(self,pb)
	self.targetId = pb.move.targetId
	self.curPos = RACcp(pb.move.curPos.x,pb.move.curPos.y)
	self.movePos = RACcp(pb.move.movePos.x,pb.move.movePos.y)
	self.moveDir = pb.move.moveDir
	if pb.move:HasField("movePeriod") then 
		self.movePeriod = pb.move.movePeriod*0.001
	else
		self.movePeriod = 0
	end 

	if pb.move:HasField("turnPeriod") then 
		self.turnPeriod = pb.move.turnPeriod*0.001
	else
		self.turnPeriod = 0
	end	
end

function RAMoveActionData:init(unitId,pos,movePos,movePeriod,moveDir)
	local BattleField_pb = RARequire('BattleField_pb')
	self.curPos = pos
	self.movePos = movePos
	self.movePeriod = movePeriod
	self.moveDir = moveDir
	self.type = BattleField_pb.MOVE
	self.unitId = unitId 
end

return RAMoveActionData