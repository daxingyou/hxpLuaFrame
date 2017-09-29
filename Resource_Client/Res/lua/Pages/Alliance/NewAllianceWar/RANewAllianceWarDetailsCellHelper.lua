--RANewAllianceWarDetailsCellHelper
--联盟战争页面cell处理
local UIExtend = RARequire("UIExtend")
local RARootManager = RARequire("RARootManager")
local RAAllianceManager = RARequire('RAAllianceManager')
local RAPlayerInfoManager = RARequire('RAPlayerInfoManager')
local RAAllianceProtoManager = RARequire("RAAllianceProtoManager")
local RANewAllianceWarManager = RARequire("RANewAllianceWarManager")
local RABuildManager = RARequire("RABuildManager")
local HP_pb = RARequire("HP_pb")
local Const_pb = RARequire("Const_pb")
local World_pb=RARequire("World_pb")
local GuildWar_pb = RARequire("GuildWar_pb")
local common = RARequire("common")

local RANewAllianceWarDetailsCellHelper = {}


-- 已经加入的cell
local RANewAllianceWarDetailsJoinedCell = 
{
    New = function(self, o)
        local o = o or {}
        setmetatable(o,self)
        self.__index = self                
        o.mLastUpdateTime = 0
        return o
    end,

    GetCCBName = function(self)
        return 'RAAllianceWarGatherCell1.ccbi'
    end,

    SetData = function(self, index, cellMarchId, itemShowData, status)
        self.mIndex = index
        self.mCellMarchId = cellMarchId
        self.mItemShowData = itemShowData
        self.mOpenStatus = status or false
    end,

    onRefreshContent = function(self, ccbRoot)
        if not ccbRoot then return end
        local ccbfile = ccbRoot:getCCBFileNode() 
        UIExtend.handleCCBNode(ccbfile)
        self.mLastUpdateTime = 0
        if self.mItemShowData == nil then return end
        local oneCellData = RANewAllianceWarManager:GetOneCellDataById(self.mCellMarchId)
        if oneCellData ~= nil then
            if oneCellData.showType == GuildWar_pb.GUILD_WAR_MASS then
                self:_handleRefreshForMass(ccbfile)
                self:_updateTimeForMass(ccbfile)
            elseif oneCellData.showType == GuildWar_pb.GUILD_WAR_ATTACK then
                print('errrrrrrrrrrrrrrrrorr--------------------atk can not joined')
            elseif oneCellData.showType == GuildWar_pb.GUILD_WAR_DEFENCE then
                self:_handleRefreshForDefence(ccbfile)
                self:_updateTimeForDefence(ccbfile)
            elseif oneCellData.showType == GuildWar_pb.GUILD_WAR_QUARTERED then
                self:_handleRefreshForQuartered(ccbfile)
                self:_updateTimeForQuartered(ccbfile)
            end                
        end
        self:ChangeArmyInfoStatus(ccbfile, self.mOpenStatus)
    end,

    -- 集结类型cell刷新
    _handleRefreshForMass = function(self, ccbfile)        
        local iconStr, nameStr = self.mItemShowData:GetShowDatas()
        UIExtend.setStringForLabel(ccbfile, {mPlayerName = nameStr})
        UIExtend.addSpriteToNodeParent(ccbfile, "mCellIconNode",iconStr)

        local armys, armyCount = self.mItemShowData:GetArmyInfo()
        UIExtend.setStringForLabel(ccbfile, {mTroopsNum = tostring(armyCount)})
    end,


    -- 防守类型cell刷新
    _handleRefreshForDefence = function(self, ccbfile)
        --和集结类型显示的一样，刷新time的时候不一样
        self:_handleRefreshForMass(ccbfile)
    end,

    -- 驻守类型cell刷新
    _handleRefreshForQuartered = function(self, ccbfile)
        --和集结类型显示的一样，刷新time的时候不一样
        self:_handleRefreshForMass(ccbfile)
    end,

    -- 集结类型cell刷新时间
    -- 集结类型的行军中，只有队伍内成员可以加速
    -- 其他情况都不可以加速
    _updateTimeForMass = function(self, ccbfile)
        local statusStr, isUpdate = self.mItemShowData:GetMarchShowStatus()
        local isSelfLeader = RANewAllianceWarManager:CheckSelfIsLeader(self.mCellMarchId)
        local isSelfInTeam = RANewAllianceWarManager:CheckSelfIsInMassTeam(self.mCellMarchId)
        local playerId = RAPlayerInfoManager.getPlayerId()
        local isSelf = playerId == self.mItemShowData.playerId
        UIExtend.setStringForLabel(ccbfile, {mGatherStateLabel = statusStr})
        UIExtend.setControlButtonTitle(ccbfile, 'mRepatriateBtn', '@TroopsRepatriate')
        
        local accelerateVisual = false
        local repatriateVisual = false
        if isUpdate then
            if isSelfLeader or isSelfInTeam then
                accelerateVisual = true
            end        
        else
            if isSelfLeader then
                if not isSelf then
                    repatriateVisual = true                            
                end
            else
                if isSelf then
                    repatriateVisual = true
                    UIExtend.setControlButtonTitle(ccbfile, 'mRepatriateBtn', '@Recall')
                end
            end
        end
        local oneCellData = RANewAllianceWarManager:GetOneCellDataById(self.mCellMarchId)
        local marchData = oneCellData.selfInfo.leaderMarch.marchData
        if marchData ~= nil then
            if marchData.marchStatus ~= World_pb.MARCH_STATUS_WAITING then            
                -- leader行军时，所有cell的召回和遣返都不可见
                repatriateVisual = false
                -- leader行军时，只有leader的加速可见
                accelerateVisual = isSelfInTeam and (self.mItemShowData.playerId == oneCellData.selfInfo.leaderMarch.playerId)
            end
        end
        UIExtend.setNodesVisible(ccbfile,{
            mAccelerateNode = accelerateVisual,
            mRepatriateBtnNode = repatriateVisual,
            })
    end,


    -- 防守类型cell刷新时间
    _updateTimeForDefence = function(self, ccbfile)
        self:_updateTimeForMass(ccbfile)
    end,

    -- 驻守类型cell刷新时间
    _updateTimeForQuartered = function(self, ccbfile)
        self:_updateTimeForMass(ccbfile)
    end,

    onExecute = function(self, ccbRoot)
        if not ccbRoot then return end
        local currTime = CCTime:getCurrentTime()
        if currTime - self.mLastUpdateTime < 300 then
            return
        end
        self.mLastUpdateTime = currTime
        local ccbfile = ccbRoot:getCCBFileNode()
        if self.mItemShowData == nil then return end
        local oneCellData = RANewAllianceWarManager:GetOneCellDataById(self.mCellMarchId)
        if oneCellData ~= nil then
            if oneCellData.showType == GuildWar_pb.GUILD_WAR_MASS then
                self:_updateTimeForMass(ccbfile)
            elseif oneCellData.showType == GuildWar_pb.GUILD_WAR_ATTACK then
                -- self:_updateTimeForAttack(ccbfile)
                print('errrrrrrrrrrrrrrrrorr--------------------atk can not joined')
            elseif oneCellData.showType == GuildWar_pb.GUILD_WAR_DEFENCE then
                self:_updateTimeForDefence(ccbfile)
            elseif oneCellData.showType == GuildWar_pb.GUILD_WAR_QUARTERED then
                self:_updateTimeForQuartered(ccbfile)
            end                
        end
    end,

    --点击加速
    onAccelerateBtn = function(self)
        local marchId = self.mItemShowData:GetMarchId()
        local RACommonGainItemData = RARequire('RACommonGainItemData')
        RARootManager.showCommonGainItemPage(
            RACommonGainItemData.GAIN_ITEM_TYPE.marchAccelerate, 
            marchId)
    end,
    --点击遣返或者是召回
    onRepatriateBtn = function(self)
        local statusStr, isUpdate = self.mItemShowData:GetMarchShowStatus()
        local isSelfLeader = RANewAllianceWarManager:CheckSelfIsLeader(self.mCellMarchId)
        local isSelfInTeam = RANewAllianceWarManager:CheckSelfIsInMassTeam(self.mCellMarchId)
        local playerId = RAPlayerInfoManager.getPlayerId()
        local isSelf = playerId == self.mItemShowData.playerId
        local isCallBack = false
        local marchId = self.mItemShowData:GetMarchId()
        if not isUpdate and marchId ~= '' then            
            if not isSelfLeader and isSelf then
                isCallBack = true            
            end
            local confirmData =
            {
                labelText = _RALang('@ConfirmSendbackTroops'),
                yesNoBtn = true,
                resultFun = function (isOK)
                    if isOK then
                        local RAWorldPushHandler = RARequire('RAWorldPushHandler')
                        if isCallBack then
                            --召回
                            RAWorldPushHandler:sendServerCalcCallBackReq(marchId)
                        else
                            --遣返
                            RAWorldPushHandler:sendMassRepatriateReq(marchId)
                        end
                    end
                end
            }
            RARootManager.showConfirmMsg(confirmData)
        end
    end,
    --点击查看部队详情
    onDetailsBtn = function(self)
        local cellMarchId = self.mCellMarchId
        local showData = self.mItemShowData
        MessageManager.sendMessage(MessageDef_AllianceWar.MSG_NewAllianceWar_DetailsPage_CellInfo_Change, 
            {
                cellMarchId = cellMarchId,
                showData = showData
            })
        -- self:ChangeArmyInfoStatus(ccbfile, not self.mOpenStatus)
    end,

    ChangeArmyInfoStatus = function(self, ccbfile, value)
        if ccbfile then
            self.mOpenStatus = value        
            local rotation = 0
            if self.mOpenStatus then rotation = 90 end
            local spr = UIExtend.getCCSpriteFromCCB(ccbfile, 'mArrowPic')
            if spr then
                spr:setRotation(rotation)
            end
        end
    end,
}


