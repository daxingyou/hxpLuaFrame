--联盟推送协议

local RAAlliancePushHandler = {}

function RAAlliancePushHandler:onReceivePacket(handler)

    local HP_pb = RARequire('HP_pb')
    local GuildManager_pb = RARequire('GuildManager_pb')
    local GuildWar_pb = RARequire("GuildWar_pb")
    local RAAllianceManager = RARequire('RAAllianceManager')
    local RANewAllianceWarManager = RARequire('RANewAllianceWarManager')
    
    local pbCode = handler:getOpcode()
    local buffer = handler:getBuffer()

    if pbCode == HP_pb.GUILD_BASIC_INFO_SYNC_S then --联盟信息推送
		local msg = GuildManager_pb.HPGuildInfoSync()
		msg:ParseFromString(buffer)

        RAAllianceManager.joinedGuild = msg.joinedGuild
        -- if msg.joinedGuild == true then 

        local guildChanged = false
        if msg:HasField('guildId') then 
            if RAAllianceManager.selfAlliance == nil then 
                local RAAllianceInfo = RARequire('RAAllianceInfo')
                RAAllianceManager.selfAlliance = RAAllianceInfo.new()
            end 
            guildChanged = RAAllianceManager.selfAlliance.id ~= msg.guildId

            RAAllianceManager.selfAlliance.id = msg.guildId

            if RAAllianceManager.selfAlliance.flag ~= msg.guildFlag then 
                RAAllianceManager.selfAlliance.flag = msg.guildFlag
                MessageManager.sendMessage(MessageDef_Alliance.MSG_Alliance_Flag_Change)
            end 
    
            RAAllianceManager.selfAlliance.tag = msg.guildTag
            RAAllianceManager.selfAlliance.name = msg.guildName
            RAAllianceManager.authority = msg.guildAuthority
            RAAllianceManager.selfAlliance.level = msg.guildLevel

            if msg:HasField('helpNum') then 
                RAAllianceManager.helpNum = msg.helpNum
            else
                RAAllianceManager.helpNum = 0
            end

            if msg:HasField('applyNum') then 
                RAAllianceManager.applyNum = msg.applyNum
            else
                RAAllianceManager.applyNum = 0
            end 

            if msg:HasField('manorId') then 
                RAAllianceManager.selfAlliance.manorId = msg.manorId
            else
                RAAllianceManager.selfAlliance.manorId = nil 
            end 

            if msg:HasField('nuclearReady') then 
                RAAllianceManager.selfAlliance.nuclearReady = msg.nuclearReady
            else
                RAAllianceManager.selfAlliance.nuclearReady = nil 
            end

            if msg:HasField('manorResType') then 
                if RAAllianceManager.selfAlliance.manorResType ~= msg.manorResType then 
                    RAAllianceManager.selfAlliance.manorResType = msg.manorResType
                    MessageManager.sendMessage(MessageDef_Alliance.MSG_Alliance_ManorResType_Change)
                end 
            else
                RAAllianceManager.selfAlliance.manorResType = nil 
            end

            --是否可以取代盟主
            if msg:HasField('canImpeachLeader') then 
                RAAllianceManager.selfAlliance.canImpeachLeader = msg.canImpeachLeader
            end

            --刷新主页面帮助红点
            local RAGameConfig = RARequire("RAGameConfig")
            local data = {}
            data.menuType= RAGameConfig.MainUIMenuType.AllianceHelp
            data.num = RAAllianceManager.helpNum
            data.isDirChange = true
            MessageManager.sendMessage(MessageDef_MainUI.MSG_ChangeMenuTipsNum,data)

            local allianceData = {}
            allianceData.menuType= RAGameConfig.MainUIMenuType.Alliance
            allianceData.num = RAAllianceManager.helpNum + RAAllianceManager.applyNum
            allianceData.isDirChange = true
            MessageManager.sendMessage(MessageDef_MainUI.MSG_ChangeMenuTipsNum,allianceData)
        else
            guildChanged = RAAllianceManager.selfAlliance ~= nil
            RAAllianceManager.selfAlliance = nil
        end

        if guildChanged then
            MessageManager.sendMessage(MessageDef_Alliance.MSG_Alliance_Changed)
            MessageManager.sendMessage(MessageDef_Alliance.MSG_Alliance_Flag_Change)
        end
    elseif pbCode == HP_pb.GUILD_BEKICK_SYNC_S then         --被踢出推送
        --1.先清空联盟聊天的信息
        RAAllianceManager:ClearChatContent()
        --2.如果打开联盟页面的话，发送消息提示弹框
        MessageManager.sendMessage(MessageDef_Alliance.MSG_Alliance_KickOut)

        
    elseif pbCode == HP_pb.PLAYER_LEAVE_GUILD then
        -- 玩家离开一个联盟(包括被提出和自己退出)
        --清除联盟战争数据
        RARequire("RANewAllianceWarManager"):reset(true)

        --刷新主页面联盟红点

        local RAGameConfig = RARequire("RAGameConfig")
        local allianceData = {}
        allianceData.menuType= RAGameConfig.MainUIMenuType.Alliance
        allianceData.num = 0
        allianceData.isDirChange = true
        MessageManager.sendMessage(MessageDef_MainUI.MSG_ChangeMenuTipsNum,allianceData)

    elseif pbCode == HP_pb.GUILD_ACCEPTAPPLY_SYNC_S then
        local RARootManager = RARequire('RARootManager')
        RARootManager.ShowMsgBox(_RALang("@YourApplyIsAccepted"))

        MessageManager.sendMessage(MessageDef_Alliance.MSG_Alliance_Jion_Success)
    elseif pbCode == HP_pb.GUILD_WAR_PUSH_ALL then
        --同步所有的联盟战争信息
        local msg = GuildWar_pb.PushGuildWarInfo()
        msg:ParseFromString(buffer)
        for _,v in ipairs(msg.cellList) do
          RANewAllianceWarManager:AddOneCellData(v, false)
        end
    elseif pbCode == HP_pb.GUILD_WAR_PUSH_ADD then
        --新增联盟战争信息
        local msg = GuildWar_pb.PushGuildWarAdd()
        msg:ParseFromString(buffer)        
        RANewAllianceWarManager:AddOneCellData(msg.cell, true)

    elseif pbCode == HP_pb.GUILD_WAR_PUSH_UPDATE_TARGET then
        --更新联盟战争目标信息        
        local msg = GuildWar_pb.PushGuildWarUpdateTarget()
        msg:ParseFromString(buffer)        
        RANewAllianceWarManager:UpdateTargetData(msg)

    elseif pbCode == HP_pb.GUILD_WAR_PUSH_UPDATE_ITEM then
        --更新联盟战争信息        
        local msg = GuildWar_pb.PushGuildWarUpdateCellItem()
        msg:ParseFromString(buffer)        
        RANewAllianceWarManager:UpdateCellItemData(msg)

    elseif pbCode == HP_pb.GUILD_WAR_PUSH_DEL then
        --删除一条联盟战争信息
        local msg = GuildWar_pb.PushGuildWarDelCell()
        msg:ParseFromString(buffer)        
        RANewAllianceWarManager:DeleteCellData(msg)

    elseif pbCode == HP_pb.GUILD_WAR_PUSH_DEL_ITEM then
        --删除一个联盟战争行军信息
        local msg = GuildWar_pb.PushGuildWarDelCellItem()
        msg:ParseFromString(buffer)        
        RANewAllianceWarManager:DeleteCellItemData(msg)

    elseif pbCode == HP_pb.GUILD_WAR_PUSH_BUY_ITEM_TIMES then
        -- 更新一个数据的购买次数
        local msg = GuildWar_pb.PushGuildWarBuyItems()
        msg:ParseFromString(buffer)        
        RANewAllianceWarManager:UpdateCellBuyTimes(msg)        

    elseif pbCode == HP_pb.GUILDMANAGER_REFRESH_HELPQUEUE_NUM_S then --帮助刷新
        local msg = GuildManager_pb.RefreshGuildHelpQueueNumRes()
        msg:ParseFromString(buffer)
        RAAllianceManager.helpNum = msg.num
        MessageManager.sendMessage(MessageDef_Alliance.MSG_Alliance_HelpNum_Change)
        RAAllianceManager:refreshAllianceNoticeNum()
    elseif pbCode == HP_pb.GUILD_APPLYNUM_SYNC_S then --申请刷新
        local msg = GuildManager_pb.HPGuildApplyNumSync()
        msg:ParseFromString(buffer)
        RAAllianceManager.applyNum = msg.applyNum
        MessageManager.sendMessage(MessageDef_Alliance.MSG_Alliance_ApplyNum_Change)
        RAAllianceManager:refreshAllianceNoticeNum()


    -- 核弹发射井相关数据
    elseif pbCode == HP_pb.NUCLEAR_INFO_SYNC then
        local msg = GuildManor_pb.NuclearInfo()
        msg:ParseFromString(buffer)

        RAAllianceManager:SyncNuclearInfo(msg)
        MessageManager.sendMessage(MessageDef_Alliance.MSG_NuclearInfo_Update)
        return
    
    elseif pbCode == HP_pb.GUILD_MANOR_NUCLEAR_DEL_SYNC then
        local msg = GuildManor_pb.GuildManorNuclearDelSync()
        msg:ParseFromString(buffer)

        RAAllianceManager:DelNuclearInfo(msg)
        return
    elseif pbCode == HP_pb.GUILD_SCORE_SYNC_S then
        local msg = GuildManager_pb.GuildScoreSync()
        msg:ParseFromString(buffer)
        RAAllianceManager.allianScore = msg.allianScore
        MessageManager.sendMessage(MessageDef_Alliance.MSG_AllianceScore_Update)
    elseif pbCode == HP_pb.GUILD_STATUE_INFO_SYNC_S then --雕像信息修改
        print("GUILD_STATUE_INFO_SYNC_S in pushHander")
        local msg = GuildManager_pb.GetGuildStatueInfoResp();
        msg:ParseFromString(buffer)     
        if msg ~= nil then
            local RAAllianceStatueManager = RARequire('RAAllianceStatueManager')
            RAAllianceStatueManager:onRecieveStatueInfo(msg)
            MessageManager.sendMessage(MessageDef_Alliance.MSG_Alliance_Statue_Update)
        end    
    elseif pbCode == HP_pb.GUILDMANAGER_BEHELPED_S then --联盟帮助
        -- RARootManager.show
        local msg = GuildManager_pb.BeGuildHelpedRes()
        msg:ParseFromString(buffer)

        local helpText = ''

        --描述
        local queueType = msg.queueType
        local des = ""
        local helperName = msg.helperName
        if queueType == Const_pb.BUILDING_QUEUE or queueType == Const_pb.BUILDING_DEFENER then
        
            local buildId = msg.itemId
            local buildInfo = RABuildingUtility.getBuildInfoById(buildId) 
            des = _RALang("@AllianceHelpBuildQueueInfo",helperName,buildInfo.level,_RALang(buildInfo.buildName))

            local queueStatus = msg.queueStatus
            if queueStatus == Const_pb.QUEUE_STATUS_UPGRADE or queueStatus == Const_pb.QUEUE_STATUS_COMMON then -- 建筑升级中
                des = _RALang("@AllianceHelpUpgradeQueueInfo",helperName, buildInfo.level,_RALang(buildInfo.buildName))
            elseif queueStatus == Const_pb.QUEUE_STATUS_REPAIR then -- 建筑维修中
                des = _RALang("@AllianceHelpBuildRepairQueueInfo",helperName,buildInfo.level,_RALang(buildInfo.buildName))
            elseif queueStatus == Const_pb.QUEUE_STATUS_REBUILD then -- 建筑改建中
                des = _RALang("@AllianceHelpBuildRebuildQueueInfo",helperName,buildInfo.level,_RALang(buildInfo.buildName))
            end
        elseif queueType==Const_pb.SCIENCE_QUEUE then
            local techId = msg.itemId
            local RAScienceUtility = RARequire('RAScienceUtility')
            local techInfo = RAScienceUtility:getScienceDataById(techId)
            des = _RALang("@AllianceHelpTechQueueInfo",helperName,_RALang(techInfo.techName))
 
        elseif queueType==Const_pb.CURE_QUEUE then
            des = _RALang("@AllianceHelpCureQueueInfo",helperName)
        end 

        local RARootManager = RARequire('RARootManager')
        RARootManager.ShowMsgBox(des)        
    end
end

return RAAlliancePushHandler

