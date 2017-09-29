--require('UICore.ScrollViewAnimation')
RARequire("BasePage")
local UIExtend = RARequire('UIExtend')
local RAMainUIHelper = RARequire('RAMainUIHelper')
local RAStringUtil = RARequire('RAStringUtil')
local RARootManager = RARequire('RARootManager')
local RAActionManager = RARequire('RAActionManager')
local RAQueueManager = RARequire('RAQueueManager')
local RABuildManager = RARequire('RABuildManager')
local RACoreDataManager = RARequire('RACoreDataManager')
local EnterFrameDefine = RARequire('EnterFrameDefine')
local Utilitys = RARequire('Utilitys')
local common = RARequire('common')
local Const_pb = RARequire('Const_pb')
local List = RARequire("List")

local RAMainUIQueueShowHelper = {}

local OnReceiveMessage = nil
local CCB_InAni = "InAni"
local CCB_OutAni = "OutAni"
local CCB_KeepIn = "KeepIn"
local CCB_KeepOut = "KeepOut"

local CCB_UpAni = "UpAni"
local CCB_DownAni = "DownAni"

local CCB_Btn_OpenAni = 'OpenAni'
local CCB_Btn_KeepOpen = 'KeepOpen'
local CCB_Btn_CloseAni = 'CloseAni'
local CCB_Btn_KeepClose = 'KeepClose'


-- 单个cell 更改状态的类型
local CellChangeType = 
{
    None = 0,
    Add = 1,
    Update = 2,
    Remove = 3
}


local delayGap = 0.05
-- 遮罩动画显示或消失消耗的时间
local _ClipNodeActionTimeNeed = 0.2

local _CellUpDownAniTime = 0.1

-- 单个cell的高度
local MainUI_Queue_One_Cell_Height = 0
local MainUI_Queue_One_Cell_Width = 0

-- 不收缩状态时，最多显示的cell个数
local MainUI_Queue_Cell_Show_Count = 2

------ queue cell
local RAMainUIQueueCellNew = 
{
    new = function(self, o)
        o = o or {}
        setmetatable(o,self)
        self.__index = self
        o.mAniCmpHandler = nil    
        return o
    end,

    GetCCBName = function(self)
        return "RAMainUIQueueCellNewTwo.ccbi"
    end,

    GetCCBFile = function(self)
        return self.ccbfile
    end,

    Load = function(self, handler)
        CCLuaLog("RAMainUIQueueCellNew:Load")
        local ccbi = UIExtend.loadCCBFile(self:GetCCBName(), self)
        if ccbi == nil then return end
        ccbi:runAnimation(CCB_KeepOut)
        -- ccbi:runAnimation(CCB_KeepIn)

        if MainUI_Queue_One_Cell_Height == 0 then
            MainUI_Queue_One_Cell_Height = ccbi:getContentSize().height
        end
        if MainUI_Queue_One_Cell_Width <= 0 then
            MainUI_Queue_One_Cell_Width = ccbi:getContentSize().width
        end
        self.mAniCmpHandler = handler
        UIExtend.setCCLabelString(ccbi, "mCellLabel", 'cell id ='..self.mCellId)
        return ccbi
    end,

    -- Execute = function(self)
        -- CCLuaLog("RAMainUIQueueCellNew:onExcute")
        -- if cellRoot and self.mStartTime ~= -1 then
        --     local lastTime = os.difftime(self.mEndTime, common:getCurTime())
        --     if self.mLastTime > lastTime then
        --         self:refreshTime(cellRoot, lastTime)
        --     end
        -- end
    -- end,

    _RefreshTime = function(self, lastTime)
        if cellRoot == nil then return end
        local ccbfile = cellRoot:getCCBFileNode()
        if ccbfile == nil then return end
        if lastTime <= 0 then
            CCLuaLog('RAMainUIQueueCellNew:refreshTime arg error!!!!  lastTime = '.. lastTime)
            lastTime = 0
            cellRoot:setIsScheduleUpdate(false)
        end

        local RAPlayerInfoManager = RARequire('RAPlayerInfoManager')
        local freeTime = RAPlayerInfoManager.getQueueFreeTime(nil, self.mQueueType)
        local isFree = freeTime >= lastTime
        local tmpStr = Utilitys.createTimeWithFormat(lastTime)
        if self.mBarLabelKey ~= '' then
            tmpStr = _RALang(self.mBarLabelKey, tmpStr)
        end
        UIExtend.setCCLabelString(ccbfile, "mCellLabel", tmpStr)
        UIExtend.setNodesVisible(ccbfile, {
            mBlueBar = not isFree,
            mBlueBtn = not isFree,
            mGreenBar = isFree,
            mFreeBtn = isFree,
            mFreeAniCCB = isFree
        })
        if self.mQueueType ~= Const_pb.MARCH_QUEUE and not isFree then
            UIExtend.setControlButtonTitle(ccbfile, 'mBlueBtn', RAMainUIHelper.SpeedKey)
        end
        -- 计算scale9缩放
        local percent = lastTime / (self.mEndTime - self.mStartTime)
        UIExtend.setCCScale9ScaleByPercent(ccbfile, 'mBlueBar', 'mBarSizeNode', 1 - percent)
        UIExtend.setCCScale9ScaleByPercent(ccbfile, 'mGreenBar', 'mBarSizeNode', 1 - percent)

        -- 计算特效位置
        local aniCCBFile = UIExtend.getCCBFileFromCCB(ccbfile, 'mBarAniCCB')
        if aniCCBFile ~= nil then
            aniCCBFile:setVisible(false)
            if lastTime > 0 and percent > 0 and percent <= 1 then
                local sizeNode = UIExtend.getCCNodeFromCCB(ccbfile, 'mBarSizeNode')
                if sizeNode ~= nil then
                    local x, y = sizeNode:getPosition()
                    local width = sizeNode:getContentSize().width
                    local or_x, or_y = aniCCBFile:getPosition()
                    local scaleX = aniCCBFile:getScaleX()
                    local newX = x + width*(1-percent)
                    aniCCBFile:setPosition(newX * scaleX, or_y)
                    aniCCBFile:setVisible(true)
                end
            end
        end

        self.mLastTime = lastTime
    end,

    onBlueBtn = function(self)
        CCLuaLog("RAMainUIQueueCellNew:onBlueBtn")        
    end,

    onBarBtn = function(self)        
        CCLuaLog("RAMainUIQueueCellNew:onBlueBtn")
    end,

    onFreeBtn = function(self)
        CCLuaLog("RAMainUIQueueCellNew:onFreeBtn")
    end,

    _GetAnimationCmd = function(self, name)
        local ccbi = self:GetCCBFile()
        return function()
            ccbi:runAnimation(name)
        end
    end,

    RunAni = function(self, isShow, delay)
        local aniName = ''
        if isShow then   
            aniName = CCB_InAni         
        else
            aniName = CCB_OutAni
        end    
        if delay > 0 then
            performWithDelay(self:GetCCBFile(), self:_GetAnimationCmd(aniName), delay)
        else
            local cmd = self:_GetAnimationCmd(aniName)
            cmd()
        end
    end,

    OnAnimationDone = function(self, ccbfile)
        local lastAnimationName = ccbfile:getCompletedAnimationName()                
        if lastAnimationName == CCB_InAni or lastAnimationName == CCB_OutAni then
            if self.mAniCmpHandler ~= nil and self.mAniCmpHandler.CellAniEndCallBack ~= nil then
                self.mAniCmpHandler:CellAniEndCallBack(lastAnimationName, self.mCellId)
            end
        end
    end,

    Exit = function(self)
        self.mAniCmpHandler = nil
        UIExtend.unLoadCCBFile(self)
    end
}



