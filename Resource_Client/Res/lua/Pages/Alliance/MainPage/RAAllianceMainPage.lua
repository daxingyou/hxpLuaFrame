--to:联盟主页
RARequire("BasePage")
local UIExtend = RARequire("UIExtend")
local RAAllianceProtoManager = RARequire("RAAllianceProtoManager")
local RARootManager = RARequire("RARootManager")
local RAAllianceManager = RARequire('RAAllianceManager')
local HP_pb = RARequire('HP_pb')
local alliance_language_conf = RARequire('alliance_language_conf')
local Utilitys = RARequire('Utilitys')
local RANetUtil = RARequire("RANetUtil")
local GuildManager_pb = RARequire('GuildManager_pb')
local RAAllianceUtility = RARequire('RAAllianceUtility')
RARequire('MessageManager')
local RAAllianceMainCell = {}
--------------------RAAllianceMainCell------------------

function RAAllianceMainCell:onRefreshContent(ccbRoot)
    CCLuaLog("RAAllianceMainCell:onRefreshContent()")
    UIExtend.handleCCBNode(ccbRoot:getCCBFileNode())

    self.ccbfile = ccbRoot:getCCBFileNode() 
    UIExtend.getCCNodeFromCCB(self.ccbfile,'mBusinessTipsNode'):setVisible(false)
    UIExtend.getCCNodeFromCCB(self.ccbfile,'mLetterTipsNode'):setVisible(false) 
    UIExtend.getCCNodeFromCCB(self.ccbfile,'mTechnolegyNode'):setVisible(false) 
    UIExtend.getCCNodeFromCCB(self.ccbfile,'mGiftMoneyTipsNode'):setVisible(false) 
    --UIExtend.getCCNodeFromCCB(self.ccbfile,'mManagerTipsNode'):setVisible(false) 

    self:updateHelpNum()     
end 

function RAAllianceMainCell:updateHelpNum()
    if self.ccbfile ~= nil then 
        if RAAllianceManager.helpNum <=0 then 
            UIExtend.getCCNodeFromCCB(self.ccbfile,'mHelpTipsNode'):setVisible(false) 
        else
            UIExtend.getCCNodeFromCCB(self.ccbfile,'mHelpTipsNode'):setVisible(true)
            UIExtend.getCCLabelTTFFromCCB(self.ccbfile,'mHelpTipsNum'):setString(RAAllianceManager.helpNum) 
        end   

        --联盟管理中联盟申请红点
        if RAAllianceManager.applyNum <=0 then 
            UIExtend.getCCNodeFromCCB(self.ccbfile,'mManagerTipsNode'):setVisible(false) 
        else
            UIExtend.getCCNodeFromCCB(self.ccbfile,'mManagerTipsNode'):setVisible(true)
            UIExtend.getCCLabelTTFFromCCB(self.ccbfile,'mManagerTipsNum'):setString(RAAllianceManager.applyNum) 
        end   
    end 
end 

function RAAllianceMainCell:onAllianceLetterBtn()
    CCLuaLog("RAAllianceMainCell:onAllianceLetterBtn()")
    -- RARootManager.ShowMsgBox('@NoOpenTips')
    RARootManager.OpenPage("RAMailWritePage",{sendName =_RALang("@SendAllianceMems"),isSendAllianceMems=true})
end

function RAAllianceMainCell:onAllianceTechnologyBtn()
    RARootManager.OpenPage("RAAllianceStatuePage")
end

function RAAllianceMainCell:onAllianceGiftMoneyBtn()
    local isPermission = RAAllianceUtility:isAbleToSendOutRedPackage(RAAllianceManager.authority)
    local guild_const_conf = RARequire("guild_const_conf")
    local redPacketAllianceLevel = guild_const_conf['redPacketAllianceLevelRequire'].value
    if not isPermission then
        RARootManager.ShowMsgBox(_RALang("@PermissionNotEnough"))
    elseif RAAllianceManager.selfAlliance.level < redPacketAllianceLevel then
        RARootManager.ShowMsgBox(_RALang("@AllianceLevelNotEnough"))    
    else
        RARootManager.OpenPage("RAAllianceGiftMoneyPage")    
    end
