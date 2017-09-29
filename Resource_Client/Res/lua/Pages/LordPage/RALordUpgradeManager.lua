--region *.lua
--Date
--此文件由[BabeLua]插件自动生成
local Player_pb = RARequire("Player_pb")
local HP_pb = RARequire("HP_pb")
local Const_pb = RARequire("Const_pb")
local RAPlayerInfoManager = RARequire("RAPlayerInfoManager")
local RACoreDataManager = RARequire("RACoreDataManager")
local RALordUpgradeManager = {
    hasUnclaimedReward = function (self)
        local level = RAPlayerInfoManager.getPlayerLevel()
        local stateInfo = RACoreDataManager:getStateInfoByKey(Const_pb.REWARD_LEVEL)
        assert(stateInfo ~= nil,"stateInfo ~= nil")
        local rewardLevel = stateInfo.value
        if rewardLevel < level then
            local nextAvailableReward = rewardLevel + 1
            return true,nextAvailableReward
        else
            return false,-1
        end
    end,

    claimLevelReward= function (self)
        local flag, rewardLevel = self:hasUnclaimedReward()
        if flag then
            local msg = Player_pb.HPGetPlayerLevelUpReward()
            rewardLevel = rewardLevel
            msg.rewardLevel = rewardLevel
            local RANetUtil = RARequire("RANetUtil")
            RANetUtil:sendPacket(HP_pb.LEVEL_UP_REWARD_C, msg, { retOpcode = - 1 }) 
        else
            return
        end
        
    end,

    maxRewordNum=6,             --等级提升 奖励cell的最大数目
    playerRewardLevel=nil       --玩家等级提升领取的奖励等级（用于当玩家同时升多级时记录玩家领奖的等级）

}

function RALordUpgradeManager:reset()
    self.playerRewardLevel=nil
end

return RALordUpgradeManager
--endregion
