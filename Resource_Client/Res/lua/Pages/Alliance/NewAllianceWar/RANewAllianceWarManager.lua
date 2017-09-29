--联盟战争管理

local Const_pb = RARequire("Const_pb")
local GuildWar_pb = RARequire("GuildWar_pb")
local Utilitys = RARequire('Utilitys')
local RAPlayerInfoManager = RARequire('RAPlayerInfoManager')
local RAAllianceManager = RARequire('RAAllianceManager')

local RANewAllianceWarManager = {
    mMassDatas = {},
    mAtkDatas = {},
    mDefDatas = {},
    mQuarteredDatas = {},

    mMassRedIdList = {},
    mAtkRedIdList = {},
    mDefRedIdList = {},
    mQuarteredRedIdList = {},
}

-- msg = GuildWarOneCellPB
-- 添加一个或者更新cell data
function RANewAllianceWarManager:AddOneCellData(msg, isAdd)
    if msg == nil then return end
    local targetDatas, redDatas = self:GetCellDataByType(msg.showType)

    if targetDatas ~= nil then
        local cellData = targetDatas[msg.cellMarchId]
        if cellData == nil then
            local RANewAllianceWarDataHelper = RARequire('RANewAllianceWarDataHelper')
            cellData = RANewAllianceWarDataHelper:CreateOneCellData(msg)
        else
            cellData:InitByPb(msg)
        end
        targetDatas[cellData.cellMarchId] = cellData
        --刷新war page
        if isAdd then
            MessageManager.sendMessage(MessageDef_AllianceWar.MSG_NewAllianceWar_WarPage_Refresh, {showType = cellData.showType})  
            if redDatas ~= nil then                
                redDatas[cellData.cellMarchId] = true
            end

            --发送红点消息
            MessageManager.sendMessage(MessageDef_AllianceWar.MSG_WAR_REDPOINT)
            RAAllianceManager:refreshAllianceNoticeNum()
        end
    end
end

-- msg = PushGuildWarUpdate
-- 更新一个cell中的某个单元数据
function RANewAllianceWarManager:UpdateCellItemData(msg)
    local oneCellData = self:GetOneCellDataById(msg.cellMarchId)
    if oneCellData ~= nil then
        --页面刷新消息放在里方法里
        local RANewAllianceWarDataHelper = RARequire('RANewAllianceWarDataHelper')
        RANewAllianceWarDataHelper:UpdateSelfTeamItemData(oneCellData, msg)
    end
end


-- msg = PushGuildWarDelCell
-- 删除整个cell
function RANewAllianceWarManager:DeleteCellData(msg)
    local oneCellData = self:GetOneCellDataById(msg.cellMarchId)
    if oneCellData ~= nil then
        --刷新war page
        local showType = oneCellData.showType
        local cellMarchId = oneCellData.cellMarchId
        self.mMassDatas[msg.cellMarchId] = nil
        self.mAtkDatas[msg.cellMarchId] = nil
        self.mDefDatas[msg.cellMarchId] = nil
        self.mQuarteredDatas[msg.cellMarchId] = nil

        self.mMassRedIdList[msg.cellMarchId] = nil
        self.mAtkRedIdList[msg.cellMarchId] = nil
        self.mDefRedIdList[msg.cellMarchId] = nil
        self.mQuarteredRedIdList[msg.cellMarchId] = nil
        MessageManager.sendMessage(MessageDef_AllianceWar.MSG_NewAllianceWar_WarPage_Refresh, {showType = showType})
        --发送红点消息
        MessageManager.sendMessage(MessageDef_AllianceWar.MSG_WAR_REDPOINT)
        RAAllianceManager:refreshAllianceNoticeNum()

        --刷新detail page，不过是关闭页面
        MessageManager.sendMessage(MessageDef_AllianceWar.MSG_NewAllianceWar_DetailsPage_Close, {cellMarchId = cellMarchId, isClose = true})
    end
end


