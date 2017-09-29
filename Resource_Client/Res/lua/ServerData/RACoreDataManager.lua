local RACoreDataManager = {}

------------------------------------state info begin---------------------------------

RACoreDataManager.stateInfo = {}

function RACoreDataManager:resetStateData()
    RACoreDataManager.stateInfo = {}
end

function RACoreDataManager:getStateInfoByKey(key)
    return RACoreDataManager.stateInfo[key]
end

function RACoreDataManager:syncStateInfo(oneState)
    RACoreDataManager.stateInfo[oneState.key] = oneState
end



-------------------------------------item info begin----------------------------------
local item_conf   = RARequire("item_conf")

RACoreDataManager.RACoreDataItemInfo = {}
RACoreDataManager.RACoreDataItemInfoByItemId = {}
RACoreDataManager.RACoreDataItemInfoSize = 0


function RACoreDataManager:resetItemData()
    RACoreDataManager.RACoreDataItemInfo = {}
    RACoreDataManager.RACoreDataItemInfoByItemId = {}
    RACoreDataManager.RACoreDataItemInfoSize = 0
end

function RACoreDataManager:getItemInfoByServerId(id)
    return RACoreDataManager.RACoreDataItemInfo[id] or nil
end

function RACoreDataManager:getItemInfoByItemId(id)
    local serverData = self.RACoreDataItemInfoByItemId[id]
    if nil ~= serverData then
        return serverData
    else
        return item_conf[id]
    end
end

function RACoreDataManager:getItemCountByItemId(itemId)
    local count = 0
    local item = self:getItemInfoByItemId(itemId)
    if item ~= nil and item.server ~= nil then
        for _,v in pairs(item.server) do
            count = count + tonumber(v.count)
        end
    end
    return count
end

function RACoreDataManager:hasItemInfoById(id)
    return self.RACoreDataItemInfo[id]~=nil
end

function RACoreDataManager:removeItemInfoById(uuid)

    if self.RACoreDataItemInfo[uuid]==nil then
        return
    end    
    
    local itemId=self.RACoreDataItemInfo[uuid].server.itemId
    if itemId==nil then
        return
    end

    local obj = {} 
    obj.uuid   = uuid
    obj.itemId = itemId
    obj.count  = newCount
    obj.isNew  = false
    local RAPackageManager = RARequire("RAPackageManager")
    RAPackageManager:updateServerDataByTempItem(obj, true)

    local itemServerData=self.RACoreDataItemInfoByItemId[itemId]
    if itemServerData~=nil and #itemServerData.server>1 then
        local i=nil
        for k,v in pairs(itemServerData.server) do
            if v.uuid==uuid then
                i=k
                break
            end        
        end    
        if i~=nil then
            table.remove(self.RACoreDataItemInfoByItemId[itemId].server,i)
        end  
    else
        self.RACoreDataItemInfoByItemId[itemId] = nil      
    end 
   
    self.RACoreDataItemInfo[uuid] = nil
    self.RACoreDataItemInfoSize = self.RACoreDataItemInfoSize - 1

    RAPackageManager:updateMainUIMenuPkgRedPoint()--更新小红点    
end


function RACoreDataManager:setItemCountById(uuid, newCount)

    if self.RACoreDataItemInfo[uuid] ~= nil then
        self.RACoreDataItemInfo[uuid].server.count = newCount
        local itemByConf = self.RACoreDataItemInfoByItemId[self.RACoreDataItemInfo[uuid].server.itemId]
        if itemByConf ~= nil then
            for _,v in pairs(itemByConf.server) do
                if v.uuid == uuid then
                    v.count = newCount
                    break
                end
            end

            local obj = {}
            obj.uuid   = uuid
            obj.itemId = self.RACoreDataItemInfo[uuid].server.itemId
            obj.count  = newCount
            obj.isNew  = false
            local RAPackageManager = RARequire("RAPackageManager")
            RAPackageManager:updateServerDataByTempItem(obj, false)
        end
    end
end

