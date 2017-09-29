--region RAFU_State_BaseAttack.lua
--战斗单元的基础攻击类
--Date 2016/11/19
--Author zhenhui
local RAFU_State_BuildingPrepareAttack = class('RAFU_State_BuildingPrepareAttack',RARequire("RAFU_State_BaseAttack"))


function RAFU_State_BuildingPrepareAttack:Enter(data)
    -- 状态本身需要execute
    self:SetIsExecute(true)
    
    -- RALog("RAFU_State_BaseAttack:Enter")
    self.frameTime = 0
    self.localAlive = true
    assert(data~=nil,"error")
    self.data = data
    local attackAction = data
    assert(attackAction~=nil,"error")
    
    --移动方向
    -- local direction = RARequire("EnumManager").FU_DIRECTION_ENUM.DIR_UP

    local RABattleSceneManager = RARequire('RABattleSceneManager')
    local targetId = data.targetId
    local curSpacePos = RABattleSceneManager:getCenterPosByUnitId(self.fightUnit.id)
    local targetSpacePos = RABattleSceneManager:getCenterPosByUnitId(targetId)
    local direction = RARequire("EnumManager"):calcBattleDir(curSpacePos,targetSpacePos)
    --武器开火相关
    self.fireData = {
        targetSpacePos = RABattleSceneManager:getHitPosByUnitId(targetId),
        attackData = data
    }

    --设置移动方向
    self.fightUnit:setDir(direction)

    -- actionType, direction, callback,needSwitch,isforce
    --自身的动作相关
    direction = RARequire("EnumManager").FU_DIRECTION_ENUM.DIR_UP
    
    self.lifeTime = 0

    local action = ACTION_TYPE.ACTION_ATTACK 
    if self.fightUnit:isBreaken() then 
        action = ACTION_TYPE.ACTION_BEHIT_ATTACK
    end 

    for boneName,boneController in pairs(self.fightUnit.boneManager) do
        local frameTime = boneController:getFrameTime(action,direction)
        if self.lifeTime < frameTime then 
            self.lifeTime = frameTime
        end   

        boneController:changeAction(action,direction)        
    end
end

function RAFU_State_BuildingPrepareAttack:Execute(dt)
    self.frameTime = self.frameTime + dt
    if self.frameTime > self.lifeTime and self.localAlive then
        self:Exit()
    end
end

function RAFU_State_BuildingPrepareAttack:Exit()
    
    if self.localAlive == true then
        self.localAlive = false

        --攻击结束的时候，发射炮火
        self.fightUnit.weapon:StartFire(self.fireData)

        local direction = RARequire("EnumManager").FU_DIRECTION_ENUM.DIR_UP

        local action = ACTION_TYPE.ACTION_IDLE 
        if self.fightUnit:isBreaken() then 
            action = ACTION_TYPE.ACTION_BEHIT_IDLE 
        end 

        for boneName,boneController in pairs(self.fightUnit.boneManager) do
            boneController:changeAction(action,direction)        
        end
    end
end

return RAFU_State_BuildingPrepareAttack
--endregion
