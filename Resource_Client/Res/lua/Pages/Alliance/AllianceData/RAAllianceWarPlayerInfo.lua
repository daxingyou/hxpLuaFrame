--联盟玩家战争信息
RARequire('extern')

local RAAllianceWarPlayerInfo = class('RAAllianceWarPlayerInfo',{
			type = 0,		-- 类型 0 成员 1 队长
            playerId = "",			--玩家ID
		    playerName = "",			--玩家名称
            icon = 0, --头像
            guildFlag = 0, --
            posX = 0,  --X
            posY = 0,  --Y
            armyNum = 0,  --军队数量
            armyInfo = nil, --军队信息
            status = 0, --集结 or 行军
            startTime = 0, --出兵开始时间
            endTime = 0, --出兵结束时间
            guildTag = "",--联盟缩写
            marchId = "", --行军唯一id
            guardId = 0, -- 据点id
            manorId = 0, -- 领地id
    })

--根据PB初始化数据
function RAAllianceWarPlayerInfo:initByPb(warPlayerInfoPb)
	self.type = warPlayerInfoPb.type
	self.playerId = warPlayerInfoPb.playerId
	self.startTime = warPlayerInfoPb.startTime
    self.endTime = warPlayerInfoPb.endTime
    self.marchId = warPlayerInfoPb.marchId

    if warPlayerInfoPb:HasField("playerName") then 
		self.playerName = warPlayerInfoPb.playerName
	end
	if warPlayerInfoPb:HasField("icon") then 
		self.icon = warPlayerInfoPb.icon
	end
	if warPlayerInfoPb:HasField("guildTag") then 
		self.guildTag = warPlayerInfoPb.guildTag
	end
	if warPlayerInfoPb:HasField("posX") then 
		self.posX = warPlayerInfoPb.posX
	end
	if warPlayerInfoPb:HasField("posY") then 
		self.posY = warPlayerInfoPb.posY
	end
	if warPlayerInfoPb:HasField("armyNum") then 
		self.armyNum = warPlayerInfoPb.armyNum
	end

    self.armyInfo = warPlayerInfoPb.armyInfo

    if warPlayerInfoPb:HasField("status") then 
		self.status = warPlayerInfoPb.status
	end

	self.guardId = warPlayerInfoPb.guardId or 0
	self.manorId = warPlayerInfoPb.manorId or 0
end

function RAAllianceWarPlayerInfo:ctor(...)
	
end 

return RAAllianceWarPlayerInfo