end

function RAAllianceMainCell:onAllianceHelpBtn()
    RARootManager.OpenPage("RAAllianceHelpPage")
end

function RAAllianceMainCell:onAllianceLeaveMsgBtn()
    RARootManager.OpenPage("RAAllianceLeaveMsgPage",{allianceId = RAAllianceManager.selfAlliance.id})
end

function RAAllianceMainCell:onAllianceApplicationBtn()
    CCLuaLog("RAAllianceMainCell:onAllianceApplicationBtn()")
    RARootManager.OpenPage("RAAllianceApplicationPage")
end

function RAAllianceMainCell:onAllianceBusinessBtn()
    CCLuaLog("RAAllianceMainCell:onAllianceBusinessBtn()")
end

--联盟管理
function RAAllianceMainCell:onAllianceManagerBtn()
    RARootManager.OpenPage("RAAllianceManagerPage",{authorityId = RAAllianceManager.authority},false, true, true)
end




local RAAllianceMainPage = BaseFunctionPage:new(...)

function RAAllianceMainPage:Enter(data)
	local ccbfile = UIExtend.loadCCBFile("RAAlliancePageNew.ccbi",self)
    self.scrollView = UIExtend.getCCScrollViewFromCCB(self.ccbfile, "mAllianceMainListSV")
    
    -- self.mDiamondsNode = UIExtend.getCCNodeFromCCB(self.ccbfile:getCCBFileFromCCB("mCommonCommonCCB"),'mDiamondsNode')
    -- self.mDiamondsNode:setVisible(false)

    --加入联盟 有几率出现页面误点击事件
    RARootManager.RemoveCoverPage()

    --联盟名字 + 联盟等级
    self.mAllianceName = UIExtend.getCCLabelTTFFromCCB(self.ccbfile,'mAllianceName')
    self.mAllianceName:setString('')

    --联盟盟主名字
    self.mAllianceLeaderName = UIExtend.getCCLabelTTFFromCCB(self.ccbfile,'mAllianceLeaderName')
    self.mAllianceLeaderName:setString('')

    --联盟战力
    self.mAllianceFightValue = UIExtend.getCCLabelTTFFromCCB(self.ccbfile,'mAllianceFightValue')
    self.mAllianceFightValue:setString('')

    --联盟等级
    --self.mAllianceLevel = UIExtend.getCCLabelTTFFromCCB(self.ccbfile,'mAllianceLevel')
    --self.mAllianceLevel:setString('')

    --联盟人数
    self.mMemNum = UIExtend.getCCLabelTTFFromCCB(self.ccbfile,'mMemNum')
    self.mMemNum:setString('')

    --联盟类型 策略
    self.mStrategy = UIExtend.getCCLabelTTFFromCCB(self.ccbfile,'mStrategy')
    self.mStrategy:setString('')

    self.mAllianceIconNode = self.ccbfile:getCCNodeFromCCB('mAllianceIconNode')

    self.mBtnsNode = UIExtend.getCCNodeFromCCB(self.ccbfile,'mBtnNode')
    self.mButtonBannerNode = UIExtend.getCCNodeFromCCB(self.ccbfile,'mButtonBannerNode')
    --self.mListNode = UIExtend.getCCNodeFromCCB(self.ccbfile,'mListNode')
    --联盟公告
    -- self.mAnnouncement = UIExtend.getCCLabelTTFFromCCB(self.ccbfile,'mAnnouncement')
    -- self.mAnnouncement:setString('')
    self.mAnnouncement = UIExtend.getCCLabelTTFFromCCB(self.ccbfile,'mAllianceReport')
    self.mAnnouncement:setString('')

    --联盟日志
    self.mAllianceHistory = UIExtend.getCCLabelTTFFromCCB(self.ccbfile,'mAllianceLabel')
    self.mAllianceHistory:setString('')

    --self.mAllianceHistory2 = UIExtend.getCCLabelTTFFromCCB(self.ccbfile,'mAllianceLabel2')
    --self.mAllianceHistory2:setString('')

    --self.mAllianceHistory3 = UIExtend.getCCLabelTTFFromCCB(self.ccbfile,'mAllianceLabel3')
    --self.mAllianceHistory3:setString('')


    self.netHandlers = {}
    --self:refreshUI()

    self:initTitle()
    self:addHandler()
    self:registerMessage()
    self:addCell()
    self:initAllianceHistory()
    self:updateRedPoint()
    --请求联盟信息
    RAAllianceProtoManager:getAllianceReq(RAAllianceManager.selfAlliance.id)
    --请求联盟日志
    RAAllianceProtoManager:getAllianceLogReg()