------ btn cell
local RAMainUIQueueBtnCell = 
{
    new = function(self, o)
        o = o or {}
        setmetatable(o,self)
        self.__index = self    
        o.mIsVisible = false
        o.mAniCmpHandler = nil
        return o
    end,

    GetCCBName = function(self)
        return "RAMainUIQueueArrowAniNew.ccbi"
    end,

    GetCCBFile = function(self)
        return self.ccbfile
    end,

    Load = function(self, handler)
        CCLuaLog("RAMainUIQueueBtnCell:Load")
        local ccbi = UIExtend.loadCCBFile(self:GetCCBName(), self)
        if ccbi == nil then return end        
        self:SetVisible(false)
        self.mAniCmpHandler = handler
        return ccbi
    end,

    SetVisible = function(self, value)
        local ccbi = self:GetCCBFile()
        if ccbi == nil then value = false end
        self.mIsVisible = value
        if ccbi ~= nil then
            ccbi:setVisible(self.mIsVisible)
        end
    end,

    GetVisible = function(self)
        return self.mIsVisible
    end,    

    SetPositionY = function(self, posY)
        local ccbi = self:GetCCBFile()
        if ccbi == nil then return end
        if ccbi ~= nil then
            ccbi:setPositionY(posY)
        end
    end,

    -- 设置按钮可不可以点击
    -- 遮罩动画过程中不可以点击；动画完成后才可以点击
    SetClickEnable = function(self, value)
        local ccbi = self:GetCCBFile()
        if ccbi == nil then return end
        UIExtend.setMenuItemEnable(ccbi, 'mArrowBtn', value)
    end,

    onArrowBtn = function(self)
        print('RAMainUIQueueBtnCell:onArrowBtn')
        if self.mAniCmpHandler ~= nil then
            self.mAniCmpHandler:ChangeCellOpenState()
        end
    end,

    _GetAnimationCmd = function(self, name)
        local ccbi = self:GetCCBFile()
        return function()
            ccbi:runAnimation(name)
        end
    end,

    RunAni = function(self, isOpen, isStatus)
        local ccbi = self:GetCCBFile()
        if ccbi == nil then return end
        if isStatus then
            if isOpen then
                ccbi:runAnimation(CCB_Btn_KeepOpen)
            else
                ccbi:runAnimation(CCB_Btn_KeepClose)
            end
        else
            if isOpen then
                ccbi:runAnimation(CCB_Btn_OpenAni)
            else
                ccbi:runAnimation(CCB_Btn_CloseAni)
            end 
        end   
    end,

    OnAnimationDone = function(self, ccbfile)
        local lastAnimationName = ccbfile:getCompletedAnimationName()                
        if self.mAniCmpHandler ~= nil and self.mAniCmpHandler.BtnCellAniEndCallBack ~= nil then
            self.mAniCmpHandler:BtnCellAniEndCallBack(lastAnimationName)
        end
    end,

    Exit = function(self)
        UIExtend.unLoadCCBFile(self)
    end
}





