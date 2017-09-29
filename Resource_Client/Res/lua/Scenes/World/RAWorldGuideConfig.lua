--region RAWorldConf.lua
--Date

local World_pb = RARequire('World_pb')

-- 新手引导配置
local RAWorldGuideConfig =
{
    -- 新手id
    IdList =
    {
        FirstBattle_Begin   = 5,
        PreExpandCity       = 8,
        GatherArmy          = 9,
        FirstBattle_Fire    = 37,
        SecondBattle_March  = 40,
        SecondBattle_Fire   = 47,
        
        -- 离开城外前的一步(下一步去城内) 
        PreLeaveWorld_1     = 9,
        --PreLeaveWorld_2     = 47
    },

    -- 坐标: 我,敌,友
    MapPos =
    {
        MapSelf = RACcp(120, 103),
        Self = RACcp(120, 101),
        Enemy = RACcp(126, 95),
        Friend = RACcp(126, 107),
        GoldResource = RACcp(122, 100),

        Center4Enemy = RACcp(124, 97),
        Center4Friend = RACcp(124, 105)
    },
    --移动镜头的偏移
    MoveCameraOffset = {
        FirstBattleShowEnemy = RACcp(-1200,-700),
        FirstBattleBackCity = RACcp(1200,700),
        SecondBattleShowEnemy = RACcp(-2600,-1500),
        SecondBattleBackCity = RACcp(2600,1500),
        SecondBattleToFriend = RACcp(-380,225),
        SecondBattleFightMove = RACcp(380,-225),
        SecondBattleFightMove2 = RACcp(-150,-80),
        --SecondBattleFightMove2 = RACcp(530,-145),
    },
    -- 时间(单位：秒)
    Duration =
    {
        FixedLensTime = 2,
        FirstBattleShowEnemy = 1,
        FirstBattleDelay = 1,
        FirstBattleBackCity = 1/6,
        SecondBattleShowEnemy = 1,
        SecondBattleDelay = 6,
        SecondBattleBackCity = 1/6,
        SecondBattleToFriend = 1,
        SecondBattleFightPrepare = 2,
        SecondBattleFightMove = 3,
        SecondBattleFightPrepare2 = 2,
        SecondBattleFightMove2 = 1/3,
        ShowEnemy = 1,
        MoveCamera = 2,
        EnemyMarch = 100,
        FriendMarch = 8,
        ShowSelf = 4,
        GotoNextStep = 2,
        UpdateMarch = 200, -- 单位：ms
        ShowSelfInCity = 1.5,--第一步在世界显示主基地的时间
        ShowClickCarDur = 1,--显示点击基地车的时间
        YuriLeaveMove = 1,--尤里逃离视野移动时间
        YuriLeave = 5--尤里逃离时间
    },

    MarchType =
    {
        Enemy   = World_pb.ENEMY,
        Friend  = World_pb.GUILD_FRIEND
    },

    --世界地图缩放度
    MapScale =
    {
        ExpandCarScale = 1.1,
        FirstBattleIngScale = 1.1,
        SecondBattlePrepareScale = 0.9,
        SecondBattleFriendScale = 1.1,
        SecondBattleYuriLeaveScale = 0.9
    },
    --世界地图缩放时间
    MapScaleTime = 
    {
        ExpandCarScaleTime = 0.5,
        FirstBattleIngScaleTime = 0.5
    },

    -- 引导点击区
    ClickArea =
    {
        --中心点位置偏移
        PosOffset = RACcp(0, -20),
        -- 宽高
        Size = {256, 160},
        -- 箭头位置偏移
        ArrowOffset = RACcp(0, 84)
    }       
}

return RAWorldGuideConfig

--endregion
