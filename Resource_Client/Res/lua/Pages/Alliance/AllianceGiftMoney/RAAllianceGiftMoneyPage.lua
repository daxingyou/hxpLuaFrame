--联盟红包页面
RARequire("BasePage")
local UIExtend = RARequire("UIExtend")
local RARootManager = RARequire("RARootManager")
local RAAllianceProtoManager = RARequire("RAAllianceProtoManager")
local GuildManager_pb = RARequire("GuildManager_pb")
local Utilitys = RARequire("Utilitys")
local HP_pb = RARequire("HP_pb")
local RAAllianceUtility = RARequire("RAAllianceUtility")
local RAAllianceGiftMoneyInfo = RARequire("RAAllianceGiftMoneyInfo")
local RAPlayerInfoManager = RARequire("RAPlayerInfoManager")
local RAAllianceGiftMoneyManager = RARequire("RAAllianceGiftMoneyManager")
local guild_const_conf = RARequire("guild_const_conf")

local RAAllianceGiftMoneyPage = BaseFunctionPage:new(...)

local TAB_TYPE = {
        GET = GuildManager_pb.OPEN_TRY,
        LUCKY = GuildManager_pb.LUCKY_TRY,
        HISTORY = GuildManager_pb.FINISH
}

local OnReceiveMessage = function(message)
    if message.messageID == MessageDef_Packet.MSG_Operation_OK then
    elseif message.messageID == MessageDef_Packet.MSG_Operation_Fail then 
    end 
end

function RAAllianceGiftMoneyPage:registerMessage()
    MessageManager.registerMessageHandler(MessageDef_Packet.MSG_Operation_OK,OnReceiveMessage)
    MessageManager.registerMessageHandler(MessageDef_Packet.MSG_Operation_Fail,OnReceiveMessage)
end

function RAAllianceGiftMoneyPage:removeMessageHandler()
    MessageManager.removeMessageHandler(MessageDef_Packet.MSG_Operation_OK,OnReceiveMessage)
    MessageManager.removeMessageHandler(MessageDef_Packet.MSG_Operation_Fail,OnReceiveMessage)
end

--发红包
function RAAllianceGiftMoneyPage:onSendGiftBtn()
    -- body
    RARootManager.OpenPage("RAAllianceGiftMoneyPopUp",nil,false, true, true)
end

--一键开启红包
function RAAllianceGiftMoneyPage:onOpenAllBtn()
    -- body
    local packetId = "all"--self.mData.id
    RAAllianceProtoManager:sendOpenPacketReq(packetId)
end

--是抢红包node的帮助按钮
function RAAllianceGiftMoneyPage:onGetGiftInfoBtn()
    -- body
    -- local confirmData = {}
    -- confirmData.yesNoBtn = false
    -- confirmData.labelText = _RALang('@AllianceGiftMoneyTips')
    -- RARootManager.OpenPage("RAConfirmPage", confirmData,false,true,true)
    RARootManager.OpenPage("RAAllianceHelpCommonPage", {title = '@AllianceRedPackageTitle',content = 'AllianceRedPackageContent'},false,true,true)
end

--一键拼手气按钮啊
function RAAllianceGiftMoneyPage:onLuckyGiftAllBtn()
    -- body
    local packetId = "all"--self.mData.id
    RAAllianceProtoManager:sendPacketLuckyTryReq(packetId)
end

--是拼手气node的帮助按钮
function RAAllianceGiftMoneyPage:onLuckyGiftInfoBtn()
    -- body
    RARootManager.ShowMsgBox(_RALang("@NoOpen"))
end

function RAAllianceGiftMoneyPage:Enter()
	-- body
	UIExtend.loadCCBFile("RAAllianceGiftMoneyPage.ccbi",self)

    self.mNoListLabel = UIExtend.getCCLabelTTFFromCCB(self.ccbfile,'mNoListLabel')
    self.mNoListLabel:setVisible(false)

    self:RegisterPacketHandler(HP_pb.GUILD_RP_GET_INFO_LIST_S)
    self:RegisterPacketHandler(HP_pb.GUILD_RP_OPEN_S)
    self:RegisterPacketHandler(HP_pb.GUILD_RP_LUCKY_TRY_S)
    self:RegisterPacketHandler(HP_pb.GUILD_RP_INFO_SYNC_S)
    
    RAAllianceProtoManager:sendGetRedPacketListReq()

    self:registerMessage()

    self:initTopTitle()

    self:initPage()
end

