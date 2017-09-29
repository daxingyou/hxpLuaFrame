-- RASearchPage
-- 查找路点页面

RARequire("BasePage")
local UIExtend = RARequire("UIExtend")
local Utilitys = RARequire('Utilitys')
local RARootManager = RARequire("RARootManager")
local RAWorldConfigManager = RARequire('RAWorldConfigManager')
local RAWorldVar = RARequire('RAWorldVar')
local World_pb = RARequire('World_pb')
local HP_pb = RARequire('HP_pb')
local world_enemy_conf = RARequire('world_enemy_conf')
local world_resshow_conf = RARequire('world_resshow_conf')
local territory_search_conf = RARequire('territory_search_conf')
local common = RARequire('common')




-- 查找的cell
local RASearchShowCell = 
{
    new = function(self, o)        
        o = o or {}
        setmetatable(o, self)
        self.__index = self
        return o
    end,

    onRefreshContent = function(self, ccbRoot)
        if ccbRoot == nil then return end
        local ccbi = ccbRoot:getCCBFileNode()        
        UIExtend.addSpriteToNodeParent(ccbi, 'mIconNode', self.icon)
        UIExtend.setCCLabelString(ccbi, 'mCellName', _RALang(self.name))
    end
}



local RASearchPage = BaseFunctionPage:new(...)

-- 资源id
RASearchPage.mResId = 0
RASearchPage.mResLevelIndex = 1
RASearchPage.mResLevelMap = {}

RASearchPage.mMosnterId = 0

RASearchPage.mTerritoryId = 5
RASearchPage.mTerritoryType = World_pb.SEARCH_MANOR_OCCUPIED
RASearchPage.mTerritoryTypeMap = {   
    [World_pb.SEARCH_MANOR_OCCUPIED] = '@OccupiedByUs',
    [World_pb.SEARCH_MANOR_ENEMY_OCCUPIED] = '@OccupiedByOther',
    [World_pb.SEARCH_MANOR_UN_OCCUPIED] = '@OccupiedByNoOne',
}

-- 查找的间隔时间，5秒
local RA_Search_Time_Gap = 5

RASearchPage.mCurrType = World_pb.SEARCH_RESOURCE
RASearchPage.mLastRequestTime = RA_Search_Time_Gap


local OnReceiveMessage = function(message)     
    -- if message.messageID == MessageDef_World.MSG_ArmyFreeCountUpdate then
    --     --需要整个UI cell重新计算
    --     CCLuaLog("MessageDef_World MSG_ArmyFreeCountUpdate")
    --     RASearchPage:RefreshUIWhenSelectedChange()
    -- end

    -- if message.messageID == MessageDef_World.MSG_ArmyChangeSelectedCount then
    --     --需要刷新cell数据和UI
    --     CCLuaLog("MessageDef_World MSG_ArmyChangeSelectedCount")
    --     RASearchPage:RefreshUIWhenSelectedChange(message.actionType, message.armyId, message.selectCount)
    -- end

    if message.messageID == MessageDef_Packet.MSG_Operation_Fail then
        local opcode = message.opcode
        if opcode == HP_pb.WORLD_SEARCH_C then
            RARootManager.RemoveWaitingPage()
        end
    end
end

function RASearchPage:registerMessageHandlers()
    -- MessageManager.registerMessageHandler(MessageDef_World.MSG_ArmyFreeCountUpdate, OnReceiveMessage)
    -- MessageManager.registerMessageHandler(MessageDef_World.MSG_ArmyChangeSelectedCount, OnReceiveMessage)

    MessageManager.registerMessageHandler(MessageDef_Packet.MSG_Operation_Fail, OnReceiveMessage)
end

function RASearchPage:unregisterMessageHandlers()
    -- MessageManager.removeMessageHandler(MessageDef_World.MSG_ArmyFreeCountUpdate, OnReceiveMessage)
    -- MessageManager.removeMessageHandler(MessageDef_World.MSG_ArmyChangeSelectedCount, OnReceiveMessage)

    MessageManager.removeMessageHandler(MessageDef_Packet.MSG_Operation_Fail, OnReceiveMessage)
end


function RASearchPage:resetData()
    --
end

function RASearchPage:EnterFrame()
    CCLuaLog("RASearchPage:EnterFrame")    
