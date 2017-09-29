--聊天界面
--test by sunyungao


local UIExtend         = RARequire("UIExtend")
local Utilitys         = RARequire("Utilitys")
local RAChatUIPageCell = RARequire("RAChatUIPageCell")
local RARootManager    = RARequire("RARootManager")
local RAChatManager    = RARequire("RAChatManager")
local RAPlayerInfoManager = RARequire('RAPlayerInfoManager')
local RACoreDataManager = RARequire("RACoreDataManager")
local common = RARequire("common")
local RAChatData = RARequire("RAChatData")
local RAAllianceManager=RARequire("RAAllianceManager")
local RANetUtil = RARequire("RANetUtil")
local RA_Common = RARequire("common")

RARequire("MessageDefine")
RARequire("MessageManager")

local p_lastWorldTime = 0
local p_lastAllianceTime = 0


--渲染历史数据面板信息条数
local LastMsgTime=
{
    world=0,
    alliance=0
}



local RAChatUIPage  = BaseFunctionPage:new(...)
local RAChatMainPageHandler = {}
RAChatUIPage.isUseHorn = false  --是否使用喇叭聊天

function RAChatUIPage:Enter(data)
	local ccbfile = UIExtend.loadCCBFile("RAChatPageNew.ccbi", RAChatUIPage)
	self.ccbfile  = ccbfile

    --向后端发送打点数据，需求是每次进来都需要发
    RAChatManager:sendNoticeToServer()

    self:ChangeShowStatus(true)
    self:registerMessage()
	self:init()
    self.lastSendTime = common:getCurTime()
end


--------------------------------------------------------------
-----------------------初始化---------------------------------
--------------------------------------------------------------
function RAChatUIPage:init()
    self.mWorldScrollView    = UIExtend.getCCScrollViewFromCCB(self.ccbfile, "mChatListSV")
    self.mAllianceScrollView = UIExtend.getCCScrollViewFromCCB(self.ccbfile, "mChatAllianceListSV")

    --self.mWorldScrollView:setBounceable(false)
    self.mWorldScrollView:registerFunctionHandler(self)

   -- self.mAllianceScrollView:setBounceable(false)
    self.mAllianceScrollView:registerFunctionHandler(self)

    self.mWorldChatBtn       = UIExtend.getCCControlButtonFromCCB(self.ccbfile, "mWorldChatBtn")
    self.mAllianceChatBtn    = UIExtend.getCCControlButtonFromCCB(self.ccbfile, "mAllianceChatBtn")
    self.mCustomChatBtn      = UIExtend.getCCControlButtonFromCCB(self.ccbfile, "mCustomChatBtn")
    self.mSendBtn = UIExtend.getCCControlButtonFromCCB(self.ccbfile,"mSendBtn")
    self.mWorldChatBtn:setEnabled(false)
    self.mSendBtn:setEnabled(false)
    self.mAllianceChatBtn:setEnabled(true)
    --self.mCustomChatBtn:setEnabled(true)

    --自定义聊天标签先隐藏
    self.mCustomChatBtn:setVisible(false)

    --UIExtend.setNodeVisible(self.ccbfile, "mPasteBtnNode", false)--粘贴按钮

    if nil == self.mWorldPanelVec then
        self.mWorldPanelVec   = {}
    end
    if nil == self.mAlliancePanelVec then
        self.mAlliancePanelVec = {}
    end
    
    if RAChatManager:isChoosenTabWorld() then
        RAChatUIPage:onWorldChatBtn()
    elseif RAChatManager:isChoosenTabAlliance() then
        RAChatUIPage:onAllianceChatBtn()
    end

    self:initEditBox()

    if self.isUseHorn then
        RARootManager.OpenPage("RAChatNoticeUIPage",nil,false,true,true)
    end

    self:initTouchLayer()
end

function RAChatUIPage:initTouchLayer()
   

    local callback = function(pEvent, pTouch)
        CCLuaLog("event name:"..pEvent)
        if pEvent == "began" then
 
            return 1
        end
        if pEvent == "ended" then
            local RALogicUtil = RARequire('RALogicUtil')
            local isInside = RALogicUtil:isTouchInside(self.mSendBtn, pTouch)
            
            if not isInside then 
                -- CCLuaLog('关闭键盘')
                self.editBox:closeKeyboard()
            end 
        end
    end

    layer = CCLayer:create()
    layer:setContentSize(CCDirector:sharedDirector():getOpenGLView():getVisibleSize())
    layer:setPosition(0, 0)
    layer:setAnchorPoint(ccp(0, 0))
    layer:setTouchEnabled(true)
    layer:setTouchMode(kCCTouchesOneByOne)
    self:getRootNode():addChild(layer)
    layer:registerScriptTouchHandler(callback,false, 1 ,false)
 
    self.mLayer = layer
end


