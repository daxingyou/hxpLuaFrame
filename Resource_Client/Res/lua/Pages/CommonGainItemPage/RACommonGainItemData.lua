

local RACommonGainItemData = 
{
	GAIN_ITEM_TYPE = 
	{
	    expeditionMax   	 = 1, --出征上限提升界面
		marchAccelerate 	 = 2, --行军加速界面
	    marchCallBack   	 = 3,  --行军召回界面
        powerCallBack   	 = 4,  --添加体力界面
        resCollectSpeedUp    = 5,  --资源采集加速
        useExp 				 = 6,  --使用经验药

	},
	GAIN_ITEM_TITLE_NAME = 
	{
		"@toCapRaised",     --出征上限提升
		"@marchSpeedUp",       --行军加速
		"@marchRecalled",      -- 行军召回
        "@addPowerTitle",      -- 添加体力
        "@ResColSpeedUpTitle",      -- 资源采集加速
        "@useExp",
	},
    AddPowerFunctionBlock = 3,
    AddExpFunctionBlock = 6,
}

return RACommonGainItemData