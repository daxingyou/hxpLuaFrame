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


local RAMainUIQueueHelper = {}

local createNewQueueCell = nil
local OnReceiveMessage = nil
local CCB_InAni = "InAni"
local CCB_OutAni = "OutAni"
local CCB_KeepIn = "KeepIn"
local CCB_KeepOut = "KeepOut"
local CCB_UpAni = "UpAni"
local CCB_DownAni = "DownAni"

local delayGap = 0.05

RAMainUIQueueHelper.mBuyNode = nil
RAMainUIQueueHelper.mNode = nil

RAMainUIQueueHelper.mCellList = nil

RAMainUIQueueHelper.mIsCellIn = false
RAMainUIQueueHelper.mChangeCount = 0

RAMainUIQueueHelper.mIsBuyCellShow = false
RAMainUIQueueHelper.mBuyCell = nil

-- 用于每秒调用一次cell的update
RAMainUIQueueHelper.mLastUpdateTime = 0
RAMainUIQueueHelper.mCellNeedUpdate = nil

RAMainUIQueueHelper.mSingleCellAniTargetIndex = -1
-- 0静止；1进入；-1移出
RAMainUIQueueHelper.mSingleCellAniStatus = 0
RAMainUIQueueHelper.mSingleCellAniCount = 0
RAMainUIQueueHelper.mSingleCellAniList = List:New()

OnReceiveMessage = function(message)    
    CCLuaLog("RAMainUIPage OnReceiveMessage id:"..message.messageID)

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
                RAMainUIQueueHelper:ChangeCellUpdate(updateData)
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
             RAMainUIQueueHelper:HandleQueueStatusChange(queueType)
             return
        end

        -- 获得伤兵会影响队列显示
        if message.queueType ~= nil then
            RAMainUIQueueHelper:HandleQueueStatusChange(message.queueType)
        end
        return
    end
    local queueId = message.queueId
    local queueType = message.queueType
    if message.messageID == MessageDef_Queue.MSG_Common_ADD then
        CCLuaLog("MessageDef_Queue MSG_Common_ADD")
        RAMainUIQueueHelper:HandleQueueStatusChange(queueType, queueId)
    end

    if message.messageID == MessageDef_Queue.MSG_Common_UPDATE then
        CCLuaLog("MessageDef_Queue MSG_Common_UPDATE")        
        RAMainUIQueueHelper:HandleQueueStatusChange(queueType, queueId)
    end

    if message.messageID == MessageDef_Queue.MSG_Common_DELETE then
        CCLuaLog("MessageDef_Queue MSG_Common_DELETE")        
        RAMainUIQueueHelper:HandleQueueStatusChange(queueType, queueId)
    end

    if message.messageID == MessageDef_Queue.MSG_Common_CANCEL then
        CCLuaLog("MessageDef_Queue MSG_Common_CANCEL")        
        RAMainUIQueueHelper:HandleQueueStatusChange(queueType, queueId)
    end
end

function RAMainUIQueueHelper:registerMessageHandlers()
    MessageManager.registerMessageHandler(MessageDef_MainUI.MSG_UpdateMainUIQueuePart, OnReceiveMessage)
    MessageManager.registerMessageHandler(MessageDef_MainUI.MSG_UpdateQueuePage, OnReceiveMessage)

    MessageManager.registerMessageHandler(MessageDef_Queue.MSG_Common_ADD, OnReceiveMessage)
    MessageManager.registerMessageHandler(MessageDef_Queue.MSG_Common_UPDATE, OnReceiveMessage)
    MessageManager.registerMessageHandler(MessageDef_Queue.MSG_Common_DELETE, OnReceiveMessage)
    MessageManager.registerMessageHandler(MessageDef_Queue.MSG_Common_CANCEL, OnReceiveMessage)
end

