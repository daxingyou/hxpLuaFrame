--通用道具使用界面
--by sunyungao


local UIExtend = RARequire("UIExtend")
local RACommonGainItemManager = RARequire("RACommonGainItemManager")
local RACommonUseItemCellHandler = RARequire("RACommonUseItemCellHandler")
local RACommonTitleHelper = RARequire('RACommonTitleHelper')
local RARootManager = RARequire("RARootManager")
local RACommonGainItemData = RARequire("RACommonGainItemData")
local common = RARequire('common')
local Utilitys = RARequire('Utilitys')
local RAGuideManager = RARequire("RAGuideManager")
local RAGuideConfig = RARequire("RAGuideConfig")

local RAMarchItemUsePage  = BaseFunctionPage:new(...)

RAMarchItemUsePage.data = nil
RAMarchItemUsePage.scrollView = nil
RAMarchItemUsePage.mIsExecute = false
RAMarchItemUsePage.mLastUpdateTime = 0

-- 莫名其妙会出现卡住的情况，增加点击多次后直接关闭的逻辑
RAMarchItemUsePage.mClickCloseCount = 0

local CCB_InAni = "InAni"
local CCB_OutAni = "OutAni"
local CCB_KeepIn = "KeepIn"
local CCB_KeepOut = "KeepOut"


--------------------------------------------------------------
-----------------------消息处理-------------------------------
--------------------------------------------------------------

local OnReceiveMessage = function(message)
    --todo
    --CCLuaLog("类型。。" .. message.type)
    if message.messageID == MessageDef_package.MSG_package_consume_item then
        if RAGuideManager.isInGuide() then
            --在新手期直接隐藏UI
            RAMarchItemUsePage:onBack()
        else
            --todo
            RAMarchItemUsePage:refreshByItemType()
            RAMarchItemUsePage:initData()
            RAMarchItemUsePage:refreshScrollView()
        end
    end

    --CCLuaLog("类型。。" .. message.type)
    if message.messageID == MessageDef_World.MSG_CloseMarchUseItemPageForCallBack then        
        RAMarchItemUsePage:onBack()
        return
    end

    -- MessageManager.sendMessage(MessageDef_Queue.MSG_Common_DELETE, {
    --                 queueId = marchId, 
    --                 queueType = Const_pb.MARCH_QUEUE, 
    --                 marchType = marchData.marchType
    --                 })
    if message.messageID == MessageDef_Queue.MSG_Common_DELETE then
        local Const_pb = RARequire('Const_pb')
        if message.queueType == Const_pb.MARCH_QUEUE then
            -- 收到删除队列的时候，尝试关闭UI
            if message.queueId == RAMarchItemUsePage.targetMarchId then
                RAMarchItemUsePage:onBack()
            end
        end
        return
    end
end
--注册监听消息
function RAMarchItemUsePage:registerMessage()
    --todo
    MessageManager.registerMessageHandler(MessageDef_package.MSG_package_consume_item, OnReceiveMessage)
    MessageManager.registerMessageHandler(MessageDef_Queue.MSG_Common_DELETE, OnReceiveMessage)
    MessageManager.registerMessageHandler(MessageDef_World.MSG_CloseMarchUseItemPageForCallBack, OnReceiveMessage)
end

function RAMarchItemUsePage:removeMessageHandler()
    --todo
   MessageManager.removeMessageHandler(MessageDef_package.MSG_package_consume_item, OnReceiveMessage)
   MessageManager.removeMessageHandler(MessageDef_Queue.MSG_Common_DELETE, OnReceiveMessage)
   MessageManager.removeMessageHandler(MessageDef_World.MSG_CloseMarchUseItemPageForCallBack, OnReceiveMessage)
end

function RAMarchItemUsePage:getCCBFileName(itemType)
    -- if itemType == RACommonGainItemData.GAIN_ITEM_TYPE.marchAccelerate then
    --     return 'RACommonGainAdditionPage2.ccbi'
    -- end        
    return 'RAWorldMarchAdditionPage.ccbi'
end

