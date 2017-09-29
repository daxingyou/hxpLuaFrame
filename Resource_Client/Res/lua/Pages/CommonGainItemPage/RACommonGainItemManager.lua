--通用道具使用界面Manager
--by sunyungao

local RANetUtil     = RARequire("RANetUtil")
local RACommonGainItemData = RARequire("RACommonGainItemData")
local RAPackageData = RARequire("RAPackageData")
local item_conf     = RARequire("item_conf")
local Item_pb = RARequire("Item_pb")
local Const_pb = RARequire('Const_pb')
local RACoreDataManager = RARequire("RACoreDataManager")


local RACommonGainItemManager = 
{
	--
	mData = {}
}

--重置数据
function RACommonGainItemManager:resetData()
	-- body
	self.mData = {}
end


function configOrderSort(a, b)
    -- body
    local r
    local aOrder = tonumber(a.conf.order)
    local bOrder = tonumber(b.conf.order)

    r = aOrder < bOrder

    return r
end

function priceOrderSort(a, b)
    -- body
    local r
    local aOrder = tonumber(a.conf.sellPrice)
    local bOrder = tonumber(b.conf.sellPrice)

    r = aOrder < bOrder

    return r
end

--配置文件数据初始化--1. 出征上限提升界面--2. 行军加速界面       --3. 行军召回界面       
function RACommonGainItemManager:updateConfigData(data)
    -- body
    self:resetData()
    local itemType = data.itemType

    if itemType == RACommonGainItemData.GAIN_ITEM_TYPE.expeditionMax then
        self.mData = self:getExpeditionMaxData()
    elseif itemType == RACommonGainItemData.GAIN_ITEM_TYPE.powerCallBack then
        self.mData = self:getAddPowerData()
    elseif itemType == RACommonGainItemData.GAIN_ITEM_TYPE.marchAccelerate then
        self.mData = self:getMarchAccelerateData()
    elseif itemType == RACommonGainItemData.GAIN_ITEM_TYPE.marchCallBack then
        self.mData = self:getMarchCallBackData()
    elseif itemType == RACommonGainItemData.GAIN_ITEM_TYPE.resCollectSpeedUp then
        self.mData = self:getResourceCollectItemData()
    elseif itemType == RACommonGainItemData.GAIN_ITEM_TYPE.useExp then
        self.mData = self:getResourceExpItemData()        
    end

    CCLuaLog("RACommonGainItemManager:updateConfigData")
end

function RACommonGainItemManager:createItem(confItem)
    -- body
    local item = {}
    item.conf = confItem

    return item
end

--获取添加体力类型数据,并排序
--functionBlock = 3 
function RACommonGainItemManager:getAddPowerData()
    local data = {}
	for k,v in pairs(item_conf) do
		local fb = v.functionBlock
		if nil ~= fb and (fb == RACommonGainItemData.AddPowerFunctionBlock) then
            local item = RACoreDataManager:getItemInfoByItemId(v.id)
            if nil ~= item and nil ~= item.server then
                table.insert(data, item)
            else
                local item = self:createItem(v)
                table.insert(data, item)
            end
		end
	end
	
	table.sort( data,configOrderSort)
	return data
end


--获取出征上限数据,并排序
--itemType = 3 ; effect = Const_pb.TROOP_STRENGTH_PER 的道具
function RACommonGainItemManager:getExpeditionMaxData()
    -- body
    local data = {}
    for k,v in pairs(item_conf) do
        --print(k,v)
        local itemType = v.item_type
        local buffId   = tonumber(v.buffId)
        local effect   = tonumber(v.effect)
        if nil ~= itemType and itemType == RAPackageData.ITEM_TYPE.state and nil ~= effect and effect == Const_pb.TROOP_STRENGTH_PER then
            --todo
            local item = RACoreDataManager:getItemInfoByItemId(v.id)
            if nil ~= item and nil ~= item.server then
                --todo
                table.insert(data, item)
            else
                --todo
                local item = self:createItem(v)
                table.insert(data, item)
            end
        end
    end

    table.sort( data,  configOrderSort )
    return data
