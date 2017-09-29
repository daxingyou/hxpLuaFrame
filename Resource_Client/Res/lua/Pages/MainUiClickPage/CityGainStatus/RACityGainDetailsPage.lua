--TO:基地增益状态详细信息显示页面
RARequire("BasePage")

local UIExtend = RARequire("UIExtend")
local RARootManager = RARequire("RARootManager")
local RACityGainManager = RARequire("RACityGainManager")
local RACoreDataManager = RARequire("RACoreDataManager")
local RAResManager = RARequire("RAResManager")
local RALogicUtil = RARequire("RALogicUtil")
local RAMailUtility = RARequire("RAMailUtility")
local HP_pb = RARequire("HP_pb")
local RABuffManager = RARequire("RABuffManager")
local Utilitys = RARequire("Utilitys")
local common = RARequire("common")

local RACityGainDetailsPage = BaseFunctionPage:new(...)

local OnReceiveMessage = function(message)
    if message.messageID == MessageDef_CityGainStatus.MSG_CityGain_Changed then
        RACityGainDetailsPage:updateRefreshPage()
    elseif message.messageID == MessageDef_Packet.MSG_Operation_OK then
        if message.opcode == HP_pb.BUY_AND_USE_C then --购买成功
            RARootManager.CloseCurrPage()
        end
    end
end

function RACityGainDetailsPage:registerMessage()
    MessageManager.registerMessageHandler(MessageDef_Packet.MSG_Operation_OK,OnReceiveMessage)
    MessageManager.registerMessageHandler(MessageDef_CityGainStatus.MSG_CityGain_Changed,OnReceiveMessage)
end

function RACityGainDetailsPage:removeMessageHandler()
    MessageManager.removeMessageHandler(MessageDef_Packet.MSG_Operation_OK,OnReceiveMessage)
    MessageManager.removeMessageHandler(MessageDef_CityGainStatus.MSG_CityGain_Changed,OnReceiveMessage)
end

function RACityGainDetailsPage:updateRefreshPage()
    self:refreshUI()
    self:addCell()
end

function RACityGainDetailsPage:Enter(data)
	local ccbfile = UIExtend.loadCCBFile("RACityGainDetailsPage.ccbi",self)
	self.scrollView = UIExtend.getCCScrollViewFromCCB(ccbfile, "mListSV")
    
    self:registerMessage()

    self.mData = data.buffData
	--top info
    self:initTitle()

    self:updateRefreshPage()
end

function RACityGainDetailsPage:updateTime()
    local buff = RABuffManager:getBuff(self.mData.effectID)
    local curTime = common:getCurMilliTime()
    local diffTime = math.ceil((buff.endTime - curTime) / 1000)
    local formatTimeStr = Utilitys.createTimeWithFormat(diffTime)
    UIExtend.setStringForLabel(self.ccbfile,{mEffectiveTime = _RALang("@BecomeEffectiveTime",formatTimeStr)})

    local mBar = UIExtend.getCCScale9SpriteFromCCB(self.ccbfile,"mBar")
    local totolTime = (buff.endTime - buff.startTime) / 1000
    local processTime = (buff.endTime - curTime) / 1000
    local scaleX = (processTime / totolTime)

    if scaleX > 1 then
        scaleX = 1
    end
    if mBar then
        mBar:setScaleX(scaleX)
    end
end

function RACityGainDetailsPage:refreshUI()
    if self.mData.isProcessTime then
        RACityGainManager:setNodeVisible(self.ccbfile,false)

        UIExtend.setStringForLabel(self.ccbfile,{mHaveBarExplain = _RALang(self.mData.des)})

        local scheduleFunc = function ()
		    self:updateTime(self)
	    end

        schedule(self.ccbfile,scheduleFunc,0.5)
    else
        RACityGainManager:setNodeVisible(self.ccbfile,true)
        
        UIExtend.setStringForLabel(self.ccbfile,{mNoBarExplain = _RALang(self.mData.des)})
    end
end

--------------------------cell begin------------------------------
local RACityGainDetailsCell = {}

function RACityGainDetailsCell:new(o)
	o = o or {}
    setmetatable(o,self)
    self.__index = self    
    return o
end

--
function RACityGainDetailsCell:onUseBtn()
    local function callBack(result)
        if result then
            local RAPackageManager = RARequire("RAPackageManager")
            RAPackageManager:sendUseItemByItemId(self.mItemData.id, 1)
        end
    end
    local RAPackageInfoPopUp = RARequire("RAPackageInfoPopUp")
    RAPackageInfoPopUp:useStatusItemHandler(self.mItemData,callBack)
