--[[
description: 运动轨迹相关的配置
	坦克炮弹
author: qinho
date: 2016/12/8
]]--

RARequire("RAFightDefine")

local RAFU_Cfg_OribitCalc_Parabola = {
	--抛物线用到的配置
	ParabolaCfg = {		
		-- 根据实际角度控制，应该具有以下情况
		-- 1、15参数一致，5、11参数一致  	
		-- 2、14参数一致，6、10参数一致 				
		-- 3、13参数一致，7、9参数一致   			
		-- 4、12 参数一致
		-- 12、13、14、15 为测试标准

		-- 0
		-- 垂直向上
		-- 垂直向上时，初始状态子弹快于影子，所以子弹做匀减速、影子做匀加速		
		-- 会预设置炮弹和影子的初始速度，时间和距离已知
		-- 然后计算出炮弹vt、a，然后计算影子的vt、a
		-- 实时根据v0 a t 来计算当前走到哪里
		[FU_DIRECTION_ENUM.DIR_UP             ] = {			
			Speed_Y_Init_V_Main = 300,		-- 自身垂直方向上的初始速度
			Speed_Y_Init_V_Sub1 = 150,		-- 影子垂直方向上的初始速度
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
			Speed_Y_Init_V_Main = 30,
			Distance_X_Percent = 0.74,
		}, 

		-- 2
		[FU_DIRECTION_ENUM.DIR_UP_LEFT        ] = {
			Speed_Y_Init_V_Main = 40,
			Distance_X_Percent = 0.66,
		}, 

		-- 3
		[FU_DIRECTION_ENUM.DIR_UP_DOWN_LEFT   ] = {
			Speed_Y_Init_V_Main = 50,
			Distance_X_Percent = 0.58,
		}, 

		-- 4
		[FU_DIRECTION_ENUM.DIR_LEFT           ] = {
			Speed_Y_Init_V_Main = 60,
			Distance_X_Percent = 0.5,
		}, 

		-- 5
		[FU_DIRECTION_ENUM.DIR_DOWN_UP_LEFT   ] = {
			Speed_Y_Init_V_Main = 50,
			Distance_X_Percent = 0.53,
		}, 

		-- 6
		[FU_DIRECTION_ENUM.DIR_DOWN_LEFT      ] = {
			Speed_Y_Init_V_Main = 40,
			Distance_X_Percent = 0.55,
		},     

		-- 7
		[FU_DIRECTION_ENUM.DIR_DOWN_DOWN_LEFT ] = {
			Speed_Y_Init_V_Main = 30,
			Distance_X_Percent = 0.6,
		},

		-- 8
		-- 垂直向下
		-- 垂直向下时，初始状态影子快于子弹，所以子弹做匀加速、影子做匀减速
		-- 会预设置炮弹和影子的初始速度，时间和距离已知
		-- 然后计算出炮弹vt、a，然后计算影子的vt、a
		-- 实时根据v0 a t 来计算当前走到哪里
		[FU_DIRECTION_ENUM.DIR_DOWN           ] = {
			Speed_Y_Init_V_Main = -150,		-- 自身垂直方向上的初始速度，向下走速度小于0
			Speed_Y_Init_V_Sub1 = -300,		-- 影子垂直方向上的初始速度，向下走速度小于0
		}, 

		-- 9
		[FU_DIRECTION_ENUM.DIR_DOWN_DOWN_RIGHT] = {
			Speed_Y_Init_V_Main = 30,
			Distance_X_Percent = 0.6,
		}, 

		-- 10
		[FU_DIRECTION_ENUM.DIR_DOWN_RIGHT     ] = {
			Speed_Y_Init_V_Main = 40,
			Distance_X_Percent = 0.55,
		}, 

		-- 11
		[FU_DIRECTION_ENUM.DIR_DOWN_UP_RIGHT  ] = {
			Speed_Y_Init_V_Main = 50,
			Distance_X_Percent = 0.53,
		}, 

		-- 12
		[FU_DIRECTION_ENUM.DIR_RIGHT          ] = {
			Speed_Y_Init_V_Main = 60,
			Distance_X_Percent = 0.5,
		}, 

		-- 13
		[FU_DIRECTION_ENUM.DIR_UP_DOWN_RIGHT  ] = {
			Speed_Y_Init_V_Main = 50,
			Distance_X_Percent = 0.58,
		}, 

		-- 14
		[FU_DIRECTION_ENUM.DIR_UP_RIGHT       ] = {
			Speed_Y_Init_V_Main = 40,
			Distance_X_Percent = 0.66,
		}, 

		-- 15
		[FU_DIRECTION_ENUM.DIR_UP_UP_RIGHT    ] = {
			Speed_Y_Init_V_Main = 30,
			Distance_X_Percent = 0.74,
		},   

	},
}
return RAFU_Cfg_OribitCalc_Parabola