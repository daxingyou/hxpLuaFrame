--region RAFU_State_BaseDie.lua
--战斗单元的基础死亡类
--Date 2016/11/19
--Author zhenhui
local RAFU_State_BaseDie = class('RAFU_State_BaseDie',RARequire("RAFU_Object"))


function RAFU_State_BaseDie:ctor(unit)
    -- RALog("RAFU_State_BaseDie:ctor")
    self.fightUnit = unit;
end

function RAFU_State_BaseDie:release()
    -- RALog("RAFU_State_BaseDie:release")
    self.fightUnit = nil;
end

function RAFU_State_BaseDie:Enter(data)
    -- 状态本身需要execute
    self:SetIsExecute(true)
    -- RALogInfo('...............................................')
    -- RALogInfo('RAFU_State_BaseDie:Enter() ')
    -- RALogInfo('unit id:'.. self.fightUnit.id.. ' itemId = '..self.fightUnit.data.confData.id)

    -- RALog("RAFU_State_BaseDie:Enter")
    self.dieActionTime = self.fightUnit.cfgData.DieCfg.dieActionTime
    self.dieEffectTime = self.fightUnit.cfgData.DieCfg.dieEffectTime 
    self.lifetime = self.dieActionTime + self.dieEffectTime
    self.localAlive = true
    self.frametime = 0
    self.isInDieAction = true
    --自身的动作相关
    self:_DieAction()
    --刷新当前数目
    self.fightUnit:updateCount()
end

function RAFU_State_BaseDie:_DieEffect()
    for boneName,boneController in pairs(self.fightUnit.boneManager) do
        boneController:beenDestroy(self.dieActionTime)
    end
end

function RAFU_State_BaseDie:_DieAction()
    self.fightUnit:setHudVisible(false)
    local curDir = self.fightUnit:getDir()
    for boneName,boneController in pairs(self.fightUnit.boneManager) do
        boneController:changeAction(ACTION_TYPE.ACTION_DEATH,curDir)
    end
end


function RAFU_State_BaseDie:_SetBoneVisible()
    self.fightUnit:setHudVisible(false)
   for boneName,boneController in pairs(self.fightUnit.boneManager) do
        boneController:setVisible(false)
    end 
end

function RAFU_State_BaseDie:_removeBuff()
    self.fightUnit.buffSystem:Exit()
end

function RAFU_State_BaseDie:Execute(dt)
    -- RALog("RAFU_State_BaseDie:Execute")
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

function RAFU_State_BaseDie:Exit()
    -- RALog("RAFU_State_BaseDie:Exit")
    --死亡生命中期结束的时候，销毁unit单元
    if self.localAlive == true then
        self.localAlive = false

        --发送消息，清除在RABattleSceneManager
        local message = {}
        message.unitId = self.fightUnit.id
        MessageManager.sendMessageInstant(MessageDef_BattleScene.MSG_FIGHT_UNIT_DIE_NOTI, message)
    end
end

return RAFU_State_BaseDie
--endregion
