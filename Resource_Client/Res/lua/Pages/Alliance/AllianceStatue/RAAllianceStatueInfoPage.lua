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
local GuildManager_pb = RARequire("GuildManager_pb")
local RAAllianceManager = RARequire("RAAllianceManager")
local RAAllianceUtility = RARequire('RAAllianceUtility')

local RAAllianceStatueInfoPage = BaseFunctionPage:new(...)

local OnReceiveMessage = function(message)    
    if message.messageID == MessageDef_Alliance.MSG_Alliance_Statue_Update then
        local statueId = RAAllianceStatueInfoPage.statueInfo.statueId
        local statueData = RAAllianceStatueManager:getStatueInfoByStatueId(statueId)
        RAAllianceStatueInfoPage:refreshData(statueData)       
    elseif message.messageID == MessageDef_Packet.MSG_Operation_OK then                 --删除邮件成功返回
        local opcode = message.opcode
        if opcode==HP_pb.GUILD_STATUE_UPGRADE_C then
            RARootManager.ShowMsgBox(_RALang('@StatueUpgradeSuccess'))
        elseif opcode==HP_pb.GUILD_STATUE_BUILD_C then
            RARootManager.ShowMsgBox(_RALang('@StatueBuildSucc'))
        end       
    end
end

function RAAllianceStatueInfoPage:registerMessageHandlers()
    MessageManager.registerMessageHandler(MessageDef_Alliance.MSG_Alliance_Statue_Update, OnReceiveMessage)
    MessageManager.registerMessageHandler(MessageDef_Packet.MSG_Operation_OK,OnReceiveMessage)
end

function RAAllianceStatueInfoPage:unregisterMessageHandlers()
    MessageManager.removeMessageHandler(MessageDef_Alliance.MSG_Alliance_Statue_Update, OnReceiveMessage)
    MessageManager.removeMessageHandler(MessageDef_Packet.MSG_Operation_OK,OnReceiveMessage)
end

function RAAllianceStatueInfoPage:sengetGuildStatueInfoResp()
    -- body
    RAAllianceProtoManager:sendGetStatueInfoResp()
end

function RAAllianceStatueInfoPage:Enter(data)

    UIExtend.loadCCBFile("RAAllianceStatuePopUp.ccbi",self)

    self:RegisterPacketHandler(HP_pb.GUILD_STATUE_UPGRADE_S)
    -- self:RegisterPacketHandler(HP_pb.GUILD_STATUE_UPGRADE_S)

    self:registerMessageHandlers()

    --是否是世界点进来的 ，是的话 请求雕像数据   TODO 这里是需要每次请求还是只请求一次？
    if data.isWorld then 
        self.statueIndex = data.statueIndex
        local statueData = RAAllianceStatueManager:getStatueInfoByIndex(data.statueIndex)
        if statueData then
            self:refreshData(statueData)
        else
            self:RegisterPacketHandler(HP_pb.GUILD_GET_STATUE_INFO_S)

            --发送获取雕像信息
            self:sengetGuildStatueInfoResp()
        end
    else
        self:refreshData(data)
    end

    self.mExplainLabel = UIExtend.getCCLabelTTFFromCCB(self.ccbfile,"mExplainLabel")
    self.mExplainLabel:setString(_RALang("@StatueExplain"))
    self.mExplainLabelStarP =ccp(self.mExplainLabel:getPosition())
    UIExtend.createLabelAction(self.ccbfile,"mExplainLabel")
end

function RAAllianceStatueInfoPage:refreshData(data)
    self.allianScore = data.allianScore
    self.statueInfo = data.statueInfo

    self:refreshUI()
end

