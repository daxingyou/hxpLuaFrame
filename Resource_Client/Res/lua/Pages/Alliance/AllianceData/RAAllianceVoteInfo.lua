--投票信息
RARequire('extern')

local RAAllianceVoteInfo = class('RAAllianceVoteInfo',{
		organizer = '',--发起人
		votePlayer = nil,--投票人
		voteProtectTime = 0,--投票保护时间
    })

--根据PB初始化数据
function RAAllianceVoteInfo:initByPb(pb)
	self.organizer = pb.organizer
	
	self.votePlayer = {}
	for i=1,#pb.votePlayer do
		self.votePlayer[i] = pb.votePlayer[i]
	end

	if pb:HasField("voteProtectTime") then 
		self.voteProtectTime = pb.voteProtectTime
	end
end

function RAAllianceVoteInfo:ctor(...)

end 

return RAAllianceVoteInfo



