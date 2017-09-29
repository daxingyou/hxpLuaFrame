--[[
    description: 光陵坦克攻击效果
    author: 	 royhu
    date: 		 2016/12/30
]]--

local RAFU_Projectile_base = RARequire('RAFU_Projectile_base')
local RAFU_Projectile_prism = class('RAFU_Projectile_prism', RAFU_Projectile_base)

local Utilitys = RARequire('Utilitys')
local UIExtend = RARequire('UIExtend')

RAFU_Projectile_prism.mExtraWarheadList = {}
RAFU_Projectile_prism.mExtraEffectList = {}
RAFU_Projectile_prism.mSpriteName = nil
RAFU_Projectile_prism.mSpriteWidth = 1
RAFU_Projectile_prism.mEffectCfg = nil


function RAFU_Projectile_prism:EnterEffect()
    --击中目标的数据和消息处理,基类统一处理
    self.super.EnterEffect(self)

  	--特效进入
  	self.curState = WEAPON_PROJECT_STATE.EFFECT_STATE
  
  	local data = {
        targetSpacePos = self.targetSpacePos
    }

    for k,v in pairs(self.effectList) do
    	RA_SAFE_ENTER(v, data)
    end

    self:_addExtraEffect()
end

-- 添加散列效果
function RAFU_Projectile_prism:_addExtraEffect()
	local RABattleScene = RARequire("RABattleScene")
	local parent = RABattleScene.mBattleEffectLayer
	local this = self

	self.mExtraWarheadList = {}
	self.mExtraEffectList = {}
	local effectCfg = self.pWeapon.cfgData.effectList
    
    local countRange = self.mEffectCfg.countRange or {3, 6}
    local degreeRange = self.mEffectCfg.degreeRange or {20, 340}
    local distanceRange = self.mEffectCfg.distanceRange or {50, 100}
    local timePercent = self.mEffectCfg.timePercent[1] or 0.2
    local scaleY = self.mEffectCfg.scaleY or 1
    local math, unpack = math, unpack

    local cnt = math.random(unpack(countRange))
    for i = 1, cnt do
    	local sprite = CCSprite:create(self.mSpriteName)
    	parent:addChild(sprite)
    	sprite:setPosition(self.targetSpacePos.x, self.targetSpacePos.y)
    	sprite:setAnchorPoint(0, 0.5)
    	-- sprite:setScaleX(0.1)
    	sprite:setScaleY(scaleY)
    	UIExtend.setBlendFunc(sprite, GL_ONE, GL_ONE)
    	table.insert(self.mExtraWarheadList, sprite)

    	local deg = math.random(unpack(degreeRange))
    	sprite:setRotation(360 - deg)
    	local scale = math.random(unpack(distanceRange)) * 0.01
    	-- local scaleAction = CCScaleTo:create(self.flyTime * timePercent, scale, scaleY)
    	sprite:setScaleX(scale)

    	local angle = math.rad(deg)
    	local distance = self.mSpriteWidth * scale
    	local dropInfo =
    	{
    		targetSpacePos =
    		{
		    	x = self.targetSpacePos.x + distance * math.cos(angle),
		    	y = self.targetSpacePos.y + distance * math.sin(angle)
    		}
    	}

    	-- UIExtend.runActionWithCallback(sprite, scaleAction, function()
	        for k, oneEffectCfg in pairs(effectCfg) do
	            local effectClass = oneEffectCfg.effectClass
	            if effectClass ~= nil then
	                local effectInstance = RARequire(effectClass).new(oneEffectCfg.effectCfgName)
	                table.insert(this.mExtraEffectList, effectInstance)
	                RA_SAFE_ENTER(effectInstance, dropInfo)
	            end
	        end
    	-- end)
    end
end


function RAFU_Projectile_prism:Enter(data)
    self.super.Enter(self, data)

    self.frameTime = 0 
    self.flyTime =  0.5
    self.effectTime = 0.3
    self.lifeTime = data.lifeTime or self.flyTime

    local targetSpacePos = data.targetSpacePos
    self.targetSpacePos = targetSpacePos
    local unitPos = self.unitPos
    local warhead = self.warheadList['main']
    local direction = RARequire('EnumManager'):calcBattle16Dir(unitPos, targetSpacePos)

    local _offset = RACcp(0, 0)
    local directOffsetCfg = (self.pWeapon.cfgData.warheadList['main'] or {}).offset
    if directOffsetCfg and  direction ~= FU_DIRECTION_ENUM.NONE then
        _offset = directOffsetCfg[direction] or _offset
    end
    unitPos = RACcp(self.unitPos.x + _offset.x, self.unitPos.y + _offset.y)

    local vecX = targetSpacePos.x - unitPos.x
    local vecY = targetSpacePos.y - unitPos.y

    local deg = 360 - Utilitys.getDegree(vecX, vecY)
    local distance = math.sqrt(vecX * vecX + vecY * vecY)

    self.mSpriteName = warhead.spriteName
    self.mSpriteWidth = warhead:getWidth()
    self.mEffectCfg = warhead.warheadData.effCfg

	warhead.sprite:setPosition(unitPos.x, unitPos.y)
	warhead.sprite:setAnchorPoint(0, 0.5)
	-- warhead.sprite:setScaleX(0.1)
	warhead.sprite:setScaleY(self.mEffectCfg.scaleY)
	warhead.sprite:setRotation(deg)
	UIExtend.setBlendFunc(warhead.sprite, GL_ONE, GL_ONE)

	local scale = distance / self.mSpriteWidth
	warhead.sprite:setScaleX(scale)
	-- local timePercent = self.mEffectCfg.timePercent[0] or 0.3
	-- local scaleAction = CCScaleTo:create(self.flyTime * timePercent, scale, self.mEffectCfg.scaleY)
	local this = self
	-- UIExtend.runActionWithCallback(warhead.sprite, scaleAction, function()
		this:EnterEffect()
	-- end)

    return self.lifeTime
end

function RAFU_Projectile_prism:Execute(dt)
	self.frameTime = self.frameTime + dt
	if self.frameTime > self.lifeTime and self.localAlive then
		self:Exit()
	end
end

function RAFU_Projectile_prism:Exit()
	for k,v in pairs(self.warheadList) do
    	RA_SAFE_EXIT(v)
	end

	for k, v in pairs(self.mExtraWarheadList) do
		RA_SAFE_REMOVEFROMPARENT(v)
	end
	self.mExtraWarheadList = {}

	for k, v in pairs(self.mExtraEffectList) do
		RA_SAFE_EXIT(v)
	end
	self.mExtraEffectList = {}
end

return RAFU_Projectile_prism