-- MessageDefine

-- message define
-- warning!!!!
-- keep message code is unique!!!

-- message for ui root manager
-- 100100 ~ 100199
MessageDef_RootManager = {
    MSG_OpenPage = 100100,
    MSG_ClosePage = 100101,

    -- call function named "CommonRefresh" in BaseFunctionPage
    -- arg example: {pageName="RACDKeyPage"}
    MSG_CommonRefreshPage = 100102,

    MSG_CutScene = 100103,
    MSG_TopPageMayChange = 100104,
    MSG_GotoLastPage = 100105,
    MSG_ReturntoLastPage = 100106,
    MSG_ActionEnd = 100107,
    -- 震屏消息(场景scene node动作)
    MSG_SceneShake = 100108,
}

-- message for main ui part
-- 100200 ~ 199999
MessageDef_MainUI = {
    -- change visibility of RAChooseBuildPage page
    MSG_HandleChooseBuildPage = 100200,
    -- update world position
	MSG_UpdateWorldCoordinate = 100201,
    -- update main ui
    MSG_UpdateBasicPlayerInfo = 100202,
    -- change is building 
    MSG_ChangeBuildStatus = 100203,
    -- change is menu tips num
    MSG_ChangeMenuTipsNum = 100204,
    
    MSG_ChangeChatNewestMsg = 100205,
    -- change world direction
    MSG_UpdateWorldDirection = 100206,

    -- close queue page and maybe need to move camare to one building
    MSG_CloseQueuePage = 100207,

    -- 当需要更新queue页面的时候发送，
    -- 比如建造军营、获得伤兵等等
    MSG_UpdateQueuePage = 100208,

    MSG_UpdateMainUIQueuePart = 100209,

    -- 需要刷新核弹显示区域时候的消息
    MSG_UpdateMainUINuclearPart = 100210, 

    -- 新的队列UI，删除某个cell，防止崩溃
    MSG_UpdateMainUIQueueDelCell = 100211,     
    -- 新的队列UI，添加一个建筑
    MSG_UpdateMainUIQueueAddBuild = 100212,     

    --切换聊天tab
    MSG_Chat_change_tab = 100300,
    --推送升级消息
    MSG_LEVEL_UP = 100301,
    --推送建造按钮解锁消息
    MSG_HAS_UNLOCK_BUILD = 100302,

    MSG_HAS_NO_UNLOCK_BUILD = 100303,

    MSG_Update_Warning = 100304,

    MSG_ShowTaskGuild = 100305,

    MSG_HideTaskGuild = 100306,

    MSG_ShowHelperTips = 100307,

    MSG_HideHelperTips = 100308,    
}


--message for build
-- 200000 ~ 201000
MessageDef_Building = {
    MSG_Choose = 200000,
    MSG_CreateBuildingSuccess = 200001,
    MSG_MovingBuildingSuccess = 200002,
    MSG_UpgradeBuildingSuccess = 200003,
    MSG_SCIENCE_TABCELL_CLICK= 200004,
    MSG_Cancel_Building_Select = 200005,
    MSG_SCIENCE_UPDATE= 200006,
    MSG_BuildingStatusChange = 200007,
    MSG_MainFactory_Levelup = 200008,    --主基地刷新
    MSG_BuildingMoveToFinshied = 200009,
    MSG_Guide_Hud_BtnInfo = 200010,
    MSG_Moving_Finished = 200011,--摄像机移动结束
    MSG_ReBuildingSuccess = 200012, --建筑重建
    MSG_RepairBuildingSuccess = 200013  --防御建筑维修
}

