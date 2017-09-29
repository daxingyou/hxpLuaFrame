--region RAFU_State_BaseDisapear.lua
--战斗单元的基础消失类
--Date 2016/12/16
--Author zhenhui
local RAFU_State_BaseDisapear = class('RAFU_State_BaseDisapear',RARequire("RAFU_Object"))


function RAFU_State_BaseDisapear:ctor(unit)
    self.fightUnit = unit;
end

function RAFU_State_BaseDisapear:release()
    self.fightUnit = nil;
end

function RAFU_State_BaseDisapear:Enter(data)
    --移除逻辑
    local unitId = self.fightUnit.id
    local message = {}
    message.unitId = unitId
    --下一帧销毁自己，防止出现问题
    MessageManager.sendMessage(MessageDef_BattleScene.MSG_FIGHT_UNIT_ATTACK_UNIT_DEATH, message)
    RALogInfo('...............................................')
    RALogInfo('RAFU_State_BaseDisapear:Enter() ')
    RALogInfo('unit id:'.. unitId.. ' itemId = '..self.fightUnit.data.confData.id)
    RALogInfo('...............................................')
end

function RAFU_State_BaseDisapear:Execute(dt)
    
end

function RAFU_State_BaseDisapear:Exit()
    
end

return RAFU_State_BaseDisapear
--endregion
