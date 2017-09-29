--region RAWorldConf.lua

local HP_pb = RARequire('HP_pb')
local World_pb = RARequire('World_pb')
local Const_pb = RARequire('Const_pb')

-- 变色蒙板颜色表
local MaskColors =
{
    RED  	= {key = 'RED',   color = {r = 255, g = 60,  b = 0}},
	BLUE 	= {key = 'BLUE',  color = {r = 45,  g = 140, b = 248}},
    GREEN 	= {key = 'GREEN', color = {r = 57,  g = 199, b = 13}},
    GREY 	= {key = 'GREY',  color = {r = 148, g = 148, b = 148}}
}

local RAWorldConfig =
{
    -- 怪物类型
    EnemyType = {
        Normal = 1,
        Elite = 2,
    },
    
    TmxFile         = 'xworldmap.tmx',
    GroundLayer     = 'background',     --背景层
    Face1Layer      = 'face1',          --装饰层1
    Face2Layer      = 'face2',			--装饰层2
    TerritoryLayer  = 'territory',      --领地数据层
    ObjGroup        = 'city_building',

    Zorder_ObjGroup = 5,
    Zorder_BaseLayer = 10,

    MapScale_Def = 0.9,
    MapScale_Min = 0.7,
    MapScale_Max = 1.7,
    MapScale_Fade = 1.7,

    -- 地块更新区域大小
    MapUpdateSize = RACcp(10, 42),
    -- 刷新地图时预留地块大小
    MapReserveSize = RACcp(4, 10),

    Camera_PerspectiveParam = 0.3,

    Capital =
    {
        GridCnt = 7,
        Image   = 'capital.png',
        Icon    = 'Favorites_Icon_Building_06.png',
        Name    = '@Capital',
    },

    Height =
    {
        -- 主UI顶部菜单区高度
        MainUITopBanner = 50,
        -- 主UI底部菜单区高度
        MainUIBottomBanner = 130,
        -- 加速道具使用页面高度百分比
        MarchUseItemPage = 0.41,
    },


    mapSize = nil,
    tileSize = nil,
    viewSize = nil,
    halfTile = nil,
    winCenter = nil,

    FavoriteType =    -- 收藏类型: 标记、朋友、敌人
    {
        Mark    = 1,
        Friend  = 2,
        Enemy   = 3
    },

    EmptyTileIcon =
    {
        ['@WorldArea001'] = 'Favorites_Icon_Terrain_01.png',
        ['@WorldArea002'] = 'Favorites_Icon_Terrain_03.png',
        ['@WorldArea003'] = 'Favorites_Icon_Terrain_02.png',
        ['@WorldArea004'] = 'Favorites_Icon_Terrain_05.png',
        ['@WorldArea005'] = 'Favorites_Icon_Terrain_04.png',
        ['@WorldArea006'] = 'Favorites_Icon_Building_05.png',
        ['@WorldArea007'] = 'Favorites_Icon_Building_06.png'
    },

    -- 资源标识图
    ResourceFlagIcon =
    {
        [World_pb.SELF]         = 'Collection_Icon_Me.png',
        [World_pb.GUILD_FRIEND] = 'Collection_Icon_Ally.png',
        [World_pb.ENEMY]        = 'Collection_Icon_Enemy.png'
    },

    -- 城点标识
    RelationFlagColor =
    {
        [World_pb.SELF]         = MaskColors.BLUE,
        [World_pb.GUILD_FRIEND] = MaskColors.GREEN,
        [World_pb.TEAM_LEADER]  = MaskColors.GREEN,
        [World_pb.ENEMY]        = MaskColors.RED,
        [World_pb.NONE]         = MaskColors.RED,
    },
    MaskColor4None =
    {
    	[World_pb.RESOURCE]        = MaskColors.GREY,
        [World_pb.GUILD_TERRITORY] = MaskColors.GREY
	},

    -- 联盟堡垒icon
    TerritoryRelationIcon =
    {
        [World_pb.SELF]     = 'WorldMap_Icon_Alliance_Blue.png',
        [World_pb.ENEMY]    = 'WorldMap_Icon_Alliance_Red.png',
        [World_pb.NONE]     = 'WorldMap_Icon_Alliance_Gray.png'
    },

    MigrateTile =
    {
        Block = 'Tile_Red.png',
        Allow = 'Tile_Green.png',
        Scale = 1.9
    },

    OperType =      -- 操作类型
    {
        Add     = 1,
        Update  = 2
    },
    OperationOkTip = -- 发送协议返回操作成功提示
    {
        [HP_pb.WORLD_FAVORITE_ADD_C]        = '@AddFavoriteOK',
        [HP_pb.WORLD_FAVORITE_UPDATE_C]     = '@EditFavoriteOK',
        -- [HP_pb.NUCLEAR_MACHINE_CREATE_C]    = '@BuildSiloOK'
    },
    ChooseCcbi =
    {
        [1] = 'Ani_Map_Choose_1x1.ccbi',
        [2] = 'Ani_Map_Choose_2x2.ccbi',
        [3] = 'Ani_Map_Choose_3x3.ccbi',
        [7] = 'Ani_Map_Choose_3x3.ccbi'
    },

    Spine =
    {   
        -- 驻扎
        Camp        = 'Camp',
        -- 基地车
        CityCar     = 'Mcv_Trans',
        -- 尤里的基地
        YuriCastle  = 'YuriCastle'
    },

    -- 音效半径，X大于或者Y大于这个范围的时候不播放音效
    VideoEffect_Radius = RACcp(32, 32),

    -- 核弹轰炸影响范围
    BombEffect_Radius = RACcp(4, 4),

    -- 超出些范围重新获取城点数据
    FetchPoint_Radius = RACcp(3, 7),

    -- 检测领地是否在视野内
    CheckMist_Radius = RACcp(4, 12),

    -- 建筑相关
    Building =
    {
        -- 保护罩的缩放
        Guard_Scale = 0.6,
        -- 总统府保护罩的缩放
        PresidentGuard_Scale = 2.2,
        -- 名字y轴偏移
        Name_OffsetY = 30,
        -- 雕像y轴偏移
        Statue_OffsetY = 384,
        -- 大总统名字偏移
        KingName_OffsetY = 500,
        -- 元帅战倒计时偏移
        KingTimer_OffsetY = 400,

        -- 数据缓存半径
        Cache_Radius = RACcp(12, 24),

        Zorder =
        {
            BackDefense     = -1,
            MainNode        = 2,
            FrontDefense    = 3,	-- load map 后 + mapSize.height
            ContainerNode   = 4,	-- load map 后 + mapSize.height 
            OtherNode       = 5,
            CDNode          = 6,
            GuardNode       = 7
        },
    },

    -- 领地建筑对应territory_building_conf 的id
    TerritoryBuildingId =
    {
        [Const_pb.GUILD_BASTION]    = 100,
        [Const_pb.GUILD_CANNON]     = 113
    },

    -- 资源带名字
    ResourceZoneName =
    {
        [Const_pb.ZONE_1] = '@ResourceZone_1',
        [Const_pb.ZONE_2] = '@ResourceZone_2',
        [Const_pb.ZONE_3] = '@ResourceZone_3',
        [Const_pb.ZONE_4] = '@ResourceZone_4',
        [Const_pb.ZONE_5] = '@ResourceZone_5',
        [Const_pb.ZONE_6] = '@ResourceZone_6'
    },

    -- 怪物形态
    MonsterShape =
    {   
        -- 机械类
        Enginery    = 1,
        -- 生物类
        Biological  = 2
    },

    -- 迷雾相关
    MistCfg =
    {
        MistId2Layer =
        {
            [1] = 'stronghold1',
            [2] = 'stronghold2',
            [3] = 'stronghold3',
            [4] = 'stronghold4'
        },
        DataLayer = 'territory',
        UserScale = 0.125
    },

    -- 超级武器瞄准ccb
    WeaponAimCCB =
    {
        [Const_pb.GUILD_SILO]    = 'Ani_Territory_Nuke_Aim.ccbi',
        [Const_pb.GUILD_WEATHER] = 'Ani_Territory_Storm_Aim.ccbi'
    },

    -- 需要检查是否与装饰物重叠
    CheckDecoTypeList =
    {
        World_pb.RESOURCE,
        World_pb.MONSTER,
        World_pb.PLAYER,
        World_pb.QUARTERED
    },

    BlinkColor =
    {
        Shadow  = {160, 160, 160},
        Warn    = {255, 60,  0}
    },

    -- 添加着火、雷击效果的延时
    AddHurtEffectDelay = 1.5,

    -- 行军Hud目标html的绽放
    MarchHtmlScale = 0.8,

    --超级武器类型对应发射平台建筑
    SuperWeaponBuildSiloId =
    {
        [Const_pb.GUILD_SILO]       = Const_pb.NUCLEAR,
        [Const_pb.GUILD_WEATHER]    = Const_pb.WEATHER
    }
}

