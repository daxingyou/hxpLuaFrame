RARequire("BasePage")
local RAPlayerInfoManager = RARequire("RAPlayerInfoManager")
local UIExtend = RARequire("UIExtend")
local RALogicUtil = RARequire("RALogicUtil")
local Utilitys = RARequire("Utilitys")
local player_details_conf = RARequire("player_details_conf")
local RAStringUtil = RARequire("RAStringUtil")
local RARootManager = RARequire("RARootManager")
local RALordBasicPage = BaseFunctionPage:new(...)

-----------------------------------------------------------
local RADetailPlayerInfoTitleCellListener = {
    id = 0
}

function RADetailPlayerInfoTitleCellListener:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    return o
end 

function RADetailPlayerInfoTitleCellListener:onRefreshContent(ccbRoot)
    local confInfo = player_details_conf[self.id]

	local ccbfile = ccbRoot:getCCBFileNode() 
    if ccbfile then
        UIExtend.setCCLabelString(ccbfile, "mInformationTitle", _RALang(confInfo.name))

        

    end
end


------------------------------------------------------------
local RADetailPlayerInfoCellListener = {
    id = 0
}

function RADetailPlayerInfoCellListener:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    return o
end

function RADetailPlayerInfoCellListener:onRefreshContent(ccbRoot)
	local ccbfile = ccbRoot:getCCBFileNode() 
    if not ccbfile then
        return
    end
    self.ccbfile = ccbfile

    local tipsBtn = UIExtend.getCCControlButtonFromCCB(ccbfile,"mTipsBtn")
     
    local containsPoint = function ( worldPos )
        local scrollView = self.scrollView
        return UIExtend.scrollViewContainPoint(scrollView, worldPos)
    end       
    UIExtend.createClickNLongClick(tipsBtn,RADetailPlayerInfoCellListener.onShortClick,
    RADetailPlayerInfoCellListener.onLongClick,{handler = self, endedColse = true,delay = 0.0, containsPoint = containsPoint})

    local confInfo = player_details_conf[self.id]
    UIExtend.setCCLabelString(ccbfile, "mDetailTitle", _RALang(confInfo.name))
    if confInfo.effect ~= nil then
        --根据effect 查找影响因子
        local effectNum = RALogicUtil:getLordDetailInfo(confInfo.effect)
        if confInfo.numType == 1 then
            effectNum = effectNum * 100
            effectNum = effectNum.."%"
        end
        UIExtend.setCCLabelString(ccbfile, "mDetailNum", effectNum)
    end
end

function RADetailPlayerInfoCellListener.onLongClick(data)
    local handler = data.handler
    local confInfo = player_details_conf[handler.id]

    local paramMsg = {}
    paramMsg.title = _RALang(confInfo.name)
    paramMsg.htmlStr = _RALang(confInfo.des)
    paramMsg.relativeNode = handler.ccbfile
    RARootManager.ShowTips(paramMsg)
end

function RADetailPlayerInfoCellListener.onShortClick(data)
   RARootManager.RemoveTips()  
end
------------------------------------------------------------------

local OnReceiveMessage = function(message)
    if message.messageID == MessageDef_Lord.MSG_RefreshName then
        RALordBasicPage:refreshName()
    elseif message.messageID == MessageDef_Lord.MSG_RefreshHeadImg then
        RALordBasicPage:refreshHeadImg()
    end
end

function RALordBasicPage:Enter(data)
    self.ccbifile = UIExtend.loadCCBFile("RALordInformationPage.ccbi", RALordBasicPage)
    self.scrollView = UIExtend.getCCScrollViewFromCCB(self.ccbifile, "DetailDataSV")
    UIExtend.setCCLabelString(self.ccbifile, "mInfoTitle", _RALang("@CommanderDetails"))

    
    self:refreshUI()
    self:addHandler()
end

function RALordBasicPage:addHandler()
    MessageManager.registerMessageHandler(MessageDef_Lord.MSG_RefreshName, OnReceiveMessage)
    MessageManager.registerMessageHandler(MessageDef_Lord.MSG_RefreshHeadImg, OnReceiveMessage)

