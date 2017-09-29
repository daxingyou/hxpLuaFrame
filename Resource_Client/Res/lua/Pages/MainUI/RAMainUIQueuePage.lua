-- RAMainUIQueuePage

RARequire('BasePage')
local UIExtend = RARequire('UIExtend')
local RAMainUIHelper = RARequire('RAMainUIHelper')
local RAStringUtil = RARequire('RAStringUtil')
local RARootManager = RARequire('RARootManager')
local RAQueueManager = RARequire('RAQueueManager')
local RABuildManager = RARequire('RABuildManager')
local RACoreDataManager = RARequire('RACoreDataManager')
local Utilitys = RARequire('Utilitys')
local common = RARequire('common')
local Const_pb = RARequire('Const_pb')

local RAMainUIQueuePage = BaseFunctionPage:new(...)
local OnReceiveMessage = nil

local CCB_InAni = "InAni"
local CCB_OutAni = "OutAni"
local CCB_KeepIn = "KeepIn"
local CCB_KeepOut = "KeepOut"

-- 跳转到的title cell type
RAMainUIQueuePage.mTargetType = -1

------ queue cell
local RAMainUIQueueDetailCell = 
{
    mQueueType = -1,
    mQueueId = -1,
    mStartTime = -1,
    mEndTime = -1,    
    mIsQueueSpare = false,  -- 队列是否闲置
    mBarLabelKey = '',
    mIsMarchMassJoinSpec = false,
    new = function(self, o)
        o = o or {}
        setmetatable(o,self)
        self.__index = self    
        return o
    end,

    getCCBName = function(self)
        return "RAMainUIQueueCell.ccbi"
    end,

    onRefreshContent = function(self, cellRoot)
        CCLuaLog("RAMainUIQueueDetailCell:onRefreshContent")
        -- local spendTime = math.random(10000)
        -- self.spendTime = spendTime
        
        -- self.startTime = common:getCurTime()
        -- self.selfCell = cellRoot
        -- self.lastTime = -1
        local ccbfile = cellRoot:getCCBFileNode()
        if ccbfile == nil then
            return
        end
        self.mIsMarchMassJoinSpec = false
        self.mBarLabelKey = ''
        UIExtend.setControlButtonTitle(ccbfile, 'mFreeBtn', '@Free')
        local isDefaultShow = true
        -- 特殊处理行军
        if self.mQueueType == Const_pb.MARCH_QUEUE then
            local icon, name = RAMainUIHelper:getQueueCellCfg(self.mQueueType, queueData)
            UIExtend.removeSpriteFromNodeParent(ccbfile, 'mIconNode')
            UIExtend.addSpriteToNodeParent(ccbfile, 'mIconNode', icon, 1)

            local RAMarchDataManager = RARequire('RAMarchDataManager')
            local marchData = RAMarchDataManager:GetMarchDataById(self.mQueueId)
            if marchData ~= nil then
                isDefaultShow = false                
                
                local World_pb = RARequire("World_pb")
                if marchData.marchStatus == World_pb.MARCH_STATUS_MARCH or
                    marchData.marchStatus == World_pb.MARCH_STATUS_RETURN_BACK then
                    -- 出征或者回程过程中，显示倒计时，按钮为加速
                    self.mStartTime = marchData.startTime / 1000
                    self.mEndTime = marchData.endTime / 1000
                    self.mLastTime = marchData:GetLastTime()
                    self:refreshTime(cellRoot, self.mLastTime)
                    if marchData.marchStatus == World_pb.MARCH_STATUS_MARCH then
                        self.mBarLabelKey = '@Marching'
                    else
                        self.mBarLabelKey = '@Retruning'
                    end
                    UIExtend.setControlButtonTitle(ccbfile, 'mBlueBtn', '@QueueSpeedUp')
                    cellRoot:setIsScheduleUpdate(true)
                elseif marchData.marchStatus == World_pb.MARCH_STATUS_MARCH_COLLECT then
                    --采集中
                    self.mStartTime = marchData.resStartTime / 1000
                    self.mEndTime = marchData.resEndTime / 1000
                    self.mLastTime = os.difftime(self.mEndTime, common:getCurTime())
                    self.mBarLabelKey = '@Collecting'
                    self:refreshTime(cellRoot, self.mLastTime)
                    UIExtend.setControlButtonTitle(ccbfile, 'mBlueBtn', '@ViewDetails')
                    cellRoot:setIsScheduleUpdate(true)
                elseif marchData.marchStatus == World_pb.MARCH_STATUS_MARCH_QUARTERED then
                    -- 驻扎中
                    self.mStartTime = -1
                    self.mBarLabelKey = '@Stationed'
                    UIExtend.setControlButtonTitle(ccbfile, 'mBlueBtn', '@ViewDetails')
                    UIExtend.setCCLabelString(ccbfile, 'mCellLabel', _RALang(self.mBarLabelKey))
                    UIExtend.setNodesVisible(ccbfile, {
                        mBlueBar = false,
                        mBlueBtn = true,
                        mGreenBar = false,
                        mFreeBtn = false,
                        mFreeAniCCB = false,
                        mBarAniCCB = false,
                    })
                elseif marchData.marchStatus == World_pb.MARCH_STATUS_WAITING then
                    --集结中                    
                    -- self.mStartTime = marchData.massReadyTime / 1000
                    -- self.mEndTime = marchData.startTime / 1000
                    -- self.mLastTime = os.difftime(self.mEndTime, common:getCurTime())
                    -- self.mBarLabelKey = '@Assemblying'

                    -- local btnLabelStr = '@ViewDetails'
                    -- -- 特殊处理，如果是自己在集结等待中，可能队长已经发车，这时候要显示的是队长的相关数据
                    -- if self.mLastTime <= 0 and marchData.marchType == World_pb.MASS_JOIN then
                    --     self.mStartTime = marchData.startTime / 1000
                    --     self.mEndTime = marchData.endTime / 1000
                    --     self.mLastTime = os.difftime(self.mEndTime, common:getCurTime())
                    --     self.mBarLabelKey = '@Marching'
                    --     btnLabelStr = '@QueueSpeedUp'
                    --     self.mIsMarchMassJoinSpec = true
                    -- end
                    -- self:refreshTime(cellRoot, self.mLastTime)
                    -- UIExtend.setControlButtonTitle(ccbfile, 'mBlueBtn', btnLabelStr)
                    -- cellRoot:setIsScheduleUpdate(true)

                    -- 直接找队长的行军数据，没有的话就不处理了
                    local btnLabelStr = '@ViewDetails'
                    local leaderMarchData = RAMarchDataManager:GetTeamLeaderMarchData(self.mQueueId)
                    if leaderMarchData ~= nil then
                        --集结等待中                    
                        if leaderMarchData.marchStatus == World_pb.MARCH_STATUS_WAITING then
                            self.mStartTime = leaderMarchData.massReadyTime / 1000
                            self.mEndTime = leaderMarchData.startTime / 1000
                            self.mLastTime = os.difftime(self.mEndTime, common:getCurTime())
                            self.mBarLabelKey = '@Assemblying'
                        elseif leaderMarchData.marchStatus == World_pb.MARCH_STATUS_MARCH then
                            self.mStartTime = leaderMarchData.startTime / 1000
                            self.mEndTime = leaderMarchData.endTime / 1000
                            self.mLastTime = os.difftime(self.mEndTime, common:getCurTime())
                            self.mBarLabelKey = '@Marching'
                            btnLabelStr = '@QueueSpeedUp'
                            self.mIsMarchMassJoinSpec = true
                        end                        
                        self:refreshTime(cellRoot, self.mLastTime)
                        UIExtend.setControlButtonTitle(ccbfile, 'mBlueBtn', btnLabelStr)
                        cellRoot:setIsScheduleUpdate(true)
                    else
                        self.mBarLabelKey = '@Assemblying'
                        UIExtend.setCCLabelString(ccbfile, 'mCellLabel', _RALang(self.mBarLabelKey))
                        UIExtend.setControlButtonTitle(ccbfile, 'mBlueBtn', btnLabelStr)
                        -- cellRoot:setIsScheduleUpdate(false)
                    end

                elseif marchData.marchStatus == World_pb.MARCH_STATUS_MARCH_ASSIST then
                    --援助中
                    self.mStartTime = -1
                    self.mBarLabelKey = '@SoldierAiding'
                    UIExtend.setControlButtonTitle(ccbfile, 'mBlueBtn', '@Recall')
                    UIExtend.setCCLabelString(ccbfile, 'mCellLabel', _RALang(self.mBarLabelKey))
                    UIExtend.setNodesVisible(ccbfile, {
                        mBlueBar = false,
                        mBlueBtn = true,
                        mGreenBar = false,
                        mFreeBtn = false,
                        mFreeAniCCB = false,
                        mBarAniCCB = false,
                    })
                end
            end
        else
            -- 取队列数据
            local queueData = RAQueueManager:getQueueData(self.mQueueType, self.mQueueId)
            if queueData ~= nil then
                isDefaultShow = false
                cellRoot:setIsScheduleUpdate(true)
                --图标显示，有队列的时候显示正在建造或者修理的对象图标；没有的时候清空
                local icon, name = RAMainUIHelper:getQueueCellCfg(self.mQueueType, queueData)
                UIExtend.addSpriteToNodeParent(ccbfile, 'mIconNode', icon, 1)

                if self.mQueueType ~= Const_pb.MARCH_QUEUE then
                    -- 设置队列时间            
                    self.mStartTime = queueData.startTime
                    self.mEndTime = queueData.endTime 
                    self.mLastTime = os.difftime(self.mEndTime, common:getCurTime())
                    self:refreshTime(cellRoot, self.mLastTime)
                end
                mIsQueueSpare = false
           end
       end
       if isDefaultShow then
            --图标显示，没有的时候清空
            local icon, name, btnName = RAMainUIHelper:getQueueCellCfg(self.mQueueType)
            if icon == '' then
                UIExtend.removeSpriteFromNodeParent(ccbfile, 'mIconNode')
            else
                UIExtend.addSpriteToNodeParent(ccbfile, 'mIconNode', icon, 1)
            end
            UIExtend.setCCLabelString(ccbfile, 'mCellLabel', name)
            UIExtend.setNodesVisible(ccbfile, {
                mBlueBar = false,
                mBlueBtn = true,
                mGreenBar = false,
                mFreeBtn = false,
                mFreeAniCCB = false,
                mBarAniCCB = false,
            })
            UIExtend.setControlButtonTitle(ccbfile, 'mBlueBtn', btnName, true)
            mIsQueueSpare = true
        end
    end,

    onExecute = function(self, cellRoot)
        -- CCLuaLog("RAMainUIQueueDetailCell:onExcute")
        if cellRoot and self.mStartTime ~= -1 then
            local lastTime = os.difftime(self.mEndTime, common:getCurTime())
            if self.mLastTime > lastTime then
                self:refreshTime(cellRoot, lastTime)
            end
        end
    end,

    refreshTime = function(self, cellRoot, lastTime)
        if cellRoot == nil then return end
        local ccbfile = cellRoot:getCCBFileNode()
        if ccbfile == nil then return end
        if lastTime <= 0 then
            CCLuaLog('RAMainUIQueueDetailCell:refreshTime arg error!!!!  lastTime = '.. lastTime)
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

    onUnLoad = function(self, cellRoot)
        CCLuaLog("RAMainUIQueueDetailCell:onUnLoad")
    end ,

    onBlueBtn = function(self)
        CCLuaLog("RAMainUIQueueDetailCell:onBlueBtn")
        -- 特殊处理行军
        if self.mQueueType == Const_pb.MARCH_QUEUE then
            local RAMarchDataManager = RARequire('RAMarchDataManager')
            local marchData = RAMarchDataManager:GetMarchDataById(self.mQueueId)
            local World_pb = RARequire("World_pb")
            if marchData.marchStatus == World_pb.MARCH_STATUS_MARCH or
                marchData.marchStatus == World_pb.MARCH_STATUS_RETURN_BACK then
                -- 加速
                self:sendMessageToSpeedUpMarch(self.mQueueType, self.mQueueId)
            elseif marchData.marchStatus == World_pb.MARCH_STATUS_MARCH_COLLECT then
                --查看
                self:sendMessageToWatchMarch(self.mQueueType, self.mQueueId)
            elseif marchData.marchStatus == World_pb.MARCH_STATUS_MARCH_QUARTERED then
                --查看
                self:sendMessageToWatchMarch(self.mQueueType, self.mQueueId)
            elseif marchData.marchStatus == World_pb.MARCH_STATUS_WAITING then
                if not self.mIsMarchMassJoinSpec then
                    --查看                
                    self:sendMessageToWatchMarch(self.mQueueType, self.mQueueId, marchData.marchStatus)
                else
                    -- 加速
                    self:sendMessageToSpeedUpMarch(self.mQueueType, marchData.targetId)
                end
            elseif marchData.marchStatus == World_pb.MARCH_STATUS_MARCH_ASSIST then
                --援助中，召回
                self:sendMessageToCallBackMarch(self.mQueueType, self.mQueueId)
            end
            return
        end
        local queueData = RAQueueManager:getQueueData(self.mQueueType, self.mQueueId)
        if queueData == nil then
            -- 跳转
            -- 训练、科技、治疗类型的
            if self.mQueueType == Const_pb.SOILDER_QUEUE or self.mQueueType == Const_pb.SCIENCE_QUEUE or self.mQueueType == Const_pb.CURE_QUEUE then
                local msgData = {}
                msgData.queueType = self.mQueueType
                msgData.buildType = self.mBuildType

                -- 科技
                if self.mQueueType == Const_pb.SCIENCE_QUEUE then
                    msgData.buildType = Const_pb.FIGHTING_LABORATORY
                end
                -- 治疗
                if self.mQueueType == Const_pb.CURE_QUEUE then
                    msgData.buildType = Const_pb.HOSPITAL_STATION
                end
                msgData.callBack = function(buildType)
                    RABuildManager:showBuildingByBuildType(buildType)
                end
                MessageManager.sendMessage(MessageDef_MainUI.MSG_CloseQueuePage, { closeData = msgData})
            end

            if self.mQueueType == Const_pb.BUILDING_QUEUE then
                local targetBuildId = RABuildManager:getReadyUpgrateBuilding() 
                if targetBuildId == nil then
                    RARootManager.ShowMsgBox("@NoBuildingToConstruct")
                else
                    local msgData = {}
                    msgData.queueType = self.mQueueType
                    msgData.buildId = targetBuildId
                    msgData.callBack = function(buildId)
                        RABuildManager:showBuildingById(buildId)
                    end
                    MessageManager.sendMessage(MessageDef_MainUI.MSG_CloseQueuePage, { closeData = msgData}) 
                end
            end
        else
            -- 加速
            local RARootManager = RARequire('RARootManager')
            RARootManager.showCommonItemsSpeedUpPopUp(queueData)
        end 
    end,

    onBarBtn = function(self)
        -- 特殊处理行军
        if self.mQueueType == Const_pb.MARCH_QUEUE then            
            local RAMarchDataManager = RARequire('RAMarchDataManager')
            local marchData = RAMarchDataManager:GetMarchDataById(self.mQueueId)
            if marchData ~= nil then            
                self:sendMessageToWatchMarch(self.mQueueType, self.mQueueId, marchData.marchStatus)
            end
        end
        CCLuaLog("RAMainUIQueueDetailCell:onBlueBtn")
    end,

    onFreeBtn = function(self)
        CCLuaLog("RAMainUIQueueDetailCell:onFreeBtn")
        if self.mQueueType == Const_pb.BUILDING_QUEUE or self.mQueueType == Const_pb.BUILDING_DEFENER then
            -- RAQueueManager:sendQueueFreeFinish(self.mQueueId)

            local msgData = {}
            msgData.isFree = true
            msgData.queueType = self.mQueueType
            msgData.buildId = self.mQueueId
            msgData.callBack = function(buildId)
                RAQueueManager:sendQueueFreeFinish(buildId)
            end
            MessageManager.sendMessage(MessageDef_MainUI.MSG_CloseQueuePage, { closeData = msgData}) 
        end

    end,

    -- 查看行军的方法
    sendMessageToWatchMarch = function(self, queueType, queueId, marchStatus)     
        local RARootManager = RARequire('RARootManager')
        local msgData = {}
        msgData.queueType = queueType
        msgData.queueId = queueId
        -- 等待状态，且没有出发行军的时候，才打开集结页面
        if marchStatus == World_pb.MARCH_STATUS_WAITING and not self.mIsMarchMassJoinSpec then
            msgData.callBack = function(queueId)
                local RARootManager = RARequire('RARootManager')
                RARootManager.OpenPage("RANewAllianceWarPage")
            end
        else
            if RARootManager:GetIsInWorld() then    
                msgData.callBack = function(queueId)
                    local RARootManager = RARequire('RARootManager')
                    if RARootManager:GetIsInWorld() then
                        local RAWorldManager = RARequire('RAWorldManager')            
                        local RAMarchManager = RARequire('RAMarchManager')
                        local pos = RAMarchManager:GetMarchMoveEntityTilePos(queueId)
                        RAWorldManager:LocateAt(pos.x, pos.y)
                        -- ShowMoeveEntityHud
                    end
                end
            end
        end
        MessageManager.sendMessage(MessageDef_MainUI.MSG_CloseQueuePage, { closeData = msgData})
    end,

    -- 加速行军的方法
    sendMessageToSpeedUpMarch = function(self, queueType, queueId)        
        local msgData = {}
        msgData.queueType = queueType
        msgData.queueId = queueId        
        msgData.callBack = function(marchId)                
            local RACommonGainItemData = RARequire('RACommonGainItemData')
            RARootManager.showCommonGainItemPage(RACommonGainItemData.GAIN_ITEM_TYPE.marchAccelerate, marchId)
        end
        MessageManager.sendMessage(MessageDef_MainUI.MSG_CloseQueuePage, { closeData = msgData})
    end,

    -- 召回行军的方法
    sendMessageToCallBackMarch = function(self, queueType, queueId)        
        local msgData = {}
        msgData.queueType = queueType
        msgData.queueId = queueId        
        msgData.callBack = function(marchId)                
            local RAWorldPushHandler = RARequire('RAWorldPushHandler')
            RAWorldPushHandler:sendServerCalcCallBackReq(marchId)
        end
        MessageManager.sendMessage(MessageDef_MainUI.MSG_CloseQueuePage, { closeData = msgData})
    end,

    OnAnimationDone = function(self, ccbfile)
        local lastAnimationName = ccbfile:getCompletedAnimationName()                
    end
}



