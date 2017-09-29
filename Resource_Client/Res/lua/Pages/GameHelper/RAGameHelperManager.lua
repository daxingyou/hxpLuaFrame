
RARequire('RAQueueData')
RARequire("MessageDefine")
RARequire("MessageManager")
local RAPlayerInfoManager = RARequire('RAPlayerInfoManager')
local Utilitys = RARequire('Utilitys')
local RANotificationManager = RARequire('RANotificationManager')

local Const_pb = RARequire('Const_pb')
local Queue_pb = RARequire('Queue_pb')
local RANetUtil = RARequire("RANetUtil")
local push_conf = RARequire('push_conf')
local RAQueueManager = RARequire('RAQueueManager')
local RABuildManager = RARequire('RABuildManager')
local RARootManager = RARequire('RARootManager')
local RAGuideManager = RARequire('RAGuideManager')
local RACoreDataManager = RARequire('RACoreDataManager')
local RAGameHelperManager = {}

RAGameHelperManager.buildDatas = {}   --建造，研究，防御，治疗队列
RAGameHelperManager.armyDatas =  {}	  --部队队列
RAGameHelperManager.marchDatas = {}   --行军队列



function RAGameHelperManager:reset()
	self.buildDatas = nil 
	self.armyDatas = nil 
	-- self.messageTable = nil 
	self.marchDatas = nil 
end

--[[
	1、打开建造功能界面建筑页签
	2、打开建筑工厂界面
	3、免费（点击免费按钮）
	4、打开正在升级建筑的hud，引导点击加速按钮
	5、打开建筑列表界面，指引建造作战实验室，未解锁出提示
	6、打开作战实验室研究界面
	7、打开作战实验室指引道具加速
	8、无防御建筑空地，无可升级建筑 隐藏
	9、打开防御建筑界面
   10、免费
   11、打开等级最低的防御建筑hud，指引升级按钮
   12、打开建筑功能页签，指引医护维修站，未解锁谈tip
   13、无伤兵，不显示条目
   14、打开等级最高的医护维护战界面，指引治疗按钮
   15、打开医疗维修站，指引道具加速按钮
   16、点击任意兵种，未建造工厂就指引打开建筑列表，指引兵厂建造
   17、打开相应训练建筑
   18、队列中有空闲时，点击训练，顺序打开最高等级空闲建筑
   19、打开相应训练建筑，指引加速
   20、如果出征队列数量为不满（3/4这种）跳转世界，弹窗，
   21、发展提示有个列表，点击出现下一个
   22、未打开界面，发展提示以聊天泡泡形式出现，
   23、未打开界面，电力不足时，常驻提示电力不足，用爱发电

   归纳：
   打开建造功能界面制定页签--指引建造指定建筑--弹出tip
   引导打开指定建筑hud，引导升级按钮
   打开指定建筑界面
   打开指定建筑界面--指引道具加速按钮
   打开指定建筑界面--指引治疗钮

]]


