-- 建筑的一些常量

-- 建筑状态 --把建筑状态和建筑动画分开了，因为建筑状态有可能是一系列动画构成
BUILDING_STATE_TYPE = 
{
    CONSTRUCTION    = "Construction",         --创建    
    IDLE            = "Idle",                 --空闲
    UPGRADE_START   = "Upgrade_Start",        --开始升级
    UPGRADE         = "Upgrade",              --升级中
    UPGRADE_FINISH  = "Upgrade_Finish",       --升级完成
    WORKING_START   = "Working_Start",        --开始工作
    WORKING         = "Working",              --工作中
    WORKING_FINISH  = "Working_Finish",       --工作完成
    WORKING_CANCEL  = "Working_Cancel",       --取消工作状态
    BROKEN          = "Broken",               --毁坏
    FULL            = "Full",                 --满载
    CANCEL          = "Cancel",               --取消
    MOVE_FINISH     = "MOVE_FINISH",          --移动完成
}

BUILDING_ANIMATION_TYPE = 
{
    CONSTRUCTION      = "Construction",         --创建  
    CONSTRUCTION_MAP  = "Constructionoutside",  --世界迁城动画
    IDLE              = "Idle",                 --空闲
    IDLE_MAP          = 'Idle_map',             --世界上的空闲
    IDLE_NIGHT        = 'Idle_night',           --夜晚空闲状态
    UPGRADE_START     = "Upgrade_Start",        --开始升级
    UPGRADE           = "Upgrade",              --升级中
    UPGRADE_FINISH    = "Upgrade_Finish",       --升级完成
    WORKING_START     = "Working_Start",        --开始工作
    WORKING           = "Working",              --工作中
    WORKING_NIGHT     = "Working_night",        --晚上工作中
    WORKING_MAP       = "Working_map",          --世界上的工作中
    WORKING_FINISH    = "Working_Finish",       --工作完成
    BROKEN            = "Broken",               --毁坏
    BROKEN_MAP        = "Broken_map",           --世界上的毁坏
    FULL              = "Full",                 --满载
    CANCEL            = "Cancel",               --取消
    ORIGIN            = 'Car',                  --原始状态
    ATTACK            = 'Attack',               --攻击
    DIE               = 'Die',                  --死亡
    START             = 'Idle_Ready',           --启动
    READY_LAUNCH      = 'Idle_ReadyLaunch',     --准备发射
    LAUNCH            = 'Launch',               --发射
    FEIDN_DEATH       = 'Feidn_death',          --假死
    FEIDN_DEATH_NIGHT = 'Feidn_death_n',        --假死晚上
}

BUILDING_BTN_TYPE = 
{
    DETAIL                            = 0,  --详情
    UPGRADE                           = 1,  --升级
    MAKE                              = 2,  --研制
    RESEARCH                          = 3,  --研究
    TREAT                             = 4,  --治疗
    SPEEDUP                           = 5,  --加速
    SOLDIER_WOUNDED                   = 6,  --伤兵状态
    GOLDSPEEDUP                       = 7,  --金币加速
    GETTROOP                          = 8,  --领大兵
    FREETIME                          = 9,  --免费时间
    TRAIN_BARRACKS                    = 10, --训练步兵
    TRAIN_WAR_FACTORY                 = 11, --训练战车
    TRAIN_REMOTE_FIRE_FACTORY         = 12, --训练远程火力
    TRAIN_RAIR_FORCE_COMMAND          = 13, --训练空军
    CANCEL_BUILDING_UPGRADE           = 14, --取消建筑升级
    CANCEL_TRAIN                      = 15, --取消训练
    CANCEL_RESEARCH                   = 16, --取消研究
    CANCEL_MAKE                       = 17, --取消研制
    CANCEL_TREAT                      = 18, --取消治疗
    RADAR                             = 19, --雷达
    HELP                              = 20, --联盟帮助
    EMBASSY                           = 21, --大使馆
    PRISON                            = 22, --监狱
    WAREHOUSE                         = 23, --仓库
    REPAIR                            = 24, --防御建筑修理
    GETCURE                           = 25, --领伤兵
    POWER_DETAIL                      = 26, --电力详情
    EINSTEIN_NOT_REACH                = 27, --爱因斯坦时光机器 未达成激活的状态
    EINSTEIN_REACH                    = 28, --爱因斯坦时光机器 达成激活,但未点击激活状态
    GET_AIR_FORCE_COMMAND             = 29,  --领飞机兵
    GET_WAR_FACTORY                   = 30,  --领坦克兵
    GET_REMOTE_FIRE_FACTORY           = 31,  --领弹兵兵
    GET_BARRACKS                      = 32,  --领大兵
}

