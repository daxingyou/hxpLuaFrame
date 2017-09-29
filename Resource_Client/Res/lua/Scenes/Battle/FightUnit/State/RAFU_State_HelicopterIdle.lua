--region RAFU_State_HelicopterIdle.lua
--战斗单元的直升机升起降落待机类
--Date 2016/2/14
--Author phan
local RAFU_State_HelicopterIdle = class('RAFU_State_HelicopterIdle',RARequire("RAFU_State_BaseIdle"))
local RAFU_Math = RARequire('RAFU_Math')

function RAFU_State_HelicopterIdle:Enter(data)    
    --RALog("RAFU_State_HelicopterIdle:Enter")
    self.super.Enter(self)


    if self.fightUnit.HelicopterLand then 
        self.fightUnit:HelicopterLand()
    end
end

return RAFU_State_HelicopterIdle


