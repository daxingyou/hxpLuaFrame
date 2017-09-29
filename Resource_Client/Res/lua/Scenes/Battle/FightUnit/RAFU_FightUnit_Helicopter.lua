--[[region RAFU_FightUnit_Helicopter.lua
直升机,下降上升
--Date 2017/2/16
--Author phan
]]

local RAFU_FightUnit_Helicopter = class('RAFU_FightUnit_Helicopter',RARequire("RAFU_FightUnit_Basic"))

local Helicopter_State = {
    AIR = 0,    --空中
    MIDAIR = 1, --半空中
    GROUND = 2  --地面
}

--直升机降落
function RAFU_FightUnit_Helicopter:HelicopterLand()
    self.super.HelicopterLand(self)

    --if self.helicopterState ~= Helicopter_State.AIR then
        --self:setHelicopterState(Helicopter_State.AIR)
        for boneName,boneController in pairs(self.boneManager) do

            if boneName ~= "U_B_NightHawkTransport_Shadow" then

                local posY = boneController.sprite:getPositionY()

                local updateFun = function()
                    boneController.sprite:setPositionY(posY - 45)
                end

                local array = CCArray:create()
                local tmpPos = ccp(boneController.sprite:getPositionX(), posY - 25)
                local moveAction = CCMoveTo:create(3, tmpPos)
                tmpPos:delete()

                array:addObject(moveAction)

                local funcAction = CCCallFunc:create(updateFun)
                array:addObject(funcAction)

                local seq = CCSequence:create(array);

                boneController.sprite:runAction(seq)
            end
        end
    --end
end

--直升机升起
function RAFU_FightUnit_Helicopter:HelicopterRise()
    self.super.HelicopterRise(self)

   -- if self.helicopterState ~= Helicopter_State.GROUND then
        --self:setHelicopterState(Helicopter_State.GROUND)
        for boneName,boneController in pairs(self.boneManager) do

            if boneName ~= "U_B_NightHawkTransport_Shadow" then
                local posY = boneController.sprite:getPositionY()

                local updateFun = function()
                    boneController.sprite:setPositionY(posY + 45)
                end
                local array = CCArray:create()
                local tmpPos = ccp(boneController.sprite:getPositionX(),posY + 20)
                local moveAction = CCMoveTo:create(3, tmpPos)
                tmpPos:delete()

                array:addObject(moveAction)

                local funcAction = CCCallFunc:create(updateFun)
                array:addObject(funcAction)

                local seq = CCSequence:create(array);

                boneController.sprite:runAction(seq)
            end
        end
    --end
end

--获取直升机状态
-- function RAFU_FightUnit_Helicopter:getHelicopterState()
--     return self.helicopterState or Helicopter_State.AIR
-- end

-- function RAFU_FightUnit_Helicopter:setHelicopterState(state)
--     self.helicopterState = state or Helicopter_State.AIR
-- end


return RAFU_FightUnit_Helicopter