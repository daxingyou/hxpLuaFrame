RARequire("BasePage")
local player_talent_conf = RARequire("player_talent_conf")
local RANetUtil = RARequire("RANetUtil")
local UIExtend = RARequire("UIExtend")
local RATalentManager = RARequire("RATalentManager")
local RARootManager = RARequire("RARootManager")
local Utilitys = RARequire("Utilitys")
local Talent_pb = RARequire("Talent_pb")
local HP_pb = RARequire("HP_pb")
local RAStringUtil = RARequire("RAStringUtil")
local RAGuideManager=RARequire("RAGuideManager")

local RATalentUpgradePage = BaseFunctionPage:new(...)
RATalentUpgradePage.talenId = 0--number
RATalentUpgradePage.talenRouteType = 0--number
RATalentUpgradePage.packetHandler = {}
RATalentUpgradePage.upgradeOnceBtn = nil--升级一次按钮
RATalentUpgradePage.upgradeAllBtn = nil--升级多次按钮
RATalentUpgradePage.isInUpgrading = false--是否在升级
RATalentUpgradePage.isUpgradeSuccess = false--是否进行了升级操作并且操作成功
RATalentUpgradePage.isColose = false


local OnReceiveMessage = function(message)
    if message.messageID == MessageDef_Guide.MSG_Guide then 
        local constGuideInfo = message.guideInfo
        local guideId = constGuideInfo.guideId
        local RAGuideConfig=RARequire("RAGuideConfig")
        if constGuideInfo and constGuideInfo.keyWord == RAGuideConfig.KeyWordArray.CircleLearnAllBtn then
             if constGuideInfo.showGuidePage == 1 then
                local learnAllNode = UIExtend.getCCNodeFromCCB(RATalentUpgradePage.ccbfile, "mGuideLearnAllNode")
                local pos = ccp(0, 0)
                pos.x, pos.y = learnAllNode:getPosition()
                local worldPos = learnAllNode:getParent():convertToWorldSpace(pos)
                local size = learnAllNode:getContentSize()
                size.width = size.width + RAGuideConfig.GuideTips.ConfigOffset*2
                size.height = size.height + RAGuideConfig.GuideTips.ConfigOffset*2
                RARootManager.AddGuidPage({["guideId"] = guideId, ["pos"] = worldPos, ["size"] = size})
            end
        end 
    elseif message.messageID == MessageDef_RootManager.MSG_ActionEnd then 
        if RAGuideManager.partComplete.Guide_UIUPDATE and RAGuideManager.isInGuide() then
            RARootManager.AddCoverPage()
            RAGuideManager.gotoNextStep()
        end 
    end
end

function RATalentUpgradePage:Enter(data)
    
    RATalentUpgradePage.talenId = data.talentId
    RATalentUpgradePage.talenRouteType = data.talentRouteType
    RATalentUpgradePage.isInUpgrading = false

    local serverTalentsInfo = RATalentManager.getTalentInfoByType(data.talentRouteType)
    local constTalentInfo = player_talent_conf[data.talentId]
    local isLock = RATalentManager.isTalentLock(data.talentRouteType, data.talentId)

    if isLock then
        self.ccbfile = UIExtend.loadCCBFile("RALordSkillPopUp3V2.ccbi", RATalentUpgradePage)
    elseif serverTalentsInfo and  constTalentInfo and  serverTalentsInfo[data.talentId] and serverTalentsInfo[data.talentId].level == constTalentInfo.maxLevel then
        self.ccbfile = UIExtend.loadCCBFile("RALordSkillPopUp1V2.ccbi", RATalentUpgradePage)
    else
        self.ccbfile = UIExtend.loadCCBFile("RALordSkillPopUp2V2.ccbi", RATalentUpgradePage)
        RATalentUpgradePage.upgradeOnceBtn = UIExtend.getCCControlButtonFromCCB(self.ccbfile, "mLearnBtn")
        RATalentUpgradePage.upgradeAllBtn = UIExtend.getCCControlButtonFromCCB(self.ccbfile, "mLearnAllBtn")        
    end

    RATalentUpgradePage:refreshUI(RATalentUpgradePage.talenRouteType, RATalentUpgradePage.talenId)
    self:addHandler()
end