end
function RALordBasicPage:removeHanlder()
    MessageManager.removeMessageHandler(MessageDef_Lord.MSG_RefreshName, OnReceiveMessage)
    MessageManager.removeMessageHandler(MessageDef_Lord.MSG_RefreshHeadImg, OnReceiveMessage)
end

function RALordBasicPage:refreshUI()
    self:refreshTitleBar()
    self:refreshDetail()    
end

function RALordBasicPage:onClose()
    RARootManager.ClosePage("RALordBasicPage")
end

function RALordBasicPage:refreshTitleBar()
    local playerInfo = RAPlayerInfoManager.getPlayerBasicInfo()
    UIExtend.setCCLabelString(self.ccbifile, "mUserName", playerInfo.name)
    UIExtend.setCCLabelString(self.ccbifile, "mKingdomNum", RAPlayerInfoManager.getKingdomName())
    UIExtend.setCCLabelString(self.ccbifile, "mUserLevel", playerInfo.level)

    UIExtend.setNodeVisible(self.ccbifile,"mAllianceNode",false)
    local RAAllianceManager = RARequire("RAAllianceManager")
    if RAAllianceManager.selfAlliance then
        UIExtend.setNodeVisible(self.ccbifile,"mAllianceNode",true)
        UIExtend.setCCLabelString(self.ccbifile, "mAlliance", RAAllianceManager.selfAlliance.name)
    end

    local totalPower = RAPlayerInfoManager.getPlayerFightPower()--todo:总战斗力
    local pwStr = RAStringUtil:getLanguageString("@BattlePointX", totalPower)
    UIExtend.setCCLabelString(self.ccbifile, "mFightValue", pwStr)

    local achivement = 0--todo:成就完成度
    local achiStr = RAStringUtil:getLanguageString("@AchieveCompleted", achivement)
    UIExtend.setCCLabelString(self.ccbifile, "mAchieveCompleted", achiStr)
    UIExtend.setNodeVisible(self.ccbifile, "mAchieveCompleted", false)

    local killArmyNum = 0--todo：消灭敌军数
    local killArmyStr = RAStringUtil:getLanguageString("@DistroyEnemy", killArmyNum)
    UIExtend.setCCLabelString(self.ccbifile, "mDistroyEnemy", killArmyStr)

    self:refreshHeadImg()

    UIExtend.setNodesVisible(self.ccbfile, {
        mChangeIcon = true,
        mReplaceImageBtn = true
    })
end

function RALordBasicPage:refreshName()
    local playerInfo = RAPlayerInfoManager.getPlayerBasicInfo()
    if self.ccbifile then
        UIExtend.setCCLabelString(self.ccbifile, "mUserName", playerInfo.name)
    end
end

function RALordBasicPage:refreshHeadImg()
    local icon = RAPlayerInfoManager.getPlayerBust()
    if self.ccbifile then
        UIExtend.setSpriteIcoToNode(self.ccbifile, "mUserBustPic", icon)
    end
end

function RALordBasicPage:refreshDetail()
    self.scrollView:removeAllCell()
    for k, v in Utilitys.table_pairsByKeys(player_details_conf) do
        if v.site == 0 then
            local titleListener = RADetailPlayerInfoTitleCellListener:new({id = v.id})
            local cell = CCBFileCell:create()
	        cell:setCCBFile("RALordInformationTitleCell.ccbi")
            cell:registerFunctionHandler(titleListener)

            self.scrollView:addCell(cell)
        else
            local detalListener = RADetailPlayerInfoCellListener:new({id = v.id, scrollView = self.scrollView})
            local cell = CCBFileCell:create()
	        cell:setCCBFile("RALordInformationCell.ccbi")
            cell:registerFunctionHandler(detalListener)

            self.scrollView:addCell(cell)
        end
    end
    self.scrollView:orderCCBFileCells()
end

function RALordBasicPage:onChangeNameBtn()
    RARootManager.OpenPage("RALordChangeNamePage", nil,false,false)
end

function RALordBasicPage:onReplaceImageBtn()
    RARootManager.OpenPage("RALordHeadChangePage", nil,false,true)
end

function RALordBasicPage:Exit(data)
    self:removeHanlder()
    self.scrollView:removeAllCell()
    self.scrollView = nil
    UIExtend.unLoadCCBFile(RALordBasicPage)
    self.ccbifile = nil
end


