--RAAllianceBaseWarInfoCellHelper   qinho
--TO:联盟堡垒部队详情页面的cell
local UIExtend = RARequire("UIExtend")
local RARootManager = RARequire("RARootManager")
local RAAllianceManager = RARequire('RAAllianceManager')
local RAPlayerInfoManager = RARequire('RAPlayerInfoManager')
local RAAllianceProtoManager = RARequire("RAAllianceProtoManager")
local RABuildManager = RARequire("RABuildManager")
local HP_pb = RARequire("HP_pb")
local Const_pb = RARequire("Const_pb")
local World_pb=RARequire("World_pb")
local GuildWar_pb = RARequire("GuildWar_pb")
local common = RARequire("common")

local RAAllianceBaseWarInfoCellHelper = {}


-- 已经加入的cell
local RAAllianceBaseWarJoinedCell = 
{
    New = function(self, o)
        local o = o or {}
        setmetatable(o,self)
        self.__index = self                
        o.mLastUpdateTime = 0
        return o
    end,

    GetCCBName = function(self)
        return 'RAAllianceBaseWarInfoCell1.ccbi'
    end,

    SetData = function(self, index, itemShowData, status, mannorId)
        self.mIndex = index
        self.mItemShowData = itemShowData
        self.mOpenStatus = status or false
        self.mMannorId = mannorId
    end,

    onRefreshContent = function(self, ccbRoot)
        if not ccbRoot then return end
        local ccbfile = ccbRoot:getCCBFileNode() 
        self.mCellRoot = ccbRoot
        UIExtend.handleCCBNode(ccbfile)
        if self.mItemShowData == nil then return end
        self:_handleRefreshCell(ccbfile)
    end,

    -- 集结类型cell刷新
    _handleRefreshCell = function(self, ccbfile)        
        local iconStr, nameStr = self.mItemShowData:GetShowDatas()
        UIExtend.setStringForLabel(ccbfile, {mPlayerName = nameStr})
        UIExtend.addSpriteToNodeParent(ccbfile, "mCellIconNode",iconStr)

        local armys, armyCount = self.mItemShowData:GetArmyInfo()
        UIExtend.setStringForLabel(ccbfile, {mTroopsNum = tostring(armyCount)})

        -- 刷新按钮的显示        
        local playerId = RAPlayerInfoManager.getPlayerId()
        local isSelf = playerId == self.mItemShowData.playerId        
        UIExtend.setNodesVisible(ccbfile,
        {
            mBackBtnNode = isSelf,
            mIncreaseTroopsBtnNode = isSelf
        })        

        self:ChangeArmyInfoStatus(ccbfile, self.mOpenStatus)
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


    --点击添加队伍
    onIncreaseTroopsBtn = function(self)
        --直接打开出征页面，发起驻扎类型的行军        
        local playerId = RAPlayerInfoManager.getPlayerId()
        local isSelf = playerId == self.mItemShowData.playerId
        if isSelf then
            RAAllianceBaseWarInfoCellHelper:MacrhToMannor(World_pb.MANOR_ASSISTANCE, self.mMannorId, self.mAddParams)
        end
    end,
    --点击召回
    onBackBtn = function(self)
        local statusStr, isUpdate = self.mItemShowData:GetMarchShowStatus()
        local playerId = RAPlayerInfoManager.getPlayerId()
        local isSelf = playerId == self.mItemShowData.playerId
        local isCallBack = false
        local marchId = self.mItemShowData:GetMarchId()
        if isSelf and marchId ~= '' then                        
            local confirmData =
            {
                labelText = _RALang('@ConfirmSendbackTroops'),
                yesNoBtn = true,
                resultFun = function (isOK)
                    if isOK then
                        local RAWorldPushHandler = RARequire('RAWorldPushHandler')
                        --召回
                        RAWorldPushHandler:sendServerCalcCallBackReq(marchId)
                        RARootManager.CloseAllPages()
                    end
                end
            }
            RARootManager.showConfirmMsg(confirmData)
        end
    end,

    onClose = function(self)
        local ccbRoot = self.mCellRoot
        if not ccbRoot then return end
        local ccbfile = ccbRoot:getCCBFileNode() 
        -- 关闭其他所有cell的add显示
        MessageManager.sendMessageInstant(MessageDef_World.MSG_PresidentQuarterPage_CellAdd_Change)
    end,


    --点击查看部队详情
    onDetailsBtn = function(self)
        local showData = self.mItemShowData
        MessageManager.sendMessage(MessageDef_World.MSG_PresidentQuarterPage_CellInfo_Change, 
            {
                showData = showData
            })
        local ccbRoot = self.mCellRoot
        if not ccbRoot then return end
        local ccbfile = ccbRoot:getCCBFileNode() 
        self:ChangeArmyInfoStatus(ccbfile, not self.mOpenStatus)
    end,
}


