--region RATroopsInfoManager.lua
--Author : phan
--Date   : 2016/7/2
--此文件由[BabeLua]插件自动生成

local RATroopsInfoManager = {}

local RATroopsInfoConfig = RARequire("RATroopsInfoConfig")
local RAArsenalManager = RARequire("RAArsenalManager")
local RACoreDataManager = RARequire("RACoreDataManager")
local RABuildManager = RARequire("RABuildManager")
local build_conf = RARequire("build_conf")

--由高到低排序
function sortBySolders(s1,s2)
    if s1.id > s2.id then
        return true
    end
    return false
end

--获得所拥有兵种的数据
function RATroopsInfoManager.getSoldersData()

    local isNull = false
    
    for i = 1,#RATroopsInfoConfig.buildIdTab do
        local pageData = RAArsenalManager:getArmyIdsByBuildId(RATroopsInfoConfig.buildIdTab[i])
        for j = 1, #pageData do
            local armyInfo = RACoreDataManager:getArmyInfoByArmyId(tonumber(pageData[j]))
            if armyInfo and armyInfo.freeCount > 0 then
                isNull = true
                if i == 1 then --兵营
                    table.insert(RATroopsInfoConfig.SoldersData.SoldersA,{[tonumber(pageData[j])] = armyInfo,type = 1,['isBar'] = false,['id'] = tonumber(pageData[j])})
                elseif i == 2 then --战车工厂
                    table.insert(RATroopsInfoConfig.SoldersData.SoldersB,{[tonumber(pageData[j])] = armyInfo,type = 1,['isBar'] = false,['id'] = tonumber(pageData[j])})
                elseif i == 3 then --远程火力工厂
                    table.insert(RATroopsInfoConfig.SoldersData.SoldersC,{[tonumber(pageData[j])] = armyInfo,type = 1,['isBar'] = false,['id'] = tonumber(pageData[j])})
                elseif i == 4 then   --远程火力工厂
                    table.insert(RATroopsInfoConfig.SoldersData.SoldersD,{[tonumber(pageData[j])] = armyInfo,type = 1,['isBar'] = false,['id'] = tonumber(pageData[j])}) 
                end
            end
        end
    end

    --排序
    table.sort(RATroopsInfoConfig.SoldersData.SoldersA,sortBySolders)
    table.sort(RATroopsInfoConfig.SoldersData.SoldersB,sortBySolders)
    table.sort(RATroopsInfoConfig.SoldersData.SoldersC,sortBySolders)
    table.sort(RATroopsInfoConfig.SoldersData.SoldersD,sortBySolders)

    --城内兵数量标题
    local troopsTotal = RATroopsInfoManager.getTroopsTotal(false)
    local title1 = _RALang("@CityTroops",tostring(troopsTotal))
    table.insert(RATroopsInfoConfig.buildIdData,{["title"] = title1})
    if isNull then 
        if #RATroopsInfoConfig.SoldersData.SoldersA ~= 0 then
            table.insert(RATroopsInfoConfig.buildIdData,RATroopsInfoConfig.SoldersData.SoldersA)
        end
    
        if #RATroopsInfoConfig.SoldersData.SoldersB ~= 0 then
            table.insert(RATroopsInfoConfig.buildIdData,RATroopsInfoConfig.SoldersData.SoldersB)
        end

        if #RATroopsInfoConfig.SoldersData.SoldersC ~= 0 then
            table.insert(RATroopsInfoConfig.buildIdData,RATroopsInfoConfig.SoldersData.SoldersC)
        end

        if #RATroopsInfoConfig.SoldersData.SoldersD ~= 0 then
            table.insert(RATroopsInfoConfig.buildIdData,RATroopsInfoConfig.SoldersData.SoldersD)
        end
    else
        table.insert(RATroopsInfoConfig.buildIdData,{['show'] = _RALang("@NoTroops")})
    end

end

