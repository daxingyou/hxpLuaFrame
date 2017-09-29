local Const_pb=RARequire('Const_pb')
local World_pb = RARequire('World_pb')
local RAMarchDataManager = RARequire('RAMarchDataManager')
local RAQueueManager = RARequire('RAQueueManager')
local RABuildManager = RARequire('RABuildManager')
local RACoreDataManager = RARequire('RACoreDataManager')
local RAGameConfig = RARequire('RAGameConfig')
local Utilitys = RARequire('Utilitys')
local RAMainUIHelper = RARequire('RAMainUIHelper')

local RAMainUIQueueDataManager = {    
    mCityQueueData = {},
    mWorldQueueData = {},
}

local ScieneSpareQueueDefaultType = Const_pb.SCIENCE_QUEUE + RAMainUIHelper.SpareQueueTypeAddValue    
-- 正常有数据的队列显示
-- 需要特殊处理，当科技队列不存在正式数据时，要增加默认显示
local CityQueueType2IndexMap = 
{
    [Const_pb.BUILDING_QUEUE] = 1,
    [Const_pb.SCIENCE_QUEUE] = 2,
    [Const_pb.SOILDER_QUEUE] = 3,
    [Const_pb.CURE_QUEUE] = 4,
    [Const_pb.BUILDING_DEFENER] = 5,
    [ScieneSpareQueueDefaultType] = 6,
}


function RAMainUIQueueDataManager:GetScieneDefaultQueueTypeAndId()
    local queueNewType = ScieneSpareQueueDefaultType
    local queueId = 'defaultId'
    return queueNewType, queueId
end

function RAMainUIQueueDataManager:GetScieneDefaultQueueCfg()
    local queueNewType, queueId = self:GetScieneDefaultQueueTypeAndId()
    local oneShowData = {}
    oneShowData.queueId = queueId
    oneShowData.queueItemId = 'defaultItemId'
    --全部存毫秒
    oneShowData.queueStartTime = -1
    oneShowData.queueEndTime = -1
    oneShowData.queueTotalTime = 0
    oneShowData.queueItemIcon = RAMainUIHelper.QueueIconMap[Const_pb.SCIENCE_QUEUE]
    oneShowData.queueItemName = RAMainUIHelper.QueueNameMap[Const_pb.SCIENCE_QUEUE]
    oneShowData.queueLabelKey = RAMainUIHelper.QueueSpareKey
    oneShowData.queueBtnLabelKey = RAMainUIHelper.QueueUseNameMap[Const_pb.SCIENCE_QUEUE]
    oneShowData.queueType = queueNewType
    oneShowData.isMarch = false
    return oneShowData
end