local hudBtnType =
{
    AddFavorite             = 0,    -- 添加收藏
    Migrate                 = 1,    -- 迁城
    Settle                  = 2,    -- 放置
    InviteToMigrate         = 3,    -- 邀请迁城
    Occupy                  = 4,    -- 占领
    EnterCity               = 5,    -- 进入城市
    CityGain                = 6,    -- 城市增益
    Attack                  = 7,    -- 进攻
    Spy                     = 8,    -- 侦查
    GeneralDetail           = 9,    -- 将军详情
    Explain                 = 10,   -- 说明
    CancelMigrate           = 11,   -- 取消迁城
    MarchSpeedUp            = 12,   -- 行军加速
    MarchRecall             = 13,   -- 行军召回
    MarchArmyDetail         = 14,   -- 行军部队
    SoldierAid              = 15,   -- 士兵援助
    ResourceAid             = 16,   -- 资源援助
    DeclareWar              = 17,   -- 集结宣战
    Recall                  = 18,   -- 召回
    ArmyDetail              = 19,   -- 部队详情
    OccupyTerritory         = 20,   -- 占领领地
    QuitTerritory           = 21,   -- 放弃领地
    LaunchBomb              = 22,   -- 发射核弹
    ViewOwnership           = 23,   -- 查看发射井
    CancelLaunch            = 24,   -- 取消发射
    ViewDetail		        = 25,	-- 查看详情
    OpenSilo                = 26,   -- 展开发射井
    CloseSilo               = 27,   -- 关闭发射井
    StrongholdDetail        = 28,   -- 据点详情
    Garrison                = 29,   -- 驻守
    MassGarrison            = 30,   -- 集结驻守
    Reoccupy                = 31,   -- 收复
    MassReoccupy            = 32,   -- 集结收复
    Reinforce               = 33,   -- 增援
    MassReinforce           = 34,   -- 集结增援
    Collect                 = 35,   -- 采集
    LaunchWeather           = 36,   -- 发射雷电风暴
    ViewDetail_President    = 37,   -- 总统详情
    ViewGarrison            = 38,   -- 守军信息
    Appoint                 = 39,   -- 任命
    ViewGarrison_President  = 40,   -- 总统府查看守军
    Garrison_President      = 41,   -- 总统府驻守
    MassGarrison_President  = 42,   -- 总统府集结驻守
    Recall_President        = 43,   -- 总统府召回
    TerritoryList           = 44,   -- 领地列表
    ViewGarrison_Territory  = 45,   -- 领地查看守军
    BuildNuclearSilo        = 46,   -- 建造核弹发射平台
    BuildWeatherSilo        = 47,   -- 建造闪电风暴发射平台
}
RAWorldConfig.HudBtnType = hudBtnType