RAMainUIQueueShowHelper.mNode = nil

-- 当前所有添加进来的cell
RAMainUIQueueShowHelper.mCellList = nil
RAMainUIQueueShowHelper.mCellCount = 0

RAMainUIQueueShowHelper.mCellNeedRemove = nil


--用于标记当前所有cell是否整体显示出来
RAMainUIQueueShowHelper.mIsAllCellIn = false

--当前cell正在进行移动的个数（用于保证所有cell移动完成后才进行下一步）
RAMainUIQueueShowHelper.mCellChangeCount = 0

--单个cell改变的时候，目标cell的id
RAMainUIQueueShowHelper.mCurrCellChangingId = -1
--单个cell改变的时候，改变的行为类型
RAMainUIQueueShowHelper.mCurrCellChangingType = CellChangeType.None

-- 所有需要接下来刷新的数据
RAMainUIQueueShowHelper.mOneCellAniList = List:New()


-- 收缩按钮(不放在mCellList中)
RAMainUIQueueShowHelper.mBtnCell = nil
RAMainUIQueueShowHelper.mIsBtnCellShow = false

-- 用于标示当前是否是展开状态
RAMainUIQueueShowHelper.mIsOpening = false

-- clip node
RAMainUIQueueShowHelper.mClipNode = nil
-- stencil for clip node
RAMainUIQueueShowHelper.mStencilNode = nil

OnReceiveMessage = function(message)    
    CCLuaLog("RAMainUIPage OnReceiveMessage id:"..message.messageID)

    -- 新的队列UI，删除某个cell，防止崩溃
    if message.messageID == MessageDef_MainUI.MSG_UpdateMainUIQueueDelCell then
        CCLuaLog("MessageDef_Queue MSG_UpdateMainUIQueueDelCell")       
        RAMainUIQueueShowHelper:CheckAndRemoveCellNeed()
        return
    end

    -- open or close RAChooseBuildPage page
    if message.messageID == MessageDef_MainUI.MSG_UpdateMainUIQueuePart then
        CCLuaLog("MessageDef_MainUI MSG_UpdateMainUIQueuePart")
        local updateData = message.updateData
        if updateData then
            -- 0为刷新，1为新增，-1为删除
            local updateType = updateData.updateType
            -- 要操控的cell index
            local cellIndex = updateData.cellIndex or -1

            if updateType == 0 then
                RAMainUIQueueShowHelper:ChangeCellUpdate(updateData)
            end
        end
        return
    end

    if message.messageID == MessageDef_MainUI.MSG_UpdateQueuePage then
        CCLuaLog("MessageDef_Queue MSG_UpdateQueuePage")        
        -- 建造可能会产生新的队列图标
        local buildType = message.buildType
        if buildType ~= nil then
             local queueType = RAQueueManager:getEffectQueueTypeByBuildType(buildType)
             if queueType == -1 then
                return
             end
             RAMainUIQueueShowHelper:HandleQueueStatusChange(queueType)
             return
        end

        -- 获得伤兵会影响队列显示
        if message.queueType ~= nil then
            RAMainUIQueueShowHelper:HandleQueueStatusChange(message.queueType)
        end
        return
    end
    local queueId = message.queueId
    local queueType = message.queueType
    if message.messageID == MessageDef_Queue.MSG_Common_ADD then
        CCLuaLog("MessageDef_Queue MSG_Common_ADD")
        RAMainUIQueueShowHelper:HandleQueueStatusChange(queueType, queueId)
    end

    if message.messageID == MessageDef_Queue.MSG_Common_UPDATE then
        CCLuaLog("MessageDef_Queue MSG_Common_UPDATE")        
        RAMainUIQueueShowHelper:HandleQueueStatusChange(queueType, queueId)
    end

    if message.messageID == MessageDef_Queue.MSG_Common_DELETE then
        CCLuaLog("MessageDef_Queue MSG_Common_DELETE")        
        RAMainUIQueueShowHelper:HandleQueueStatusChange(queueType, queueId)
    end

    if message.messageID == MessageDef_Queue.MSG_Common_CANCEL then
        CCLuaLog("MessageDef_Queue MSG_Common_CANCEL")        
        RAMainUIQueueShowHelper:HandleQueueStatusChange(queueType, queueId)
    end
end