end

function RACityGainDetailsCell:sureBuyAndUse()
    -- body
    local itemConf = self.mItemData
    local RAVIPDataManager = RARequire("RAVIPDataManager")
    local RAPackageData = RARequire("RAPackageData")
    itemConf = RAVIPDataManager.getShopConfByItemId(itemConf.id)--传入的是物品
    local itemData = self.mItemData
    itemData.optionType = RAPackageData.PACKAGE_POP_UP_BTN_STYLE.shopBuy
    itemData.shopId     = itemConf.id
    itemData.price      = itemConf.price
    RAVIPDataManager.Object.SelBuyItemConf=itemData
    
    RARootManager.OpenPage("RAVIPBuyToolsPopup", nil, false, false ,true)
end

--购买并使用
function RACityGainDetailsCell:onBuyBtn()
    local function callBack(result)
        if result then
            self:sureBuyAndUse()
        end
    end
    local RAPackageInfoPopUp = RARequire("RAPackageInfoPopUp")
    RAPackageInfoPopUp:useStatusItemHandler(self.mItemData,callBack)
end

function RACityGainDetailsCell:setNodeVisible(ccbfile,isVisible)
    UIExtend.setNodeVisible(ccbfile,"mUseBtn",isVisible)
    UIExtend.setNodeVisible(ccbfile,"mBuyBtnNode",not isVisible)
end

function RACityGainDetailsCell:onRefreshContent(ccbRoot)
    if not ccbRoot then return end
    local ccbfile = ccbRoot:getCCBFileNode() 
    UIExtend.handleCCBNode(ccbfile)

    local itemConf = self.mItemData
    local itemId = itemConf.id
    local icon = RAMailUtility:getItemIconByid(itemId)
    UIExtend.addSpriteToNodeParent(ccbfile, 'mIconNode', icon)
      
    local bgName  = RALogicUtil:getItemBgByColor(itemConf.item_color)
    UIExtend.addSpriteToNodeParent(ccbfile, 'mQualityNode', bgName)

    local count = RACoreDataManager:getItemCountByItemId(itemId)

    UIExtend.setStringForLabel(ccbfile,{mCellTitle = _RALang(itemConf.item_name)})

    UIExtend.setStringForLabel(ccbfile,{mDetailsExplain = _RALang(itemConf.item_des)})

    local count = RACoreDataManager:getItemCountByItemId(itemId)
    if count >= 1 then
        self:setNodeVisible(ccbfile,true)
    else
        self:setNodeVisible(ccbfile,false)
        UIExtend.setStringForLabel(ccbfile,{mDiamondsNum = itemConf.sellPrice})
    end
    UIExtend.setStringForLabel(ccbfile,{mHaveNum = _RALang("@ItemCurNumber",count)})

end
------------------------------------------------------------------

function RACityGainDetailsPage:addCell()
	self.scrollView:removeAllCell()
    local scrollView = self.scrollView

    local useItemData = RACityGainManager:getCityGainUseItemData(self.mData)

    for k,v in ipairs(useItemData) do
        local cell = CCBFileCell:create()
        cell:setCCBFile("RACityGainDetailsCell.ccbi")
        local panel = RACityGainDetailsCell:new({
	        mTag = k,
            mItemData = v
        })  	  
 
        cell:registerFunctionHandler(panel)
        scrollView:addCell(cell)
    end
    scrollView:orderCCBFileCells()
end

function RACityGainDetailsPage:initTitle()
    local titleCCB = UIExtend.getCCBFileFromCCB(self.ccbfile, "mCommonTitleCCB")
	local RACommonTitleHelper = RARequire('RACommonTitleHelper')
	local backCallBack = function()
		RARootManager.CloseCurrPage()  
	end
    local titleName = _RALang(self.mData.name)
	local titleHandler = RACommonTitleHelper:RegisterCommonTitle('RACityGainDetailsPage', 
    titleCCB, titleName, backCallBack, RACommonTitleHelper.BgType.Blue)
end

function RACityGainDetailsPage:Exit()
	local RACommonTitleHelper = RARequire('RACommonTitleHelper')
    RACommonTitleHelper:RemoveCommonTitle("RACityGainDetailsPage")

    self:removeMessageHandler()

    self.scrollView:removeAllCell()
    self.scrollView = nil

    self.ccbfile:stopAllActions()
    UIExtend.unLoadCCBFile(self)
    self.ccbfile = nil
end

return RACityGainDetailsPage