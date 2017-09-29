RARequire("BasePage")
local player_show_conf = RARequire("player_show_conf")
local Utilitys = RARequire("Utilitys")
local UIExtend = RARequire("UIExtend")
local RAPlayerInfoManager = RARequire("RAPlayerInfoManager")
local RAGameConfig = RARequire("RAGameConfig")
local RANetUtil = RARequire("RANetUtil")
local RARootManager = RARequire("RARootManager")
local shop_conf = RARequire("shop_conf")
local item_conf = RARequire("item_conf")
local Const_pb = RARequire("Const_pb")
local RACoreDataManager = RARequire("RACoreDataManager")
RARequire("MessageManager")

local RALordHeadChangePage = BaseFunctionPage:new(...)
local RALordHeadChangeHandler = {}
RALordHeadChangePage.useGold = false

local currentChooseId = 0 --当前处于选择状态的icon id，没有包含区段号的

local OnReceiveMessage = function(message)
    if message.messageID == MessageDef_Packet.MSG_Operation_OK then
        --修改成功
        RAPlayerInfoManager.setPlayerIconId(currentChooseId)
        MessageManager.sendMessage(MessageDef_Lord.MSG_RefreshPortrait)
        MessageManager.sendMessage(MessageDef_Lord.MSG_RefreshHeadImg)
        RARootManager.ClosePage("RALordHeadChangePage")
    elseif message.messageID == MessageDef_Packet.MSG_Operation_Fail then 
        --修改失败
    end 
end

function RALordHeadChangePage:registerMessage()
    MessageManager.registerMessageHandler(MessageDef_Packet.MSG_Operation_OK,OnReceiveMessage)
    MessageManager.registerMessageHandler(MessageDef_Packet.MSG_Operation_Fail,OnReceiveMessage)
end

function RALordHeadChangePage:removeMessageHandler()
    MessageManager.removeMessageHandler(MessageDef_Packet.MSG_Operation_OK,OnReceiveMessage)
    MessageManager.removeMessageHandler(MessageDef_Packet.MSG_Operation_Fail,OnReceiveMessage)
end

----------------------------------------------------------------------
local RAChangeImageCellListener = {
    id = 0
}
function RAChangeImageCellListener:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    return o
end

function RAChangeImageCellListener:onRefreshContent(ccbRoot)
    local ccbifile = ccbRoot:getCCBFileNode()
    local info = player_show_conf[self.id]
    if info then
        local icon = info.playerShow
        UIExtend.addSpriteToNodeParent(ccbifile, "mPortraitPicNode", icon)
    end
end
-------------------------------------------------------------------------


function RALordHeadChangePage:Enter(data)
    self.ccbifile = UIExtend.loadCCBFile("RALordChangePortrait.ccbi", RALordHeadChangePage)

    self:registerMessage()

    local svNode = UIExtend.getCCNodeFromCCB(self.ccbifile, "mScrollNode")
    self:refreshTitle()

    self.mPreviousBtn = UIExtend.getCCMenuItemImageFromCCB(self.ccbifile, 'mPreviousBtn')
    --self.mPreviousBtn:setEnabled(false)

    self.mNextBtn = UIExtend.getCCMenuItemImageFromCCB(self.ccbifile, 'mNextBtn')
    --self.mNextBtn:setEnabled(false)

    local size = CCSizeMake(0, 0)
    if svNode then
        size = svNode:getContentSize()
    end
    self.scrollView = CCSelectedScrollView:create(size)
    self.scrollView:setDirection(kCCScrollViewDirectionHorizontal)
    self.scrollView:registerFunctionHandler(RALordHeadChangePage)
    
    UIExtend.addNodeToParentNode(self.ccbifile, "mScrollNode", self.scrollView)
    self:showAllHead()
    --self:addHandler()
end

function RALordHeadChangePage:refreshTitle()
    if self.ccbifile then
        local titleCCB = UIExtend.getCCBFileFromCCB(self.ccbifile, "mCommonTitleCCB")
        if titleCCB then
            UIExtend.setNodeVisible(titleCCB, "mDiamondsNode", false)
            UIExtend.setCCLabelString(titleCCB, "mTitle", _RALang("@GeneralDetail"))
        end
    end
end