function RAMainUIQueueShowHelper:registerMessageHandlers()    
    MessageManager.registerMessageHandler(MessageDef_MainUI.MSG_UpdateMainUIQueueDelCell, OnReceiveMessage)

    MessageManager.registerMessageHandler(MessageDef_MainUI.MSG_UpdateMainUIQueuePart, OnReceiveMessage)
    MessageManager.registerMessageHandler(MessageDef_MainUI.MSG_UpdateQueuePage, OnReceiveMessage)

    MessageManager.registerMessageHandler(MessageDef_Queue.MSG_Common_ADD, OnReceiveMessage)
    MessageManager.registerMessageHandler(MessageDef_Queue.MSG_Common_UPDATE, OnReceiveMessage)
    MessageManager.registerMessageHandler(MessageDef_Queue.MSG_Common_DELETE, OnReceiveMessage)
    MessageManager.registerMessageHandler(MessageDef_Queue.MSG_Common_CANCEL, OnReceiveMessage)
end

function RAMainUIQueueShowHelper:unregisterMessageHandlers()
    MessageManager.removeMessageHandler(MessageDef_MainUI.MSG_UpdateMainUIQueueDelCell, OnReceiveMessage)

    MessageManager.removeMessageHandler(MessageDef_MainUI.MSG_UpdateMainUIQueuePart, OnReceiveMessage)
    MessageManager.removeMessageHandler(MessageDef_MainUI.MSG_UpdateQueuePage, OnReceiveMessage)

    MessageManager.removeMessageHandler(MessageDef_Queue.MSG_Common_ADD, OnReceiveMessage)
    MessageManager.removeMessageHandler(MessageDef_Queue.MSG_Common_UPDATE, OnReceiveMessage)
    MessageManager.removeMessageHandler(MessageDef_Queue.MSG_Common_DELETE, OnReceiveMessage)
    MessageManager.removeMessageHandler(MessageDef_Queue.MSG_Common_CANCEL, OnReceiveMessage)    
end


function RAMainUIQueueShowHelper:resetData(isClear)
    if self.mCellList ~= nil then
        for cellId, cell in pairs(self.mCellList) do
            cell:Exit()
        end
    end
    if self.mClipNode ~= nil then
        self.mClipNode:removeFromParentAndCleanup(true)
        self.mClipNode = nil
    end
    if self.mNode ~= nil then
        self.mNode:removeAllChildrenWithCleanup(true)
    end
    self.mStencilNode = nil
    self.mCellList = nil
    self.mCellCount = 0
    self.mIsBuyCellShow = false
    if isClear then
        self.mNode = nil
    end

end


function RAMainUIQueueShowHelper:Enter(data)
    self:resetData(true)
    CCLuaLog("RAMainUIQueueShowHelper:Enter")

    self.mCellNeedRemove = {}

    if data ~= nil then
        self.mNode = data.queueNode
    end
    if self.mIsBuyCellShow == nil then
        self.mIsBuyCellShow = false
    end

    EnterFrameMananger.registerEnterFrameHandler(EnterFrameDefine.MainUI.EF_QueueHelperUpdate, self)
    -- self:registerMessageHandlers()   

    self.mClipNode = CCClippingNode:create()
    self.mClipNode:setAnchorPoint(0.5, 0.5)
    self.mClipNode:setPosition(0, 0)
    self.mNode:addChild(self.mClipNode)

    self.mStencilNode = CCSprite:create('empty.png')   
    self.mStencilNode:setAnchorPoint(0, 1)
    self.mStencilNode:setPosition(0, 0)
    self.mClipNode:setStencil(self.mStencilNode)
end


-- 刷新cell的显示，设置为收缩状态
function RAMainUIQueueShowHelper:RefreshQueueAllCells()
     if self.mCellList ~= nil then
        for cellId, cell in pairs(self.mCellList) do
            cell:Exit()
        end
    end
    self.mOneCellAniList = List:New()
    self.mCellList = {}
    self.mCellCount = 0
    self.mCellChangeCount = 0
    self.mCurrCellChangingId = -1
    self.mCurrCellChangingType = CellChangeType.None

    self.mStencilNode:setScaleX(0) 
    self.mStencilNode:setScaleY(0)

    -- -- init data需要二级遍历
    -- local initDatas = nil
    -- if RARootManager.GetIsInWorld() then
    --     initDatas = RAMainUIQueueDataManager:GetWroldAllData(true)
    -- else
    --     initDatas = RAMainUIQueueDataManager:GetCityAllData(true)
    -- end

    -- for i=1,#initDatas do
    --     -- 一级数据
    --     -- local oneData = {
    --     --     isShow = false,
    --     --     queueList = {},
    --     --     realCount = 0, 
    --     --     queueType = queueType,
    --     --     index = index
    --     -- }
    --     local oneData = initDatas[i]
    --     if oneData.isShow then
    --         for j=1, #oneData.queueList do
    --             self.mCellCount = self.mCellCount + 1
    --             local showData = oneData.queueList[j]
    --             local cell = RAMainUIQueueCellNew:new(
    --             {
    --                 mCellId = self.mCellCount
    --             })
    --             local ccbi = cell:Load(self)
    --             local posY = (1 - i) * MainUI_Queue_One_Cell_Height
    --             ccbi:setPositionY(posY)
    --             self.mClipNode:addChild(ccbi)        
    --             self.mCellList[i] = cell
    --         end
    --     end
    -- end

    local max = 5
    print('RAMainUIQueueShowHelper:RefreshQueueAllCells.....max:'..max)
    for i=1,max do
        local cell = RAMainUIQueueCellNew:new(
        {
            mCellId = i
        })
        local ccbi = cell:Load(self)
        local posY = (1 - i) * MainUI_Queue_One_Cell_Height
        ccbi:setPositionY(posY)
        self.mClipNode:addChild(ccbi)        
        self.mCellList[i] = cell
        self.mCellCount = self.mCellCount + 1
    end
    self:_UpdateBtnCell()
    self:_UpdateClipNode()
