local RAPlayerInfoManager = RARequire("RAPlayerInfoManager")
local player_talent_conf = RARequire("player_talent_conf")
local Utilitys = RARequire("Utilitys")
local RAGameConfig = RARequire("RAGameConfig")
local RAPlayerEffect = RARequire("RAPlayerEffect")

local RATalentManager = {}

package.loaded[...] = RATalentManager

RATalentManager.CurrTurnOnType = 0--当前开启的天赋路线类型，0，1，2，。。。
--获得该等级下最大技能点数
function RATalentManager.getTotalGeneralNum()
    local playerLev = RAPlayerInfoManager.getPlayerBasicInfo().level
    local key = RAGameConfig.ConfigIDFragment.ID_PLAYER_LEVEL + playerLev - 1
    local player_level_conf = RARequire("player_level_conf")
    local point = player_level_conf[key].skillPoint--根据等级读表获得
    return point
end

function RATalentManager.getUseGeneralNumByType(talentRouteType)
    --根据talentType获得该type所使用的天赋点
    local playerInfo = RAPlayerInfoManager.getPlayerInfo()
    local useNum = 0
    local turnOnTalentInfos = playerInfo.raTalentInfo[talentRouteType +1]--数组下标从1开始，但是类型是从0开始

    if turnOnTalentInfos then
        for key, value in Utilitys.table_pairsByKeys(turnOnTalentInfos) do
            useNum = useNum + value.level
        end
    end
    
    return useNum
end

--desc:获得剩余的技能点
function RATalentManager.getFreeGeneralNum(talentRouteType)
    local totalPoint = RATalentManager.getTotalGeneralNum()
    local usePoint = RATalentManager.getUseGeneralNumByType(talentRouteType)
    return totalPoint - usePoint
end

--设置天赋基本信息
function RATalentManager.setTalentInfo(msg)
    --raTalentInfo的key是天赋路线类型
    local playerInfo = RAPlayerInfoManager.getPlayerInfo()
    RATalentManager.CurrTurnOnType = msg["type"]
    for i = 1, #msg.talentInfos do
        local talentInfo = msg.talentInfos[i]
        local typeIndex = talentInfo["type"] +1--天赋路线类型
        if playerInfo.raTalentInfo[typeIndex] == nil then
            playerInfo.raTalentInfo[typeIndex] = {}
        end
        playerInfo.raTalentInfo[typeIndex][talentInfo.talentId] = {}
        playerInfo.raTalentInfo[typeIndex][talentInfo.talentId].talentId = talentInfo.talentId
        playerInfo.raTalentInfo[typeIndex][talentInfo.talentId].level = talentInfo.level
        playerInfo.raTalentInfo[typeIndex][talentInfo.talentId]["type"] = talentInfo["type"]
        --设置作用号
        if talentInfo["type"] == RATalentManager.CurrTurnOnType then
            RATalentManager.setTalentEffect(talentInfo.talentId, talentInfo.level)
        end
    end
end

--设置天赋的作用号,游戏初始时调用
function RATalentManager.setTalentEffect(talentId, level)
    local constTalentInfo = player_talent_conf[talentId]
    if constTalentInfo then
        local effect = constTalentInfo.effect
        local value = constTalentInfo.value
        local numType = constTalentInfo.numType

        local valueArray = Utilitys.Split(value, "_")
        local effectValue = 0
        if valueArray[level] ~= nil then
            effectValue = tonumber(valueArray[level])
        end

        if numType == 1 then
            effectValue = effectValue * 0.0001
        end
        RAPlayerEffect:addEffectTalent(tonumber(effect),effectValue)
    end
end

--天赋升级时调用，用来增加作用号数值
function RATalentManager.addTalentEffect(talentId, preLevel, currLevel)
    local constTalentInfo = player_talent_conf[talentId]
    if constTalentInfo then
        local effect = constTalentInfo.effect
        local value = constTalentInfo.value
        local numType = constTalentInfo.numType

        local valueArray = Utilitys.Split(value, "_")
        local addEffectValue = 0

        if valueArray[currLevel] then
            local currentEffectVal = tonumber(valueArray[currLevel])
            local preEffectVal = 0
            if valueArray[preLevel] then
                preEffectVal = tonumber(valueArray[preLevel])
            end
            addEffectValue = currentEffectVal - preEffectVal
        end

        if numType == 1 then
            addEffectValue = addEffectValue * 0.01--天赋表配置的值除以10000才是真实值，但是很多其他系统是除以100，为了匹配使用者，这里会除以100后保存
        end
        RAPlayerEffect:addEffectTalent(tonumber(effect),addEffectValue)
    end
end

function RATalentManager.setTalentLevel(talentRouteType, talentId, talentLevel)
    local playerInfo = RAPlayerInfoManager.getPlayerInfo()
    local talentInfos = playerInfo.raTalentInfo[talentRouteType + 1]
    if talentInfos then
        if talentInfos[talentId] == nil then
            talentInfos[talentId] = {}
            talentInfos[talentId].talentId = talentId
            talentInfos[talentId].level = talentLevel
            talentInfos[talentId]["type"] = talentRouteType
        else
            talentInfos[talentId].level = talentLevel
        end
    else
        playerInfo.raTalentInfo[talentRouteType + 1] = {}
        playerInfo.raTalentInfo[talentRouteType + 1][talentId] = {}
        playerInfo.raTalentInfo[talentRouteType + 1][talentId].talentId = talentId
        playerInfo.raTalentInfo[talentRouteType + 1][talentId].level = talentLevel
        playerInfo.raTalentInfo[talentRouteType + 1][talentId]["type"] = talentRouteType
    end