function RAAllianceGiftMoneyPage:initPage()
	self.tabArr = {} --三个分页签
	self.tabArr[TAB_TYPE.GET] = UIExtend.getCCControlButtonFromCCB(self.ccbfile,'mGetGiftMoneyBtn')
	self.tabArr[TAB_TYPE.LUCKY] = UIExtend.getCCControlButtonFromCCB(self.ccbfile,'mLuckyGiftBtn')
	self.tabArr[TAB_TYPE.HISTORY] = UIExtend.getCCControlButtonFromCCB(self.ccbfile,'mGiftMoneyHistoryBtn')

	self.scrollViews = {} --2个scrollViews
	self.scrollViews[TAB_TYPE.GET] = UIExtend.getCCScrollViewFromCCB(self.ccbfile, "mListSV")
	self.scrollViews[TAB_TYPE.HISTORY] = UIExtend.getCCScrollViewFromCCB(self.ccbfile, "mHistoryListSV")

	for k,v in pairs(self.scrollViews) do
		v:setVisible(false)
	end
end

function RAAllianceGiftMoneyPage:refreshPage()
    -- body
    if self.curPageType == nil then
        self.curPageType = TAB_TYPE.GET
    end
    self:setCurrentPage(self.curPageType)

    --set DiamondsNum
    local playerInfo = RAPlayerInfoManager.getPlayerInfo()
    local surplusGoldStr = _RALang("@SurplusGold",playerInfo.raPlayerBasicInfo.gold)
    UIExtend.setStringForLabel(self.ccbfile, {mOverageDiamondsNum = surplusGoldStr})

end

function RAAllianceGiftMoneyPage:onGetGiftMoneyBtn()
	self:setCurrentPage(TAB_TYPE.GET)
end

function RAAllianceGiftMoneyPage:onLuckyGiftBtn()
	self:setCurrentPage(TAB_TYPE.LUCKY)
end

function RAAllianceGiftMoneyPage:onGiftMoneyHistoryBtn()
	self:setCurrentPage(TAB_TYPE.HISTORY)
end

function RAAllianceGiftMoneyPage:setCurrentPage(pageType)
	-- body
	self.curPageType = pageType

	for k,v in pairs(self.tabArr) do
		if pageType == k then 
			v:setEnabled(false)
		else
			v:setEnabled(true)
		end  
	end

    for k,v in pairs(self.scrollViews) do
        if k == TAB_TYPE.LUCKY then
            k = TAB_TYPE.HISTORY
        end
        self.scrollViews[k]:setVisible(false)
    end

    if pageType == TAB_TYPE.LUCKY then
        self.scrollViews[TAB_TYPE.HISTORY]:setVisible(true)  
    else
       self.scrollViews[pageType]:setVisible(true)     
    end    

    if pageType == TAB_TYPE.GET then 
    	self:initGetPanel()
    elseif pageType == TAB_TYPE.LUCKY then 
    	self:initLuckyPanel()
   	elseif pageType == TAB_TYPE.HISTORY then  
   		self:initHistoryPanel()
	end 

    self:setBtnNodeVisible()
end

function RAAllianceGiftMoneyPage:setBtnNodeVisible()
    -- body
    if self.curPageType == TAB_TYPE.GET then
        UIExtend.setNodeVisible(self.ccbfile,"mGetGiftBtnNode",true)
        UIExtend.setNodeVisible(self.ccbfile,"mLuckyGiftBtnNode",false)

        --set ControlButton title
        UIExtend.setControlButtonTitle(self.ccbfile, "mOpenAllBtn", _RALang("@OpenAllBtnTxt"))
        UIExtend.setControlButtonTitle(self.ccbfile, "mSendGiftBtn", _RALang("@SendGiftBtnTxt"))

    elseif self.curPageType == TAB_TYPE.LUCKY then
        UIExtend.setNodeVisible(self.ccbfile,"mGetGiftBtnNode",false)
        UIExtend.setNodeVisible(self.ccbfile,"mLuckyGiftBtnNode",false)

        --set ControlButton title
        UIExtend.setControlButtonTitle(self.ccbfile, "mLuckyGiftAllBtn", _RALang("@LuckyGiftAllBtnTxt"))
    else
        UIExtend.setNodeVisible(self.ccbfile,"mGetGiftBtnNode",false)
        UIExtend.setNodeVisible(self.ccbfile,"mLuckyGiftBtnNode",false)
    end
end

--
function RAAllianceGiftMoneyPage:initGetPanel()
    self:addCell()
end

function RAAllianceGiftMoneyPage:initLuckyPanel()
    self:addCell()
end

function RAAllianceGiftMoneyPage:initHistoryPanel()
    self:addCell()
end