--空闲的cell和带花钱开启的cell
local RAAllianceBaseWarSpareCell = 
{
    New = function(self, o)
        local o = o or {}
        setmetatable(o,self)
        self.__index = self                
        return o
    end,

    GetCCBName = function(self)
        return 'RAAllianceBaseWarInfoCell3.ccbi'
    end,

    SetData = function(self, index, isLock, buyItemTimes, mannorId)
        self.mIndex = index
        self.mIsLock = isLock or false
        self.mBuyTimes = buyItemTimes or 0
        self.mIsOptVisual = false
        self.mMannorId = mannorId
    end,

    onRefreshContent = function(self, ccbRoot)
        if not ccbRoot then return end
        local ccbfile = ccbRoot:getCCBFileNode() 
        UIExtend.handleCCBNode(ccbfile)
        self.mCellRoot = ccbRoot
        if not self.mIsLock then
            UIExtend.setStringForLabel(ccbfile, {mCellExplainLabel = _RALang("@ClickAidDefenceEnemy")}) 
        else         
            local RANewAllianceWarManager = RARequire('RANewAllianceWarManager')
            local isCanBuy, costValue = RANewAllianceWarManager:GetNextMassItemCost(self.mBuyTimes)
            UIExtend.setStringForLabel(ccbfile, {mCellExplainLabel = _RALang("@TempQueueCost", costValue)})
        end
        UIExtend.setNodesVisible(ccbfile, {mLockedNode = self.mIsLock})
        UIExtend.setNodesVisible(ccbfile, {mAddNode = not self.mIsLock})
        UIExtend.setNodesVisible(ccbfile, {mAssistanceOptBtnNode = self.mIsOptVisual})        
        UIExtend.setMenuItemEnable(ccbfile, 'mCellBtn', not self.mIsOptVisual)
        UIExtend.setMenuItemEnable(ccbfile, 'mClose', self.mIsOptVisual)
    end,

    UpdateSpareCellStatus = function(self, value)
        local ccbRoot = self.mCellRoot
        if not ccbRoot then return end
        local ccbfile = ccbRoot:getCCBFileNode() 
        if ccbfile ~= nil then
            self.mIsOptVisual = value or false
            UIExtend.setNodesVisible(ccbfile, {mAssistanceOptBtnNode = self.mIsOptVisual})                 
            UIExtend.setMenuItemEnable(ccbfile, 'mCellBtn', not self.mIsOptVisual)
            UIExtend.setMenuItemEnable(ccbfile, 'mClose', self.mIsOptVisual)
        end
    end,

    onCellBtn = function(self)
        local ccbRoot = self.mCellRoot
        if not ccbRoot then return end
        local ccbfile = ccbRoot:getCCBFileNode() 
        -- 关闭其他所有cell的add显示
        MessageManager.sendMessageInstant(MessageDef_World.MSG_PresidentQuarterPage_CellAdd_Change)
        -- 没锁的时候，直接弹出2个按钮来选择
        if not self.mIsLock then            
            self.mIsOptVisual = not self.mIsOptVisual
            self:UpdateSpareCellStatus(self.mIsOptVisual)
        else
        -- 锁定的话，点击购买
            local playerId = RAPlayerInfoManager.getPlayerId()
            local isSelfLeader = false
            local marchId = ''
            if self.mAddParams ~= nil then
                isSelfLeader = self.mAddParams.leaderId == playerId
                marchId = self.mAddParams.leaderMarchId                
            end            
            if isSelfLeader and marchId ~= '' then
                local RANewAllianceWarManager = RARequire('RANewAllianceWarManager')
                local isCanBuy, costValue = RANewAllianceWarManager:GetNextMassItemCost(self.mBuyTimes)
                local confirmData =
                {
                    labelText = _RALang('@TempQueueHint', costValue),
                    yesNoBtn = true,
                    resultFun = function (isOK)
                        if isOK then
                            --点击发送解锁的协议
                            local msg = GuildWar_pb.WorldQuarteredMarchBuyExtraItemsReq()
                            msg.marchId = marchId
                            local RANetUtil = RARequire('RANetUtil')
                            RANetUtil:sendPacket(HP_pb.WORLD_QUARTERED_MARCH_BUY_ITEMS_C, msg)
                        end
                    end
                }
                RARootManager.showConfirmMsg(confirmData)
            else
                RARootManager.ShowMsgBox(_RALang('@PermissionDeniedForExtraMarch'))
            end            
        end
    end,

    onClose = function(self)
        local ccbRoot = self.mCellRoot
        if not ccbRoot then return end
        local ccbfile = ccbRoot:getCCBFileNode() 
        -- 关闭其他所有cell的add显示
        MessageManager.sendMessageInstant(MessageDef_World.MSG_PresidentQuarterPage_CellAdd_Change)
        if not self.mIsLock then
            self.mIsOptVisual = not self.mIsOptVisual
            self:UpdateSpareCellStatus(self.mIsOptVisual)
        end        
    end,

    onAssistanceBtn = function(self)
        RAAllianceBaseWarInfoCellHelper:MacrhToMannor(World_pb.MANOR_ASSISTANCE, self.mMannorId, self.mAddParams)
    end,

    onGatherAssistanceBtn = function(self)
        --集结援助
        RAAllianceBaseWarInfoCellHelper:MacrhToMannor(World_pb.MANOR_ASSISTANCE_MASS, self.mMannorId, self.mAddParams)
    end,
}