end

------------------------ Queue Cell Handle ----------------------------------
------------------------------------------------------------------------------


-- 切换或者进入场景的时候会调用，整体进入或者移出cell
function RAMainUIQueueShowHelper:ChangeAllCellShowStatus(isShow, isForce)
    local isForce = isForce or false
    if not isForce then
        if self.mCellChangeCount > 0 then
            CCLuaLog("RAMainUIQueueShowHelper cell is moving count:"..self.mCellChangeCount)
            return
        end
        if self.mIsAllCellIn == isShow then
            return
        end
    end
    self.mIsAllCellIn = isShow
    -- 如果要整体进入的时候，刷新所有数据，先隐藏按钮，播放动画完毕后再显示
    if self.mIsAllCellIn then
        self:RefreshQueueAllCells()
        if self.mBtnCell ~= nil then
            self.mBtnCell:SetVisible(false)
        end
    else
        self:_UpdateBtnCell()
        -- self:_UpdateClipNode()
    end

    local cellCount = 0
    for i=1,#self.mCellList do
        local cell = self.mCellList[i]
        self.mCellChangeCount = self.mCellChangeCount + 1
        cell:RunAni(self.mIsAllCellIn, delayGap * cellCount)
        cellCount = cellCount + 1
    end
end


-- changeType :CellChangeType
function RAMainUIQueueShowHelper:ChangeOneCellShowStatus(cellId, changeType)
    -- 如果当前正在播动画的时候就加到队列里
    if self.mCellChangeCount > 0 or self.mCurrCellChangingType ~= CellChangeType.None then
        local cellAniData = {
            cellId = cellId,
            changeType = changeType
        }
        self.mOneCellAniList:PushEnd(cellAniData)        
        return
    end
    print('RAMainUIQueueShowHelper:ChangeOneCellShowStatus, handle id:'..cellId..'  changeType:'..changeType)    
    self.mCurrCellChangingId = cellId
    self.mCurrCellChangingType = changeType
    self.mCellChangeCount = 0
    if changeType == CellChangeType.Remove then
        local cellRemove = self.mCellList[self.mCurrCellChangingId]
        if cellRemove ~= nil then
            self.mCellChangeCount = self.mCellChangeCount + 1
            cellRemove:RunAni(false, 0)
            
            -- 把大于当前要添加到的索引的所有cell，都向前移一位
            for i=self.mCellCount, self.mCurrCellChangingId + 1, -1 do
                local cellNeedMove = self.mCellList[i]
                local moveToId = i - 1
                if cellNeedMove ~= nil then
                    
                    -- local upAni = RAActionManager:CreateCCBAnimationContainer(
                    --     cellNeedMove:GetCCBFile(), 'RAMainUIQueueCellAni.ccbi', 
                    --     'mCellNode', CCB_UpAni)
                    -- upAni:setAniCallBackHandler(self)        
                    self.mCellChangeCount = self.mCellChangeCount + 1
                    -- upAni:beginAni()                    

                    local callBack = CCCallFunc:create(function()
                        self:_OnOneCellCCBAniComplete(-1)
                    end)
                    local posY = (1 - moveToId) * MainUI_Queue_One_Cell_Height
                    local moveTo = CCMoveTo:create(_CellUpDownAniTime, ccp(0, posY))    
                    cellNeedMove:GetCCBFile():stopAllActions()            
                    cellNeedMove:GetCCBFile():runAction(CCSequence:createWithTwoActions(moveTo, callBack))
                end        
            end

            -- 如果当前是在城内，且不是收缩状态，那么按钮需要向上移
            if not RARootManager.GetIsInWorld() and self.mBtnCell ~= nil and self.mIsOpening then
                -- local btnUpAni = RAActionManager:CreateCCBAnimationContainer(
                --     self.mBtnCell:GetCCBFile(), 'RAMainUIQueueCellAni.ccbi', 
                --     'mCellNode', CCB_UpAni)
                -- btnUpAni:setAniCallBackHandler(self)        
                self.mCellChangeCount = self.mCellChangeCount + 1
                -- btnUpAni:beginAni()

                local callBack = CCCallFunc:create(function()
                    self:_OnOneCellCCBAniComplete(-1)
                end)
                local posY = (1 - self.mCellCount) * MainUI_Queue_One_Cell_Height
                local moveTo = CCMoveTo:create(_CellUpDownAniTime, ccp(0, posY))          
                self.mBtnCell:GetCCBFile():stopAllActions()      
                self.mBtnCell:GetCCBFile():runAction(CCSequence:createWithTwoActions(moveTo, callBack))
            end
            print('remove ani cell changing count = '..self.mCellChangeCount)
        else
            print('want to remove id= '..self.mCurrCellChangingId.. ', but not found')
            self.mCurrCellChangingId = -1
            self.mCurrCellChangingType = CellChangeType.None
            self.mCellChangeCount = 0
        end
    elseif changeType == CellChangeType.Add then   
        -- 延迟播放进入动画的时间，如果没有添加任何一个其他动画的时候，值为0(立即播放)
        local addCellDelay = 0
        -- 把大于等于当前要添加到的索引的所有cell，都向后移一位
        for i=self.mCellCount, self.mCurrCellChangingId, -1 do
            local cellNeedMove = self.mCellList[i]
            local moveToId = i + 1
            if cellNeedMove ~= nil then
                self.mCellList[moveToId] = cellNeedMove
                cellNeedMove.mCellId = moveToId
                -- local downAni = RAActionManager:CreateCCBAnimationContainer(
                --     cellNeedMove:GetCCBFile(), 'RAMainUIQueueCellAni.ccbi', 
                --     'mCellNode', CCB_DownAni)
                -- downAni:setAniCallBackHandler(self)        
                self.mCellChangeCount = self.mCellChangeCount + 1
                -- downAni:beginAni()
                
                local callBack = CCCallFunc:create(function()
                        self:_OnOneCellCCBAniComplete(-1)
                    end)
                local posY = (1 - moveToId) * MainUI_Queue_One_Cell_Height
                local moveTo = CCMoveTo:create(_CellUpDownAniTime, ccp(0, posY))      
                cellNeedMove:GetCCBFile():stopAllActions()                 
                cellNeedMove:GetCCBFile():runAction(CCSequence:createWithTwoActions(moveTo, callBack))
            end            

            addCellDelay = _CellUpDownAniTime
        end

        local cellAdd = RAMainUIQueueCellNew:new(
        {
            mCellId = self.mCurrCellChangingId
        })
        local ccbi = cellAdd:Load(self)
        local posY = (1 - self.mCurrCellChangingId) * MainUI_Queue_One_Cell_Height
        ccbi:setPositionY(posY)
        self.mClipNode:addChild(ccbi)        
        self.mCellList[self.mCurrCellChangingId] = cellAdd
        self.mCellCount = Utilitys.table_count(self.mCellList)

        --需要立即刷新遮罩大小
        self:_UpdateClipNode(false)

        -- 如果当前是在城内，且不是收缩状态，那么按钮需要向下移
        if not RARootManager.GetIsInWorld() and self.mBtnCell ~= nil and self.mIsOpening then
            -- local btnDownAni = RAActionManager:CreateCCBAnimationContainer(
            --     self.mBtnCell:GetCCBFile(), 'RAMainUIQueueCellAni.ccbi', 
            --     'mCellNode', CCB_DownAni)
            -- btnDownAni:setAniCallBackHandler(self)        
            self.mCellChangeCount = self.mCellChangeCount + 1
            -- btnDownAni:beginAni()

            local callBack = CCCallFunc:create(function()
                    self:_OnOneCellCCBAniComplete(-1)
                end)
            local posY = (-self.mCellCount) * MainUI_Queue_One_Cell_Height
            local moveTo = CCMoveTo:create(_CellUpDownAniTime, ccp(0, posY))       
            self.mBtnCell:GetCCBFile():stopAllActions()               
            self.mBtnCell:GetCCBFile():runAction(CCSequence:createWithTwoActions(moveTo, callBack))

            addCellDelay = _CellUpDownAniTime
        end

        

        -- 播放进入动画
        self.mCellChangeCount = self.mCellChangeCount + 1
        cellAdd:RunAni(true, addCellDelay)

        print('add ani cell changing count = '..self.mCellChangeCount)

    elseif changeType == CellChangeType.Update then

    end