-- message for build
-- 201001 ~ 202000
MessageDef_Queue = {
    MSG_Building_ADD    = 201001,
    MSG_Building_UPDATE = 201002,
    MSG_Building_DELETE = 201003,
    MSG_Building_CANCEL = 201004,

    MSG_Science_ADD     = 201011,
    MSG_Science_UPDATE  = 201012,
    MSG_Science_DELETE  = 201013,
    MSG_Science_CANCEL  = 201014,

    MSG_Soilder_ADD     = 201031,
    MSG_Soilder_UPDATE  = 201032,
    MSG_Soilder_DELETE  = 201033,
    MSG_Soilder_CANCEL  = 201034,

    MSG_hospital_ADD     = 201041,
    MSG_hospital_UPDATE  = 201042,
    MSG_hospital_DELETE  = 201043,
    MSG_hospital_CANCEL  = 201044,

    MSG_Common_ADD    = 201051,
    MSG_Common_UPDATE = 201052,
    MSG_Common_DELETE = 201053,
    MSG_Common_CANCEL = 201054,

    MSG_Defener_ADD    = 201061,
    MSG_Defener_UPDATE = 201062,
    MSG_Defener_DELETE = 201063,
    MSG_Defener_CANCEL = 201064,

    MSG_SuperWeapon_ADD    = 201071,
    MSG_SuperWeapon_UPDATE = 201072,
    MSG_SuperWeapon_DELETE = 201073,
    MSG_SuperWeapon_CANCEL = 201074,

    MSG_Defener_REBUILD_ADD = 201081,
    MSG_Defener_REBUILD_UPDATE = 201082,
    MSG_Defener_REBUILD_DELETE = 201083,
    MSG_Defener_REBUILD_CANCEL = 201084,

    MSG_Defener_REPAIRE_ADD = 201091,
    MSG_Defener_REPAIRE_UPDATE = 201092,
    MSG_Defener_REPAIRE_DELETE = 201093,
    MSG_Defener_REPAIRE_CANCEL = 201094,

    MSG_Building_REBUILD_ADD    = 201101,
    MSG_Building_REBUILD_UPDATE = 201102,
    MSG_Building_REBUILD_DELETE = 201103,
    MSG_Building_REBUILD_CANCEL = 201104,
}

--message for chat
--202001 ~ 203000
MessageDef_Chat = {
    MSG_Chat_Generate_World_Data     = 202001,
    MSG_Chat_Generate_Alliance_Data  = 202002,
    MSG_Chat_CopyBtn_CellTag_Data    = 202003,
    MSG_Chat_remove_World_top_Data  = 202004,
    MSG_Chat_remove_Alliance_top_Data  = 202005
}


--message for choose build ui
--203001 ~ 204000
MessageDef_ChooseBuild = {
    MSG_ChooseBuild_ShowDetail     = 203001,
    MSG_ChooseBuild_refreshSelect  = 203002
}

--message for package
--204001 ~ 205000
MessageDef_package = {
    MSG_package_push_item     = 204001,
    --用来刷新显示道具的面板，如果此面板在监听的话
    MSG_package_consume_item  = 204002,
    --刷新背包当前选中tab的数据
    MSG_package_refresh_data  = 204003,
    MSG_package_discount_selling_data = 204004,
    --加速道具消耗，传向加速道具消耗面板
    MSG_package_consume_accelerate_item = 204005,
    --记录当前背包scrollview滑动到的位置
    MSG_package_remember_sv_offset = 204006
}

--message for train soilder
--205001 ~ 206000
MessageDef_TrainSoilder = {
    MSG_TrainSoilder_QueueFinish  = 205001
}

MessageDef_Packet =
{
    MSG_Operation_OK = 206001,
    MSG_Operation_Fail = 206002
}

--医院
--207001 ~ 208000
MessageDefine_Hospital = {
    MSG_refresh_consume = 207001,
    --面板开着的话，服务器发送新的伤兵数据更新
    MSG_receive_wounded_data = 207002,
    MSG_receive_cure_count = 207003
}


--邮件
--208001 ~ 209000
MessageDefine_Mail = {
    MSG_Refresh_MailList = 208001,
    MSG_Selected_Mail = 208002,
    MSG_Delete_Mail = 208003,
    MSG_Click_OptMail = 208004,
    MSG_Refresh_MailOptList = 208005,
    MSG_Read_Mail = 208006,
    MSG_Read_ReportMail =208007,
    MSG_Update_ChatMail =208008,
    MSG_Update_ChatRoomMem =208009,
    MSG_Update_ChatRoomName =208010,
    MSG_BeExit_ChatRoom =208011,


}