RAWorldConfig.HudBtnLang =
{
    [hudBtnType.Migrate]                = '@Migrate',
    [hudBtnType.Settle]                 = '@Settle',
    [hudBtnType.InviteToMigrate]        = '@InviteToMigrate',
    [hudBtnType.Occupy]                 = '@Occupy',
    [hudBtnType.EnterCity]              = '@EnterCity',
    [hudBtnType.CityGain]               = '@CityGain',
    [hudBtnType.Attack]                 = '@DoAttack',
    [hudBtnType.Spy]                    = '@Spy',
    [hudBtnType.GeneralDetail]          = '@GeneralDetail',
    [hudBtnType.Explain]                = '@Explain',
    [hudBtnType.CancelMigrate]          = '@Cancel',
    [hudBtnType.MarchSpeedUp]           = '@Speedup',
    [hudBtnType.Recall]                 = '@Recall',
    [hudBtnType.ArmyDetail]             = '@TroopsInfo',
    [hudBtnType.SoldierAid]             = '@SoldierAid',
    [hudBtnType.ResourceAid]            = '@ResourceAid',
    [hudBtnType.DeclareWar]             = '@DeclareWar',
    [hudBtnType.OccupyTerritory]        = '@Occupy',
    [hudBtnType.QuitTerritory]          = '@Quit',
    [hudBtnType.LaunchBomb]             = '@LaunchBomb',
    [hudBtnType.ViewOwnership]          = '@ViewDetails',
    [hudBtnType.CancelLaunch]           = '@Cancel',
    [hudBtnType.ViewDetail]			    = '@ViewDetail',
    [hudBtnType.OpenSilo]               = '@OpenSilo',
    [hudBtnType.CloseSilo]              = '@CloseSilo',
    [hudBtnType.StrongholdDetail]       = '@StrongholdDetail',
    [hudBtnType.Garrison]               = '@Garrison',
    [hudBtnType.MassGarrison]           = '@MassGarrison',
    [hudBtnType.Reoccupy]               = '@Reoccupy',
    [hudBtnType.MassReoccupy]           = '@MassReoccupy',
    [hudBtnType.Reinforce]              = '@Reinforce',
    [hudBtnType.MassReinforce]          = '@MassReinforce',
    [hudBtnType.Collect]                = '@DoCollect',
    [hudBtnType.LaunchWeather]          = '@LaunchWeather',
    [hudBtnType.ViewDetail_President]   = '@ViewPresidentDetail',
    [hudBtnType.ViewGarrison]           = '@ViewGarrison',
    [hudBtnType.Appoint]                = '@Appointment',
    [hudBtnType.ViewGarrison_President] = '@ViewGarrison',
    [hudBtnType.Garrison_President]     = '@Garrison',
    [hudBtnType.MassGarrison_President] = '@MassGarrison',
    [hudBtnType.Recall_President]       = '@Recall',
    [hudBtnType.TerritoryList]          = '@TerritoryList',
    [hudBtnType.ViewGarrison_Territory] = '@ViewGarrison',
    [hudBtnType.BuildNuclearSilo]       = '@BuildNuclearSilo',
    [hudBtnType.BuildWeatherSilo]       = '@BuildWeatherSilo'
}

