--医院管理文件
--by sunyungao

local RANetUtil      = RARequire("RANetUtil")
local RAHospitalData = RARequire("RAHospitalData")
local RACoreDataManager   = RARequire("RACoreDataManager")
local RAResManager = RARequire("RAResManager")
local RAPlayerInfoManager = RARequire("RAPlayerInfoManager")
local RALogicUtil = RARequire("RALogicUtil")
local battle_soldier_conf = RARequire("battle_soldier_conf")
local Army_pb  = RARequire("Army_pb")
local Const_pb = RARequire("Const_pb")

local RAHospitalManager = 
{
	mPanelCellVec = {}
}

--重置数据
function RAHospitalManager:resetData()
	-- body
	self.mPanelCellVec = {}
end

function RAHospitalManager:reset()
    -- body
    self:resetData()
end

--获取治疗/待治疗中部队的数量
function RAHospitalManager:getCuringAndWoundedCount()
    -- body
    local curingCount, woundedCount = 0,0
    for k,v in pairs(RACoreDataManager.ArmyWoundedInfo) do
        --print(k,v)
        if v.woundedCount and v.woundedCount > 0 then
            woundedCount = woundedCount + tonumber(v.woundedCount)
        end
    end

    for k,v in pairs(RACoreDataManager.ArmyCuringInfo) do
        --print(k,v)
        if v.cureCount and v.cureCount > 0 then
            curingCount = curingCount + tonumber(v.cureCount)
        end
    end

    return curingCount, woundedCount
end


--获取四种资源的消耗
function RAHospitalManager:getResourceNums()
    -- body
    local needGoldNum, needOilNum, needSteelNum, needRareEarthsNum = 0,0,0,0
    for k,v in pairs(self.mPanelCellVec) do
        --print(k,v)
        needGoldNum = needGoldNum + tonumber(v["needGoldNum"])
        needOilNum = needOilNum + tonumber(v["needOilNum"])
        needSteelNum = needSteelNum + tonumber(v["needSteelNum"])
        needRareEarthsNum = needRareEarthsNum + tonumber(v["needRareEarthsNum"])
    end

    -- needGoldNum = RALogicUtil:num2k(needGoldNum)
    -- needOilNum  = RALogicUtil:num2k(needOilNum)
    -- needSteelNum      = RALogicUtil:num2k(needSteelNum)
    -- needRareEarthsNum = RALogicUtil:num2k(needRareEarthsNum)
    return needGoldNum, needOilNum, needSteelNum, needRareEarthsNum
end

--获取消耗的钻石
function RAHospitalManager:getNeedDiamond()
    -- body
    -- local needDiamondsNum = 0
    -- for k,v in pairs(self.mPanelCellVec) do
    --     --print(k,v)
    --     needDiamondsNum = needDiamondsNum + tonumber(v["needDiamondsNum"])
    -- end

    --需求条件判断 不包括资源不足的情况
    local isCanHeal = true
    local actualTotalTime = self:getNeedTime()
    local totalCostDiamd = RALogicUtil:time2Gold(actualTotalTime)
    local playerDiamond = RAPlayerInfoManager.getResCountById(Const_pb.GOLD)

    --资源不足时判断玩家钻石是否满足

    local needGoldNum = 0
    local needOilNum = 0
    local needSteelNum = 0
    local needRareEarthsNum = 0

    for k,v in pairs(self.mPanelCellVec) do
        local enough,gold
        if v.needGoldNum > 0 then

            needGoldNum = needGoldNum + v.needGoldNum
        end
        if v.needOilNum > 0 then
            needOilNum = needOilNum + v.needOilNum
        end
        if v.needSteelNum > 0 then
            needSteelNum = needSteelNum + v.needSteelNum
        end    
        if v.needRareEarthsNum > 0 then
            needRareEarthsNum = needRareEarthsNum + v.needRareEarthsNum
        end    
    end

    local enough1,gold1 = RALogicUtil:hasEnoughRes(Const_pb.GOLDORE,needGoldNum)
    local enough2,gold2 = RALogicUtil:hasEnoughRes(Const_pb.OIL,needOilNum)
    local enough3,gold3 = RALogicUtil:hasEnoughRes(Const_pb.STEEL,needSteelNum)
    local enough4,gold4 = RALogicUtil:hasEnoughRes(Const_pb.TOMBARTHITE,needRareEarthsNum)

    totalCostDiamd = totalCostDiamd + gold1 + gold2 + gold3 + gold4
    isCanHeal = playerDiamond>=totalCostDiamd and true or false

    return totalCostDiamd,isCanHeal
