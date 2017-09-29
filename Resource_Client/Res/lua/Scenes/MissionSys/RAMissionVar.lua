-- RAMissionVar.lua
-- Author: xinghui
-- Using: 数据

local RAMissionVar = 
{
    MissionType     = 1,                --副本类型
    FragmentId      = 10000001,         --副本类型下的阶段id，默认是新手id
    BarrierId       = 0,                --副本类型下的关卡id，从服务器获取的数值是已经完成的BarrierId，进入游戏后，保存的是当前显示的barrerId
    SubCCBsOwner    = {},               --子ccb的owner数组
    WalkLineOwner   = {},               --行走线数组
}

--[[
    desc: 初始化数据
]]
function RAMissionVar:init()
    self.MissionType = 1
    self.FragmentId = 10000001
    self.BarrierId = 0
end

--[[
    desc: 设置当前的副本类型
    @param: missionType 副本类型
]]
function RAMissionVar:setMissionType(missionType)
    self.MissionType = missionType
end

--[[
    desc: 获得副本类型
]]
function RAMissionVar:getMissionType()
    return self.MissionType
end

--[[
    desc: 设置当前的阶段id
    @param: fragmentId 阶段id
]]
function RAMissionVar:setFragmentId(fragmentId)
    self.FragmentId = fragmentId
end

--[[
    desc: 获得阶段id
]]
function RAMissionVar:getFragmentId()
    return self.FragmentId
end

--[[
    desc: 设置当前的关卡id
]]
function RAMissionVar:setBarrierId(barrierId)
    self.BarrierId = barrierId
end

--[[
    desc: 获得关卡id
]]
function RAMissionVar:getBarrierId()
    return self.BarrierId
end

--[[
    desc: 添加一个ccb的owner
]]
function RAMissionVar:addCCBOwner(name, owner)
    self.SubCCBsOwner[name] = owner
end

--[[
    desc: 获得一个ccb的owner
]]
function RAMissionVar:getCCBOwner(name)
    return self.SubCCBsOwner[name]
end

--[[
    desc: 删除一个owner
]]
function RAMissionVar:deleteCCBOwner(name)
    self.SubCCBsOwner[name] = nil
end


--[[
    desc: 保存walkline
]]
function RAMissionVar:addLineOwner(id, line)
    self.WalkLineOwner[id] = line
end

--[[
    desc: 删除walkline
]]
function RAMissionVar:deleteLineOwner(id)
    self.WalkLineOwner[id] = nil
end

--[[
    desc: 删除所有walkLine
]]
function RAMissionVar:deleteAllLineOwner()
    for i, lineOwner in pairs(self.WalkLineOwner) do
        if lineOwner then
            lineOwner:release()
        end
    end
    self.WalkLineOwner = {}
end

--[[
    desc: 每一帧调用函数
]]
function RAMissionVar:update()
    for _, lineOwner in pairs(self.WalkLineOwner) do
        if lineOwner then
            lineOwner:Execute()
        end
    end
end

--[[
    desc: 重置数据
]]
function RAMissionVar:reset()
    self.MissionType     = 1                --副本类型
    self.FragmentId      = 10000001         --副本类型下的阶段id，默认是新手id
    self.BarrierId       = 0                --副本类型下的关卡id，从服务器获取的数值是已经完成的BarrierId，进入游戏后，保存的是当前显示的barrerId

    self:deleteAllLineOwner()
    
    --所有卸载都要在剧情手动配置卸载，所以这里就不需要统一卸载了
    self.SubCCBsOwner    = {}               --子ccb的owner数组

end

return RAMissionVar