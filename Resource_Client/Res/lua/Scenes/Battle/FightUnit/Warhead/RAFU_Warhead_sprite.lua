--[[
description: 子弹模型
--单个sprite子弹类型相关，配置包括图片名，是否旋转，旋转次数等。
author: zhenhui
date: 2016/11/22
]]--


local RAFU_Warhead_sprite = class('RAFU_Warhead_sprite',RARequire("RAFU_Object"))


function RAFU_Warhead_sprite:ctor(pWeapon,WarheadCfgName)
	self.pWeapon = pWeapon
	self.WarheadCfgName = WarheadCfgName
	local RAFU_Cfg_Warhead = RARequire("RAFU_Cfg_Warhead")
	self.warheadData = RAFU_Cfg_Warhead[WarheadCfgName]
	self.spriteName = self.warheadData.spriteName
	local common = RARequire("common")
	common:addSpriteFramesWithFile(self.warheadData.plist,self.warheadData.pic)

	--创建sprite,同时挂接到战斗单元的父节点上
	self.sprite = CCSprite:create(self.spriteName)
	local RABattleScene = RARequire("RABattleScene")
	local parent = RABattleScene.mBattleEffectLayer
	local unitPos = pWeapon.ownerUnit:getPosition()
	parent:addChild(self.sprite)
	self.sprite:setPosition(unitPos.x,unitPos.y)
	self.sprite:setAnchorPoint(0.5,0.5)
	self.unitPos = unitPos

	--设置scale
    if self.warheadData.scaleY ~= nil then
        self:setScale(self.warheadData.scaleY)
    end
end

function RAFU_Warhead_sprite:release()
	if self.sprite ~= nil then
		RA_SAFE_REMOVEFROMPARENT(self.sprite)
		self.sprite = nil
	end
end

--set scale add phan
function RAFU_Warhead_sprite:setScale(value)
    -- body
    local scaleY = value or 1
    if self.sprite ~= nil then
    	self.sprite:setScaleY(scaleY)
    end
end

function RAFU_Warhead_sprite:setPosition(pos)
	if self.sprite ~= nil then
		self.sprite:setPosition(pos.x,pos.y)
	end
end

function RAFU_Warhead_sprite:runAction( actions )
	if self.sprite ~= nil then
		self.sprite:runAction(actions)
	end
end

function RAFU_Warhead_sprite:setSpriteArr(distance)
	local allSprites = self.warheadData.spriteArr
	if allSprites == nil then return end

	local common = RARequire('common')
	local keys = common:table_keys(allSprites)
	common:table_rsort(keys)

	for _, k in ipairs(keys) do
		if distance >= k then
			self.spriteArr = allSprites[k]
			return
		end
	end
end

function RAFU_Warhead_sprite:randomTexture()
	local len = #(self.spriteArr or {})
	if len > 0 then
		local index = math.random(1, len)
		self.sprite:setTexture(self.spriteArr[index])
	end
end

function RAFU_Warhead_sprite:getWidth()
	local size = self.sprite:getContentSize()
	local width = size.width
	size:delete()
	return width
end

function RAFU_Warhead_sprite:Enter(data)
    -- RALog("RAFU_Warhead_sprite:Enter")
    if data.offset~= nil then
		local newPos = RACcp(self.unitPos.x + data.offset.x, self.unitPos.y + data.offset.y)
		self.sprite:setPosition(newPos.x,newPos.y)
	end
end

function RAFU_Warhead_sprite:Execute(dt)
  
end

function RAFU_Warhead_sprite:Exit()
    -- RALog("RAFU_Warhead_sprite:Exit")
    if self.sprite ~= nil then
        RA_SAFE_REMOVEFROMPARENT(self.sprite)
        self.sprite = nil 
    end
    
end

return RAFU_Warhead_sprite;