function RAMainUIQueueHelper:unregisterMessageHandlers()
    MessageManager.removeMessageHandler(MessageDef_MainUI.MSG_UpdateMainUIQueuePart, OnReceiveMessage)
    MessageManager.removeMessageHandler(MessageDef_MainUI.MSG_UpdateQueuePage, OnReceiveMessage)

    MessageManager.removeMessageHandler(MessageDef_Queue.MSG_Common_ADD, OnReceiveMessage)
    MessageManager.removeMessageHandler(MessageDef_Queue.MSG_Common_UPDATE, OnReceiveMessage)
    MessageManager.removeMessageHandler(MessageDef_Queue.MSG_Common_DELETE, OnReceiveMessage)
    MessageManager.removeMessageHandler(MessageDef_Queue.MSG_Common_CANCEL, OnReceiveMessage)    
end


function RAMainUIQueueHelper:resetData(isClear)
    if isClear and self.mCellList ~= nil then
        for cellId, cell in pairs(self.mCellList) do
            cell:exit()
        end
    end
    if self.mBuyNode ~= nil then
        self.mBuyNode:removeAllChildrenWithCleanup(true)
    end
    if self.mNode ~= nil then
        self.mNode:removeAllChildrenWithCleanup(true)
    end
    self.mBuyNode = nil
    self.mNode = nil

    self.mCellList = nil
    self.mIsCellIn = false
    self.mChangeCount = 0

    self.mIsBuyCellShow = false
    self.mBuyCell = nil

    self.mLastUpdateTime = 0
    self.mCellNeedUpdate = nil

    self.mSingleCellAniTargetIndex = -1
    self.mSingleCellAniStatus = 0
    self.mSingleCellAniCount = 0
    self.mSingleCellAniList = List:New()
end


function RAMainUIQueueHelper:Enter(data)
    self:resetData()
    self.mCellList = {}
    CCLuaLog("RAMainUIQueueHelper:Enter")

    if data ~= nil then
        self.mBuyNode = data.buyNode
        self.mNode = data.queueNode
        self.mIsBuyCellShow = data.isBuyCellShow
    end
    if self.mIsBuyCellShow == nil then
        self.mIsBuyCellShow = false
    end
    self.mIsBuyCellShow = false
    -- 购买队列，暂时不添加
    -- self.mBuyCell = createNewQueueCell({
    --         label = "buy cell",
    --         cellId = -1
    --         })
    -- local buyCCBI = self.mBuyCell:load()
    -- self.mBuyNode:addChild(buyCCBI)
    -- self.mBuyCell:updateCell()

    EnterFrameMananger.registerEnterFrameHandler(EnterFrameDefine.MainUI.EF_QueueHelperUpdate, self)
    self:registerMessageHandlers()    

    -- self:RefreshQueueAllCells()
end

function RAMainUIQueueHelper:RefreshQueueAllCells()
    if isClear and self.mCellList ~= nil then
        for cellId, cell in pairs(self.mCellList) do
            cell:exit()
        end
    end
    self.mCellList = {}
    if self.mBuyNode ~= nil then
        self.mBuyNode:removeAllChildrenWithCleanup(true)
    end
    if self.mNode ~= nil then
        self.mNode:removeAllChildrenWithCleanup(true)
    end

    local lastY = 0
    local queueShowDataMap = RAQueueManager:getQueueShowDataMap(true)
    for titleIndex, showData in ipairs(queueShowDataMap) do
        if showData.isShow then
            local cell = createNewQueueCell({                
                mIndex = titleIndex,
                mQueueType = showData.queueType,
            })
            local ccbi = cell:load()
            self.mNode:addChild(ccbi)
            cell:updateCell(showData.cellCount, showData.cellMap)
            ccbi:setPositionY(lastY)
            lastY = lastY - ccbi:getContentSize().height
            self.mCellList[titleIndex] = cell
        end
    end
end

