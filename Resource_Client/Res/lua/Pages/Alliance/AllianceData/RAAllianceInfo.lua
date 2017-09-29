--联盟信息
RARequire('extern')

local RAAllianceInfo = class('RAAllianceInfo',{
		id = "",			--联盟ID
		name = "",			--联盟名称
		guildLevel = 0,		--联盟等级
		leaderName = "",	--盟主
		power = 0,			--联盟战力
		memberNum = 0,		--联盟人数
		memberMaxNum = 0,   --联盟最大人数
		language = 0,		--语言
		notice = "",		--公告
		flag = 0,			--旗帜
		tag = "", 			--联盟缩写
		openRecurit = false,    --公开招募
        announcement = "",      --宣言
        needBuildingLevel = 1,  --建筑等级
        needCommonderLevel = 1, --指挥官等级
        needPower = 0,           --战力
        needLanguage = 0,	--现在语言
        L1Name	= "",		--联盟阶级称谓1,2,3,4,5
        L2Name	= "",
        L3Name	= "",
        L4Name	= "",
        L5Name	= "",
        manorId = nil,		--领地信息
        nuclearReady = nil,
        manorResType = 0,  --超级矿类型
        guildType = 0,--联盟类型
    })

--根据PB初始化数据
function RAAllianceInfo:initByPb(alliancePb)
	self.id = alliancePb.id
	self.name = alliancePb.name
	self.leaderName = alliancePb.leaderName
	self.power = alliancePb.power
	self.level = alliancePb.level
	self.memberNum = alliancePb.memberNum
	self.memberMaxNum = alliancePb.memberMaxNum
	self.language = alliancePb.language
	self.notice = alliancePb.notice
	self.flag = alliancePb.flag
	self.tag = alliancePb.tag
	self.guildType = alliancePb.guildType
	
	if alliancePb:HasField("announcement") then 
		self.announcement = alliancePb.announcement
	end

	if alliancePb:HasField("needBuildingLevel") then 
		self.needBuildingLevel = alliancePb.needBuildingLevel
	end

    if alliancePb:HasField("needCommonderLevel") then 
		self.needCommonderLevel = alliancePb.needCommonderLevel
	end

	if alliancePb:HasField("needPower") then 
		self.needPower = alliancePb.needPower
	end

	if alliancePb:HasField("needLanguage") then 
		self.needLanguage = alliancePb.needLanguage
	end

	if alliancePb:HasField("L1Name") then 
		self.L1Name = alliancePb.L1Name
	end

	if alliancePb:HasField("L2Name") then 
		self.L2Name = alliancePb.L2Name
	end

	if alliancePb:HasField("L3Name") then 
		self.L3Name = alliancePb.L3Name
	end

	if alliancePb:HasField("L4Name") then 
		self.L4Name = alliancePb.L4Name
	end

	if alliancePb:HasField("L5Name") then 
		self.L5Name = alliancePb.L5Name
	end

	if alliancePb:HasField("openRecurit") then 
		self.openRecurit = alliancePb.openRecurit
	end

	if alliancePb:HasField("manorId") then 
		self.manorId = alliancePb.manorId
	end

	if alliancePb:HasField("nuclearReady") then 
		self.nuclearReady = alliancePb.nuclearReady
	end

	if alliancePb:HasField("manorResType") then 
		self.manorResType = alliancePb.manorResType
	end
end

function RAAllianceInfo:getLName()
	local names = {}

	for i=5,1,-1 do
		local key = 'L' .. i .. 'Name' 
		if self[key] == nil or self[key] == '' then 
			names[#names + 1] = '@Default' .. key
		else 
			names[#names + 1] = self[key] 
		end 
	end

	return names
end

function RAAllianceInfo:ctor(...)

end 

return RAAllianceInfo
