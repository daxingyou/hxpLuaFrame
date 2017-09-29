local missionaction_conf = {
    [10] = {
        actionTarget = "xxx.ccbi",
        actionType = "shownode",
        varibleName = "nodename1",
        param = "true",
        nextActionId = "30",
        desc = "显示黑色背景"
    },
    [20] = {
        actionTarget = "xxx.ccbi",
        actionType = "shownode",
        varibleName = "nodename2",
        param = "false",
        nextActionId = nil,
        desc = "隐藏蓝色节点"
    },
    [25] = {
        actionTarget = "xxx.ccbi",
        actionType = "shownode",
        varibleName = "btnnode",
        param = "false",
        nextActionId = nil,
        desc = "隐藏按钮节点"
    },
    [30] = {
        actionTarget = "xxx.ccbi",
        actionType = "runani",
        param = "aniname1",
        nextActionId = "40,50",
        desc = "播放黑色启动动画"
    },
    [40] = {
        actionTarget = "xxx.ccbi",
        actionType = "shownode",
        varibleName = "nodename2",
        param = "true",
        nextActionId = "60",
        desc = "显示蓝色背景"
    },
    [50] = {
        actionTarget = "xxx.ccbi",
        actionType = "shwonode",
        varibleName = "nodename1",
        param = "false",
        nextActionId = nil,
        desc = "隐藏黑色初始化背景"
    },
    [60] = {
        actionTarget = "xxx.ccbi",
        actionType = "runani",
        param = "aniname2",
        nextActionId = "70,80",
        desc = "播放蓝色流光动画"
    },
    [70] = {
        actionTarget = "xxx.ccbi",
        actionType = "runani",
        param = "aniname3",
        nextActionId = "90,100,110",
        desc = "播放eva图像向下的动画"
    },
    [80] = {
        actionTarget = "xxx.ccbi",
        actionType = "changepic",
        varibleName = "picnode",
        param = "xxxx.png",
        nextActionId = nil,
        desc = "设置eva图片"
    },
    [90] = {
        actionTarget = "xxx.ccbi",
        actionType = "shownode",
        varibleName = "labenode",
        param = "true"
    },
    [100] = {
        actionTarget = "xxx.ccbi",
        actionType = "changelabel",
        varibleName = "labelnode",
        param = "@aaaaaa",
        nextActionId = nil,
        desc = "设置语言"
    },
    [110] = {
        actionTarget = "xxx.ccbi",
        actionType = "runani",
        param = "labelaniname",
        nextActionId = "120",
        desc = "播放label动画"
    },
    [120] = {
        actionTarget = "xxx.ccbi",
        actionType = "shownode",
        varibleName = "btnnode",
        param = "true",
        nextActionId = nil,
        desc = "显示按钮节点"
    },

    --关卡动作开始
    [2000] = {
        actionTarget = "RAMissionMap1.ccbi",
        actionType = "delaytime",
        param = "2",
        nextActionId = "2010",
        desc = "延迟2s"
    },
    [2005] = {
        actionTarget = "RAMissionMap1.ccbi",
        actionType = "runani",
        param = "March1_Timeline1",
        nextActionId = nil,
        desc = "播放迷雾动画"
    },
    [2010] = {
        actionType = "showpage",
        varibleName = "RAMissionBarrierPage",
        param = "true",
        nextActionId = "2020,2030,2040,2045",
        desc = "显示对话框"
    },
    [2020] = {
        actionTarget = "RAMissionMap_Ani_Dialog.ccbi",
        actionType = "changepic",
        varibleName = "mHeadPortraitNode",
        param = "HeadPortait_Sys.png",
        nextActionId = nil,
        desc = "显示头像"
    },
    [2030] = {
        actionTarget = "RAMissionMap_Ani_Dialog.ccbi",
        actionType = "changelabel",
        varibleName = "mDialogue",
        param = "@dialog1",
        nextActionId = nil,
        desc = "对话：指挥官，这就是尤里部队架设的心灵探针"
    },
    [2040] = {
        actionTarget = "RAMissionMap_Ani_Dialog.ccbi",
        actionType = "runani",
        param = "Play",
        nextActionId = "2050",
        desc = "播放动画"
    },
    [2045] = {
        actionTarget = "RAMissionMap1_March1.ccbi",
        actionType = "runani",
        param = "March1_Timeline1",
        nextActionId = nil,
        desc = "播放心灵探针闪动"
    },
    [2050] = {
        actionTarget = "RAMissionMap_Ani_Dialog.ccbi",
        actionType = "addtouchlayer",
        param = "true",
        nextActionId = nil,
        desc = "添加点击层"
    },
    [2060] = {
        actionTarget = "RAMissionMap_Ani_Dialog.ccbi",
        actionType = "changelabel",
        varibleName = "mDialogue",
        param = "@dialog2",
        nextActionId = nil,
        desc = "对话：摧毁它是您的第一个任务"
    },
    [2070] = {
        actionTarget = "RAMissionMap_Ani_Dialog.ccbi",
        actionType = "runani",
        param = "Play",
        nextActionId = "2090",
        desc = "播放动画"
    },
    [2080] = {
        actionTarget = "RAMissionMap_Ani_Dialog.ccbi",
        actionType = "addtouchlayer",
        param = "false",
        nextActionId = nil,
        desc = "移除点击层"
    },
    [2090] = {
        actionTarget = "RAMissionMap_Ani_Dialog.ccbi",
        actionType = "addtouchlayer",
        param = "true",
        nextActionId = nil,
        desc = "添加点击层"
    },
    [2100] = {
        actionType = "showpage",
        varibleName = "RAMissionBarrierPage",
        param = "false",
        nextActionId = nil,
        desc = "移除对话框"
    },
    [2105] = {
        actionTarget = "RAMissionMap1.ccbi",
        actionType = "movecamera",
        varibleName = "mMarch1Point2",
        param = "0.5",
        nextActionId = "2110,2120",
        desc = "移动镜头到潜艇"
    },
    [2110] = {
        actionTarget = "RAMissionMap1_March1.ccbi",
        actionType = "runani",
        param = "March1_Timeline3",
        nextActionId = "2115",
        desc = "播放潜艇闪动动画"
    },
    [2115] = {
        actionTarget = "RAMissionMap_Ani_Dialog.ccbi",
        actionType = "addtouchlayer",
        param = "true",
        nextActionId = nil,
        desc = "添加点击层"
    },
    [2120] = {
        actionType = "showpage",
        varibleName = "RAMissionBarrierPage",
        param = "true",
        nextActionId = "2125,2130",
        desc = "显示对话框"
    },
    [2125] = {
        actionTarget = "RAMissionMap_Ani_Dialog.ccbi",
        actionType = "changelabel",
        varibleName = "mDialogue",
        param = "@dialog3",
        nextActionId = nil,
        desc = "对话：但是目前尤里派4艘"
    },
    [2130] = {
        actionTarget = "RAMissionMap_Ani_Dialog.ccbi",
        actionType = "runani",
        param = "Play",
        nextActionId = nil,
        desc = "播放动画"
    },
    [2140] = {
        actionTarget = "RAMissionMap_Ani_Dialog.ccbi",
        actionType = "changelabel",
        varibleName = "mDialogue",
        param = "@dialog4",
        nextActionId = nil,
        desc = "对话：我方部队无法接近"
    },
    [2145] = {
        actionTarget = "RAMissionMap_Ani_Dialog.ccbi",
        actionType = "addtouchlayer",
        param = "false",
        nextActionId = nil,
        desc = "移除点击层"
    },
    [2150] = {
        actionTarget = "RAMissionMap_Ani_Dialog.ccbi",
        actionType = "runani",
        param = "Play",
        nextActionId = "2155",
        desc = "播放动画"
    },
    [2155] = {
        actionTarget = "RAMissionMap_Ani_Dialog.ccbi",
        actionType = "addtouchlayer",
        param = "true",
        nextActionId = nil,
        desc = "添加点击层"
    },
    [2160] = {
        actionTarget = "RAMissionMap_Ani_Dialog.ccbi",
        actionType = "changelabel",
        varibleName = "mDialogue",
        param = "@dialog5",
        nextActionId = nil,
        desc = "对话：您需要首先解决掉这些雷鸣潜艇"
    },
    [2165] = {
        actionTarget = "RAMissionMap_Ani_Dialog.ccbi",
        actionType = "addtouchlayer",
        param = "false",
        nextActionId = nil,
        desc = "移除点击层"
    },
    [2170] = {
        actionTarget = "RAMissionMap_Ani_Dialog.ccbi",
        actionType = "runani",
        param = "Play",
        nextActionId = "2175",
        desc = "播放动画"
    },
    [2175] = {
        actionTarget = "RAMissionMap_Ani_Dialog.ccbi",
        actionType = "addtouchlayer",
        param = "true",
        nextActionId = nil,
        desc = "添加点击层"
    },
    [2180] = {
        actionTarget = "RAMissionMap_Ani_Dialog.ccbi",
        actionType = "changelabel",
        varibleName = "mDialogue",
        param = "@dialog6",
        nextActionId = nil,
        desc = "对话：然后与增援部队汇合"
    },
    [2185] = {
        actionTarget = "RAMissionMap_Ani_Dialog.ccbi",
        actionType = "addtouchlayer",
        param = "false",
        nextActionId = nil,
        desc = "移除点击层"
    },
    [2190] = {
        actionTarget = "RAMissionMap_Ani_Dialog.ccbi",
        actionType = "runani",
        param = "Play",
        nextActionId = "2195",
        desc = "播放动画"
    },
    [2195] = {
        actionTarget = "RAMissionMap_Ani_Dialog.ccbi",
        actionType = "addtouchlayer",
        param = "true",
        nextActionId = nil,
        desc = "添加点击层"
    },
    [2200] = {
        actionTarget = "RAMissionMap1.ccbi",
        actionType = "movecamera",
        varibleName = "mMarch1Point3",
        param = "0.5",
        nextActionId = nil,
        desc = "移动镜头到指挥官"
    },
    [2203] = {
        actionType = "showpage",
        varibleName = "RAMissionBarrierPage",
        param = "false",
        nextActionId = nil,
        desc = "隐藏对话框"
    },
    [2205] = {
        actionTarget = "RAMissionMap1_March1.ccbi",
        actionType = "runani",
        param = "March1_Timeline4",
        nextActionId = "2208",
        desc = "播放指挥官进场动画"
    },
    [2208] = {
        actionType = "showpage",
        varibleName = "RAMissionBarrierPage",
        param = "true",
        nextActionId = "2210,2220,2225",
        desc = "显示对话框"
    },
    [2210] = {
        actionTarget = "RAMissionMap_Ani_Dialog.ccbi",
        actionType = "changelabel",
        varibleName = "mDialogue",
        param = "@dialog7",
        nextActionId = nil,
        desc = "对话：我们已经从卫星上看到您了"
    },
    [2220] = {
        actionTarget = "RAMissionMap_Ani_Dialog.ccbi",
        actionType = "runani",
        param = "Play",
        nextActionId = "2228",
        desc = "播放动画"
    },
    [2225] = {
        actionTarget = "RAMissionMap_Ani_Dialog.ccbi",
        actionType = "changepic",
        varibleName = "mHeadPortraitNode",
        param = "HeadPortait_Sys.png",
        nextActionId = nil,
        desc = "显示头像"
    },
    [2228] = {
        actionTarget = "RAMissionMap_Ani_Dialog.ccbi",
        actionType = "addtouchlayer",
        param = "true",
        nextActionId = nil,
        desc = "添加点击层"
    },
    [2230] = {
        actionTarget = "RAMissionMap_Ani_Dialog.ccbi",
        actionType = "changelabel",
        varibleName = "mDialogue",
        param = "@dialog8",
        nextActionId = nil,
        desc = "对话：回头冲我们招招手"
    },
    [2235] = {
        actionTarget = "RAMissionMap_Ani_Dialog.ccbi",
        actionType = "addtouchlayer",
        param = "false",
        nextActionId = nil,
        desc = "移除点击层"
    },
    [2238] = {
        actionTarget = "RAMissionMap_Ani_Dialog.ccbi",
        actionType = "runani",
        param = "Play",
        nextActionId = "2240",
        desc = "播放动画"
    },
    [2240] = {
        actionTarget = "RAMissionMap1_March1.ccbi",
        actionType = "runani",
        param = "March1_Timeline5",
        nextActionId = "2245",
        desc = "播放指挥官招手动画"
    },
    [2245] = {
        actionTarget = "RAMissionMap_Ani_Dialog.ccbi",
        actionType = "addtouchlayer",
        param = "true",
        nextActionId = nil,
        desc = "添加点击层"
    },
    [2250] = {
        actionTarget = "RAMissionMap_Ani_Dialog.ccbi",
        actionType = "changelabel",
        varibleName = "mDialogue",
        param = "@dialog9",
        nextActionId = nil,
        desc = "对话：现在就请开始您的任务吧"
    },
    [2255] = {
        actionTarget = "RAMissionMap_Ani_Dialog.ccbi",
        actionType = "addtouchlayer",
        param = "false",
        nextActionId = nil,
        desc = "移除点击层"
    },
    [2260] = {
        actionTarget = "RAMissionMap_Ani_Dialog.ccbi",
        actionType = "runani",
        param = "Play",
        nextActionId = "2265",
        desc = "播放动画"
    },
    [2265] = {
        actionTarget = "RAMissionMap_Ani_Dialog.ccbi",
        actionType = "addtouchlayer",
        param = "true",
        nextActionId = nil,
        desc = "添加点击层"
    },
    [2270] = {
        actionType = "showpage",
        varibleName = "RAMissionBarrierPage",
        param = "false",
        nextActionId = nil,
        desc = "隐藏对话框"
    },
    [2280] = {
        actionTarget = "RAMissionMap1.ccbi",
        actionType = "movecamera",
        varibleName = "mMarch1Point4",
        param = "0.5",
        nextActionId = "2290",
        desc = "移动镜头到潜艇"
    },
    [2290] = {
        actionTarget = "RAMissionMap1_March1.ccbi",
        actionType = "runani",
        param = "March1_Timeline7",
        nextActionId = nil,
        desc = "播放指挥官安装潜艇炸弹动画"
    },
    [2310] = {
        actionTarget = "RAMissionMap1_March1.ccbi",
        actionType = "runani",
        param = "March1_Timeline9",
        nextActionId = "2320",
        desc = "播放潜艇爆炸动画"
    },
    [2320] = {
        actionTarget = "RAMissionMap1_March1.ccbi",
        actionType = "runani",
        param = "March1_Timeline10",
        nextActionId = "2400",
        desc = "播放汉克集合动画"
    },
--    [2330] = {
--        actionTarget = "RAMissionMap1_March1.ccbi",
--        actionType = "runani",
--        param = "March1_Timeline9",
--        nextActionId = "2340",
--        desc = "播放指挥官游泳炸潜艇动画"
--    },
--    [2340] = {
--        actionTarget = "RAMissionMap1_March1.ccbi",
--        actionType = "runani",
--        param = "March1_Timeline10",
--        nextActionId = nil,
--        desc = "播放第二个潜艇动画"
--    },
--    [2350] = {
--        actionTarget = "RAMissionMap1_March1.ccbi",
--        actionType = "runani",
--        param = "March1_Timeline11",
--        nextActionId = "2360",
--        desc = "播放第二个潜艇爆炸动画"
--    },
--    [2360] = {
--        actionTarget = "RAMissionMap1_March1.ccbi",
--        actionType = "runani",
--        param = "March1_Timeline12",
--        nextActionId = nil,
--        desc = "播放第三个潜艇动画"
--    },
--    [2370] = {
--        actionTarget = "RAMissionMap1_March1.ccbi",
--        actionType = "runani",
--        param = "March1_Timeline13",
--        nextActionId = "2380",
--        desc = "播放第三个潜艇爆炸动画"
--    },
--    [2380] = {
--        actionTarget = "RAMissionMap1_March1.ccbi",
--        actionType = "runani",
--        param = "March1_Timeline14",
--        nextActionId = nil,
--        desc = "播放第四个潜艇动画"
--    },
--    [2390] = {
--        actionTarget = "RAMissionMap1_March1.ccbi",
--        actionType = "runani",
--        param = "March1_Timeline15",
--        nextActionId = "2400",
--        desc = "播放第四个潜艇爆炸动画"
--    },
    [2400] = {
        actionType = "showpage",
        varibleName = "RAMissionBarrierPage",
        param = "true",
        nextActionId = "2410,2420,2430",
        desc = "显示对话框"
    },
    [2410] = {
        actionTarget = "RAMissionMap_Ani_Dialog.ccbi",
        actionType = "changepic",
        varibleName = "mHeadPortraitNode",
        param = "HeadPortait_Sys.png",
        nextActionId = nil,
        desc = "显示头像"
    },
    [2420] = {
        actionTarget = "RAMissionMap_Ani_Dialog.ccbi",
        actionType = "changelabel",
        varibleName = "mDialogue",
        param = "@dialog10",
        nextActionId = nil,
        desc = "对话：您好长官，幽灵小队前来支援"
    },
    [2430] = {
        actionTarget = "RAMissionMap_Ani_Dialog.ccbi",
        actionType = "runani",
        param = "Play",
        nextActionId = "2435",
        desc = "播放动画"
    },
    [2435] = {
        actionTarget = "RAMissionMap_Ani_Dialog.ccbi",
        actionType = "addtouchlayer",
        param = "true",
        nextActionId = nil,
        desc = "添加点击层"
    },
    [2440] = {
        actionTarget = "RAMissionMap_Ani_Dialog.ccbi",
        actionType = "changelabel",
        varibleName = "mDialogue",
        param = "@dialog11",
        nextActionId = nil,
        desc = "对话：我是汉克上尉，很高兴能与您一起作战"
    },
    [2445] = {
        actionTarget = "RAMissionMap_Ani_Dialog.ccbi",
        actionType = "addtouchlayer",
        param = "false",
        nextActionId = nil,
        desc = "移除点击层"
    },
    [2450] = {
        actionTarget = "RAMissionMap_Ani_Dialog.ccbi",
        actionType = "runani",
        param = "Play",
        nextActionId = "2455",
        desc = "播放动画"
    },
    [2455] = {
        actionTarget = "RAMissionMap_Ani_Dialog.ccbi",
        actionType = "addtouchlayer",
        param = "true",
        nextActionId = nil,
        desc = "添加点击层"
    },
    [2460] = {
        actionTarget = "RAMissionMap_Ani_Dialog.ccbi",
        actionType = "changepic",
        varibleName = "mHeadPortraitNode",
        param = "HeadPortait_Sys.png",
        nextActionId = nil,
        desc = "显示头像"
    },
    [2470] = {
        actionTarget = "RAMissionMap_Ani_Dialog.ccbi",
        actionType = "changelabel",
        varibleName = "mDialogue",
        param = "@dialog16",
        nextActionId = nil,
        desc = "对话：很好上尉，上面就是心灵图标"
    },
    [2475] = {
        actionTarget = "RAMissionMap_Ani_Dialog.ccbi",
        actionType = "addtouchlayer",
        param = "false",
        nextActionId = nil,
        desc = "移除点击层"
    },
    [2480] = {
        actionTarget = "RAMissionMap_Ani_Dialog.ccbi",
        actionType = "runani",
        param = "Play",
        nextActionId = "2485",
        desc = "播放动画"
    },
    [2485] = {
        actionTarget = "RAMissionMap_Ani_Dialog.ccbi",
        actionType = "addtouchlayer",
        param = "true",
        nextActionId = nil,
        desc = "添加点击层"
    },
    [2490] = {
        actionTarget = "RAMissionMap_Ani_Dialog.ccbi",
        actionType = "changelabel",
        varibleName = "mDialogue",
        param = "@dialog17",
        nextActionId = nil,
        desc = "对话：这附近还有一些尤里部队正在巡逻"
    },
    [2495] = {
        actionTarget = "RAMissionMap_Ani_Dialog.ccbi",
        actionType = "addtouchlayer",
        param = "false",
        nextActionId = nil,
        desc = "删除点击层"
    },
    [2500] = {
        actionTarget = "RAMissionMap_Ani_Dialog.ccbi",
        actionType = "runani",
        param = "Play",
        nextActionId = "2505",
        desc = "播放动画"
    },
    [2505] = {
        actionTarget = "RAMissionMap_Ani_Dialog.ccbi",
        actionType = "addtouchlayer",
        param = "true",
        nextActionId = nil,
        desc = "添加点击层"
    },
    [2510] = {
        actionTarget = "RAMissionMap_Ani_Dialog.ccbi",
        actionType = "changelabel",
        varibleName = "mDialogue",
        param = "@dialog18",
        nextActionId = nil,
        desc = "对话：你们拖住并解决掉他们"
    },
    [2515] = {
        actionTarget = "RAMissionMap_Ani_Dialog.ccbi",
        actionType = "addtouchlayer",
        param = "false",
        nextActionId = nil,
        desc = "移除点击层"
    },
    [2520] = {
        actionTarget = "RAMissionMap_Ani_Dialog.ccbi",
        actionType = "runani",
        param = "Play",
        nextActionId = "2525",
        desc = "播放动画"
    },
    [2525] = {
        actionTarget = "RAMissionMap_Ani_Dialog.ccbi",
        actionType = "addtouchlayer",
        param = "true",
        nextActionId = nil,
        desc = "添加点击层"
    },
    [2530] = {
        actionTarget = "RAMissionMap_Ani_Dialog.ccbi",
        actionType = "changepic",
        varibleName = "mHeadPortraitNode",
        param = "HeadPortait_Sys.png",
        nextActionId = nil,
        desc = "显示头像"
    },
    [2540] = {
        actionTarget = "RAMissionMap_Ani_Dialog.ccbi",
        actionType = "changelabel",
        varibleName = "mDialogue",
        param = "@dialog19",
        nextActionId = nil,
        desc = "对话：明白，长官"
    },
    [2545] = {
        actionTarget = "RAMissionMap_Ani_Dialog.ccbi",
        actionType = "addtouchlayer",
        param = "false",
        nextActionId = nil,
        desc = "移除点击层"
    },
    [2550] = {
        actionTarget = "RAMissionMap_Ani_Dialog.ccbi",
        actionType = "runani",
        param = "Play",
        nextActionId = "2555",
        desc = "播放动画"
    },
    [2555] = {
        actionTarget = "RAMissionMap_Ani_Dialog.ccbi",
        actionType = "addtouchlayer",
        param = "true",
        nextActionId = nil,
        desc = "添加点击层"
    },
    [2560] = {
        actionTarget = "RAMissionMap_Ani_Dialog.ccbi",
        actionType = "changepic",
        varibleName = "mHeadPortraitNode",
        param = "HeadPortait_Sys.png",
        nextActionId = nil,
        desc = "显示头像"
    },
    [2570] = {
        actionTarget = "RAMissionMap_Ani_Dialog.ccbi",
        actionType = "changelabel",
        varibleName = "mDialogue",
        param = "@dialog20",
        nextActionId = nil,
        desc = "对话：等我命令"
    },
    [2575] = {
        actionTarget = "RAMissionMap_Ani_Dialog.ccbi",
        actionType = "addtouchlayer",
        param = "false",
        nextActionId = nil,
        desc = "添加点击层"
    },
    [2580] = {
        actionTarget = "RAMissionMap1.ccbi",
        actionType = "movecamera",
        varibleName = "mMarchRouteStart1",
        param = "0.5",
        nextActionId = "2590",
        desc = "移动镜头到心灵探针"
    },
    [2590] = {
        actionTarget = "RAMissionMap1_March1.ccbi",
        actionType = "runani",
        param = "March1_Timeline12",
        nextActionId = "2595",
        desc = "播放心灵探针闪烁动画"
    },
    [2595] = {
        actionTarget = "RAMissionMap_Ani_Dialog.ccbi",
        actionType = "addtouchlayer",
        param = "true",
        nextActionId = nil,
        desc = "添加点击层"
    },
    [2596] = {
        actionTarget = "RAMissionMap_Ani_Dialog.ccbi",
        actionType = "changelabel",
        varibleName = "mDialogue",
        param = "@dialog22",
        nextActionId = nil,
        desc = "对话：Go"
    },
    [2597] = {
        actionTarget = "RAMissionMap_Ani_Dialog.ccbi",
        actionType = "addtouchlayer",
        param = "false",
        nextActionId = nil,
        desc = "移除点击层"
    },
    [2598] = {
        actionTarget = "RAMissionMap_Ani_Dialog.ccbi",
        actionType = "runani",
        param = "Play",
        nextActionId = "2600,2610",
        desc = "播放动画"
    },
    [2599] = {
        actionTarget = "RAMissionMap1_March1.ccbi",
        actionType = "addwalkline",
        varibleName = "mMarch1End,mMarch1Soldier1,mMarch1Soldier2,mMarch1Soldier3,mMarch1Soldier4,mMarch1Soldier5,mMarch1Soldier6,mMarch1Soldier7,mMarch1Soldier8,mMarch1Soldier9,mMarch1Soldier10",
        param = "4",
        nextActionId = nil,
        desc = "出现行走线"
    },
    [2600] = {
        actionTarget = "RAMissionMap1.ccbi",
        actionType = "delaytime",
        param = "3",
        nextActionId = "2605",
        desc = "延迟3s"
    },
    [2605] = {
        actionType = "showpage",
        varibleName = "RAMissionBarrierPage",
        param = "false",
        nextActionId = nil,
        desc = "移除对话框"
    },
    [2610] = {
        actionTarget = "RAMissionMap1.ccbi",
        actionType = "movecamera",
        varibleName = "mMarch1Point5",
        param = "0.5",
        nextActionId = "2620,2630",
        desc = "移动镜头到登陆地"
    },
    [2620] = {
        actionTarget = "RAMissionMap1.ccbi",
        actionType = "movecamera",
        varibleName = "mMarch1Point6",
        param = "3",
        nextActionId = nil,
        desc = "移动镜头到战斗位置"
    },
    [2630] = {
        actionTarget = "RAMissionMap1_March1.ccbi",
        actionType = "runani",
        param = "March1_Timeline13",
        nextActionId = "2640",
        desc = "播放部队攻击动画"
    },
    [2640] = {
        actionType = "gotonextstep",
    },




    [3000] = {
        actionTarget = "RAMissionMap1.ccbi",
        actionType = "delaytime",
        param = "2",
        nextActionId = "3020",
        desc = "延迟2s"
    },
    [3005] = {
        actionTarget = "RAMissionMap1.ccbi",
        actionType = "runani",
        param = "March2_Timeline1",
        nextActionId = nil,
        desc = "播放迷雾动画"
    },
    [3010] = {
        actionTarget = "RAMissionMap1_March2.ccbi",
        actionType = "runani",
        param = "March2_Timeline1",
        nextActionId = nil,
        desc = "播放心灵探针爆炸动画"
    },
    [3020] = {
        actionType = "showpage",
        varibleName = "RAMissionBarrierPage",
        param = "true",
        nextActionId = "3030,3040,3050",
        desc = "显示对话框"
    },
    [3030] = {
        actionTarget = "RAMissionMap_Ani_Dialog.ccbi",
        actionType = "changepic",
        varibleName = "mHeadPortraitNode",
        param = "HeadPortait_Sys.png",
        nextActionId = nil,
        desc = "显示头像"
    },
    [3040] = {
        actionTarget = "RAMissionMap_Ani_Dialog.ccbi",
        actionType = "changelabel",
        varibleName = "mDialogue",
        param = "@dialog30",
        nextActionId = nil,
        desc = "对话：心灵信标被摧毁"
    },
    [3050] = {
        actionTarget = "RAMissionMap_Ani_Dialog.ccbi",
        actionType = "runani",
        param = "Play",
        nextActionId = "3060",
        desc = "播放动画"
    },
    [3060] = {
        actionTarget = "RAMissionMap_Ani_Dialog.ccbi",
        actionType = "addtouchlayer",
        param = "true",
        nextActionId = nil,
        desc = "添加点击层"
    },
    [3070] = {
        actionTarget = "RAMissionMap_Ani_Dialog.ccbi",
        actionType = "changelabel",
        varibleName = "mDialogue",
        param = "@dialog31",
        nextActionId = nil,
        desc = "对话：接下来请前往军事基地建立联系"
    },
    [3080] = {
        actionTarget = "RAMissionMap_Ani_Dialog.ccbi",
        actionType = "addtouchlayer",
        param = "false",
        nextActionId = nil,
        desc = "移除点击层"
    },
    [3090] = {
        actionTarget = "RAMissionMap_Ani_Dialog.ccbi",
        actionType = "runani",
        param = "Play",
        nextActionId = "3100",
        desc = "播放动画"
    },
    [3100] = {
        actionTarget = "RAMissionMap_Ani_Dialog.ccbi",
        actionType = "addtouchlayer",
        param = "true",
        nextActionId = nil,
        desc = "添加点击层"
    },
    [3110] = {
        actionTarget = "RAMissionMap_Ani_Dialog.ccbi",
        actionType = "changepic",
        varibleName = "mHeadPortraitNode",
        param = "HeadPortait_Sys.png",
        nextActionId = nil,
        desc = "显示头像"
    },
    [3120] = {
        actionTarget = "RAMissionMap_Ani_Dialog.ccbi",
        actionType = "changelabel",
        varibleName = "mDialogue",
        param = "@dialog32",
        nextActionId = nil,
        desc = "对话：收到"
    },
    [3130] = {
        actionTarget = "RAMissionMap_Ani_Dialog.ccbi",
        actionType = "addtouchlayer",
        param = "false",
        nextActionId = nil,
        desc = "移除点击层"
    },
    [3140] = {
        actionTarget = "RAMissionMap_Ani_Dialog.ccbi",
        actionType = "runani",
        param = "Play",
        nextActionId = "3150",
        desc = "播放动画"
    },
    [3150] = {
        actionTarget = "RAMissionMap_Ani_Dialog.ccbi",
        actionType = "addtouchlayer",
        param = "true",
        nextActionId = nil,
        desc = "添加点击层"
    },
    [3160] = {
        actionTarget = "RAMissionMap_Ani_Dialog.ccbi",
        actionType = "changepic",
        varibleName = "mHeadPortraitNode",
        param = "HeadPortait_Sys.png",
        nextActionId = nil,
        desc = "显示头像"
    },
    [3170] = {
        actionTarget = "RAMissionMap_Ani_Dialog.ccbi",
        actionType = "changelabel",
        varibleName = "mDialogue",
        param = "@dialog34",
        nextActionId = nil,
        desc = "对话：长官，有一个不好的消息"
    },
    [3180] = {
        actionTarget = "RAMissionMap_Ani_Dialog.ccbi",
        actionType = "addtouchlayer",
        param = "false",
        nextActionId = nil,
        desc = "移除点击层"
    },
    [3190] = {
        actionTarget = "RAMissionMap_Ani_Dialog.ccbi",
        actionType = "runani",
        param = "Play",
        nextActionId = "3200",
        desc = "播放动画"
    },
    [3200] = {
        actionTarget = "RAMissionMap_Ani_Dialog.ccbi",
        actionType = "addtouchlayer",
        param = "true",
        nextActionId = nil,
        desc = "添加点击层"
    },
    [3210] = {
        actionType = "showpage",
        varibleName = "RAMissionBarrierPage",
        param = "false",
        nextActionId = nil,
        desc = "移除对话框"
    },
    [3220] = {
        actionTarget = "RAMissionMap1.ccbi",
        actionType = "movecamera",
        varibleName = "mMarch2Point2",
        param = "0.5",
        nextActionId = "3230",
        desc = "移动镜头到断桥"
    },
    [3225] = {
        actionTarget = "RAMissionMap1.ccbi",
        actionType = "runani",
        param = "March2_Timeline2",
        nextActionId = nil,
        desc = "播放迷雾动画"
    },
    [3230] = {
        actionType = "showpage",
        varibleName = "RAMissionBarrierPage",
        param = "true",
        nextActionId = "3240,3250,3260",
        desc = "显示对话框"
    },
    [3240] = {
        actionTarget = "RAMissionMap_Ani_Dialog.ccbi",
        actionType = "changepic",
        varibleName = "mHeadPortraitNode",
        param = "HeadPortait_Sys.png",
        nextActionId = nil,
        desc = "显示头像"
    },
    [3250] = {
        actionTarget = "RAMissionMap_Ani_Dialog.ccbi",
        actionType = "changelabel",
        varibleName = "mDialogue",
        param = "@dialog36",
        nextActionId = nil,
        desc = "对话：前往军事基地的桥梁被炸毁"
    },
    [3260] = {
        actionTarget = "RAMissionMap_Ani_Dialog.ccbi",
        actionType = "runani",
        param = "Play",
        nextActionId = "3270",
        desc = "播放动画"
    },
    [3270] = {
        actionTarget = "RAMissionMap_Ani_Dialog.ccbi",
        actionType = "addtouchlayer",
        param = "true",
        nextActionId = nil,
        desc = "添加点击层"
    },
    [3280] = {
        actionTarget = "RAMissionMap_Ani_Dialog.ccbi",
        actionType = "changepic",
        varibleName = "mHeadPortraitNode",
        param = "HeadPortait_Sys.png",
        nextActionId = nil,
        desc = "显示头像"
    },
    [3290] = {
        actionTarget = "RAMissionMap_Ani_Dialog.ccbi",
        actionType = "changelabel",
        varibleName = "mDialogue",
        param = "@dialog37",
        nextActionId = nil,
        desc = "对话：EVA少尉，请帮我们找到另一条路"
    },
    [3300] = {
        actionTarget = "RAMissionMap_Ani_Dialog.ccbi",
        actionType = "addtouchlayer",
        param = "false",
        nextActionId = nil,
        desc = "移除点击层"
    },
    [3310] = {
        actionTarget = "RAMissionMap_Ani_Dialog.ccbi",
        actionType = "runani",
        param = "Play",
        nextActionId = "3320",
        desc = "播放动画"
    },
    [3320] = {
        actionTarget = "RAMissionMap_Ani_Dialog.ccbi",
        actionType = "addtouchlayer",
        param = "true",
        nextActionId = nil,
        desc = "添加点击层"
    },
    [3330] = {
        actionTarget = "RAMissionMap_Ani_Dialog.ccbi",
        actionType = "changepic",
        varibleName = "mHeadPortraitNode",
        param = "HeadPortait_Sys.png",
        nextActionId = nil,
        desc = "显示头像"
    },
    [3340] = {
        actionTarget = "RAMissionMap_Ani_Dialog.ccbi",
        actionType = "changelabel",
        varibleName = "mDialogue",
        param = "@dialog371",
        nextActionId = nil,
        desc = "对话：路径搜索完毕"
    },
    [3350] = {
        actionTarget = "RAMissionMap_Ani_Dialog.ccbi",
        actionType = "addtouchlayer",
        param = "false",
        nextActionId = nil,
        desc = "移除点击层"
    },
    [3360] = {
        actionTarget = "RAMissionMap_Ani_Dialog.ccbi",
        actionType = "runani",
        param = "Play",
        nextActionId = nil,
        desc = "播放动画"
    },
    [3370] = {
        actionTarget = "RAMissionMap1.ccbi",
        actionType = "movecamera",
        varibleName = "mMarch2Point3",
        param = "2",
        nextActionId = "3380,3390,3400",
        desc = "移动镜头到第二步战斗地点"
    },
    [3380] = {
        actionTarget = "RAMissionMap_Ani_Dialog.ccbi",
        actionType = "changelabel",
        varibleName = "mDialogue",
        param = "@dialog38",
        nextActionId = nil,
        desc = "对话：我已经设置坐标位置，请立即前往"
    },
    [3390] = {
        actionTarget = "RAMissionMap_Ani_Dialog.ccbi",
        actionType = "runani",
        param = "Play",
        nextActionId = nil,
        desc = "播放动画"
    },
    [3400] = {
        actionTarget = "RAMissionMap1_March2.ccbi",
        actionType = "runani",
        param = "March2_Timeline3",
        nextActionId = nil,
        desc = "播放绿色行军标志"
    },
    [3410] = {
        actionType = "showpage",
        varibleName = "RAMissionBarrierPage",
        param = "false",
        nextActionId = nil,
        desc = "移除对话框"
    },
    [3415] = {
        actionTarget = "RAMissionMap1_March2.ccbi",
        actionType = "addwalkline",
        varibleName = "mMarch2End,mMarch2Soldier1,mMarch2Soldier2,mMarch2Soldier3,mMarch2Soldier4,mMarch2Soldier5,mMarch2Soldier6,mMarch2Soldier7,mMarch2Soldier8,mMarch2Soldier9,mMarch2Soldier10",
        param = "4",
        nextActionId = nil,
        desc = "出现行走线"
    },
    [3420] = {
        actionTarget = "RAMissionMap1.ccbi",
        actionType = "movecamera",
        varibleName = "mMarch2Point4",
        param = "0.5",
        nextActionId = "3430,3440,3445",
        desc = "移动镜头到第二次战斗起始位置"
    },
    [3430] = {
        actionTarget = "RAMissionMap1_March2.ccbi",
        actionType = "runani",
        param = "March2_Timeline5",
        nextActionId = "3500",
        desc = "播放第二次战斗集结动画"
    },
    [3440] = {
        actionTarget = "RAMissionMap1.ccbi",
        actionType = "movecamera",
        varibleName = "mMarch2Point6",
        param = "3",
        nextActionId = "3450",
        desc = "移动镜头到第二次战斗上坡位置"
    },
    [3445] = {
        actionTarget = "RAMissionMap1.ccbi",
        actionType = "runani",
        param = "March2_Timeline5",
        nextActionId = nil,
        desc = "播放迷雾动画"
    },
    [3450] = {
        actionTarget = "RAMissionMap1.ccbi",
        actionType = "movecamera",
        varibleName = "mMarch2Point5",
        param = "0.3",
        nextActionId = "3460",
        desc = "移动镜头到第二次战斗地点"
    },
    [3460] = {
        actionType = "showpage",
        varibleName = "RAMissionBarrierPage",
        param = "true",
        nextActionId = "3470,3480,3490",
        desc = "显示对话框"
    },
    [3470] = {
        actionTarget = "RAMissionMap_Ani_Dialog.ccbi",
        actionType = "changepic",
        varibleName = "mHeadPortraitNode",
        param = "HeadPortait_Sys.png",
        nextActionId = nil,
        desc = "显示头像"
    },
    [3480] = {
        actionTarget = "RAMissionMap_Ani_Dialog.ccbi",
        actionType = "changelabel",
        varibleName = "mDialogue",
        param = "@dialog39",
        nextActionId = nil,
        desc = "对话：尤里的巡逻队，我们快速解决他们"
    },
    [3490] = {
        actionTarget = "RAMissionMap_Ani_Dialog.ccbi",
        actionType = "runani",
        param = "Play",
        nextActionId = nil,
        desc = "播放动画"
    },
    [3500] = {
        actionType = "showpage",
        varibleName = "RAMissionBarrierPage",
        param = "false",
        nextActionId = "3510",
        desc = "移除对话框"
    },
    [3510] = {
        actionType = "gotonextstep",
    },

    [4000] = {
        actionTarget = "RAMissionMap1.ccbi",
        actionType = "delaytime",
        param = "1.5",
        nextActionId = "4010",
        desc = "延迟1.5s"
    },
    [4005] = {
        actionTarget = "RAMissionMap1_March3.ccbi",
        actionType = "runani",
        param = "March3_Timeline1",
        nextActionId = nil,
        desc = "播放第三次战斗的起始动画"
    },
    [4008] = {
        actionTarget = "RAMissionMap1.ccbi",
        actionType = "runani",
        param = "MarchEnd4_Timeline1",
        nextActionId = nil,
        desc = "播放迷雾动画"
    },
    [4010] = {
        actionType = "showpage",
        varibleName = "RAMissionBarrierPage",
        param = "true",
        nextActionId = "4020,4030,4040",
        desc = "显示对话框"
    },
    [4020] = {
        actionTarget = "RAMissionMap_Ani_Dialog.ccbi",
        actionType = "changepic",
        varibleName = "mHeadPortraitNode",
        param = "HeadPortait_Sys.png",
        nextActionId = nil,
        desc = "显示头像"
    },
    [4030] = {
        actionTarget = "RAMissionMap_Ani_Dialog.ccbi",
        actionType = "changelabel",
        varibleName = "mDialogue",
        param = "@dialog50",
        nextActionId = nil,
        desc = "对话：Eva少尉，我们已经抵达目的地"
    },
    [4040] = {
        actionTarget = "RAMissionMap_Ani_Dialog.ccbi",
        actionType = "runani",
        param = "Play",
        nextActionId = "4050",
        desc = "播放动画"
    },
    [4050] = {
        actionTarget = "RAMissionMap_Ani_Dialog.ccbi",
        actionType = "addtouchlayer",
        param = "true",
        nextActionId = nil,
        desc = "添加点击层"
    },
    [4060] = {
        actionTarget = "RAMissionMap_Ani_Dialog.ccbi",
        actionType = "changelabel",
        varibleName = "mDialogue",
        param = "@dialog51",
        nextActionId = nil,
        desc = "对话：请给出下一个坐标"
    },
    [4070] = {
        actionTarget = "RAMissionMap_Ani_Dialog.ccbi",
        actionType = "addtouchlayer",
        param = "false",
        nextActionId = nil,
        desc = "移除点击层"
    },
    [4080] = {
        actionTarget = "RAMissionMap_Ani_Dialog.ccbi",
        actionType = "runani",
        param = "Play",
        nextActionId = "4090",
        desc = "播放动画"
    },
    [4090] = {
        actionTarget = "RAMissionMap_Ani_Dialog.ccbi",
        actionType = "addtouchlayer",
        param = "true",
        nextActionId = nil,
        desc = "添加点击层"
    },
    [4100] = {
        actionTarget = "RAMissionMap_Ani_Dialog.ccbi",
        actionType = "changepic",
        varibleName = "mHeadPortraitNode",
        param = "HeadPortait_Sys.png",
        nextActionId = nil,
        desc = "显示头像"
    },
    [4110] = {
        actionTarget = "RAMissionMap_Ani_Dialog.ccbi",
        actionType = "changelabel",
        varibleName = "mDialogue",
        param = "@dialog53",
        nextActionId = nil,
        desc = "对话：已经找到地点"
    },
    [4120] = {
        actionTarget = "RAMissionMap_Ani_Dialog.ccbi",
        actionType = "addtouchlayer",
        param = "false",
        nextActionId = nil,
        desc = "移除点击层"
    },
    [4130] = {
        actionTarget = "RAMissionMap_Ani_Dialog.ccbi",
        actionType = "runani",
        param = "Play",
        nextActionId = "4140",
        desc = "播放动画"
    },
    [4135] = {
        actionTarget = "RAMissionMap1.ccbi",
        actionType = "movecamera",
        varibleName = "mMarch3Point2",
        param = "1.5",
        nextActionId = "4145",
        desc = "移动镜头到第三次战斗地点"
    },
    [4138] = {
        actionTarget = "RAMissionMap1.ccbi",
        actionType = "runani",
        param = "MarchEnd4_Timeline1",
        nextActionId = nil,
        desc = "播放迷雾动画"
    },
    [4140] = {
        actionTarget = "RAMissionMap_Ani_Dialog.ccbi",
        actionType = "addtouchlayer",
        param = "true",
        nextActionId = nil,
        desc = "添加点击层"
    },
    [4145] = {
        actionTarget = "RAMissionMap1_March3.ccbi",
        actionType = "runani",
        param = "March3_Timeline5",
        nextActionId = nil,
        desc = "播放伞兵降落动画"
    },
    [4150] = {
        actionTarget = "RAMissionMap_Ani_Dialog.ccbi",
        actionType = "changelabel",
        varibleName = "mDialogue",
        param = "@dialog54",
        nextActionId = nil,
        desc = "对话：雷达显示将会有少量尤里空降增援部队"
    },
    [4160] = {
        actionTarget = "RAMissionMap_Ani_Dialog.ccbi",
        actionType = "addtouchlayer",
        param = "false",
        nextActionId = nil,
        desc = "移除点击层"
    },
    [4170] = {
        actionTarget = "RAMissionMap_Ani_Dialog.ccbi",
        actionType = "runani",
        param = "Play",
        nextActionId = "4180",
        desc = "播放动画"
    },
    [4180] = {
        actionTarget = "RAMissionMap_Ani_Dialog.ccbi",
        actionType = "addtouchlayer",
        param = "true",
        nextActionId = nil,
        desc = "添加点击层"
    },
    [4190] = {
        actionTarget = "RAMissionMap_Ani_Dialog.ccbi",
        actionType = "changelabel",
        varibleName = "mDialogue",
        param = "@dialog55",
        nextActionId = nil,
        desc = "对话：需要再次寻找吗"
    },
    [4200] = {
        actionTarget = "RAMissionMap_Ani_Dialog.ccbi",
        actionType = "addtouchlayer",
        param = "false",
        nextActionId = nil,
        desc = "移除点击层"
    },
    [4210] = {
        actionTarget = "RAMissionMap_Ani_Dialog.ccbi",
        actionType = "runani",
        param = "Play",
        nextActionId = "4220",
        desc = "播放动画"
    },
    [4220] = {
        actionTarget = "RAMissionMap_Ani_Dialog.ccbi",
        actionType = "addtouchlayer",
        param = "true",
        nextActionId = nil,
        desc = "添加点击层"
    },
    [4230] = {
        actionTarget = "RAMissionMap_Ani_Dialog.ccbi",
        actionType = "changepic",
        varibleName = "mHeadPortraitNode",
        param = "HeadPortait_Sys.png",
        nextActionId = nil,
        desc = "显示头像"
    },
    [4240] = {
        actionTarget = "RAMissionMap_Ani_Dialog.ccbi",
        actionType = "changelabel",
        varibleName = "mDialogue",
        param = "@dialog56",
        nextActionId = nil,
        desc = "对话：就那里吧，我们时间不多了"
    },
    [4250] = {
        actionTarget = "RAMissionMap_Ani_Dialog.ccbi",
        actionType = "addtouchlayer",
        param = "false",
        nextActionId = nil,
        desc = "移除点击层"
    },
    [4260] = {
        actionTarget = "RAMissionMap_Ani_Dialog.ccbi",
        actionType = "runani",
        param = "Play",
        nextActionId = "4270",
        desc = "播放动画"
    },
    [4270] = {
        actionTarget = "RAMissionMap_Ani_Dialog.ccbi",
        actionType = "addtouchlayer",
        param = "true",
        nextActionId = nil,
        desc = "添加点击层"
    },
    [4280] = {
        actionTarget = "RAMissionMap_Ani_Dialog.ccbi",
        actionType = "changepic",
        varibleName = "mHeadPortraitNode",
        param = "HeadPortait_Sys.png",
        nextActionId = nil,
        desc = "显示头像"
    },
    [4290] = {
        actionTarget = "RAMissionMap_Ani_Dialog.ccbi",
        actionType = "changelabel",
        varibleName = "mDialogue",
        param = "@dialog58",
        nextActionId = nil,
        desc = "对话：标记完毕，请立即前往"
    },
    [4300] = {
        actionTarget = "RAMissionMap_Ani_Dialog.ccbi",
        actionType = "addtouchlayer",
        param = "false",
        nextActionId = nil,
        desc = "移除点击层"
    },
    [4310] = {
        actionTarget = "RAMissionMap_Ani_Dialog.ccbi",
        actionType = "runani",
        param = "Play",
        nextActionId = "4320",
        desc = "播放动画"
    },
    [4320] = {
        actionTarget = "RAMissionMap1_March3.ccbi",
        actionType = "runani",
        param = "March3_Timeline7",
        nextActionId = nil,
        desc = "播放绿色集结点动画"
    },
    [4330] = {
        actionType = "showpage",
        varibleName = "RAMissionBarrierPage",
        param = "false",
        nextActionId = nil,
        desc = "移除对话框"
    },
    [4340] = {
        actionTarget = "RAMissionMap1_March3.ccbi",
        actionType = "addwalkline",
        varibleName = "mMarch3End,mMarch3Soldier1,mMarch3Soldier2,mMarch3Soldier3,mMarch3Soldier4,mMarch3Soldier5,mMarch3Soldier6,mMarch3Soldier7,mMarch3Soldier8,mMarch3Soldier9,mMarch3Soldier10,mMarch3Tank1,mMarch3Tank2,mMarch3Commander1",
        param = "1",
        nextActionId = nil,
        desc = "出现行走线"
    },
    [4350] = {
        actionTarget = "RAMissionMap1.ccbi",
        actionType = "movecamera",
        varibleName = "mMarch3Point3",
        param = "0.5",
        nextActionId = "4355,4360",
        desc = "移动镜头到第三次战斗起始点"
    },
    [4355] = {
        actionTarget = "RAMissionMap1_March3.ccbi",
        actionType = "runani",
        param = "March3_Timeline8",
        nextActionId = "4370",
        desc = "播放第三次战斗行军动画"
    },
    [4360] = {
        actionTarget = "RAMissionMap1.ccbi",
        actionType = "movecamera",
        varibleName = "mMarch3Point4",
        param = "8",
        nextActionId = nil,
        desc = "移动镜头到第三次战斗终点"
    },
    [4370] = {
        actionType = "gotonextstep",
    },


    [5000] = {
        actionTarget = "RAMissionMap1.ccbi",
        actionType = "delaytime",
        param = "1.5",
        nextActionId = "5020",
        desc = "延迟1.5s"
    },
    [5005] = {
        actionTarget = "RAMissionMap1.ccbi",
        actionType = "runani",
        param = "MarchEnd4_Timeline1",
        nextActionId = nil,
        desc = "播放迷雾动画"
    },
    [5010] = {
        actionTarget = "RAMissionMap1_March4.ccbi",
        actionType = "runani",
        param = "March4_Timeline1",
        nextActionId = nil,
        desc = "播放爆炸动画"
    },
    [5020] = {
        actionType = "showpage",
        varibleName = "RAMissionBarrierPage",
        param = "true",
        nextActionId = "5030,5040,5050",
        desc = "显示对话框"
    },
    [5030] = {
        actionTarget = "RAMissionMap_Ani_Dialog.ccbi",
        actionType = "changepic",
        varibleName = "mHeadPortraitNode",
        param = "HeadPortait_Sys.png",
        nextActionId = nil,
        desc = "显示头像"
    },
    [5040] = {
        actionTarget = "RAMissionMap_Ani_Dialog.ccbi",
        actionType = "changelabel",
        varibleName = "mDialogue",
        param = "@dialog61",
        nextActionId = nil,
        desc = "对话：指挥官，再过一个街区就是军事基地了"
    },
    [5050] = {
        actionTarget = "RAMissionMap_Ani_Dialog.ccbi",
        actionType = "runani",
        param = "Play",
        nextActionId = "5060",
        desc = "播放动画"
    },
    [5060] = {
        actionTarget = "RAMissionMap_Ani_Dialog.ccbi",
        actionType = "addtouchlayer",
        param = "true",
        nextActionId = nil,
        desc = "添加点击层"
    },
    [5070] = {
        actionTarget = "RAMissionMap_Ani_Dialog.ccbi",
        actionType = "changelabel",
        varibleName = "mDialogue",
        param = "@dialog62",
        nextActionId = nil,
        desc = "对话：从卫星上看，军事基地已经被占领了"
    },
    [5080] = {
        actionTarget = "RAMissionMap_Ani_Dialog.ccbi",
        actionType = "addtouchlayer",
        param = "false",
        nextActionId = nil,
        desc = "移除点击层"
    },
    [5090] = {
        actionTarget = "RAMissionMap_Ani_Dialog.ccbi",
        actionType = "runani",
        param = "Play",
        nextActionId = "5100",
        desc = "播放动画"
    },
    [5095] = {
        actionTarget = "RAMissionMap1.ccbi",
        actionType = "movecamera",
        varibleName = "mMarch4Point2",
        param = "0.5",
        nextActionId = nil,
        desc = "移动镜头到第四次战斗位置"
    },
    [5100] = {
        actionTarget = "RAMissionMap_Ani_Dialog.ccbi",
        actionType = "addtouchlayer",
        param = "true",
        nextActionId = nil,
        desc = "添加点击层"
    },
    [5110] = {
        actionTarget = "RAMissionMap_Ani_Dialog.ccbi",
        actionType = "changelabel",
        varibleName = "mDialogue",
        param = "@dialog63",
        nextActionId = nil,
        desc = "对话：基地外围目前没有发现敌军"
    },
    [5120] = {
        actionTarget = "RAMissionMap_Ani_Dialog.ccbi",
        actionType = "addtouchlayer",
        param = "false",
        nextActionId = nil,
        desc = "移除点击层"
    },
    [5130] = {
        actionTarget = "RAMissionMap_Ani_Dialog.ccbi",
        actionType = "runani",
        param = "Play",
        nextActionId = "5140",
        desc = "播放动画"
    },
    [5140] = {
        actionTarget = "RAMissionMap_Ani_Dialog.ccbi",
        actionType = "addtouchlayer",
        param = "true",
        nextActionId = nil,
        desc = "添加点击层"
    },
    [5150] = {
        actionTarget = "RAMissionMap_Ani_Dialog.ccbi",
        actionType = "changepic",
        varibleName = "mHeadPortraitNode",
        param = "HeadPortait_Sys.png",
        nextActionId = nil,
        desc = "显示头像"
    },
    [5160] = {
        actionTarget = "RAMissionMap_Ani_Dialog.ccbi",
        actionType = "changelabel",
        varibleName = "mDialogue",
        param = "@dialog63",
        nextActionId = nil,
        desc = "对话：很好，汉克上尉，我们一鼓作气，拿下这里"
    },
    [5170] = {
        actionTarget = "RAMissionMap_Ani_Dialog.ccbi",
        actionType = "addtouchlayer",
        param = "false",
        nextActionId = nil,
        desc = "移除点击层"
    },
    [5180] = {
        actionTarget = "RAMissionMap_Ani_Dialog.ccbi",
        actionType = "runani",
        param = "Play",
        nextActionId = "5190",
        desc = "播放动画"
    },
    [5190] = {
        actionTarget = "RAMissionMap_Ani_Dialog.ccbi",
        actionType = "addtouchlayer",
        param = "true",
        nextActionId = nil,
        desc = "添加点击层"
    },
    [5200] = {
        actionTarget = "RAMissionMap_Ani_Dialog.ccbi",
        actionType = "changepic",
        varibleName = "mHeadPortraitNode",
        param = "HeadPortait_Sys.png",
        nextActionId = nil,
        desc = "显示头像"
    },
    [5210] = {
        actionTarget = "RAMissionMap_Ani_Dialog.ccbi",
        actionType = "changelabel",
        varibleName = "mDialogue",
        param = "@dialog64",
        nextActionId = nil,
        desc = "对话：遵命长官"
    },
    [5220] = {
        actionTarget = "RAMissionMap_Ani_Dialog.ccbi",
        actionType = "addtouchlayer",
        param = "false",
        nextActionId = nil,
        desc = "移除点击层"
    },
    [5230] = {
        actionTarget = "RAMissionMap_Ani_Dialog.ccbi",
        actionType = "runani",
        param = "Play",
        nextActionId = "5240",
        desc = "播放动画"
    },
    [5240] = {
        actionTarget = "RAMissionMap_Ani_Dialog.ccbi",
        actionType = "addtouchlayer",
        param = "true",
        nextActionId = nil,
        desc = "添加点击层"
    },
    [5250] = {
        actionType = "showpage",
        varibleName = "RAMissionBarrierPage",
        param = "false",
        nextActionId = nil,
        desc = "移除对话框"
    },
    [5260] = {
        actionTarget = "RAMissionMap1_March4.ccbi",
        actionType = "runani",
        param = "March4_Timeline4",
        nextActionId = nil,
        desc = "播放集结点动画"
    },
    [5270] = {
        actionTarget = "RAMissionMap1_March4.ccbi",
        actionType = "addwalkline",
        varibleName = "mMarch4End,mMarch4Soldier1,mMarch4Soldier2,mMarch4Soldier3,mMarch4Soldier4,mMarch4Soldier5,mMarch4Soldier6,mMarch4Soldier7,mMarch4Soldier8,mMarch4Soldier9,mMarch4Soldier10,mMarch4Tank1,mMarch4Tank2,mMarch4Commander1",
        param = "2",
        nextActionId = nil,
        desc = "出现行走线"
    },
    [5280] = {
        actionTarget = "RAMissionMap1.ccbi",
        actionType = "movecamera",
        varibleName = "mMarch4Point3",
        param = "0.5",
        nextActionId = "5290,5300",
        desc = "移动镜头到第四次战斗起始点"
    },
    [5290] = {
        actionTarget = "RAMissionMap1.ccbi",
        actionType = "movecamera",
        varibleName = "mMarch4Point4",
        param = "9",
        nextActionId = nil,
        desc = "移动镜头到第四次战斗位置"
    },
    [5300] = {
        actionTarget = "RAMissionMap1_March4.ccbi",
        actionType = "runani",
        param = "March4_Timeline5",
        nextActionId = "5310",
        desc = "播放第四次战斗行军动画"
    },
    [5310] = {
        actionType = "gotonextstep",
    },
    [6000] = {
        actionTarget = "RAMissionMap1.ccbi",
        actionType = "delaytime",
        param = "2",
        nextActionId = "6010",
        desc = "延迟2s"
    },
    [6005] = {
        actionTarget = "RAMissionMap1_MarchEnd4.ccbi",
        actionType = "runani",
        param = "MarchEnd4_Timeline1",
        nextActionId = nil,
        desc = "播放指挥官招手动画"
    },
    [6008] = {
        actionTarget = "RAMissionMap1.ccbi",
        actionType = "runani",
        param = "MarchEnd4_Timeline1",
        nextActionId = nil,
        desc = "播放迷雾动画"
    },
    [6010] = {
        actionType = "showpage",
        varibleName = "RAMissionBarrierPage",
        param = "true",
        nextActionId = "6020,6030,6040",
        desc = "显示对话框"
    },
    [6020] = {
        actionTarget = "RAMissionMap_Ani_Dialog.ccbi",
        actionType = "changepic",
        varibleName = "mHeadPortraitNode",
        param = "HeadPortait_Sys.png",
        nextActionId = nil,
        desc = "显示头像"
    },
    [6030] = {
        actionTarget = "RAMissionMap_Ani_Dialog.ccbi",
        actionType = "changelabel",
        varibleName = "mDialogue",
        param = "@dialog100",
        nextActionId = nil,
        desc = "对话：指挥官，卡维利将军要与您连线"
    },
    [6040] = {
        actionTarget = "RAMissionMap_Ani_Dialog.ccbi",
        actionType = "runani",
        param = "Play",
        nextActionId = "6050",
        desc = "播放动画"
    },
    [6050] = {
        actionTarget = "RAMissionMap_Ani_Dialog.ccbi",
        actionType = "addtouchlayer",
        param = "true",
        nextActionId = nil,
        desc = "添加点击层"
    },
    [6060] = {
        actionTarget = "RAMissionMap_Ani_Dialog.ccbi",
        actionType = "changepic",
        varibleName = "mHeadPortraitNode",
        param = "HeadPortait_Sys.png",
        nextActionId = nil,
        desc = "显示头像"
    },
    [6070] = {
        actionTarget = "RAMissionMap_Ani_Dialog.ccbi",
        actionType = "changelabel",
        varibleName = "mDialogue",
        param = "@dialog101",
        nextActionId = nil,
        desc = "对话：干得不错，指挥官"
    },
    [6080] = {
        actionTarget = "RAMissionMap_Ani_Dialog.ccbi",
        actionType = "addtouchlayer",
        param = "false",
        nextActionId = nil,
        desc = "移除点击层"
    },
    [6090] = {
        actionTarget = "RAMissionMap_Ani_Dialog.ccbi",
        actionType = "runani",
        param = "Play",
        nextActionId = "6100",
        desc = "播放动画"
    },
    [6100] = {
        actionTarget = "RAMissionMap_Ani_Dialog.ccbi",
        actionType = "addtouchlayer",
        param = "true",
        nextActionId = nil,
        desc = "添加点击层"
    },
    [6110] = {
        actionTarget = "RAMissionMap_Ani_Dialog.ccbi",
        actionType = "changelabel",
        varibleName = "mDialogue",
        param = "@dialog102",
        nextActionId = nil,
        desc = "对话：基地又重新回到我们手中"
    },
    [6120] = {
        actionTarget = "RAMissionMap_Ani_Dialog.ccbi",
        actionType = "addtouchlayer",
        param = "false",
        nextActionId = nil,
        desc = "移除点击层"
    },
    [6130] = {
        actionTarget = "RAMissionMap_Ani_Dialog.ccbi",
        actionType = "runani",
        param = "Play",
        nextActionId = "6140",
        desc = "播放动画"
    },
    [6140] = {
        actionTarget = "RAMissionMap_Ani_Dialog.ccbi",
        actionType = "addtouchlayer",
        param = "true",
        nextActionId = nil,
        desc = "添加点击层"
    },
    [6150] = {
        actionTarget = "RAMissionMap_Ani_Dialog.ccbi",
        actionType = "changelabel",
        varibleName = "mDialogue",
        param = "@dialog103",
        nextActionId = nil,
        desc = "对话：我们的增员部队马上就去前往驻守"
    },
    [6160] = {
        actionTarget = "RAMissionMap_Ani_Dialog.ccbi",
        actionType = "addtouchlayer",
        param = "false",
        nextActionId = nil,
        desc = "移除点击层"
    },
    [6170] = {
        actionTarget = "RAMissionMap_Ani_Dialog.ccbi",
        actionType = "runani",
        param = "Play",
        nextActionId = "6180",
        desc = "播放动画"
    },
    [6180] = {
        actionTarget = "RAMissionMap_Ani_Dialog.ccbi",
        actionType = "addtouchlayer",
        param = "true",
        nextActionId = nil,
        desc = "添加点击层"
    },
    [6190] = {
        actionTarget = "RAMissionMap_Ani_Dialog.ccbi",
        actionType = "changepic",
        varibleName = "mHeadPortraitNode",
        param = "HeadPortait_Sys.png",
        nextActionId = nil,
        desc = "显示头像"
    },
    [6200] = {
        actionTarget = "RAMissionMap_Ani_Dialog.ccbi",
        actionType = "changelabel",
        varibleName = "mDialogue",
        param = "@dialog106",
        nextActionId = nil,
        desc = "对话：事情可没想象那么简单"
    },
    [6210] = {
        actionTarget = "RAMissionMap_Ani_Dialog.ccbi",
        actionType = "addtouchlayer",
        param = "false",
        nextActionId = nil,
        desc = "移除点击层"
    },
    [6220] = {
        actionTarget = "RAMissionMap_Ani_Dialog.ccbi",
        actionType = "runani",
        param = "Play",
        nextActionId = "6230",
        desc = "播放动画"
    },
    [6230] = {
        actionTarget = "RAMissionMap_Ani_Dialog.ccbi",
        actionType = "addtouchlayer",
        param = "true",
        nextActionId = nil,
        desc = "添加点击层"
    },
    [6240] = {
        actionTarget = "RAMissionMap_Ani_Dialog.ccbi",
        actionType = "changelabel",
        varibleName = "mDialogue",
        param = "@dialog107",
        nextActionId = nil,
        desc = "对话：这里马上就会重新回到我的手中"
    },
    [6250] = {
        actionTarget = "RAMissionMap_Ani_Dialog.ccbi",
        actionType = "addtouchlayer",
        param = "false",
        nextActionId = nil,
        desc = "移除点击层"
    },
    [6260] = {
        actionTarget = "RAMissionMap_Ani_Dialog.ccbi",
        actionType = "runani",
        param = "Play",
        nextActionId = "6270",
        desc = "播放动画"
    },
    [6270] = {
        actionTarget = "RAMissionMap_Ani_Dialog.ccbi",
        actionType = "addtouchlayer",
        param = "true",
        nextActionId = nil,
        desc = "添加点击层"
    },
    [6280] = {
        actionTarget = "RAMissionMap_Ani_Dialog.ccbi",
        actionType = "changepic",
        varibleName = "mHeadPortraitNode",
        param = "HeadPortait_Sys.png",
        nextActionId = nil,
        desc = "显示头像"
    },
    [6290] = {
        actionTarget = "RAMissionMap_Ani_Dialog.ccbi",
        actionType = "changelabel",
        varibleName = "mDialogue",
        param = "@dialog110",
        nextActionId = nil,
        desc = "对话：尤里！！！我们绝不会让你得逞"
    },
    [6300] = {
        actionTarget = "RAMissionMap_Ani_Dialog.ccbi",
        actionType = "addtouchlayer",
        param = "false",
        nextActionId = nil,
        desc = "移除点击层"
    },
    [6310] = {
        actionTarget = "RAMissionMap_Ani_Dialog.ccbi",
        actionType = "runani",
        param = "Play",
        nextActionId = "6320",
        desc = "播放动画"
    },
    [6320] = {
        actionTarget = "RAMissionMap_Ani_Dialog.ccbi",
        actionType = "addtouchlayer",
        param = "true",
        nextActionId = nil,
        desc = "添加点击层"
    },
    [6330] = {
        actionTarget = "RAMissionMap_Ani_Dialog.ccbi",
        actionType = "changepic",
        varibleName = "mHeadPortraitNode",
        param = "HeadPortait_Sys.png",
        nextActionId = nil,
        desc = "显示头像"
    },
    [6340] = {
        actionTarget = "RAMissionMap_Ani_Dialog.ccbi",
        actionType = "changelabel",
        varibleName = "mDialogue",
        param = "@dialog111",
        nextActionId = nil,
        desc = "对话：指挥官，这雷达侦测有大批部队向您靠近"
    },
    [6350] = {
        actionTarget = "RAMissionMap_Ani_Dialog.ccbi",
        actionType = "addtouchlayer",
        param = "false",
        nextActionId = nil,
        desc = "移除点击层"
    },
    [6360] = {
        actionTarget = "RAMissionMap_Ani_Dialog.ccbi",
        actionType = "runani",
        param = "Play",
        nextActionId = "6390",
        desc = "播放动画"
    },
    [6370] = {
        actionTarget = "RAMissionMap1.ccbi",
        actionType = "movecamera",
        varibleName = "mMarch4EndPoint2",
        param = "0.5",
        nextActionId = nil,
        desc = "移动镜头到基地门口两条路上"
    },
    [6380] = {
        actionTarget = "RAMissionMap1_MarchEnd4.ccbi",
        actionType = "runani",
        param = "MarchEnd4_Timeline2",
        nextActionId = nil,
        desc = "播放尤里大部队从两条路涌过来的动画"
    },
    [6390] = {
        actionTarget = "RAMissionMap_Ani_Dialog.ccbi",
        actionType = "addtouchlayer",
        param = "true",
        nextActionId = nil,
        desc = "添加点击层"
    },
    [6400] = {
        actionType = "showpage",
        varibleName = "RAMissionBarrierPage",
        param = "false",
        nextActionId = nil,
        desc = "隐藏对话框"
    },
    [6410] = {
        actionTarget = "RAMissionMap1.ccbi",
        actionType = "movecamera",
        varibleName = "mMarch4EndPoint3",
        param = "0.5",
        nextActionId = "6420",
        desc = "移动镜头到基地"
    },
    [6420] = {
        actionType = "showpage",
        varibleName = "RAMissionBarrierPage",
        param = "true",
        nextActionId = "6430,6440,6450",
        desc = "显示对话框"
    },
    [6430] = {
        actionTarget = "RAMissionMap_Ani_Dialog.ccbi",
        actionType = "changepic",
        varibleName = "mHeadPortraitNode",
        param = "HeadPortait_Sys.png",
        nextActionId = nil,
        desc = "显示头像"
    },
    [6440] = {
        actionTarget = "RAMissionMap_Ani_Dialog.ccbi",
        actionType = "changelabel",
        varibleName = "mDialogue",
        param = "@dialog113",
        nextActionId = nil,
        desc = "对话：长官，您应该知道MCV的操作方式吧"
    },
    [6450] = {
        actionTarget = "RAMissionMap_Ani_Dialog.ccbi",
        actionType = "runani",
        param = "Play",
        nextActionId = "6460",
        desc = "播放动画"
    },
    [6460] = {
        actionTarget = "RAMissionMap_Ani_Dialog.ccbi",
        actionType = "addtouchlayer",
        param = "true",
        nextActionId = nil,
        desc = "添加点击层"
    },
    [6470] = {
        actionTarget = "RAMissionMap_Ani_Dialog.ccbi",
        actionType = "changelabel",
        varibleName = "mDialogue",
        param = "@dialog117",
        nextActionId = nil,
        desc = "对话：快去操作然后带走他，这交给我们"
    },
    [6480] = {
        actionTarget = "RAMissionMap_Ani_Dialog.ccbi",
        actionType = "addtouchlayer",
        param = "false",
        nextActionId = nil,
        desc = "移除点击层"
    },
    [6490] = {
        actionTarget = "RAMissionMap_Ani_Dialog.ccbi",
        actionType = "runani",
        param = "Play",
        nextActionId = "6500",
        desc = "播放动画"
    },
    [6500] = {
        actionTarget = "RAMissionMap_Ani_Dialog.ccbi",
        actionType = "addtouchlayer",
        param = "true",
        nextActionId = nil,
        desc = "添加点击层"
    },
    [6510] = {
        actionTarget = "RAMissionMap_Ani_Dialog.ccbi",
        actionType = "changepic",
        varibleName = "mHeadPortraitNode",
        param = "HeadPortait_Sys.png",
        nextActionId = nil,
        desc = "显示头像"
    },
    [6520] = {
        actionTarget = "RAMissionMap_Ani_Dialog.ccbi",
        actionType = "changelabel",
        varibleName = "mDialogue",
        param = "@dialog118",
        nextActionId = nil,
        desc = "对话：什么意思，那你怎么办"
    },
    [6530] = {
        actionTarget = "RAMissionMap_Ani_Dialog.ccbi",
        actionType = "addtouchlayer",
        param = "false",
        nextActionId = nil,
        desc = "移除点击层"
    },
    [6540] = {
        actionTarget = "RAMissionMap_Ani_Dialog.ccbi",
        actionType = "runani",
        param = "Play",
        nextActionId = "6550",
        desc = "播放动画"
    },
    [6550] = {
        actionTarget = "RAMissionMap_Ani_Dialog.ccbi",
        actionType = "addtouchlayer",
        param = "true",
        nextActionId = nil,
        desc = "添加点击层"
    },
    [6560] = {
        actionTarget = "RAMissionMap_Ani_Dialog.ccbi",
        actionType = "changepic",
        varibleName = "mHeadPortraitNode",
        param = "HeadPortait_Sys.png",
        nextActionId = nil,
        desc = "显示头像"
    },
    [6570] = {
        actionTarget = "RAMissionMap_Ani_Dialog.ccbi",
        actionType = "changelabel",
        varibleName = "mDialogue",
        param = "@dialog119",
        nextActionId = nil,
        desc = "对话：总要有人殿后"
    },
    [6580] = {
        actionTarget = "RAMissionMap_Ani_Dialog.ccbi",
        actionType = "addtouchlayer",
        param = "false",
        nextActionId = nil,
        desc = "移除点击层"
    },
    [6590] = {
        actionTarget = "RAMissionMap_Ani_Dialog.ccbi",
        actionType = "runani",
        param = "Play",
        nextActionId = "6600",
        desc = "播放动画"
    },
    [6600] = {
        actionTarget = "RAMissionMap_Ani_Dialog.ccbi",
        actionType = "addtouchlayer",
        param = "true",
        nextActionId = nil,
        desc = "添加点击层"
    },
    [6610] = {
        actionTarget = "RAMissionMap_Ani_Dialog.ccbi",
        actionType = "changepic",
        varibleName = "mHeadPortraitNode",
        param = "HeadPortait_Sys.png",
        nextActionId = nil,
        desc = "显示头像"
    },
    [6620] = {
        actionTarget = "RAMissionMap_Ani_Dialog.ccbi",
        actionType = "changelabel",
        varibleName = "mDialogue",
        param = "@dialog120",
        nextActionId = nil,
        desc = "对话：好，那你自己小心"
    },
    [6630] = {
        actionTarget = "RAMissionMap_Ani_Dialog.ccbi",
        actionType = "addtouchlayer",
        param = "false",
        nextActionId = nil,
        desc = "移除点击层"
    },
    [6640] = {
        actionTarget = "RAMissionMap_Ani_Dialog.ccbi",
        actionType = "runani",
        param = "Play",
        nextActionId = "6650",
        desc = "播放动画"
    },
    [6650] = {
        actionTarget = "RAMissionMap_Ani_Dialog.ccbi",
        actionType = "addtouchlayer",
        param = "true",
        nextActionId = nil,
        desc = "添加点击层"
    },
    [6660] = {
        actionType = "showpage",
        varibleName = "RAMissionBarrierPage",
        param = "false",
        nextActionId = nil,
        desc = "移除对话框"
    },
    [6670] = {
        actionTarget = "RAMissionMap1_MarchEnd4.ccbi",
        actionType = "runani",
        param = "MarchEnd4_Timeline4",
        nextActionId = nil,
        desc = "播放基地闪烁动画"        
    },
    [6680] = {
        actionTarget = "RAMissionMap1_MarchEnd4.ccbi",
        actionType = "addwalkline",
        varibleName = "mMarchEnd4Base,mMarchEnd4Commander1",
        param = "1",
        nextActionId = nil,
        desc = "出现行走线"
    },
    [6690] = {
        actionTarget = "RAMissionMap1_MarchEnd4.ccbi",
        actionType = "runani",
        param = "MarchEnd4_Timeline6",
        nextActionId = "6700",
        desc = "播放指挥官跑向主基地动画"
    },
    [6700] = {
        actionTarget = "RAMissionMap1_MarchEnd4.ccbi",
        actionType = "addspine",
        varibleName = "mMarchEnd4BaseSpine",
        param = "201001",
        nextActionId = "6710,6720",
        desc = "添加spine"
    },
    [6710] = {
        actionTarget = "201001",
        actionType = "runspineani",
        param = "Constructionoutside",
        nextActionId = "6730,6740,6750",
        desc = "播放主基地变形为基地车的动画"
    },
    [6720] = {
        actionTarget = "RAMissionMap1_MarchEnd4.ccbi",
        actionType = "shownode",
        varibleName = "mMarchEnd4Base",
        param = "false",
        nextActionId = nil,
        desc = "隐藏ccb上的主基地"
    },
    [6730] = {
        actionTarget = "RAMissionMap1_MarchEnd4.ccbi",
        actionType = "runani",
        param = "MarchEnd4_Timeline8",
        nextActionId = nil,
        desc = "播放基地车开走动画"
    },
    [6740] = {
        actionTarget = "RAMissionMap1_MarchEnd4.ccbi",
        actionType = "shownode",
        varibleName = "mMarchEnd4BaseSpine",
        param = "false",
        nextActionId = nil,
        desc = "隐藏spine节点"
    },
    [6750] = {
        actionTarget = "RAMissionMap1.ccbi",
        actionType = "movecamera",
        varibleName = "mMarch4EndPoint4",
        param = "4",
        nextActionId = "6760",
        desc = "移动镜头跟随基地车"
    },
    [6760] = {
        actionType = "gotonextstep",
    },

    --新手专用
    [10000002] = {
        actionType = "showpage",
        varibleName = "RAMissionBarrierGuideDialogPage",
        param = "true",
        nextActionId = "10000003",
        desc = "显示对话框"
    },
    [10000003] = {
        actionTarget = "RAGuidePage.ccbi",
        actionType = "shownode",
        varibleName = "mBGColor",
        param = "true",
        nextActionId = "10000004",
        desc = "显示黑色底层"
    },
    [10000004] = {
        actionTarget = "RAGuidePage.ccbi",
        actionType = "setcapacity",
        varibleName = "mBGColor",
        param = 255,
        nextActionId = "10000006,10000005,10000007,10000011",
        desc = "设置黑色底层为不透明"
    },
    [10000005] = {
        actionTarget = "RAGuidePage.ccbi",
        actionType = "changelabel",
        varibleName = "mGuideLabel",
        param = "@Guidedialog50",
        nextActionId = nil,
        desc = "对话：Guidedialog50"
    },
    [10000006] = {
        actionTarget = "RAGuidePage.ccbi",
        actionType = "shownode",
        varibleName = "mGuideLabel",
        param = "true",
        nextActionId = nil,
        desc = "显示文字"
    },
    [10000007] = {
        actionTarget = "RAGuidePage.ccbi",
        actionType = "runani",
        param = "LabelAni",
        nextActionId = "10000008",
        desc = "播放文字动画"
    },
    [10000011] = {
        actionType = "playmusic",
        varibleName = "blackScreenSubtitleCursor.mp3",
        param = "effect,false",
        nextActionId = nil,
        desc = "播放黑屏打字音效"
    },	
    [10000008] = {
        actionTarget = "RAGuidePage.ccbi",
        actionType = "changelabel",
        varibleName = "mGuideLabel",
        param = "@Guidedialog60",
        nextActionId = "10000009,10000012",
        desc = "对话：Guidedialog60"
    },
    [10000009] = {
        actionTarget = "RAGuidePage.ccbi",
        actionType = "runani",
        param = "LabelAni",
        nextActionId = "10000010,10000015",
        desc = "播放文字动画"
    },
    [10000012] = {
        actionType = "playmusic",
        varibleName = "blackScreenSubtitleCursor.mp3",
        param = "effect,false",
        nextActionId = nil,
        desc = "播放黑屏打字音效"
    },	
    [10000010] = {
        actionTarget = "RAGuidePage.ccbi",
        actionType = "shownode",
        varibleName = "mGuideLabel",
        param = "false",
        nextActionId = nil,
        desc = "隐藏文字"
    },
    [10000015] = {
        actionTarget = "RAGuidePage.ccbi",
        actionType = "shownode",
        varibleName = "mBGColor",
        param = "false",
        nextActionId = "10000020",
        desc = "隐藏黑色底层"
    },
    [10000020] = {
        actionType = "addccb",
        actionTarget = "RAGuidePage.ccbi",
        varibleName = "mBottomGuideTalkNode",
        param = "RAGuideLabelBlueNode.ccbi",
        nextActionId = "10000030,10000040,10000045",
        desc = "把文字框加入到对话框"
    },
    [10000030] = {
        actionType = "addccb",
        actionTarget = "RAGuideLabelBlueNode.ccbi",
        varibleName = "mBustNode",
        param = "RAGuideBustNode.ccbi",
        nextActionId = "10000050",
        desc = "把图像框加入到文字框"
    },
    [10000040] = {
        actionTarget = "RAGuideLabelBlueNode.ccbi",
        actionType = "changelabel",
        varibleName = "mRightGuideLabel",
        param = "@Guidedialog1",
        nextActionId = "10000060,10000065",
        desc = "对话：卡维利将军，目前有一好一坏两个消息"
    },
    [10000045] = {
        actionTarget = "RAGuideLabelBlueNode.ccbi",
        actionType = "changelabel",
        varibleName = "mGuideName",
        param = "@GuideName1",
        nextActionId = nil,
        desc = "设置显示名字"
    },
    [10000050] = {
        actionTarget = "RAGuideBustNode.ccbi",
        actionType = "changepic",
        varibleName = "mLeftBustPic",
        param = "tutorial.png",
        nextActionId = "10000070",
        desc = "显示头像"
    },
    [10000060] = {
        actionTarget = "RAGuideLabelBlueNode.ccbi",
        actionType = "runani",
        param = "InAni",
        nextActionId = nil,
        desc = "播放文字框进入动画"
    },
    [10000065] = {
        actionType = "playmusic",
        varibleName = "DialogueAdmission.mp3",
        param = "effect,false",
        nextActionId = nil,
        desc = "播放对话打字音效"
    },	
    [10000070] = {
        actionTarget = "RAGuideBustNode.ccbi",
        actionType = "runani",
        param = "LeftAni",
        nextActionId = "10000080",
        desc = "播放图像框进入动画"
    },
    [10000080] = {
        actionTarget = "RAGuidePage.ccbi",
        actionType = "addtouchlayer",
        param = "true",
        nextActionId = nil,
        desc = "添加点击层"
    },
    [10000090] = {
        actionTarget = "RAGuideLabelBlueNode.ccbi",
        actionType = "changelabel",
        varibleName = "mRightGuideLabel",
        param = "@Guidedialog2",
        nextActionId = "10000110,10000115",
        desc = "对话：坏消息是尤里部队已经占领R区"
    },
    [10000100] = {
        actionTarget = "RAGuidePage.ccbi",
        actionType = "addtouchlayer",
        param = "false",
        nextActionId = nil,
        desc = "移除点击层"
    },
    [10000110] = {
        actionTarget = "RAGuideLabelBlueNode.ccbi",
        actionType = "runani",
        param = "LabelAni",
        nextActionId = "10000120",
        desc = "播放文字打印动画"
    },
    [10000115] = {
        actionType = "playmusic",
        varibleName = "DialogueAdmission.mp3",
        param = "effect,false",
        nextActionId = nil,
        desc = "播放对话打字音效"
    },	
    [10000120] = {
        actionTarget = "RAGuidePage.ccbi",
        actionType = "addtouchlayer",
        param = "true",
        nextActionId = nil,
        desc = "添加点击层"
    },
    [10000130] = {
        actionTarget = "RAGuideLabelBlueNode.ccbi",
        actionType = "changelabel",
        varibleName = "mRightGuideLabel",
        param = "@Guidedialog7",
        nextActionId = "10000150,10000155",
        desc = "对话：好消息是，我们发现尤里A作战区的总指挥部"
    },
    [10000140] = {
        actionTarget = "RAGuidePage.ccbi",
        actionType = "addtouchlayer",
        param = "false",
        nextActionId = nil,
        desc = "移除点击层"
    },
    [10000150] = {
        actionTarget = "RAGuideLabelBlueNode.ccbi",
        actionType = "runani",
        param = "LabelAni",
        nextActionId = "10000160",
        desc = "播放文字打印动画"
    },
    [10000155] = {
        actionType = "playmusic",
        varibleName = "DialogueAdmission.mp3",
        param = "effect,false",
        nextActionId = nil,
        desc = "播放对话打字音效"
    },
    [10000160] = {
        actionTarget = "RAGuidePage.ccbi",
        actionType = "addtouchlayer",
        param = "true",
        nextActionId = nil,
        desc = "添加点击层"
    },
    [10000170] = {
        actionTarget = "RAGuideBustNode.ccbi",
        actionType = "runani",
        param = "LeftOutAni",
        nextActionId = nil,
        desc = "播放图像框离开动画"
    },
    [10000180] = {
        actionTarget = "RAGuideLabelBlueNode.ccbi",
        actionType = "runani",
        param = "OutAni",
        nextActionId = nil,
        desc = "播放文字框离开动画"
    },
    [10000190] = {
        actionTarget = "RAMissionMap2.ccbi",
        actionType = "delaytime",
        param = "0.2",
        nextActionId = "10000210",
        desc = "延迟0.2s"
    },
    [10000200] = {
        actionTarget = "RAGuidePage.ccbi",
        actionType = "addtouchlayer",
        param = "false",
        nextActionId = nil,
        desc = "移除点击层"
    },
    [10000210] = {
        actionType = "addccb",
        actionTarget = "RAGuidePage.ccbi",
        varibleName = "mBottomGuideTalkNode",
        param = "RAGuideLabelBlueNode2.ccbi",
        nextActionId = "10000220,10000230,10000235",
        desc = "把文字框加入到对话框"
    },
    [10000220] = {
        actionType = "changeparent",
        actionTarget = "RAGuideLabelBlueNode2.ccbi",
        varibleName = "mBustNode",
        param = "RAGuideBustNode.ccbi",
        nextActionId = "10000240",
        desc = "把图像框加入到当前文字框"
    },
    [10000230] = {
        actionTarget = "RAGuideLabelBlueNode2.ccbi",
        actionType = "changelabel",
        varibleName = "mRightGuideLabel",
        param = "@Guidedialog10000230",
        nextActionId = "10000250,10000255",
        desc = "对话：非常好，立刻执行既定作战计划"
    },
	[10000235] = {
        actionTarget = "RAGuideLabelBlueNode2.ccbi",
        actionType = "changelabel",
        varibleName = "mGuideName",
        param = "@GuideName2",
        nextActionId = nil,
        desc = "设置显示名字"
    },
    [10000240] = {
        actionTarget = "RAGuideBustNode.ccbi",
        actionType = "changepic",
        varibleName = "mRightBustPic",
        param = "Guide_Bust_General.png",
        nextActionId = "10000260",
        desc = "显示头像"
    },
    [10000250] = {
        actionTarget = "RAGuideLabelBlueNode2.ccbi",
        actionType = "runani",
        param = "InAni",
        nextActionId = nil,
        desc = "播放文字框进入动画"
    },
    [10000255] = {
        actionType = "playmusic",
        varibleName = "DialogueAdmission.mp3",
        param = "effect,false",
        nextActionId = nil,
        desc = "播放对话打字音效"
    },
    [10000260] = {
        actionTarget = "RAGuideBustNode.ccbi",
        actionType = "runani",
        param = "RightAni",
        nextActionId = "10000270",
        desc = "播放图像框进入动画"
    },
    [10000270] = {
        actionTarget = "RAGuidePage.ccbi",
        actionType = "addtouchlayer",
        param = "true",
        nextActionId = nil,
        desc = "添加点击层"
    },
    [10000280] = {
        actionTarget = "RAGuidePage.ccbi",
        actionType = "addtouchlayer",
        param = "false",
        nextActionId = nil,
        desc = "移除点击层"
    },
    [10000290] = {
        actionTarget = "RAGuideLabelBlueNode2.ccbi",
        actionType = "changelabel",
        varibleName = "mRightGuideLabel",
        param = "@Guidedialog10000290",
        nextActionId = "10000300,10000305",
        desc = "对话：通讯官，接入卫星视频影像"
    },
    [10000300] = {
        actionTarget = "RAGuideLabelBlueNode2.ccbi",
        actionType = "runani",
        param = "LabelAni",
        nextActionId = "10000310",
        desc = "播放文字打印动画"
    },
    [10000305] = {
        actionType = "playmusic",
        varibleName = "DialogueAdmission.mp3",
        param = "effect,false",
        nextActionId = nil,
        desc = "播放对话打字音效"
    },
    [10000310] = {
        actionTarget = "RAGuidePage.ccbi",
        actionType = "addtouchlayer",
        param = "true",
        nextActionId = nil,
        desc = "添加点击层"
    },
    [10000320] = {
        actionType = "gotofight",
        param = "1",
        nextActionId = nil,
        desc = "进入第一关战斗"
    },
    [10000330] = {
        actionTarget = "RAGuidePage.ccbi",
        actionType = "addtouchlayer",
        param = "false",
        nextActionId = nil,
        desc = "移除点击层"
    },
    [10000340] = {
        actionTarget = "RAGuideBustNode.ccbi",
        actionType = "runani",
        param = "RightOutAni",
        nextActionId = nil,
        desc = "播放图像框离开动画"
    },
    [10000350] = {
        actionTarget = "RAGuideLabelBlueNode2.ccbi",
        actionType = "runani",
        param = "OutAni",
        nextActionId = nil,
        desc = "播放文字框离开动画"
    },
    [10000360] = {
        actionType = "addccb",
        actionTarget = "RAGuidePage.ccbi",
        varibleName = "mBottomGuideTalkNode",
        param = "RAGuideLabelRedNode.ccbi",
        nextActionId = "10000370,10000380,10000385",
        desc = "把文字框加入到对话框"
    },
    [10000370] = {
        actionType = "changeparent",
        actionTarget = "RAGuideLabelRedNode.ccbi",
        varibleName = "mBustNode",
        param = "RAGuideBustNode.ccbi",
        nextActionId = "10000390",
        desc = "把图像框加入到当前文字框"
    },
    [10000380] = {
        actionTarget = "RAGuideLabelRedNode.ccbi",
        actionType = "changelabel",
        varibleName = "mRightGuideLabel",
        param = "@Guidedialog10000380",
        nextActionId = "10000400,10000405",
        desc = "对话：你们以为这样就能阻止我了吗"
    },
	[10000385] = {
        actionTarget = "RAGuideLabelRedNode.ccbi",
        actionType = "changelabel",
        varibleName = "mGuideName",
        param = "@GuideName4",
        nextActionId = nil,
        desc = "设置显示名字"
    },
    [10000390] = {
        actionTarget = "RAGuideBustNode.ccbi",
        actionType = "changepic",
        varibleName = "mRightBustPic",
        param = "Guide_Bust_Commander.png",
        nextActionId = "10000410",
        desc = "显示头像"
    },
    [10000400] = {
        actionTarget = "RAGuideLabelRedNode.ccbi",
        actionType = "runani",
        param = "InAni",
        nextActionId = "10000420",
        desc = "播放文字框进入动画"
    },
    [10000405] = {
        actionType = "playmusic",
        varibleName = "DialogueAdmission.mp3",
        param = "effect,false",
        nextActionId = nil,
        desc = "播放对话打字音效"
    },
    [10000410] = {
        actionTarget = "RAGuideBustNode.ccbi",
        actionType = "runani",
        param = "RightAni",
        nextActionId = nil,
        desc = "播放图像框进入动画"
    },
    [10000420] = {
        actionTarget = "RAGuidePage.ccbi",
        actionType = "addtouchlayer",
        param = "true",
        nextActionId = nil,
        desc = "添加点击层"
    },
    [10000430] = {
        actionTarget = "RAGuidePage.ccbi",
        actionType = "addtouchlayer",
        param = "false",
        nextActionId = nil,
        desc = "删除点击层"
    },
    [10000440] = {
        actionTarget = "RAGuideLabelRedNode.ccbi",
        actionType = "runani",
        param = "OutAni",
        nextActionId = nil,
        desc = "播放文字框离开动画"
    },
    [10000450] = {
        actionTarget = "RAGuideBustNode.ccbi",
        actionType = "runani",
        param = "RightOutAni",
        nextActionId = nil,
        desc = "播放图像框离开动画"
    },
    [10000460] = {
        actionTarget = "RAGuidePage.ccbi",
        actionType = "delaytime",
        param = "0.2",
        nextActionId = "10000470",
        desc = "延迟0.2s"
    },
    [10000470] = {
        actionType = "changeparent",
        actionTarget = "RAGuideLabelBlueNode.ccbi",
        varibleName = "mBustNode",
        param = "RAGuideBustNode.ccbi",
        nextActionId = "10000480,10000490,10000495",
        desc = "把图像框加入到当前文字框"
    },
    [10000480] = {
        actionTarget = "RAGuideLabelBlueNode.ccbi",
        actionType = "changelabel",
        varibleName = "mRightGuideLabel",
        param = "@Guidedialog10000480",
        nextActionId = "10000500,10000505",
        desc = "对话：尤里？"
    },
    [10000490] = {
        actionTarget = "RAGuideBustNode.ccbi",
        actionType = "changepic",
        varibleName = "mLeftBustPic",
        param = "Guide_Bust_General.png",
        nextActionId = "10000510",
        desc = "显示头像"
    },
	[10000495] = {
        actionTarget = "RAGuideLabelBlueNode.ccbi",
        actionType = "changelabel",
        varibleName = "mGuideName",
        param = "@GuideName2",
        nextActionId = nil,
        desc = "设置显示名字"
    },
    [10000500] = {
        actionTarget = "RAGuideLabelBlueNode.ccbi",
        actionType = "runani",
        param = "InAni",
        nextActionId = "10000520",
        desc = "播放文字框进入动画"
    },
    [10000505] = {
        actionType = "playmusic",
        varibleName = "DialogueAdmission.mp3",
        param = "effect,false",
        nextActionId = nil,
        desc = "播放对话打字音效"
    },
    [10000510] = {
        actionTarget = "RAGuideBustNode.ccbi",
        actionType = "runani",
        param = "LeftAni",
        nextActionId = nil,
        desc = "播放图像框进入动画"
    },
    [10000520] = {
        actionTarget = "RAGuidePage.ccbi",
        actionType = "addtouchlayer",
        param = "true",
        nextActionId = nil,
        desc = "添加点击层"
    },
    [10000530] = {
        actionTarget = "RAGuidePage.ccbi",
        actionType = "addtouchlayer",
        param = "false",
        nextActionId = nil,
        desc = "删除点击层"
    },
    [10000540] = {
        actionTarget = "RAGuideLabelBlueNode.ccbi",
        actionType = "runani",
        param = "OutAni",
        nextActionId = nil,
        desc = "播放文字框离开动画"
    },
    [10000550] = {
        actionTarget = "RAGuideBustNode.ccbi",
        actionType = "runani",
        param = "LeftOutAni",
        nextActionId = "10000551",
        desc = "播放图像框离开动画"
    },
    [10000551] = {
        actionTarget = "RAGuidePage.ccbi",
        actionType = "delaytime",
        param = "1",
        nextActionId = "10000552",
        desc = "延迟1s心灵控制音效"
    },
    [10000552] = {
        actionType = "playmusic",
        varibleName = "mindControlOpen.mp3",
        param = "effect,false",
        nextActionId = nil,
        desc = "播放心灵控制音效"
    },
    [10000560] = {
        actionType = "sendmessage",
        varibleName = 500003,
        param = "state_8",
        nextActionId = nil,
        desc = "调用函数"
    },
    [10000570] = {
        actionTarget = "RAGuideLabelBlueNode.ccbi",
        actionType = "changelabel",
        varibleName = "mRightGuideLabel",
        param = "@Guidedialog10000570",
        nextActionId = "10000590,10000593,10000595",
        desc = "对话：我们的士兵都叛变了，尤里你这卑鄙小人"
    },
    [10000580] = {
        actionTarget = "RAGuideBustNode.ccbi",
        actionType = "changepic",
        varibleName = "mLeftBustPic",
        param = "Guide_Bust_General.png",
        nextActionId = "10000600",
        desc = "显示头像"
    },
    [10000590] = {
        actionTarget = "RAGuideLabelBlueNode.ccbi",
        actionType = "runani",
        param = "InAni",
        nextActionId = "10000610",
        desc = "播放文字框进入动画"
    },
    [10000593] = {
        actionType = "playmusic",
        varibleName = "DialogueAdmission.mp3",
        param = "effect,false",
        nextActionId = nil,
        desc = "播放对话打字音效"
    },
	[10000595] = {
        actionTarget = "RAGuideLabelBlueNode.ccbi",
        actionType = "changelabel",
        varibleName = "mGuideName",
        param = "@GuideName2",
        nextActionId = nil,
        desc = "设置显示名字"
    },
    [10000600] = {
        actionTarget = "RAGuideBustNode.ccbi",
        actionType = "runani",
        param = "LeftAni",
        nextActionId = nil,
        desc = "播放图像框进入动画"
    },
    [10000610] = {
        actionTarget = "RAGuidePage.ccbi",
        actionType = "addtouchlayer",
        param = "true",
        nextActionId = nil,
        desc = "添加点击层"
    },
    [10000620] = {
        actionTarget = "RAGuidePage.ccbi",
        actionType = "addtouchlayer",
        param = "false",
        nextActionId = nil,
        desc = "删除点击层"
    },
    [10000630] = {
        actionTarget = "RAGuideLabelBlueNode.ccbi",
        actionType = "runani",
        param = "OutAni",
        nextActionId = nil,
        desc = "播放文字框离开动画"
    },
    [10000640] = {
        actionTarget = "RAGuideBustNode.ccbi",
        actionType = "runani",
        param = "LeftOutAni",
        nextActionId = nil,
        desc = "播放图像框离开动画"
    },
    [10000650] = {
        actionTarget = "RAGuidePage.ccbi",
        actionType = "delaytime",
        param = "0.2",
        nextActionId = "10000660",
        desc = "延迟0.2s"
    },
    [10000660] = {
        actionType = "changeparent",
        actionTarget = "RAGuideLabelRedNode.ccbi",
        varibleName = "mBustNode",
        param = "RAGuideBustNode.ccbi",
        nextActionId = "10000670,10000680,10000685",
        desc = "把图像框加入到当前文字框"
    },
    [10000670] = {
        actionTarget = "RAGuideLabelRedNode.ccbi",
        actionType = "changelabel",
        varibleName = "mRightGuideLabel",
        param = "@Guidedialog10000670",
        nextActionId = "10000690,10000695",
        desc = "对话：服从于我吧，空出你的心灵"
    },
    [10000680] = {
        actionTarget = "RAGuideBustNode.ccbi",
        actionType = "changepic",
        varibleName = "mRightBustPic",
        param = "Guide_Bust_Commander.png",
        nextActionId = "10000700",
        desc = "显示头像"
    },
	[10000685] = {
        actionTarget = "RAGuideLabelBlueNode.ccbi",
        actionType = "changelabel",
        varibleName = "mGuideName",
        param = "@GuideName4",
        nextActionId = nil,
        desc = "设置显示名字"
    },
    [10000690] = {
        actionTarget = "RAGuideLabelRedNode.ccbi",
        actionType = "runani",
        param = "InAni",
        nextActionId = "10000710",
        desc = "播放文字框进入动画"
    },
    [10000695] = {
        actionType = "playmusic",
        varibleName = "DialogueAdmission.mp3",
        param = "effect,false",
        nextActionId = nil,
        desc = "播放对话打字音效"
    },
    [10000700] = {
        actionTarget = "RAGuideBustNode.ccbi",
        actionType = "runani",
        param = "RightAni",
        nextActionId = nil,
        desc = "播放图像框进入动画"
    },
    [10000710] = {
        actionTarget = "RAGuidePage.ccbi",
        actionType = "addtouchlayer",
        param = "true",
        nextActionId = nil,
        desc = "添加点击层"
    },
    [10000720] = {
        actionTarget = "RAGuidePage.ccbi",
        actionType = "addtouchlayer",
        param = "false",
        nextActionId = nil,
        desc = "移除点击层"
    },
    [10000730] = {
        actionTarget = "RAGuideLabelRedNode.ccbi",
        actionType = "runani",
        param = "OutAni",
        nextActionId = nil,
        desc = "播放文字框离开动画"
    },
    [10000740] = {
        actionTarget = "RAGuideBustNode.ccbi",
        actionType = "runani",
        param = "RightOutAni",
        nextActionId = nil,
        desc = "播放图像框离开动画"
    },
    [10000750] = {
        actionTarget = "RAGuidePage.ccbi",
        actionType = "delaytime",
        param = "0.2",
        nextActionId = "10000760",
        desc = "延迟0.2s"
    },
    [10000760] = {
        actionType = "changeparent",
        actionTarget = "RAGuideLabelBlueNode.ccbi",
        varibleName = "mBustNode",
        param = "RAGuideBustNode.ccbi",
        nextActionId = "10000770,10000780,10000785",
        desc = "把图像框加入到当前文字框"
    },
    [10000770] = {
        actionTarget = "RAGuideLabelBlueNode.ccbi",
        actionType = "changelabel",
        varibleName = "mRightGuideLabel",
        param = "@Guidedialog10000770",
        nextActionId = "10000790,10000795",
        desc = "对话：通讯官，快切断视频连接"
    },
    [10000780] = {
        actionTarget = "RAGuideBustNode.ccbi",
        actionType = "changepic",
        varibleName = "mLeftBustPic",
        param = "tutorial.png",
        nextActionId = "10000800",
        desc = "显示头像"
    },
	[10000785] = {
        actionTarget = "RAGuideLabelBlueNode.ccbi",
        actionType = "changelabel",
        varibleName = "mGuideName",
        param = "@GuideName1",
        nextActionId = nil,
        desc = "设置显示名字"
    },
    [10000790] = {
        actionTarget = "RAGuideLabelBlueNode.ccbi",
        actionType = "runani",
        param = "InAni",
        nextActionId = "10000810",
        desc = "播放文字框进入动画"
    },
    [10000795] = {
        actionType = "playmusic",
        varibleName = "DialogueAdmission.mp3",
        param = "effect,false",
        nextActionId = nil,
        desc = "播放对话打字音效"
    },
    [10000800] = {
        actionTarget = "RAGuideBustNode.ccbi",
        actionType = "runani",
        param = "LeftAni",
        nextActionId = nil,
        desc = "播放图像框进入动画"
    },
    [10000810] = {
        actionTarget = "RAGuidePage.ccbi",
        actionType = "addtouchlayer",
        param = "true",
        nextActionId = nil,
        desc = "添加点击层"
    },
    [10000820] = {
        actionTarget = "RAGuidePage.ccbi",
        actionType = "addtouchlayer",
        param = "false",
        nextActionId = nil,
        desc = "移除点击层"
    },
    [10000830] = {
        actionTarget = "RAGuideLabelBlueNode.ccbi",
        actionType = "runani",
        param = "OutAni",
        nextActionId = nil,
        desc = "播放文字框离开动画"
    },
    [10000840] = {
        actionTarget = "RAGuideBustNode.ccbi",
        actionType = "runani",
        param = "LeftOutAni",
        nextActionId = nil,
        desc = "播放图像框离开动画"
    },
    [10000850] = {
        actionTarget = "RAGuidePage.ccbi",
        actionType = "delaytime",
        param = "0.4",
        nextActionId = "10000860",
        desc = "延迟0.4s"
    },
    [10000860] = {
        actionTarget = "RAGuidePage.ccbi",
        actionType = "shownode",
        varibleName = "mBGColor",
        param = "true",
        nextActionId = "10000870",
        desc = "显示黑色底层"
    },
    [10000870] = {
        actionTarget = "RAGuidePage.ccbi",
        actionType = "setcapacity",
        varibleName = "mBGColor",
        param = 255,
        nextActionId = "10000880,10000884",
        desc = "设置黑色底层为不透明"
    },
    [10000880] = {
        actionTarget = "RAGuidePage.ccbi",
        actionType = "runani",
        param = "DisturbAni",
        nextActionId = "10000890",
        desc = "播放信号扰乱动画"
    },
    [10000884] = {
        actionTarget = "RAGuideBustNode.ccbi",
        actionType = "deleteccb",
        nextActionId = "10000886,10000888,10000889",
        desc = "删除头像ccb"
    },
    [10000886] = {
        actionTarget = "RAGuideLabelBlueNode.ccbi",
        actionType = "deleteccb",
        nextActionId = nil,
        desc = "删除对话ccb"
    },
    [10000888] = {
        actionTarget = "RAGuideLabelRedNode.ccbi",
        actionType = "deleteccb",
        nextActionId = nil,
        desc = "删除对话ccb"
    },
    [10000889] = {
        actionTarget = "RAGuideLabelBlueNode2.ccbi",
        actionType = "deleteccb",
        nextActionId = nil,
        desc = "删除对话ccb"
    },
    [10000890] = {
        actionType = "gotonextstep",
    },
    [10001010] = {
        actionTarget = "RAMissionMap2.ccbi",
        actionType = "delaytime",
        param = "1",
        nextActionId = "10001012",
        desc = "延迟1s"
    },
    [10001012] = {
        actionType = "showpage",
        varibleName = "RAMissionBarrierGuideDialogPage",
        param = "true",
        nextActionId = "10001014",
        desc = "添加对话框"
    },
    [10001014] = {
        actionTarget = "RAGuidePage.ccbi",
        actionType = "shownode",
        varibleName = "mBGColor",
        param = "false",
        nextActionId = "10001016",
        desc = "隐藏黑色底层"
    },
    [10001016] = {
        actionType = "addccb",
        actionTarget = "RAGuidePage.ccbi",
        varibleName = "mBottomGuideTalkNode",
        param = "RAGuideLabelBlueNode.ccbi",
        nextActionId = "10001018,10001020,10001035",
        desc = "把文字框加入到对话框"
    },
    [10001018] = {
        actionType = "addccb",
        actionTarget = "RAGuideLabelBlueNode.ccbi",
        varibleName = "mBustNode",
        param = "RAGuideBustNode.ccbi",
        nextActionId = "10001030",
        desc = "把图像框加入到文字框"
    },
    [10001020] = {
        actionTarget = "RAGuideLabelBlueNode.ccbi",
        actionType = "changelabel",
        varibleName = "mRightGuideLabel",
        param = "@Guidedialog10001020",
        nextActionId = "10001040,10001045",
        desc = "对话：好险，差一点连我们也被控制了"
    },
    [10001030] = {
        actionTarget = "RAGuideBustNode.ccbi",
        actionType = "changepic",
        varibleName = "mLeftBustPic",
        param = "tutorial.png",
        nextActionId = "10001050",
        desc = "显示头像"
    },
	[10001035] = {
        actionTarget = "RAGuideLabelBlueNode.ccbi",
        actionType = "changelabel",
        varibleName = "mGuideName",
        param = "@GuideName1",
        nextActionId = nil,
        desc = "设置显示名字"
    },
    [10001040] = {
        actionTarget = "RAGuideLabelBlueNode.ccbi",
        actionType = "runani",
        param = "InAni",
        nextActionId = "10001060",
        desc = "播放文字框进入动画"
    },
    [10001045] = {
        actionType = "playmusic",
        varibleName = "DialogueAdmission.mp3",
        param = "effect,false",
        nextActionId = nil,
        desc = "播放对话打字音效"
    },
    [10001050] = {
        actionTarget = "RAGuideBustNode.ccbi",
        actionType = "runani",
        param = "LeftAni",
        nextActionId = nil,
        desc = "播放图像框进入动画"
    },
    [10001060] = {
        actionTarget = "RAGuidePage.ccbi",
        actionType = "addtouchlayer",
        param = "true",
        nextActionId = nil,
        desc = "添加点击层"
    },
    [10001070] = {
        actionTarget = "RAGuidePage.ccbi",
        actionType = "addtouchlayer",
        param = "false",
        nextActionId = nil,
        desc = "移除点击层"
    },
    [10001080] = {
        actionTarget = "RAGuideBustNode.ccbi",
        actionType = "runani",
        param = "LeftOutAni",
        nextActionId = "10001110",
        desc = "播放图像框离开动画"
    },
    [10001090] = {
        actionTarget = "RAGuideLabelBlueNode.ccbi",
        actionType = "changelabel",
        varibleName = "mRightGuideLabel",
        param = "@Guidedialog10001090",
        nextActionId = "10001100,10001105,10001095",
        desc = "对话：看来我们只剩下一个办法了"
    },
	[10001095] = {
        actionTarget = "RAGuideLabelBlueNode.ccbi",
        actionType = "changelabel",
        varibleName = "mGuideName",
        param = "@GuideName2",
        nextActionId = nil,
        desc = "设置显示名字"
    },
    [10001100] = {
        actionTarget = "RAGuideLabelBlueNode.ccbi",
        actionType = "runani",
        param = "LabelAni",
        nextActionId = "10001130",
        desc = "播放文字打印动画"
    },
    [10001105] = {
        actionType = "playmusic",
        varibleName = "DialogueAdmission.mp3",
        param = "effect,false",
        nextActionId = nil,
        desc = "播放对话打字音效"
    },
    [10001110] = {
        actionTarget = "RAGuideBustNode.ccbi",
        actionType = "changepic",
        varibleName = "mLeftBustPic",
        param = "Guide_Bust_General.png",
        nextActionId = "10001120",
        desc = "显示头像"
    },
    [10001120] = {
        actionTarget = "RAGuideBustNode.ccbi",
        actionType = "runani",
        param = "LeftAni",
        nextActionId = nil,
        desc = "播放图像框进入动画"
    },
    [10001130] = {
        actionTarget = "RAGuidePage.ccbi",
        actionType = "addtouchlayer",
        param = "true",
        nextActionId = nil,
        desc = "添加点击层"
    },
    [10001140] = {
        actionTarget = "RAGuidePage.ccbi",
        actionType = "addtouchlayer",
        param = "false",
        nextActionId = nil,
        desc = "移除点击层"
    },
    [10001150] = {
        actionTarget = "RAGuideBustNode.ccbi",
        actionType = "runani",
        param = "LeftOutAni",
        nextActionId = nil,
        desc = "播放图像框离开动画"
    },
    [10001160] = {
        actionTarget = "RAGuideLabelBlueNode.ccbi",
        actionType = "runani",
        param = "OutAni",
        nextActionId = "10001170,10001175",
        desc = "播放文字框离开动画"
    },
    [10001170] = {
        actionTarget = "RAGuidePage.ccbi",
        actionType = "runani",
        param = "SignalAni",
        nextActionId = nil,
        desc = "播放心电图波动动画"
    },
    [10001175] = {
        actionType = "addccb",
        actionTarget = "RAGuidePage.ccbi",
        varibleName = "mBottomGuideTalkNode",
        param = "RAGuideLabelRedNode.ccbi",
        nextActionId = "10001180",
        desc = "把文字框加入到对话框"
    },
    [10001180] = {
        actionType = "changeparent",
        actionTarget = "RAGuideLabelRedNode.ccbi",
        varibleName = "mBustNode",
        param = "RAGuideBustNode.ccbi",
        nextActionId = "10001190,10001200,10001205",
        desc = "把图像框加入到当前文字框"
    },
    [10001190] = {
        actionTarget = "RAGuideLabelRedNode.ccbi",
        actionType = "changelabel",
        varibleName = "mRightGuideLabel",
        param = "@Guidedialog10001190",
        nextActionId = "10001210,10001215",
        desc = "对话：是要使用核弹来对付我吗"
    },
    [10001200] = {
        actionTarget = "RAGuideBustNode.ccbi",
        actionType = "changepic",
        varibleName = "mRightBustPic",
        param = "Guide_Bust_Yuri.png",
        nextActionId = "10001220",
        desc = "显示头像"
    },
	[10001205] = {
        actionTarget = "RAGuideLabelRedNode.ccbi",
        actionType = "changelabel",
        varibleName = "mGuideName",
        param = "@GuideName3",
        nextActionId = nil,
        desc = "设置显示名字"
    },
    [10001210] = {
        actionTarget = "RAGuideLabelRedNode.ccbi",
        actionType = "runani",
        param = "InAni",
        nextActionId = "10001230",
        desc = "播放文字框进入动画"
    },
    [10001215] = {
        actionType = "playmusic",
        varibleName = "DialogueAdmission.mp3",
        param = "effect,false",
        nextActionId = nil,
        desc = "播放对话打字音效"
    },
    [10001220] = {
        actionTarget = "RAGuideBustNode.ccbi",
        actionType = "runani",
        param = "RightAni",
        nextActionId = nil,
        desc = "播放图像框进入动画"
    },
    [10001230] = {
        actionTarget = "RAGuidePage.ccbi",
        actionType = "addtouchlayer",
        param = "true",
        nextActionId = nil,
        desc = "添加点击层"
    },
    [10001240] = {
        actionTarget = "RAGuidePage.ccbi",
        actionType = "addtouchlayer",
        param = "false",
        nextActionId = nil,
        desc = "移除点击层"
    },
    [10001250] = {
        actionTarget = "RAGuideLabelRedNode.ccbi",
        actionType = "changelabel",
        varibleName = "mRightGuideLabel",
        param = "@Guidedialog10001250",
        nextActionId =  "10001260,10001265",
        desc = "对话：你真是顽固，顺便说一句"
    },
    [10001260] = {
        actionTarget = "RAGuideLabelRedNode.ccbi",
        actionType = "runani",
        param = "LabelAni",
        nextActionId = "10001270",
        desc = "播放文字打印动画"
    },
    [10001265] = {
        actionType = "playmusic",
        varibleName = "DialogueAdmission.mp3",
        param = "effect,false",
        nextActionId = nil,
        desc = "播放对话打字音效"
    },
    [10001270] = {
        actionTarget = "RAGuidePage.ccbi",
        actionType = "addtouchlayer",
        param = "true",
        nextActionId = nil,
        desc = "添加点击层"
    },
    [10001280] = {
        actionTarget = "RAGuidePage.ccbi",
        actionType = "addtouchlayer",
        param = "false",
        nextActionId = nil,
        desc = "移除点击层"
    },
    [10001290] = {
        actionTarget = "RAGuideLabelRedNode.ccbi",
        actionType = "changelabel",
        varibleName = "mRightGuideLabel",
        param = "@Guidedialog10001290",
        nextActionId =  "10001300,10001305",
        desc = "对话：快猜猜我会把"
    },
    [10001300] = {
        actionTarget = "RAGuideLabelRedNode.ccbi",
        actionType = "runani",
        param = "LabelAni",
        nextActionId = "10001310",
        desc = "播放文字打印动画"
    },
    [10001305] = {
        actionType = "playmusic",
        varibleName = "DialogueAdmission.mp3",
        param = "effect,false",
        nextActionId = nil,
        desc = "播放对话打字音效"
    },
    [10001310] = {
        actionTarget = "RAGuidePage.ccbi",
        actionType = "addtouchlayer",
        param = "true",
        nextActionId = nil,
        desc = "添加点击层"
    },
    [10001320] = {
        actionTarget = "RAGuidePage.ccbi",
        actionType = "addtouchlayer",
        param = "false",
        nextActionId = nil,
        desc = "删除点击层"
    },
    [10001330] = {
        actionTarget = "RAGuideLabelRedNode.ccbi",
        actionType = "runani",
        param = "OutAni",
        nextActionId = "10001350,10002010",
        desc = "播放文字框离开动画"
    }, 
    [10001340] = {
        actionTarget = "RAGuideBustNode.ccbi",
        actionType = "runani",
        param = "RightOutAni",
        nextActionId = nil,
        desc = "播放图像框离开动画"
    },
    [10001350] = {
        actionType = "showtransform",
        nextActionId = nil,
        desc = "添加过场动画"
    },
    [10002010] = {
        actionTarget = "RAMissionMap2.ccbi",
        actionType = "delaytime",
        param = "0.5",
        nextActionId = "10002013,10002015,10002020",
        desc = "延迟0.5s"
    },
    [10002013] = {
        actionType = "setcamerascale",
        param = "0.7,0",
        nextActionId = nil,
        desc = "设置镜头"
    },
    [10002015] = {
        actionTarget = "RAMissionMap2_March1.ccbi",
        actionType = "runani",
        param = "March1_Timeline2",
        nextActionId = nil,
        desc = "播放草地动画"
    },
    [10002020] = {
        actionTarget = "RAMissionMap2_March1.ccbi",
        actionType = "addspine",
        varibleName = "mMarch2NukeSpine",
        param = "GuildBuilding_Bomb",
        name = "GuildBuilding_Bomb",
        nextActionId = "10002030",
        desc = "添加核弹spine"
    },
    [10002030] = {
        actionTarget = "GuildBuilding_Bomb",
        varibleName = "false",
        actionType = "runspineani",
        param = "Idle_ReadyLaunch",
        nextActionId = "10002032",
        desc = "播放核弹准备发射的动画"
    },
    [10002032] = {
        actionTarget = "RAMissionMap2.ccbi",
        actionType = "delaytime",
        param = "1.5",
        nextActionId = "10002035,10002037",
        desc = "延迟0.3s"
    },
    [10002035] = {
        actionType = "setcamerascale",
        param = "1.3,1.5",
        nextActionId = nil,
        desc = "设置镜头"
    },
    [10002037] = {
        actionTarget = "RAMissionMap2.ccbi",
        actionType = "delaytime",
        param = "1.5",
        nextActionId = "10002039,10002038,10002045",
        desc = "延迟1.5s"
    },
    [10002038] = {
        actionTarget = "RAMissionMap2.ccbi",
        actionType = "delaytime",
        param = "3",
        nextActionId = "10002041",
        desc = "延迟3s，准备配合核弹升空"
    },
    [10002039] = {
        actionTarget = "GuildBuilding_Bomb",
        varibleName = "false",
        actionType = "runspineani",
        param = "Launch2",
        nextActionId = "10002050,10003010",
        desc = "播放核弹发射的动画"
    },
    [10002041] = {
        actionTarget = "RAMissionMap2.ccbi",
        actionType = "movecamera",
        varibleName = "mMarch1Point6",
        param = "2.2",
        nextActionId = nil,
        desc = "镜头随着核弹移动"
    },
    [10002045] = {
        actionType = "playmusic",
        varibleName = "bombLaunch.mp3",
        param = "effect,false",
        nextActionId = nil,
        desc = "播放核弹升空音效"
    },	
    [10002050] = {
        actionType = "showtransform",
        nextActionId = nil,
        desc = "添加过场动画"
    },
    [10003010] = {
        actionTarget = "RAMissionMap2.ccbi",
        actionType = "delaytime",
        param = "0.5",
        nextActionId = "10003020,10003033,10003030",
        desc = "延迟0.5s"
    },
    [10003020] = {
        actionTarget = "RAMissionMap2_March1.ccbi",
        actionType = "runani",
        param = "March1_Timeline3",
        nextActionId = nil,
        desc = "播放被核弹瞄准动画"
    },
    [10003033] = {
        actionType = "playmusic",
        varibleName = "bombLock.mp3",
        param = "effect,false",
        nextActionId = nil,
        desc = "播放核弹锁定音效"
    },
    [10003030] = {
        actionType = "addccb",
        actionTarget = nil,
        varibleName = nil,
        param = "RAWarningAni.ccbi",
        nextActionId = "10003040",
        desc = "把雷达报警加入到topnode"
    },
    [10003040] = {
        actionTarget = "RAWarningAni.ccbi",
        actionType = "runani",
        param = "Default Timeline",
        nextActionId = "10003050,10003055,10003060",
        desc = "播放报警动画"
    },
    [10003050] = {
        actionTarget = "RAWarningAni.ccbi",
        actionType = "deleteccb",
        nextActionId = nil,
        desc = "删除报警动画ccb"
    },
    [10003055] = {
        actionTarget = "GuildBuilding_Bomb",
        actionType = "addspine",
        param = "false",
        nextActionId = nil,
        desc = "删除核弹spine"
    },
    [10003060] = {
        actionType = "changeparent",
        actionTarget = "RAGuideLabelBlueNode.ccbi",
        varibleName = "mBustNode",
        param = "RAGuideBustNode.ccbi",
        nextActionId = "10003070,10003075,10003080,10003085",
        desc = "把图像框加入到当前文字框"
    },
    [10003070] = {
        actionTarget = "RAGuideLabelBlueNode.ccbi",
        actionType = "changelabel",
        varibleName = "mRightGuideLabel",
        param = "@Guidedialog10003070",
        nextActionId =  "10003090,10003095",
        desc = "对话：看来尤里打算对我们进行核打击"
    },
    [10003075] = {
        actionType = "playmusic",
        varibleName = "airDefenseWarning.mp3",
        param = "effect,false",
        nextActionId = nil,
        desc = "播放空袭音效"
    },	
    [10003080] = {
        actionTarget = "RAGuideBustNode.ccbi",
        actionType = "changepic",
        varibleName = "mLeftBustPic",
        param = "Guide_Bust_General.png",
        nextActionId = "10003100",
        desc = "显示头像"
    },
	[10003085] = {
        actionTarget = "RAGuideLabelBlueNode.ccbi",
        actionType = "changelabel",
        varibleName = "mGuideName",
        param = "@GuideName2",
        nextActionId = nil,
        desc = "设置显示名字"
    },
    [10003090] = {
        actionTarget = "RAGuideLabelBlueNode.ccbi",
        actionType = "runani",
        param = "InAni",
        nextActionId = "10003110",
        desc = "播放文字框进入动画"
    },
    [10003095] = {
        actionType = "playmusic",
        varibleName = "DialogueAdmission.mp3",
        param = "effect,false",
        nextActionId = nil,
        desc = "播放对话打字音效"
    },
    [10003100] = {
        actionTarget = "RAGuideBustNode.ccbi",
        actionType = "runani",
        param = "LeftAni",
        nextActionId = nil,
        desc = "播放图像框进入动画"
    },
    [10003110] = {
        actionTarget = "RAGuidePage.ccbi",
        actionType = "addtouchlayer",
        param = "true",
        nextActionId = nil,
        desc = "添加点击层"
    },
    [10003120] = {
        actionTarget = "RAGuidePage.ccbi",
        actionType = "addtouchlayer",
        param = "false",
        nextActionId = nil,
        desc = "删除点击层"
    },
    [10003130] = {
        actionTarget = "RAGuideLabelBlueNode.ccbi",
        actionType = "changelabel",
        varibleName = "mRightGuideLabel",
        param = "@Guidedialog10003130",
        nextActionId = "10003140,10003145",
        desc = "对话：谭雅，尤里虽未控制我"
    },
    [10003140] = {
        actionTarget = "RAGuideLabelBlueNode.ccbi",
        actionType = "runani",
        param = "LabelAni",
        nextActionId = "10003150",
        desc = "播放文字显示动画"
    },
    [10003145] = {
        actionType = "playmusic",
        varibleName = "DialogueAdmission.mp3",
        param = "effect,false",
        nextActionId = nil,
        desc = "播放对话打字音效"
    },
    [10003150] = {
        actionTarget = "RAGuidePage.ccbi",
        actionType = "addtouchlayer",
        param = "true",
        nextActionId = nil,
        desc = "添加点击层"
    },
    [10003160] = {
        actionTarget = "RAGuidePage.ccbi",
        actionType = "addtouchlayer",
        param = "false",
        nextActionId = nil,
        desc = "删除点击层"
    },
    [10003170] = {
        actionTarget = "RAGuideLabelBlueNode.ccbi",
        actionType = "changelabel",
        varibleName = "mRightGuideLabel",
        param = "@Guidedialog10003170",
        nextActionId =  "10003180,10003185",
        desc = "对话：你快通知联盟领地领地内所有作战指挥官"
    },
    [10003180] = {
        actionTarget = "RAGuideLabelBlueNode.ccbi",
        actionType = "runani",
        param = "LabelAni",
        nextActionId = "10003190",
        desc = "播放文字显示动画"
    },
    [10003185] = {
        actionType = "playmusic",
        varibleName = "DialogueAdmission.mp3",
        param = "effect,false",
        nextActionId = nil,
        desc = "播放对话打字音效"
    },
    [10003190] = {
        actionTarget = "RAGuidePage.ccbi",
        actionType = "addtouchlayer",
        param = "true",
        nextActionId = nil,
        desc = "添加点击层"
    },
    [10003200] = {
        actionTarget = "RAGuidePage.ccbi",
        actionType = "addtouchlayer",
        param = "false",
        nextActionId = nil,
        desc = "删除点击层"
    },
    [10003210] = {
        actionTarget = "RAGuideBustNode.ccbi",
        actionType = "runani",
        param = "LeftOutAni",
        nextActionId = "10003230",
        desc = "播放图像框离开动画"
    },
    [10003220] = {
        actionTarget = "RAGuideLabelBlueNode.ccbi",
        actionType = "changelabel",
        varibleName = "mRightGuideLabel",
        param = "@Guidedialog10003220",
        nextActionId = "10003240,10003245,10003225",
        desc = "对话：卡维利将军，你。。。"
    },
	[10003225] = {
        actionTarget = "RAGuideLabelBlueNode.ccbi",
        actionType = "changelabel",
        varibleName = "mGuideName",
        param = "@GuideName1",
        nextActionId = nil,
        desc = "设置显示名字"
    },	
    [10003230] = {
        actionTarget = "RAGuideBustNode.ccbi",
        actionType = "changepic",
        varibleName = "mLeftBustPic",
        param = "tutorial.png",
        nextActionId = "10003250",
        desc = "显示头像"
    },
    [10003240] = {
        actionTarget = "RAGuideLabelBlueNode.ccbi",
        actionType = "runani",
        param = "LabelAni",
        nextActionId = nil,
        desc = "播放文字显示动画"
    },
    [10003245] = {
        actionType = "playmusic",
        varibleName = "DialogueAdmission.mp3",
        param = "effect,false",
        nextActionId = nil,
        desc = "播放对话打字音效"
    },
    [10003250] = {
        actionTarget = "RAGuideBustNode.ccbi",
        actionType = "runani",
        param = "LeftAni",
        nextActionId = "10003260",
        desc = "播放图像框进入动画"
    },
    [10003260] = {
        actionTarget = "RAGuidePage.ccbi",
        actionType = "addtouchlayer",
        param = "true",
        nextActionId = nil,
        desc = "添加点击层"
    },
    [10003270] = {
        actionTarget = "RAGuidePage.ccbi",
        actionType = "addtouchlayer",
        param = "false",
        nextActionId = nil,
        desc = "删除点击层"
    },
    [10003280] = {
        actionTarget = "RAGuideBustNode.ccbi",
        actionType = "runani",
        param = "LeftOutAni",
        nextActionId = "10003300",
        desc = "播放图像框离开动画"
    },
    [10003290] = {
        actionTarget = "RAGuideLabelBlueNode.ccbi",
        actionType = "changelabel",
        varibleName = "mRightGuideLabel",
        param = "@Guidedialog10003290",
        nextActionId = "10003310,10003315,10003295",
        desc = "对话：不要管我"
    },
	[10003295] = {
        actionTarget = "RAGuideLabelBlueNode.ccbi",
        actionType = "changelabel",
        varibleName = "mGuideName",
        param = "@GuideName2",
        nextActionId = nil,
        desc = "设置显示名字"
    },
    [10003300] = {
        actionTarget = "RAGuideBustNode.ccbi",
        actionType = "changepic",
        varibleName = "mLeftBustPic",
        param = "Guide_Bust_General.png",
        nextActionId = "10003320",
        desc = "显示头像"
    },
    [10003310] = {
        actionTarget = "RAGuideLabelBlueNode.ccbi",
        actionType = "runani",
        param = "LabelAni",
        nextActionId = nil,
        desc = "播放文字显示动画"
    },
    [10003315] = {
        actionType = "playmusic",
        varibleName = "DialogueAdmission.mp3",
        param = "effect,false",
        nextActionId = nil,
        desc = "播放对话打字音效"
    },
    [10003320] = {
        actionTarget = "RAGuideBustNode.ccbi",
        actionType = "runani",
        param = "LeftAni",
        nextActionId = "10003330",
        desc = "播放图像框进入动画"
    },
    [10003330] = {
        actionTarget = "RAGuidePage.ccbi",
        actionType = "addtouchlayer",
        param = "true",
        nextActionId = nil,
        desc = "添加点击层"
    },
    [10003340] = {
        actionTarget = "RAGuidePage.ccbi",
        actionType = "addtouchlayer",
        param = "false",
        nextActionId = nil,
        desc = "删除点击层"
    },
    [10003350] = {
        actionTarget = "RAGuideBustNode.ccbi",
        actionType = "runani",
        param = "LeftOutAni",
        nextActionId = "10003370",
        desc = "播放图像框离开动画"
    },
    [10003360] = {
        actionTarget = "RAGuideLabelBlueNode.ccbi",
        actionType = "changelabel",
        varibleName = "mRightGuideLabel",
        param = "@Guidedialog10003360",
        nextActionId = "10003380,10003385,10003365",
        desc = "对话：是！。。。。所有作战指挥官听命"
    },
	[10003365] = {
        actionTarget = "RAGuideLabelBlueNode.ccbi",
        actionType = "changelabel",
        varibleName = "mGuideName",
        param = "@GuideName1",
        nextActionId = nil,
        desc = "设置显示名字"
    },
    [10003370] = {
        actionTarget = "RAGuideBustNode.ccbi",
        actionType = "changepic",
        varibleName = "mLeftBustPic",
        param = "tutorial.png",
        nextActionId = "10003390",
        desc = "显示头像"
    },
    [10003380] = {
        actionTarget = "RAGuideLabelBlueNode.ccbi",
        actionType = "runani",
        param = "LabelAni",
        nextActionId = nil,
        desc = "播放文字显示动画"
    },
    [10003385] = {
        actionType = "playmusic",
        varibleName = "DialogueAdmission.mp3",
        param = "effect,false",
        nextActionId = nil,
        desc = "播放对话打字音效"
    },
    [10003390] = {
        actionTarget = "RAGuideBustNode.ccbi",
        actionType = "runani",
        param = "LeftAni",
        nextActionId = "10003400",
        desc = "播放图像框进入动画"
    },
    [10003400] = {
        actionTarget = "RAGuidePage.ccbi",
        actionType = "addtouchlayer",
        param = "true",
        nextActionId = nil,
        desc = "添加点击层"
    },
    [10003410] = {
        actionTarget = "RAGuidePage.ccbi",
        actionType = "addtouchlayer",
        param = "false",
        nextActionId = nil,
        desc = "移除点击层"
    },
    [10003412] = {
        actionTarget = "RAGuideLabelBlueNode.ccbi",
        actionType = "runani",
        param = "OutAni",
        nextActionId = nil,
        desc = "播放文字框离开动画"
    },
    [10003414] = {
        actionTarget = "RAGuideBustNode.ccbi",
        actionType = "runani",
        param = "LeftOutAni",
        nextActionId = nil,
        desc = "播放图像框离开动画"
    },
    [10003420] = {
        actionTarget = "RAMissionMap2.ccbi",
        actionType = "movecamera",
        varibleName = "mMarch1Point3",
        param = "0.5",
        nextActionId = "10003430,10003460,10003500",
        desc = "移动镜头到三个基地"
    },
    [10003430] = {
        actionTarget = "RAMissionMap2_March1.ccbi",
        actionType = "addspine",
        varibleName = "mMarch2BaseSpine1",
        param = "201001",
        name = "mcv1",
        nextActionId = "10003440,10003448,10003450",
        desc = "添加spine"
    },
    [10003440] = {
        actionTarget = "mcv1",
        actionType = "runspineani",
        param = "Constructionoutside",
        nextActionId = "10003445",
        desc = "播放主基地变形为基地车的动画"
    },
    [10003445] = {
        actionTarget = "RAMissionMap2_March1.ccbi",
        actionType = "addspine",
        varibleName = "mMarch2BaseSpine1",
        param = "Mcv_Trans",
        name = "Mcv_Trans1",
        nextActionId = "10003447",
        desc = "添加基地车spine"
    },
    [10003447] = {
        actionTarget = "Mcv_Trans1",
        actionType = "runspineani",
        param = "Car",
        nextActionId = nil,
        desc = "播放主基地变形为基地车的动画"
    },
    [10003448] = {
        actionType = "playmusic",
        varibleName = "deformationBaseCar.mp3",
        param = "effect,false",
        nextActionId = nil,
        desc = "播放基地车变形音效"
    },		
    [10003450] = {
        actionTarget = "RAMissionMap2_March1.ccbi",
        actionType = "shownode",
        varibleName = "mMap2March1BaseNode1",
        param = "false",
        nextActionId = nil,
        desc = "隐藏ccb上的主基地"
    },
    [10003460] = {
        actionTarget = "RAMissionMap2.ccbi",
        actionType = "delaytime",
        param = "1",
        nextActionId = "10003470",
        desc = "延迟1s"
    },
    [10003470] = {
        actionTarget = "RAMissionMap2_March1.ccbi",
        actionType = "addspine",
        varibleName = "mMarch2BaseSpine2",
        param = "201001",
        name = "mcv2",
        nextActionId = "10003480,10003484,10003490",
        desc = "添加spine"
    },
    [10003480] = {
        actionTarget = "mcv2",
        actionType = "runspineani",
        param = "Constructionoutside",
        nextActionId = "10003485",
        desc = "播放主基地变形为基地车的动画"
    },	
	[10003485] = {
        actionTarget = "RAMissionMap2_March1.ccbi",
        actionType = "addspine",
        varibleName = "mMarch2BaseSpine2",
        param = "Mcv_Trans",
        name = "Mcv_Trans2",
        nextActionId = "10003487",
        desc = "添加基地车spine"
    },
    [10003487] = {
        actionTarget = "Mcv_Trans2",
        actionType = "runspineani",
        param = "Car",
        nextActionId = nil,
        desc = "播放主基地变形为基地车的动画"
    },
    [10003484] = {
        actionType = "playmusic",
        varibleName = "deformationBaseCar.mp3",
        param = "effect,false",
        nextActionId = nil,
        desc = "播放基地车变形音效"
    },
	[10003490] = {
        actionTarget = "RAMissionMap2_March1.ccbi",
        actionType = "shownode",
        varibleName = "mMap2March1BaseNode2",
        param = "false",
        nextActionId = nil,
        desc = "隐藏ccb上的主基地"
    },
    [10003500] = {
        actionTarget = "RAMissionMap2.ccbi",
        actionType = "delaytime",
        param = "2",
        nextActionId = "10003510",
        desc = "延迟2s"
    },
    [10003510] = {
        actionTarget = "RAMissionMap2_March1.ccbi",
        actionType = "addspine",
        varibleName = "mMarch2BaseSpine3",
        param = "201001",
        name = "mcv3",
        nextActionId = "10003520,10003527,10003530",
        desc = "添加spine"
    },
    [10003520] = {
        actionTarget = "mcv3",
        actionType = "runspineani",
        param = "Constructionoutside",
        nextActionId = "10003525",
        desc = "播放主基地变形为基地车的动画"
    },
	[10003525] = {
        actionTarget = "RAMissionMap2_March1.ccbi",
        actionType = "addspine",
        varibleName = "mMarch2BaseSpine3",
        param = "Mcv_Trans",
        name = "Mcv_Trans3",
        nextActionId = "10003526,10003528",
        desc = "添加基地车spine"
    },
    [10003526] = {
        actionTarget = "Mcv_Trans3",
        actionType = "runspineani",
        param = "Car",
        nextActionId = nil,
        desc = "播放主基地变形为基地车的动画"
    },
    [10003527] = {
        actionType = "playmusic",
        varibleName = "deformationBaseCar.mp3",
        param = "effect,false",
        nextActionId = nil,
        desc = "播放基地车变形音效"
    },	
    [10003530] = {
        actionTarget = "RAMissionMap2_March1.ccbi",
        actionType = "shownode",
        varibleName = "mMap2March1BaseNode3",
        param = "false",
        nextActionId = nil,
        desc = "隐藏ccb上的主基地"
    },	
	[10003528] = {
        actionTarget = "Mcv_Trans3",
        actionType = "runspineani",
        param = "Car",
        nextActionId = "10003550,10003560,10003570,10003580,10003540,10003545",
        desc = "播放基地车开走的动画"
    },
    [10003540] = {
        actionTarget = "RAMissionMap2_March1.ccbi",
        actionType = "runani",
        param = "March1_Timeline5",
        nextActionId = nil,
        desc = "播放基地车开走动画"
    },
    [10003545] = {
        actionType = "playmusic",
        varibleName = "baseCarMove.mp3",
        param = "effect,false",
        nextActionId = nil,
        desc = "播放基地车开走音效"
    },
    [10003550] = {
        actionTarget = "RAMissionMap2_March1.ccbi",
        actionType = "shownode",
        varibleName = "mMarch2BaseSpine1",
        param = "false",
        nextActionId = nil,
        desc = "隐藏spine节点"
    },
    [10003560] = {
        actionTarget = "RAMissionMap2_March1.ccbi",
        actionType = "shownode",
        varibleName = "mMarch2BaseSpine2",
        param = "false",
        nextActionId = nil,
        desc = "隐藏spine节点"
    },
    [10003570] = {
        actionTarget = "RAMissionMap2_March1.ccbi",
        actionType = "shownode",
        varibleName = "mMarch2BaseSpine3",
        param = "false",
        nextActionId = nil,
        desc = "隐藏spine节点"
    },
    [10003580] = {
        actionTarget = "RAMissionMap2.ccbi",
        actionType = "movecamera",
        varibleName = "mMarch1Point4",
        param = "4",
        nextActionId = "10003590,10003592,10003593,10003594,10003595,10003596,10003597",
        desc = "移动镜头跟随基地车"
    },
    [10003590] = {
        actionTarget = "RAMissionMap2.ccbi",
        actionType = "movecamera",
        varibleName = "mMarch1Point5",
        param = "2",
        nextActionId = "10003600,10003601,10003610",
        desc = "移动镜头到核弹爆炸地点"
    },
    [10003592] = {
        actionTarget = "mcv1",
        actionType = "addspine",
        param = "false",
        nextActionId = nil,
        desc = "删除基地车spine"
    },
    [10003593] = {
        actionTarget = "mcv2",
        actionType = "addspine",
        param = "false",
        nextActionId = nil,
        desc = "删除基地车spine"
    },
    [10003594] = {
        actionTarget = "mcv3",
        actionType = "addspine",
        param = "false",
        nextActionId = nil,
        desc = "删除基地车spine"
    },
    [10003595] = {
        actionTarget = "Mcv_Trans1",
        actionType = "addspine",
        param = "false",
        nextActionId = nil,
        desc = "删除小车spine"
    },
    [10003596] = {
        actionTarget = "Mcv_Trans2",
        actionType = "addspine",
        param = "false",
        nextActionId = nil,
        desc = "删除小车spine"
    },
    [10003597] = {
        actionTarget = "Mcv_Trans3",
        actionType = "addspine",
        param = "false",
        nextActionId = nil,
        desc = "删除小车spine"
    },
    [10003600] = {
        actionTarget = "RAMissionMap2_March1.ccbi",
        actionType = "runani",
        param = "March1_Timeline6",
        nextActionId = nil,
        desc = "播放核弹爆炸动画"
    },
    [10003601] = {
        actionTarget = "RAMissionMap2.ccbi",
        actionType = "delaytime",
        param = "1.7",
        nextActionId = "10003605",
        desc = "延迟1.7s，配合核弹到达"
    },
    [10003605] = {
        actionType = "playmusic",
        varibleName = "nuclearBombExpLosion.mp3",
        param = "effect,false",
        nextActionId = nil,
        desc = "播放核弹爆炸音效"
    },
    [10003610] = {
        actionTarget = "RAMissionMap2.ccbi",
        actionType = "delaytime",
        param = "4",
        nextActionId = "10003620,10003630,10003640",
        desc = "延迟4s"
    },
    [10003620] = {
        actionType = "addccb",
        actionTarget = "RAGuidePage.ccbi",
        varibleName = "mTargetNode",
        param = "RAMissionMap2_March2.ccbi",
        nextActionId = "10003625",
        desc = "把气氛ccb加入到对话框"
    },
    [10003625] = {
        actionTarget = "RAMissionMap2_March2.ccbi",
        actionType = "runani",
        param = "March2_Timeline1",
        nextActionId = nil,
        desc = "播放气氛动画"
    },
    [10003630] = {
        actionTarget = "RAGuidePage.ccbi",
        actionType = "changelabel",
        varibleName = "mGuideLabel",
        param = "@Guidedialog100036300",
        nextActionId = nil,
        desc = "对话：Guidedialog100036300"
    },
    [10003640] = {
        actionTarget = "RAGuidePage.ccbi",
        actionType = "shownode",
        varibleName = "mGuideLabel",
        param = "true",
        nextActionId = "10003650,10003655",
        desc = "显示文字"
    },
    [10003650] = {
        actionTarget = "RAGuidePage.ccbi",
        actionType = "runani",
        param = "LabelAni",
        nextActionId = "10003660,10003670",
        desc = "播放文字动画"
    },
    [10003655] = {
        actionType = "playmusic",
        varibleName = "blackScreenSubtitleCursor.mp3",
        param = "effect,false",
        nextActionId = nil,
        desc = "播放黑屏打字音效"
    },	
    [10003660] = {
        actionTarget = "RAMissionMap2_March2.ccbi",
        actionType = "runani",
        param = "March2_Timeline2",
        nextActionId = nil,
        desc = "播放气氛动画"
    },
    [10003670] = {
        actionTarget = "RAGuidePage.ccbi",
        actionType = "changelabel",
        varibleName = "mGuideLabel",
        param = "@Guidedialog100036700",
        nextActionId = "10003680,10003683",
        desc = "对话：Guidedialog100036700"
    },
    [10003680] = {
        actionTarget = "RAGuidePage.ccbi",
        actionType = "runani",
        param = "LabelAni",
        nextActionId = "10003685,10003690,10003692,10003710",
        desc = "播放文字动画"
    },
    [10003683] = {
        actionType = "playmusic",
        varibleName = "blackScreenSubtitleCursor.mp3",
        param = "effect,false",
        nextActionId = nil,
        desc = "播放黑屏打字音效"
    },	
    [10003685] = {
        actionTarget = "RAGuidePage.ccbi",
        actionType = "delaytime",
        param = "0.5",
        nextActionId = "10003705",
        desc = "延迟0.5s"
    },
    [10003690] = {
        actionTarget = "RAGuidePage.ccbi",
        actionType = "delaytime",
        param = "1",
        nextActionId = "10003700",
        desc = "延迟1s"
    },
    [10003692] = {
        actionTarget = "RAGuideBustNode.ccbi",
        actionType = "deleteccb",
        nextActionId = "10003694,10003696",
        desc = "删除头像ccb"
    },
    [10003694] = {
        actionTarget = "RAGuideLabelBlueNode.ccbi",
        actionType = "deleteccb",
        nextActionId = nil,
        desc = "删除对话ccb"
    },
    [10003696] = {
        actionTarget = "RAGuideLabelRedNode.ccbi",
        actionType = "deleteccb",
        nextActionId = nil,
        desc = "删除对话ccb"
    },
    [10003700] = {
        actionType = "showpage",
        varibleName = "RAMissionBarrierGuideDialogPage",
        param = "false",
        nextActionId = nil,
        desc = "移除对话框"
    },
    [10003705] = {
        actionTarget = "RAMissionMap2_March2.ccbi",
        actionType = "deleteccb",
        nextActionId = nil,
        desc = "删除气氛ccb"
    },
    [10003710] = {
        actionType = "gotonextstep",
    },



    [20000010] = {
        actionTarget = "RAMissionMap3.ccbi",
        actionType = "delaytime",
        param = "2",
        nextActionId = "20000020",
        desc = "延迟2s"
    },
    [20000020] = {
        actionTarget = "RAMissionMap3_March1.ccbi",
        actionType = "runani",
        param = "March3_Timeline1",
        nextActionId = "20000040",
        desc = "播放雷达探测动画"
    },
    [20000040] = {
        actionType = "showpage",
        varibleName = "RAMissionBarrierGuideDialogPage",
        param = "true",
        nextActionId = "20000045,20000050",
        desc = "显示基础对话框"
    },
    [20000045] = {
        actionTarget = "RAGuidePage.ccbi",
        actionType = "shownode",
        varibleName = "mBGColor",
        param = "false",
        nextActionId = nil,
        desc = "隐藏黑色底层"
    },
    [20000050] = {
        actionType = "addccb",
        actionTarget = "RAGuidePage.ccbi",
        varibleName = "mBottomGuideTalkNode",
        param = "RAGuideLabelBlueNode.ccbi",
        nextActionId = "20000060,20000070,20000080",
        desc = "把文字框加入到对话框"
    },
    [20000060] = {
        actionType = "addccb",
        actionTarget = "RAGuideLabelBlueNode.ccbi",
        varibleName = "mBustNode",
        param = "RAGuideBustNode.ccbi",
        nextActionId = "20000090",
        desc = "把图像框加入到文字框"
    },
    [20000070] = {
        actionTarget = "RAGuideLabelBlueNode.ccbi",
        actionType = "changelabel",
        varibleName = "mRightGuideLabel",
        param = "@Guidedialog20000070",
        nextActionId = "20000100,20000120",
        desc = "对话：雷达探测到了附近尤里基地的通讯电波"
    },
    [20000080] = {
        actionTarget = "RAGuideLabelBlueNode.ccbi",
        actionType = "changelabel",
        varibleName = "mGuideName",
        param = "@GuideName20000080",
        nextActionId = nil,
        desc = "设置显示名字"
    },
    [20000090] = {
        actionTarget = "RAGuideBustNode.ccbi",
        actionType = "changepic",
        varibleName = "mLeftBustPic",
        param = "tutorial.png",
        nextActionId = "20000110",
        desc = "显示头像"
    },
    [20000100] = {
        actionTarget = "RAGuideLabelBlueNode.ccbi",
        actionType = "runani",
        param = "InAni",
        nextActionId = nil,
        desc = "播放文字框进入动画"
    },
    [20000110] = {
        actionTarget = "RAGuideBustNode.ccbi",
        actionType = "runani",
        param = "LeftAni",
        nextActionId = "20000130",
        desc = "播放图像框进入动画"
    },
    [20000120] = {
        actionTarget = "RAGuidePage.ccbi",
        actionType = "circletarget",
        varibleName = "mTargetNode",
        param = "RAMissionMap3_March1.ccbi,mYuriBaseSprite,3D,100_100",
        nextActionId = nil,
        desc = "圈住目标点"
    },
    [20000130] = {
        actionTarget = "RAGuidePage.ccbi",
        actionType = "addtouchlayer",
        param = "true",
        nextActionId = nil,
        desc = "添加点击层"
    },
    [20000140] = {
        actionTarget = "RAGuidePage.ccbi",
        actionType = "addtouchlayer",
        param = "false",
        nextActionId = nil,
        desc = "移除点击层"
    },
    [20000143] = {
        actionTarget = "RAGuideLabelBlueNode.ccbi",
        actionType = "runani",
        param = "OutAni",
        nextActionId = nil,
        desc = "播放文字框离开动画"
    },
    [20000146] = {
        actionTarget = "RAGuideBustNode.ccbi",
        actionType = "runani",
        param = "LeftOutAni",
        nextActionId = nil,
        desc = "播放图像框离开动画"
    },
    [20000150] = {
        actionTarget = "RAMissionMap3_March1.ccbi",
        actionType = "runani",
        param = "March3_Timeline3",
        nextActionId = "20000160,20000170",
        desc = "播放HUD弹出动画"
    },
    [20000160] = {
        actionTarget = "RAGuidePage.ccbi",
        actionType = "circletarget",
        varibleName = "mTargetNode",
        param = "RAMissionMap3_March1.ccbi,mYuriBaseHUDSprite,3D,100_100",
        nextActionId = nil,
        desc = "圈住目标点"
    },
    [20000170] = {
        actionTarget = "RAGuidePage.ccbi",
        actionType = "addtouchlayer",
        param = "true",
        nextActionId = nil,
        desc = "添加点击层"
    },
    [20000180] = {
        actionTarget = "RAGuidePage.ccbi",
        actionType = "addtouchlayer",
        param = "false",
        nextActionId = nil,
        desc = "移除点击层"
    },
    [20000185] = {
        actionTarget = "RAGuidePage.ccbi",
        actionType = "circletarget",
        varibleName = "mTargetNode",
        param = "false",
        nextActionId = nil,
        desc = "圈住目标点"
    },
    [20000190] = {
        actionTarget = "RARootManager",
        varibleName = "OpenPage,RATroopChargePage",
        actionType = "executescriptfunction",
        param = "coord=707|1185,name=尤里残部,icon=Monster_05_HeadPortait.png,marchType=2,times=1",
        nextActionId = "20000200,20000193",
        desc = "弹出出征页面"
    },

    [20000193] = {
        actionTarget = "RAGuideBustNode.ccbi",
        actionType = "deleteccb",
        nextActionId = "20000196",
        desc = "删除头像ccb"
    },
    [20000196] = {
        actionTarget = "RAGuideLabelBlueNode.ccbi",
        actionType = "deleteccb",
        nextActionId = nil,
        desc = "删除对话ccb"
    },


    [20000200] = {
        actionTarget = "RAGuidePage.ccbi",
        actionType = "addtouchlayer",
        param = "true",
        nextActionId = nil,
        desc = "添加点击层"
    },
    [20000210] = {
        actionTarget = "RARootManager",
        varibleName = "ClosePage,RATroopChargePage",
        actionType = "executescriptfunction",
        param = nil,
        nextActionId = nil,
        desc = "关闭出征页面"
    },
    [20000220] = {
        actionTarget = "RAGuidePage.ccbi",
        actionType = "addtouchlayer",
        param = "false",
        nextActionId = nil,
        desc = "删除点击层"
    },
    [20000225] = {
        actionType = "showpage",
        varibleName = "RAMissionBarrierGuideDialogPage",
        param = "false",
        nextActionId = nil,
        desc = "移除对话框"
    },
    [20000230] = {
        actionTarget = "RAMissionMap3_March1.ccbi",
        actionType = "runani",
        param = "March3_Timeline6",
        nextActionId = "20000240",
        desc = "播放出征动画"
    },
    [20000240] = {
        actionTarget = "RARootManager",
        varibleName = "ChangeSceneWithArr",
        actionType = "executescriptfunction",
        param = "sceneType=1,isPassTrans=1",
        nextActionId = nil,
        desc = "回到城内"
    },
}

return missionaction_conf