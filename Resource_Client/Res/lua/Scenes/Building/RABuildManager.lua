local RARootManager = RARequire("RARootManager")
RARequire('RABaseBuilding')
RARequire('RATileUtil')
RARequire("MessageDefine")
RARequire("MessageManager")
RARequire('RABuildingType')
RARequire('extern')

local Const_pb = RARequire('Const_pb')
local GuildManager_pb = RARequire('GuildManager_pb')
local UIExtend = RARequire('UIExtend')
local RANetUtil = RARequire("RANetUtil")
local common = RARequire("common")
local build_conf = RARequire("build_conf")
local RAQueueManager = RARequire("RAQueueManager")
local RACoreDataManager = RARequire("RACoreDataManager")
local RAGuideManager = RARequire("RAGuideManager")
local RAGuideConfig = RARequire("RAGuideConfig")
local RAPlayerInfo = RARequire('RAPlayerInfo')
local RAGameConfig = RARequire('RAGameConfig')

RARequire('EnterFrameMananger')
local RABuildManager = {}
local winSize = CCDirector:sharedDirector():getWinSize()

local BUILD_ACTON = {
    CREATE = 1,
    MOVE = 2,
    UPGATE = 3,
    CLICKING = 4,--点击等待中
    CREATE_DEFENCE = 5,--建筑防御建筑
    MOVE_DEFF = 6,--移动防御建筑
}

local RACitySceneManager = nil 
local m_FrameTime = 0
local lastTime = 0

--当前建筑的信息
RABuildManager.buildingDatas = {} --建筑的数据
RABuildManager.buildingIndex = {} --建筑的数据索引

RABuildManager.hudPanel = nil -- HUD 面板

RABuildManager.buildings = {}
RABuildManager.buildingTilesMap = {}
RABuildManager.doodadTilesMap = {} --装饰层
RABuildManager.giftPos = nil --礼物的位置
RABuildManager.gift = nil --礼物 
RABuildManager.giftData = nil 
RABuildManager.giftSpine = nil 

RABuildManager.configBuildings = {}
RABuildManager.buildCCBIAnis = {}
RABuildManager.doodadBuildings = {}
RABuildManager.movingBuilding = nil 
RABuildManager.curBuilding = nil 
RABuildManager.curAction = nil --定义当前是在做什么操作
RABuildManager.netHandlers = {}

RABuildManager.tempNewBuilding = nil --暂存新建筑的 先客户端显示再更新服务器数据 
RABuildManager.tilesSprites = nil  --地砖
RABuildManager.arrSprites = nil 

RABuildManager.yesccbfile = nil --确定节点
RABuildManager.noccbfile = nil --取消节点

RABuildManager.clickedBuilding = false --是否点击到建筑
RABuildManager.isShowingBackground = false --是否已经显示背景了
RABuildManager.isMoving = false --是否出发移动了
RABuildManager.isClick = false --是否是单击事件
RABuildManager.showBuildingId = nil --默认显示的
RABuildManager.isInTouch = false

--防御建筑
RABuildManager.towerPosArr =  nil  --塔座信息
RABuildManager.towerSpines =  nil  --炮台信息
RABuildManager.towerMap = nil --炮台阻挡点



