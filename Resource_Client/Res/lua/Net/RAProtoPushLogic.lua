--region RAProtoPushLogic.lua
--Date  2016/5/28
--Author zhenhui
--此文件由[BabeLua]插件自动生成

local RAProtoPushLogic = {}
package.loaded[...] = RAProtoPushLogic

local HP_pb = RARequire("HP_pb")
local RANetUtil = RARequire("RANetUtil")
RAProtoPushLogic.mPushHandler = {}

function RAProtoPushLogic:registerPushProto()
    --login推送
    self.mPushHandler[HP_pb.LOGIN_S] = RANetUtil:addListener(HP_pb.LOGIN_S,RARequire("RALoginManager"))

    --playerPush
    local playerOpcode =
    {
        HP_pb.PLAYER_INFO_SYNC_S,
        
        --talent推送
        HP_pb.PLAYER_TALENT_SYNC_S,
        HP_pb.MISSION_REFRESH_S,
        HP_pb.MISSION_UPDATE_SYNC_S,

        --支付信息推送
        HP_pb.RECHARGE_INFO_SYNC,
        HP_pb.RECHARGE_SUCCESS_SYNC,

        --屏蔽用户的推送
        HP_pb.SHIELD_PLAYER_INFO_SYNC_S,
        HP_pb.SHIELD_PLAYER_S,
        HP_pb.REMOVE_SHIELD_S,

        --自定义数据推送，比如新手
        HP_pb.CUSTOM_DATA_SYNC,

        --mission推送
        HP_pb.MISSION_LIST_SYNC_S,

        --作用号推送
        HP_pb.PLAYER_EFFECT_INFO_SYNC_S
    }
    self.mPushHandler[HP_pb.PLAYER_INFO_SYNC_S] = RANetUtil:addListener(playerOpcode, RARequire("RAPlayerPushHandler"))
    
    local itemOpcode =
    {
        -- 物品
        HP_pb.ITEM_INFO_SYNC_S,
        --打折物品
        HP_pb.HOT_SALES_INFO_SYNC_S
    }
    self.mPushHandler[HP_pb.ITEM_INFO_SYNC_S] = RANetUtil:addListener(itemOpcode, RARequire("RAItemPushHandler"))


    local queueOpcode =
    {
        --建造
        HP_pb.PLAYER_BUILDING_SYNC_S,
        HP_pb.BUILDING_CREATE_PUSH,
        HP_pb.BUILDING_UPDATE_PUSH,
        HP_pb.BUILDING_STATUS_CHANGE_PUSH,
        HP_pb.BUILDING_REBUILD_PUSH,
        HP_pb.DEFENCE_BUILDING_REPAIR_PUSH,
        
        --战斗完推送防御建筑血量变化
        HP_pb.DEFENCE_BUILDING_CHANGE_PUSH,

        --队列推送
        HP_pb.QUEUE_ADD_PUSH,
        HP_pb.QUEUE_DELETE_PUSH,
        HP_pb.QUEUE_CANCEL_PUSH,
        HP_pb.QUEUE_UPDATE_PUSH,
        HP_pb.PLAYER_QUEUE_SYNC_S
    }
    self.mPushHandler[HP_pb.PLAYER_BUILDING_SYNC_S] = RANetUtil:addListener(queueOpcode, RARequire("RAQueuePushHandler"))

    -- 奖励
    self.mPushHandler[HP_pb.PLAYER_AWARD_S] = RANetUtil:addListener(HP_pb.PLAYER_AWARD_S,RARequire("RARewardPushHandler"))
    -- 消耗
    self.mPushHandler[HP_pb.PLAYER_CONSUME_S] = RANetUtil:addListener(HP_pb.PLAYER_CONSUME_S, RARequire("RAConsumePushHandler"))

    local sysOpcode =
    {
        -- 心跳通知、错误码提示
        HP_pb.HEART_BEAT,
        HP_pb.ERROR_CODE,

        HP_pb.OPERATE_SUCCESS,
        HP_pb.ASSEMBLE_FINISH_S,

        
        HP_pb.PLAYER_KICKOUT_S
    }
    self.mPushHandler[HP_pb.HEART_BEAT] = RANetUtil:addListener(sysOpcode, RARequire("RASysPushHandler"))

    -- 聊天
    local chatOpcode =
    {
        HP_pb.PUSH_CHAT_S,
        HP_pb.ALLIANCE_MSG_CACHE_S
    }
    self.mPushHandler[HP_pb.PUSH_CHAT_S] = RANetUtil:addListener(chatOpcode, RARequire('RAChatPushHandler'))
    
    --科技
    self.mPushHandler[HP_pb.PLAYER_TECHNOLOGY_S] = RANetUtil:addListener(HP_pb.PLAYER_TECHNOLOGY_S,RARequire("RASciencePushHandler"))

    --士兵相关
    self.mPushHandler[HP_pb.PLAYER_ARMY_S] = RANetUtil:addListener(HP_pb.PLAYER_ARMY_S,RARequire("RAArmyPushHandler"))

    -- 世界
    local worldOpcode = 
    {
        HP_pb.WORLD_PLAYER_WORLD_INFO_PUSH,
        HP_pb.WORLD_FAVORITE_SYNC_S,
        HP_pb.WORLD_MOVE_CITY_S,

        --march push self
        HP_pb.WORLD_MARCH_ADD_PUSH,         
        HP_pb.WORLD_MARCH_UPDATE_PUSH,      
        HP_pb.WORLD_MARCH_DELETE_PUSH,   
        HP_pb.WORLD_MARCHS_PUSH,

        --march push others
        HP_pb.WORLD_MARCH_BLOCK_ADD,
        HP_pb.WORLD_MARCH_BLOCK_UPDATE,
        HP_pb.WORLD_MARCH_BLOCK_DELETE,        

        --new march push
        HP_pb.WORLD_MARCH_EVENT_SYNC,

        --world map three push
        HP_pb.OPEN_KING_DISTRIBUTE_MAP_S,

        --被攻击
        HP_pb.WORLD_PLAYER_WORLD_BEATING_PUSH,

        -- 行军召回
        HP_pb.WORLD_SERVER_CALLBACK_S,
        -- 行军加速
        HP_pb.WORLD_MARCH_SPEEDUP_S,
        -- 队长遣返某人
        HP_pb.WORLD_MASS_REPATRIATE_S,

        -- 国王战
        HP_pb.PRESIDENT_INFO_SYNC,
        HP_pb.PUSH_ALL_QUARTERED_MARCHS,
        HP_pb.PUSH_DEL_QUARTERED_MARCHS,
        HP_pb.PUSH_UPDATE_QUARTERED_MARCHS,
        HP_pb.PUSH_UPDATE_QUARTERED_MARCHS_BUY_ITEM,
        HP_pb.PRESIDENT_HISTORY_SYNC,
        HP_pb.PRESIDENT_EVENT_SYNC,        
        HP_pb.PUSH_MANOR_INFO_CHANGED,
    }
    self.mPushHandler[HP_pb.WORLD_PLAYER_WORLD_INFO_PUSH] = RANetUtil:addListener(worldOpcode, RARequire('RAWorldPushHandler'))

    local allianceOpcode =
    {
        HP_pb.GUILD_BASIC_INFO_SYNC_S,
        HP_pb.GUILDMANAGER_REFRESH_HELPQUEUE_NUM_S, --帮助数目
        HP_pb.GUILD_APPLYNUM_SYNC_S,
        HP_pb.NUCLEAR_INFO_SYNC,
        HP_pb.GUILD_MANOR_NUCLEAR_DEL_SYNC,
        HP_pb.GUILD_ACCEPTAPPLY_SYNC_S,
        HP_pb.GUILD_STATUE_INFO_SYNC_S,
        HP_pb.PLAYER_LEAVE_GUILD,
        HP_pb.GUILD_SCORE_SYNC_S,

        --联盟战争推送
        HP_pb.GUILD_WAR_PUSH_ALL,
        HP_pb.GUILD_WAR_PUSH_ADD,
        HP_pb.GUILD_WAR_PUSH_UPDATE_TARGET,
        HP_pb.GUILD_WAR_PUSH_UPDATE_ITEM,
        HP_pb.GUILD_WAR_PUSH_DEL,
        HP_pb.GUILD_WAR_PUSH_DEL_ITEM,
        HP_pb.GUILD_WAR_PUSH_BUY_ITEM_TIMES,
        
        
        --被踢出联盟
        HP_pb.GUILD_BEKICK_SYNC_S,

        --联盟帮助监听
        HP_pb.GUILDMANAGER_BEHELPED_S,
    }
    --联盟
    self.mPushHandler[HP_pb.GUILD_BASIC_INFO_SYNC_S] = RANetUtil:addListener(allianceOpcode, RARequire('RAAlliancePushHandler'))

    --邮件：登录推送,聊天室推送,新邮件推送,玩家离开聊天室,修改聊天室名字,玩家加入聊天室，给加入聊天室的成员推送修改名字系协议
    local mailOpcode =
    {
        HP_pb.MAIL_LIST_SYNC_S,
        HP_pb.MAIL_PUSH_CHATROOM_MSG_S,
        HP_pb.MAIL_NEW_MAIL_S,
        HP_pb.MAIL_PUHS_DEL_S,
        HP_pb.MAIL_BE_DEL_S,
        -- HP_pb.MAIL_MEMBER_LEAVE_S,
        -- HP_pb.MAIL_REFRESH_CHATROOM_NAME_S,
        -- HP_pb.MAIL_CHAT_ADD_PLAYERS_S,
        HP_pb.MAIL_UPDATE_CHATROOM_S
    }
    self.mPushHandler[HP_pb.MAIL_LIST_SYNC_S] = RANetUtil:addListener(mailOpcode, RARequire('RAMailPushHandler'))

    --状态同步协议
    self.mPushHandler[HP_pb.STATE_INFO_SYNC_S] = RANetUtil:addListener(HP_pb.STATE_INFO_SYNC_S, RARequire("RAStatePushHandler"))
    
    local marchOpcode =
    {
        --行军报告推送
        HP_pb.WORLD_MARCH_REPORT_PUSH,
        --行军结束
        HP_pb.WORLD_MARCH_END_PUSH,
        --行军刷新
        HP_pb.WORLD_MARCH_REFRESH_PUSH
    }
    self.mPushHandler[HP_pb.WORLD_MARCH_REPORT_PUSH] = RANetUtil:addListener(marchOpcode, RARequire("RAWorldMarchReportPushHandle"))

    --装备推送
    self.mPushHandler[HP_pb.PLAYER_EQUIPMENT_SYNC_S] = RANetUtil:addListener(HP_pb.PLAYER_EQUIPMENT_SYNC_S, RARequire("RAEquipPushHandler"))

    --指挥官信息同步
    self.mPushHandler[HP_pb.PLAYER_COMMANDER_INFO_SYNC_S] = RANetUtil:addListener(HP_pb.PLAYER_COMMANDER_INFO_SYNC_S, RARequire("RACommonderPushHandle"))

    --联盟领地
    local territoryOpcodes =
    {
        HP_pb.GUILD_MANOR_SYNC,
        HP_pb.NUCLEAR_BOMB_SYNC,
        HP_pb.DISARM_NUCLEAR_BOMB_SYNC,
    }
    self.mPushHandler[HP_pb.GUILD_MANOR_SYNC] = RANetUtil:addListener(territoryOpcodes, RARequire('RATerritoryPushHandler'))

    
    local activityOpcodes = 
    {
        HP_pb.ONLINE_REWARD_PUSH,                   --在线奖励推送（宝箱）
        HP_pb.ROUND_TASK_ACTIVITY_START_PUSH,        --周期性日常活动推送以及活动阶段变更
        HP_pb.TRAVEL_SHOP_INFO_SYNC,        --旅行商人信息同步
        --每日登陆礼包活动
        HP_pb.DAILYLOGIN_INFO_SYNC_S
    }
    self.mPushHandler[HP_pb.ONLINE_REWARD_PUSH] = RANetUtil:addListener(activityOpcodes, RARequire('RAActivityPushHandle'))

    local pveOpcodes =
    {
    	HP_pb.PUSH_PVE_ONE_PART_INFO
	}
	self.mPushHandler[HP_pb.PUSH_PVE_ONE_PART_INFO] = RANetUtil:addListener(pveOpcodes, RARequire('RADungeonHandler'))
end

function RAProtoPushLogic:removePushProto()
    for k, v in pairs(self.mPushHandler) do
        if v then
            RANetUtil:removeListener(v)
            self.mPushHandler[k] = nil
        end
    end
    -- self.mPushHandler = {}
end

--endregion