end


-- 使用 RAActionManager:CreateCCBAnimationContainer 的回调执行方法
function RAMainUIQueueShowHelper:onCCBContainerCallBack(lastAnimationName, aniCcbfile, isEnd)
    if isEnd then
        self:_OnOneCellCCBAniComplete(-1)
    end
end

function RAMainUIQueueShowHelper:_OnOneCellCCBAniComplete(changeCount)
    if self.mCurrCellChangingType ~= CellChangeType.None and  self.mCellChangeCount > 0 then
        print('RAMainUIQueueShowHelper:_OnOneCellCCBAniComplete curr count:'..self.mCellChangeCount.. ' '..changeCount)
        self.mCellChangeCount = self.mCellChangeCount + changeCount
        if self.mCellChangeCount == 0 then
            print('RAMainUIQueueShowHelper:_OnOneCellCCBAniComplete changing count = 0, type='..self.mCurrCellChangingType)
            if self.mCurrCellChangingType == CellChangeType.Remove then
                self:_LogicAfterOneCellOutAni()
            elseif self.mCurrCellChangingType == CellChangeType.Add then
                self:_LogicAfterOneCellInAni()
            end
        end
    end
end

function RAMainUIQueueShowHelper:_CheckAndPlayOneCellAniInList()
    local nextAni = self.mOneCellAniList:PopFront()
    if nextAni ~= nil then
        print('RAMainUIQueueShowHelper:_CheckAndPlayOneCellAniInList')
        self:ChangeOneCellShowStatus(nextAni.cellId, nextAni.changeType)
    end