--当前建筑模块需要处理的队列类型
local allQueueType = {}
allQueueType[#allQueueType+1] = Const_pb.BUILDING_QUEUE --城建队列
allQueueType[#allQueueType+1] = Const_pb.BUILDING_DEFENER  --防御建筑
allQueueType[#allQueueType+1] = Const_pb.SCIENCE_QUEUE --科技队列
allQueueType[#allQueueType+1] = Const_pb.SOILDER_QUEUE --造兵队列 
allQueueType[#allQueueType+1] = Const_pb.CURE_QUEUE --治疗伤兵


RABuildManager.tempNode = nil  

local RALongTouchAni = {}

function RALongTouchAni:new()
    local o = {}
    setmetatable(o,self)
    self.__index = self
    return o
end

function RALongTouchAni:init(handler)
    -- self.handler = handler
    UIExtend.loadCCBFileWithOutPool("RAHUDCityLongTouchAni.ccbi",self)
end

function RALongTouchAni:release()
    UIExtend.unLoadCCBFile(self)
end

local RABuildCCBIAni = {}

function RABuildCCBIAni:new()
    local o = {}
    setmetatable(o,self)
    self.__index = self
    return o
end

function RABuildCCBIAni:init(ccbi)
    UIExtend.loadCCBFileWithOutPool(ccbi,self)
end

function RABuildCCBIAni:release()
    UIExtend.unLoadCCBFile(self)
end

function RABuildManager:reset()

    --self:Exit()
    --当前建筑的信息
    -- self.buildingDatas = {} --建筑的数据
    -- self.buildingIndex = {} --建筑的数据索引
    self:resetData()
    self.hudPanel = nil -- HUD 面板

    self.buildings = {}
    self.buildingTilesMap = {}
    self.doodadTilesMap = {} --装饰层
    self.configBuildings = {}
    self.buildCCBIAnis = {}
    self.doodadBuildings = {}
    self.movingBuilding = nil 
    self.curBuilding = nil 
    self.curAction = nil --定义当前是在做什么操作
    self.netHandlers = {}

    self.tempNewBuilding = nil --暂存新建筑的 先客户端显示再更新服务器数据 
    self.tilesSprites = nil  --地砖
    self.arrSprites = nil 

    self.yesccbfile = nil --确定节点
    self.noccbfile = nil --取消节点

    self.clickedBuilding = false --是否点击到建筑
    self.isShowingBackground = false --是否已经显示背景了
    self.isMoving = false --是否出发移动了
    self.isClick = false --是否是单击事件
    self.showBuildingId = nil --默认显示的

    self.tempNode = nil  
    self.isClickBtn = nil
end

function RABuildManager:resetData()
    self.buildingDatas = {} --建筑的数据
    self.buildingIndex = {} --建筑的数据索引
end

function RABuildManager:addHandler()
    self.netHandlers[#self.netHandlers + 1] = RANetUtil:addListener(HP_pb.BUILDING_CREATE_S, RABuildManager) --创建建筑返回
--    self.netHandlers[#self.netHandlers + 1] = RANetUtil:addListener(HP_pb.GUILDMANAGER_BEHELPED_S, RABuildManager) --联盟帮助提示
end


--处理新手阶段建造完成之后的数据逻辑
function RABuildManager:handleGuideStep(buildData)

    local buildType = buildData.confData.buildType
    local Utilitys = RARequire("Utilitys")
    local RAGuideConfig = RARequire("RAGuideConfig")

    if RAGuideManager.isInGuide() and Utilitys.tableFind(RAGuideConfig.ContructBuildFree,buildType) then
        RALogRelease('RABaseBuilding:initBuild: gotoNextStep Current buildType is '..tostring(buildType))
        RARootManager.AddCoverPage()
        RAGuideManager.gotoNextStep()
    end
 
end



local OnReceiveMessage = function(message)
    if message.messageID == MessageDef_Building.MSG_CreateBuildingSuccess then
        -- CCLuaLog("需要创建个建筑了。。" .. message.id)
        -- RACityScene.mBuildSpineLayer:addChild(building.spineNode)

        if not RABuildManager.tempNewBuilding then return end
        local buildData = RABuildManager.tempNewBuilding.buildData
        RABuildManager.buildings[buildData.id] = RABuildManager.tempNewBuilding

        RABuildManager:setBuildPos(RABuildManager.tempNewBuilding,RABuildManager.tempNewBuilding.buildData.tilePos,true)
        RABuildManager.tempNewBuilding = nil

        RABuildManager:handleGuideStep(buildData)

        -- RABuildManager:setBuildPos(building,buildData.tilePos)
        --if buildType is a mine car, add one mine car to scene
        local RACitySceneConfig = RARequire("RACitySceneConfig")
        local RACitySceneManager = RARequire("RACitySceneManager")
        if buildData.confData.buildType == RACitySceneConfig.TubInfo.tubType then
            RACitySceneManager:addOneMineCarByBuildData(buildData)
        end

        --防御建筑还需要刷新血条
        if buildData.confData.limitType == Const_pb.LIMIT_TYPE_BUILDING_DEFENDER then
            local building = RABuildManager.buildings[message.id]
            building:updateHp() 
        end
    elseif message.messageID == MessageDef_Building.MSG_UpgradeBuildingSuccess 
        or message.messageID == MessageDef_Building.MSG_ReBuildingSuccess
        or message.messageID == MessageDef_Building.MSG_RepairBuildingSuccess then 

        local building = RABuildManager.buildings[message.id] --建造完成，兵营需要设置为造兵状态
        local queueData = RAQueueManager:getSoilderQueue(building.buildData.confData.buildType)
        if queueData ~= nil then 
            building.queueData = queueData 
        else

            if building.buildData.confData.buildType == Const_pb.HOSPITAL_STATION then 
                local queueDatas = RAQueueManager:getQueueDataArr(Const_pb.CURE_QUEUE)
                if #queueDatas ~= 0 then 
                    building.queueData = queueDatas[1]  
                end
            end  
        end 

        if message.isImmidiately == true then 
            building:setState("update")
            RABuildManager:setBuildPos(building,building.buildData.tilePos,true)
        else 
            building:setState("update_finish")
        end  

        --时光机状态还需要刷新动画
        if building.buildData.confData.buildType == Const_pb.EINSTEIN_LODGE then   --爱因斯坦时光机器
            building:setState(BUILDING_STATE_TYPE.WORKING)
        end

       -- RABuildManager.
    elseif message.messageID == MessageDef_MainUI.MSG_ChangeBuildStatus then 

        if message.isShow == false then 
            if RABuildManager.curAction == BUILD_ACTON.CREATE then 
                RABuildManager:destoryTempNew()
                RABuildManager.curAction = nil  
            end
        end 
    elseif message.messageID == MessageDef_Queue.MSG_Defener_ADD 
        or message.messageID == MessageDef_Queue.MSG_Defener_REBUILD_ADD --防御建筑改建开始
        or message.messageID == MessageDef_Queue.MSG_Defener_REPAIRE_ADD --防御建筑修理开始
        or message.messageID == MessageDef_Queue.MSG_Building_REBUILD_ADD --普通建筑改建开始  
        or message.messageID == MessageDef_Queue.MSG_Building_ADD then -- 防御建筑
        
        local building = RABuildManager.buildings[message.itemId]
        building.queueData = message
        building:setState(BUILDING_STATE_TYPE.UPGRADE_START)

    elseif message.messageID == MessageDef_Queue.MSG_Defener_DELETE 
        or message.messageID == MessageDef_Queue.MSG_Defener_REBUILD_DELETE
        or message.messageID == MessageDef_Queue.MSG_Defener_REPAIRE_DELETE
    then -- 防御建筑
        
        local building = RABuildManager.buildings[message.itemId]
        building.queueData = nil 
        building:setState(BUILDING_STATE_TYPE.UPGRADE_FINISH,message.messageID)

        if message.messageID == MessageDef_Queue.MSG_Defener_REPAIRE_DELETE then
           building:updateHp() 
        end 

        if RABuildManager.curAction == nil and building == RABuildManager.curBuilding then 
            RABuildManager:cancelSelectBuilding()
        end 

    elseif message.messageID == MessageDef_Queue.MSG_Defener_CANCEL -- 防御建筑升级取消
        or message.messageID == MessageDef_Queue.MSG_Defener_REBUILD_CANCEL --防御建筑改建取消
        or message.messageID == MessageDef_Queue.MSG_Defener_REPAIRE_CANCEL --防御建筑修理取消
        or message.messageID == MessageDef_Queue.MSG_Building_REBUILD_CANCEL --普通建筑改建取消  
        or message.messageID == MessageDef_Queue.MSG_Building_CANCEL then -- 普通建筑升级取消

        local building = RABuildManager.buildings[message.itemId]
        building.queueData = nil

         --建造完成，兵营需要设置为造兵状态
        local queueData = RAQueueManager:getSoilderQueue(building.buildData.confData.buildType)
        if queueData ~= nil then 
            building.queueData = queueData 
        else
            if building.buildData.confData.buildType == Const_pb.HOSPITAL_STATION then 
                local queueDatas = RAQueueManager:getQueueDataArr(Const_pb.CURE_QUEUE)
                if #queueDatas ~= 0 then 
                    building.queueData = queueDatas[1]  
                end
            end  
        end 

        building:setState(BUILDING_STATE_TYPE.CANCEL)

    elseif message.messageID == MessageDef_Queue.MSG_Building_DELETE
        or message.messageID == MessageDef_Queue.MSG_Building_REBUILD_DELETE
    then -- 建筑完成了
        local building = RABuildManager.buildings[message.itemId]
        if building == nil then 
            return 
        end 

        RABuildManager.freeTimeGuiderHandler()
        building.queueData = nil 
        building:setState(BUILDING_STATE_TYPE.UPGRADE_FINISH,message.messageID)

        if RABuildManager.curAction == nil and building == RABuildManager.curBuilding then 
            RABuildManager:cancelSelectBuilding()
        end 
    elseif message.messageID == MessageDef_Queue.MSG_Science_ADD then --科技开始
        local buildDataTable = RABuildManager:getBuildDataByType(Const_pb.FIGHTING_LABORATORY)
        for k,buildData in pairs(buildDataTable) do
            local building = RABuildManager.buildings[buildData.id]
            building.queueData = message
            building:setState(BUILDING_STATE_TYPE.WORKING_START)
        end
    elseif message.messageID == MessageDef_Queue.MSG_Science_UPDATE then --科技更新
        local buildDataTable = RABuildManager:getBuildDataByType(Const_pb.FIGHTING_LABORATORY)
        for k,buildData in pairs(buildDataTable) do
            local building = RABuildManager.buildings[buildData.id]
            building.queueData = message
            building:updateHelpIcon() 
        end
    elseif message.messageID == MessageDef_Queue.MSG_Science_DELETE then --科技完成了
        local buildDataTable = RABuildManager:getBuildDataByType(Const_pb.FIGHTING_LABORATORY)
        for k,buildData in pairs(buildDataTable) do
            local building = RABuildManager.buildings[buildData.id]
            building.queueData = nil 
            building:setState(BUILDING_STATE_TYPE.WORKING_FINISH)
        end
    elseif message.messageID == MessageDef_Queue.MSG_Science_CANCEL then
        local buildDatas = RABuildManager:getBuildDataArray(Const_pb.FIGHTING_LABORATORY)
        local building = RABuildManager.buildings[buildDatas[1].id]
        building.queueData = nil 
        building:setState(BUILDING_STATE_TYPE.WORKING_CANCEL)
    elseif message.messageID == MessageDef_Queue.MSG_hospital_ADD then --医院
        local buildDataTable = RABuildManager:getBuildDataByType(Const_pb.HOSPITAL_STATION)
        for k,buildData in pairs(buildDataTable) do
            local building = RABuildManager.buildings[buildData.id]

            if not RAQueueManager:isBuildingUpgrade(buildData.id) then 
                building.queueData = message
                building:setState(BUILDING_STATE_TYPE.WORKING_START)
            end 
        end
    elseif message.messageID == MessageDef_Queue.MSG_hospital_UPDATE then --医院
        local buildDataTable = RABuildManager:getBuildDataByType(Const_pb.HOSPITAL_STATION)
        for k,buildData in pairs(buildDataTable) do
            local building = RABuildManager.buildings[buildData.id]

            if not RAQueueManager:isBuildingUpgrade(buildData.id) then 
                building.queueData = message
                building:updateHelpIcon() 
            end 
        end
    elseif message.messageID == MessageDef_Queue.MSG_hospital_DELETE then
        local buildDataTable = RABuildManager:getBuildDataByType(Const_pb.HOSPITAL_STATION)
        for k,buildData in pairs(buildDataTable) do
            local building = RABuildManager.buildings[buildData.id]

            if not RAQueueManager:isBuildingUpgrade(buildData.id) then 
                building.queueData = nil 
                building:setState(BUILDING_STATE_TYPE.WORKING_FINISH)
            end 
        end
        MessageManager.sendMessage(MessageDef_CITY.MSG_NOTICE_GATHER)
    elseif message.messageID == MessageDef_Queue.MSG_hospital_CANCEL then
        local buildDataTable = RABuildManager:getBuildDataByType(Const_pb.HOSPITAL_STATION)
        for k,buildData in pairs(buildDataTable) do
            local building = RABuildManager.buildings[buildData.id]

            if not RAQueueManager:isBuildingUpgrade(buildData.id) then 
                building.queueData = nil 
                building:setState(BUILDING_STATE_TYPE.WORKING_CANCEL)
            end 
        end
    elseif message.messageID == MessageDef_Queue.MSG_Soilder_ADD then 
        local buildType = tonumber(message.info)
        -- CCLuaLog("buildType:" .. buildType)
        local buildDataTable = RABuildManager:getBuildDataByType(buildType)
        for k,buildData in pairs(buildDataTable) do
            local building = RABuildManager.buildings[buildData.id]

            if not RAQueueManager:isBuildingUpgrade(buildData.id) then 
                building.queueData = message
                building:setState(BUILDING_STATE_TYPE.WORKING_START)
            end
        end
    elseif message.messageID == MessageDef_Building.MSG_MainFactory_Levelup then 
        RABuildManager:updateTowerState()
    elseif message.messageID == MessageDef_Queue.MSG_Soilder_DELETE then 
        local buildDataTable = RABuildManager:getBuildDataByType(tonumber(message.info))
        for k,buildData in pairs(buildDataTable) do
            local building = RABuildManager.buildings[buildData.id]

            if not RAQueueManager:isBuildingUpgrade(buildData.id) then 
                building.queueData = nil 
                building:setState(BUILDING_STATE_TYPE.WORKING_FINISH)
            end
        end
    elseif message.messageID == MessageDef_Queue.MSG_Soilder_CANCEL then 
        local buildDataTable = RABuildManager:getBuildDataByType(tonumber(message.info))
        for k,buildData in pairs(buildDataTable) do
            local building = RABuildManager.buildings[buildData.id]

            if not RAQueueManager:isBuildingUpgrade(buildData.id) then 
                building.queueData = nil 
                building:setState(BUILDING_STATE_TYPE.WORKING_CANCEL)
            end
        end

    elseif message.messageID == MessageDef_Building.MSG_BuildingStatusChange then 
        local buildDataTable = RABuildManager:getBuildDataByType(message.buildType)
        for k,buildData in pairs(buildDataTable) do
            local building = RABuildManager.buildings[buildData.id]
            building:updateTopStatus()

            --时光机状态还需要刷新动画
            if buildData.confData.buildType == Const_pb.EINSTEIN_LODGE then   --爱因斯坦时光机器
                local einsteinState = BUILDING_STATE_TYPE.WORKING

                if buildData.status == Const_pb.DAMAGED then                  --爱因斯坦时光机器损毁状态
                    einsteinState = BUILDING_STATE_TYPE.IDLE
                elseif buildData.status == Const_pb.READY_TO_CREATE then      --爱因斯坦时光机器待建造状态
                    einsteinState = BUILDING_STATE_TYPE.WORKING_START
                end

                if einsteinState == BUILDING_STATE_TYPE.WORKING then
                    RARootManager.ShowMsgBox(_RALang("@TimeMachineStartAccomplish"))
                end

                building:setState(einsteinState)
            end
        end
    elseif message.messageID == MessageDef_Packet.MSG_Operation_OK then
        if message.opcode == HP_pb.GUILDMANAGER_APPLYHELP_C then 
            --收到联盟帮助的回包后
        end
    elseif message.messageID == MessageDef_Packet.MSG_Operation_Fail then
        if message.opcode == HP_pb.BUILDING_CREATE_C then 
            if RABuildManager.tempNewBuilding ~= nil then 
                RABuildManager.tempNewBuilding:removeFromParentAndCleanup(true)
                RABuildManager.tempNewBuilding = nil
                -- CCLuaLog("createBuilding result:fail")
            end
        end
    elseif message.messageID == MessageDef_Guide.MSG_Guide then --新手引导
        CCLuaLog('MessageDef_Guide.MSG_Guide:' .. message.guideInfo.guideId)
        RABuildManager:guideHandler(message.guideInfo)
    elseif message.messageID == MessageDef_Guide.MSG_GuideEnd then --新手引导结束
        if RABuildManager.giftSpine == nil and RABuildManager.gift ~= nil and (not RAGuideManager.isInFirstPart()) then --新手第一阶段结束不能有宝箱地图上没有宝箱
            RABuildManager:initGift()
        end 
    elseif message.messageID == MessageDef_CITY.MSG_NOTICE_ATTACK_HP_CHANGE then --刷新HP
        RABuildManager:updateAllBuildingHp()
    elseif message.messageID == MessageDef_TreasureBox.MSG_TreasureBox_Create then
        if RABuildManager.gift ~= nil then 

            if not RAGuideManager:isInGuide() then 
                RABuildManager:createGift()
                RABuildManager:genGiftPos()
                RABuildManager:setGiftPos()
            end
            -- RABuildManager:createGift()
        end 
    elseif message.messageID == MessageDef_TreasureBox.MSG_TreasureBox_Delete then
        RABuildManager:removeGift()
    elseif message.messageID == MessageDef_BaseInfo.MSG_ElectricStatus_Change then
        RABuildManager:updateTowerState()
    -- elseif message.messageID == MessageDef_TreasureBox.MSG_TreasureBox_Delete then
    elseif message.messageID == MessageDef_Building.MSG_Cancel_Building_Select then
        CCLuaLog("取消选中了 MessageDef_Building.MSG_Cancel_Building_Select")

        -- local RACityScene = RARequire('RACityScene') 
        if RAGuideManager:isInGuide() then 
            local RACityScene = RARequire('RACityScene') 
            if RACityScene.isCameraMoving then 
                return 
            end 
        end 


        RABuildManager:hideLongAni()
        if RABuildManager.curAction ~= BUILD_ACTON.CREATE then 
            if RABuildManager.curBuilding ~= nil then 
                RABuildManager.curBuilding.timeNode:stopAllActions()
                -- RABuildManager:hideLongAni()
                RABuildManager.curBuilding.buildData:setClickTile(nil)
            end

            if RABuildManager.curAction == BUILD_ACTON.MOVE then 
                RABuildManager:cancelMovingBuilding()
            elseif RABuildManager.curAction == BUILD_ACTON.MOVE_DEFF then
                RABuildManager:DefFinishMoving()
            end  

            RABuildManager:cancelSelectBuilding() 
            RABuildManager.movingBuilding = nil
            RABuildManager.curBuilding = nil
            RABuildManager.clickedBuilding = false
            RABuildManager.curAction = nil 
        end  
    end
end

function RABuildManager:guideHandler(guideInfo)

    --移动镜头
    if guideInfo.keyWord == RAGuideConfig.KeyWordArray.CityMoveCameraToBuildArea then 
        local Utilitys = RARequire("Utilitys")
        local pos = Utilitys.Split(guideInfo.BuildAraePos, '_')
        local x = tonumber(pos[1])
        local y = tonumber(pos[2])
        RACitySceneManager = RARequire("RACitySceneManager")
        RACitySceneManager:cameraGotoTilePos({x=x,y=y}) 

        local callback = function ()
            -- CCLuaLog('callback')
            RAGuideManager.gotoNextStep()
        end
        local mainBuildData = self:getBuildDataArray(Const_pb.CONSTRUCTION_FACTORY)[1]
        local mainBuilding = self.buildings[mainBuildData.id]
        performWithDelay(mainBuilding.spineNode,callback,0.75)
    end 
end

function RABuildManager:hideAllBuildings()
     for k,v in pairs(self.buildings) do
        v:setVisible(false)
    end
end

--添加建筑数据
function RABuildManager:addBuildData(buildData)
    self.buildingDatas[buildData.id] = buildData

    if self.buildingIndex[buildData.confData.buildType] == nil then 
        self.buildingIndex[buildData.confData.buildType] = {}
    end 

    local indexTable = self.buildingIndex[buildData.confData.buildType]
    indexTable[buildData.id] = buildData
end

function RABuildManager:getCureBuildTyps()
    local Const_pb = RARequire("Const_pb")
    local ret = {}
    table.insert(ret, Const_pb.HOSPITAL_STATION)
    return ret
end

-- 获取治疗伤兵的建筑个数
function RABuildManager:getCureBuildCounts()
    local buildCount = 0
    local buildTypes = self:getCureBuildTyps()
    local typeList = {}
    for k,buildType in pairs(buildTypes) do
        local count = RABuildManager:getBuildDataCountByType(buildType)
        if count > 0 then
            buildCount = buildCount + 1
            table.insert(typeList, buildType)
        end
    end
    return buildCount, typeList
end


-- 获取所有防御建筑的类型
function RABuildManager:getDefenceBuildTyps()
    local Const_pb = RARequire("Const_pb")
    local ret = {}
    table.insert(ret, Const_pb.PRISM_TOWER)
    table.insert(ret, Const_pb.PATRIOT_MISSILE)
    table.insert(ret, Const_pb.PILLBOX)
    return ret
end

-- 获取防御建筑的个数
function RABuildManager:getDefenceBuildCounts()
    local defenceBuildCount = 0
    local defenceBuildType = self:getDefenceBuildTyps()
    -- local typeList = {}
    for k,buildType in pairs(defenceBuildType) do
        local count = RABuildManager:getBuildDataCountByType(buildType)
        if count > 0 then
            defenceBuildCount = defenceBuildCount + count
            -- table.insert(typeList, buildType)
        end
    end
    return defenceBuildCount
end

--获得可升级防御建筑
function RABuildManager:getDefenceBuildLevelUp( )
    local defenceBuildType = self:getDefenceBuildTyps()
    for k,buildType in pairs(defenceBuildType) do
        local buildings = RABuildManager:getBuildDataByType(buildType)
        if buildings then
            for id, build in pairs(buildings) do
                if RABuildingUtility.isCanUpgradeBuild(build.confData.id, true) then
                    return build
                end
            end
        end
    end
end

-- TODO:获取防御建筑是否受损
function RABuildManager:getDefenceBuildIsHurt()
    return false
end



-- 获取所有建造士兵类型的建筑类型列表
function RABuildManager:getSoilderBuildTyps()
    local Const_pb = RARequire("Const_pb")
    local ret = {}
    table.insert(ret, Const_pb.BARRACKS)
    table.insert(ret, Const_pb.WAR_FACTORY)
    table.insert(ret, Const_pb.REMOTE_FIRE_FACTORY)
    table.insert(ret, Const_pb.AIR_FORCE_COMMAND)
    return ret
end

function RABuildManager:getSoilderBuildCounts()
    local soilderBuildCount = 0
    local soilderBuildType = self:getSoilderBuildTyps()
    local typeList = {}
    for k,buildType in pairs(soilderBuildType) do
        local count = RABuildManager:getBuildDataCountByType(buildType)
        if count > 0 then
            soilderBuildCount = soilderBuildCount + 1
            table.insert(typeList, buildType)
        end
    end
    return soilderBuildCount, typeList
end

function RABuildManager:getMainCityData()
    local Const_pb = RARequire("Const_pb")
    local buildData = self:getBuildDataByType(Const_pb.CONSTRUCTION_FACTORY)
    if buildData == nil then return nil end
    for k,v in pairs(buildData) do
        return v
    end
    return nil
end


function RABuildManager:getMainCityLvl()
    local Const_pb = RARequire("Const_pb")
    local buildData = self:getBuildDataByType(Const_pb.CONSTRUCTION_FACTORY)
    if buildData == nil then return 0 end
    for k,v in pairs(buildData) do
        return v.confData.level
    end
    return 0
end


--根据BuildTypeId 查找到该建筑在对应主城等级的限制数目
function RABuildManager:getBuildLimitNumByBuildType(buildTypeId)
    local buildId = buildTypeId * 100 + 1
    local limitType = build_conf[buildId].limitType
    local mainCityLvl = self:getMainCityLvl();
    if mainCityLvl == 0 then mainCityLvl = 1 end
    local build_limit_conf = RARequire("build_limit_conf")
    local limitNum = build_limit_conf[limitType]['cyLv'..mainCityLvl]
    return limitNum
end


function RABuildManager:getBuildDataCountByType(buildType)
    local data = self:getBuildDataByType(buildType)
    if data == nil then return 0 end;
    return common:table_count(data)
end

--通过类型得到数据
function RABuildManager:getBuildDataByType(buildType)
    return self.buildingIndex[buildType]
end

function RABuildManager:getBuildDataArray(buildType)
    local arr = {}

    if self.buildingIndex[buildType] == nil then 
        return arr
    end 

    for k,v in pairs(self.buildingIndex[buildType]) do
        arr[#arr+1] = v
    end
    return arr
end

function RABuildManager:isBuildingExist(buildingCfgId,buildingType)
    -- body
    for k,v in pairs(self.buildingDatas) do
        if v.confData.id == buildingCfgId or (buildingType==v.confData.buildType and buildingCfgId<v.confData.id) then 
            return true
        end 
    end

    return false
end

function RABuildManager:getBuildingDataByConfId(buildingCfgId)
    -- body
    for k,v in pairs(self.buildingDatas) do
        if v.confData.id == buildingCfgId then 
            return v
        end 
    end
end

function RABuildManager:registerQueueMessage()
    for queueKey,queueType in pairs(allQueueType) do
        local messageTable = RAQueueManager.messageTable[queueType]
        for _,message in pairs(messageTable) do
            if queueType == Const_pb.BUILDING_QUEUE or queueType == Const_pb.BUILDING_DEFENER then 
                for _,v in pairs(message) do
                    MessageManager.registerMessageHandler(v,OnReceiveMessage)
                end
            else
                MessageManager.registerMessageHandler(message,OnReceiveMessage)
            end
        end
    end
end

function RABuildManager:removeQueueMessage()
    for queueKey,queueType in pairs(allQueueType) do
        local messageTable = RAQueueManager.messageTable[queueType]
        for _,message in pairs(messageTable) do
            if queueType == Const_pb.BUILDING_QUEUE or queueType == Const_pb.BUILDING_DEFENER then 
                for _,v in pairs(message) do
                    MessageManager.removeMessageHandler(v,OnReceiveMessage)
                end
            else
                MessageManager.removeMessageHandler(message,OnReceiveMessage)
            end
        end
    end
end

function RABuildManager:registerMessage()
    MessageManager.registerMessageHandler(MessageDef_Building.MSG_CreateBuildingSuccess,OnReceiveMessage)
    MessageManager.registerMessageHandler(MessageDef_Building.MSG_UpgradeBuildingSuccess,OnReceiveMessage)
    MessageManager.registerMessageHandler(MessageDef_Building.MSG_ReBuildingSuccess,OnReceiveMessage)
    MessageManager.registerMessageHandler(MessageDef_Building.MSG_RepairBuildingSuccess,OnReceiveMessage)
    MessageManager.registerMessageHandler(MessageDef_Building.MSG_Cancel_Building_Select,OnReceiveMessage)
    MessageManager.registerMessageHandler(MessageDef_MainUI.MSG_ChangeBuildStatus,OnReceiveMessage)
    MessageManager.registerMessageHandler(MessageDef_Building.MSG_BuildingStatusChange,OnReceiveMessage)
    MessageManager.registerMessageHandler(MessageDef_Packet.MSG_Operation_OK,OnReceiveMessage)
    MessageManager.registerMessageHandler(MessageDef_Packet.MSG_Operation_Fail,OnReceiveMessage)
    MessageManager.registerMessageHandler(MessageDef_TreasureBox.MSG_TreasureBox_Create,OnReceiveMessage)
    MessageManager.registerMessageHandler(MessageDef_TreasureBox.MSG_TreasureBox_Delete,OnReceiveMessage)
    MessageManager.registerMessageHandler(MessageDef_Building.MSG_MainFactory_Levelup,OnReceiveMessage)
    MessageManager.registerMessageHandler(MessageDef_Building.MSG_Moving_Finished,OnReceiveMessage)
    MessageManager.registerMessageHandler(MessageDef_BaseInfo.MSG_ElectricStatus_Change,OnReceiveMessage)
    MessageManager.registerMessageHandler(MessageDef_CITY.MSG_NOTICE_ATTACK_HP_CHANGE,OnReceiveMessage)

    --新手引导的消息
    MessageManager.registerMessageHandler(MessageDef_Guide.MSG_Guide,OnReceiveMessage)
    MessageManager.registerMessageHandler(MessageDef_Guide.MSG_GuideEnd,OnReceiveMessage) --新手引导结束，产生宝箱
    self:registerQueueMessage()
end

function RABuildManager:removeMessageHandler()
    MessageManager.removeMessageHandler(MessageDef_Building.MSG_CreateBuildingSuccess,OnReceiveMessage)
    MessageManager.removeMessageHandler(MessageDef_Building.MSG_UpgradeBuildingSuccess,OnReceiveMessage)
    MessageManager.removeMessageHandler(MessageDef_Building.MSG_ReBuildingSuccess,OnReceiveMessage)
    MessageManager.removeMessageHandler(MessageDef_Building.MSG_RepairBuildingSuccess,OnReceiveMessage)
    MessageManager.removeMessageHandler(MessageDef_MainUI.MSG_ChangeBuildStatus,OnReceiveMessage)
    MessageManager.removeMessageHandler(MessageDef_Building.MSG_Cancel_Building_Select,OnReceiveMessage)
    MessageManager.removeMessageHandler(MessageDef_Building.MSG_BuildingStatusChange,OnReceiveMessage)
    MessageManager.removeMessageHandler(MessageDef_Packet.MSG_Operation_OK,OnReceiveMessage)
    MessageManager.removeMessageHandler(MessageDef_Guide.MSG_Guide,OnReceiveMessage)
    MessageManager.removeMessageHandler(MessageDef_TreasureBox.MSG_TreasureBox_Create,OnReceiveMessage)
    MessageManager.removeMessageHandler(MessageDef_TreasureBox.MSG_TreasureBox_Delete,OnReceiveMessage)
    MessageManager.removeMessageHandler(MessageDef_Guide.MSG_GuideEnd,OnReceiveMessage)
    MessageManager.removeMessageHandler(MessageDef_Building.MSG_MainFactory_Levelup,OnReceiveMessage)
    MessageManager.removeMessageHandler(MessageDef_Building.MSG_Moving_Finished,OnReceiveMessage)
    MessageManager.removeMessageHandler(MessageDef_BaseInfo.MSG_ElectricStatus_Change,OnReceiveMessage)
    MessageManager.removeMessageHandler(MessageDef_CITY.MSG_NOTICE_ATTACK_HP_CHANGE,OnReceiveMessage)

    self:removeQueueMessage()
end

function RABuildManager:onReceivePacket(handler)
    local pbCode = handler:getOpcode()
    local buffer = handler:getBuffer()
    if pbCode == HP_pb.BUILDING_CREATE_S then --建筑的返回
        local Building_pb = RARequire("Building_pb")
        local msg = Building_pb.BuildingCreateResp()
        msg:ParseFromString(buffer)
        
        if msg.result == true then 
            CCLuaLog("createBuilding result:success")
            --播放音效
            common:playEffect("v_ConstructionComplete")
        else
            if self.tempNewBuilding ~= nil then 
                self.tempNewBuilding:removeFromParentAndCleanup(true)
                self.tempNewBuilding = nil 
                CCLuaLog("createBuilding result:fail")
            end 
        end 
    elseif pbCode == HP_pb.GUILDMANAGER_BEHELPED_S then --联盟帮助
        -- RARootManager.show
         local msg = GuildManager_pb.BeGuildHelpedRes()
        msg:ParseFromString(buffer)

        local helpText = ''

        --描述
        local queueType=msg.queueType
        local des=""
        local helperName = msg.helperName
        if queueType==Const_pb.BUILDING_QUEUE then
        
            local buildId=msg.itemId
            local buildInfo=RABuildingUtility.getBuildInfoById(buildId) 
            des=_RALang("@AllianceHelpBuildQueueInfo",helperName,buildInfo.level,_RALang(buildInfo.buildName))

        elseif queueType==Const_pb.SCIENCE_QUEUE then
            local techId=msg.itemId
            local RAScienceUtility = RARequire('RAScienceUtility')
            local techInfo=RAScienceUtility:getScienceDataById(techId)
            des=_RALang("@AllianceHelpTechQueueInfo",helperName,_RALang(techInfo.techName))

        elseif queueType==Const_pb.CURE_QUEUE then
            des=_RALang("@AllianceHelpCureQueueInfo",helperName)
        end 

        RARootManager.ShowMsgBox(des)
    end
end


function RABuildManager:initData()
    self.hudPanel = nil -- HUD 面板

    self.buildings = {}
    self.movingBuilding = nil 
    self.curBuilding = nil 
    self.curAction = nil --定义当前是在做什么操作

    self.tempNewBuilding = nil --暂存新建筑的 先客户端显示再更新服务器数据 
    self.tilesSprites = nil  --地砖
    self.arrSprites = nil 

    self.yesccbfile = nil --确定节点
    self.noccbfile = nil --取消节点

    self.clickedBuilding = false --是否点击到建筑
    self.isShowingBackground = false --是否已经显示背景了
    self.isMoving = false --是否出发移动了
    self.isClick = false --是否是单击事件


    self.tempNode = nil 
    

    if self.towerPosArr == nil then 
        self.towerPosArr = RABuildingUtility.getTowerPosArr()
    end 
end

function RABuildManager:Enter()
    self:initData()
    RACitySceneManager = RARequire("RACitySceneManager")
    -- self:initAllBuildings()
    -- self:initBackgoundTiles()
    -- local EnterFrameDefine =  RARequire('EnterFrameDefine')

    self:initConfigBuildings()
    

    -- self.isInitBuilding = false
    -- self.buildingsArr = {}

    -- for k,v in pairs(self.buildingDatas) do
    --     self.buildingsArr[#self.buildingsArr+1] = v
    -- end 
    -- self.initIndex = 1

    -- EnterFrameMananger.registerEnterFrameHandler(EnterFrameDefine.BuildingUI.EF_BuildingUpdate, self)
    self:initAllTowers()
    self:initAllBuildings()
    self:initGift()
    self:updateTowerState()
    self:updateAllBuildingHp()
    self:addHandler()
    self:registerMessage()

    self.isInCity = true

    self:initHUD()

end

function RABuildManager:initGift()

    if RAGuideManager:isInGuide() then 
        return 
    end 

    if self.gift ~= nil then 
        self:createGift()
        if self.giftPos == nil then 
            self:genGiftPos()
        end 
        self:setGiftPos()
    end 
end

function RABuildManager:EnterFrame()

    if self.isInitBuilding == false then 
        if self.initIndex > #self.buildingsArr then 
            self.isInitBuilding = true 
        else
            local v = self.buildingsArr[self.initIndex]
            self:initSingleBuildings(v)
            self.initIndex = self.initIndex+1
        end 
    end 
    -- CCLuaLog("RABuildManager:EnterFrame")  
end

function RABuildManager:initHUD()
    self.hudPanel = dynamic_require("RABuildingHUD")
    self.hudPanel:init()
    self.hudPanel.handler = self
end

function RABuildManager:isHudShow()
    return self.hudPanel and self.hudPanel.isShow
end

function RABuildManager:initBackgoundTiles()
    for k,v in pairs(self.buildingTilesMap) do
        RACitySceneManager:setTileEmptyBg(v)
        RACitySceneManager:setTileBlock(true,v)
    end
end

function RABuildManager:Exit()
    self:removeHandler()
    self:removeMessageHandler()
    --clear the buildings by zhenhui
    for k,v in pairs(self.buildings) do
        if v.spineNode ~= nil then
            v:removeFromParentAndCleanup(true)
        end
    end
    self.buildings = nil
    for k,v in pairs(self.configBuildings) do
        if v.spineNode ~= nil then
            v:removeFromParentAndCleanup(true)
        end
    end
    self.configBuildings = nil
    
    for k,v in pairs(self.doodadBuildings) do
        if v.spineNode ~= nil then
            v:removeFromParentAndCleanup(true)
        end
    end
    self.doodadBuildings = nil

    if self.hudPanel ~= nil then 
        self.hudPanel:release()
        self.hudPanel = nil 
    end 

    for i,v in pairs(self.buildCCBIAnis) do
        v:release()
    end
    self.buildCCBIAnis = nil

    self.isInCity = false
end

--移除
function RABuildManager:removeHandler()
    for k, value in pairs(self.netHandlers) do
        RANetUtil:removeListener(value)
    end

    self.netHandlers = {}
end 


function RABuildManager:createBuilding(buildingInfo,isUpgrade)
	
	local building = RABaseBuilding:new("test")
    -- spineContainer:setPositon(ccp(0,0))
    building:initBuild(buildingInfo,isUpgrade)
    -- building:setState("a")
    return building
end

--获得作战指挥中心出征上限
function RABuildManager:getAttackUnitLimit()
    local buildDataArr = self:getBuildDataArray(Const_pb.FIGHTING_COMMAND)
    if #buildDataArr == 0 then --没有
        return 0
    end

    if buildDataArr[1].confData.attackUnitLimit == nil then 
        return 0
    end  

    return buildDataArr[1].confData.attackUnitLimit
end

--获得伤兵上限
function RABuildManager:getWoundedLimit()
    local buildDataArr = self:getBuildDataArray(Const_pb.HOSPITAL_STATION)
    if #buildDataArr == 0 then --没有
        return 0
    end

    local totalNum = 0

    for k,v in pairs(buildDataArr) do
        totalNum = totalNum + v.confData.woundedLimit
    end

    return totalNum
end

function RABuildManager:initConfigBuildings()
    -- body
    self.configBuildings = {}
    self.doodadBuildings = {}
    self.buildCCBIAnis = {}
    local base_initialization_conf = RARequire("base_initialization_conf")
    for k,v in pairs(base_initialization_conf) do
     
        if v.type == 1 then 
            local buildData = RABuildData:new()
            buildData:initByCfgId(v.buildId)
            buildData:setTilePos({x=v.posX,y=v.posY})
            building = self:createBuilding(buildData)
            RACityScene.mBuildSpineLayer:addChild(building.spineNode)
            self:setTilePos(building,buildData.tilePos)
            building:setState(BUILDING_STATE_TYPE.IDLE)
            self.configBuildings[#self.configBuildings+1] = building
        elseif v.type == 2 then 
            local buildData = RABuildData:new()
            buildData:initByCfgId(v.buildId)
            buildData:setTilePos({x=v.posX,y=v.posY})
            building = self:createBuilding(buildData)
            RACityScene.mBuildSpineLayer:addChild(building.spineNode) 
            self:setDoodadPos(building,buildData.tilePos)
            self.doodadBuildings[#self.doodadBuildings+1] = building
        end 

        --load need ccbi ani
        if v.loadCcbiAni then
            local buildCCBIAni = RABuildCCBIAni:new()
            buildCCBIAni:init(v.loadCcbiAni)
            building.spineNode:addChild(buildCCBIAni.ccbfile) 

            self.buildCCBIAnis[#self.buildCCBIAnis + 1] = buildCCBIAni
        end
    end
end

function RABuildManager:initSingleBuildings(v)
    -- body
    local buildingQueueInfo = RAQueueManager:getQueueDatas(Const_pb.BUILDING_QUEUE)

    local curState = BUILDING_STATE_TYPE.IDLE
    local queueData = nil --是否有队列

    --判断是不是建筑队列 
    if buildingQueueInfo ~= nil then 
        for queueK,queueV in pairs(buildingQueueInfo) do
            if queueV.itemId == v.id then 
                queueData = queueV
                curState = BUILDING_STATE_TYPE.UPGRADE
                break 
            end 
        end
    end

    --判断科技
    if v.confData.buildType == Const_pb.FIGHTING_LABORATORY then 
        if curState == BUILDING_STATE_TYPE.IDLE then 
            local scienceQueueInfo = RAQueueManager:getQueueDatas(Const_pb.SCIENCE_QUEUE)
            
            for queueK,queueV in pairs(scienceQueueInfo) do
                queueData = queueV
                curState = BUILDING_STATE_TYPE.WORKING
            end
        end 
    elseif RABuildingUtility.isTrainBuilding(v.confData.buildType) then --兵营
        if curState == BUILDING_STATE_TYPE.IDLE then

            local soilderQueueData = RAQueueManager:getSoilderQueue(v.confData.buildType)
            if soilderQueueData then 
                queueData = soilderQueueData
                curState = BUILDING_STATE_TYPE.WORKING
            end 
        end 
    elseif v.confData.buildType == Const_pb.HOSPITAL_STATION then --伤兵
        if curState == BUILDING_STATE_TYPE.IDLE then 
            local queueInfo = RAQueueManager:getQueueDatas(Const_pb.CURE_QUEUE)
            
            for queueK,queueV in pairs(queueInfo) do
                queueData = queueV
                curState = BUILDING_STATE_TYPE.WORKING
            end
        end
    elseif v.confData.limitType == Const_pb.LIMIT_TYPE_BUILDING_DEFENDER then  --防御性建筑 
        if curState == BUILDING_STATE_TYPE.IDLE then
            local defenerQueueData = RAQueueManager:getBuildingDefenerQueue(v.id) 
            if defenerQueueData then 
                queueData = defenerQueueData

                if queueData.status == Const_pb.QUEUE_STATUS_UPGRADE then 
                    curState = BUILDING_STATE_TYPE.UPGRADE
                elseif queueData.status == Const_pb.QUEUE_STATUS_REPAIR then 

                end 
            end 
        end 
    end

    local building
    if curState == BUILDING_STATE_TYPE.UPGRADE then 
        building = self:createBuilding(v,true)
    else 
        building = self:createBuilding(v)
    end 

    building.queueData = queueData 
    RACityScene.mBuildSpineLayer:addChild(building.spineNode)
    self.buildings[v.id] = building
    self:setBuildPos(building,v.tilePos)
    -- building.queueData = queueData 
    building:setState(curState)
    building:updateTopStatus()
    building:updateUpgradeIcon() 
end


--初始化塔座
function RABuildManager:initAllTowers()
    self.towerSpines = {}
    self.towerMap = {}
    local RATower = RARequire('RATower')
    for k,v in pairs(self.towerPosArr) do
        local towerSpine = RATower:new({})
        towerSpine:init()
        towerSpine:setTile(v)
        towerSpine.order = k

        self.towerSpines[#self.towerSpines + 1] = towerSpine
        self.towerMap[v.x .. '_' .. v.y] = towerSpine
        RACityScene.mBuildLayer:addChild(towerSpine.spineNode)
    end
end

function RABuildManager:getTower(tilePos)
    return self.towerMap[tilePos.x .. '_' .. tilePos.y]
end

function RABuildManager:getCurTowerLimitNum()
    local num =  RABuildingUtility.getBuildingLimitCount(Const_pb.LIMIT_TYPE_BUILDING_DEFENDER,self:getMainCityLvl())
    return num or 0
end

function RABuildManager:updateAllBuildingHp()
    local num =  self:getCurTowerLimitNum()
    for i=1,num do
        local spine = self.towerSpines[i]

        if spine.building then 
            spine.building:updateHp()

            if spine.building.queueData == nil then 
                spine.building:setState(BUILDING_STATE_TYPE.IDLE)
            end 
        end
    end
end

--刷新塔座状态
function RABuildManager:updateTowerState()
    local num =  self:getCurTowerLimitNum()
    local electricStatus = RAPlayerInfo.raPlayerBasicInfo.electricStatus 
    local powState = TOWER_STATE_TYPE.IDLE_GREEN
    if electricStatus == RAGameConfig.ElectricStatus.Enough then 
        powState = TOWER_STATE_TYPE.IDLE_GREEN
    elseif electricStatus == RAGameConfig.ElectricStatus.Intense then
        powState = TOWER_STATE_TYPE.IDLE_YELLOW
    elseif electricStatus == RAGameConfig.ElectricStatus.NotEnough then
        powState = TOWER_STATE_TYPE.IDLE_RED
    end

    for i=1,#self.towerSpines do
        local spine = self.towerSpines[i]
        if i <= num then
            if spine.building and spine.building.buildData.HP == 0 then 
                spine:setState(TOWER_STATE_TYPE.BROKEN)
            else 
                spine:setState(powState)
            end
        else --未开启
            spine:setState(TOWER_STATE_TYPE.IDLE_CLOSE)
        end  
    end
end

function RABuildManager:initAllBuildings()
    self.movingBuilding = nil 
    self.curBuilding = nil 
 
    local buildingQueueInfo = RAQueueManager:getQueueDatas(Const_pb.BUILDING_QUEUE)
    local defenerBuildingQueueInfo = RAQueueManager:getQueueDatas(Const_pb.BUILDING_DEFENER)
    
    for k,v in pairs(self.buildingDatas) do
        
        local curState = BUILDING_STATE_TYPE.IDLE
        local queueData = nil --是否有队列

        --判断是不是建筑队列 
        if buildingQueueInfo ~= nil then 
            for queueK,queueV in pairs(buildingQueueInfo) do
                if queueV.itemId == v.id then 
                    queueData = queueV
                    curState = BUILDING_STATE_TYPE.UPGRADE
                    break 
                end 
            end
        end

        --判断是不是防御建筑升级或者维修队列
        if defenerBuildingQueueInfo ~= nil then 
            for queueK,queueV in pairs(defenerBuildingQueueInfo) do
                if queueV.itemId == v.id then 
                    queueData = queueV
                    curState = BUILDING_STATE_TYPE.UPGRADE
                    break 
                end 
            end
        end

        --判断科技
        if v.confData.buildType == Const_pb.FIGHTING_LABORATORY then 
            if curState == BUILDING_STATE_TYPE.IDLE then 
                local scienceQueueInfo = RAQueueManager:getQueueDatas(Const_pb.SCIENCE_QUEUE)
                
                for queueK,queueV in pairs(scienceQueueInfo) do
                    queueData = queueV
                    curState = BUILDING_STATE_TYPE.WORKING
                end
            end 
        elseif RABuildingUtility.isTrainBuilding(v.confData.buildType) then --兵营
            if curState == BUILDING_STATE_TYPE.IDLE then

                local soilderQueueData = RAQueueManager:getSoilderQueue(v.confData.buildType)
                if soilderQueueData then 
                    queueData = soilderQueueData
                    curState = BUILDING_STATE_TYPE.WORKING
                end 
            end 
        elseif v.confData.buildType == Const_pb.HOSPITAL_STATION then --伤兵
            if curState == BUILDING_STATE_TYPE.IDLE then 
                local queueInfo = RAQueueManager:getQueueDatas(Const_pb.CURE_QUEUE)
                
                for queueK,queueV in pairs(queueInfo) do
                    queueData = queueV
                    curState = BUILDING_STATE_TYPE.WORKING
                end
            end
        elseif v.confData.limitType == Const_pb.LIMIT_TYPE_BUILDING_DEFENDER then  --防御性建筑 
            if curState == BUILDING_STATE_TYPE.IDLE then
                local defenerQueueData = RAQueueManager:getBuildingDefenerQueue(v.id) 
                if defenerQueueData then 
                    queueData = defenerQueueData

                    if queueData.status == Const_pb.QUEUE_STATUS_UPGRADE then 
                        curState = BUILDING_STATE_TYPE.UPGRADE
                    elseif queueData.status == Const_pb.QUEUE_STATUS_REPAIR then 

                    end 
                end 
            end 
        elseif v.confData.buildType == Const_pb.EINSTEIN_LODGE then   --爱因斯坦时光机器
            local einsteinState = BUILDING_STATE_TYPE.WORKING

            if v.status == Const_pb.DAMAGED then 
                einsteinState = BUILDING_STATE_TYPE.IDLE
            elseif v.status == Const_pb.READY_TO_CREATE then     
                einsteinState = BUILDING_STATE_TYPE.WORKING_START
            end
            curState = einsteinState
        end

        local building
        if curState == BUILDING_STATE_TYPE.UPGRADE then 
            building = self:createBuilding(v,true)
        else 
            building = self:createBuilding(v)
        end 

        building.queueData = queueData 
        RACityScene.mBuildSpineLayer:addChild(building.spineNode)
        self.buildings[v.id] = building
        self:setBuildPos(building,v.tilePos)
        -- building.queueData = queueData 
        building:setState(curState)
        building:updateTopStatus()
        building:updateUpgradeIcon() 
    end

    self:reorderAllBuildings()
end

-- function RABaseBuilding:updateAllUpgradeIcon()
--     for k,v in pairs(self.buildings) do
--         v:updateUpgradeIcon()
--     end
-- end

-- 创建建筑协议
function RABuildManager:sendCreateBuildCmd(cfgId,x,y)
    CCLuaLog("sendCreateBuildCmd")
    local Building_pb = RARequire("Building_pb")
    local cmd = Building_pb.BuildingCreateReq()
    cmd.buildCfgId = cfgId
    cmd.x = x
    cmd.y = y
    RANetUtil:sendPacket(HP_pb.BUILDING_CREATE_C, cmd)
end

-- 移动建筑协议
function RABuildManager:sendMoveBuildCmd(buildId,target_x,target_y)
    CCLuaLog("sendMoveBuildCmd")
    local Building_pb = RARequire("Building_pb")
    local cmd = Building_pb.BuildingMoveReq()
    cmd.id = buildId
    cmd.target_x = target_x
    cmd.target_y = target_y
    RANetUtil:sendPacket(HP_pb.BUILDING_MOVE_C, cmd)
end

function RABuildManager:sendUpgradeBuildCmd(buildId,isImmediately)
    CCLuaLog("sendUpgradeBuildCmd:" .. buildId)
    local buildData = self.buildingDatas[buildId]
    local Building_pb = RARequire("Building_pb")
    local cmd = Building_pb.BuildingUpgradeReq()
    cmd.id = buildId
    cmd.immediately = isImmediately
    cmd.buildCfgId = buildData.confData.id
    RANetUtil:sendPacket(HP_pb.BUILDING_UPGRADE_C, cmd)
end

--改造建筑(防御建筑，资源建筑)
function RABuildManager:sendReBuildCmd(buildId, reBuildId, isImmediately)
    CCLuaLog("sendReBuildCmd  buildId:" .. buildId .. "reBuildId: " .. reBuildId)
    local Building_pb = RARequire("Building_pb")
    local cmd = Building_pb.BuildingRebuildReq()
    cmd.id = buildId
    cmd.immediately = isImmediately
    cmd.buildCfgId = reBuildId
    RANetUtil:sendPacket(HP_pb.BUILDING_REBUILD_C, cmd)
end

--防御建筑修理协议
function RABuildManager:sendRepairBuildCmd(buildId, isImmediately)
    CCLuaLog("sendRepairBuildCmd:" .. buildId)
    local Building_pb = RARequire("Building_pb")
    local cmd = Building_pb.BuildingRepairReq()
    cmd.id = buildId
    cmd.immediately = isImmediately
    RANetUtil:sendPacket(HP_pb.BUILDING_REPAIR_C, cmd)
end

--通过ID得到数据
function RABuildManager:getBuildDataById(id)
    return self.buildingDatas[id]
end

--desc:通过buildcfgid(210203)判断是否存在该类型的建筑
function RABuildManager:hasBuildByBuidCfgId(cfgId)
    for k,v in pairs(self.buildingDatas) do
        local buildInfo = v
        if v and v.confData and v.confData.id == cfgId then
            return true
        end
    end

    return false
end

function RABuildManager:getBuildMaxLevel( buildType )
    local buildDataTable = self:getBuildDataArray(buildType)

    table.sort( buildDataTable, function (v1,v2)
        return v1.confData.level> v2.confData.level
        end)

    if #buildDataTable == 0 then 
        return 0
    end 
    return buildDataTable[1].confData.level
end

--desc:通过建筑的frontBuild，判断当前建筑是否可以建造
function RABuildManager:isBuildCanCreateByFrontBuild(cfgId)
    local buildType = tonumber(string.sub(tostring(cfgId), 1, 4))
    local buildLv = tonumber(string.sub(tostring(cfgId), -2))
    local buildTypeBuildings = self.buildingIndex[buildType]

    if buildTypeBuildings then
        for k,v in pairs(buildTypeBuildings) do
            if v.confData.level >= buildLv then
                return true
            end
        end
    end
    return false
end

function RABuildManager:createTempBuilding(buildingInfo)
    --创建临时建筑
    local building = RABaseBuilding:new()
    building:initBuild(buildingInfo)
    building.buildData.HP = building.buildData.totalHP
    building:setState(BUILDING_STATE_TYPE.IDLE)
    building:setOpacity(105)
    -- 
    -- building:setColor(ccc3(255,0,0))
    return building
end

--设置底座
function RABuildManager:initTileSprites(building)

    self.tilesSprites = {}
    self.tilesSprites["green"] = {}
    self.tilesSprites["red"] = {}
    local layer = RACityScene.mBuildSpineLayer
    local tileMaps = building:getTilesMap()
    local index = 1
    for k,v in pairs(tileMaps) do
        local spacePos = RATileUtil:tile2Space(RACityScene.mTileMapGroundLayer,v)
        
        local sprite = CCSprite:create("Tile_Green.png")
        sprite:setAnchorPoint(0.5,0)
        sprite:setPosition(spacePos)
        self.tilesSprites["green"][index] = sprite
        layer:addChild(sprite)
        layer:reorderChild(sprite,1000)

       
        sprite = CCSprite:create("Tile_Red.png")
        sprite:setAnchorPoint(0.5,0)
        sprite:setPosition(spacePos)
        self.tilesSprites["red"][index] = sprite
        layer:addChild(sprite)
        layer:reorderChild(sprite,1000)
        index = index + 1
    end

    local x,y = building:getPosition()
    local length = building.buildData.confData.length
    local width = building.buildData.confData.width
    
    self.arrSprites = {}
    local sprite = CCSprite:create("Common_u_BuildingArrow_LD.png")
    sprite:setPosition(x - length/2*128,y)
    sprite:setScale(0.5)
    self.arrSprites['LD'] = sprite
    sprite:setAnchorPoint(0.5,0.5)
    layer:addChild(sprite)
    sprite = CCSprite:create("Common_u_BuildingArrow_LT.png")
    self.arrSprites['LT'] = sprite
    sprite:setAnchorPoint(0.5,0.5)
    sprite:setPosition(x + width/2*128,y)
    sprite:setScale(0.5)
    layer:addChild(sprite)
    sprite = CCSprite:create("Common_u_BuildingArrow_RD.png")
    self.arrSprites['RD'] = sprite
    layer:addChild(sprite)
    sprite:setAnchorPoint(0.5,0.5)
    sprite:setScale(0.5)
    sprite = CCSprite:create("Common_u_BuildingArrow_RT.png")
    self.arrSprites['RT'] = sprite
    sprite:setScale(0.5)
    layer:addChild(sprite)
    sprite:setAnchorPoint(0.5,0.5)

    for k,v in pairs(self.arrSprites) do
        layer:reorderChild(v,1000)
    end
end

function RABuildManager:initYesNo()
    self.yesccbfile = UIExtend.loadCCBFile("RAHUDYesNoNode.ccbi",self)
    self.noccbfile  = UIExtend.loadCCBFile("RAHUDYesNoNode.ccbi",self)
    UIExtend.getCCNodeFromCCB(self.yesccbfile,"mYes"):setVisible(true)
    UIExtend.getCCNodeFromCCB(self.yesccbfile,"mNo"):setVisible(false)
    UIExtend.getCCNodeFromCCB(self.noccbfile,"mYes"):setVisible(false)
    UIExtend.getCCNodeFromCCB(self.noccbfile,"mNo"):setVisible(true)
    RACityScene.mBuildUILayer:addChild(self.yesccbfile,1000)
    RACityScene.mBuildUILayer:addChild(self.noccbfile,1000)
    self:setYesNoVisible(false)
    -- local RACitySceneManager = RARequire("RACitySceneManager")
    RACitySceneManager:setControlToCamera(self.yesccbfile)
    RACitySceneManager:setControlToCamera(self.noccbfile)
end 

function RABuildManager:setYesNoVisible(flag)
    self.yesccbfile:setVisible(flag)
    self.noccbfile:setVisible(flag)

    if RAGuideManager.isInGuide() then 
        self.noccbfile:setVisible(false)
    end 
end

function RABuildManager:getGiftData()
    return self.giftData
end

--随机放置个礼包
function RABuildManager:genGiftPos()

    local freePosArr = self:getFreePosInScreen()

    if #freePosArr ~= 0 then 
        local randomIndex = math.random(1,#freePosArr)
        self.giftPos = freePosArr[randomIndex]
    end 

    if self.giftPos == nil then 
        local randomX = math.random(2,29)
        local randomY = math.random(7,55)

        while self.buildingTilesMap[randomX .. "_" .. randomY] ~= nil do
            local randomX = math.random(2,29)
            local randomY = math.random(7,55)
        end 

        self.giftPos = {x = randomX,y=randomY}
    end 
end

function RABuildManager:setGiftPos()
    self.giftSpine:setTile(self.giftPos)
    local nowTileMap = self.giftSpine:getTilesMap()


    for k,v in pairs(nowTileMap) do
        self.buildingTilesMap[k] = v 
        RACitySceneManager:setTileEmptyBg(v)
        RACitySceneManager:setTileBlock(true,v)
    end
end

function RABuildManager:createGift()

    local buildData = RABuildData:new()
    buildData:initByCfgId(220401)
    self.giftData = buildData
    local giftSpine = RABaseBuilding:new()
    giftSpine:initBuild(self.giftData)
    giftSpine:setState(BUILDING_STATE_TYPE.IDLE)
    RACityScene.mBuildSpineLayer:addChild(giftSpine.spineNode)
    self.giftSpine = giftSpine
    self.gift = {}
end

function RABuildManager:removeGift()

    if self.giftSpine ~= nil then
        local nowTileMap = self.giftSpine:getTilesMap()
        for k,v in pairs(nowTileMap) do
            self.buildingTilesMap[k] = nil 
            RACitySceneManager:setTileWhiteBg(v)
            RACitySceneManager:setTileBlock(false,v) 
        end 
        self.giftSpine:removeFromParentAndCleanup(true)
    end 

    self.giftSpine = nil 
    self.giftData = nil 
    self.giftPos = nil 
    self.gift = nil     
end

--获得屏幕内空置的点
function RABuildManager:getFreePosInScreen()
    local buildRank = RATileUtil:getFullScreenTilesRank(RACityScene.mTileMapGroundLayer)
    local freePosArr = {} 
    for x=buildRank.lowTileX,buildRank.highTileX do
        for y= buildRank.lowTileY,buildRank.highTileY do
            -- if self.buildingTilesMap[x .. "_" .. y] == nil then 
            if RACitySceneManager:isBuildBlock({x=x,y=y}) == false then 
                freePosArr[#freePosArr+1] = {x=x,y=y}
            end 
        end 
    end
    return freePosArr
end

function RABuildManager:getPosInScreen(building)
    local buildRank = RATileUtil:getFullScreenTilesRank(RACityScene.mTileMapGroundLayer)
    local centerTile = RATileUtil:getCenterTile(RACityScene.mTileMapGroundLayer)

    -- 先判断中心点
    local pos = nil 
    if self:isBuildingCanPut(building,centerTile) then 
        pos = centerTile
    end 

    -- if pos 

    for y= centerTile.y,buildRank.highTileY do

        if pos ~= nil then 
            break
        end 

        for x=buildRank.lowTileX,buildRank.highTileX do
            -- self.curBuilding:setTile({x = x,y=y})
            local tempPos = {x = x,y=y}
            if self:isBuildingCanPut(building,tempPos) then 
                if self:isBuildingInScreen(building,buildRank,tempPos) then 
                    pos = tempPos
                    break
                end 
            end 
        end
    end

    if pos ==nil then 
        for y=centerTile.y,buildRank.lowTileY,-1 do

            if pos ~= nil then 
                break
            end 

            for x=buildRank.lowTileX,buildRank.highTileX do
                -- self.curBuilding:setTile({x = x,y=y})
                local tempPos = {x = x,y=y}
                if self:isBuildingCanPut(building,tempPos) then 
                    if self:isBuildingInScreen(building,buildRank,tempPos) then 
                        pos = tempPos
                        break
                    end 
                end 
            end
        end 
    end

    building.buildData.tilePos = nil 

    return pos 
end

function RABuildManager:getFreeTower()
    for i=1,#self.towerSpines do
        local spine = self.towerSpines[i]
        if spine:isFree() then 
            return spine
        end 
    end
end

function RABuildManager:buildNew(buildID,isDefense,targetpos)
    -- body
    local isMoveTo = false

    if self.curAction == BUILD_ACTON.CREATE then 
        return 
    end 

    local buildData = RABuildData:new()
    buildData:initByCfgId(buildID)
    self.curBuilding = self:createTempBuilding(buildData)
    RACityScene.mBuildSpineLayer:addChild(self.curBuilding.spineNode)
    self.curAction = BUILD_ACTON.CREATE
    self:initYesNo()

    if isDefense then 
        self:setMoveBuildPos(targetpos)
        self:onYesBtn()
    else  
        
        -- --初始化确定 取消
        -- self:initYesNo()
        
        local pos = nil
        if self.curBuilding.buildData.confData.limitType == Const_pb.LIMIT_TYPE_BUILDING_DEFENDER then 
            pos = self:getFreeTower().tilePos
            isMoveTo = true

        else
            if RAGuideManager.isInGuide() then 
                local guideInfo = RAGuideManager.getConstGuideInfoById(RAGuideManager.currentGuildId)
                if guideInfo ~= 0 and guideInfo.keyWord == RAGuideConfig.KeyWordArray.CircleBuildTypeAndMoveCamera then
                    local Utilitys = RARequire("Utilitys")
                    local posText = Utilitys.Split(guideInfo.buildingArea, '_')
                    if posText[1] ~= '0' and posText[2] ~= '0' then 
                        pos = {x = tonumber(posText[1]),y = tonumber(posText[2])}
                    end 
                end 
            end 

            if pos == nil then 
                pos = self:getPosInScreen(self.curBuilding)
            end

            if pos == nil then 
                pos = RATileUtil:getCenterTile(RACityScene.mTileMapGroundLayer)
            end
        end 

        self:setMoveBuildPos(pos) 

        if RAGuideManager.isInGuide() then 
        -- if true then 
            local handler = function ()
                self:setYesNoVisible(true)
                self.curBuilding:setVisible(true)
                self:initTileSprites(self.curBuilding)
                self:checkPos(self.curBuilding)
            end

            local x,y = self.curBuilding:getCenter()
            RACitySceneManager:cameraGotoSpacePos(ccp(x,y))
            self.curBuilding:setVisible(false)
            performWithDelay(self.curBuilding.spineNode,handler,0.75)
        else
            self:setYesNoVisible(true)
            self:initTileSprites(self.curBuilding)
            self:checkPos(self.curBuilding)

            if isMoveTo then    
                local x,y = self.curBuilding:getCenter()
                RACitySceneManager:cameraGotoSpacePos(ccp(x,y))
            end 
        end
    end  
end

function RABuildManager:isBuildingInScreen(building,buildRank,pos)
    building:setTile(pos)
    local isInScreen = true
    local tileMap = building:getTilesMap()
    for k,v in pairs(tileMap) do
        if v.x<buildRank.lowTileX+1 or v.x>buildRank.highTileX-1 or v.y<buildRank.lowTileY+1 or v.y>buildRank.highTileY-1 then 
            isInScreen = false
            break
        end 
    end 

    building.buildData.tilePos = nil 
    return isInScreen
end

function RABuildManager:isBuildingCanPut(building,pos)
    building:setTile(pos)
    local canPut = false
    if self:isCanPut(building) then 
        canPut = true
    end 

    building.buildData.tilePos = nil 
    return canPut
end

function RABuildManager:setMovingBuildingVisible(flag)
        
    self.movingBuilding:setVisible(flag)
    local nowTileMap = self.movingBuilding:getTilesMap()

    for k,v in pairs(nowTileMap) do
        -- CCLuaLog("K:" .. k)
        if flag then 
            -- CCLuaLog("setTileEmptyBg:" .. k)
            RACitySceneManager:setTileEmptyBg(v)
            RACitySceneManager:setTileBlock(true,v)
        else 
            -- CCLuaLog("setTileWhiteBg:" .. k)
            RACitySceneManager:setTileWhiteBg(v)
            RACitySceneManager:setTileBlock(false,v)
        end 
    end
end


function RABuildManager:debugMode()
    for k,v in pairs(self.buildings) do
        self:deleteBuilding(v)
    end

    self.isDebug = true
    for k,v in pairs(self.buildingDatas) do
        v.confData.buildArtJson = 201501
        -- v.confData.buildArtJson = 'shandian'
        local building = self:createBuilding(v)
        RACityScene.mBuildSpineLayer:addChild(building.spineNode)
        self.buildings[v.id] = building
        self:setBuildPos(building,v.tilePos)
        building.spineNode:runAnimation(0,BUILDING_STATE_TYPE.CONSTRUCTION,-1)
        -- building.spineNode:runAnimation(0,'animation',-1)
    end
end

--开始移动建筑
function RABuildManager:replaceBuild(buildData)

    self:setMovingBuildingVisible(false)
    -- body
    local data = RABuildData:new()
    data.confData = buildData.confData
    data.clickPos = buildData.clickPos
    data.id = buildData.id

    -- CCLuaLog("TIME:" .. os.time())
    self.curBuilding = self:createTempBuilding(data)
    -- CCLuaLog("TIME:" .. os.time())
    RACityScene.mBuildSpineLayer:addChild(self.curBuilding.spineNode)

    self:initYesNo()
    self:setYesNoVisible(true)
    -- self:showHUD(self.curBuilding)
    -- local centerTile = RATileUtil:getCenterTile(RACityScene.mTileMapGroundLayer)
    self:setMoveBuildPos(self.movingBuilding.buildData.tilePos)
    self:initTileSprites(self.curBuilding)
    self:checkPos(self.curBuilding)
    self.curAction = BUILD_ACTON.MOVE
end

function RABuildManager:setAllBuildingsColor(color)
    for k,v in pairs(self.buildings) do

        if self.hudPanel.isShow == true then 
            if self.hudPanel.building ~= v then
                v:setColor(color)
            end  
        else 
            v:setColor(color)
        end 
    end

    for k,v in pairs(self.configBuildings) do
        v:setColor(color)
    end
end

function RABuildManager:onNoBtn()
    -- CCLuaLog("RABuildManager:onNoBtn")
    if self.curAction == BUILD_ACTON.CREATE then 
        self:destoryTempNew()
        MessageManager.sendMessage(MessageDef_MainUI.MSG_ChangeBuildStatus, {isShow = false})
        RARootManager.OpenPage("RAChooseBuildPage")
        MessageManager.sendMessage(MessageDef_MainUI.MSG_HandleChooseBuildPage, {isShow = false})
    elseif self.curAction == BUILD_ACTON.MOVE then 
        self:cancelMovingBuilding()
        MessageManager.sendMessage(MessageDef_MainUI.MSG_HandleChooseBuildPage, {isShow = true}) 
    elseif self.curAction == BUILD_ACTON.MOVE_DEFF then 
        self:DefFinishMoving()
        MessageManager.sendMessage(MessageDef_MainUI.MSG_HandleChooseBuildPage, {isShow = true}) 
    end 

     self.curAction = nil
end

function RABuildManager:onYesBtn()
    -- CCLuaLog("sendCreateBuildCmd")

    if self.curAction == BUILD_ACTON.CREATE then 
        -- local building = RABuildManager:createBuilding(self.curBuilding.buildData)
        -- RACityScene.mBuildSpineLayer:addChild(building.spineNode)
        self.curBuilding:setState(BUILDING_STATE_TYPE.CONSTRUCTION)

        local queueData = RAQueueManager:getSoilderQueue(self.curBuilding.buildData.confData.buildType)
        if queueData ~= nil then 
            self.curBuilding.queueData = queueData 
        end
        

        self.tempNewBuilding = self.curBuilding

        self:sendCreateBuildCmd(self.curBuilding.buildData.confData.id,self.curBuilding.buildData.tilePos.x,self.curBuilding.buildData.tilePos.y)

        self:removeYesNo()
        self:cancelSelectBuilding()
        self.curBuilding = nil 

        MessageManager.sendMessage(MessageDef_MainUI.MSG_ChangeBuildStatus, {isShow = false})
        MessageManager.sendMessage(MessageDef_MainUI.MSG_HandleChooseBuildPage, {isShow = true})

        --新手期，点击建造按钮后，立即屏蔽拖动事件：add by xinghui
        if RAGuideManager.isInGuide() then
            RAGuideManager.saveGuide()
            RARootManager.AddCoverPage()
        end
    else 

        local oriPos = self.movingBuilding.buildData.tilePos
        local desPos = self.curBuilding.buildData.tilePos
        if oriPos.x == desPos.x and oriPos.y == desPos.y then 
            self:cancelMovingBuilding(true) 
        else 
            self:deleteTilesMapData(self.movingBuilding)
            RABuildManager:setBuildPos(self.movingBuilding,self.curBuilding.buildData.tilePos,true)
            self:sendMoveBuildCmd(self.movingBuilding.buildData.id,self.curBuilding.buildData.tilePos.x,self.curBuilding.buildData.tilePos.y)
            self:setMovingBuildingVisible(true)
            self:removeYesNo()
            self.movingBuilding:setState(BUILDING_STATE_TYPE.MOVE_FINISH)
            self:cancelSelectBuilding()
            self.curBuilding:removeFromParentAndCleanup(true) 
            self.curBuilding = nil 
        end 
        MessageManager.sendMessage(MessageDef_MainUI.MSG_HandleChooseBuildPage, {isShow = true}) 
    end
    --播放音效
    --common:playEffect("build1")  -- 老牛需求，移动建筑后或者其他的 打钩的话播放 buildUpComplete.mp3
    common:playEffect("buildUpComplete")
    self.curAction = nil  
end

--设置建筑移动点并添加遮挡区
function RABuildManager:setBuildPos(building,tilePos,isReorder)

    self:setTilePos(building,tilePos) 
    local nowTileMap = building:getTilesMap()

    local doodads = {}
    for k,v in pairs(nowTileMap) do
        if self.doodadTilesMap[k] ~= nil then 
            doodads[self.doodadTilesMap[k]] = true
        end 
    end 

    for k,v in pairs(doodads) do
        self:setDoodadVisible(k,false)
    end

    for k,v in pairs(nowTileMap) do
        self.buildingTilesMap[k] = v 
        RACitySceneManager:setTileEmptyBg(v)
        RACitySceneManager:setTileBlock(true,v)
    end

    if isReorder then 
        self:reorderAllBuildings()
    end 

    if building.buildData.confData.limitType == Const_pb.LIMIT_TYPE_BUILDING_DEFENDER then 
        local spine = self.towerMap[tilePos.x .. '_' .. tilePos.y]
        if spine ~= nil then 
            spine.building = building
        end
    end 
end

--设置建筑位置
function RABuildManager:setTilePos(building,tilePos)
    building:setTile(tilePos)
    -- local x,y = building:getCenter()
    -- RACityScene.mBuildSpineLayer:reorderChild(building.spineNode,-y)
    -- local order = 0
    -- if tilePos.y%2==0 then 
    --     order = tilePos.y - tilePos.x*2
    -- else 
    --     order = tilePos.y - tilePos.x*2-1
    -- end  
    -- if isReorder then 
    --     self:reorderAllBuildings()
    -- end 
    -- RACityScene.mBuildSpineLayer:reorderChild(building.spineNode,tilePos.y*10 + order)
    -- RACityScene.mBuildSpineLayer:reorderChild(building.spineNode,y*10-x)
end

function RABuildManager:reorderAllBuildings()

    -- local buildDatas = {}
    -- for k,v in pairs(self.buildingDatas) do
    --     buildDatas[#buildDatas+1] = v
    -- end

    -- table.sort(buildDatas, function(a,b)
    --     if a.lowX >= b.lowX and a.highX <= b.highX then 
    --         return true
    --     elseif b.lowX >= a.lowX and  b.highX <= b.highX then
    --         return false
    --     elseif a.lowX <= b.lowX and a.highX <= b.highX then 
    --         return false 
    --     else 
    --         return true
    --     end 
    --     return false
    -- end
    -- )

    -- for i,v in ipairs(buildDatas) do
    --     local building = self.buildings[v.id]
    --     RACityScene.mBuildSpineLayer:reorderChild(building.spineNode,i)
    -- end
end

function RABuildManager:setDoodadPos(building,tilePos)
    -- body
    self:setTilePos(building,tilePos)
    local nowTileMap = building:getTilesMap()

    for k,v in pairs(nowTileMap) do
        self.doodadTilesMap[k] = building
        RACitySceneManager:setTileBlock(true,v)
    end
end

function RABuildManager:setDoodadVisible(building,flag)
    building.spineNode:setVisible(flag)

    local nowTileMap = building:getTilesMap()
        
    for k,v in pairs(nowTileMap) do
        if flag == true then 
            RACitySceneManager:setTileBlock(true,v)
        else
            RACitySceneManager:setTileBlock(false,v)
        end 
    end  
end


--设置建筑移动点 不更新占地格子
function RABuildManager:setMoveBuildPos(tilePos)

    if self.curBuilding.buildData.clickPos ~= nil then 
        
    end 

    --如果是同一区域，不处理
    if self.curBuilding.buildData.tilePos ~= nil and self.curBuilding.buildData.tilePos.x == tilePos.x and self.curBuilding.buildData.tilePos.y == tilePos.y then 
        return false
    end 

    self.curBuilding:setTile(tilePos)
    RACityScene.mBuildSpineLayer:reorderChild(self.curBuilding.spineNode,1000)

    local contentSize = self.yesccbfile:getContentSize()
    local bulidPos = RATileUtil:tile2Space(RACityScene.mTileMapGroundLayer,self.curBuilding:getTopTile())
    local centerX,centerY= self.curBuilding:getCenter()
    local xDis = 30
    local yDis = 50

    if self.curBuilding.buildData.confData.upHUDPos ~= nil then 
        self.yesccbfile:setPosition(centerX+xDis,centerY+self.curBuilding.buildData.confData.upHUDPos)
        self.noccbfile:setPosition(centerX- contentSize.width - xDis,centerY+self.curBuilding.buildData.confData.upHUDPos)
    else 
        self.yesccbfile:setPosition(centerX+xDis,bulidPos.y+yDis)
        self.noccbfile:setPosition(centerX- contentSize.width - xDis,bulidPos.y+yDis)
    end  

    return true
end

--更新底座显示逻辑
function RABuildManager:checkPos(building)

    if self.tilesSprites == nil then 
        return 
    end 

    local tileMap = building:getTilesMap()

    -- local RACitySceneManager = RARequire("RACitySceneManager")
    local canPut = true
    local index = 1
    for k,v in pairs(tileMap) do
        -- CCLuaLog("k:" .. k)
        local spacePos = RATileUtil:tile2Space(RACityScene.mTileMapGroundLayer,v)
        self.tilesSprites["green"][index]:setPosition(spacePos)
        self.tilesSprites["red"][index]:setPosition(spacePos)

        if RACitySceneManager:isBuildBlock(v) then 
            if self.doodadTilesMap[k] == nil then 
                canPut = false
            end 
        end 
         
        if canPut then 
            if self.buildingTilesMap[k] ~= nil then
                if self.movingBuilding == nil or self.movingBuilding:isContain(v) == false then 
                    canPut = false
                end 
            end 
        end  

        index = index + 1
    end

    if building.buildData.confData.limitType == Const_pb.LIMIT_TYPE_BUILDING_DEFENDER then 
        local pos = nil 
        for k,v in pairs(tileMap) do
            pos = v
        end
        local spine = self.towerMap[pos.x .. '_' .. pos.y]
        if spine == nil then 
            canPut = false
        else
            if spine:isFree() then 
                canPut = true
            else
                if self.movingBuilding == nil or self.movingBuilding:isContain(pos) == false then 
                    canPut = false
                end 
            end 
        end 
    end 

    for i,v in ipairs(self.tilesSprites["green"]) do
        self.tilesSprites["green"][i]:setVisible(canPut)
        self.tilesSprites["red"][i]:setVisible(not canPut)
    end

    for k,v in pairs(self.arrSprites) do
        v:setVisible(canPut)
    end

    if self.curAction ~= nil  then 
        UIExtend.getCCMenuItemImageFromCCB(self.yesccbfile,"mYesBtn"):setEnabled(canPut)
    end 

    local x,y = building:getPosition()
    local length = building.buildData.confData.length
    local width = building.buildData.confData.width
    local xDis = 10
    local yDis = 10
    self.arrSprites['LD']:setPosition(x - length/4.0*128 - xDis,y + length/4.0*64 -yDis)
    self.arrSprites['LT']:setPosition(x - length/2.0*128 + width/4.0*128 -xDis,y + length/2.0*64 + width/4.0*64 + yDis)
    self.arrSprites['RD']:setPosition(x + width/4.0*128 + xDis ,y + width/4.0*64 - yDis )
    self.arrSprites['RT']:setPosition(x + width/2.0*128 - length/4.0*128 + xDis ,y + width/2.0*64 + length/4.0*64+yDis)
end

function RABuildManager:isCanPut(building)
    local tileMap = building:getTilesMap()
    for k,v in pairs(tileMap) do

        if RACitySceneManager:isBuildBlock(v) then 
            if self.doodadTilesMap[k] == nil then 
                return false
            end  
        end 

        if self.buildingTilesMap[k] ~= nil then
            if self.movingBuilding == nil or self.movingBuilding:isContain(v) == false then 
                return false
            end
        end 
    end

    return true
end

function RABuildManager:isCanWalk(tilePos)
    if self.buildingTilesMap[tilePos.x .. "_" .. tilePos.y] ~= nil then 
        return false
    else 
        return true
    end 
end

function RABuildManager:deleteBuilding(building)
    -- body
    building:removeFromParentAndCleanup(true)
    self:deleteTilesMapData(building)
end

function RABuildManager:deleteTilesMapData(building)

    local nowTileMap = building:getTilesMap()

    --获得该建筑挡住的树
    local doodads = {}
    for k,v in pairs(nowTileMap) do
        if self.doodadTilesMap[k] ~= nil then 
            doodads[self.doodadTilesMap[k]] = true
        end 
    end 

    for k1,v1 in pairs(nowTileMap) do
        self.buildingTilesMap[k1] = nil 
        RACitySceneManager:setTileWhiteBg(v1)
        RACitySceneManager:setTileBlock(false,v1)
    end

    for k,v in pairs(doodads) do

        local isCanShow = true  
        local nowTileMap = k:getTilesMap()

        for k1,v1 in pairs(nowTileMap) do
            if self.buildingTilesMap[k1] ~= nil then 
                isCanShow = false
                break
            end 
        end

        if isCanShow then 
            self:setDoodadVisible(k,true)
        end 
    end
end

function RABuildManager:cancelSelectBuilding()

    if self.tilesSprites ~= nil then 
        local  index  = 1
        for k,v in pairs(self.tilesSprites["green"]) do
            self.tilesSprites["green"][index]:removeFromParentAndCleanup(true)
            self.tilesSprites["red"][index]:removeFromParentAndCleanup(true)
            index = index + 1
        end
        self.tilesSprites = nil 
    end 

    if self.arrSprites ~= nil then 
        for k,v in pairs(self.arrSprites) do
            v:removeFromParentAndCleanup(true)
        end
        self.arrSprites = nil 
    end 

    if self.hudPanel ~= nil then 
        self.hudPanel:hide()
    end
end

function RABuildManager:removeYesNo()
    self.yesccbfile:removeFromParentAndCleanup(true)
    self.yesccbfile = nil 
    self.noccbfile:removeFromParentAndCleanup(true)
    self.noccbfile = nil   
end

function RABuildManager:destoryTempNew()
    self:removeYesNo()

    self:cancelSelectBuilding()

    self.curBuilding:removeFromParentAndCleanup(true) 
    self.curBuilding = nil 
end


-- BUILDING_BTN_TYPE = 
-- {
--     DETAIL = 0,
--     UPGRADE = 1,
--     TRAIN = 2,
--     RESEARCH = 3
-- }

--随机选择播放的音效
function RABuildManager:onRandom(count)
    local n = 0
    math.randomseed(os.time())
    for i = 1, count do
        n = math.random(count)
    end
    return n
end

function RABuildManager:onHUDHandler(buildData,btnType)
    CCLuaLog("RABuildManager:onHUDHandler")
    --移除guidePage:by xinghui
    if RAGuideManager.isInGuide() then
        RARootManager.AddCoverPage({["update"] = true})
    end
    RARootManager.RemoveGuidePage()

    --播放音效
    common:playEffect("click_build_btn",btnType)

    if btnType == BUILDING_BTN_TYPE.DETAIL then --详情
        RARootManager.OpenPage("RABuildInformationNewPage", buildData,false,true,true)
       --RARootManager.OpenPage("RABuildInformation", buildData,false,true,true)
        --测试代码

        -- self:createGift()
        -- self:genGiftPos()
        -- self:setGiftPos()
    elseif btnType == BUILDING_BTN_TYPE.PRISON then --监狱
        RARootManager.OpenPage("RAPrisonPage", buildData,true,true)
    elseif btnType == BUILDING_BTN_TYPE.WAREHOUSE then --仓库
        RARootManager.OpenPage("RAReposityPage")
    elseif btnType == BUILDING_BTN_TYPE.UPGRADE then --升级
        local RAGuideManager=RARequire("RAGuideManager")
        if RAGuideManager.partComplete.Guide_UIUPDATE and RAGuideManager.isInGuide() then
            RARootManager.AddCoverPage()
            RARootManager.RemoveGuidePage()
        end
        RARootManager.OpenPage("RABuildPromoteNewPage", buildData)
        -- self:removeGift()
    elseif btnType == BUILDING_BTN_TYPE.REPAIR then --防御建筑修理
        RARootManager.OpenPage("RABuildingRepairPage", buildData,true,true,true)
        -- self:removeGift()    
    elseif btnType == BUILDING_BTN_TYPE.TRAIN_BARRACKS or
    btnType == BUILDING_BTN_TYPE.TRAIN_WAR_FACTORY or
    btnType == BUILDING_BTN_TYPE.TRAIN_REMOTE_FIRE_FACTORY or
    btnType == BUILDING_BTN_TYPE.TRAIN_RAIR_FORCE_COMMAND then 
     --造兵
        local RAGuideManager=RARequire("RAGuideManager")
        if RAGuideManager.partComplete.Guide_UIUPDATE and RAGuideManager.isInGuide() then
            RARootManager.AddCoverPage()
            RARootManager.RemoveGuidePage()
        end
        -- RARootManager.OpenPage("RAArsenalPage", buildData,true,true)
        RARootManager.OpenPage("RAArsenalNewPage", buildData,true,true)
    elseif btnType == BUILDING_BTN_TYPE.RESEARCH then  --研究
        local RAGuideManager=RARequire("RAGuideManager")
        if RAGuideManager.partComplete.Guide_UIUPDATE and RAGuideManager.isInGuide() then
            local RAGuideConfig=RARequire("RAGuideConfig")
            local data={}
            data.scienceId=RAGuideConfig.guideScienceId
            RARootManager.AddCoverPage()
            RARootManager.RemoveGuidePage()
            RARootManager.OpenPage("RAScienceTreePage", data,true,true)
        else
            RARootManager.OpenPage("RAScienceTreePage", nil,true,true)
        end
    elseif btnType == BUILDING_BTN_TYPE.RADAR then  --雷达
         RARootManager.OpenPage("RARadarWarningPage", buildData,true,true)
    elseif btnType == BUILDING_BTN_TYPE.EMBASSY then --大使馆
       
        RARootManager.OpenPage("RAEmabassyPage", buildData,true,true)
    elseif btnType == BUILDING_BTN_TYPE.MAKE then --研制
         RARootManager.ShowMsgBox(_RALang("@NoOpenTips"))
    elseif btnType == BUILDING_BTN_TYPE.TREAT then --医疗
        RARootManager.OpenPage("RAHospitalUIPage", buildData,true,true)
    elseif btnType == BUILDING_BTN_TYPE.SPEEDUP then --加速
        local building = self.buildings[buildData.id]
	    RARootManager.showCommonItemsSpeedUpPopUp(building.queueData)
        self:cancelSelectBuilding()
    elseif btnType == BUILDING_BTN_TYPE.GOLDSPEEDUP then --金币加速
        local building = self.buildings[buildData.id]
        local RAQueueUtility = RARequire('RAQueueUtility')
        RAQueueUtility.showSpeedupByGoldWindow(building.queueData)
        self:cancelSelectBuilding()
    elseif btnType == BUILDING_BTN_TYPE.CANCEL_BUILDING_UPGRADE or --取消队列
        btnType == BUILDING_BTN_TYPE.CANCEL_TRAIN or
        btnType == BUILDING_BTN_TYPE.CANCEL_RESEARCH or
        btnType == BUILDING_BTN_TYPE.CANCEL_MAKE or
        btnType == BUILDING_BTN_TYPE.CANCEL_TREAT then 
        local RAQueueUtility = RARequire('RAQueueUtility')
        local building = self.buildings[buildData.id]
        RAQueueUtility.showCancelQueueWindow(building.queueData)
        self:cancelSelectBuilding()
    elseif btnType == BUILDING_BTN_TYPE.GETTROOP then
        local playEffectName = nil
        local playEffectId = nil
        if buildData.confData.buildType == Const_pb.BARRACKS then   --兵营
            playEffectName = "clickSoldiers"
            playEffectId = self:onRandom(4) 
        elseif buildData.confData.buildType == Const_pb.WAR_FACTORY then -- 战车工厂
            playEffectName = "clickTank"
            playEffectId = self:onRandom(4) 
        elseif buildData.confData.buildType == Const_pb.REMOTE_FIRE_FACTORY then -- 远程火力工厂
            playEffectName = "clickRocketCar"
            playEffectId = self:onRandom(2) 
        elseif buildData.confData.buildType == Const_pb.AIR_FORCE_COMMAND then --空指部
            playEffectName = "clickAircraft"
            playEffectId = self:onRandom(2) 
        end
        common:playEffect(playEffectName,playEffectId)
        local RAArsenalManager = RARequire('RAArsenalManager')
        return RAArsenalManager:sendCollectArmyCmd(buildData.id)
    elseif btnType == BUILDING_BTN_TYPE.GETCURE then                    --治疗完成后收兵
        RANetUtil:sendPacket(HP_pb.COLLECT_CURE_FINISH_SOLDIER, nil)
    elseif btnType == BUILDING_BTN_TYPE.FREETIME then --免费时间
        
        --避免快速点击
        local nowTime = os.time()
        local diffTime = nowTime - lastTime
        if diffTime < 2 then return end
        lastTime = nowTime
        --RARootManager.ShowWaitingPage(true)
        local building = self.buildings[buildData.id]
        RAQueueManager:sendQueueFreeFinish(building.queueData.id)
        
        if self.curAction == nil then 
            self:cancelSelectBuilding()
        end 

        self:freeTimeGuiderHandler()
    elseif btnType == BUILDING_BTN_TYPE.HELP then --请求帮助
        local RAAllianceProtoManager =  RARequire('RAAllianceProtoManager')
        local building = self.buildings[buildData.id]
        -- RAQueueManager:sendQueueFreeFinish(building.queueData.id)
        RAAllianceProtoManager:sendApplyHelpInfoReq(building.queueData.id)
        RARootManager.ShowMsgBox(_RALang('@NeedAllianceHelpDone'))

        building.isHideHelpBtn = true
        building:hideHelpBtn()

    elseif btnType == BUILDING_BTN_TYPE.POWER_DETAIL then --电力详情
        RARootManager.OpenPage('RAElectricInfoPage', nil, false, true, true)
    elseif btnType == BUILDING_BTN_TYPE.EINSTEIN_NOT_REACH then --爱因斯坦时光机器 未达成激活  
        RARootManager.OpenPage("RATimeMachinePopUp", buildData,false,true,true)
    elseif btnType == BUILDING_BTN_TYPE.EINSTEIN_REACH then     --爱因斯坦时光机器 达成激活条件，但是未激活    
        self:sendCreateBuildCmd(buildData.confData.id,buildData.tilePos.x,buildData.tilePos.y)
    end    
end

function RABuildManager:freeTimeGuiderHandler()
    if RAGuideManager.isInGuide() then 
        local keyWord = RAGuideManager.getKeyWordById(RAGuideManager.currentGuildId)
        if keyWord == RAGuideConfig.KeyWordArray.CircleFreeBtn then 
            --RAGuideManager.gotoNextStep()--点击free
        end 
    end
end

function RABuildManager:checkIsEdge(screenPoint,newSpacePos,tilePos)
    
    if screenPoint.x <100 or screenPoint.x >540 
    or screenPoint.y <100 or screenPoint.y >(winSize.height-200) then

        local centerSpacePos =  RACitySceneManager.convertScreenPos2TerrainPos(RACcp(winSize.width/2, winSize.height/2))
        local newSpace = ccp((centerSpacePos.x + newSpacePos.x  )/2,(centerSpacePos.y + newSpacePos.y )/2) 
        RACityScene.mCamera:lookAt(newSpace,0.5,false)
        newSpace:delete()
    end
end

function RABuildManager:getClickBuilding(tilePos)
    for i,v in pairs(self.buildings) do
        if v:isContain(tilePos) then 
            v.buildData:setClickTile(tilePos)
            return v
        end   
    end 
    return nil 
end

function RABuildManager:showHUD(building)
    --移除新手页面：add by xinghui
    if RAGuideManager.isInGuide() then
        RARootManager.AddCoverPage({["update"] = true})
    end
    RARootManager.RemoveGuidePage()

    if building == nil then 
        return 
    end 
    -- if self.hudPanel ~= nil then
    --     if self.hudPanel.building == building then 
    --         return
    --     else 
    --         self.hudPanel:removeFromParentAndCleanup(true)
    --     end  
    -- end 
    if self.hudPanel.isShow == true then 
        if self.hudPanel.building == building then 
            self:onHUDAnimationDone(building.buildData)
            return 
        else 
            self.hudPanel:hide()
        end 
    end 

    --播放音效
    common:playEffect("click_build",building.buildData.confData.buildType)
    
    -- local hudPanel = dynamic_require("RABuildingHUD")
    -- hudPanel:init()
    self.hudPanel:show(building)
    
    local x,y = building:getPosition()
    local centerX,centerY = building:getCenter()

    if building.buildData.confData.downHUDPos ~= nil then 
        self.hudPanel:setPosition(centerX,centerY+building.buildData.confData.downHUDPos) 
    else
        self.hudPanel:setPosition(centerX,y) 
    end 

    local x,y = building.spineNode:getPosition();

    --转换为屏幕坐标
    local _ccp = ccp(x, y)
    local pos = building.spineNode:getParent():convertToWorldSpace3D(_ccp)
    print("building.spineNode:convertToWorldSpace   pos.x is ",pos.x,"pos.y",pos.y)
    _ccp:delete()
    print("x:"..pos.x ..",y:"..pos.y)

    local btnSize = #self.hudPanel.btnTable / 2

    --根据屏幕大小 移动摄像机
    local winSize = CCDirector:sharedDirector():getWinSize()
    local WinX = winSize.width
    local WinY = winSize.height
    local leftX = pos.x - (tonumber(btnSize) * 65)
    local rightX = pos.x + (tonumber(btnSize) * 65)

    local buttonY = pos.y - 300
    local topY = pos.y 

    if leftX < 0 or WinX <= rightX or  buttonY < 0 or WinY <= topY then
        local tilePos = CCPoint(building.buildData.tilePos.x,building.buildData.tilePos.y)
        local RACitySceneManager = RARequire("RACitySceneManager")
        RACitySceneManager:cameraGotoTilePos(tilePos)
    end

    -- hudPanel:setPosition(x,y) 
    RACityScene.mBuildUILayer:addChild(self.hudPanel.ccbfile,1000)
    -- self.hudPanel = hudPanel
    -- self.hudPanel.handler = self
    building:playShadow()
end


-- performWithDelay(node, callback, delay)
function RABuildManager:hideLongAni()
    if self.longTouchAni ~= nil then
        self.longTouchAni:release()
        self.longTouchAni = nil 
    end
end

function RABuildManager:TouchBeginHandler(touch,screenPoint,newSpacePos,tilePos)
    --CCLuaLog('RABuildManager:TouchBeginHandler.. tilePos.x:' .. tilePos.x .. '  tilePos.y: ' ..  tilePos.y)
    if self.isInTouch == true then 
        CCLuaLog('self.isInTouch == true')
        if self.curBuilding ~= nil then 
            self.curBuilding.timeNode:stopAllActions()
            self:hideLongAni()
            self.curBuilding.buildData:setClickTile(nil)
        end 
        return 
    end 

    self.isInTouch = true

    self.isMoving = false
    self.isClick = true
    self.beginTime = os.time()
    self.clickedBuilding = false
    if self.curAction == BUILD_ACTON.CREATE or self.curAction == BUILD_ACTON.MOVE or self.curAction == BUILD_ACTON.MOVE_DEFF then 
        if self.curBuilding~=nil and  self.curBuilding:isContain(tilePos) then 
            self.curBuilding.buildData:setClickTile(tilePos)
            self.clickedBuilding = true 
        else
            self.clickedBuilding = false
        end
    else
        local building = self:getClickBuilding(tilePos)
        
        if building == nil and RAGuideManager:isInGuide() and self.tempNewBuilding then 
            if self.tempNewBuilding:isContain(tilePos) then 
                building = self.tempNewBuilding
            end 
        end

        if building ~= nil then 

            if building ~= self.curBuilding then 
                if self.curBuilding ~= nil then 
                    -- self:cancelSelectBuilding()
                end 
            
                self.curBuilding = building
            end
            self.clickedBuilding = true
      
        else 
            self.clickedBuilding = false
        end 
    end 


    if self.clickedBuilding == true then

        if self.curBuilding == nil then 
            return 
        end 

        --新手屏蔽长按
        if RAGuideManager:isInGuide() then 
        -- if true then 
            return 
        end 

        --爱因斯坦时光机器 屏蔽长按
        if self.curBuilding.buildData.confData.buildType == Const_pb.EINSTEIN_LODGE then
            return
        end

        if self.curAction == nil then  
            local handler = function ()

                if self.curBuilding == nil then 
                    return 
                end

                self:hideLongAni()
                if RACityMultiLayerTouch.isInScaleState() then
                    return
                end
                
                if self.curBuilding.buildData.confData.limitType == Const_pb.LIMIT_TYPE_BUILDING_DEFENDER then
                    self:cancelSelectBuilding()
                    self:DefStartMoving(self.curBuilding)
                else
                    self.isMoving = true
                    RACityMultiLayerTouch.setEnabled(true,false)
                    RACitySceneManager:showBackGround(true)
                    self.isShowingBackground = true

                    if self.curAction == BUILD_ACTON.CLICKING then
                        self:cancelSelectBuilding()
                        -- CCLuaLog("replaceBuild ........................................")
                        self.movingBuilding = self.curBuilding


                    -- self.curAction = BUILD_ACTON.MOVE
                        -- CCLuaLog("TIME------------------------------------:" .. os.time())
                        self:replaceBuild(self.curBuilding.buildData)
                        self:setYesNoVisible(false)
                    -- self:initTileSprites(self.curBuilding)
                    -- self:checkPos(self.curBuilding)
                        -- CCLuaLog("TIME------------------------------------:" .. os.time())
                    else 
                        self:setYesNoVisible(false)
                    end
                end
                MessageManager.sendMessage(MessageDef_MainUI.MSG_HandleChooseBuildPage, {isShow = false})  
            end
            CCLuaLog("performWithDelay:")
            self.curBuilding.timeNode:stopAllActions()
            self:hideLongAni()

            local aniHandler = function ()
                self.curAction = BUILD_ACTON.CLICKING
                if self.longTouchAni == nil then 
                    self.longTouchAni = RALongTouchAni:new()
                    self.longTouchAni:init()
                    self.longTouchAni.ccbfile:runAnimation('LongTouchAni')
                    RACityScene.mBuildUILayer:addChild(self.longTouchAni.ccbfile)

                    local centerX,centerY = self.curBuilding:getCenter()
                    local topPos = RATileUtil:tile2Space(RACityScene.mTileMapGroundLayer,self.curBuilding:getTopTile())

                    if self.curBuilding.buildData.confData.upButtonPos ~= nil then 
                        self.longTouchAni.ccbfile:setPosition(centerX-125.0/2,centerY+self.curBuilding.buildData.confData.upButtonPos)
                    else 
                        self.longTouchAni.ccbfile:setPosition(centerX-125.0/2,topPos.y+75) 
                    end
                end  
                -- self.curBuilding.timeNode:stopAllActions()
                -- performWithDelay(self.longTouchAni.ccbfile,handler,0.5)  

                -- if self.longTouchAni ~= nil then
                --     self.longTouchAni:release()
                --     self.longTouchAni = nil 
                -- end
            end

            local const_conf = RARequire('const_conf')
            local delay = CCDelayTime:create(const_conf.moveBuildTimerBefore.value * 1.0/100)
            local callfunc = CCCallFunc:create(aniHandler)
            local sequence = CCSequence:createWithTwoActions(delay, callfunc)
            delay = CCDelayTime:create(1)
            sequence = CCSequence:createWithTwoActions(sequence, delay)
            callfunc = CCCallFunc:create(handler)
            sequence = CCSequence:createWithTwoActions(sequence, callfunc)

            self.curBuilding.timeNode:runAction(sequence)
        else 
            -- self.isMoving = true 
        end 
    end 
end

function RABuildManager:DefStartMoving(selectDef)
    self.curAction = BUILD_ACTON.MOVE_DEFF
    self:initDefYesNo(selectDef)
    self:initAllDefTileSprites(selectDef)
end

function RABuildManager:DefFinishMoving()

    self:removeYesNo()
    for k,v in pairs(self.defTilesSprites) do
        v:removeFromParentAndCleanup(true)
    end

    self.defTilesSprites = nil 
    self.curAction = nil 
end 

function RABuildManager:initDefYesNo(selectDef)
    self:initYesNo()
    self.noccbfile:setVisible(true)
    self.yesccbfile:setVisible(false)

    local contentSize = self.noccbfile:getContentSize()
    local bulidPos = RATileUtil:tile2Space(RACityScene.mTileMapGroundLayer,selectDef:getTopTile())
    local centerX,centerY= selectDef:getCenter()

    if selectDef.buildData.confData.upHUDPos ~= nil then 
        self.noccbfile:setPosition(centerX-contentSize.width/2,centerY+self.curBuilding.buildData.confData.upHUDPos)
    else 
        self.noccbfile:setPosition(centerX-contentSize.width/2,centerY+60)
    end  
end

function RABuildManager:initAllDefTileSprites(selectDef)
    self.defTilesSprites = {}
    local layer = RACityScene.mBuildSpineLayer
    local tileMaps = selectDef:getTilesMap()
    local index = 1
    for k,v in pairs(tileMaps) do
        local spacePos = RATileUtil:tile2Space(RACityScene.mTileMapGroundLayer,v)
        
        local sprite = CCSprite:create("Tile_White.png")
        sprite:setAnchorPoint(0.5,0)
        sprite:setPosition(spacePos)
        self.defTilesSprites[#self.defTilesSprites+1] = sprite
        layer:addChild(sprite)
        -- layer:reorderChild(sprite,1000)
    end

    for k,v in pairs(self.towerMap) do
        if v.building ~= selectDef and v:isOpen() then 
            local spacePos = RATileUtil:tile2Space(RACityScene.mTileMapGroundLayer,v.tilePos)
        
            local sprite = CCSprite:create("Tile_Green.png")
            sprite:setAnchorPoint(0.5,0)
            sprite:setPosition(spacePos)
            self.defTilesSprites[#self.defTilesSprites+1] = sprite
            layer:addChild(sprite)
        end
    end


    for k,v in pairs(self.defTilesSprites) do
        layer:reorderChild(v,1000)
    end
end

function RABuildManager:deleteBuildingIndexData(buildData)
    -- body
    local indexTable = self.buildingIndex[buildData.confData.buildType]
    indexTable[buildData.id] = nil
end

function RABuildManager:removeAllBuildDefTileSprites()
    for k,v in pairs(self.defBuildTilesSprites) do
        v:removeFromParentAndCleanup(true)
    end

    self.defBuildTilesSprites = nil 
end

function RABuildManager:initAllBuildDefTileSprites()
    self.defBuildTilesSprites = {}
    local layer = RACityScene.mBuildSpineLayer

    for k,v in pairs(self.towerMap) do
        if v:isFree() then 
            local spacePos = RATileUtil:tile2Space(RACityScene.mTileMapGroundLayer,v.tilePos)
        
            local sprite = CCSprite:create("Tile_Green.png")
            sprite:setAnchorPoint(0.5,0)
            sprite:setPosition(spacePos)
            self.defBuildTilesSprites[#self.defBuildTilesSprites+1] = sprite
            layer:addChild(sprite)
        end
    end

    for k,v in pairs(self.defBuildTilesSprites) do
        layer:reorderChild(v,1000)
    end
end

function RABuildManager:TouchMovedHandler(touch,screenPoint,newSpacePos,tilePos)
    --CCLuaLog('RABuildManager:TouchMovedHandler')

    -- if RAGuideManager.isInGuide() then 
    -- -- if true then 
    --     return
    -- end 
    -- self.isClick = false 
    if self.clickedBuilding == true then 

        --新手期间，不让移动建筑
        if RAGuideManager.isInGuide() then 
            return
        end 

        if self.curBuilding == nil then
            return 
        end 

        if self.curAction == BUILD_ACTON.MOVE or self.curAction == BUILD_ACTON.CREATE then 
            if self.isClick == true then 
               self.isMoving = true
               RACityMultiLayerTouch.setEnabled(true,false)

                if self.curBuilding.buildData.confData.limitType == Const_pb.LIMIT_TYPE_BUILDING_DEFENDER then 
                    self:initAllBuildDefTileSprites()
                    self.isShowDefTile = true
                else 
                   RACitySceneManager:showBackGround(true)
                   self.isShowingBackground = true  
                end
            end  
        end 

        if self.isMoving then 
        --     local newSpacePos = RACitySceneManager.getTouchCityScenePos(touch)
        -- local tilePos = RATileUtil:space2Tile(RACityScene.mTileMapGroundLayer,newSpacePos)
            local clickTile = self.curBuilding.buildData.clickPos 
            local targetPos = {}
            local x,y = self.curBuilding:getXYformCenter(newSpacePos)

            --点任意点移动的公式
            -- targetPos.x = newSpacePos.x - (clickTile.xIndex - clickTile.yIndex)/2.0*128
            -- targetPos.y = newSpacePos.y - (clickTile.xIndex + clickTile.yIndex)/2.0*64

            targetPos.x = x
            targetPos.y = y

            tilePos = RATileUtil:space2Tile(RACityScene.mTileMapGroundLayer,targetPos)
            local isMoveBuildPos = self:setMoveBuildPos(tilePos)
            self:checkPos(self.curBuilding)
            self:checkIsEdge(screenPoint,newSpacePos,tilePos)   
            self:setYesNoVisible(false)

            --先不添加 干掉
--            if isMoveBuildPos then
--                local common = RARequire("common")
--                if m_FrameTime == 0 then
--                    common:playEffect("move")
--                end
--                m_FrameTime = m_FrameTime + common:getFrameTime()
--                if m_FrameTime >= 0.25 then
--                    common:playEffect("move")
--                end
--            end
        else
            self.curBuilding.timeNode:stopAllActions()
            self:hideLongAni()
        end 
    end 

    self.isClick = false 
end

--恢复移动建筑
function RABuildManager:cancelMovingBuilding(isPlayAnimation)
    self:removeYesNo()
    self:cancelSelectBuilding()
    self:setMovingBuildingVisible(true)

    if isPlayAnimation then 
        self.movingBuilding:setState(BUILDING_STATE_TYPE.MOVE_FINISH)
    end 

    self.movingBuilding = nil
    self.curBuilding:removeFromParentAndCleanup(true) 
    self.curBuilding = nil 
end

function RABuildManager:getReadyUpgrateBuilding()

    local buildId = nil 

    --主线任务的类型
    local RATaskManager = RARequire("RATaskManager")
    local buildType = RATaskManager.getTaskBuildType()

    if buildType ~= nil then 
        buildId = self:getCanUpgradBuildByBuildType(buildType)
        if buildId ~= nil then 
            -- CCLuaLog("-------------------------:" .. buildId)
            return buildId
        end 
    end 

    for i=1,3 do
        buildId = self:getCanUpgradBuildByType(i)
        if buildId ~= nil then 
            -- CCLuaLog("-------------------------:" .. buildId)
            return buildId
        end 
    end
    
    -- CCLuaLog("RETURN NIL")
    return nil 
end

function RABuildManager:moveToBuildingById(id,isSmooth,isShowHud)
    local buildData = self.buildingDatas[id]
    if buildData == nil then 
        return
    end

    if self.curAction == BUILD_ACTON.MOVE then 
        self:onNoBtn()
    end 

    if isShowHud == true then 
        self.mustShowId = buildData.id
    end 

    -- self:setBuildingSelect(buildData.id)
    if isSmooth == nil or isSmooth == true then
        local handler = function ()
            MessageManager.sendMessage(MessageDef_Building.MSG_BuildingMoveToFinshied)

            if isShowHud ~= false then  
                self:setBuildingSelect(buildData.id)
            end 
        end

        local building = self.buildings[id]
        if building ~= nil then 
            performWithDelay(building.timeNode,handler,0.75)
            local x,y = building:getCenter()
            RACitySceneManager:cameraGotoSpacePos(ccp(x,y))
        else 
            RACitySceneManager:cameraGotoTilePos(buildData.tilePos)
        end 
    else 
        if isShowHud ~= false then  
            self:setBuildingSelect(buildData.id)
        end

        local building = self.buildings[id] 

        if building ~= nil then 
            local x,y = building:getCenter()
            RACitySceneManager:cameraGotoSpacePos(ccp(x,y),0,false)
        else 
            RACitySceneManager:cameraGotoTilePos(buildData.tilePos,0,false) 
        end 
        -- RACitySceneManager:cameraGotoTilePos(buildData.tilePos,0,false) 
    end 
end

function RABuildManager:moveToBuilding(buildType)
    local buildDataTable = self:getBuildDataArray(buildType)

    if #buildDataTable == 0 then 
        return 
    end 

    self:setBuildingSelect(buildDataTable[1].id)

    local building = self.buildings[buildDataTable[1].id] 

    if building ~= nil then 
        local x,y = building:getCenter()
        RACitySceneManager:cameraGotoSpacePos(ccp(x,y))
    else 
        RACitySceneManager:cameraGotoTilePos(buildDataTable[1].tilePos)
    end 
end

function RABuildManager:showBuildingByBuildType(buildType,btnType,isClick,isShowHud)
    local buildDataTable = self:getBuildDataArray(buildType)

    table.sort( buildDataTable, function (v1,v2)
        return v1.confData.level> v2.confData.level
        end)

    if #buildDataTable == 0 then 
        return false
    end 
    self:showBuildingById(buildDataTable[1].id,btnType,isClick,isShowHud)
    return true
end

function RABuildManager:showBuildingById(id,btnType,isClick,isShowHud)

    self.needBtnType = btnType
    self.needClick = isClick
    self.needId = id

    if RARootManager.GetIsInWorld() then
        self.showBuildingId = id
        RARootManager.ChangeScene(SceneTypeList.CityScene)
    else
        self:moveToBuildingById(id,true,isShowHud)
    end 
end

function RABuildManager:onHUDAnimationDone(buildData)

     self.mustShowId = nil 
     local guideinfo = RAGuideManager.getConstGuideInfoById()

     if guideinfo ~= nil and guideinfo.btnType ~= nil then 
         local info = self.hudPanel:getBtnInfo(guideinfo.btnType)
         if info ~= nil then 
             info.pos.x = info.pos.x - info.size.width*0.5
             info.pos.y = info.pos.y - info.size.height*0.5

             
                
             MessageManager.sendMessage(MessageDef_Building.MSG_Guide_Hud_BtnInfo,{pos = info.pos, size = info.size})
             return
         end 
     end 


    if self.needId ~= buildData.id then 
        return 
    end 

    if self.needClick then 
        self:onHUDHandler(buildData,self.needBtnType)
    else 
        if self.needBtnType then 
            local info = self.hudPanel:getBtnInfo(self.needBtnType)
            --btn的锚点是在中间，但是需要的是左下角的位置，因此需要处理一下：xinghui

            if info == nil then 
                MessageManager.sendMessage(MessageDef_Guide.MSG_TaskGuide)
            else 
                info.pos.x = info.pos.x - info.size.width*0.5
                info.pos.y = info.pos.y - info.size.height*0.5
                MessageManager.sendMessage(MessageDef_Guide.MSG_TaskGuide,{pos = info.pos, size = info.size})
            end 
        end 
    end 



    self.needClick = nil 
    self.needBtnType = nil 
    self.needId = nil 
end

function RABuildManager:setBuildingSelect(buildingId)
    if buildingId == nil then 
        return     
    end

    if self.mustShowId ~= nil and self.mustShowId ~= buildingId then 
        return 
    end 

    local selectBuilding = self.buildings[buildingId]
    if selectBuilding == nil then 
        return 
    end 

    self.curBuilding = selectBuilding
    self:showHUD(self.curBuilding)
end

function RABuildManager:onClickGiftHandler()
    CCLuaLog('click GiftHandler')
    local RATreasureBoxManager = RARequire("RATreasureBoxManager")
    RATreasureBoxManager:sendAchieveTreasurBoxCmd()
end

function RABuildManager:TouchCancelHandler()
    CCLuaLog('RABuildManager:TouchCancelHandler()')
end

function RABuildManager:TouchEndHandler(touch,screenPoint,newSpacePos,tilePos)
    --CCLuaLog('RABuildManager:TouchEndHandler')
    -- if RAGuideManager.isInGuide() then 
    -- -- if true then 
    --     return
    -- end 


    if self.isShowingBackground == true then 
        RACitySceneManager:showBackGround(false)
        self.isShowingBackground = false
    end

    if self.isShowDefTile == true then 
        self:removeAllBuildDefTileSprites()
        self.isShowDefTile = false
    end  

    if self.curAction == nil then
        if self.clickedBuilding == true and self.isClick == true then --选中了建筑 
            if self.curBuilding.buildData.status == Const_pb.SOILDER_HARVEST then           --训练完成待收兵
                local RAArsenalManager = RARequire('RAArsenalManager') 
                RAArsenalManager:sendCollectArmyCmd(self.curBuilding.buildData.id)  
            elseif self.curBuilding.buildData.status == Const_pb.CURE_FINISH_HARVEST then       --治疗完成待收兵
                RANetUtil:sendPacket(HP_pb.COLLECT_CURE_FINISH_SOLDIER, nil)
            elseif self.curBuilding.buildData.status == Const_pb.DAMAGED then               --爱因斯坦时光机器损毁状态
                self:onHUDHandler(self.curBuilding.buildData,BUILDING_BTN_TYPE.EINSTEIN_NOT_REACH)
            elseif self.curBuilding.buildData.status == Const_pb.READY_TO_CREATE then   --爱因斯坦时光机器待建造状态
                self:onHUDHandler(self.curBuilding.buildData,BUILDING_BTN_TYPE.EINSTEIN_REACH)
            else 
                self:showHUD(self.curBuilding)
            end 
        elseif self.clickedBuilding == false and self.isClick == true then 
            self:cancelSelectBuilding()
            self.curBuilding = nil 
        end
    else
        if self.isMoving == true then 
            self:setYesNoVisible(true)
        end 
    end 

    if self.clickedBuilding then 
        if self.curBuilding ~= nil then 
            self.curBuilding.timeNode:stopAllActions()
            self:hideLongAni()
            self.curBuilding.buildData:setClickTile(nil)
        end 
    end 


    self.isInTouch = false

    -- self.clickedBuilding = false
    RACityMultiLayerTouch.setEnabled(true,true) 

    if self.clickedBuilding == true then 

        -- local tower = self:getTower(tilePos)
        -- if tower then
        --     if self.curAction == BUILD_ACTON.MOVE_DEFF then 
        --         if tower.building ~= self.curBuilding then 
        --             local curPos = self.curBuilding.buildData.tilePos
        --             RABuildManager:setBuildPos(self.curBuilding,tilePos,true)
        --             RABuildManager:setBuildPos(tower.building,curPos,true)
        --             self:sendMoveBuildCmd(self.curBuilding.buildData.id,tilePos.x,tilePos.y) 
        --         end
        --     end
        -- end 
        self.clickedBuilding = false
    else

        --判断是不是点击了装饰用建筑
        for k,v in pairs(self.configBuildings) do
            if v:isContain(tilePos) then 
                self:onMenuBuilding(v.buildData.confData.buildType)
                break
            end 
        end

        --判断是不是点击了礼包
        if self.giftSpine ~=nil and self.giftSpine:isContain(tilePos) then 
            self:onClickGiftHandler()
        end

        -- local oriPos = self.movingBuilding.buildData.tilePos
        -- local desPos = self.curBuilding.buildData.tilePos
        -- if oriPos.x == desPos.x and oriPos.y == desPos.y then 
        --     self:cancelMovingBuilding(true) 
        -- else 
        --     self:deleteTilesMapData(self.movingBuilding)
        --     RABuildManager:setBuildPos(self.movingBuilding,self.curBuilding.buildData.tilePos,true)
        --     self:sendMoveBuildCmd(self.movingBuilding.buildData.id,self.curBuilding.buildData.tilePos.x,self.curBuilding.buildData.tilePos.y)
        --     self:setMovingBuildingVisible(true)
        --     self:removeYesNo()
        --     self.movingBuilding:setState(BUILDING_STATE_TYPE.MOVE_FINISH)
        --     self:cancelSelectBuilding()
        --     self.curBuilding:removeFromParentAndCleanup(true) 
        --     self.curBuilding = nil 
        -- end  


        --判断是不是点击了空炮塔
        local tower = self:getTower(tilePos)
        if tower then      
            if self.curAction == BUILD_ACTON.MOVE_DEFF then

                local curPos = self.curBuilding.buildData.tilePos

                if curPos.x ~= tilePos.x or curPos.y ~= tilePos.y then --点击到了其他位置
                    if tower:isOpen() then --是可开启的

                        local oldtower = self:getTower(curPos)
                        oldtower.building = nil

                        if tower.building == nil then 
                            RABuildManager:setBuildPos(self.curBuilding,tilePos,true)
                        elseif tower.building ~= self.curBuilding then 
                            
                            local targetBuilding = tower.building
                            RABuildManager:setBuildPos(self.curBuilding,tilePos,true)
                            RABuildManager:setBuildPos(targetBuilding,curPos,true)
                            targetBuilding:setState(BUILDING_STATE_TYPE.MOVE_FINISH)
                        end 

                        self.curBuilding:setState(BUILDING_STATE_TYPE.MOVE_FINISH)
                        self:sendMoveBuildCmd(self.curBuilding.buildData.id,tilePos.x,tilePos.y)
                        self:DefFinishMoving()
                        MessageManager.sendMessage(MessageDef_MainUI.MSG_HandleChooseBuildPage, {isShow = true}) 
                    end
                end  
            else 
                if tower:isFree() then
                    if self.curBuilding == nil then  
                        RARootManager.OpenPage("RAChooseBuildPage",{isDefense = true,pos = tilePos})
                        MessageManager.sendMessage(MessageDef_MainUI.MSG_ChangeBuildStatus, {isShow = false})
                        MessageManager.sendMessage(MessageDef_MainUI.MSG_HandleChooseBuildPage, {isShow = false})
                    end 
                else
                    RARootManager.ShowMsgBox(_RALang("@NeedToUpgrateToUnlock"))
                end
            end  
        end     
    end 


    if self.curAction == BUILD_ACTON.CLICKING then 
        self.curAction = nil 
    end 
end


function RABuildManager:onMenuBuilding(buildType)

    --播放音效
    common:playEffect("click_build_btn",buildType)

    if buildType == Const_pb.HELP_PROMPT then --帮助提示牌
        -- CCLuaLog("点击了帮助提示牌")
    elseif buildType == Const_pb.RESOURCES_VIEW then --资源总览
        -- CCLuaLog("点击了资源总览")
    elseif buildType == Const_pb.ARMS_DEALER then --旅行商人
        RARootManager.OpenPage("RABlackShopPage",nil,true)
    elseif buildType == Const_pb.SOILDER_DETAIL_FLAG then --部队详情旗帜
        common:playEffect("clickFlag")
        RARootManager.OpenPage("RATroopsInfoPage")
    elseif buildType == Const_pb.ACTIVITY_CENTER then --活动中心
        RARootManager.OpenPage("RADailyTaskMainPage") 
    end   
end

--根据uitype判断当前玩家拥有建筑中可升级的建筑 uitype:1 功能 2 资源 3 防御
function RABuildManager:getCanUpgradBuildByType(tmpUiType)
    local upgradBuildId = nil
    --根据uitype拿到所有同uitype建筑信息
    local buildUitypeTab={}
    for k,v in pairs(self.buildingDatas) do
        local buildInfo = v
        if tmpUiType == buildInfo.confData.uiType  then
            table.insert(buildUitypeTab,buildInfo)
        end 
    end

    --根据id判断某个建筑能否升级
    if not next(buildUitypeTab) then return nil end 
    for i,v in ipairs(buildUitypeTab) do
       local buildInfo = v
       local isUpgrade=RABuildingUtility.isCanUpgradeBuild(buildInfo.confData.id)
       if isUpgrade then
         upgradBuildId = buildInfo.id
         break
       end 
    end

    return upgradBuildId
end

--根据id判断该建筑升级的限制链中可升级的建筑（排除资源影响）
function RABuildManager:getLastCanUpgradBuildByType(buildId)

    local isUpgrade, frontBuildType = RABuildingUtility.isCanUpgradeBuild(buildId, true)
    if isUpgrade then
        return buildId
    end
    
    if frontBuildType == nil then return false end

    local buildDataTable = self:getBuildDataArray(frontBuildType)

    table.sort( buildDataTable, function (v1,v2)
        return v1.confData.level> v2.confData.level
        end)

    if #buildDataTable == 0 then 
        return false, frontBuildType
    end
    return RABuildManager:getLastCanUpgradBuildByType(buildDataTable[1].confData.id)
end


--根据Buildtype判断当前玩家拥有建筑中可升级的建筑 
function RABuildManager:getCanUpgradBuildByBuildType(tmpType)
     local upgradBuildId = nil
    --根据Buildtype拿到所有同Buildtype建筑信息
    local buildBuildTypeTab={}
    for k,v in pairs(self.buildingDatas) do
        local buildInfo = v
        if tmpType == buildInfo.confData.buildType  then
            table.insert(buildBuildTypeTab,buildInfo)
        end 
    end

    --根据id判断某个建筑能否升级
    if not next(buildBuildTypeTab or {}) then return nil end 
    for i,v in ipairs(buildBuildTypeTab) do
       local buildInfo = v
       local isUpgrade=RABuildingUtility.isCanUpgradeBuild(buildInfo.confData.id)
       if isUpgrade then
         upgradBuildId = buildInfo.id
         break
       end 
    end

    return upgradBuildId
end

--根据BuildTypeId, 根据BuildLevel 查找到该建筑信息
function RABuildManager:getBuildInfoByBuildType(buildTypeId,buildLevel)
    for i,buildInfo in pairs(build_conf) do
        if buildInfo.buildType == buildTypeId and buildInfo.level == buildLevel then
            return buildInfo
        end
    end
    return nil
end

return RABuildManager