-- 城内队列数据初始化
function RAMainUIQueueDataManager:_InitOneQueueDataInCity(index, queueType)
    if not CityQueueType2IndexMap[queueType] then
        return nil
    end
    local oneData = {
        isShow = false,
        queueList = {},
        realCount = 0, 
        queueType = queueType,
        index = index
    }
    local queueList = oneData.queueList
    local queueDatas = RAQueueManager:getQueueDatas(queueType)
    local realCount = Utilitys.table_count(queueDatas)
    oneData.realCount = realCount

    if queueType == Const_pb.BUILDING_QUEUE then                
        --建筑升级
        if realCount <= 0 then
            oneData.isShow = false
        else
            oneData.isShow = true
            for queueId, v in pairs(queueDatas) do
                local oneShowData = {}
                oneShowData.queueId = v.id
                oneShowData.queueItemId = v.itemId
                --全部存毫秒
                oneShowData.queueStartTime = v.startTime2
                oneShowData.queueEndTime = v.endTime2
                oneShowData.queueTotalTime = v.totalQueueTime2

                local buildData = RABuildManager:getBuildDataById(oneShowData.queueItemId)
                if buildData ~= nil then
                    -- oneShowData.queueItemIcon = buildData.confData.buildArtImg
                    oneShowData.queueItemIcon = RAMainUIHelper.QueueIconMap[queueType]
                    oneShowData.queueItemName = buildData.confData.buildName
                    oneShowData.queueLabelKey = RAMainUIHelper.QueueUsingDesKeyMap[queueType][v.status]
                    oneShowData.queueBtnLabelKey = RAMainUIHelper.SpeedKey
                    oneShowData.queueType = queueType
                    oneShowData.isMarch = false

                    table.insert(queueList, oneShowData)
                end
            end
            Utilitys.tableSortByKeyReverse(queueList, 'queueStartTime')
        end

    elseif queueType == Const_pb.BUILDING_DEFENER then      
        -- 防御建筑
        if realCount <= 0 then
            oneData.isShow = false
        else
            oneData.isShow = true
            for queueId, v in pairs(queueDatas) do
                local oneShowData = {}
                oneShowData.queueId = v.id
                oneShowData.queueItemId = v.itemId
                --全部存毫秒
                oneShowData.queueStartTime = v.startTime2
                oneShowData.queueEndTime = v.endTime2
                oneShowData.queueTotalTime = v.totalQueueTime2

                local buildData = RABuildManager:getBuildDataById(oneShowData.queueItemId)
                if buildData ~= nil then
                    -- oneShowData.queueItemIcon = buildData.confData.buildArtImg
                    oneShowData.queueItemIcon = RAMainUIHelper.QueueIconMap[queueType]
                    oneShowData.queueItemName = buildData.confData.buildName
                    oneShowData.queueLabelKey = RAMainUIHelper.QueueUsingDesKeyMap[queueType][v.status]
                    oneShowData.queueBtnLabelKey = RAMainUIHelper.SpeedKey
                    oneShowData.queueType = queueType
                    oneShowData.isMarch = false

                    table.insert(queueList, oneShowData)
                end
            end
            Utilitys.tableSortByKeyReverse(queueList, 'queueStartTime')
        end
    elseif queueType == Const_pb.SOILDER_QUEUE then
        -- 士兵训练
        if realCount <= 0 then
            oneData.isShow = false
        else
            oneData.isShow = true
            for queueId, v in pairs(queueDatas) do
                local oneShowData = {}
                oneShowData.queueId = v.id
                oneShowData.queueItemId = v.itemId
                --全部存毫秒
                oneShowData.queueStartTime = v.startTime2
                oneShowData.queueEndTime = v.endTime2
                oneShowData.queueTotalTime = v.totalQueueTime2
                local RAArsenalManager = RARequire('RAArsenalManager')        
                local cfg = RAArsenalManager:getArmyCfgById(oneShowData.queueItemId)
                if cfg ~= nil then
                    oneShowData.queueItemIcon = cfg.icon
                    oneShowData.queueItemName = cfg.name
                    oneShowData.queueLabelKey = RAMainUIHelper.QueueUsingDesKeyMap[queueType]
                    oneShowData.queueBtnLabelKey = RAMainUIHelper.SpeedKey
                    oneShowData.queueType = queueType
                    oneShowData.isMarch = false
                    
                    table.insert(queueList, oneShowData)
                end
                local buildType = tonumber(v.info)
                local iconStr = RAMainUIHelper.QueueSoilderIconMap[buildType]
                if iconStr ~= nil then
                    oneShowData.queueItemIcon = iconStr
                end
            end
            Utilitys.tableSortByKeyReverse(queueList, 'queueStartTime')
        end
    elseif queueType == Const_pb.SCIENCE_QUEUE then
        -- 科技研发
        if realCount <= 0 then
            oneData.isShow = false
        else
            oneData.isShow = true
            for queueId, v in pairs(queueDatas) do
                local oneShowData = {}
                oneShowData.queueId = v.id
                oneShowData.queueItemId = v.itemId
                --全部存毫秒
                oneShowData.queueStartTime = v.startTime2
                oneShowData.queueEndTime = v.endTime2
                oneShowData.queueTotalTime = v.totalQueueTime2
                local RAScienceUtility = RARequire('RAScienceUtility')        
                local scieneData = RAScienceUtility:getScienceDataById(oneShowData.queueItemId)
                if scieneData ~= nil then
                    -- oneShowData.queueItemIcon = scieneData.techPic
                    oneShowData.queueItemIcon = RAMainUIHelper.QueueIconMap[queueType]
                    oneShowData.queueItemName = scieneData.techName
                    oneShowData.queueLabelKey = RAMainUIHelper.QueueUsingDesKeyMap[queueType]
                    oneShowData.queueBtnLabelKey = RAMainUIHelper.SpeedKey
                    oneShowData.queueType = queueType
                    oneShowData.isMarch = false
                    
                    table.insert(queueList, oneShowData)
                end
            end
            Utilitys.tableSortByKeyReverse(queueList, 'queueStartTime')
        end
    elseif queueType == Const_pb.CURE_QUEUE then
        -- 治疗队列
        if realCount <= 0 then
            oneData.isShow = false
        else
            oneData.isShow = true
            for queueId, v in pairs(queueDatas) do
                local oneShowData = {}
                oneShowData.queueId = v.id
                oneShowData.queueItemId = v.itemId
                --全部存毫秒
                oneShowData.queueStartTime = v.startTime2
                oneShowData.queueEndTime = v.endTime2
                oneShowData.queueTotalTime = v.totalQueueTime2
                oneShowData.queueItemIcon = RAMainUIHelper.QueueIconMap[queueType]
                oneShowData.queueItemName = ''
                oneShowData.queueLabelKey = RAMainUIHelper.QueueUsingDesKeyMap[queueType]
                oneShowData.queueBtnLabelKey = RAMainUIHelper.SpeedKey
                oneShowData.queueType = queueType
                oneShowData.isMarch = false
                    
                table.insert(queueList, oneShowData)
            end
            Utilitys.tableSortByKeyReverse(queueList, 'queueStartTime')
        end
    end
    return oneData
