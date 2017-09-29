--pb数据存储 超级武器发射平台信息
RARequire('extern')

local RAAllianceNuclearMachineInfo = class('RAAllianceNuclearMachineInfo',{
	machineState 		= 0,	--发射平台状态	
	posX = 0, --发射平台位置
	posY = 0,--发射平台位置
	machineFinishTime 	= 0, --平台建造完成时间
	launchTimes = 0,--成功发射次数
	})


-- //超级武器发射平台状态
-- enum NuclearMachineState
-- {
-- 	NONE_STATE		= 0; // 未建造
-- 	BUILDING_STATE	= 1; // 建造中
-- 	FINISHED_STATE	= 2; // 建造完成
-- }
--根据PB初始化数据
function RAAllianceNuclearMachineInfo:initByPb(pb)
	local GuildManor_pb = RARequire('GuildManor_pb')
	self.machineState = pb.machineState or GuildManor_pb.NONE_STATE
	self.posX = pb.posX or 0 
	self.posY = pb.posY or 0
	self.machineFinishTime = pb.machineFinishTime or 0
	self.launchTimes = pb.launchTimes or 0	
end

function RAAllianceNuclearMachineInfo:ctor(...)

end 

return RAAllianceNuclearMachineInfo
