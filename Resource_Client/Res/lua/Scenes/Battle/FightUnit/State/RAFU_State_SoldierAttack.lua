--region RAFU_State_SoldierAttack.lua
--士兵类攻击
--Date 2016/12/22
--Author hulei
local RAFU_State_SoldierAttack = class('RAFU_State_SoldierAttack',RARequire("RAFU_State_BaseAttack"))

function RAFU_State_SoldierAttack:Enter(data)

	self.fightUnit:HelicopterRise()
	self:SetIsExecute(true)
	self.super.Enter(self,data)

end


function RAFU_State_SoldierAttack:Exit()
    if self.localAlive == true then
        self.localAlive = false
        self:SetIsExecute(false)
        for boneName,boneController in pairs(self.fightUnit.boneManager) do
            boneController:changeAction(ACTION_TYPE.ACTION_IDLE ,self.fightUnit:getDir())        
        end
    end

end

return RAFU_State_SoldierAttack
--endregion