--空闲的cell和带花钱开启的cell
local RANewAllianceWarDetailsSpareCell = 
{
    New = function(self, o)
        local o = o or {}
        setmetatable(o,self)
        self.__index = self                
        return o
    end,

    GetCCBName = function(self)
        return 'RAAllianceWarGatherCell3.ccbi'
    end,

    SetData = function(self, index, cellMarchId, isLock)
        self.mIndex = index
        self.mCellMarchId = cellMarchId
        self.mIsLock = isLock or false
    end,

    onRefreshContent = function(self, ccbRoot)
        if not ccbRoot then return end
        local ccbfile = ccbRoot:getCCBFileNode() 
        local oneCellData = RANewAllianceWarManager:GetOneCellDataById(self.mCellMarchId)
        if oneCellData ~= nil then
            if not self.mIsLock then
                if oneCellData.showType == GuildWar_pb.GUILD_WAR_MASS then
                    UIExtend.setStringForLabel(ccbfile, {mCellExplainLabel = _RALang("@ClickJoinAssemblyInTxt")})
                elseif oneCellData.showType == GuildWar_pb.GUILD_WAR_ATTACK then
                    print('errrrrrrrrrrrrrrrrorr--------------------atk can not joined')
                elseif oneCellData.showType == GuildWar_pb.GUILD_WAR_DEFENCE then
                    UIExtend.setStringForLabel(ccbfile, {mCellExplainLabel = _RALang("@ClickAidAlklyTxt")})
                elseif oneCellData.showType == GuildWar_pb.GUILD_WAR_QUARTERED then
                    UIExtend.setStringForLabel(ccbfile, {mCellExplainLabel = _RALang("@ClickJoinAssemblyInTxt")})
                end       
            else         
                local isCanBuy, costValue = RANewAllianceWarManager:GetNextMassItemCost(oneCellData.selfInfo.buyItemTimes)
                UIExtend.setStringForLabel(ccbfile, {mCellExplainLabel = _RALang("@TempQueueCost", costValue)})
            end
            UIExtend.setNodesVisible(ccbfile, {mLockedNode = self.mIsLock})
        end
    end,

    onCellBtn = function(self)
        local oneCellData = RANewAllianceWarManager:GetOneCellDataById(self.mCellMarchId)
        if oneCellData ~= nil then
            if not self.mIsLock then                
                local isSelfLeader = RANewAllianceWarManager:CheckSelfIsLeader(self.mCellMarchId)
                local isSelfInTeam = RANewAllianceWarManager:CheckSelfIsInMassTeam(self.mCellMarchId)
                if isSelfLeader then
                    if oneCellData.showType == GuildWar_pb.GUILD_WAR_MASS or 
                        oneCellData.showType == GuildWar_pb.GUILD_WAR_QUARTERED then
                        RARootManager.ShowMsgBox("@TeamMemberCanJoinTxt")
                    end
                    if oneCellData.showType == GuildWar_pb.GUILD_WAR_DEFENCE then
                        RARootManager.ShowMsgBox("@TeamMemberDefendCanJoinTxt")
                    end
                    return
                end

                if isSelfInTeam then
                    if oneCellData.showType == GuildWar_pb.GUILD_WAR_MASS or 
                        oneCellData.showType == GuildWar_pb.GUILD_WAR_QUARTERED then
                        RARootManager.ShowMsgBox("@AlreadyJoinedTxt")
                    end
                    if oneCellData.showType == GuildWar_pb.GUILD_WAR_DEFENCE then
                        RARootManager.ShowMsgBox("@AlreadyJoinedDefendTxt")
                    end
                    return
                end

                -- 集结和驻扎，需要判断当前行军状态
                if oneCellData.showType == GuildWar_pb.GUILD_WAR_MASS or 
                    oneCellData.showType == GuildWar_pb.GUILD_WAR_QUARTERED then
                    --只有队长的行军在集结状态中的时候，才可以去加入集结
                    local leaderMarch = oneCellData.selfInfo.leaderMarch
                    local marchData = leaderMarch.marchData
                    if marchData.marchStatus == World_pb.MARCH_STATUS_WAITING then
                        local confirmFunc = function()
                            local mPosXorY = {}
                            mPosXorY.x = marchData.origionX
                            mPosXorY.y = marchData.origionY
                            local marchId = marchData.marchId
                            local marchType = World_pb.MASS_JOIN
                            if marchData.marchType == World_pb.MANOR_MASS then
                                marchType = World_pb.MANOR_MASS_JOIN
                            end

                            if marchData.marchType == World_pb.MANOR_ASSISTANCE_MASS then
                                marchType = World_pb.MANOR_ASSISTANCE_MASS_JOIN
                            end

                            if marchData.marchType == World_pb.PRESIDENT_MASS then
                                marchType = World_pb.PRESIDENT_MASS_JOIN
                            end

                            if marchData.marchType == World_pb.PRESIDENT_ASSISTANCE_MASS then
                                marchType = World_pb.PRESIDENT_ASSISTANCE_MASS_JOIN
                            end
                            
                            if marchData.marchType == World_pb.MONSTER_MASS then
                                marchType = World_pb.MONSTER_MASS_JOIN
                            end

                            local playerName = leaderMarch.playerName
                            local headIconPic = RAPlayerInfoManager.getHeadIcon(leaderMarch.iconId)
                            RARootManager.OpenPage('RATroopChargePage',  {
                                coord = mPosXorY, 
                                massTargetMarchId = marchId,
                                name = playerName,
                                icon = headIconPic,      
                                marchType = marchType,
                            })
                        end
                        local RAWorldUtil = RARequire('RAWorldUtil')
                        RAWorldUtil:ActAfterConfirm(confirmFunc)
                    else
                        RARootManager.ShowMsgBox(_RALang("@IsMarching"))
                    end
                end
                -- 援助
                if oneCellData.showType == GuildWar_pb.GUILD_WAR_DEFENCE then
                    -- 根据点类型来判断发起什么援助                    
                    local selfInfo = oneCellData.selfInfo                    
                    local leaderMarch = oneCellData.selfInfo.leaderMarch
                    local iconStr, nameStr = selfInfo:GetShowDatas()
                    local targetInfo = oneCellData.targetInfo
                    if self.pointType == World_pb.GUILD_GUARD or self.pointType == World_pb.GUILD_TERRITORY then
                        -- 堡垒和据点直接跳转
                        local RAWorldManager = RARequire("RAWorldManager")
                        RARootManager.CloseAllPages()
                        RAWorldManager:LocateAt(selfInfo.x, selfInfo.y)

                    elseif self.pointType == World_pb.KING_PALACE then
                        --王座
                        local RAWorldManager = RARequire("RAWorldManager")
                        RARootManager.CloseAllPages()
                        RAWorldManager:LocateAt(selfInfo.x, selfInfo.y)
                    else
                        --玩家
                        local pageData = {
                            posX = selfInfo.x,
                            posY = selfInfo.y,
                            name = nameStr,
                            icon = iconStr,
                            playerId = leaderMarch.playerId
                        }
                        RARootManager.OpenPage('RAAllianceSoldierAidPage', pageData, false, true, true)
                    end                    
                end
            else
                --点击去解锁
                local cellMarchId = self.mCellMarchId
                local oneCellData = RANewAllianceWarManager:GetOneCellDataById(self.mCellMarchId)
                local isSelfLeader = RANewAllianceWarManager:CheckSelfIsLeader(self.mCellMarchId)
                if oneCellData ~= nil and isSelfLeader then                    
                    local isCanBuy, costValue = RANewAllianceWarManager:GetNextMassItemCost(oneCellData.selfInfo.buyItemTimes)
                    local confirmData =
                    {
                        labelText = _RALang('@TempQueueHint', costValue),
                        yesNoBtn = true,
                        resultFun = function (isOK)
                            if isOK then
                                --点击发送解锁的协议
                                local msg = GuildWar_pb.WorldMassMarchBuyExtraItemsReq()
                                msg.cellMarchId = cellMarchId
                                local RANetUtil = RARequire('RANetUtil')
                                RANetUtil:sendPacket(HP_pb.WORLD_MASS_MARCH_BUY_ITEMS_C, msg)
                            end
                        end
                    }
                    RARootManager.showConfirmMsg(confirmData)
                else
                    RARootManager.ShowMsgBox(_RALang('@PermissionDeniedForExtraMarch'))
                end
            end
        end
    end,
}


