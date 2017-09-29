--pb数据存储 核弹发射井数据
RARequire('extern')
local RAAllianceNuclearLaunchInfo = RARequire('RAAllianceNuclearLaunchInfo') 
local RAAllianceNuclearMachineInfo = RARequire('RAAllianceNuclearMachineInfo') 

local RAAllianceNuclearInfo = class('RAAllianceNuclearInfo',{
	count 		= 0,	--超级武器数目	
	nuclearReource = 0, --原料
	nuclearResUpdateTime = 0,--上次结算信息
	nuclearCreateEndTime 	= 0, --超级武器制造结束时间
	machineInfo = nil,	--发射平台信息
	launchInfo = nil, --发射流程信息
	})

--根据PB初始化数据
function RAAllianceNuclearInfo:initByPb(pb)
	
	self.count = pb.count
	self.nuclearReource = pb.nuclearReource
	self.nuclearResUpdateTime = pb.nuclearResUpdateTime
	self.nuclearCreateEndTime = pb.nuclearCreateEndTime

	self.machineInfo = RAAllianceNuclearMachineInfo.new()
	self.machineInfo:initByPb(pb.machineInfo)

	if pb:HasField("launchInfo") then 
		self.launchInfo = RAAllianceNuclearLaunchInfo.new()
		self.launchInfo:initByPb(pb.launchInfo)
	else
		self.launchInfo = nil
	end
end

function RAAllianceNuclearInfo:ctor(...)

end 

return RAAllianceNuclearInfo