function RALordHeadChangePage:showAllHead()
    self.scrollView:removeAllCell()
    local palyerInfo = RAPlayerInfoManager.getPlayerBasicInfo()
    self.imageCount = 0
    self.imageIndexs = {}
    for k, value in Utilitys.table_pairsByKeys(player_show_conf) do
        self.imageCount = self.imageCount + 1
        self.imageIndexs[value.id - RAGameConfig.ConfigIDFragment.ID_PLAYER_SHOWCONF] = self.imageCount
        local cellListener = RAChangeImageCellListener:new({id = value.id})
        local cell = CCBFileCell:create()
        cell:setCCBFile("RALordChangePortraitCell.ccbi")
        cell:registerFunctionHandler(cellListener)
        cell:setCellTag(k)
        self.scrollView:addCellBack(cell)
        if palyerInfo.headIconId == (value.id-RAGameConfig.ConfigIDFragment.ID_PLAYER_SHOWCONF) then
            self.scrollView:setSelectedCell(cell)
            currentChooseId = value.id - RAGameConfig.ConfigIDFragment.ID_PLAYER_SHOWCONF
            --self:setCurrentId(value.id)
            cell:setScale(1)
        end
    end

    --设置左右的按钮visible
    self:setCurrentId(currentChooseId + RAGameConfig.ConfigIDFragment.ID_PLAYER_SHOWCONF)

    self.scrollView:orderCCBFileCells()
	self.scrollView:getSelectedCell():locateTo(CCBFileCell.LT_Mid);

    self:refreshBtn()
end

function RALordHeadChangePage:setLordHeadNode(isShow)
    -- body
    UIExtend.setNodeVisible(self.ccbifile, 'mBuyPortraitBtnNode', not isShow)
    UIExtend.setNodeVisible(self.ccbifile, 'mUseBtnNode', isShow)
end

function RALordHeadChangePage:refreshBtn()
        --todo更换头像的道具逻辑判断
    -- if currentChooseId == RAPlayerInfoManager.getPlayerBasicInfo().headIconId then
    --     --不可更改
    --     UIExtend.setCCControlButtonEnable(self.ccbifile, "mChangePortraitBtn", false)
    -- else
    --     --可以更改
    --     UIExtend.setCCControlButtonEnable(self.ccbifile, "mChangePortraitBtn", true)
    -- end

    local id = currentChooseId + RAGameConfig.ConfigIDFragment.ID_PLAYER_SHOWCONF
    local playerShowConf = player_show_conf[id]

    local isBuy = RAPlayerInfoManager.getPlayerIsAlreadyBuyHead(currentChooseId)
    --正在使用的
    if currentChooseId == RAPlayerInfoManager.getPlayerBasicInfo().headIconId then
        self:setLordHeadNode(true)
        UIExtend.setCCControlButtonEnable(self.ccbifile, "mUsePortraitBtn", false)
        UIExtend.setControlButtonTitle(self.ccbfile, 'mUsePortraitBtn', _RALang('@IsUse'))
    elseif playerShowConf.type == 0 or isBuy then   --不需要购买的 免费的  或者已经购买过的
        self:setLordHeadNode(true)
        UIExtend.setCCControlButtonEnable(self.ccbifile, "mUsePortraitBtn", true)
        UIExtend.setControlButtonTitle(self.ccbfile, 'mUsePortraitBtn', _RALang('@UsePortrait'))
    elseif playerShowConf.type == 1 then   --需要购买的    
        self:setLordHeadNode(false)
        UIExtend.setCCControlButtonEnable(self.ccbifile, "mChangePortraitBtn", true)

        local icon=nil
        local num=0
        --local cardNum = 0
        local shopItemInfo = shop_conf[Const_pb.SHOP_CHANGE_ICON]
        --local itemId = shopItemInfo.shopItemID
        local price = shopItemInfo.price
        --local itemCount = RACoreDataManager:getItemCountByItemId(itemId)
        --local constItemInfo = item_conf[Const_pb.ITEM_CHANGE_ICON]
        --if itemCount > 0 then
            -- icon = constItemInfo.item_icon

            -- local iconSub = string.sub(icon, -3)
            -- if iconSub ~= "png" then
            --     icon = icon .. ".png"
            -- end

            -- num = 1
            -- cardNum = itemCount
            --RALordHeadChangePage.useGold = false
        --else
            icon = RAGameConfig.Diamond_Icon
            num = price
            --RALordHeadChangePage.useGold = true
        --end
        --UIExtend.setCCLabelString(self.ccbifile, "mChangeNameCardNum", cardNum)--todo改名卡数量暂时是10
        UIExtend.addSpriteToNodeParent(self.ccbifile, "mChangePorIcon", icon)--todo暂时使用金币icon
        UIExtend.setCCLabelString(self.ccbifile, "mChangeNameDiamonds", num)--todo暂时是1000
    end
end

function RALordHeadChangePage:onChangePortrait()
    --点击购买按钮
    local confirmData =
    {
        labelText = _RALang('@IsLordHeadChange'),
        yesNoBtn = true,
        resultFun = function (isOK)
            if isOK then
                self.useGold = true
                self:sendChangeImg(currentChooseId)
            end
        end
    }
    RARootManager.showConfirmMsg(confirmData)
end

function RALordHeadChangePage:onUsePortraitBtn()
    --点击更换按钮
    self.useGold = false
    self:sendChangeImg(currentChooseId)
end

