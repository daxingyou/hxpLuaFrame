local Const_pb = RARequire("Const_pb")

local RANotificationManager = {}

package.loaded[...] = RANotificationManager

RANotificationManager.dailyLoginRewardNoticeTime = 20--晚上8点
RANotificationManager.MINI_NOTI_KEY = 10000

--desc:添加每日登陆奖励，以定点的某时某分为参数，从当前客户端时间判断，添加7天内的通知。如果当前时间没有到达给定时间，那么7天包含当前天，否则不包含
function RANotificationManager.add7LocalTimingNotice(timeHour, timeMinite, jumpToday)
    local notiKey = Const_pb.DAILY_LOGIN_ACTIVITY

    local currTime = os.time()
    local currTab = os.date("*t", currTime);

    local nextStartTime = 0
    if currTab.hour > timeHour or (currTab.hour == timeHour and currTab.min >= timeMinite) or jumpToday  then
        --当前时间已经过了需要通知的时间了，从明天的这个时间点开始通知，处理跨日，跨月，跨年的影响
        local tommorrowTime = currTime + 24*3600--获得第二天时间戳
        local tommorrowTab = os.date("*t", tommorrowTime)

        nextStartTime = os.time({year = tommorrowTab.year, month = tommorrowTab.month, day = tommorrowTab.day, hour = timeHour, min = timeMinite, sec = 0})

    else
        nextStartTime = os.time({year = currTab.year, month = currTab.month, day = currTab.day, hour = timeHour, min = timeMinite, sec = 0})
    end

    local push_conf = RARequire("push_conf")
    local pushConstInfo = push_conf[Const_pb.DAILY_LOGIN_ACTIVITY]
    local title = pushConstInfo.text and _RALang(pushConstInfo.text) or "DailyReward"
    local message = pushConstInfo.text and _RALang(pushConstInfo.text) or "DailyReward"
    for i=1,7 do
        local key = RANotificationManager.MINI_NOTI_KEY + notiKey * 1000 + i
        local timeDur = (nextStartTime+(i-1)*24*3600 - currTime)
        RAPlatformUtils:addLocalNotification(title, message , timeDur, key)
        --RALogWarn("RANotificationManager.add7LocalTimingNotice Add Daily Login Reward Notification With Key : " .. key .. " and Time : " .. timeDur, true)
    end
    
end
--desc:删除每日登陆奖励通知
function RANotificationManager.delete7LocalTimingNotice()
    local tomeLoginNotiKey = Const_pb.DAILY_LOGIN_ACTIVITY
    for i=1,7 do
        local key = RANotificationManager.MINI_NOTI_KEY + tomeLoginNotiKey * 1000 + i
        RAPlatformUtils:clearNotification(key)
        --RALogWarn("RANotificationManager.delete7LocalTimingNotice Delete Daily Login Reward Notification With Key : ".. key, true)
    end
end

--desc:所有的每日通知都在此添加，游戏登陆会调用
function RANotificationManager.addAllDailyNotification()
    --添加领取每日登陆奖励的notify，如果已经领取了，那么今天的通知就跳过了
    RANotificationManager.delete7LocalTimingNotice()--先删除
    local RADailyLoginPage = RARequire("RADailyLoginPage")
    local result = RADailyLoginPage:isReceiveDailyLogin()--判断是否领取了每日奖励，true领取了，false没领
    RANotificationManager.add7LocalTimingNotice(RANotificationManager.dailyLoginRewardNoticeTime, 0, result)

end

--desc:添加正常通知,key是int, delayTime单位是s
function RANotificationManager.addCommonNotification(title, message, delayTime, notiKey)
    local key = RANotificationManager.MINI_NOTI_KEY + notiKey --key > 10000
    RAPlatformUtils:addLocalNotification(title, message , delayTime, key)
end

--des: 
-- key 获取userDefault中的值
-- id 推送配置的 id
-- time 推送的时间间隔 单位秒
function RANotificationManager.addNotification(id, delayTime, notiKey, name)
    -- body
    local push_conf = RARequire("push_conf")
    local pushConf = push_conf[id]
    if not pushConf then return end

    local isOpen = CCUserDefault:sharedUserDefault():getBoolForKey(pushConf.key, true)
    if isOpen then
        local text = _RALang(pushConf.text,_RALang(name))
        if text ~= "" and text ~= nil then
            if delayTime < 0 then
                delayTime = 0
            end
            RANotificationManager.addCommonNotification(text, text, delayTime, notiKey)
            --RALogWarn("RANotificationManager.addNotification Add Local Notification With Key : " .. notiKey .. " and Time : " .. delayTime, true)
        end
    end
end

--desc:删除正常通知key > 10000
function RANotificationManager.deleteCommonNotification(notiKey)
    local key = RANotificationManager.MINI_NOTI_KEY + notiKey
    RAPlatformUtils:clearNotification(key)
    --RALogWarn("RANotificationManager.deleteCommonNotification Delete Local Notification With Key : " .. notiKey, true)
end

--根据队列类型和状态返回 push_conf id
function RANotificationManager.getPushIdByQueue(queueData)
    -- body
    local pushId = 0
    if queueData.queueType == Const_pb.BUILDING_QUEUE or queueData.queueType == Const_pb.BUILDING_DEFENER then --防御队列 --建造或者升级
        local status = tonumber(queueData.status)
        if status == Const_pb.QUEUE_STATUS_COMMON then --普通状态，其他队列使用 只有普通队列升级
            pushId = Const_pb.BUILDING_QUEUE_FINISHED
        elseif status == Const_pb.QUEUE_STATUS_REBUILD then --建筑改造
            pushId = Const_pb.BUILDING_REBUILD_FINISHED
        elseif status == Const_pb.QUEUE_STATUS_UPGRADE then --防御建筑升级中
            pushId = Const_pb.DEFENCE_BUILDING_FINISHED
        elseif status == Const_pb.QUEUE_STATUS_REPAIR then --防御建筑维修中
            pushId = Const_pb.DEFENCE_BUILDING_REPAIR_FINISHED  
        end 
    elseif queueData.queueType == Const_pb.SOILDER_QUEUE then --造兵
        pushId = Const_pb.SOILDER_QUEUE_FINISHED    
    elseif queueData.queueType == Const_pb.CURE_QUEUE then --治疗伤兵不需要
        pushId = Const_pb.CURE_QUEUE_FINISHED   
    elseif queueData.queueType == Const_pb.SCIENCE_QUEUE then --研究科技
        pushId = Const_pb.SCIENCE_QUEUE_FINISHED    
    end
    return pushId
end

--[[
    desc:删除所有本地通知
]]
function RANotificationManager.deleteAllLocalNotification()
    RAPlatformUtils:clearNotification()
    --RALogWarn("RANotificationManager.deleteAllLocalNotification Delete All Notification", true)
end

--[[
    desc:重置本地通知
]]
function RANotificationManager:reset()
    self.deleteAllLocalNotification()
end