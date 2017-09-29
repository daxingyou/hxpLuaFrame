--[[
description: 子弹模型
author: hulei
date: 2016/12/16
]]--


local RAFU_Warhead_frame = class('RAFU_Warhead_frame',RARequire("RAFU_Warhead_sprite"))


function RAFU_Warhead_frame:ctor(pWeapon,WarheadCfgName)
	self.pWeapon = pWeapon
	self.WarheadCfgName = WarheadCfgName
	local RAFU_Cfg_Warhead = RARequire("RAFU_Cfg_Warhead")
	self.warheadData = RAFU_Cfg_Warhead[WarheadCfgName]
	
	local common = RARequire("common")
	common:addSpriteFramesWithFile(self.warheadData.plist,self.warheadData.pic)

	if self.warheadData.frameNum and self.warheadData.frameNum ~= 1 then
		--todo
	else
		local dir = pWeapon.ownerUnit:getDir()
		self.spriteName = self.warheadData.frameBase.."_"..dir.."_1.png"
		--创建sprite,同时挂接到战斗单元的父节点上
		self.sprite = CCSprite:create(self.spriteName)
		local RABattleScene = RARequire("RABattleScene")
		local parent = RABattleScene.mBattleUnitLayer
		local unitPos = pWeapon.ownerUnit:getCenterPosition()
		parent:addChild(self.sprite)
		self.sprite:setPosition(unitPos.x,unitPos.y)
		self.sprite:setAnchorPoint(0.5,0.5)
		self.sprite:setZOrder(pWeapon.ownerUnit.rootNode:getZOrder() - 1)
		self.unitPos = unitPos
	end
end


function RAFU_Warhead_frame:Execute(dt)
  	self.sprite:setZOrder(10000 - 1 * self.sprite:getPositionY())
end

return RAFU_Warhead_frame;