--排行榜实体
RARequire('extern')

local RAAllianceRankingInfo = class('RAAllianceRankingInfo',{
            playerId = "",			    --玩家id
		    playerName = "",		    --玩家名字
		    contribution = 0,	        --玩家贡献值
            contributeRefreshTime = 0   --贡献更新时间
    })

--根据PB初始化数据
function RAAllianceRankingInfo:initByPb(rankInfoPb)
	self.playerId = rankInfoPb.playerId
    self.playerName = rankInfoPb.playerName
    self.contribution = rankInfoPb.contribution
    self.contributeRefreshTime = rankInfoPb.contributeRefreshTime
end

function RAAllianceRankingInfo:ctor(...)

end 


return RAAllianceRankingInfo