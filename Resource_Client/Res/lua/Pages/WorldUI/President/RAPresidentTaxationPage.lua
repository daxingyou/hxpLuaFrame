--TO:联盟雕像详细页面
RARequire("BasePage")
local UIExtend = RARequire("UIExtend")
local RARootManager = RARequire("RARootManager")
local RAAllianceStatueManager = RARequire("RAAllianceStatueManager")
local RAAllianceProtoManager = RARequire("RAAllianceProtoManager")
local Utilitys = RARequire("Utilitys")
local RAStringUtil = RARequire("RAStringUtil")
local html_zh_cn = RARequire("html_zh_cn")
local RAQueueManager = RARequire("RAQueueManager")
local HP_pb = RARequire("HP_pb")
local common = RARequire("common")
local President_pb = RARequire("President_pb")
local RAAllianceManager = RARequire("RAAllianceManager")
local RAAllianceUtility = RARequire('RAAllianceUtility')
local RALogicUtil = RARequire('RALogicUtil')
local RANetUtil = RARequire('RANetUtil')

local RAPresidentTaxationPage = BaseFunctionPage:new(...)

-----------------------------------------------------------
local RAPresidentTaxationCellListener = {
    id = 0
}

function RAPresidentTaxationCellListener:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    return o
end 

function RAPresidentTaxationCellListener:onRefreshContent(ccbRoot)
    local allianceInfo = RAPresidentTaxationPage.taxInfos[self.id]

    local ccbfile = ccbRoot:getCCBFileNode()   
    if ccbfile then
        -- dump(allianceInfo)
        local flagIcon = RAAllianceUtility:getAllianceFlagIdByIcon(allianceInfo.guildIcon)
        UIExtend.setCCLabelString(ccbfile, "mAllianceName", "（"..allianceInfo.guildTag.."）\n".. allianceInfo.guildName)
        UIExtend.addSpriteToNodeParent(ccbfile,"mCellIconNode",flagIcon)
        UIExtend.setNodeVisible(ccbfile,"mSelBG", self.id == RAPresidentTaxationPage.curAlliance)
    end
end
--升级
function RAPresidentTaxationCellListener:onCellBtn()
    RAPresidentTaxationPage.curAlliance = self.id
    RAPresidentTaxationPage:refreshRightUI()

    RAPresidentTaxationPage:refreshAlliacneScrollView()
end


local RAPresidentPalaceLabelCellListener = {
    id = 0
}

function RAPresidentPalaceLabelCellListener:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    return o
end 

function RAPresidentPalaceLabelCellListener:onRefreshContent(ccbRoot)
    local record = RAPresidentTaxationPage.records[self.id]

    local ccbfile = ccbRoot:getCCBFileNode() 
    if ccbfile then
        UIExtend.setCCLabelString(ccbfile, "mTime", Utilitys.formatTime(record.taxTime/1000))
        local html_zh_cn = RARequire("html_zh_cn")
        local RAStringUtil = RARequire("RAStringUtil")        
        local htmlStr = RAStringUtil:fill(html_zh_cn["PresidentialTax"], "(" .. record.taxGuildName .. ")" .. record.taxPlayerName, "(" .. record.guildName .. ")" .. record.playerName  )
        -- UIExtend.getCCLabelHTMLFromCCB(ccbfile,"mCellLabel"):setString(htmlStr)
        UIExtend.setCCLabelString(ccbfile, "mCellLabel",htmlStr)
    end
end
--升级
function RAPresidentPalaceLabelCellListener:onCellBtn()
    RAPresidentTaxationPage.curAlliance = self.id
    RAPresidentTaxationPage:refreshUI()
end




local OnReceiveMessage = function(message)    
    if message.messageID == MessageDef_Packet.MSG_Operation_OK then                 --征税成功返回
        local opcode = message.opcode
        if opcode==HP_pb.PRESIDENT_TAX_GUILD_C then
            RAPresidentTaxationPage:setCurAllianceTax()
            RAPresidentTaxationPage:refreshRightUI()
            RAPresidentTaxationPage:refreshRecordScrollView()            
            RARootManager.ShowMsgBox(_RALang("@PresidentTaxationSucc"))
        end       
    end
