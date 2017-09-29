--region RAFU_State_TankDie.lua
--战斗单元的TANK死亡类
--Date 2016/12/7
--Author zhenhui
local RAFU_State_BaseDie = RARequire("RAFU_State_BaseDie")
local RAFU_State_TankDie = class('RAFU_State_TankDie',RAFU_State_BaseDie)


function RAFU_State_TankDie:Execute(dt)
    self.super.Execute(self,dt)
    RA_SAFE_EXECUTE(self.dieEffectInstance,dt)
end

function RAFU_State_TankDie:Exit()
    self.super.Exit(self)
    RA_SAFE_EXIT(self.dieEffectInstance)
end

--坦克特殊的死亡模式，只有死亡特效与其他兵种不同，故只重写坦克的死亡特效
function RAFU_State_TankDie:_DieEffect()
    local dieCfgData = self.fightUnit.cfgData.DieCfg
    self.dieEffectInstance = RARequire(dieCfgData.EffectClass).new(dieCfgData.EffectCfg)



    local centerPos = RARequire("RABattleSceneManager"):getCenterPosByUnitId(self.fightUnit.id)
    
    if dieCfgData.offsetY ~= nil then 
        centerPos.y = centerPos.y + dieCfgData.offsetY
    end 

    if dieCfgData.offsetX ~= nil then 
        centerPos.x = centerPos.x + dieCfgData.offsetX
    end 

    if self.fightUnit.cfgData.AfterDieCfg then
        local RABattleSceneManager = RARequire("RABattleSceneManager")
        local AfterDieCfg = self.fightUnit.cfgData.AfterDieCfg
        local AfterDieInstance = RARequire(AfterDieCfg.EffectClass).new(AfterDieCfg.EffectCfg)
        local tile = RABattleSceneManager:spaceToTile(self.fightUnit:getPosition())
        local width = self.fightUnit.data.size.width
        local height = self.fightUnit.data.size.height
        local data = { tile = tile }
        for i=1, width do
            for j=1,height do
                AfterDieInstance:Enter({targetSpacePos = RABattleSceneManager:tileToSpace({x = tile.x + j - 1, y = tile.y + i - 1})})
            end
        end
    end

    local data = {
        targetSpacePos = centerPos
    }
    self.dieEffectInstance:Enter(data)
end

return RAFU_State_TankDie
--endregion
