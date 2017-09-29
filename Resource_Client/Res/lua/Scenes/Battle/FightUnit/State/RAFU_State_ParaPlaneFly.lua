--region RAFU_State_ParaPlaneFly.lua
--伞兵运输机的飞行类
--Date 2016/12/29
--Author qinho
local RAFU_State_ParaPlaneFly = class('RAFU_State_ParaPlaneFly',RARequire("RAFU_State_BaseFly"))


function RAFU_State_ParaPlaneFly:Enter(data)
    RALogInfo("***********************************************")
    RALogInfo("RAFU_State_ParaPlaneFly:Enter")
    RALogInfo("***********************************************")
    -- 状态本身需要execute
    self:SetIsExecute(true)
    
    local targetId = data.targetId
    local curTilePos = data.fromPos
    local moveTilePos = data.targetPos
    local RABattleSceneManager = RARequire("RABattleSceneManager")
    self.targetSpacePos = RABattleSceneManager:tileToSpace(moveTilePos)

    self.spendTime = data.flyTime/1000.0

    
    self.lifeTime = self.spendTime

    self.startAnimationTime = self.spendTime - 4
    self.frameTime = 0
    self.curState = 0
end


function RAFU_State_ParaPlaneFly:EnterAnimation( ... )
	self.curState = 1

	local RAFU_Cfg_Effect = RARequire("RAFU_Cfg_Effect")
    local effectName = "ParaPlane_Fly"
    effectCfg = RAFU_Cfg_Effect[effectName]
    if effectCfg then
        self.effectInstance = RARequire(effectCfg.class).new(effectName)
        local data = {
        	targetSpacePos = self.targetSpacePos
    	}
        self.effectInstance:Enter(data)
    end

end

function RAFU_State_ParaPlaneFly:Execute(dt)
    self.frameTime = self.frameTime + dt
    if self.frameTime > self.startAnimationTime then
    	if self.curState == 0 then
    		self:EnterAnimation()
    	end
    end
end

function RAFU_State_ParaPlaneFly:Exit()
    
end

return RAFU_State_ParaPlaneFly
--endregion