end

function RAPresidentTaxationPage:registerMessageHandlers()
    MessageManager.registerMessageHandler(MessageDef_Packet.MSG_Operation_OK,OnReceiveMessage)
end

function RAPresidentTaxationPage:unregisterMessageHandlers()
    MessageManager.removeMessageHandler(MessageDef_Packet.MSG_Operation_OK,OnReceiveMessage)
end

function RAPresidentTaxationPage:sengetGuildStatueInfoResp()
    RANetUtil:sendPacket(HP_pb.PRESIDENT_TAX_INFO_SYNC_C) 
end

function RAPresidentTaxationPage:Enter()

    UIExtend.loadCCBFile("RAPresidentTaxationPage.ccbi",self)
    self.curAlliance = 1
    self:RegisterPacketHandler(HP_pb.PRESIDENT_TAX_INFO_SYNC_S)
    self:registerMessageHandlers()
    self:refreshTitle()  
    self:sengetGuildStatueInfoResp()
    UIExtend.setNodeVisible(self.ccbfile, "DetailsNode", false)
end


function RAPresidentTaxationPage:refreshTitle()
    local titleCCB = UIExtend.getCCBFileFromCCB(self.ccbfile, "mCommonTitleCCB")
    if titleCCB then
          
        UIExtend.setCCLabelString(titleCCB, "mTitle", _RALang("@Taxation"))
        -- UIExtend.setNodeVisible(titleCCB, "mDiamondsNode", false)
    end


    local RACommonTitleHelper = RARequire('RACommonTitleHelper')
    local backCallBack = function()
        RARootManager.ClosePage("RAPresidentTaxationPage") 
    end
    local diamondCallBack = function()
        local RARealPayManager = RARequire('RARealPayManager')
        RARealPayManager:getRechargeInfo()
    end

    local titleHandler = RACommonTitleHelper:RegisterCommonTitle('RAPresidentTaxationPage', 
    titleCCB, _RALang("@Taxation"), backCallBack, RACommonTitleHelper.BgType.Blue)
    titleHandler:SetCallBack(RACommonTitleHelper.TitleCallBack.Diamonds, diamondCallBack)    
end


function RAPresidentTaxationPage:refreshData(data)
    self.allianScore = data.allianScore
    self.statueInfo = data.statueInfo

    self:refreshUI()
end

function RAPresidentTaxationPage:initByPbData( msg )
        if self.taxInfos == nil or msg.taxInfos then
            self.taxInfos = {}
        end

        if msg.records then
            self.records = {}
        end

        for i,info in ipairs(msg.taxInfos) do
            self.taxInfos[i] = 
            {
                guildId = info.guildId,
                playerId = info.playerId,
                playerName = info.playerName,
                guildIcon = info.guildIcon,
                guildLevel = info.guildLevel,
                guildName = info.guildName,
                guildTag = info.guildTag,
                taxTime = info.taxTime,
                goldore = info.goldore,
                oil = info.oil,
                steel = info.steel,
                tombarthite = info.tombarthite
            }
        end

        for i,info in ipairs(msg.records) do
            self.records[i] = 
            {
                taxPlayerId = info.taxPlayerId,
                taxPlayerName = info.taxPlayerName,
                taxGuildName = info.taxGuildName,
                taxTime = info.taxTime,
                playerId = info.playerId,
                playerName = info.playerName,
                guildName = info.guildName
            }
        end
        table.sort( self.taxInfos, function ( left, right )
            if left.guildLevel == right.guildLevel then
                return left.guildName > right.guildName
            end
            return left.guildLevel > right.guildLevel
        end )
        table.sort( self.records, function ( left, right )
            return left.taxTime > right.taxTime
        end )        
end

