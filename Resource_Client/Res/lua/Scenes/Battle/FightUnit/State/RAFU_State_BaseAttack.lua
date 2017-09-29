--region RAFU_State_BaseAttack.lua
--战斗单元的基础攻击类
--Date 2016/11/19
--Author zhenhui
local RAFU_State_BaseAttack = class('RAFU_State_BaseAttack',RARequire("RAFU_Object"))

function RAFU_State_BaseAttack:ctor(unit)
    -- RALog("RAFU_State_BaseAttack:ctor")
    self.fightUnit = unit;

end

function RAFU_State_BaseAttack:release()
    -- RALog("RAFU_State_BaseAttack:release")
    self.fightUnit = nil;
end

function RAFU_State_BaseAttack:Enter(data)
    -- RALog("RAFU_State_BaseAttack:Enter")
    self.frameTime = 0
    self.localAlive = true
    assert(data~=nil,"error")
    -- RALogInfo('...............................................')
    -- RALogInfo('RAFU_State_BaseAttack:Enter() ')
    -- RALogInfo('unit id:'.. self.fightUnit.id.. ' itemId = '..self.fightUnit.data.confData.id)
    -- RALogInfo('...............................................')
    self.data = data
    local attackAction = data
    assert(attackAction~=nil,"error")
    
    --移动方向
    local RABattleSceneManager = RARequire("RABattleSceneManager")
    local targetId = data.targetId
    local curSpacePos = RABattleSceneManager:getCenterPosByUnitId(self.fightUnit.id)
    local targetSpacePos = RABattleSceneManager:getCenterPosByUnitId(targetId)
    local direction = RARequire("EnumManager"):calcBattleDir(curSpacePos,targetSpacePos)
    assert(direction~=nil,"direction error")
    if direction == nil then
        local i = 0
    end 
    self.direction = direction
    --武器开火相关
    local fireData = {
        targetSpacePos = RABattleSceneManager:getHitPosByUnitId(targetId),
        attackData = data
    }
    local weaponAttackTime = self.fightUnit.weapon:StartFire(fireData)
    self.lifeTime = weaponAttackTime or 1

    --设置移动方向
    self.fightUnit:setDir(direction)

    --自身的动作相关    
    for boneName,boneController in pairs(self.fightUnit.boneManager) do
        local frameCount = boneController:getFrameCount(ACTION_TYPE.ACTION_ATTACK, direction)
        local newFps = frameCount / self.lifeTime
        boneController:changeAction(ACTION_TYPE.ACTION_ATTACK,direction, {newFps = newFps})        
    end

    -- self.fightUnit:whiteFlashBuff({})
end

function RAFU_State_BaseAttack:Execute(dt)
    self.frameTime = self.frameTime + dt
    if self.frameTime > self.lifeTime and self.localAlive then
        self:Exit()
    end
end

function RAFU_State_BaseAttack:Exit()
    if self.localAlive == true then
        self.localAlive = false

        for boneName,boneController in pairs(self.fightUnit.boneManager) do
            -- boneController:changeAction(ACTION_TYPE.ACTION_IDLE ,self.fightUnit:getDir())        
        end
    end

end

return RAFU_State_BaseAttack
--endregion
