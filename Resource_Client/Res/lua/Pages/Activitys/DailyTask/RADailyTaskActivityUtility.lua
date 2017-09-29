--region *.lua
--Date
--此文件由[BabeLua]插件自动生成


local  event_conf = RARequire("event_conf")
local item_conf = RARequire("item_conf")
local event_content_conf =RARequire("event_content_conf")
local RAStringUtil = RARequire("RAStringUtil")
local RAResManager = RARequire("RAResManager")
local RADailyTaskActivityUtility = {}

RADailyTaskActivityUtility.STAGESTATU={
	NOSTART=1, 
	START=2, 
	OVER=3, 
}

--获取活动配置信息
function RADailyTaskActivityUtility:getActivityConfigData(activityId)
	local data = event_conf[activityId]
	if data then
		return data
	end
	return nil 
end

--获取非首次活动中阶段Id
function RADailyTaskActivityUtility:getStageIdsInActivity(activityId)
	local activityData = self:getActivityConfigData(activityId)
	local groups = RAStringUtil:split(activityData.group,"_")
	local tb={}
	for i,v in ipairs(groups) do
		local groupId = tonumber(v)
		table.insert(tb,groupId)
	end

	-- table.sort(tb)
	return tb
end

--获取首次活动中阶段Id
function RADailyTaskActivityUtility:getFirstStageIdsInActivity(activityId)
	local activityData = self:getActivityConfigData(activityId)
	local groups = RAStringUtil:split(activityData.group,"_")
	local tb={}
	local count = #groups
	for i=1,count do
		if i~=count then
			local groupId = tonumber(groups[i])
			table.insert(tb,groupId)
		end 
	end
	-- table.sort(tb)
	return tb
end

--获取阶段的基本信息
function RADailyTaskActivityUtility:getStageDataById(stageId)
	local stageData = event_conf[stageId]
	if stageData then
		return stageData
	end 
	return nil	
end


--获取活动总排名奖励排行信息
function RADailyTaskActivityUtility:getRankRewardDataByActivityId(activityId)
	local activityData = self:getActivityConfigData(activityId)

	local rankStage = RAStringUtil:split(activityData.rankRound,"_")
	local rankRewardStage = RAStringUtil:split(activityData.rankRewardRound,",")

	local tb={}
	local count = #rankStage
	for i=1,count do
		local rank = tonumber(rankStage[i])
		local rewardStage = rankRewardStage[i]

		local reward = RAStringUtil:split(rewardStage,"_")
		local mainType=tonumber(reward[1])
		local rewardId=tonumber(reward[2])
		local num=tonumber(reward[3])
		local icon,name=RAResManager:getIconByTypeAndId(mainType, rewardId)
		local rewardData={}
		rewardData.item_name=name
		rewardData.item_icon=icon
		rewardData.num=num

		-- local rewardData = item_conf[rewardId]
		local t={}
		t.rank =rank
		t.reward = rewardData
		table.insert(tb,t)
	end
	return tb
end

--获取活动阶段奖励排行信息
function RADailyTaskActivityUtility:getRankRewardDataByStageId(stageId)
	local stageData = self:getStageDataById(stageId)

	local rankStage = RAStringUtil:split(stageData.rankStage,"_")
	local rankRewardStage = RAStringUtil:split(stageData.rankRewardStage,",")

	local tb={}
	local count = #rankStage
	for i=1,count do

		local rank = tonumber(rankStage[i])
		local rewardStage = rankRewardStage[i]

		local reward = RAStringUtil:split(rewardStage,"_")
		local mainType=tonumber(reward[1])
		local rewardId=tonumber(reward[2])
		local num=tonumber(reward[3])
		local icon,name=RAResManager:getIconByTypeAndId(mainType, rewardId)
		local rewardData={}
		rewardData.item_name=name
		rewardData.item_icon=icon
		rewardData.num=num


		-- local rewardData = item_conf[rewardId]
		local t={}
		t.rank =rank
		t.reward = rewardData
		table.insert(tb,t)
	end
	return tb
end

--获取阶段描述内容数据
function RADailyTaskActivityUtility:getStageContentDatas(stageId)
	local data={}
	local stageData = self:getStageDataById(stageId)
	local contentIds = RAStringUtil:split(stageData.contentId,"_")
	for i,v in ipairs(contentIds) do
		local contentId = tonumber(v)
		local contentData = self:getContentDataById(contentId)
		for i,v in ipairs(contentData) do
			table.insert(data,v)
		end
		
	end

	table.sort(data,function (v1,v2)
		return v1.contentOrder<=v2.contentOrder
	end)
	return data
end



function RADailyTaskActivityUtility:getConfigScoreRankDatas(stageId)
	local tb={}
	tb.score=0
	tb.stageId=stageId
	tb.selfRank=0
	tb.playerRank={}
	return tb
end

function RADailyTaskActivityUtility:getContentDataById(contentId)

	local cont= math.floor(contentId/100)

	local tb={}
	for k,v in pairs(event_content_conf) do
		local tmpContenId = tonumber(k)
		local tmpCon = math.floor(tmpContenId/100)
		if cont==tmpCon then
			table.insert(tb,v)
		end 
	end
	return tb
end

--获取阶段积分信息
function RADailyTaskActivityUtility:getStageScoreData(stageId,cityLevel)

	local RABuildManager = RARequire("RABuildManager")
    -- local cityLevel=RABuildManager:getMainCityLvl()

	local data={}
	data.score={}
	data.reward={}
	local str=""
	local stageData = self:getStageDataById(stageId)

	--score
	local scoreDatas = RAStringUtil:split(stageData.stageScoreThreshold,";")
	for i=1,#scoreDatas do

		if cityLevel==i then
			str=scoreDatas[i]
			break
		end
	end

	local tb = RAStringUtil:split(str,"_")
	for i=1,#tb do
		local score = tonumber(tb[i])
		table.insert(data.score,score)
	end


	local stageScoreReward = RAStringUtil:split(stageData.stageScoreReward,",")

	local tb={}
	local count = #stageScoreReward
	for i=1,count do

		local scoreReward = stageScoreReward[i]
		local reward = RAStringUtil:split(scoreReward,"_")
		local mainType=tonumber(reward[1])
		local rewardId=tonumber(reward[2])
		local num=tonumber(reward[3])
		local icon,name=RAResManager:getIconByTypeAndId(mainType, rewardId)
		local rewardData={}
		rewardData.item_name=name
		rewardData.item_icon=icon
		rewardData.num=num
		table.insert(data.reward,rewardData)
	end


	return data
	
end

function RADailyTaskActivityUtility:getStatgeStatue(activityId,currentId,targetId)

	local stageDatas=self:getStageIdsInActivity(activityId)
	local currentIndex=0
	local targetIndex=0
	for i=1,#stageDatas do
		local stageId=stageDatas[i]
		if stageId==currentId then
			currentIndex=i
		end

		if stageId==targetId then
			targetIndex=i
		end
	end

	if currentIndex==targetIndex then
		return self.STAGESTATU.START
	elseif currentIndex<targetIndex then
		return self.STAGESTATU.NOSTART
	else
		return self.STAGESTATU.OVER
	end 

end
return RADailyTaskActivityUtility

--endregion