function RATalentUpgradePage:refreshUI(talenRouteType, talentId)
    local serverTalentsInfo = RATalentManager.getTalentInfoByType(talenRouteType)
    local constTalentInfo = player_talent_conf[talentId]
    local isLock = RATalentManager.isTalentLock(talenRouteType, talentId)
    local level = 0
    local iconNode = nil
    if constTalentInfo then
        UIExtend.setCCLabelString(self.ccbfile, "mSkillExplain", _RALang(constTalentInfo.des))
        iconNode = UIExtend.addSpriteToNodeParent(self.ccbfile, "mCellIconNode", constTalentInfo.icon)
        if iconNode then
            UIExtend.setCCSpriteGray(iconNode, isLock)
        end
        UIExtend.setCCLabelString(self.ccbfile, "mPopUpTitle", _RALang(constTalentInfo.name))
    end
    

    if serverTalentsInfo and serverTalentsInfo[talentId] ~= nil then
        level = serverTalentsInfo[talentId].level
    end
    local levelStr = level .. "/"..constTalentInfo.maxLevel
    UIExtend.setCCLabelString(self.ccbfile, "mCellLevel", levelStr)
    if level == constTalentInfo.maxLevel then
        UIExtend.setLabelTTFColor(self.ccbfile, "mCellLevel", ccc3(255, 255, 0))
    else
        UIExtend.setLabelTTFColor(self.ccbfile, "mCellLevel", ccc3(255, 255, 255))
    end

    local levelEffectStr = RATalentManager.getTalentEffectStrWithSymble(self.talenId, level)
    local levelEffectStr = _RALang("@ResourceLevel", level) .."\n".. levelEffectStr
    UIExtend.setCCLabelString(self.ccbfile, "mCurrentLevel", levelEffectStr)
    local nextLevel = level +1
    if nextLevel <= constTalentInfo.maxLevel then
        local levelNextEffectStr = RATalentManager.getTalentEffectStrWithSymble(self.talenId, nextLevel)
        levelNextEffectStr = _RALang("@ResourceLevel", nextLevel)  .."\n".. levelNextEffectStr
        UIExtend.setCCLabelString(self.ccbfile, "mNextLevel", levelNextEffectStr)            
        if not isLock then
            if RATalentManager.getFreeGeneralNum(self.talenRouteType) > 0 then
                --按钮可用
                self:setBtnEnable(true)
            else
                --按钮不可用
                self:setBtnEnable(false)
            end
        end
    end


    if isLock then

        if constTalentInfo.frontTalent then
            local frontTalents = Utilitys.Split(constTalentInfo.frontTalent, ",")
            local leftLabel, rightLabel
            for i = 1, 3 do
                leftLabel = UIExtend.getCCLabelTTFFromCCB(self.ccbfile, "mLeftUnlockLabel"..i)
                rightLabel = UIExtend.getCCLabelTTFFromCCB(self.ccbfile, "mRightUnlockLabel"..i)
                if frontTalents[i] ~= nil then
                    local frontTalentArr = Utilitys.Split(frontTalents[i], "_")
                    local frontTalentId = tonumber(frontTalentArr[1])
                    local frontTalentLevel = tonumber(frontTalentArr[2]) 
                    local frontTalentConstInfo = player_talent_conf[frontTalentId]
                    local tmpStr = RAStringUtil:getLanguageString("@LevelNum", frontTalentArr[2])
                    leftLabel:setVisible(true)
                    leftLabel:setString(_RALang(frontTalentConstInfo.name))
                    leftLabel:setPositionY(30 * (#frontTalents - 1)/2 - i*30 + 30)
                    rightLabel:setVisible(true)
                    rightLabel:setString(tmpStr)
                    rightLabel:setPositionY(30 * (#frontTalents - 1)/2 - i*30 + 30)
                    if serverTalentsInfo == nil or serverTalentsInfo[frontTalentId] == nil or (serverTalentsInfo[frontTalentId] ~= nil and serverTalentsInfo[frontTalentId].level < frontTalentLevel) then
                        leftLabel:setColor(ccc3(182,22,0))
                        rightLabel:setColor(ccc3(182,22,0))
                    else
                        leftLabel:setColor(ccc3(82,214,66))
                        rightLabel:setColor(ccc3(82,214,66))
                    end
                else
                    leftLabel:setVisible(false)
                    rightLabel:setVisible(false)
                end
            end
        end
    end
end

function RATalentUpgradePage:addHandler()
    if RAGuideManager.partComplete.Guide_UIUPDATE then
         MessageManager.registerMessageHandler(MessageDef_Guide.MSG_Guide,OnReceiveMessage)
         MessageManager.registerMessageHandler(MessageDef_RootManager.MSG_ActionEnd,OnReceiveMessage) 
    end
    RATalentUpgradePage.packetHandler[#RATalentUpgradePage.packetHandler +1] = RANetUtil:addListener(HP_pb.TALENT_UPGRADE_S, RATalentUpgradePage)

end

function RATalentUpgradePage:removeHandler()

    if RAGuideManager.partComplete.Guide_UIUPDATE then
        MessageManager.removeMessageHandler(MessageDef_Guide.MSG_Guide,OnReceiveMessage)
        MessageManager.removeMessageHandler(MessageDef_RootManager.MSG_ActionEnd,OnReceiveMessage)
    end

    for i = 1, #RATalentUpgradePage.packetHandler do
        RANetUtil:removeListener(RATalentUpgradePage.packetHandler[i])
        RATalentUpgradePage.packetHandler[i] = nil
    end
    RATalentUpgradePage.packetHandler = {}
end

function RATalentUpgradePage:setBtnEnable(enable)
    RATalentUpgradePage.upgradeOnceBtn:setEnabled(enable)
    RATalentUpgradePage.upgradeAllBtn:setEnabled(enable)
end

function RATalentUpgradePage:onReceivePacket(handler)
    local pbCode = handler:getOpcode()
    local buffer = handler:getBuffer()
    if pbCode == HP_pb.TALENT_UPGRADE_S then
        RARootManager.RemoveWaitingPage()
        local msg = Talent_pb.HPTalentUpgradeResp()
        msg:ParseFromString(buffer)
        if msg.result == true then
            local talentLevel = msg.level
            local talentInfo = RATalentManager.getTalentInfoByType(self.talenRouteType)
            local preLevel = 0
            if talentInfo and talentInfo[self.talenId] then
                preLevel = talentInfo[self.talenId].level
            end
            if preLevel >= talentLevel then
                --todo 数据出错了
                CCLuaLog("Talent Level Upgrade Error!")
                return
            end
            RATalentManager.addTalentEffect(self.talenId, preLevel, talentLevel)
            RATalentManager.setTalentLevel(self.talenRouteType, self.talenId, talentLevel)
            self:refreshUI(self.talenRouteType, self.talenId)
            self.isUpgradeSuccess = true

            local constTalentInfo = player_talent_conf[self.talenId]
            RARootManager.ShowMsgBox(_RALang("@StudyComplete",_RALang(constTalentInfo.name),talentLevel))

            self:isColoseUpgradePage()

            --新手 by xinping
            if RAGuideManager.partComplete.Guide_UIUPDATE and RAGuideManager.isInGuide() then
                RAGuideManager.gotoNextStep()
            end

        else
            --todo 升级失败
            CCLuaLog("")
            self:setBtnEnable(true)
        end
        RATalentUpgradePage.isInUpgrading = false
    end
end

function RATalentUpgradePage:isColoseUpgradePage()
    -- body
    if self.isColose then
        RARootManager.CloseCurrPage()
    end
end

function RATalentUpgradePage:onLearnBtn()
    --如果正在升级则返回
    if RATalentUpgradePage.isInUpgrading then
        return
    end
    RARootManager.ShowWaitingPage(false)

    RATalentUpgradePage.isInUpgrading = true

    local serverTalentsInfo = RATalentManager.getTalentInfoByType(self.talenRouteType)
    local level = 0

    if serverTalentsInfo and serverTalentsInfo[RATalentUpgradePage.talenId] ~= nil then
        level = serverTalentsInfo[RATalentUpgradePage.talenId].level
    end
    local msg = Talent_pb.HPTalentUpgradeReq()
    msg.talentId = RATalentUpgradePage.talenId
    msg.targetLevel = level +1
    msg["type"] = self.talenRouteType
    RANetUtil:sendPacket(HP_pb.TALENT_UPGRADE_C, msg)
    self:setBtnEnable(false)
    RATalentUpgradePage.isInUpgrading = true
end

function RATalentUpgradePage:onLearnAllBtn()
    if RAGuideManager.partComplete.Guide_UIUPDATE and RAGuideManager.isInGuide() then
       RARootManager.AddCoverPage()
       RARootManager.RemoveGuidePage()
    end

    --如果正在升级则返回
    if RATalentUpgradePage.isInUpgrading then
        return
    end
    RARootManager.ShowWaitingPage(false)

    RATalentUpgradePage.isInUpgrading = true

    self.isColose = true

    local serverTalentsInfo = RATalentManager.getTalentInfoByType(self.talenRouteType)
    local level = 0
    if serverTalentsInfo and serverTalentsInfo[RATalentUpgradePage.talenId] ~= nil then
        level = serverTalentsInfo[RATalentUpgradePage.talenId].level
    end
    local maxLevel = player_talent_conf[RATalentUpgradePage.talenId].maxLevel
    local remainPoint = RATalentManager.getFreeGeneralNum(self.talenRouteType)

    local msg = Talent_pb.HPTalentUpgradeReq()
    msg.talentId = RATalentUpgradePage.talenId
    if remainPoint > (maxLevel - level) then
        msg.targetLevel = maxLevel
    else
        msg.targetLevel = level + remainPoint
    end
    msg["type"] = self.talenRouteType
    RANetUtil:sendPacket(HP_pb.TALENT_UPGRADE_C, msg)
    self:setBtnEnable(false)
end

function RATalentUpgradePage:onClose()
    RARootManager.ClosePage("RATalentUpgradePage")
end

function RATalentUpgradePage:Exit(data)
    if self.isUpgradeSuccess then
        MessageManager.sendMessage(MessageDef_Lord.MSG_TalentUpgrade, {talentId = self.talenId})
    else
        MessageManager.sendMessage(MessageDef_Lord.MSG_TalentUpgrade)
    end
    self:removeHandler()
    UIExtend.unLoadCCBFile(RATalentUpgradePage)
    self.ccbfile = nil
    self.isUpgradeSuccess = false--是否进行了升级操作并且操作成功
    self.isColose = false
end

function RATalentUpgradePage:setMaxLevel(isMax)
    UIExtend.setNodeVisible(self.ccbfile, "mYesNoBtnNode", not isMax)
    UIExtend.setNodeVisible(self.ccbfile, "mIsMaxLevel", isMax)
end