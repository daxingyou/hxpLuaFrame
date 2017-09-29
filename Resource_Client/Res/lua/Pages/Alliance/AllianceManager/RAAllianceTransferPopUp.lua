RARequire("BasePage")
local UIExtend = RARequire("UIExtend")
local RARootManager = RARequire("RARootManager")
local RAPlayerInfoManager = RARequire("RAPlayerInfoManager")
local Utilitys = RARequire("Utilitys")
local RAStringUtil = RARequire("RAStringUtil")
local html_zh_cn = RARequire("html_zh_cn")
local RAAllianceProtoManager = RARequire("RAAllianceProtoManager")

local RAAllianceTransferPopUp = BaseFunctionPage:new(...)

local OnReceiveMessage = function(message)
    if message.messageID == MessageDef_Packet.MSG_Operation_OK then
        if message.opcode == HP_pb.GUILDMANAGER_DEMISELEADER_C then --转让
            RARootManager.ShowMsgBox("@TransferSuccess")
            RARootManager.CloseAllPages()
            RARootManager.OpenPage("RAAllianceMainPage")
        end 
    elseif message.messageID == MessageDef_Packet.MSG_Operation_Fail then 
        if message.opcode == HP_pb.GUILDMANAGER_DEMISELEADER_C then 
            RARootManager.ShowMsgBox("@TransferFail")
        end 
    end 
end

function RAAllianceTransferPopUp:registerMessage()
    MessageManager.registerMessageHandler(MessageDef_Packet.MSG_Operation_OK,OnReceiveMessage)
    MessageManager.registerMessageHandler(MessageDef_Packet.MSG_Operation_Fail,OnReceiveMessage)
end

function RAAllianceTransferPopUp:removeMessageHandler()
    MessageManager.removeMessageHandler(MessageDef_Packet.MSG_Operation_OK,OnReceiveMessage)
    MessageManager.removeMessageHandler(MessageDef_Packet.MSG_Operation_Fail,OnReceiveMessage)
end

function RAAllianceTransferPopUp:Enter(data)
	local ccbfile = UIExtend.loadCCBFile("RAAllianceTransferPopUp.ccbi",self)
	self.playerInfo = data.playerInfo
	self.type = data.type	--0:转让，1:根据自己的情况定
    self:registerMessage()
	self:refreshUI()
end

function RAAllianceTransferPopUp:refreshUI()
	if self.playerInfo then
        local libStr = {}
        libStr['mPlayerName'] = self.playerInfo.playerName
        libStr['mFightValue'] = Utilitys.formatNumber(self.playerInfo.power)
        libStr['mRankNum'] = self.playerInfo.authority
        
        UIExtend.setStringForLabel(self.ccbfile,libStr)

	    local desStr = RAStringUtil:fill(html_zh_cn["AllianceDes1"],self.playerInfo.playerName) 
	    local labelHtml = self.ccbfile:getCCLabelHTMLFromCCB("mConfirmTransferLabel")
	    labelHtml:setPreferredSize(600,150)
	    UIExtend.setCCLabelHTMLString(self.ccbfile,"mConfirmTransferLabel",desStr)

        --头像
        local playerIcon = RAPlayerInfoManager.getHeadIcon(self.playerInfo.icon)

        UIExtend.addSpriteToNodeParent(self.ccbfile, "mMemIconNode", playerIcon)
    end
end

--取消
function RAAllianceTransferPopUp:onCancelBtn()
	-- body
	RARootManager.CloseCurrPage()
end

--取消
function RAAllianceTransferPopUp:onClose()
	-- body
	RARootManager.CloseCurrPage()
end

--确认
function RAAllianceTransferPopUp:onConfim()
	-- body
	if self.type == 0 then  --转让
	    RAAllianceProtoManager:dimiseLeader(self.playerInfo.playerId)
	end   	 
end

function RAAllianceTransferPopUp:Exit()
    self.playerInfo = nil
    self:removeMessageHandler()
    UIExtend.unLoadCCBFile(self)
end

return RAAllianceTransferPopUp