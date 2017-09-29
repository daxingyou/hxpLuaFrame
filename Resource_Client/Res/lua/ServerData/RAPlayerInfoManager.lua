local Utilitys = RARequire('Utilitys')
local const_conf = RARequire('const_conf')
local RAPlayerInfo = RARequire("RAPlayerInfo")
local RAGameConfig = RARequire("RAGameConfig")
local RASDKLoginConfig = RARequire("RASDKLoginConfig")

local RAPlayerInfoManager = 
{
    -- 开服时间
    mOpenServerTime = 0,
    -- 服务器当前时间
    serverTime      = 0,
    -- 本地时间与服务器时间间隔
    offsetTime      = 0
}
package.loaded[...] = RAPlayerInfoManager

function RAPlayerInfoManager.setPlayerBasicInfo(msg)
    CCLuaLog("RAPlayerInfoManager.setPlayerBasicInfo")
    RAPlayerInfo.raPlayerBasicInfo.playerId = msg.playerId

    RAPlayerInfo.raPlayerBasicInfo.name = msg.name

    RAPlayerInfo.raPlayerBasicInfo.gold = msg.gold

    RAPlayerInfo.raPlayerBasicInfo.coin = msg.coin

    RAPlayerInfo.raPlayerBasicInfo.recharge = msg.recharge

    RAPlayerInfo.raPlayerBasicInfo.vipEndTime = msg.vipEndTime

    RAPlayerInfo.raPlayerBasicInfo.vipPoints = msg.vipPoint

    local needSendExtend = false--需要向平台发送信息的标记
    if RAPlayerInfo.raPlayerBasicInfo.vipLevel == nil or RAPlayerInfo.raPlayerBasicInfo.vipLevel < msg.vipLevel then
        needSendExtend = true
    end

    --judge if player is level up, send msg
    if RAPlayerInfo.raPlayerBasicInfo.level ~= 0 and 
        RAPlayerInfo.raPlayerBasicInfo.level < msg.level then
        MessageManager.sendMessage(MessageDef_Lord.MSG_LevelUpgrade)
        needSendExtend = true
    end

    RAPlayerInfo.raPlayerBasicInfo.vipLevel = msg.vipLevel

    RAPlayerInfo.raPlayerBasicInfo.level = msg.level

    RAPlayerInfo.raPlayerBasicInfo.exp = msg.exp

    RAPlayerInfo.raPlayerBasicInfo.headIconId = msg.icon

    RAPlayerInfo:setElectric(msg.electric,msg.electricMax)

    RAPlayerInfo.raPlayerBasicInfo.goldore = msg.goldore

    RAPlayerInfo.raPlayerBasicInfo.oil = msg.oil

    RAPlayerInfo.raPlayerBasicInfo.steel = msg.steel

    RAPlayerInfo.raPlayerBasicInfo.power = msg.vit

    RAPlayerInfo.raPlayerBasicInfo.tombarthite = msg.tombarthite

    RAPlayerInfo.raPlayerBasicInfo.battlePoint = msg.battlePoint

    RAPlayerInfo.raPlayerBasicInfo.lastLoginTime = msg.lastLoginTime

    RAPlayerInfo.raPlayerBasicInfo.freeVipPoint = msg.freeVipPoint

    RAPlayerInfo.raPlayerBasicInfo.iconBuy = msg.iconBuy

    --向平台发送信息
    if needSendExtend then
        local puid = CCUserDefault:sharedUserDefault():getStringForKey(RASDKLoginConfig.ACCOUNT_PUID, "")
        local serverId = CCUserDefault:sharedUserDefault():getStringForKey(RASDKLoginConfig.SERVER_ID, "");
        local RAWorldUtil = RARequire('RAWorldUtil')
        local k = RAWorldUtil.kingdomId.tonumber(serverId)
        RAPlatformUtils:sendExtendData(msg.vipLevel, msg.level, msg.name, msg.playerId, k, puid)
    end

    MessageManager.sendMessage(MessageDef_MainUI.MSG_UpdateBasicPlayerInfo,{})
end

