-- RAMarchManager.lua
-- 处理行军层逻辑

local RAMarchManager = {
	mRootNode = nil,
    mLineNode = nil,
    mModelNode = nil,
    -- 行军控制器列表，正常来说每个march data对应一个行军controller, key为marchId
    -- 会进行缓冲刷新
	mMoveControllerMap = {},

    mLastBufferOutputTime = 0,

    -- mSelfMarchCount = 0,    --自己行军个数
    mEnmyMarchCount = 0,    --敌人行军个数
    mGuildMarchCount = 0,   --联盟行军个数
    mIrrelevantCount = 0,   --无关的行军个数
    mTotalMarchCount = 0,   --总行军个数
}

local RAStringUtil = RARequire('RAStringUtil')
local RAWorldMath = RARequire('RAWorldMath')
local RAWorldVar = RARequire('RAWorldVar')
local RAMarchConfig = RARequire('RAMarchConfig')
local RAMarchActionHelper = RARequire('RAMarchActionHelper')
local RAMarchMoveHelper = RARequire('RAMarchMoveHelper')
local RAMarchDataManager = RARequire('RAMarchDataManager')
local Utilitys = RARequire('Utilitys')
local World_pb = RARequire('World_pb')
local Const_pb = RARequire('Const_pb')

local OnReceiveMessage = function(message)    
    CCLuaLog("RAMarchManager OnReceiveMessage id:"..message.messageID)
    if message.messageID == MessageDef_World.MSG_MarchDelete then
        CCLuaLog("MessageDef_World MSG_MarchDelete")
        local marchId = message.marchId
        local relation = message.relation
        RAMarchManager:RemoveMarchDisplayById(marchId, relation)
    end
    if message.messageID == MessageDef_World.MSG_MarchBeginBattle then
        CCLuaLog("MessageDef_World MSG_MarchBeginBattle")
        local marchId = message.marchId
        RAMarchManager:_RecordMarchBeginBattle(marchId)
    end

    if message.messageID == MessageDef_World.MSG_MarchEndBattle then
        CCLuaLog("MessageDef_World MSG_MarchEndBattle")
        local marchId = message.marchId
        RAMarchManager:_RecordMarchEndBattle(marchId)
    end
end

function RAMarchManager:registerMessageHandlers()
    MessageManager.registerMessageHandler(MessageDef_World.MSG_MarchDelete, OnReceiveMessage)
    MessageManager.registerMessageHandler(MessageDef_World.MSG_MarchBeginBattle, OnReceiveMessage)
    MessageManager.registerMessageHandler(MessageDef_World.MSG_MarchEndBattle, OnReceiveMessage)
end

function RAMarchManager:unregisterMessageHandlers()    
    MessageManager.removeMessageHandler(MessageDef_World.MSG_MarchDelete, OnReceiveMessage)
    MessageManager.removeMessageHandler(MessageDef_World.MSG_MarchBeginBattle, OnReceiveMessage)
    MessageManager.removeMessageHandler(MessageDef_World.MSG_MarchEndBattle, OnReceiveMessage)
end

-- 城外初始化的时候调用
function RAMarchManager:Init(rootNode)
    if RAMarchConfig.MarchBufferOutputGap < 0 then
        RAMarchConfig.MarchBufferOutputGap = RARequire('march_display_conf').refreshTime.value
    end
    if RAMarchConfig.MarchLimitTotalCount < 0 then
        local totalCount, enmyCount, guildCount, irrelevantCount = RAMarchConfig:GetMarchLimitValue()
        RAMarchConfig.MarchLimitTotalCount = totalCount
        RAMarchConfig.MarchLimitEnmyCount = enmyCount
        RAMarchConfig.MarchLimitGuildCount = guildCount
        RAMarchConfig.MarchLimitIrrelevantCount = irrelevantCount
    end
    self.mRootNode = rootNode    
    self.mLineNode = CCNode:create()
    self.mRootNode:addChild(self.mLineNode, RAMarchConfig.March_Line_Tag_And_ZOrder, RAMarchConfig.March_Line_Tag_And_ZOrder)
    self.mModelNode = CCNode:create()
    self.mRootNode:addChild(self.mModelNode, RAMarchConfig.March_Model_Tag_And_ZOrder, RAMarchConfig.March_Model_Tag_And_ZOrder)

    self:ShowSelfMarches()
    self:registerMessageHandlers()
