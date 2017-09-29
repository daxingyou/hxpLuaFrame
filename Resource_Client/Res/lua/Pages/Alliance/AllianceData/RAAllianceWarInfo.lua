--联盟玩家战争信息
RARequire('extern')

local RAAllianceWarPlayerInfo = RARequire("RAAllianceWarPlayerInfo")

local RAAllianceWarInfo = class('RAAllianceWarInfo',{
			marchId = nil,		-- 行军唯一id
            warType = 0,		--类型
            marchType = World_pb.MASS, --行军类型 默认为集结
		    atkInfo = {},		--进攻玩家
		    dfcInfo = {}, 		--防御玩家
            startTime = 0,		-- 时间
            endTime = 0,		-- 时间
            status = 0, 		-- 状态
            maxNum = 0,			--集结和援助最大兵力
            atkCaptainInfo = nil, --进攻玩家队长信息
            dfcCaptainInfo = nil, --防御玩家队长信息
            gatherTeamMemberInfos = {},	  --集结队员信息
            defendTeamMemberInfos = {}	  --防守队员信息
    })

--根据PB初始化数据
function RAAllianceWarInfo:initByPb(warInfoPb)
	if warInfoPb:HasField("marchId") then 
		self.marchId = warInfoPb.marchId
 	end
    if warInfoPb:HasField("warType") then 
		self.warType = warInfoPb.warType
 	end
 	if warInfoPb:HasField("marchType") then 
		self.marchType = warInfoPb.marchType
 	end
	if warInfoPb:HasField("startTime") then 
	    self.startTime = warInfoPb.startTime
 	end
 	if warInfoPb:HasField("endTime") then 
	    self.endTime = warInfoPb.endTime
 	end	
    if warInfoPb:HasField("status") then 
	    self.status = warInfoPb.status
 	end
 	if warInfoPb:HasField("maxNum") then 
	    self.maxNum = warInfoPb.maxNum
 	end

 	if warInfoPb:HasField("info") then 
		for i = 1 ,#warInfoPb.info.atk do
			local info = RAAllianceWarPlayerInfo.new()
	        info:initByPb(warInfoPb.info.atk[i])
	        self.atkInfo[#self.atkInfo + 1] = info
	        if info.type == 1 then
        		self.atkCaptainInfo = info
        	else
        		self.gatherTeamMemberInfos[#self.gatherTeamMemberInfos + 1] = info
	        end	
		end

		for i = 1 ,#warInfoPb.info.dfc do
			local info = RAAllianceWarPlayerInfo.new()
	        info:initByPb(warInfoPb.info.dfc[i])
	        self.dfcInfo[#self.dfcInfo + 1] = info
	        if info.type == 1 then
        		self.dfcCaptainInfo = info
	        end	
		end	
 	end
end

function RAAllianceWarInfo:ctor(...)
	self.marchId = nil		-- 行军唯一id
    self.warType = 0		--类型
    self.marchType = 0
	self.atkInfo = {}		--进攻玩家
	self.dfcInfo = {} 		--防御玩家
    self.startTime = 0		-- 时间
    self.endTime = 0		-- 时间
    self.status = 0		-- 状态
    self.atkCaptainInfo = nil --进攻玩家队长信息
    self.dfcCaptainInfo = nil --防御玩家队长信息
    self.gatherTeamMemberInfos = {}	  --集结队员信息
    self.defendTeamMemberInfos = {}	  --防守队员信息
end 

return RAAllianceWarInfo