-- CCScrollView Cell 点击变化消息
MessageDef_ScrollViewCell = 
{
    MSG_FavoriteListCell    = 209001,
    MSG_MailScoutListCell   = 209002,
    
    MSG_BastionListCell     = 209003,
    MSG_GarrisonListCell    = 209004,
    MSG_GarrisonJoinedCell  = 209005,
    
    MSG_AppointTitleCell    = 209006,
    MSG_AppointPlayerCell   = 209007,
    MSG_AppointOfficialCell = 209008,

    MSG_GrantGiftTitleCell  = 209009,
    MSG_GrantGiftPlayerCell = 209010,
    MSG_GrantGiftSelectCell = 209011,

    MSG_PresidentFlagCell   = 209012
}

-- World 相关消息
MessageDef_World =
{
    MSG_UpdateFavorite          = 210001,

    -- 添加行军，需要从池里取数据了
    MSG_MarchAdd                = 210002,        
    -- 移除行军
    MSG_MarchDelete             = 210003,  

    -- 闲置军队发生改变的时候，需要刷新出征UI
    MSG_ArmyFreeCountUpdate     = 210004,
    -- 出征UI的cell选择数目改变的时候，需要刷新UI
    MSG_ArmyChangeSelectedCount = 210005,

    -- 战斗播放时发送，用于记录某个行军战斗开始
    MSG_MarchBeginBattle        = 210006,
    -- 战斗结束时发送，用于记录某个行军战斗结束
    MSG_MarchEndBattle          = 210007,

    -- 地图分块变化
    MSG_UpdateMapArea           = 210008,
    -- 地图位置变化
    MSG_UpdateMapPosition       = 210009,

    -- 城点被重建
    MSG_CityRecreated           = 210010,
    -- 添加行军Hud
    MSG_AddMarchHud             = 210011,
    -- 移除行军Hud
    MSG_RemoveMarchHud          = 210012,

    -- 联盟领地数据更新
    MSG_Territory_Update        = 210013,
    -- 核弹爆炸
    MSG_NuclearBomb_Explode     = 210014,

    -- 添加城点
    MSG_AddWorldPoint           = 210015,
    -- 删除城点
    MSG_DelWorldPoint           = 210016,
    -- 城点数据刷新(添加、更新)
    MSG_RefreshWorldPoints      = 210017,

    -- 打开使用加速或者召回道具页面
    MSG_OpenMarchUseItemPage    = 210018,
    -- 关闭使用加速或者召回道具页面
    MSG_CloseMarchUseItemPage   = 210019,
    -- 关闭使用加速或者召回道具页面
    MSG_CloseMarchUseItemPageForCallBack   = 210020,

    -- 超级武器目标选择中
    MSG_SuperWeapon_Aiming      = 210021,
    -- 超级武器目标选择结束
    MSG_SuperWeapon_AimEnd      = 210022,

    -- 元帅战相关信息变更
    MSG_PresidentInfo_Update    = 210023,
    -- 总统府官职信息
    MSG_OfficialInfo_Update     = 210024,
    -- 元帅战礼包信息
    MSG_PresidentGift_Update    = 210025,
    -- 国王战事件刷新
    MSG_PresidentEvents_Update  = 210026,
    -- 国王战历代国王信息变更
    MSG_PresidentHistory_Update = 210027,

    --国王战刷新驻军信息页面        
    MSG_PresidentQuarterPage_Refresh = 210028,
    -- 驻军信息页面里，切换某个cell的部队详情状态
    MSG_PresidentQuarterPage_CellInfo_Change = 210029,

    --临时国王切换
    MSG_TmpPresident_Change = 210030,

    -- 驻军信息点击空队列时候
    MSG_PresidentQuarterPage_CellAdd_Change = 210031,

    -- 跨服总统战信息变更
    MSG_CrossServerPresidentInfo_Update = 210032,
    
    -- 吞噬触摸事件
    MSG_SwallowTouch            = 210033,

    -- 跳转
    MSG_LocateAtPos             = 210034,

}


-- City 相关消息
MessageDef_CITY = {
    MSG_NOTICE_GATHER = 211001,  --通知主城收集士兵已经到位，刷新集结场
    MSG_NOTICE_ATTACK_HP_CHANGE = 211002,  --
}

--解雇 消息
MessageDef_FireSoldier = {
    MSG_RATroopsInfoUpdate = 212001,
    MSG_RAArmyDetailsPopUpUpdate = 212002
}

-- message for ui RAScenesMananger
-- 213001 ~ 213999
MessageDef_ScenesMananger = {
    MSG_AddLocateMarchData = 213001,

    MSG_AddCmdData = 213002,
}

