local RAAllianceRankingManager = {}

local RAAllianceRankingInfo = RARequire('RAAllianceRankingInfo')

--初始化
function RAAllianceRankingManager:setContributeData(infos)
	-- body
	local contributionRank = {}
	contributionRank.contribution = infos.contribution
	contributionRank.dailyContribution = infos.dailyContribution
	contributionRank.rankInfo = {}
	local rankInfos = infos.rankInfo
	for i=1,#rankInfos do
		local rankInfo = rankInfos[i]
		local info = RAAllianceRankingInfo.new()
	    info:initByPb(rankInfo)
        contributionRank.rankInfo[#contributionRank.rankInfo + 1] = info
	end
	
	return contributionRank
end

return RAAllianceRankingManager