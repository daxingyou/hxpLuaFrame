local RAFU_FightUnit_Basic = RARequire("RAFU_FightUnit_Basic")
local RAFU_FightUnit_Building = RARequire("RAFU_FightUnit_Building")
local RAFU_FightUnit_V3 = RARequire("RAFU_FightUnit_V3")
local RAFU_FightUnit_Helicopter = RARequire("RAFU_FightUnit_Helicopter")
local BattleField_pb = RARequire('BattleField_pb')

local RAFightUnitFactory = {
	
}

function RAFightUnitFactory:createUnit(unitData)

	--建筑
	if unitData.type == BattleField_pb.UNIT_BUILDING or unitData.type == BattleField_pb.UNIT_DEFENCE then 
		return RAFU_FightUnit_Building.new(unitData)
	end 

	-- v3车
	if unitData.itemId == 1004 then
		return RAFU_FightUnit_V3.new(unitData)
	end
	
	--夜鹰直升机
	if unitData.itemId == 1028 then
		return RAFU_FightUnit_Helicopter.new(unitData)
	end

	return RAFU_FightUnit_Basic.new(unitData)	
end

return RAFightUnitFactory