end


-- 单个cell的时间轴播放完毕的回调
function RAMainUIQueueShowHelper:CellAniEndCallBack(aniName, cellId)    
    if cellId ~= nil then
        if self.mCurrCellChangingType == CellChangeType.None then
            local checkIsHandle = function(aniName, isIn)
                local isHandle = false
                if isIn and aniName == CCB_InAni then                
                    isHandle = true
                end
                
                if not isIn and aniName == CCB_OutAni then                
                    isHandle = true
                end
                return isHandle
            end
            local isHandle = checkIsHandle(aniName, self.mIsAllCellIn)
            if isHandle then
                self.mCellChangeCount = self.mCellChangeCount - 1
                print("cell handle over, cout:"..self.mCellChangeCount)
            end
            -- 等于0的时候
            if self.mCellChangeCount == 0 then
                print('RAMainUIQueueShowHelper:CellAniEndCallBack over')            
                -- 如果是进入，需要重新刷一下按钮的位置和状态
                if self.mIsAllCellIn then
                    self:_UpdateBtnCell()
                    self:_CheckAndPlayOneCellAniInList()
                else
                    self:_UpdateClipNode()
                end                
            end
        else
            if self.mCurrCellChangingType == CellChangeType.Add then
                -- 如果是单个cell的进入
                if aniName == CCB_InAni then
                    print('RAMainUIQueueShowHelper:CellAniEndCallBack curr count:'..self.mCellChangeCount.. ' -1')
                    self.mCellChangeCount = self.mCellChangeCount - 1
                end
                 -- 等于0的时候
                if self.mCellChangeCount == 0 then
                    print('RAMainUIQueueShowHelper:CellAniEndCallBack changing count = 0, type='..self.mCurrCellChangingType)
                    self:_LogicAfterOneCellInAni()
                end
            elseif self.mCurrCellChangingType == CellChangeType.Remove then
                if aniName == CCB_OutAni then
                    print('RAMainUIQueueShowHelper:CellAniEndCallBack curr count:'..self.mCellChangeCount.. ' -1')
                    self.mCellChangeCount = self.mCellChangeCount - 1
                end
                --移除cell的时候，在这里删除cell
                if self.mCellChangeCount == 0 then                     
                    print('RAMainUIQueueShowHelper:CellAniEndCallBack changing count = 0, type='..self.mCurrCellChangingType)
                    self:_LogicAfterOneCellOutAni()
                end
            else
                print('to dooooooooooooooooo')
            end
        end
    end
end

--添加cell的时候，在动画结束后处理逻辑
--1、当添加第一个cell的时候，
--   可能不存在 RACCBAnimationContainer 的动画，那么直接在CellAniEndCallBack中调用
--2、当添加cell 到其他位置的时候，
--   往往在 RACCBAnimationContainer 的动画结束的回调中调用
function RAMainUIQueueShowHelper:_LogicAfterOneCellInAni()
    self:_UpdateBtnCell(true)
    self.mCurrCellChangingId = -1            
    self.mCurrCellChangingType = CellChangeType.None
    self:_CheckAndPlayOneCellAniInList()
end

--移除cell的时候，在动画结束后处理逻辑
--1、当移除最后一个cell的时候，
--   可能不存在 RACCBAnimationContainer 的动画，那么直接在CellAniEndCallBack中调用
--2、当移除中间的某一个cell的时候，
--   往往在 RACCBAnimationContainer 的动画结束的回调中调用
function RAMainUIQueueShowHelper:_LogicAfterOneCellOutAni()
    print('RAMainUIQueueShowHelper:_LogicAfterOneCellOutAni want to remove :'..self.mCurrCellChangingId)
    local cellRemove = self.mCellList[self.mCurrCellChangingId]
    if cellRemove == nil then 
        print('iiiiiiiiiiiiddddddddddddddddddd not found!!!!!!!!!!')        
    else
        -- cellRemove:Exit()        
        table.insert(self.mCellNeedRemove, cellRemove)
        MessageManager.sendMessage(MessageDef_MainUI.MSG_UpdateMainUIQueueDelCell)
    end
    self.mCellList[self.mCurrCellChangingId] = nil                
    -- 把大于当前要添加到的索引的所有cell，都向前移一位
    for i=self.mCurrCellChangingId + 1, self.mCellCount do
        local cellNeedMove = self.mCellList[i]
        local moveToId = i - 1
        if cellNeedMove ~= nil then
            self.mCellList[moveToId] = cellNeedMove
            cellNeedMove.mCellId = moveToId
        end
    end
    --移除最后一个重复cell
    self.mCellList[self.mCellCount] = nil
    self.mCellCount = Utilitys.table_count(self.mCellList)
    --需要立即刷新遮罩大小和按钮状态
    self:_UpdateClipNode(false)
    self:_UpdateBtnCell(true)

    self.mCurrCellChangingId = -1            
    self.mCurrCellChangingType = CellChangeType.None
    self:_CheckAndPlayOneCellAniInList()