--部队详情的cell
local RANewAllianceWarDetailsArmyCell = 
{
    New = function(self, o)
        local o = o or {}
        setmetatable(o,self)
        self.__index = self                
        return o
    end,

    GetCCBName = function(self)
        return 'RAAllianceWarGatherCell2.ccbi'
    end,

    SetData = function(self, index, cellMarchId, showData)
        self.mIndex = index
        self.mCellMarchId = cellMarchId
        self.mShowData = showData
    end,

    onRefreshContent = function(self, ccbRoot)
        if not ccbRoot then return end
        local ccbfile = ccbRoot:getCCBFileNode() 
        local scrollView = UIExtend.getCCScrollViewFromCCB(ccbfile, "mTroopsListSV")
        if self.mShowData ~= nil and scrollView ~= nil then
            scrollView:removeAllCell()
            local armys = self.mShowData.armys
            local cellIndex = 0 
            for i=1, #armys do                
                local amryInfo = armys[i]
                cellIndex = cellIndex + 1
                local itemCellHandler = RANewAllianceWarDetailsCellHelper:CreateArmyInfoNode(cellIndex, amryInfo.armyId, amryInfo.count)
                local itemCell = CCBFileCell:create()            
                itemCell:registerFunctionHandler(itemCellHandler)
                itemCell:setCCBFile(itemCellHandler:GetCCBName())
                scrollView:addCellBack(itemCell)
            end
            scrollView:orderCCBFileCells()
        end
    end,

    onUnLoad = function(self, ccbRoot)
        if not ccbRoot then return end
        local ccbfile = ccbRoot:getCCBFileNode() 
        local scrollView = UIExtend.getCCScrollViewFromCCB(ccbfile, "mTroopsListSV")
        if scrollView ~= nil then
            scrollView:removeAllCell()
        end
    end
}

