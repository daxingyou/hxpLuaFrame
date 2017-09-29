--region RAFU_State_WarheadV3Die.lua
-- v3 炮弹被攻击死亡的处理
--Date 2017-01-15
--Author qinho
local RAFU_State_WarheadV3Die = class('RAFU_State_WarheadV3Die',RARequire("RAFU_State_BaseDie"))


function RAFU_State_WarheadV3Die:Enter(data)
    -- 状态本身需要execute
    self:SetIsExecute(true)
    -- RALogInfo('...............................................')
    -- RALogInfo('RAFU_State_WarheadV3Die:Enter() ')
    -- RALogInfo('unit id:'.. self.fightUnit.id.. ' itemId = '..self.fightUnit.data.confData.id)

    -- RALog("RAFU_State_WarheadV3Die:Enter")
    self.dieActionTime = self.fightUnit.cfgData.DieCfg.dieActionTime
    self.dieEffectTime = self.fightUnit.cfgData.DieCfg.dieEffectTime 
    self.lifetime = self.dieActionTime + self.dieEffectTime
    self.localAlive = true
    self.frametime = 0
    self.isInDieAction = true
    -- --自身的动作相关
    self:_DieAction()
    --刷新当前数目
    self.fightUnit:updateCount()
end

function RAFU_State_WarheadV3Die:_DieEffect()
    -- for boneName,boneController in pairs(self.fightUnit.boneManager) do
    --     boneController:beenDestroy(self.dieActionTime)
    -- end
    -- v3 的死亡直接隐藏，不做渐变消失
    self:_SetBoneVisible()
end

function RAFU_State_WarheadV3Die:_DieAction()
    -- self.fightUnit:setHudVisible(false)
    -- local curDir = self.fightUnit:getDir()
    -- for boneName,boneController in pairs(self.fightUnit.boneManager) do
    --     boneController:changeAction(ACTION_TYPE.ACTION_DEATH,curDir)
    -- end
    self:_SetBoneVisible()
end


function RAFU_State_WarheadV3Die:_SetBoneVisible()
    self.fightUnit:setHudVisible(false)
    for boneName,boneController in pairs(self.fightUnit.boneManager) do
        boneController:setVisible(false)
    end 
end

function RAFU_State_WarheadV3Die:_removeBuff()
    self.fightUnit.buffSystem:Exit()
end

function RAFU_State_WarheadV3Die:Execute(dt)
    -- RALog("RAFU_State_WarheadV3Die:Execute")
    self.frametime = self.frametime + dt
    if self.frametime > self.lifetime and self.localAlive == true then
        self:Exit()
    elseif self.frametime > self.dieActionTime and self.isInDieAction then
        self.isInDieAction = false
        
        self:_SetBoneVisible()
        self:_removeBuff()
        self:_DieEffect()
    end


end

function RAFU_State_WarheadV3Die:Exit()
    -- RALog("RAFU_State_WarheadV3Die:Exit")
    --死亡生命中期结束的时候，销毁unit单元
    if self.localAlive == true then
        self.localAlive = false

        --发送消息，清除在RABattleSceneManager
        local message = {}
        message.unitId = self.fightUnit.id
        MessageManager.sendMessageInstant(MessageDef_BattleScene.MSG_FIGHT_UNIT_DIE_NOTI, message)
    end
end

return RAFU_State_WarheadV3Die
--endregion