function RAPlayerInfoManager.setPlayerDetailInfo(msg)
    RAPlayerInfo.raPlayerDetailInfo.warWinCnt = msg.warWinCnt
    RAPlayerInfo.raPlayerDetailInfo.warLoseCnt = msg.warLoseCnt
    RAPlayerInfo.raPlayerDetailInfo.atkWinCnt = msg.atkWinCnt
    RAPlayerInfo.raPlayerDetailInfo.atkLoseCnt = msg.atkLoseCnt
    RAPlayerInfo.raPlayerDetailInfo.defWinCnt = msg.defWinCnt
    RAPlayerInfo.raPlayerDetailInfo.defLoseCnt = msg.defLoseCnt
    RAPlayerInfo.raPlayerDetailInfo.spyCnt = msg.spyCnt
    RAPlayerInfo.raPlayerDetailInfo.armyKillCnt = msg.armyKillCnt
    RAPlayerInfo.raPlayerDetailInfo.armyLoseCnt = msg.armyLoseCnt
    RAPlayerInfo.raPlayerDetailInfo.armyCureCnt = msg.armyCureCnt

    if msg:HasField("battlePoint") then
        RAPlayerInfo.raPlayerBasicInfo.battlePoint = msg.battlePoint
    end
    if msg:HasField("playerBattlePoint") then
        RAPlayerInfo.raPlayerDetailInfo.playerBattlePoint = msg.playerBattlePoint
    end
    if msg:HasField("armyBattlePoint") then
        RAPlayerInfo.raPlayerDetailInfo.armyBattlePoint = msg.armyBattlePoint
    end
    if msg:HasField("techBattlePoint") then
        RAPlayerInfo.raPlayerDetailInfo.techBattlePoint = msg.techBattlePoint
    end
    if msg:HasField("buildBattlePoint") then
        RAPlayerInfo.raPlayerDetailInfo.buildBattlePoint = msg.buildBattlePoint
    end

    if msg:HasField("defenseBattlePoint") then
        RAPlayerInfo.raPlayerDetailInfo.defenseBattlePoint = msg.defenseBattlePoint
    end

    if msg:HasField("equipBattlePoint") then
        RAPlayerInfo.raPlayerDetailInfo.equipBattlePoint = msg.equipBattlePoint
    end
    
    if msg:HasField("maxMarchSoldierNum") then
        RAPlayerInfo.raPlayerDetailInfo.maxMarchSoldierNum = msg.maxMarchSoldierNum
    end

    if msg:HasField("maxCapNum") then
        RAPlayerInfo.raPlayerDetailInfo.maxCapNum = msg.maxCapNum
    end

end

function RAPlayerInfoManager.getWinRat()
    local totalCount = (RAPlayerInfo.raPlayerDetailInfo.warWinCnt + RAPlayerInfo.raPlayerDetailInfo.warLoseCnt)
    if totalCount == 0 then
        return 0
    else
        return (RAPlayerInfo.raPlayerDetailInfo.warWinCnt / totalCount)
    end
end

function RAPlayerInfoManager.getPlayerInfo()
    return RAPlayerInfo
end

function RAPlayerInfoManager.getPlayerDetailInfo()
    return RAPlayerInfo.raPlayerDetailInfo
end

function RAPlayerInfoManager.getVipLevel(vipPoint)
    --鏍规嵁vip鐐规暟锛岃幏寰梫iplevel
    -- if vipPoint == nil then
    --     vipPoint = RAPlayerInfo.raPlayerBasicInfo.vipPoints
    -- end
    -- local vipLevel = 0
    -- for i=1, Utilitys.table_count(vip_conf) do
    --    local configId = RAGameConfig.ConfigIDFragment.ID_VIP_LEVEL + i - 1
    --    local cfgItem = vip_conf[configId]
    --    if cfgItem ~= nil then
    --         if cfgItem.point > vipPoint then
    --             break
    --         else
    --             vipLevel = cfgItem.level
    --         end
    --    end
    -- end
    return RAPlayerInfo.raPlayerBasicInfo.vipLevel
end


function RAPlayerInfoManager.getVipCfgByLevel(level)
    if level == nil then
        level = RAPlayerInfoManager.getVipLevel()
    end

    local vip_conf = RARequire('vip_conf')
    return vip_conf[level]
end

-- 鑾峰彇闃熷垪鐨勫厤璐规椂闂撮暱搴︼紝绉掍负鍗曚綅
function RAPlayerInfoManager.getQueueFreeTime(vipLevel, queueType)
    -- 鍙湁寤洪犻槦鍒楁墠鏈夊厤璐规椂闂?
    if queueType == nil then
        queueType = Const_pb.BUILDING_QUEUE
    end
    if queueType ~= Const_pb.BUILDING_QUEUE then
        return -1
    end
    local cfg = RAPlayerInfoManager.getVipCfgByLevel(vipLevel)
    local baseTime = const_conf.freeTime.value
    if RAPlayerInfoManager.isVIPActive() and cfg ~= nil and cfg.freeTime ~= nil then
        baseTime = cfg.freeTime*60/100 --配置文件写的1000代表10分钟
    end
    return baseTime
end

function RAPlayerInfoManager.isVIPActive()
    local endTime = RAPlayerInfoManager.getPlayerBasicInfo().vipEndTime
    local remainTime = Utilitys.getCurDiffTime(endTime/1000)

    local isActive = false
    if remainTime > 0 then
        isActive = true
    end

    return isActive,remainTime
end



function RAPlayerInfoManager.getPlayerBust(headIconId)
    local id = RAPlayerInfo.raPlayerBasicInfo.headIconId
    if headIconId then
        id = headIconId
    end
    id = tonumber(id) or 0

    local key = RAGameConfig.ConfigIDFragment.ID_PLAYER_SHOWCONF + id
    local player_show_conf = RARequire("player_show_conf")
    local info = player_show_conf[key]
    if not info then
        info = player_show_conf[701000]
    end
    return info.playerShow
