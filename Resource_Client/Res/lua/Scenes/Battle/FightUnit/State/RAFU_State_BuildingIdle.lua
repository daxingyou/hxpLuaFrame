--region RAFU_State_BaseIdle.lua
--战斗单元的基础待机类
--Date 2016/11/19
--Author zhenhui
local RAFU_State_BuildingIdle = class('RAFU_State_BuildingIdle',RARequire("RAFU_State_BaseIdle"))

function RAFU_State_BuildingIdle:Enter(data)

    local action = ACTION_TYPE.ACTION_IDLE
    if self.fightUnit:isBreaken() then 
        action = ACTION_TYPE.ACTION_BEHIT_IDLE
    end 

    for boneName,boneController in pairs(self.fightUnit.boneManager) do
        boneController:changeAction(action,RARequire("EnumManager").FU_DIRECTION_ENUM.DIR_UP)
    end
end

return RAFU_State_BuildingIdle