RAWorldConfig.HudBtnImg =
{
    [hudBtnType.Migrate]                = 'HUD_MoveCity.png',
    [hudBtnType.Settle]                 = 'HUD_Explain.png',
    [hudBtnType.InviteToMigrate]        = 'HUD_MoveCity.png',
    [hudBtnType.Occupy]                 = 'HUD_Occupy.png',
    [hudBtnType.EnterCity]              = 'HUD_City.png',
    [hudBtnType.CityGain]               = 'HUD_CityGain.png',
    [hudBtnType.Attack]                 = 'HUD_Attack.png',
    [hudBtnType.Spy]                    = 'HUD_Spy.png',
    [hudBtnType.GeneralDetail]          = 'HUD_GeneralDetails.png',
    [hudBtnType.Explain]                = 'HUD_Explain.png',
    [hudBtnType.CancelMigrate]          = 'HUD_CancelMoveCity.png',
    [hudBtnType.MarchSpeedUp]           = 'HUD_MarchAccelerate.png',
    [hudBtnType.Recall]                 = 'HUD_MarchRecall.png',
    [hudBtnType.ArmyDetail]             = 'HUD_ArmyDetails.png',
    [hudBtnType.SoldierAid]             = 'HUD_AllianceSoldierAid.png',
    [hudBtnType.ResourceAid]            = 'HUD_AllianceResourceAid.png',
    [hudBtnType.DeclareWar]             = 'HUD_Gather.png',
    [hudBtnType.OccupyTerritory]        = 'HUD_OccupiedTerritory.png',
    [hudBtnType.QuitTerritory]          = 'HUD_GiveUpterritory.png',
    [hudBtnType.LaunchBomb]             = 'HUD_LaunchNuclear.png',
    [hudBtnType.ViewOwnership]          = 'HUD_Explain.png',
    [hudBtnType.CancelLaunch]           = 'HUD_Cancel.png',
    [hudBtnType.ViewDetail]			    = 'HUD_CheckTerritory.png',
    [hudBtnType.OpenSilo]               = 'HUD_CheckTerritory.png',
    [hudBtnType.CloseSilo]              = 'HUD_CheckTerritory.png',
    [hudBtnType.StrongholdDetail]       = 'HUD_CheckTerritory.png',
    [hudBtnType.Garrison]               = 'HUD_AllianceSoldierAid.png',
    [hudBtnType.MassGarrison]           = 'HUD_AllianceSoldierAid.png',
    [hudBtnType.Reoccupy]               = 'HUD_OccupiedTerritory.png',
    [hudBtnType.MassReoccupy]           = 'HUD_OccupiedTerritory.png',
    [hudBtnType.Reinforce]              = 'HUD_AllianceSoldierAid.png',
    [hudBtnType.MassReinforce]          = 'HUD_AllianceSoldierAid.png',
    [hudBtnType.Collect]                = 'HUD_Occupy.png',
    [hudBtnType.LaunchWeather]          = 'HUD_LaunchNuclear.png',
    [hudBtnType.ViewDetail_President]   = 'HUD_President_Job.png',
    [hudBtnType.ViewGarrison]           = 'HUD_Explain.png',
    [hudBtnType.Appoint]                = 'HUD_President_Job.png',
    [hudBtnType.ViewGarrison_President] = 'HUD_President_StationedInfo.png',
    [hudBtnType.Garrison_President]     = 'HUD_President_Stationed.png',
    [hudBtnType.MassGarrison_President] = 'HUD_President_GatherStationed.png',
    [hudBtnType.Recall_President]       = 'HUD_President_Recall.png',
    [hudBtnType.TerritoryList]          = 'HUD_CheckTerritory.png',
    [hudBtnType.ViewGarrison_Territory] = 'HUD_President_StationedInfo.png',
    [hudBtnType.BuildNuclearSilo]       = 'HUD_LaunchNuclear.png',
    [hudBtnType.BuildWeatherSilo]       = 'HUD_LaunchNuclear.png'
}

RAWorldConfig.WeaponBuildSiloHud =
{
    [Const_pb.GUILD_SILO]       = hudBtnType.BuildNuclearSilo,
    [Const_pb.GUILD_WEATHER]    = hudBtnType.BuildWeatherSilo
}

RAWorldConfig.WeaponLaunchHud =
{
    [Const_pb.GUILD_SILO]       = hudBtnType.LaunchBomb,
    [Const_pb.GUILD_WEATHER]    = hudBtnType.LaunchWeather
}

function RAWorldConfig:ResetZorder()
	local zorders = self.Building.Zorder
	if zorders.FrontDefense < self.mapSize.height then
		zorders.FrontDefense = zorders.FrontDefense + self.mapSize.height
		zorders.ContainerNode = zorders.ContainerNode + self.mapSize.height
	end
end

return RAWorldConfig

--endregion
