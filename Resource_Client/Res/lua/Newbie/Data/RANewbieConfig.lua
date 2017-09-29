--
--  @ Project : NewbieGuide
--  @ File Name : RANewbieConfig.lua
--  @ Date : 2017/2/9
--  @ Author : @Qinho
--
--

local RANewbieConfig = {

	Enum_ChapterType = {
		Chapter_First = 1,
		Chapter_Middle = 2,
		Chapter_Last = 3
	},


	-- 步骤处理逻辑类型，
	-- 1、公共页面处理
	-- 2、只能点击框选位置进入下一步骤
	-- 3、点击任何区域均不可进入下一步，一定时间后自己跳过，h_stepDuration控制时间
	Enum_StepClickType = {
		Click_All_Screen = 1,
		Click_Rect_Only = 2,
		Time_End_Only = 3,
	},

	-- 步骤处理方式的类型，如不清楚需要程序确认！
	-- 1、配置好h_targetPageName 等参数，用于普通功能页面的引导
	-- 2、程序处理。通过程序内发送消息，消息包含处理目标、点击回调等，在handler里处理的类型，具体每一个步骤有不同，统一在handler里根据step id进行区分判断，常用于非页面，但是通过点击新建的内容。
	-- 3、程序处理。在handler里根据step id，自行获取需要引导的对象，常用于引导常驻类型的页面、建筑等内容
	-- 4、程序处理。单个步骤单独实现自身逻辑，会有对应该步骤id的handler 文件
	Enum_StepHandleType = {
		Config_Get_Handle = 1,
		Message_Get_Handle = 2,
		Self_Get_Handle = 3,
		Special_Get_Handle = 4
	},

	-- 新手视觉表现类型，
	-- 1：半身像+文字
	-- 2：框选
	-- 3：1+2
	-- 4：只有黑屏+文字（刚开始 的几步）
	-- 5：显示成功页面
	-- 6: 没有任何显示内容
	-- 7: 播放某个关卡（此时会有v_missionId的值）
	Enum_StepViewType = {
		Role_Only = 1,
		Rect_Only = 2,
		Rect_With_Role = 3,
		BlackBg_With_Label = 4,
		Victory_Only = 5,
		Show_Nothing = 6,
		Play_One_Mission = 7
	},



	GuideTips=                          --光圈的配置大小
    {
        ConfigWidth=64,                 --CCB里光圈的宽
        ConfigHeight=64,                --CCB里光圈的高
        ConfigOffset=9,                 --CCB里光圈的边距
    },

    DialogCCBConfig = {
	    "RAGuideLabelBlueNode.ccbi" = 1001,
	    "RAGuideLabelBlueNode2.ccbi" = 1002,
	    "RAGuideLabelGreenNode.ccbi" = 1003,
	    "RAGuideLabelGreenNode2.ccbi" = 1004,
	}

}





return RANewbieConfig