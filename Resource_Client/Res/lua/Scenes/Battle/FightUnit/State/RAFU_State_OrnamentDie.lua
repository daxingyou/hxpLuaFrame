--region RAFU_State_OrnamentDie.lua
--战斗中的装饰物的基础死亡类

local RAFU_State_OrnamentDie = class('RAFU_State_OrnamentDie',RARequire("RAFU_Object"))

function RAFU_State_OrnamentDie:ctor(unit)
    self.fightUnit = unit;
end

function RAFU_State_OrnamentDie:release()
    self.fightUnit = nil;
end

function RAFU_State_OrnamentDie:Enter(data)
    self.fightUnit:changeToDieLayer()
    for boneName,boneController in pairs(self.fightUnit.boneManager) do
        boneController:changeAction(ACTION_TYPE.ACTION_BEHIT_IDLE,RARequire("EnumManager").FU_DIRECTION_ENUM.DIR_UP)
    end
end

function RAFU_State_OrnamentDie:Execute(dt)
end

function RAFU_State_OrnamentDie:Exit()
end


return RAFU_State_OrnamentDie

