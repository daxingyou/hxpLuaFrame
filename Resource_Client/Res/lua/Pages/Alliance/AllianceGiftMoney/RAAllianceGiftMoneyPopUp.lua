--联盟发红包页面
RARequire("BasePage")
local UIExtend = RARequire("UIExtend")
local RARootManager = RARequire("RARootManager")
local RAAllianceProtoManager = RARequire("RAAllianceProtoManager")
local HP_pb = RARequire("HP_pb")
local guild_const_conf = RARequire("guild_const_conf")
local Utilitys = RARequire("Utilitys")
local RAAllianceGiftMoneyManager = RARequire("RAAllianceGiftMoneyManager")

local RAAllianceGiftMoneyPopUp = BaseFunctionPage:new(...)

local selectPic = 1

local OnReceiveMessage = function(message)
    if message.messageID == MessageDef_Packet.MSG_Operation_OK then
    	--发红包成功

        RARootManager.RemoveWaitingPage()
    	RARootManager.ShowMsgBox(_RALang("@SendSuccess"))
    	RARootManager.ClosePage("RAAllianceGiftMoneyPopUp")
        RAAllianceGiftMoneyManager:setDailySendCount()
    elseif message.messageID == MessageDef_Packet.MSG_Operation_Fail then 
    	--发红包失败
    end 
end

function RAAllianceGiftMoneyPopUp:registerMessage()
    MessageManager.registerMessageHandler(MessageDef_Packet.MSG_Operation_OK,OnReceiveMessage)
    MessageManager.registerMessageHandler(MessageDef_Packet.MSG_Operation_Fail,OnReceiveMessage)
end

function RAAllianceGiftMoneyPopUp:removeMessageHandler()
    MessageManager.removeMessageHandler(MessageDef_Packet.MSG_Operation_OK,OnReceiveMessage)
    MessageManager.removeMessageHandler(MessageDef_Packet.MSG_Operation_Fail,OnReceiveMessage)
end

function RAAllianceGiftMoneyPopUp:Enter()
	-- body
	UIExtend.loadCCBFile("RAAllianceGiftMoneyPopUp.ccbi",self)

    self:registerMessage()

    local redPacketSendCost = guild_const_conf["redPacketSendCost"].value
    self.redPacketSendCostTable = Utilitys.Split(redPacketSendCost, ",")

    self:selectFunPic(selectPic)
    self.packetGold = self.redPacketSendCostTable[selectPic]

    self:refreshPage()
end

function RAAllianceGiftMoneyPopUp:refreshPage()
	-- body
	UIExtend.setStringForLabel(self.ccbfile, {mTitle = _RALang("@AllianceGiftMoneyPopUpTitle")})

	for i=1,3 do
		UIExtend.setStringForLabel(self.ccbfile, {['mGiftNum'..i] = self.redPacketSendCostTable[i]})
	end

    local redPacketMaxSendNumDaily = guild_const_conf["redPacketMaxSendNumDaily"].value
    local dailySendCount = RAAllianceGiftMoneyManager:getDailySendCount()
    local redPackageCount = _RALang('@GiftMoneyMaxNum',dailySendCount,redPacketMaxSendNumDaily)
    UIExtend.setStringForLabel(self.ccbfile, {mGiftMoneyMaxNum = redPackageCount})

	local RAPlayerInfoManager = RARequire("RAPlayerInfoManager")
    local playerInfo = RAPlayerInfoManager.getPlayerInfo()
    local surplusGoldStr = _RALang("@SurplusGold",playerInfo.raPlayerBasicInfo.gold)
    UIExtend.setStringForLabel(self.ccbfile, {mOverageNum = surplusGoldStr})
end

function RAAllianceGiftMoneyPopUp:selectFunPic(index)
    -- body
    for i=1,3 do
        local selBG = UIExtend.getCCScale9SpriteFromCCB(self.ccbfile, "mSelBG"..i)
        if i == index then
            selBG:setVisible(true)
        else
            selBG:setVisible(false)    
        end
    end
end

function RAAllianceGiftMoneyPopUp:onBtn1()
	-- body
    if selectPic == 1 then return end
    selectPic = 1
    self:selectFunPic(selectPic)
	self.packetGold = self.redPacketSendCostTable[selectPic] or 0
end

function RAAllianceGiftMoneyPopUp:onBtn2()
	-- body
    if selectPic == 2 then return end
    selectPic = 2
    self:selectFunPic(selectPic)
	self.packetGold = self.redPacketSendCostTable[selectPic] or 0
end

function RAAllianceGiftMoneyPopUp:onBtn3()
	-- body
    if selectPic == 3 then return end
    selectPic = 3
    self:selectFunPic(selectPic)
	self.packetGold = self.redPacketSendCostTable[selectPic] or 0
end

function RAAllianceGiftMoneyPopUp:onShareAgainBtn()
	-- body
    RARootManager.ShowWaitingPage(true)
	RAAllianceProtoManager:sendRedPacketReq(tonumber(self.packetGold))
end

function RAAllianceGiftMoneyPopUp:Exit()
    self:removeMessageHandler()

    selectPic = 1
    self.packetGold = nil

	UIExtend.unLoadCCBFile(self)	
end

function RAAllianceGiftMoneyPopUp:onClose()
	-- body
	RARootManager.ClosePage("RAAllianceGiftMoneyPopUp")
end

return RAAllianceGiftMoneyPopUp