--Description: 
--recieve the item data
function RACoreDataManager:onRecieveItemInfo(msg)
	if msg~=nil and msg.itemInfos ~=nil then
        local RAPackageManager = RARequire("RAPackageManager")
		local size = #msg.itemInfos
        for i = 1,size do
            local serverItem = msg.itemInfos[i]
            local itemId=serverItem.itemId
            if item_conf[itemId]~=nil then
                self.RACoreDataItemInfo[serverItem.uuid] = self:createItemByServer(serverItem)--key is serverId
                self.RACoreDataItemInfoByItemId[serverItem.itemId] = self:createItemByConf(serverItem)--key is ItemId
                self.RACoreDataItemInfoSize = self.RACoreDataItemInfoSize + 1	--count
                RAPackageManager:updateServerDataByTempItem(self:createServerDataByServerItem(serverItem), false)	--to Package Manager	
            else
                CCLuaLog("[!!!!!Warning!!!!!]RACoreDataManager:onRecieveItemInfo itemId:"..tostring(itemId).." not exist in item_conf!")
            end
        end

        if 0 ~= size then
            RAPackageManager:updateMainUIMenuPkgRedPoint()--更新小红点
        end
	end
end

function itemsOrderSort(a, b)
    local r
    local aOrder = tonumber(a.conf.order)
    local bOrder = tonumber(b.conf.order)

    r = aOrder < bOrder
    return r
end

function RACoreDataManager:getAccelerateDataByType( type )
    -- body  speedUpType
    local data = {}
    local Const_pb = RARequire("Const_pb")
    local RAPackageData = RARequire("RAPackageData")
    for _,v in pairs(self.RACoreDataItemInfo) do
        if v.conf~=nil and (tonumber(type) == tonumber(v.conf.speedUpType) 
            or (tonumber(v.conf.speedUpType) == tonumber(RAPackageData.SPEED_UP_TYPE.common) and tonumber(type) ~= Const_pb.GUILD_SCIENCE_QUEUE ) )  --联盟加速不能使用通用加速Const_pb.GUILD_SCIENCE_QUEUE
        then
            table.insert(data, v)
        end
    end

    table.sort( data, itemsOrderSort )
    return data
end

--创建以itemId为key的数据，（可以存储多个uuid的数据）。存储于ItemInfoByItemId
--{conf={},server={1={}, 2={}...}}
function RACoreDataManager:createItemByConf( serverItem )
    local item = self.RACoreDataItemInfoByItemId[serverItem.itemId]
    if nil ~= item then
        local isChange = false
        for k,v in pairs(item.server) do
            if serverItem.uuid == v.uuid then
                item.server[k] = self:createServerDataByServerItem(serverItem)
                isChange = true
                break
            end
        end

        if not isChange  then
            table.insert(item.server, self:createServerDataByServerItem(serverItem))
        end
    else
        item = {}
        item.server={}
        table.insert(item.server, self:createServerDataByServerItem(serverItem))
    end

    item.conf = item_conf[serverItem.itemId]
    return item
end

--创建以uuid为key的数据，存储于ItemInfo�?
--{conf={},server={}}
function RACoreDataManager:createItemByServer( serverItem )
    local item = {}
    item.conf = item_conf[serverItem.itemId]
    item.server = self:createServerDataByServerItem(serverItem)
    return item
end

function RACoreDataManager:createServerDataByServerItem(serverItem)
    local obj = {}
    obj.uuid   = serverItem.id or serverItem.uuid
    obj.itemId = serverItem.itemId
    obj.count  = serverItem.count
    obj.isNew  = serverItem.isNew
    return obj
end

function RACoreDataManager:clearAllItemIsNewFalse()
    for k,v in pairs(self.RACoreDataItemInfo) do
        v.server.isNew = false
    end
    for k,v in pairs(self.RACoreDataItemInfoByItemId) do
        for _,v2 in pairs(v.server) do
            v2.isNew = false
        end
    end

    local RAPackageManager = RARequire("RAPackageManager")
    RAPackageManager:clearAllItemIsNewFalse()
end
-------------------------------------item info end----------------------------------



-------------------------------------Army info begin----------------------------------

local RARootManager = RARequire("RARootManager")
RACoreDataManager.ArmyInfo = {}
RACoreDataManager.ArmyInfoByArmyId = {}
RACoreDataManager.ArmyWoundedInfo = {}
RACoreDataManager.ArmyWoundedInfoIndex = {}
RACoreDataManager.ArmyNewWoundedInfo = {}
RACoreDataManager.ArmyCuringInfo = {}
RACoreDataManager.ArmyInfoSize = 0
RACoreDataManager.ArmyWoundedSize = 0
RACoreDataManager.ArmyWoundedSumCount = 0
RACoreDataManager.ArmyCuringSize = 0
RACoreDataManager.ArmyNewWoundedSize = 0
RACoreDataManager.mHasWoundedArmy = false
RACoreDataManager.hasCuringArmy = false
RACoreDataManager.currArmyId={}


