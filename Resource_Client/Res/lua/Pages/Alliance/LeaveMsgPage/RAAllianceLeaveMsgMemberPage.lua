--联盟成员
RARequire("BasePage")
local UIExtend = RARequire("UIExtend")
local RARootManager = RARequire("RARootManager")
local RAGameConfig = RARequire("RAGameConfig")
local RAAllianceLeaveMsgMemberPage = BaseFunctionPage:new(...)
local RAStringUtil = RARequire('RAStringUtil')
local RAAllianceManager = RARequire('RAAllianceManager')
local RAPlayerInfoManager = RARequire('RAPlayerInfoManager')
local RAAllianceProtoManager = RARequire('RAAllianceProtoManager')
local RAAllianceManager = RARequire('RAAllianceManager')
local Utilitys = RARequire('Utilitys')
local RAAllianceUtility = RARequire('RAAllianceUtility')

function RAAllianceLeaveMsgMemberPage:Enter(data)
    self.ccbfile = UIExtend.loadCCBFile("RAAllianceMemPopUp.ccbi", RAAllianceLeaveMsgMemberPage)
    self.info = data

    --头像
    local playerIcon = RAPlayerInfoManager.getHeadIcon(self.info.icon)
    UIExtend.addSpriteToNodeParent(self.ccbfile, "mMemIconNode", playerIcon)

    self.mPlayerName = UIExtend.getCCLabelTTFFromCCB(self.ccbfile,'mPlayerName')

    local playerName = self.info.playerName
    if self.info.guildTag ~= nil then 
        playerName = '(' .. self.info.guildTag .. ')' .. playerName
    end

    self.mPlayerName:setString(playerName)

    self.mFightValue = UIExtend.getCCLabelTTFFromCCB(self.ccbfile,'mFightValue') 
    self.mFightValue:setString(Utilitys.formatNumber(self.info.power))

    UIExtend.getCCSpriteFromCCB(self.ccbfile,'mLevelNode'):setVisible(false)
    UIExtend.getCCLabelTTFFromCCB(self.ccbfile,'mLevelLabel'):setVisible(false)
    self.mLaveBlockBtn = UIExtend.getCCControlButtonFromCCB(self.ccbfile,'mLaveBlockBtn')

    if RAAllianceManager.selfAlliance == nil or RAAllianceManager.selfAlliance.id ~= self.info.allianceId then 
    	self.mLaveBlockBtn:setEnabled(false)
    else
    	local isCan = RAAllianceUtility:isMessageMask(RAAllianceManager.authority)

    	if isCan then
    		self.mLaveBlockBtn:setEnabled(true)
    	else 
    		self.mLaveBlockBtn:setEnabled(false)
    	end 
    end 
end


function RAAllianceLeaveMsgMemberPage:Exit()
	UIExtend.unLoadCCBFile(RAAllianceLeaveMsgMemberPage)
end

--关闭
function RAAllianceLeaveMsgMemberPage:onClose()
    RARootManager.ClosePage("RAAllianceLeaveMsgMemberPage")
end

function RAAllianceLeaveMsgMemberPage:onMailBtn()
    -- RARootManager.ShowMsgBox('@NoOpenTips')
	RARootManager.OpenPage("RAMailWritePage",{sendName = self.info.playerName})
end

function RAAllianceLeaveMsgMemberPage:onPlayerInfoBtn()
	RARootManager.OpenPage('RAGeneralInfoPage', {playerId = self.info.playerId})
end 

function RAAllianceLeaveMsgMemberPage:onLaveBlockBtn()

    if RAAllianceManager.selfAlliance.tag == self.info.guildTag then 
        local str = _RALang("@CanotBlockAllianceMember")
        RARootManager.ShowMsgBox(str)
        return 
    end 

	RAAllianceProtoManager:forbidPlayerPostMessageReq(self.info.playerId)
end

return RAAllianceLeaveMsgMemberPage