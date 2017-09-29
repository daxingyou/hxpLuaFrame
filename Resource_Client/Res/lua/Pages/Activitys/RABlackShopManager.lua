--region *.lua
--Date
--此文件由[BabeLua]插件自动生成
local HP_pb = RARequire("HP_pb")
local Activity_pb = RARequire("Activity_pb")
local RARootManager = RARequire("RARootManager")
local RANetUtil = RARequire("RANetUtil")
local RABlackShopManager = {
    goodsInfos = {},--商品信息
    nextRefreshTime = nil,--下次刷新时间
    refreshNeedGold = nil,
    hasNewGoods = false,
    --recieve the packet
    onRecievePacket = function(self,msg)
        self.goodsInfos = msg.goodsInfos
        self.nextRefreshTime = msg.nextRefreshTime
        self.hasNewGoods = msg.hasNewGoods
        self.refreshNeedGold = msg.refreshNeedGold
        local message = {}
        message.pageName = "RABlackShopPage"
        message.isLocalRefresh  = true
        MessageManager.sendMessage(MessageDef_RootManager.MSG_CommonRefreshPage,message)
    end,
    --send buy goods command
    sendBuyGoodCommand = function(self,id)
        local msg = Activity_pb.HPTravelShopBuyReq()
        msg.id = id
        RANetUtil:sendPacket(HP_pb.TRAVEL_SHOP_BUY_C, msg)
    end,
    --send refresh shop command
    sendRefreshGoodCommand = function(self)
        RANetUtil:sendPacket(HP_pb.TRAVEL_SHOP_REFRESH_C, nil)
    end

}

return RABlackShopManager;
--endregion
