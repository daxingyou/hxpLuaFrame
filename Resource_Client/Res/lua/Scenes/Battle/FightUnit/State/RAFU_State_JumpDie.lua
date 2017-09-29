--region RAFU_State_JumpDie.lua
--战斗单元的基础死亡类
--Date 2016/12/15
--Author hulei
local RAFU_State_JumpDie = class('RAFU_State_JumpDie',RARequire("RAFU_State_BaseDie"))

function RAFU_State_JumpDie:_DieAction()
    -- self.fightUnit.rootNode:runAction(CCEaseIn:create(CCMoveBy:create(0.2, ccp(0,-60)), 1))
    local curDir = self.fightUnit:getDir()
    for boneName,boneController in pairs(self.fightUnit.boneManager) do
        boneController:changeAction(ACTION_TYPE.ACTION_DEATH,curDir)
        if boneController.boneData.isTop == true then
        	boneController.sprite:runAction(CCEaseIn:create(CCMoveBy:create(self.dieActionTime, ccp(0,-60)), 1))
        end
    end
    local dieCfgData = self.fightUnit.cfgData.DieCfg
    self.dieEffectInstance = RARequire(dieCfgData.EffectClass).new(dieCfgData.EffectCfg)

    local data = {
        targetSpacePos = RARequire("RABattleSceneManager"):getCenterPosByUnitId(self.fightUnit.id)
    }
    self.dieEffectInstance:Enter(data)    
end


return RAFU_State_JumpDie
--endregion