------ title cell
local RAMainUIQueueTitleCell = 
{
    -- 队列类型
    mQueueType = -1,
    -- 当前队列的数目
    mCurCount = 0,
    
    new = function(self, o)
        o = o or {}
        setmetatable(o,self)
        self.__index = self    
        return o
    end,

    getCCBName = function(self)
        return "RAMainUIQueueCellTitle.ccbi"
    end,

    onRefreshContent = function(self, cellRoot)
        CCLuaLog("RAMainUIQueueTitleCell:onRefreshContent")
        local ccbfile = cellRoot:getCCBFileNode()
        if ccbfile ~= nil then
            UIExtend.addSpriteToNodeParent(ccbfile, 'mIconNode', RAMainUIHelper.QueueIconMap[self.mQueueType])
            local str = RAStringUtil:getLanguageString(RAMainUIHelper.QueueNameMap[self.mQueueType])
            if self.mQueueType ~= Const_pb.SCIENCE_QUEUE and 
                    self.mQueueType ~= Const_pb.CURE_QUEUE and
                    self.mQueueType ~= Const_pb.BUILDING_DEFENER then
                local currCount = self.mCurCount
                local maxCount = RAQueueManager:getQueueMaxCounts(self.mQueueType)
                str = str .. RAStringUtil:getLanguageString('@PartedTwoParams', currCount, maxCount)
            end
            UIExtend.setCCLabelString(ccbfile, 'mCellTItle', str)            
        end
    end,

    OnAnimationDone = function(self, ccbfile)
        local lastAnimationName = ccbfile:getCompletedAnimationName()                
    end
}



