-- RAMissionBriefingManager.lua
-- Author: xinghui
-- Using: 简报管理类

local fragment_conf                 = RARequire("fragment_conf")
local story_conf                    = RARequire("story_conf")
local RAMissionVar                  = RARequire("RAMissionVar")
local RAMissionBarrierManager       = RARequire("RAMissionBarrierManager")
local RAMissionActionManager        = RARequire("RAMissionActionManager")
local SysProtocol_pb                = RARequire("SysProtocol_pb")
local HP_pb                         = RARequire("HP_pb")
local RANetUtil                     = RARequire("RANetUtil")



local RAMissionBriefingManager = {
    storyId = 0,                        --简报id
    constStoryInfo = nil,               --简报配置信息，由storyId标示
    currentStep = 0                     --标示在story_conf中的第几步
}

--[[
    desc: 简报的起点，添加简报页，初始化数据
]]
function RAMissionBriefingManager:start()
    self:_resetData()

    --添加简报页面
    local fragmentId = RAMissionVar:getFragmentId()
    local constFramgmentInfo = fragment_conf[fragmentId]
    self.storyId = constFramgmentInfo.storyId
    self.constStoryInfo = story_conf[self.storyId]
end

--[[
    desc: 简报进入下一步，每一步只有一个startActionId，接下来的动作由该action的nextAction决定。
]]
function RAMissionBriefingManager:gotoNextStep()
    if self.currentStep == 0 then
        self.currentStep = self.constStoryInfo.startStepId
    else
        self.currentStep = self.constStoryInfo[self.currentStep].nextStepId
    end

    if self.currentStep == nil then
        --简报结束，进入关卡
        self:_saveBriefingOver()
        RAMissionBarrierManager:start()
    else
        RAMissionActionManager:startAction(self.constStoryInfo[self.currentStep].startActionId)
    end
end

--[[
    desc: 简报走完后会进行保存
]]
function RAMissionBriefingManager:_saveBriefingOver()
    local msg = SysProtocol_pb.HPCustomDataDefine()
    msg.data.key = "briefingid"
    msg.data.val = self.storyId
    RANetUtil:sendPacket(HP_pb.CUSTOM_DATA_DEFINE, msg, {retOpcode = -1})
end

--[[
    desc: 重置数据
]]
function RAMissionBriefingManager:_resetData()
    self.storyId = 0
    self.constStoryInfo = nil
    self.currentStep = 0
end


--[[
    desc: 是否在新手期
]]
function RAMissionBriefingManager:isInGuide()
    return false
end

--[[
    desc: 重置数据
]]
function RAMissionBriefingManager:reset()
    self:_resetData()
end

return RAMissionBriefingManager