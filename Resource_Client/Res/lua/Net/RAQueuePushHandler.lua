--region RAPlayerPushHandler.lua
--Date  2016/5/28
--Author zhenhui
--此文件由[BabeLua]插件自动生成

local RAQueuePushHandler = {}

function RAQueuePushHandler:onReceivePacket(handler)
    local HP_pb = RARequire("HP_pb")
    local building_pb = RARequire("Building_pb")
    local Queue_pb = RARequire("Queue_pb")
    local RABuildManager = RARequire("RABuildManager")
    local RAQueueManager = RARequire("RAQueueManager")
    
    RARequire("MessageDefine")
    RARequire("MessageManager")

    local pbCode = handler:getOpcode()
    local buffer = handler:getBuffer()
    if pbCode == HP_pb.PLAYER_BUILDING_SYNC_S then  --同步建筑
        local msg = building_pb.HPBuildingInfoSync()
        msg:ParseFromString(buffer)
        
        RARequire("RABuildData")
        for i=1,#msg.buildings do
        	local buildData = RABuildData:new()
        	buildData:initByPb(msg.buildings[i])
            RABuildManager:addBuildData(buildData)
        end
    elseif pbCode == HP_pb.DEFENCE_BUILDING_CHANGE_PUSH then --同步防御建筑血量
        local msg = building_pb.DefenceBuildingStatusPB()
        msg:ParseFromString(buffer)
        
        for i=1,#msg.defBuildHp do

            local defBuildHp = msg.defBuildHp[i]
            local id = defBuildHp.id
            local hp = defBuildHp.hp
            local normal = defBuildHp.normal

            local buildData = RABuildManager:getBuildDataById(id)
            buildData.HP = hp
            buildData.normal = normal
        end  

        -- 
        MessageManager.sendMessage(MessageDef_CITY.MSG_NOTICE_ATTACK_HP_CHANGE)  
    elseif pbCode == HP_pb.BUILDING_CREATE_PUSH then --建造建筑 --客户端预先处理了。。
        local msg = building_pb.BuildingPB()
        msg:ParseFromString(buffer)
        -- local buildData = RABuildData:new()
        -- buildData:initByPb(msg.building)
        -- RABuildManager:addBuildData(buildData)
        -- CCLuaLog("创建的建筑的ID是:" .. msg.id)
        local buildData = RABuildManager.tempNewBuilding.buildData
        buildData.id = msg.id
        
        if msg:HasField("hp") then
            buildData.HP = msg.hp
            buildData.totalHP = msg.hp  --建造建筑 总血量不去读配置了 直接拿当前的就是最大值
        end
        
        -- local building = RABuildManager:createBuilding(buildData)
        RABuildManager:addBuildData(buildData)
        MessageManager.sendMessage(MessageDef_Building.MSG_CreateBuildingSuccess,{id = msg.id,buildType = buildData.confData.buildType})

        --新的队列，用于空闲的科技队列显示
        MessageManager.sendMessage(MessageDef_MainUI.MSG_UpdateMainUIQueueAddBuild, {buildType = buildData.confData.buildType})
    elseif pbCode == HP_pb.BUILDING_MOVE_PUSH then --移动建筑 --客户端预先处理了。。
        local msg = building_pb.BuildingPB()
        msg:ParseFromString(buffer)
        MessageManager.sendMessage(MessageDef_Building.MSG_MovingBuildingSuccess,{id = msg.id})
    -- elseif pbCode == HP_pb.BUILDING_UPDATE_PUSH then --立即建造处理 
    --     local msg = building_pb.BuildingUpdatePush()
    --     msg:ParseFromString(buffer)
    --     local buildData = RABuildManager:getBuildDataById(msg.building.id)
    --     buildData:initByCfgId(msg.building.buildCfgId)
    --     -- CCLuaLog(buildData.id)
    --     local isImmidiately = false
    --     if msg.operation == building_pb.BUILDING_UPDATE_IMMIDIATELY then 
    --         isImmidiately = true
    --     end 
    elseif pbCode == HP_pb.BUILDING_UPDATE_PUSH or pbCode == HP_pb.BUILDING_REBUILD_PUSH or pbCode == HP_pb.DEFENCE_BUILDING_REPAIR_PUSH then --立即建造处理  , 建筑改造 , 修理
        local msg = building_pb.BuildingUpdatePush()
        msg:ParseFromString(buffer)
        local buildData = RABuildManager:getBuildDataById(msg.building.id)

        --建筑改造成功后，删除之前在 buildingIndex 里面老的建筑数据
        if pbCode == HP_pb.BUILDING_REBUILD_PUSH then
            RABuildManager:deleteBuildingIndexData(buildData)
        end

        if pbCode == HP_pb.DEFENCE_BUILDING_REPAIR_PUSH or pbCode == HP_pb.BUILDING_UPDATE_PUSH
            or pbCode == HP_pb.BUILDING_REBUILD_PUSH then --修理成功，升级成功,  改造成功  --刷新当前血量
            if msg.building:HasField("hp") then
                buildData.HP = msg.building.hp
                buildData.normal = 1
            end
        end

        buildData:initByCfgId(msg.building.buildCfgId)
        -- CCLuaLog(buildData.id)
        local isImmidiately = false
        if msg.operation == building_pb.BUILDING_UPDATE_IMMIDIATELY then 
            isImmidiately = true
        end 
        
        local Const_pb = RARequire('Const_pb')
        if pbCode == HP_pb.BUILDING_UPDATE_PUSH then
            if buildData.confData.buildType == Const_pb.CONSTRUCTION_FACTORY then 
                -- CCLuaLog('主基地升级了:' .. buildData.confData.level)
                MessageManager.sendMessage(MessageDef_Building.MSG_MainFactory_Levelup,{level = buildData.confData.level}) 
            end 

            MessageManager.sendMessage(MessageDef_Building.MSG_UpgradeBuildingSuccess,{id = msg.building.id,isImmidiately = isImmidiately})
        elseif pbCode == HP_pb.BUILDING_REBUILD_PUSH then

            ----建筑改造成功后，更新当前建筑id的建筑数据
            RABuildManager:addBuildData(buildData)

            -- 其他建筑 改造成 矿石精鍊厂 需要 add 矿车
            if buildData.confData.buildType == Const_pb.ORE_REFINING_PLANT then
                local RACitySceneManager = RARequire("RACitySceneManager")
                RACitySceneManager:addOneMineCarByBuildData(buildData)
            end

            MessageManager.sendMessage(MessageDef_Building.MSG_ReBuildingSuccess,{id = msg.building.id,isImmidiately = isImmidiately})    
        elseif pbCode == HP_pb.DEFENCE_BUILDING_REPAIR_PUSH then
            MessageManager.sendMessage(MessageDef_Building.MSG_RepairBuildingSuccess,{id = msg.building.id,isImmidiately = isImmidiately})   
        end
    elseif pbCode == HP_pb.BUILDING_STATUS_CHANGE_PUSH then --建筑状态发生改变
        local msg = building_pb.PushBuildingStatus()
        msg:ParseFromString(buffer)
        CCLuaLog("MES.TYPE:" .. msg.type)
        local buildDatas = RABuildManager:getBuildDataByType(msg.type)
        if buildDatas == nil then 
            return 
        end 
        local _oldStatus = nil 
        local _newStatus = msg.status

        for k,v in pairs(buildDatas) do
            _oldStatus = v.status
            v.status = msg.status
        end

        MessageManager.sendMessage(MessageDef_Building.MSG_BuildingStatusChange,{buildType = msg.type,oldStatus = _oldStatus,newStatus=_newStatus})        
    elseif pbCode == HP_pb.QUEUE_ADD_PUSH then --队列添加
        local msg = Queue_pb.QueuePB()
        msg:ParseFromString(buffer)
        RAQueueManager:addQueueData(msg)
    elseif pbCode == HP_pb.QUEUE_UPDATE_PUSH then --队列更新
        local msg = Queue_pb.QueuePB()
         msg:ParseFromString(buffer)
        RAQueueManager:updateQueueData(msg)
    elseif pbCode == HP_pb.QUEUE_DELETE_PUSH then --队列删除
        local msg = Queue_pb.QueuePBSimple()
        msg:ParseFromString(buffer)
        RAQueueManager:deleteQueueData(msg)
    elseif pbCode == HP_pb.QUEUE_CANCEL_PUSH then --队列取消
        local msg = Queue_pb.QueuePBSimple()
        msg:ParseFromString(buffer)
        RAQueueManager:cancelQueueData(msg)
    elseif pbCode == HP_pb.PLAYER_QUEUE_SYNC_S then --队列同步
        local msg = Queue_pb.HPQueueInfoSync()
        msg:ParseFromString(buffer)
        local queues = msg.queues
        RAQueueManager:init()
        RAQueueManager:initAllQueues(queues)
    elseif pbCode == HP_pb.QUEUE_SPEED_UP_S then --队列同步
        local msg = Queue_pb.QueueSpeedUpResp()
        msg:ParseFromString(buffer)
        local result = msg.result
        --todo
        local RARootManager = RARequire("RARootManager")
        RARootManager.RemoveWaitingPage()
    end
end

return RAQueuePushHandler

--endregion