function RACoreDataManager:hasWoundedArmy()
    return RACoreDataManager.mHasWoundedArmy
end


function RACoreDataManager:resetArmyData()
    RACoreDataManager.ArmyInfo = {}
    RACoreDataManager.ArmyInfoByArmyId = {}
    RACoreDataManager.ArmyWoundedInfo = {}
    RACoreDataManager.ArmyWoundedInfoIndex = {}
    RACoreDataManager.ArmyNewWoundedInfo = {}
    RACoreDataManager.ArmyCuringInfo = {}
    RACoreDataManager.ArmyInfoSize = 0
    RACoreDataManager.ArmyWoundedSize = 0
    RACoreDataManager.ArmyWoundedSumCount = 0
    RACoreDataManager.ArmyCuringSize = 0
    RACoreDataManager.ArmyNewWoundedSize = 0
    RACoreDataManager.mHasWoundedArmy = false
    RACoreDataManager.hasCuringArmy = false
    RACoreDataManager.currArmyId=nil
    RACoreDataManager.currArmyKind=nil
    RACoreDataManager.currArmyIndex=nil
end


function RACoreDataManager:getArmyInfoByServerId(id)
    return RACoreDataManager.ArmyInfo[id] or nil
end

function RACoreDataManager:getArmyInfoByArmyId(id)
    return RACoreDataManager.ArmyInfoByArmyId[id] or nil
end

function RACoreDataManager:hasArmyInfoById(id)
    return self.ArmyInfo[id]~=nil
end

function RACoreDataManager:removeArmyInfoById(id)
    self.ArmyInfoByArmyId[self.ArmyInfo[id].ArmyId] = nil
    self.ArmyInfo[id] = nil
    self.ArmyInfoSize = self.ArmyInfoSize - 1
end

function RACoreDataManager:setArmyCountById(id,newCount)
    if self.ArmyInfo[id]~=nil then
        self.ArmyInfo[id].count = newCount
        if self.ArmyInfoByArmyId[self.ArmyInfo[id].ArmyId]~=nil then
            self.ArmyInfoByArmyId[self.ArmyInfo[id].ArmyId].count = newCount
        end
    end
end


--记录兵营界面最后点击的兵种id
function RACoreDataManager:setCurrArmyId(buildType,armyId)
    if self.currArmyId==nil then 
        self.currArmyId={}
    end 
    self.currArmyId[buildType]= armyId
end

function RACoreDataManager:getCurrArmyId(buildType)

    if self.currArmyId then
        return self.currArmyId[buildType]
    end 
end

--记录兵营界面最后点击的兵种页签（普通兵种or进阶兵种）
--1位普通兵种 2为进阶兵种
function RACoreDataManager:setCurrArmyKind(kind)
    self.currArmyKind = kind
end

function RACoreDataManager:getCurrArmyKind()
    return self.currArmyKind
end

--记录兵营界面最后点击的兵种顺序index
function RACoreDataManager:setCurrArmyIndex(index)
    self.currArmyIndex = index
end

function RACoreDataManager:getCurrArmyIndex()
    return self.currArmyIndex
end

