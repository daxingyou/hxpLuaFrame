RARequire("BasePage")

local RARootManager = RARequire("RARootManager")
local UIExtend = RARequire('UIExtend')
local RALordUpgradePage = BaseFunctionPage:new(...)
local RALordUpgradeManager = RARequire("RALordUpgradeManager")
local HP_pb = RARequire("HP_pb")
local player_level_conf = RARequire("player_level_conf")
local Utilitys = RARequire("Utilitys")
local item_conf = RARequire("item_conf")
local RALogicUtil = RARequire("RALogicUtil")
local RAResManager = RARequire("RAResManager")
local RAGameConfig = RARequire("RAGameConfig")
local RAStringUtil = RARequire("RAStringUtil")
local RAPackageData = RARequire("RAPackageData")

RALordUpgradePage.rewardsSV = nil


local OnReceiveMessage = function(message)
    if  message.messageID==MessageDef_Packet.MSG_Operation_OK then
        local opcode = message.opcode
        if opcode==HP_pb.LEVEL_UP_REWARD_C then 
            local RALordUpgradeManager = RARequire("RALordUpgradeManager")
            local flag = RALordUpgradeManager:hasUnclaimedReward()
            if flag then
                local RARootManager = RARequire("RARootManager")
                RARootManager.OpenPage("RALordUpgradePage")
            else
                -- RARootManager.CloseCurrPage()
                RARootManager.ClosePage('RALordUpgradePage')
            end
            --RARootManager.CloseCurrPage()
        end
    end
end

-------------------------------------------------------------------------------------
local RALordUpgradeRewardCellListener = 
{
    rewardStr = nil
}

function RALordUpgradeRewardCellListener:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    return o
end

function RALordUpgradeRewardCellListener:onRefreshContent(ccbRoot)
    local ccbfile = ccbRoot:getCCBFileNode()
    if ccbfile then
        local rewardArr = Utilitys.Split(self.rewardStr, "_")
        local mainType = rewardArr[1]
        local rewardId = rewardArr[2]
        local rewardCount = rewardArr[3]

        --Ìí¼ÓÆ·ÖÊ¿ò
        if (tonumber(mainType)*0.0001) == Const_pb.TOOL then
            local constItemInfo = item_conf[tonumber(rewardId)]
            if constItemInfo then
                local qualityIcon = RALogicUtil:getItemBgByColor(constItemInfo.item_color)
                UIExtend.addSpriteToNodeParent(ccbfile, "mItemIconNode", qualityIcon,nil, nil, 20000)

                RAPackageData.setNumTypeInItemIcon(ccbfile, "mItemHaveNum", "mItemHaveNumNode", constItemInfo)
            end
        else
            UIExtend.setNodeVisible(ccbfile, "mItemHaveNumNode", false)
            UIExtend.addSpriteToNodeParent(ccbfile, "mItemIconNode", "Common_u_Quality_04.png",nil, nil, 20000)
        end

        --Ìí¼Óicon
        local icon, _ = RAResManager:getIconByTypeAndId(tonumber(mainType), tonumber(rewardId))
        UIExtend.addSpriteToNodeParent(ccbfile, "mItemIconNode", icon)
        UIExtend.setCCLabelString(ccbfile, "mItemNum", tostring(rewardCount))
    end
end

--------------------------------------------------------------------------------------
function RALordUpgradePage:Enter(data)
	
	local ccbfile = UIExtend.loadCCBFile("RALevelUpPopUpV2.ccbi",RALordUpgradePage)
	self.ccbfile = ccbfile
    -- self.rewardsSV = UIExtend.getCCScrollViewFromCCB(self.ccbfile, "mItemListSV")
	MessageManager.registerMessageHandler(MessageDef_Packet.MSG_Operation_OK, OnReceiveMessage)
	
    self:CommonRefresh()

end



