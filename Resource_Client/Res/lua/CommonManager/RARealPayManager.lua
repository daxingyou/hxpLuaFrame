local RARootManager = RARequire("RARootManager")
local RAStringUtil = RARequire("RAStringUtil")
local Utilitys = RARequire("Utilitys")
local RASDKInitManager = RARequire("RASDKInitManager")
local RANetUtil = RARequire("RANetUtil")
local HP_pb = RARequire('HP_pb')
local Recharge_pb = RARequire('Recharge_pb')

local RARealPayManager = {}

package.loaded[...] = RARealPayManager

--local platformProductionInfo = {
--    ["diamond_01"] = {
--        productionId = "diamond_01",
--        formatterPrice = "4.99",
--        currencyCode = "CNY",
--        price = "4.99",
--        description = "diamond_01"
--    },
--    ["diamond_02"] = {
--        productionId = "diamond_02",
--        formatterPrice = "9.99",
--        currencyCode = "CNY",
--        price = "9.99",
--        description = "diamond_02"
--    },
--    ["diamond_03"] = {
--        productionId = "diamond_03",
--        formatterPrice = "19.99",
--        currencyCode = "CNY",
--        price = "19.99",
--        description = "diamond_03"
--    },
--    ["diamond_04"] = {
--        productionId = "diamond_04",
--        formatterPrice = "49.99",
--        currencyCode = "CNY",
--        price = "49.99",
--        description = "diamond_04"
--    },
--    ["diamond_05"] = {
--        productionId = "diamond_05",
--        formatterPrice = "99.99",
--        currencyCode = "CNY",
--        price = "99.99",
--        description = "diamond_05"
--    },
--    ["diamond_06"] = {
--        productionId = "diamond_06",
--        formatterPrice = "4.99",
--        currencyCode = "CNY",
--        price = "4.99",
--        description = "diamond_06"
--    },
--    ["diamond_07"] = {
--        productionId = "diamond_07",
--        formatterPrice = "9.99",
--        currencyCode = "CNY",
--        price = "9.99",
--        description = "diamond_07"
--    },
--    ["diamond_08"] = {
--        productionId = "diamond_08",
--        formatterPrice = "19.99",
--        currencyCode = "CNY",
--        price = "19.99",
--        description = "diamond_08"
--    },
--    ["diamond_09"] = {
--        productionId = "diamond_09",
--        formatterPrice = "49.99",
--        currencyCode = "CNY",
--        price = "49.99",
--        description = "diamond_09"
--    },
--    ["diamond_10"] = {
--        productionId = "diamond_10",
--        formatterPrice = "99.99",
--        currencyCode = "CNY",
--        price = "99.99",
--        description = "diamond_10"
--    },
--    ["gift_01"] = {
--        productionId = "gift_01",
--        formatterPrice = "0.99",
--        currencyCode = "CNY",
--        price = "0.99",
--        description = "gift_01"
--    },
--    ["gift_02"] = {
--        productionId = "gift_02",
--        formatterPrice = "19.99",
--        currencyCode = "CNY",
--        price = "19.99",
--        description = "gift_02"
--    },
--}
local serverProductionInfo = {}
serverProductionInfo.goodsItems = {}
serverProductionInfo.giftItems = {}
RARealPayManager.loginTimes = 0
RARealPayManager.addGoldLevel = 0
RARealPayManager.addGold = 0
RARealPayManager.levelRewards = {}
RARealPayManager.netHandler = {}
RARealPayManager.goodsId = nil--购买的商品id
RARealPayManager.sdkListener = nil
RARealPayManager.isInit = false--是否初始化，只初始化一次
RARealPayManager.comFromPop = false--购买操作是否来自如popup的页面


function RARealPayManager.init()
    if RARealPayManager.isInit == false then
        RARealPayManager.registerHandler()
        RARealPayManager.isInit = true
    end
end

