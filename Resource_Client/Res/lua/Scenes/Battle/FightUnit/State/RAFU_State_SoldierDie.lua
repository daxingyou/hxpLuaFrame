--region RAFU_State_SoldierDie.lua
--战斗单元的士兵死亡类
--Date 2016/12/7
--Author zhenhui
local RAFU_State_BaseDie = RARequire("RAFU_State_BaseDie")
local RAFU_State_SoldierDie = class('RAFU_State_SoldierDie',RAFU_State_BaseDie)


function RAFU_State_SoldierDie:Execute(dt)
    self.super.Execute(self,dt)
    RA_SAFE_EXECUTE(self.dieEffectInstance,dt)
end

function RAFU_State_SoldierDie:Exit()
    self.super.Exit(self)
    RA_SAFE_EXIT(self.dieEffectInstance)
end

--士兵死亡后特效
--需要根据 被受到的根据类型来 播放不同的死亡特效
function RAFU_State_SoldierDie:_DieEffect()
    local dieCfgData = self.fightUnit.cfgData.DieCfg

    local attackerType = self.fightUnit.data.attackerType or 1

    local EffectCfg = dieCfgData.EffectCfg[attackerType]

    self.dieEffectInstance = RARequire(dieCfgData.EffectClass).new(EffectCfg)

    local data = {
        targetSpacePos = self.fightUnit:getPosition()
    }
    self.dieEffectInstance:Enter(data)
end

--需要重写 士兵死亡区分开死亡动作
function RAFU_State_SoldierDie:_DieAction()
    self.fightUnit:setHudVisible(false)
end

return RAFU_State_SoldierDie
--endregion
