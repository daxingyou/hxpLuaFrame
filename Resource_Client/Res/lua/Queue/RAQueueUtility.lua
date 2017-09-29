local RAQueueUtility = {}

local common = RARequire("common")
local Const_pb = RARequire('Const_pb')
local RALogicUtil = RARequire("RALogicUtil")
local Utilitys = RARequire("Utilitys")
local RAMainUIHelper = RARequire("RAMainUIHelper")
local RAStringUtil = RARequire("RAStringUtil")
local RAQueueManager = RARequire("RAQueueManager")
local RARootManager = RARequire("RARootManager")
local RAPlayerInfoManager = RARequire('RAPlayerInfoManager')
local RARealPayManager = RARequire('RARealPayManager')

--取消队列提示框
function RAQueueUtility.showCancelQueueWindow(queueData)
    local confirmData = {}
    confirmData.yesNoBtn = true
    confirmData.labelText = RAQueueUtility.getQueueCancelTip(queueData)
    confirmData.resultFun = function (isOk)
        if isOk then
            RAQueueManager:sendQueueCancel(queueData.id)
        end 
        RARootManager.CloseCurrPage()
    end
    RARootManager.OpenPage("RAConfirmPage", confirmData,false,true,true)
end

--队列金币加速
function RAQueueUtility.showSpeedupByGoldWindow(queueData)
    --金币加速需要显示金币消耗
    local remainTime = Utilitys.getCurDiffTime(queueData.endTime)
    local timeCostDimand = RALogicUtil:time2Gold(remainTime)

    local playerDiamond = RAPlayerInfoManager.getResCountById(Const_pb.GOLD)
    local isEnoughDiamod = playerDiamond>=timeCostDimand and true or false

    if isEnoughDiamod then
        local tip = RAQueueUtility.getGoldSpeedupTip(queueData)
        local confirmData = {}
        confirmData.yesNoBtn = true
        confirmData.labelText = _RALang(tip,timeCostDimand)
        confirmData.resultFun = function (isOk)
            if isOk then

                local count = RAQueueManager:getQueueCounts(queueData.queueType)
                if count == 0 then
                    return 
                end 
                RAQueueManager:sendQueueSpeedUpByGold(queueData.id)
            end 
        end
        RARootManager.OpenPage("RAConfirmPage", confirmData,false,true,true) 
    else
        RARealPayManager:getRechargeInfo()
    end 
end

function RAQueueUtility.getQueueCancelTip(queueData)
    --'是否确定要取消{0}？取消只会返还50％资源',  @BuildQueueCancelTip
    local queueType = queueData.queueType
    if queueType == Const_pb.BUILDING_DEFENER then  --防御建筑队列
        queueType = queueData.status
    end
    local text = RAStringUtil:getLanguageString("@cancelCheckTip", _RALang(RAMainUIHelper.QueueNameMap[queueType])).._RALang("@cancelReclaimHalf")
    return text
end

--立即完成弹框title
function RAQueueUtility.getFinishQueueNeedDoItRight( queueType )
    --_RALang("@instantToDo")  需要立即{0}吗？
    return RAStringUtil:getLanguageString("@instantToDo", _RALang(RAMainUIHelper.QueueNameMap[queueType]))
end

--通用加速道具使用弹框title
function RAQueueUtility.getQueueNeedDoItRight( queueType )
    --_RALang("@popUpTitle")  {0}中
    return RAStringUtil:getLanguageString("@popUpTitle", _RALang(RAMainUIHelper.QueueNameMap[queueType]))
end

function RAQueueUtility.getQueueGoShopBuy( queueType )
    --请前往商店购买{0}加速道具  @commonUseItemTips
    return RAStringUtil:getLanguageString("@commonUseItemTips", _RALang(RAMainUIHelper.QueueNameMap[queueType]))
end

--是否可以帮助的队列
function RAQueueUtility.isQueueTypeCanHelp(queueType)
    if queueType==Const_pb.BUILDING_QUEUE or queueType == Const_pb.BUILDING_DEFENER or queueType==Const_pb.SCIENCE_QUEUE or queueType==Const_pb.CURE_QUEUE then
        return true
    end  

    return false
end

--目前推送都是服务器推了，该函数未使用
function RAQueueUtility.isQueueTypePush(queueType)
    if queueType==Const_pb.BUILDING_QUEUE or queueType == Const_pb.BUILDING_DEFENER or queueType==Const_pb.SCIENCE_QUEUE 
        or queueType==Const_pb.CURE_QUEUE or queueType == Const_pb.SOILDER_QUEUE then
        return true
    end  

    return false
