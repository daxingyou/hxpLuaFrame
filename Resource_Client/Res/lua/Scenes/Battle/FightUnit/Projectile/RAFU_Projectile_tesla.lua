--[[
    description: 数据模型
    author: royhu
    date: 2016/12/13
]]--

local RAFU_Projectile_base = RARequire('RAFU_Projectile_base')
local RAFU_Projectile_tesla = class('RAFU_Projectile_tesla', RAFU_Projectile_base)

local Utilitys = RARequire('Utilitys')

function RAFU_Projectile_tesla:EnterEffect()

    --击中目标的数据和消息处理,基类统一处理
    self.super.EnterEffect(self)


  	--子弹退出
	-- for k,v in pairs(self.warheadList) do
 --    	RA_SAFE_EXIT(v)
	-- end
  	--特效进入
  	self.curState = WEAPON_PROJECT_STATE.EFFECT_STATE
  
  	local data = {
        targetSpacePos = self.targetSpacePos
    }

    for k,v in pairs(self.effectList) do
    	RA_SAFE_ENTER(v,data)
    end
end


function RAFU_Projectile_tesla:Enter(data)
    self.super.Enter(self, data)

    self.frameTime = 0 
    self.flyTime =  0.5
    self.effectTime = 0.3
    self.lifeTime = data.lifeTime or self.flyTime



    local targetSpacePos = data.targetSpacePos
    self.targetSpacePos = targetSpacePos
    local unitPos = self.unitPos
    local direction = RARequire('EnumManager'):calcBattle16Dir(unitPos, targetSpacePos)
    self.direction = direction

    local _offset = RACcp(0, 0)
    local directOffsetCfg = self.pWeapon.cfgData.warheadList['main'].offset
    assert(directOffsetCfg ~= nil, "error in directOffsetCfg")
    if self.direction ~= FU_DIRECTION_ENUM.NONE then
        _offset = directOffsetCfg[self.direction] or _offset
    end
    unitPos = RACcp(self.unitPos.x + _offset.x, self.unitPos.y + _offset.y)

    local vecX = targetSpacePos.x - unitPos.x
    local vecY = targetSpacePos.y - unitPos.y
    -- local orX = 1
    -- local orY = 0
    -- local cos = (orX*vecX + orY*vecY)/(math.sqrt(orX*orX+orY*orY)*math.sqrt(vecX*vecX + vecY*vecY))
    -- local deg = math.acos(cos) 

    local deg = 360 - Utilitys.getDegree(vecX, vecY)
    local distance = math.sqrt(vecX * vecX + vecY * vecY)

    local spriteWidth = distance
    for k,v in pairs(self.warheadList) do
    	v:setSpriteArr(distance)
    	-- v:randomTexture()
    	v:setPosition(unitPos)
    	v.sprite:setTextureRepeatEnable(true)
    	v.sprite:setPreferedSize(CCSizeMake(distance, 64))
    	v.sprite:setTextureRepeatSpeed(ccp(0, 64))
    	v.sprite:setTextureRepeatInterval(ccp(0.1, 0.034))

    	v.sprite:setAnchorPoint(0, 0.5)
    	v.sprite:setRotation(deg)
    	spriteWidth = v:getWidth()

    	local k = spriteWidth / distance
    	self.targetSpacePos = RACcp(unitPos.x + vecX * k, unitPos.y + vecY * k)
    end
    
    self:EnterEffect()
   
    return self.lifeTime
end

function RAFU_Projectile_tesla:Execute(dt)
	self.frameTime = self.frameTime + dt
	if self.frameTime > self.lifeTime and self.localAlive then
		self:Exit()
	elseif self.localAlive then
	    for k,v in pairs(self.warheadList) do
	    	-- v:randomTexture()
	    end
	end
end

return RAFU_Projectile_tesla