end

function RAPlayerInfoManager.getHeadIcon(headIconId)
    local id = RAPlayerInfo.raPlayerBasicInfo.headIconId
    if headIconId then
        id = headIconId
    end
    id = tonumber(id) or 0

    local key = RAGameConfig.ConfigIDFragment.ID_PLAYER_SHOWCONF + id
    local player_show_conf = RARequire("player_show_conf")
    local info = player_show_conf[key]
    if not info then
        info = player_show_conf[701000]
    end 
    return info.playerIcon
end

function RAPlayerInfoManager.getPlayerBasicInfo()
    return RAPlayerInfo.raPlayerBasicInfo
end

function RAPlayerInfoManager.getPlayerEquipInfo()
    return RAPlayerInfo.raPlayerBasicInfo.equip
end

function RAPlayerInfoManager.setPlayerEquipInfo(equips)
    RAPlayerInfo.raPlayerBasicInfo.equip = equips
end


function RAPlayerInfoManager.setPlayerId(playerId)
    RAPlayerInfo.raPlayerBasicInfo.playerId = playerId
end

function RAPlayerInfoManager.getPlayerId()
    -- body
    return RAPlayerInfo.raPlayerBasicInfo.playerId
end

function RAPlayerInfoManager.isSelf(playerId)
    return RAPlayerInfo.raPlayerBasicInfo.playerId == playerId
end

function RAPlayerInfoManager.getPlayerLevel()
    -- body
    return RAPlayerInfo.raPlayerBasicInfo.level or 1
end

--根据形象id 判断是否有购买此形象
function RAPlayerInfoManager.getPlayerIsAlreadyBuyHead(headId)
    -- body
    local isBuy = false
    local RAStringUtil = RARequire('RAStringUtil')
    local iconBuys = RAPlayerInfo.raPlayerBasicInfo.iconBuy
    if iconBuys == "" then return isBuy end
    local arr = RAStringUtil:split(iconBuys,",") 
    for i = 1, #arr do
        local iconBuyId = tonumber(arr[i])
        if iconBuyId == headId then
            isBuy = true
            break
        end
    end

    return isBuy
end

-- 鏈嶅姟鍣ㄧ闅忔椂璁＄畻鍚庢帹閫?
function RAPlayerInfoManager.getPlayerFightPower()
    return RAPlayerInfo.raPlayerBasicInfo.battlePoint
    -- --todo:璁＄畻涓诲皢鎴樻枟鍔?
    -- local id = RAGameConfig.ConfigIDFragment.ID_PLAYER_LEVEL + RAPlayerInfo.raPlayerBasicInfo.level - 1
    -- local lordPower = 0
    -- local armyPower = 0
    -- local buildPower = 0
    -- local techPower = 0
    -- local equipPower = 0
    -- local trapPower = 0
    -- if player_level_conf[id] ~= nil thenelectric
    --     lordPower = player_level_conf[id].battlePoint
    -- end
    -- local totalPower = lordPower + armyPower + buildPower + techPower + equipPower + trapPower
    -- return totalPower
end

--将军战斗力
function RAPlayerInfoManager.getGeneralFightPower()
--    local id = RAGameConfig.ConfigIDFragment.ID_PLAYER_LEVEL + RAPlayerInfo.raPlayerBasicInfo.level - 1
--    local lordPower = 0
--    if player_level_conf[id] ~= nil then
--        lordPower = player_level_conf[id].battlePoint
--    end
--    return lordPower


    return RAPlayerInfo.raPlayerDetailInfo.playerBattlePoint
end

--部队战斗力
function RAPlayerInfoManager.getArmyFightPower()
    return RAPlayerInfo.raPlayerDetailInfo.armyBattlePoint
end

--科技战斗力
function RAPlayerInfoManager.getTechFightPower()
    return RAPlayerInfo.raPlayerDetailInfo.techBattlePoint
end

--建筑战斗力
function RAPlayerInfoManager.getBuildFightPower()
    return RAPlayerInfo.raPlayerDetailInfo.buildBattlePoint
end

--防御战斗力
function RAPlayerInfoManager.getDefenseFightPower()
    return RAPlayerInfo.raPlayerDetailInfo.defenseBattlePoint
end

--装备战斗力
function RAPlayerInfoManager.getEquipFightPower()
    return RAPlayerInfo.raPlayerDetailInfo.equipBattlePoint
end

function RAPlayerInfoManager:getPlayerName()
    return RAPlayerInfo.raPlayerDetailInfo.name
end


-- 获取当前电力值，这个服务器会计算完作用号后发过来
function RAPlayerInfoManager.getCurrElectricValue()    
    local baseElectric = RAPlayerInfo.raPlayerBasicInfo.electric    
    return baseElectric, baseElectric
