-- RAMissionBarrierManager.lua
-- Author: xinghui
-- Using: 关卡管理类

local HP_pb                     = RARequire("HP_pb")
local RANetUtil                 = RARequire("RANetUtil")
local SysProtocol_pb            = RARequire("SysProtocol_pb")
local RARootManager             = RARequire("RARootManager")
local RAMissionActionManager    = RARequire("RAMissionActionManager")
local barrier_conf              = RARequire("barrier_conf")
local fragment_conf             = RARequire("fragment_conf")
local RAMissionVar              = RARequire("RAMissionVar")
local Utilitys                  = RARequire("Utilitys")
local RAGuideManager            = RARequire("RAGuideManager")

local RAMissionBarrierManager   = {
    currentStep         = 0,                    --当前关卡第几步
    constBarrierInfo    = nil,
    sceneCamera         = nil,                  --场景摄像机
    isInBarrier         = false                 --是否在剧情中
}

--[[
    desc: 关卡起点
]]
function RAMissionBarrierManager:start()
    self:_resetData()

    self.isInBarrier = true
    --RARootManager.ChangeScene(SceneTypeList.MissionBarrierScene, true)

    --self:gotoBarrier(RAMissionVar:getBarrierId())
    self:gotoNextBarrier()
end

--[[
    desc: 关卡进入下一步
]]
function RAMissionBarrierManager:gotoNextStep()
    if self.currentStep == 0 then
        self.currentStep = self.constBarrierInfo.startStepId
    else
        self.currentStep = self.constBarrierInfo[self.currentStep].nextStepId
    end

    if self.currentStep == nil then
        --下一步没有了，进入下一关
        RAMissionBarrierManager:gotoNextBarrier()
    else
        RAMissionActionManager:startAction(self.constBarrierInfo[self.currentStep].startActionId)
    end
end

--[[
    desc: 进入关卡
]]
function RAMissionBarrierManager:gotoBarrier(barrierId)
    if barrierId then
        --设置当前关卡的相关数据
        RAMissionVar:setBarrierId(barrierId)
        self.constBarrierInfo = barrier_conf[barrierId]
        self.currentStep = 0
        self.isInBarrier = true
        --进入关卡之前，判断一些场景的逻辑，主要是为了适应战斗是视频或者是scene，以及加载不同的armyccb，如果battle是scene，在change到BarrierScene的时候，
        --可以根据数据直接加载正确的armyccb，但是如果是播放视频，scene一直是barrierScene，这个时候就得去动态卸载错误的armyNode，然后加载正确的armyNode
        --然后固定摄像机焦点
        if RARootManager.GetIsInBarrierScene() then
            local RAMissionBarierSceneHandler = RARootManager.GetCurrSceneHandler()

            local armyNodeCCB = RAMissionVar:getCCBOwner(self.constBarrierInfo.armyRes)
            if not armyNodeCCB then
                RAMissionBarierSceneHandler:changeArmyNode()
            end

            RAMissionBarierSceneHandler:focusCamera()

            self:gotoNextStep()

        else
            RARootManager.RemoveGuidePage()--如果是从新手过来的话，有可能有guidepage显示
            RARootManager.RemoveCoverPage()--如果是从新手过来的话，有可能有coverpage显示
            RARootManager.ShowTransform()
            RARootManager.ChangeScene(SceneTypeList.MissionBarrierScene)
        end

        
    end
end


--[[
    desc: 进入下一个关卡，用于战斗系统完成之后进行回调
]]
function RAMissionBarrierManager:gotoNextBarrier()
    self:_saveFragmentBarrier()

    local currentBarrierId = RAMissionVar:getBarrierId()
    local constFragmentInfo = fragment_conf[RAMissionVar:getFragmentId()]
    local index = 0
    if constFragmentInfo then
        local nextBarrierId = 0
        local barrierIds = Utilitys.Split(constFragmentInfo.barrierIds, ",")
        if currentBarrierId == 0 then
            nextBarrierId = tonumber(barrierIds[1])
        else
            for i, barrierId in ipairs(barrierIds) do
                if tonumber(barrierId) == currentBarrierId then
                    index = i
                    break
                end
            end
            if index > 0 then
                if index < #barrierIds then
                    nextBarrierId = tonumber(barrierIds[index +1])
                end
            end
        end
        

        if nextBarrierId > 0 then
            RAMissionBarrierManager:gotoBarrier(nextBarrierId)
        else
            --关卡结束了
            self.isInBarrier = false
            if RAGuideManager.isInGuide() and RAGuideManager.guideInWorld() then
                RARootManager.ChangeScene(SceneTypeList.WorldScene)
            end
        end
    end
end

--[[
    desc: 保存完成关卡信息
]]
function RAMissionBarrierManager:_saveFragmentBarrier()
    local msg = SysProtocol_pb.HPCustomDataDefine()
    msg.data.key = "guidefragmentbarrier"
    local fragment = RAMissionVar:getFragmentId()
    local barrier = RAMissionVar:getBarrierId()
    local arg = tostring(fragment) .. "_"..tostring(barrier)
    msg.data.arg = arg
    RANetUtil:sendPacket(HP_pb.CUSTOM_DATA_DEFINE, msg, {retOpcode = -1})
end

--[[
    desc: 场景摄像机移动
    @param: pos 移动到位置   time 移动时间   isSmooth 是否平滑移动
]]
function RAMissionBarrierManager:cameraGotoSpacePos(pos,time,isSmooth)
    if time == nil then time = 0.7 end
    if isSmooth == nil then isSmooth = true end
    self.sceneCamera:lookAt(pos,time,isSmooth)
end

--[[
    desc: 设置场景摄像机
]]
function RAMissionBarrierManager:setCamera(sceneCamera)
    self.sceneCamera = sceneCamera
end

--[[
    desc: 设置摄像机scale
]]
function RAMissionBarrierManager:setCameraScale(scale, time)
    local pos = self.sceneCamera:getCenter()

    self.sceneCamera:setScale(scale, time)
    self.sceneCamera:lookAt(pos,time, true)
end

--[[
    desc: 是否在新手期
]]
function RAMissionBarrierManager:isInGuide()
    local currentBarrierId = RAMissionVar:getBarrierId()
    if currentBarrierId == 0 then
        return true
    end

    local constFragmentInfo = fragment_conf[RAMissionVar:getFragmentId()]

    if constFragmentInfo then
        local barrierIds = Utilitys.Split(constFragmentInfo.barrierIds, ",")
        for i, barrierId in ipairs(barrierIds) do
            if tonumber(barrierId) == currentBarrierId then
                return i < #barrierIds
            end
        end
    end

    return false
end

--[[
    desc: 是否在剧情过程中
]]
function RAMissionBarrierManager:isInBarrierOrNot()
    return self.isInBarrier
end

--[[
    desc: 设置
]]
function RAMissionBarrierManager:setIsInBarrier(isInBarrier)
    self.isInBarrier = isInBarrier
end

--[[
    desc: 重置数据
]]
function RAMissionBarrierManager:_resetData()
    self.currentStep = 0
    self.constBarrierInfo = nil
    self.sceneCamera = nil
end

--[[
    desc: 重置数据
]]
function RAMissionBarrierManager:reset()
    self:_resetData()
end

return RAMissionBarrierManager