OnReceiveMessage = function(message) 
    -- 关闭队列UI的消息
    if message.messageID == MessageDef_MainUI.MSG_CloseQueuePage then
        CCLuaLog("MessageDef_MainUI MSG_CloseQueuePage")        
        RAMainUIQueuePage:ClosePageByArg(message.closeData)
    end

    if message.messageID == MessageDef_Queue.MSG_Common_ADD then
        CCLuaLog("MessageDef_Queue MSG_Common_ADD")        
        RAMainUIQueuePage:refreshQueueScrollView()
    end

    if message.messageID == MessageDef_Queue.MSG_Common_UPDATE then
        CCLuaLog("MessageDef_Queue MSG_Common_UPDATE")        
        RAMainUIQueuePage:refreshQueueScrollView()
    end

    if message.messageID == MessageDef_Queue.MSG_Common_DELETE then
        CCLuaLog("MessageDef_Queue MSG_Common_DELETE")        
        RAMainUIQueuePage:refreshQueueScrollView()
    end

    if message.messageID == MessageDef_Queue.MSG_Common_CANCEL then
        CCLuaLog("MessageDef_Queue MSG_Common_CANCEL")        
        RAMainUIQueuePage:refreshQueueScrollView()
    end
end

function RAMainUIQueuePage:registerMessageHandlers()
    MessageManager.registerMessageHandler(MessageDef_MainUI.MSG_CloseQueuePage, OnReceiveMessage)
    MessageManager.registerMessageHandler(MessageDef_Queue.MSG_Common_ADD, OnReceiveMessage)
    MessageManager.registerMessageHandler(MessageDef_Queue.MSG_Common_UPDATE, OnReceiveMessage)
    MessageManager.registerMessageHandler(MessageDef_Queue.MSG_Common_DELETE, OnReceiveMessage)
    MessageManager.registerMessageHandler(MessageDef_Queue.MSG_Common_CANCEL, OnReceiveMessage)