function RAGameHelperManager:getQueueData()
	RAGameHelperManager.buildDatas = {
										{type = Const_pb.BUILDING_QUEUE},
										{type = Const_pb.SCIENCE_QUEUE},
										{type = Const_pb.BUILDING_DEFENER},
										{type = Const_pb.CURE_QUEUE}
									 }
	RAGameHelperManager.buildDatas[1].queueDatas = RAQueueManager:getQueueDataArr(Const_pb.BUILDING_QUEUE)   --城建
	RAGameHelperManager.buildDatas[2].queueDatas = RAQueueManager:getQueueDataArr(Const_pb.SCIENCE_QUEUE)	--科技
	RAGameHelperManager.buildDatas[3].queueDatas = RAQueueManager:getQueueDataArr(Const_pb.BUILDING_DEFENER)	--防御建筑
	RAGameHelperManager.buildDatas[4].queueDatas = RAQueueManager:getQueueDataArr(Const_pb.CURE_QUEUE)		--治疗

	RAGameHelperManager.armyDatas = {
										{type = Const_pb.BARRACKS, btnType = BUILDING_BTN_TYPE.TRAIN_BARRACKS},
										{type = Const_pb.WAR_FACTORY, btnType = BUILDING_BTN_TYPE.TRAIN_WAR_FACTORY},
										{type = Const_pb.AIR_FORCE_COMMAND, btnType = BUILDING_BTN_TYPE.TRAIN_RAIR_FORCE_COMMAND},
										{type = Const_pb.REMOTE_FIRE_FACTORY, btnType = BUILDING_BTN_TYPE.TRAIN_REMOTE_FIRE_FACTORY}
									}
	local soilderQueueArr = RAQueueManager:getQueueDataArr(Const_pb.SOILDER_QUEUE)		--造兵
	for j,armyData in ipairs(RAGameHelperManager.armyDatas) do
		for i,queue in ipairs(soilderQueueArr) do
			if tonumber(queue.info) == tonumber(armyData.type) then
				armyData.queueData = queue
				-- dump(armyData)
				break
			end
		end
		armyData.building = RABuildManager:getBuildDataArray(armyData.type)
	end

	RAGameHelperManager.marchDatas = RAQueueManager:getQueueDataArr(Const_pb.MARCH_QUEUE)		    --行军
	
end 


function RAGameHelperManager:deleteQueue(queueType, queueId)
	for i,v in ipairs(RAGameHelperManager.buildDatas) do
		if v.type == queueType then
			v.queueDatas = RAQueueManager:getQueueDataArr(v.type)
		end
	end
	if queueType == Const_pb.SOILDER_QUEUE then
		for i,v in ipairs(RAGameHelperManager.armyDatas) do
			if v.queueData and v.queueData.id == queueId then
				v.queueData = nil
			end
		end	
	end
end

-- isBuildType = true, building 为buildType, 指引一类建筑中等级最高的， 默认为false，表示指引指定id 的建筑
function RAGameHelperManager:gotoHud( building, btnType, isBuildType )
    if not RARootManager.GetIsInCity() then
        RARootManager.ChangeScene(SceneTypeList.CityScene)
        return
    end
    --RARootManager.AddGuidPage({["guideId"] = RAGameConfig.AvoidTouchGuideId, ["update"] = true})
    RARootManager.AddCoverPage({["update"] = true})

    RAGuideManager.guideTaskGuideId = 10000
    local result
    if isBuildType then
    	result = RABuildManager:showBuildingByBuildType(building, btnType) --是指定某个建筑还是一类建筑中查找等级最高的
    else
		result = RABuildManager:showBuildingById(building, btnType)    	
	end
    
    --Èç¹û·µ»Ønil£¬ËµÃ÷ÓÐÌØÊâÇé¿öÎÞ·¨Òýµ¼
    if not result then
        RARootManager.RemoveGuidePage()
        RARootManager.RemoveCoverPage()
    end

end

function RAGameHelperManager:openChooseBuilding( buildType, isDefense )
    if RARootManager.GetIsInWorld() then
        RARootManager.ChangeScene(SceneTypeList.CityScene)
    end
    local tmpConstGuideInfo = {isDefense = isDefense}
    if buildType then
	    RARootManager.AddCoverPage({["update"] = true})
	    RAGuideManager.guideTaskGuideId = 10000
	    tmpConstGuideInfo.GuideData = {}
	    tmpConstGuideInfo.GuideData.buildType = buildType
	    tmpConstGuideInfo.GuideData.guideId = 10000
	end

    RARootManager.OpenPage("RAChooseBuildPage", tmpConstGuideInfo)
    MessageManager.sendMessage(MessageDef_MainUI.MSG_HandleChooseBuildPage, {isShow = false})
end



