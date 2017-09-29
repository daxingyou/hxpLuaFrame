local RAFU_Warhead_motionStreak = class('RAFU_Warhead_motionStreak', RARequire("RAFU_Object"))

function RAFU_Warhead_motionStreak:ctor(pWeapon,WarheadCfgName)
	self.pWeapon = pWeapon
	self.WarheadCfgName = WarheadCfgName
	local RAFU_Cfg_Warhead = RARequire("RAFU_Cfg_Warhead")
	self.warheadData = RAFU_Cfg_Warhead[WarheadCfgName]
	self.spriteName = self.warheadData.spriteName
	if self.warheadData.plist and self.warheadData.pic then
		local common = RARequire("common")
		common:addSpriteFramesWithFile(self.warheadData.plist,self.warheadData.pic)
	end

	local fadeTime = self.warheadData.fadeTime or 2
	local minSeg = self.warheadData.minSeg or -1
	local stroke = self.warheadData.stroke or 1
	local color = self.warheadData.color and ccc3(unpack(self.warheadData.color)) or ccc3(255, 255, 255) 
	local streak = CCMotionStreak:create(fadeTime, minSeg, stroke, color, self.spriteName)
	color:delete()

	local RABattleScene = RARequire('RABattleScene')
	local unitPos = pWeapon.ownerUnit:getPosition()
	streak:setPosition(ccp(unitPos.x, unitPos.y))
	self.streak = streak
	local RABattleScene = RARequire("RABattleScene")
	local parent = RABattleScene.mBattleEffectLayer
	parent:addChild(streak)

	if self.warheadData.prefixSprite then
		local sprite = CCSprite:create(self.warheadData.prefixSprite)
		parent:addChild(sprite)
		sprite:setPosition(streak:getPosition())
		self.prefixSprite = sprite
		sprite:setAnchorPoint(1, 0.5)
	end

	self.unitPos = unitPos
end

function RAFU_Warhead_motionStreak:setTargetPos(targetPos)
	local Utilitys = RARequire('Utilitys')
	local angle = Utilitys.ccpAngle(self.unitPos, targetPos)
	if self.prefixSprite then
		self.prefixSprite:setRotation(360 - angle)
	end
end

function RAFU_Warhead_motionStreak:setFadeTime(fadeTime)
	self.streak:setFadeTime(fadeTime+0.2)
end

function RAFU_Warhead_motionStreak:release()
	if self.streak ~= nil then
		RA_SAFE_REMOVEFROMPARENT(self.streak)
		self.streak = nil
	end
end

function RAFU_Warhead_motionStreak:setPosition(pos)
	if self.streak ~= nil then
		self.streak:setPosition(ccp(pos.x,pos.y))
	end
	if self.prefixSprite then
		self.prefixSprite:setPosition(pos.x, pos.y)
	end
end


function RAFU_Warhead_motionStreak:Enter(data)
    if data.offset~= nil then
		local newPos = RACcp(self.unitPos.x + data.offset.x, self.unitPos.y + data.offset.y)
		self:setPosition(newPos)
	end
end

function RAFU_Warhead_motionStreak:Exit()
    if self.streak ~= nil then
        RA_SAFE_REMOVEFROMPARENT(self.streak)
        self.streak = nil 
    end
    if self.prefixSprite then
    	RA_SAFE_REMOVEFROMPARENT(self.prefixSprite)
    	self.prefixSprite = nil
    end
end

return RAFU_Warhead_motionStreak