--部队详情的cell node
local RANewAllianceWarDetailsArmyNode= 
{
    New = function(self, o)
        local o = o or {}
        setmetatable(o,self)
        self.__index = self                
        return o
    end,

    GetCCBName = function(self)
        return 'RAAllianceWarGatherCell2Node.ccbi'
    end,

    SetData = function(self, index, soldierId, count)
        self.mIndex = index
        self.mSoldierId = tonumber(soldierId)
        self.mCount = count
    end,

    onRefreshContent = function(self, ccbRoot)
        if not ccbRoot then return end
        local ccbfile = ccbRoot:getCCBFileNode() 
        local battle_soldier_conf = RARequire("battle_soldier_conf")
        UIExtend.removeSpriteFromNodeParent(ccbfile, "mIconNode")
        local armyConf = battle_soldier_conf[self.mSoldierId]
        if armyConf ~= nil then
            UIExtend.addSpriteToNodeParent(ccbfile, "mIconNode",armyConf.icon)
        end
        local count = self.mCount or 0
        UIExtend.setStringForLabel(ccbfile, {mTroopsNum = count})
    end,
}

function RANewAllianceWarDetailsCellHelper:CreateArmyInfoCell(index, cellMarchId, showData)
    local cell = RANewAllianceWarDetailsArmyCell:New()
    cell:SetData(index, cellMarchId, showData)
    return cell
end

function RANewAllianceWarDetailsCellHelper:CreateArmyInfoNode(index, soldierId, count)
    local cell = RANewAllianceWarDetailsArmyNode:New()
    cell:SetData(index, soldierId, count)
    return cell
end


function RANewAllianceWarDetailsCellHelper:CreateJoinedCell(index, cellMarchId, itemShowData, openStatus)
    local cell = RANewAllianceWarDetailsJoinedCell:New()
    cell:SetData(index, cellMarchId, itemShowData, openStatus)
    return cell
end

function RANewAllianceWarDetailsCellHelper:CreateSpareCell(index, cellMarchId, isLock)
    local cell = RANewAllianceWarDetailsSpareCell:New()
    cell:SetData(index, cellMarchId, isLock)
    return cell
end

return RANewAllianceWarDetailsCellHelper