--雷达
MessageDef_Radar={
    MSG_UPDATE=214001,
    MSG_DELETE=214002,
    MSG_ADD=214003,
}

--联盟帮助相关
MessageDef_AllianceHelp={
    MSG_DELETE=215001
}

--联盟战争相关
MessageDef_AllianceWar={
    --战争页面消息
    MSG_AllianceWar_ADD    = 216001,
    MSG_AllianceWar_UPDATE = 216002,
    MSG_AllianceWar_DELETE = 216003,

    --集结,防守,攻击队员消息
    MSG_AllianceWar_Member_ADD     = 216011,
    MSG_AllianceWar_Member_UPDATE  = 216012,
    MSG_AllianceWar_Member_DELETE  = 216013,
    MSG_AllianceWar_MemberPage_Close  = 216014,

    --红点消息
    MSG_WAR_REDPOINT   = 216025,

    -- 刷新war页面，附带showType
    MSG_NewAllianceWar_WarPage_Refresh = 216026,
    -- 刷新detail页面，附带cellMarchId
    MSG_NewAllianceWar_DetailsPage_Refresh = 216027,
    -- detail页面里，切换某个cell的部队详情状态
    MSG_NewAllianceWar_DetailsPage_CellInfo_Change = 216028,
    -- 关闭detail页面，附带cellMarchId
    MSG_NewAllianceWar_DetailsPage_Close = 216029,
}

MessageDef_Alliance =
{
    MSG_Alliance_Changed = 217001,
    MSG_Alliance_KickOut = 217002,
    MSG_Alliance_HelpNum_Change = 217003,
    MSG_Alliance_ApplyNum_Change = 217004,
    MSG_Alliance_SettingLangue = 217005,

    --联盟雕像消息
    MSG_Alliance_Statue_Queue_ADD = 217006,
    MSG_Alliance_Statue_Queue_UPDATE = 217007,
    MSG_Alliance_Statue_Queue_DELETE = 217008,

    MSG_NuclearInfo_Update = 217009,

    --雕像升级成功
    MSG_Alliance_Statue_UP_Success = 217010,

    MSG_Alliance_ManorResType_Change = 217011,

    MSG_Alliance_Flag_Change = 217012,

    MSG_Alliance_RedPackage_Change = 217013,

    --雕像数据更新
    MSG_Alliance_Statue_Update = 217014,

    --盟主统一加入联盟后的消息
    MSG_Alliance_Jion_Success = 217015,

    MSG_AllianceScore_Update = 217016,
}

--指挥官状态变化
MessageDef_Commonder =
{
    MSG_State_Changed = 218001,
}

MessageDef_Equip =
{
    MSG_Equip_Changed = 219001,
    MSG_Equip_Item_Changed = 219002,
}

--宝箱的推送消息
MessageDef_TreasureBox =
{
    MSG_TreasureBox_Create = 220001,
    MSG_TreasureBox_Delete = 220002,
}

--基地增益状态刷新消息
MessageDef_CityGainStatus = {
    MSG_CityGain_Changed = 230001
}

--日常活动状态刷新消息
MessageDef_DailyTaskStatus = {
    MSG_DailyTask_Changed = 240001
}

--红点消息，红点的
MessageDef_RedPoint = {
    
    --主页头像红点消息
    MSG_Refresh_Head_RedPoint = 250001,

    --天赋红点消息
    MSG_Refresh_Talent_RedPoint = 250002
}

--htmlLabel 事件
MessageDef_Html = {
    --点击事件
    Html_Click = 260001,
}


--视频播放 事件

-- enum EventType
-- {
--     PLAYING = 0,
--     PAUSED,
--     STOPPED,
--     COMPLETED
-- };
MessageDef_Video = {
    Playing = 270001,
    Paused = 270002,
    Stopped = 270003,
    Completed = 270004,
}

MessageDef_Reward = {
    Disappear = 280001,

}

MessageDef_BINDACCOUNT = {
    MSG_Bind_Data_Refresh = 290001,
}

--message for lord
-- 300000 - 301000
MessageDef_Lord = 
{
    MSG_RefreshName = 300000,
    MSG_RefreshPortrait = 300001,
    MSG_RefreshHeadImg = 300002,
    MSG_TalentUpgrade = 300003,
    MSG_LevelUpgrade = 300004,
}