-- 增删改一个队列的时候进行处理
function RAMainUIQueueHelper:HandleQueueStatusChange(queueType, queueId)
    if self.mCellList == nil then return false end
    if queueType == nil then return false end
    -- 先尝试从本地取cell
    local targetCell = nil
    for k, cellHandler in pairs(self.mCellList) do
        if cellHandler ~= nil and cellHandler.mQueueType == queueType then
            targetCell = cellHandler
            break
        end
    end

    -- 刷新数据
    local queueShowDataMap = RAQueueManager:getQueueShowDataMap(true)
    local targetIndex = -1
    local targetShowData = nil
    for titleIndex, showData in ipairs(queueShowDataMap) do
        if showData.queueType == queueType then
            targetIndex = titleIndex
            targetShowData = showData
            break
        end
    end
    if targetIndex == -1 or targetShowData == nil then return end

    -- 需要显示的时候，判断是直接刷新还是新增
    if targetShowData.isShow then
        if targetCell ~= nil then
            targetCell:updateCell(targetShowData.cellCount, targetShowData.cellMap)
        else
            --add cell
             local cell = createNewQueueCell({                
                mIndex = targetIndex,
                mQueueType = targetShowData.queueType,
            })
            local ccbi = cell:load()
            cell:updateCell(targetShowData.cellCount, targetShowData.cellMap)
            local cellHeight = ccbi:getContentSize().height
            local cellY = 0
            for oldIndex, oldCell in pairs(self.mCellList) do
                if targetIndex > oldIndex then
                    cellY = cellY - cellHeight
                end
            end
            ccbi:setPositionY(cellY)
            self.mNode:addChild(ccbi)            
            self.mCellList[targetIndex] = cell

            self:ChangeOneCellShowStatus(targetIndex, true)
        end
    else
        -- remove cell
        if targetCell ~= nil then
            self:ChangeOneCellShowStatus(targetCell.mIndex, false)
        end
    end
    return false
end




-- 更改一个cell是否需要进行帧刷新
function RAMainUIQueueHelper:ChangeCellUpdate(updateData)
     -- 0为刷新，1为新增，-1为删除
    local updateType = updateData.updateType
    -- 要操控的cell index
    local cellIndex = updateData.cellIndex or -1
    if updateType == 0 then
        if self.mCellNeedUpdate == nil then
            self.mCellNeedUpdate = {}
        end
        if cellIndex ~= -1 then
            local isSecondUpdate = updateData.isUpdate or false
            if not isSecondUpdate then
                self.mCellNeedUpdate[cellIndex] = nil
            else
                self.mCellNeedUpdate[cellIndex] = true
            end
        end
    end
end

function RAMainUIQueueHelper:EnterFrame()
    -- CCLuaLog("RAMainUIQueueHelper:EnterFrame")
    self.mLastUpdateTime = self.mLastUpdateTime + common:getFrameTime()
    if self.mLastUpdateTime > 1 then
        self.mLastUpdateTime = 0
        if self.mCellNeedUpdate then
            for index, isUpdate in pairs(self.mCellNeedUpdate) do
                local cell = self.mCellList[index]
                if isUpdate and cell ~= nil then
                    cell:secondUpdate()
                end
            end
        end
    end
end

function RAMainUIQueueHelper:GetShowStatus()
    return self.mIsCellIn
end

-- 使用 RAActionManager:CreateCCBAnimationContainer 的回调执行方法
function RAMainUIQueueHelper:onCCBContainerCallBack(lastAnimationName, aniCcbfile, isEnd)
    if isEnd then
        self:onSingleCellAniComplete(-1)
    end
end

function RAMainUIQueueHelper:onSingleCellAniComplete(changeCount)
    if self.mSingleCellAniStatus ~= 0 and  self.mSingleCellAniCount > 0 then
        self.mSingleCellAniCount = self.mSingleCellAniCount + changeCount
        if self.mSingleCellAniCount == 0 then
            if self.mSingleCellAniStatus == -1 then
                self.mCellList[self.mSingleCellAniTargetIndex] = nil
            end

            self.mSingleCellAniStatus = 0
            self.mSingleCellAniTargetIndex = -1            
            self:checkAndPlaySingleCellListAni()
        end
    end
end

function RAMainUIQueueHelper:checkAndPlaySingleCellListAni()
    local nextAni = self.mSingleCellAniList:PopFront()
    if nextAni ~= nil then
        self:ChangeOneCellShowStatus(nextAni.cellIndex, nextAni.isShow)
    end
end