--HUD上的图片
Btn_Image_Table = 
{
   [BUILDING_BTN_TYPE.DETAIL]                       = "HUD_Information.png",                      --详情
   [BUILDING_BTN_TYPE.UPGRADE]                      = "HUD_Upgrade.png",                          --升级
   [BUILDING_BTN_TYPE.MAKE]                         = "HUD_Develop.png",                          --研制
   [BUILDING_BTN_TYPE.RESEARCH]                     = "HUD_Research.png",                         --研究
   [BUILDING_BTN_TYPE.TREAT]                        = "HUD_TreatmentWounded.png",                 --治疗
   [BUILDING_BTN_TYPE.SPEEDUP]                      = "HUD_SpeedUp.png",                          --加速
   [BUILDING_BTN_TYPE.GOLDSPEEDUP]                  = "HUD_UpgradeSpeedUp.png",                   --金币加速
   [BUILDING_BTN_TYPE.SOLDIER_WOUNDED]              = "HEAL.png",                                 --伤兵状态
   [BUILDING_BTN_TYPE.GETTROOP]                     = "HUD_TranInfantry.png",                     --领兵
   [BUILDING_BTN_TYPE.GETCURE]                      = "HUD_TranInfantry.png",                     --领伤兵
   [BUILDING_BTN_TYPE.FREETIME]                     = "HUD_Free.png",                             --免费
   [BUILDING_BTN_TYPE.TRAIN_BARRACKS]               = "HUD_TranInfantry.png",                     --训练步兵
   [BUILDING_BTN_TYPE.TRAIN_WAR_FACTORY]            = "HUD_TrainTank.png",                        --训练战车
   [BUILDING_BTN_TYPE.TRAIN_REMOTE_FIRE_FACTORY]    = "HUD_Remotely.png",                         --训练远程火力
   [BUILDING_BTN_TYPE.TRAIN_RAIR_FORCE_COMMAND]     = "HUD_TrainAirman.png",                      --训练空军
   [BUILDING_BTN_TYPE.CANCEL_BUILDING_UPGRADE]      = "HUD_CancelReconstruction_Yellow.png",      --取消建筑升级
   [BUILDING_BTN_TYPE.CANCEL_TRAIN]                 = "HUD_CancelTraining_Yellow.png",            --取消训练
   [BUILDING_BTN_TYPE.CANCEL_RESEARCH]              = "HUD_CancelResearch_Yellow.png",            --取消研究
   [BUILDING_BTN_TYPE.CANCEL_MAKE]                  = "HUD_CancelDevelop_Yellow.png",             --取消研制
   [BUILDING_BTN_TYPE.CANCEL_TREAT]                 = "HUD_CancelTreatment_Yellow.png",           --取消治疗
   [BUILDING_BTN_TYPE.RADAR]                        = "HUD_Radar.png",                            --雷达
   [BUILDING_BTN_TYPE.HELP]                         = "HUD_AllianceHelp.png",                     --帮助
   [BUILDING_BTN_TYPE.EMBASSY]                      = "HUD_Embassy.png",                          --大使馆
   [BUILDING_BTN_TYPE.PRISON]                       = "HUD_CheckPrison.png",                      --监狱
   [BUILDING_BTN_TYPE.WAREHOUSE]                    = "HUD_CheckRes.png",                      	  --仓库
   [BUILDING_BTN_TYPE.REPAIR]                       = "HUD_Repair.png",                           --防御建筑修理
   [BUILDING_BTN_TYPE.POWER_DETAIL]                 = "HUD_ElectricInformation.png",              --电力详情
   [BUILDING_BTN_TYPE.EINSTEIN_NOT_REACH]           = "HUD_TimeMachine.png",                      --爱因斯坦时光机器 未达成激活的状态
   [BUILDING_BTN_TYPE.EINSTEIN_REACH]               = "HUD_TimeMachineStart.png",                 --爱因斯坦时光机器 达成激活,但未点击激活状态
   [BUILDING_BTN_TYPE.GET_BARRACKS]                 = "HUD_TopInfantry.png",                     --领大兵
   [BUILDING_BTN_TYPE.GET_AIR_FORCE_COMMAND]        = "HUD_TopAirman.png",                      --领飞机兵
   [BUILDING_BTN_TYPE.GET_WAR_FACTORY]              = "HUD_TopTank.png",                        --领坦克兵
   [BUILDING_BTN_TYPE.GET_REMOTE_FIRE_FACTORY]      = "HUD_TopRemotely.png",                         --领弹兵兵
} 

