--[[
description: 数据模型
抛射类型是抛射体。如导弹，tank的子弹等
武器抛射体状态包括飞行状态和特效状态

WEAPON_PROJECT_STATE ={
	NONE = 0, --空状态
	FLY_STATE = 1,--飞行状态
	EFFECT_STATE = 2, --特效状态
	DESTROY = 3
}

author: hulei
date: 2016/12/16
]]--

local RAFU_Projectile_base = RARequire("RAFU_Projectile_base")
local RAFU_Projectile_zep = class('RAFU_Projectile_zep',RAFU_Projectile_base)


--析构函数
function RAFU_Projectile_zep:release()
	self.super.release(self)
end

--控制器开始
function RAFU_Projectile_zep:Enter(data)
    -- RALog("RAFU_Projectile_zep:Enter")

    --调用父类的Enter
    self.super.Enter(self,data)

    self.frameTime = 0
    self.lifeTime = data.lifeTime or 0.8
    self.flyTime = data.flyTime or 0.5
    self.effectTime = data.effectTime or 0.3
    self.direction = self.pWeapon.ownerUnit:getDir()

    local unitPos = self.pWeapon.ownerUnit:getCenterPosition()
    local offsetY = self.pWeapon.ownerUnit:_getCoreBonePosOffset()
    local time = self.flyTime

    self.startPos = RACcp(self.unitPos.x, self.unitPos.y)    
    self.targetSpacePos = RACcp(self.unitPos.x, self.unitPos.y - offsetY)
    self.bulletSpeedAdd = self.pWeapon.ownerUnit.data.bulletSpeed or 100

    self.flyTime = math.sqrt(offsetY*2/self.bulletSpeedAdd)
	self.lifeTime = self.effectTime + self.flyTime
    return self.lifeTime
end


function RAFU_Projectile_zep:EnterFly()
	self.curState = WEAPON_PROJECT_STATE.FLY_STATE
	 --子弹bind，ENTER
    local this = self
    for k,v in pairs(self.warheadList) do
    	if v ~= nil then
    		local _offset = RACcp(0,0)
    		--warhead offset map by direction
			local directOffsetCfg = self.pWeapon.cfgData.warheadList[k].offset
		   	assert(directOffsetCfg ~= nil ,"error in directOffsetCfg")
		    if self.direction ~= FU_DIRECTION_ENUM.NONE then
		    	_offset = directOffsetCfg[self.direction]
		    end
		    local data = {
		    	offset = _offset
			}
	   		v:Enter(data)
	   		if k == "main" then
	   			v:runAction(CCEaseIn:create(CCMoveBy:create(self.flyTime, ccp(0, -self.pWeapon.ownerUnit:_getCoreBonePosOffset())), 2))
	   		end
	    end
    end
    
end

function RAFU_Projectile_zep:EnterEffect()

	--击中目标的数据和消息处理,基类统一处理
	self.super.EnterEffect(self)

	--子弹退出
	for k,v in pairs(self.warheadList) do
    	RA_SAFE_EXIT(v)
    end

    for k1,v1 in pairs(self.effectList) do
    	if k1 == EFFECT_STATE_TYPE.FIRE then 
    		RA_SAFE_EXIT(v1)
    	end 
	end

	--特效进入
	self.curState = WEAPON_PROJECT_STATE.EFFECT_STATE
	
    local directOffsetCfg = self.pWeapon.cfgData.warheadList['main'].offset
    local _offset = RACcp(0,0)
    if self.direction ~= FU_DIRECTION_ENUM.NONE then
		_offset = directOffsetCfg[self.direction]
	end
	local data = {
        targetSpacePos = RACcp(self.startPos.x + _offset.x, self.startPos.y +  _offset.y)
    }

    for k,v in pairs(self.effectList) do
    	if k ~= EFFECT_STATE_TYPE.FIRE then 
    		RA_SAFE_ENTER(v,data)
    	end 
    end
	
end


function RAFU_Projectile_zep:Execute(dt)
	self.frameTime = self.frameTime + dt
	
	--状态切换
	if self.frameTime <self.flyTime then
		if self.curState ~= WEAPON_PROJECT_STATE.FLY_STATE then
			self:EnterFly()
		end
	elseif self.frameTime <self.lifeTime then
		if self.curState ~= WEAPON_PROJECT_STATE.EFFECT_STATE then
			self:EnterEffect()
		end
	else
		--one projectile finish
		self:Exit()
		self:release()
	end
  	
	--状态帧tick
  	if self.curState == WEAPON_PROJECT_STATE.FLY_STATE then
  		--bullet fly time
  		for k,v in pairs(self.warheadList) do
  			RA_SAFE_EXECUTE(v,dt)
  		end	
  	end
end


return RAFU_Projectile_zep