end


local timeBarIconMap = {}
timeBarIconMap[Const_pb.SCIENCE_QUEUE] = 'MainUI_Queue_Btn_Research.png' --科研队列
timeBarIconMap[Const_pb.SOILDER_QUEUE] = 'MainUI_Queue_Btn_Army.png' --造兵队列
timeBarIconMap[Const_pb.CURE_QUEUE] = 'MainUI_Queue_Btn_Repair.png'  --治疗队列
timeBarIconMap[Const_pb.BUILDING_QUEUE] = {}
timeBarIconMap[Const_pb.BUILDING_QUEUE][Const_pb.QUEUE_STATUS_COMMON] = 'MainUI_HUD_Upgrade.png'
timeBarIconMap[Const_pb.BUILDING_QUEUE][Const_pb.QUEUE_STATUS_REBUILD] = 'MainUI_HUD_Rebuilding.png'

timeBarIconMap[Const_pb.BUILDING_DEFENER] = {}
timeBarIconMap[Const_pb.BUILDING_DEFENER][Const_pb.QUEUE_STATUS_COMMON] = 'MainUI_HUD_Upgrade.png'
timeBarIconMap[Const_pb.BUILDING_DEFENER][Const_pb.QUEUE_STATUS_REPAIR] = 'MainUI_HUD_RePair.png'
timeBarIconMap[Const_pb.BUILDING_DEFENER][Const_pb.QUEUE_STATUS_REBUILD] = 'MainUI_HUD_Rebuilding.png'

--获得进度条的小图标
function RAQueueUtility.getTimeBarIcon(queueData)
    return RAQueueUtility.getBaseInfo(timeBarIconMap,queueData)
end


local goldSpeedupTipMap = {}
goldSpeedupTipMap[Const_pb.SCIENCE_QUEUE] = '@SpeedupScienceByGoldTip' --科研队列
goldSpeedupTipMap[Const_pb.SOILDER_QUEUE] = '@SpeedupSoilderByGoldTip' --造兵队列
goldSpeedupTipMap[Const_pb.CURE_QUEUE] = '@SpeedupCureByGoldTip'  --治疗队列
goldSpeedupTipMap[Const_pb.BUILDING_QUEUE] = {}
goldSpeedupTipMap[Const_pb.BUILDING_QUEUE][Const_pb.QUEUE_STATUS_COMMON] = '@SpeedupUpgradeByGoldTip'
goldSpeedupTipMap[Const_pb.BUILDING_QUEUE][Const_pb.QUEUE_STATUS_REBUILD] = '@SpeedupRebuildByGoldTip'

goldSpeedupTipMap[Const_pb.BUILDING_DEFENER] = {}
goldSpeedupTipMap[Const_pb.BUILDING_DEFENER][Const_pb.QUEUE_STATUS_COMMON] = '@SpeedupUpgradeByGoldTip'
goldSpeedupTipMap[Const_pb.BUILDING_DEFENER][Const_pb.QUEUE_STATUS_REPAIR] = '@SpeedupRepairByGoldTip'
goldSpeedupTipMap[Const_pb.BUILDING_DEFENER][Const_pb.QUEUE_STATUS_REBUILD] = '@SpeedupRebuildByGoldTip'

function RAQueueUtility.getGoldSpeedupTip(queueData)
    return RAQueueUtility.getBaseInfo(goldSpeedupTipMap,queueData)
end

function RAQueueUtility.getBaseInfo(map,queueData)
    local info = nil 
    if queueData.queueType==Const_pb.BUILDING_QUEUE or queueData.queueType == Const_pb.BUILDING_DEFENER then
        info = map[queueData.queueType][queueData.status]
    else
        info = map[queueData.queueType]
    end 
    return info
end

--得到时间条的比例
function RAQueueUtility.getTimeBarScale(queueData)
    local processTime = os.difftime(common:getCurTime(),queueData.startTime) + queueData.totalReduceTime
    local totolTime = queueData.totalQueueTime
        
    local scaleX = processTime/totolTime

    if scaleX>=1 then
        scaleX = 1
    elseif scaleX<0 then 
        scaleX = 0
    end

    return scaleX 
end

return RAQueueUtility