end

function RAAllianceMainPage:updateRedPoint()
    -- body
    UIExtend.getCCNodeFromCCB(self.ccbfile,'mMemHotNode'):setVisible(false)
    UIExtend.getCCNodeFromCCB(self.ccbfile,'mTerritoryHotNode'):setVisible(false)
    UIExtend.getCCNodeFromCCB(self.ccbfile,'mWarHotNode'):setVisible(false)
    UIExtend.getCCNodeFromCCB(self.ccbfile,'mAllianceShopHotNode'):setVisible(false)

    self:updateWarNum()
end

function RAAllianceMainPage:initAllianceHistory()
    --self.mHistoryCloseNode = UIExtend.getCCNodeFromCCB(self.ccbfile,'mHistoryCloseNode')
    self.mHistoryOpenNode = UIExtend.getCCNodeFromCCB(self.ccbfile,'mHistoryOpenNode')
    --self.mOpenBottomNode = UIExtend.getCCNodeFromCCB(self.ccbfile,'mOpenBottomNode')
    self.mHistoryDetailsListSV = UIExtend.getCCScrollViewFromCCB(self.ccbfile, "mHistoryDetailsListSV")
    self:setHistoryPanel(false)
end

local OnReceiveMessage = function(message)
    if message.messageID == MessageDef_Packet.MSG_Operation_OK then
        if message.opcode == HP_pb.GUILDMANAGER_POSTNOTICE_C then 
            RAAllianceManager.selfAlliance.notice = RAAllianceManager.tempAnnouncement
            RAAllianceManager.tempAnnouncement = ''
            RAAllianceMainPage:refreshAnnouncement()
        end 
    elseif message.messageID == MessageDef_AlliancePage.MSG_RefreshMainPage then
        RAAllianceMainPage:refreshUI()
    elseif message.messageID == MessageDef_Alliance.MSG_Alliance_KickOut then   
        RAAllianceMainPage:onKickOut()  
    elseif message.messageID == MessageDef_AllianceWar.MSG_WAR_REDPOINT then 
        RAAllianceMainPage:updateWarNum()
    elseif message.messageID == MessageDef_Alliance.MSG_Alliance_HelpNum_Change then 
        RAAllianceMainCell:updateHelpNum()
    end 
end

function RAAllianceMainPage:updateWarNum()
    -- body
    local RANewAllianceWarManager =  RARequire('RANewAllianceWarManager')
    local num = RANewAllianceWarManager:GetRedPointNum()

    if num <=0 then 
        UIExtend.getCCNodeFromCCB(self.ccbfile,'mWarHotNode'):setVisible(false) 
    else
        UIExtend.getCCNodeFromCCB(self.ccbfile,'mWarHotNode'):setVisible(true)
        UIExtend.getCCLabelTTFFromCCB(self.ccbfile,'mWarNum'):setString(num) 
    end  
end

