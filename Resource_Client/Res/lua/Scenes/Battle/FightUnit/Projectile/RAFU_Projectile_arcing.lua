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

author: zhenhui
date: 2016/11/22
]]--

local RAFU_OribitCalc_Straight = RARequire('RAFU_OribitCalc_Straight')
local RAFU_OribitCalc_Parabola = RARequire('RAFU_OribitCalc_Parabola')
local RAFU_Projectile_base = RARequire("RAFU_Projectile_base")
local RAFU_Projectile_arcing = class('RAFU_Projectile_arcing',RAFU_Projectile_base)


--析构函数
function RAFU_Projectile_arcing:release()
	self.super.release(self)

	if self.mOribitCalc then
		self.mOribitCalc:release()
	end
end

--控制器开始
function RAFU_Projectile_arcing:Enter(data)
    -- RALog("RAFU_Projectile_arcing:Enter")

    --调用父类的Enter
    self.super.Enter(self,data)

    self.frameTime = 0
    self.lifeTime = data.lifeTime or 0.8
    self.flyTime = data.flyTime or 0.5
    self.effectTime = data.effectTime or 0.5

    local targetSpacePos = data.targetSpacePos
    self.targetSpacePos = targetSpacePos
    local unitPos = self.pWeapon.ownerUnit:getCenterPosition()
    local direction = RARequire("EnumManager"):calcBattleDir(unitPos,targetSpacePos)
    self.direction = direction
    local time = self.flyTime

    local startPos = RACcp(self.unitPos.x, self.unitPos.y)    

    self.bulletSpeed = self.pWeapon.ownerUnit.data.bulletSpeed or 200
    -- test
    -- self.bulletSpeed = 200

    local param = self:_prepareInputParam()
    self.flyTime = param.spendTime
    if self.flyTime > 0 then
	    -- 抛物线轨迹
	    local oribitCalc = RAFU_OribitCalc_Parabola.new(param)
	    -- local oribitCalc = RAFU_OribitCalc_Straight.new(param)
	    if oribitCalc.mIsNewSuccess then
		    self.mOribitCalc = oribitCalc	    
		    local calcDatas = self.mOribitCalc:Begin()	    
		    self:_HandleCalcDatas(calcDatas)
		end
	end
	self.lifeTime = self.effectTime + self.flyTime
    return self.lifeTime
end

function RAFU_Projectile_arcing:_prepareInputParam()
	local param = {}
	param.position = {}
	for k,v in pairs(self.warheadList) do
    	if v ~= nil then
    		local _offset = RACcp(0,0)
    		--warhead offset map by direction
			local directOffsetCfg = self.pWeapon.cfgData.warheadList[k].offset
		   	assert(directOffsetCfg ~= nil ,"error in directOffsetCfg")
		    if self.direction ~= FU_DIRECTION_ENUM.NONE then
		    	_offset = directOffsetCfg[self.direction]
		    end
		    local _startPos = RACcp(self.unitPos.x + _offset.x,self.unitPos.y + _offset.y)
		    param.position[k] = {
		    	startPos = _startPos,
		    	endPos = self.targetSpacePos
			}

			if v.setTargetPos then
				v:setTargetPos(self.targetSpacePos)
			end
	    end
    end
    param.speed = self.bulletSpeed
    local Utilitys = RARequire('Utilitys')
    param.pixelDistance = Utilitys.getDistance(self.unitPos, self.targetSpacePos)
    param.spendTime = param.pixelDistance / param.speed
    return param
end

function RAFU_Projectile_arcing:EnterFly()
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

	    end
    end

    local directOffsetCfg = self.pWeapon.cfgData.warheadList['main'].offset
    local _offset
    if self.direction ~= FU_DIRECTION_ENUM.NONE then
		_offset = directOffsetCfg[self.direction]
	end
    local _startPos = RACcp(self.unitPos.x + _offset.x,self.unitPos.y + _offset.y)
	data = {
    	targetSpacePos = _startPos
	}

    for k1,v1 in pairs(self.effectList) do
    	if k1 == EFFECT_STATE_TYPE.FIRE then 
    		RA_SAFE_ENTER(v1,data)
    	end 
    end
    
end

function RAFU_Projectile_arcing:EnterEffect()

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
	
	local data = {
        targetSpacePos = self.targetSpacePos
    }

    for k,v in pairs(self.effectList) do
    	if k ~= EFFECT_STATE_TYPE.FIRE then 
    		RA_SAFE_ENTER(v,data)
    	end 
    end
	
end


function RAFU_Projectile_arcing:Execute(dt)
	self.frameTime = self.frameTime + dt
	
	--状态切换
	if self.frameTime <self.flyTime then
		if self.curState ~= WEAPON_PROJECT_STATE.FLY_STATE then
			self:EnterFly()
		end
		if self.mOribitCalc then
			self:_HandleCalcDatas(self.mOribitCalc:Execute(dt))
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

			--改为在战场中循环effectList,弹道的生命周期不管理effectList
  -- 		for k1,v1 in pairs(self.effectList) do
	 --    	if k1 == EFFECT_STATE_TYPE.FIRE then 
	 --    		RA_SAFE_EXECUTE(v1,dt)
	 --    	end 
		-- end
		
	elseif self.curState == WEAPON_PROJECT_STATE.EFFECT_STATE then
		--effect time

		--改为在战场中循环effectList,弹道的生命周期不管理effectList
		-- for k,v in pairs(self.effectList) do
  -- 			RA_SAFE_EXECUTE(v,dt)
  -- 		end
  	end
end

function RAFU_Projectile_arcing:_HandleCalcDatas(calcDatas)
	if calcDatas == nil then return end
	for k,v in pairs(self.warheadList) do
		local oneData = calcDatas[k]
		if oneData then
			v:setPosition(RACcp(oneData.pos.x, oneData.pos.y))
		end
	end
end

return RAFU_Projectile_arcing