--message for task
-- 310000 - 311000
MessageDef_Task = 
{
    MSG_RefreshMainUITask = 310000,
    MSG_RefreshTaskUITask = 310001,
    MSG_ShowTaskReward = 310002,
    MSG_GotoTarget = 310003,
    MSG_RefreshTaskList = 310004,
}

--message for guide
--320000 - 321000
MessageDef_Guide = 
{
    MSG_Guide = 320000,
    MSG_TaskGuide = 320001,
    MSG_GuideEnd = 320002,
    MSG_TaskGuideWorld = 320003
}

--message for missionBarrier
--322000 - 323000
MessageDef_MissionBarrier = 
{
    MSG_ActionEnd = 322000,         --动作完成
    MSG_CameraMoveEnd = 322001,     --摄像机移动结束
}

--message for pay
--330000 - 331000
MessageDef_Pay =
{
    MSG_PayInfoRefresh = 330000,
    MSG_PaySuccess = 330001--支付成功
}

--message for auto pop page
--340000 - 341000
Message_AutoPopPage = 
{
    MSG_AlreadyPopPage = 340000
}

--message for alliance page
--350000 - 351000
MessageDef_AlliancePage = 
{
    MSG_RefreshMainPage = 350000,
    MSG_RefreshMemberPage = 350001
}

--360000 - 361000
MessageDef_BaseInfo = 
{
    MSG_ElectricStatus_Change = 360000
}

-- PVE　关卡相关
MessageDefine_PVE =
{
	MSG_Sync_AllChapterInfo 	= 400001,
	MSG_Sync_ChapterPartsInfo 	= 400002
}

--战斗模块逻辑消息体定义
MessageDef_BattleScene = {
    --战斗单元死亡相关协议
    MSG_FIGHT_UNIT_DIE_NOTI = 500000,
    MSG_CameraMoving_Start = 500001,
    MSG_CameraMoving_Finished = 500002,
    MSG_FightPlay_State_Change = 500003,
    MSG_FIGHT_UNIT_ATTACK_UNIT_DEATH = 500004,
    MSG_FIGHT_UNIT_ATTACK_UNIT_BEHIT = 500005,
    MSG_FIGHT_UNIT_CREATE_UNIT = 500006,
    MSG_FIGHT_UNIT_ATTACK_UNIT_TARGET = 500007,
    MSG_Update_Fight_BloodBar = 500008,
    MSG_Change_Speed_Scale = 500009,

    -- 技能释放后发送的消息（用于控制船体表现）
    MSG_PlayerSkillCast = 500010,


    --战斗弹道和特效创建删除消息相关
    MSG_FIGHT_UNIT_CREATE_EFFECT = 510001,
    MSG_FIGHT_UNIT_DELETE_EFFECT = 510002,
    MSG_FIGHT_UNIT_CREATE_PROJECTILE = 510003,
    MSG_FIGHT_UNIT_DELETE_PROJECTILE = 510004,
    --技能实体的创建删除消息相关
    MSG_FIGHT_UNIT_CREATE_SKILL = 510005,
    MSG_FIGHT_UNIT_DELETE_SKILL = 510006,

    -- 技能释放相关
    MSG_CastSkill_Start 		= 511001,
    MSG_CastSkill_Quit			= 511002,
    MSG_CastSkill_TakeEffect 	= 511003,
    MSG_CastSkill_Depart		= 511004,
    MSG_CastSkill_Deploy		= 511005,
    MSG_CastSkill_CancelDeploy	= 511006,
    MSG_CastSkill_EnterGround 	= 511007,
    MSG_SkillPoint_Change 		= 511008
}

-- message for example
-- 900900 ~ 900999
--MessageDef_Example = {
--    MSG_Example = 900900,
--    MSG_LoginSuccess = 900901

--}
MessageDef_LOGIN = {
    -- open RAChooseBuildPage page
    MSG_LoginSuccess = 900901,
}

MessageDef_MainState = {
    SwitchUser = 1000101,

    EnterForeground = 1000102,

    ReloginRefresh = 1000103,
    --断网重连会发reconnect refresh
    ReConnectRefresh = 1000104,    
}