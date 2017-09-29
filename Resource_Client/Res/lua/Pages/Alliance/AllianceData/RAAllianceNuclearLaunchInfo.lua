--pb数据存储 发射流程信息
RARequire('extern')
local RAAllianceVoteInfo = RARequire('RAAllianceVoteInfo')  --投票数据

local RAAllianceNuclearLaunchInfo = class('RAAllianceNuclearLaunchInfo',{
	launchType 		= 0,	--发射方式	
	state = 0, --发射流程状态
	launchTime = 0,--发射时间
	firePosX 	= 0, --目标位置
	firePosY 	= 0, --目标位置
	voteInfo 	= 0, --投票信息
	})

-- //超级武器发射方式
-- enum NuclearLaunchType
-- {
-- 	FROM_NONE		= 0; // 未发射
-- 	FROM_MANOR		= 1; // 发射井
-- 	FROM_MACHINE	= 2; // 发射平台
-- }


-- //核弹发射井状态
-- enum NuclearState
-- {
-- 	NORMAL_STATE	= 0; //正常
-- 	VOTING			= 1; //投票中
-- 	CAN_OPENUP		= 2; //可展开
-- 	CAN_LAUNCH		= 3; //可发射
-- 	LAUNCHING		= 4; //发射中
-- 	CANCEL			= 5; //取消(仅供客户端推送,server实际存储为0)
-- }


--根据PB初始化数据
function RAAllianceNuclearLaunchInfo:initByPb(pb)
	local GuildManor_pb = RARequire('GuildManor_pb')
	local World_pb = RARequire('World_pb')
	self.launchType = pb.launchType
	self.state = pb.state
	self.launchTime = pb.launchTime or 0
	self.firePosX = pb.firePosX or 0
	self.firePosY = pb.firePosY or 0

	if pb:HasField("voteInfo") then 
		self.voteInfo = RAAllianceVoteInfo.new()
		self.voteInfo:initByPb(pb.voteInfo)
	else
		self.voteInfo = nil 
	end 
end

function RAAllianceNuclearLaunchInfo:ctor(...)

end 

return RAAllianceNuclearLaunchInfo
