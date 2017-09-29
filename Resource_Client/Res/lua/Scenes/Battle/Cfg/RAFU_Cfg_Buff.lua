--[[
description: buff配置
author: zhenhui
date: 2016/12/13
]]--


local RAFU_Cfg_Buff = {
	["BUFF_BorisTarget"] = {
		class = "RAFU_Buff_shaderNodeCCB",
		ccbiName = "FightUnit_Buff_borisTarget.ccbi",
		scale = 1.0,
		timeLine = "Default Timeline",
	},
	["BUFF_TerroristDamage"] = {
		class = "RAFU_Buff_TerroistDamage",
		ccbiName = "FightUnit_Buff_borisTarget.ccbi",
		scale = 1.0,
		timeLine = "Default Timeline",
	},
	["BUFF_WhiteFlash"] = {
		class = "RAFU_Buff_shaderNodeCCB",
		ccbiName = "FightUnit_Buff_whiteFlash.ccbi",
		scale = 1.0,
		timeLine = "Default Timeline",
	},
	["Fight_Ani_Buff_Effect_3"] = {
		class = "RAFU_Buff_frameList",
		prefix = "Fight_Ani_Buff_Effect_3",
		pic = "Army_Effect_1.png",
		plist = "Army_Effect_1.plist",
		frameCount = 30,
		frameFps = 25,
		scale = 1.0,
		indexMode = 1,
	},
	["Fight_Ani_Buff_Effect_4"] = {
		class = "RAFU_Buff_frameList",
		prefix = "Fight_Ani_Buff_Effect_4",
		pic = "Army_Effect_1.png",
		plist = "Army_Effect_1.plist",
		frameCount = 64,
		frameFps = 25,
		scale = 1.0,
		indexMode = 1,
	},
	["Fight_Ani_Buff_Effect_5"] = {
		class = "RAFU_Buff_frameList",
		prefix = "Fight_Ani_Buff_Effect_5",
		pic = "Army_Effect_1.png",
		plist = "Army_Effect_1.plist",
		frameCount = 30,
		frameFps = 25,
		scale = 1.0,
		indexMode = 1,
	},
	["Fight_Ani_Buff_Effect_7"] = {
		class = "RAFU_Buff_frameList",
		prefix = "Fight_Ani_Buff_Effect_7",
		pic = "Army_Effect_1.png",
		plist = "Army_Effect_1.plist",
		frameCount = 9,
		frameFps = 25,
		scale = 1.0,
		indexMode = 1,
	},
}
return RAFU_Cfg_Buff