--region *.lua
--Date
--此文件由[BabeLua]插件自动生成


local RAActivityPushHandle = {}

function RAActivityPushHandle:onReceivePacket(handler)
    local HP_pb = RARequire("HP_pb")
    local Activity_pb = RARequire("Activity_pb")
    local RA_Common = RARequire("common")

    RARequire("MessageDefine")
    RARequire("MessageManager")

    
    local pbCode = handler:getOpcode()
    local buffer = handler:getBuffer()
    if pbCode == HP_pb.ONLINE_REWARD_PUSH then  	--在线宝箱奖励推送，
        local msg = Activity_pb.OnlineRewardItemPB()
        msg:ParseFromString(buffer)
        local treasureBoxData = msg
        local RATreasureBoxManager = RARequire("RATreasureBoxManager")
        local curTreasureBox = RATreasureBoxManager:getCurTreasureBox()
        if not curTreasureBox then
            RATreasureBoxManager:Enter()
            RATreasureBoxManager:addTreasureBoxData(treasureBoxData)
        else
            local refreshTime =treasureBoxData.nextRefreshTime
            local currTime = RA_Common:getCurTime()*1000
            --当刷新时间超出现在时间时才更新时间 否则就重置时间
            if refreshTime and refreshTime>currTime then
                RATreasureBoxManager:updateTreasureBoxData(refreshTime)
            else
                --最后一次宝箱
                CCLuaLog("the treasureBox is end=====================")
                RATreasureBoxManager:updateTreasureBoxData(0)
            end 
            
        end 

    elseif pbCode == HP_pb.DAILYLOGIN_INFO_SYNC_S then
        local msg = Activity_pb.HPDailyLoginInfoSync()
        msg:ParseFromString(buffer)

        local RADailyLoginPage = RARequire("RADailyLoginPage")
        RADailyLoginPage.dailyLoginInfos = {}
        RADailyLoginPage.dailyLoginInfos.dayOfWeek = msg.dayOfWeek
        local weekRewards = msg.weekReward

        for i = 1,#weekRewards do
            local info = {}
            info.itemId = weekRewards[i].itemId
            info.itemType = weekRewards[i].itemType
            info.itemCount = weekRewards[i].itemCount
            info.receiveStatus = 0
            RADailyLoginPage.dailyLoginInfos[#RADailyLoginPage.dailyLoginInfos + 1] = info
        end

        local rewardDays = msg.rewardDay
        for i = 1,#rewardDays do
            local rewardDay = rewardDays[i]
            if rewardDay then
                RADailyLoginPage.dailyLoginInfos[rewardDay].receiveStatus = 1
            end
        end
    elseif pbCode == HP_pb.ROUND_TASK_ACTIVITY_START_PUSH then                  --周期性日常活动推送以及活动阶段变更
        local msg = Activity_pb.RoundTaskActivityPushPB()
        msg:ParseFromString(buffer)

        local activitys = msg.activity
        local count = #activitys
        for i=1,count do
            local activityData =activitys[i] 
            local activityId = activityData.activityId

            local RADailyTaskActivityManager =RARequire("RADailyTaskActivityManager")
            local activity = RADailyTaskActivityManager:getActivityDatasById(activityId)
            if not activity then
                RADailyTaskActivityManager:addActivityDatas(activityId,activityData)
            else
                RADailyTaskActivityManager:updateActivityDatas(activityId,activityData)
            end 

            --发一个消息
            local updateMsg = MessageDef_DailyTaskStatus.MSG_DailyTask_Changed
            MessageManager.sendMessage(updateMsg)
        end
     elseif pbCode == HP_pb.TRAVEL_SHOP_INFO_SYNC then                  --周期性日常活动推送以及活动阶段变更
        local msg = Activity_pb.HPTravelShopInfoSync()
        msg:ParseFromString(buffer)
        local RABlackShopManager = RARequire("RABlackShopManager")
        RABlackShopManager:onRecievePacket(msg)
    end
end

return RAActivityPushHandle

--endregion
