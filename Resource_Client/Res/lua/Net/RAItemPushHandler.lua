--region RAItemPushHandler.lua
--Date
--此文件由[BabeLua]插件自动生成
local RAItemPushHandler = {}

function RAItemPushHandler:onReceivePacket(handler)
    local HP_pb = RARequire("HP_pb")
    local RACoreDataManager = RARequire('RACoreDataManager')

    local pbCode = handler:getOpcode()
    local buffer = handler:getBuffer()
    if pbCode == HP_pb.ITEM_INFO_SYNC_S then
        local Item_pb = RARequire("Item_pb")
        local msg = Item_pb.HPItemInfoSync()
        msg:ParseFromString(buffer)		
        if msg ~= nil then
            RACoreDataManager:onRecieveItemInfo(msg)
        end
    elseif pbCode == HP_pb.HOT_SALES_INFO_SYNC_S then
        --todo
        local RAStoreManager = RARequire('RAStoreManager')
        local Item_pb = RARequire("Item_pb")
        local msg = Item_pb.HotSalesInfo()
        msg:ParseFromString(buffer)     
        if msg ~= nil then
            RAStoreManager:onRecieveHotSalesInfo(msg)
        end
    end
end

return RAItemPushHandler
--endregion