function RALordHeadChangePage:setCurrentId(id)
    self.currentChooseId = id - RAGameConfig.ConfigIDFragment.ID_PLAYER_SHOWCONF
    local index  = self.imageIndexs[self.currentChooseId]
    if index == 1 then 
        self.mPreviousBtn:setVisible(false)
        self.mNextBtn:setVisible(true)
    elseif index == self.imageCount then 
        self.mPreviousBtn:setVisible(true)
        self.mNextBtn:setVisible(false)
    else
        self.mPreviousBtn:setVisible(true)
        self.mNextBtn:setVisible(true)
    end
end

function RALordHeadChangePage:sendChangeImg(id)
    --todo 发送changeimg协议
    local msg = Player_pb.PlayerChangeIconReq()
    msg.iconId = id
    msg.useGold = self.useGold
    RANetUtil:sendPacket(HP_pb.PLAYER_CHANGE_ICON_C, msg)
end

-- function RALordHeadChangePage:onReceivePacket(handler)
--     local pbCode = handler:getOpcode()
--     local buffer = handler:getBuffer()
--     if pbCode == HP_pb.PLAYER_CHANGE_ICON_S then
--         --解析
--         local msg = Player_pb.PlayerChangeIconRes()
--         msg:ParseFromString(buffer)
--         if msg then
--             local result = msg.result
--             if result then
--                 RAPlayerInfoManager.setPlayerIconId(currentChooseId)
--                 MessageManager.sendMessage(MessageDef_Lord.MSG_RefreshPortrait)
--                 MessageManager.sendMessage(MessageDef_Lord.MSG_RefreshHeadImg)
--                 RARootManager.ClosePage("RALordHeadChangePage")
--             end
--         end
--     end
-- end

function RALordHeadChangePage:mCommonTitleCCB_onBack()
    RARootManager.ClosePage("RALordHeadChangePage")
end

function RALordHeadChangePage:onNextBtn()
    if self.scrollView then
        self.scrollView:moveCellByDirection(1)
    end
end


function RALordHeadChangePage:onPreviousBtn()
    if self.scrollView then
        self.scrollView:moveCellByDirection(-1)
    end
end

-- function RALordHeadChangePage:addHandler()
--     RALordHeadChangeHandler[#RALordHeadChangeHandler +1] = RANetUtil:addListener(HP_pb.PLAYER_CHANGE_ICON_S, RALordHeadChangePage)

--     self.scrollView:registerFunctionHandler(RALordHeadChangePage)
-- end

-- function RALordHeadChangePage:removeHandler()
--     for k, value in pairs(RALordHeadChangeHandler) do
--         if RALordHeadChangeHandler[k] then
--             RANetUtil:removeListener(RALordHeadChangeHandler[k])
--             RALordHeadChangeHandler[k] = nil
--         end
--     end
--     RALordHeadChangeHandler = {}

--     self.scrollView:unregisterFunctionHandler()
-- end

function RALordHeadChangePage:scrollViewSelectNewItem(cell)
    if cell then
        local preCell = self.scrollView:getSelectedCell()
        if preCell then
            --播放缩小动画
            local scaleSmallAction = CCScaleTo:create(0.2, RAGameConfig.Portrait_Scale, RAGameConfig.Portrait_Scale)
            preCell:runAction(scaleSmallAction)
        end
        self.scrollView:setSelectedCell(cell, CCBFileCell.LT_Mid, 0.0, 0.2)
        --播放放大动画
        local scaleLargeAction = CCScaleTo:create(0.2, 1, 1)
        cell:runAction(scaleLargeAction)
        local cellTag = cell:getCellTag()
        currentChooseId = cellTag - RAGameConfig.ConfigIDFragment.ID_PLAYER_SHOWCONF
        self:setCurrentId(cellTag)
        self:refreshBtn()
    end
end

function RALordHeadChangePage:scrollViewSelectNewItemIsNull(cell)
    if cell then
        local preCell = self.scrollView:getSelectedCell()
        if preCell then
            --todo播放缩小动画
        end
        self.scrollView:setSelectedCell(cell, CCBFileCell.LT_Mid, 0.0, 0.2)
        --todo播放放大动画
    end
end

function RALordHeadChangePage:scrollViewRollBack(cell)
    if cell then
        self.scrollView:setSelectedCell(cell, CCBFileCell.LT_Mid, 0.0, 0.2)
    end
end

function RALordHeadChangePage:scrollViewPreItem(preCell)

end

function RALordHeadChangePage:scrollViewChangeItem(cell)

end

function RALordHeadChangePage:Exit(data)
    --self:removeHandler()
    self.scrollView:unregisterFunctionHandler()
    self:removeMessageHandler()
    self.scrollView:removeAllCell()
    self.scrollView = nil
    UIExtend.unLoadCCBFile(RALordHeadChangePage)
    self.ccbifile = nil
end
