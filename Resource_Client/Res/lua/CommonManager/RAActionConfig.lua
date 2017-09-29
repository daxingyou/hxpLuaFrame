-- RAActionConfig
-- RAActionManager中的配置

local RAActionConfig = 
{
	-- type
	MoveToCallBackType = 
	{
		NormalEnd = 1,				-- 正常结束动作
		InitiativeEnd = 2,			-- 主动结束动作
		ParamsErrorEnd = 3,			-- 参数错误结束动作
	}
}



return RAActionConfig