end

function RASearchPage:Enter(data)
    CCLuaLog("RASearchPage:Enter")    

    data = data or {}
    if data.selectType then
        self.mCurrType = data.selectType
        if data.subType then
            self.mResId = data.subType
        end
    end

    self:resetData()
    local ccbfile = UIExtend.loadCCBFile("ccbi/RASearchPopUp.ccbi",RASearchPage)    
    self.mListNode = UIExtend.getCCNodeFromCCB(self.ccbfile, "mListNode")
    local size = CCSizeMake(0, 0)
    if self.mListNode then
        size = self.mListNode:getContentSize()
    end
    self.scrollView = CCSelectedScrollView:create(size)
    self.scrollView:setDirection(kCCScrollViewDirectionHorizontal)
    self.scrollView:registerFunctionHandler(self)
    UIExtend.addNodeToParentNode(self.ccbfile, "mListNode", self.scrollView)

    self:RegisterPacketHandler(HP_pb.WORLD_SEARCH_S)
    self:registerMessageHandlers()

    self:RefreshScrollView(self.mCurrType, true)
    -- self:refreshCommonUI()
end


-- 根据搜索类型刷新
function RASearchPage:RefreshScrollView(searchType, isForce)        
    isForce = isForce or false
    local ccbi = self.ccbfile
    if ccbi == nil then return end
    if not isForce and self.mCurrType == searchType then return end
    local scrollViewData, showData = self:GetScrollViewData(searchType)
    
    self.scrollView:removeAllCell()
    
    local firstCell = nil
    local selectCell = nil
    for i=1, #scrollViewData do
        local oneCfg = scrollViewData[i]
        local cellListener = RASearchShowCell:new(oneCfg)
        local cell = CCBFileCell:create()
        cell:registerFunctionHandler(cellListener)
        cell:setCCBFile("RASearchPopUpCell.ccbi")        
        self.scrollView:addCellBack(cell)        
        cell:setTag(tonumber(oneCfg.id))
        if showData.tmpId == oneCfg.id then
            self.scrollView:setSelectedCell(cell)            
            selectCell = cell
        end   
        if i == 1 then                
            firstCell = cell
        end
    end
    self.scrollView:orderCCBFileCells()
    if selectCell ~= nil then
        self.scrollView:setSelectedCell(selectCell)
    else
        self.scrollView:setSelectedCell(firstCell)
    end
    local cellSelected = self.scrollView:getSelectedCell()
    cellSelected:locateTo(CCBFileCell.LT_Mid)
    self.mCurrType = searchType
    self:SelectOneCell(cellSelected)

    local selectedMap = {
        mResBtn = false,
        mYuriBtn = false,
        mTerritoryBtn = false,
    }
    if self.mCurrType == World_pb.SEARCH_RESOURCE then
        self.mResId = cellSelected:getTag()
        selectedMap.mResBtn = true
    elseif self.mCurrType == World_pb.SEARCH_MONSTER then
        self.mMosnterId = cellSelected:getTag()
        selectedMap.mYuriBtn = true
    elseif self.mCurrType == World_pb.SEARCH_GUILD_MANOR then
        self.mTerritoryId = cellSelected:getTag()
        selectedMap.mTerritoryBtn = true
    end
    UIExtend.setControlButtonSelected(ccbi, selectedMap )
end

function RASearchPage:GetScrollViewData(searchType)
    local scrollViewData = {}
    local showData = {}
    if searchType == World_pb.SEARCH_RESOURCE then
        for id,cfg in pairs(world_resshow_conf) do
            local oneCfg = {
                id = id,
                level = cfg.levelRange,
                icon = cfg.resTargetIcon,
                name = cfg.resName,
                resType = cfg.resType
            }
            table.insert(scrollViewData, oneCfg)
        end
        Utilitys.tableSortByKey(scrollViewData,'id')
        showData.isNameSelect = true
        showData.tmpId = self.mResId
        showData.tmpIndex = self.mResLevelIndex        
    elseif searchType == World_pb.SEARCH_MONSTER then
        for id,cfg in pairs(world_enemy_conf) do
            if cfg.newly == 0 then
                local oneCfg = {
                    id = id,
                    level = cfg.level,
                    icon = cfg.icon,
                    name = cfg.name,
                }
                table.insert(scrollViewData, oneCfg)
            end
        end
        Utilitys.tableSortByKey(scrollViewData,'id')
        showData.isNameSelect = false
        showData.tmpId = self.mMosnterId
        showData.tmpIndex = nil
    elseif searchType == World_pb.SEARCH_GUILD_MANOR then
        for id,cfg in pairs(territory_search_conf) do
            local oneCfg = {
                id = id,
                level = cfg.level,
                icon = cfg.icon,
                name = cfg.name,
            }
            table.insert(scrollViewData, oneCfg)
        end
        Utilitys.tableSortByKey(scrollViewData,'id')
        showData.isNameSelect = true        
        showData.tmpId = self.mTerritoryId
        showData.tmpIndex = self.mTerritoryType
    end
    return scrollViewData, showData
