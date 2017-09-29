--联盟类型改变
RARequire("BasePage")
RARequire("MessageManager")
local UIExtend = RARequire("UIExtend")
local RARootManager = RARequire("RARootManager")
local Utilitys = RARequire("Utilitys")
local RAAllianceProtoManager = RARequire("RAAllianceProtoManager")
local RAAllianceChangeTypePage = BaseFunctionPage:new(...)
local RAAllianceManager = RARequire('RAAllianceManager')
local RAAllianceUtility = RARequire('RAAllianceUtility')
local RAStringUtil = RARequire('RAStringUtil')
local GuildManager_pb = RARequire('GuildManager_pb')

local OnReceiveMessage = function(message)
    if message.messageID == MessageDef_Packet.MSG_Operation_OK then
        if message.opcode == HP_pb.GUILDMANAGER_CHANGETYPE_C then --
            RAAllianceManager.selfAlliance.guildType = RAAllianceChangeTypePage.selectType
            RAAllianceChangeTypePage.data.settingCell:refreshAllianceType()
            RARootManager.ShowMsgBox("@ChangeAllianceTypeSuccess")
            RARootManager.ClosePage('RAAllianceChangeTypePage')
        end 
    elseif message.messageID == MessageDef_Packet.MSG_Operation_Fail then 
        if message.opcode == HP_pb.GUILDMANAGER_CHANGETYPE_C then 
            --RARootManager.ShowMsgBox("@TirenFail")
        end 
    end 
end

function RAAllianceChangeTypePage:setSelectType(selectType)
    self.selectType = selectType

    for i=1,3 do
        if self.selectType == i then 
            UIExtend.getCCMenuItemImageFromCCB(self.ccbfile, 'mTypeBtn' .. i):setEnabled(false)
        else
            UIExtend.getCCMenuItemImageFromCCB(self.ccbfile, 'mTypeBtn' .. i):setEnabled(true)
        end 
    end

    self.mTypeExplain:setString(_RALang('@AllianceTypeExplain' .. selectType)) 
end

function RAAllianceChangeTypePage:registerMessage()
    MessageManager.registerMessageHandler(MessageDef_Packet.MSG_Operation_OK,OnReceiveMessage)
    MessageManager.registerMessageHandler(MessageDef_Packet.MSG_Operation_Fail,OnReceiveMessage)
end

function RAAllianceChangeTypePage:removeMessageHandler()
    MessageManager.removeMessageHandler(MessageDef_Packet.MSG_Operation_OK,OnReceiveMessage)
    MessageManager.removeMessageHandler(MessageDef_Packet.MSG_Operation_Fail,OnReceiveMessage)
end

function RAAllianceChangeTypePage:onTypeBtn1()
    self:setSelectType(GuildManager_pb.DEVELOPING)
end

function RAAllianceChangeTypePage:onTypeBtn2()
    self:setSelectType(GuildManager_pb.STRATEGIC)
end

function RAAllianceChangeTypePage:onTypeBtn3()
    self:setSelectType(GuildManager_pb.FIGHTING)
end

function RAAllianceChangeTypePage:Enter(data)
    self.ccbfile = UIExtend.loadCCBFile("RAAllianceSettingWarTypePopUp.ccbi", RAAllianceChangeTypePage)
    self.data = data

    self.mTitle = UIExtend.getCCLabelTTFFromCCB(self.ccbfile,'mTitle')
    self.mTitle:setString(_RALang('@AllianceChangeTypeTitle'))

    self.mTypeLabel1 = UIExtend.getCCLabelTTFFromCCB(self.ccbfile,'mTypeLabel1')
    self.mTypeLabel2 = UIExtend.getCCLabelTTFFromCCB(self.ccbfile,'mTypeLabel2')
    self.mTypeLabel3 = UIExtend.getCCLabelTTFFromCCB(self.ccbfile,'mTypeLabel3')

    self.mTypeLabel1:setString(_RALang('@AllianceTypeDeveloping'))
    self.mTypeLabel2:setString(_RALang('@AllianceTypeStrategic'))
    self.mTypeLabel3:setString(_RALang('@AllianceTypeFighting'))

    self.mTypeExplain = UIExtend.getCCLabelTTFFromCCB(self.ccbfile,'mTypeExplain')
    self.mTypeInfoExplain = UIExtend.getCCLabelTTFFromCCB(self.ccbfile,'mTypeExplain2')
    self.mTypeInfoExplain:setString(_RALang('@AllianceTypeChangeExplain'))

    self.selectType = RAAllianceManager.selfAlliance.guildType
    self:setSelectType(self.selectType)
    self:registerMessage()
end


function RAAllianceChangeTypePage:Exit()
    self:removeMessageHandler()
	UIExtend.unLoadCCBFile(RAAllianceChangeTypePage)
end

--关闭
function RAAllianceChangeTypePage:onClose()
    RARootManager.ClosePage('RAAllianceChangeTypePage')
end

function RAAllianceChangeTypePage:onSaveBtn()
    if self.selectType == RAAllianceManager.selfAlliance.guildType then 
        self:onClose()
    else
        RAAllianceProtoManager:changeAllianceType(self.selectType)
    end  
end



return RAAllianceChangeTypePage