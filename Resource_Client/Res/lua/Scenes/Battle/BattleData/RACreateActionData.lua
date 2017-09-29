--pb数据存储
RARequire('extern')
local RABattleActionData = RARequire('RABattleActionData')
local RACreateActionData = class('RACreateActionData',RABattleActionData)


local RACreateData = class('RACreateData',{})

function RACreateData:ctor(...)

end

function RACreateData:initByPb(pb)
	self.pos = { x= pb.pos.x, y = pb.pos.y}
	self.childUnitId = pb.childUnitId
	self.childItemId = pb.childItemId

	if pb:HasField("targetUnit") then 
		self.targetUnit = pb.targetUnit
	end 

	if pb:HasField("targetPos") then 
		self.targetPos = {x= pb.targetPos.x,y=pb.targetPos.y}
	end 
end


function RACreateActionData:initByPb(pb)
	
	self.super.initByPb(self,pb)
	self.skillId = pb.create.skillId

	self.data = {}
	for i=1,#pb.create.data do
		local createData = RACreateData.new()
		createData:initByPb(pb.create.data[i])
		createData.unitId = self.unitId 
		self.data[#self.data+1] = createData
	end
end

return RACreateActionData