--HUD上的文字
Btn_Txt_Map = {
   [BUILDING_BTN_TYPE.DETAIL]                       = "@Detail",                --详情
   [BUILDING_BTN_TYPE.UPGRADE]                      = "@Update",                --升级
   [BUILDING_BTN_TYPE.MAKE]                         = "@Make",                  --研制
   [BUILDING_BTN_TYPE.RESEARCH]                     = "@Research",              --研究
   [BUILDING_BTN_TYPE.TREAT]                        = "@Treat",                 --治疗
   [BUILDING_BTN_TYPE.SPEEDUP]                      = "@Speedup",               --加速
   [BUILDING_BTN_TYPE.GOLDSPEEDUP]                  = "@GoldSpeedup",           --金币加速
   [BUILDING_BTN_TYPE.SOLDIER_WOUNDED]              = "@Cancel",                --伤兵状态
   [BUILDING_BTN_TYPE.GETTROOP]                     = "@GetTroop",              --领兵
   [BUILDING_BTN_TYPE.FREETIME]                     = "@Freetime",              --免费
   [BUILDING_BTN_TYPE.TRAIN_BARRACKS]               = "@Train",                 --训练步兵
   [BUILDING_BTN_TYPE.TRAIN_WAR_FACTORY]            = "@Train",                 --训练战车
   [BUILDING_BTN_TYPE.TRAIN_REMOTE_FIRE_FACTORY]    = "@Train",                 --训练远程火力
   [BUILDING_BTN_TYPE.TRAIN_RAIR_FORCE_COMMAND]     = "@Train",                 --训练空军
   [BUILDING_BTN_TYPE.CANCEL_BUILDING_UPGRADE]      = "@Cancel",                --取消建筑升级
   [BUILDING_BTN_TYPE.CANCEL_TRAIN]                 = "@Cancel",                --取消训练
   [BUILDING_BTN_TYPE.CANCEL_RESEARCH]              = "@Cancel",                --取消研究
   [BUILDING_BTN_TYPE.CANCEL_MAKE]                  = "@Cancel",                --取消研制
   [BUILDING_BTN_TYPE.CANCEL_TREAT]                 = "@Cancel",                --取消治疗
   [BUILDING_BTN_TYPE.RADAR]                        = "@Radar",                 --雷达
   [BUILDING_BTN_TYPE.HELP]                         = "@Help",                  --帮助
   [BUILDING_BTN_TYPE.EMBASSY]                      = "@Assistance",            --援助
   [BUILDING_BTN_TYPE.PRISON]                       = "@Prison",                --监狱
   [BUILDING_BTN_TYPE.WAREHOUSE]                    = "@Warehouse",             --仓库
   [BUILDING_BTN_TYPE.REPAIR]                       = "@Repair",                --修理
   [BUILDING_BTN_TYPE.POWER_DETAIL]                 = "@PowerDetail",            --电力详情
}




--塔座
TOWER_STATE_TYPE = 
{
    IDLE_CLOSE = 'idle_close',     --关闭状态
    IDLE_GREEN = 'idle_green',     --电力充足
    IDLE_YELLOW = 'idle_yellow',   --电力负载中等
    IDLE_RED = 'idle_red',         --电力超载
    BROKEN  = 'Broken'             --毁坏
}

TOWER_ANIMATION_TYPE = {
    IDLE_CLOSE = 'Idle_close', --未开启
    IDLE_GREEN = 'Idle_green', --电力充足
    IDLE_NIGHT_GREEN = 'Idle_n_green',--夜晚电力充足
    IDLE_YELLOW = 'Idle_yellow',--电力负载中等
    IDLE_NIGHT_YELLOW = 'Idle_n_yellow',--夜晚电力负载中等
    IDLE_RED = 'Idle_red',  --电力超载
    IDLE_NIGHT_RED = 'Idle_n_red',--夜晚超载
    BROKEN = 'Broken',--损毁
    BROKEN_NIGHT = 'Broken_n' --损毁，晚上
}