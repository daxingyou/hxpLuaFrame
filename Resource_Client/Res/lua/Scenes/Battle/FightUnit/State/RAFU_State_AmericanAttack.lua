--region RAFU_State_SoldierAttack.lua
--士兵类攻击
--Date 2016/12/22
--Author hulei
local RAFU_State_AmericanAttack = class('RAFU_State_AmericanAttack',RARequire("RAFU_State_BaseAttack"))
local EnumManager = RARequire("EnumManager")
    

function RAFU_State_AmericanAttack:Enter(data)
    RALog("RAFU_State_BaseAttack:Enter")
    self:SetIsExecute(true)
    self.frameTime = 0
    self.localAlive = true
    assert(data~=nil,"error")
    self.data = data
    local attackAction = data
    assert(attackAction~=nil,"error")
    
    self.sitTime = 0
    self.lifeTime = 10 --要大于sitTime
    self.beginFire = false
    if self.fightUnit.state == EnumManager.UNIT_STATE.STAND then
    	self.fightUnit.state = EnumManager.UNIT_STATE.SIT
    	self.sitTime = 0.2
	    --自身的动作相关
	    for boneName,boneController in pairs(self.fightUnit.boneManager) do
	        boneController:changeAction(ACTION_TYPE.ACTION_SIT_DOWN,self.fightUnit:getDir())        
	    end    	
    end

    if self.fightUnit.addAttackTime then 
        self.fightUnit:addAttackTime()
    end
end

function RAFU_State_AmericanAttack:StartFire(  )
	local data = self.data
	self.beginFire = true
    --移动方向
    local RABattleSceneManager = RARequire("RABattleSceneManager")
    local targetId = data.targetId
    local curSpacePos = RABattleSceneManager:getCenterPosByUnitId(self.fightUnit.id)
    local targetSpacePos = RABattleSceneManager:getCenterPosByUnitId(targetId)
    local direction = RARequire("EnumManager"):calcBattleDir(curSpacePos,targetSpacePos)
    assert(direction~=nil,"direction error")

    self.direction = direction
    --武器开火相关
    local fireData = {
        targetSpacePos = RABattleSceneManager:getHitPosByUnitId(targetId),
        attackData = data
    }
    local weaponAttackTime = self.fightUnit.weapon:StartFire(fireData)
    self.lifeTime = (weaponAttackTime or 1) + self.sitTime

    --设置移动方向
    self.fightUnit:setDir(direction)

    --自身的动作相关
    for boneName,boneController in pairs(self.fightUnit.boneManager) do
        boneController:changeAction(ACTION_TYPE.ACTION_SIT_ATTACK,direction)        
    end
end

function RAFU_State_AmericanAttack:Execute(dt)
	if self.localAlive == true then
	    self.frameTime = self.frameTime + dt
	    if not self.beginFire and self.frameTime > self.sitTime and self.localAlive then
	        self:StartFire()
	    end
	    if self.beginFire and self.frameTime > self.lifeTime and self.localAlive then
	        self:Exit()
	    end
	end
end

function RAFU_State_AmericanAttack:Exit()
    if self.localAlive == true then
        self.localAlive = false
        if self.beginFire == false then
            self:StartFire()
        end
        self.beginFire = false
        self:SetIsExecute(false)
        for boneName,boneController in pairs(self.fightUnit.boneManager) do
            boneController:changeAction(ACTION_TYPE.ACTION_SIT_IDLE ,self.fightUnit:getDir())        
        end
    end

end

return RAFU_State_AmericanAttack
--endregion