-- 删除或者添加一个队列的时候调用接口如下
-- 需要实现队列机制，同时只能播放一个cmd
function RAMainUIQueueHelper:ChangeOneCellShowStatus(cellIndex, isShow)
    local targetHandler = self.mCellList[cellIndex]
    if targetHandler == nil then return end
    -- 如果当前正在播动画的时候就加到队列里
    if self.mSingleCellAniStatus ~= 0 or self.mChangeCount > 0 then
        local cellAniData = {
            cellIndex = cellIndex,
            isShow = isShow
        }
        self.mSingleCellAniList:PushEnd(cellAniData)        
        return
    end
    
    self.mSingleCellAniTargetIndex = cellIndex
    -- 移出
    if not isShow then
        self.mSingleCellAniStatus = -1        
        self.mSingleCellAniCount = 0
        targetHandler:runAni(false, 0.1)
        self.mSingleCellAniCount = self.mSingleCellAniCount + 1
        for k,cellHandler in pairs(self.mCellList) do
            if k > self.mSingleCellAniTargetIndex then
                local upAni = RAActionManager:CreateCCBAnimationContainer(cellHandler:getCCBFile(), 'RAMainUIQueueCellAniNew.ccbi', 'mCellNode', CCB_UpAni)
                upAni:setAniCallBackHandler(self)        
                upAni:beginAni()
                self.mSingleCellAniCount = self.mSingleCellAniCount + 1    
            end
        end
    end

    -- 添加
    if isShow then
        self.mSingleCellAniStatus = 1        
        self.mSingleCellAniCount = 0
        targetHandler:runAni(true, 0.1)
        self.mSingleCellAniCount = self.mSingleCellAniCount + 1
        for k,cellHandler in pairs(self.mCellList) do
            if k > self.mSingleCellAniTargetIndex then
                local downAni = RAActionManager:CreateCCBAnimationContainer(cellHandler:getCCBFile(), 'RAMainUIQueueCellAniNew.ccbi', 'mCellNode', CCB_DownAni)
                downAni:setAniCallBackHandler(self)        
                downAni:beginAni()
                self.mSingleCellAniCount = self.mSingleCellAniCount + 1
            end
        end
    end
end

-- 切换或者进入场景的时候会调用，整体进入或者移出cell
function RAMainUIQueueHelper:ChangeCellShowStatus(isShow, isAni)
    if self.mSingleCellAniStatus ~= 0 and not isShow then
        CCLuaLog("RAMainUIQueueHelper cell is moving mSingleCellAniStatus:"..self.mSingleCellAniStatus)
        return
    end
    if self.mChangeCount > 0 then
        CCLuaLog("RAMainUIQueueHelper cell is moving count:"..self.mChangeCount)
        return
    end
    if self.mIsCellIn == isShow then
        return
    end

    self.mIsCellIn = isShow
    local cellCount = 0

    if self.mIsCellIn then
        self:RefreshQueueAllCells()
    end

    -- buy cell
    if self.mIsBuyCellShow and self.mBuyCell ~= nil then
        self.mChangeCount = 1
        self.mBuyCell:runAni(self.mIsCellIn, delayGap * cellCount)     
        cellCount = cellCount + 1   
    end

    -- normal cell    
    for cellId, cell in pairs(self.mCellList) do
        cell:runAni(self.mIsCellIn, delayGap * cellCount)
        cellCount = cellCount + 1

        self.mChangeCount = self.mChangeCount + 1
    end
end

function RAMainUIQueueHelper:CellAniEnd(aniName, cellId, cell)
    -- 单个cell完成动作的时候
    if self.mSingleCellAniStatus ~= 0 and cellId ~= nil then
        if self.mSingleCellAniStatus == 1 and aniName == CCB_InAni then
            self:onSingleCellAniComplete(-1)
        end
        if self.mSingleCellAniStatus == -1 and aniName == CCB_OutAni then
            self:onSingleCellAniComplete(-1)
        end
    end

    -- 整体动作的逻辑
    if cellId ~= nil then
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
        local isHandle = checkIsHandle(aniName, self.mIsCellIn)
        if isHandle then
            if cellId < 0 then
                if cell == self.mBuyCell then
                    self.mChangeCount = self.mChangeCount - 1
                    CCLuaLog("buy cell handle over, cout:"..self.mChangeCount)
                end
            else
                local cellTar = self.mCellList[cellId]
                if cellTar == cell then
                    self.mChangeCount = self.mChangeCount - 1
                    CCLuaLog("cell handle over, cout:"..self.mChangeCount)
                end
            end
        end
        -- 等于0的时候
        if self.mChangeCount == 0 then
            self:checkAndPlaySingleCellListAni()
        end
    end