end


--当选中一个cell的时候调用；用于记录当前的Id
function RASearchPage:SelectOneCell(cell)
    if cell == nil then return end
    local RAStringUtil = RARequire('RAStringUtil')
    local id = cell:getTag()
    if self.mCurrType == World_pb.SEARCH_RESOURCE then
        self.mResId = id
        --刷新等级map
        local resCfg = world_resshow_conf[self.mResId]
        self.mResLevelMap = {}
        if resCfg ~= nil then
            self.mResLevelMap = RAStringUtil:split(resCfg.levelRange, '_')            
        else
            table.insert(self.mResLevelMap, 1)
        end
        self:CheckAndSelectLabelByIndex(self.mResLevelIndex)
    elseif self.mCurrType == World_pb.SEARCH_MONSTER then
        self.mMosnterId = id
        self:CheckAndSelectLabelByIndex(0)
    elseif self.mCurrType == World_pb.SEARCH_GUILD_MANOR then
        self.mTerritoryId = id
        self:CheckAndSelectLabelByIndex(self.mTerritoryType)
    end

    -- 判断左右按钮是否显示
    if self.scrollView ~= nil and self.ccbfile ~= nil then        
        local currOrder = self.scrollView:getCCBFileCellOrderIndex()
        local visibleMap = {
            mIconLABtnNode = false,
            mIconRABtnNode = false,
        }
        if currOrder > 0 then
            visibleMap.mIconLABtnNode = true
        end

        if currOrder < self.scrollView:getCCBFileCellsCount() - 1 then
            visibleMap.mIconRABtnNode = true
        end
        UIExtend.setNodesVisible(self.ccbfile,visibleMap)            
    end
end



-- 获取当前选中文本部分的索引和最大值
function RASearchPage:GetCurrSelectIndex(searchType)
    local maxSize = 0
    local currIndex = 0
    if searchType == World_pb.SEARCH_RESOURCE then
        maxSize = #self.mResLevelMap
        currIndex =  self.mResLevelIndex
    elseif searchType == World_pb.SEARCH_MONSTER then
        maxSize = 0
        currIndex = 0
    elseif searchType == World_pb.SEARCH_GUILD_MANOR then
        maxSize = World_pb.SEARCH_MANOR_UN_OCCUPIED
        currIndex = self.mTerritoryType
    end
    return currIndex, maxSize
end