--获得所拥有防御武器的数据
function RATroopsInfoManager.getDefenseData()

    local isNull = false
    --光棱塔
    local prismTower = RABuildManager:getBuildDataArray(Const_pb.PRISM_TOWER)
    for k,v in ipairs(prismTower) do
        isNull = true
        local buildDataCfg = v.confData
        table.insert(RATroopsInfoConfig.DefenseData.DefenseA,{[tonumber(buildDataCfg.id)] = v,type = 2,['name'] = buildDataCfg.buildName,['isBar'] = true,['id'] = tonumber(buildDataCfg.id)})
    end

    --爱国者飞弹
    local patrtotMissile = RABuildManager:getBuildDataArray(Const_pb.PATRIOT_MISSILE)
    for k,v in ipairs(patrtotMissile) do
        isNull = true
        local buildDataCfg = v.confData
        table.insert(RATroopsInfoConfig.DefenseData.DefenseB,{[tonumber(buildDataCfg.id)] = v,type = 2,['name'] = buildDataCfg.buildName,['isBar'] = true,['id'] = tonumber(buildDataCfg.id)})
    end

    --机枪碉堡
    local pillbox = RABuildManager:getBuildDataArray(Const_pb.PILLBOX)
    for k,v in ipairs(pillbox) do
        isNull = true
        local buildDataCfg = v.confData
        table.insert(RATroopsInfoConfig.DefenseData.DefenseC,{[tonumber(buildDataCfg.id)] = v,type = 2,['name'] = buildDataCfg.buildName,['isBar'] = true,['id'] = tonumber(buildDataCfg.id)})
    end

    --巨炮
    local cannon = RABuildManager:getBuildDataArray(Const_pb.CANNON)
    for k,v in ipairs(cannon) do
        isNull = true
        local buildDataCfg = v.confData
        table.insert(RATroopsInfoConfig.DefenseData.DefenseD,{[tonumber(buildDataCfg.id)] = v,type = 2,['name'] = buildDataCfg.buildName,['isBar'] = true,['id'] = tonumber(buildDataCfg.id)})
    end

    if isNull then
        local defenseTotal = #prismTower + #patrtotMissile + #pillbox + #cannon
        local title2 = _RALang("@DefenseTotal",defenseTotal)
        table.insert(RATroopsInfoConfig.buildIdData,{["title"] = title2})

        if #RATroopsInfoConfig.DefenseData.DefenseA ~= 0 then
            table.insert(RATroopsInfoConfig.buildIdData,RATroopsInfoConfig.DefenseData.DefenseA)
        end
        if #RATroopsInfoConfig.DefenseData.DefenseB ~= 0 then
            table.insert(RATroopsInfoConfig.buildIdData,RATroopsInfoConfig.DefenseData.DefenseB)
        end
        if #RATroopsInfoConfig.DefenseData.DefenseC ~= 0 then
            table.insert(RATroopsInfoConfig.buildIdData,RATroopsInfoConfig.DefenseData.DefenseC)
        end
        if #RATroopsInfoConfig.DefenseData.DefenseD ~= 0 then
            table.insert(RATroopsInfoConfig.buildIdData,RATroopsInfoConfig.DefenseData.DefenseD)
        end
    end
end

--获取部队总数
function RATroopsInfoManager.getTroopsTotal(cityOrWar)
    local troopsTotal = 0
    for i = 1 ,#RATroopsInfoConfig.buildIdTab do
        local data = RAArsenalManager:getArmyIdsByBuildId(RATroopsInfoConfig.buildIdTab[i])
        for i = 1 ,#data do
            local armyInfo = RACoreDataManager:getArmyInfoByArmyId(tonumber(data[i]))
            if armyInfo then
                if cityOrWar then
                    troopsTotal = troopsTotal + armyInfo.freeCount + armyInfo.woundedCount --空闲的加伤兵
                else
                    troopsTotal = troopsTotal + armyInfo.freeCount  --空闲的
                end
            end
        end
    end
    return troopsTotal
end

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------行军的数据--------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--获取行軍中的部队数
function RATroopsInfoManager.getRunTroopsTotal()
    local runTroopsTotal = 0
    local armyData = RATroopsInfoConfig.RunTroopsData.armyData
    for i = 1 ,#armyData do
        runTroopsTotal = runTroopsTotal + armyData[i].count --行軍的
    end
    return runTroopsTotal
end

--获取行軍中的部队数据
function RATroopsInfoManager.getRunTroopsData()
    local armyData = RATroopsInfoConfig.RunTroopsData.armyData
    for i = 1 ,#armyData do
        local armyInfo = armyData[i]
        table.insert(RATroopsInfoConfig.buildIdData,{['id'] = armyInfo.armyId,['count'] = armyInfo.count})
    end
end

--后端返回行軍中的部队数据
function RATroopsInfoManager.setRunTroopsData(data)
    local playerName = data.playerName  --玩家名字
    local guildTag = data.guildTag  --玩家联盟简称

    RATroopsInfoConfig.RunTroopsData.playerName = playerName
    RATroopsInfoConfig.RunTroopsData.guildTag = guildTag
    local army = data.army  --出征的军队信息
    for i = 1,#army do
        local armySvrData = army[i]
        local armyId = armySvrData.armyId
        RATroopsInfoConfig.RunTroopsData.armyData[i] = armySvrData
    end
end

--解僱
function RATroopsInfoManager.onSendFireSoldier(soldierId,mArmyCount)
    local Army_pb = RARequire("Army_pb")
    local RANetUtil = RARequire("RANetUtil")
    local HP_pb = RARequire("HP_pb")

    local cmd = Army_pb.HPFireSoldierReq()
    local cmd2 = cmd.soldiers:add()
    cmd2.armyId = tonumber(soldierId)
    cmd2.count = tonumber(mArmyCount)
    RANetUtil:sendPacket(HP_pb.FIRE_SOLDIER_C, cmd, {retOpcode = -1})
end

--重置数据
function RATroopsInfoManager.restData()

    RATroopsInfoConfig.SoldersData.SoldersA = {}
    RATroopsInfoConfig.SoldersData.SoldersB = {}
    RATroopsInfoConfig.SoldersData.SoldersC = {}
    RATroopsInfoConfig.SoldersData.SoldersD = {}

    RATroopsInfoConfig.DefenseData.DefenseA = {}
    RATroopsInfoConfig.DefenseData.DefenseB = {}
    RATroopsInfoConfig.DefenseData.DefenseC = {}
    RATroopsInfoConfig.DefenseData.DefenseD = {}

    RATroopsInfoConfig.RunTroopsData.armyData = {}

    RATroopsInfoConfig.buildIdData ={}
end

return RATroopsInfoManager

--endregion