end

--获取需要的时间
function RAHospitalManager:getNeedTime()
    -- body
    local actualTime = 0
    for k,v in pairs(self.mPanelCellVec) do
        --print(k,v)
        actualTime = actualTime + tonumber(v["actualTime"])
    end

    return actualTime
end

--计算消耗 四种资源 钻石 时间
function RAHospitalManager:calculateConsume(uuid, sliderValue)
    -- body
    local mArmyId = RACoreDataManager.ArmyWoundedInfo[uuid].armyId
    local mArmyCount = sliderValue
    local costMap = RAHospitalManager:calcResCostByArmyIdAndCount(mArmyId, mArmyCount)
    local oriTime, actualTime = RAHospitalManager:calcTimeCostByArmyIdAndCount(mArmyId, mArmyCount)
    local hasEnoughDiamd, totalCostDiamd = RAHospitalManager:isCanOneKeyUpgrade(actualTime, costMap)

    local propMap = {}
    propMap["needGoldNum"]       = costMap[tostring(Const_pb.GOLDORE)] or 0 
    propMap["needOilNum"]        = costMap[tostring(Const_pb.OIL)] or 0 
    propMap["needSteelNum"]      = costMap[tostring(Const_pb.STEEL)] or 0
    propMap["needRareEarthsNum"] = costMap[tostring(Const_pb.TOMBARTHITE)] or 0 

    propMap["wantHealNum"]       = mArmyCount
    propMap["needDiamondsNum"]   = totalCostDiamd

    propMap["actualTime"]     = actualTime
    propMap["originalTime"]   = oriTime
    propMap["hasEnoughDiamd"] = hasEnoughDiamd

    propMap["armyId"] = mArmyId

    self.mPanelCellVec[uuid] = propMap
end

--刷新消耗显示，每次移动滑动块都要刷新
function RAHospitalManager:sendRefreshConsumeMsg()
    -- body
    MessageManager.sendMessage(MessageDefine_Hospital.MSG_refresh_consume, {})
end

function RAHospitalManager:getSelectedArmyElectricConsume()
    local id2Count = {}
    for k,v in pairs(self.mPanelCellVec) do
        --print(k,v)
        local count = tonumber(v["wantHealNum"])
        local armyId = tonumber(v["armyId"])
        local oldCount = id2Count[armyId] or 0
        id2Count[armyId] = oldCount + count
    end
    local consume = RAPlayerInfoManager.getArmyElectricConsume(id2Count)
    return consume
end

--------------------------------------------------------------
-----------------------协议发送-------------------------------
--------------------------------------------------------------
--向服务器发送治疗的协议
function RAHospitalManager:sendTreatmentProto(isImmediate, buildUUID)
    -- body
    local cmd = Army_pb.HPCureSoldierReq()
    for k,v in pairs(self.mPanelCellVec) do
        --print(k,v)
        local num = tonumber(v["wantHealNum"])
        if 0 ~= num then
            local cmd2 = cmd.soldiers:add()
            cmd2.armyId = tonumber(v["armyId"])
            cmd2.count = num
        end
    end

    cmd.isImmediate  = isImmediate
    cmd.gold         = RAHospitalManager:getNeedDiamond()
    cmd.buildingUUID = buildUUID
    RANetUtil:sendPacket(HP_pb.CURE_SOLDIER_C, cmd, {retOpcode = -1})
end

--是否有滑块选中的伤兵
function RAHospitalManager:hasSelectedSoldiersToCure()
    -- body
    local hasS = false
    for k,v in pairs(self.mPanelCellVec) do
        --print(k,v)
        local num = tonumber(v["wantHealNum"])
        if 0 ~= num then
            hasS = true
            break
        end
    end

    return hasS
end

--------------------------------------------------------------
-----------------------计算公式-------------------------------
--------------------------------------------------------------