--当选中一个cell对应的附加状态时调用
-- 领地：关系
-- 资源：等级
-- 怪物：无
function RASearchPage:CheckAndSelectLabelByIndex(index)    
    local labelStr = ''
    local maxSize = 0
    local lastIndex = 0
    if self.mCurrType == World_pb.SEARCH_RESOURCE then
        local level = self.mResLevelMap[index]
        if level ~= nil then
            self.mResLevelIndex = index        
            labelStr = _RALang('@ResourceLevel', level)        
            lastIndex = index
        end
        maxSize = #self.mResLevelMap
    elseif self.mCurrType == World_pb.SEARCH_MONSTER then
        print('RASearchPage:CheckAndSelectLabelByIndex errrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrrror')
        index = 0
        maxSize = 0
        local cfg = world_enemy_conf[self.mMosnterId]
        if cfg ~= nil then
            labelStr = _RALang('@ResourceLevel', cfg.level)    
        end
    elseif self.mCurrType == World_pb.SEARCH_GUILD_MANOR then
        if self.mTerritoryTypeMap[index] ~= nil then
            self.mTerritoryType = index           
            labelStr = _RALang(self.mTerritoryTypeMap[self.mTerritoryType])
            lastIndex = index
        end
        maxSize = World_pb.SEARCH_MANOR_UN_OCCUPIED
    end    

    local ccbfile = self.ccbfile
    if ccbfile ~= nil then        
        if maxSize == 0 then
            UIExtend.setNodesVisible(ccbfile, {
                mStateArrowBtnNode = false
                })
        else
            local nodesVisible = {
                mStateArrowBtnNode = true
            }
            nodesVisible['mStateLABtnNode'] = false
            nodesVisible['mStateRABtnNode'] = false
            if lastIndex > 1 then
                nodesVisible['mStateLABtnNode'] = true
            end

            if lastIndex < maxSize then
                nodesVisible['mStateRABtnNode'] = true
            end

            UIExtend.setNodesVisible(ccbfile, nodesVisible)
        end        
        if labelStr ~= '' then
            UIExtend.setCCLabelString(ccbfile, 'mStateLabel', labelStr)
        end
    end

end

function RASearchPage:scrollViewSelectNewItem(cell)
    if cell then
        local preCell = self.scrollView:getSelectedCell()
        if preCell then
            -- --播放缩小动画
            -- local scaleSmallAction = CCScaleTo:create(0.2, RAGameConfig.Portrait_Scale, RAGameConfig.Portrait_Scale)
            -- preCell:runAction(scaleSmallAction)
        end
        self.scrollView:setSelectedCell(cell, CCBFileCell.LT_Mid, 0.0, 0.2)
        -- --播放放大动画
        -- local scaleLargeAction = CCScaleTo:create(0.2, 1, 1)
        -- cell:runAction(scaleLargeAction)
        -- local cellTag = cell:getCellTag()
        -- currentChooseId = cellTag - RAGameConfig.ConfigIDFragment.ID_PLAYER_SHOWCONF
        -- self:refreshBtn()
    end
end

function RASearchPage:scrollViewSelectNewItemIsNull(cell)
    if cell then
        local preCell = self.scrollView:getSelectedCell()
        if preCell then
            --todo播放缩小动画
        end
        self.scrollView:setSelectedCell(cell, CCBFileCell.LT_Mid, 0.0, 0.2)
        --todo播放放大动画       
    end
end

function RASearchPage:scrollViewRollBack(cell)
    if cell then
        self.scrollView:setSelectedCell(cell, CCBFileCell.LT_Mid, 0.0, 0.2)
    end
end

function RASearchPage:scrollViewPreItem(preCell)

end

function RASearchPage:scrollViewChangeItem(cell)
    self:SelectOneCell(cell)
end

function RASearchPage:onResBtn()
    CCLuaLog("RASearchPage:onResBtn") 
    self:RefreshScrollView(World_pb.SEARCH_RESOURCE)
end

function RASearchPage:onYuriBtn()
    CCLuaLog("RASearchPage:onYuriBtn") 
    self:RefreshScrollView(World_pb.SEARCH_MONSTER)
end

function RASearchPage:onTerritoryBtn()
    CCLuaLog("RASearchPage:onTerritoryBtn") 
    self:RefreshScrollView(World_pb.SEARCH_MANOR_UN_OCCUPIED)
end

function RASearchPage:onStateLABtn()
    CCLuaLog("RASearchPage:onStateLABtn") 
    -- self:RefreshScrollView(World_pb.SEARCH_MONSTER)    
    local currIndex, maxSize = self:GetCurrSelectIndex(self.mCurrType)
    if currIndex <= 1 or currIndex > maxSize then
        return
    else
        self:CheckAndSelectLabelByIndex(currIndex - 1)
    end
end

function RASearchPage:onStateRABtn()
    CCLuaLog("RASearchPage:onStateRABtn") 
    -- self:RefreshScrollView(World_pb.SEARCH_MANOR_UN_OCCUPIED)
    local currIndex, maxSize = self:GetCurrSelectIndex(self.mCurrType)
    if currIndex <= 0 or currIndex >= maxSize then
        return
    else
        self:CheckAndSelectLabelByIndex(currIndex + 1)
    end
end