function RAPresidentTaxationPage:onReceivePacket(handler)
    local pbCode = handler:getOpcode()
    local buffer = handler:getBuffer()
    if pbCode == HP_pb.PRESIDENT_TAX_INFO_SYNC_S then --其他联盟列表
        local msg = President_pb.TaxGuildInfoSync()
        msg:ParseFromString(buffer)
        self:initByPbData(msg)

        self:refreshUI()
    end
end

function RAPresidentTaxationPage:refreshUI()
	-- body
    self:buildAlliacneScrollView()
    self:refreshRecordScrollView()
    self:refreshRightUI()
end

function RAPresidentTaxationPage:buildAlliacneScrollView(  )

    self.alliacneScrollView = UIExtend.getCCScrollViewFromCCB(self.ccbfile, "mAllianceListSV")

    self.alliacneScrollView:removeAllCell()
    for i,v in ipairs(self.taxInfos) do
        local titleListener = RAPresidentTaxationCellListener:new({id = i})
        local cell = CCBFileCell:create()
        cell:setCCBFile("RAPresidentTaxationCell.ccbi")
        cell:registerFunctionHandler(titleListener)

        self.alliacneScrollView:addCell(cell)
    end
    self.alliacneScrollView:orderCCBFileCells()    
end

function RAPresidentTaxationPage:refreshAlliacneScrollView(  )

    self.alliacneScrollView = UIExtend.getCCScrollViewFromCCB(self.ccbfile, "mAllianceListSV")
    local preOffest=self.alliacneScrollView:getContentOffset()

    self.alliacneScrollView:refreshAllCell()
    self.alliacneScrollView:setContentOffset(preOffest)

end

function RAPresidentTaxationPage:refreshRecordScrollView(  )

    self.recordScrollView = UIExtend.getCCScrollViewFromCCB(self.ccbfile, "mRecordListSV")
    self.recordScrollView:removeAllCell()
    self.records = self.records or {}
    for i, v in ipairs(self.records) do
        local titleListener = RAPresidentPalaceLabelCellListener:new({id = i})
        local cell = CCBFileCell:create()
        cell:setCCBFile("RAPresidentPalaceLabelCell.ccbi")
        cell:registerFunctionHandler(titleListener)

        self.recordScrollView:addCell(cell)
    end
    self.recordScrollView:orderCCBFileCells()  
end

function RAPresidentTaxationPage:refreshRightUI(  )
    local curAllianceInfo = self.taxInfos[self.curAlliance]
    if curAllianceInfo == nil then
        UIExtend.setNodeVisible(self.ccbfile, "mNoTaxationLabelNode", true)
        UIExtend.setNodeVisible(self.ccbfile, "DetailsNode", false)
        return
    end

    UIExtend.setNodeVisible(self.ccbfile, "mNoTaxationLabelNode", false)
    UIExtend.setNodeVisible(self.ccbfile, "DetailsNode", true)    

    local flagIcon = RAAllianceUtility:getAllianceFlagIdByIcon(curAllianceInfo.guildIcon)
    UIExtend.addSpriteToNodeParent(self.ccbfile,"mCellIconNode",flagIcon)
    local president_const_conf = RARequire('president_const_conf')
    local strTable = { 
                        mAllianceName = "（"..curAllianceInfo.guildTag.."）" .. curAllianceInfo.guildName,
                        mLeaderName = curAllianceInfo.playerName,
                        mLevyFineLabel = curAllianceInfo.taxTime == 0 and _RALang("@NotLevied") or _RALang("@AlreadyLevied"),
                        mLevyFineExplain = _RALang("@LevyFineExplain",math.floor(president_const_conf.taxPercent.value/100))
                    }
    UIExtend.setStringForLabel(self.ccbfile, strTable)
    local mResNum1,mResNum2,mResNum3,mResNum4

    if curAllianceInfo.taxTime == 0 then
        mResNum1 = RAStringUtil:fill(html_zh_cn["PresidentialRes"],RALogicUtil:num2k(curAllianceInfo.goldore),RALogicUtil:num2k(curAllianceInfo.goldore/10))
        mResNum2 = RAStringUtil:fill(html_zh_cn["PresidentialRes"],RALogicUtil:num2k(curAllianceInfo.oil),RALogicUtil:num2k(curAllianceInfo.oil/10))
        mResNum3 = RAStringUtil:fill(html_zh_cn["PresidentialRes"],RALogicUtil:num2k(curAllianceInfo.steel),RALogicUtil:num2k(curAllianceInfo.steel/10))
        mResNum4 = RAStringUtil:fill(html_zh_cn["PresidentialRes"],RALogicUtil:num2k(curAllianceInfo.tombarthite),RALogicUtil:num2k(curAllianceInfo.tombarthite/10))
    else
        mResNum1 = _RALang("@unKnown")
        mResNum2 = _RALang("@unKnown")
        mResNum3 = _RALang("@unKnown")
        mResNum4 = _RALang("@unKnown")
    end

    UIExtend.getCCLabelHTMLFromCCB(self.ccbfile,"mResNum1"):setString(mResNum1)
    UIExtend.getCCLabelHTMLFromCCB(self.ccbfile,"mResNum2"):setString(mResNum2)
    UIExtend.getCCLabelHTMLFromCCB(self.ccbfile,"mResNum3"):setString(mResNum3)
    UIExtend.getCCLabelHTMLFromCCB(self.ccbfile,"mResNum4"):setString(mResNum4)
    UIExtend.getCCLabelHTMLFromCCB(self.ccbfile,"mResNum1"):setScale(0.8)
    UIExtend.getCCLabelHTMLFromCCB(self.ccbfile,"mResNum2"):setScale(0.8)
    UIExtend.getCCLabelHTMLFromCCB(self.ccbfile,"mResNum3"):setScale(0.8)
    UIExtend.getCCLabelHTMLFromCCB(self.ccbfile,"mResNum4"):setScale(0.8)
