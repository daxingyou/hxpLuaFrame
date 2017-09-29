--pb数据存储
RARequire('extern')

local RAUnitDamageData = class('RAUnitDamageData',{
	unitId = 0,
	count = 0,
	hp = 0,
	damage = 0,
	})



--根据PB初始化数据
function RAUnitDamageData:initByPb(pb)
	self.unitId = pb.unitId
	self.count = pb.count
	self.hp = pb.hp
	self.fight = pb.fight

	if pb:HasField("damage") then 
		self.damage = pb.damage
	end
end

function RAUnitDamageData:ctor(pb)
	self:initByPb(pb)
end 

return RAUnitDamageData