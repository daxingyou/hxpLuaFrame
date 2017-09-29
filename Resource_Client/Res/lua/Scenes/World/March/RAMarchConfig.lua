--RAMarchConfig
-- 行军的配置相关信息
local Const_pb = RARequire('Const_pb')
local World_pb = RARequire('World_pb')
local HP_pb = RARequire('HP_pb')
local EnumManager = RARequire('EnumManager')

local RAMarchConfig = 
{
	-- 集结前往中的行军类型
	MassMarchType =
	{
		World_pb.MASS,
        World_pb.MANOR_MASS,
        World_pb.MANOR_ASSISTANCE_MASS,
        World_pb.PRESIDENT_MASS,
        World_pb.PRESIDENT_ASSISTANCE_MASS,
        World_pb.MONSTER_MASS,
	},

	-- 参与集结的行军类型
	JoinMassMarchType =
	{
		World_pb.MASS_JOIN,
        World_pb.MANOR_MASS_JOIN,
        World_pb.MANOR_ASSISTANCE_MASS_JOIN,
        World_pb.PRESIDENT_MASS_JOIN,
        World_pb.PRESIDENT_ASSISTANCE_MASS_JOIN,
        World_pb.MONSTER_MASS_JOIN,
	},

	-- 非战斗型行军
	PeaceMarchType =
	{
		World_pb.COLLECT_RESOURCE,
		World_pb.ASSISTANCE,
		World_pb.ARMY_QUARTERED,
		World_pb.ASSISTANCE_RES,
		World_pb.CAPTIVE_RELEASE,
		World_pb.MANOR_COLLECT
	},

	-- 行军显示的类型（目前有4种显示情况）
	MarchShowType = 
	{
		One = 1,
		Two = 2,
		Three = 3,
		Four = 4,
		-- 国王飞艇node
		Five = 5,
	},

	-- 国王的飞艇显示
	MarchShowForPresidentFrameId = 10,

	-- 国王的行军线ccb
	MarchShowForPresidentLineCCBName = 'RAWorldMarchLineGold.ccbi',

	-- 采用ccb之后，行军显示配置，用于获取ccb内应该使用哪个角度的动作名
	ArmyMarchAniCfg = 
	{
		[0]   = {dir = 0  , 	ccbName = 'RAWorldMarchNodeNew0.ccbi'  ,	base = { 90		} , gapAdd = 11.25,	gapSub = 11.25, addEqual = false, subEqual = true, }, 
		[1]   = {dir = 1  , 	ccbName = 'RAWorldMarchNodeNew1.ccbi'  ,	base = { 112.5	} , gapAdd = 11.25,	gapSub = 11.25, addEqual = false, subEqual = true, }, 
		[2]   = {dir = 2  , 	ccbName = 'RAWorldMarchNodeNew2.ccbi'  ,	base = { 135	} , gapAdd = 11.25,	gapSub = 11.25, addEqual = false, subEqual = true, }, 
		[3]   = {dir = 3  , 	ccbName = 'RAWorldMarchNodeNew3.ccbi'  ,	base = { 157.5	} , gapAdd = 11.25,	gapSub = 11.25, addEqual = false, subEqual = true, }, 
		[4]   = {dir = 4  , 	ccbName = 'RAWorldMarchNodeNew4.ccbi'  ,	base = { 180	} , gapAdd = 11.25,	gapSub = 11.25, addEqual = false, subEqual = true, }, 
		[5]   = {dir = 5  , 	ccbName = 'RAWorldMarchNodeNew5.ccbi'  ,	base = { 202.5	} , gapAdd = 11.25,	gapSub = 11.25, addEqual = false, subEqual = true, }, 
		[6]   = {dir = 6  , 	ccbName = 'RAWorldMarchNodeNew6.ccbi'  ,	base = { 225	} , gapAdd = 11.25,	gapSub = 11.25, addEqual = false, subEqual = true, }, 		
		[7]   = {dir = 7  , 	ccbName = 'RAWorldMarchNodeNew7.ccbi'  ,	base = { 247.5	} , gapAdd = 11.25,	gapSub = 11.25, addEqual = false, subEqual = true, },
		[8]   = {dir = 8  , 	ccbName = 'RAWorldMarchNodeNew8.ccbi'  ,	base = { 270	} , gapAdd = 11.25,	gapSub = 11.25, addEqual = false, subEqual = true, }, 
		[9]   = {dir = 9  , 	ccbName = 'RAWorldMarchNodeNew9.ccbi'  ,	base = { 292.5	} , gapAdd = 11.25,	gapSub = 11.25, addEqual = false, subEqual = true, }, 
		[10]  = {dir = 10 , 	ccbName = 'RAWorldMarchNodeNew10.ccbi' ,	base = { 315	} , gapAdd = 11.25,	gapSub = 11.25, addEqual = false, subEqual = true, }, 
		[11]  = {dir = 11 , 	ccbName = 'RAWorldMarchNodeNew11.ccbi' ,	base = { 337.5 	} , gapAdd = 11.25,	gapSub = 11.25, addEqual = false, subEqual = true, }, 
		[12]  = {dir = 12 , 	ccbName = 'RAWorldMarchNodeNew12.ccbi' ,	base = { 0, 360 } , gapAdd = 11.25,	gapSub = 11.25, addEqual = false, subEqual = true, }, 
		[13]  = {dir = 13 , 	ccbName = 'RAWorldMarchNodeNew13.ccbi' ,	base = { 22.5	} , gapAdd = 11.25,	gapSub = 11.25, addEqual = false, subEqual = true, }, 
		[14]  = {dir = 14 , 	ccbName = 'RAWorldMarchNodeNew14.ccbi' ,	base = { 45	 	} , gapAdd = 11.25,	gapSub = 11.25, addEqual = false, subEqual = true, }, 
		[15]  = {dir = 15 , 	ccbName = 'RAWorldMarchNodeNew15.ccbi' ,	base = { 67.5	} , gapAdd = 11.25,	gapSub = 11.25, addEqual = false, subEqual = true, }, 	
	},

	-- 容器中ccb模型的tag
	ArmyMarchAniCCBTag = 10001,

	--行军层中，分为两层来添加行军线和行军模型
	March_Line_Tag_And_ZOrder = 100002,
	March_Model_Tag_And_ZOrder = 100003,

	-- 序列帧方向与实际角度的对应关系
	AngleBorderCfg = 
	{
		-- [EnumManager.DIRECTION_ENUM.DIR_UP] = 			{base = 90,  gapAdd = 22.5, gapSub = 22.5, isEqual = false },
		-- [EnumManager.DIRECTION_ENUM.DIR_UP_LEFT] = 		{base = 135, gapAdd = 22.5, gapSub = 22.5, isEqual = true  },
		-- [EnumManager.DIRECTION_ENUM.DIR_LEFT] = 		{base = 180, gapAdd = 22.5, gapSub = 22.5, isEqual = false },
		-- [EnumManager.DIRECTION_ENUM.DIR_DOWN_LEFT] = 	{base = 225, gapAdd = 22.5, gapSub = 22.5, isEqual = true  },
		-- [EnumManager.DIRECTION_ENUM.DIR_DOWN] = 		{base = 270, gapAdd = 22.5, gapSub = 22.5, isEqual = false },
		-- [EnumManager.DIRECTION_ENUM.DIR_DOWN_RIGHT] = 	{base = 315, gapAdd = 22.5, gapSub = 22.5, isEqual = true  },
		-- [EnumManager.DIRECTION_ENUM.DIR_RIGHT] =		{base = 0,   gapAdd = 22.5, gapSub = 22.5, isEqual = false },		
		-- [EnumManager.DIRECTION_ENUM.DIR_UP_RIGHT] = 	{base = 45,  gapAdd = 22.5, gapSub = 22.5, isEqual = true  },
		{dir = EnumManager.DIRECTION_ENUM.DIR_UP,			base = 90,  gapAdd = 22.5, gapSub = 22.5, isEqual = false },
		{dir = EnumManager.DIRECTION_ENUM.DIR_UP_LEFT,  	base = 135, gapAdd = 22.5, gapSub = 22.5, isEqual = true  },
		{dir = EnumManager.DIRECTION_ENUM.DIR_LEFT,  		base = 180, gapAdd = 22.5, gapSub = 22.5, isEqual = false },
		{dir = EnumManager.DIRECTION_ENUM.DIR_DOWN_LEFT, 	base = 225, gapAdd = 25,   gapSub = 22.5, isEqual = true  },
		{dir = EnumManager.DIRECTION_ENUM.DIR_DOWN,  		base = 270, gapAdd = 20,   gapSub = 20, isEqual = false },
		{dir = EnumManager.DIRECTION_ENUM.DIR_DOWN_RIGHT,	base = 315, gapAdd = 22.5, gapSub = 25, isEqual = true  },
		{dir = EnumManager.DIRECTION_ENUM.DIR_RIGHT,	 	base = 0,   gapAdd = 22.5, gapSub = 22.5, isEqual = false },		
		{dir = EnumManager.DIRECTION_ENUM.DIR_RIGHT,	 	base = 360, gapAdd = 22.5, gapSub = 22.5, isEqual = false },		
		{dir = EnumManager.DIRECTION_ENUM.DIR_UP_RIGHT,		base = 45,  gapAdd = 22.5, gapSub = 22.5, isEqual = true  },
	}, 

	-- 行军实际角度与ccb容器的对应关系
	EntityNameCfg = 
	{
		[EnumManager.DIRECTION_ENUM.DIR_UP] = 			{name = 'RAWorldMarchNode90.ccbi', 	isFlip = false  },
		[EnumManager.DIRECTION_ENUM.DIR_UP_LEFT] = 		{name = 'RAWorldMarchNode135.ccbi', isFlip = false },
		[EnumManager.DIRECTION_ENUM.DIR_LEFT] = 		{name = 'RAWorldMarchNode180.ccbi', isFlip = false },
		[EnumManager.DIRECTION_ENUM.DIR_DOWN_LEFT] = 	{name = 'RAWorldMarchNode225.ccbi', isFlip = false },
		[EnumManager.DIRECTION_ENUM.DIR_DOWN] = 		{name = 'RAWorldMarchNode270.ccbi', isFlip = false },
		[EnumManager.DIRECTION_ENUM.DIR_DOWN_RIGHT] = 	{name = 'RAWorldMarchNode315.ccbi', isFlip = false  },
		[EnumManager.DIRECTION_ENUM.DIR_RIGHT] =		{name = 'RAWorldMarchNode0.ccbi', 	isFlip = false  },
		[EnumManager.DIRECTION_ENUM.DIR_UP_RIGHT] = 	{name = 'RAWorldMarchNode45.ccbi', 	isFlip = false  },
	},

	-- 返回目标点ccb
	ReturnPosCCB = 'Ani_Map_Icon_Return.ccbi',
	-- 行军目标点ccb
	EndPosCCB = 'Ani_Map_Icon_Attack.ccbi',

	-- -- 侦查行军ccb
	-- MarchSpyCCB = 'Army_Scout_Run.ccbi',

	-- -- 抓将返回ccb
	-- MarchCaptiveReleaseCCB = 'Army_General_Run.ccbi',

	-- -- 资源援助行军ccb
	-- MarchResAssistanceCCB = 'Army_Truck_Run.ccbi',	
	-- -- 采集行军ccb ，根据采集资源类型来区分
	-- MarchCollectResCCB = 
	-- {
	-- 	[Const_pb.GOLDORE] 		= 'Army_Harvesters.ccbi',
	-- 	[Const_pb.OIL] 			= 'Army_Engineer_Run.ccbi',
	-- 	[Const_pb.STEEL] 		= 'Army_Engineer_Run.ccbi',
	-- 	[Const_pb.TOMBARTHITE] 	= 'Army_Engineer_Run.ccbi',
	-- },

	-- MarchCollectResVideos = 
	-- {
	-- 	[Const_pb.GOLDORE] 		= {out = 'mineCarOut', arr = 'mineCarArrive'},
	-- 	[Const_pb.OIL] 			= {out = 'engineerOut', arr = 'engineerArrive'},
	-- 	[Const_pb.STEEL] 		= {out = 'engineerOut', arr = 'engineerArrive'},
	-- 	[Const_pb.TOMBARTHITE] 	= {out = 'engineerOut', arr = 'engineerArrive'},
	-- },

	-- -- 士兵行军ccb ，根据士兵大类型区分
	-- MarchSoldiersCCB = 
	-- {
	-- 	[Const_pb.FOOT_SOLDIER] 		= { normal = 'Army_Soldier_Run.ccbi' 	,	mass = 'Army_Soldier_Run.ccbi' 	,	video = 'v_ImGoing' 	},
	-- 	[Const_pb.TANK_SOLDIER] 		= { normal = 'Army_Tank_Run.ccbi' 		,	mass = 'Army_Tank_Run.ccbi' 	,	video = 'v_OnTheWaySir' 	},
	-- 	[Const_pb.CANNON_SOLDIER] 		= { normal = 'Army_V3_Run.ccbi' 		,	mass = 'Army_V3_Run.ccbi' 		,	video = 'groundForcesMove' 	},
	-- 	[Const_pb.PLANE_SOLDIER] 		= { normal = 'Army_Copter_Run.ccbi' 	,	mass = 'Army_Copter_Run.ccbi' 	,	video = 'helicopterMove' 	},
	-- },

	-- MarchModelAniName = 'Run_',	-- 后面链接方向 0-15，例如 ‘Run_0’


	-- 侦查行军ccb
	MarchSpyCCB = 'Army_Scout_World_March.ccbi',

	-- 抓将返回ccb
	MarchCaptiveReleaseCCB = 'Army_General_World_March.ccbi',

	-- 资源援助行军ccb
	MarchResAssistanceCCB = 'Army_Truck_World_March.ccbi',	
	-- 采集行军ccb ，根据采集资源类型来区分
	MarchCollectResCCB = 
	{
		[Const_pb.GOLDORE] 		= 'Army_Harvesters_World_March.ccbi',
		[Const_pb.OIL] 			= 'Army_Engineer_World_March.ccbi',
		[Const_pb.STEEL] 		= 'Army_Engineer_World_March.ccbi',
		[Const_pb.TOMBARTHITE] 	= 'Army_Engineer_World_March.ccbi',
	},

	MarchCollectResVideos = 
	{
		[Const_pb.GOLDORE] 		= {out = 'mineCarOut', arr = 'mineCarArrive'},
		[Const_pb.OIL] 			= {out = 'engineerOut', arr = 'engineerArrive'},
		[Const_pb.STEEL] 		= {out = 'engineerOut', arr = 'engineerArrive'},
		[Const_pb.TOMBARTHITE] 	= {out = 'engineerOut', arr = 'engineerArrive'},
	},

	-- 士兵行军ccb ，根据士兵大类型区分
	MarchSoldiersCCB = 
	{
		[Const_pb.FOOT_SOLDIER] 		= { normal = 'Army_Soldier_World_March.ccbi' 	,	mass = 'Army_Soldier_World_March.ccbi' 	,	video = 'v_ImGoing' 	},
		[Const_pb.TANK_SOLDIER] 		= { normal = 'Army_Tank_World_March.ccbi' 		,	mass = 'Army_Tank_World_March.ccbi' 	,	video = 'v_OnTheWaySir' 	},
		[Const_pb.CANNON_SOLDIER] 		= { normal = 'Army_V3_World_March.ccbi' 		,	mass = 'Army_V3_World_March.ccbi' 		,	video = 'groundForcesMove' 	},
		[Const_pb.PLANE_SOLDIER] 		= { normal = 'Army_Copter_World_March.ccbi' 	,	mass = 'Army_Copter_World_March.ccbi' 	,	video = 'helicopterMove' 	},
	},

	MarchModelAniName = 'March_',	-- 后面链接方向 0-15，例如 ‘Run_0’

	-- 行军类型对应的hp code
	MarchType2HpCode = 
	{
		[World_pb.COLLECT_RESOURCE] =		{ c2s = HP_pb.WORLD_COLLECTRESOURCE_C,	 s2c = HP_pb.WORLD_COLLECTRESOURCE_S },
		[World_pb.ATTACK_MONSTER] 	=		{ c2s = HP_pb.WORLD_FIGHTMONSTER_C,		 s2c = HP_pb.WORLD_FIGHTMONSTER_S	 },
		[World_pb.ATTACK_PLAYER] 	=		{ c2s = HP_pb.WORLD_ATTACK_PLAYER_C,	 s2c = HP_pb.WORLD_ATTACK_PLAYER_S	 },
		[World_pb.ASSISTANCE]		=		{ c2s = HP_pb.WORLD_ASSISTANCE_C,		 s2c = HP_pb.WORLD_ASSISTANCE_S 	 },
		[World_pb.ARMY_QUARTERED] 	=		{ c2s = HP_pb.WORLD_QUARTERED_C,		 s2c = HP_pb.WORLD_QUARTERED_S		 },
		[World_pb.SPY]	 			=		{ c2s = HP_pb.WORLD_SPY_C,	 			 s2c = HP_pb.WORLD_SPY_S			 },
		[World_pb.MASS] 			=		{ c2s = HP_pb.WORLD_MASS_C,	 			 s2c = HP_pb.WORLD_MASS_S 			 },
		[World_pb.MASS_JOIN] 		=		{ c2s = HP_pb.WORLD_MASS_JOIN_C,	 	 s2c = HP_pb.WORLD_MASS_JOIN_S 		 },

		[World_pb.MONSTER_MASS] 			=		{ c2s = HP_pb.WORLD_MASS_C,	 			 s2c = HP_pb.WORLD_MASS_S 			 },
		[World_pb.MONSTER_MASS_JOIN] 		=		{ c2s = HP_pb.WORLD_MASS_JOIN_C,	 	 s2c = HP_pb.WORLD_MASS_JOIN_S 		 },

		[World_pb.ASSISTANCE_RES] 	=		{ c2s = HP_pb.WORLD_ASSISTANCE_RES_C,	 s2c = HP_pb.WORLD_ASSISTANCE_RES_S  },
		--抓将类型行军，前端不会主动发起
		--[World_pb.CAPTIVE_RELEASE]
		[World_pb.MANOR_SINGLE] 	=		{ c2s = HP_pb.WORLD_ATTACK_PLAYER_C,	 s2c = HP_pb.WORLD_ATTACK_PLAYER_S  },
		[World_pb.MANOR_MASS] 		=		{ c2s = HP_pb.WORLD_MASS_C,	 			 s2c = HP_pb.WORLD_MASS_S 			 },
		[World_pb.MANOR_MASS_JOIN] 	=		{ c2s = HP_pb.WORLD_MASS_JOIN_C,	 	 s2c = HP_pb.WORLD_MASS_JOIN_S 		 },
		--集结援助
		[World_pb.MANOR_ASSISTANCE_MASS] 		=		{ c2s = HP_pb.WORLD_MASS_C,	 			 s2c = HP_pb.WORLD_MASS_S 			 },
		[World_pb.MANOR_ASSISTANCE_MASS_JOIN] 	=		{ c2s = HP_pb.WORLD_MASS_JOIN_C,	 	 s2c = HP_pb.WORLD_MASS_JOIN_S 		 },
		--超级矿采集
		[World_pb.MANOR_COLLECT] =		{ c2s = HP_pb.WORLD_COLLECTRESOURCE_C,	 s2c = HP_pb.WORLD_COLLECTRESOURCE_S },
		--堡垒单人援助
		[World_pb.MANOR_ASSISTANCE]		=		{ c2s = HP_pb.WORLD_ASSISTANCE_C,		 s2c = HP_pb.WORLD_ASSISTANCE_S 	 },

		--首都争夺战相关
		[World_pb.PRESIDENT_SINGLE] 	=		{ c2s = HP_pb.WORLD_ATTACK_PLAYER_C,	 s2c = HP_pb.WORLD_ATTACK_PLAYER_S  },
		[World_pb.PRESIDENT_MASS] 		=		{ c2s = HP_pb.WORLD_MASS_C,	 			 s2c = HP_pb.WORLD_MASS_S 			 },
		[World_pb.PRESIDENT_MASS_JOIN] 	=		{ c2s = HP_pb.WORLD_MASS_JOIN_C,	 	 s2c = HP_pb.WORLD_MASS_JOIN_S 		 },
		[World_pb.PRESIDENT_ASSISTANCE_MASS] 		=		{ c2s = HP_pb.WORLD_MASS_C,	 			 s2c = HP_pb.WORLD_MASS_S 			 },
		[World_pb.PRESIDENT_ASSISTANCE_MASS_JOIN] 	=		{ c2s = HP_pb.WORLD_MASS_JOIN_C,	 	 s2c = HP_pb.WORLD_MASS_JOIN_S 		 },
		[World_pb.PRESIDENT_ASSISTANCE]		=		{ c2s = HP_pb.WORLD_ASSISTANCE_C,		 s2c = HP_pb.WORLD_ASSISTANCE_S 	 },
	},

	MarchType2DisCfg = 
	{
		[World_pb.COLLECT_RESOURCE] =		{ title = '@CollectResTiltle' 		,	btnLabel =	'@TroopCharge'		, 	},
		[World_pb.ATTACK_MONSTER] 	=		{ title = '@AtkMonsterTiltle' 		,	btnLabel =	'@TroopCharge'		, 	},
		[World_pb.ATTACK_PLAYER] 	=		{ title = '@TroopChargeTitle' 		,	btnLabel =	'@TroopCharge'		, 	},
		[World_pb.ASSISTANCE]		=		{ title = '@AssistanceTiltle' 		,	btnLabel =	'@AssistanceBtn'	, 	},
		[World_pb.ARMY_QUARTERED] 	=		{ title = '@ArmyQuarteredTiltle' 	,	btnLabel =	'@TroopCharge'		, 	},
		[World_pb.SPY]	 			=		{ title = '@SpyTiltle' 				,	btnLabel =	'@TroopCharge'		, 	},
		[World_pb.MASS] 			=		{ title = '@MassTiltle' 			,	btnLabel =	'@MassBtn'			, 	},
		[World_pb.MASS_JOIN] 		=		{ title = '@MassJoinTiltle' 		,	btnLabel =	'@MassJoinBtn'		, 	},

		[World_pb.MONSTER_MASS] 			=		{ title = '@MassTiltle' 			,	btnLabel =	'@MassBtn'			, 	},
		[World_pb.MONSTER_MASS_JOIN] 		=		{ title = '@MassJoinTiltle' 		,	btnLabel =	'@MassJoinBtn'		, 	},

		[World_pb.ASSISTANCE_RES] 	=		{ title = '@AssistanceResTiltle' 	,	btnLabel =	'@AssistanceResBtn'	, 	},
		--抓将类型行军，前端不会主动发起
		--[World_pb.CAPTIVE_RELEASE]
		[World_pb.MANOR_SINGLE] 	=		{ title = '@TroopChargeTitle' 		,	btnLabel =	'@TroopCharge'		, 	},
		[World_pb.MANOR_MASS] 		=		{ title = '@MassTiltle' 			,	btnLabel =	'@MassBtn'			, 	},
		[World_pb.MANOR_MASS_JOIN] 	=		{ title = '@MassJoinTiltle' 		,	btnLabel =	'@MassJoinBtn'		, 	},
		[World_pb.MANOR_ASSISTANCE_MASS] 		=		{ title = '@MassTiltle' 			,	btnLabel =	'@MassBtn'			, 	},
		[World_pb.MANOR_ASSISTANCE_MASS_JOIN] 	=		{ title = '@MassJoinTiltle' 		,	btnLabel =	'@MassJoinBtn'		, 	},		
		[World_pb.MANOR_COLLECT] =		{ title = '@CollectResTiltle' 		,	btnLabel =	'@TroopCharge'		, 	},
		[World_pb.MANOR_ASSISTANCE]		=		{ title = '@AssistanceTiltle' 		,	btnLabel =	'@AssistanceBtn'	, 	},

		--首都争夺战相关
		[World_pb.PRESIDENT_SINGLE] 	=		{ title = '@TroopChargeTitle' 		,	btnLabel =	'@TroopCharge'		, 	},
		[World_pb.PRESIDENT_MASS] 		=		{ title = '@MassTiltle' 			,	btnLabel =	'@MassBtn'			, 	},
		[World_pb.PRESIDENT_MASS_JOIN] 	=		{ title = '@MassJoinTiltle' 		,	btnLabel =	'@MassJoinBtn'		, 	},
		[World_pb.PRESIDENT_ASSISTANCE_MASS] 		=		{ title = '@MassTiltle' 			,	btnLabel =	'@MassBtn'			, 	},
		[World_pb.PRESIDENT_ASSISTANCE_MASS_JOIN] 	=		{ title = '@MassJoinTiltle' 		,	btnLabel =	'@MassJoinBtn'		, 	},		
		[World_pb.PRESIDENT_ASSISTANCE]		=		{ title = '@AssistanceTiltle' 		,	btnLabel =	'@AssistanceBtn'	, 	},
	}, 
 
	-- 行军距离类型，根据是否穿过黑土地区分
	-- S为起点，E为终点，B1为黑土地点1，B2为黑土地点2
	MarchDisType = 
	{
		S_B1_B2_E 	= 1,		-- 完整从黑土地中走过，与黑土边缘有两个交点
		S_B1_B2		= 2,		-- 终点在黑土地中，与黑土地边缘有1个交点（包含终点在黑土地边缘上的情况）
		B1_B2 		= 3, 		-- 起点在黑土地中，终点也在黑土地
		B1_B2_E 	= 4,		-- 起点在黑土地，终点在普通地带（包含起点在黑土地边缘的情况）
		S_E 		= 5,		-- 起点和终点都不在黑土地，且和黑土地没有交点
	},

	-- 行军关系对应的ccb名字
	MarchRelation2CCB = 
	{
		[World_pb.SELF] 			= {ccb = 'RAWorldMarchLineGreen.ccbi'},
		[World_pb.GUILD_FRIEND] 	= {ccb = 'RAWorldMarchLineBlue.ccbi'},
		[World_pb.TEAM_LEADER] 		= {ccb = 'RAWorldMarchLineBlue.ccbi'},
		[World_pb.ENEMY] 			= {ccb = 'RAWorldMarchLineRed.ccbi'},
		[World_pb.NONE] 			= {ccb = 'RAWorldMarchLineWhite.ccbi'},
	},


	-- 行军线最高速度提升比例，防止出现倒着走
	MarchLineSpeedMaxScale = 2.5,
	-- 行军线初始速度值{x=x, y=y}
	MarchLineSpeedInit = {x = -1.5, y = 0},

	-- 行军返回的容错距离，单位像素
	-- 用于快速召回的时候后端的起始格子和终点格子一样的情况
	MarchCallBackGapDis = 40,

	-- 行军加速的容错距离，单位像素
	-- 用于行军快达到的时候，使用加速道具后，后端的起始格子和终点格子一样的情况
	MarchSpeedUpGapDis = 40,

	MarchDisplayZOrder = 
	{		
		MoveEntity = 120,
		LineEntity = 100,
		EndEntity = 110,
	},

	-- 行军保存的范围，以屏幕中心扩散，单位和后端保持一致为格子
	MarchDisplayRange = -1, 

	-- 每条行军计算间隔，毫秒，从配置中取
	MarchBufferOutputGap = -1,
	-- 行军限制数目
	MarchLimitTotalCount = -1,
	MarchLimitEnmyCount = -1,
	MarchLimitGuildCount = -1,
	MarchLimitIrrelevantCount = -1,
}


