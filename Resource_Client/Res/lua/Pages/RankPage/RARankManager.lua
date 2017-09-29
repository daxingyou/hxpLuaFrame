local Utilitys = RARequire("Utilitys")
local RANetUtil = RARequire("RANetUtil")
local RAStringUtil = RARequire("RAStringUtil")
local Const_pb = RARequire("Const_pb")
local RAPlayerInfoManager = RARequire("RAPlayerInfoManager")

local RARankManager = {}

RARankManager.rankTabTypeIndex=
{
	Player=0,
	Alliance=1
}

--网络监听数据处理
RARankManager.CurrShowContentRankType=nil
RARankManager.currTabIndex=nil
RARankManager.SelfRankData={}
RARankManager.RankItemContentList={}
RARankManager.RankTopList=nil
RARankManager.RankTopPanel=nil
--接收服务器包，刷新排行面板
function RARankManager.initRankContentData(msg)
	if msg ~= nil then
		local rankType=nil
		local rankItem={}
		for i=1,#msg.rankInfo do
			local rankInfo = msg.rankInfo[i]

			if rankInfo then
				if i==1 then
					rankType=rankInfo.rankType
				end
				local rank=tonumber(rankInfo.rank)
				rankItem[rank]={}
				rankItem[rank].rank=rankInfo.rank
				rankItem[rank].playerName=rankInfo.playerName
				rankItem[rank].allianceName=rankInfo.allianceName
				rankItem[rank].rankInfoValue=rankInfo.rankInfoValue
				rankItem[rank].icon=rankInfo.icon
				rankItem[rank].allianceIcon=rankInfo.allianceIcon
				rankItem[rank].rankType=rankInfo.rankType
				rankItem[rank].guildTag=rankInfo.guildTag
				--CCLuaLog("RARankManager:initRankContentData() i:"..tostring(i)..",Rank:"..tostring(rankItem[rank].rank)..",playerName:"..rankItem[rank].playerName..",allianceName:"..tostring(rankItem[rank].allianceName)..",rankInfoValue:"..rankItem[rank].rankInfoValue..",icon:"..tostring(rankItem[rank].icon)..",allianceIcon:"..rankItem[rank].allianceIcon..",rankType:"..tostring(rankItem[rank].rankType))
			end
		end

		if rankType~=nil then
			RARankManager.RankItemContentList[rankType]=rankItem
			--自己的排行

			RARankManager.SelfRankData[rankType]={}
			RARankManager.SelfRankData[rankType].rank=msg.myRank
			RARankManager.SelfRankData[rankType].rankScore=msg.myRankScore

			if msg:HasField('guildName') then
        		RARankManager.SelfRankData[rankType].guildName=msg.guildName
    		end
			if msg:HasField('guildTag') then
				RARankManager.SelfRankData[rankType].guildTag=msg.guildTag
			end
			if msg:HasField('guildLeaderName') then
				RARankManager.SelfRankData[rankType].guildLeaderName=msg.guildLeaderName
			end
			if msg:HasField('guildFlag') then
				RARankManager.SelfRankData[rankType].guildFlag=msg.guildFlag
			end
			
			--CCLuaLog("RARankManager:initRankContentData():The packet msg MyRank:"..tostring(RARankManager.SelfRankData[rankType]))
		else
			--CCLuaLog("RARankManager:initRankContentData():The packet msg nil,CurrReqRankIndex:"..tostring(RARankManager.CurrShowContentRankType))
		end
	else
		--CCLuaLog("RARankManager:initRankContentData():The packet HPPushRank parse Failed")
	end	
end