end

--获取行军加速数据,并排序
--itemType = 2 ; effect = Const_pb.MARCH_TIME_REDUCE 的道具
function RACommonGainItemManager:getMarchAccelerateData()
    -- body
    local data = {}
    for k,v in pairs(item_conf) do
        --print(k,v)
        local itemType = v.item_type
        local effect   = v.effect
        if nil ~= itemType and itemType == RAPackageData.ITEM_TYPE.buff and nil ~= effect and effect == Const_pb.MARCH_TIME_REDUCE then
            --todo
            local item = RACoreDataManager:getItemInfoByItemId(v.id)
            if nil ~= item and nil ~= item.server then
                --todo
                table.insert(data, item)
            else
                --todo
                local item = self:createItem(v)
                table.insert(data, item)
            end
        end
    end

    table.sort( data,  configOrderSort )
    return data
end

--获取行军召回数据,并排序
--itemType = 102的道具
function RACommonGainItemManager:getMarchCallBackData()
    -- body
    local data = {}
    for k,v in pairs(item_conf) do
        --print(k,v)
        local itemType = v.item_type
        if nil ~= itemType and itemType == 102 then
            --todo
            local item = RACoreDataManager:getItemInfoByItemId(v.id)
            if nil ~= item and nil ~= item.server then
                --todo
                table.insert(data, item)
            else
                --todo
                local item = self:createItem(v)
                table.insert(data, item)
            end
        end
    end

    table.sort( data,  configOrderSort )
    return data
end

--获取资源采集加速的道具
--itemType = 3 ; effect = Const_pb.RES_COLLECT_BUF 的 的道具
function RACommonGainItemManager:getResourceCollectItemData()
    -- body
    local data = {}
    for k,v in pairs(item_conf) do
        --print(k,v)
        local itemType = v.item_type
        local effect   = v.effect
        if nil ~= itemType and itemType == RAPackageData.ITEM_TYPE.state and nil ~= effect and effect == Const_pb.RES_COLLECT_BUF then
            --todo
            local item = RACoreDataManager:getItemInfoByItemId(v.id)
            if nil ~= item and nil ~= item.server then
                --todo
                table.insert(data, item)
            else
                --todo
                local item = self:createItem(v)
                table.insert(data, item)
            end
        end
    end

    table.sort( data,  configOrderSort )
    return data
end

--获取经验道具
--itemType = 5
--functionBlock = 6 
function RACommonGainItemManager:getResourceExpItemData()
    local data = {}
    for k,v in pairs(item_conf) do
        local fb = v.functionBlock
        local itemType = v.item_type
        if itemType == RAPackageData.ITEM_TYPE.res and nil ~= fb and (fb == RACommonGainItemData.AddExpFunctionBlock) then
            local item = RACoreDataManager:getItemInfoByItemId(v.id)
            if nil ~= item and nil ~= item.server then
                table.insert(data, item)
            else
                local item = self:createItem(v)
                table.insert(data, item)
            end
        end
    end
    
    table.sort( data,priceOrderSort)
    return data
end

--------------------------------------------------------------
-----------------------协议相关-------------------------------
--------------------------------------------------------------

-- 发送购买
function RACommonGainItemManager:sendBuyItem(shopId, count)
	--todo
    local cmd = Item_pb.HPItemBuyReq()
    cmd.shopId = shopId
    cmd.itemCount = count
    RANetUtil:sendPacket(HP_pb.ITEM_BUY_C, cmd, {retOpcode = -1})
end

--发送打折商品购买
function RACommonGainItemManager:sendDiscountedSelling(salesId)
    -- body 
    local cmd = Item_pb.HPBuyHotReq()
    cmd.salesId = salesId
    RANetUtil:sendPacket(HP_pb.BUY_HOT_C, cmd, {retOpcode = -1})
end

return RACommonGainItemManager