-- 根据手机配置，获取当前行军上限的条目
-- 条目逻辑：
-- 1、这些限制不包括自己的行军在内
-- 2、最优先判定totaltMarchLimit，所有非自己参与的行军均如此
-- 3、在totaltMarchLimit之内，按 enmy、guild、irreleveant的关系挨个刷新
function RAMarchConfig:GetMarchLimitValue(phoneLv)
	local march_display_conf = RARequire('march_display_conf')
	-- 手机优劣等级，3最高，2次之，1最低
	local phoneLv = phoneLv or 3
	local valueKey = 'High'
	if phoneLv == 2 then valueKey = 'Mid' end
	if phoneLv == 1 then valueKey = 'Low' end
	local enmyKey = 'enemyMarchLimit'..valueKey
	local enmyCount = march_display_conf[enmyKey].value

	local guildKey = 'allianceMarchLimit'..valueKey
	local guildCount = march_display_conf[guildKey].value

	local irrelevantKey = 'irrelevantMarchLimit'..valueKey
	local irrelevantCount = march_display_conf[irrelevantKey].value

	local totalKey = 'totaltMarchLimit'..valueKey
	local totalCount = march_display_conf[totalKey].value

	return totalCount, enmyCount, guildCount, irrelevantCount
end


-- 获取需要预加载的ccbi名字列表，返回一个table
-- result = {name1 = [arg1, arg2] }
-- arg1 = {count = 1, colorParam = {}}
-- colorParam = {key = '', color = {r = 0, g = 0, b = 0}} or nil
function RAMarchConfig:GetPreloadCCBFiles()
	local RAWorldConfig = RARequire('RAWorldConfig')	
	local result = {}
	
	local copyColorParam = function(colorParam)
		local result = {}
		result.key = colorParam.key
		result.color = {}
		result.color.r = colorParam.color.r
		result.color.g = colorParam.color.g
		result.color.b = colorParam.color.b
		return result
	end

	-- 士兵
	for k,cfg in pairs(RAMarchConfig.MarchSoldiersCCB) do
		result[cfg.normal] = {}
		for relation, colorParam in pairs(RAWorldConfig.RelationFlagColor) do
			local soldierArg = {count = 1, colorParam = {}}
			soldierArg.colorParam = copyColorParam(colorParam)
			table.insert(result[cfg.normal], soldierArg)

			-- 因为预加载机制修改，所以颜色无效，只加载ccb文件
			break
		end
	end

	-- 侦查、释放领主、资源援助
	result[RAMarchConfig.MarchSpyCCB] = {}
	result[RAMarchConfig.MarchCaptiveReleaseCCB] = {}
	result[RAMarchConfig.MarchResAssistanceCCB] = {}
	for relation, colorParam in pairs(RAWorldConfig.RelationFlagColor) do
		local spyArg = {count = 1, colorParam = {}}
		spyArg.colorParam = copyColorParam(colorParam)
		table.insert(result[RAMarchConfig.MarchSpyCCB], spyArg)

		local releaseArg = {count = 1, colorParam = {}}
		releaseArg.colorParam = copyColorParam(colorParam)
		table.insert(result[RAMarchConfig.MarchCaptiveReleaseCCB], releaseArg)

		local assistArg = {count = 1, colorParam = {}}
		assistArg.colorParam = copyColorParam(colorParam)
		table.insert(result[RAMarchConfig.MarchResAssistanceCCB], assistArg)
		-- 因为预加载机制修改，所以颜色无效，只加载ccb文件
		break
	end

	-- 资源采集
	for k,name in pairs(RAMarchConfig.MarchCollectResCCB) do
		result[name] = {}
		for relation, colorParam in pairs(RAWorldConfig.RelationFlagColor) do
			local resArg = {count = 1, colorParam = {}}
			resArg.colorParam = copyColorParam(colorParam)
			table.insert(result[name], resArg)
			-- 因为预加载机制修改，所以颜色无效，只加载ccb文件
			break
		end
	end	
	return result
end

return RAMarchConfig