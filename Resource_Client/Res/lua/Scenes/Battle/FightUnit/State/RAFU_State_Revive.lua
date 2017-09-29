--region RAFU_State_Revive.lua
--战斗单元的复活
--Date 2016/2/15
--Author bls
local RAFU_State_Revive = class('RAFU_State_Revive',RARequire("RAFU_Object"))


function RAFU_State_Revive:ctor(unit)
    -- RALog("RAFU_State_BaseIdle:ctor")
    self.fightUnit = unit;
end

function RAFU_State_Revive:release()
    self.fightUnit = nil;
end

function RAFU_State_Revive:Enter(data) 
                                              
    local targetPos =  RARequire("RABattleSceneManager"):tileToSpace(data.pos)
    local pos =  ccp(targetPos.x,targetPos.y)
    local hp  = data.hp
    local count = data.count
    self.fightUnit.rootNode:setPosition(pos)
    self.fightUnit.rootNode:setVisible(true)   
end

function RAFU_State_Revive:Execute(dt)
    --RALog("RAFU_State_BaseIdle:Execute")
    
end

function RAFU_State_Revive:Exit()
    -- RALog("RAFU_State_BaseIdle:Exit")
end

return RAFU_State_Revive
--endregion
