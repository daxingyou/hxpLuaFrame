--pb数据存储
RARequire('extern')

local RABattleActionData = class('RABattleActionData',{
	time = 0,
	type = 0,
	unitId = 0,
	})

--根据PB初始化数据
function RABattleActionData:initByPb(pb)
	self.time = pb.time
	self.type = pb.type
	self.unitId = pb.unitId 
end

function RABattleActionData:ctor(pb)
	self:initByPb(pb)
end 

return RABattleActionData