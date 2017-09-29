--region RAArsenalManager.lua
--Date
--此文件由[BabeLua]插件自动生成
local RAArsenalManager = {}
local build_conf = RARequire("build_conf")
local battle_soldier_conf = RARequire("battle_soldier_conf")
local RALogicUtil = RARequire("RALogicUtil")
local Const_pb = RARequire("Const_pb")
local RAResManager = RARequire("RAResManager")
local RAPlayerInfoManager = RARequire("RAPlayerInfoManager")
local RAQueueManager = RARequire("RAQueueManager")
local RAArsenalConfig = RARequire("RAArsenalConfig")
local common = RARequire("common")
RAArsenalManager.AllArmyCatogory = {}
RAArsenalManager.clickCollect = false
--记录点击收兵时间间隔
local lastTime = 0

function RAArsenalManager:getAllArmyCatatory()
    if common:table_count(RAArsenalManager.AllArmyCatogory) > 0 then
        return RAArsenalManager.AllArmyCatogory
    else
        RAArsenalManager.AllArmyCatogory = { --每个大类型的兵种包含的小兵种
            [1]= RAArsenalManager:getArmyIdsByBuildId(RAArsenalConfig.Build2011 * 100 +1),
            [2] =RAArsenalManager:getArmyIdsByBuildId(RAArsenalConfig.Build2012* 100 +1),
            [3] =RAArsenalManager:getArmyIdsByBuildId(RAArsenalConfig.Build2013* 100 +1),
            [4] =RAArsenalManager:getArmyIdsByBuildId(RAArsenalConfig.Build2014* 100 +1),
        }
        return RAArsenalManager.AllArmyCatogory
    end
end

function RAArsenalManager:getArmyIdsByBuildId(buildID)
    local trainSoldier = build_conf[buildID].trainSoldier
    assert(trainSoldier~= nil , "trainSoldier~= nil")
    if trainSoldier ~= nil then
        local RAStringUtil = RARequire("RAStringUtil")
        local vec = RAStringUtil:split(trainSoldier,"_")
        return vec
    end
    return nil
end

function RAArsenalManager:calcMaxTrainNum(armyId,buildTypeId)
    --step.1 calc max count based on building

    local RABuildManager = RARequire("RABuildManager")
    local basicTrainNum = 0
    local buildData = RABuildManager:getBuildDataArray(buildTypeId)
    if buildData[1] == nil then
        local const_conf = RARequire('const_conf') 
        local newTrainQuantity = const_conf.newTrainQuantity.value
        return newTrainQuantity,newTrainQuantity 
    end
    --local basicTrainNum = 0
    -- for k,oneBuildData in pairs(buildData) do
    --     local t= oneBuildData.confData.trainQuantity
    --     if t>basicTrainNum then
    --         basicTrainNum = t
    --     end 
    --     -- basicTrainNum = basicTrainNum + oneBuildData.confData.trainQuantity
    -- end

    local basicTrainNum = buildData[1].confData.trainQuantity
    local buffPersent = 0 / FACTOR_EFFECT_DIVIDE -- 百分比作用值

    local countBuff = RALogicUtil:getEffectResult(Const_pb.CITY_ARMY_TRAIN_NUM) --数值作用值
    local buildMaxNum = basicTrainNum * (1 + buffPersent) + countBuff

    --step.2 calc max count based on the res
    local armyCostRes = RAResManager:getResInfosByStr(battle_soldier_conf[armyId].res)
    local minTrainCount = 1000000000
    for i =1,#armyCostRes,1 do 
        local oneRes = armyCostRes[i]
        local totalHasRes = RAPlayerInfoManager.getResCountById(oneRes.itemId) 
        local oneArmyCost = oneRes.itemCount
        local canTrainCount = math.floor(totalHasRes / oneArmyCost)
        if minTrainCount > canTrainCount then minTrainCount = canTrainCount end
    end
    
    local finalCount = math.min(minTrainCount,buildMaxNum)
    --进入造兵页面，资源什么不足的时候 默认为1 不足的资源颜色显示红色字体
    if finalCount == 0 then
        finalCount = 1
    end
    return finalCount,buildMaxNum
end

function RAArsenalManager:calcResCostByArmyIdAndCount(armyId,count)
    local armyCostRes = RAResManager:getResInfosByStr(battle_soldier_conf[armyId].res)
    local costMap = {}
    for i =1,#armyCostRes,1 do 
        local oneRes = armyCostRes[i]
        local itemId = oneRes.itemId 
        local costCount = count * oneRes.itemCount
        costMap[itemId] = costCount
    end
    return costMap