--接收服务器包，刷新Top 1排行
function RARankManager.initRankTopContentData(msg)
	if msg ~= nil then
		local rankType=nil
		if RARankManager.RankTopList==nil then
			RARankManager.RankTopList={}
			RARankManager.RankTopList[RARankManager.rankTabTypeIndex.Player]={}
			RARankManager.RankTopList[RARankManager.rankTabTypeIndex.Alliance]={}
		end
		for i=1,#msg.rankInfo do
			local rankInfo = msg.rankInfo[i]
			if rankInfo then
				rankType=rankInfo.rankType
				local rank=tonumber(rankInfo.rank)
				local rankItem={}
				rankItem.rank=rankInfo.rank
				rankItem.playerName=rankInfo.playerName
				rankItem.allianceName=rankInfo.allianceName
				rankItem.rankInfoValue=rankInfo.rankInfoValue
				rankItem.icon=rankInfo.icon
				rankItem.allianceIcon=rankInfo.allianceIcon
				rankItem.rankType=rankInfo.rankType
				rankItem.rankGroup=rankInfo.rankGrop
				rankItem.guildTag=rankInfo.guildTag
				--CCLuaLog("RARankManager:initRankTopContentData() i:"..tostring(i).."Rank:"..tostring(rankItem.rank)..",playerName:"..rankItem.playerName..",allianceName:"..tostring(rankItem.allianceName)..",rankInfoValue:"..rankItem.rankInfoValue..",icon:"..tostring(rankItem.icon)..",allianceIcon:"..rankItem.allianceIcon..",rankType:"..tostring(rankItem.rankType)..",rankGroup:"..tostring(rankItem.rankGroup))
				
				local rankGroupTabIndex=RARankManager.rankTabTypeIndex.Player
				if rankItem.rankGroup==Const_pb.PLAYER_TYPE then
					rankGroupTabIndex=RARankManager.rankTabTypeIndex.Player
				else
					rankGroupTabIndex=RARankManager.rankTabTypeIndex.Alliance	
				end
				table.insert(RARankManager.RankTopList[rankGroupTabIndex],rank,rankItem)
			end
		end
	else
		--CCLuaLog("RARankManager:initRankContentData():The packet HPPushTopRank parse Failed")
	end	
end

function RARankManager.getRankListByIndex(typeIndex)
	local obj=nil
	if RARankManager.RankItemContentList~=nil then
		obj=RARankManager.RankItemContentList[typeIndex]
	end
	
	if obj~=nil then
		--sort		
	end
	
	return obj
end	

function RARankManager.getRankTopListByIndex(typeIndex)
	local obj=nil
	if RARankManager.RankTopList~=nil then
		obj=RARankManager.RankTopList[typeIndex]
	end
	
	if obj~=nil then
		--sort
		obj = Utilitys.tableSortByKey(obj, 'rankType')
	end
	
	return obj
end	

function RARankManager.rankGroupIsPlayer()
	if RARankManager.currTabIndex==nil or RARankManager.currTabIndex==RARankManager.rankTabTypeIndex.Player then
		return true
	end
	return false
end

function RARankManager.getMyRank(rankType)
	local player=RAPlayerInfoManager.getPlayerBasicInfo()
	local rankItem={}
	local item=RARankManager.SelfRankData[RARankManager.CurrShowContentRankType]
	if item~=nil then
		rankItem.rank=item.rank
		rankItem.rankInfoValue=item.rankScore--这是临时的，这个数值应该是客户端获取还是服务器给?
	else
		rankItem.rank=0
		rankItem.rankInfoValue=0
	end
	
	rankItem.playerName=player.name
	rankItem.allianceName=""

	if item.guildName~=nil then
		rankItem.allianceName=item.guildName
		if item.guildTag~=nil then
			rankItem.allianceName="("..item.guildTag..")"..rankItem.allianceName
		end	
	end	
	
	rankItem.guildLeaderName=""
	if item.guildLeaderName~=nil then
		rankItem.guildLeaderName=item.guildLeaderName
	end	

	rankItem.icon=player.headIconId
	rankItem.allianceIcon=nil
	if item.guildFlag~=nil then
		rankItem.allianceIcon=item.guildFlag
	end	
	return rankItem
end

--重置数据
function RARankManager.resetData()
    RARankManager.CurrShowContentRankType=nil
	RARankManager.SelfRankData={}
	RARankManager.RankItemContentList={}
	RARankManager.RankTopList=nil
end

return RARankManager