--玩家被踢出
function RAAllianceMainPage:onKickOut()
    -- body
    onConfirm = function()
        RARootManager.CloseAllPages()
    end

    local confirmData = {}
    confirmData.labelText = _RALang("@KickOutAllinceTxt")
    confirmData.title = _RALang("@KickOutAllinceTitleTxt")
    confirmData.resultFun = function (isOk)
        onConfirm()
    end
    RARootManager.OpenPage("RAConfirmPage", confirmData)
end

function RAAllianceMainPage:setHistoryPanel(isOpen)
    self.isHistoryOpen = isOpen

    -- if self.isHistoryOpen then 
    self.mHistoryOpenNode:setVisible(self.isHistoryOpen)
    --self.mOpenBottomNode:setVisible(self.isHistoryOpen)
    --self.mHistoryCloseNode:setVisible(not self.isHistoryOpen)
    --self.mListNode:setVisible(not self.isHistoryOpen)
    self.mBtnsNode:setVisible(self.isHistoryOpen)
    self.scrollView:setVisible(not self.isHistoryOpen)
    self.mButtonBannerNode:setVisible(not self.isHistoryOpen)

    if self.isHistoryOpen then 
        RAAllianceProtoManager:getAllianceLogReg()
    end 
end

function RAAllianceMainPage:refreshHistory()
    self.mHistoryDetailsListSV:removeAllCell()

    local RAAllianceHistoryCell = RARequire('RAAllianceHistoryCell')

    for i=#self.logs,1,-1 do

        local cell = CCBFileCell:create()
        local ccbiStr = "RAAllianceMainHistoryCellNew.ccbi"
        cell:setCCBFile(ccbiStr)
        local panel = RAAllianceHistoryCell:new()
        -- panel.cellType = 1
        panel.info = self.logs[i]
        cell:registerFunctionHandler(panel)
        self.mHistoryDetailsListSV:addCell(cell)
    end

    self.mHistoryDetailsListSV:orderCCBFileCells()

    if #self.logs == 0 then 
        self.mAllianceHistory:setString('')
        --self.mAllianceHistory2:setString('')
        --self.mAllianceHistory3:setString('')
    else
        local size = #self.logs
        local text = RAAllianceUtility:getLogText(self.logs[size])
        if text ~= '' then
            --self.mAllianceHistory:setString(text)
            text = self:getSubString(text)
        end

        local nSize = 0
        for w in string.gmatch(text, '\n') do
            nSize = nSize + 1
        end
        local text2 = RAAllianceUtility:getLogText(self.logs[size-1])
        if text2 ~= '' and nSize < 3 then
            --self.mAllianceHistory2:setString(text2)
            text = text .. "\n" .. text2
        end

        local nSize2 = 0
        for w in string.gmatch(text, '\n') do
            nSize2 = nSize2 + 1
        end
        local text3 = RAAllianceUtility:getLogText(self.logs[size-2])
        if text3 ~= '' and nSize2 < 3 then
            --self.mAllianceHistory3:setString(text3)
            text3 = self:getSubString(text3)
            text = text .. "\n" .. text3
        end

        self.mAllianceHistory:setString(text)
        self.mAllianceHistory:setHorizontalAlignment(kCCTextAlignmentLeft)
    end 
end

function RAAllianceMainPage:getSubString( subString )
    -- body
     local num = GameMaths:calculateNumCharacters(subString)

    if num > 90 then 
        -- subString =  GameMaths:getStringSubNumCharacters(subString,0,90)
        -- subString = subString ..'...'
       subString = Utilitys.autoReturn(subString, 45, 1)
    end 
    return subString
end

function RAAllianceMainPage:onHistoryCloseBtn()
    self:setHistoryPanel(false)
end

function RAAllianceMainPage:onAnnouncement()
    self:setHistoryPanel(true)
end

function RAAllianceMainPage:mCommonTitleCCB_onBack()
    RARootManager.CloseCurrPage()
end

