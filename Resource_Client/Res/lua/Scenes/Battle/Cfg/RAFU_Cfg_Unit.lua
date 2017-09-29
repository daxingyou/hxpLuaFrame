--[[
description: 战斗单元配置
author: zhenhui
date: 2016/11/22
]]--


local RAFU_Cfg_Unit = {
	[1]={ --灰熊坦克
		Bones = {--骨骼，可包含多个，但必须填 CoreBone 是哪一根
			['U_B_GrizzlyTank_UP'] = {
				BoneFrameCfgName = "B_F_GrizzlyTankUp",--RAFU_Cfg_Bone表的key值
				BoneFrameClass = "RAFU_Frame_Basic",--骨骼挂载的脚本
				CanSwitch = true,--是否可以旋转，比如坦克为true,大兵为false
				Zorder = 2,--层级结构，越大表示越靠上
				isTop = true,--是否上半部分，主要针对tank
				scale = 0.5,--缩放
				imageOffsetY = 8,
			},
            ['U_B_GrizzlyTank_DOWN'] = {
				BoneFrameCfgName = "B_F_GrizzlyTankDown",
				BoneFrameClass = "RAFU_Frame_Basic",
				CanSwitch = true,
				Zorder = 1,
				scale = 0.5,
				isTop = false,
				imageOffsetY = 8
			},
			CoreBone = "U_B_GrizzlyTank_DOWN" --主实体的骨骼ID，如坦克是底座，飞行兵是兵实体而不是影子,如果只有一个骨骼，则填自身骨骼
		},
		State = {--战斗单元所有的状态类型和脚本
			[STATE_TYPE.STATE_IDLE] = "RAFU_State_BaseIdle",
			[STATE_TYPE.STATE_ATTACK] = "RAFU_State_TankAttack",
			[STATE_TYPE.STATE_MOVE] = "RAFU_State_TankMove",			
			[STATE_TYPE.STATE_DEATH] = "RAFU_State_TankDie",
		},
		Weapon = "WP_GrizzlyTankWeapon",--携带的武器类型
        BloodCfg = {
            BloodBar = 4,--血条配置
            BloodPos = "0_-25" 
        },
        
		DieCfg= {
			dieActionTime = 0.1,--死亡序列帧的时间
			dieEffectTime = 2,--死亡特效的时间
			EffectCfg = "Fight_Ani_Behit_10",--死亡特效的RAFU_Cfg_Effect特效配置
			EffectClass = "RAFU_Effect_frameList"--死亡特效的类型，如ccb, 序列帧等
		},
	},
	[2]={ --磁暴坦克
		Bones = {
			['U_B_TeslaTank_UP'] = {
				BoneFrameCfgName = "B_F_TeslaTankUp",
				BoneFrameClass = "RAFU_Frame_Basic",
				CanSwitch = true,
				Zorder = 2,
				isTop = true,
				scale = 0.5,
				turnPeriod = 0.03,
				imageOffsetY = 12

			},
            ['U_B_TeslaTank_DOWN'] = {
				BoneFrameCfgName = "B_F_TeslaTankDown",
				BoneFrameClass = "RAFU_Frame_Basic",
				CanSwitch = true,
				Zorder = 1,
				scale = 0.5,
				isTop = false,
				imageOffsetY = 12
			},
			CoreBone = "U_B_TeslaTank_DOWN" --主实体的骨骼ID，如坦克是底座，飞行兵是兵实体而不是影子,如果只有一个骨骼，则填自身骨骼
		},
		State = {
			[STATE_TYPE.STATE_IDLE] = "RAFU_State_BaseIdle",
			[STATE_TYPE.STATE_ATTACK] = "RAFU_State_TankAttack",
			[STATE_TYPE.STATE_MOVE] = "RAFU_State_TankMove",			
			[STATE_TYPE.STATE_DEATH] = "RAFU_State_TankDie",
		},
		Weapon = "WP_TeslaTankWeapon",
        BloodCfg = {
            BloodBar = 4,--血条配置
            BloodPos = "0_-15" 
        },
		DieCfg= {
			dieActionTime = 0.1,
			dieEffectTime = 1,
			EffectCfg = "Fight_Ani_Death_Machine_2",
			EffectClass = "RAFU_Effect_frameList"
		},
	},
	[3]={ --天启坦克
		Bones = {
			['U_B_ApocalypseTank_UP'] = {
				BoneFrameCfgName = "B_F_ApocalypseTankUp",
				BoneFrameClass = "RAFU_Frame_Basic",
				CanSwitch = true,
				Zorder = 2,
				isTop = true,
				scale = 0.5,
				turnPeriod = 0.03,
				imageOffsetY = 10

			},
            ['U_B_ApocalypseTank_DOWN'] = {
				BoneFrameCfgName = "B_F_ApocalypseTankDown",
				BoneFrameClass = "RAFU_Frame_Basic",
				CanSwitch = true,
				Zorder = 1,
				scale = 0.5,
				isTop = false,
				imageOffsetY = 10
			},
			CoreBone = "U_B_ApocalypseTank_DOWN" --主实体的骨骼ID，如坦克是底座，飞行兵是兵实体而不是影子,如果只有一个骨骼，则填自身骨骼
		},
		State = {
			[STATE_TYPE.STATE_IDLE] = "RAFU_State_BaseIdle",
			[STATE_TYPE.STATE_ATTACK] = "RAFU_State_TankAttack",
			[STATE_TYPE.STATE_MOVE] = "RAFU_State_TankMove",			
			[STATE_TYPE.STATE_DEATH] = "RAFU_State_TankDie",
		},
		Weapon = "WP_ApocalypseTankWeapon",
        BloodCfg = {
            BloodBar = 4,--血条配置
            BloodPos = "0_-25" 
        },
		DieCfg= {
			dieActionTime = 0.1,
			dieEffectTime = 2,
			EffectCfg = "Fight_Ani_Death_Machine_1",
			EffectClass = "RAFU_Effect_frameList"
		},
		AfterDieCfg= {
			EffectCfg = "Bulllt_Effect_Build_Surface",
			EffectClass = "RAFU_Effect_surface"
		},		
	},
	[63]={ --坦克杀手
		Bones = {
            ['U_B_TankDestroyerDown'] = {
				BoneFrameCfgName = "B_F_TankDestroyerDown",
				BoneFrameClass = "RAFU_Frame_Basic",
				CanSwitch = true,
				Zorder = 1,
				scale = 1,
				isTop = false,
				imageOffsetY = 30
			},
			CoreBone = "B_F_TankDestroyerDown" --主实体的骨骼ID，如坦克是底座，飞行兵是兵实体而不是影子,如果只有一个骨骼，则填自身骨骼
		},
		State = {
			[STATE_TYPE.STATE_IDLE] = "RAFU_State_BaseIdle",
			[STATE_TYPE.STATE_ATTACK] = "RAFU_State_AmericanAttack",
			[STATE_TYPE.STATE_MOVE] = "RAFU_State_TankMove",			
			[STATE_TYPE.STATE_DEATH] = "RAFU_State_TankDie",
		},
		Weapon = "WP_TankDestroyerWeapon",
        BloodCfg = {
            BloodBar = 4,--血条配置
            BloodPos = "0_-25" 
        },
		DieCfg= {
			dieActionTime = 0.1,
			dieEffectTime = 2,
			EffectCfg = "Fight_Ani_Death_Machine_1",
			EffectClass = "RAFU_Effect_frameList"
		},
		AfterDieCfg= {
			EffectCfg = "Bulllt_Effect_Build_Surface",
			EffectClass = "RAFU_Effect_surface"
		},		
	},
	[64]={ --冷冻车
		Bones = {
            ['B_F_FreezerTank'] = {
				BoneFrameCfgName = "B_F_FreezerTank",
				BoneFrameClass = "RAFU_Frame_Basic",
				CanSwitch = true,
				Zorder = 1,
				scale = 1,
				isTop = false,
				imageOffsetY = 0
			},
			CoreBone = "B_F_FreezerTank" --主实体的骨骼ID，如坦克是底座，飞行兵是兵实体而不是影子,如果只有一个骨骼，则填自身骨骼
		},
		State = {
			[STATE_TYPE.STATE_IDLE] = "RAFU_State_BaseIdle",
			[STATE_TYPE.STATE_ATTACK] = "RAFU_State_TankAttack",
			[STATE_TYPE.STATE_MOVE] = "RAFU_State_TankMove",			
			[STATE_TYPE.STATE_DEATH] = "RAFU_State_TankDie",
		},
		Weapon = "WP_FreezerTankWeapon",
        BloodCfg = {
            BloodBar = 4,--血条配置
            BloodPos = "0_-25" 
        },
		DieCfg= {
			dieActionTime = 0.1,
			dieEffectTime = 2,
			EffectCfg = "Fight_Ani_Death_Machine_1",
			EffectClass = "RAFU_Effect_frameList"
		},
		AfterDieCfg= {
			EffectCfg = "Bulllt_Effect_Build_Surface",
			EffectClass = "RAFU_Effect_surface"
		},		
	},
	[68]={ --幻影坦克
		Bones = {
            ['U_B_MirageTankDown'] = {
				BoneFrameCfgName = "B_F_MirageTankDown",
				BoneFrameClass = "RAFU_Frame_Basic",
				CanSwitch = true,
				Zorder = 1,
				scale = 1,
				isTop = false,
				imageOffsetY = 0
			},
			CoreBone = "B_F_MirageTankDown" --主实体的骨骼ID，如坦克是底座，飞行兵是兵实体而不是影子,如果只有一个骨骼，则填自身骨骼
		},
		State = {
			[STATE_TYPE.STATE_IDLE] = "RAFU_State_BaseIdle",
			[STATE_TYPE.STATE_ATTACK] = "RAFU_State_TankAttack",
			[STATE_TYPE.STATE_MOVE] = "RAFU_State_TankMove",			
			[STATE_TYPE.STATE_DEATH] = "RAFU_State_TankDie",
		},
		Weapon = "WP_MirageTankWeapon",
        BloodCfg = {
            BloodBar = 4,--血条配置
            BloodPos = "0_-25" 
        },
		DieCfg= {
			dieActionTime = 0.1,
			dieEffectTime = 2,
			EffectCfg = "Fight_Ani_Death_Machine_1",
			EffectClass = "RAFU_Effect_frameList"
		},
		AfterDieCfg= {
			EffectCfg = "Bulllt_Effect_Build_Surface",
			EffectClass = "RAFU_Effect_surface"
		},		
	},
	[61]={ --战斗要塞
		Bones = {
            ['U_B_BattleFortressDown'] = {
				BoneFrameCfgName = "B_F_BattleFortressDown",
				BoneFrameClass = "RAFU_Frame_Basic",
				CanSwitch = true,
				Zorder = 1,
				scale = 1,
				isTop = false,
				imageOffsetY = 20
			},
			CoreBone = "B_F_BattleFortressDown" --主实体的骨骼ID，如坦克是底座，飞行兵是兵实体而不是影子,如果只有一个骨骼，则填自身骨骼
		},
		State = {
			[STATE_TYPE.STATE_IDLE] = "RAFU_State_BaseIdle",
			[STATE_TYPE.STATE_ATTACK] = "RAFU_State_TankAttack",
			[STATE_TYPE.STATE_MOVE] = "RAFU_State_TankMove",			
			[STATE_TYPE.STATE_DEATH] = "RAFU_State_TankDie",
		},
		Weapon = "WP_AmericanSoldierWeapon",
        BloodCfg = {
            BloodBar = 4,--血条配置
            BloodPos = "0_-25" 
        },
		DieCfg= {
			dieActionTime = 0.1,
			dieEffectTime = 2,
			EffectCfg = "Fight_Ani_Death_Machine_1",
			EffectClass = "RAFU_Effect_frameList"
		},
		AfterDieCfg= {
			EffectCfg = "Bulllt_Effect_Build_Surface",
			EffectClass = "RAFU_Effect_surface"
		},		
	},
	[4]={ --美国大兵
		Bones = {
			['U_B_AmericanSoldier_UP'] = {
				BoneFrameCfgName = "B_F_AmericanSoldier",
				BoneFrameClass = "RAFU_Frame_Basic",
				CanSwitch = false,
				Zorder = 2,
				isTop = false,
				scale = 1.0,
				imageOffsetY = 0
			},
			CoreBone = "U_B_AmericanSoldier_UP" --主实体的骨骼ID，如坦克是底座，飞行兵是兵实体而不是影子,如果只有一个骨骼，则填自身骨骼
		},
		State = {
			[STATE_TYPE.STATE_IDLE] = "RAFU_State_BaseIdle",
			[STATE_TYPE.STATE_ATTACK] = "RAFU_State_AmericanAttack",
			[STATE_TYPE.STATE_MOVE] = "RAFU_State_AmericanMove",			
			[STATE_TYPE.STATE_DEATH] = "RAFU_State_SoldierDie",
		},
		Weapon = "WP_AmericanSoldierWeapon_new",
        BloodCfg = {
            BloodBar = 5,--血条配置
            BloodPos = "0_-10" 
        },
		DieCfg= {
			dieActionTime = 0.6,--死亡序列帧的时间
			dieEffectTime = 1,--死亡特效的时间
			EffectCfg = {"Fight_Ani_Death_Buff_1","Fight_Ani_Death_Buff_2","Fight_Ani_Death_Buff_3"},--死亡特效的RAFU_Cfg_Effect特效配置 ,1 电死，2 烧死， 3 辐射死
			EffectClass = "RAFU_Effect_frameList"--死亡特效的类型，如ccb, 序列帧等
		}
	},
	[5]={ --尤里新兵
		Bones = {
			['U_B_Initiate_UP'] = {
				BoneFrameCfgName = "B_F_Initiate",
				BoneFrameClass = "RAFU_Frame_Basic",
				CanSwitch = false,
				Zorder = 2,
				isTop = false,
				scale = 1.0,
				imageOffsetY = 0
			},
			CoreBone = "U_B_Initiate_UP" --主实体的骨骼ID，如坦克是底座，飞行兵是兵实体而不是影子,如果只有一个骨骼，则填自身骨骼
		},
		State = {
			[STATE_TYPE.STATE_IDLE] = "RAFU_State_BaseIdle",
			[STATE_TYPE.STATE_ATTACK] = "RAFU_State_BaseAttack",
			[STATE_TYPE.STATE_MOVE] = "RAFU_State_BaseMove",			
			[STATE_TYPE.STATE_DEATH] = "RAFU_State_BaseDie",
		},
		Weapon = "WP_InitiateWeapon",
        BloodCfg = {
            BloodBar = 5,--血条配置
            BloodPos = "0_-10" 
        },
		DieCfg= {
			dieActionTime = 0.4,
			dieEffectTime = 0.5
		}
	},
	[6]={ --狂兽人
		Bones = {
			['U_B_Brute_UP'] = {
				BoneFrameCfgName = "B_F_Brute",
				BoneFrameClass = "RAFU_Frame_Basic",
				CanSwitch = false,
				Zorder = 2,
				isTop = false,
				scale = 1.3,
				imageOffsetY = 0
			},
			CoreBone = "U_B_Brute_UP" --主实体的骨骼ID，如坦克是底座，飞行兵是兵实体而不是影子,如果只有一个骨骼，则填自身骨骼
		},
		State = {
			[STATE_TYPE.STATE_IDLE] = "RAFU_State_BaseIdle",
			[STATE_TYPE.STATE_ATTACK] = "RAFU_State_SoldierAttack",
			[STATE_TYPE.STATE_MOVE] = "RAFU_State_BaseMove",			
			[STATE_TYPE.STATE_DEATH] = "RAFU_State_BaseDie",
		},
		Weapon = "WP_BruteWeapon",
        BloodCfg = {
            BloodBar = 5,--血条配置
            BloodPos = "0_0" 
        },
		DieCfg= {
			dieActionTime = 0.4,
			dieEffectTime = 0.5
		}
	},

	[7]={ --基洛夫飞艇
		Bones = {
			['U_B_KirovAirship_UP'] = {
				BoneFrameCfgName = "B_F_KirovAirshipUp",
				BoneFrameClass = "RAFU_Frame_Aircraft",
				CanSwitch = true,
				Zorder = 2,
				isTop = true,
				scale = 1.0,
				imageOffsetY = 100,
				offsetY = 100,
				crashUpTime = 2,
				turnPeriod = 0.2

			},
            ['U_B_KirovAirship_Down'] = {
				BoneFrameCfgName = "B_F_KirovAirshipDown",
				BoneFrameClass = "RAFU_Frame_Shadow",
				CanSwitch = true,
				Zorder = 1,
				scale = 1.0,
				isTop = false,
				dieShadowScale = 1.5,--飞行单位死亡影子下落缩放比例
			},
			CoreBone = "U_B_KirovAirship_UP" --主实体的骨骼ID，如坦克是底座，飞行兵是兵实体而不是影子,如果只有一个骨骼，则填自身骨骼
		},
		State = {
			[STATE_TYPE.STATE_IDLE] = "RAFU_State_BaseIdle",
			[STATE_TYPE.STATE_ATTACK] = "RAFU_State_ZepAttack",
			[STATE_TYPE.STATE_MOVE] = "RAFU_State_BaseMove",			
			[STATE_TYPE.STATE_DEATH] = "RAFU_State_ZepDie",
		},
		Weapon = "WP_ZepWeapon",
        BloodCfg = {
            BloodBar = 4,--血条配置
            BloodPos = "0_100" 
        },
		DieCfg= {
			dieActionTime = 2,
			dieEffectTime = 3,
			EffectCfg = "Fight_Ani_Death_Machine_1",
			EffectClass = "RAFU_Effect_frameList"
		},
	},

	[8]={ --黑鹰战机
		Bones = {
			['U_B_BlackEagle_UP'] = {
				BoneFrameCfgName = "B_F_BlackEagleUp",
				BoneFrameClass = "RAFU_Frame_Basic",
				CanSwitch = true,
				Zorder = 2,
				isTop = true,
				scale = 1.0,
				turnPeriod = 0.03

			},
            ['U_B_BlackEagle_Down'] = {
				BoneFrameCfgName = "B_F_BlackEagleDown",
				BoneFrameClass = "RAFU_Frame_Basic",
				CanSwitch = true,
				Zorder = 1,
				scale = 1.0,
				isTop = false,
			},
			CoreBone = "U_B_BlackEagle_UP" --主实体的骨骼ID，如坦克是底座，飞行兵是兵实体而不是影子,如果只有一个骨骼，则填自身骨骼
		},
		State = {
			[STATE_TYPE.STATE_IDLE] = "RAFU_State_BaseIdle",
			[STATE_TYPE.STATE_ATTACK] = "RAFU_State_TankAttack",
			[STATE_TYPE.STATE_MOVE] = "RAFU_State_TankMove",			
			[STATE_TYPE.STATE_DEATH] = "RAFU_State_TankDie",
		},
		Weapon = "WP_TankWeapon",
        BloodCfg = {
            BloodBar = 4,--血条配置
            BloodPos = "0_-25" 
        },
		DieCfg= {
			dieActionTime = 0.1,
			dieEffectTime = 0.4,
			EffectCfg = "Fight_Ani_Death_Machine_1",
			EffectClass = "RAFU_Effect_frameList"
		},
	},

	[9]={ --飞行兵
		Bones = {
			['U_B_Rocketeer_UP'] = {
				BoneFrameCfgName = "B_F_RocketeerUp",
				BoneFrameClass = "RAFU_Frame_Aircraft",
				CanSwitch = false,
				Zorder = 2,
				isTop = true,
				scale = 1.0,
				turnPeriod = 0.23,
				imageOffsetY = 50,
				frameNum = 8,
				offsetY = 50

			},
            ['U_B_Rocketeer_Down'] = {
				BoneFrameCfgName = "B_F_RocketeerDown",
				BoneFrameClass = "RAFU_Frame_Basic",
				CanSwitch = false,
				Zorder = 1,
				scale = 1.0,
				turnPeriod = 0.23,
				isTop = false,
			},
			CoreBone = "U_B_Rocketeer_UP" --主实体的骨骼ID，如坦克是底座，飞行兵是兵实体而不是影子,如果只有一个骨骼，则填自身骨骼
		},
		State = {
			[STATE_TYPE.STATE_IDLE] = "RAFU_State_BaseIdle",
			[STATE_TYPE.STATE_ATTACK] = "RAFU_State_SoldierAttack",
			[STATE_TYPE.STATE_MOVE] = "RAFU_State_JumpMove",			
			[STATE_TYPE.STATE_DEATH] = "RAFU_State_JumpDie",
		},
		Weapon = "WP_AmericanSoldierWeapon",
        BloodCfg = {
            BloodBar = 5,--血条配置
            BloodPos = "0_35" 
        },
		DieCfg= {
			dieActionTime = 0.5,
			dieEffectTime = 0.1,
			EffectCfg = "Fight_Ani_Death_Machine_3",
			EffectClass = "RAFU_Effect_frameList"
		},
	},
	[10]={ --鲍里斯
		Bones = {
			['U_B_Boris_UP'] = {
				BoneFrameCfgName = "B_F_BorisUp",
				BoneFrameClass = "RAFU_Frame_Basic",
				CanSwitch = false,
				Zorder = 1,
				isTop = false,
				scale = 1.0,
				turnPeriod = 0.03
			},
			['U_B_BorisBadge_Down'] = {
				BoneFrameCfgName = "B_F_BorisBadgeDown",
				BoneFrameClass = "RAFU_Frame_Basic",
				CanSwitch = false,
				Zorder = 2,
				scale = 0.8,
				turnPeriod = 0.23,
				isTop = false,
				imageOffsetY = 50,
			},
			CoreBone = "U_B_Boris_UP" --
		},
		State = {
			[STATE_TYPE.STATE_IDLE] = "RAFU_State_BaseIdle",
			[STATE_TYPE.STATE_ATTACK] = "RAFU_State_BaseAttack",
			[STATE_TYPE.STATE_MOVE] = "RAFU_State_BaseMove",			
			[STATE_TYPE.STATE_DEATH] = "RAFU_State_BaseDie",
			[STATE_TYPE.STATE_CREATE] = "RAFU_State_BorisCreate",--鲍里斯的技能，单独创建轰炸机单元逻辑
		},
		Weapon = "WP_AmericanSoldierWeapon",
        BloodCfg = {
            BloodBar = 5,--血条配置
            BloodPos = "0_-25" 
        },
		DieCfg= {
			dieActionTime = 0.3,
			dieEffectTime = 0.2,
		},
	},
	[11]={ --电磁塔
		Bones = {
            ['B_F_TeslaCoilDown'] = {
				BoneFrameCfgName = "B_F_TeslaCoilDown",
				BoneFrameClass = "RAFU_Frame_Basic",
				CanSwitch = false,
				Zorder = 1,
				scale = 1.0,
				isTop = false,
				imageOffsetY = 0
			},
		},
		State = {
			[STATE_TYPE.STATE_IDLE] = "RAFU_State_BuildingIdle",
			[STATE_TYPE.STATE_ATTACK] = "RAFU_State_BuildingPrepareAttack",
			[STATE_TYPE.STATE_MOVE] = "RAFU_State_TankMove",			
			[STATE_TYPE.STATE_DEATH] = "RAFU_State_TankDie",
		},
		Weapon = "WP_TeslaCoilWeapon",
        BloodCfg = {
            BloodBar = 3,--血条配置
            BloodPos = "0_85" 
        },
		DieCfg= {
			dieActionTime = 0.1,
			dieEffectTime = 3,
			EffectCfg = "Fight_Ani_Death_Building_3",
			EffectClass = "RAFU_Effect_ccb",
			offsetY = 15
		},
		DestoryBuff = {
			['Fight_Ani_Buff_Effect_3'] = RACcp(0,10),
		},
		AfterDieCfg= {
			EffectCfg = "Bulllt_Effect_Build_Surface",
			EffectClass = "RAFU_Effect_surface"
		},		
	},
	[13]={ --苏俄基地
		Bones = {
            ['B_F_ConstructionYardDown'] = {
				BoneFrameCfgName = "B_F_ConstructionYardDown",
				BoneFrameClass = "RAFU_Frame_Basic",
				CanSwitch = false,
				Zorder = 1,
				scale = 1.0,
				isTop = false,
				imageOffsetY = 0
			},
			CoreBone = "B_F_ConstructionYardDown"
		},
		State = {
			[STATE_TYPE.STATE_IDLE] = "RAFU_State_BuildingIdle",	
			[STATE_TYPE.STATE_DEATH] = "RAFU_State_TankDie",	
		},
		Weapon = "WP_TeslaCoilWeapon",
        BloodCfg = {
            BloodBar = 1,--血条配置
            BloodPos = "0_80" 
        },
		DestoryBuff = {
			['Fight_Ani_Buff_Effect_3'] = RACcp(0,20),
			['Fight_Ani_Buff_Effect_4'] = RACcp(30,50),
			['Fight_Ani_Buff_Effect_5'] = RACcp(-50,70),
		},
		DieCfg= {
			dieActionTime = 0.1,
			dieEffectTime = 3.3,
			EffectCfg = "Fight_Ani_Death_Building_1",
			EffectClass = "RAFU_Effect_ccb",
			offsetY = 0,
			offsetX = -20
		},
		AfterDieCfg= {
			EffectCfg = "Bulllt_Effect_Build_Surface",
			EffectClass = "RAFU_Effect_surface"
		},				
	},
	[20]={ --尤里基地
		Bones = {
            ['B_F_YuriConstructionYardDown'] = {
				BoneFrameCfgName = "B_F_YuriConstructionYardDown",
				BoneFrameClass = "RAFU_Frame_Basic",
				CanSwitch = false,
				Zorder = 1,
				scale = 1.0,
				isTop = false,
				imageOffsetY = 0
			},
			CoreBone = "B_F_YuriConstructionYardDown"
		},
		State = {
			[STATE_TYPE.STATE_IDLE] = "RAFU_State_BuildingIdle",	
			[STATE_TYPE.STATE_DEATH] = "RAFU_State_TankDie",	
		},
		Weapon = "WP_TeslaCoilWeapon",
        BloodCfg = {
            BloodBar = 1,--血条配置
            BloodPos = "0_80" 
        },
		DestoryBuff = {
			['Fight_Ani_Buff_Effect_3'] = RACcp(0,20),
			['Fight_Ani_Buff_Effect_4'] = RACcp(30,50),
			['Fight_Ani_Buff_Effect_5'] = RACcp(-50,70),
		},
		DieCfg= {
			dieActionTime = 0.1,
			dieEffectTime = 3.3,
			EffectCfg = "Fight_Ani_Death_Building_1",
			EffectClass = "RAFU_Effect_ccb",
			offsetY = 0,
			offsetX = -20
		},
		AfterDieCfg= {
			EffectCfg = "Bulllt_Effect_Build_Surface",
			EffectClass = "RAFU_Effect_surface"
		},				
	},
	[19]={ --v3炮弹
		Bones = {
			['U_B_V3Bullet_UP'] = {
				BoneFrameCfgName = "B_F_V3Bullet",
				BoneFrameClass = "RAFU_Frame_Basic",
				CanSwitch = false,
				Zorder = 2,
				isTop = false,
				scale = 1.0,
				imageOffsetY = 0
			},
			CoreBone = "U_B_V3Bullet_UP" --主实体的骨骼ID，如坦克是底座，飞行兵是兵实体而不是影子,如果只有一个骨骼，则填自身骨骼
		},
		State = {
			[STATE_TYPE.STATE_IDLE] = "RAFU_State_BaseIdle",			
			[STATE_TYPE.STATE_FLY] = "RAFU_State_WarheadV3Fly",
			[STATE_TYPE.STATE_ATTACK] = "RAFU_State_BaseAttack",
			[STATE_TYPE.STATE_DEATH] = "RAFU_State_WarheadV3Die",
			[STATE_TYPE.STATE_DISAPPEAR] = "RAFU_State_BaseDisapear",--子弹的消失状态
		},
		Weapon = "WP_V3WarheadWeapon",
        BloodCfg = {
            BloodBar = 5,--血条配置
            BloodPos = "0_-25" 
        },
		DieCfg= {
			dieActionTime = 0.2,
			dieEffectTime = 0.1,
			EffectCfg = "Fight_Ani_Death_Machine_3",
			EffectClass = "RAFU_Effect_frameList"
		},
		FlyEndCfg= {							-- 飞行完毕后播放的爆炸特效
			effectClass = "RAFU_Effect_frameList",
			effectCfgName = "Fight_Ani_Behit_5",
		},
	},
	[18]={ --V3
		Bones = {
			['U_B_V3Car_Down'] = {
				BoneFrameCfgName = "B_F_V3CarDown",
				BoneFrameClass = "RAFU_Frame_Basic",
				CanSwitch = true,
				Zorder = 1,
				isTop = false,
				scale = 1.0,
				turnPeriod = 0.23,
			},
			['U_B_V3Car_Up'] = {
				BoneFrameCfgName = "B_F_V3CarUp",
				BoneFrameClass = "RAFU_Frame_Basic",
				CanSwitch = true,
				Zorder = 2,
				isTop = false,
				scale = 1.0,
				turnPeriod = 0.23,
			},
			CoreBone = "U_B_V3Car_Down" --主实体的骨骼ID，如坦克是底座，飞行兵是兵实体而不是影子,如果只有一个骨骼，则填自身骨骼
		},
		State = {
			[STATE_TYPE.STATE_IDLE] = "RAFU_State_BaseIdle",
			[STATE_TYPE.STATE_MOVE] = "RAFU_State_TankMove",			
			[STATE_TYPE.STATE_DEATH] = "RAFU_State_TankDie",
			[STATE_TYPE.STATE_CREATE] = "RAFU_State_V3Create",
		},
		Weapon = "WP_AmericanSoldierWeapon",
        BloodCfg = {
            BloodBar = 4,--血条配置
            BloodPos = "0_-25" 
        },
		DieCfg= {
			dieActionTime = 0.5,
			dieEffectTime = 0.1,
			EffectCfg = "Fight_Ani_Death_Machine_3",
			EffectClass = "RAFU_Effect_frameList"
		},
	},	
	[14]={ --哨戒炮
		Bones = {
            ['B_F_GattlingCannonDown'] = {
				BoneFrameCfgName = "B_F_GattlingCannonDown",
				BoneFrameClass = "RAFU_Frame_Basic",
				CanSwitch = false,
				Zorder = 1,
				scale = 1.0,
				isTop = true,
				imageOffsetY = -10,
				imageOffsetX = -5
			},
			CoreBone = "B_F_GattlingCannonDown"
		},
		State = {
			[STATE_TYPE.STATE_IDLE] = "RAFU_State_BaseIdle",
			[STATE_TYPE.STATE_ATTACK] = "RAFU_State_TankAttack",	
			[STATE_TYPE.STATE_DEATH] = "RAFU_State_TankDie",	
		},
		Weapon = "WP_GattlingCannonWeapon",
        BloodCfg = {
            BloodBar = 3,--血条配置
            BloodPos = "0_20" 
        },
		DestoryBuff = {
			['Fight_Ani_Buff_Effect_4'] = RACcp(0,0),
		},
		DieCfg= {
			dieActionTime = 0.1,
			dieEffectTime = 3,
			EffectCfg = "Fight_Ani_Death_Building_4",
			EffectClass = "RAFU_Effect_ccb",
			offsetY = -4,
			offsetX = 2
		},
		AfterDieCfg= {
			EffectCfg = "Bulllt_Effect_Build_Surface",
			EffectClass = "RAFU_Effect_surface"
		},	
	},
	[36]={ --盖特机炮
		Bones = {
            ['B_F_YuriGattlingCannonDown'] = {
				BoneFrameCfgName = "B_F_YuriGattlingCannonDown",
				BoneFrameClass = "RAFU_Frame_Basic",
				CanSwitch = false,
				Zorder = 1,
				scale = 1.0,
				isTop = true,
				imageOffsetY = -10,
				imageOffsetX = -5
			},
			CoreBone = "B_F_YuriGattlingCannonDown"
		},
		State = {
			[STATE_TYPE.STATE_IDLE] = "RAFU_State_BaseIdle",
			[STATE_TYPE.STATE_ATTACK] = "RAFU_State_TankAttack",	
			[STATE_TYPE.STATE_DEATH] = "RAFU_State_TankDie",	
		},
		Weapon = "WP_GattlingCannonWeapon",
        BloodCfg = {
            BloodBar = 3,--血条配置
            BloodPos = "0_25" 
        },
		DestoryBuff = {
			['Fight_Ani_Buff_Effect_4'] = RACcp(0,0),
		},
		DieCfg= {
			dieActionTime = 0.1,
			dieEffectTime = 3,
			EffectCfg = "Fight_Ani_Death_Building_4",
			EffectClass = "RAFU_Effect_ccb",
			offsetY = -4,
			offsetX = 2
		},
		AfterDieCfg= {
			EffectCfg = "Bulllt_Effect_Build_Surface",
			EffectClass = "RAFU_Effect_surface"
		},	
	},
	[26]={ --防空炮
		Bones = {
            ['B_F_FlakCannonDown'] = {
				BoneFrameCfgName = "B_F_FlakCannonDown",
				BoneFrameClass = "RAFU_Frame_Basic",
				CanSwitch = false,
				Zorder = 1,
				scale = 1.0,
				isTop = true,
				imageOffsetY = -10,
				imageOffsetX = -5
			},
			CoreBone = "B_F_FlakCannonDown"
		},
		State = {
			[STATE_TYPE.STATE_IDLE] = "RAFU_State_BaseIdle",
			[STATE_TYPE.STATE_ATTACK] = "RAFU_State_TankAttack",	
			[STATE_TYPE.STATE_DEATH] = "RAFU_State_TankDie",	
		},
		Weapon = "WP_FlakCannonWeapon",
        BloodCfg = {
            BloodBar = 3,--血条配置
            BloodPos = "0_40" 
        },
		DestoryBuff = {
			['Fight_Ani_Buff_Effect_4'] = RACcp(0,0),
		},
		DieCfg= {
			dieActionTime = 0.1,
			dieEffectTime = 3,
			EffectCfg = "Fight_Ani_Death_Building_4",
			EffectClass = "RAFU_Effect_ccb",
			offsetY = 0
		},
		AfterDieCfg= {
			EffectCfg = "Bulllt_Effect_Build_Surface",
			EffectClass = "RAFU_Effect_surface"
		},	
	},
	-- [15]={ --苏俄战斗碉堡
	-- 	Bones = {
 --            ['B_F_TankBunkerDown'] = {
	-- 			BoneFrameCfgName = "B_F_TankBunkerDown",
	-- 			BoneFrameClass = "RAFU_Frame_Basic",
	-- 			CanSwitch = false,
	-- 			Zorder = 1,
	-- 			scale = 1.0,
	-- 			isTop = false,
	-- 			imageOffsetY = 0
	-- 		},
	-- 		CoreBone = "B_F_TankBunkerDown"
	-- 	},
	-- 	State = {
	-- 		[STATE_TYPE.STATE_IDLE] = "RAFU_State_BuildingIdle",	
	-- 		[STATE_TYPE.STATE_DEATH] = "RAFU_State_TankDie",	
	-- 	},
	-- 	Weapon = "WP_TeslaCoilWeapon",
	-- 	DestoryBuff = {
	-- 		['Fight_Ani_Buff_Effect_3'] = RACcp(0,0),
	-- 		['Fight_Ani_Buff_Effect_4'] = RACcp(10,10),
	-- 		['Fight_Ani_Buff_Effect_5'] = RACcp(-20,20),
	-- 	},
	-- 	DieCfg= {
	-- 		dieActionTime = 0.1,
	-- 		dieEffectTime = 0.4,
	-- 		EffectCfg = "Fight_Ani_Death_Machine_1",
	-- 		EffectClass = "RAFU_Effect_frameList"
	-- 	},
	-- 	AfterDieCfg= {
	-- 		EffectCfg = "Bulllt_Effect_Build_Surface",
	-- 		EffectClass = "RAFU_Effect_surface"
	-- 	},	
	-- },
	[16]={ --苏俄发电厂
		Bones = {
            ['B_F_TeslaReactorDown'] = {
				BoneFrameCfgName = "B_F_TeslaReactorDown",
				BoneFrameClass = "RAFU_Frame_Basic",
				CanSwitch = false,
				Zorder = 1,
				scale = 1.0,
				isTop = false,
				imageOffsetY = -13,
				imageOffsetX = 0

			},
			CoreBone = "B_F_TeslaReactorDown"
		},
		State = {
			[STATE_TYPE.STATE_IDLE] = "RAFU_State_BuildingIdle",	
			[STATE_TYPE.STATE_DEATH] = "RAFU_State_TankDie",	
		},
		Weapon = "WP_TeslaCoilWeapon",
        BloodCfg = {
            BloodBar = 2,--血条配置
            BloodPos = "0_80" 
        },
		DestoryBuff = {
			['Fight_Ani_Buff_Effect_3'] = RACcp(0,0),
			['Fight_Ani_Buff_Effect_4'] = RACcp(5,5),
			['Fight_Ani_Buff_Effect_5'] = RACcp(-15,20),
		},
		DieCfg= {
			dieActionTime = 0.1,
			dieEffectTime = 3,
			EffectCfg = "Fight_Ani_Death_Building_2",
			EffectClass = "RAFU_Effect_ccb",
			offsetY = 10,
			offsetX = -30
		},
		AfterDieCfg= {
			EffectCfg = "Bulllt_Effect_Build_Surface",
			EffectClass = "RAFU_Effect_surface"
		},		
	},
	[12]={ --尤里发电厂
		Bones = {
            ['B_F_YuriTeslaReactorDown'] = {
				BoneFrameCfgName = "B_F_YuriTeslaReactorDown",
				BoneFrameClass = "RAFU_Frame_Basic",
				CanSwitch = false,
				Zorder = 1,
				scale = 1.0,
				isTop = false,
				imageOffsetY = -13,
				imageOffsetX = 0

			},
			CoreBone = "B_F_YuriTeslaReactorDown"
		},
		State = {
			[STATE_TYPE.STATE_IDLE] = "RAFU_State_BuildingIdle",	
			[STATE_TYPE.STATE_DEATH] = "RAFU_State_TankDie",	
		},
		Weapon = "WP_TeslaCoilWeapon",
        BloodCfg = {
            BloodBar = 2,--血条配置
            BloodPos = "0_100" 
        },
		DestoryBuff = {
			['Fight_Ani_Buff_Effect_3'] = RACcp(0,0),
			['Fight_Ani_Buff_Effect_4'] = RACcp(5,5),
			['Fight_Ani_Buff_Effect_5'] = RACcp(-15,20),
		},
		DieCfg= {
			dieActionTime = 0.1,
			dieEffectTime = 3,
			EffectCfg = "Fight_Ani_Death_Building_2",
			EffectClass = "RAFU_Effect_ccb",
			offsetY = 10,
			offsetX = -30
		},
		AfterDieCfg= {
			EffectCfg = "Bulllt_Effect_Build_Surface",
			EffectClass = "RAFU_Effect_surface"
		},		
	},
	[17]={ --旗帜
		Bones = {
	        ['B_F_FlagDown'] = {
				BoneFrameCfgName = "B_F_FlagDown",
				BoneFrameClass = "RAFU_Frame_Basic",
				CanSwitch = false,
				Zorder = 1,
				scale = 1.0,
				isTop = false,
				imageOffsetY = -5
			},
			CoreBone = "B_F_FlagDown"
		},
		State = {
			[STATE_TYPE.STATE_IDLE] = "RAFU_State_BuildingIdle",	
			[STATE_TYPE.STATE_DEATH] = "RAFU_State_TankDie",	
		},
		Weapon = "WP_TeslaCoilWeapon",
        BloodCfg = {
            BloodBar = 3,--血条配置
            BloodPos = "0_110" 
        },
		DieCfg= {
			dieActionTime = 0.1,
			dieEffectTime = 2,
			EffectCfg = "Fight_Ani_Death_Machine_2",
			EffectClass = "RAFU_Effect_frameList",
			offsetY = 0
		},
		AfterDieCfg= {
			EffectCfg = "Bulllt_Effect_Build_Surface",
			EffectClass = "RAFU_Effect_surface"
		},	
	},

[38]={ --恐怖机器人 bls
		Bones = {--骨骼，可包含多个，但必须填 CoreBone 是哪一根
            ['B_F_TerrorDrone'] = {
				BoneFrameCfgName = "B_F_TerrorDrone",
				BoneFrameClass = "RAFU_Frame_Basic",
				CanSwitch = true,
				Zorder = 1,
				scale = 1,
				isTop = false,
				imageOffsetY = 8
			},
			CoreBone = "B_F_TerrorDrone" --主实体的骨骼ID，如坦克是底座，飞行兵是兵实体而不是影子,如果只有一个骨骼，则填自身骨骼
		},
		State = {--战斗单元所有的状态类型和脚本
			[STATE_TYPE.STATE_IDLE] = "RAFU_State_BaseIdle",
			[STATE_TYPE.STATE_ATTACK] = "RAFU_State_TerrorDroneAttack",
			[STATE_TYPE.STATE_FLY] = "RAFU_State_WarheadV3Fly",
			[STATE_TYPE.STATE_MOVE] = "RAFU_State_BaseMove",			
			[STATE_TYPE.STATE_DEATH] = "RAFU_State_TankDie",
			[STATE_TYPE.STATE_REVIVE] = "RAFU_State_Revive",
			-- [STATE_TYPE.STATE_DISAPPEAR] = "RAFU_State_TerrorDroneDisapear",--消失状态
			[STATE_TYPE.STATE_TERRORIST_ATTACK] = "RAFU_State_TerrorDroneAttack",
		},
		Weapon = "WP_TerrorDroneWeapon",--携带的武器类型
		-- Weapon = "WP_AmericanSoldierWeapon_new",
        BloodCfg = {
            BloodBar = 4,--血条配置
            BloodPos = "0_-25" 
        },
        
		DieCfg= {
			dieActionTime = 0.1,--死亡序列帧的时间
			dieEffectTime = 2,--死亡特效的时间
			EffectCfg = "Fight_Ani_Behit_10",--死亡特效的RAFU_Cfg_Effect特效配置
			EffectClass = "RAFU_Effect_frameList"--死亡特效的类型，如ccb, 序列帧等
		},
	},
	[51]={ --苏俄城墙中心
		Bones = {
            ['B_F_WallOriginDown'] = {
				BoneFrameCfgName = "B_F_WallOriginDown",
				BoneFrameClass = "RAFU_Frame_Basic",
				CanSwitch = false,
				Zorder = 1,
				scale = 1.0,
				isTop = false,
				imageOffsetY = -10
			},
			CoreBone = "B_F_WallOriginDown"
		},
		State = {
			[STATE_TYPE.STATE_IDLE] = "RAFU_State_BuildingIdle",	
			[STATE_TYPE.STATE_DEATH] = "RAFU_State_OrnamentDie",	
		},
		Weapon = "None",
	},
	[52]={ --苏俄城墙X
		Bones = {
            ['B_F_WallXDown'] = {
				BoneFrameCfgName = "B_F_WallXDown",
				BoneFrameClass = "RAFU_Frame_Basic",
				CanSwitch = false,
				Zorder = 1,
				scale = 1.0,
				isTop = false,
				imageOffsetX = 18,
				imageOffsetY = -10
			},
			CoreBone = "B_F_WallXDown"
		},
		State = {
			[STATE_TYPE.STATE_IDLE] = "RAFU_State_BuildingIdle",	
			[STATE_TYPE.STATE_DEATH] = "RAFU_State_OrnamentDie",	
		},
		Weapon = "None",
	},
	[53]={ --苏俄城墙Y
		Bones = {
            ['B_F_WallYDown'] = {
				BoneFrameCfgName = "B_F_WallYDown",
				BoneFrameClass = "RAFU_Frame_Basic",
				CanSwitch = false,
				Zorder = 1,
				scale = 1.0,
				isTop = false,
				imageOffsetX = -15,
				imageOffsetY = -10
			},
			CoreBone = "B_F_WallYDown"
		},
		State = {
			[STATE_TYPE.STATE_IDLE] = "RAFU_State_BuildingIdle",	
			[STATE_TYPE.STATE_DEATH] = "RAFU_State_OrnamentDie",	
		},
		Weapon = "None",
	},
	[54]={ --尤里城墙中心
		Bones = {
            ['B_F_YuriWallOriginDown'] = {
				BoneFrameCfgName = "B_F_YuriWallOriginDown",
				BoneFrameClass = "RAFU_Frame_Basic",
				CanSwitch = false,
				Zorder = 1,
				scale = 1.0,
				isTop = false,
				imageOffsetY = -15
			},
			CoreBone = "B_F_YuriWallOriginDown"
		},
		State = {
			[STATE_TYPE.STATE_IDLE] = "RAFU_State_BuildingIdle",	
			[STATE_TYPE.STATE_DEATH] = "RAFU_State_OrnamentDie",	
		},
		Weapon = "None",
	},
	[55]={ --尤里城墙X
		Bones = {
            ['B_F_YuriWallXDown'] = {
				BoneFrameCfgName = "B_F_YuriWallXDown",
				BoneFrameClass = "RAFU_Frame_Basic",
				CanSwitch = false,
				Zorder = 1,
				scale = 1.0,
				isTop = false,
				imageOffsetX = 10,
				imageOffsetY = -15
			},
			CoreBone = "B_F_YuriWallXDown"
		},
		State = {
			[STATE_TYPE.STATE_IDLE] = "RAFU_State_BuildingIdle",	
			[STATE_TYPE.STATE_DEATH] = "RAFU_State_OrnamentDie",	
		},
		Weapon = "None",
	},
	[56]={ --尤里城墙Y
		Bones = {
            ['B_F_YuriWallYDown'] = {
				BoneFrameCfgName = "B_F_YuriWallYDown",
				BoneFrameClass = "RAFU_Frame_Basic",
				CanSwitch = false,
				Zorder = 1,
				scale = 1.0,
				isTop = false,
				imageOffsetX = -10,
				imageOffsetY = -15
			},
			CoreBone = "B_F_YuriWallYDown"
		},
		State = {
			[STATE_TYPE.STATE_IDLE] = "RAFU_State_BuildingIdle",	
			[STATE_TYPE.STATE_DEATH] = "RAFU_State_OrnamentDie",	
		},
		Weapon = "None",
	},
	[41]={ --沙包中心
		Bones = {
            ['B_F_SandBagOriginDown'] = {
				BoneFrameCfgName = "B_F_SandBagOriginDown",
				BoneFrameClass = "RAFU_Frame_Basic",
				CanSwitch = false,
				Zorder = 1,
				scale = 1.0,
				isTop = false,
				imageOffsetY = -5
			},
			CoreBone = "B_F_SandBagOriginDown"
		},
		State = {
			[STATE_TYPE.STATE_IDLE] = "RAFU_State_BuildingIdle",	
			[STATE_TYPE.STATE_DEATH] = "RAFU_State_OrnamentDie",	
		},
		Weapon = "None",
	},
	[42]={ --沙包X
		Bones = {
            ['B_F_SandBagXDown'] = {
				BoneFrameCfgName = "B_F_SandBagXDown",
				BoneFrameClass = "RAFU_Frame_Basic",
				CanSwitch = false,
				Zorder = 1,
				scale = 1.0,
				isTop = false,
				imageOffsetX = 10,
				imageOffsetY = -15
			},
			CoreBone = "B_F_SandBagXDown"
		},
		State = {
			[STATE_TYPE.STATE_IDLE] = "RAFU_State_BuildingIdle",	
			[STATE_TYPE.STATE_DEATH] = "RAFU_State_OrnamentDie",	
		},
		Weapon = "None",
	},
	[43]={ --沙包Y
		Bones = {
            ['B_F_SandBagYDown'] = {
				BoneFrameCfgName = "B_F_SandBagYDown",
				BoneFrameClass = "RAFU_Frame_Basic",
				CanSwitch = false,
				Zorder = 1,
				scale = 1.0,
				isTop = false,
				imageOffsetX = -10,
				imageOffsetY = -15
			},
			CoreBone = "B_F_SandBagYDown"
		},
		State = {
			[STATE_TYPE.STATE_IDLE] = "RAFU_State_BuildingIdle",	
			[STATE_TYPE.STATE_DEATH] = "RAFU_State_OrnamentDie",	
		},
		Weapon = "None",
	},
	[25]={ --医疗帐篷
		Bones = {
	        ['B_F_TentDown'] = {
				BoneFrameCfgName = "B_F_TentDown",
				BoneFrameClass = "RAFU_Frame_Basic",
				CanSwitch = false,
				Zorder = 1,
				scale = 1.0,
				isTop = false,
				imageOffsetX = 30,
				imageOffsetY = -10
			},
			CoreBone = "B_F_TentDown"
		},
		State = {
			[STATE_TYPE.STATE_IDLE] = "RAFU_State_BuildingIdle",	
			[STATE_TYPE.STATE_DEATH] = "RAFU_State_TankDie",	
		},
		Weapon = "WP_TeslaCoilWeapon",
        BloodCfg = {
            BloodBar = 3,--血条配置
            BloodPos = "0_70" 
        },
		DieCfg= {
			dieActionTime = 0.1,
			dieEffectTime = 3,
			EffectCfg = "Fight_Ani_Death_Building_3",
			EffectClass = "RAFU_Effect_ccb",
			offsetY = 0,
			offsetX = 20
		},
		AfterDieCfg= {
			EffectCfg = "Bulllt_Effect_Build_Surface",
			EffectClass = "RAFU_Effect_surface"
		},	
	},

	[28]={ --鲍里斯的轰炸机
		-- Bones = {
		-- 	['U_B_BlackEagle_UP'] = {
		-- 		BoneFrameCfgName = "B_F_Boris",
		-- 		BoneFrameClass = "RAFU_Frame_Basic",
		-- 		CanSwitch = false,
		-- 		Zorder = 2,
		-- 		isTop = true,
		-- 		scale = 1.0,
		-- 		turnPeriod = 0.03
		-- 	},
		-- 	CoreBone = "U_B_BlackEagle_UP" --主实体的骨骼ID，如坦克是底座，飞行兵是兵实体而不是影子,如果只有一个骨骼，则填自身骨骼
		-- },
		State = {			
			[STATE_TYPE.STATE_IDLE] = "RAFU_State_BaseIdle",
			[STATE_TYPE.STATE_FLY] = "RAFU_State_BorisFly",
			[STATE_TYPE.STATE_ATTACK] = "RAFU_State_BaseAttack",
			[STATE_TYPE.STATE_DEATH] = "RAFU_State_BaseDie",
			[STATE_TYPE.STATE_DISAPPEAR] = "RAFU_State_BaseDisapear",--子弹的消失状态
		},
		Weapon = "WP_V3WarheadWeapon",
        BloodCfg = {
            BloodBar = 5,--血条配置
            BloodPos = "0_-25" 
        },
		DieCfg= {
			dieActionTime = 0.4,
			dieEffectTime = 0.5
		}
	},

	[29]={ --伞兵运输机
		-- Bones = {
		-- 	['U_B_ParaPlane_UP'] = {
		-- 		BoneFrameCfgName = "B_F_BlackEagleUp",
		-- 		BoneFrameClass = "RAFU_Frame_Basic",
		-- 		CanSwitch = true,
		-- 		Zorder = 2,
		-- 		isTop = true,
		-- 		scale = 1.0,
		-- 		turnPeriod = 0.03
		-- 	},
		-- 	CoreBone = "U_B_ParaPlane_UP" --主实体的骨骼ID，如坦克是底座，飞行兵是兵实体而不是影子,如果只有一个骨骼，则填自身骨骼
		-- },
		State = {
			[STATE_TYPE.STATE_IDLE] = "RAFU_State_BaseIdle",
			[STATE_TYPE.STATE_FLY] = "RAFU_State_ParaPlaneFly",
			[STATE_TYPE.STATE_CREATE] = "RAFU_State_ParaPlaneCreate",
			[STATE_TYPE.STATE_DEATH] = "RAFU_State_BaseDie",
			[STATE_TYPE.STATE_DISAPPEAR] = "RAFU_State_BaseDisapear",
		},
		Weapon = "None",
        BloodCfg = {
            BloodBar = 4,--血条配置
            BloodPos = "0_-25" 
        },
		DieCfg= {
			dieActionTime = 0.4,
			dieEffectTime = 0.5
		}
	},
	[30]={ --伞兵空中状态
		Bones = {
			['U_B_Paratrooper_UP'] = {
				BoneFrameCfgName = "B_F_Paratroopers",
				BoneFrameClass = "RAFU_Frame_Basic",
				CanSwitch = true,
				Zorder = 2,
				isTop = true,
				scale = 1.0,
				turnPeriod = 0.23,
				imageOffsetY = 120,
				offsetY = 120
			},
            ['U_B_Paratrooper_Down'] = {
				BoneFrameCfgName = "B_F_RocketeerDown",
				BoneFrameClass = "RAFU_Frame_Basic",
				CanSwitch = false,
				Zorder = 1,
				scale = 1.0,
				turnPeriod = 0.23,
				isTop = false,
			},
			CoreBone = "U_B_Paratrooper_UP" --主实体的骨骼ID，如坦克是底座，飞行兵是兵实体而不是影子,如果只有一个骨骼，则填自身骨骼
		},
		State = {
			[STATE_TYPE.STATE_FLY] = "RAFU_State_ParatrooperFly",
			[STATE_TYPE.STATE_CREATE] = "RAFU_State_ParatrooperCreate",
			[STATE_TYPE.STATE_DEATH] = "RAFU_State_BaseDie",
			[STATE_TYPE.STATE_DISAPPEAR] = "RAFU_State_BaseDisapear",
		},
		Weapon = "None",
        BloodCfg = {
            BloodBar = 5,--血条配置
            BloodPos = "0_-25" 
        },
		DieCfg= {
			dieActionTime = 0.5,
			dieEffectTime = 0.1,
			EffectCfg = "Fight_Ani_Death_Machine_3",
			EffectClass = "RAFU_Effect_frameList"
		},
	},
	[31]={ --光陵坦克
		Bones = {
			['U_B_PrismTank_UP'] = {
				BoneFrameCfgName = "B_F_PrismTankUp",
				BoneFrameClass = "RAFU_Frame_Basic",
				CanSwitch = true,
				Zorder = 2,
				isTop = true,
				scale = 0.5,
				turnPeriod = 0.03,
				imageOffsetY = 5,
				imageOffsetY = 17
			},
            ['U_B_PrismTank_DOWN'] = {
				BoneFrameCfgName = "B_F_PrismTankDown",
				BoneFrameClass = "RAFU_Frame_Basic",
				CanSwitch = true,
				Zorder = 1,
				scale = 0.5,
				isTop = false,
				imageOffsetY = 5,
				imageOffsetY = 17
			},
			CoreBone = "U_B_PrismTank_DOWN" --主实体的骨骼ID，如坦克是底座，飞行兵是兵实体而不是影子,如果只有一个骨骼，则填自身骨骼
		},
		State = {
			[STATE_TYPE.STATE_IDLE] = "RAFU_State_BaseIdle",
			[STATE_TYPE.STATE_ATTACK] = "RAFU_State_TankAttack",
			[STATE_TYPE.STATE_MOVE] = "RAFU_State_TankMove",			
			[STATE_TYPE.STATE_DEATH] = "RAFU_State_TankDie",
		},
		Weapon = "WP_PrismTankWeapon",
        BloodCfg = {
            BloodBar = 4,--血条配置
            BloodPos = "0_-15" 
        },
		DieCfg= {
			dieActionTime = 0.1,
			dieEffectTime = 3,
			EffectCfg = "Fight_Ani_Death_Machine_1",
			EffectClass = "RAFU_Effect_frameList"
		},
	},
	[32]={ --多功能步兵坦克
		Bones = {
			['U_B_InfantryFightingVehicle_UP'] = {
				BoneFrameCfgName = "B_F_InfantryFightingVehicleUp",
				BoneFrameClass = "RAFU_Frame_Basic",
				CanSwitch = true,
				Zorder = 2,
				isTop = true,
				scale = 0.5,
				turnPeriod = 0.03,
				imageOffsetY = 12

			},
            ['U_B_InfantryFightingVehicle_DOWN'] = {
				BoneFrameCfgName = "B_F_InfantryFightingVehicleDown",
				BoneFrameClass = "RAFU_Frame_Basic",
				CanSwitch = true,
				Zorder = 1,
				scale = 0.5,
				isTop = false,
				imageOffsetY = 12
			},
			CoreBone = "U_B_InfantryFightingVehicle_DOWN" --主实体的骨骼ID，如坦克是底座，飞行兵是兵实体而不是影子,如果只有一个骨骼，则填自身骨骼
		},
		State = {
			[STATE_TYPE.STATE_IDLE] = "RAFU_State_BaseIdle",
			[STATE_TYPE.STATE_ATTACK] = "RAFU_State_TankAttack",
			[STATE_TYPE.STATE_MOVE] = "RAFU_State_TankMove",			
			[STATE_TYPE.STATE_DEATH] = "RAFU_State_TankDie",
		},
		Weapon = "WP_InfantryFightingVehicle_Weapon",
        BloodCfg = {
            BloodBar = 4,--血条配置
            BloodPos = "0_-15" 
        },
		DieCfg= {
			dieActionTime = 0.1,
			dieEffectTime = 0.4,
			EffectCfg = "Fight_Ani_Death_Machine_2",
			EffectClass = "RAFU_Effect_frameList"
		},
		AfterDieCfg= {
			EffectCfg = "Bulllt_Effect_Build_Surface",
			EffectClass = "RAFU_Effect_surface"
		},		
	},
	[34]={ --心灵控制器
		Bones = {
            ['B_F_PsychicTowerDown'] = {
				BoneFrameCfgName = "B_F_PsychicTowerDown",
				BoneFrameClass = "RAFU_Frame_Basic",
				CanSwitch = false,
				Zorder = 1,
				scale = 1.0,
				isTop = false,
				imageOffsetY = 0
			},
		},
		State = {
			[STATE_TYPE.STATE_IDLE] = "RAFU_State_BuildingIdle",
			[STATE_TYPE.STATE_ATTACK] = "RAFU_State_BuildingPrepareAttack",
			[STATE_TYPE.STATE_MOVE] = "RAFU_State_TankMove",			
			[STATE_TYPE.STATE_DEATH] = "RAFU_State_TankDie",
		},
		Weapon = "WP_TeslaCoilWeapon",
        BloodCfg = {
            BloodBar = 2,--血条配置
            BloodPos = "0_80" 
        },
		DieCfg= {
			dieActionTime = 0.1,
			dieEffectTime = 1.25,
			EffectCfg = "Fight_Ani_Death_Machine_3",
			EffectClass = "RAFU_Effect_frameList"
		},
		DestoryBuff = {
			['Fight_Ani_Buff_Effect_3'] = RACcp(0,0),
		},
			AfterDieCfg= {
			EffectCfg = "Bulllt_Effect_Build_Surface",
			EffectClass = "RAFU_Effect_surface"
		},
	},
	[35]={ --光陵塔
		Bones = {
            ['B_F_PrismTowerDown'] = {
				BoneFrameCfgName = "B_F_PrismTowerDown",
				BoneFrameClass = "RAFU_Frame_Basic",
				CanSwitch = false,
				Zorder = 1,
				scale = 1.0,
				isTop = false,
				imageOffsetY = 0
			},
		},
		State = {
			[STATE_TYPE.STATE_IDLE] = "RAFU_State_BuildingIdle",
			[STATE_TYPE.STATE_ATTACK] = "RAFU_State_BuildingPrepareAttack",
			[STATE_TYPE.STATE_MOVE] = "RAFU_State_TankMove",			
			[STATE_TYPE.STATE_DEATH] = "RAFU_State_TankDie",
		},
		Weapon = "WP_PrismTowerWeapon",
        BloodCfg = {
            BloodBar = 3,--血条配置
            BloodPos = "0_100" 
        },
		DieCfg= {
			dieActionTime = 0.1,
			dieEffectTime = 3,
			EffectCfg = "Fight_Ani_Death_Building_3",
			EffectClass = "RAFU_Effect_ccb",
			offsetY = 15
		},
		DestoryBuff = {
			['Fight_Ani_Buff_Effect_3'] = RACcp(0,10),
		},
		AfterDieCfg= {
			EffectCfg = "Bulllt_Effect_Build_Surface",
			EffectClass = "RAFU_Effect_surface"
		},		
	},
	[21]={ --油井
		Bones = {
            ['B_F_OilWellDown'] = {
				BoneFrameCfgName = "B_F_OilWellDown",
				BoneFrameClass = "RAFU_Frame_Basic",
				CanSwitch = false,
				Zorder = 1,
				scale = 1.0,
				isTop = false,
				imageOffsetY = -13,
				imageOffsetX = 0

			},
			CoreBone = "B_F_OilWellDown"
		},
		State = {
			[STATE_TYPE.STATE_IDLE] = "RAFU_State_BuildingIdle",	
			[STATE_TYPE.STATE_DEATH] = "RAFU_State_TankDie",	
		},
		Weapon = "WP_TeslaCoilWeapon",
        BloodCfg = {
            BloodBar = 2,--血条配置
            BloodPos = "0_90" 
        },
		DestoryBuff = {
			['Fight_Ani_Buff_Effect_3'] = RACcp(0,0),
			['Fight_Ani_Buff_Effect_4'] = RACcp(5,5),
			['Fight_Ani_Buff_Effect_5'] = RACcp(-15,20),
		},
		DieCfg= {
			dieActionTime = 0.1,
			dieEffectTime = 3,
			EffectCfg = "Fight_Ani_Death_Building_2",
			EffectClass = "RAFU_Effect_ccb",
			offsetY = 10,
			offsetX = -30
		},
		AfterDieCfg= {
			EffectCfg = "Bulllt_Effect_Build_Surface",
			EffectClass = "RAFU_Effect_surface"
		},		
	},
	[33]={ --法国巨炮
		Bones = {
            ['B_F_GrandCannonDown'] = {
				BoneFrameCfgName = "B_F_GrandCannonDown",
				BoneFrameClass = "RAFU_Frame_Basic",
				CanSwitch = false,
				Zorder = 1,
				scale = 1.0,
				isTop = true,
				imageOffsetY = 0
			},
			CoreBone = "B_F_GrandCannonDown"
		},
		State = {
			[STATE_TYPE.STATE_IDLE] = "RAFU_State_BaseIdle",
			[STATE_TYPE.STATE_ATTACK] = "RAFU_State_TankAttack",	
			[STATE_TYPE.STATE_DEATH] = "RAFU_State_TankDie",	
		},
		Weapon = "WP_GrandCannonWeapon",
        BloodCfg = {
            BloodBar = 2,--血条配置
            BloodPos = "0_50" 
        },
		DestoryBuff = {
			['Fight_Ani_Buff_Effect_4'] = RACcp(0,0),
		},
		DieCfg= {
			dieActionTime = 0.1,
			dieEffectTime = 3,
			EffectCfg = "Fight_Ani_Death_Building_2",
			EffectClass = "RAFU_Effect_ccb",
			offsetY = 20,
			offsetX = -50
		},
		AfterDieCfg= {
			EffectCfg = "Bulllt_Effect_Build_Surface",
			EffectClass = "RAFU_Effect_surface"
		},	
	},
	[37]={ --医疗车 
		Bones = {
            ['U_B_MedicalVehicle'] = {
				BoneFrameCfgName = "B_F_MedicalVehicle",
				BoneFrameClass = "RAFU_Frame_Basic",
				CanSwitch = false,
				Zorder = 1,
				scale = 0.5,
				isTop = true,
				imageOffsetY = 0
			},
			CoreBone = "U_B_MedicalVehicle"
		},
		State = {
			[STATE_TYPE.STATE_IDLE] = "RAFU_State_BaseIdle",
			[STATE_TYPE.STATE_ATTACK] = "RAFU_State_CureAttack",
			[STATE_TYPE.STATE_MOVE] = "RAFU_State_TankMove",		
			[STATE_TYPE.STATE_DEATH] = "RAFU_State_BaseDie"
		},
		Weapon = "WP_PrismTankWeapon",
        BloodCfg = {
            BloodBar = 4,--血条配置
            BloodPos = "0_50" 
        },
		DieCfg= {
			dieActionTime = 0.1,--死亡序列帧的时间
			dieEffectTime = 2,--死亡特效的时间
			EffectCfg = "Fight_Ani_Behit_10",--死亡特效的RAFU_Cfg_Effect特效配置
			EffectClass = "RAFU_Effect_frameList"--死亡特效的类型，如ccb, 序列帧等
		},
	},
	[60]={ --犀牛坦克
		Bones = {--骨骼，可包含多个，但必须填 CoreBone 是哪一根
			['U_B_RhinoTank_UP'] = {
				BoneFrameCfgName = "B_F_RhinoTankUp",--RAFU_Cfg_Bone表的key值
				BoneFrameClass = "RAFU_Frame_Basic",--骨骼挂载的脚本
				CanSwitch = true,--是否可以旋转，比如坦克为true,大兵为false
				Zorder = 2,--层级结构，越大表示越靠上
				isTop = true,--是否上半部分，主要针对tank
				scale = 0.5,--缩放
				imageOffsetY = 8,
			},
            ['U_B_RhinoTank_DOWN'] = {
				BoneFrameCfgName = "B_F_RhinoTankDown",
				BoneFrameClass = "RAFU_Frame_Basic",
				CanSwitch = true,
				Zorder = 1,
				scale = 0.5,
				isTop = false,
				imageOffsetY = 8
			},
			CoreBone = "U_B_RhinoTank_DOWN" --主实体的骨骼ID，如坦克是底座，飞行兵是兵实体而不是影子,如果只有一个骨骼，则填自身骨骼
		},
		State = {--战斗单元所有的状态类型和脚本
			[STATE_TYPE.STATE_IDLE] = "RAFU_State_BaseIdle",
			[STATE_TYPE.STATE_ATTACK] = "RAFU_State_TankAttack",
			[STATE_TYPE.STATE_MOVE] = "RAFU_State_TankMove",			
			[STATE_TYPE.STATE_DEATH] = "RAFU_State_TankDie",
		},
		Weapon = "WP_TankDestroyerWeapon",--携带的武器类型
        BloodCfg = {
            BloodBar = 4,--血条配置
            BloodPos = "0_-25" 
        },
        
		DieCfg= {
			dieActionTime = 0.1,--死亡序列帧的时间
			dieEffectTime = 2,--死亡特效的时间
			EffectCfg = "Fight_Ani_Behit_10",--死亡特效的RAFU_Cfg_Effect特效配置
			EffectClass = "RAFU_Effect_frameList"--死亡特效的类型，如ccb, 序列帧等
		},
	},
	[66]={ --防空步兵
		Bones = {
			['U_B_AmericanSoldier_UP'] = {
				BoneFrameCfgName = "B_F_FlakTrooper",
				BoneFrameClass = "RAFU_Frame_Basic",
				CanSwitch = false,
				Zorder = 2,
				isTop = false,
				scale = 1.0,
				imageOffsetY = 0
			},
			CoreBone = "U_B_AmericanSoldier_UP" --主实体的骨骼ID，如坦克是底座，飞行兵是兵实体而不是影子,如果只有一个骨骼，则填自身骨骼
		},
		State = {
			[STATE_TYPE.STATE_IDLE] = "RAFU_State_BaseIdle",
			[STATE_TYPE.STATE_ATTACK] = "RAFU_State_BaseAttack",
			[STATE_TYPE.STATE_MOVE] = "RAFU_State_BaseMove",			
			[STATE_TYPE.STATE_DEATH] = "RAFU_State_BaseDie",
		},
		Weapon = "WP_FlakTrooperWeapon",
        BloodCfg = {
            BloodBar = 5,--血条配置
            BloodPos = "0_-10" 
        },
		DieCfg= {
			dieActionTime = 0.4,
			dieEffectTime = 0.5
		}
	},
	[62]={ --磁暴步兵
		Bones = {
			['U_B_AmericanSoldier_UP'] = {
				BoneFrameCfgName = "B_F_TeslaTrooper",
				BoneFrameClass = "RAFU_Frame_Basic",
				CanSwitch = false,
				Zorder = 2,
				isTop = false,
				scale = 1.0,
				imageOffsetY = 0
			},
			CoreBone = "U_B_AmericanSoldier_UP" --主实体的骨骼ID，如坦克是底座，飞行兵是兵实体而不是影子,如果只有一个骨骼，则填自身骨骼
		},
		State = {
			[STATE_TYPE.STATE_IDLE] = "RAFU_State_BaseIdle",
			[STATE_TYPE.STATE_ATTACK] = "RAFU_State_TankAttack",
			[STATE_TYPE.STATE_MOVE] = "RAFU_State_AmericanMove",			
			[STATE_TYPE.STATE_DEATH] = "RAFU_State_BaseDie",
		},
		Weapon = "WP_TeslaTankWeapon", 
        BloodCfg = {
            BloodBar = 4,--血条配置
            BloodPos = "0_-15" 
        },
		DieCfg= {
			dieActionTime = 0.1,--死亡序列帧的时间
			dieEffectTime = 2,--死亡特效的时间
			EffectCfg = "Fight_Ani_Behit_10",--死亡特效的RAFU_Cfg_Effect特效配置
			EffectClass = "RAFU_Effect_frameList"--死亡特效的类型，如ccb, 序列帧等
		},
	},
	[69]={ --夜鹰直升机
		Bones = {
			['U_B_NightHawkTransport_UP'] = {
				BoneFrameCfgName = "B_F_NightHawkTransportUp",
				BoneFrameClass = "RAFU_Frame_Aircraft",
				CanSwitch = false,
				Zorder = 2,
				scale = 1.0,
				turnPeriod = 0.23,
				isTop = true,
				imageOffsetY = 0,
			},
            ['U_B_NightHawkTransport_Down'] = {
				BoneFrameCfgName = "B_F_NightHawkTransportDown",
				BoneFrameClass = "RAFU_Frame_Basic",
				CanSwitch = false,
				Zorder = 3,
				isTop = true,
				scale = 1.0,
				turnPeriod = 0.23,
				imageOffsetY = 15,
				frameNum = 16,
				offsetY = 25,
				isTop = true,
			},
			['U_B_NightHawkTransport_Down2'] = {
				BoneFrameCfgName = "B_F_NightHawkTransportDown",
				BoneFrameClass = "RAFU_Frame_Basic",
				CanSwitch = false,
				Zorder = 3,
				isTop = true,
				scale = 1.0,
				turnPeriod = 0.23,
				imageOffsetX = -15,
				imageOffsetY = 5,
				frameNum = 16,
				offsetY = 25,
				isTop = true,
			},
			['U_B_NightHawkTransport_Shadow'] = {
				BoneFrameCfgName = "B_F_NightHawkTransportShadow",
				BoneFrameClass = "RAFU_Frame_Basic",
				CanSwitch = false,
				Zorder = 1,
				scale = 1.0,
				turnPeriod = 0.23,
				imageOffsetX = 20,
				imageOffsetY = 38,
				isTop = false,
			},
			CoreBone = "U_B_NightHawkTransport_Down" --主实体的骨骼ID，如坦克是底座，飞行兵是兵实体而不是影子,如果只有一个骨骼，则填自身骨骼
		},
		State = {
			[STATE_TYPE.STATE_IDLE] = "RAFU_State_HelicopterIdle",
			[STATE_TYPE.STATE_ATTACK] = "RAFU_State_SoldierAttack",
			[STATE_TYPE.STATE_MOVE] = "RAFU_State_JumpMove",			
			[STATE_TYPE.STATE_DEATH] = "RAFU_State_JumpDie",
		},
		Weapon = "WP_AmericanSoldierWeapon",
        BloodCfg = {
            BloodBar = 5,--血条配置
            BloodPos = "0_35" 
        },
		DieCfg= {
			dieActionTime = 0.5,
			dieEffectTime = 0.1,
			EffectCfg = "Fight_Ani_Death_Machine_3",
			EffectClass = "RAFU_Effect_frameList"
		},
	},
}
return RAFU_Cfg_Unit