end



function RAMainUIQueueDataManager:InitAllDataForCity()
    -- 城内队列数据初始化
    -- 会包含所有队列数据，但不一定都显示，按策划规定的优先级添加
    self.mCityQueueData = {}
    -- 先添加实际存在的队列
    local isScienceShow = false
    local indexMax = 0
    for queueType,index in pairs(CityQueueType2IndexMap) do
        if queueType ~= ScieneSpareQueueDefaultType then
            self.mCityQueueData[index] = self:_InitOneQueueDataInCity(index, queueType)    
            if queueType == Const_pb.SCIENCE_QUEUE then
                isScienceShow = self.mCityQueueData[index].isShow
            end
            if index > indexMax then indexMax = index end
        end
    end
    -- 如果没有科技队列的时候，且玩家建造了科研所，默认添加科技闲置队列
    if not isScienceShow then
        local scienceBuildCount = RABuildManager:getBuildDataCountByType(Const_pb.FIGHTING_LABORATORY)
        if scienceBuildCount > 0 then
            indexMax = indexMax + 1
            local queueNewType = ScieneSpareQueueDefaultType
            local oneData = {
                isShow = true,
                queueList = {},
                realCount = 1, 
                queueType = queueNewType,
                index = indexMax
            }
            local oneShowData = self:GetScieneDefaultQueueCfg()
                    
            table.insert(oneData.queueList, oneShowData)
            self.mCityQueueData[indexMax] = oneData
        end
    end
    return self.mCityQueueData
end

function RAMainUIQueueDataManager:GetCityAllData(isForce)
    if isForce then
        self:InitAllDataForCity()
    end
    return self.mCityQueueData
end

--获取一个城内队列所在的索引
function RAMainUIQueueDataManager:GetCityShowDataIndex(queueType, queueId)
    if self.mCityQueueData == nil then return -1 end
    
    local index = 0
    local resultData = nil
    for i=1,#self.mCityQueueData do        
        local oneData = self.mCityQueueData[i]
        if oneData.isShow then
            for j=1, #oneData.queueList do
                index = index + 1
                local showData = oneData.queueList[j]
                if showData.queueType == queueType and showData.queueId == queueId then
                    resultData = showData
                    break
                end
            end
        end
        if resultData ~= nil then break end
    end
    if resultData == nil then index = 0 end
    return index, resultData
