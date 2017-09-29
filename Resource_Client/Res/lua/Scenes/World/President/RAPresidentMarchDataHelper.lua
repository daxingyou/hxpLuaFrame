-- RAPresidentMarchDataHelper.lua
--首都战军队信息管理
local RANewAllianceWarDataHelper = RARequire('RANewAllianceWarDataHelper')
local Const_pb = RARequire("Const_pb")
local GuildWar_pb = RARequire("GuildWar_pb")
local Utilitys = RARequire('Utilitys')
local RAPlayerInfoManager = RARequire('RAPlayerInfoManager')
local RAAllianceManager = RARequire('RAAllianceManager')


local RAPresidentMarchDataHelper = {
    -- 当前的联盟id
    mCurrGuildId = '',
    -- 当前的驻军数据
    mCurrTeamData = nil,
}

-- msg = PushAllQuarteredMarch
-- 登陆的时候、切换队长的时候都会推送，
-- 需要注意，在切换王座临时国王的时候要删除这边的数据
function RAPresidentMarchDataHelper:InitTeamData(msg)
    if msg == nil then return end
    if msg.pushType ~= GuildWar_pb.PUSH_QUARTERED_PRESIDENT then return end
    self.mCurrGuildId = msg.guildId
    self.mCurrTeamData = RANewAllianceWarDataHelper:CreateTeamData(msg.team)
    MessageManager.sendMessage(MessageDef_World.MSG_PresidentQuarterPage_Refresh, {})
end

-- msg = PushQuarteredMarchUpdateItem
function RAPresidentMarchDataHelper:UpdateTeamItemData(msg)
    if msg == nil then return end
    if msg.pushType ~= GuildWar_pb.PUSH_QUARTERED_PRESIDENT then return end
    if self.mCurrGuildId == '' or self.mCurrTeamData == nil then return end
    if self.mCurrGuildId == msg.guildId then
        RANewAllianceWarDataHelper:UpdateTeamItemData(self.mCurrTeamData, msg.showPB)
        MessageManager.sendMessage(MessageDef_World.MSG_PresidentQuarterPage_Refresh, {})
    end
end

-- msg = PushQuarteredMarchDelItem
function RAPresidentMarchDataHelper:DeleteTeamItemData(msg)
    if msg == nil then return end
    if msg.pushType ~= GuildWar_pb.PUSH_QUARTERED_PRESIDENT then return end
    if self.mCurrGuildId == '' or self.mCurrTeamData == nil then return end
    if self.mCurrGuildId == msg.guildId then
        RANewAllianceWarDataHelper:DeleteTeamItemData(self.mCurrTeamData, msg.marchId, msg.playerId)
        MessageManager.sendMessage(MessageDef_World.MSG_PresidentQuarterPage_Refresh, {})
    end 
end


-- msg = PushQuarteredMarchBuyItems
-- 购买了集结队列
function RAPresidentMarchDataHelper:UpdateBuyTimes(msg)
    if msg == nil then return end
    if msg.pushType ~= GuildWar_pb.PUSH_QUARTERED_PRESIDENT then return end
    if self.mCurrGuildId == '' or self.mCurrTeamData == nil then return end    
    if self.mCurrGuildId == msg.guildId then
        self.mCurrTeamData.buyItemTimes = msg.buyItemTimes
        -- 刷新驻军信息页面
        MessageManager.sendMessage(MessageDef_World.MSG_PresidentQuarterPage_Refresh, {})
    end 
end


function RAPresidentMarchDataHelper:GetCurrTeamData()
    return self.mCurrTeamData
end

function RAPresidentMarchDataHelper:GetCurrGuildId()
    return self.mCurrGuildId
end

function RAPresidentMarchDataHelper:CheckIsSelfGuild()
    local RAAllianceManager = RARequire('RAAllianceManager')
    local isSameGuild = RAAllianceManager:IsGuildFriend(self.mCurrGuildId)
    return isSameGuild
end

-- 检查自己是不是队长：驻守的队长
function RAPresidentMarchDataHelper:CheckSelfIsLeader()    
    if self.mCurrTeamData ~= nil then
        local playerId = RAPlayerInfoManager.getPlayerId()
        if playerId == self.mCurrTeamData.leaderMarch.playerId then
            return true, self.mCurrTeamData.leaderMarch:GetMarchId()
        end
    end
    return false, ''
end

-- 检查自己是不是队员：驻守的队员
function RAPresidentMarchDataHelper:CheckSelfIsQuartering()
    if self.mCurrTeamData ~= nil then
        local playerId = RAPlayerInfoManager.getPlayerId()
        local marchesShowData = self.mCurrTeamData.joinMarchs
        for k,v in pairs(marchesShowData) do
            if v.playerId == playerId then
                return true, v:GetMarchId()
            end
        end
    end
    return false, ''
end


-- 向首都发起行军，附带参数行军类型
function RAPresidentMarchDataHelper:MarchToPresident(marchType)
    local RAWorldVar = RARequire('RAWorldVar')
    local RAWorldUtil = RARequire('RAWorldUtil')
    local RAWorldBuildingManager = RARequire('RAWorldBuildingManager')
    local pos = Utilitys.ccpCopy(RAWorldVar.MapPos.Core)
    local buildingId, buildingNode = RAWorldBuildingManager:GetBuildingAt(pos)
    if buildingNode ~= nil then
        if RAWorldUtil:IsMassingMarch(marchType) then
            local info = buildingNode.mBuildingInfo
            local confirmFunc = function ()
                local pageData = 
                {
                    posX = info.coord.x,
                    posY = info.coord.y,
                    name = info.name,
                    icon = info.icon,
                    marchType = marchType
                }
                local RARootManager = RARequire('RARootManager')
                RARootManager.OpenPage('RAAllianceGatherPage', pageData, false, true, true)
            end
            RAWorldUtil:ActAfterConfirm(confirmFunc)
        else
            local targetInfo = buildingNode.mBuildingInfo
            local confirmFunc = function ()        
                RAWorldUtil:ChargeTroops(targetInfo, marchType)
            end
            RAWorldUtil:ActAfterConfirm(confirmFunc)
        end
    end
    return 
end



function RAPresidentMarchDataHelper:reset()
    self.mCurrGuildId = ''
    self.mCurrTeamData = nil
end

return RAPresidentMarchDataHelper