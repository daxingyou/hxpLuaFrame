--[[
description: 空中单位模型
author: hulei
date: 2016/12/25
]]--

local RAFU_Frame_Aircraft = class('RAFU_Frame_Aircraft',RARequire('RAFU_Frame_Basic'))
local RABattleConfig = RARequire('RABattleConfig')

--初始化sprite
function RAFU_Frame_Aircraft:_initSprite()
    self.container = CCNode:create()
	self.sprite = CCSprite:create("empty.png")
    local zorder = self.boneData.Zorder  

	self.owner.spriteNode:addChild(self.container,zorder)
    self.container:addChild(self.sprite)

    self:initSpriteInfo()
end

function RAFU_Frame_Aircraft:initSpriteInfo()
    self.isCrashUp = RABattleConfig.AircraftCrashType.CRASH_STAND -- 是否与地面部队重叠而升高
    self.crashUpTime = self.boneData.crashUpTime or 0.5

    local scale = self.boneData.scale or 1.0
    self.sprite:setAnchorPoint(0.5,0.5)
    self.sprite:setScale(scale)
    local x = 0
    local y = 0

    if self.boneData.imageOffsetY ~= nil then 
        y = y + self.boneData.imageOffsetY
    end

    if self.boneData.imageOffsetX ~= nil then 
        x = x + self.boneData.imageOffsetX
    end 

    self.sprite:setPosition(ccp(x,y)) 
    self.currentAction = ACTION_TYPE.ACTION_IDLE
    self.currentDirection = FU_DIRECTION_ENUM.DIR_DOWN_LEFT
    self:changeAction(self.currentAction, self.currentDirection)   
end

function RAFU_Frame_Aircraft:getOffsetY( )
    self.boneData.offsetY = self.boneData.offsetY or 0
    return self.boneData.offsetY + self.container:getPositionY()
end

function RAFU_Frame_Aircraft:crashUp( crashUnit )
    self.isCrashUp = RABattleConfig.AircraftCrashType.CRASH_UP
    local height = crashUnit.confData.unitHeight or 20
    self.container:stopAllActions()
    self.container:runAction(CCSequence:createWithTwoActions(CCJumpTo:create(self.crashUpTime,ccp(0,height),10,1), CCCallFunc:create(function( ... )
        self.isCrashUp = RABattleConfig.AircraftCrashType.CRASH_HIGH
    end)))
end

function RAFU_Frame_Aircraft:crashDrop(  )
    self.isCrashUp = 3
    self.container:stopAllActions()
    self.container:runAction(CCSequence:createWithTwoActions(CCJumpTo:create(self.crashUpTime,ccp(0,0),10,1), CCCallFunc:create(function( ... )
        self.isCrashUp = RABattleConfig.AircraftCrashType.CRASH_DOWN
    end)))    
end

--析构函数
function RAFU_Frame_Aircraft:release()
    if self.AllActionData ~= nil then
        self.AllActionData:release()
    end
    self.isCrashUp = RABattleConfig.AircraftCrashType.CRASH_STAND
    RA_SAFE_REMOVEFROMPARENT(self.container)
end


return RAFU_Frame_Aircraft