--[[
description: 子弹模型
--单个sprite子弹类型相关，配置包括图片名，是否旋转，旋转次数等。
author: zhenhui
date: 2016/11/22
]]--
local common = RARequire("common")
local UIExtend = RARequire('UIExtend')
local RAFU_Warhead_ccbfile = class('RAFU_Warhead_ccbfile',RARequire("RAFU_Object"))


function RAFU_Warhead_ccbfile:ctor(pWeapon,WarheadCfgName)
	self.pWeapon = pWeapon
	self.WarheadCfgName = WarheadCfgName
	local RAFU_Cfg_Warhead = RARequire("RAFU_Cfg_Warhead")
	self.warheadData = RAFU_Cfg_Warhead[WarheadCfgName]
	self.ccbfileName = self.warheadData.ccbfileName

	common:addSpriteFramesWithFile(self.warheadData.plist,self.warheadData.pic)

	--创建sprite,同时挂接到战斗单元的父节点上
	self.sprite = UIExtend.loadCCBFile(self.ccbfileName,{})
	
	local RABattleScene = RARequire("RABattleScene")
	local parent = RABattleScene.mBattleEffectLayer
	local unitPos = pWeapon.ownerUnit:getPosition()
	parent:addChild(self.sprite)
	self.sprite:setPosition(unitPos.x,unitPos.y)
	self.sprite:setAnchorPoint(0.5,0.5)
	self.unitPos = unitPos
end

function RAFU_Warhead_sprite:release()
	RA_SAFE_REMOVEFROMPARENT(self.sprite)
end

function RAFU_Warhead_sprite:setPosition(pos)
	if self.sprite ~= nil then
		self.sprite:setPosition(pos.x,pos.y)
	end
end

function RAFU_Warhead_sprite:Enter(data)
    -- RALog("RAFU_Warhead_sprite:Enter")
    if data.offset~= nil then
		local newPos = RACcp(self.unitPos.x + data.offset.x, self.unitPos.y + data.offset.y)
		self.sprite:setPosition(newPos.x,newPos.y)
	end
end

function RAFU_Warhead_sprite:Execute()
  
end

function RAFU_Warhead_sprite:Exit()
    -- RALog("RAFU_Warhead_sprite:Exit")
    if self.sprite ~= nil then
        RA_SAFE_REMOVEFROMPARENT(self.sprite)
        self.sprite = nil 
    end
    
end


return RAFU_Warhead_ccbfile;