end

function RAArsenalManager:getArmyCfgById(armyId)
    armyId = tonumber(armyId)
    return battle_soldier_conf[armyId]    
end

function RAArsenalManager:calcTimeCostByArmyIdAndCount(armyId,count,buildTypeId)
    local oneArmyTimeCost =  battle_soldier_conf[armyId].time
    local basicTimeCost = oneArmyTimeCost * count 
    local armyType = battle_soldier_conf[armyId].type
    --effect map for each type army
    local effectMap = {
        [1] = 403,
        [2] = 404,
        [3] = 405,
        [4] = 406
    }

    local basicTrainSpeed = 0
    local RABuildManager = RARequire("RABuildManager")
    local buildData = RABuildManager:getBuildDataByType(buildTypeId)
    if buildData == nil then return 0 end
    for k,oneBuildData in pairs(buildData) do
        basicTrainSpeed = basicTrainSpeed + oneBuildData.confData.trainSpeed
    end

    local trainSpeedBuff = tonumber(basicTrainSpeed)
    local allTrainBuff = RALogicUtil:getEffectResult(Const_pb.CITY_SPD_ALL) / 100
    local eachArmyBuff = RALogicUtil:getEffectResult(effectMap[armyType]) / 100
    local finalCostTime = math.ceil(basicTimeCost / (1 + (allTrainBuff + eachArmyBuff + trainSpeedBuff)/100))


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
    return basicTimeCost,math.ceil(finalCostTime)
end


function RAArsenalManager:isCanOneKeyUpgrade(actualTime,costMap)

	local timeCostDimand = RALogicUtil:time2Gold(actualTime)

	--需求条件判断 不包括资源不足的情况
	local isCanUpgrade = true
	local totalCostDiamd = 0
	local playerDiamond = RAPlayerInfoManager.getResCountById(Const_pb.GOLD)

	--资源不足时判断玩家钻石是否满足
	if isCanUpgrade then
		
		local resCostDiamond = 0
		for k,v in pairs(costMap) do
			local resId = k
			local resCount = v
            local enough,gold = RALogicUtil:hasEnoughRes(resId,resCount)
			resCostDiamond = resCostDiamond+gold
		end

		totalCostDiamd = timeCostDimand + resCostDiamond
		isCanUpgrade = playerDiamond>=totalCostDiamd and true or false
    end
	
	return isCanUpgrade,totalCostDiamd,timeCostDimand,resCostDiamond
end

function RAArsenalManager:hasQueueByBuildId(buildId)
    local pageData = self:getArmyIdsByBuildId(buildId)
     for k,armyId in pairs(pageData) do 
        local hasQueue,QueueData = self:hasQueueByArmyId(armyId)
        if hasQueue then
            return true,QueueData
        end
     end
     return false,nil
end

function RAArsenalManager:hasQueueByArmyId(armyId)
    local queueData = RAQueueManager:getQueueDatas(Const_pb.SOILDER_QUEUE)
    for queueId,queueData in pairs(queueData)  do
        if queueData.itemId == tostring(armyId) then
            return true,queueData
        end
    end
    return false,nil
end


function RAArsenalManager:sendCollectArmyCmd(buildingUUID)
    --避免快速点击
    local nowTime = os.time()
    local diffTime = nowTime - lastTime
    if diffTime < 2 then return end
    lastTime = nowTime
    local RARootManager = RARequire('RARootManager')
    --RARootManager.ShowWaitingPage(true)
    local HP_pb = RARequire("HP_pb")
    local RANetUtil = RARequire("RANetUtil")
    local Army_pb = RARequire("Army_pb")
    local cmd = Army_pb.HPCollectSoldierReq()
    cmd.buildingUUID = buildingUUID
    RANetUtil:sendPacket(HP_pb.COLLECT_SOLDIER_C, cmd)
    RAArsenalManager.clickCollect = true
end



