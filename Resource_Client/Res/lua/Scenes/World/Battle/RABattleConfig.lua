local ArmyCatogory = RARequire('RAArsenalConfig').ArmyCatogory
local DirEnum = RARequire('EnumManager').DIRECTION_ENUM
local World_pb = RARequire('World_pb')

local AttackCCB_Grid_2 =
{
	Win 	= 'Ani_Map_Att_Solo_Win.ccbi',
	Fail 	= 'Ani_Map_Att_Solo_Fail.ccbi'
}
local AttackCCB_Grid_1 =
{
	Win 	= 'Ani_Map_Att_Monster_Win.ccbi',
	Fail 	= 'Ani_Map_Att_Monster_Fail.ccbi'
}
local DefenseCCB_Grid_2 =
{
	Front 	= 'Army_Defense_Befor_B1.ccbi',
	Back 	= 'Army_Defense_After_B1.ccbi'
}
local DefenseCCB_Grid_1 =
{
	Front 	= 'Army_Defense_Befor_S1.ccbi',
	Back 	= 'Army_Defense_After_S1.ccbi'
}


local RABattleConfig = 
{
	-- 列队时间总时长
	LineUp_Duration = 1,

	-- 战斗动画总时长(单位：s)
	Fire_Duration = 5,

	-- 战斗多久后信显示战果
	ShowResult_TimeSpan = 4,
	-- 显示战果后多久结束整个战斗
	EndBattle_TimeSpan = 1,
	
	-- 血条总格数
	HP_Total = 20,
	-- 血条开始变红的衰减格子数
	HP_LossToRed = 15,
	-- 血条每减一格width变化量
	HP_DescWidth = 11.3,
	-- 血条红格图片
	-- HP_RedSlotPic = 'Animation/MapAni/Ani_Map_Blood_red.png',
	-- 血条ccb
	HP_CCBFile = 'Ani_Map_Icon_Blood_L.ccbi',
	-- 血条width,初次加载时填值
	HP_FullWidth = 0,

	HP_NodeTag = 100,
	
	-- 光陵塔spine名
	LightTower_Spine = '215101',
	LightTower_Attack = 'Ani_Map_Tower_Attack.ccbi',
	LightTower_Harm = 'Ani_Map_Strikez_Tank.ccbi',

	-- 站位CCB
	Stance_CCBFile =
	{
		[DirEnum.DIR_UP_LEFT]	 = 'RAWorldAttackTLNode.ccbi',
		[DirEnum.DIR_UP_RIGHT]	 = 'RAWorldAttackTRNode.ccbi',
		[DirEnum.DIR_DOWN_LEFT]	 = 'RAWorldAttackDLNode.ccbi',
		[DirEnum.DIR_DOWN_RIGHT] = 'RAWorldAttackDRNode.ccbi'
	},
	-- 站位与ArmyId对应([位置]=ArmyId)
	Stance_ArmyMap =
	{
		[1] = ArmyCatogory.infantry,
		[2] = ArmyCatogory.tank,
		[3] = ArmyCatogory.missile,
		[4] = ArmyCatogory.helicopter
 	},

 	Attack_ArmyMap = 
 	{
 		[ArmyCatogory.infantry] = '',
 		[ArmyCatogory.tank] = '',
 		[ArmyCatogory.missile] =
 		{
			[DirEnum.DIR_UP_LEFT]	 = {ccbi = 'Ani_Map_V3_Att_3.ccbi', flipX = -1},
			[DirEnum.DIR_UP_RIGHT]	 = {ccbi = 'Ani_Map_V3_Att_3.ccbi', flipX = 1},
			[DirEnum.DIR_DOWN_LEFT]	 = {ccbi = 'Ani_Map_V3_Att_1.ccbi', flipX = -1},
			[DirEnum.DIR_DOWN_RIGHT] = {ccbi = 'Ani_Map_V3_Att_1.ccbi', flipX = 1}
 		},
 		[ArmyCatogory.helicopter] ='Ani_Map_Bullet_Copter.ccbi'
 	},

 	SoundEffect_Attack =
 	{
 		[ArmyCatogory.infantry] = 'battle_fire_infantry',
 		[ArmyCatogory.tank] = 'battle_fire_tank',
 		[ArmyCatogory.missile] = 'battle_fire_missle',
 		[ArmyCatogory.helicopter] = 'battle_fire_helicopter'
 	},

	SoundEffect_Ready =
 	{
 		-- [ArmyCatogory.infantry] = 'battle_ready_infantry',
 		-- [ArmyCatogory.tank] = 'battle_fire_tank',
 		-- [ArmyCatogory.missile] = 'battle_fire_missle',
 		-- [ArmyCatogory.helicopter] = 'battle_fire_helicopter'
 	},

 	SoundEffect_Defense =
 	{
 		Fire = 'battle_fire_tower',
 		-- Show = 'battle_tower_show',
 		Ready = 'battle_ready_tower'
 	},

 	SoundEffect_Result =
 	{
 		Explode = 'battle_result_explode',
 		-- Burn = 'battle_result_burn',
 		-- Win = 'battle_result_win',
 		Cheer = 'battle_result_cheer'
 	},

 	Harm_ArmyMap =
 	{
 		[ArmyCatogory.infantry] 	= 'Ani_Map_Strikez_Copter.ccbi',
 		[ArmyCatogory.tank] 		= 'Ani_Map_Strikez_Tank.ccbi',
 		[ArmyCatogory.missile] 		= 'Ani_Map_Strikez_V3.ccbi',
 		[ArmyCatogory.helicopter] 	= 'Ani_Map_Strikez_Copter.ccbi'
 	},

 	Bullet_Offset =
 	{
 		[ArmyCatogory.helicopter] = {y = 20}
 	},

 	-- 爆炸
 	Explode_CCBFile =
 	{
		[World_pb.ATTACK_PLAYER] 				= 'Ani_Map_BaseExplode.ccbi',
		[World_pb.ATTACK_MONSTER] 				= 'Ani_Map_MonsterExplode.ccbi',
		[World_pb.MONSTER_MASS]					= 'Ani_Map_MonsterExplode.ccbi',
 		[World_pb.MASS] 						= 'Ani_Map_BaseExplode.ccbi',
 		[World_pb.MANOR_SINGLE]					= 'Ani_Map_BaseExplode.ccbi',
 		[World_pb.MANOR_MASS]					= 'Ani_Map_BaseExplode.ccbi',
 		[World_pb.MANOR_ASSISTANCE]				= 'Ani_Map_BaseExplode.ccbi',
 		[World_pb.MANOR_ASSISTANCE_MASS] 		= 'Ani_Map_BaseExplode.ccbi',
 		[World_pb.PRESIDENT_SINGLE]	 			= 'Ani_Map_BaseExplode.ccbi',
 		[World_pb.PRESIDENT_MASS] 				= 'Ani_Map_BaseExplode.ccbi',
 		[World_pb.PRESIDENT_ASSISTANCE]			= 'Ani_Map_BaseExplode.ccbi',
 		[World_pb.PRESIDENT_ASSISTANCE_MASS] 	= 'Ani_Map_BaseExplode.ccbi'
	},
 	-- 燃烧
 	Burn_CCBFile = 'Ani_Map_Burning.ccbi',

 	-- 不同目标占格数对应ccb文件
 	Attack_CCB =
 	{
 		[1] = AttackCCB_Grid_1,
 		[2] = AttackCCB_Grid_2,
 		[3] = AttackCCB_Grid_2,
 		[7] = AttackCCB_Grid_2
 	},

 	-- 防御工事
 	Defense_CCB =
 	{
 		[1] = DefenseCCB_Grid_1,
 		[2] = DefenseCCB_Grid_2,
 		[3] = DefenseCCB_Grid_2,
 		[7] = DefenseCCB_Grid_2
 	},
 	
 	Defense_CCB_Gold = 'Army_Defense_Gold1.ccbi',

 	Defense_CCB_Ani =
 	{
	 	[World_pb.GUILD_GUARD] 		= '201006',
	 	[World_pb.GUILD_TERRITORY] 	= '201006',
	 	[World_pb.KING_PALACE] 		= '201006'
 	},

 	Defense_CCB_Ani_Gold = 'WorldRes1007',

 	-- 不同类型不同占格数对应的防御工事位置偏移
 	-- @Attention: 援助到达后，若目标已易主，会发生战斗
 	Defense_CCB_Offset =
 	{
		[World_pb.GUILD_GUARD]				= RACcp(0, 50),
		[World_pb.GUILD_TERRITORY]			= RACcp(0, 50),
 		[World_pb.KING_PALACE] 				= RACcp(0, 300)
 	},

 	-- 各兵种对应ccb node
 	Attacker_AniNode =
 	{
 		[ArmyCatogory.infantry] 	= 'mAtt_Solo_Soldier',
 		[ArmyCatogory.tank] 		= 'mAtt_Solo_Tank',
 		[ArmyCatogory.missile] 		= 'mAtt_Solo_V3',
 		[ArmyCatogory.helicopter] 	= 'mAtt_Solo_Copter'
 	},

 	AircraftCrashType = 
 	{
 		CRASH_STAND  =  0, --最低点静止
 		CRASH_UP     =  1, --上升过程
 		CRASH_HIGH   =  2, --最高点
 		CRASH_DOWN   =  3 --下落过程

 	}
}

-- 获取需要预加载的ccbi名字列表，返回一个table
-- result = {name1 = [arg1, arg2] }
-- arg1 = {count = 1, colorParam = {}}
-- colorParam = {key = '', color = {r = 0, g = 0, b = 0}} or nil
function RABattleConfig:GetPreloadCCBFiles()
	local result = {}

	local targetCCBGroups =
	{
		AttackCCB_Grid_2,
		AttackCCB_Grid_1,
		DefenseCCB_Grid_2,
		DefenseCCB_Grid_1
	}
	for _, group in ipairs(targetCCBGroups) do
		for _, ccb in pairs(group) do
			result[ccb] =
			{
				-- 暂时不做变色相关处理
				-- {count = 1, colorParam = {color = {}}}
				{count = 1}
			}
		end
	end
	
	return result
end

return RABattleConfig