--部队详情的cell
local RAAllianceBaseWarArmyCell = 
{
    New = function(self, o)
        local o = o or {}
        setmetatable(o,self)
        self.__index = self                
        return o
    end,

    GetCCBName = function(self)
        return 'RAAllianceBaseWarInfoCell2.ccbi'
    end,

    SetData = function(self, index, showData, mannorId)
        self.mIndex = index
        self.mShowData = showData
        self.mMannorId = mannorId
    end,

    onRefreshContent = function(self, ccbRoot)
        if not ccbRoot then return end
        local ccbfile = ccbRoot:getCCBFileNode() 
        self.mCellRoot = ccbRoot
        local scrollView = UIExtend.getCCScrollViewFromCCB(ccbfile, "mTroopsListSV")
        if self.mShowData ~= nil and scrollView ~= nil then
            scrollView:removeAllCell()
            local armys = self.mShowData.armys
            local cellIndex = 0 
            for i=1, #armys do                
                local amryInfo = armys[i]
                cellIndex = cellIndex + 1
                local itemCellHandler = RAAllianceBaseWarInfoCellHelper:CreateArmyInfoNode(cellIndex, amryInfo.armyId, amryInfo.count)
                local itemCell = CCBFileCell:create()            
                itemCell:registerFunctionHandler(itemCellHandler)
                itemCell:setCCBFile(itemCellHandler:GetCCBName())
                scrollView:addCellBack(itemCell)
            end
            scrollView:orderCCBFileCells()
        end
    end,

    onClose = function(self)
        local ccbRoot = self.mCellRoot
        if not ccbRoot then return end
        local ccbfile = ccbRoot:getCCBFileNode() 
        -- 关闭其他所有cell的add显示
        MessageManager.sendMessageInstant(MessageDef_World.MSG_PresidentQuarterPage_CellAdd_Change)
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
local RAAllianceBaseWarArmyNode= 
{
    New = function(self, o)
        local o = o or {}
        setmetatable(o,self)
        self.__index = self                
        return o
    end,

    GetCCBName = function(self)
        return 'RAAllianceBaseWarInfoCell2Node.ccbi'
    end,

    SetData = function(self, index, soldierId, count, mannorId)
        self.mIndex = index
        self.mSoldierId = tonumber(soldierId)
        self.mCount = count
        self.mMannorId = mannorId
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

function RAAllianceBaseWarInfoCellHelper:CreateArmyInfoCell(index, showData, mannorId)
    local cell = RAAllianceBaseWarArmyCell:New()
    cell:SetData(index, showData, mannorId)
    return cell
end

function RAAllianceBaseWarInfoCellHelper:CreateArmyInfoNode(index, soldierId, count, mannorId)
    local cell = RAAllianceBaseWarArmyNode:New()
    cell:SetData(index, soldierId, count, mannorId)
    return cell
end


function RAAllianceBaseWarInfoCellHelper:CreateJoinedCell(index, itemShowData, openStatus, mannorId, addParams)
    local cell = RAAllianceBaseWarJoinedCell:New()
    cell:SetData(index, itemShowData, openStatus, mannorId)
    cell.mAddParams = addParams
    return cell
end

function RAAllianceBaseWarInfoCellHelper:CreateSpareCell(index, isLock, buyItemTimes, mannorId, addParams)
    local cell = RAAllianceBaseWarSpareCell:New()
    cell:SetData(index, isLock, buyItemTimes, mannorId)
    cell.mAddParams = addParams
    return cell
end

function RAAllianceBaseWarInfoCellHelper:MacrhToMannor(marchType, mannorId, addParams)
    local RAWorldVar = RARequire('RAWorldVar')
    local RAWorldUtil = RARequire('RAWorldUtil')
    local RAWorldConfig = RARequire('RAWorldConfig')
    local RAWorldConfigManager = RARequire('RAWorldConfigManager')
    local RATerritoryDataManager = RARequire('RATerritoryDataManager')

    local cfgId = RAWorldConfig.TerritoryBuildingId[Const_pb.GUILD_BASTION]
    local cfg = RAWorldConfigManager:GetTerritoryBuildingCfg(cfgId)
    local territoryData = RATerritoryDataManager:GetTerritoryById(mannorId)
    if territoryData ~= nil then
        local coord = territoryData.buildingPos[Const_pb.GUILD_BASTION]
        if addParams ~= nil and addParams.coord ~= nil then
            coord = RACcp(addParams.coord.x, addParams.coord.y)
        end
        local icon = cfg.icon
        local name = _RALang(cfg.name)
        if RAWorldUtil:IsMassingMarch(marchType) then   
            if RAWorldUtil:IsAbleToMass() then         
                local confirmFunc = function ()
                    local pageData = 
                    {
                        posX = coord.x,
                        posY = coord.y,
                        name = name,
                        icon = icon,
                        marchType = marchType
                    }
                    RARootManager.OpenPage('RAAllianceGatherPage', pageData, false, true, true)
                end
                RAWorldUtil:ActAfterConfirm(confirmFunc)
            else
                --建造卫星通讯所后才能参与集结
                RARootManager.showErrorCode(535)
            end
        else            
            local confirmFunc = function ()        
                local pageData =
                {
                    coord       = coord, 
                    name        = name,
                    icon        = icon,
                    marchType   = marchType
                }
                RARootManager.OpenPage('RATroopChargePage', pageData)
            end
            RAWorldUtil:ActAfterConfirm(confirmFunc)
        end
    end
    return 
end

return RAAllianceBaseWarInfoCellHelper
