--region RAFU_State_BaseFly.lua
--战斗单元的基础消失类
--Date 2016/12/16
--Author zhenhui
local RAFU_State_BaseFly = class('RAFU_State_BaseFly',RARequire("RAFU_Object"))

function RAFU_State_BaseFly:ctor(unit)
    self.fightUnit = unit
    self.frameTime = 0.0
end

function RAFU_State_BaseFly:release()
    self.fightUnit = nil
    self.frameTime = 0.0
end

function RAFU_State_BaseFly:Enter(data)
    RALogInfo("RAFU_State_BaseFly:Enter")
    local RABattleSceneManager = RARequire("RABattleSceneManager")
    self.targetSpacePos = RABattleSceneManager:getCenterPosByUnitId(data.targetId)
end

function RAFU_State_BaseFly:Execute(dt)
    
end

function RAFU_State_BaseFly:Exit()
    
end

-- 播放飞行完毕的特效
function RAFU_State_BaseFly:PlayFlyEndEffect()
    -- FlyEndCfg
    local flyEndCfg = self.fightUnit.cfgData.FlyEndCfg
    if flyEndCfg ~= nil then
    	local effectClass = flyEndCfg.effectClass
        local effectInstance = nil
        if effectClass ~= nil then
            effectInstance = RARequire(effectClass).new(flyEndCfg.effectCfgName)
            local data = {
		        targetSpacePos = self.targetSpacePos
		    }            
            RA_SAFE_ENTER(effectInstance, data)
        end
    end
end

return RAFU_State_BaseFly
--endregion