end

function RATalentManager.getTalentInfoByType(talentRouteType)
    local playerInfo = RAPlayerInfoManager.getPlayerInfo()
    return playerInfo.raTalentInfo[talentRouteType + 1]
end

function RATalentManager.resetData()
    local playerInfo = RAPlayerInfoManager.getPlayerInfo()
    playerInfo.raTalentInfo = {}
end

function RATalentManager:reset(talentRouteType)
    local playerInfo = RAPlayerInfoManager.getPlayerInfo()
    if talentRouteType == nil then
        playerInfo.raTalentInfo = {}
    else
        playerInfo.raTalentInfo[talentRouteType + 1] = nil
    end
end

function RATalentManager.isTalentLock(talentRouteType, talentId)
    local constTalentInfo = player_talent_conf[talentId]
    local serverTalentsInfo = RATalentManager.getTalentInfoByType(talentRouteType)
    local isLock = false

    if constTalentInfo == nil then
        CCLuaLog("The talentId is not in the conf")
        isLock = true
    else
        if constTalentInfo.frontTalent == nil or constTalentInfo.frontTalent == "" then
            isLock = false
        else
            local frontTalents = {}
            frontTalents = Utilitys.Split(constTalentInfo.frontTalent, ",")

            for i = 1, #frontTalents do
                frontTalent = frontTalents[i]
                frontTalentArr = Utilitys.Split(frontTalent, "_")
                local frontTalentId = tonumber(frontTalentArr[1])
                local frontTalentLevel = tonumber(frontTalentArr[2]) 
                if serverTalentsInfo == nil or serverTalentsInfo[frontTalentId] == nil or (serverTalentsInfo[frontTalentId] ~= nil and serverTalentsInfo[frontTalentId].level < frontTalentLevel) then
                    isLock = true
                end
            end
        end
    end
    
    return isLock



--    if serverTalentsInfo == nil then
--        isLock = true
--    else
--        if serverTalentsInfo[talenId] ~= nil then
--            local talentInfo = serverTalentsInfo[talenId]

--            if talentInfo.level >= 0 then
--                isLock = false
--            end
--        else
--            if constTalentInfo ~= nil then
--                local frontTalents = {}
--                if constTalentInfo.frontTalent ~= nil then
--                    frontTalents = Utilitys.Split(constTalentInfo.frontTalent, ",")
--                    for i = 1, #frontTalents do
--                        frontTalent = frontTalents[i]
--                        frontTalentArr = Utilitys.Split(frontTalent, "_")
--                        local frontTalentId = tonumber(frontTalentArr[1])
--                        local frontTalentLevel = tonumber(frontTalentArr[2]) 
--                        if serverTalentsInfo[frontTalentId] == nil or (serverTalentsInfo[frontTalentId] ~= nil and serverTalentsInfo[frontTalentId].level < frontTalentLevel) then
--                            isLock = true
--                        end
--                    end
--                else
--                    isLock = false
--                end
--            else 
--                isLock = true
--            end
--        end
--    end

--    return isLock
end

--获得天赋作用号数值，不带符号,比如2，4
function RATalentManager.getTalentEffectCount(talentId, level)
    local constTalentInfo = player_talent_conf[talentId]
    if constTalentInfo then
        local valueStr = constTalentInfo.value
        if valueStr then
            local valueArray = Utilitys.Split(valueStr, "_")
            if valueArray[level] then
                return tonumber(valueArray[level])
            else
                return 0
            end
        else 
            return 0
        end
    else 
        return 0
    end

    return 0
end

--获得天赋作用号数值，带符号， 比如0.02， 0.04，2，4
function RATalentManager.getTalentEffectCountWithSymble(talentId, level)
    local constTalentInfo = player_talent_conf[talentId]
    if constTalentInfo then
        local valueStr = constTalentInfo.value
        if valueStr then
            local valueArray = Utilitys.Split(valueStr, "_")
            if valueArray[level] then
                if constTalentInfo.numType == 1 then
                    return (tonumber(valueArray[level]) * 0.01)
                end
                return tonumber(valueArray[level])
            else
                return 0
            end
        else 
            return 0
        end
    else 
        return 0
    end

    return 0
end

--获得天赋作用号数值，带符号， 比如2%， 4%, string
function RATalentManager.getTalentEffectStrWithSymble(talentId, level)
    local constTalentInfo = player_talent_conf[talentId]
    if constTalentInfo then
        local valueStr = constTalentInfo.value
        if valueStr then
            local valueArray = Utilitys.Split(valueStr, "_")
            if valueArray[level] then
                if constTalentInfo.numType == 1 then
                    local value = tonumber(valueArray[level]) / 100
                    return (value .. "%")
                end
                return valueArray[level]
            else
                return "0%"
            end
        else 
            return "0%"
        end
    else 
        return "0%"
    end

    return "0%"
end

--desc:天赋路线2是否开放了
function RATalentManager.isTalentRoute2Open()
    local const_conf = RARequire("const_conf")
    return RAPlayerInfoManager.getPlayerLevel() >= const_conf.TalentRouteTurnOnLevel.value
end

--天赋红点
function RATalentManager.getTalentRedPointCount()
    -- body
    local totalTalentPoint = RATalentManager.getTotalGeneralNum()
    local useTalentPoint = RATalentManager.getUseGeneralNumByType(RATalentManager.CurrTurnOnType) --首先显示的是当前启用的路线
    local freeTalentPoint = totalTalentPoint - useTalentPoint

    return freeTalentPoint
end