--初始化顶部
function RAAllianceGiftMoneyPage:initTopTitle()
    -- body
    local titleCCB = UIExtend.getCCBFileFromCCB(self.ccbfile, "mAllianceCommonCCB")
    titleCCB:runAnimation("InAni")
    local mDiamondsNode = UIExtend.getCCNodeFromCCB(titleCCB,'mDiamondsNode')
    mDiamondsNode:setVisible(false)

    local RACommonTitleHelper = RARequire('RACommonTitleHelper')
    local backCallBack = function()
        RARootManager.CloseCurrPage()  
    end
    local titleName = _RALang("@RAAllianceGiftMoneyTitle")
    local titleHandler = RACommonTitleHelper:RegisterCommonTitle('RAAllianceGiftMoneyPage', 
    titleCCB, titleName, backCallBack, RACommonTitleHelper.BgType.Blue)
end

function RAAllianceGiftMoneyPage:Exit()
    self:RemovePacketHandlers()
    self:removeMessageHandler()

    local RACommonTitleHelper = RARequire('RACommonTitleHelper')
    RACommonTitleHelper:RemoveCommonTitle("RAAllianceGiftMoneyPage")

    for _, scrollView in pairs(self.scrollViews) do
        if scrollView then
            scrollView:removeAllCell()
        end
    end
    self.scrollViews = {}

	UIExtend.unLoadCCBFile(self)	
end

function RAAllianceGiftMoneyPage:mAllianceCommonCCB_onBack()
	RARootManager.ClosePage("RAAllianceGiftMoneyPage")
end

-- add cell begin
local RAAllianceGiftMoneyCell = {}

function RAAllianceGiftMoneyCell:new(o)
	-- body
	o = o or {}
	setmetatable(o,self)
	self.__index = self
	return o
end

--------------按钮点击事件处理
--开启红包
function RAAllianceGiftMoneyCell:onOpenBtn()
    -- body
    RARootManager.ShowWaitingPage(true)
    local packetId = self.mData.id
    RAAllianceProtoManager:sendOpenPacketReq(packetId)
end

--查看红包
function RAAllianceGiftMoneyCell:onCheckBtn()
    -- body
    local data = self.mData
    RARootManager.OpenPage("RAAllianceGiftMoneyHistoryPage",{mRedPackageInfo = data},true)
end

--拼手气红包
function RAAllianceGiftMoneyCell:onLuckyBtn()
    -- body
    RARootManager.ShowWaitingPage(true)
    local packetId = self.mData.id
    RAAllianceProtoManager:sendPacketLuckyTryReq(packetId)
end

------------------------------

function RAAllianceGiftMoneyCell:onRefreshContent(ccbRoot)
    if not ccbRoot then return end
    local ccbfile = ccbRoot:getCCBFileNode() 
    UIExtend.handleCCBNode(ccbfile)
    self.ccbfile = ccbfile
    
    local data = self.mData

    --set totalGold
    UIExtend.setStringForLabel(ccbfile, {mHaveNum = data.totalGold})

    --set name
    UIExtend.getCCLabelHTMLFromCCB(ccbfile,"mName"):setString(data.sponsorName)

    --按钮: 开启xx 查看  拼手气
    local playerId = RAPlayerInfoManager.getPlayerId()
    if RAAllianceGiftMoneyPage.curPageType == TAB_TYPE.GET then
        UIExtend.setNodeVisible(ccbfile,"mLuckyBtnNode",false)  
        if data.hasOpen or playerId == data.sponsorId then
            UIExtend.setNodeVisible(ccbfile,"mOpenBtnNode",false)
            UIExtend.setNodeVisible(ccbfile,"mCheckBtnNode",true)  
        else
            UIExtend.setNodeVisible(ccbfile,"mOpenBtnNode",true)
            UIExtend.setNodeVisible(ccbfile,"mCheckBtnNode",false)  

            local redPacketOpenCost = guild_const_conf["redPacketOpenCost"].value
            UIExtend.setStringForLabel(ccbfile, {mNeedNum = redPacketOpenCost})
        end
    elseif RAAllianceGiftMoneyPage.curPageType == TAB_TYPE.LUCKY then
        UIExtend.setNodeVisible(ccbfile,"mOpenBtnNode",false)

        if data.hasLuckyTry then
            UIExtend.setNodeVisible(ccbfile,"mCheckBtnNode",true)
            UIExtend.setNodeVisible(ccbfile,"mLuckyBtnNode",false)  
        else
            UIExtend.setNodeVisible(ccbfile,"mCheckBtnNode",false)   
            UIExtend.setNodeVisible(ccbfile,"mLuckyBtnNode",true)   
        end
    else
        UIExtend.setNodeVisible(ccbfile,"mOpenBtnNode",false)   
        UIExtend.setNodeVisible(ccbfile,"mLuckyBtnNode",false)  
        UIExtend.setNodeVisible(ccbfile,"mCheckBtnNode",true)  
    end

    if data.isOpen then
        UIExtend.getCCSpriteFromCCB(ccbfile,"mOpenPic"):setVisible(true)
        UIExtend.getCCSpriteFromCCB(ccbfile,"mClosePic"):setVisible(false)    
    else
        UIExtend.getCCSpriteFromCCB(ccbfile,"mOpenPic"):setVisible(false)  
        UIExtend.getCCSpriteFromCCB(ccbfile,"mClosePic"):setVisible(true)      
    end  
