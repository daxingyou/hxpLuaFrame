--[[
description: 子弹配置
author: zhenhui
date: 2016/11/22
]]--


local RAFU_Cfg_Warhead = {
	["WH_TankBullet"] = {
		class = "RAFU_Warhead_sprite",
		spriteName = "Fight_Ani_Bullet_Parabola_1.png",
		plist = "Army_Bullet_1.plist",
	    pic = "Army_Bullet_1.png"
	},
	["WH_TankBullet_Line"] = {
		class = "RAFU_Warhead_sprite",
		spriteName = "College_u_Cable.png",
		plist = "Army_Bullet_1.plist",
	    pic = "Army_Bullet_1.png"
	},
	["WH_TankBullet_Air"] = {
		class = "RAFU_Warhead_motionStreak",
		spriteName = "Animation/YuriRewardAni/Yuri_Reward_pipe_8.png",
		-- plist = "Army_Bullet_1.plist",
	    -- pic = "Army_Bullet_1.png",
	    fadeTime = 2,
	    minSeg = 1,
	    stroke = 1
	},
	["WH_GrizzlyTankBullet"] = {
		class = "RAFU_Warhead_motionStreak",
		spriteName = "Animation/Particle/Rain.png",
		prefixSprite = "Animation/Fight/Fight_Ani/Fight_Ani_Bullet_Parabola_6/Fight_Ani_Bullet_Parabola_6.png",
		-- plist = "Army_Bullet_1.plist",
	    -- pic = "Army_Bullet_1.png",
	    fadeTime = 2,
	    minSeg = -1,
	    stroke = 4,
	    --color = {50, 50, 50}
	},
	["WH_ZepBullet"] = {
		class = "RAFU_Warhead_frame",
		plist = "Army_Bullet_1.plist",
	    pic = "Army_Bullet_1.png",
	    frameNum = 1,
	    frameBase = "Fight_Ani_Bullet_Parabola_3"
	},	
	["WH_TankBullet_Shadow"] = {
		class = "RAFU_Warhead_sprite",
		spriteName = "Fight_Ani_Bullet_Parabola_1Shadow.png",
		plist = "Army_Bullet_1.plist",
	    pic = "Army_Bullet_1.png"
	},
	["WH_V3Bullet"] = {
		class = "RAFU_Warhead_bone",
		boneCfg = {
			BoneFrameCfgName = "B_F_ApocalypseTankDown",
			BoneFrameClass = "RAFU_Frame_Basic",
			NeedSwitch = true,
			Zorder = 1,
			scale = 1.0,
			isTop = false,
		},
	},
	["WH_PrismTankBullet"] = {
		class = "RAFU_Warhead_sprite",
		spriteName = "Fight_Ani_Bullet_Instant_102.png",
		plist = "Army_Bullet_1.plist",
	    pic = "Army_Bullet_1.png",
	    effCfg = {
			-- 线　y 方向缩放
		    scaleY = 2,
		    -- 攻击到达时间比例，散列时间比例 (相对lifeTime的比例)
		    timePercent = {0.01, 0.01},
		    -- 散列个数随机范围
		    countRange = {0, 4},
		    -- 散列角度随机范围
		    degreeRange = {20, 340},
		    -- 散列长度随机范围(线长的百分比 %前的数值)
		    distanceRange = {10, 50}
		}
	},
	["WH_PrismTowerBullet"] = {
		class = "RAFU_Warhead_sprite",
		spriteName = "Fight_Ani_Bullet_Instant_102.png",
		plist = "Army_Bullet_1.plist",
	    pic = "Army_Bullet_1.png",
	    effCfg = {
			-- 线　y 方向缩放
		    scaleY = 2,
		    -- 攻击到达时间比例，散列时间比例 (相对lifeTime的比例)
		    timePercent = {0.01, 0.01},
		    -- 散列个数随机范围
		    countRange = {0, 0},
		    -- 散列角度随机范围
		    degreeRange = {20, 340},
		    -- 散列长度随机范围(线长的百分比 %前的数值)
		    distanceRange = {10, 50}
		}
	},
	["WH_TeslaTankBullet"] = {
		class = "RAFU_Warhead_sprite",
		spriteName = "Army_Effect_2.png",
		plist = "Army_Bullet_1.plist",
	    pic = "Army_Bullet_1.png",
	    spriteArr = {
	    	[149] = { 
	    		"Fight_Ani_Bullet_Tesla_301.png",
		    	"Fight_Ani_Bullet_Tesla_302.png",
		    	"Fight_Ani_Bullet_Tesla_303.png"
		    },
	    	[96] = { 
	    		"Fight_Ani_Bullet_Tesla_201.png",
		    	"Fight_Ani_Bullet_Tesla_202.png",
		    	"Fight_Ani_Bullet_Tesla_203.png"
		    },
	    	[41] = { 
	    		"Fight_Ani_Bullet_Tesla_101.png",
		    	"Fight_Ani_Bullet_Tesla_102.png",
		    	"Fight_Ani_Bullet_Tesla_103.png"
		    },
		},
		--子弹的Y缩放
		scaleY = 0.2
	},
}
return RAFU_Cfg_Warhead