end

function RAMainUIQueuePage:unregisterMessageHandlers()
    MessageManager.removeMessageHandler(MessageDef_MainUI.MSG_CloseQueuePage, OnReceiveMessage)
    MessageManager.removeMessageHandler(MessageDef_Queue.MSG_Common_ADD, OnReceiveMessage)
    MessageManager.removeMessageHandler(MessageDef_Queue.MSG_Common_UPDATE, OnReceiveMessage)
    MessageManager.removeMessageHandler(MessageDef_Queue.MSG_Common_DELETE, OnReceiveMessage)
    MessageManager.removeMessageHandler(MessageDef_Queue.MSG_Common_CANCEL, OnReceiveMessage)    
end


function RAMainUIQueuePage:resetData()
    CCLuaLog("RAMainUIQueuePage:resetData")
    self.mCloseArg = nil
    self.mTargetType = -1
    local scrollView = self.mQueueListSV
    if self.mQueueListSV ~= nil then
        self.mQueueListSV:removeAllCell()
    end   
end

function RAMainUIQueuePage:CommonRefresh(data)
    self:refreshQueueScrollView()
end

function RAMainUIQueuePage:Enter(data)
	CCLuaLog("RAMainUIQueuePage:Enter")
	local ccbfile = UIExtend.loadCCBFile("ccbi/RAMainUIQueuePage.ccbi",RAMainUIQueuePage)
    if data ~= nil and data.queueType ~= nil then
        self.mTargetType = data.queueType
    end
    -- 点击空白区域关闭的方法回调
    self.closeFunc = function()
        RAMainUIQueuePage:onBack()
    end
    -- UIExtend.setNodeVisible(ccbfile, "mWaitingNode", isShow)    
    self.mQueueListSV = UIExtend.getCCScrollViewFromCCB(ccbfile, "mQueueListSV")
    ccbfile:runAnimation(CCB_InAni)
    self:refreshQueueScrollView()

    self:registerMessageHandlers()

    -- ui缩放
    local contentSizeNode = UIExtend.getCCNodeFromCCB(ccbfile,"mContentSizeNode")    
    local scaleNode = UIExtend.getCCNodeFromCCB(ccbfile,"mMiddleNode")
    if scaleNode and contentSizeNode then
        scaleNode:setScale(1.0)
        local addSize = UIExtend.calcAdditionalWidth()
        local currSize = contentSizeNode:getContentSize().width
        local winSize = CCDirector:sharedDirector():getWinSize()        
        local maxPer = winSize.width / currSize
        if addSize > 0 then
            local per = addSize / currSize + 1
            if per > maxPer then
                per = maxPer
            end
            scaleNode:setScale(per)
        end
    end
    -- 初始化进来不让点击返回
    self.mIsClosing = true

    --播放音效 by phan
    local common = RARequire("common")
    common:playEffect("click_main_botton_banner")
