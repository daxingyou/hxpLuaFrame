--联盟玩家战争信息
RARequire('extern')

local RAGarrionPlayerInfo = class('RAGarrionPlayerInfo', {
    playerId 	= '',	--玩家ID
    playerName 	= '',	--玩家名称
    icon 		= 0, 	--头像
    posX 		= 0, 	--X
    posY 		= 0,  	--Y
    armyNum 	= 0,  	--军队数量
    armyInfo 	= nil, 	--军队信息
    status 		= 0, 	--集结 or 行军
    startTime 	= 0, 	--出兵开始时间
    endTime 	= 0, 	--出兵结束时间
    guildTag 	= '',	--联盟缩写
    marchId 	= '', 	--行军唯一id
    isLeader	= false,-- 是否是队长
})

--根据PB初始化数据
function RAGarrionPlayerInfo:initByPb(garrisonPlayerInfoPb)
	self.playerId = garrisonPlayerInfoPb.playerId
	self.playerName = garrisonPlayerInfoPb.playerName
	self.icon = garrisonPlayerInfoPb.icon
	self.posX = garrisonPlayerInfoPb.posX
	self.posY = garrisonPlayerInfoPb.posY
	self.armyNum = garrisonPlayerInfoPb.armyNum
    self.armyInfo = garrisonPlayerInfoPb.armyInfo
	self.status = garrisonPlayerInfoPb.status
    self.startTime = garrisonPlayerInfoPb.startTime
    self.endTime = garrisonPlayerInfoPb.endTime
		self.marchId = garrisonPlayerInfoPb.marchId
end

function RAGarrionPlayerInfo:ctor(...)
	self.playerId 	= ''	--玩家ID
    self.playerName = ''	--玩家名称
    self.icon 		= 0 	--头像
    self.posX 		= 0 	--X
    self.posY 		= 0  	--Y
    self.armyNum 	= 0  	--军队数量
    self.armyInfo 	= nil 	--军队信息
    self.status 	= 0 	--集结 or 行军
    self.startTime 	= 0 	--出兵开始时间
    self.endTime 	= 0 	--出兵结束时间
    self.guildTag 	= ''	--联盟缩写
    self.marchId 	= '' 	--行军唯一id
    self.isLeader	= false -- 是否是队长
end

local RAGarrisonInfo = class('RAGarrisonInfo', {
	marchId 		= nil,		-- 队长行军唯一id
    leaderId 		= nil,		-- 队长的玩家ID
    playerInfo 		= {}, 		-- 防御玩家
    startTime 		= 0,		-- 行军开始时间
    endTime 		= 0,		-- 行军结束时间
    currArmyCount 	= 0,		-- 部队当前总兵力
    maxArmyCount 	= 0,		-- 队长的集结上限
    captainInfo 	= nil, 		-- 队长信息
    teamMemberInfos = {},	  	-- 集结队员信息
})

--根据PB初始化数据
function RAGarrisonInfo:initByPb(garrisonPB)
	self.marchId = garrisonPB.leaderMarchId
	self.leaderId = garrisonPB.leaderId
	self.currArmyCount = garrisonPB.currArmyCount
	self.maxArmyCount = garrisonPB.maxArmyCount
	self.status = garrisonPB.status

	if garrisonPB:HasField('startTime') then 
	    self.startTime = garrisonPB.startTime
 	end
 	if garrisonPB:HasField('endTime') then 
	    self.endTime = garrisonPB.endTime
 	end	

	for i = 1 ,#garrisonPB.players do
		local info = RAGarrionPlayerInfo.new()
        info:initByPb(garrisonPB.players[i])
        self.playerInfo[#self.playerInfo + 1] = info
        local isLeader = info.playerId == self.leaderId
        if isLeader then
    		self.captainInfo = info
    	end
    	info.isLeader = isLeader
		self.teamMemberInfos[#self.teamMemberInfos + 1] = info
	end
end

function RAGarrisonInfo:ctor(...)
	self.marchId 			= nil		-- 队长行军唯一id
    self.leaderId 			= nil		-- 队长的玩家ID
    self.playerInfo 		= {} 		-- 防御玩家
    self.startTime 			= 0			-- 行军开始时间
    self.endTime 			= 0			-- 行军结束时间
    self.currArmyCount 		= 0			-- 部队当前总兵力
    self.maxArmyCount 		= 0			-- 队长的集结上限
    self.captainInfo 		= nil 		-- 队长信息
    self.teamMemberInfos 	= {}	  	-- 集结队员信息
end

return RAGarrisonInfo