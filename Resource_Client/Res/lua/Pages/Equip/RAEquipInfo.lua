--装备信息BaseInfo
RARequire('extern')

local RAEquipInfo = class("RAEquipInfo",{
    uuid    = "",    --装备唯一id
	equipId = 0, 	--装备id
	level 	= 0, 	--装备强化等级
	point	= 0		--装备当前累计的进阶点数
})

--根据PB初始化数据
function RAEquipInfo:initByPb(equipPb)
    self.uuid    = equipPb.uuid
	self.equipId = equipPb.equipId
	self.level   = equipPb.level
	self.point   = equipPb.point
end

function RAEquipInfo:ctor(...)

end

return RAEquipInfo