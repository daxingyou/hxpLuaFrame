--[[
description: 子弹模型
--子弹下面挂在一个bone，来控制多个方向，不同序列帧的情况
author: zhenhui
date: 2016/12/15
]]--


local RAFU_Warhead_bone = class('RAFU_Warhead_bone',RARequire("RAFU_Object"))


function RAFU_Warhead_bone:ctor(pWeapon,WarheadCfgName)
	self.pWeapon = pWeapon
	self.WarheadCfgName = WarheadCfgName
	local RAFU_Cfg_Warhead = RARequire("RAFU_Cfg_Warhead")
	self.warheadData = RAFU_Cfg_Warhead[WarheadCfgName]
	
	--spriteNode 创建一个node节点
	self.spriteNode = CCNode:create()
	local RABattleScene = RARequire("RABattleScene")
	local parent = RABattleScene.mBattleEffectLayer
	local unitPos = pWeapon.ownerUnit:getPosition()
	parent:addChild(self.spriteNode)
	self.spriteNode:setPosition(unitPos.x,unitPos.y)
	self.spriteNode:setAnchorPoint(0.5,0.5)
	self.unitPos = unitPos

	local owner = self
	--创建骨骼，同时挂接在spriteNode下
	local oneBoneCfg = self.warheadData.boneCfg
	local boneFrameClass = oneBoneCfg.BoneFrameClass
	self.boneInstance = RARequire(boneFrameClass).new(owner,oneBoneCfg)

	self.localAlive = true
	
end

function RAFU_Warhead_bone:setPosition(pos)
	if self.spriteNode ~= nil then
		self.spriteNode:setPosition(pos.x,pos.y)
	end
end

function RAFU_Warhead_bone:release()
	if self.localAlive then
		self.localAlive = false
		RA_SAFE_RELEASE(self.boneInstance)

		if self.spriteNode ~= nil then
			RA_SAFE_REMOVEFROMPARENT(self.spriteNode)
		end
	end
end

function RAFU_Warhead_bone:Enter(data)
    -- RALog("RAFU_Warhead_bone:Enter")
    --self.boneInstance:changeAction(ACTION_TYPE.ACTION_IDLE, 1,nil,false)
end

function RAFU_Warhead_bone:Execute(dt)
  
end

function RAFU_Warhead_bone:Exit()
    -- RALog("RAFU_Warhead_bone:Exit")
    self:release()
    
end

return RAFU_Warhead_bone;