local OnReceiveMessage = function(message)
    if message.messageID == MessageDef_Chat.MSG_Chat_Generate_World_Data then
        RAChatUIPage:refreshWorldOneChat()
    elseif message.messageID == MessageDef_Chat.MSG_Chat_Generate_Alliance_Data then
        RAChatUIPage:refreshAllianceOneChat()
    elseif message.messageID == MessageDef_Chat.MSG_Chat_CopyBtn_CellTag_Data then
        RAChatUIPage:mCellCopyBtnClickHandler( message )
    elseif message.messageID == MessageDef_Chat.MSG_Chat_remove_World_top_Data then
        RAChatUIPage:refreshWorldOneChat()
        RAChatUIPage:removeWorldTopCell()
    elseif message.messageID == MessageDef_Chat.MSG_Chat_remove_Alliance_top_Data then
        RAChatUIPage:refreshAllianceOneChat()
        RAChatUIPage:removeAllianceTopCell()
    elseif message.messageID == MessageDef_RootManager.MSG_TopPageMayChange then
        if message.topPageName == 'RAChatUIPage' then 
            RAChatUIPage:setEditBoxVisible(true)
        else
            RAChatUIPage:setEditBoxVisible(false)
        end 
    end
end

function RAChatUIPage:setEditBoxVisible(visible)

    if self.editBox ~= nil then 
        self.editBox:setVisible(visible)
    end 
end

--注册监听消息
function RAChatUIPage:registerMessage()
    MessageManager.registerMessageHandler(MessageDef_Chat.MSG_Chat_Generate_World_Data,    OnReceiveMessage)
    MessageManager.registerMessageHandler(MessageDef_Chat.MSG_Chat_Generate_Alliance_Data, OnReceiveMessage)
    MessageManager.registerMessageHandler(MessageDef_Chat.MSG_Chat_CopyBtn_CellTag_Data,   OnReceiveMessage)
    MessageManager.registerMessageHandler(MessageDef_Chat.MSG_Chat_remove_World_top_Data,   OnReceiveMessage)
    MessageManager.registerMessageHandler(MessageDef_Chat.MSG_Chat_remove_Alliance_top_Data,   OnReceiveMessage)
    MessageManager.registerMessageHandler(MessageDef_RootManager.MSG_TopPageMayChange,   OnReceiveMessage)
    self:addHandler()
end

function RAChatUIPage:removeMessageHandler()
    MessageManager.removeMessageHandler(MessageDef_Chat.MSG_Chat_Generate_World_Data,    OnReceiveMessage)
    MessageManager.removeMessageHandler(MessageDef_Chat.MSG_Chat_Generate_Alliance_Data, OnReceiveMessage)
    MessageManager.removeMessageHandler(MessageDef_Chat.MSG_Chat_CopyBtn_CellTag_Data,   OnReceiveMessage)
    MessageManager.removeMessageHandler(MessageDef_Chat.MSG_Chat_remove_World_top_Data,   OnReceiveMessage)
    MessageManager.removeMessageHandler(MessageDef_Chat.MSG_Chat_remove_Alliance_top_Data,   OnReceiveMessage)
    MessageManager.removeMessageHandler(MessageDef_RootManager.MSG_TopPageMayChange,   OnReceiveMessage)
    self:removeHandler()
end


