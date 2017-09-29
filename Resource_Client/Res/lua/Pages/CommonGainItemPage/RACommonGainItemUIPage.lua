--通用道具使用界面
--by sunyungao


local UIExtend         = RARequire("UIExtend")
local RACommonGainItemManager = RARequire("RACommonGainItemManager")
local RACommonUseItemCellHandler = RARequire("RACommonUseItemCellHandler")
local RACommonTitleHelper = RARequire('RACommonTitleHelper')
local RARootManager = RARequire("RARootManager")
local RACommonGainItemData = RARequire("RACommonGainItemData")
local common = RARequire('common')
local Utilitys = RARequire('Utilitys')

local RACommonGainItemUIPage  = BaseFunctionPage:new(...)

RACommonGainItemUIPage.data = nil
RACommonGainItemUIPage.scrollView = nil
RACommonGainItemUIPage.mIsExecute = false
RACommonGainItemUIPage.mLastUpdateTime = 0

function RACommonGainItemUIPage:getCCBFileName(itemType)
    if itemType == RACommonGainItemData.GAIN_ITEM_TYPE.marchAccelerate then
        return 'RACommonGainAdditionPage2.ccbi'
    end        
    return 'RACommonGainAdditionPage.ccbi'
end

function RACommonGainItemUIPage:Enter(data)
    local ccbfileName = self:getCCBFileName(data.itemType)	
	local ccbfile = UIExtend.loadCCBFile(ccbfileName, self)
	self.ccbfile  = ccbfile
	self.data     = data

    self.scrollView = UIExtend.getCCScrollViewFromCCB(self.ccbfile, "mGainAdditionListSV")

    local titleCCB = UIExtend.getCCBFileFromCCB(self.ccbfile, "mCommonTitleCCB")
    local backCallBack = function()
        RARootManager.CloseCurrPage()
    end

    local titleName = _RALang(RACommonGainItemData.GAIN_ITEM_TITLE_NAME[self.data.itemType])
    local titleHandler = RACommonTitleHelper:RegisterCommonTitle('RACommonGainItemUIPage', titleCCB, titleName, backCallBack, RACommonTitleHelper.BgType.Blue)
    if data.itemType == RACommonGainItemData.GAIN_ITEM_TYPE.marchAccelerate then
        self.mIsExecute = true
    else
        self.mIsExecute = false
    end

    self.targetMarchId = self.data.marchId

    self:registerMessage()    
    self:refreshByItemType()
	self:initData()
    self:refreshScrollView()
end


function RACommonGainItemUIPage:Execute()
    if not self.mIsExecute then return end
    self.mLastUpdateTime = self.mLastUpdateTime + common:getFrameTime()
    if self.mLastUpdateTime > 1 then
        self.mLastUpdateTime = 0
        self:refreshByItemType()
    end
end

function RACommonGainItemUIPage:Exit()
    RACommonTitleHelper:RemoveCommonTitle("RACommonGainItemUIPage")
    self.scrollView:removeAllCell()
    self:removeMessageHandler()
    self.ccbfile:stopAllActions()

    self.data = nil
    self.scrollView = nil
    self.mLastUpdateTime = 0
    self.mIsExecute = false
    self.targetMarchId = ''

    UIExtend.unLoadCCBFile(self)
end


--初始化ui
function RACommonGainItemUIPage:initData()
    --刷新配置数据
    RACommonGainItemManager:updateConfigData(self.data)    
end

-- 根据道具类型，刷新UI
function RACommonGainItemUIPage:refreshByItemType()
    local ccbfile = self.ccbfile
    local itemType = self.data.itemType
    if ccbfile == nil then return end    
    -- 加速行军的道具，需要刷新倒计时
    if itemType == RACommonGainItemData.GAIN_ITEM_TYPE.marchAccelerate then
        local RAMarchDataManager = RARequire('RAMarchDataManager')
        local marchData = RAMarchDataManager:GetMarchDataById(self.data.marchId)
        self.targetMarchId = self.data.marchId
        if marchData ~= nil then
            local startTime = marchData.startTime / 1000
            local endTime = marchData.endTime / 1000
            local lastTime = marchData:GetLastTime()
            local leaderData = RAMarchDataManager:GetTeamLeaderMarchData(marchData.marchId)
            if leaderData ~= nil then
                startTime = leaderData.startTime / 1000
                endTime = leaderData.endTime / 1000
                lastTime = leaderData:GetLastTime()
                self.targetMarchId = leaderData.marchId
            end
            if lastTime < 1 then
                self.mIsExecute = false
                RARootManager.ClosePage('RACommonGainItemUIPage')
                return
            end
            local totalTime = marchData.marchJourneyTime / 1000
            if totalTime == 0 then
                totalTime = endTime - startTime
            end
            local lbKey = ''
            if marchData.marchStatus == World_pb.MARCH_STATUS_MARCH then
                lbKey = '@Marching'
            else
                lbKey = '@Retruning'
            end
            local tmpStr = Utilitys.createTimeWithFormat(lastTime)
            if lbKey ~= '' then
                tmpStr = _RALang(lbKey, tmpStr)
            end
            UIExtend.setCCLabelString(ccbfile, "mStateTime", tmpStr)
            
            -- 计算scale9缩放
            local percent = lastTime / totalTime
            if percent < 0 then percent = 0 end
            if percent > 1 then percent = 1 end
            UIExtend.setCCScale9SpriteScale(ccbfile, "mBar", 1 - percent, true)
        end
    end
end


-----------------------刷新数据-------------------------------
--更新物品
function RACommonGainItemUIPage:refreshScrollView()
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
end




--------------------------------------------------------------
-----------------------消息处理-------------------------------
--------------------------------------------------------------

local OnReceiveMessage = function(message)
    --todo
    --CCLuaLog("类型。。" .. message.type)
    if message.messageID == MessageDef_package.MSG_package_consume_item then
        --todo
        RACommonGainItemUIPage:refreshByItemType()
        RACommonGainItemUIPage:initData()
        RACommonGainItemUIPage:refreshScrollView()
    end
end
--注册监听消息
function RACommonGainItemUIPage:registerMessage()
    --todo
    MessageManager.registerMessageHandler(MessageDef_package.MSG_package_consume_item, OnReceiveMessage)
end

function RACommonGainItemUIPage:removeMessageHandler()
    --todo
   MessageManager.removeMessageHandler(MessageDef_package.MSG_package_consume_item, OnReceiveMessage)
end


--------------------------------------------------------------
-----------------------事件处理-------------------------------
--------------------------------------------------------------