end

function RAPresidentTaxationPage:setCurAllianceTax(  )
    local RAPlayerInfoManager = RARequire('RAPlayerInfoManager')
    local curAllianceInfo = self.taxInfos[self.curAlliance]
    curAllianceInfo.taxTime = 1
    curAllianceInfo.goldore = 0
    curAllianceInfo.oil = 0
    curAllianceInfo.steel = 0
    curAllianceInfo.tombarthite = 0
    local selfAllianceName = ""
    if RAAllianceManager.selfAlliance then
        selfAllianceName = RAAllianceManager.selfAlliance.name
    end
    local palyerInfo = RAPlayerInfoManager.getPlayerInfo()
    table.insert(self.records, 1, {
                taxPlayerId = palyerInfo.raPlayerBasicInfo.playerId,
                taxPlayerName = palyerInfo.raPlayerBasicInfo.name,
                taxGuildName = selfAllianceName,
                taxTime = common:getCurTime()*1000,
                playerId = curAllianceInfo.playerId,
                playerName = curAllianceInfo.playerName,
                guildName = curAllianceInfo.guildName
            })
end

--征收
function RAPresidentTaxationPage:onLevyFineBtn()
    if self.taxInfos[self.curAlliance].taxTime == 0 then
        local cmd = President_pb.TaxGuildReq()
        cmd.playerId = self.taxInfos[self.curAlliance].playerId
        RANetUtil:sendPacket(HP_pb.PRESIDENT_TAX_GUILD_C, cmd)        
    else
        RARootManager.ShowMsgBox(_RALang('@AllianceHasAlreadyLevied'))
    end
end



function RAPresidentTaxationPage:onClose()
    RARootManager.CloseCurrPage()
end

function RAPresidentTaxationPage:Exit()
    local RACommonTitleHelper = RARequire('RACommonTitleHelper')
    RACommonTitleHelper:RemoveCommonTitle("RAPresidentTaxationPage")    
    self:RemovePacketHandlers()
	self:unregisterMessageHandlers()
    
    self.taxInfos = nil
    self.curAlliance = nil
    self.records = nil

    self.ccbfile:stopAllActions()
    
    UIExtend.unLoadCCBFile(self)
    self.ccbfile = nil
end

return RAPresidentTaxationPage