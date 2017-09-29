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

local RAAllianceStatueInfoRebuildPage = BaseFunctionPage:new(...)

local OnReceiveMessage = function(message)    
    if message.messageID == MessageDef_Alliance.MSG_Alliance_Statue_Update then
        local statueId = RAAllianceStatueInfoRebuildPage.statueInfo.statueId
        local statueData = RAAllianceStatueManager:getStatueInfoByStatueId(statueId)

        RAAllianceStatueInfoRebuildPage:refreshData(statueData)       
    end
end

function RAAllianceStatueInfoRebuildPage:registerMessageHandlers()
    MessageManager.registerMessageHandler(MessageDef_Alliance.MSG_Alliance_Statue_Update, OnReceiveMessage)
end

function RAAllianceStatueInfoRebuildPage:unregisterMessageHandlers()
    MessageManager.removeMessageHandler(MessageDef_Alliance.MSG_Alliance_Statue_Update, OnReceiveMessage)
end


function RAAllianceStatueInfoRebuildPage:Enter(data)

    UIExtend.loadCCBFile("RAAllianceStatueRebuildingPopUp.ccbi",self)
    UIExtend.setCCLabelString(self.ccbfile,"mTitle", _RALang("@StatueRebuild"))

    self:RegisterPacketHandler(HP_pb.GUILD_STATUE_UPGRADE_S)
    self:registerMessageHandlers()
    local statueInfo = RAAllianceStatueManager:getStatueInfoByStatueId(data.statueId)

    self:refreshData(statueInfo)
end

function RAAllianceStatueInfoRebuildPage:refreshData(data)
    self.allianScore = data.allianScore
    self.statueInfo = data.statueInfo

    self:refreshUI()
end


function RAAllianceStatueInfoRebuildPage:onReceivePacket(handler)
    local pbCode = handler:getOpcode()
    local buffer = handler:getBuffer()
    if pbCode == HP_pb.GUILD_GET_STATUE_INFO_S then
        local msg = GuildManager_pb.GetGuildStatueInfoResp()
        msg:ParseFromString(buffer)
        self.statueInfo = RAAllianceStatueManager:setStatueData(msg)
        local data = RAAllianceStatueManager:setStatueInfo(self.statueIndex,self.statueInfo)

        self:refreshData(data)
    elseif pbCode == HP_pb.GUILD_STATUE_UPGRADE_S then
        local msg = GuildManager_pb.GetGuildStatueInfoResp()
        msg:ParseFromString(buffer)
        self.allianScore = msg.allianScore
    end
end