end


function RAMainUIQueueShowHelper:CheckAndRemoveCellNeed()
    print('function RAMainUIQueueShowHelper:CheckAndRemoveCellNeed()')
    if self.mCellNeedRemove ~= nil then        
        for _, cell in pairs(self.mCellNeedRemove) do
            if cell ~= nil then
                cell:Exit()
                print('remove &&&&&&&&&& one cell')
            end
        end
    end
end


------------------------ Queue Cell Handle end -------------------------------
------------------------------------------------------------------------------

------------------------ Button Cell Handle ----------------------------------
------------------------------------------------------------------------------
-- 返回是否显示按钮cell，按钮cell的位置（也是遮罩的大小）
function RAMainUIQueueShowHelper:_GetBtnCellShowData()
    local posY = 0
    local isShowBtn = false
    if self.mCellCount > 0 then
        posY = -self.mCellCount * MainUI_Queue_One_Cell_Height
    end
    if RARootManager.GetIsInWorld() then
        return false, posY
    end

    if self.mCellCount > MainUI_Queue_Cell_Show_Count then
        if not self.mIsOpening then
            posY = -MainUI_Queue_Cell_Show_Count * MainUI_Queue_One_Cell_Height            
        end
        isShowBtn = true
    else
        isShowBtn = false
    end
    if not self.mIsAllCellIn then
        isShowBtn = false
    end
    return isShowBtn, posY
end

-- 检查并创建、刷新点击按钮cell
function RAMainUIQueueShowHelper:_UpdateBtnCell(isIgnorePos)
    local isIgnorePos = isIgnorePos or false
    if self.mNode == nil then return end 
    if self.mBtnCell == nil then
        self.mBtnCell = RAMainUIQueueBtnCell:new()
        local ccbi = self.mBtnCell:Load(self)        
        self.mNode:addChild(ccbi)
        self.mBtnCell:RunAni(self.mIsOpening, true)
    end
    local isShow, posY = self:_GetBtnCellShowData()
    self.mBtnCell:SetVisible(isShow)
    if not isIgnorePos then
        self.mBtnCell:SetPositionY(posY)
    end
end
-- 刷新遮罩大小
function RAMainUIQueueShowHelper:_UpdateClipNode(isAni)
    if self.mClipNode == nil or self.mStencilNode == nil then return end
    local isShow, posY = self:_GetBtnCellShowData()
    posY = math.abs(posY)
    self.mStencilNode:stopAllActions()
    self.mStencilNode:setScaleX(MainUI_Queue_One_Cell_Width) 
    if isAni then
        local scaleAction = CCScaleTo:create(_ClipNodeActionTimeNeed, MainUI_Queue_One_Cell_Width, posY)
        self.mStencilNode:runAction(scaleAction)
    else
        self.mStencilNode:setScaleY(posY)
        self.mBtnCell:SetClickEnable(true)
    end
end
--点击按钮切换收缩和放开状态调用的方法
function RAMainUIQueueShowHelper:ChangeCellOpenState()
    if RARootManager.GetIsInWorld() then
        self.mIsOpening = false
    else
        -- 先设置状态，再播放时间轴和遮罩动画
        self.mIsOpening = not self.mIsOpening
        -- 需要打开的时候，先设置位置，再播两个动画
        if self.mIsOpening then
            self:_UpdateBtnCell()
        end
        self.mBtnCell:SetClickEnable(false)
        self.mBtnCell:RunAni(self.mIsOpening)        
        self:_UpdateClipNode(true)
    end
end
-- 按钮点击后转圈动画结束后的回调
function RAMainUIQueueShowHelper:BtnCellAniEndCallBack(aniName)
    if self.mIsOpening and aniName == CCB_Btn_OpenAni then
        self.mBtnCell:SetClickEnable(true)
    end

    if not self.mIsOpening and aniName == CCB_Btn_CloseAni then
        --关闭的时候，先播完动画，再来设置位置
        self:_UpdateBtnCell()
        self.mBtnCell:SetClickEnable(true)        
    end
end
------------------------------------------------------------------------------
------------------------ Button Cell Handle End ------------------------------

function RAMainUIQueueShowHelper:EnterFrame()
    -- CCLuaLog("RAMainUIQueueShowHelper:EnterFrame")
    -- self.mLastUpdateTime = self.mLastUpdateTime + common:getFrameTime()
    -- if self.mLastUpdateTime > 1 then
    --     self.mLastUpdateTime = 0
    --     if self.mCellNeedUpdate then
    --         for index, isUpdate in pairs(self.mCellNeedUpdate) do
    --             local cell = self.mCellList[index]
    --             if isUpdate and cell ~= nil then
    --                 cell:secondUpdate()
    --             end
    --         end
    --     end
    -- end
end

function RAMainUIQueueShowHelper:Exit()
    CCLuaLog("RAMainUIQueueShowHelper:Exit")
    self:unregisterMessageHandlers()
    EnterFrameMananger.removeEnterFrameHandler(EnterFrameDefine.MainUI.EF_QueueHelperUpdate, self)
    self:resetData(true)
end



return RAMainUIQueueShowHelper