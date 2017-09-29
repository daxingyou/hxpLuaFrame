--region RAFU_State_BorisFly.lua
--boris轰炸机的飞行类
--Date 2016/12/22
--Author zhenhui
local RAFU_State_BorisFly = class('RAFU_State_BorisFly',RARequire("RAFU_Object"))


function RAFU_State_BorisFly:ctor(unit)
    self.fightUnit = unit;
    self.frameTime = 0.0
end

function RAFU_State_BorisFly:release()
    self.fightUnit = nil;
    self.frameTime = 0.0
end

function RAFU_State_BorisFly:Enter(data)
    RALogInfo("RAFU_State_BorisFly:Enter")
    -- 状态本身需要execute
    self:SetIsExecute(true)
    
    local targetId = data.targetId
    local curTilePos = data.fromPos
    local moveTilePos = data.targetPos
    local RABattleSceneManager = RARequire("RABattleSceneManager")
    self.targetSpacePos = RABattleSceneManager:getCenterPosByUnitId(targetId)

    self.spendTime = data.flyTime/1000.0

    
    self.lifeTime = self.spendTime + 4

    self.startAnimationTime = 0
    self.frameTime = 0
    self.curState = 0


end


function RAFU_State_BorisFly:EnterAnimation( ... )
	self.curState = 1

	local RAFU_Cfg_Effect = RARequire("RAFU_Cfg_Effect")
    local effectName = "Mig_fly"
    effectCfg = RAFU_Cfg_Effect[effectName]
    if effectCfg then
        self.effectInstance = RARequire(effectCfg.class).new(effectName)
        local data = {
        	targetSpacePos = self.targetSpacePos
    	}
        self.effectInstance:Enter(data)
    end

end

function RAFU_State_BorisFly:Execute(dt)
    self.frameTime = self.frameTime + dt
    if self.frameTime > self.startAnimationTime then
    	if self.curState == 0 then
    		self:EnterAnimation()
    	end
    end
end

function RAFU_State_BorisFly:Exit()
    
end

return RAFU_State_BorisFly
--endregion
