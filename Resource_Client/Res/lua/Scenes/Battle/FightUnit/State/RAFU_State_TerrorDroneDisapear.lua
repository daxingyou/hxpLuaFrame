--region RAFU_State_BaseDisapear.lua
--恐怖机器人消失
--Date 2016/2/14
--Author bls
local RAFU_State_BaseDisapear = RARequire("RAFU_State_BaseDisapear") 
local RAFU_State_TerrorDroneDisapear = class('RAFU_State_TerrorDroneDisapear',RAFU_State_BaseDisapear)


function RAFU_State_TerrorDroneDisapear:Enter(data)
    --移除逻辑
    local unitId = self.fightUnit.id
    local message = {}
    message.unitId = unitId
    --下一帧销毁自己，防止出现问题
--    MessageManager.sendMessage(MessageDef_BattleScene.MSG_FIGHT_UNIT_ATTACK_UNIT_DEATH, message)
    RALogInfo('...............................................')
    RALogInfo('RAFU_State_BaseDisapear:Enter() ')
    RALogInfo('unit id:'.. unitId.. ' itemId = '..self.fightUnit.data.confData.id)
    RALogInfo('...............................................')
end

function RAFU_State_TerrorDroneDisapear:Execute(dt)
    
end

function RAFU_State_TerrorDroneDisapear:Exit()
    
end

return RAFU_State_TerrorDroneDisapear
--endregion
