--region *.lua
--Date
--此文件由[BabeLua]插件自动生成

local RADailyTaskActivityManager={}
RADailyTaskActivityManager.activityDatas={} 		--活动数据 
RADailyTaskActivityManager.stageDatas={}			--每个活动的阶段数据

--------------------------------activity data begin------------------------------------------------------
RADalilyTaskActivityData = {}

--构造函数
function RADalilyTaskActivityData:new(o)
    o = o or {}
    o.activityId    = nil
    o.stageId    = nil
    o.startTime  = nil
    o.endTime    = nil
    o.beginTime  = nil
    o.firstRound = nil
    o.roundRank  = nil
    o.playerRank = {}
    setmetatable(o,self)
    self.__index = self
    return o
end

function RADalilyTaskActivityData:initByPbData(activityData)

	self.activityId = activityData.activityId

	if activityData:HasField('stageId') then
    	self.stageId=activityData.stageId
    end

    if activityData:HasField('startTime') then
    	self.startTime = math.floor(activityData.startTime/1000)
    end

    if activityData:HasField('endTime') then
    	self.endTime = math.floor(activityData.endTime/1000)
    end 

    if activityData:HasField('beginTime') then
    	self.beginTime = math.floor(activityData.beginTime/1000)
    end

    self.firstRound = activityData.firstRound

    if activityData:HasField('roundRank') then
    	self.roundRank = activityData.roundRank
    end



    if activityData:HasField('playerRank') then
    	local playerRank = activityData.playerRank
    	local rankInfos = playerRank.rankInfo
		local count = #rankInfos
		for i=1,count do
			local rankData = rankInfos[i]
			local tb={}
			tb.rank = rankData.rank
			tb.playerIcon = rankData.playerIcon
			tb.playerName = rankData.playerName

			tb.score=0
			if rankData:HasField("score") then
				tb.score = rankData.score
			end 
			tb.guildTag = nil
			if rankData:HasField('guildTag') then
				tb.guildTag = rankData.guildTag
			end 
			table.insert(self.playerRank,tb)
		end

		--
		table.sort(self.playerRank,function (v1,v2)
			return v1.rank< v2.rank
		end)

    end 
    
end
--------------------------------activity data end------------------------------------------------------

--------------------------------stage data begin-------------------------------------------------------

RADalilyActivityStageData = {}

--构造函数
function RADalilyActivityStageData:new(o)
    o = o or {}
    o.stageId    = nil
    o.score    = nil
    o.selfRank  = nil
    o.playerRank = {}
    setmetatable(o,self)
    self.__index = self
    return o
end

function RADalilyActivityStageData:initByPbData(stageData)

	self.stageId = stageData.stageId
	self.score = stageData.score
	self.selfRank = stageData.selfRank

	if stageData:HasField('playerRank') then
		local playerRank = stageData.playerRank
		local ranks = playerRank.rankInfo
		local count = #ranks
		for i=1,count do
			local rankData = ranks[i]
			local tb={}
			tb.rank = rankData.rank
			tb.playerName = rankData.playerName
			tb.playerIcon = rankData.playerIcon
			tb.guildTag = nil
			if rankData:HasField('guildTag') then
				tb.guildTag = rankData.guildTag
			end 
			table.insert(self.playerRank,tb)
		end

		table.sort(self.playerRank,function (v1,v2)
			return v1.rank< v2.rank
		end)

	end
	

end
--------------------------------stage data end---------------------------------------------------------
--添加活动数据
function RADailyTaskActivityManager:addActivityDatas(activityId,data)
	if activityId then
		local activityData=RADalilyTaskActivityData:new()
    	activityData:initByPbData(data) 
		self.activityDatas[activityId]=activityData
	end
end

--更新活动数据
function RADailyTaskActivityManager:updateActivityDatas(activityId,data)
	if self.activityDatas[activityId] then
		local activityData=RADalilyTaskActivityData:new()
    	activityData:initByPbData(data) 
		self.activityDatas[activityId] = activityData 
	end 
end

--获取单个活动数据
function RADailyTaskActivityManager:getActivityDatasById(activityId)
	if self.activityDatas[activityId] then
		return self.activityDatas[activityId]
	end
end

--获取所有活动数据
function RADailyTaskActivityManager:getActivityDatas()
	return self.activityDatas
end


--活动阶段数据 (一个一个添加)
function RADailyTaskActivityManager:addActivityStageDatas(activityId,data)
	if activityId then
		if not self.stageDatas[activityId] then
			self.stageDatas[activityId]={}
		end
		local stageData=RADalilyActivityStageData:new()
    	stageData:initByPbData(data) 
		table.insert(self.stageDatas[activityId],stageData)
	end 
end

--获取活动阶段数据
function RADailyTaskActivityManager:getActivityStageDatas(activityId)
	if self.stageDatas[activityId] then
		return self.stageDatas[activityId]
	end 
end

--获取活动某个阶段数据
function RADailyTaskActivityManager:getActivityStageDatas(activityId,stageId)
	local data=nil
	if self.stageDatas[activityId] then
		for i,v in ipairs(self.stageDatas[activityId]) do
			local stageData = v
			if stageData.stageId==stageId then
				data = stageData
				break
			end 
		end
	end 
	return data
end

--清理单个活动阶段的数据
function RADailyTaskActivityManager:clearSingleaActivityStatus(activityId)
	local data=nil
	if self.stageDatas[activityId] then
		for i,v in ipairs(self.stageDatas[activityId]) do
			 v = nil
		end
	end

	self.stageDatas[activityId]=nil 
end

--清理活动数据
function RADailyTaskActivityManager:clearActivityDatas()
	for k,v in pairs(self.activityDatas) do
		v = nil
	end
	self.activityDatas={}
end

--清理阶段数据
function RADailyTaskActivityManager:clearStageDatas()
	for k,v in pairs(self.stageDatas) do
		for i,v1 in ipairs(v) do
			v1 = nil
		end
		v =nil
	end
end

function RADailyTaskActivityManager:reset()
	self:clearStageDatas()
	self:clearActivityDatas()
	self.currStageId = nil
end


function RADailyTaskActivityManager:setCurrStageId(stageId)
	self.currStageId = stageId
end

function RADailyTaskActivityManager:getCurrStageId()
	return self.currStageId
end
--------------------------------proto send begin------------------------------------------------------------

function RADailyTaskActivityManager:sendGetActivityStageReq()
	local HP_pb = RARequire("HP_pb")
	local RANetUtil=RARequire("RANetUtil")

	--在相应的界面监听HP_pb.ROUND_TASK_STAGE_RANK_S
	RANetUtil:sendPacket(HP_pb.ROUND_TASK_STAGE_RANK_C)
end

--------------------------------proto send end------------------------------------------------------------

return RADailyTaskActivityManager
--endregion
