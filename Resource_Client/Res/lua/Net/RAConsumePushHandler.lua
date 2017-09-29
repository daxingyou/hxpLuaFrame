--region *.lua
--Date
--此文件由[BabeLua]插件自动生成

local RAConsumePushHandler = {}

function RAConsumePushHandler:onReceivePacket(handler)
    local HP_pb      = RARequire('HP_pb')
    local Consume_pb = RARequire('Consume_pb')
    local Const_pb   = RARequire('Const_pb')
    local RAPlayerInfoManager = RARequire('RAPlayerInfoManager')
    local RACoreDataManager   = RARequire("RACoreDataManager")
    local RAPackageData       = RARequire("RAPackageData")

    local pbCode = handler:getOpcode()
    local buffer = handler:getBuffer()

    if pbCode == HP_pb.PLAYER_CONSUME_S then
		local msg = Consume_pb.HPConsumeInfo()
		msg:ParseFromString(buffer)

        if msg:HasField('attrInfo') then
            RAPlayerInfoManager.SyncAttrInfo(msg.attrInfo)
        end

        for i = 1, #msg.consumeItem do
            self:_consumeItem(msg.consumeItem[i])
        end
    end
end

--消耗物品处理
function RAConsumePushHandler:_consumeItem(item)

    local HP_pb      = RARequire('HP_pb')
    local Consume_pb = RARequire('Consume_pb')
    local Const_pb   = RARequire('Const_pb')
    local RAPlayerInfoManager = RARequire('RAPlayerInfoManager')
    local RACoreDataManager   = RARequire("RACoreDataManager")
    local RAPackageData       = RARequire("RAPackageData")
    
    local itemType = item.type--道具表里的itemType
    local uuid, itemId = item.id, item.itemId
    local count = item.count or 1

    if RACoreDataManager:hasItemInfoById(uuid) then
        local oldItem = RACoreDataManager:getItemInfoByServerId(uuid)
        local oldCount = oldItem.server.count
        local costCount = count
        local newCount = oldCount - costCount
        if newCount < 0 then
            CCLuaLog("ERROR: ITEM ID "..tostring(uuid).." new count < 0 IN MAP")
        elseif newCount==0 then
            RACoreDataManager:removeItemInfoById(uuid)
        else
            RACoreDataManager:setItemCountById(uuid,newCount)
        end

        --判断为加速道具的话，修改道具加速面板内的数据
        if oldItem.conf.speedUpType ~= nil then
            --todo
            MessageManager.sendMessage(MessageDef_package.MSG_package_consume_accelerate_item)
        end

        -- 消耗道具的时候发送消息
        MessageManager.sendMessage(MessageDef_package.MSG_package_consume_item)    
    else
        CCLuaLog("ERROR: NOT FOUND THE ITEM ID "..tostring(uuid).." IN MAP")
    end
end

return RAConsumePushHandler

--endregion