end


-- 在城外的时候会调用
function RAMarchManager:Execute()
    if not RAWorldVar:IsInSelfKingdom() then return end
    if self.mIsBufferEmpty then return end
    local currTime = CCTime:getCurrentTime()
    if currTime - self.mLastBufferOutputTime > RAMarchConfig.MarchBufferOutputGap then
        local marchId = RAMarchDataManager:PopMarchIdFromBuffer()
        if marchId == nil or marchId == '' then
            self:SetIsBufferEmpty(true)
            self.mLastBufferOutputTime = currTime
        else
            -- local timeDebug = CCTime:getCurrentTime()        
            local marchData = RAMarchDataManager:GetMarchDataById(marchId)
            -- 这块不再计算，直接添加行军模型即可
            -- local isCalculated = self:ShowMarchByData(marchData, false)            
            -- 如果没计算过的话，下一帧直接刷新下一个缓冲区中的行军数据
            -- 即：计算过的才会去计时
            -- if isCalculated then
            --     self.mLastBufferOutputTime = currTime    
            -- end

            -- 添加行军模型
            local isAddModel = false
            local controller = self.mMoveControllerMap[marchId]            
            if controller ~= nil and marchData ~= nil then
                isAddModel = self:CheckAndCreateMarchMoveModels(controller, marchData)
            end
            if isAddModel then
                self.mLastBufferOutputTime = currTime    
            end

            -- local calcTimeSpend = CCTime:getCurrentTime() - timeDebug
            -- print('run RAMarchManager.CreateMarchMoveModels one time, spend time:'.. tostring(calcTimeSpend))
        end
    end	
end

function RAMarchManager:PrintCurrMarchCount()
    print('-----------------------RAMarchManager:PrintCurrMarchCount-------------------------')
    print('-----------------------Enmy Count:'..self.mEnmyMarchCount.. ' max:'..RAMarchConfig.MarchLimitEnmyCount)
    print('-----------------------Guild Count:'..self.mGuildMarchCount.. ' max:'..RAMarchConfig.MarchLimitGuildCount)
    print('-----------------------Irrelevant Count:'..self.mIrrelevantCount.. ' max:'..RAMarchConfig.MarchLimitIrrelevantCount)
    print('-----------------------Total Count:'..self.mTotalMarchCount.. ' max:'..RAMarchConfig.MarchLimitTotalCount)
end

-- 仅移除行军显示数据，不移除指针和监听
function RAMarchManager:ClearMarches()
    -- 先移除行军显示
    for id, controller in pairs(self.mMoveControllerMap) do
        if controller ~= nil then
            controller:Release()
        end
    end
    self.mMoveControllerMap = {}
    self.mLastBufferOutputTime = 0
    self.mEnmyMarchCount = 0
    self.mGuildMarchCount = 0
    self.mIrrelevantCount = 0
    self.mTotalMarchCount = 0
end

-- 退出城外时调用，需要清除显示对象缓存，同时移除指针、监听等
function RAMarchManager:Clear()	
    self:unregisterMessageHandlers()
    -- 先移除行军显示
    for id, controller in pairs(self.mMoveControllerMap) do
        if controller ~= nil then
            controller:Release()
        end
    end
    self.mMoveControllerMap = {}
    self.mLastBufferOutputTime = 0
    -- 去除指针
    if self.mRootNode ~= nil then
        self.mRootNode:removeChildByTag(RAMarchConfig.March_Line_Tag_And_ZOrder, true)
        self.mRootNode:removeChildByTag(RAMarchConfig.March_Model_Tag_And_ZOrder, true)
    end
    self.mRootNode = nil
    self.mLineNode = nil
    self.mModelNode = nil
    self.mEnmyMarchCount = 0
    self.mGuildMarchCount = 0
    self.mIrrelevantCount = 0
    self.mTotalMarchCount = 0

    -- 切换城内城外的时候移除世界上其他人的行军数据
    RAMarchDataManager:resetForChangeScene()