end


-- 获取当前电力上限值，这个需要前端自己来算作用号加成
function RAPlayerInfoManager.getCurrElectricMaxValue()
    local addPer = RAPlayerInfoManager.getElectricAddEffect()
    local baseElectricMax = RAPlayerInfo.raPlayerBasicInfo.electricMax
    local realElectricMax = math.floor(baseElectricMax * (addPer + 1))
    return realElectricMax, baseElectricMax
end


-- 获取当前主城等级下，电力上限值
function RAPlayerInfoManager.getCurrElectricMaxCfgValue()
    local Const_pb = RARequire("Const_pb")
    local RABuildManager = RARequire("RABuildManager")
    local buildData = RABuildManager:getBuildDataByType(Const_pb.CONSTRUCTION_FACTORY)
    if buildData == nil then return 0 end
    local electricMaxBase = 0
    for k,v in pairs(buildData) do
        electricMaxBase = v.confData.electricMax
    end
    local addPer = RAPlayerInfoManager.getElectricAddEffect()
    local realElectric = math.floor(electricMaxBase * (addPer + 1))
    return realElectric, electricMaxBase
end

function RAPlayerInfoManager.getElectricAddEffect()
    local RAPlayerEffect = RARequire('RAPlayerEffect')
    local effectValue = RAPlayerEffect:getEffectResult(Const_pb.CITY_ELECTRIC_OVERLOAD)
    local addPer = FACTOR_EFFECT_MULTIPLE * effectValue
    return addPer
end

-- 根据类型获取对应的电力减少作用号
-- 1 normal build
-- 2 defence build
-- 3 soldier 
function RAPlayerInfoManager.getElectricReduceEffectByType(target)
    local RAPlayerEffect = RARequire('RAPlayerEffect')
    local baseReduceValue = RAPlayerEffect:getEffectResult(Const_pb.CITY_ELECTRIC_REDUCE)
    local baseReducePer = FACTOR_EFFECT_MULTIPLE * baseReduceValue

    local targetReducePer = 0
    if target == 1 then
        local targetReduceValue = RAPlayerEffect:getEffectResult(Const_pb.CITY_ELECTRIC_BUILD)
        targetReducePer = FACTOR_EFFECT_MULTIPLE * targetReduceValue
    elseif target == 2 then
        local targetReduceValue = RAPlayerEffect:getEffectResult(Const_pb.CITY_ELECTRIC_CANNON)
        targetReducePer = FACTOR_EFFECT_MULTIPLE * targetReduceValue
    elseif target == 3 then
        local targetReduceValue = RAPlayerEffect:getEffectResult(Const_pb.CITY_ELECTRIC_SOLDIER)
        targetReducePer = FACTOR_EFFECT_MULTIPLE * targetReduceValue
    end
    return baseReducePer + targetReducePer, baseReducePer, targetReducePer
end

-- 获取普通建筑和防御建筑电力占用值
function RAPlayerInfoManager.getElectricValueForBuildings()
    local RABuildManager = RARequire("RABuildManager")

    local normalPer, _, _ = RAPlayerInfoManager.getElectricReduceEffectByType(1)
    local defencePer, _, _ = RAPlayerInfoManager.getElectricReduceEffectByType(2)

    local baseNormal = 0
    local baseDef = 0
    local allBuildDatas = RABuildManager.buildingDatas
    for k,v in pairs(allBuildDatas) do
        local consume = v.confData.electricConsume or 0
        if v.confData.limitType == Const_pb.LIMIT_TYPE_BUILDING_DEFENDER then
            baseDef = baseDef + consume
        else
            baseNormal = baseNormal + consume
        end
    end

    return baseNormal, baseDef, baseNormal * normalPer, baseDef * defencePer
end

-- 获取所有类型建筑对应的电力展示数据
-- 数据均为float  未取整
function RAPlayerInfoManager.getElectricInfoForAllBuildings()
    local RABuildManager = RARequire("RABuildManager")
    local result = {}

    local normalPer, _, _ = RAPlayerInfoManager.getElectricReduceEffectByType(1)
    local defencePer, _, _ = RAPlayerInfoManager.getElectricReduceEffectByType(2)

    local baseNormal = 0
    local baseDef = 0
    local allBuildDatas = RABuildManager.buildingDatas
    for k,v in pairs(allBuildDatas) do
        local buildType = v.confData.buildType        
        --- 排除不占用电力的建筑状态（爱因斯坦）
        if v.status ~= Const_pb.DAMAGED and
            v.status ~= Const_pb.READY_TO_CREATE then     
            local configId = v.confData.id
            local consume = v.confData.electricConsume or 0        
            local buildName = _RALang(v.confData.buildName)
            local typeData = result[buildType]
            if typeData == nil then
                typeData = {}
                result[buildType] = typeData            
                typeData.count = 0                --build count
                typeData.electricTotal = 0
                typeData.id2Count = {}            -- build id-->count
                typeData.buildType = buildType
                typeData.buildName = buildName    
                typeData.reducePer = 0
                typeData.reduceValue = 0
            end

            typeData.count = typeData.count + 1
            typeData.electricTotal = typeData.electricTotal + consume
            local idCount = typeData.id2Count[configId] or 0
            typeData.id2Count[configId] = idCount + 1

            if v.confData.limitType == Const_pb.LIMIT_TYPE_BUILDING_DEFENDER then
                typeData.reducePer = defencePer            
            else
                typeData.reducePer = normalPer
            end
            typeData.reduceValue = typeData.electricTotal * typeData.reducePer
        end        
    end
    Utilitys.tableSortByKey(result, 'buildType')
    return result
