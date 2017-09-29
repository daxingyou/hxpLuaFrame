--region RAFU_State_CureAttack.lua
--战斗单元的医疗车攻击类
--Date 2017/02/09
--Author phan
local RAFU_State_BaseAttack = RARequire("RAFU_State_BaseAttack")
local RAFU_State_CureAttack = class('RAFU_State_CureAttack',RAFU_State_BaseAttack)


function RAFU_State_CureAttack:Enter(data)
    -- RALog("RAFU_State_CureAttack:Enter")
    self.frameTime = 0
    self.localAlive = true
    assert(data~=nil,"error")
    self.data = data
    local attackAction = data
    assert(attackAction~=nil,"error")
    
    self.lifeTime = weaponAttackTime or 1
    
    --移动方向
    local RABattleSceneManager = RARequire("RABattleSceneManager")
    local targetId = data.targetId
    local curSpacePos = RABattleSceneManager:getCenterPosByUnitId(self.fightUnit.id)
    local targetSpacePos = RABattleSceneManager:getHitPosByUnitId(targetId)

    --治疗相关
    local fireData = {
        targetSpacePos = targetSpacePos,
        attackData = data
    }
    local weaponAttackTime = self.fightUnit.weapon:StartFire(fireData)

    --处理医疗车对准逻辑
    local direction = RARequire("EnumManager"):calcBattle16Dir(curSpacePos,targetSpacePos)
    for boneName,boneController in pairs(self.fightUnit.boneManager) do
        boneController:changeAction(ACTION_TYPE.ACTION_ATTACK,direction)
    end
end

return RAFU_State_CureAttack
--endregion
