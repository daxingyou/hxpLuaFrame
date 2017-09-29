--空庭攻击
--Author hulei
local RAFU_State_BaseAttack = RARequire("RAFU_State_BaseAttack")
local RAFU_State_ZepAttack = class('RAFU_State_ZepAttack',RAFU_State_BaseAttack)


function RAFU_State_ZepAttack:Enter(data)
    self.frameTime = 0
    self.localAlive = true
    assert(data~=nil,"error")
    self.data = data
    local attackAction = data
    assert(attackAction~=nil,"error")

    --武器开火相关
    local fireData = {
        attackData = data
    }
    local weaponAttackTime = self.fightUnit.weapon:StartFire(fireData)
    self.lifeTime = weaponAttackTime or 1
end


return RAFU_State_ZepAttack
--endregion
