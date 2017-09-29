-- RAScenesConfig

local RAScenesConfig = {

	-- cmd type in city Scene
	CMD_CityScene = 
	{

	},

	-- cmd type in world scene
	CMD_WorldScene =
	{
		-- 切到城外之后，视角移动到某个格子，有以下情况数据结构
		-- 1、{x = 1, y= 1}
		-- 2、{marchId = '1231'}  点击行军队列后，世界初始化完毕后切换到队列当前行军的坐标
		Locate_Tile = 'Locate_Tile',
	},
}

return RAScenesConfig