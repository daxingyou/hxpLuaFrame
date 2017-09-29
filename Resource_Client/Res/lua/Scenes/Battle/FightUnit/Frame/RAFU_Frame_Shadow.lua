--[[
description: 空中单位影子模型
author: hulei
date: 2016/12/25
]]--

local RAFU_Frame_Shadow = class('RAFU_Frame_Shadow',RARequire('RAFU_Frame_Basic'))
local RABattleConfig = RARequire('RABattleConfig')

function RAFU_Frame_Shadow:crashUp( crashUnit )
    if self.owner.coreBone and self.owner.coreBone.boneData.offsetY then
        local crashUpTime = self.owner.coreBone.boneData.crashUpTime or 0.5
        local offsetY = self.owner.coreBone.boneData.offsetY
        local height = crashUnit.confData.unitHeight or 20
        self.sprite:stopAllActions()
        self.sprite:runAction(CCScaleTo:create(crashUpTime, 0.5 + offsetY/(offsetY + height)/2 ))
    end
end

function RAFU_Frame_Shadow:crashDrop(  )
    if self.owner.coreBone then
        local crashUpTime = self.owner.coreBone.boneData.crashUpTime or 0.5
        self.sprite:stopAllActions()
        self.sprite:runAction(CCScaleTo:create(crashUpTime, 1))
    end
end

return RAFU_Frame_Shadow