--region RAFU_State_BaseIdle.lua
--战斗单元的基础待机类
--Date 2016/11/19
--Author zhenhui
local RAFU_State_BaseIdle = class('RAFU_State_BaseIdle',RARequire("RAFU_Object"))


function RAFU_State_BaseIdle:ctor(unit)
    -- RALog("RAFU_State_BaseIdle:ctor")
    self.fightUnit = unit;
end

function RAFU_State_BaseIdle:release()
    -- RALog("RAFU_State_BaseIdle:release")
    self.fightUnit = nil;
end

function RAFU_State_BaseIdle:Enter(data)    
    -- RALog("RAFU_State_BaseIdle:Enter")
     --自身的动作相关
    local direction = self.fightUnit:getDir()
    for boneName,boneController in pairs(self.fightUnit.boneManager) do
        boneController:changeAction(ACTION_TYPE.ACTION_IDLE,direction)
    end
end

function RAFU_State_BaseIdle:Execute(dt)
    --RALog("RAFU_State_BaseIdle:Execute")
    
end

function RAFU_State_BaseIdle:Exit()
    -- RALog("RAFU_State_BaseIdle:Exit")
end

return RAFU_State_BaseIdle
--endregion