function RALordUpgradePage:CommonRefresh()
    -- self.rewardsSV:removeAllCell()
    local flag,nextReward = RALordUpgradeManager:hasUnclaimedReward()
    if flag then
        --read table
        local realIndex = RAGameConfig.ConfigIDFragment.ID_PLAYER_LEVEL + nextReward - 1--Æ´½ÓµÃµ½ÅäÖÃ±íµÄkey
        local levelConstInfo = player_level_conf[realIndex]
        if levelConstInfo then
            UIExtend.setCCLabelBMFontString(self.ccbfile, "mLevel", tostring(nextReward))--µÈ¼¶
            UIExtend.setCCLabelBMFontString(self.ccbfile, "mLevelDark", tostring(nextReward))
            local fightAddPower = levelConstInfo.battlePoint
            local skillAddPoint = levelConstInfo.skillPoint
            if nextReward > 1 then
                local preConstInfo = player_level_conf[realIndex-1]
                if preConstInfo then
                    fightAddPower = fightAddPower - preConstInfo.battlePoint
                    skillAddPoint = skillAddPoint - preConstInfo.skillPoint
                end
            end
            local fightStr = _RALang("@FightValueAdd", fightAddPower)
            UIExtend.setCCLabelString(self.ccbfile, "mWarPower", fightStr)--Õ½¶·Á¦
            local skillStr = RAStringUtil:getLanguageString("@SkillPointAdd", skillAddPoint)
            UIExtend.setCCLabelString(self.ccbfile, "mSkillPoint", skillStr)--¼¼ÄÜµã

            local rewardStrArry = Utilitys.Split(levelConstInfo.levelAward, ",")
            local count=RALordUpgradeManager.maxRewordNum
            for i=1, count do
                local rewardStr = rewardStrArry[i]
                -- local listener = RALordUpgradeRewardCellListener:new({["rewardStr"] = rewardStr})
                -- local cell = CCBFileCell:create()
                -- cell:setCCBFile("RALevelUpCell.ccbi")
                -- cell:registerFunctionHandler(listener)
                -- self.rewardsSV:addCell(cell)

                local rewordCellCCB=UIExtend.getCCBFileFromCCB(self.ccbfile,"mItemCCB"..i)
                if rewardStr then
                    rewordCellCCB:setVisible(true)
                    local rewardArr = Utilitys.Split(rewardStr, "_")
                    local mainType = rewardArr[1]
                    local rewardId = rewardArr[2]
                    local rewardCount = rewardArr[3]
                    if (tonumber(mainType)*0.0001) == Const_pb.TOOL then
                        local constItemInfo = item_conf[tonumber(rewardId)]
                        if constItemInfo then
                            local qualityIcon = RALogicUtil:getItemBgByColor(constItemInfo.item_color)
                            UIExtend.addSpriteToNodeParent(rewordCellCCB, "mQualityIconNode", qualityIcon,nil, nil, 20000)

                            RAPackageData.setNumTypeInItemIcon(rewordCellCCB, "mItemHaveNum", "mItemHaveNumNode", constItemInfo)
                        end
                    else
                        UIExtend.setNodeVisible(rewordCellCCB, "mItemHaveNumNode", false)
                        UIExtend.addSpriteToNodeParent(rewordCellCCB, "mIconNode", "Common_u_Quality_04.png",nil, nil, 20000)
                    end

                    --Ìí¼Óicon
                    local icon, _ = RAResManager:getIconByTypeAndId(tonumber(mainType), tonumber(rewardId))
                    UIExtend.addSpriteToNodeParent(rewordCellCCB, "mIconNode", icon)
                    UIExtend.setCCLabelString(rewordCellCCB, "mCellNum", tostring(rewardCount))


                else
                    rewordCellCCB:setVisible(false)
                end 
            end
            -- self.rewardsSV:orderCCBFileCells(self.rewardsSV:getViewSize().width)
            -- UIExtend.setCCControlButtonEnable(self.ccbfile, "mConfirm", true)
        end
    else
        RARootManager.CloseCurrPage()
    end
end


function RALordUpgradePage:onConfirm()
    local flag,nextReward = RALordUpgradeManager:hasUnclaimedReward()
    if flag then
        -- UIExtend.setCCControlButtonEnable(self.ccbfile, "mConfirm", false)
       return RALordUpgradeManager:claimLevelReward()
    else
       return RARootManager.CloseCurrPage()
    end
end

function RALordUpgradePage:Exit()

    self:onConfirm()
    --refresh lordMainPage red point
    MessageManager.sendMessage(MessageDef_RedPoint.MSG_Refresh_Talent_RedPoint)
    --刷新指挥官头像上的红点
    MessageManager.sendMessage(MessageDef_RedPoint.MSG_Refresh_Head_RedPoint)
    
    MessageManager.removeMessageHandler(MessageDef_Packet.MSG_Operation_OK, OnReceiveMessage)
    -- if self.rewardsSV then
    --     self.rewardsSV:removeAllCell()
    --     self.rewardsSV = nil
    -- end
	UIExtend.unLoadCCBFile(self)
end



return RALordUpgradePage