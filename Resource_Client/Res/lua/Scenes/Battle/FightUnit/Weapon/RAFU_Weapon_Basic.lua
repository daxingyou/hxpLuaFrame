--[[
description: 武器的基础类
--武器 包含 子弹 + 到达之后的特效 + 抛射控制器
--一个武器可能发射出多个弹道，也就是 _projectleTable 
author: zhenhui
date: 2016/11/22
]]--

local RAFU_Weapon_Basic = class('RAFU_Weapon_Basic',RARequire("RAFU_Object"))

function RAFU_Weapon_Basic:ctor(ownerUnit,cfgName)
    -- RALog("RAFU_Weapon_Basic:ctor")
    local RAFU_Cfg_Weapon = RARequire("RAFU_Cfg_Weapon")
    local cfgData = RAFU_Cfg_Weapon[cfgName]
    self.cfgName = cfgName
    assert(cfgData~=nil,"error")
    local projectileClass = cfgData.projectileClass
    assert(projectileClass ~= nil ,"projectileClass ~= nil")
    self.ownerUnit = ownerUnit
    self.projectileClass = projectileClass
    self.cfgData = cfgData

end

function RAFU_Weapon_Basic:getOwnerUnit()
    if self.ownerUnit ~= nil then
        return self.ownerUnit
    end
end


function RAFU_Weapon_Basic:release()
    

end

--基础的开始攻击方法
function RAFU_Weapon_Basic:StartFire(data)
    if self.ownerUnit.isAlive == false then return end
    
    local cfgData = self.cfgData

    --  targetType: 获取目标类型
    local targetType = nil
    local RABattleSceneManager = RARequire('RABattleSceneManager')
    if (data.attackData or {}).targetId then
        local targetUnit = RABattleSceneManager:getUnitCfgByUnitId(data.attackData.targetId)
        if targetUnit == nil then
            return 0
        end
        targetType = targetUnit.type
    else
        -- targetType = 4 -- TODO
    end

    --真实的子弹，list
    self.warheadList = {}
    if cfgData.warheadList ~= nil then
        local common = RARequire('common')
        for k,oneWarheadData in pairs(cfgData.warheadList) do
            local warheadClass = oneWarheadData.warheadClass
            local warheadInstance = nil
            if warheadClass ~= nil then
                -- 判断子弹目标类型与攻击类型是否符合，符合才创建实例
                local needInstance = true
                if targetType and oneWarheadData.targetType then
                    needInstance = common:table_contains(oneWarheadData.targetType, targetType)
                elseif targetType and oneWarheadData.excludeTargetType then
                    needInstance = not common:table_contains(oneWarheadData.excludeTargetType, targetType)
                end

                if needInstance then
                    local pWeapon = self
                    warheadInstance = RARequire(warheadClass).new(pWeapon,oneWarheadData.warheadCfgName)
                end
            end
            
            self.warheadList[k] = warheadInstance
        end

    end

    --子弹到达之后的特效Effect
    self.effectList = {}
    if cfgData.effectList ~= nil then
        for k,oneEffectCfg in pairs(cfgData.effectList) do
            local effectClass = oneEffectCfg.effectClass
            local effectInstance = nil
            if effectClass ~= nil then
                effectInstance = RARequire(effectClass).new(oneEffectCfg.effectCfgName)
            end
            self.effectList[k] = effectInstance
        end
    end
    

    local pWeapon = self
    --运动轨迹+控制器，控制器管理子弹和特效的生命周期和曲线
    local uuid = RARequire("uuid")
    local projectUUID = uuid.new()
    local projectInstance = RARequire(self.projectileClass).new(projectUUID,pWeapon,self.warheadList,self.effectList)
    local attackLiftTime = projectInstance:Enter(data)
    --添加进入游戏场景中
    projectInstance:AddToBattleScene()


    return attackLiftTime

end

function RAFU_Weapon_Basic:Execute(dt)
    
end

function RAFU_Weapon_Basic:Exit()
   
end

return RAFU_Weapon_Basic
--endregion