function RAMarchItemUsePage:Enter(data)
    local ccbfileName = self:getCCBFileName(data.itemType)	
	local ccbfile = UIExtend.loadCCBFile(ccbfileName, self)
	self.ccbfile  = ccbfile
	self.data     = data
    self.mClickCloseCount = 0
    -- 初始化进来不让点击返回
    self.mIsClosing = true

    -- ccbfile:runAnimation(CCB_KeepOut)
    ccbfile:runAnimation(CCB_InAni)

    print('RAMarchItemUsePage:Enter')

    self.closeFunc = function()
        RAMarchItemUsePage:onBack()
    end

    self.scrollView = UIExtend.getCCScrollViewFromCCB(self.ccbfile, "mListSV")

    self.mIsExecute = true

    self.targetMarchId = self.data.marchId

    self:registerMessage()    
    self:refreshByItemType()
	self:initData()
    self:refreshScrollView()
end


function RAMarchItemUsePage:Execute()
    if not self.mIsExecute then return end
    self.mLastUpdateTime = self.mLastUpdateTime + common:getFrameTime()
    if self.mLastUpdateTime > 1 then
        self.mLastUpdateTime = 0
        self:refreshByItemType()
    end
end

function RAMarchItemUsePage:Exit()
    print('RAMarchItemUsePage:Exit')
    self.scrollView:removeAllCell()
    self:removeMessageHandler()
    self.ccbfile:stopAllActions()

    self.data = nil
    self.scrollView = nil
    self.mLastUpdateTime = 0
    self.mIsExecute = false
    self.targetMarchId = ''
    self.mClickCloseCount = 0

    UIExtend.unLoadCCBFile(self)

    MessageManager.sendMessage(MessageDef_World.MSG_CloseMarchUseItemPage)
end

function RAMarchItemUsePage:onBack()
    CCLuaLog("RAMarchItemUsePage:onBack")    
    if not self.mIsClosing then
        self.mIsClosing = true
        CCLuaLog("RAMarchItemUsePage:runAnimation.."..CCB_OutAni)
        self:getRootNode():runAnimation(CCB_OutAni)
        --播放音效 by phan
        local common = RARequire("common")
        common:playEffect("click_main_botton_banner_back")
    else
        self.mClickCloseCount = self.mClickCloseCount + 1
        print("RAMarchItemUsePage is closinggggggggggggggggggggg, close count:"..self.mClickCloseCount)    
        if self.mClickCloseCount > 10 then
            RARootManager.ClosePage('RAMarchItemUsePage')
        end
    end
end

--初始化ui
function RAMarchItemUsePage:initData()
    --刷新配置数据
    RACommonGainItemManager:updateConfigData(self.data)    
end

-- 根据道具类型，刷新UI
function RAMarchItemUsePage:refreshByItemType()
    local ccbfile = self.ccbfile
    local itemType = self.data.itemType
    if ccbfile == nil then return end    
    local RAMarchDataManager = RARequire('RAMarchDataManager')
    local marchData = RAMarchDataManager:GetMarchDataById(self.data.marchId)
    self.targetMarchId = self.data.marchId
    local isVisual = false
    if marchData ~= nil then
        local startTime = marchData.startTime / 1000
        local endTime = marchData.endTime / 1000
        local lastTime = marchData:GetLastTime()
        local leaderData = RAMarchDataManager:GetTeamLeaderMarchData(marchData.marchId)
        if leaderData ~= nil and marchData.marchStatus == World_pb.MARCH_STATUS_WAITING then
            startTime = leaderData.startTime / 1000
            endTime = leaderData.endTime / 1000
            lastTime = leaderData:GetLastTime()
            self.targetMarchId = leaderData.marchId
        end
        if lastTime <= 0 then
            print('RAMarchItemUsePage:refreshByItemType last time <= 0')
            self.mIsExecute = false
            self:onBack()
            return
        end
        local totalTime = marchData.marchJourneyTime / 1000
        if totalTime == 0 then
            totalTime = endTime - startTime
        end
        local lbKey = ''
        if marchData.marchStatus == World_pb.MARCH_STATUS_MARCH then
            lbKey = '@Marching'
        end
        if marchData.marchStatus == World_pb.MARCH_STATUS_RETURN_BACK then
            lbKey = '@Retruning'
        end
        local tmpStr = Utilitys.createTimeWithFormat(lastTime)
        if lbKey ~= '' then
            tmpStr = _RALang(lbKey, tmpStr)
        end
        UIExtend.setCCLabelString(ccbfile, "mTime", tmpStr)
        
        -- 计算scale9缩放
        local percent = lastTime / totalTime
        if percent < 0 then percent = 0 end
        if percent > 1 then percent = 1 end
        UIExtend.setCCScale9SpriteScale(ccbfile, "mBar", 1 - percent, true)

        isVisual = true
    end
    UIExtend.setNodesVisible(ccbfile,{
            mBar = isVisual,
            mTime = isVisual
        })