function RAHospitalManager:currResTreatmentArmyCount(aCostMap)
    -- body
    local treatmentNum = 0

    for itemId,itemCount in pairs(aCostMap) do
        itemId = tonumber(itemId)
        itemCount = tonumber(itemCount)
        local currNumValue = RAPlayerInfoManager.getResCountById(itemId)
        local needGoldNum, needOilNum, needSteelNum, needRareEarthsNum = self:getResourceNums()

        if itemId == Const_pb.GOLDORE then
            currNumValue = currNumValue - needGoldNum
        elseif itemId == Const_pb.OIL then
            currNumValue = currNumValue - needOilNum
        elseif itemId == Const_pb.STEEL then
            currNumValue = currNumValue - needSteelNum
        elseif itemId == Const_pb.TOMBARTHITE then
            currNumValue = currNumValue - needRareEarthsNum
        end

        local count = math.floor(currNumValue / itemCount)

        --如果有一种资源一点不剩，那么直接 break
        if count <= 0 then
            treatmentNum = 0
            break
        end

        if treatmentNum <= 0 then
            treatmentNum = count

        end
        if count < treatmentNum then
            treatmentNum = count
        end
    end

    return treatmentNum
end

--根据士兵id和数量计算资源消耗
function RAHospitalManager:calcResCostByArmyIdAndCount(armyId, count)
    --body
    local armyCostRes = RAResManager:getResInfosByStr(battle_soldier_conf[armyId].recoverRes)
    local costMap = {}
    for i =1,#armyCostRes do 
        local oneRes = armyCostRes[i]
        local itemId = oneRes.itemId 
        local costCount = count * oneRes.itemCount
        costMap[itemId] = costCount
    end
    return costMap
end

--计算使用的时间
function RAHospitalManager:calcTimeCostByArmyIdAndCount(armyId, count)
    --body
    local oneArmyTimeCost =  battle_soldier_conf[armyId].recoverTime
    local basicTimeCost = oneArmyTimeCost * count 
    local armyType = battle_soldier_conf[armyId].type
    --effect map for each type army
    local effectMap = 
    {
        [1] = Const_pb.CITY_SPD_FOOT,
        [2] = Const_pb.CITY_SPD_TANK,
        [3] = Const_pb.CITY_SPD_PLANE,
        [4] = Const_pb.CITY_SPD_CANNON
    }
    local allTrainBuff = RALogicUtil:getEffectResult(Const_pb.CITY_HURT_CRUT_SPD) / FACTOR_EFFECT_DIVIDE
    -- local eachArmyBuff = RALogicUtil:getEffectResult(effectMap[armyType]) / FACTOR_EFFECT_DIVIDE
    local finalCostTime = basicTimeCost / (1 + allTrainBuff) 

    local const_conf = RARequire("const_conf")
    local electric1 = 1+const_conf.electric_decrease1.value/100
    local electric2 = 1+const_conf.electric_decrease2.value/100
    --电力影响
    local electricBuff = RAPlayerInfoManager.getCurrElectricEffect()
    if electricBuff == electric1 then
        finalCostTime = finalCostTime + finalCostTime * const_conf.electric_decrease1.value/100
    elseif electricBuff == electric2 then
        finalCostTime = finalCostTime + finalCostTime * const_conf.electric_decrease2.value/100
    end

    return basicTimeCost, math.ceil(finalCostTime)
end

function RAHospitalManager:isCanOneKeyUpgrade(actualTime, costMap)

    local timeCostDimand = RALogicUtil:time2Gold(actualTime)

    --需求条件判断 不包括资源不足的情况
    local isCanHeal = true
    local totalCostDiamd = 0
    local playerDiamond = RAPlayerInfoManager.getResCountById(Const_pb.GOLD)

    --资源不足时判断玩家钻石是否满足
    if isCanHeal then
        
        local resCostDiamond = 0
        for k,v in pairs(costMap) do
            local resId = k
            local resCount = v
            local enough,gold = RALogicUtil:hasEnoughRes(resId,resCount)
            resCostDiamond = resCostDiamond+gold
        end

        totalCostDiamd = timeCostDimand + resCostDiamond
        isCanHeal = playerDiamond>=totalCostDiamd and true or false
    end
    
    return isCanHeal,totalCostDiamd,timeCostDimand,resCostDiamond
end

--伤病按照battle_soldier_conf表 先level排序：等级高的在上面; 后type排序：type值低的在上面
function RAHospitalManager:ArmySort(data)
    -- body
    table.sort( data, function (v1,v2)
        local data1 = battle_soldier_conf[v1.armyId]
        local data2 = battle_soldier_conf[v2.armyId]

        if data1.level > data2.level then
            return true  
        elseif data1.level < data2.level then
            return false          
        elseif data1.type > data2.type then
            return true      
        end
        return false      
    end)

    return data
end

return RAHospitalManager