function RAAllianceStatueInfoRebuildPage:getAttrsName(attrs)

    local attrNames = {}
    local attrsValues = {}
    local attrsNewValues = {}

    for i = 1 ,#attrs do
        if attrs[i] then
            local attrName = RAAllianceStatueManager:getEffectConf(attrs[i].type)
            attrNames[#attrNames + 1] = _RALang(attrName)

            local currValue = attrs[i].value
            local newValue = attrs[i].newValue

            --isAffact 为1的话 受联盟领地影响
            -- if attrs[i].isAffact == 1 then
            --     if actualEffectValue == nil or actualEffectValue == "" then
            --         actualEffectValue = 0
            --     end
            --     currValue = currValue * (tonumber(actualEffectValue)/100)
            --     if newValue and newValue > 0 then
            --         newValue = newValue * (tonumber(actualEffectValue)/100)
            --     end
            -- end

            --additional 为1的话 为百分比值
            if attrs[i].additional == 1 then
                local value = currValue / 100
                attrsValues[#attrsValues + 1] = value .. "%"

                if newValue then
                    newValue = newValue / 100
                    attrsNewValues[#attrsNewValues + 1] = newValue .. "%"
                end

            else
                 attrsValues[#attrsValues + 1] = currValue
                 attrsNewValues[#attrsNewValues + 1] = newValue
            end
        end
    end


    return attrNames,attrsValues,attrsNewValues
end


--self.attrUpNum: 新属性比原属性高的个数
function RAAllianceStatueInfoRebuildPage:refreshUI()
	-- body
    self.attrUpNum = 0
    self.attrDownNum = 0
	local statueId = self.statueInfo.statueId
    local statueLevel = self.statueInfo.level
    local hasNewEffectValue = #self.statueInfo.refreshEffect > 0
    local statueConf = RAAllianceStatueManager:getStatueInfoConfById(statueId,statueLevel)
    local buildcost =  tostring(statueConf.build_cost or 0)
    UIExtend.setNodesVisible(self.ccbfile, {
                                                mGiveUpBtnNode = hasNewEffectValue, 
                                                mHoldBtnNode = hasNewEffectValue,
                                                mRebuidlingBtnNode = not hasNewEffectValue
                                            })
    
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
        
        if #self.statueInfo.refreshEffect > 0 then
            v.newValue = 0
            for j,v2 in ipairs(self.statueInfo.refreshEffect) do
                if v.type == v2.effectId then
                    v.newValue = v2.effectValue
                    break;
                end
            end        
        end
    end

    -- --影响值
    -- local guild_const_conf = RARequire("guild_const_conf")
    -- local allianceTerritoryScienceEffect = guild_const_conf['allianceTerritoryScienceEffect'].value
    -- local actualEffectValues = RAStringUtil:split(allianceTerritoryScienceEffect,",")
    -- local territoryData = RAAllianceManager:getManorDataById(RAAllianceManager.selfAlliance.manorId) 
    -- local manorLevel = 0
    -- if territoryData then
    --     manorLevel = tonumber(territoryData.level)
    -- end
    local attrNames,attrsValues,attrsActualValues = self:getAttrsName(attrs)
    
    local currName = ""
    local currValueStr = ""
    local nextName = ""
    local nextValue = "???"
    local mAddArrow1 = false
    local mAddArrow2 = false
    local mSubArrow1 = false
    local mSubArrow2 = false
    local mFlatArrow1 = false
    local mFlatArrow2 = false

    local upPosy = UIExtend.getCCNodeFromCCB(self.ccbfile,"mArrowNode1"):getPositionY()
    local downPosy = UIExtend.getCCNodeFromCCB(self.ccbfile,"mArrowNode2"):getPositionY()
    local midPosy = (upPosy  +  downPosy)/2
    local posList = {midPosy,midPosy,midPosy,midPosy,midPosy,midPosy}
    if #attrNames == 1 then
        currName = attrNames[1]
        currValueStr = attrsValues[1]
        nextName = attrNames[1]
        if hasNewEffectValue then
            nextValue = attrsActualValues[1]
            if attrs[1].value > attrs[1].newValue then
                self.attrDownNum = self.attrDownNum + 1
                mSubArrow1 = true
            elseif attrs[1].value < attrs[1].newValue then
                mAddArrow1 = true
                self.attrUpNum = self.attrUpNum + 1
            else
                mFlatArrow1 = true
            end
        end
    elseif#attrNames == 2 then
        currName = attrNames[1].."\n\n\n"..attrNames[2]
        currValueStr = attrsValues[1].."\n\n\n"..attrsValues[2]
        nextName = attrNames[1].."\n\n\n"..attrNames[2]
        if hasNewEffectValue then
            nextValue = attrsActualValues[1].."\n\n\n"..attrsActualValues[2]
            if attrs[1].value > attrs[1].newValue then
                mSubArrow1 = true
                posList[3] = upPosy
                self.attrDownNum = self.attrDownNum + 1
            elseif attrs[1].value < attrs[1].newValue then
                mAddArrow1 = true
                posList[1] = upPosy
                self.attrUpNum = self.attrUpNum + 1
            else
                mFlatArrow1 = true
                posList[5] = upPosy                
            end 
            if attrs[2].value > attrs[2].newValue then
                mSubArrow2 = true
                posList[4] = downPosy
                self.attrDownNum = self.attrDownNum + 1
            elseif attrs[2].value < attrs[2].newValue then
                mAddArrow2 = true
                posList[2] = downPosy
                self.attrUpNum = self.attrUpNum + 1
            else
                mFlatArrow2 = true
                posList[6] = upPosy                 
            end                          
        end
    end

    UIExtend.getCCNodeFromCCB(self.ccbfile,"mAddArrow1"):setPositionY(posList[1])
    UIExtend.getCCNodeFromCCB(self.ccbfile,"mAddArrow2"):setPositionY(posList[2])
    UIExtend.getCCNodeFromCCB(self.ccbfile,"mSubArrow1"):setPositionY(posList[3])
    UIExtend.getCCNodeFromCCB(self.ccbfile,"mSubArrow2"):setPositionY(posList[4])
    UIExtend.getCCNodeFromCCB(self.ccbfile,"mFlatArrow1"):setPositionY(posList[5])
    UIExtend.getCCNodeFromCCB(self.ccbfile,"mFlatArrow2"):setPositionY(posList[6])

    UIExtend.setNodesVisible(self.ccbfile, {
                                            mAddArrow1 = mAddArrow1,
                                            mAddArrow2 = mAddArrow2,
                                            mSubArrow1 = mSubArrow1,
                                            mSubArrow2 = mSubArrow2,
                                            mFlatArrow1 = mFlatArrow1,
                                            mFlatArrow2 = mFlatArrow2

                                            })

    UIExtend.setStringForLabel(self.ccbfile, { 
                                                mCurrentTitle = currName,
                                                mCurrentData = currValueStr,
                                                -- mNextTitle = nextName,
                                                mNextData = nextValue,
                                                mRebuildingNeedNum = buildcost
                                            })

end


function RAAllianceStatueInfoRebuildPage:onGiveUpBtn()
    if self.attrUpNum > 0 then
        local confirmData =
        {
            labelText = _RALang('@StatueHasUpAttr'),
            yesNoBtn = true,
            resultFun = function (isOK)
                if isOK then
                    RAAllianceProtoManager:sendGuildStatueReBuildSaveReq(self.statueInfo.statueId, false)
                end
            end
        }
        RARootManager.showConfirmMsg(confirmData)        
    else
        RAAllianceProtoManager:sendGuildStatueReBuildSaveReq(self.statueInfo.statueId, false)
    end
end

--
function RAAllianceStatueInfoRebuildPage:onHoldBtn()
    if self.attrDownNum > 0 then
        local confirmData =
        {
            labelText = _RALang('@StatueHasDownAttr'),
            yesNoBtn = true,
            resultFun = function (isOK)
                if isOK then
                    RAAllianceProtoManager:sendGuildStatueReBuildSaveReq(self.statueInfo.statueId, true)
                end
            end
        }
        RARootManager.showConfirmMsg(confirmData)
    else
        RAAllianceProtoManager:sendGuildStatueReBuildSaveReq(self.statueInfo.statueId, true)
    end
end

function RAAllianceStatueInfoRebuildPage:onRebuildingBtn()
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
        RAAllianceProtoManager:sendGuildStatueReBuildReq(self.statueInfo.statueId)    
    end
end

function RAAllianceStatueInfoRebuildPage:onClose()
    RARootManager.CloseCurrPage()
end

function RAAllianceStatueInfoRebuildPage:Exit()
    self:RemovePacketHandlers()
    self:unregisterMessageHandlers()

    self.allianScore = nil
    self.attrDownNum = nil
    self.attrUpNum = nil
    self.statueInfo = nil

    self.ccbfile:stopAllActions()
    
    UIExtend.unLoadCCBFile(self)
    self.ccbfile = nil
end

return RAAllianceStatueInfoRebuildPage