--RAPresidentQuarterCellHelper
-- 驻军信息 cell
local UIExtend = RARequire("UIExtend")
local RARootManager = RARequire("RARootManager")
local RAAllianceManager = RARequire('RAAllianceManager')
local RAPlayerInfoManager = RARequire('RAPlayerInfoManager')
local RAAllianceProtoManager = RARequire("RAAllianceProtoManager")
local RAPresidentMarchDataHelper = RARequire("RAPresidentMarchDataHelper")
local RABuildManager = RARequire("RABuildManager")
local HP_pb = RARequire("HP_pb")
local Const_pb = RARequire("Const_pb")
local World_pb=RARequire("World_pb")
local GuildWar_pb = RARequire("GuildWar_pb")
local common = RARequire("common")

local RAPresidentQuarterCellHelper = {}


-- 已经加入的cell
local RAPresidentQuarterJoinedCell = 
{
    New = function(self, o)
        local o = o or {}
        setmetatable(o,self)
        self.__index = self                
        o.mLastUpdateTime = 0
        return o
    end,

    GetCCBName = function(self)
        return 'RAPresidentGatherCell1.ccbi'
    end,

    SetData = function(self, index, itemShowData, status)
        self.mIndex = index
        self.mItemShowData = itemShowData
        self.mOpenStatus = status or false
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
            RAPresidentMarchDataHelper:MarchToPresident(World_pb.PRESIDENT_ASSISTANCE)
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
        self:ChangeArmyInfoStatus(ccbfile, not self.mOpenStatus)
    end,
}


--空闲的cell和带花钱开启的cell
local RAPresidentQuarterSpareCell = 
{
    New = function(self, o)
        local o = o or {}
        setmetatable(o,self)
        self.__index = self                
        return o
    end,

    GetCCBName = function(self)
        return 'RAPresidentGatherCell3.ccbi'
    end,

    SetData = function(self, index, isLock, buyItemTimes)
        self.mIndex = index
        self.mIsLock = isLock or false
        self.mBuyTimes = buyItemTimes or 0
        self.mIsOptVisual = false
    end,

    onRefreshContent = function(self, ccbRoot)
        if not ccbRoot then return end
        local ccbfile = ccbRoot:getCCBFileNode() 
        UIExtend.handleCCBNode(ccbfile)
        self.mCellRoot = ccbRoot
        if not self.mIsLock then
            UIExtend.setStringForLabel(ccbfile, {mCellExplainLabel = _RALang("@ClickAidAlklyTxt")}) 
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
            local isLeader, marchId = RAPresidentMarchDataHelper:CheckSelfIsLeader()
            local guildId = RAPresidentMarchDataHelper:GetCurrGuildId()
            if isLeader and guildId ~= '' then
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
        RAPresidentMarchDataHelper:MarchToPresident(World_pb.PRESIDENT_ASSISTANCE)
    end,

    onGatherAssistanceBtn = function(self)
        --集结援助
        RAPresidentMarchDataHelper:MarchToPresident(World_pb.PRESIDENT_ASSISTANCE_MASS)
    end,
}


--部队详情的cell
local RAPresidentQuarterArmyCell = 
{
    New = function(self, o)
        local o = o or {}
        setmetatable(o,self)
        self.__index = self                
        return o
    end,

    GetCCBName = function(self)
        return 'RAPresidentGatherCell2.ccbi'
    end,

    SetData = function(self, index, showData)
        self.mIndex = index
        self.mShowData = showData
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
                local itemCellHandler = RAPresidentQuarterCellHelper:CreateArmyInfoNode(cellIndex, amryInfo.armyId, amryInfo.count)
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
local RAPresidentQuarterArmyNode= 
{
    New = function(self, o)
        local o = o or {}
        setmetatable(o,self)
        self.__index = self                
        return o
    end,

    GetCCBName = function(self)
        return 'RAPresidentGatherCell2Node.ccbi'
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

function RAPresidentQuarterCellHelper:CreateArmyInfoCell(index, showData)
    local cell = RAPresidentQuarterArmyCell:New()
    cell:SetData(index, showData)
    return cell
end

function RAPresidentQuarterCellHelper:CreateArmyInfoNode(index, soldierId, count)
    local cell = RAPresidentQuarterArmyNode:New()
    cell:SetData(index, soldierId, count)
    return cell
end


function RAPresidentQuarterCellHelper:CreateJoinedCell(index, itemShowData, openStatus)
    local cell = RAPresidentQuarterJoinedCell:New()
    cell:SetData(index, itemShowData, openStatus)
    return cell
end

function RAPresidentQuarterCellHelper:CreateSpareCell(index, isLock, buyItemTimes)
    local cell = RAPresidentQuarterSpareCell:New()
    cell:SetData(index, isLock, buyItemTimes)
    return cell
end

return RAPresidentQuarterCellHelper