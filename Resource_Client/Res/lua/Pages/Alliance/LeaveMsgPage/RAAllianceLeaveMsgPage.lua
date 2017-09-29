--联盟留言面板
local RAAllianceBasePage = RARequire("RAAllianceBasePage")
local RAAllianceBBSMessageInfo = RARequire('RAAllianceBBSMessageInfo')
local RAAllianceProtoManager = RARequire("RAAllianceProtoManager")
local RARootManager = RARequire('RARootManager')
RARequire('MessageManager')
local HP_pb = RARequire('HP_pb')
local GuildManager_pb = RARequire('GuildManager_pb')
local RAAllianceLeaveMsgCell = RARequire('RAAllianceLeaveMsgCell')
local RANetUtil = RARequire('RANetUtil')

RARequire('extern')
local UIExtend = RARequire('UIExtend')

local RAAllianceLeaveMsgPage = class('RAAllianceLeaveMsgPage',RAAllianceBasePage)

local localPage = nil 
function RAAllianceLeaveMsgPage:ctor(...)
    self.ccbfileName = "RAAllianceLaveMsgPage.ccbi"
    self.scrollViewName = 'mHelpListSV'
    -- self.allianceId = data.allianceId
end

function RAAllianceLeaveMsgPage:init(data)
	self.allianceId = data.allianceId
	localPage = self
end

--初始化顶部
function RAAllianceLeaveMsgPage:initTitle()
    -- body
    self.mDiamondsNode = UIExtend.getCCNodeFromCCB(self.ccbfile:getCCBFileFromCCB("mAllianceCommonCCB"),'mDiamondsNode')
    self.mDiamondsNode:setVisible(false)

    self.ccbfile:getCCBFileFromCCB("mAllianceCommonCCB"):runAnimation("InAni")
    local titleName = _RALang("@AllianceLeaveMsgTitle")
    UIExtend.setCCLabelString(self.ccbfile:getCCBFileFromCCB("mAllianceCommonCCB"),'mTitle',titleName)
end

--子类实现
function RAAllianceLeaveMsgPage:initScrollview()
	self.mMessageSV = UIExtend.getCCScrollViewFromCCB(self.ccbfile, self.scrollViewName)

	RAAllianceProtoManager:getGuildMessageReq(self.allianceId)
end

--子类实现
function RAAllianceLeaveMsgPage:addHandler()
    self.netHandlers[#self.netHandlers + 1] = RANetUtil:addListener(HP_pb.GUILDMANAGER_GETMESSAGE_S, self) 
end

function RAAllianceLeaveMsgPage:onReceivePacket(handler)
    local pbCode = handler:getOpcode()
    local buffer = handler:getBuffer()
	
	if pbCode == HP_pb.GUILDMANAGER_GETMESSAGE_S then --获得联盟留言
        local messages,isForbiden = RAAllianceProtoManager:getGuildMessageResp(buffer)
        self.messages = messages
        self.isForbiden = isForbiden
        self:refreshScrollView()
    end
end

local OnReceiveMessage = function(message)
    if message.messageID == MessageDef_Packet.MSG_Operation_OK then
        if message.opcode == HP_pb.GUILDMANAGER_FORBIDPLAYERMESSAGE_C then 
            local str = _RALang("@ForbidPlayerMessageOK")
    		RARootManager.ShowMsgBox(str)
    		-- RAAllianceProtoManager:getGuildMessageReq(localPage.allianceId)
    	elseif message.opcode == HP_pb.GUILDMANAGER_POSTMESSAGE_C then 
    		RAAllianceProtoManager:getGuildMessageReq(localPage.allianceId)
        end 
    end 
end

function RAAllianceLeaveMsgPage:registerMessage()
    MessageManager.registerMessageHandler(MessageDef_Packet.MSG_Operation_OK,OnReceiveMessage)
end

function RAAllianceLeaveMsgPage:removeMessageHandler()
    MessageManager.removeMessageHandler(MessageDef_Packet.MSG_Operation_OK,OnReceiveMessage)
end

--刷新scrollview
function RAAllianceLeaveMsgPage:refreshScrollView()
	
	self.mMessageSV:removeAllCell()

    for i=#self.messages,1,-1 do

        local cell = CCBFileCell:create()
        local ccbiStr = "RAAllianceLaveMsgCell.ccbi"
        local panel = RAAllianceLeaveMsgCell:new()
        panel.info = self.messages[i]
        panel.info.allianceId = self.allianceId
        panel.cell = cell
        cell:registerFunctionHandler(panel)
        cell:setCCBFile(ccbiStr)
        self.mMessageSV:addCell(cell)
    end

    self.mMessageSV:orderCCBFileCells()
end

function RAAllianceLeaveMsgPage:release()
	self.mMessageSV:removeAllCell()
end

function RAAllianceLeaveMsgPage:onLaveMsgBtn()
	CCLuaLog('onLaveMsg')
	if self.isForbiden then 
		local str = _RALang("@YouAreForbidLeaveMessage")
    	RARootManager.ShowMsgBox(str)
	else
		RARootManager.OpenPage("RAAllianceEditLeaveMsgPage",{allianceId = self.allianceId},false, true, true)
	end 
end

return RAAllianceLeaveMsgPage.new()