end


function RAMarchManager:SetIsBufferEmpty(value)
    self.mIsBufferEmpty = value
end


function RAMarchManager:CheckAndCreateMarchMoveModels(controller, marchData)
    if controller == nil or marchData == nil then return false end
    local isAddedModel = false
    local isCanCreate = true
    if marchData.relation ~= World_pb.SELF and marchData.relation ~= World_pb.TEAM_LEADER then
        if self.mTotalMarchCount >= RAMarchConfig.MarchLimitTotalCount then isCanCreate = false end
        if marchData.relation == World_pb.ENEMY then
            if self.mEnmyMarchCount >= RAMarchConfig.MarchLimitEnmyCount then isCanCreate = false end
        elseif marchData.relation == World_pb.GUILD_FRIEND then
            if self.mGuildMarchCount >= RAMarchConfig.MarchLimitGuildCount then isCanCreate = false end
        elseif marchData.relation == World_pb.NONE then
            if self.mIrrelevantCount >= RAMarchConfig.MarchLimitIrrelevantCount then isCanCreate = false end
        end
    end
    if isCanCreate then
        isAddedModel = controller:CreateMarchMoveModels(marchData)  
        if isAddedModel then
            if marchData.relation == World_pb.ENEMY then
                self.mEnmyMarchCount = self.mEnmyMarchCount + 1
            elseif marchData.relation == World_pb.GUILD_FRIEND then
                self.mGuildMarchCount = self.mGuildMarchCount + 1
            elseif marchData.relation == World_pb.NONE then
                self.mIrrelevantCount = self.mIrrelevantCount + 1
            end
        end
    end
    self:PrintCurrMarchCount()
    return isAddedModel
end

-- 添加一个行军显示对象，如果有的话，直接刷新
-- isLookAt:判断是否需要切换显示到起始位置（自己刚出发的行军才需要）
-- isCreateModel:判断是否需要立即创建行军模型（自己的行军需要传true）
function RAMarchManager:ShowMarchByData(marchData, isLookAt, isCreateModel)    
    if not RAWorldVar:IsInSelfKingdom() then return end
    local isLookAt = isLookAt or false
    local isCreateModel = isCreateModel or false
    if marchData == nil or marchData.marchId == '' then return false end
    if self.mRootNode == nil then return end
    if self.mModelNode == nil or self.mLineNode == nil then return end
    local relation = marchData.relation
    local marchId = marchData.marchId
    local controller = self.mMoveControllerMap[marchId]

    -- 只有出发或者返回过程中，才需要创建，但是也有可能需要创建后隐藏
    if RAMarchDataManager:LocalCheckMarchShowStatus(marchData.marchStatus, marchData.marchType) then
    -- if marchData.marchStatus == World_pb.MARCH_STATUS_MARCH or 
    --     marchData.marchStatus == World_pb.MARCH_STATUS_RETURN_BACK then          
        -- 刷新行军计算路线      
        local lastStatus = marchData:GetLastUpdateStatus()
        -- 行军状态不同的时候，需要重新计算方向、重新刷新行军显示
        if controller == nil or lastStatus ~= marchData.marchStatus then 
            marchData:SetLastUpdateStatus(marchData.marchStatus)
            local visibleStatus = self:_CheckMarchShowStatusById(marchId)
            if controller ~= nil then
                -- 增加逻辑，如果存在controller的话，就去重新加载，而不是remove
                controller:UpdateControlerData(marchId, true, true)
            else
                controller = self:CreateMarchMoveController(marchId, visibleStatus)
            end
            if isLookAt then
                local RAWorldManager = RARequire('RAWorldManager')
                RAWorldManager:LocateAt(marchData.origionX, marchData.origionY)
                -- 显示HUD
                self:ShowMarchHud(marchId)
            end

            if isCreateModel and controller ~= nil then
                self:CheckAndCreateMarchMoveModels(controller, marchData)
            end
        else
            -- 刷新行军计算路线      
            self:_CheckMarchShowStatusById(marchId)
            controller:UpdateControlerData(marchId, true, false)
        end
        return true
    else
        self:RemoveMarchDisplayById(marchId, relation)
        return false
    end