end

function RAMainUIQueueDataManager:CheckIsNeedToShowScienDefaultQueue()
    local isNeed = true
    local queueDatas = RAQueueManager:getQueueDatas(Const_pb.SCIENCE_QUEUE)
    if queueDatas ~= nil then
        local count = Utilitys.table_count(queueDatas)
        if count > 0 then
            isNeed = false
        end
    end
    local scienceBuildCount = RABuildManager:getBuildDataCountByType(Const_pb.FIGHTING_LABORATORY)
    if scienceBuildCount <= 0 then
        isNeed = false
    end
    return isNeed
end


-- // 行军类型
-- enum WorldMarchType
-- {
--     COLLECT_RESOURCE                = 1; // 采集
--     ATTACK_MONSTER                  = 2; // 杀怪
--     ATTACK_PLAYER                   = 3; // 攻击单人基地，驻扎点
--     ASSISTANCE                      = 4; // 援助
--     ARMY_QUARTERED                  = 5; // 驻扎
--     SPY                             = 6; // 侦察
--     MASS                            = 7; // 集结攻打单人基地
--     MASS_JOIN                       = 8; // 加入集结攻打单人基地
--     ASSISTANCE_RES                  = 9; // 资源援助盟友
--     CAPTIVE_RELEASE                 = 10; // 抓将遣返
--     MANOR_SINGLE                    = 11; // 单人攻占联盟领地
--     MANOR_MASS                      = 12; // 集结攻占联盟领地
--     MANOR_MASS_JOIN                 = 13; // 集结攻占联盟领地参与者
--     MANOR_ASSISTANCE_MASS           = 14; // 联盟领地集结援助
--     MANOR_ASSISTANCE_MASS_JOIN      = 15; // 联盟领地集结援助加入者
--     MANOR_COLLECT                   = 16; // 联盟超级矿采集行军类型
--     MANOR_ASSISTANCE                = 17; // 联盟领地单人援助
--     PRESIDENT_SINGLE                = 18; // 单人攻占总统府
--     PRESIDENT_MASS                  = 19; // 集结攻占总统府
--     PRESIDENT_MASS_JOIN             = 20; // 集结攻占总统府参与者
--     PRESIDENT_ASSISTANCE_MASS       = 21; // 总统府集结援助
--     PRESIDENT_ASSISTANCE_MASS_JOIN  = 22; // 总统府集结援助加入者
--     PRESIDENT_ASSISTANCE            = 23; // 总统府单人援助
-- }

-- 行军类型对应的队列页面的排序
local WorldQueueMarchType2IndexMap = 
{
    [1 ] = World_pb.PRESIDENT_SINGLE                 ,
    [2 ] = World_pb.MANOR_SINGLE                     ,
    [3 ] = World_pb.ATTACK_PLAYER                    ,
    [4 ] = World_pb.PRESIDENT_MASS                   ,
    [5 ] = World_pb.MANOR_MASS                       ,
    [6 ] = World_pb.MASS                             ,
    [7 ] = World_pb.PRESIDENT_MASS_JOIN              ,
    [8 ] = World_pb.MANOR_MASS_JOIN                  ,
    [9 ] = World_pb.MASS_JOIN                        ,
    [10] = World_pb.PRESIDENT_ASSISTANCE             ,
    [11] = World_pb.MANOR_ASSISTANCE                 ,
    [12] = World_pb.PRESIDENT_ASSISTANCE_MASS        ,
    [13] = World_pb.MANOR_ASSISTANCE_MASS            ,
    [14] = World_pb.PRESIDENT_ASSISTANCE_MASS_JOIN   ,
    [15] = World_pb.MANOR_ASSISTANCE_MASS_JOIN       ,
    [16] = World_pb.SPY                              ,
    [17] = World_pb.CAPTIVE_RELEASE                  ,
    [18] = World_pb.ASSISTANCE                       ,
    [19] = World_pb.ASSISTANCE_RES                   ,
    [20] = World_pb.MANOR_COLLECT                    ,
    [21] = World_pb.ARMY_QUARTERED                   ,
    [22] = World_pb.COLLECT_RESOURCE                 ,
    [23] = World_pb.ATTACK_MONSTER                   ,
    [24] = World_pb.MONSTER_MASS                   ,
    [25] = World_pb.MONSTER_MASS_JOIN                   ,
}