end


-----------------------刷新数据-------------------------------
--更新物品
function RAMarchItemUsePage:refreshScrollView()
    -- body
    local scrollView = self.scrollView
    scrollView:removeAllCell()
    local data = RACommonGainItemManager.mData

    for k,v in pairs(data) do
        --CCLuaLog(v)
        local cell = CCBFileCell:create()
        local ccbiStr = "RACommonGainAdditionCell.ccbi"
        cell:setCCBFile(ccbiStr)
        local panel = RACommonUseItemCellHandler:new({
                mData = v,
                mTag   = k,
                mMarchId = self.targetMarchId,
                mCellType = self.data.itemType
        })
        cell:registerFunctionHandler(panel)
        scrollView:addCell(cell)
    end

    scrollView:orderCCBFileCells()

    scrollView:setTouchEnabled(not RAGuideManager.isInGuide())
end


--desc:根据当前加速道具的情况，返回使用按钮的位置和大小
--加速25%是首要选择，50%是次要选择
function RAMarchItemUsePage:getUseBtnInfo()
    local RACoreDataManager = RARequire("RACoreDataManager")
    local accLowCount = RACoreDataManager:getItemCountByItemId(Const_pb.ITEM_WORLD_MARCH_SPEEDUPL)
    local accHighCount = RACoreDataManager:getItemCountByItemId(Const_pb.ITEM_WORLD_MARCH_SPEEDUPH)
    local chooseCell = nil
    if accLowCount > 0 then
        chooseCell = self.scrollView:getCCBFileWithIndex(1)
    elseif accHighCount > 0 then
        chooseCell = self.scrollView:getCCBFileWithIndex(2)
    end
    if chooseCell then
        local ccbFile = chooseCell:getCCBFileNode()
        if ccbFile then
            local btnNode = UIExtend.getCCControlButtonFromCCB(ccbFile, "mBuyBtnac")
            local tmpPos = ccp(0, 0)
            tmpPos.x, tmpPos.y = btnNode:getPosition()
            local worldPos = btnNode:getParent():convertToWorldSpace(tmpPos)
            tmpPos:delete()
            local btnSize = btnNode:getContentSize()
            return {pos = worldPos, size = btnSize}
        end
    end
    return nil
end



function RAMarchItemUsePage:OnAnimationDone(ccbfile)
    local lastAnimationName = ccbfile:getCompletedAnimationName()       
    if lastAnimationName == CCB_OutAni then
        self.mIsClosing = false
        RARootManager.ClosePage('RAMarchItemUsePage')        
        print('RAMarchItemUsePage:OnAnimationDone  ClosePage')
    end
    if lastAnimationName == CCB_InAni then
        ccbfile:runAnimation(CCB_KeepIn)
        self.mIsClosing = false
        print('RAMarchItemUsePage:OnAnimationDone  KeepIn')
        --add by xinghui:使用加速道具页面，in的动画播放完成后
        if RAGuideManager.isInGuide() then
            local keyWord = RAGuideManager.getKeyWordById(RAGuideManager.currentGuildId)
            if keyWord ~= RAGuideConfig.KeyWordArray.AddCoverPage then--加此判断是为了解决在新手打怪出征的最后一秒点击加速hud按钮出现新手卡住的现象。卡主原因：出征hud在remove的时候会gotoNextStep2用来添加遮罩层，如果此时加速道具使用页面走到此处，依然会调用gotoNext()，导致新手显示错乱
                RAGuideManager.gotoNextStep();
            end
        end
    end
end


--------------------------------------------------------------
-----------------------事件处理-------------------------------
--------------------------------------------------------------
