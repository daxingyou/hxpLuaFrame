--[[
description: 玩家技能相关配置
author: qinho
date: 2017-01-13
]]--


local RAFU_Cfg_PlayerSkill = {
	[BattleSkillId.ONE_MISSILE]={ --单发炮弹技能特效
		main = {	-- 主体展示
			EffectFrameCfgName = 'OneMissile_Skill_Effect',	-- RAFU_Cfg_Effect 的key值
			EffectFrameClass = "RAFU_Effect_bone",	--effect实现的脚本
		},
		sub1 = {	-- 影子展示
			EffectFrameCfgName = 'OneMissile_SkillShadow_Effect',	-- RAFU_Cfg_Effect 的key值
			EffectFrameClass = "RAFU_Effect_bone",	--effect实现的脚本
		},
		skillEndCfg = {		-- 技能生效后的特效展示
			EffectFrameCfgName = 'Fight_Ani_Behit_10',	-- RAFU_Cfg_Effect 的key值
			EffectFrameClass = "RAFU_Effect_frameList",	--effect实现的脚本
		}
	},
	[BattleSkillId.MULTI_MISSILE]={ --多发炮弹技能特效
		main = {	-- 主体展示
			EffectFrameCfgName = 'MultipleMissile_Skill_Effect',	-- RAFU_Cfg_Effect 的key值
			EffectFrameClass = "RAFU_Effect_bone",	--effect实现的脚本
		},
		sub1 = {	-- 影子展示
			EffectFrameCfgName = 'MultipleMissile_SkillShadow_Effect',	-- RAFU_Cfg_Effect 的key值
			EffectFrameClass = "RAFU_Effect_bone",	--effect实现的脚本
		},
		skillEndCfg = {		-- 技能生效后的特效展示
			EffectFrameCfgName = 'Fight_Ani_Behit_9',	-- RAFU_Cfg_Effect 的key值
			EffectFrameClass = "RAFU_Effect_frameList",	--effect实现的脚本
		},
		extraParams = {
			-- 多重技能释放的时候，随机发射时间的百分比
			MultiMissileFlyTimeRandomStartPer = 0.4,
			MultiMissileFlyTimeRandomEndPer = 0.4,
			-- 随机数最大值
			MultiMissileFlyTimeRandomMax = 30,

			-- 每发炮弹延迟发射的时间增加的百分比，第一发为0，之后每发递增，值为1-5
			OneMissileStartTimePer = 1,
			-- 每发炮弹到达的时间减去的百分比，最后一发为0，之前每发递增，值为1-5
			OneMissileEndTimePer = 15,

			-- 当前多发技能是否采用随机
			IsRandom = false,
		}
	},
    [BattleSkillId.TEAM_TREAT]={ --医疗包技能特效
		main = {	-- 主体展示
			EffectFrameCfgName = 'Fight_Ani_Bullet_Parabola_4',	-- RAFU_Cfg_Effect 的key值
			EffectFrameClass = "RAFU_Effect_frameList",	--effect实现的脚本
		},
		sub1 = {	-- 影子展示
			EffectFrameCfgName = 'Fight_Ani_Bullet_ParabolaShadow_4',	-- RAFU_Cfg_Effect 的key值
			EffectFrameClass = "RAFU_Effect_frameList",	--effect实现的脚本
		},
		skillEndCfg = {		-- 技能生效后的特效展示
			EffectFrameCfgName = 'Fight_Ani_Behit_8',	-- RAFU_Cfg_Effect 的key值
			EffectFrameClass = "RAFU_Effect_frameList",	--effect实现的脚本
		}
	}
}
return RAFU_Cfg_PlayerSkill