-- 城外队列数据初始化
function RAMainUIQueueDataManager:_InitOneQueueDataInWorld(index, marchType)
    local oneData = {
        isShow = false,
        queueList = {},
        realCount = 0, 
        queueType = marchType,
        index = index
    }
    local queueList = oneData.queueList
    local queueDatas = RAMarchDataManager:GetSelfMarchDataMapByType(marchType)
    local realCount = Utilitys.table_count(queueDatas)
    oneData.realCount = realCount
    if realCount <= 0 then
        oneData.isShow = false
    else
        oneData.isShow = true
        -- 这块已经是行军数据了
        for queueId, v in pairs(queueDatas) do
            local oneShowData = {}
            oneShowData.queueId = v.marchId
            oneShowData.queueItemId = 0
            local isHandled = false
            --集结等待的队列要特殊显示（取队长集结的数据显示）
            if v.marchStatus == World_pb.MARCH_STATUS_WAITING then
                local leaderMarchData = RAMarchDataManager:GetTeamLeaderMarchData(v.marchId)
                if leaderMarchData ~= nil then
                    --集结等待中                    
                    if leaderMarchData.marchStatus == World_pb.MARCH_STATUS_WAITING then
                        --集结队伍在集结中
                        --全部存毫秒
                        oneShowData.queueStartTime = leaderMarchData.massReadyTime
                        oneShowData.queueEndTime = leaderMarchData.startTime                        
                        --集结中的时候，要自己计算总时间
                        oneShowData.marchJourneyTime = 0
                        oneShowData.marchStatus = leaderMarchData.marchStatus
                        oneShowData.targetId = leaderMarchData.targetId
                        oneShowData.queueItemIcon = RAMainUIHelper.QueueIconMap[Const_pb.MARCH_QUEUE]
                        oneShowData.queueItemName = ''
                        oneShowData.queueLabelKey = ''
                        oneShowData.queueBtnLabelKey = RAMainUIHelper.SpeedKey
                        local showCfg = RAMainUIHelper.MarchStatusShowCfg[leaderMarchData.marchStatus]
                        if showCfg then
                            oneShowData.queueLabelKey = showCfg.lbKey
                            oneShowData.queueBtnLabelKey = showCfg.btnKey                
                        end
                        oneShowData.queueType = marchType
                        oneShowData.isMarch = true
                        oneShowData.isMarchMassJoining = true
                    elseif leaderMarchData.marchStatus == World_pb.MARCH_STATUS_MARCH then
                        --集结队伍在行军中
                        --全部存毫秒
                        oneShowData.queueStartTime = leaderMarchData.startTime
                        oneShowData.queueEndTime = leaderMarchData.endTime
                        oneShowData.marchJourneyTime = leaderMarchData.marchJourneyTime
                        oneShowData.marchStatus = leaderMarchData.marchStatus
                        oneShowData.targetId = leaderMarchData.targetId
                        oneShowData.queueItemIcon = RAMainUIHelper.QueueIconMap[Const_pb.MARCH_QUEUE]
                        oneShowData.queueItemName = ''
                        oneShowData.queueLabelKey = ''
                        oneShowData.queueBtnLabelKey = RAMainUIHelper.SpeedKey
                        local showCfg = RAMainUIHelper.MarchStatusShowCfg[leaderMarchData.marchStatus]
                        if showCfg then
                            oneShowData.queueLabelKey = showCfg.lbKey
                            oneShowData.queueBtnLabelKey = '@QueueSpeedUp'                
                        end
                        oneShowData.queueType = marchType
                        oneShowData.isMarch = true
                        oneShowData.isMarchMassJoining = false
                    end    
                    isHandled = true
                end
            end
            if not isHandled then
                --全部存毫秒
                oneShowData.queueStartTime = v.startTime
                oneShowData.queueEndTime = v.endTime
                oneShowData.marchJourneyTime = v.marchJourneyTime
                oneShowData.marchStatus = v.marchStatus
                oneShowData.targetId = v.targetId
                oneShowData.queueItemIcon = RAMainUIHelper.QueueIconMap[Const_pb.MARCH_QUEUE]
                oneShowData.queueItemName = ''
                oneShowData.queueLabelKey = ''
                oneShowData.queueBtnLabelKey = RAMainUIHelper.SpeedKey
                local showCfg = RAMainUIHelper.MarchStatusShowCfg[v.marchStatus]
                if showCfg then
                    oneShowData.queueLabelKey = showCfg.lbKey
                    oneShowData.queueBtnLabelKey = showCfg.btnKey                
                end
                oneShowData.queueType = marchType
                oneShowData.isMarch = true
                if v.marchStatus == World_pb.MARCH_STATUS_MARCH_COLLECT then
                    --采集中
                    oneShowData.queueStartTime = v.resStartTime
                    oneShowData.queueEndTime = v.resEndTime                    
                    oneShowData.marchJourneyTime = 0
                elseif v.marchStatus == World_pb.MARCH_STATUS_MARCH_QUARTERED then
                    -- 驻扎中
                    oneShowData.queueStartTime = -1
                    oneShowData.queueEndTime = -1                    
                elseif v.marchStatus == World_pb.MARCH_STATUS_MARCH_ASSIST then
                    --援助中
                    oneShowData.queueStartTime = -1
                    oneShowData.queueEndTime = -1     
                end
            end
            
            table.insert(queueList, oneShowData)
        end
        Utilitys.tableSortByKeyReverse(queueList, 'queueStartTime')
    end
    return oneData
