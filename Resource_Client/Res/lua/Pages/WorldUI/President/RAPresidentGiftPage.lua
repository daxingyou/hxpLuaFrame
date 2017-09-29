-- 王国界面

RARequire('BasePage')
local UIExtend = RARequire('UIExtend')
local RACommonTitleHelper = RARequire('RACommonTitleHelper')
local RARootManager = RARequire('RARootManager')
local RAPresidentConfig = RARequire('RAPresidentConfig')
local RAPresidentDataManager = RARequire('RAPresidentDataManager')
local common = RARequire('common')

local pageInfo =
{
    mPageName       = 'RAPresidentGiftPage',
    mScrollView     = nil,
    mViewWidth      = 640,
}
local RAPresidentGiftPage = BaseFunctionPage:new(..., pageInfo)

--------------------------------------------------------------------------------------
-- region: RAGiftCellHandler

local GiftItemCellCnt = 8

local RAGiftCellHandler =
{
    mConf = {},

    new = function(self, o)
        o = o or {}
        setmetatable(o,self)
        self.__index = self    
        return o
    end,

    getCCBName = function(self)
        return 'RAPresidentConferCell.ccbi'
    end,

    onRefreshContent = function(self, cellRoot)
        if not cellRoot then return end
        local ccbfile = cellRoot:getCCBFileNode()

        local giftInfo = RAPresidentDataManager:GetGiftInfo(self.mConf.id) or {}

        local remainCnt, totalCnt = giftInfo.remainCnt or 0, giftInfo.totalCnt or self.mConf.totalNumber
        local txtMap =
        {
            mCellTitle  = _RALang(self.mConf.giftName or ''),
            mCellNum = _RALang('@PresidentGiftNum', remainCnt, totalCnt)
        }

        local visibleMap = {}

        local RAResManager = RARequire('RAResManager')
        local item_conf = RARequire('item_conf')
        local RAPackageData =  RARequire('RAPackageData')
        local rewardArr = RAResManager:getResInfosByStr(self.mConf.awardShow)
        for i = 1, GiftItemCellCnt, 1 do
            local resInfo = rewardArr[i]
            local nodeName = 'mFrameNode' .. i

            if resInfo then
                visibleMap[nodeName] = true
                txtMap['mIconNum' .. i] = 'x ' .. resInfo.itemCount
                local icon = RAResManager:getIconByTypeAndId(resInfo.itemType, resInfo.itemId)
                UIExtend.addSpriteToNodeParent(ccbfile, 'mCellIconNode' .. i, icon)
                local itemCfg = item_conf[tonumber(resInfo.itemId)]
                RAPackageData.setNumTypeInItemIcon(ccbfile, 'mItemHaveNum' .. i, 'mItemHaveNumNode' .. i, itemCfg)
            else
                visibleMap[nodeName] = false
            end
        end
        UIExtend.setStringForLabel(ccbfile, txtMap)
        UIExtend.setNodesVisible(ccbfile, visibleMap)
        UIExtend.setTitle4ControlButtons(ccbfile, {mConferBtn = _RALang('@Award')})
        UIExtend.setEnabled4ControlButtons(ccbfile, {mConferBtn = remainCnt > 0})
        local colorKey = remainCnt > 0 and 'Enough' or 'Lack'
        local color = ccc3(unpack(RAPresidentConfig.GiftNumColor[colorKey]))
        UIExtend.setLabelTTFColor(ccbfile, 'mCellNum', color)
        color:delete()
    end,

    onConferBtn = function(self, btn)
        RARootManager.OpenPage('RAPresidentGrantGiftPage', {giftId = self.mConf.id})
    end
}

-- endregion: RAGiftCellHandler
--------------------------------------------------------------------------------------

local msgTB =
{
    MessageDef_World.MSG_PresidentGift_Update
}

function RAPresidentGiftPage:Enter(data)
    self:_resetData()
    self:_getGiftInfo()

    UIExtend.loadCCBFile('RAPresidentConferPage.ccbi', self)
    
    self.mScrollView = UIExtend.getCCScrollViewFromCCB(self.ccbfile, 'mListSV')

    self:_initTitle()

    self:_initScrollView()
    self:_registerMessageHandlers()
end

function RAPresidentGiftPage:Exit()
    self:_unregisterMessageHandlers()
    RACommonTitleHelper:RemoveCommonTitle(self.mPageName)
    if self.mScrollView then
        self.mScrollView:removeAllCell()
    end
    UIExtend.unLoadCCBFile(self)
    self:_resetData()
end

function RAPresidentGiftPage:_resetData()
    self.mScrollView = nil
end

--初始化顶部
function RAPresidentGiftPage:_initTitle()
    local titleCCB = UIExtend.getCCBFileFromCCB(self.ccbfile, 'mCommonTitleCCB')
    titleCCB:runAnimation('InAni')

    local titleName = _RALang('@PresidentGift')
    local title = RACommonTitleHelper:RegisterCommonTitle(self.mPageName, titleCCB, titleName, 
        nil, RACommonTitleHelper.BgType.Blue)
    title:SetFunctionCallBackType(RACommonTitleHelper.TitleCallBack.Label)
    title:SetCallBack(RACommonTitleHelper.TitleCallBack.Label, self._showRecord)
    title:SetFunctionLabelTxt(_RALang('@PresidentGiftRecord'))
end

function RAPresidentGiftPage:_registerMessageHandlers()
    for _, msgId in ipairs(msgTB) do
        MessageManager.registerMessageHandler(msgId, self._onReceiveMessage)
    end
end

function RAPresidentGiftPage:_unregisterMessageHandlers()
    for _, msgId in ipairs(msgTB) do
        MessageManager.removeMessageHandler(msgId, self._onReceiveMessage)
    end
end

function RAPresidentGiftPage._onReceiveMessage(msg)
    local msgId = msg.messageID

    if msgId == MessageDef_World.MSG_PresidentGift_Update then
        RAPresidentGiftPage:_refreshPage()        
        return
    end
end

function RAPresidentGiftPage:onManagerBtn()
    self.mIsShowMgr = not self.mIsShowMgr
    self.ccbfile:runAnimation(self.mIsShowMgr and 'MgrOpenAni' or 'MgrCloseAni')
end

function RAPresidentGiftPage:_showRecord()
    local pageData = {recordType = RAPresidentConfig.RecordType.Gift}
    RARootManager.OpenPage('RAPresidentRecordPage', pageData, false, true, true)
end

function RAPresidentGiftPage:_refreshPage()
    if self.mScrollView then
        self.mScrollView:refreshAllCell()
    end
end

function RAPresidentGiftPage:_initScrollView()
    self.mScrollView:removeAllCell()
    
    local itemCell, cellHandler = nil, nil

    local president_gift_conf = RARequire('president_gift_conf')
    local ids = common:table_keys(president_gift_conf)
    table.sort(ids)
    for _, id in pairs(ids) do
        itemCell = CCBFileCell:create()
        cellHandler = RAGiftCellHandler:new({
            mConf = president_gift_conf[id]
        })
        itemCell:registerFunctionHandler(cellHandler)
        itemCell:setCCBFile(cellHandler:getCCBName())
            
        self.mScrollView:addCellBack(itemCell)
    end

    self.mScrollView:orderCCBFileCells()
end

function RAPresidentGiftPage:_getGiftInfo()
    local RAWorldProtoHandler = RARequire('RAWorldProtoHandler')
    RAWorldProtoHandler:sendGetPresidentGiftInfoReq()
end

return RAPresidentGiftPage