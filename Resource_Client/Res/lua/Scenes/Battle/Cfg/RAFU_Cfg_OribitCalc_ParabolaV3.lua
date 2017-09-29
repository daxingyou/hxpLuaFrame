--[[
description: 运动轨迹相关的配置
	v3导弹
author: qinho
date: 2016/12/16
]]--

RARequire("RAFightDefine")

local RAFU_Cfg_OribitCalc_ParabolaV3 = {
	--抛物线用到的配置
	ParabolaV3Cfg = {		
		-- 根据实际角度控制，应该具有以下情况
		-- 1、15参数一致，5、11参数一致  	
		-- 2、14参数一致，6、10参数一致 				
		-- 3、13参数一致，7、9参数一致   			
		-- 4、12 参数一致
		-- 12、13、14、15 为测试标准

		-- 0
		-- 垂直向上
		-- 垂直向上时，炮弹会先向下走一段路程（匀减速），然后再向上（匀加速）
		-- 会预设置炮弹向下的速度 v，预设向下走的距离百分比 per
		-- 同时我们假定炮弹的加速度不变
		[FU_DIRECTION_ENUM.DIR_UP             ] = {			
			Speed_Y_Init_V_Main = 200,		-- 自身垂直方向上的初始速度
			Distance_Y_Percent = 0.3,		-- 炮弹向下走的路程和直线距离的百分比
			AheadTimeToRemoveBody = 0.1,	-- 炮弹移动提前消失不见的时间，单位s，因为炮弹的中心现在是尾部，规避视觉上尾巴打中目标的情况
		}, 

		-- 1
		-- 斜向抛物线，以轨迹为x轴建立新坐标系，下面提到的x、y轴均为该坐标系
		-- x轴方向上，影子做匀速直线运动
		-- y轴方向上，炮弹先做匀减速，再做匀加速运动，		
		-- 另外为模拟更真实的视角倾斜，将抛物线分为上升段和下降段
		-- 增加配置，用于设定最高点在x轴上映射的坐标比例
		-- 增加配置，y方向上初始速度
		-- 根据以上3个配置和已知的水平轴上距离、速度、时间，计算最高点、下降加速度等
		[FU_DIRECTION_ENUM.DIR_UP_UP_LEFT     ] = {
			Speed_Y_Init_V_Main = 70,
			Distance_X_Percent = 0.8,
			AheadTimeToRemoveBody = 0.1,
		}, 

		-- 2
		[FU_DIRECTION_ENUM.DIR_UP_LEFT        ] = {
			Speed_Y_Init_V_Main = 200,
			Distance_X_Percent = 0.70,
			AheadTimeToRemoveBody = 0.1,
		}, 

		-- 3
		[FU_DIRECTION_ENUM.DIR_UP_DOWN_LEFT   ] = {
			Speed_Y_Init_V_Main = 300,
			Distance_X_Percent = 0.6,
			AheadTimeToRemoveBody = 0.1,
		}, 

		-- 4
		[FU_DIRECTION_ENUM.DIR_LEFT           ] = {
			Speed_Y_Init_V_Main = 400,
			Distance_X_Percent = 0.5,
			AheadTimeToRemoveBody = 0.1,
		}, 

		-- 5
		[FU_DIRECTION_ENUM.DIR_DOWN_UP_LEFT   ] = {
			Speed_Y_Init_V_Main = 300,
			Distance_X_Percent = 0.6,
			AheadTimeToRemoveBody = 0.1,
		}, 

		-- 6
		[FU_DIRECTION_ENUM.DIR_DOWN_LEFT      ] = {
			Speed_Y_Init_V_Main = 200,
			Distance_X_Percent = 0.70,
			AheadTimeToRemoveBody = 0.1,
		},     

		-- 7
		[FU_DIRECTION_ENUM.DIR_DOWN_DOWN_LEFT ] = {
			Speed_Y_Init_V_Main = 70,
			Distance_X_Percent = 0.80,
			AheadTimeToRemoveBody = 0.1,
		},

		-- 8
		-- 垂直向下
		-- 垂直向下时，炮弹会先向上走一段路程（匀减速），然后再向下（匀加速）
		-- 会预设置炮弹向上的速度 v，预设向上走的距离百分比 per
		-- 同时我们假定炮弹的加速度不变
		[FU_DIRECTION_ENUM.DIR_DOWN           ] = {
			Speed_Y_Init_V_Main = 200,		-- 自身垂直方向上的初始速度
			Distance_Y_Percent = 0.3,		-- 炮弹向上走的路程和直线距离的百分比
			AheadTimeToRemoveBody = 0.1,
		}, 

		-- 9
		[FU_DIRECTION_ENUM.DIR_DOWN_DOWN_RIGHT] = {
			Speed_Y_Init_V_Main = 70,
			Distance_X_Percent = 0.80,
			AheadTimeToRemoveBody = 0.1,
		}, 

		-- 10
		[FU_DIRECTION_ENUM.DIR_DOWN_RIGHT     ] = {
			Speed_Y_Init_V_Main = 200,
			Distance_X_Percent = 0.70,
			AheadTimeToRemoveBody = 0.1,
		}, 

		-- 11
		[FU_DIRECTION_ENUM.DIR_DOWN_UP_RIGHT  ] = {
			Speed_Y_Init_V_Main = 300,
			Distance_X_Percent = 0.60,
			AheadTimeToRemoveBody = 0.1,
		}, 

		-- 12
		[FU_DIRECTION_ENUM.DIR_RIGHT          ] = {
			Speed_Y_Init_V_Main = 400,
			Distance_X_Percent = 0.5,
			AheadTimeToRemoveBody = 0.1,
		}, 

		-- 13
		[FU_DIRECTION_ENUM.DIR_UP_DOWN_RIGHT  ] = {
			Speed_Y_Init_V_Main = 300,
			Distance_X_Percent = 0.6,
			AheadTimeToRemoveBody = 0.1,
		}, 

		-- 14
		[FU_DIRECTION_ENUM.DIR_UP_RIGHT       ] = {
			Speed_Y_Init_V_Main = 200,
			Distance_X_Percent = 0.70,
			AheadTimeToRemoveBody = 0.1,
		}, 

		-- 15
		[FU_DIRECTION_ENUM.DIR_UP_UP_RIGHT    ] = {
			Speed_Y_Init_V_Main = 70,
			Distance_X_Percent = 0.80,
			AheadTimeToRemoveBody = 0.1,
		},   

	},

	ParabolaPartType = 
	{
		PartOne = 1,
		PartTwo = 2,
		PartThree = 3,
	}
}
return RAFU_Cfg_OribitCalc_ParabolaV3