end


function RAMainUIQueueHelper:Exit()
    CCLuaLog("RAMainUIQueueHelper:Exit")
    self:unregisterMessageHandlers()
    EnterFrameMananger.removeEnterFrameHandler(EnterFrameDefine.MainUI.EF_QueueHelperUpdate, self)
    self:resetData(true)
end

---------------Queue cell---------------

local RAMainUIQueueCell = 
{
    mIndex = -1,
    mQueueType = 0,
    -- mCurCount = 0,
    mCurrId = '',

    new = function(self, o)
        o = o or {}
        setmetatable(o,self)
        self.__index = self    
        return o
    end,

    getCCBName = function(self)
        return "RAMainUIQueueNode.ccbi"
    end,
    load = function(self, aniCallBack)
        local ccbi = UIExtend.loadCCBFile(self:getCCBName(), self)
        ccbi:runAnimation(CCB_KeepOut)
        self.aniCallBack = aniCallBack

        -- 图片不会变
        UIExtend.addSpriteToNodeParent(self:getCCBFile(), 'mQueuePic', RAMainUIHelper.QueueIconMap[self.mQueueType])
        UIExtend.setNodesVisible(self:getCCBFile(),{                            
                mDesLabel = false
            })
        return ccbi
    end,


    -- mCurCount = showData.cellCount,
    -- 队列新增、删除、更新，都需要调用的方法
    updateCell = function(self, cellCount, cellMap)        
        UIExtend.setNodesVisible(self:getCCBFile(),{mDesLabel = false})
        local str = RAStringUtil:getLanguageString(RAMainUIHelper.QueueNameMap[self.mQueueType])
        str = ""
        if self.mQueueType ~= Const_pb.SCIENCE_QUEUE and 
                self.mQueueType ~= Const_pb.CURE_QUEUE and
                self.mQueueType ~= Const_pb.BUILDING_DEFENER then
            local currCount = cellCount
            local maxCount = RAQueueManager:getQueueMaxCounts(self.mQueueType)
            str = str .. RAStringUtil:getLanguageString('@PartedTwoParams', currCount, maxCount)
        end
        UIExtend.setCCLabelString(self:getCCBFile(), 'mQueueNum', str)

        self.mCurrId = ''
         -- 设置队列时间            
        self.mStartTime = 0
        self.mEndTime = 0
        self.mLastTime = 0
        for i, queueItem in pairs(cellMap) do
            local queueId = queueItem.id
             -- 特殊处理行军
            if self.mQueueType == Const_pb.MARCH_QUEUE then
                local RAMarchDataManager = RARequire('RAMarchDataManager')
                local marchData = RAMarchDataManager:GetMarchDataById(queueId)
                if marchData ~= nil then
                    -- 取最近要完成的行军
                    if self.mEndTime == 0 or marchData.endTime / 1000 < self.mEndTime then
                        if marchData.marchStatus == World_pb.MARCH_STATUS_WAITING then
                            self.mStartTime = marchData.massReadyTime / 1000
                            self.mEndTime = marchData.startTime / 1000
                            self.mLastTime = os.difftime(self.mEndTime, common:getCurTime())
                            self.mCurrId = marchData.marchId
                        else
                            self.mStartTime = marchData.startTime / 1000
                            self.mEndTime = marchData.endTime / 1000
                            self.mLastTime = os.difftime(self.mEndTime, common:getCurTime())
                            self.mCurrId = marchData.marchId
                        end
                    end
                end
            end
            local queueData = RAQueueManager:getQueueData(self.mQueueType, queueId)
            if queueData ~= nil then
                -- 取最近要完成的队列
                if self.mEndTime == 0 or queueData.endTime < self.mEndTime then
                    self.mStartTime = queueData.startTime
                    self.mEndTime = queueData.endTime
                    self.mLastTime = os.difftime(self.mEndTime, common:getCurTime())
                    self.mCurrId = queueItem.id
                end
            end
        end
        if self.mCurrId ~= '' then
            local updateData = {}
            updateData.updateType = 0
            updateData.cellIndex = self.mIndex
            updateData.isUpdate = true
            MessageManager.sendMessage(MessageDef_MainUI.MSG_UpdateMainUIQueuePart,{updateData = updateData})        
        end
        UIExtend.setCCLabelString(self:getCCBFile(), "mQueueTime", "")

        self:updateCellByTime(self.mLastTime)
    end,

    secondUpdate = function(self)
        local ccbfile = self:getCCBFile()
        if ccbfile == nil then return end
        if self.mStartTime > 0 then
            local lastTime = os.difftime(self.mEndTime, common:getCurTime())
            if self.mLastTime > lastTime then
                if lastTime <= 0 then
                    CCLuaLog('RAMainUIQueueCell:enterFrame error!!!!  lastTime = '.. lastTime)
                    lastTime = 0
                    local updateData = {}
                    updateData.updateType = 0
                    updateData.cellIndex = self.mIndex
                    updateData.isUpdate = false
                    MessageManager.sendMessage(MessageDef_MainUI.MSG_UpdateMainUIQueuePart,{updateData = updateData})
                end
                
                self:updateCellByTime(lastTime)
            end
        end        
    end,

    updateCellByTime = function(self, lastTime)
        local ccbfile = self:getCCBFile()
        if ccbfile == nil then return end
        if lastTime > 0 then
            local RAPlayerInfoManager = RARequire('RAPlayerInfoManager')
            local freeTime = RAPlayerInfoManager.getQueueFreeTime(nil, self.mQueueType)
            local isFree = freeTime >= lastTime
            UIExtend.setNodesVisible(self:getCCBFile(),{                            
                mDesLabel = isFree
            })
            local tmpStr = Utilitys.createTimeWithFormat(lastTime)
            UIExtend.setCCLabelString(ccbfile, "mQueueTime", tmpStr)
            self.mLastTime = lastTime
        else
            UIExtend.setCCLabelString(ccbfile, "mQueueTime", "")
        end
    end,

    getCCBFile = function(self)
        return self.ccbfile
    end,

    onCellClick = function(self)
        local queueType = self.mQueueType
        RARootManager.OpenPage("RAMainUIQueuePage", {queueType = queueType}, false, true, true)
        -- 测试移出
        -- local ani = RAActionManager:CreateCCBAnimationContainer(
        --     self:getCCBFile(), 'RAMainUIQueueCellAni.ccbi', 
        --     'mCellNode', 'UpAni', function(lastAnimationName, ccbfile, isEnd)
        --         print("RAMainUIQueueCell onCellClick:"..lastAnimationName)
        --     end)
        -- ani:beginAni()

        -- 音效 clickMenuEject
        common:playEffect("click_main_botton_banner")
    end,

    getAnimationCmd = function(self, name)
        local ccbi = self:getCCBFile()
        return function()
            ccbi:runAnimation(name)
        end
    end,

    runAni = function(self, isShow, delay)
        if isShow then
            performWithDelay(self:getCCBFile(), self:getAnimationCmd(CCB_InAni), delay)
        else
            performWithDelay(self:getCCBFile(), self:getAnimationCmd(CCB_OutAni), delay)
        end    
    end,

    OnAnimationDone = function(self, ccbfile)
        local lastAnimationName = ccbfile:getCompletedAnimationName()           
        if self.aniCallBack then
            self.aniCallBack(lastAnimationName)
        end
        RAMainUIQueueHelper:CellAniEnd(lastAnimationName, self.mIndex, self)
    end,

    exit = function(self)
        UIExtend.unLoadCCBFile(self)
    end
}



createNewQueueCell = function(data)
    return RAMainUIQueueCell:new(data)
end


return RAMainUIQueueHelper