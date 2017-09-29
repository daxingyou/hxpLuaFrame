--TO:联盟雕像页面
RARequire("BasePage")
local UIExtend = RARequire("UIExtend")
local RARootManager = RARequire("RARootManager")
local RAAllianceProtoManager = RARequire("RAAllianceProtoManager")
local GuildManager_pb = RARequire("GuildManager_pb")
local HP_pb = RARequire("HP_pb")
local RAAllianceStatueManager = RARequire("RAAllianceStatueManager")

local RAAllianceStatuePage = BaseFunctionPage:new(...)

local selectStatueIndex = 0

function RAAllianceStatuePage:sengetGuildStatueInfoResp()
    -- body
    RAAllianceProtoManager:sendGetStatueInfoResp()
end

function RAAllianceStatuePage:setUpgradingNode()
    
    --发送消息刷新页面
    local data = RAAllianceStatueManager:setStatueInfo(selectStatueIndex,self.statueInfo)
    MessageManager.sendMessage(MessageDef_Alliance.MSG_Alliance_Statue_UP_Success,{data = data})

    local RAQueueManager = RARequire("RAQueueManager")
    local queue = RAQueueManager:getStatueQueue()
    local statueQueueInfo = {}
    for k,v in pairs(queue) do
        statueQueueInfo = v
    end
    for i=1,8 do
        if tonumber(statueQueueInfo.itemId) == i then
            UIExtend.setNodeVisible(self.ccbfile,"mUpgradingNode"..i,true)
        else
            UIExtend.setNodeVisible(self.ccbfile,"mUpgradingNode"..i,false)    
        end

        local info = self.statueInfo[i]
        UIExtend.setStringForLabel(self.ccbfile, {['mStatueName'..i] = _RALang("@StatueName"..i,info.level)})
    end
end 

local OnReceiveMessage = function(message)    
    if message.messageID == MessageDef_Alliance.MSG_Alliance_Statue_Update then
        RAAllianceStatuePage.statueInfo = RAAllianceStatueManager:getStatueData()
        RAAllianceStatuePage:refreshUI()
    end
end

function RAAllianceStatuePage:registerMessageHandlers()
    MessageManager.registerMessageHandler(MessageDef_Alliance.MSG_Alliance_Statue_Update, OnReceiveMessage)
end

function RAAllianceStatuePage:unregisterMessageHandlers()
    MessageManager.removeMessageHandler(MessageDef_Alliance.MSG_Alliance_Statue_Update, OnReceiveMessage)
end

function RAAllianceStatuePage:Enter()

	self:RegisterPacketHandler(HP_pb.GUILD_GET_STATUE_INFO_S)
    self:RegisterPacketHandler(HP_pb.GUILD_STATUE_UPGRADE_S)
    self:registerMessageHandlers()

    --发送获取雕像信息
    self:sengetGuildStatueInfoResp()

	UIExtend.loadCCBFile("RAAllianceStatuePage.ccbi",self)

    --top info
    self:initTitle()
end

function RAAllianceStatuePage:refreshUI()
	-- body
	UIExtend.setStringForLabel(self.ccbfile, {mContribution = _RALang("@AllianceScore",self.statueInfo.allianScore)})

    self:setUpgradingNode()
end

function RAAllianceStatuePage:onReceivePacket(handler)
	local pbCode = handler:getOpcode()
    local buffer = handler:getBuffer()
    if pbCode == HP_pb.GUILD_GET_STATUE_INFO_S then
        local msg = GuildManager_pb.GetGuildStatueInfoResp()
        msg:ParseFromString(buffer)
        self.statueInfo = RAAllianceStatueManager:setStatueData(msg)

        self:refreshUI()
    elseif pbCode == HP_pb.GUILD_STATUE_UPGRADE_S then
        local msg = GuildManager_pb.GetGuildStatueInfoResp()
        msg:ParseFromString(buffer)
        self.statueInfo.allianScore = msg.allianScore
        UIExtend.setStringForLabel(self.ccbfile, {mContribution = _RALang("@AllianceScore",self.statueInfo.allianScore)})
    end
end

function RAAllianceStatuePage:initTitle()
    local titleCCB = UIExtend.getCCBFileFromCCB(self.ccbfile, "mAllianceCommonCCB")
	local RACommonTitleHelper = RARequire('RACommonTitleHelper')
	local backCallBack = function()
		RARootManager.CloseCurrPage()  
	end
    local titleName = _RALang("@RAAllianceStatueTitle")
	local titleHandler = RACommonTitleHelper:RegisterCommonTitle('RAAllianceStatuePage', 
    titleCCB, titleName, backCallBack, RACommonTitleHelper.BgType.Blue)
end

function RAAllianceStatuePage:onStatueBtn1()
    -- body
    selectStatueIndex = 1
    local data = RAAllianceStatueManager:setStatueInfo(selectStatueIndex,self.statueInfo)
    RARootManager.OpenPage("RAAllianceStatueInfoPage", data ,false,true,true)
end

function RAAllianceStatuePage:onStatueBtn2()
    -- body
    selectStatueIndex = 2
    local data = RAAllianceStatueManager:setStatueInfo(selectStatueIndex,self.statueInfo)
    RARootManager.OpenPage("RAAllianceStatueInfoPage", data ,false,true,true)
end

function RAAllianceStatuePage:onStatueBtn3()
    -- body
    selectStatueIndex = 3
    local data = RAAllianceStatueManager:setStatueInfo(selectStatueIndex,self.statueInfo)
    RARootManager.OpenPage("RAAllianceStatueInfoPage", data ,false,true,true)
end

function RAAllianceStatuePage:onStatueBtn4()
    -- body
    selectStatueIndex = 4
    local data = RAAllianceStatueManager:setStatueInfo(selectStatueIndex,self.statueInfo)
    RARootManager.OpenPage("RAAllianceStatueInfoPage", data ,false,true,true)
end

function RAAllianceStatuePage:onStatueBtn5()
    -- body
    selectStatueIndex = 5
    local data = RAAllianceStatueManager:setStatueInfo(selectStatueIndex,self.statueInfo)
    RARootManager.OpenPage("RAAllianceStatueInfoPage", data ,false,true,true)
end

function RAAllianceStatuePage:onStatueBtn6()
    -- body
    selectStatueIndex = 6
    local data = RAAllianceStatueManager:setStatueInfo(selectStatueIndex,self.statueInfo)
    RARootManager.OpenPage("RAAllianceStatueInfoPage", data ,false,true,true)
end

function RAAllianceStatuePage:onStatueBtn7()
    -- body
    selectStatueIndex = 7
    local data = RAAllianceStatueManager:setStatueInfo(selectStatueIndex,self.statueInfo)
    RARootManager.OpenPage("RAAllianceStatueInfoPage", data ,false,true,true)
end

function RAAllianceStatuePage:onStatueBtn8()
    -- body
    selectStatueIndex = 8
    local data = RAAllianceStatueManager:setStatueInfo(selectStatueIndex,self.statueInfo)
    RARootManager.OpenPage("RAAllianceStatueInfoPage", data ,false,true,true)
end

function RAAllianceStatuePage:mAllianceCommonCCB_onBack()
    RARootManager.CloseCurrPage()
end

function RAAllianceStatuePage:Exit()
    self:unregisterMessageHandlers()
	self:RemovePacketHandlers()

    selectStatueIndex = 0
	local RACommonTitleHelper = RARequire('RACommonTitleHelper')
    RACommonTitleHelper:RemoveCommonTitle("RAAllianceStatuePage")

    UIExtend.unLoadCCBFile(self)
    self.ccbfile = nil
end

return RAAllianceStatuePage