end

function RAAllianceGiftMoneyPage:addCell()
	-- body

    local data = RAAllianceGiftMoneyManager:getDataByType(self.curPageType)

    --排序
    data = RAAllianceGiftMoneyManager:orderDatas(data,self.curPageType)

    local isNull = false
    for i,v in ipairs(data) do
        if v and v.state ~= 2 then
            isNull = true
        elseif v and v.hasOpen then
            isNull = true
        end
    end
    if isNull then
        local pageType = TAB_TYPE.HISTORY
        if self.curPageType ~= TAB_TYPE.LUCKY then
            pageType = self.curPageType
        end
        self.scrollViews[pageType]:removeAllCell()
        local scrollView = self.scrollViews[pageType]
        for k,v in ipairs(data) do
        --for i = 1,10 do
            --没有开启过红包的人，不显示在拼手气的cell里面
            if v.state ~= 2 then
                local cell = CCBFileCell:create()
                cell:setCCBFile("RAAllianceGiftMoneyCell.ccbi")
                local panel = RAAllianceGiftMoneyCell:new({
                    mData = v
                })
                cell:registerFunctionHandler(panel)
                
                scrollView:addCell(cell)
            else
                if v.hasOpen then
                    local cell = CCBFileCell:create()
                    cell:setCCBFile("RAAllianceGiftMoneyCell.ccbi")
                    local panel = RAAllianceGiftMoneyCell:new({
                        mData = v
                    })
                    cell:registerFunctionHandler(panel)
                    
                    scrollView:addCell(cell)
                end
            end
        end
        self.mNoListLabel:setVisible(false) 
        scrollView:orderCCBFileCells()
    else
         for k,v in pairs(self.scrollViews) do
            v:setVisible(false)
         end
         self.mNoListLabel:setVisible(true) 
         if self.curPageType == TAB_TYPE.GET then
            self.mNoListLabel:setString(_RALang("@NoGrabRedPackage"))
         elseif self.curPageType == TAB_TYPE.LUCKY then
            self.mNoListLabel:setString(_RALang("@NoLuckyRedPackage"))
         elseif self.curPageType == TAB_TYPE.HISTORY then
            self.mNoListLabel:setString(_RALang("@NoRecordRedPackage"))
         end
    end
end

function RAAllianceGiftMoneyPage:onReceivePacket(handler)
    local pbCode = handler:getOpcode()
    local buffer = handler:getBuffer()
    if pbCode == HP_pb.GUILD_RP_GET_INFO_LIST_S then           --获得红包数据
        local msg = GuildManager_pb.GetRedPacketListResp()
        msg:ParseFromString(buffer)
        
        RAAllianceGiftMoneyManager:initData(msg)
    elseif pbCode == HP_pb.GUILD_RP_OPEN_S then     --开启红包
        local msg = GuildManager_pb.OpenPacketResp()
        msg:ParseFromString(buffer)   

        --TODO...
        if msg.success then
            --local result = _RALang("@OpenSuccess")..msg.getGold
            --RARootManager.ShowMsgBox(result)
            --RARootManager.OpenPage("RAAllianceGiftMoneyOpenAniPage",{diamonds = msg.getGold},false,true,true)
            RARootManager.OpenPage("RAAllianceGiftMoneyOpenAniPage",{diamonds = msg.getGold})
        else
            RARootManager.ShowMsgBox(_RALang("@OpenFail"))    
        end
    elseif pbCode == HP_pb.GUILD_RP_LUCKY_TRY_S then  --拼手气红包
        local msg = GuildManager_pb.PacketLuckyTryResp()
        msg:ParseFromString(buffer)   

        RARootManager.OpenPage("RAAllianceGiftMoneyOpenAniPage",{diamonds = msg.luckyGold})
    elseif pbCode == HP_pb.GUILD_RP_INFO_SYNC_S then  --联盟红包信息推送
        local msg = GuildManager_pb.RedPacketInfo()
        msg:ParseFromString(buffer)

        RAAllianceGiftMoneyManager:update(msg)

        MessageManager.sendMessage(MessageDef_Alliance.MSG_Alliance_RedPackage_Change)
    end
    self:refreshPage()
    
    RARootManager.RemoveWaitingPage()
end

return RAAllianceGiftMoneyPage