function RARealPayManager.registerHandler()
    RARealPayManager.netHandler[#RARealPayManager.netHandler +1] = RANetUtil:addListener(HP_pb.RECHARGE_S, RARealPayManager)
    --RARealPayManager.netHandler[#RARealPayManager.netHandler +1] = RANetUtil:addListener(HP_pb.RECHARGE_REWARD_S, RARealPayManager)
end

function RARealPayManager.removeHandler()
    --取消packet监听
    for k, value in pairs(RARealPayManager.netHandler) do
        if RARealPayManager.netHandler[k] ~= nil then
             RANetUtil:removeListener(RARealPayManager.netHandler[k])
             RARealPayManager.netHandler[k] = nil
        end
    end
    RARealPayManager.netHandler = {}
end

--desc:接收数据
function RARealPayManager:onReceivePacket(handler)
    local pbCode = handler:getOpcode()
    local buffer = handler:getBuffer()
    if pbCode == HP_pb.RECHARGE_S then
        --支付消息
        local msg = Recharge_pb.RechargeResponse()
        msg:ParseFromString(buffer)
        if msg.result == 0 then
            if msg:HasField("orderId") then
                local orderId = msg.orderId
                Utilitys.pay(self.goodsId, orderId)
                self:_removeSDKListener()
                self.sdkListener = platformSDKListener:new(self)
            end
        elseif msg.result == -1 then
        --订单获取失败
            RARootManager.RemoveWaitingPage()
            RARootManager.ShowMsgBox(_RALang("@PayOrderFailed"))
        end
    --elseif pbCode == HP_pb.RECHARGE_REWARD_S then
        --累计充值奖励
        -- local msg = Recharge_pb.RecievePayAddAwardResp()
        -- msg:ParseFromString(buffer)
        -- if msg.result == true then
        -- else
        --     --奖励领取失败
        --     RARootManager.ShowMsgBox(_RALang("@RewardFailed"))
        -- end
    end
end


function RARealPayManager:onSDKPaySuccess(listener)
    self:_removeSDKListener()
end

function RARealPayManager:onSDKPayFailed(listener)
    -- RARootManager.ShowMsgBox(_RALang("@PayCallbackFailed"))
    RARootManager.RemoveWaitingPage()
    self:_removeSDKListener()
end

function RARealPayManager:_removeSDKListener()
    if self.sdkListener then
        self.sdkListener:delete()
        self.sdkListener = nil
    end
end

--desc:初始化平台商品信息
function RARealPayManager.getAllPlatformProductionInfo()
    return RASDKInitManager.platformProductionInfo
end

function RARealPayManager.getPlatfromProductionByProductId(productId)
    
    if RASDKInitManager.platformProductionInfo[productId] then
        return RASDKInitManager.platformProductionInfo[productId]
    else
        return nil
    end
end

function RARealPayManager:getRechargeInfo()
    local msg = Recharge_pb.FetchRechargeInfo()
    RANetUtil:sendPacket(HP_pb.FETCH_RECHARGE_INFO, msg)
end

---------------------------------------------
---------------------------------------------
function RARealPayManager.sortServerProduction(serverItemInfo1, serverItemInfo2)
    if serverItemInfo1.order and serverItemInfo2.order then
        return serverItemInfo1.order < serverItemInfo2.order
    else
        return tonumber(serverItemInfo1.goodsId) < tonumber(serverItemInfo2.goodsId)
    end
end

function RARealPayManager.sortServerGiftProduction(serverItemInfo1, serverItemInfo2)
    if serverItemInfo1.popup and serverItemInfo2.popup then
        return serverItemInfo1.popup < serverItemInfo2.popup
    else
        return tonumber(serverItemInfo1.goodsId) < tonumber(serverItemInfo2.goodsId)
    end
end

--[[
serverItem包含的信息：
	required string goodsId 	= 1;
	required string saleId 		= 2;
	optional int32	type 		= 3;
	optional int32	priceType	= 4;
	optional int32	oldPrice	= 5;
	optional int32	payPrice	= 6;
	optional int32	gold		= 7;
	optional int32	payLimit	= 8;
	optional string	name		= 9;
	optional int32	percent		= 10;
	optional int32	popup		= 11;
	optional int32	hot			= 12;
	optional string	show		= 13;
	optional int32 order		= 14;
    --]]
 --desc:初始化服务器商品信息
function RARealPayManager.initServerProductionInfo(msg)
    serverProductionInfo.goodsItems = {}
    RARealPayManager.levelRewards = {}
    serverProductionInfo.giftItems = {}

    --普通商品信息
    if msg.goodsItems then
        for i=1, #msg.goodsItems do
            local item = msg.goodsItems[i]
            serverProductionInfo.goodsItems[i] = item
        end
        table.sort(serverProductionInfo.goodsItems, RARealPayManager.sortServerProduction)
    end

    --礼包商品信息
    if msg.giftItems then
        for j=1, #msg.giftItems do
            local item = msg.giftItems[j]
            serverProductionInfo.giftItems[j] = item
        end
        table.sort(serverProductionInfo.giftItems, RARealPayManager.sortServerGiftProduction)
    end

    
    RARealPayManager.addGold = msg.addGold--当前等级充值钻石数
    local RAStringUtil = RARequire('RAStringUtil')
    local hasRecvArr = RAStringUtil:split(msg.addGoldLevel,",") -- 已经领取的奖励
    local pay_add_conf = RARequire('pay_add_conf')
    local nowLevel = #pay_add_conf + 1
    for i,v in ipairs(pay_add_conf) do
        local hasRecv = false
        for j,level in ipairs(hasRecvArr) do
            if tonumber(level) == v.level then
                hasRecv = true
                break
            end
        end
        if hasRecv == false then
            nowLevel = v.level
            break
        end
    end    
    RARealPayManager.hasRecvArr = hasRecvArr
    RARealPayManager.nowLevel = nowLevel --当前最低未领取的等级

    --当前累计充值奖励
    if msg.awards then
        for m=1, #msg.awards do
            RARealPayManager.levelRewards[m] = msg.awards[m]
        end
    end
    
    --是否包含loginTimes字段用来判断是进入游戏是的信息推送还是游戏内点击按钮时的请求返回
    if msg:HasField("loginTimes") then
        RARealPayManager.loginTimes = msg.loginTimes--当前登陆次数
        --MessageManager.sendMessage(MessageDef_Pay.MSG_PayInfoRefresh)--作为推送的话，需要刷新支付相关信息
    else
        --点击按钮，打开支付页面
        local RARechargeMainPage = RARequire("RARechargeMainPage")
        if RARechargeMainPage and RARechargeMainPage.isShowing then
            MessageManager.sendMessage(MessageDef_Pay.MSG_PayInfoRefresh)--作为推送的话，需要刷新支付相关信息
        else
            if not RARealPayManager.comFromPop then
                RARootManager.OpenPage("RARechargeMainPage", nil, false, true, false, true)
            else
                MessageManager.sendMessage(MessageDef_Pay.MSG_PayInfoRefresh)--作为推送的话，需要刷新支付相关信息
            end
        end
    end
end

--desc:根据登陆次数，选择要弹出的礼包
function RARealPayManager.getGiftItemByLogTimes()
    if RARealPayManager.loginTimes then
        
        local giftCount = #serverProductionInfo.giftItems
        if giftCount > 0 then
            local index = RARealPayManager.loginTimes % giftCount
            if index == 0 then
                index = giftCount
            end

            local item = serverProductionInfo.giftItems[index]

            return item
        end
    end
end

--desc:根据登录次数，获得主UI上显示的icon种类
function RARealPayManager.getGiftItemMainUICCBByLogTimes()
    if RARealPayManager.loginTimes then
        
        local giftCount = #serverProductionInfo.giftItems
        if giftCount > 0 then
            local index = RARealPayManager.loginTimes % giftCount
            if index == 0 then
                index = giftCount
            end

            local item = serverProductionInfo.giftItems[index]

            return item.json
        end
    end
end

--desc:获得普通购买商品信息
function RARealPayManager.getGoodsItems()
    return serverProductionInfo.goodsItems
end

--desc:根据goodsId获得服务器商品信息
function RARealPayManager.getGoodItemByGoodsId(goodsId)
    for k, goodItem in pairs(serverProductionInfo.goodsItems) do
        if goodItem.goodsId == goodsId then
            return goodItem
        end
    end

    for k, giftItem in pairs(serverProductionInfo.giftItems) do
        if giftItem.goodsId == goodsId then
            return giftItem
        end
    end

    return nil
end

--desc:获得礼包商品信息
function RARealPayManager.getGiftItems()
    return serverProductionInfo.giftItems
end


function RARealPayManager.onPayResult(msg)
    if msg.success == true then
        --支付回调成功
        if CC_TARGET_PLATFORM_LUA ~= CC_PLATFORM.CC_PLATFORM_WIN32 then
            RARootManager.RemoveWaitingPage()
        end
        RARootManager.ShowMsgBox(_RALang("@PayCallbackSuccess"))
        MessageManager.sendMessage(MessageDef_Pay.MSG_PaySuccess)--支付成功
    else
        --支付回调失败
        RARootManager.ShowMsgBox(_RALang("@PayCallbackFailed"))
    end
end

function RARealPayManager:reset()
    serverProductionInfo = {}
    self.levelRewards = {}
    self.loginTimes = 0
    self.addGoldLevel = 0
    self.addGold = 0
    self.removeHandler()
    self:_removeSDKListener()
    self.isInit = false
    self.comFromPop = false
end
