local Const_pb=RARequire("Const_pb")
local RAGuideConfig = 
{
    GuideStageEnum = {
        StageFirst = 1,                 --从新手第一步到第一阶段结束，isInGuide == true
        StageSecond = 2,                --第一阶段结束到第二阶段开始的自由操作阶段，isInGuide == false
        StageThird = 3                  --第二阶段开始到第二阶段结束isInGuide == true
    },
    KeyWordArray = 
    {
        GuideStartDescription = "GuideStartDescription",
        GuideStart = "GuideStart",
        WorldPrepareOpenBaseCar = "WorldPrepareOpenBaseCar",
        WorldOpenBaseCar = "WorldOpenBaseCar",
        ShowContructionBtn = "ShowContructionBtn",
        CircleContructionBtn = "CircleContructionBtn",
        CircleBuildTypeAndMoveCamera = "CircleBuildTypeAndMoveCamera",
        ChooseTrainSoldierFirst = "ChooseTrainSoldierFirst",
        ChooseTrainSoldier = "ChooseTrainSoldier",
        CircleTrainSoldierBtnFirst = "CircleTrainSoldierBtnFirst",
        CreateTrainImm = "CreateTrainImm",
        RatarBuildCompleted = "RatarBuildCompleted",
        CircleWorldBtn = "CircleWorldBtn",
        PlayMainUIAni = "PlayMainUIAni",
        CircleUpgradeBtn = "CircleUpgradeBtn",
        ActiveVip = "ActiveVip",
        CircleResourceLand = "CircleResourceLand",
        CircleMarchBtn = "CircleMarchBtn",
        CircleHomeBtn = "CircleHomeBtn",
        CircleUseBtn = "CircleUseBtn",
        GotoCity = "GotoCity",
        showWorldBtn = "showWorldBtn",
        ShowWalkieTalkie = "ShowWalkieTalkie",
        CityMoveCameraToBuildArea = "CityMoveCameraToBuildArea",
        CircleFreeBtn = "CircleFreeBtn",
        FirstBattleStart = "FirstBattleStart",
        SecondBattleStart = "SecondBattleStart",
        TonyaForward = "TonyaForward",
        YuriLeave = "YuriLeave",
        FindGuideResourceLand = "FindGuideResourceLand",
        AddAttackBtn = "AddAttackBtn",
        FirstBattleIng = "FirstBattleIng",
        SecondBattleIng = "SecondBattleIng",
        CircleTaskBanner = "CircleTaskBanner",
        CircleWeightNum = "CircleWeightNum",
        TravelShopShow = "TravelShopShow",
        VIPLevelUp = "VIPLevelUp",
        FindGuideMonster = "FindGuideMonster",
        CircleMonster = "CircleMonster",
        CircleAttackBtn = "CircleAttackBtn",
        ShowEnegy = "ShowEnegy",
        CircleTaskBtn = "CircleTaskBtn",
        CircleMarchBtnWithNoDelay = "CircleMarchBtnWithNoDelay",
        ShowElectricLow = "ShowElectricLow",
        ShowElectricHigh = "ShowElectricHigh",
        CircleMarchAcc = "CircleMarchAcc",
        CircleAccToolUseBtn = "CircleAccToolUseBtn",
        AddCoverPage = "AddCoverPage",
        FightMonsterSuc = "FightMonsterSuc",

        CirclePVEBtn = "CirclePVEBtn",
        CirclePVEResultConfirmBtn="CirclePVEResultConfirmBtn",
        CircleHeadIconBtn="CircleHeadIconBtn",
        CircleTalentBtn="CircleTalentBtn",
        CircleTalentCell="CircleTalentCell",
        CircleLearnAllBtn="CircleLearnAllBtn",
        CircleTalentSysMainPageBackBtn="CircleTalentSysMainPageBackBtn",
        CircleRALordMainPageBackBtn="CircleRALordMainPageBackBtn",
        CircleResearchCell="CircleResearchCell",
        CircleNowResearchBtn="CircleNowResearchBtn",
        CirclePVEMapNode="CirclePVEMapNode",
        CirclePVEWorldMapNode="CirclePVEWorldMapNode",
        CirclePVEStartFightNode="CirclePVEStartFightNode",
        CirclePVEBackBtn="CirclePVEBackBtn",
        StartStory="StartStory",
        EndStory="EndStory",
        RemoveCoverPage="RemoveCoverPage",
        CircleBuildInCenter = "CircleBuildInCenter",
        CirclePVEMarchNode = "CirclePVEMarchNode"
      

    },
    --特殊处理的任务id
    guideTaskIds = 
    {
        [100001] = 1,
        [100002] = 1,
        [100003] = 1,
        [100004] = 1,
        [100014] = 1
    },
    --进入游戏，如果在新手期，而且新手关键字是如下其中一个，那么RACityScene中不自动调用gotoNext
    enterNotGotoNext = 
    {
        ["CircleFreeBtn"] = 1
    },
    partNameWithStartId = 
    {
        ["Guide_First"] = 5,
        ["Guide_MainCity_Start_2To3"] = 1500
    },
    partNameWithEndId = 
    {
        ["Guide_First"] = 1480,
        ["Guide_MainCity_Start_2To3"] = 1720
    },
    playGuideStartMovie = true,            --是否播放新手视频
    GuideStartId = 5,
    showQueenBtn = 30000,                --新手普通造兵不显示加速按钮，造兵结束之后恢复正常显示
    mainUIAllInGuideId = 550,           --主UI完全显示的新手步骤id，之后的所有新手步骤，主UI都是显示着的
    worldSceneShowGuideId = 10,        --世界信息全部展示的步骤id，之后的步骤哦，世界上的信息都是正常的。
    TrainSoldierMagicFlag = 20160914,   --跟后端商量好的魔法字
    mainCityLevelLimit = 30,             --限制触发新手的主基地等级
    mainCityLevelPopup = 2,             --限制弹出活动页面的主基地等级：小于该等级，所有的RAPushRemindPageManager管理的页面都不popUp
    showTravelShopGuideId = 1500,
    guideIdKey = "GUIDE_SAVE_STEP",
    DialogDelayShowTime = 0.5,          --延迟弹出的对话框需要延迟的时间
    ConsBtnTwinkleMaincityLvl = 4,      --新手期主基地等级小于该等级时，建筑按钮不闪烁
    PushRemindMaincityLvl = 3,          --开启新手的情况下，主基地小于该等级，不进行push自主弹框的触发
    guideArmyLineDisplayTime = 3,       --新手期间收兵出现连线时间
    normalCollectArmy = 200,            --新手普通造兵收兵开始
    normalCollectTank = 300,            --新手普通造坦克收兵开始
    normalCollectPlane = 430,            --新手普通造飞机收兵开始

    missionCollectArmy = 810,           --新手任务引导造兵开始   ?? 
    gotoResAndMonsterTime = 0.5,        --新手期，世界上移动镜头到资源田和小怪的时间
    taskGuideMaxLevel = 10,             --城内任务引导到大本多少级结束
    taskGuideTime = 3,                  --城内无操作多少秒后出现任务指引
    helperGuideTime = 3,               --城内无操作多少秒后出现小助手提示
    jumpGuideId = 1720,                 --跳过新手时，保存的id，一般为新手最后一步的id

    clickCoverPageCount=30000,            --点击遮罩层的次数来判断是否卡主

    --兵种ID
    FOOT_SOLDIER_L1    = 100011,
    guideSkillId       = 710001,                 --新手引导用的天赋id
    guideScienceId     = 530101,                 --新手引导用的科技id

    guideDebug=false,
    guideIdDebug=310,                           --设置从那部开始的新手引导 最好从城内开始然后修改配置表
    showAllMainUI=320,
    
    battleFailure =344,                     --第一次战斗失败
    battleFailureMissionId = 33,			--第一次战斗失败对应missionId

    reConnectionTime = 3,

    --新手造兵，城内摄像机放大
    CityCameraSetting = 
    {
        SoldierTrain = 0.9
    },
    CityCameraTime = 
    {
        SoldierTrainTime = 1,
        SoldierMoveTime = 6,            -- 新手期间造士兵后镜头移动到集结点时间
        TankMoveTime = 4                -- 新手期间造坦克后镜头移动到集结点时间
    },
    CityTrain = 
    {
        TankMovePos = RACcp(22,53),
        SoldierMovePos = RACcp(21,55),
    },
    GuideLimitType =                    --新手步骤限制类型
    {
        ContainBuild = 1,               --包含某些建筑             
        NotContainBuild = 2,            --一定不包含某些建筑
        BuildLevel = 3                  --某些建筑level满足条件
    },
    GuideTips=                          --光圈的配置大小
    {
        ConfigWidth=64,                 --CCB里光圈的宽
        ConfigHeight=64,                --CCB里光圈的高
        ConfigOffset=9,                 --CCB里光圈的边距
    },

    --创建的建筑类型==>创建好后会自己调用新手的下一步
    ContructBuildFree={
            Const_pb.BARRACKS,                      --兵营
            Const_pb.FIGHTING_COMMAND,              --作战指挥部
            Const_pb.WAR_FACTORY,                   --战车工厂
            Const_pb.AIR_FORCE_COMMAND,             --空指部
            Const_pb.POWER_PLANT,                   --电厂
            Const_pb.ORE_REFINING_PLANT,            --矿石精鍊厂
            Const_pb.RADAR,                         --雷达
            Const_pb.FIGHTING_LABORATORY            --作战实验室
    },

    --建筑免费升级==》点击调用新手的下一步
    UpgradeBuildFree={
        Const_pb.CONSTRUCTION_FACTORY,              --大本
        Const_pb.BARRACKS,                          --兵营
        Const_pb.POWER_PLANT,                       --电厂
        Const_pb.RADAR,                             --雷达
    }
}

return RAGuideConfig