-- msg = PushGuildWarDelCellItem
-- 删除一个cell中的某个单元数据
function RANewAllianceWarManager:DeleteCellItemData(msg)
    local oneCellData = self:GetOneCellDataById(msg.cellMarchId)
    if oneCellData ~= nil then
        local cellMarchId = oneCellData.cellMarchId
        local RANewAllianceWarDataHelper = RARequire('RANewAllianceWarDataHelper')
        RANewAllianceWarDataHelper:DeleteSelfTeamItemData(oneCellData, msg)
        --刷新detail page
        MessageManager.sendMessage(MessageDef_AllianceWar.MSG_NewAllianceWar_DetailsPage_Refresh, {cellMarchId = cellMarchId})
    end
end



-- msg = PushGuildWarBuyItems
-- 更新 一个cell的购买次数
function RANewAllianceWarManager:UpdateCellBuyTimes(msg)
    local oneCellData = self:GetOneCellDataById(msg.cellMarchId)
    if oneCellData ~= nil then
        oneCellData.selfInfo.buyItemTimes = msg.buyItemTimes
        --刷新detail page
        MessageManager.sendMessage(MessageDef_AllianceWar.MSG_NewAllianceWar_DetailsPage_Refresh, {cellMarchId = msg.cellMarchId})
    end
end

-- 更新一个cell的目标信息
function RANewAllianceWarManager:UpdateTargetData(msg)
    local oneCellData = self:GetOneCellDataById(msg.cellMarchId)
    if oneCellData ~= nil then
        oneCellData.targetInfo:InitByPb(msg.targetInfo)
        -- 刷新war page
        local showType = oneCellData.showType
        MessageManager.sendMessage(MessageDef_AllianceWar.MSG_NewAllianceWar_WarPage_Refresh, {showType = showType})
        --刷新detail page
        MessageManager.sendMessage(MessageDef_AllianceWar.MSG_NewAllianceWar_DetailsPage_Refresh, {cellMarchId = msg.cellMarchId})
    end
end



function RANewAllianceWarManager:GetOneCellDataById(cellMarchId)
    if self.mMassDatas[cellMarchId] ~= nil then
        return self.mMassDatas[cellMarchId]
    end
    if self.mAtkDatas[cellMarchId] ~= nil then
        return self.mAtkDatas[cellMarchId]
    end
    if self.mDefDatas[cellMarchId] ~= nil then
        return self.mDefDatas[cellMarchId]
    end
    if self.mQuarteredDatas[cellMarchId] ~= nil then
        return self.mQuarteredDatas[cellMarchId]
    end
    return nil
end

function RANewAllianceWarManager:ClearRedListByType(showType)
    -- if showType == GuildWar_pb.GUILD_WAR_MASS then
    --     self.mMassRedIdList = {}
    -- elseif showType == GuildWar_pb.GUILD_WAR_ATTACK then
    --     self.mAtkRedIdList = {}
    -- elseif showType == GuildWar_pb.GUILD_WAR_DEFENCE then
    --     self.mDefRedIdList = {}
    -- elseif showType == GuildWar_pb.GUILD_WAR_QUARTERED then
    --     self.mQuarteredRedIdList = {}
    -- end  
    -- --发送红点消息
    -- MessageManager.sendMessage(MessageDef_AllianceWar.MSG_WAR_REDPOINT)
    -- RAAllianceManager:refreshAllianceNoticeNum()

    -- 红点改成持久性的了
end

function RANewAllianceWarManager:GetCellDataByType(showType)
    local targetDatas = {}
    local redDatas = {}
    if showType == GuildWar_pb.GUILD_WAR_MASS then
        targetDatas = self.mMassDatas
        redDatas = self.mMassRedIdList
    elseif showType == GuildWar_pb.GUILD_WAR_ATTACK then
        targetDatas = self.mAtkDatas
        redDatas = self.mAtkRedIdList
    elseif showType == GuildWar_pb.GUILD_WAR_DEFENCE then
        targetDatas = self.mDefDatas
        redDatas = self.mDefRedIdList
    elseif showType == GuildWar_pb.GUILD_WAR_QUARTERED then
        targetDatas = self.mQuarteredDatas
        redDatas = self.mQuarteredRedIdList
    end    
    return targetDatas, redDatas, Utilitys.table_count(redDatas)
end