function RAAllianceStatueInfoPage:onReceivePacket(handler)
    local pbCode = handler:getOpcode()
    local buffer = handler:getBuffer()
    if pbCode == HP_pb.GUILD_GET_STATUE_INFO_S then
        local msg = GuildManager_pb.GetGuildStatueInfoResp()
        msg:ParseFromString(buffer)
        self.statueInfo = RAAllianceStatueManager:setStatueData(msg)
        local data = RAAllianceStatueManager:setStatueInfo(self.statueIndex,self.statueInfo)

        self:refreshData(data)
    elseif pbCode == HP_pb.GUILD_STATUE_UPGRADE_S then
        print("pbCode == HP_pb.GUILD_STATUE_UPGRADE_S")
        local msg = GuildManager_pb.GetGuildStatueInfoResp()
        msg:ParseFromString(buffer)
        self.allianScore = msg.allianScore
        RARootManager.ShowMsgBox(_RALang('@StatueUpgradeSuccess'))
    end
end

function RAAllianceStatueInfoPage:getAttrsName(attrs,actualEffectValue)

    local attrNames = {}
    local attrsValues = {}
    local actualValues = {}

    for i = 1 ,#attrs do
        if attrs[i] then
            local attrName = RAAllianceStatueManager:getEffectConf(attrs[i].type)
            attrNames[#attrNames + 1] = _RALang(attrName)

            local currValue = attrs[i].value

            local actualValue = currValue

            --isAffact 为1的话 受联盟领地影响
            if actualEffectValue ~= nil and actualEffectValue ~= "" then 
                if attrs[i].isAffact == 1 then 
                    actualValue = math.floor(currValue * (tonumber(actualEffectValue)/100))
                end
            else
                currValue = 0
            end

            --additional 为1的话 为百分比值
            if attrs[i].additional == 1 then
                local value = currValue / 100
                actualValue = actualValue / 100
                local temStr = "+" .. value .. "%"
                attrsValues[#attrsValues + 1] = temStr
                if attrs[i].isAffact == 1 and actualEffectValue ~= nil and actualEffectValue ~= "" then
                    temStr = temStr .. 
                             " x "..actualEffectValue.."%"..
                             " = ".. actualValue .."%"
                end
                actualValues[#actualValues + 1] = temStr
                -- local value2 = actualValue / 100

            else
                local temStr = "+" ..  currValue
                attrsValues[#attrsValues + 1] = temStr
                if attrs[i].isAffact == 1 and actualEffectValue ~= nil and actualEffectValue ~= "" then
                    temStr = temStr .. 
                             " x "..actualEffectValue.."%"..
                             " = ".. actualValue
                end
                actualValues[#actualValues + 1] = temStr               
            end
        end
    end


    return attrNames,attrsValues,actualValues
end


function RAAllianceStatueInfoPage:refreshUI()
	-- body
	local statueId = self.statueInfo.statueId
    local statueLevel = self.statueInfo.level
    local statueConf = RAAllianceStatueManager:getStatueInfoConfById(statueId,statueLevel)

    --statue icon 
    UIExtend.setSpriteImage(self.ccbfile, {mStatuePic = statueConf.pic})

    -- self.nextStatueConf = RAAllianceStatueManager:getStatueInfoConfById(statueId,statueLevel + 1)
    --名称
    local statueName = statueConf.name 
    UIExtend.setStringForLabel(self.ccbfile, {mTitle = _RALang(statueName,statueLevel)})
    
    UIExtend.setNodesVisible(self.ccbfile, {
                                            mMaxLevel = false,
                                            })


    local next_level_need = ""
    local buildcost =  tostring(statueConf.build_cost or 0)

    if statueLevel == 0 then
        UIExtend.setNodeVisible(self.ccbfile, "mRebuildingIconNode", false)
        UIExtend.getCCLabelTTFFromCCB(self.ccbfile, "mRebuildingLabel"):setPositionX(0)
    else
        UIExtend.setNodeVisible(self.ccbfile, "mRebuildingIconNode", true)
        UIExtend.getCCLabelTTFFromCCB(self.ccbfile, "mRebuildingLabel"):setPositionX(-65)
    end
    if self.statueInfo.hasBuild then
        UIExtend.setCCLabelString(self.ccbfile,"mRebuildingLabel",_RALang("@Rebuilding"))
    else
        UIExtend.setCCLabelString(self.ccbfile,"mRebuildingLabel",_RALang("@Build"))
        -- if territoryData then
        --     UIExtend.setCCControlButtonEnable(self.ccbfile, "mRebuildingBtn", true)
        -- else
        --     UIExtend.setCCControlButtonEnable(self.ccbfile, "mRebuildingBtn", false)
        -- end        
    end  

    UIExtend.setNodeVisible(self.ccbfile, "mRebuildingIconNode", statueLevel ~= 0)
    UIExtend.setNodeVisible(self.ccbfile, "mMaxNode", statueConf.next_level == nil)
    UIExtend.setNodeVisible(self.ccbfile, "mUpgradeBtnNode", statueConf.next_level ~= nil)

    --还没有升级到最大
    if statueConf.next_level ~= nil then
        UIExtend.setStringForLabel(self.ccbfile, {mCurrentLevel = _RALang("@ResCollectTargetLevel",statueLevel)})
        UIExtend.setCCControlButtonEnable(self.ccbfile, "mUpgradeBtn", true)
        local nextStatueConf = RAAllianceStatueManager:getStatueInfoConfById(statueId,statueConf.next_level)
        next_level_need =  tostring(nextStatueConf.alliance_score)    
        -- UIExtend.setControlButtonTitle(self.ccbfile,"mUpgradeBtn",_RALang("@Upgrade"))
    else

        UIExtend.setCCControlButtonEnable(self.ccbfile, "mUpgradeBtn", false)
        UIExtend.setStringForLabel(self.ccbfile, {mCurrentLevel = _RALang("@StatueUpgradeMax",statueLevel)})
        -- UIExtend.setControlButtonTitle(self.ccbfile,"mUpgradeBtn",_RALang("@BuildMax"))
    end


    --雕像属性
    --当前等级数据
    local attrs = RAStringUtil:parseWithComma(statueConf.effect, {"type", "minValue", "maxValue", "isAffact", "additional"})
    for i,v in ipairs(attrs) do
        v.value = 0
        for j,v2 in ipairs(self.statueInfo.effect) do
            if v.type == v2.effectId then
                v.value = v2.effectValue
                break;
            end
        end
    end

    --影响值
    local guild_const_conf = RARequire("guild_const_conf")
    local allianceTerritoryScienceEffect = guild_const_conf['allianceTerritoryScienceEffect'].value
    local actualEffectValues = RAStringUtil:split(allianceTerritoryScienceEffect,",")
    local territoryData = RAAllianceManager:getManorDataById(RAAllianceManager.selfAlliance.manorId) 
    local manorLevel = 0
    if territoryData then
        manorLevel = tonumber(territoryData.level)
    end
    local attrNames,attrsValues,actualValues = self:getAttrsName(attrs,actualEffectValues[manorLevel])
    local nameStr = ""
    local valueStr = ""

    local noBuilding = _RALang("@NoBuilding")
    local noManor = _RALang("@NoManor")
    if #attrNames == 1 then
        nameStr = attrNames[1]
        if territoryData then
            if self.statueInfo.hasBuild then
                valueStr = actualValues[1]
            else
                valueStr = attrsValues[1] .. noBuilding
            end
        else
            valueStr = attrsValues[1].. noManor
        end
    else
        nameStr = attrNames[1].."\n\n\n"..attrNames[2]
        if territoryData then
            if self.statueInfo.hasBuild then
                valueStr = actualValues[1].."\n\n\n"..actualValues[2]
            else
                valueStr = attrsValues[1]..noBuilding.."\n\n\n"..attrsValues[2]..noBuilding
            end
        else
            valueStr = attrsValues[1]..noManor.."\n\n\n"..attrsValues[2]..noManor
        end
    end
    -- UIExtend.getCCLabelTTFFromCCB(self.ccbfile, "mAdditionalTitleLabel"):setAnchorPoint(ccp(0,0.5))
    -- UIExtend.getCCLabelTTFFromCCB(self.ccbfile, "mAdditionalLabel"):setAnchorPoint(ccp(0,0.5))
 
    local RAGameConfig = RARequire('RAGameConfig')

    local stringColor = (territoryData and self.statueInfo.hasBuild) and RAGameConfig.COLOR.GREEN or RAGameConfig.COLOR.RED
    UIExtend.setColorForLabel(self.ccbfile, {mAdditionalLabel = stringColor})

    UIExtend.setStringForLabel(self.ccbfile,{   mAdditionalTitleLabel = nameStr, 
                                                mAdditionalLabel = valueStr,
                                                mNeedNum = next_level_need,
                                                mRebuildingNeedNum = buildcost
                                                })




   


end

--
function RAAllianceStatueInfoPage:onStatueEffectInfoBtn()
    if self.statueInfo and self.statueInfo.level > 0 then
        RARootManager.OpenPage("RAAllianceStatueEffectDetailPage", {statueId = self.statueInfo.statueId}, false, true, true)
    else
        RARootManager.ShowMsgBox(_RALang('@NeedBuildStatue'))
    end
end
  
--
function RAAllianceStatueInfoPage:onLevelInfoBtn()
    RARootManager.OpenPage("RAAllianceStatueLevelEffectPage", {statueId = self.statueInfo.statueId}, false, true, true)
end


--建造或者重建
function RAAllianceStatueInfoPage:onRebuildingBtn()
    if RAAllianceUtility:isCanRebuildStatue(RAAllianceManager.authority) then
        if self.statueInfo.level > 0 then
            if self.statueInfo.hasBuild then
                RARootManager.OpenPage("RAAllianceStatueInfoRebuildPage", {statueId = self.statueInfo.statueId}, false, true, true)     
            else
                local isCanRebuild = true
                local resultStr = ""
                local statueConf = RAAllianceStatueManager:getStatueInfoConfById(self.statueInfo.statueId, self.statueInfo.level)
                if tonumber(self.allianScore) < tonumber(statueConf.build_cost) then
                    resultStr = _RALang("@StatueUpgradeScoreEnough")
                    isCanRebuild = false  
                end

                if not isCanRebuild then
                    RARootManager.ShowMsgBox(resultStr)
                else
                    RAAllianceProtoManager:sendGuildStatueBuildReq(self.statueInfo.statueId)    
                end
            end
        else
            RARootManager.ShowMsgBox(_RALang('@StatueLevelZero'))
        end
    else    
        RARootManager.ShowMsgBox(_RALang('@NotHaveAuthorityToRebuild'))
    end
end

--升级
function RAAllianceStatueInfoPage:onUpgradeBtn()
    -- body
    local isCanUpgrade = true
    local resultStr = ""
    local nextStatueConf = RAAllianceStatueManager:getStatueInfoConfById(self.statueInfo.statueId, self.statueInfo.level + 1)
    if tonumber(self.allianScore) < tonumber(nextStatueConf.alliance_score) then
        resultStr = _RALang("@StatueUpgradeScoreEnough")
        isCanUpgrade = false  
    end

    if not isCanUpgrade then
        RARootManager.ShowMsgBox(resultStr)
    else
        RAAllianceProtoManager:sendGuildStatueUpgradeReq(self.statueInfo.statueId)    
    end
end

function RAAllianceStatueInfoPage:onClose()
    RARootManager.CloseCurrPage()
end

function RAAllianceStatueInfoPage:Exit()
    self:RemovePacketHandlers()
	self:unregisterMessageHandlers()
    
    self.statueInfo = nil
    self.statueQueueInfo = nil

    self.mExplainLabel:stopAllActions()
    self.mExplainLabel:setPosition(self.mExplainLabelStarP)

    self.ccbfile:stopAllActions()
    
    UIExtend.unLoadCCBFile(self)
    self.ccbfile = nil
end

return RAAllianceStatueInfoPage