--Description: 
--recieve the Army data
function RACoreDataManager:onRecieveArmyInfo(msg)
	if msg~=nil and msg.armyInfos ~=nil then
        local Army_pb = RARequire('Army_pb')
        local armyId = nil 
		local size = #msg.armyInfos
        RACoreDataManager.mHasWoundedArmy = false
        RACoreDataManager.hasCuringArmy  = false
        local totalNum = 0
        for i = 1,size do
            local oneArmy = msg.armyInfos[i]
            local serverId = oneArmy.id
            local ArmyId = oneArmy.armyId
            armyId = oneArmy.armyId 
            --key is serverId
            RACoreDataManager.ArmyInfo[serverId] = oneArmy
            --key is ArmyId
            RACoreDataManager.ArmyInfoByArmyId[ArmyId] = oneArmy
            RACoreDataManager.ArmyInfoSize = RACoreDataManager.ArmyInfoSize +1		
            if oneArmy.woundedCount > 0 then
                RACoreDataManager.mHasWoundedArmy = true
            end	
            if oneArmy.cureCount > 0 then 
                RACoreDataManager.hasCuringArmy = true
            end

            if msg.cause == Army_pb.CURE_FINISH_COLLECT or  msg.cause == Army_pb.SOLDIER_COLLECT then 
                totalNum = totalNum + oneArmy.addCount
            end 
        end

        RACoreDataManager:recieveArmyWoundedInfo()
        RACoreDataManager:recieveArmyCuringInfo()
        RACoreDataManager:recieveArmyFreeInfo()

        if msg.cause == Army_pb.MARCH_BACK then -- Army_pb.MARCH_BACK  出征回来，包括死亡士兵和正常返回   直接写死的话 不用 RARequire 了
            --解雇成功后发送消息刷新集结点
            MessageManager.sendMessage(MessageDef_CITY.MSG_NOTICE_GATHER)
        elseif msg.cause == Army_pb.SOLDIER_COLLECT then --收兵
            local RACitySceneManager = RARequire('RACitySceneManager')
            local battle_soldier_conf = RARequire('battle_soldier_conf')
            local soldierName = _RALang(battle_soldier_conf[armyId].name)

            local RAGuideManager = RARequire("RAGuideManager")
            if RAGuideManager.isInGuide() then
                --立即造兵，不会弹出收兵hud，所以这里要调用gotoNext一下
                local RAGuideConfig = RARequire("RAGuideConfig")
                local keyWorld = RAGuideManager.getKeyWordById(RAGuideManager.currentGuildId)
                if keyWorld == RAGuideConfig.KeyWordArray.CreateTrainImm then
                    RAGuideManager.gotoNextStep()
                end
            else
                local RAArsenalManager = RARequire('RAArsenalManager')
                if not RAArsenalManager.clickCollect then
                    MessageManager.sendMessage(MessageDef_CITY.MSG_NOTICE_GATHER)
                else
                    RAArsenalManager.clickCollect = false
                end
            end
            RARootManager.ShowMsgBox('@SoldierCollectInfo',soldierName,totalNum)
        elseif msg.cause == Army_pb.CURE_FINISH_COLLECT then --治疗伤兵
            local RACitySceneManager = RARequire('RACitySceneManager')
            RACitySceneManager:finishCureSoldier()
            RARootManager.ShowMsgBox('@CureSoldierCollectInfo',totalNum)
        end 
	end
end

function RACoreDataManager:recieveArmyWoundedInfo()
    -- body
    self:refreshArmyWoundedInfo()

    local k,pageHandler = RARootManager.checkPageLoaded("RAHospitalUIPage")
    if pageHandler == nil then
        --todo
        return
    end

    local data = {woundedCount = self.ArmyWoundedSumCount}
    MessageManager.sendMessage(MessageDefine_Hospital.MSG_receive_wounded_data, data)
end

