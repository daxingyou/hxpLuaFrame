-- RAMissionFragmentManager.lua
-- Author: xinghui
-- Using: 简报管理类

local Utilitys                      = RARequire("Utilitys")
local RAMissionVar                  = RARequire("RAMissionVar")
local RAMissionBriefingManager      = RARequire("RAMissionBriefingManager")
local RAMissionBarrierManager       = RARequire("RAMissionBarrierManager")

local RAMissionFragmentManager = {}

--[[
    desc: 关卡副本的入口
]]
function RAMissionFragmentManager:start()
    --todo:这里的条件判断要进行逻辑处理，调试阶段先写为true
    if true then
        RAMissionBarrierManager:start()
    else
        RAMissionBriefingManager:start()
    end
end

--[[
    desc: 从服务器获得数据后保存
]]
function RAMissionFragmentManager:setInfo(msg)
--设置新手真实数据
    if msg.data then
        for i=1, #msg.data do
            local info = msg.data[i]
            if info then
                if info.key == "guidefragmentbarrier" then
                    --新手
                    local arg = info.arg
                    argArr = Utilitys.Split(arg, "_")
                    RAMissionVar:setFragmentId(tonumber(argArr[1]))
                    RAMissionVar:setBarrierId(tonumber(argArr[2]))
                end
            end
        end
    end
end

--[[
    desc: 是否处于引导期
]]
function RAMissionFragmentManager:isInGuide()
    return RAMissionBriefingManager:isInGuide() or RAMissionBarrierManager:isInGuide()
end

--[[
    desc: 重置副本剧情相关数据
]]
function RAMissionFragmentManager:reset()
    RAMissionBriefingManager:reset()

    RAMissionBarrierManager:reset()

    RAMissionVar:reset()
end

return RAMissionFragmentManager