function RAChatUIPage:addHandler()
    RAChatMainPageHandler[#RAChatMainPageHandler +1] = RANetUtil:addListener(HP_pb.ALLIANCE_MSG_CACHE_S, RAChatUIPage)
end

function RAChatUIPage:removeHandler()
    for k, value in pairs(RAChatMainPageHandler) do
        if RAChatMainPageHandler[k] then
            RANetUtil:removeListener(RAChatMainPageHandler[k])
            RAChatMainPageHandler[k] = nil
        end
    end
    RAChatMainPageHandler = {}
end

function RAChatUIPage:onReceivePacket(handler)
    RARootManager.RemoveWaitingPage()
    local pbCode = handler:getOpcode()
    local buffer = handler:getBuffer()
    if pbCode == HP_pb.ALLIANCE_MSG_CACHE_S then
        self:pullTopRefreshAllianceChats()
    end
end

--------------------------------------------------------------
-----------------------刷新数据-------------------------------
--------------------------------------------------------------


function RAChatUIPage:mCellCopyBtnClickHandler( message )
end

local RAChatUITimeCell = 
{
    showTime = 0,
    mTag     = -100,
    new = function(self, o )
        -- body
        o = o or {}
        setmetatable(o,self)
        self.__index = self    
        return o
    end,

    onRefreshContent = function (self, ccbRoot )
        -- body
        if not ccbRoot then return end
        local ccbfile = ccbRoot:getCCBFileNode() 
        self.ccbfile = ccbfile

        local timeStr = Utilitys.timeConvertShowingTime(self.showTime)
        local mTime = UIExtend.getCCLabelTTFFromCCB(self.ccbfile,"mTime")
        mTime:setString(timeStr)
        local lableWidth = mTime:getContentSize().width + 20
        local mTimeBG = UIExtend.getCCScale9SpriteFromCCB(self.ccbfile, "mTimeBG")
        mTimeBG:setContentSize(lableWidth,mTime:getContentSize().height)
    end
}

--创建时间cell
function RAChatUIPage:createTimeCell( nowTime, channelIndex, isPushBack )
    -- body
    local lastMsgTime = 0
    if channelIndex == RAChatData.CHATCHOOSENTAB.worldTab then
        lastMsgTime  = p_lastWorldTime
        if nowTime>LastMsgTime.world then
            LastMsgTime.world=nowTime
        end    
    elseif channelIndex == RAChatData.CHATCHOOSENTAB.allianceTab then
        lastMsgTime  = p_lastAllianceTime
        if nowTime>LastMsgTime.alliance then
            LastMsgTime.alliance=nowTime
        end  
    end

    local isTimeShow = true
    if not Utilitys.timeDiffBetweenTwo( nowTime, lastMsgTime, RAChatManager.chatTimeDiff ) then
       -- return
       isTimeShow = false
    end
    local scrollView
    if channelIndex == RAChatData.CHATCHOOSENTAB.worldTab then
        scrollView  = self.mWorldScrollView
    elseif channelIndex == RAChatData.CHATCHOOSENTAB.allianceTab then
        scrollView  = self.mAllianceScrollView
    end


    local cell = CCBFileCell:create()
    local panel = RAChatUITimeCell:new({
            showTime = nowTime
    })
    cell:registerFunctionHandler(panel)
    panel.selfCell = cell
    cell:setAnchorPoint(CCPointMake(0,1))
    local ccbNameFile = "RAChatTimeCellNew.ccbi"
    if not isTimeShow then
        ccbNameFile = "RAChatTimeEmptyCellNew.ccbi"
    end
    cell:setCCBFile(ccbNameFile)
    if isPushBack then
        scrollView:addCellBack(cell)
    else
        scrollView:addCellFront(cell)
    end

    if channelIndex == RAChatData.CHATCHOOSENTAB.worldTab then
        table.insert(self.mWorldPanelVec, panel)
        p_lastWorldTime = nowTime
    elseif channelIndex == RAChatData.CHATCHOOSENTAB.allianceTab then
        table.insert(self.mAlliancePanelVec, panel)
        p_lastAllianceTime = nowTime 
    end
end

function RAChatUIPage:removeWorldTopCell()
    --mWorldChannelData 顶部已经移除掉了
    local scrollView = self.mWorldScrollView
    local panel = table.remove(self.mWorldPanelVec, 1)
    if panel.mTag < 0 then --如果顶部是时间，删除时间
        local cell = panel.selfCell
        scrollView:removeCell(cell)
        panel = table.remove(self.mWorldPanelVec, 1)
        cell = panel.selfCell
        scrollView:removeCell(cell)
    else
        local cell = panel.selfCell
        scrollView:removeCell(cell)
    end
end

function RAChatUIPage:removeAllianceTopCell()
    -- body
    local scrollView = self.mAllianceScrollView
    local panel = table.remove(self.mAlliancePanelVec, 1)
    if panel.mTag < 0 then --如果顶部是时间，删除时间
        local cell = panel.selfCell
        scrollView:removeCell(cell)
        panel = table.remove(self.mAlliancePanelVec, 1)
        cell = panel.selfCell
        scrollView:removeCell(cell)
    else
        local cell = panel.selfCell
        scrollView:removeCell(cell)
    end
end

--刷新世界频道聊天信息（初始化）
function RAChatUIPage:refreshWorldSomeChats()
    --self:printPositionLog("refreshWorldSomeChats")
    if 0 == #RAChatManager.mWorldChannelData then
        return
    end

    local tmpData = {} --获取前worldChatFirstCount条数据，不够的话为mWorldChannelData全部数据
    if #RAChatManager.mWorldChannelData <= RAChatManager.worldChatFirstCount then
        tmpData = RAChatManager.mWorldChannelData
    else
        local refreshFirstCount = #RAChatManager.mWorldChannelData - RAChatManager.worldChatFirstCount + 1
        for i=refreshFirstCount,#RAChatManager.mWorldChannelData do
            table.insert(tmpData, RAChatManager.mWorldChannelData[i])
        end
    end
    
    local scrollView = self.mWorldScrollView

    for k,v in pairs(tmpData) do
        if v.msgTime>LastMsgTime.world then
            self:createTimeCell(v.msgTime, RAChatData.CHATCHOOSENTAB.worldTab, true)
            self:createChatBackCell(self.mWorldPanelVec, v, scrollView)
        end
    end

    scrollView:orderCCBFileCells(0, false)
    local bottomCell = self.mWorldPanelVec[#self.mWorldPanelVec].selfCell
    bottomCell:locateTo(CCBFileCell.LT_Bottom, bottomCell:getContentSize().height)
end

function RAChatUIPage:printPositionLog(str)
    local scrollView = self.mWorldScrollView
    local offsetY=scrollView:getContentOffset().y
    local viewSizeHeight=scrollView:getViewSize().height
    local minY=scrollView:minContainerOffset().y
    local maxY=scrollView:maxContainerOffset().y
    local contentHeight=scrollView:getContentSize().height
    CCLuaLog(str.." | printPositionLog,offsetY:"..tostring(offsetY).."viewSize height:"..tostring(viewSizeHeight).."minY :"..tostring(minY).."maxY:"..tostring(maxY).."contentHeight :"..tostring(contentHeight))
end

--scrollview 上拉刷新回调
function RAChatUIPage:scrollViewDidRefreshToTop()
    --self:printPositionLog("scrollViewDidRefreshToTop")
    local scrollView=nil
    if RAChatManager:isChoosenTabWorld() then
        scrollView=self.mWorldScrollView
    elseif RAChatManager:isChoosenTabAlliance() then
        scrollView=self.mAllianceScrollView
    end

    if scrollView~=nil then
        local offsetY=scrollView:getContentOffset().y
        local minY=scrollView:minContainerOffset().y
        if offsetY<=minY then
            --self:printPositionLog("offsetY<=minY getChatHistoryMsg ")
            if RAChatManager:isChoosenTabWorld() then
                self:pullTopRefreshWorldChats()
            elseif RAChatManager:isChoosenTabAlliance() then
                --1、判断两次请求时间是否合理
                --2、记录请求时间
                --3、设置遮罩
                if RAChatManager.LastReqAllianceMsgTime==0 then
                    RAChatManager.LastReqAllianceMsgTime=RA_Common:getCurMilliTime()
                end
                RAChatManager:getChatMsgCacheForAlliance(RAChatManager.LastReqAllianceMsgTime)
            end
        end    
    end    
end

--处理上拉刷新
function RAChatUIPage:pullTopRefreshWorldChats()
    local worldChannelDataCount = #RAChatManager.mWorldChannelData
    local worldPanelCount = self:getChatPanelCount(self.mWorldPanelVec)
    local scrollView = self.mWorldScrollView

    for i=1,RAChatManager.chatPullTopRefreshCount do
        local tmpValue = RAChatManager.mWorldChannelData[worldChannelDataCount-worldPanelCount+1-i]
        if nil ~= tmpValue then
            self:createChatTopCell( self.mWorldPanelVec, tmpValue, scrollView )
            self:createTimeCell(tmpValue.msgTime, RAChatData.CHATCHOOSENTAB.worldTab, false)
        else
            break
        end
    end

    scrollView:orderCCBFileCells(0, false)
    local firstCell = self.mWorldPanelVec[1]
    if nil ~= firstCell then
        local bottomCell = firstCell.selfCell
        bottomCell:locateTo(CCBFileCell.LT_Top)
    end
end

--排除时间cell获取展示中的聊天cell数量
function RAChatUIPage:getChatPanelCount(panelVec)
    local count = 0
    for _,v in pairs(panelVec) do
        if v.mTag >= 0 then
            count = count + 1
        end
    end
    return count 
end

--刷新联盟频道聊天信息（初始化、上拉刷新）
function RAChatUIPage:refreshAllianceSomeChats()
    if 0 == #RAChatManager.mAllianceChannelData then
        return
    end

    local tmpData = {} --获取前worldChatFirstCount条数据，不够的话为mWorldChannelData全部数据
    if #RAChatManager.mAllianceChannelData <= RAChatManager.worldChatFirstCount then
        tmpData = RAChatManager.mAllianceChannelData
    else
        local refreshFirstCount = #RAChatManager.mAllianceChannelData - RAChatManager.worldChatFirstCount + 1
        for i=refreshFirstCount,#RAChatManager.mAllianceChannelData do
            table.insert(tmpData, RAChatManager.mAllianceChannelData[i])
        end
    end
    
    local scrollView = self.mAllianceScrollView
    local panelSize=#self.mAlliancePanelVec
    for k,v in pairs(tmpData) do
        if v.msgTime>LastMsgTime.alliance or panelSize==0 then
            self:createTimeCell(v.msgTime, RAChatData.CHATCHOOSENTAB.allianceTab, true)
            self:createChatBackCell(self.mAlliancePanelVec, v, scrollView)
        end
    end

    scrollView:orderCCBFileCells(0, false)
    local bottomCell = self.mAlliancePanelVec[#self.mAlliancePanelVec].selfCell
    bottomCell:locateTo(CCBFileCell.LT_Bottom, bottomCell:getContentSize().height)
end

--联盟需求，查看历史信息
--处理上拉刷新
function RAChatUIPage:pullTopRefreshAllianceChats()
    local allianceChannelDataCount = #RAChatManager.mAllianceChannelData
    local alliancePanelCount = self:getChatPanelCount(self.mAlliancePanelVec)
    local scrollView = self.mAllianceScrollView

    local recieveMsgCount=RAChatManager.chatPullTopRefreshCount
    local diffCount=allianceChannelDataCount-alliancePanelCount

    --实际的历史条数不足20条时，以实际的条数为准
    if RAChatManager.chatPullTopRefreshCount>diffCount then
        recieveMsgCount=diffCount
    end

    for i=1,recieveMsgCount do
        local tmpValue = RAChatManager.mAllianceChannelData[recieveMsgCount+1-i]
        if nil ~= tmpValue then
            self:createChatTopCell( self.mAlliancePanelVec, tmpValue, scrollView )
            self:createTimeCell(tmpValue.msgTime, RAChatData.CHATCHOOSENTAB.allianceTab, false)
        else
            break
        end
    end

    scrollView:orderCCBFileCells(0, false)
    local firstCell = self.mAlliancePanelVec[1]
    if nil ~= firstCell then
        local bottomCell = firstCell.selfCell
        bottomCell:locateTo(CCBFileCell.LT_Top)
    end
end

--刷新世界频道聊天信息（接受某条消息）
function RAChatUIPage:refreshWorldOneChat()
    local scrollView = self.mWorldScrollView 
    local len = #RAChatManager.mWorldChannelData
    if 0 == len then
        return
    end
    local content = RAChatManager.mWorldChannelData[len]
    --record old offset
    local oldContentHeight=scrollView:getContentSize().height
    local oldOffsetY=scrollView:getContentOffset().y

    self:createTimeCell(content.msgTime, RAChatData.CHATCHOOSENTAB.worldTab, true )
    local cell = self:createChatBackCell( self.mWorldPanelVec, content, scrollView, true )

    scrollView:orderCCBFileCells(0, false)

    --reset new offset
    local newContentHeight=scrollView:getContentSize().height
    local maxY=scrollView:maxContainerOffset().y
    --todo 如果允许有差值可以再进行优化
    if oldOffsetY==maxY then
        --self:printPositionLog("refreshWorldOneChat")
        cell:locateTo(CCBFileCell.LT_Bottom, cell:getContentSize().height)
        --todo在此位置完善提示有多少未读信息
    else
        local offset=scrollView:getContentOffset()
        offset.y=oldOffsetY-(newContentHeight-oldContentHeight)
        scrollView:setContentOffset(offset)           
    end
end

--刷新联盟频道聊天信息（接受某条消息）
function RAChatUIPage:refreshAllianceOneChat()
    local scrollView = self.mAllianceScrollView
    local len = #RAChatManager.mAllianceChannelData
    if 0 == len then
        return
    end

    local content = RAChatManager.mAllianceChannelData[len]
    --record old offset
    local oldContentHeight=scrollView:getContentSize().height
    local oldOffsetY=scrollView:getContentOffset().y

    self:createTimeCell(content.msgTime, RAChatData.CHATCHOOSENTAB.allianceTab, true )
    local cell = self:createChatBackCell( self.mAlliancePanelVec, content, scrollView, true )

    scrollView:orderCCBFileCells(0, false)
    
    --reset new offset
    local newContentHeight=scrollView:getContentSize().height
    local maxY=scrollView:maxContainerOffset().y
    --todo 如果允许有差值可以再进行优化
    if oldOffsetY==maxY then
        --self:printPositionLog("refreshAllianceOneChat")
        cell:locateTo(CCBFileCell.LT_Bottom, cell:getContentSize().height)
        --todo在此位置完善提示有多少未读信息
    else
        local offset=scrollView:getContentOffset()
        offset.y=oldOffsetY-(newContentHeight-oldContentHeight)
        scrollView:setContentOffset(offset)           
    end
end

--isClearInputContent:是否要清理输入框内容
function RAChatUIPage:createChatBackCell( channelPanelVec, contentData, scrollView, isClearInputContent )
    local cell = self:createChatCell( channelPanelVec, contentData, scrollView, true, isClearInputContent )
    return cell
end

--顶部添加cell
function RAChatUIPage:createChatTopCell( channelPanelVec, contentData, scrollView )
    local cell = self:createChatCell( channelPanelVec, contentData, scrollView, false, false )
    return cell
end

function RAChatUIPage:createChatCell( channelPanelVec, contentData, scrollView, isPushBack, isClearInputContent )
    -- body
    local cell = CCBFileCell:create()
    local pisOtherPlayer = true
    local ccbiStr

    local playerId, serverPlayerId = RAPlayerInfoManager.getPlayerId(), contentData.playerId
    local result = string.find(serverPlayerId, playerId)
    if nil ~= result then --如果是我自己的聊天内容
        ccbiStr = "RAChatMyCellNew.ccbi"
        pisOtherPlayer = false
        if nil ~= isClearInputContent and isClearInputContent then
            self:afterSendMsgUIHandler()
        end
    else
        ccbiStr = "RAChatOthersCellNew.ccbi"
        pisOtherPlayer = true
    end
    local mTag = (#channelPanelVec+1)
    local panel = RAChatUIPageCell:new({
            mIsOtherPlayer = pisOtherPlayer,
            mChatData = contentData,
            mTag = (#channelPanelVec+1),
            mScrollView = scrollView
    })
        
    cell:registerFunctionHandler(panel)
    --set the z orde so that copy, shield node can be seen
    cell:setZOrder(mTag)
    panel.selfCell = cell
    cell:setAnchorPoint(CCPointMake(0,1))
    cell:setCCBFile(ccbiStr)
    if isPushBack then
        scrollView:addCellBack(cell)
        table.insert(channelPanelVec, panel)
    else
        scrollView:addCellFront(cell)
        table.insert(channelPanelVec, 1, panel)
    end

    return cell
end

--------------------------------------------------------------
-----------------------聊天输入框处理-------------------------
--------------------------------------------------------------
--点击聊天框
local InputChatListener = {}

function InputChatListener:onInputboxOK(listener)
    --CCLuaLog("onInputboxOK")
    local input = listener:getResultStr()
    if input ~= nil and input ~= "" then
        RAChatManager.MsgString = cjson.decode(input).content
        RAChatUIPage:setInputBoxLabelString()
    end
    listener:delete()
end

function InputChatListener:onInputboxCancel(listener)
    listener:delete()
end

function RAChatUIPage:setInputBoxLabelString()
    --UIExtend.setCCLabelString(self.ccbfile, "mINputLabel", RAChatManager.MsgString)
end

function RAChatUIPage:setChatButtonIcon(worldChatIcon,allianceIcon)
    --UIExtend.setSpriteImage(self.ccbfile, {mWorldIcon = worldChatIcon})
    --UIExtend.setSpriteImage(self.ccbfile, {mAllianceIcon = allianceIcon})
end

--------------------------------------------------------------
-----------------------事件处理-------------------------------
--------------------------------------------------------------

--点击世界频道按钮
function RAChatUIPage:onWorldChatBtn()
    -- body
    RAChatManager:changeChoosenTabToWorld()

    --self:setChatButtonIcon(RAChatData.CHAT_ICON.Chat_Icon_World_Sel,RAChatData.CHAT_ICON.Chat_Icon_Alliance_Nor)

    local mBtns = {}
    mBtns["mWorldChatBtn"] = true
    mBtns["mAllianceChatBtn"] = false
    mBtns["mCustomChatBtn"] = false
    UIExtend.setControlButtonSelected( self.ccbfile, mBtns )

    self.mWorldScrollView:setVisible(true)
    self.mAllianceScrollView:setVisible(false)

    self.mAllianceChatBtn:setEnabled(true)
    self.mCustomChatBtn:setEnabled(true)

    --UIExtend.setCCControlButtonEnable(self.ccbfile,"mWorldChatBtn",true)

    --如果没有刷新过数据。关闭面板isRefreshWorld设置成false
    if false == RAChatManager.isRefreshWorld then
        RAChatManager:setIsRefreshWorld(true)
        RAChatManager:setIsRefreshAlliance(false)
        self:refreshWorldSomeChats()
    end
    self:updateAllianceChatTip()
    RAChatManager:updateMainUIBottomTabAndContent()
end

--点击联盟频道按钮
function RAChatUIPage:onAllianceChatBtn()
    RAChatManager:changeChoosenTabToAlliance()

    --self:setChatButtonIcon(RAChatData.CHAT_ICON.Chat_Icon_World_Nor,RAChatData.CHAT_ICON.Chat_Icon_Alliance_Sel)
    local mBtns = {}
    mBtns["mWorldChatBtn"] = false
    mBtns["mAllianceChatBtn"] = true
    mBtns["mCustomChatBtn"] = false
    UIExtend.setControlButtonSelected( self.ccbfile, mBtns )

    self.mWorldScrollView:setVisible(false)
    self.mAllianceScrollView:setVisible(true)
    self.mWorldChatBtn:setEnabled(true)
    --self.mAllianceChatBtn:setEnabled(false)
    self.mCustomChatBtn:setEnabled(true)

    --如果没有刷新过数据。关闭面板isRefreshAlliance设置成false
    if false == RAChatManager.isRefreshAlliance then
        RAChatManager:setIsRefreshWorld(false)
        RAChatManager:setIsRefreshAlliance(true)
        self:refreshAllianceSomeChats()
    end
    self:updateAllianceChatTip()
    RAChatManager:updateMainUIBottomTabAndContent()
end

--点击自定义聊天按钮
function RAChatUIPage:onCustomChatBtn()
    --UIExtend.setCCControlButtonSelected(self.ccbfile, "mWorldChatBtn", false)
    --UIExtend.setCCControlButtonSelected(self.ccbfile, "mAllianceChatBtn", false)
    --UIExtend.setCCControlButtonSelected(self.ccbfile, "mCustomChatBtn", true)

    RARootManager.ShowMsgBox("@NoOpenTips")
end

function RAChatUIPage:updateAllianceChatTip()
    if RAChatManager:isChoosenTabAlliance() then
        if false == RAChatManager.isAllianceChatOpen then
           RAChatUIPage:noAllianceTipContent(true) 
        else
            if RAAllianceManager.selfAlliance==nil then
                RAChatUIPage:noAllianceTipContent(true)
                self.mAllianceScrollView:setVisible(false)
                self.mAllianceChannelData = {}
            else
                RAChatUIPage:noAllianceTipContent(false)
            end    
        end
    else
         RAChatUIPage:noAllianceTipContent(false)
    end
end

--没有联盟提示消息
function RAChatUIPage:noAllianceTipContent(isShow)
    UIExtend.setNodeVisible(self.ccbfile, "mNoAllianceNode", isShow)
    UIExtend.setNodeVisible(self.ccbfile, "mButtomNode", not isShow)
    if nil ~= self.editBox then
        self.editBox:setVisible(not isShow)
    end
end

--------------------------------------------------------------
-----------------------点击事件-------------------------------
--------------------------------------------------------------

--使用喇叭触摸事件
function RAChatUIPage:onBroadCastBtn()
    RARootManager.OpenPage("RAChatNoticeUIPage",nil,false,true,true)
end 

local function editboxEventHandler(eventType, node)
    if eventType == "began" then
        RAChatManager.MsgString = RAChatUIPage.editBox:getText()
        -- RAChatUIPage:setInputBoxLabelString()
        RAChatUIPage:resetEditAreaContentSize()
    elseif eventType == "changed" then
        -- CCLuaLog('CHAT changed')
        RAChatManager.MsgString = RAChatUIPage.editBox:getText()
        
        if #RAChatManager.MsgString == 0 then 
            RAChatUIPage.mSendBtn:setEnabled(false)
        else
            RAChatUIPage.mSendBtn:setEnabled(true)
        end 
        -- RAChatUIPage:setInputBoxLabelString()
        RAChatUIPage:resetEditAreaContentSize()

    elseif eventType == "ended" then
        CCLuaLog('CHAT ended')
        RAChatManager.MsgString = RAChatUIPage.editBox:getText()
        RAChatUIPage:setInputBoxLabelString()
        RAChatUIPage:resetEditAreaContentSize()
    elseif eventType == "return" then
    end
end


--重置聊天区域框的尺寸，高度
function RAChatUIPage:resetEditAreaContentSize()
    local perfersize = self.editBox:getLabelContentSize()
    --底图
    local mBottomBG1 = UIExtend.getCCScale9SpriteFromCCB(self.ccbfile, "mInputBG1")
    local mBottomBG2 = UIExtend.getCCScale9SpriteFromCCB(self.ccbfile, "mInputBG2")
    local mBottomBG3 = UIExtend.getCCScale9SpriteFromCCB(self.ccbfile, "mInputBG3")
    -- mBottomBG1:setContentSize(439, perfersize.height+30)
    -- mBottomBG2:setContentSize(104, perfersize.height+30)
    -- mBottomBG3:setContentSize(104, perfersize.height+30)

    local height = perfersize.height + 20

    mBottomBG1:setContentSize(439, height)
    mBottomBG2:setContentSize(104, height)
    mBottomBG3:setContentSize(104, height)

    --发送按钮 
    -- local mSendBtnSizeHeight = self.mSendBtn:getContentSize().height
    -- local mSendBtnPosY = self.mSendBtn:getPositionY()
    -- local mSendBtnFinalPosY = perfersize.height - mSendBtnSizeHeight - 12
    self.mSendBtn:setPositionY((height - 68))
    -- --mSendBtn:setPositionX(mSendBtn:getPositionX() + 10)
    -- self.mSendBtn:setPositionX(259)
    -- --左侧喇叭   
    --local mBottomBtnNode = UIExtend.getCCNodeFromCCB(self.ccbfile,"mBottomBtnNode")
    -- local mBroadCastBtn = UIExtend.getCCControlButtonFromCCB(self.ccbfile,"mBroadCastBtn")
    -- local mBroadCastBtnSizeHeight = mBroadCastBtn:getContentSize().height
    -- local mBottomBtnNodePosY = mBottomBtnNode:getPositionY()
    -- local mBottomBtnNodeFinalPosY = perfersize.height - mBroadCastBtnSizeHeight - 3
    local mBroadCastBtn = UIExtend.getCCControlButtonFromCCB(self.ccbfile,"mBroadCastBtn")
    mBroadCastBtn:setPositionY((height - 68))

    --local perfersizeW, perfersizeH = perfersize.width, perfersize.height
end

function RAChatUIPage:initEditBox()
    local sprite = UIExtend.getCCScale9SpriteFromCCB(self.ccbfile, "mInputSprite")
    sprite:setContentSize(390,52)
    local size = sprite:getContentSize()

    sprite:removeFromParentAndCleanup(true)

    local editbox = nil 
    if CC_TARGET_PLATFORM_LUA == CC_PLATFORM.CC_PLATFORM_IOS or CC_TARGET_PLATFORM_LUA == CC_PLATFORM.CC_PLATFORM_ANDROID then
        editbox = CCNewEditBox:create(size, sprite,nil,nil,true,kEditBoxCloseKeybroadChat)
        editbox:setIsAutoFitHeight(true)
    else
    	editbox = CCEditBox:create(size, sprite)
    end
    local x, y = sprite:getPositionX(), sprite:getPositionY()
    local offsetW, offsetH = sprite:getContentSize().width/2, sprite:getContentSize().height/2

    local mBroadCastBtn = UIExtend.getCCControlButtonFromCCB(self.ccbfile,"mBroadCastBtn")
    local mBroadCastBtnSizeWidth = mBroadCastBtn:getContentSize().width - 2

    editbox:setPosition(CCPointMake(mBroadCastBtnSizeWidth, y-offsetH+4))
    editbox:setAnchorPoint(CCPointMake(0, 0))
    self.ccbfile:addChild(editbox)

    local RAGameConfig = RARequire("RAGameConfig")
    editbox:setIsDimensions(true)
    editbox:setFontName(RAGameConfig.DefaultFontName)
    editbox:setFontSize(27)
    editbox:setAlignment(0)
    editbox:setFontColor(RAGameConfig.COLOR.BLACK)

    editbox:setInputMode(kEditBoxInputModeAny)
    editbox:setMaxLength(200)
    editbox:registerScriptEditBoxHandler(editboxEventHandler)
    self.editBox = editbox

    self.editBox:setVisible(false)
    self.editBox:setText(RAChatManager.MsgString)
    self:resetEditAreaContentSize()
end

--粘贴点击事件
function RAChatUIPage:onPasteBtn()
    --UIExtend.setNodeVisible(self.ccbfile, "mPasteBtnNode", false)--粘贴按钮
end

--点击发送消息
function RAChatUIPage:onSendBtn()
    local curTime = common:getCurTime()  
    local mulTime = curTime - self.lastSendTime
    local errorText = ""

    if mulTime < 0.5 then
        CCLuaLog("RAChatUIPage:onSendBtn():input content too often")
        errorText = "@chatInputTooOften"
    elseif RAChatManager.MsgString == nil or RAChatManager.MsgString == "" or Utilitys.trim(RAChatManager.MsgString)=="" then
        CCLuaLog("RAChatUIPage:onSendBtn():input content not be nil")
        errorText = "@chatInputNil"
    elseif RAChatManager:isChoosenTabAlliance()==true then
        if false == RAChatManager.isAllianceChatOpen then
            errorText = "@chatAllianceNotOpen"
        elseif RAAllianceManager.selfAlliance==nil then
            errorText = "@CreateAllianceWillCreateChatRoom"    
        end    
    else
        
    end
    if string.find(RAChatManager.MsgString, "@3d") ~= nil then
        RARootManager.OpenPage("RATest3DPage", {str = RAChatManager.MsgString}, true)
        return
    end

    if string.find(RAChatManager.MsgString, "@gm") ~= nil then
        local RAGameConfig = RARequire("RAGameConfig")
        local RAStringUtil = RARequire('RAStringUtil')
        local paramList = RAStringUtil:split(RAChatManager.MsgString, ";") 
        for i = 2, #paramList do
            local param = RAStringUtil:split(paramList[i], "=")
            RAGameConfig[param[1]] = param[2] or true
            if RAGameConfig[param[1]] == "false" then
                RAGameConfig[param[1]] = false
            end
        end
        RARootManager.ShowMsgBox("设置成功")
        self:onClose()
        return
    end

    if errorText ~= "" then
        local errorStr = _RALang(errorText)
        local data = {labelText = errorStr}
        RARootManager.showConfirmMsg(data)
    else
        self.mSendBtn:setEnabled(false)
        self:sendChatContents(false)
        self.lastSendTime = curTime    
    end
end

function RAChatUIPage:sendChatContents(isUseHorn)
    local RAStringUtil = RARequire('RAStringUtil')
    RAChatManager.MsgString = RAStringUtil:replaceToStarForChat(RAChatManager.MsgString)
    RAChatManager:sendChatContent(RAChatManager.MsgString,self.isUseHorn)
end

function RAChatUIPage:afterSendMsgUIHandler()
    RAChatManager.MsgString = ""
    --UIExtend.setCCLabelString(self.ccbfile, "mInputLabel", "")
    self.editBox:setText("")
    self:resetEditAreaContentSize()
end

--没有联盟点击事件
function RAChatUIPage:onNoAllianceBtn()
    if false==RAChatManager.isAllianceChatOpen then
        local str = _RALang("@NoOpenTips")
        RARootManager.ShowMsgBox(str)
    else    
        if RAAllianceManager.selfAlliance == nil then 
            RARootManager.OpenPage("RAAllianceJoinPage")
        else
            RARootManager.OpenPage("RAAllianceMainPage")
        end
    end
end

--关闭面板
function RAChatUIPage:onClose()
    self:ChangeShowStatus(false)
end

--退出页面处理操作
function RAChatUIPage:Exit()
    self:removeMessageHandler()
    self:resetData()
    self.mLayer:removeFromParentAndCleanup(true)
    UIExtend.unLoadCCBFile(self)
end

--重置数据
function RAChatUIPage:resetData()
    self.mWorldScrollView:removeAllCell()
    self.mAllianceScrollView:removeAllCell()
    RAChatManager:setIsRefreshWorld( false )
    RAChatManager:setIsRefreshAlliance( false )
    self.mWorldPanelVec = {}
    self.mAlliancePanelVec = {}

    p_lastWorldTime = 0
    p_lastAllianceTime = 0

    if self.mWorldScrollView~=nil then
        self.mWorldScrollView:removeAllCell()
        self.mWorldScrollView:unregisterFunctionHandler()
    end
    self.mWorldScrollView    = nil

    if self.mAllianceScrollView~=nil then
        self.mAllianceScrollView:removeAllCell()
        self.mAllianceScrollView:unregisterFunctionHandler()
    end
    self.mAllianceScrollView = nil

    self.mWorldChatBtn       = nil
    self.mAllianceChatBtn    = nil
    self.mCustomChatBtn      = nil

    self.editBox:removeFromParentAndCleanup(true)
    self.editBox = nil
    self.isUseHorn = false

    LastMsgTime.world=0
    LastMsgTime.alliance=0
end

--------------------------------------------------------------
-----------------------动画处理-------------------------------
--------------------------------------------------------------
function RAChatUIPage:OnAnimationDone(ccbfile)
    --body
    local lastAnimationName = ccbfile:getCompletedAnimationName()       
    if lastAnimationName == "OutAni" then
        RARootManager.ClosePage("RAChatUIPage")
    end

    if lastAnimationName == "InAni" then
        --打开聊天，且页签为联盟
        if RAChatManager:isChoosenTabAlliance() then
            --1.如果有联盟
            if nil == RAAllianceManager.selfAlliance then
                self.editBox:setVisible(false)
            else
                self.editBox:setVisible(true)
            end
        else
            --todo
            self.editBox:setVisible(true)
        end
    end 
end

function RAChatUIPage:ChangeShowStatus(isShow)
    --body
    local aniName
    if isShow then
        aniName = "InAni"        
    else
        aniName = "OutAni"  
        self.editBox:setVisible(false)     
    end
    if self.ccbfile ~= nil then
        self:AllCCBRunAnimation(aniName)
    else
        CCLuaLog("RAChatUIPage:getAnimationCmd ccbi is nil")
    end
end

return RAChatUIPage