end


-- 获取所有士兵耗电量相关的详细信息
-- 数据均为float  未取整
function RAPlayerInfoManager.getElectricInfoForAllArmys()
    local RACoreDataManager = RARequire('RACoreDataManager')
    local battle_soldier_conf = RARequire("battle_soldier_conf")
    local marchingResult, _, _ = RACoreDataManager:getMarchingArmyLevelMap()
    local freeResult, _, _ = RACoreDataManager:getFreeArmyLevelMap()
    local result = {}
    local handleResult = function(levelMaps)
        local id2Count = {}
        if levelMaps ~= nil then
            for level,datas in pairs(levelMaps) do
                for id,value in pairs(datas) do
                    local armyId = value.armyId
                    local freeCount = value.freeCount or 0
                    local marchCount = value.marchCount or 0
                    local oldCount = id2Count[armyId] or 0
                    id2Count[armyId] = freeCount + marchCount + oldCount
                end
            end
        end
        return id2Count
    end
    local marchingId2Count = handleResult(marchingResult)
    local freeId2Count = handleResult(freeResult)
    local soldierPer, _, _ = RAPlayerInfoManager.getElectricReduceEffectByType(3)

    local totalConsume = 0
    local totalReduce = 0
    local handleId2Count = function(armyId, count)
        local armyCfg = battle_soldier_conf[armyId]
        if armyCfg ~= nil then
            local oneArmyInfo = result[armyId]
            if oneArmyInfo == nil then
                oneArmyInfo = {}
                result[armyId] = oneArmyInfo
                oneArmyInfo.armyId = armyId
                oneArmyInfo.armyName = _RALang(armyCfg.name)
                oneArmyInfo.count = 0
                oneArmyInfo.electricTotal = 0
                oneArmyInfo.reducePer = soldierPer
                oneArmyInfo.reduceValue = 0
            end
            oneArmyInfo.count = oneArmyInfo.count + count

            local consume = armyCfg.energyCost or 0 
            oneArmyInfo.electricTotal = oneArmyInfo.electricTotal + consume * oneArmyInfo.count
            oneArmyInfo.reduceValue = oneArmyInfo.electricTotal * oneArmyInfo.reducePer
            totalConsume = totalConsume + oneArmyInfo.electricTotal
            totalReduce = totalReduce + oneArmyInfo.reduceValue
        end
    end
    for armyId,count in pairs(marchingId2Count) do        
        handleId2Count(armyId, count)
    end

    for armyId,count in pairs(freeId2Count) do        
        handleId2Count(armyId, count)
    end
    Utilitys.tableSortByKey(result, 'armyId')
    return result, totalConsume, totalReduce
end


-- 根据{id = count}获取一共消耗的电力
function RAPlayerInfoManager.getArmyElectricConsume(id2Count)
    local battle_soldier_conf = RARequire("battle_soldier_conf")
    local totalConsume = 0
    if id2Count ~= nil then
        for armyId,count in pairs(id2Count) do
            local armyCfg = battle_soldier_conf[armyId]
            if armyCfg ~= nil then
                local consume = armyCfg.energyCost or 0 
                totalConsume = totalConsume + consume * count
            end
        end
    end
    return math.floor(totalConsume)
end


-- 鑾峰彇褰撳墠鐢甸噺鐨勭姸鎬?
function RAPlayerInfoManager.getCurrElectricStatus(tmpValue)
    tmpValue = tmpValue or 0
    local electric = RAPlayerInfoManager.getCurrElectricValue() + tmpValue
    local electricMax = RAPlayerInfoManager.getCurrElectricMaxValue()
    -- 褰撳墠鐢靛姏涓婇檺涓?鐨勬椂鍊欙紝涓烘渶鎱㈢姸鎬?
    if electricMax == nil  then
        return RAGameConfig.ElectricStatus.NotEnough
    end
    local decrease0 = 0
    local decrease1 = const_conf.electric_decrease1.value
    local decrease2 = const_conf.electric_decrease2.value
    local percent = electric / electricMax * 100
    if percent < const_conf.electric_cap1.value then
        return RAGameConfig.ElectricStatus.Enough, decrease0
    end

    if percent >= const_conf.electric_cap1.value and percent < const_conf.electric_cap2.value then
        return RAGameConfig.ElectricStatus.Intense, decrease1
    end

    if percent >= const_conf.electric_cap2.value then
        return RAGameConfig.ElectricStatus.NotEnough, decrease2
    end

    return RAGameConfig.ElectricStatus.NotEnough, decrease2