end


function RAMainUIQueuePage:refreshQueueScrollView()
    local scrollView = self.mQueueListSV
    scrollView:removeAllCell()
    local first2showCell = nil
    local queueShowDataMap = RAQueueManager:getQueueShowDataMap(true)
    for titleIndex, showData in ipairs(queueShowDataMap) do
        if showData.isShow then
            -- 先创建一个title
            local ccbTitleCell = CCBFileCell:create()
            local handlerTitle = RAMainUIQueueTitleCell:new(
                {
                    mQueueType = showData.queueType,
                    mCurCount = showData.cellCount,
                    mIndex = titleIndex
                })
            handlerTitle.selfCell = ccbTitleCell
            ccbTitleCell:registerFunctionHandler(handlerTitle)
            ccbTitleCell:setCCBFile(handlerTitle:getCCBName())
            scrollView:addCellBack(ccbTitleCell)
            if showData.queueType == self.mTargetType then
                first2showCell = handlerTitle
            end

            for cellIndex, cellData in ipairs(showData.cellMap) do
                local ccbDetailCell = CCBFileCell:create()
                local handlerDetail = RAMainUIQueueDetailCell:new(
                    {
                        mIndex = cellIndex,
                        mQueueId = cellData.id,                       
                        mQueueType = showData.queueType
                    })
                if showData.queueType == Const_pb.SOILDER_QUEUE then
                    handlerDetail.mBuildType = cellData.buildType
                end
                handlerDetail.selfCell = ccbDetailCell
                ccbDetailCell:registerFunctionHandler(handlerDetail)
                ccbDetailCell:setCCBFile(handlerDetail:getCCBName())
                scrollView:addCellBack(ccbDetailCell)
            end
        end
    end
    scrollView:orderCCBFileCells()
    if first2showCell and first2showCell.selfCell then
        first2showCell.selfCell:locateTo(CCBFileCell.LT_Top)
    end
