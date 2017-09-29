
RARequire('RAQueueData')
RARequire("MessageDefine")
RARequire("MessageManager")
local RAPlayerInfoManager = RARequire('RAPlayerInfoManager')
local Utilitys = RARequire('Utilitys')
local Const_pb = RARequire('Const_pb')
local Queue_pb = RARequire('Queue_pb')
local RANetUtil = RARequire("RANetUtil")

local RAQueueManager = {}

RAQueueManager.queueDatas = {}   --现有的队列数据
RAQueueManager.queueCount =  {}	 --队列数目
RAQueueManager.messageTable = {} --增删改的消息

RAQueueManager.mQueueShowDataMap = nil
RAQueueManager.mQueueShowScene = -1


function RAQueueManager:reset()
	self.queueDatas = nil 
	self.queueCount = nil 
	-- self.messageTable = nil 
	self.mQueueShowDataMap = nil 
	self.mQueueShowScene = -1
end

function RAQueueManager:init()
	self.queueDatas = {}
	self.queueCount = {}

	self:initAllQueueType()

	for k,v in pairs(self.allQueueType) do
		self:initQueueType(v)
	end

	self:initMessage()
end

function RAQueueManager:initAllQueueType()
	-- body
	local allQueueType = {}
	allQueueType[#allQueueType+1] = Const_pb.BUILDING_QUEUE --城建队列
	allQueueType[#allQueueType+1] = Const_pb.BUILDING_DEFENER  --防御建筑
	allQueueType[#allQueueType+1] = Const_pb.SCIENCE_QUEUE --科技队列
	allQueueType[#allQueueType+1] = Const_pb.SOILDER_QUEUE --造兵队列 
	allQueueType[#allQueueType+1] = Const_pb.CURE_QUEUE --治疗伤兵
	allQueueType[#allQueueType+1] = Const_pb.EQUIP_QUEUE --装备队列
	allQueueType[#allQueueType+1] = Const_pb.MARCH_QUEUE --行军队列
	allQueueType[#allQueueType+1] = Const_pb.GUILD_SCIENCE_QUEUE --联盟雕像队列
	allQueueType[#allQueueType+1] = Const_pb.NUCLEAR_CREATE_QUEUE --生产超级武器
	self.allQueueType = allQueueType
end

function RAQueueManager:initMessage()
	self.messageTable = {}

	local queueMessageTable = {} --城建队列
	queueMessageTable.ADD = MessageDef_Queue.MSG_Building_ADD
	queueMessageTable.UPDATE = MessageDef_Queue.MSG_Building_UPDATE
	queueMessageTable.DELETE = MessageDef_Queue.MSG_Building_DELETE
	queueMessageTable.CANCEL = MessageDef_Queue.MSG_Building_CANCEL
	self.messageTable[Const_pb.BUILDING_QUEUE] = {}
	self.messageTable[Const_pb.BUILDING_QUEUE][Const_pb.QUEUE_STATUS_COMMON] = queueMessageTable

	local queueMessageTable = {} --城建队列
	queueMessageTable.ADD = MessageDef_Queue.MSG_Building_REBUILD_ADD
	queueMessageTable.UPDATE = MessageDef_Queue.MSG_Building_REBUILD_UPDATE
	queueMessageTable.DELETE = MessageDef_Queue.MSG_Building_REBUILD_DELETE
	queueMessageTable.CANCEL = MessageDef_Queue.MSG_Building_REBUILD_CANCEL
	self.messageTable[Const_pb.BUILDING_QUEUE][Const_pb.QUEUE_STATUS_REBUILD] = queueMessageTable

	--防御建筑比较特别 有升级，修理，改建
	queueMessageTable = {} --防御建筑
	queueMessageTable.ADD = MessageDef_Queue.MSG_Defener_ADD --升级
	queueMessageTable.UPDATE = MessageDef_Queue.MSG_Defener_UPDATE
	queueMessageTable.DELETE = MessageDef_Queue.MSG_Defener_DELETE
	queueMessageTable.CANCEL = MessageDef_Queue.MSG_Defener_CANCEL
	self.messageTable[Const_pb.BUILDING_DEFENER] = {}
	self.messageTable[Const_pb.BUILDING_DEFENER][Const_pb.QUEUE_STATUS_COMMON] = queueMessageTable

	queueMessageTable = {} --改建
	queueMessageTable.ADD = MessageDef_Queue.MSG_Defener_REBUILD_ADD 
	queueMessageTable.UPDATE = MessageDef_Queue.MSG_Defener_REBUILD_UPDATE
	queueMessageTable.DELETE = MessageDef_Queue.MSG_Defener_REBUILD_DELETE
	queueMessageTable.CANCEL = MessageDef_Queue.MSG_Defener_REBUILD_CANCEL
	self.messageTable[Const_pb.BUILDING_DEFENER][Const_pb.QUEUE_STATUS_REBUILD] = queueMessageTable

	queueMessageTable = {} --修理
	queueMessageTable.ADD = MessageDef_Queue.MSG_Defener_REPAIRE_ADD --升级
	queueMessageTable.UPDATE = MessageDef_Queue.MSG_Defener_REPAIRE_UPDATE
	queueMessageTable.DELETE = MessageDef_Queue.MSG_Defener_REPAIRE_DELETE
	queueMessageTable.CANCEL = MessageDef_Queue.MSG_Defener_REPAIRE_CANCEL
	self.messageTable[Const_pb.BUILDING_DEFENER][Const_pb.QUEUE_STATUS_REPAIR] = queueMessageTable



	 -- = queueMessageTable

	queueMessageTable = {} --科技队列
	queueMessageTable.ADD = MessageDef_Queue.MSG_Science_ADD
	queueMessageTable.UPDATE = MessageDef_Queue.MSG_Science_UPDATE
	queueMessageTable.DELETE = MessageDef_Queue.MSG_Science_DELETE
	queueMessageTable.CANCEL = MessageDef_Queue.MSG_Science_CANCEL
	self.messageTable[Const_pb.SCIENCE_QUEUE] = queueMessageTable

	queueMessageTable = {} --造兵队列 
	queueMessageTable.ADD = MessageDef_Queue.MSG_Soilder_ADD
	queueMessageTable.UPDATE = MessageDef_Queue.MSG_Soilder_UPDATE
	queueMessageTable.DELETE = MessageDef_Queue.MSG_Soilder_DELETE
	queueMessageTable.CANCEL = MessageDef_Queue.MSG_Soilder_CANCEL
	self.messageTable[Const_pb.SOILDER_QUEUE] = queueMessageTable

	queueMessageTable = {} --治疗伤兵
	queueMessageTable.ADD = MessageDef_Queue.MSG_hospital_ADD
	queueMessageTable.UPDATE = MessageDef_Queue.MSG_hospital_UPDATE
	queueMessageTable.DELETE = MessageDef_Queue.MSG_hospital_DELETE
	queueMessageTable.CANCEL = MessageDef_Queue.MSG_hospital_CANCEL
	self.messageTable[Const_pb.CURE_QUEUE] = queueMessageTable

	queueMessageTable = {} --装备队列
	self.messageTable[Const_pb.EQUIP_QUEUE] = queueMessageTable

	queueMessageTable = {} --行军队列
	self.messageTable[Const_pb.MARCH_QUEUE] = queueMessageTable

	queueMessageTable = {} --联盟雕像队列
	queueMessageTable.ADD = MessageDef_Alliance.MSG_Alliance_Statue_Queue_ADD
	queueMessageTable.UPDATE = MessageDef_Alliance.MSG_Alliance_Statue_Queue_UPDATE
	queueMessageTable.DELETE = MessageDef_Alliance.MSG_Alliance_Statue_Queue_DELETE
	self.messageTable[Const_pb.GUILD_SCIENCE_QUEUE] = queueMessageTable

	queueMessageTable = {} --联盟核弹制造
	queueMessageTable.ADD = MessageDef_Queue.MSG_SuperWeapon_ADD
	queueMessageTable.UPDATE = MessageDef_Queue.MSG_SuperWeapon_UPDATE
	queueMessageTable.DELETE = MessageDef_Queue.MSG_SuperWeapon_DELETE
	queueMessageTable.CANCEL = MessageDef_Queue.MSG_SuperWeapon_CANCEL
	self.messageTable[Const_pb.NUCLEAR_CREATE_QUEUE] = queueMessageTable
end 

function RAQueueManager:initQueueType(queueType)
	self.queueDatas[queueType] = {}
	self.queueCount[queueType] = 0
end

-- 获取当前某种类型队列的数目，为0表示没有
function RAQueueManager:getQueueCounts(queueType)
	local count = self.queueCount[queueType]
	if count == nil then 
		count = 0
	end 
	return count
end

function RAQueueManager:getQueueDatas(queueType)
	return self.queueDatas[queueType]
end 

function RAQueueManager:isCanApplyHelp(queueType, queueId)
	local RAAllianceManager = RARequire('RAAllianceManager') --没有联盟的判断
	if RAAllianceManager.selfAlliance == nil then 
		return false
	end 

	local RAQueueUtility = RARequire('RAQueueUtility')
	local isTypeCan = RAQueueUtility.isQueueTypeCanHelp(queueType)
	if isTypeCan then
		local data = self:getQueueData(queueType, queueId)
		if data ~=nil and data.helpTimes ~= nil and data.helpTimes == 0 then
			return true
		end 
	end
	return false
end

function RAQueueManager:getQueueData(queueType, queueId)
	local datas = self.queueDatas[queueType]
	if datas == nil then 
		CCLuaLog('not have this queueType:' .. queueType)
		return nil 
	end 
	return datas[queueId]
end 

function RAQueueManager:getQueueDataArr(queueType)
	local datas = self.queueDatas[queueType]
	local arr = {}
	for k,v in pairs(datas) do
		arr[#arr + 1] = v
	end
	return arr
end



function RAQueueManager:getSoilderQueue(buildType)
	for k,v in pairs(self.queueDatas[Const_pb.SOILDER_QUEUE]) do
		if tonumber(v.info) == buildType then 
			return v
		end  
	end

	return nil
end

--判断建筑是不是在升级中
function RAQueueManager:isBuildingUpgrade(buildId)
	local queueData = self:getBuildingQueue(buildId)
	if queueData~= nil then 
		return true
	end 

	queueData = self:getBuildingDefenerQueue(buildId)
	if queueData ~= nil then 
		return true
	end  

	return false
end

--建筑是否在免费升级时间
function RAQueueManager:isBuildingInFreeTime(buildType)
	local isUpgrade,buildData = self:isBuildingTypeUpgrade(buildType)
	if isUpgrade == false then 
		return false
	else 
		local queueData = self:getBuildingQueue(buildData.id)
		if queueData == nil then 
			queueData = self:getBuildingDefenerQueue(buildData.id)
		end 

		if queueData == nil then 
			return false
		end 

		return RAQueueManager:isBuildQueueInFreeTime(queueData)
	end 
end


function RAQueueManager:isBuildQueueInFreeTime( queueData )
	local freeTime = RAPlayerInfoManager.getQueueFreeTime(nil, queueData.queueType)
	local remainTime = Utilitys.getCurDiffTime(queueData.endTime)

	if remainTime< freeTime then 
		return true
	else
		return false
	end 
end

--desc:获得处于免费时间内的建筑数据：for 新手
function RAQueueManager:getFreeTimeBuildData(buildType)
    local isUpgrade,buildData = self:isBuildingTypeUpgrade(buildType)
    if isUpgrade then
		local queueData = self:getBuildingQueue(buildData.id)
        if queueData == nil then
            queueData = self:getBuildingDefenerQueue(buildData.id)
        end
        if queueData then
            local freeTime = RAPlayerInfoManager.getQueueFreeTime(nil, queueData.queueType)
		    local remainTime = Utilitys.getCurDiffTime(queueData.endTime)

            if remainTime < freeTime then
                return buildData
            end
        end
    end

    return nil
end

function RAQueueManager:isBuildingTypeUpgrade(buildType)
	local  isUpgrade = false
	local RABuildManager = RARequire('RABuildManager')
	local buildingDatas = RABuildManager:getBuildDataByType(buildType)
	for k,v in pairs(buildingDatas) do
		isUpgrade = self:isBuildingUpgrade(k)
		if isUpgrade then 
			return isUpgrade,v
		end 
	end

	return isUpgrade,nil
end

function RAQueueManager:getBuildingQueue(buildId)
	for k,v in pairs(self.queueDatas[Const_pb.BUILDING_QUEUE]) do
		if v.itemId == buildId then 
			return v
		end  
	end

	return nil
end

function RAQueueManager:getBuildingDefenerQueue(buildId)
	for k,v in pairs(self.queueDatas[Const_pb.BUILDING_DEFENER]) do
		if v.itemId == buildId then 
			return v
		end  
	end

	return nil
end

--是否目前队列正在进行的建筑
function RAQueueManager:isTrainingBuilding(buildType)
	for k,v in pairs(self.queueDatas[Const_pb.SOILDER_QUEUE]) do
		if tonumber(v.info) == buildType then 
			return true
		end  
	end

	return false
end

function RAQueueManager:initAllQueues(queues)
    for i=1,#queues do
        local queueData = RAQueueData:new()
        queueData:initByPb(queues[i])
        self.queueDatas[queues[i].queueType][queues[i].id] = queueData
        self.queueCount[queues[i].queueType] = self.queueCount[queues[i].queueType] + 1
        self:updateQueueLocalPush(queueData)
    end
end

function RAQueueManager:addQueueData(queuePb)
	CCLuaLog("RAQueueManager:addQueueData")
	local queueData = RAQueueData:new()
	queueData:initByPb(queuePb)
	self.queueDatas[queuePb.queueType][queuePb.id] = queueData
	self.queueCount[queuePb.queueType] = self.queueCount[queuePb.queueType] + 1

	local MESSAGE = nil 
	if queuePb.queueType == Const_pb.BUILDING_QUEUE or queuePb.queueType == Const_pb.BUILDING_DEFENER then 
		MESSAGE = self.messageTable[queuePb.queueType][queuePb.status].ADD
	else
		MESSAGE = self.messageTable[queuePb.queueType].ADD
	end

	if MESSAGE ~= nil then 
		MessageManager.sendMessage(MESSAGE,queueData)
		self:updateQueueLocalPush(queueData)
		if queuePb.queueType == Const_pb.BUILDING_QUEUE then 
			local RABuildManager = RARequire('RABuildManager')
			local buildData = RABuildManager.buildingDatas[queuePb.itemId]
            local RAGameConfig = RARequire("RAGameConfig")
            --主基地开始2级升级3级触发引导
			if RAGameConfig.SwitchGuide == 1  and buildData ~= nil and buildData.confData.buildType == Const_pb.CONSTRUCTION_FACTORY and buildData.confData.level == 2 then 
	            local RARootManager = RARequire("RARootManager")
                local RAGuideManager= RARequire("RAGuideManager")
	            RARootManager.AddCoverPage()
                RAGuideManager.gotoNextStep()			
			end 
		end 

	end 
	
	if queueData.queueType ~= Const_pb.BUILDING_QUEUE and queueData.queueType ~= Const_pb.BUILDING_DEFENER then  
		MessageManager.sendMessage(MessageDef_Queue.MSG_Common_ADD,{queueId = queueData.id, queueType = queueData.queueType})
	end
end

function RAQueueManager:updateQueueData(queuePb)
	CCLuaLog("RAQueueManager:updateQueueData")
	local queueData = self.queueDatas[queuePb.queueType][queuePb.id]

	if queueData == nil then 
		queueData = RAQueueData:new()
		self.queueDatas[queuePb.queueType][queuePb.id] = queueData
	end 

	queueData:initByPb(queuePb)


	local MESSAGE = nil 
	if queuePb.queueType == Const_pb.BUILDING_QUEUE or queuePb.queueType == Const_pb.BUILDING_DEFENER then 
		MESSAGE = self.messageTable[queuePb.queueType][queuePb.status].UPDATE
	else
		MESSAGE = self.messageTable[queuePb.queueType].UPDATE
	end

	if MESSAGE ~= nil then 
		MessageManager.sendMessage(MESSAGE,queueData)
		self:updateQueueLocalPush(queueData)
	end  

	MessageManager.sendMessage(MessageDef_Queue.MSG_Common_UPDATE,{queueId = queueData.id, queueType = queueData.queueType})
end

function RAQueueManager:updateQueueLocalPush(queueData)
	local RAQueueUtility = RARequire('RAQueueUtility')
	local isCanPush = RAQueueUtility.isQueueTypePush(queueData.queueType)

	if isCanPush then 
		-- body
		--local remainTime = Utilitys.getCurDiffTime(self.queueData.endTime)
		--local text = ''

		-- if queueData.queueType == Const_pb.BUILDING_QUEUE then --建筑升级完成
		-- 	text = push_conf[Const_pb.BUILDING_QUEUE_FINISHED].text 
		-- elseif queueData.queueType == Const_pb.BUILDING_DEFENER then --防御队列
		-- 	text = push_conf[Const_pb.DEFENCE_BUILDING_FINISHED].text 
		-- elseif queueData.queueType == Const_pb.SOILDER_QUEUE then --部队训练完成
		-- 	text = push_conf[Const_pb.SOILDER_QUEUE_FINISHED].text
		-- elseif queueData.queueType == Const_pb.CURE_QUEUE then --伤病治疗完成
		-- 	text = push_conf[Const_pb.CURE_QUEUE_FINISHED].text
		-- elseif queueData.queueType == Const_pb.SCIENCE_QUEUE then --科技研究完成
		-- 	text = push_conf[Const_pb.SCIENCE_QUEUE_FINISHED].text
		-- end 

		-- RANotificationManager.addCommonNotification(text, text, remainTime,self.queueData.id)

		local RABuildManager = RARequire("RABuildManager")
		local data = nil
		local exName = nil
		local key = 0
		local queueDefaultVlaue = 10000

		if queueData.queueType == Const_pb.BUILDING_QUEUE or queueData.queueType == Const_pb.BUILDING_DEFENER then --防御队列 --建造或者升级
			data = RABuildManager.buildingDatas[queueData.itemId]

			if not data then return end

			exName = data.confData.buildName
			key = queueDefaultVlaue + queueData.queueType 
		elseif queueData.queueType == Const_pb.SOILDER_QUEUE then --造兵
		 	-- local battleSoldierConf = RARequire("battle_soldier_conf") 
		 	-- local data = battleSoldierConf[tonumber(queueData.itemId)]

		 	-- if not data then return end

		 	exName = "@SoldierName"..queueData.itemId
		 	key = queueDefaultVlaue + queueData.itemId
		elseif queueData.queueType == Const_pb.CURE_QUEUE then
			 --治疗伤兵不需要 name	
			 key = queueDefaultVlaue + queueData.queueType 
		elseif queueData.queueType == Const_pb.SCIENCE_QUEUE then 	
			--科技研究
			local techConf = RARequire("tech_conf") 
			local data = techConf[tonumber(queueData.itemId)]

			if not data then return end

			exName = data.techName

			key = queueDefaultVlaue + queueData.itemId
		end
		
		if key ~= 0 then
			local RANotificationManager = RARequire('RANotificationManager')
			local pushId = RANotificationManager.getPushIdByQueue(queueData)
			if pushId == 0 then return end

			RANotificationManager.deleteCommonNotification(pushId)

			local delayTime = Utilitys.getCurDiffTime(queueData.endTime)
			RANotificationManager.addNotification(pushId, delayTime, pushId, exName)
		end
	end 
end

function RAQueueManager:deleteQueueLocalPush(queueData)
	local RAQueueUtility = RARequire('RAQueueUtility')
	local isCanPush = RAQueueUtility.isQueueTypePush(queueData.queueType)

	if isCanPush then 
		-- body
		local RANotificationManager = RARequire('RANotificationManager')
		local pushId = RANotificationManager.getPushIdByQueue(queueData)
		if pushId == 0 then return end
		
		local RANotificationManager = RARequire('RANotificationManager')
		RANotificationManager.deleteCommonNotification(pushId)
	end
end

function RAQueueManager:deleteQueueData(queuePBSimple)
	CCLuaLog("RAQueueManager:deleteQueueData")	
	local queueData = self.queueDatas[queuePBSimple.queueType][queuePBSimple.id]
	self:deleteQueueLocalPush(queueData)
	local queueId = nil
	local queueType = nil 
	if queueData ~= nil then
		queueId = queueData.id
		queueType = queueData.queueType	
	end
	
	if queueData == nil then return end

	self.queueDatas[queuePBSimple.queueType][queuePBSimple.id] = nil 
	self.queueCount[queuePBSimple.queueType] = self.queueCount[queuePBSimple.queueType] - 1

	local MESSAGE = nil 
	if queueData.queueType == Const_pb.BUILDING_QUEUE or queueData.queueType == Const_pb.BUILDING_DEFENER then 
		MESSAGE = self.messageTable[queueData.queueType][queueData.status].DELETE
	else
		MESSAGE = self.messageTable[queueData.queueType].DELETE
	end


	if MESSAGE ~= nil then 
		MessageManager.sendMessage(MESSAGE,queueData)
		if queueData.queueType == Const_pb.BUILDING_QUEUE then 
			local RABuildManager = RARequire('RABuildManager')
			local buildData = RABuildManager.buildingDatas[queueData.itemId]

			--主基地，兵营,雷达,电厂升级完成
			local Utilitys=RARequire("Utilitys")
			local RAGuideConfig=RARequire("RAGuideConfig")
			if buildData ~= nil and  Utilitys.tableFind(RAGuideConfig.UpgradeBuildFree,buildData.confData.buildType) then 
	            local RARootManager = RARequire("RARootManager")
                if RARootManager.mTopNode ~= nil then--如果是刚进入游戏就走到这里，那么不走这里逻辑，由新手起点处统一处理
                    local RAGuideManager = RARequire('RAGuideManager')
			        RAGuideManager.gotoNextStep()
                end
			end 
		end 
	end  

	MessageManager.sendMessage(MessageDef_Queue.MSG_Common_DELETE,{queueId = queueId, queueType = queueType})   
end

function RAQueueManager:cancelQueueData(queuePBSimple)	
	CCLuaLog("RAQueueManager:cancelQueueData")
	local queueData = self.queueDatas[queuePBSimple.queueType][queuePBSimple.id]
	self:deleteQueueLocalPush(queueData)
	self.queueDatas[queuePBSimple.queueType][queuePBSimple.id] = nil 
	self.queueCount[queuePBSimple.queueType] = self.queueCount[queuePBSimple.queueType] - 1

	local MESSAGE = nil 
	if queueData.queueType == Const_pb.BUILDING_QUEUE or queueData.queueType == Const_pb.BUILDING_DEFENER then 
		MESSAGE = self.messageTable[queueData.queueType][queueData.status].CANCEL
	else
		MESSAGE = self.messageTable[queueData.queueType].CANCEL
	end

	if MESSAGE ~= nil then 
		MessageManager.sendMessage(MESSAGE,queueData)
	end

	MessageManager.sendMessage(MessageDef_Queue.MSG_Common_CANCEL,{queueId = queueData.id, queueType = queueData.queueType})   
end


-- 发送队列加速协议 消耗钻石
-- id 为正在研究的队列id
function RAQueueManager:sendQueueSpeedUpByGold(id)
    local RARootManager = RARequire('RARootManager')
    RARootManager.ShowWaitingPage(true)
    -- body
    local cmd = Queue_pb.QueueSpeedUpReq()
    cmd.id = id
    cmd.isGold = true
    RANetUtil:sendPacket(HP_pb.QUEUE_SPEED_UP_C,cmd,{retOpcode=-1})
end

--发送队列加速协议 消耗道具
--联盟队列加速
function RAQueueManager:sendAllianceQueueSpeedUpByItems(id,itemUUid,count)
    local cmd = Queue_pb.QueueSpeedUpReq()
    cmd.id = id
    cmd.isGold = false
    cmd.itemUUid = itemUUid
    cmd.count = count
    RANetUtil:sendPacket(HP_pb.GUILD_QUEUE_SPEED_UP_C,cmd,{retOpcode=-1})
end

--发送队列加速协议 消耗道具
-- id  			正在研究的队列id 
-- itemUUid 	道具的uuid 
-- count 		使用的道具数量
function RAQueueManager:sendQueueSpeedUpByItems(id,itemUUid,count)
    local cmd = Queue_pb.QueueSpeedUpReq()
    cmd.id = id
    cmd.isGold = false
    cmd.itemUUid=itemUUid
    cmd.count = count
    RANetUtil:sendPacket(HP_pb.QUEUE_SPEED_UP_C, cmd,{retOpcode=-1})
end


--发送取消队列
-- id 为正在研究的队列id
function RAQueueManager:sendQueueCancel(id)
    local cmd = Queue_pb.QueueCancelReq()
    cmd.id = id
    RANetUtil:sendPacket(HP_pb.QUEUE_CANCEL_C, cmd,{retOpcode=-1})
end

function RAQueueManager:sendQueueFreeFinish(id)
	local cmd = Queue_pb.QueueFinishFreeReq()
    cmd.id = id
    RANetUtil:sendPacket(HP_pb.QUEUE_FININSH_FREE_C, cmd,{retOpcode=-1})
end


-- 获取某种类型队列当前的上限数目
function RAQueueManager:getQueueMaxCounts(queueType)
	local ret = 0
	if queueType == Const_pb.BUILDING_QUEUE then
		--可能需要建造那边给接口
		ret = 1
	elseif queueType == Const_pb.BUILDING_DEFENER then
		--可能需要建造那边给接口
		ret = 1
	elseif queueType == Const_pb.SCIENCE_QUEUE then		
		-- 科技队列是固定的一个
		ret = 1
	elseif queueType == Const_pb.SOILDER_QUEUE then
		-- 训练队列上限根据兵营类建筑个数决定
		local RABuildManager = RARequire('RABuildManager')
		ret = RABuildManager:getSoilderBuildCounts()
	elseif queueType == Const_pb.CURE_QUEUE then	
		-- 治疗队列是固定的一个
		ret = 1
	elseif queueType == Const_pb.EQUIP_QUEUE then
		-- 装备未实现
		ret = 0
	elseif queueType == Const_pb.MARCH_QUEUE then	
		local RAPlayerEffect = RARequire('RAPlayerEffect')
		ret = RAPlayerEffect:getEffectResult(Const_pb.MARCH_TROOP_NUM) + 1
	elseif queueType == Const_pb.GUILD_SCIENCE_QUEUE then
		--联盟雕像队列是固定的一个
		ret = 1		
	end
	return ret
end


function RAQueueManager:getQueueShowStatus(queueType)
	local RABuildManager = RARequire('RABuildManager')
	local RACoreDataManager = RARequire('RACoreDataManager')
	local RAGameConfig = RARequire('RAGameConfig')
	local Utilitys = RARequire('Utilitys')

    local isShow = false
    local cellQueueCount = 0
    local cellQueueMap = {}
    local queueDatas = self:getQueueDatas(queueType)
    local realCount = Utilitys.table_count(queueDatas)
    if queueDatas ~= nil then
    	local cellIndex = 1
    	-- 训练士兵的自己加
    	if queueType ~= Const_pb.SOILDER_QUEUE then
	    	for k,v in pairs(queueDatas) do    		
	    		local cellData = {id = v.id} 
	    		cellQueueMap[cellIndex] = cellData
	    		cellIndex = cellIndex + 1
	    	end
	    end
	end
	
    if queueType == Const_pb.BUILDING_QUEUE then
    	isShow = true
    	-- 建筑队列暂时只有一个，后续功能增加后再添加
    	cellQueueCount = realCount

    	-- 没有建筑队列的时候，添加个默认空闲队列
    	if realCount == 0 then
    		local defautBuildQueue = {id = 0}
    		defautBuildQueue.isDefault = true
    		cellQueueMap[1] = defautBuildQueue
    	end

	elseif queueType == Const_pb.BUILDING_DEFENER then		
    	-- 正在建造或者修理防御建筑的时候显示；有受损防御建筑时显示
		cellQueueCount = 1
		isShow = realCount > 0 or RABuildManager:getDefenceBuildIsHurt()

	elseif queueType == Const_pb.SOILDER_QUEUE then
		-- 士兵队列，需要建造了训练兵种类建筑才会显示
		cellQueueCount,  typeList = RABuildManager:getSoilderBuildCounts()
		isShow = cellQueueCount > 0
		for cellIndex, buildType in ipairs(typeList) do
			local cellData = {buildType = buildType, id = 0}
			if queueDatas ~= nil then
				for k,v in pairs(queueDatas) do
					if v.info == tostring(buildType) then
						cellData.id = v.id
						break
					end
		    	end	
			end
			cellQueueMap[cellIndex] = cellData
    		cellIndex = cellIndex + 1
		end
		cellQueueCount = realCount
	elseif queueType == Const_pb.SCIENCE_QUEUE then
		local scienceBuildCount = RABuildManager:getBuildDataCountByType(Const_pb.FIGHTING_LABORATORY)
		cellQueueCount = 1
		isShow = scienceBuildCount > 0
		-- 没有科技队列的时候，添加个默认空闲队列
    	if isShow and realCount == 0 then
    		local defautQueue = {id = 0}
    		defautQueue.isDefault = true
    		cellQueueMap[1] = defautQueue
    	end

	elseif queueType == Const_pb.CURE_QUEUE then
		-- 治疗队列，当玩家有伤兵，且有修理厂的时候
	    local hospitalBuildCount = RABuildManager:getCureBuildCounts()
	    local isHasHurtSoilder = RACoreDataManager:hasWoundedArmy() or false
		cellQueueCount = 1		
		isShow = isHasHurtSoilder and hospitalBuildCount > 0
		if isShow and realCount == 0 then
    		local defautQueue = {id = 0}
    		defautQueue.isDefault = true
    		cellQueueMap[1] = defautQueue
    	end
    	if realCount > 0 then
    		isShow = true
    	end

    -- 行军的数据，从行军那边取，不在队列里了
	elseif queueType == Const_pb.MARCH_QUEUE then
		local RAMarchDataManager = RARequire('RAMarchDataManager')
		cellQueueCount = RAMarchDataManager:GetSelfMarchCount()
		isShow = cellQueueCount > 0
		cellQueueMap = {}
		local selfMarchMap = RAMarchDataManager:GetSelfMarchDataMap()
		-- 这块可能需要做行军数据的排序
		local index = 1
		for marchId, marchData in pairs(selfMarchMap) do
			if marchData ~= nil then
				cellQueueMap[index] = { id = marchId}
				index = index + 1
			end
		end
	end
	return isShow, cellQueueCount, cellQueueMap
end

-- 获取一个用于队列显示页面的data
function RAQueueManager:getQueueShowData(index, queueType)    
    local queueType = queueType or -1
    local queue = {
    	isShow = false,        
        queueType = queueType, --value should be type in const_pb
        index = index
    }
    if queueType ~= -1 then
    	local isQueueShow, cellQueueCount, cellQueueMap = self:getQueueShowStatus(queueType)
    	queue.isShow = isQueueShow
    	queue.cellCount = cellQueueCount
    	queue.cellMap = cellQueueMap
    end
    return queue
end

-- 构建或队列数据
function RAQueueManager:getQueueShowDataMap(isRefresh)
	local RARootManager = RARequire('RARootManager')
	local isRebuild = false
	if self.mQueueShowDataMap == nil or self.mQueueShowScene ~= RARootManager.GetCurrScene() then
		isRebuild = true
	end

	-- 重新构建数据
	if isRebuild then
		self.mQueueShowScene = RARootManager.GetCurrScene()
		self.mQueueShowDataMap = {}

	 	local index = 1
	    -- 先增加世界的判断，如果在世界需要先显示行军队列
	    -- 需要增加是否有行军队列的判定
	    if RARootManager.GetIsInWorld() then
	        self.mQueueShowDataMap[index] = self:getQueueShowData(index, Const_pb.MARCH_QUEUE)            
            index = index + 1
	    end

	    -- 建造队列，常驻显示
	    self.mQueueShowDataMap[index] = self:getQueueShowData(index, Const_pb.BUILDING_QUEUE)
	    index = index + 1

	    -- 士兵队列，需要建造了训练兵种类建筑才会显示
	    self.mQueueShowDataMap[index] = self:getQueueShowData(index, Const_pb.SOILDER_QUEUE)  
        index = index + 1

	    -- 防御建筑队列，暂时未实现，先不显示
	    -- 正在建造或者修理防御建筑的时候显示；有受损防御建筑时显示
	    self.mQueueShowDataMap[index] = self:getQueueShowData(index, Const_pb.BUILDING_DEFENER)  
	    index = index + 1

	    -- 科技队列，当玩家有作战实验室的时候就显示
	    self.mQueueShowDataMap[index] = self:getQueueShowData(index, Const_pb.SCIENCE_QUEUE)  
        index = index + 1

	    -- 治疗队列，当玩家有伤兵，且有修理厂的时候
	    self.mQueueShowDataMap[index] = self:getQueueShowData(index, Const_pb.CURE_QUEUE)  
        index = index + 1 

	    -- 如果在城内，最后要显示行军队列
	    if RARootManager.GetIsInCity() then
	        self.mQueueShowDataMap[index] = self:getQueueShowData(index, Const_pb.MARCH_QUEUE)  
            index = index + 1
	    end
	end
	if not isRebuild and isRefresh then
		self:refreshQueueShowDataMap(Const_pb.BUILDING_QUEUE)
		self:refreshQueueShowDataMap(Const_pb.SOILDER_QUEUE)
		self:refreshQueueShowDataMap(Const_pb.BUILDING_DEFENER)
		self:refreshQueueShowDataMap(Const_pb.SCIENCE_QUEUE)
		self:refreshQueueShowDataMap(Const_pb.CURE_QUEUE)
		self:refreshQueueShowDataMap(Const_pb.MARCH_QUEUE)
	end
    return self.mQueueShowDataMap
end

function RAQueueManager:refreshQueueShowDataMap(queueType)
	-- 需要的话先build
	self:getQueueShowDataMap()
	for index, showData in pairs(self.mQueueShowDataMap) do
		if showData.queueType == queueType then
			local isQueueShow, cellQueueCount, cellQueueMap = self:getQueueShowStatus(queueType)

			-- 这边可能 isQueueShow 会跟原有的不同，此时，需要主页面播放队列插入和删除动画
			-- todo 
			if showData.isShow ~= isQueueShow then
				print('queue is show status change, type = '..queueType..' last status='..tostring(showData.isShow))
			end

			showData.isShow = isQueueShow
			showData.cellCount = cellQueueCount
			showData.cellMap = cellQueueMap
		end
	end
end

function RAQueueManager:getEffectQueueTypeByBuildType(buildType)
	local RABuildManager = RARequire('RABuildManager')

	-- 作战实验室，科技队列
	if buildType == Const_pb.FIGHTING_LABORATORY then
		return Const_pb.SCIENCE_QUEUE
	end
	-- 士兵队列
	local soilderTypeList = RABuildManager:getSoilderBuildTyps()
	for k,v in pairs(soilderTypeList) do
		if buildType == v then
			return Const_pb.SOILDER_QUEUE
		end
	end

	-- 治疗队列
	local cureTypeList = RABuildManager:getCureBuildTyps()
	for k,v in pairs(cureTypeList) do
		if buildType == v then
			return Const_pb.CURE_QUEUE
		end
	end

	-- 防御建筑队列（不会受影响，升级和受损会受）


	-- 出兵队里，不会在这里处理


	return -1
end

function RAQueueManager:getArsenaQueue()
    return self:getQueueDatas(Const_pb.SOILDER_QUEUE)
end

--获取联盟雕像数据
function RAQueueManager:getStatueQueue()
	-- body
	return self:getQueueDatas(Const_pb.GUILD_SCIENCE_QUEUE)
end

RAQueueManager:init()
return RAQueueManager
