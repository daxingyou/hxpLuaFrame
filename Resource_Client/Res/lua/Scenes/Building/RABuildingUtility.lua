RABuildingUtility = {}
local build_conf = RARequire("build_conf")
local Utilitys = RARequire("Utilitys")
local Const_pb = RARequire('Const_pb')
local RAStringUtil = RARequire('RAStringUtil')
local RACoreDataManager = RARequire('RACoreDataManager')
local RAStringUtil = RARequire('RAStringUtil')
local RAPlayerInfoManager = RARequire('RAPlayerInfoManager')

--获得占地位置
function RABuildingUtility.getSortedBuildingAllTilePos(pos,width,length)
    local tilesMap = RABuildingUtility.getBuildingAllTilePos(pos,width,length)

    local tilesTable = {}
    for k,v in pairs(tilesMap) do 
        table.insert(tilesTable,v)
    end
    
    local sortFunc = function (a, b)
        local r
        local aOrder = a.yIndex + a.xIndex
        local bOrder = b.yIndex + b.xIndex
        r = aOrder < bOrder
        return r
    end
    table.sort(tilesTable,sortFunc)
    return tilesTable
end


--获得占地位置
function RABuildingUtility.getBuildingAllTilePos(pos,width,length)
    local posArr = {}
    local orignX = pos.x
    local orignY = pos.y

    for j=1, length do
        local newPos = {}
        newPos.yIndex = j-1 -- 格子的索引
        newPos.y = orignY - (j-1)
        
        if orignY%2 ~= 0 then 
            newPos.x = orignX - math.floor((j-1)/ 2)
        else 
            newPos.x = orignX - math.ceil((j+1) / 2)+1
        end

        RABuildingUtility.getSingleTiles(newPos,width,posArr) 
    end

    return posArr
end

function RABuildingUtility.getTilePosByClickPos(tilePos,clickPos)
end

function RABuildingUtility.getSingleTiles(pos,width,posArr)

    local orignX = pos.x
    local orignY = pos.y

    for j=1,width do
        local newPos = {}
        
        if orignY%2 == 0 then 
            newPos.x = orignX + math.floor((j-1) / 2)
        else 
            newPos.x = orignX + math.ceil((j-1) / 2)
        end 

        newPos.y = orignY - (j-1)
        newPos.yIndex = pos.yIndex
        newPos.xIndex = j-1
        posArr[newPos.x .. "_" .. newPos.y] = newPos
    end
end

function RABuildingUtility.isTrainBuilding(buildType) --是不是训练士兵的建筑
    -- body
    if buildType == Const_pb.BARRACKS or buildType == Const_pb.WAR_FACTORY or buildType == Const_pb.REMOTE_FIRE_FACTORY or buildType == Const_pb.AIR_FORCE_COMMAND then 
        return true
    else 
        return false 
    end 
end

--根据id获取建筑配置信息
function RABuildingUtility.getBuildInfoById(id) 
    return build_conf[id]
end

--根据type获取建筑配置信息以及该建筑的最高的等级
--isSort:是否排序
function RABuildingUtility.getBuildInfoByType(tmptype,isSort) 

    local tb = {}
    local tb_key = {}
    local level = 0
    for k,v in pairs(build_conf) do
        if v.buildType == tmptype then
            level = level + 1
            table.insert(tb_key,k)
        end  
    end
    if isSort then
        table.sort(tb_key)
        for i,v in ipairs(tb_key) do
           table.insert(tb,build_conf[v])
        end
    end 
    
    return tb,level
end

--根据等级获取某建筑的配置信息
function RABuildingUtility:getBuildInfoByLevel(buildType,level)
    local tb=nil
     for k,v in pairs(build_conf) do
        if v.level == level and v.buildType==buildType then
           tb=v
           break
        end  
    end

    return tb
end

function RABuildingUtility.isResourceBuilding(limitType)
    if limitType == Const_pb.LIMIT_TYPE_BUIDING_RESOURCES then 
        return true
    else 
        return false
    end 
end

function RABuildingUtility.isDefenderBuilding(limitType)
    if limitType == Const_pb.LIMIT_TYPE_BUILDING_DEFENDER then 
        return true
    else 
        return false
    end 
end

-- 根据限制类型获取建筑信息 除了资源性建筑和防御性建筑
function RABuildingUtility.getBuildInfoByLimitType(limitType) 
    local buildInfo= {}
    for k,v in pairs(build_conf) do
        if v.limitType == limitType then
          buildInfo = v
          break
        end  
    end
    return buildInfo
end 