end

function RAMainUIQueuePage:onBack()
    CCLuaLog("RAMainUIQueuePage:onBack")    
    if not self.mIsClosing then
        self.mIsClosing = true
        self:getRootNode():runAnimation("OutAni")
    end

    --播放音效 by phan
    local common = RARequire("common")
    common:playEffect("click_main_botton_banner_back")
end

function RAMainUIQueuePage:ClosePageByArg(arg)
    if not self.mIsClosing then
        self.mCloseArg = arg
        self:getRootNode():runAnimation("OutAni")
        self.mIsClosing = true
    end
end

function RAMainUIQueuePage:OnAnimationDone(ccbfile)
	local lastAnimationName = ccbfile:getCompletedAnimationName()
    if lastAnimationName == CCB_OutAni then        
        if self.mCloseArg ~= nil then
            if self.mCloseArg.isFree then
                if self.mCloseArg.queueType == Const_pb.BUILDING_QUEUE or self.mCloseArg.queueType == Const_pb.BUILDING_DEFENER then
                    if self.mCloseArg.callBack ~= nil then
                        self.mCloseArg.callBack(self.mCloseArg.buildId)
                    end
                end
            else
                if self.mCloseArg.queueType == Const_pb.SOILDER_QUEUE or self.mCloseArg.queueType == Const_pb.SCIENCE_QUEUE or self.mCloseArg.queueType == Const_pb.CURE_QUEUE then
                    if self.mCloseArg.callBack ~= nil then
                        self.mCloseArg.callBack(self.mCloseArg.buildType)
                    end
                elseif self.mCloseArg.queueType == Const_pb.BUILDING_QUEUE then
                    if self.mCloseArg.callBack ~= nil then
                        self.mCloseArg.callBack(self.mCloseArg.buildId)
                    end
                elseif self.mCloseArg.queueType == Const_pb.MARCH_QUEUE then
                    if self.mCloseArg.callBack ~= nil then
                        self.mCloseArg.callBack(self.mCloseArg.queueId)
                    else
                        local RAScenesMananger = RARequire('RAScenesMananger')
                        RAScenesMananger.AddWorldLocateCmdByMarchId(self.mCloseArg.queueId, true)                    
                    end
                end
            end
        end
        RARootManager.ClosePage("RAMainUIQueuePage")
        -- msgData.queueType = self.mQueueType
        -- msgData.buildType = self.mBuildType
        -- msgData.callBack = function(buildType)
    end
    if lastAnimationName == CCB_InAni then
        self.mIsClosing = false
    end
end

function RAMainUIQueuePage:Exit()	
    CCLuaLog("RAMainUIQueuePage:Exit")
    self:unregisterMessageHandlers()
    self:resetData()
    UIExtend.unLoadCCBFile(self)    
end









    