function RASearchPage:onIconLABtn()
    CCLuaLog("RASearchPage:onIconLABtn") 
    if self.scrollView == nil then return end
    self.scrollView:moveCellByDirection(-1)
    -- self:RefreshScrollView(World_pb.SEARCH_MONSTER)
end

function RASearchPage:onIconRABtn()
    CCLuaLog("RASearchPage:onIconRABtn") 
    if self.scrollView == nil then return end
    self.scrollView:moveCellByDirection(1)
    -- self:RefreshScrollView(World_pb.SEARCH_MANOR_UN_OCCUPIED)
end



function RASearchPage:onClose()
    CCLuaLog("RASearchPage:onClose") 
    RARootManager.ClosePage('RASearchPage')
end

function RASearchPage:onFindBtn()
    CCLuaLog("RASearchPage:onFindBtn")
    local RANetUtil = RARequire('RANetUtil')
    local cmd = World_pb.WorldSearchReq()
    cmd.type = self.mCurrType
    if self.mCurrType == World_pb.SEARCH_RESOURCE then
        cmd.id = self.mResId
        local RAWorldConfigManager = RARequire('RAWorldConfigManager')
        local id, _ = RAWorldConfigManager:GetResIdByTypeAndLevel(self.mResId, self.mResLevelMap[self.mResLevelIndex])
        if id ~= nil then
            cmd.id = id
        else
            print('there is some thing wwwwwwwwwwwwwwwwwwwwrongggggggggggggggggggggg')
            return
        end
    elseif self.mCurrType == World_pb.SEARCH_MONSTER then
        cmd.id = self.mMosnterId
    elseif self.mCurrType == World_pb.SEARCH_GUILD_MANOR then
        cmd.id = self.mTerritoryId
        cmd.manorType = self.mTerritoryType
    end
    local errorStr = 'RASearchPage:onFindBtn waiting page close Error'
    RARootManager.ShowWaitingPage(false, RA_Search_Time_Gap, errorStr)
    RANetUtil:sendPacket(HP_pb.WORLD_SEARCH_C,cmd,{retOpcode=-1})
    self.mLastRequestTime = common:getCurTime()
    self.mIsExecute = true
end


function RASearchPage:onReceivePacket(handler)
    local pbCode = handler:getOpcode()
    local buffer = handler:getBuffer()
    if pbCode == HP_pb.WORLD_SEARCH_S then
        local msg = World_pb.WorldSearchResp()
        msg:ParseFromString(buffer)        
        RARootManager.RemoveWaitingPage()

        if RARootManager.GetIsInWorld() then
            local RAWorldManager = RARequire('RAWorldManager')
            RAWorldManager:LocateAt(msg.targetX, msg.targetY, nil, true)
        end
        self:onClose()
    end
end



function RASearchPage:OnAnimationDone(ccbfile)
	local lastAnimationName = ccbfile:getCompletedAnimationName()	
end

function RASearchPage:Execute()
    if self.ccbfile ~= nil then
    	if not self.mIsExecute then return end        
        local pastTime = os.difftime(common:getCurTime(), self.mLastRequestTime)
        if pastTime >= RA_Search_Time_Gap then        
            UIExtend.setControlButtonTitle(self.ccbfile, 'mFindBtn', '@Find')
            UIExtend.setCCControlButtonEnable(self.ccbfile, 'mFindBtn', true)
            self.mIsExecute = false
            self.mLastRequestTime = common:getCurTime()
        else
            local lastTime = math.floor(RA_Search_Time_Gap - pastTime)
            UIExtend.setControlButtonTitle(self.ccbfile, 'mFindBtn', _RALang('@FindCd', lastTime))
            UIExtend.setCCControlButtonEnable(self.ccbfile, 'mFindBtn', false)
        end
    end
end	

function RASearchPage:Exit()
	--you can release lua data here,but can't release node element
    CCLuaLog("RASearchPage:Exit")    
    self:RemovePacketHandlers()
    self:unregisterMessageHandlers()
    if self.scrollView ~= nil then
        self.scrollView:unregisterFunctionHandler()
        self.scrollView:removeAllCell()
        self.scrollView = nil
    end
    if self.mListNode then
        self.mListNode:removeAllChildren()
    end
    self:resetData()
    UIExtend.unLoadCCBFile(self)    
end