end


-- 进入城外的时候，先需要添加自己的行军
function RAMarchManager:ShowSelfMarches()
    local selfDatas = RAMarchDataManager:GetSelfMarchDataMap()
    for k,v in pairs(selfDatas) do
        local timeDebug = CCTime:getCurrentTime()
        self:ShowMarchByData(v, false, true)
        local calcTimeSpend = CCTime:getCurrentTime() - timeDebug
        print('run RAMarchManager ShowSelfMarches .ShowMarchByData one time, spend time:'.. tostring(calcTimeSpend))
    end
end


-- 移除一个行军
-- 及时删除
function RAMarchManager:RemoveMarchDisplayById(marchId, relation)        
    local controller = self.mMoveControllerMap[marchId]
    if controller ~= nil then
        controller:SetVisible(false)
        controller:Release()
        if relation == World_pb.ENEMY then
            self.mEnmyMarchCount = self.mEnmyMarchCount - 1
            if self.mEnmyMarchCount < 0 then self.mEnmyMarchCount = 0 end
        elseif relation == World_pb.GUILD_FRIEND then
            self.mGuildMarchCount = self.mGuildMarchCount - 1
            if self.mGuildMarchCount < 0 then self.mGuildMarchCount = 0 end
        elseif relation == World_pb.NONE then
            self.mIrrelevantCount = self.mIrrelevantCount - 1
            if self.mIrrelevantCount < 0 then self.mIrrelevantCount = 0 end
        end
    end
    self.mMoveControllerMap[marchId] = nil
    relation = relation or -1
    print('RAMarchManager:RemoveMarchDisplayById  marchId:'..marchId.. '  relation:'..relation)
    self:PrintCurrMarchCount()
end


-- 创建一个行军显示控制器
function RAMarchManager:CreateMarchMoveController(marchId, visibleStatus)
    local controller = RAMarchMoveHelper:CreateMarchMoveController(marchId, visibleStatus)
    local container, lineCnt = controller:GetSelfContainer()
    if container ~= nil and lineCnt ~= nil then
        self.mModelNode:addChild(container)
        self.mLineNode:addChild(lineCnt)
        self.mMoveControllerMap[marchId] = controller

        self:_CheckMarchShowStatusById(marchId)
    else
        controller:Release()
    end
    return controller
end


-- 获取当前行军走到了哪个格子
function RAMarchManager:GetMarchMoveEntityTilePos(marchId)
    local selfCurrPos = RAWorldVar.MapPos.Map
    -- body
    local controller = self.mMoveControllerMap[marchId]
    if controller and controller:GetMoveEntity() ~= nil then
        return controller:GetMarchMoveEntityTilePos(), true, controller
    end
    local marchData, isSelf = RAMarchDataManager:GetMarchDataById(marchId)
    if marchData == nil then return selfCurrPos, false end
    -- 如果不存在的话，根据行军的状态返回到对应的格子
    if marchData.marchStatus == World_pb.MARCH_STATUS_MARCH or
        marchData.marchStatus == World_pb.MARCH_STATUS_RETURN_BACK then
        -- 加速        
        return Utilitys.ccpCopy(marchData:GetEndCoord()), true, nil

    elseif marchData.marchStatus == World_pb.MARCH_STATUS_MARCH_COLLECT then
        --采集，查看采集点，终点        
        return Utilitys.ccpCopy(marchData:GetEndCoord()), true, nil

    elseif marchData.marchStatus == World_pb.MARCH_STATUS_MARCH_QUARTERED then
        --驻扎，查看驻扎点，终点
        return Utilitys.ccpCopy(marchData:GetEndCoord()), true, nil

    elseif marchData.marchStatus == World_pb.MARCH_STATUS_WAITING then
        --集结等待中，队伍未行军，查看队长点；
        --集结行军中，先找当前移动点，没有的话查看集结目标点
        local massController = self.mMoveControllerMap[marchData.targetId]
        if massController and massController:GetMoveEntity() ~= nil then
            return massController:GetMarchMoveEntityTilePos(), true, massController
        else
            local leaderMarchData = RAMarchDataManager:GetTeamLeaderMarchData(marchData.marchId)
            if leaderMarchData ~= nil then
                local leaderController = self.mMoveControllerMap[leaderMarchData.marchId] or nil
                if leaderMarchData.marchStatus == World_pb.MARCH_STATUS_WAITING then
                    return Utilitys.ccpCopy(leaderMarchData:GetStartCoord()), true, leaderController
                else
                    return Utilitys.ccpCopy(leaderMarchData:GetEndCoord()), true, leaderController
                end
            end
        end

    elseif marchData.marchStatus == World_pb.MARCH_STATUS_MARCH_ASSIST then
        --援助中，查看援助人，终点
        return Utilitys.ccpCopy(marchData:GetEndCoord()), true, nil
    end

    return selfCurrPos, false, nil
