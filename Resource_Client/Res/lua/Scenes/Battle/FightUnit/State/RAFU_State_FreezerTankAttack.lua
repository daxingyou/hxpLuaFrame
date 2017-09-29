--region RAFU_State_TerrorDroneAttack.lua
--战斗单元的恐怖机器人的攻击
--Date 2017/2/5
--Author bls
RARequire('BattleField_pb')
local RAFU_State_BaseAttack = RARequire("RAFU_State_BaseAttack")
local RAFU_State_TerrorDroneAttack = class('RAFU_State_TerrorDroneAttack',RAFU_State_BaseAttack)


function RAFU_State_TerrorDroneAttack:Enter(data)
   
    RALog("RAFU_State_TankAttack:Enter")
    self.frameTime = 0
    self.localAlive = true
    assert(data~=nil,"error")
    self.data = data
    self.lifeTime = weaponAttackTime or 1
    --移动方向
    local RABattleSceneManager = RARequire("RABattleSceneManager")
    local targetId = data.targetId
    local curSpacePos = RABattleSceneManager:getCenterPosByUnitId(self.fightUnit.id)
    local targetSpacePos = RABattleSceneManager:getHitPosByUnitId(targetId)

    if targetSpacePos == nil then
        return
    end
    local jumpTime = self:clacAttackTime(curSpacePos,targetSpacePos)
    local targetpos = ccp(targetSpacePos.x,targetSpacePos.y)
    self.mTargetPosTmp =  targetpos
    local array = CCArray:create()
    local moveAction = CCMoveTo:create(jumpTime, targetpos)
    local easemove  = CCActionEase:create(moveAction)
--    local delayTime = CCDelayTime:create(0.2)
    local ccCall =  nil
    
    print("RAFU_State_TerrorDroneAttack posx= %d posy %d",targetSpacePos.x,targetSpacePos.y)

    if data.type == BattleField_pb.ATTACK then
        ccCall = CCCallFunc:create(function ( ... )
            local fireData = {
                targetSpacePos = targetSpacePos,
                attackData = data,
            }
            local weaponAttackTime = self.fightUnit.weapon:StartFire(fireData)
            self.fightUnit:changeState(STATE_TYPE.STATE_IDLE)
            end) 
    else 
        ccCall = CCCallFunc:create(function ( ... )
             self.fightUnit.rootNode:setVisible(false)
--             self.fightUnit:changeState(STATE_TYPE.STATE_DEATH)
            end) 
    end
    array:addObject(easemove)
    array:addObject(ccCall)

    local seq = CCSequence:create(array);
    self.fightUnit.rootNode:runAction(seq)
 

   local direction = RARequire("EnumManager"):calcBattle16Dir(curSpacePos,targetSpacePos)
   for boneName,boneController in pairs(self.fightUnit.boneManager) do
       boneController:changeAction(ACTION_TYPE.ACTION_SKILL_ATTACK,direction)        
   end

end

function RAFU_State_TerrorDroneAttack:Exit()
   if self.localAlive == true then
        self.localAlive = false
   end
   self.fightUnit.rootNode:setPosition(self.mTargetPosTmp)
end

function RAFU_State_TerrorDroneAttack:clacAttackTime(currentPos,targetPos)
    local disw = math.abs(currentPos.x - targetPos.x)
    local dish = math.abs(currentPos.y - targetPos.y)
    local dis = math.sqrt(disw * disw +dish * dish )
    local speed = 350
    return dis/speed
end
return RAFU_State_TerrorDroneAttack
--endregion
