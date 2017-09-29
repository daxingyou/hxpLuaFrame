--region RAFU_State_TankAttack.lua
--战斗单元的坦克通用移动类
--Date 2016/11/24
--Author zhenhui
local RAFU_State_BaseAttack = RARequire("RAFU_State_BaseAttack")
local RAFU_State_TankAttack = class('RAFU_State_TankAttack',RAFU_State_BaseAttack)


function RAFU_State_TankAttack:Enter(data)
    -- RALog("RAFU_State_TankAttack:Enter")
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

    --武器开火相关
    local fireData = {
        targetSpacePos = targetSpacePos,
        attackData = data
    }
    local weaponAttackTime = self.fightUnit.weapon:StartFire(fireData)

    --处理TANK炮管对准逻辑，不设置移动方向，同时，不设置底座的方向，tank只有移动的时候设置方向
    local direction = RARequire("EnumManager"):calcBattle16Dir(curSpacePos,targetSpacePos)
    for boneName,boneController in pairs(self.fightUnit.boneManager) do
        if boneController.boneData.isTop then
            boneController:changeAction(ACTION_TYPE.ACTION_ATTACK,direction)
        end
    end
end


return RAFU_State_TankAttack
--endregion
