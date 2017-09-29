--region RAFU_State_ZepDie.lua
--飞艇死亡类
--Date 2016/12/15
--Author hulei
local RAFU_State_ZepDie = class('RAFU_State_ZepDie',RARequire("RAFU_State_BaseDie"))

function RAFU_State_ZepDie:_DieAction()
    -- self.fightUnit.rootNode:runAction(CCEaseIn:create(CCMoveBy:create(0.2, ccp(0,-60)), 1))
    local curDir = self.fightUnit:getDir()
    
    local changeDirection = math.random(8,15)
    local timeScale = changeDirection/12
    self.dieActionTime = self.dieActionTime * timeScale
    self.lifetime = self.dieActionTime + self.dieEffectTime
    local direction = (curDir + changeDirection)%16
    for boneName,boneController in pairs(self.fightUnit.boneManager) do
        boneController:changeAction(ACTION_TYPE.ACTION_DEATH,direction, {isCircle = true})
        if boneController.boneData.isTop == false then
            boneController.sprite:runAction(CCScaleTo:create(self.dieActionTime , boneController.boneData.dieShadowScale or 1.5))
        end
    end
    self.fightUnit.coreBone.sprite:runAction(CCEaseIn:create(CCMoveBy:create(self.dieActionTime , ccp(0,-self.fightUnit.coreBone:getOffsetY())), 2))
      
end

function RAFU_State_ZepDie:Execute(dt)
    self.super.Execute(self,dt)
    RA_SAFE_EXECUTE(self.dieEffectInstance,dt)
end

function RAFU_State_ZepDie:Exit()
    self.super.Exit(self)
    RA_SAFE_EXIT(self.dieEffectInstance)
end

function RAFU_State_ZepDie:_DieEffect()
    for boneName,boneController in pairs(self.fightUnit.boneManager) do
        boneController.sprite:setVisible(false)
    end    
    local dieCfgData = self.fightUnit.cfgData.DieCfg
    self.dieEffectInstance = RARequire(dieCfgData.EffectClass).new(dieCfgData.EffectCfg)

    local data = {
        targetSpacePos = self.fightUnit:getPosition()
    }
    self.dieEffectInstance:Enter(data)
end

return RAFU_State_ZepDie
--endregion