end


-- 返回行军移动ccb的view pos（tile map）
function RAMarchManager:GetMarchMoveEntityViewPos(marchId)
    local selfCurrPos, isSuc, controller = self:GetMarchMoveEntityTilePos(marchId)
    if controller then
        return controller:GetMarchMoveEntityViewPos(), controller
    end
    return RACcp(-1, -1), nil
end

-- 返回每个行军序列帧的位置
function RAMarchManager:GetMarchMovePos(marchId)    
    local selfCurrPos, isSuc, controller = self:GetMarchMoveEntityTilePos(marchId)
    if controller then
        return controller:GetArmyPostion()
    end
    return nil, nil
end

function RAMarchManager:ShowMarchHud(marchId)
    local controller = self.mMoveControllerMap[marchId]
    if controller then
        return controller:ShowMoeveEntityHud()
    end
end

-- 记录一个行军战斗结束
function RAMarchManager:_RecordMarchEndBattle(marchId)    
    local marchData = RAMarchDataManager:GetMarchDataById(marchId)
    if marchData ~= nil then
        marchData:SetBattleStatus(false)
    end
    self:_CheckMarchShowStatusById(marchId)
end

-- 记录一个行军战斗开始
function RAMarchManager:_RecordMarchBeginBattle(marchId)
    local marchData = RAMarchDataManager:GetMarchDataById(marchId)
    if marchData ~= nil then
        marchData:SetBattleStatus(true)
    end
    self:_CheckMarchShowStatusById(marchId)
end


-- 根据当前行军的状态和战斗状态，刷新行军的显示和隐藏状态
function RAMarchManager:_CheckMarchShowStatusById(marchId)
    local controller = self.mMoveControllerMap[marchId]
    local visibleStatus = false
    local battleStatus = -1
    local marchData = RAMarchDataManager:GetMarchDataById(marchId)

    if marchData then
        battleStatus = marchData:GetBattleStatus()
        local marchStatus = marchData.marchStatus
        local marchType = marchData.marchType

        -- 默认值，则没经过战斗
        if battleStatus == -1 then
            -- 状态为采集和驻扎的时候，隐藏行军对象
            if RAMarchDataManager:LocalCheckMarchShowStatus(marchStatus, marchType) then
                visibleStatus = true
            else
                visibleStatus = false
            end
        end

        -- 战斗开始的状态，一定隐藏
        if battleStatus == 1 then
            visibleStatus = false
        end

        -- 战斗打完的状态
        if battleStatus == 0 then
            -- 状态为采集和驻扎的时候，隐藏行军对象
            if RAMarchDataManager:LocalCheckMarchShowStatus(marchStatus, marchType) then            
                visibleStatus = true
            else
                visibleStatus = false
            end
        end
    else
        if controller then
            controller:Release()
        end
        self.mMoveControllerMap[marchId] = nil
    end
    if controller then
        controller:SetVisible(visibleStatus)
    end

    return visibleStatus
end



return RAMarchManager