function RACoreDataManager:refreshArmyWoundedInfo()
    -- body
    self.ArmyWoundedInfo = {}
    self.ArmyWoundedInfoIndex = {}
    self.ArmyWoundedSize = 0
    self.ArmyWoundedSumCount = 0

    for k,v in pairs(self.ArmyInfo) do
        --print(k,v)
        if v.woundedCount and v.woundedCount > 0 then
            --todo
            local armyInfo = {}
            armyInfo.id = v.id
            armyInfo.armyId = v.armyId
            armyInfo.freeCount = v.freeCount
            armyInfo.marchCount = v.marchCount
            armyInfo.defenceCount = v.defenceCount
            armyInfo.inTrainCount = v.inTrainCount
            armyInfo.finishTrainCount = v.finishTrainCount
            armyInfo.woundedCount = v.woundedCount
            armyInfo.cureCount = v.cureCount
            armyInfo.cureFinishCount = v.cureFinishCount
            armyInfo.killCount = v.killCount
            armyInfo.addCount = v.addCount

            self.ArmyWoundedInfo[k] = armyInfo
            self.ArmyWoundedInfoIndex[#self.ArmyWoundedInfoIndex + 1] = armyInfo
            self.ArmyWoundedSize = self.ArmyWoundedSize + 1
            self.ArmyWoundedSumCount = self.ArmyWoundedSumCount + tonumber(armyInfo.woundedCount)
        end
    end
end

function RACoreDataManager:getArmyWoundedSumCount()
    -- body
    return self.ArmyWoundedSumCount or nil
end

function RACoreDataManager:addArmyNewWoundedToInfo()
    -- body
    for k,v in pairs(RACoreDataManager.ArmyNewWoundedInfo) do
        --print(k,v)
        RACoreDataManager.ArmyWoundedInfo[k] = v
        RACoreDataManager.ArmyWoundedSize = RACoreDataManager.ArmyWoundedSize + 1
    end

    RACoreDataManager.ArmyNewWoundedInfo = {}
    RACoreDataManager.ArmyNewWoundedSize = 0
end


function RACoreDataManager:recieveArmyCuringInfo()
    -- body

    local k,pageHandler = RARootManager.checkPageLoaded("RAHospitalUIPage")
    if pageHandler == nil then
        --todo
        return
    end

    local curingCount = RACoreDataManager:refreshArmyCuringInfo()
    local data = {cureCount = curingCount}
    MessageManager.sendMessage(MessageDefine_Hospital.MSG_receive_cure_count, data)
end


function RACoreDataManager:refreshArmyCuringInfo()
    -- body
    RACoreDataManager.ArmyCuringInfo = {}
    RACoreDataManager.ArmyCuringSize = 0

    local curingCount = 0
    for k,v in pairs(RACoreDataManager.ArmyInfo) do
        --print(k,v)
        if v.cureCount and v.cureCount > 0 then
            --todo
            RACoreDataManager.ArmyCuringInfo[k] = v
            RACoreDataManager.ArmyCuringSize = RACoreDataManager.ArmyCuringSize + 1
            curingCount = tonumber(v.cureCount) + curingCount
        end
    end

    return curingCount
end

-- get amry id and count list; key value = army level
function RACoreDataManager:getFreeArmyLevelMap()
    local battle_soldier_conf = RARequire("battle_soldier_conf")
    local Utilitys = RARequire('Utilitys')
    local result = {}
    local maxLevel = 0
    local totalFree = 0
    local currLoad = 0
    for k,armyInfo in pairs(self.ArmyInfo) do
        local cfgId = armyInfo.armyId
        local cfgArmy = battle_soldier_conf[cfgId]
        if cfgArmy ~= nil then
            local oneArmyInfo = {}
            local level = cfgArmy.level
            if level > maxLevel then
                maxLevel = level
            end            
            oneArmyInfo.uuid = k
            oneArmyInfo.armyId = cfgId
            oneArmyInfo.freeCount = armyInfo.freeCount
            oneArmyInfo.load = cfgArmy.load
            if oneArmyInfo.freeCount > 0 then
                if result[level] == nil then
                    result[level] = {}                
                end
                table.insert(result[level], oneArmyInfo)
                totalFree = totalFree + oneArmyInfo.freeCount
            end            
        end
    end
    -- 同等级下按id 排序
    for level, levelMap in pairs(result) do
        Utilitys.tableSortByKey(levelMap, 'armyId')
    end
    return result, maxLevel, totalFree
end

-- get army id and count list; key value = armyId level
function RACoreDataManager:getMarchingArmyLevelMap()
    local battle_soldier_conf = RARequire("battle_soldier_conf")
    local Utilitys = RARequire('Utilitys')
    local result = {}
    local maxLevel = 0
    local totalMarch = 0
    for k,armyInfo in pairs(self.ArmyInfo) do
        local cfgId = armyInfo.armyId
        local cfgArmy = battle_soldier_conf[cfgId]
        if cfgArmy ~= nil then
            local oneArmyInfo = {}
            local level = cfgArmy.level
            if level > maxLevel then
                maxLevel = level
            end            
            oneArmyInfo.uuid = k
            oneArmyInfo.armyId = cfgId
            oneArmyInfo.marchCount = armyInfo.marchCount
            if oneArmyInfo.marchCount > 0 then
                if result[level] == nil then
                    result[level] = {}                
                end
                table.insert(result[level], oneArmyInfo)
                totalMarch = totalMarch + oneArmyInfo.marchCount
            end            
        end
    end
    -- 同等级下按id 排序
    for level, levelMap in pairs(result) do
        Utilitys.tableSortByKey(levelMap, 'armyId')
    end
    return result, maxLevel, totalMarch 
end


function RACoreDataManager:recieveArmyFreeInfo()
    local k,pageHandler = RARootManager.checkPageLoaded("RATroopChargePage")
    if pageHandler == nil then
        --todo
        return
    end

    -- local armyMap, maxLevel = RACoreDataManager:getFreeArmyLevelMap()
    -- local data = {armyData = armyMap, maxLevel = maxLevel}
    MessageManager.sendMessage(MessageDef_World.MSG_ArmyFreeCountUpdate, {})
end

-------------------------------------Army info end----------------------------------

-------------------------------------reset------------------------------------------
function RACoreDataManager:reset(flag)
    self:resetItemData()
    self:resetArmyData()
    self:resetStateData()
end

return RACoreDataManager