function RABuildingUtility.getResBuildInfoByLimitType(limitType) 
    local buildInfo= {}
    for k,v in pairs(build_conf) do
        if v.limitType == limitType and v.level==1 then
          table.insert(buildInfo,v)
        end  
    end
    return buildInfo
end 

--根据id判断该建筑是否能升级 不考虑队列影响和玩家钻石影响
function RABuildingUtility.isCanUpgradeBuild(id, notNeedCost)
    local RABuildManager = RARequire('RABuildManager')
    local RAPlayerInfoManager = RARequire('RAPlayerInfoManager')
    --根据id拿到配置信息
    local buildInfo = RABuildingUtility.getBuildInfoById(id+1)
    if buildInfo == nil then 
        return false 
    end
    local isCanUpgrad = true

    --前置建筑判断
    if buildInfo.frontBuild then
        local frontBuilds = RAStringUtil:split(buildInfo.frontBuild,",")
        for i,v in ipairs(frontBuilds) do
            local frontBuild = tonumber(v)
             if frontBuild then
                local preBuildInfo = RABuildingUtility.getBuildInfoById(frontBuild)
                local isBuildExist = RABuildManager:isBuildingExist(frontBuild,preBuildInfo.buildType)
                if not isBuildExist then
                    return false, preBuildInfo.buildType
                end
            end
        end
    end 

    --前置建筑判断
    local RAScienceManager = RARequire('RAScienceManager')
    if buildInfo.frontScience then
        local frontSciences = RAStringUtil:split(buildInfo.frontScience,",")
        for i,v in ipairs(frontSciences) do
            local frontScience = tonumber(v)
             if frontScience then
                local isScienceExist = RAScienceManager:isResearchFinish(frontScience)
                if not isScienceExist then
                    return false
                end
            end
        end
    end     
   
   

    --资源道具判断
    if buildInfo.buildCost and not notNeedCost then

        local resArr = RAStringUtil:split(buildInfo.buildCost,",")

        local RALogicUtil = RARequire('RALogicUtil')
        for k,v in pairs(resArr) do
            local costInfo = RAStringUtil:split(v,"_")
            local costType = costInfo[1] 
            local costId = costInfo[2] 
            local costNum = costInfo[3] 

            if RALogicUtil:isItemById(costId) then
                local tmpSumValue = RACoreDataManager:getItemCountByItemId(costId)
                local itemCost = tonumber(costNum)
                isCanUpgrad = tmpSumValue>=itemCost and true or false
            elseif RALogicUtil:isResourceById(costId) then
                local curNum = RAPlayerInfoManager.getResCountById(tonumber(costId))
                local resCost = tonumber(costNum)
                isCanUpgrad = curNum>=resCost and true or false
            end

            if isCanUpgrad == false then 
                break
            end 
        end
    end 

    return isCanUpgrad
end

--获得建筑的限制数目
function RABuildingUtility.getBuildingLimitCount(limitType,mainCityLvl)
    local build_limit_conf = RARequire("build_limit_conf")
    local limitNum = build_limit_conf[limitType]['cyLv'..mainCityLvl]
    return limitNum
end
 

--获得塔座的位置
function RABuildingUtility.getTowerPosArr()
    local arr = {}
    local const_conf = RARequire('const_conf')
    local RAStringUtil = RARequire('RAStringUtil')

    local towers = RAStringUtil:split(const_conf['defenceBuilding'].value, ',')
    for k,v in pairs(towers) do
        local towerInfo = RAStringUtil:split(v, '_')
        arr[tonumber(towerInfo[1])] = {x=tonumber(towerInfo[2]),y=tonumber(towerInfo[3])} 
    end

    return arr
end

--根据build id 获得防御建筑类型的数据
function RABuildingUtility:getDefenceBuildConfById(buildId)
    -- body
    local battle_soldier_conf = RARequire("battle_soldier_conf")
    for k,v in pairs(battle_soldier_conf) do
        if v.building == buildId then
            return v
        end
    end
    return nil
end

-- 获取所有建造士兵类型的建筑类型列表
function RABuildingUtility:getSoilderBuildTyps()
    local Const_pb = RARequire("Const_pb")
    local ret = {Const_pb.BARRACKS,Const_pb.WAR_FACTORY,Const_pb.REMOTE_FIRE_FACTORY,Const_pb.AIR_FORCE_COMMAND}
    return ret
end

--是否是造兵的建筑
function RABuildingUtility:isSoilderBuilding(buildType)
    local Const_pb = RARequire("Const_pb")
    if buildType == Const_pb.BARRACKS or buildType == Const_pb.WAR_FACTORY or buildType == Const_pb.REMOTE_FIRE_FACTORY or buildType == Const_pb.AIR_FORCE_COMMAND then 
        return true
    end  

    return false
end