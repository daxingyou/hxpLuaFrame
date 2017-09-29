--[[
description: 数据模型
--抛射类型是无形抛射体。瞬间击中子弹,如机枪类，不会miss也不存在飞行时间
author: zhenhui
date: 2016/11/22
]]--

local RAFU_Projectile_base = RARequire("RAFU_Projectile_base")
local RAFU_Projectile_invisio = class('RAFU_Projectile_invisio',RAFU_Projectile_base)

function RAFU_Projectile_invisio:EnterEffect()

  --击中目标的数据和消息处理,基类统一处理
  self.super.EnterEffect(self)

  --子弹退出
  for k,v in pairs(self.warheadList) do
      RA_SAFE_EXIT(v)
    end
  --特效进入
  self.curState = WEAPON_PROJECT_STATE.EFFECT_STATE
  
  local data = {
        targetSpacePos = self.targetSpacePos
    }

    for k1,v1 in pairs(self.effectList) do
      if k1 ~= EFFECT_STATE_TYPE.FIRE then 
        RA_SAFE_ENTER(v1,data)
      end 
    end

    if self.effectList[EFFECT_STATE_TYPE.FIRE] ~= nil then
      self.direction = self.pWeapon.ownerUnit:getDir()

      local _offset = RACcp(0,0)
      if self.pWeapon.cfgData.warheadList ~= nil then
        local directOffsetCfg = self.pWeapon.cfgData.warheadList['main'].offset
        if self.direction ~= FU_DIRECTION_ENUM.NONE then
            _offset = directOffsetCfg[self.direction]
        end
      end

      
      
      local _startPos = RACcp(self.unitPos.x + _offset.x,self.unitPos.y + _offset.y)
      data = {
          targetSpacePos = _startPos,
          endPos = self.targetSpacePos
      }

      for k1,v1 in pairs(self.effectList) do
        if k1 == EFFECT_STATE_TYPE.FIRE then 
          RA_SAFE_ENTER(v1,data)
        end 
      end
    end
  
end


function RAFU_Projectile_invisio:Enter(data)
    -- RALog("RAFU_Projectile_invisio:Enter")
    self.super.Enter(self,data)
    
    self.effectTime = 0.2
    self.flyTime = 0
    self.lifeTime = self.effectTime + self.flyTime
    local targetSpacePos = data.targetSpacePos
    self.targetSpacePos = targetSpacePos
    self.frameTime = 0
    self.localAlive = true
    self:EnterEffect()
    return self.lifeTime
end

function RAFU_Projectile_invisio:Execute(dt)
	self.frameTime = self.frameTime + dt
	if self.frameTime > self.lifeTime and self.localAlive then
		self:Exit()
	end
end

function RAFU_Projectile_invisio:Exit()
  if self.localAlive then
      self:release()
      self.localAlive = false

      for k1,v1 in pairs(self.effectList) do
        if k1 == EFFECT_STATE_TYPE.FIRE then 
          RA_SAFE_EXIT(v1)
        end 
    end
  end
    
end

return RAFU_Projectile_invisio;