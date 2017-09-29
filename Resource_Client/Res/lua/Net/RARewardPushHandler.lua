--region *.lua
--Date
--此文件由[BabeLua]插件自动生成

local RARewardPushHandler = 
{
    mInstantShow = true,

    mRewardList = {}
}

function RARewardPushHandler:onReceivePacket(handler)
    local HP_pb = RARequire("HP_pb")
    local Reward_pb = RARequire("Reward_pb")
    local Const_pb = RARequire("Const_pb")
    local RAResManager = RARequire("RAResManager")
    local RAStringUtil = RARequire("RAStringUtil")
    local RARootManager = RARequire("RARootManager")
    local RAPlayerInfoManager = RARequire("RAPlayerInfoManager")
    
    local pbCode = handler:getOpcode()
    local buffer = handler:getBuffer()
    if pbCode == HP_pb.PLAYER_AWARD_S then  --资源收集推送
		local msg = Reward_pb.HPPlayerReward()
		msg:ParseFromString(buffer)
        
        if  msg.rewards then
            local rewards = msg.rewards
            RAPlayerInfoManager.SyncAttrInfoFromReward(rewards)

            if (not msg:HasField("flag")) or (msg.flag == 0) or RARootManager.CheckIsPageOpening('RATaskMainPage') then
                return
            end

            if rewards.showItems then
--                local data = {}
--                data.text = ""
--                local item_conf = RARequire("item_conf")
--                for i=1, #rewards.showItems do
--                    local rewardItem = rewards.showItems[i]
--                    local mainType = rewardItem.itemType
--                    local rewardId = rewardItem.itemId
--                    local rewardCount = rewardItem.itemCount
--                    local _, name = RAResManager:getIconByTypeAndId(mainType, rewardId)

--                    --获得品质
--                    local colorIndex = COLOR_TYPE.PURPLE
--                    if (tonumber(mainType)*0.0001) == Const_pb.TOOL then
--                        local constItemInfo = item_conf[tonumber(rewardId)]
--                        if constItemInfo then
--                            colorIndex = constItemInfo.item_color
--                        end
--                    end

--                    local desStr = RAStringUtil:getHTMLString("RewardDes"..colorIndex)
--                    if desStr then
--                        local countStr = RAStringUtil:getLanguageString("@GetResNum", rewardCount)
--                        local nameStr = _RALang(name)
--                        nameStr = string.gsub(nameStr,"%%","%%%%")
--                        desStr = RAStringUtil:fill(desStr, nameStr, countStr)
--                        data.text = data.text .. desStr
--                    end
--                end

--                if data.text ~= "" then
--                    data.title = "@Reward"
--                    if self.mInstantShow then
--                        RARootManager.ShowCommonReward(data)
--                    else
--                        table.insert(self.mRewardList, data)
--                    end
--                end

                if self.mInstantShow then

                    --[[
                        这段代码先屏蔽，需求策划未来要改成领主升级界面领取奖励后就不弹通用弹框 by xinping
                    ]]
                    -- local RALordUpgradeManager=RARequire("RALordUpgradeManager")
                    -- local nextAvailableReward=RALordUpgradeManager.playerRewardLevel
                    -- if nextAvailableReward~=nil then
                        
                    --     --只在领主升级的时候判断发送
                    --     RARequire("MessageDefine")
                    --     RARequire("MessageManager")
                    --     local RAPlayerInfoManager = RARequire("RAPlayerInfoManager")
                    --     local playLevel =  RAPlayerInfoManager.getPlayerLevel()
                    --     -- --judge if player is level up, send msg
                    --     if playLevel>nextAvailableReward then
                    --         MessageManager.sendMessage(MessageDef_Lord.MSG_LevelUpgrade)
                    --     end 
                    --     RALordUpgradeManager.playerRewardLevel=nil 
                    -- else
                    --     RARootManager.ShowCommonReward(rewards.showItems, true)
                    -- end 

                     RARootManager.ShowCommonReward(rewards.showItems, true)
                   
                else
                    table.insert(self.mRewardList, rewards.showItems) 
                end
            end
        end 
    end
end

function RARewardPushHandler:delayShowReward()
    self.mInstantShow = false
end

function RARewardPushHandler:showAllReward()
    self.mInstantShow = true
    local RARootManager = RARequire("RARootManager")
    table.foreach(self.mRewardList, function (_, data)
        RARootManager.ShowCommonReward(data, true)
    end)
    self.mRewardList = {}
end

return RARewardPushHandler

--endregion