function RAGameHelperManager:buildGuide( data )

	if #data.queueDatas > 0 then
		local building, isBuildType
		local btnType = BUILDING_BTN_TYPE.SPEEDUP
		if data.type == Const_pb.BUILDING_QUEUE or data.type == Const_pb.BUILDING_DEFENER  then
			local isFree = RAQueueManager:isBuildQueueInFreeTime( data.queueDatas[1] )
			if isFree then
				RAQueueManager:sendQueueFreeFinish(data.queueDatas[1].id)
				return
			end
			building = data.queueDatas[1].itemId
		elseif data.type == Const_pb.SCIENCE_QUEUE then
			building = Const_pb.FIGHTING_LABORATORY
			isBuildType = true
		elseif data.type == Const_pb.CURE_QUEUE then
			building = Const_pb.HOSPITAL_STATION
			isBuildType = true			
		end		 	
		RAGameHelperManager:gotoHud(building, btnType, isBuildType )
	else
		if data.type == Const_pb.BUILDING_QUEUE then
			local mainCityData = RABuildManager:getBuildDataArray(Const_pb.CONSTRUCTION_FACTORY)
			-- dump(mainCityData)
			local nextBuildId, needBuildId = RABuildManager:getLastCanUpgradBuildByType(mainCityData[1].confData.id)
			if nextBuildId ~= false then
				local buildData = RABuildManager:getBuildingDataByConfId(nextBuildId)
				RAGameHelperManager:gotoHud(buildData.id, BUILDING_BTN_TYPE.UPGRADE)
				return		
			elseif needBuildId ~= nil then
				RAGameHelperManager:openChooseBuilding(needBuildId)
			end
		elseif data.type == Const_pb.SCIENCE_QUEUE then
			local scienceData = RABuildManager:getBuildDataArray(Const_pb.FIGHTING_LABORATORY)
			if #scienceData > 0 then
				RAGameHelperManager:gotoHud(scienceData[1].id, BUILDING_BTN_TYPE.RESEARCH)
			else
				RAGameHelperManager:openChooseBuilding(Const_pb.FIGHTING_LABORATORY)
			end
		elseif data.type == Const_pb.BUILDING_DEFENER then
			local count = RABuildManager:getDefenceBuildCounts()
			local totalCount = RABuildManager:getBuildLimitNumByBuildType(Const_pb.PRISM_TOWER)
			if 	count < totalCount then
				RAGameHelperManager:openChooseBuilding(nil, true)
			else
				local upgradeBuildData = RABuildManager:getDefenceBuildLevelUp( )
				if upgradeBuildData then
					RAGameHelperManager:gotoHud(upgradeBuildData.id, BUILDING_BTN_TYPE.UPGRADE)
				else
					RARootManager.ShowMsgBox(_RALang("@HasNoSite"))
				end
			end
		elseif data.type == Const_pb.CURE_QUEUE then
			local cureBuilds = RABuildManager:getBuildDataArray(Const_pb.HOSPITAL_STATION)
			if #cureBuilds > 0 then
				if RACoreDataManager:getArmyWoundedSumCount() > 0 then
					RAGameHelperManager:gotoHud(Const_pb.HOSPITAL_STATION, BUILDING_BTN_TYPE.TREAT, true)
				end
			else
				RAGameHelperManager:openChooseBuilding(Const_pb.HOSPITAL_STATION)
			end
		end
	end

end


function RAGameHelperManager:onSoilderClick( data )
	-- dump(data)
	if data.queueDatas then
		RAGameHelperManager:gotoHud(data.type, BUILDING_BTN_TYPE.SPEEDUP, true)
	elseif #data.building > 0 then
		RAGameHelperManager:gotoHud(data.type, data.btnType, true)
	else
		RAGameHelperManager:openChooseBuilding(data.type)
	end
end

function RAGameHelperManager:onClick(  )
	for i,data in ipairs(RAGameHelperManager.armyDatas) do
		if #data.building > 0 and data.queueData == nil then
			RAGameHelperManager:gotoHud(data.type, data.btnType, true)
			return
		end
	end
	for i,data in ipairs(RAGameHelperManager.armyDatas) do
		if data.queueData then
			RAGameHelperManager:gotoHud(data.type, BUILDING_BTN_TYPE.SPEEDUP, true)
			return
		end
	end	
end

return RAGameHelperManager
