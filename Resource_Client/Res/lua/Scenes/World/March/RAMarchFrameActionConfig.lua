--RAMarchFrameActionConfig
-- 行军序列帧显示相关的配置
local Const_pb = RARequire('Const_pb')
local World_pb = RARequire('World_pb')
local HP_pb = RARequire('HP_pb')
local EnumManager = RARequire('EnumManager')
 
local FrameId_Army_Soldier 		= 1 	--大兵
local FrameId_Army_Tank 		= 2 	--坦克
local FrameId_Army_Copter 		= 3 	--飞机
local FrameId_Army_V3 			= 4 	--V3
local FrameId_Army_Scount 		= 5 	--侦查
local FrameId_Army_General 		= 6 	--抓将
local FrameId_Army_Harvesters 	= 7		--采集矿车
local FrameId_Army_Engineer 	= 8		--采集工程师
local FrameId_Army_Trunk 		= 9 	--资源援助

local RAMarchFrameActionConfig = 
{
	-- 采用ccb之后，行军显示配置，用于获取ccb内应该使用哪个角度的动作名
	FrameDirCfg = 
	{
		[0]   = {dir = 0  , 	dirFileName = 0 }, 
		[1]   = {dir = 1  , 	dirFileName = 1 }, 
		[2]   = {dir = 2  , 	dirFileName = 2 }, 
		[3]   = {dir = 3  , 	dirFileName = 3 }, 
		[4]   = {dir = 4  , 	dirFileName = 4 }, 
		[5]   = {dir = 5  , 	dirFileName = 5 }, 
		[6]   = {dir = 6  , 	dirFileName = 6 }, 		
		[7]   = {dir = 7  , 	dirFileName = 7 },
		[8]   = {dir = 8  , 	dirFileName = 8 }, 
		[9]   = {dir = 9  , 	dirFileName = 7 }, 
		[10]  = {dir = 10 , 	dirFileName = 6 }, 
		[11]  = {dir = 11 , 	dirFileName = 5 }, 
		[12]  = {dir = 12 , 	dirFileName = 4 }, 
		[13]  = {dir = 13 , 	dirFileName = 3 }, 
		[14]  = {dir = 14 , 	dirFileName = 2 }, 
		[15]  = {dir = 15 , 	dirFileName = 1 }, 	
	},

	-- 士兵行军序列帧id，march_frame表中 ，根据士兵大类型区分
	MarchSoldiersFrameId = 
	{
		[Const_pb.FOOT_SOLDIER] 		= { normal = FrameId_Army_Soldier,	mass = FrameId_Army_Soldier,	},
		[Const_pb.TANK_SOLDIER] 		= { normal = FrameId_Army_Tank,		mass = FrameId_Army_Tank,		},
		[Const_pb.CANNON_SOLDIER] 		= { normal = FrameId_Army_V3,		mass = FrameId_Army_V3,			},
		[Const_pb.PLANE_SOLDIER] 		= { normal = FrameId_Army_Copter,	mass = FrameId_Army_Copter,		},
	},

	-- 侦查行军序列帧id，march_frame表中
	MarchSpyFrameId = FrameId_Army_Scount,

	-- 抓将返回序列帧id，march_frame表中
	MarchCaptiveReleaseFrameId = FrameId_Army_General,

	-- 资源援助行军序列帧id，march_frame表中
	MarchResAssistanceFrameId = FrameId_Army_Trunk,	
	-- 采集行军序列帧id，march_frame表中 ，根据采集资源类型来区分
	MarchCollectRes2FrameId = 
	{
		[Const_pb.GOLDORE] 		= FrameId_Army_Harvesters,
		[Const_pb.OIL] 			= FrameId_Army_Engineer,
		[Const_pb.STEEL] 		= FrameId_Army_Engineer,
		[Const_pb.TOMBARTHITE] 	= FrameId_Army_Engineer,
	},

	-- 组成独立模型的ccb
	FramePartCCBAniName = 'Frame_',	-- 后面链接方向 0-15，例如 'Frame_0'
	FramePartCCBNodeName = 'mNodeFrame',	-- 后面链接方向 1-2，例如 'mNodeFrame1'

	-- 由单个模型组合成行军显示对象
	FrameCntCCBAniName = 'March_',	-- 后面链接方向 0-15，例如 'March_0'
	FrameCntCCBNodeName = 'mNodeCnt',	-- 后面链接方向 1-2，例如 'mNodeCnt1'
}

-- 根据0-15的方向，获取文件名中的方向值（0-8）
function RAMarchFrameActionConfig:GetDirForFileName(realDir)
	for k,v in pairs(RAMarchFrameActionConfig.FrameDirCfg) do
		if v.dir == realDir then
			return v.dirFileName
		end
	end
	return 0
end


return RAMarchFrameActionConfig