function RAAllianceMainPage:addHandler()
    self.netHandlers[#self.netHandlers + 1] = RANetUtil:addListener(HP_pb.GUILDMANAGER_GETINFO_S, RAAllianceMainPage) --加入联盟
    self.netHandlers[#self.netHandlers + 1] = RANetUtil:addListener(HP_pb.GUILDMANAGER_GETMEMBERINFO_S, RAAllianceMainPage)
    self.netHandlers[#self.netHandlers + 1] = RANetUtil:addListener(HP_pb.GUILD_GETLOG_S, RAAllianceMainPage)
end

function RAAllianceMainPage:registerMessage()
    MessageManager.registerMessageHandler(MessageDef_Packet.MSG_Operation_OK,OnReceiveMessage)
    MessageManager.registerMessageHandler(MessageDef_AlliancePage.MSG_RefreshMainPage,OnReceiveMessage)
    MessageManager.registerMessageHandler(MessageDef_Alliance.MSG_Alliance_KickOut,OnReceiveMessage)
    MessageManager.registerMessageHandler(MessageDef_Alliance.MSG_Alliance_HelpNum_Change,OnReceiveMessage)
    MessageManager.registerMessageHandler(MessageDef_AllianceWar.MSG_WAR_REDPOINT,OnReceiveMessage)
end

function RAAllianceMainPage:removeMessageHandler()
    MessageManager.removeMessageHandler(MessageDef_Packet.MSG_Operation_OK,OnReceiveMessage)
    MessageManager.removeMessageHandler(MessageDef_AlliancePage.MSG_RefreshMainPage,OnReceiveMessage)
    MessageManager.removeMessageHandler(MessageDef_Alliance.MSG_Alliance_KickOut,OnReceiveMessage)
    MessageManager.removeMessageHandler(MessageDef_Alliance.MSG_Alliance_HelpNum_Change,OnReceiveMessage)
    MessageManager.removeMessageHandler(MessageDef_AllianceWar.MSG_WAR_REDPOINT,OnReceiveMessage)
end


    --移除
function RAAllianceMainPage:removeHandler()
    
    for k, value in pairs(self.netHandlers) do
        RANetUtil:removeListener(value)
    end

end

function RAAllianceMainPage:onReceivePacket(handler)
    local pbCode = handler:getOpcode()
    local buffer = handler:getBuffer()
    if pbCode == HP_pb.GUILDMANAGER_GETINFO_S then --
        local msg = GuildManager_pb.GetGuildInfoResp()
        msg:ParseFromString(buffer)

        if RAAllianceManager.selfAlliance == nil then 
            local RAAllianceInfo = RARequire('RAAllianceInfo')
            RAAllianceManager.selfAlliance = RAAllianceInfo:new()
        end 

        if msg.id == RAAllianceManager.selfAlliance.id then 
            RAAllianceManager.selfAlliance:initByPb(msg)
            self:refreshUI()
        end 
    elseif pbCode == HP_pb.GUILDMANAGER_GETMEMBERINFO_S then --获得联盟成员

        if  RARootManager.CheckIsPageOpening('RAAllianceMainPage') then 
            local memberInfos,leaderNames = RAAllianceProtoManager:getGuildMemeberInfoResp(buffer)
            RARootManager.OpenPage("RAAllianceMemberPage",{memberInfos=memberInfos,leaderNames = leaderNames,contentType=0})
        end 
    elseif pbCode == HP_pb.GUILD_GETLOG_S then --获得日志
        local logs = RAAllianceProtoManager:getAllianceLogResp(buffer)
        self.logs = logs

        self:refreshHistory()
    end
end

--等级说明
function RAAllianceMainPage:onLevelTipsBtn()

    --_RALang('@AllianceLevelTipsTitle')
    -- local confirmData = {}
    -- confirmData.yesNoBtn = false
    -- confirmData.labelText = _RALang('@AllianceLevelTips')
    RARootManager.OpenPage("RAAllianceLevelPage", confirmData,false,true,true)
end

--联盟说明
function RAAllianceMainPage:onMemTipsBtn()
    --_RALang('@AllianceMemberNumTipsTitle')
    local confirmData = {}
    confirmData.yesNoBtn = false
    confirmData.labelText = _RALang('@AllianceMemberNumTips')
    RARootManager.OpenPage("RAConfirmPage", confirmData,false,true,true)
end

function RAAllianceMainPage:refreshUI()
    self.mAllianceLeaderName:setString('('.. RAAllianceManager.selfAlliance.tag .. ')' .. RAAllianceManager.selfAlliance.leaderName)
    local powerString = Utilitys.formatNumber(RAAllianceManager.selfAlliance.power)
    self.mAllianceFightValue:setString(powerString)
    self.mMemNum:setString(RAAllianceManager.selfAlliance.memberNum .. '/' .. RAAllianceManager.selfAlliance.memberMaxNum)

   -- self.mAllianceLevel:setString('Lv.' .. RAAllianceManager.selfAlliance.level)
   local allianceNameAndLevelStr = RAAllianceManager.selfAlliance.name .. '('.. RAAllianceManager.selfAlliance.tag .. ') Lv.' .. RAAllianceManager.selfAlliance.level
   self.mAllianceName:setString(allianceNameAndLevelStr)

    -- local languageName = RAAllianceUtility:getLanguageIdByName(RAAllianceManager.selfAlliance.language)
    -- if languageName ~= nil then
    --     self.mLanguage:setString(languageName)
    -- end

    local allianceTypeName = _RALang('@AllianceTypeDeveloping')
    if RAAllianceManager.selfAlliance.guildType == GuildManager_pb.STRATEGIC then
        allianceTypeName = _RALang('@AllianceTypeStrategic')
    elseif RAAllianceManager.selfAlliance.guildType == GuildManager_pb.FIGHTING then
        allianceTypeName = _RALang('@AllianceTypeFighting')
    end
    self.mStrategy:setString(allianceTypeName) 

    --UIExtend.setCCLabelString(self.ccbfile:getCCBFileFromCCB("mAllianceCommonCCB"),'mTitle',RAAllianceManager.selfAlliance.name)

    if RAAllianceUtility:isCanEditAnnouncement(RAAllianceManager.authority) then 
        self.ccbfile:getCCControlButtonFromCCB('mEditAnnoumentBtn'):setVisible(true)
    else 
        self.ccbfile:getCCControlButtonFromCCB('mEditAnnoumentBtn'):setVisible(false)
    end

    local contentSize = self.mAllianceIconNode:getContentSize()
    if self.flagIcon == nil then 
        self.flagIcon = CCSprite:create()
        self.flagIcon:setAnchorPoint(ccp(0.5,0.5))
        self.flagIcon:setPosition(contentSize.width/2,contentSize.height/2)
        self.mAllianceIconNode:addChild(self.flagIcon)
    end  

    local flagName = RAAllianceUtility:getAllianceFlagIdByIcon(RAAllianceManager.selfAlliance.flag)
    self.flagIcon:setTexture(flagName)

    self.mAnnouncement:setString(RAAllianceManager.selfAlliance.notice)
    self:refreshAnnouncement()
    
    local flagIconSize = self.flagIcon:getContentSize()
    self.flagIcon:setScaleX(contentSize.width/flagIconSize.width)
    self.flagIcon:setScaleY(contentSize.height/flagIconSize.height)
end

function RAAllianceMainPage:refreshAnnouncement()
    -- RAAllianceManager.selfAlliance.notice = RAAllianceManager.selfAlliance.notice .. '\n' .. 'dddddddddddddddd'

    local startIndex=string.find(RAAllianceManager.selfAlliance.notice,'\n') 

    local subString = nil
    if startIndex ~= nil then 
        subString = string.sub(RAAllianceManager.selfAlliance.notice,0,startIndex-1)
    else
        subString = RAAllianceManager.selfAlliance.notice  
    end 
    
    -- local subString = string.find()
    local num = GameMaths:calculateNumCharacters(subString)

    if num >43 then 
        local text =  GameMaths:getStringSubNumCharacters(subString,0,43)
        self.mAnnouncement:setString(text .. '...')
    else 
        self.mAnnouncement:setString(subString)
    end 
end

function RAAllianceMainPage:onMemBtn()
    -- CCLuaLog('联盟成员')
    RAAllianceProtoManager:getGuildMemeberInfoReq(RAAllianceManager.selfAlliance.id)
end

function RAAllianceMainPage:onCheckAnnouncementBtn()
    -- CCLuaLog('查看编辑')
    RARootManager.OpenPage("RAAllianceEditAnnouncePage",{text = RAAllianceManager.selfAlliance.notice,pageType = 0})
    -- self:setHistoryPanel(not self.isHistoryOpen)
end

--联盟领地
function RAAllianceMainPage:onTerritoryBtn()

    local territoryData = RAAllianceManager:getManorDataById(RAAllianceManager.selfAlliance.manorId)
    -- local territoryData = RAAllianceManager:getManorDataById(1)
    if territoryData == nil then 
        RARootManager.ShowMsgBox('@NoHaveAllianceTerritoryInfo')
        -- RARootManager.ShowMsgBox('@我的天哪我的天哪我的天!哪我的天哪')
        -- RARootManager.ShowMsgBox('@联盟还未占领任何联盟领地！')
    else 
        RARootManager.OpenPage("RAAllianceManorPage",territoryData)
    end 

end

--联盟战争
function RAAllianceMainPage:onWarBtn()
    RARootManager.OpenPage("RANewAllianceWarPage")
end

--联盟商城
function RAAllianceMainPage:onStoreBtn()
    RARootManager.OpenPage("RAAllianceShopPage")
end

function RAAllianceMainPage:onEditAnnoumentBtn()
    RARootManager.OpenPage("RAAllianceEditAnnouncePage",{text = RAAllianceManager.selfAlliance.notice,pageType = 1})
end

--初始化顶部
function RAAllianceMainPage:initTitle()
    -- body
    -- self.ccbfile:getCCBFileFromCCB("mAllianceCommonCCB"):runAnimation("InAni")
    -- local titleName = _RALang("@Alliance")
    -- UIExtend.setCCLabelString(self.ccbfile:getCCBFileFromCCB("mAllianceCommonCCB"),'mTitle',titleName)

    local titleCCB = UIExtend.getCCBFileFromCCB(self.ccbfile, "mCommonTitleCCB")
    local RACommonTitleHelper = RARequire('RACommonTitleHelper')
    local backCallBack = function()
        RARootManager.CloseCurrPage()  
    end
    local titleName = _RALang("@Alliance")
    local titleHandler = RACommonTitleHelper:RegisterCommonTitle('RAAllianceMainPage', 
    titleCCB, titleName, backCallBack, RACommonTitleHelper.BgType.Blue, false)
end

function RAAllianceMainPage:Exit()
    print("RAAllianceMainPage:Exit")
    self:removeHandler()
    self:removeMessageHandler()
    if self.flagIcon ~= nil then
        self.flagIcon:removeFromParentAndCleanup(true)
        self.flagIcon = nil 
    end 
   	local RACommonTitleHelper = RARequire('RACommonTitleHelper')
   	RACommonTitleHelper:RemoveCommonTitle('RAAllianceMainPage')
    self.scrollView:removeAllCell()
    UIExtend.unLoadCCBFile(self)
end

--------------------------------------------------------

function RAAllianceMainPage:addCell()
    self.scrollView:removeAllCell()
    local cell = CCBFileCell:create()
    cell:setCCBFile("RAAllianceMainCellNew.ccbi")
    cell:registerFunctionHandler(RAAllianceMainCell)

    self.scrollView:addCell(cell)
    self.scrollView:orderCCBFileCells()
end



return RAAllianceMainPage