end

-- 检查电力是否需要弹出警告页面
function RAPlayerInfoManager.checkElectricStatusIsChange(electricAdd, confirmFun)
    electricAdd = electricAdd or 0
    if electricAdd > 0 then
        local currStatus = RAPlayerInfoManager.getCurrElectricStatus()
        local newStatus = RAPlayerInfoManager.getCurrElectricStatus(electricAdd)
        if newStatus > currStatus then
            -- 电力状态发生向上的改变的时候，弹电力警告页面
            local RARootManager = RARequire('RARootManager')
            RARootManager.OpenPage('RAElectricWarningPage', {
                electricAdd = electricAdd,
                confirmFun = confirmFun
                }, false, true, false)
            return true
        end
    end
    if confirmFun ~= nil then
        confirmFun()
    end
    return false
end


-- 鑾峰彇褰撳墠鐢甸噺瀵归槦鍒楃殑褰卞搷鍊硷細澶т簬绛変簬1
function RAPlayerInfoManager.getCurrElectricEffect()
    local effectValue = 0
    local status = RAPlayerInfo.raPlayerBasicInfo.electricStatus
    if status == RAGameConfig.ElectricStatus.Enough then
        effectValue = 0
    elseif status == RAGameConfig.ElectricStatus.Intense then
        effectValue = const_conf.electric_decrease1.value
    elseif status == RAGameConfig.ElectricStatus.NotEnough then
        effectValue = const_conf.electric_decrease2.value
    end
    return (100 + effectValue) / 100
end


function RAPlayerInfoManager.setPlayerName(name)
    RAPlayerInfo.raPlayerBasicInfo.name = name
end

function RAPlayerInfoManager.getPlayerName()
    return RAPlayerInfo.raPlayerBasicInfo.name
end

function RAPlayerInfoManager.setPlayerIconId(id)
    RAPlayerInfo.raPlayerBasicInfo.headIconId = id
end

function RAPlayerInfoManager.SetServerTime(time)
    if time ~= nil and time > 0 then
        RAPlayerInfoManager.serverTime = time
        RAPlayerInfoManager.offsetTime = time - os.time()
    end
end

-- 鑾峰彇浣撳姏涓婇檺鍊?
function RAPlayerInfoManager.getPlayerVitMax(level)            
    if level == nil then
        level = RAPlayerInfo.raPlayerBasicInfo.level
    end
    local levelId = RAGameConfig.ConfigIDFragment.ID_PLAYER_LEVEL + level - 1
    local vitMax = 0

    local player_level_conf = RARequire("player_level_conf")
    if player_level_conf[levelId] ~= nil then
        vitMax = player_level_conf[levelId].vitPoint
    end

    -- 获取体力上限的buff
    -- Const_pb.PLAYER_VIT_MAX_NUM
    -- Const_pb.PLAYER_VIT_MAX_PER
    local RAPlayerEffect = RARequire('RAPlayerEffect')
    local addPer = RAPlayerEffect:getEffectResult(Const_pb.PLAYER_VIT_MAX_PER)
    vitMax = vitMax * (FACTOR_EFFECT_DIVIDE + addPer) /FACTOR_EFFECT_DIVIDE
    local addNum = RAPlayerEffect:getEffectResult(Const_pb.PLAYER_VIT_MAX_NUM)
    vitMax = vitMax + addNum
    return vitMax
end

-- 自己是否在保护状态中
function RAPlayerInfoManager.IsSelfInProtect()
    local RAPlayerEffect = RARequire('RAPlayerEffect')
    local _, endTime = RAPlayerEffect:getEffectTime(Const_pb.CITY_SHIELD)
    local common = RARequire('common')
    return endTime and endTime > common:getCurMilliTime()
end

function RAPlayerInfoManager.isNewerInProtect()

    if RAPlayerInfoManager.IsSelfInProtect() then 
        local RAPlayerEffect = RARequire('RAPlayerEffect')
        local value = RAPlayerEffect:getEffectResult(Const_pb.CITY_SHIELD)

        if value == 2 then 
            return true
        end 
    end 

    return false
end

-- 是否是大总统
function RAPlayerInfoManager.IsPresident()
    local RAPresidentDataManager = RARequire('RAPresidentDataManager')
    return RAPresidentDataManager:IsPresident(RAPlayerInfo.raPlayerBasicInfo.playerId)
end

-- 是否是临时大总统
function RAPlayerInfoManager.IsTmpPresident()
    local RAPresidentDataManager = RARequire('RAPresidentDataManager')
    return RAPresidentDataManager:IsTmpPresident(RAPlayerInfo.raPlayerBasicInfo.playerId)
