--[[
description: 子弹配置
author: zhenhui
date: 2016/11/22
]]--


local RAFU_Cfg_Weapon = {
	["WP_BasicWeapon"] = {--最基础的攻击行为，瞬时伤害，只计算伤害，而且没有任何特效
		weaponClass = "RAFU_Weapon_Basic",
		projectileClass = "RAFU_Projectile_invisio",
	},
	["WP_V3WarheadWeapon"] = {--V3
		weaponClass = "RAFU_Weapon_Basic",
		projectileClass = "RAFU_Projectile_invisio",
		effectList = {
			["surface"] = {
				effectClass = "RAFU_Effect_surface",
				effectCfgName = "Bulllt_Effect_Surface",
			}			
		},
	},
	["WP_ApocalypseTankWeapon"] = {--天启
		weaponClass = "RAFU_Weapon_Basic",
		projectileClass = "RAFU_Projectile_apocalypse",
		effectList = {
			["behit"] = {
				effectClass = "RAFU_Effect_frameList",
				effectCfgName = "Fight_Ani_Behit_3",
			},
			["fire"] = {
				effectClass = "RAFU_Effect_frameList",
				effectCfgName = "Fight_Ani_Fire_1",
				offset = {
					[0] = RACcp(-4,26), [1] = RACcp(-27,21),[2] = RACcp(-27,21),[3] = RACcp(-36,16),
				    [4] = RACcp(-42,7),[5] = RACcp(-39,-3),[6] = RACcp(-28,-10),[7] = RACcp(-17,-14),
				    [8] = RACcp(-4,-16),[9] = RACcp(7,-16),[10] = RACcp(15,-12),[11] = RACcp(24,-7),
				    [12] = RACcp(33,1),[13] = RACcp(32,10),[14] = RACcp(25,19),[15] = RACcp(13,23),
				},
			},
			["surface"] = {
				effectClass = "RAFU_Effect_surface",
				effectCfgName = "Bulllt_Effect_Surface",
			}	
		},		
		warheadList = {
			["main_1"] = {
				warheadClass = "RAFU_Warhead_sprite",
				warheadCfgName = "WH_TankBullet",
				excludeTargetType = {4},
				groupId = 1,
				groupType = "main",
				offset = {
					[0] = RACcp(2,30), [1] = RACcp(-14,29),[2] = RACcp(-30,25),[3] = RACcp(-40,18),
				    [4] = RACcp(-45,7),[5] = RACcp(-45,-3),[6] = RACcp(-33,-13),[7] = RACcp(-20,-20),
				    [8] = RACcp(2,-24),[9] = RACcp(21,-19),[10] = RACcp(35,-12),[11] = RACcp(44,-2),
				    [12] = RACcp(48,6),[13] = RACcp(42,15),[14] = RACcp(36,23),[15] = RACcp(21,28),
				}
			},
			["shadow_1"] = {
				warheadClass = "RAFU_Warhead_sprite",
				warheadCfgName = "WH_TankBullet_Shadow",
				excludeTargetType = {4},
				groupId = 1,
				groupType = "sub1",
				offset = {
					[0] = RACcp(2,30), [1] = RACcp(-14,29),[2] = RACcp(-30,25),[3] = RACcp(-40,18),
				    [4] = RACcp(-45,7),[5] = RACcp(-45,-3),[6] = RACcp(-33,-13),[7] = RACcp(-20,-20),
				    [8] = RACcp(2,-24),[9] = RACcp(21,-19),[10] = RACcp(35,-12),[11] = RACcp(44,-2),
				    [12] = RACcp(48,6),[13] = RACcp(42,15),[14] = RACcp(36,23),[15] = RACcp(21,28),
				}
			},
			-- ["main_2"] = {
			-- 	warheadClass = "RAFU_Warhead_sprite",
			-- 	warheadCfgName = "WH_TankBullet",
			-- 	excludeTargetType = {4},
			-- 	groupId = 2,
			-- 	groupType = "main",
			-- 	offset = {
			-- 		[0] = RACcp(2,0), [1] = RACcp(-20,2),[2] = RACcp(-9,0),[3] = RACcp(0,-8),
			-- 	    [4] = RACcp(0,-10),[5] = RACcp(0,-2),[6] = RACcp(-8,-10),[7] = RACcp(-10,-6),
			-- 	    [8] = RACcp(2,-10),[9] = RACcp(-4,-6),[10] = RACcp(-3,-10),[11] = RACcp(0,-2),
			-- 	    [12] = RACcp(0,-10),[13] = RACcp(-10,-20),[14] = RACcp(-3,0),[15] = RACcp(-6,0),
			-- 	}
			-- },
			-- ["shadow_2"] = {
			-- 	warheadClass = "RAFU_Warhead_sprite",
			-- 	warheadCfgName = "WH_TankBullet_Shadow",
			-- 	excludeTargetType = {4},
			-- 	groupId = 2,
			-- 	groupType = "sub1",
			-- 	offset = {
			-- 		[0] = RACcp(2,-5), [1] = RACcp(-20,-5),[2] = RACcp(-9,-7),[3] = RACcp(0,-12),
			-- 	    [4] = RACcp(0,-15),[5] = RACcp(0,-7),[6] = RACcp(-8,-15),[7] = RACcp(-10,-10),
			-- 	    [8] = RACcp(8,-14),[9] = RACcp(-4,-8),[10] = RACcp(-3,-13),[11] = RACcp(0,-5),
			-- 	    [12] = RACcp(0,-13),[13] = RACcp(-10,-26),[14] = RACcp(-3,-6),[15] = RACcp(-6,-8),
			-- 	}
			-- },
			["air_1"] = {
				warheadClass = "RAFU_Warhead_motionStreak",
				warheadCfgName = "WH_TankBullet_Air",
				targetType = {4},
				groupId = 1,
				groupType = "main",
				offset = {
					[0] = RACcp(0,0), [1] = RACcp(0,0),[2] = RACcp(0,0),[3] = RACcp(0,0),
				    [4] = RACcp(0,0),[5] = RACcp(0,0),[6] = RACcp(0,0),[7] = RACcp(0,0),
				    [8] = RACcp(0,0),[9] = RACcp(0,0),[10] = RACcp(0,0),[11] = RACcp(0,0),
				    [12] = RACcp(0,0),[13] = RACcp(0,0),[14] = RACcp(0,0),[15] = RACcp(0,0),
				}
			},
			["air_2"] = {
				warheadClass = "RAFU_Warhead_motionStreak",
				warheadCfgName = "WH_TankBullet_Air",
				targetType = {4},
				groupId = 2,
				groupType = "main",
				offset = {
					[0] = RACcp(0,-3), [1] = RACcp(0,-3),[2] = RACcp(0,-3),[3] = RACcp(0,-3),
				    [4] = RACcp(0,-3),[5] = RACcp(0,-3),[6] = RACcp(0,-3),[7] = RACcp(0,-3),
				    [8] = RACcp(0,-3),[9] = RACcp(0,-3),[10] = RACcp(0,-3),[11] = RACcp(0,-3),
				    [12] = RACcp(0,-3),[13] = RACcp(0,-3),[14] = RACcp(0,-3),[15] = RACcp(0,-3),
				}
			},
		}
	},
	["WP_GrizzlyTankWeapon"] = {--灰熊坦克武器
		weaponClass = "RAFU_Weapon_Basic",--基础武器脚本
		projectileClass = "RAFU_Projectile_arcing",--武器的攻击轨迹（抛射体）
		effectList = {--定义特效的的配置
			["behit"] = {--命中目标之后的特效
				effectClass = "RAFU_Effect_frameList",
				effectCfgName = "Fight_Ani_Behit_9",
			},
			["fire"] = {--开火时候的特效  炮口
				effectClass = "RAFU_Effect_frameList",
				effectCfgName = "Fight_Ani_Fire_1",
			},
			["surface"] = {
				effectClass = "RAFU_Effect_surface",
				effectCfgName = "Bulllt_Effect_Surface",
			}	
		},		
		warheadList = {--定义子弹的配置
			["main"] = {--主炮弹
				warheadClass = "RAFU_Warhead_motionStreak",--子弹的类型
				warheadCfgName = "WH_GrizzlyTankBullet",--子弹的配置
				offset = {--子弹的偏移，从中心点的偏移，图片大小200,200，中心点就是100，100
					[0] = RACcp(2,30), [1] = RACcp(-14,29),[2] = RACcp(-30,25),[3] = RACcp(-40,18),
				    [4] = RACcp(-45,7),[5] = RACcp(-45,-3),[6] = RACcp(-33,-13),[7] = RACcp(-20,-20),
				    [8] = RACcp(2,-24),[9] = RACcp(21,-19),[10] = RACcp(35,-12),[11] = RACcp(44,-2),
				    [12] = RACcp(48,6),[13] = RACcp(42,15),[14] = RACcp(36,23),[15] = RACcp(21,28),
				},
			},
			["sub1"] = {--影子
				warheadClass = "RAFU_Warhead_sprite",
				warheadCfgName = "WH_TankBullet_Shadow",
				offset = {
					[0] = RACcp(14,18), [1] = RACcp(-14,16),[2] = RACcp(-21,11),[3] = RACcp(-25,6),
				    [4] = RACcp(-28,-7),[5] = RACcp(-27,-16),[6] = RACcp(-23,-15),[7] = RACcp(-12,-22),
				    [8] = RACcp(9,-11),[9] = RACcp(20,-19),[10] = RACcp(31,-18),[11] = RACcp(41,-15),
				    [12] = RACcp(44,2),[13] = RACcp(39,9),[14] = RACcp(32,14),[15] = RACcp(20,17),
			},
			},
		}, 
	},
    ["WP_TankDestroyerWeapon"] = {--坦克杀手武器
		weaponClass = "RAFU_Weapon_Basic",--基础武器脚本
		projectileClass = "RAFU_Projectile_arcing",--武器的攻击轨迹（抛射体）
		effectList = {--定义特效的的配置
			["behit"] = {--命中目标之后的特效
				effectClass = "RAFU_Effect_frameList",
				effectCfgName = "Fight_Ani_Behit_9",
			},
			["fire"] = {--开火时候的特效  炮口
				effectClass = "RAFU_Effect_frameList",
				effectCfgName = "Fight_Ani_Fire_1",
			},
			["surface"] = {
				effectClass = "RAFU_Effect_surface",
				effectCfgName = "Bulllt_Effect_Surface",
			}	
		},		
		warheadList = {--定义子弹的配置
			["main"] = {--主炮弹
				warheadClass = "RAFU_Warhead_motionStreak",--子弹的类型
				warheadCfgName = "WH_GrizzlyTankBullet",--子弹的配置
				offset = {--子弹的偏移，从中心点的偏移，图片大小200,200，中心点就是100，100
					[0] = RACcp(2,15), [1] = RACcp(-7,15),[2] = RACcp(-20,20),[3] = RACcp(-20,18),
				    [4] = RACcp(-25,7),[5] = RACcp(-25,-3),[6] = RACcp(-13,-5),[7] = RACcp(-10,-10),
				    [8] = RACcp(2,-10),[9] = RACcp(11,-19),[10] = RACcp(20,-5),[11] = RACcp(24,-2),
				    [12] = RACcp(28,0),[13] = RACcp(22,15),[14] = RACcp(25,18),[15] = RACcp(11,28),
				},
			},
			["sub1"] = {--影子
				warheadClass = "RAFU_Warhead_sprite",
				warheadCfgName = "WH_TankBullet_Shadow",
				offset = {
					[0] = RACcp(14,18), [1] = RACcp(-14,16),[2] = RACcp(-21,11),[3] = RACcp(-25,6),
				    [4] = RACcp(-28,-7),[5] = RACcp(-27,-16),[6] = RACcp(-23,-15),[7] = RACcp(-12,-22),
				    [8] = RACcp(9,-11),[9] = RACcp(20,-19),[10] = RACcp(31,-18),[11] = RACcp(41,-15),
				    [12] = RACcp(44,2),[13] = RACcp(39,9),[14] = RACcp(32,14),[15] = RACcp(20,17),
			},
			},
		}, 
	},
	["WP_MirageTankWeapon"] = {--幻影坦克武器
		weaponClass = "RAFU_Weapon_Basic",--基础武器脚本
		projectileClass = "RAFU_Projectile_arcing",--武器的攻击轨迹（抛射体）
		effectList = {--定义特效的的配置
			["behit"] = {--命中目标之后的特效
				effectClass = "RAFU_Effect_frameList",
				effectCfgName = "Fight_Ani_Behit_13",
			},
			["fire"] = {--开火时候的特效  炮口
				effectClass = "RAFU_Effect_frameList",
				effectCfgName = "Fight_Ani_Fire_1",
			},
			["surface"] = {
				effectClass = "RAFU_Effect_surface",
				effectCfgName = "Bulllt_Effect_Surface",
			}	
		},		
		warheadList = {--定义子弹的配置
			["main"] = {--主炮弹
				warheadClass = "RAFU_Warhead_motionStreak",--子弹的类型
				warheadCfgName = "WH_GrizzlyTankBullet",--子弹的配置
				offset = {--子弹的偏移，从中心点的偏移，图片大小200,200，中心点就是100，100
					[0] = RACcp(2,15), [1] = RACcp(-7,15),[2] = RACcp(-20,20),[3] = RACcp(-20,18),
				    [4] = RACcp(-25,7),[5] = RACcp(-25,-3),[6] = RACcp(-13,-5),[7] = RACcp(-10,-10),
				    [8] = RACcp(2,-10),[9] = RACcp(11,-19),[10] = RACcp(20,-5),[11] = RACcp(24,-2),
				    [12] = RACcp(28,0),[13] = RACcp(22,15),[14] = RACcp(25,18),[15] = RACcp(11,28),
				},
			},
			["sub1"] = {--影子
				warheadClass = "RAFU_Warhead_sprite",
				warheadCfgName = "WH_TankBullet_Shadow",
				offset = {
					[0] = RACcp(14,18), [1] = RACcp(-14,16),[2] = RACcp(-21,11),[3] = RACcp(-25,6),
				    [4] = RACcp(-28,-7),[5] = RACcp(-27,-16),[6] = RACcp(-23,-15),[7] = RACcp(-12,-22),
				    [8] = RACcp(9,-11),[9] = RACcp(20,-19),[10] = RACcp(31,-18),[11] = RACcp(41,-15),
				    [12] = RACcp(44,2),[13] = RACcp(39,9),[14] = RACcp(32,14),[15] = RACcp(20,17),
			},
			},
		}, 
	},
	["WP_TankWeapon"] = {
		weaponClass = "RAFU_Weapon_Basic",
		projectileClass = "RAFU_Projectile_arcing",
		effectList = {
			["behit"] = {
				effectClass = "RAFU_Effect_frameList",
				effectCfgName = "Fight_Ani_Behit_2",
			},
			["fire"] = {
				effectClass = "RAFU_Effect_frameList",
				effectCfgName = "Fight_Ani_Fire_1",
			},
			["surface"] = {
				effectClass = "RAFU_Effect_surface",
				effectCfgName = "Bulllt_Effect_Surface",
			}	
		},		
		warheadList = {
			["main"] = {
				warheadClass = "RAFU_Warhead_sprite",
				warheadCfgName = "WH_TankBullet",
				offset = {
					[0] = RACcp(0,40), [1] = RACcp(-25,40),[2] = RACcp(-40,30),[3] = RACcp(-50,23),
				    [4] = RACcp(-50,0),[5] = RACcp(-50,-12),[6] = RACcp(-40,0),[7] = RACcp(-22,-16),
				    [8] = RACcp(0,-20),[9] = RACcp(22,-16),[10] = RACcp(40,0),[11] = RACcp(50,-12),
				    [12] = RACcp(50,0),[13] = RACcp(50,23),[14] = RACcp(40,30),[15] = RACcp(25,40),
				},
			},
			["sub1"] = {
				warheadClass = "RAFU_Warhead_sprite",
				warheadCfgName = "WH_TankBullet_Shadow",
				offset = {
					[0] = RACcp(0,20), [1] = RACcp(-25,20),[2] = RACcp(-40,30),[3] = RACcp(-50,23),
				    [4] = RACcp(-50,-10),[5] = RACcp(-50,-2),[6] = RACcp(-40,-10),[7] = RACcp(-22,-6),
				    [8] = RACcp(0,-10),[9] = RACcp(22,-6),[10] = RACcp(40,-10),[11] = RACcp(50,-2),
				    [12] = RACcp(50,-10),[13] = RACcp(50,13),[14] = RACcp(40,20),[15] = RACcp(25,30),
			},
			},
		}, 
	},
	["WP_ZepWeapon"] = {
		weaponClass = "RAFU_Weapon_Basic",
		projectileClass = "RAFU_Projectile_zep",
		effectList = {
			["behit"] = {
				effectClass = "RAFU_Effect_frameList",
				effectCfgName = "Fight_Ani_Behit_5",
			},
			["surface"] = {
				effectClass = "RAFU_Effect_surface",
				effectCfgName = "Bulllt_Effect_Surface",
			}	
		},		
		warheadList = {
			["main"] = {
				warheadClass = "RAFU_Warhead_frame",
				warheadCfgName = "WH_ZepBullet",
				offset = {
					[0] = RACcp(0,0), [1] = RACcp(0,0),[2] = RACcp(5,0),[3] = RACcp(0,0),
				    [4] = RACcp(5,0), [5] = RACcp(0,0),[6] = RACcp(5,0),[7] = RACcp(0,0),
				    [8] = RACcp(0,-15), [9] = RACcp(0,0),[10] = RACcp(-5,0),[11] = RACcp(0,0),
				    [12] = RACcp(-5,0), [13] = RACcp(0,0),[14] = RACcp(-5,0),[15] = RACcp(0,0),
				},
			},
			["sub1"] = {
				warheadClass = "RAFU_Warhead_sprite",
				warheadCfgName = "WH_TankBullet_Shadow",
				offset = {
					[0] = RACcp(0,0), [1] = RACcp(0,0),[2] = RACcp(5,0),[3] = RACcp(0,0),
				    [4] = RACcp(5,0), [5] = RACcp(0,0),[6] = RACcp(5,0),[7] = RACcp(0,0),
				    [8] = RACcp(0,-15), [9] = RACcp(0,0),[10] = RACcp(-5,0),[11] = RACcp(0,0),
				    [12] = RACcp(-5,0), [13] = RACcp(0,0),[14] = RACcp(-5,0),[15] = RACcp(0,0),
			},
			},
		}, 		
	},
	["WP_TerrorDroneWeapon"] = {
		weaponClass = "RAFU_Weapon_Basic",
		projectileClass = "RAFU_Projectile_invisio",
		effectList = {
			-- ["behit"] = {
			-- 	effectClass = "RAFU_Effect_frameList",
			-- 	effectCfgName = "Fight_Ani_Behit_1",
			-- }
		}
	},		
	["WP_AmericanSoldierWeapon"] = {
		weaponClass = "RAFU_Weapon_Basic",
		projectileClass = "RAFU_Projectile_invisio",
		effectList = {
			["behit"] = {
				effectClass = "RAFU_Effect_frameList",
				effectCfgName = "Fight_Ani_Behit_1",
			}
		}
	},
	["WP_AmericanSoldierWeapon_new"] = {
		weaponClass = "RAFU_Weapon_Basic",
		projectileClass = "RAFU_Projectile_invisio",
		effectList = {
			["behit"] = {
				effectClass = "RAFU_Effect_frameList",
				effectCfgName = "Fight_Ani_Behit_1",
			},
			["fire"] = {
				effectClass = "RAFU_Effect_spriteRepeat",
				effectCfgName = "Fight_Ani_AM_ATTACK",
			},
		}
	},

	["WP_InitiateWeapon"] = {
		weaponClass = "RAFU_Weapon_Basic",
		projectileClass = "RAFU_Projectile_invisio",
		effectList = {
			["behit"] = {
				effectClass = "RAFU_Effect_frameList",
				effectCfgName = "Fight_Ani_Buff_Effect_3",
			},
		}
	},
	["WP_FlakTrooperWeapon"] = {
		weaponClass = "RAFU_Weapon_Basic",
		projectileClass = "RAFU_Projectile_invisio",
		effectList = {
			["behit"] = {
				effectClass = "RAFU_Effect_frameList",
				effectCfgName = "Fight_Ani_Behit_6",
			},
		}
	},
	["WP_BruteWeapon"] = {
		weaponClass = "RAFU_Weapon_Basic",
		projectileClass = "RAFU_Projectile_invisio",
	},
	["WP_GattlingCannonWeapon"] = {
		weaponClass = "RAFU_Weapon_Basic",
		projectileClass = "RAFU_Projectile_invisio",
		effectList = {
			["behit"] = {
				effectClass = "RAFU_Effect_frameList",
				effectCfgName = "Fight_Ani_Behit_1",
			}
			,
			-- ["fire"] = {
			-- 	effectClass = "RAFU_Effect_frameList",
			-- 	effectCfgName = "Fight_Ani_Fire_1",
			-- }
		},
		warheadList = {
			["main"] = {
				-- warheadClass = "RAFU_Warhead_frame",
				-- warheadCfgName = "WH_ZepBullet",
				offset = {
					[0] = RACcp(0,0), [1] = RACcp(0,0),[2] = RACcp(5,0),[3] = RACcp(0,0),
				    [4] = RACcp(5,0), [5] = RACcp(0,0),[6] = RACcp(5,0),[7] = RACcp(0,0),
				    [8] = RACcp(0,-15), [9] = RACcp(0,0),[10] = RACcp(-5,0),[11] = RACcp(0,0),
				    [12] = RACcp(-5,0), [13] = RACcp(0,0),[14] = RACcp(-5,0),[15] = RACcp(0,0),
					},
				},
			},
	},
	["WP_FlakCannonWeapon"] = {
		weaponClass = "RAFU_Weapon_Basic",
		projectileClass = "RAFU_Projectile_invisio",
		effectList = {
			["behit"] = {
				effectClass = "RAFU_Effect_frameList",
				effectCfgName = "Fight_Ani_Behit_6",
			}
			,
			-- ["fire"] = {
			-- 	effectClass = "RAFU_Effect_frameList",
			-- 	effectCfgName = "Fight_Ani_Fire_1",
			-- }
		},
		warheadList = {
			["main"] = {
				-- warheadClass = "RAFU_Warhead_frame",
				-- warheadCfgName = "WH_ZepBullet",
				offset = {
					[0] = RACcp(0,0), [1] = RACcp(0,0),[2] = RACcp(5,0),[3] = RACcp(0,0),
				    [4] = RACcp(5,0), [5] = RACcp(0,0),[6] = RACcp(5,0),[7] = RACcp(0,0),
				    [8] = RACcp(0,-15), [9] = RACcp(0,0),[10] = RACcp(-5,0),[11] = RACcp(0,0),
				    [12] = RACcp(-5,0), [13] = RACcp(0,0),[14] = RACcp(-5,0),[15] = RACcp(0,0),
					},
				},
			},
	},
	["WP_GrandCannonWeapon"] = {
		weaponClass = "RAFU_Weapon_Basic",
		projectileClass = "RAFU_Projectile_invisio",
		effectList = {
			["behit"] = {
				effectClass = "RAFU_Effect_frameList",
				effectCfgName = "Fight_Ani_Behit_5",
			}
			,
			["fire"] = {
				effectClass = "RAFU_Effect_frameList",
				effectCfgName = "Fight_Ani_Death_Machine_3",
			}
		},
		warheadList = {
			["main"] = {
				-- warheadClass = "RAFU_Warhead_frame",
				-- warheadCfgName = "WH_ZepBullet",
				offset = {
					[0] = RACcp(-2,59), [1] = RACcp(-28,57),[2] = RACcp(-52,48),[3] = RACcp(-67,37),
				    [4] = RACcp(-72,23), [5] = RACcp(-67,15),[6] = RACcp(-55,-8),[7] = RACcp(-35,-15),
				    [8] = RACcp(-2,-19), [9] = RACcp(27,-9),[10] = RACcp(46,0),[11] = RACcp(64,9),
				    [12] = RACcp(69,23), [13] = RACcp(83,38),[14] = RACcp(45,48),[15] = RACcp(26,56),
					},
				},
			},
	},
	["WP_PrismTankWeapon"] = {--光陵坦克
		weaponClass = "RAFU_Weapon_Basic",
		projectileClass = "RAFU_Projectile_prism",
		effectClass = "RAFU_Effect_ccb",
		effectCfgName = "E_TankBlast",
		effectList = {
			["behit"] = {
				effectClass = "RAFU_Effect_frameList",
				effectCfgName = "Fight_Ani_Death_Machine_3",
			},
		},
		warheadList = {
			["main"] = {
				warheadClass = "RAFU_Warhead_sprite",
				warheadCfgName = "WH_PrismTankBullet",
				offset = {
					[0] = RACcp(-3,13), [1] = RACcp(-2,14),[2] = RACcp(-3,11),[3] = RACcp(-1,12),
				    [4] = RACcp(-4,13),[5] = RACcp(1,14),[6] = RACcp(0,18),[7] = RACcp(2,19),
				    [8] = RACcp(-1,19),[9] = RACcp(-2,17),[10] = RACcp(-4,17),[11] = RACcp(-1,15),
				    [12] = RACcp(-3,15),[13] = RACcp(-4,15),[14] = RACcp(0,12),[15] = RACcp(-1,12),
				},
			}
		}, 
	},
	["WP_PrismTowerWeapon"] = {--光陵塔
		weaponClass = "RAFU_Weapon_Basic",
		projectileClass = "RAFU_Projectile_prism",
		effectClass = "RAFU_Effect_ccb",
		effectCfgName = "E_TankBlast",
		effectList = {
			["behit"] = {
				effectClass = "RAFU_Effect_frameList",
				effectCfgName = "Fight_Ani_Death_Machine_3",
			},
		},
		warheadList = {
			["main"] = {
				warheadClass = "RAFU_Warhead_sprite",
				warheadCfgName = "WH_PrismTowerBullet",
				offset = {
					[0] = RACcp(0,80), [1] = RACcp(0,80),[2] = RACcp(0,80),[3] = RACcp(0,80),
				    [4] = RACcp(0,80),[5] = RACcp(0,80),[6] = RACcp(0,80),[7] = RACcp(0,80),
				    [8] = RACcp(0,80),[9] = RACcp(0,80),[10] = RACcp(0,80),[11] = RACcp(0,80),
				    [12] = RACcp(0,80),[13] = RACcp(0,80),[14] = RACcp(0,80),[15] = RACcp(0,80),
				},
			}
		}, 
	},
	['WP_TeslaTankWeapon'] = {--磁暴坦克武器
		weaponClass = "RAFU_Weapon_Basic",
		projectileClass = "RAFU_Projectile_tesla",
		effectList = {
			["behit"] = {
				effectClass = "RAFU_Effect_frameList",
				effectCfgName = "Fight_Ani_Behit_4",
			},
		},
		warheadList = {
			["main"] = {
				warheadClass = "RAFU_Warhead_sprite",
				warheadCfgName = "WH_TeslaTankBullet",
				offset = {
					[0] = RACcp(0,20), [1] = RACcp(-5,19),[2] = RACcp(-12,16),[3] = RACcp(-17,11),
				    [4] = RACcp(-18,7),[5] = RACcp(-15,1),[6] = RACcp(-10,0),[7] = RACcp(-4,0),
				    [8] = RACcp(0,0),[9] = RACcp(3,0),[10] = RACcp(8,0),[11] = RACcp(12,3),
				    [12] = RACcp(15,8),[13] = RACcp(14,12),[14] = RACcp(9,16),[15] = RACcp(4,18),
				},
			}
		}, 
	},
	['WP_FreezerTankWeapon'] = {--冷冻车武器
		weaponClass = "RAFU_Weapon_Basic",
		projectileClass = "RAFU_Projectile_tesla",
		effectList = {
			["behit"] = {
				effectClass = "RAFU_Effect_frameList",
				effectCfgName = "Fight_Ani_Behit_4",
			},
		},
		warheadList = {
			["main"] = {
				warheadClass = "RAFU_Warhead_sprite",
				warheadCfgName = "WH_TeslaTankBullet",
				offset = {
					[0] = RACcp(0,20), [1] = RACcp(-5,19),[2] = RACcp(-12,16),[3] = RACcp(-17,11),
				    [4] = RACcp(-18,7),[5] = RACcp(-15,1),[6] = RACcp(-10,0),[7] = RACcp(-4,0),
				    [8] = RACcp(0,0),[9] = RACcp(3,0),[10] = RACcp(8,0),[11] = RACcp(12,3),
				    [12] = RACcp(15,8),[13] = RACcp(14,12),[14] = RACcp(9,16),[15] = RACcp(4,18),
				},
			}
		}, 
	},
	['WP_TeslaCoilWeapon'] = {
		weaponClass = "RAFU_Weapon_Basic",
		projectileClass = "RAFU_Projectile_tesla",
		effectList = {
			["behit"] = {
				effectClass = "RAFU_Effect_frameList",
				effectCfgName = "Fight_Ani_Behit_2",
			},
		},
		warheadList = {
			["main"] = {
				warheadClass = "RAFU_Warhead_sprite",
				warheadCfgName = "WH_TeslaTankBullet",
				offset = {
					[0] = RACcp(0,50), [1] = RACcp(0,50),[2] = RACcp(0,50),[3] = RACcp(0,50),
				    [4] = RACcp(0,50),[5] = RACcp(0,50),[6] = RACcp(0,50),[7] = RACcp(0,50),
				    [8] = RACcp(0,50),[9] = RACcp(0,50),[10] = RACcp(0,50),[11] = RACcp(0,50),
				    [12] = RACcp(0,50),[13] = RACcp(0,50),[14] = RACcp(0,50),[15] = RACcp(0,50),
				}
			}
		}, 
	},
	["WP_InfantryFightingVehicle_Weapon"] = {--多功能步兵车
		weaponClass = "RAFU_Weapon_Basic",
		projectileClass = "RAFU_Projectile_vehicle",
		effectList = {
			["behit"] = {
				effectClass = "RAFU_Effect_frameList",
				effectCfgName = "Fight_Ani_Behit_2",
			},
			-- ["fire"] = {
			-- 	effectClass = "RAFU_Effect_frameList",
			-- 	effectCfgName = "Fight_Ani_Fire_1",
			-- },
			["surface"] = {
				effectClass = "RAFU_Effect_surface",
				effectCfgName = "Bulllt_Effect_Surface",
			}	
		},		
		warheadList = {
			["main_1"] = {
				warheadClass = "RAFU_Warhead_motionStreak",
				warheadCfgName = "WH_TankBullet_Air",
				excludeTargetType = {4},
				groupId = 1,
				groupType = "main",
				offset = {
					[0] = RACcp(0,0), [1] = RACcp(-25,2),[2] = RACcp(-4,0),[3] = RACcp(-5,-8),
				    [4] = RACcp(-5,-10),[5] = RACcp(-5,-2),[6] = RACcp(-4,-10),[7] = RACcp(-2,-6),
				    [8] = RACcp(4,-10),[9] = RACcp(2,-6),[10] = RACcp(4,-10),[11] = RACcp(5,-2),
				    [12] = RACcp(5,-10),[13] = RACcp(8,1),[14] = RACcp(4,0),[15] = RACcp(2,0),
				}
			},
			["main_2"] = {
				warheadClass = "RAFU_Warhead_motionStreak",
				warheadCfgName = "WH_TankBullet_Air",
				excludeTargetType = {4},
				groupId = 2,
				groupType = "main",
				offset = {
					[0] = RACcp(2,0), [1] = RACcp(-20,2),[2] = RACcp(-9,0),[3] = RACcp(0,-8),
				    [4] = RACcp(0,-10),[5] = RACcp(0,-2),[6] = RACcp(-8,-10),[7] = RACcp(-10,-6),
				    [8] = RACcp(2,-10),[9] = RACcp(-4,-6),[10] = RACcp(-3,-10),[11] = RACcp(0,-2),
				    [12] = RACcp(0,-10),[13] = RACcp(-10,-20),[14] = RACcp(-3,0),[15] = RACcp(-6,0),
				}
			},
			["air_1"] = {
				warheadClass = "RAFU_Warhead_motionStreak",
				warheadCfgName = "WH_TankBullet_Air",
				targetType = {4},
				groupId = 1,
				groupType = "main",
				offset = {
					[0] = RACcp(0,0), [1] = RACcp(0,0),[2] = RACcp(0,0),[3] = RACcp(0,0),
				    [4] = RACcp(0,0),[5] = RACcp(0,0),[6] = RACcp(0,0),[7] = RACcp(0,0),
				    [8] = RACcp(0,0),[9] = RACcp(0,0),[10] = RACcp(0,0),[11] = RACcp(0,0),
				    [12] = RACcp(0,0),[13] = RACcp(0,0),[14] = RACcp(0,0),[15] = RACcp(0,0),
				}
			},
			["air_2"] = {
				warheadClass = "RAFU_Warhead_motionStreak",
				warheadCfgName = "WH_TankBullet_Air",
				targetType = {4},
				groupId = 2,
				groupType = "main",
				offset = {
					[0] = RACcp(0,-3), [1] = RACcp(0,-3),[2] = RACcp(0,-3),[3] = RACcp(0,-3),
				    [4] = RACcp(0,-3),[5] = RACcp(0,-3),[6] = RACcp(0,-3),[7] = RACcp(0,-3),
				    [8] = RACcp(0,-3),[9] = RACcp(0,-3),[10] = RACcp(0,-3),[11] = RACcp(0,-3),
				    [12] = RACcp(0,-3),[13] = RACcp(0,-3),[14] = RACcp(0,-3),[15] = RACcp(0,-3),
				}
			},
		}, 
	},
}

return RAFU_Cfg_Weapon