-- 检查自己是不是队长：集结的队长、防守的自己
function RANewAllianceWarManager:CheckSelfIsLeader(cellMarchId)
    local oneCellData = self:GetOneCellDataById(cellMarchId)
    if oneCellData ~= nil then
        local playerId = RAPlayerInfoManager.getPlayerId()
        if playerId == oneCellData.selfInfo.leaderMarch.playerId then
            return true
        end
    end
    return false
end

-- 检查自己是不是队员：集结的队员
function RANewAllianceWarManager:CheckSelfIsInMassTeam(cellMarchId)
    local oneCellData = self:GetOneCellDataById(cellMarchId)
    if oneCellData ~= nil then
        if oneCellData.showType == GuildWar_pb.GUILD_WAR_MASS or
            oneCellData.showType == GuildWar_pb.GUILD_WAR_QUARTERED then 
            local marchesShowData = oneCellData.selfInfo.joinMarchs
            local playerId = RAPlayerInfoManager.getPlayerId()
            for k,v in pairs(marchesShowData) do
                if v.playerId == playerId then
                    return true
                end
            end
        end
    end
    return false
end

--获取一个人当前基础的集结队列数目（自己队长也算一个的）
function RANewAllianceWarManager:GetPlayerBaseMassItemCount()
    local baseCount = RARequire('world_march_const_conf').assemblyQueueNum.value
    --TODO:作用号

    return baseCount
end

--获取一个的集结队列数目上限（自己队长也算一个的）
--基础值+购买次数
function RANewAllianceWarManager:GetPlayerMassItemMax(cellMarchId)
    local oneCellData = self:GetOneCellDataById(cellMarchId)
    local baseCount = self:GetPlayerBaseMassItemCount()
    local totalCount = baseCount
    if oneCellData ~= nil then
        local buyTimes = oneCellData.selfInfo.buyItemTimes
        totalCount = totalCount + buyTimes
    end
    return baseCount
end

-- 获取是否可以购买队列，和需要花多少钱
function RANewAllianceWarManager:GetNextMassItemCost(buyItemTimes)
    local world_march_const_conf = RARequire('world_march_const_conf')
    local costStr = world_march_const_conf.tempAssemblyQueueCost.value
    local buyMaxTimes = world_march_const_conf.tempAssemblyQueueUpper.value
    local isCanBuy = false
    local costValue = 0
    if buyItemTimes < buyMaxTimes then
        isCanBuy = true
        local costStrTable = Utilitys.Split(costStr, "_")
        costValue = tonumber(costStrTable[buyItemTimes + 1])
    end
    return isCanBuy, costValue
end


-- 获取红点的显示个数
-- 参数showType为空的时候获取所有类型
function RANewAllianceWarManager:GetRedPointNum(showType)
    local totalCount = 0
    if showType ~= nil then
        local targetDatas, redDatas, count = self:GetCellDataByType(showType)
        totalCount = Utilitys.table_count(targetDatas)
    else
        -- local massCount = Utilitys.table_count(self.mMassRedIdList)
        -- local atkCount = Utilitys.table_count(self.mAtkRedIdList)
        -- local defCount = Utilitys.table_count(self.mDefRedIdList)
        -- local quarteredCount = Utilitys.table_count(self.mQuarteredRedIdList)
        local massCount = Utilitys.table_count(self.mMassDatas)
        local atkCount = Utilitys.table_count(self.mAtkDatas)
        local defCount = Utilitys.table_count(self.mDefDatas)
        local quarteredCount = Utilitys.table_count(self.mQuarteredDatas)
        totalCount = massCount + atkCount + defCount + quarteredCount
    end
    return totalCount
end

function RANewAllianceWarManager:reset(isClose)
    self.mMassDatas = {}
    self.mAtkDatas = {}
    self.mDefDatas = {}
    self.mQuarteredDatas = {}

    self.mMassRedIdList = {}
    self.mAtkRedIdList = {}
    self.mDefRedIdList = {}
    self.mQuarteredRedIdList = {}

    --关闭detail和war page
    if isClose then
       local RARootManager = RARequire("RARootManager")
       RARootManager.ClosePage('RANewAllianceWarPage')
       RARootManager.ClosePage('RANewAllianceWarDetailsPage')
   end
end

return RANewAllianceWarManager