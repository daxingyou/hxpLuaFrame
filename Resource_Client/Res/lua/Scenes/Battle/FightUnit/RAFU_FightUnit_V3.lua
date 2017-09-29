--[[region RAFU_FightUnit_V3.lua
 V3 发射车创建v3炮弹的cd
 本技能只会用一个，所以没有做技能列表的区分
--Date 2016/12/26
--Author qinho
]]


local RAFU_FightUnit_V3 = class('RAFU_FightUnit_V3',RARequire("RAFU_FightUnit_Basic"))

-- 为空的时候，清空，且设置可见
function RAFU_FightUnit_V3:SetSkillUsed(skillId)
    local isHandled = false
    for index,skillData in pairs(self.data.skills) do
        if skillData.skillId == skillId and skillData.skillCd > 0 then
            self.mSkillUsed = skillId
            -- 变成毫秒
            self.mSkillCd = skillData.skillCd * 1000 
            self.mLastSkillTime = CCTime:getCurrentTime()
            self:SetV3UpPartVisible(false)    
            isHandled = true
        end
    end
    if not isHandled then
        self.mSkillUsed = nil
        self.mSkillCd = 0
        self:SetV3UpPartVisible(true)
    end
end

function RAFU_FightUnit_V3:SetV3UpPartVisible(value)
    for boneName,boneController in pairs(self.boneManager) do
        if boneName ~= self.cfgData.Bones.CoreBone then
            boneController.sprite:setVisible(value)
        end
    end
end


-- 用于子类添加个性化属性
function RAFU_FightUnit_V3:_initSpecificProperty()
    self.super._initSpecificProperty(self)

    -- 使用的技能id
    self.mSkillUsed = nil
    self.mSkillCd = 0
end



-- 方便子类添加自己的刷新逻辑
function RAFU_FightUnit_V3:_executeSpecific(dt)    
    if self.mSkillUsed ~= nil and self.mSkillCd > 0 then
        local curTime = CCTime:getCurrentTime()
        if curTime - self.mLastSkillTime >= self.mSkillCd then
            self.mSkillUsed = nil
            self.mSkillCd = 0
            self:SetV3UpPartVisible(true)
            return
        end
    end
end

return RAFU_FightUnit_V3