local Const_pb=RARequire("Const_pb")
local const_conf = RARequire("const_conf")

local RAGameConfig = {
    ResourceType = {
        GOLDORE = Const_pb.GOLDORE ,        -- 矿石 1007
        OIL = Const_pb.OIL,                 -- 石油 1008
        STEEL = Const_pb.STEEL,             --钢铁  1009
        TOMBARTHITE = Const_pb.TOMBARTHITE, --稀土 1010
    },

    -- 特定道具ID
    ItemId =
    {
        -- 定向(高级)迁城道具
        DirectionalMigrate  = 800101,
        -- 新手定向迁城道具
        GuideMigrate        = 800108
    },

    ConfigIDFragment = 
    {
        ID_PLAYER_LEVEL = 700000,
        ID_PLAYER_SHOWCONF = 701000,
        ID_VIP_LEVEL = 22000
    },

    TalentTypes = 
    {
        TALENT_FIGHT = 1,
        TALENT_DEVELOP = 2
    },
    TalentIcons = 
    {
        TALENT_FIGHT_ICON = "ico1071001.png",
        TALENT_DEVELOP_ICON = "ico1073011.png"
    },
    TalentIntroduce = 
    {
        TALENT_FIGHT_INTRO = "@Talent_Fight_Intro",
        TALENT_DEVELOP_INTRO = "@Talent_Develop_Intro"
    },
    TalentResetConsume=
    {
        CONSUME_COUNT = 1
    },

    CirlclePic = 
    {
        CIRCLE_BG = "Common_Tips_PageNum_BG.png",
        CIRCLE_FG = "Common_Tips_PageNum.png",
    },

    MAX_LEVEL = 60,
    MAX_EQUIPNUM = 8,
    Player_Detail_Type_FightingState = 2,
    NOT_START_LANG = "@NotStart",
    Gold_Icon = "Common_Icon_Gold_01.png",
    Diamond_Icon = "Common_Icon_Diamonds.png",
    Portrait_Scale = 0.95,

    TOTAL_GUIDE_NUM = 1721,--新手步骤总数，要新手配置中的新手最大id要大，否则最后一步保存不上
    SwitchGuide = 1,--新手开关
    BattleDebug = 0,--战斗Debug
    GuideGMFlag = false,--新手GM开关
    GuideGMStep = 350,--新手GM 直接跳转步骤
    GuideGMPartId = 1,--新手GM part id
    ShaderNodeEffect = true,--模糊shader开关
    AvoidTouchGuideId = 1000000,--进行引导时，会先添加此id的引导页，防止真正的引导页出来时，用于可以点击
    CommonGuideId = 20000,--普通引导所用的id
    SwitchBarrierGuide = 0,--开启关卡引导

    IsBattleUnitSetMaskColor = 1,--战斗中士兵是否变色
    --背景音乐
    BackgroundMusic = "loading_sound.aac",

    --支付开启
    SwitchPay = 0,--支付开关，1：开启  0：关闭  关闭的时候，点击支付按钮没有响应

    -- 主界面下部菜单类型
    MainUIMenuType = 
    {
        Task = 1,
        Item = 2,
        Mail = 3,
        Menu = 4,
        Alliance = 5,
        AllianceHelp = 6,
    },

    COLOR={
        RED=ccc3(255,0,0),
        GREEN=ccc3(0,255,0),
        GRAY=ccc3(120,120,120),
        WHITE=ccc3(255,255,255),
        LIGHTBULE=ccc3(0,112,192),
        GRASSGREEN=ccc3(79,98,40),
        LIGHTRED=ccc3(228,108,105),
        ROSERED=ccc3(192,0,0),
        BLACK=ccc3(0,0,0),
        YELLOW=ccc3(255,236,56),
        ORANGE=ccc3(255, 139, 75)
    },

    TaskType ={
        Common = 1,
        Recommand = 2
    },

    TaskStatus = {
        CanAccept = 0,
        Complete = 1,
        Rewarded = 2
    },

    CommonTaskNum = 4,

    ElectricStatus = 
    {
        -- 这里的100%和150%配置在const表中，electric_cap1 和 electric_cap2
        -- 减速值为 electric_decrease1 和 electric_decrease2
        Enough = 0,     -- 充足 < 100%
        Intense = 1,    -- 紧张 >= 100% && <= 150%
        NotEnough = 2,  -- 不足   > 150%
    },

    HTMLID = {
        AllianceRecruit             = 10000,    --联盟招募
        AllianceBomb                = 10001,    --联盟导弹
        MailShare                   = 10002,    --邮件分享
        ShowBombPage                = 10003,    --跳转核弹发射页面
        AllianceRedPacketLuckyTry   = 10004,    --联盟拼手气红包    
        AllianceRedPacketOpen       = 10005,    --开启联盟红包
        CorePos                     = 10006,    --跳转到王座位置      
        MarchTarget                 = 10007,    --行军目的地
        WorldPosShow                = 10008,    --世界上一个坐标显示
        LaunchPlatform              = 10009,    --发射平台
    },

    DefaultFontName = "Helvetica",--"WQY.ttf",

    ScienceTreeCellW = 100,

    --音效配置
    Sound = 
    {
        buildingWait = "buildingWait.mp3",--菜单内建筑建造进度音效
        degree = "degree.mp3",--建筑菜单电力条音效
        menuVideo = "menuVideo.mp3",--建筑菜单上方建筑栏视窗预览音效
        v_ConstructionComplete = "v_ConstructionComplete.mp3",--建筑物建造完成语音音效
        build1 = "build1.mp3",--建筑物建造音效1
        start_build_Up = "buildUp.mp3",--建筑物升级时建造音效
        prompt1 = "prompt1.mp3",--建筑物升级时免费加速提示音效
        buildUpComplete = "buildUpComplete.mp3",--建筑物升级完成音效
        up = "up.mp3",--建筑物一键升级完成音效
        data = "data.mp3",--建筑物属性数据进度条音效
        into = "into.mp3",--进入世界战斗地图音效
        move = "move.mp3",
        v_Building = "v_Building.mp3",--开始建造似的语音building
        vbuilding = "v_building.mp3",--开始建造似的语音building
        prompt2 = "prompt2.mp3",--拖动建筑物到不可建造区域提示音
        build2 = "build2.mp3",--拖动建筑物后再次建造是的建造音效
        v_ImGoing = "v_ImGoing.mp3",--战斗界面步兵行军语音音效1
        v_OnTheWaySir = "v_OnTheWaySir.mp3",--战斗界面步兵行军语音音效2
        groundForcesMove = "groundForcesMove.mp3",--战斗界面地面部队行军音效
        battleMenuEject = "battleMenuEject.mp3",--战斗界面选择兵力数量菜单弹出音效
        slide = "slide.mp3",--战斗界面选择兵力数量滑动音效
        helicopterMove = "helicopterMove.mp3",--战斗界面直升飞机行军音效
        promptCursor = "promptCursor.mp3",--新手引导圆圈的音效
        prompt3 = "prompt3.mp3",--战斗力提升提示音效
        click_build_2014 = "clickACHQ.mp3",--点击空指部
        click_build_2024 = "clickWarehouse.mp3",--点击仓库
        click_build_2020 = "clickSchoolField.mp3",--点击校场
        click_build_2022 = "clickRadar.mp3",--点击雷达
        click_build_2026 = "clickRepairPlant.mp3",--点击修理厂
        click_build_2151 = "clickPrismTower.mp3",--点击光棱塔
        click_build_2010 = "clickConstructionFactory.mp3",--点击建筑工厂
        click_build_2011 = "clickBarracks.mp3",--点击兵营
        click_build_2013 = "clickRemoteWeaponsFactory.mp3",--点击远程武器工厂
        click_build_2015 = "clickOperationalLaboratory.mp3",--点击作战实验室
        click_build_2101 = "clickRefinery.mp3",--点击矿石精炼厂
        click_build_2102 = "clickOilWell.mp3",--点击油井
        click_build_2103 = "clickSteelPlant.mp3",--点击炼钢厂
        click_build_2012 = "clickChariotFactory.mp3",--点击战车工厂
        click_build_2023 = "clickCrackGenerator.mp3",--点击裂缝产生器
        click_build_2025 = "clickPowerPlant.mp3",--点击发电厂
        click_build_2027 = "prison.mp3",--点击监狱  
        click_build_2104 = "clickRareEarthSmelter.mp3",--点击稀土冶炼厂
        click_build_2016 = "clickEmbassy.mp3",--点击大使馆
        click_build_2017 = "clickTradeCentre.mp3",--点击贸易中心
        click_build_2018 = "clickSatelliteCommunications.mp3",--点击卫星通讯所
        click_build_2019 = "clickCombatReadinessInstitute.mp3",--点击战备研究所
        click_build_2152 = "clickPatriotMissile.mp3",--爱国者飞弹
        click_build_2153 = "clickPillbox.mp3",--机枪碉堡
        click_build_2205 = "ActivityCenter.mp3", --点击活动中心
		mapClickLaserFloating = "mapClickLaserFloating.mp3",
		mapClickLasherTank = "mapClickLasherTank.mp3",
		mapClickMagnetron = "mapClickMagnetron.mp3",
		mapClickMindControlCar = "mapClickMindControlCar.mp3",
		mapClickMadHordeDead = "mapClickMadHordeDead.mp3",
		mapClickYuriInitiateDead = "mapClickYuriInitiateDead.mp3",
		mapClickVirusSniper = "mapClickVirusSniper.mp3",
		mapClickGattlingCannonVehicle = "mapClickGattlingCannonVehicle.mp3",
		laserFloatingAttack = "laserFloatingAttack.mp3",
		lasherTankAttack = "lasherTankAttack.mp3",
		magnetronAttack = "magnetronAttack.mp3",
		mindControlCarAttack = "mindControlCarAttack.mp3",
		madHordeAttack = "madHordeAttack.mp3",
		yuriInitiateAttack = "yuriInitiateAttack.mp3",
		virusSniperAttack = "virusSniperAttack.mp3",
		gattlingCannonVehicleAttack = "gattlingCannonVehicleAttack.mp3",
		laserFloatingDead = "laserFloatingDead.mp3",
		lasherTankDead = "lasherTankDead.mp3",
		magnetronDead = "magnetronDead.mp3",
		mindControlCarDead = "mindControlCarDead.mp3",
		madHordeDead = "madHordeDead.mp3",
		yuriInitiateDead = "yuriInitiateDead.mp3",
		virusSniperDead = "virusSniperDead.mp3",
		gattlingCannonVehicleDead = "gattlingCannonVehicleDead.mp3",

        --新手音效
        BaseDeformation = "BaseDeformation.mp3",
        ProduceTank = "ProduceTank.mp3",
        AlarmSound = "AlarmSound.mp3",
        BaseWasLocked = "BaseWasLocked.mp3",
        FristWaveOfTroops = "FristWaveOfTroops.mp3",
        StrikeSound = "StrikeSound.mp3",
        FristBattles = "FristBattles.mp3",
        SecondWaveOfTroops = "SecondWaveOfTroops.mp3",
        SecondBattles = "SecondBattles.mp3",
        VictorySound = "VictorySound.mp3",
        GuideSound = "GuideSound.mp3",
        TransmissionStart = "TransmissionStart.mp3",
        TransmissionLoop = "TransmissionLoop.mp3",
        TransmissionBaseDeformation = "TransmissionBaseDeformation.mp3",
        BaseTravel = "BaseTravel.mp3",
        TrainingSoldiers = "TrainingSoldiers.mp3",
        DialogueAdmission = "DialogueAdmission.mp3",
        SpaceTransAndBaseDefor = "SpaceTransAndBaseDefor.mp3",
        yurileave = "yurileave.mp3",
        businessmanHelicopterPass = "businessmanHelicopterPass.mp3",
        businessmanHelicopterStop = "businessmanHelicopterStop.mp3",
		
        --点击下方任务图标菜单弹出音效
        --点击下方物品图标菜单弹出音效
        --点击下方邮件图标菜单弹出音效
        --点击下方菜单图标方框弹出音效
        --主界面点击左侧队列按键时菜单弹出音效
        click_main_botton_banner = "clickMenuEject.mp3",

        --点击上面5个返回
        click_main_botton_banner_back = "clickMenuBack.mp3",

        --主界面下方点击领取任务奖励的音效
        click_main_botton_collectReward = "collectReward.mp3",

        harvest = "harvest.mp3", --收兵时播放

        clickFlag = "clickFlag.mp3", --点击国旗（部队详情）
        
        clickMineCar = "clickMineCar.mp3",  --点击铲车音效
        --战斗相关音效
        battle_fire_missle = 'v3MissileLaunch.mp3', --战斗界面V3导弹发射音效
        battle_fire_infantry = 'machineGun.mp3',  --战斗界面步兵机关枪音效
        battle_fire_helicopter = 'helicopterAttack.mp3',    --战斗界面直升飞机攻击音效
        battle_fire_tank = 'tankAttack.mp3',  --战斗界面坦克攻击音效
        battle_fire_tower = 'pagodaAttack.mp3',    --战斗界面光棱塔发射攻击音效

        battle_ready_infantry = 'sit.mp3', --战斗界面步兵坐下音效
        battle_ready_tower = 'pagodaStorageCapacity.mp3',   --战斗界面光棱塔蓄力音效
        
        battle_tower_show = 'pagodaEject.mp3', --战斗界面光棱塔弹出音效
        
        battle_result_burn = 'fire.mp3',    --战斗界面基地爆炸后着火音效
        battle_result_explode = 'buildingeExplosion.mp3',  --战斗界面基地爆炸音效
        battle_result_win = 'v_YouAreVictory.mp3', --战斗界面宣布胜利语音音效
        battle_result_cheer = 'win.mp3', --战斗界面战斗胜利欢呼音效

        clickSoldiers_1 = 'clickSoldiers1.mp3',--主界面点击士兵音效1（语音）1,2,3,4
        clickSoldiers_2 = 'clickSoldiers2.mp3',
        clickSoldiers_3 = 'clickSoldiers3.mp3',
        clickSoldiers_4 = 'clickSoldiers4.mp3',

        clickTank_1 = 'clickTank1.mp3',--主界面点击坦克音效1,2,3,4
        clickTank_2 = 'clickTank2.mp3',
        clickTank_3 = 'clickTank3.mp3',
        clickTank_4 = 'clickTank4.mp3',

        clickAircraft_1 = 'clickAircraft1.mp3',--主界面点击飞机音效1,2
        clickAircraft_2 = 'clickAircraft2.mp3',

        clickRocketCar_1 = 'clickRocketCar1.mp3',--主界面点击火箭车音效1,2
        clickRocketCar_2 = 'clickRocketCar2.mp3',

        mapClick = 'mapClick.mp3',					 --点击空地和建筑
        mapClickDetermine = 'mapClickDetermine.mp3', --占领、出征、迁城
        moveCity = 'overTimeSpaceTransfer.mp3',		 --迁城动画
        hud_bastion = 'guildFortressNormal.mp3', --点击联盟堡垒建筑，出现hud时的音效
        hud_silo = 'nuclearSiloNormal.mp3', --点击核弹发射井建筑，出现hud时的音效
        bomb_ready = 'nuclearSiloActive.mp3', --核弹发射井展开，核弹升起
        bomb_launch = 'nuclearSiloLaunch.mp3', --核弹升空
        bomb_target = 'nuclearSiloTarget.mp3', --核弹发射过程中，被选中目标处的waring
        bomb_warning = 'airDefenseWarning.mp3', --防空警报
        bomb_explode = 'nuclearSiloExplosion.mp3', --核弹落地并爆炸

        bomb_storm_warning = 'thunderStormWarning.mp3', -- 天气控制器防空警报
        bomb_storm_explode = 'thunderStormAttack.mp3', --天气控制器落地并爆炸



        torture = 'electrocution.mp3', --实施电刑的音效：高压电流不停点击肉体的音效&电流声

        clickEquipPush = "equipPush.mp3", -- 点击强化及进阶按键
        qualityUpCrit = "QualityUpCrit.mp3", -- 进阶暴击
        qualityUpSuccess = "QualityUpSuccess.mp3", --进阶成功

        engineerOut = 'engineerOut.mp3',    --大地图工程师行军1出发（采集非金矿）
        engineerArrive = 'engineerArrive.mp3',  --大地图工程师行军2到达（采集非金矿）
        mineCarOut = 'mineCarOut.mp3',    --大地图矿车行军出门（采集金矿）
        mineCarArrive = 'mineCarArrive.mp3',    --大地图矿车行军到达（采集金矿）
        reconnaissanceAircraftOut = 'reconnaissanceAircraftOut.mp3',    --大地图侦察机行军出门（侦察）

        closeClick = 'click1.mp3', --点击关闭

        --奖励弹框动画音效
        rewardAcquisition = 'rewardAcquisition.mp3',                    -- UI界面奖励获取
        rewardAcquisitionCompleted = 'rewardAcquisitionCompleted.mp3',  --UI界面奖励获取完成
    },
    Tag = {
        TipLayer = 10000,-- tag for the tip layer
    },

    MailType={
        CHAT=Const_pb.CHAT,                                     --玩家聊天
        MOVE_CITY=Const_pb.MOVE_CITY,                           --迁城邀请
        ALLIANCE=Const_pb.ALLIANCE,                             --联盟群发
        ALLIANCE_KICK=Const_pb.ALLIANCE_KICK,                   --踢出联盟
        ALLIANCE_REFUSE_APPLY=Const_pb.ALLIANCE_REFUSE_APPLY,   --拒绝联盟申请
        ALLIANCE_REFUSE_INVITE=Const_pb.ALLIANCE_REFUSE_INVITE, --拒绝联盟邀请
        ALLIANCE_CHANGE_POS=Const_pb.ALLIANCE_CHANGE_POS,       --联盟军阶变更
        ALLIANCE_DISSOLVE=Const_pb.ALLIANCE_DISSOLVE,           --联盟解散
        COLLECT=Const_pb.COLLECT,                               --采集
        CAMP=Const_pb.CAMP,                                     --扎营
        DETECT=Const_pb.DETECT,                                 --侦查
        BE_DETECTED=Const_pb.BE_DETECTED,                       --被侦查
        CURE=Const_pb.CURE,                                     --治疗伤兵
        KILL_MONSTER=Const_pb.KILL_MONSTER,                     --打怪
        FIGHT=Const_pb.FIGHT,                                   --战斗
        SYSMAIL_UPDATE=Const_pb.SYSMAIL_UPDATE,                 --更新公告
        SYSMAIL_NOTICE=Const_pb.SYSMAIL_NOTICE,                 --正常通知
        SYSMAIL_QA=Const_pb.SYSMAIL_QA,                         --问题解决，奖励补偿

    },

    --邮件里不同邮件的数量上限
    MailLimitNum=
    {
        STAR=const_conf["mailLimit"].value,     --收藏邮件
        SYSTEM=const_conf["mailLimit"].value,    --系统邮件
        REPORT=const_conf["mailLimit"].value,   --报告类邮件
    },
    --
    TechLine={
        line="NewCollege_u_Bar.png",
        lineBg="NewCollege_u_Bar_BG.png",
        lineDot="NewCollege_u_Bar_Light.png",
    },

    --ButtonGrayBg
    ButtonBg=
    {
        GARY="Common_Btn_01_B_Gray.png"
    },
    RadarDefaultStr={
        STR="???"
    },


    --邮件类型 以后这里直接换成邮件ID区间
    MAILTYPE={
        PRIVATE=10001,
        ALLIANCE=10002,
        FIGHT = 10003,
        SYSTEM = 10004,
        MONSTERREPORT=10005,
        COLLECTREPORT = 10006
    },

    --账号绑定类型
    BINDACCOUNT_TYPE = {
        createGuest = "GoUserService/createGuest",              --试玩账号创建
        getTryUserlistWithType = "GoUserService/getTryUserlistWithType",   --获取试玩玩具列表和最新试玩账号
        getBindlist = "GoUserService/getBindlist",              --获取绑定的第三方列表
        isBind = "GoUserService/isBindByType",             --是否绑定第三方账号
        switchFb = "GoFbService/switchFb",                 --切换已绑定的账号
        bindFb = "GoFbService/bindFb",                      --绑定账号
        unBind = "GoUserService/unBindByType",             --解绑
        bindGameCenter = "GoGcService/bindGameCenter",      --GameCenter绑定
        bindGooglePlay = "GoGgService/bindGg",              --GooglePlay绑定
        switchGooglePlay = "GoGgService/switchGg",  --切换已绑定的账号
        bindSina = "GoWbService/bindWb",          --微博绑定
        switchSina = "GoWbService/switchWb",        --切换已绑定的账号
    },

    --绑定账号对应的 平台 以及值  (具体来源 查看用户平台统一接口 5.1)
    BINDACCOUNT_PLATFORM = {
        [4] = "NAVERCAFE",      --Navercate
        [6] = "APPSTORE",       --appstore
        [11] = "WEIXIN",        --微信
        [12] = "QQ",            --QQ
        [13] = "SINA",          --新浪登陆
        [14] = "GAMECENTER",    --GameCenter登陆
        [15] = "FACEBOOK",       --FaceBook
        [16] = "GOOGLE",         --Google 
    }
}

return RAGameConfig;