end

function RAPlayerInfoManager.UpdateServerTime(delta)
    RAPlayerInfoManager.serverTime = RAPlayerInfoManager.serverTime + delta
end

function RAPlayerInfoManager.SyncAttrInfo(info)
    if info:HasField('gold') then
        RAPlayerInfo.raPlayerBasicInfo.gold = info.gold
    end

    if info:HasField('coin') then
        RAPlayerInfo.raPlayerBasicInfo.coin = info.coin
    end

    if info:HasField('electric') and info:HasField('electricMax') then
        RAPlayerInfo:setElectric(info.electric,info.electricMax)
    else
        if info:HasField('electric') then 
            RAPlayerInfo:setElectric(info.electric)   
        elseif info:HasField('electricMax') then 
            RAPlayerInfo:setElectric(nil,info.electricMax)  
        end
    end 

    if info:HasField('goldore') then
        RAPlayerInfo.raPlayerBasicInfo.goldore = info.goldore
    end

    if info:HasField('oil') then
        RAPlayerInfo.raPlayerBasicInfo.oil = info.oil
    end

    if info:HasField('steel') then
        RAPlayerInfo.raPlayerBasicInfo.steel = info.steel
    end

    if info:HasField('tombarthite') then
        RAPlayerInfo.raPlayerBasicInfo.tombarthite = info.tombarthite
    end

    if info:HasField('level') then
        RAPlayerInfo.raPlayerBasicInfo.level = info.level
    end
    
    if info:HasField('exp') then
        RAPlayerInfo.raPlayerBasicInfo.exp = info.exp
    end

    if info:HasField('vipLevel') then
        RAPlayerInfo.raPlayerBasicInfo.vipLevel = info.vipLevel
    end

    if info:HasField('vit') then
        RAPlayerInfo.raPlayerBasicInfo.power = info.vit
    end

    MessageManager.sendMessage(MessageDef_MainUI.MSG_UpdateBasicPlayerInfo)
end

function RAPlayerInfoManager.SyncAttrInfoFromReward(info)

    if info:HasField('vipPoint') then
        RAPlayerInfo.raPlayerBasicInfo.vipPoints = info.vipPoint
    end

    if info:HasField('vipEndTime') then
        RAPlayerInfo.raPlayerBasicInfo.vipEndTime = info.vipEndTime
    end

    if info:HasField('vipLevel') then
        RAPlayerInfo.raPlayerBasicInfo.vipLevel = info.vipLevel
    end

    RAPlayerInfoManager.SyncAttrInfo(info)
end

--鏍规嵁Id淇敼璧勬簮鏁伴噺
function RAPlayerInfoManager.addResCount(resId, addCount)
    if resId == Const_pb.GOLD then
        RAPlayerInfo.raPlayerBasicInfo.gold = RAPlayerInfo.raPlayerBasicInfo.gold + addCount
    elseif resId == Const_pb.COIN then
        RAPlayerInfo.raPlayerBasicInfo.coin = RAPlayerInfo.raPlayerBasicInfo.coin + addCount
    elseif resId == Const_pb.LEVEL then
        RAPlayerInfo.raPlayerBasicInfo.level = RAPlayerInfo.raPlayerBasicInfo.level + addCount
    elseif resId == Const_pb.EXP then
        RAPlayerInfo.raPlayerBasicInfo.exp = RAPlayerInfo.raPlayerBasicInfo.exp + addCount
    elseif resId == Const_pb.VIP_POINT then
        RAPlayerInfo.raPlayerBasicInfo.vipPoints = RAPlayerInfo.raPlayerBasicInfo.vipPoints + addCount
    elseif resId == Const_pb.ELECTRIC then
        RAPlayerInfo:setElectric(RAPlayerInfo.raPlayerBasicInfo.electric + addCount)
    elseif resId == Const_pb.OIL then
        RAPlayerInfo.raPlayerBasicInfo.oil = RAPlayerInfo.raPlayerBasicInfo.oil + addCount
    elseif resId ==  Const_pb.STEEL then
        RAPlayerInfo.raPlayerBasicInfo.steel = RAPlayerInfo.raPlayerBasicInfo.steel + addCount
    elseif resId ==  Const_pb.TOMBARTHITE then
        RAPlayerInfo.raPlayerBasicInfo.tombarthite = RAPlayerInfo.raPlayerBasicInfo.tombarthite + addCount 
    elseif resId == Const_pb.VIT then
        RAPlayerInfo.raPlayerBasicInfo.power = RAPlayerInfo.raPlayerBasicInfo.power + addCount
    elseif resId == Const_pb.GOLDORE then
        RAPlayerInfo.raPlayerBasicInfo.goldore = RAPlayerInfo.raPlayerBasicInfo.goldore + addCount
    end

    MessageManager.sendMessage(MessageDef_MainUI.MSG_UpdateBasicPlayerInfo)
