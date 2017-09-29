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

local RAPresidentTaxationRecordPage = BaseFunctionPage:new(...)

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
    local record = RAPresidentTaxationRecordPage.records[self.id]

    local ccbfile = ccbRoot:getCCBFileNode() 
    if ccbfile then
        UIExtend.setCCLabelString(ccbfile, "mTime", Utilitys.formatTime(record.taxTime/1000))
        local html_zh_cn = RARequire("html_zh_cn")
        local RAStringUtil = RARequire("RAStringUtil")        
        local htmlStr = RAStringUtil:fill(html_zh_cn["PresidentialTax"], "(" .. record.taxGuildName .. ")".. record.taxPlayerName, "(" .. record.guildName .. ")" .. record.playerName  )
        -- UIExtend.getCCLabelHTMLFromCCB(ccbfile,"mCellLabel"):setString(htmlStr)        
        UIExtend.setCCLabelString(ccbfile, "mCellLabel",htmlStr)
    end
end
--升级
function RAPresidentPalaceLabelCellListener:onCellBtn()
    RAPresidentTaxationRecordPage.curAlliance = self.id
    RAPresidentTaxationRecordPage:refreshUI()
end




local OnReceiveMessage = function(message)    
    if message.messageID == MessageDef_Packet.MSG_Operation_OK then                 --删除邮件成功返回
        local opcode = message.opcode
        if opcode==HP_pb.PRESIDENT_TAX_GUILD_C then
            RARootManager.ShowMsgBox("@presidentTaxation")
        end       
    end
end

function RAPresidentTaxationRecordPage:registerMessageHandlers()
    MessageManager.removeMessageHandler(MessageDef_Packet.MSG_Operation_OK,OnReceiveMessage)
end

function RAPresidentTaxationRecordPage:unregisterMessageHandlers()
    MessageManager.registerMessageHandler(MessageDef_Packet.MSG_Operation_OK,OnReceiveMessage)
end

function RAPresidentTaxationRecordPage:sengetGuildStatueInfoResp()
    -- body
    RANetUtil:sendPacket(HP_pb.PRESIDENT_TAX_INFO_SYNC_C) 
end

function RAPresidentTaxationRecordPage:Enter()

    UIExtend.loadCCBFile("RAPresidentTaxationRecordPage.ccbi",self)
    self:RegisterPacketHandler(HP_pb.PRESIDENT_TAX_INFO_SYNC_S)
    self:registerMessageHandlers()
    self:refreshTitle()  
    self:sengetGuildStatueInfoResp()
end


function RAPresidentTaxationRecordPage:refreshTitle()
    local titleCCB = UIExtend.getCCBFileFromCCB(self.ccbfile, "mCommonTitleCCB")
    local RAPlayerInfoManager = RARequire('RAPlayerInfoManager')
    local playerInfo = RAPlayerInfoManager.getPlayerBasicInfo()    
    if titleCCB then
          
        UIExtend.setCCLabelString(titleCCB, "mTitle", _RALang("@TaxationRecord"))
        -- UIExtend.setNodeVisible(titleCCB, "mDiamondsNode", false)
    end


    local RACommonTitleHelper = RARequire('RACommonTitleHelper')
    local backCallBack = function()
        RARootManager.ClosePage("RAPresidentTaxationRecordPage") 
    end
    local diamondCallBack = function()
        local RARealPayManager = RARequire('RARealPayManager')
        RARealPayManager:getRechargeInfo()
    end

    local titleHandler = RACommonTitleHelper:RegisterCommonTitle('RAPresidentTaxationRecordPage', 
    titleCCB, _RALang("@TaxationRecord"), backCallBack, RACommonTitleHelper.BgType.Blue)
    titleHandler:SetCallBack(RACommonTitleHelper.TitleCallBack.Diamonds, diamondCallBack)    
end


function RAPresidentTaxationRecordPage:refreshData(data)
    self.allianScore = data.allianScore
    self.statueInfo = data.statueInfo

    self:refreshUI()
end

function RAPresidentTaxationRecordPage:onReceivePacket(handler)
    local pbCode = handler:getOpcode()
    local buffer = handler:getBuffer()
    if pbCode == HP_pb.PRESIDENT_TAX_INFO_SYNC_S then --其他联盟列表
        local msg = President_pb.TaxGuildInfoSync()
        msg:ParseFromString(buffer)
        self.records = msg.records
        table.sort( self.records, function ( left, right )
            return left.taxTime > right.taxTime
        end )
        self:refreshUI()

    end
end

function RAPresidentTaxationRecordPage:refreshUI()
    self.mRecordListSV = UIExtend.getCCScrollViewFromCCB(self.ccbfile, "mRecordListSV")

    self.mRecordListSV:removeAllCell()
    for i,v in ipairs(self.records) do
        local titleListener = RAPresidentPalaceLabelCellListener:new({id = i})
        local cell = CCBFileCell:create()
        cell:setCCBFile("RAPresidentPalaceLabelCell.ccbi")
        cell:registerFunctionHandler(titleListener)

        self.mRecordListSV:addCell(cell)
    end
    self.mRecordListSV:orderCCBFileCells() 
end

function RAPresidentTaxationRecordPage:onClose()
    RARootManager.CloseCurrPage()
end

function RAPresidentTaxationRecordPage:Exit()
    local RACommonTitleHelper = RARequire('RACommonTitleHelper')
    RACommonTitleHelper:RemoveCommonTitle("RAPresidentTaxationRecordPage")    
    self:RemovePacketHandlers()
	self:unregisterMessageHandlers()
    
    self.alliacneList = nil
    self.curAlliance = nil

    self.ccbfile:stopAllActions()
    
    UIExtend.unLoadCCBFile(self)
    self.ccbfile = nil
end

return RAPresidentTaxationRecordPage