--筛选统计每种大类型的士兵类型，有多少freecount的士兵
function RAArsenalManager:getArmyCatagoryMap()
    local armyCatogoryMap = {}
    local RACoreDataManager = RARequire("RACoreDataManager")
    local RAArsenalConfig = RARequire("RAArsenalConfig")
    for k,fourArmyId in pairs(RAArsenalManager:getAllArmyCatatory()) do 
        local totalNum = 0 
        for i =1,#fourArmyId do 
            local oneArmyId = fourArmyId[i]
            local armyInfo = RACoreDataManager:getArmyInfoByArmyId(tonumber(oneArmyId))
            if armyInfo ~= nil then
                totalNum = armyInfo.freeCount + totalNum
            end
        end
        armyCatogoryMap[k] = totalNum
    end
    return armyCatogoryMap
end

-- 根据传入的士兵id列表，返回大类型列表
function RAArsenalManager:getCatagoryByArmyId(armyId)
    local RAArsenalConfig = RARequire("RAArsenalConfig")

    for k,fourArmyId in pairs(RAArsenalManager:getAllArmyCatatory()) do 
        for i =1,#fourArmyId do 
           if tonumber(fourArmyId[i]) == armyId then
                return k
           end 
        end
    end    
    print("RAArsenalManager:getCatagoryByArmyId  error!! armyId="..armyId.." not defined!")
    return -1
end

-- 根据传入的士兵id列表，返回大类型列表
function RAArsenalManager:getCatagoryMapByArmyIdList(armyIdList)
    if armyIdList == nil then return {} end
    local armyCatogoryMap = {}
    local RACoreDataManager = RARequire("RACoreDataManager")
    local RAArsenalConfig = RARequire("RAArsenalConfig")
    for k,armyId in pairs(armyIdList) do
        local catagoryType = self:getCatagoryByArmyId(armyId)
        if catagoryType ~= -1 then
            local armyTypeCount = armyCatogoryMap[catagoryType]
            if armyTypeCount == nil then
                armyCatogoryMap[catagoryType] = 1
            else
                armyCatogoryMap[catagoryType] = armyTypeCount + 1
            end
        end
    end    
    return armyCatogoryMap
end



--根据士兵的数量，对集结点的每一堆士兵做排列处理
function RAArsenalManager:arrangeArmyTroop()
    local armyCatogoryMap = self:getArmyCatagoryMap()
    local returnMap  = {}
    local RAStringUtil = RARequire('RAStringUtil')
    local const_conf = RARequire("const_conf")
    local oriNumTable = RAStringUtil:parseWithComma(const_conf.newSoldier.value)
    for i=1,24 do 
        for armyType,totalNum in pairs(armyCatogoryMap) do 
            if totalNum~=nil and totalNum > 0 then
                local oneTroopNum = RAArsenalConfig.ArmyTroopTotalNum[armyType]
                local troopLimitNum = self:calcTroopTotalNumByIndex(i)  --3001
                local data = {}
                if troopLimitNum >= totalNum then
                    --如果限制大于总数
                    local displayNum = math.ceil(totalNum / (troopLimitNum/oneTroopNum))

                    --优化点，对于步兵，坦克，远程单位，当公式计算后显示量小于3，且只有一个对应兵种集合点时，实际显示量按3显示
                    if armyType == Const_pb.FOOT_SOLDIER or armyType == Const_pb.TANK_SOLDIER 
                    or armyType == Const_pb.CANNON_SOLDIER  then
                        if displayNum < 3 then
                            displayNum = 3
                        end
                    end
                    
                    data.displayNum = displayNum
                    data.armyType = armyType
                    returnMap[i] = data
                else
                    --如果当前数量超过了 当前堆的数目，减去数量，到下一个
                    local displayNum = oneTroopNum
                    data.displayNum = displayNum
                    data.armyType = armyType
                    returnMap[i] = data
                end 
                --只要某一个堆被放了东西，将当前的armyType置为负数，标记为不需要下一次处理
                remainNum = totalNum - troopLimitNum 
                armyCatogoryMap[armyType] = remainNum
                break
            end
        end
    end

    return returnMap;
    
end

function RAArsenalManager:calcTroopTotalNumByIndex(index)
    local totalNum = RAArsenalConfig.baseGatherNum +  index ^3 
    return totalNum 
end

--判断是否有进阶兵种
--兵营  1
--战车工厂 1
--远程火力工厂 0
--空指部 1
function RAArsenalManager:isHaveSpecailArmy(buildType)
    local isHave = true 
    if buildType==Const_pb.REMOTE_FIRE_FACTORY then
        isHave = false
    end 
    return isHave
end

return RAArsenalManager
--endregion