end
--鏍规嵁璧勬簮id鑾峰緱璧勬簮鏁伴噺
function RAPlayerInfoManager.getResCountById(resId)
    assert(resId~=nil)
    resId = tonumber(resId)
    local count = 0
    if resId == Const_pb.GOLD then
        count = RAPlayerInfo.raPlayerBasicInfo.gold
    elseif resId == Const_pb.COIN then
        count = RAPlayerInfo.raPlayerBasicInfo.coin
    elseif resId == Const_pb.LEVEL then
        count = RAPlayerInfo.raPlayerBasicInfo.level
    elseif resId == Const_pb.EXP then
        count = RAPlayerInfo.raPlayerBasicInfo.exp
    elseif resId == Const_pb.VIP_POINT then
        count = RAPlayerInfo.raPlayerBasicInfo.vipPoints
    elseif resId == Const_pb.ELECTRIC then
        count = RAPlayerInfoManager.getCurrElectricValue()
    elseif resId == Const_pb.ELECTRIC_MAX then
        count = RAPlayerInfoManager.getCurrElectricMaxValue()
    elseif resId == Const_pb.OIL then
        count = RAPlayerInfo.raPlayerBasicInfo.oil
    elseif resId ==  Const_pb.STEEL then
        count = RAPlayerInfo.raPlayerBasicInfo.steel
    elseif resId ==  Const_pb.TOMBARTHITE then
        count = RAPlayerInfo.raPlayerBasicInfo.tombarthite
    elseif resId == Const_pb.VIT then
        count = RAPlayerInfo.raPlayerBasicInfo.power
    elseif resId == Const_pb.GOLDORE then
        count = RAPlayerInfo.raPlayerBasicInfo.goldore
    end
    return count
end

function RAPlayerInfoManager.getKingdomName(k)
    k = k or RAPlayerInfo.raWorldInfo.kingdomId
    local RAWorldUtil = RARequire('RAWorldUtil')
    return RAWorldUtil.kingdomId.tostring(k)
end

function RAPlayerInfoManager.setServerOpenTime(time)
    RAPlayerInfoManager.mOpenServerTime = time
end

function RAPlayerInfoManager.getServerOpenTime()
    return RAPlayerInfoManager.mOpenServerTime
end

--------------------------------------------------------------------------------------
-- region: WorldInfo

function RAPlayerInfoManager.getWorldInfo()
    return RAPlayerInfo.raWorldInfo or {}
end

function RAPlayerInfoManager.getWorldPos()
    return RAPlayerInfo.raWorldInfo.worldCoord
end

function RAPlayerInfoManager.setWorldPos(x, y)
    RAPlayerInfo.raWorldInfo.worldCoord = RACcp(x, y)
end

-- @param serverId: string like 's1', 's2' ...
function RAPlayerInfoManager.setKingdomId(serverId)
    local RAWorldUtil = RARequire('RAWorldUtil')
    RAPlayerInfo.raWorldInfo.serverId = serverId
    RAPlayerInfo.raWorldInfo.kingdomId = RAWorldUtil.kingdomId.tonumber(serverId)
    return RAPlayerInfo.raWorldInfo.kingdomId
end

function RAPlayerInfoManager.getKingdomId()
    return RAPlayerInfo.raWorldInfo.kingdomId
end

function RAPlayerInfoManager.isCityRecreated()
    return RAPlayerInfo.raWorldInfo.isCityRecreated
end

function RAPlayerInfoManager.setCityRecreated(isCityRecreated)
    RAPlayerInfo.raWorldInfo.isCityRecreated = isCityRecreated
end

--根据玩家自己大本等级，获取资源是否开启
function RAPlayerInfoManager.getSelfIsOpenResByType(resType)
    --资源按大本等级显示
    local world_map_const_conf = RARequire("world_map_const_conf")
    local RABuildManager = RARequire("RABuildManager")
    local RAStringUtil = RARequire('RAStringUtil')
    local stepCityLevel2 = world_map_const_conf["stepCityLevel2"]
    local arr = RAStringUtil:split(stepCityLevel2.value,"_") 
    --获取大本的等级
    local cityLevel = RABuildManager:getMainCityLvl()
    local arr1 = tonumber(arr[1])
    local arr2 = tonumber(arr[2])
    if resType == Const_pb.STEEL then
        if cityLevel >= arr1 then
            return true, arr1
        end
        return false, arr1
    end

    if resType == Const_pb.TOMBARTHITE then
        if cityLevel >= arr2 then
            return true, arr2
        end
        return false, arr2
    end

    if resType == Const_pb.OIL or resType == Const_pb.GOLDORE then
        return true, 0
    end
    return false, 0
end

-- endregion: WorldInfo
--------------------------------------------------------------------------------------

function RAPlayerInfoManager:reset()
    RAPlayerInfo:reset()
end

return RAPlayerInfoManager