end

function RAMainUIQueueDataManager:InitAllDataForWorld()    
    -- 城外行军队列初始化数据
    self.mWorldQueueData = {}
    local indexMax = 0
    for index, marchType in pairs(WorldQueueMarchType2IndexMap) do
        self.mWorldQueueData[index] = self:_InitOneQueueDataInWorld(index, marchType)        
        if index > indexMax then indexMax = index end
    end
    return self.mWorldQueueData
end

function RAMainUIQueueDataManager:GetWorldAllData(isForce)
    if isForce then
        self:InitAllDataForWorld()
    end
    return self.mWorldQueueData
end

--获取一个城内队列所在的索引
function RAMainUIQueueDataManager:GetWorldShowDataIndex(marchType, queueId)
    if self.mWorldQueueData == nil then return -1 end
    
    local index = 0
    local resultData = nil
    for i=1,#self.mWorldQueueData do        
        local oneData = self.mWorldQueueData[i]
        if oneData.isShow then
            for j=1, #oneData.queueList do
                index = index + 1
                local showData = oneData.queueList[j]
                if showData.queueType == marchType and showData.queueId == queueId then
                    resultData = showData
                    break
                end
            end
        end
        if resultData ~= nil then break end
    end
    if resultData == nil then index = 0 end
    return index, resultData
end



--检查这个类型的队列，是否要处理
function RAMainUIQueueDataManager:CheckIsHandleQueue(queueType, sceneType)
    local isHandle = false
    local RARootManager = RARequire('RARootManager')
    if sceneType == SceneTypeList.CityScene then
        if CityQueueType2IndexMap[queueType] ~= nil then
            return true
        end
    end
    if sceneType == SceneTypeList.WorldScene then
        if queueType == Const_pb.MARCH_QUEUE then
            return true
        end
    end    
    return false
end
return RAMainUIQueueDataManager
