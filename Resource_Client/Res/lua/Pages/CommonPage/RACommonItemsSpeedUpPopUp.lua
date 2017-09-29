--[[加速道具使用二级面板]]
--sunyungao

RARequire("BasePage")

local RARootManager = RARequire("RARootManager")
local UIExtend = RARequire('UIExtend')
local RACoreDataManager = RARequire("RACoreDataManager")
local RAPackageManager  = RARequire("RAPackageManager")
local common   = RARequire("common")
local Utilitys = RARequire("Utilitys")
local RAPackageData = RARequire("RAPackageData")
local Const_pb = RARequire("Const_pb")
local RAQueueUtility = RARequire("RAQueueUtility")
local RAStringUtil = RARequire("RAStringUtil")
local RAPlayerInfoManager = RARequire('RAPlayerInfoManager')
local RAQueueManager = RARequire("RAQueueManager")


local RACommonItemsSpeedUpPopUp = BaseFunctionPage:new(...)

local m_FrameTime  = 0
local m_itemData   = {}
local m_panelVec   = {}
local m_selectedIndex = 1 --选中物品的索引

function RACommonItemsSpeedUpPopUp:resetData()
	--todo
	m_FrameTime = 0
	m_selectedIndex = 1
	m_itemData   = {}
	m_panelVec = {}
end

--data:队列数据 RAQueueData
function RACommonItemsSpeedUpPopUp:Enter(data)
	self:resetData()
	local ccbfile = UIExtend.loadCCBFile("RACommonItemsSpeedUpPopUp.ccbi", RACommonItemsSpeedUpPopUp)
	self.ccbfile  = ccbfile
	self.data     = data

	self:registerMessageHandlers()
	self:initUI()

    --新手期的话，需要完全弹出后，才能正确走到下一步（圈住使用按钮）
    performWithDelay(self:getRootNode(), function()
        local RAGuideManager = RARequire("RAGuideManager")
        if RAGuideManager.isInGuide() then
            RAGuideManager.gotoNextStep()
        end
end, 1)
    
end

local RACommonItemsSpeedUpCell = 
{
	new = function(self, o )
		-- body
		o = o or {}
	    setmetatable(o,self)
	    self.__index = self    
	    return o
	end,

	onRefreshContent = function (self, ccbRoot )
		-- body
		CCLuaLog("RACommonItemsSpeedUpCell:onRefreshContent")
		if not ccbRoot then return end
		local ccbfile = ccbRoot:getCCBFileNode() 
		self.ccbfile = ccbfile

		if self.index == m_selectedIndex then
			--todo
			self:setSelectedState(true)
		else
			--todo
			self:setSelectedState(false)
		end
	    
		--物品icon
		RAPackageData.addBgAndPicToItemGrid( self.ccbfile, "mIconNode", self.cellData.conf )

		UIExtend.setCCLabelString(self.ccbfile,"mItemNum", self.cellData.server.count)
	end,

	setSelectedState = function ( self, isSelected )
		-- body
		if nil ~= self.ccbfile then
			UIExtend.setMenuItemSelected( self.ccbfile, {mSelectItemBtn = isSelected} )
		end
	end,

	--点击按钮事件
	onSelectItemBtn = function (self)
		-- body
		for k,v in pairs(m_panelVec) do
			--print(k,v)
			v:setSelectedState(false)
		end
		self:setSelectedState(true)
		m_selectedIndex = self.index

		RACommonItemsSpeedUpPopUp:updateSliderProAndTimeLabel()
	end
}

--desc:获得按钮信息
function RACommonItemsSpeedUpPopUp:getGuideNodeInfo()
    local useBtn = self.ccbfile:getCCNodeFromCCB("mUseBtn")
    local worldPos =  useBtn:getParent():convertToWorldSpaceAR(ccp(useBtn:getPositionX(),useBtn:getPositionY()))
    local size = useBtn:getContentSize()
    local guideData = {
        ["pos"] = worldPos,
        ["size"] = size
    }
    return guideData
end

function RACommonItemsSpeedUpPopUp:sliderBegan( sliderNode )
	-- body
end
function RACommonItemsSpeedUpPopUp:sliderMoved( sliderNode )
	-- body
	self:refreshSliderValue()
end
function RACommonItemsSpeedUpPopUp:sliderEnded( sliderNode )
	-- body
	self:refreshSliderValue()
end

function RACommonItemsSpeedUpPopUp:initUI()
	-- body
    local titleTxt = RAQueueUtility.getQueueNeedDoItRight( self.data.queueType )
	UIExtend.setCCLabelString(self.ccbfile,"mPopUpTitle", titleTxt)

    local controlSlider = UIExtend.getControlSlider("mSliderBarNode", self.ccbfile)
	controlSlider:registerScriptSliderHandler(self)
	self.controlSlider = controlSlider
  	
    self:refreshScrollViewData()
    self:refreshTimeBar()
    self:setUseBtnEnable(true)
end


function RACommonItemsSpeedUpPopUp:refreshScrollViewData()
	-- body
	local speedType = self:getSpeedUpTypeByQueueType(self.data.queueType)
	local pageData = RACoreDataManager:getAccelerateDataByType( speedType )
	m_itemData = pageData
	--如果没有道具，处理
	if not next(m_itemData) then
		--todo
		self:onClose()
	end
	self.scrollView = self.ccbfile:getCCScrollViewFromCCB("mSpeedUpListSV")
	self.scrollView:removeAllCell()
	m_panelVec = {}

	if m_selectedIndex > #pageData then
    	m_selectedIndex = 1
    end

    for k,v in pairs(pageData) do 
        local cell = CCBFileCell:create()
		cell:setCCBFile("RACommonItemSpeedUpCell.ccbi")
		local panel = RACommonItemsSpeedUpCell:new({
                cellData = v,
                index = k
        })
		cell:registerFunctionHandler(panel)
		self.scrollView:addCell(cell)
		table.insert(m_panelVec, panel)
    end
    self.scrollView:orderCCBFileCells()

    self:updateSliderProAndTimeLabel()
end

function RACommonItemsSpeedUpPopUp:updateSliderProAndTimeLabel()
	-- body
	self:updateControlSliderProp()
    self:setSliderDefaultValue()
   	self:updateSpeedUpTime()
end

--选中道具初始化选中几个
function RACommonItemsSpeedUpPopUp:setSliderDefaultValue()
	-- body
	if nil == self.controlSlider then
		return
	end

    if m_itemData == nil or 0 == #m_itemData then
        return
    end

	local itemCount  = self:getOneItemCount()
	local maxCount   = self.controlSlider:getMaximumValue()
	local curCount   = maxCount
	if itemCount < maxCount then
		curCount = itemCount
	end
	self.controlSlider:setValue(curCount)
	self:refreshSliderValue()
end

--刷新底部滑动条，按钮显示状态
function RACommonItemsSpeedUpPopUp:refreshButtonVisibleState(isVisible)
	-- body
	UIExtend.setNodeVisible(self.ccbfile, "mSliderNode", isVisible)
	UIExtend.setNodeVisible(self.ccbfile, "mUseNumNode", isVisible)
end

--更新滑动条属性
--每秒调用
--切换物品调用
function RACommonItemsSpeedUpPopUp:updateControlSliderProp()
	-- body
	if m_itemData == nil or 0 == #m_itemData then-- or self:getOneItemCount() == 1
		self:refreshButtonVisibleState(false)
		return
	end

	self:refreshButtonVisibleState(true)
	local needCount = self:calculateNeedItemCount()
	local itemCount = self:getOneItemCount()
	if needCount == 1 or itemCount == 1 then
		self.controlSlider:setMinimumValue(0)
	else
		self.controlSlider:setMinimumValue(1)
	end
	local finalCount = needCount
	if itemCount < needCount then
		finalCount = itemCount
	end
	--最大值取两者(itemCount,needCount)的最小值
	self.controlSlider:setMaximumValue(finalCount)
end

--每次切换物品的时候计算加速了的时间
--切换
--初始化
function RACommonItemsSpeedUpPopUp:updateSpeedUpTime()
	-- body
	if m_itemData == nil or 0 == #m_itemData then
		UIExtend.setNodeVisible(self.ccbfile, "mSpeedUpTime", false)
		UIExtend.setNodeVisible(self.ccbfile, "mUseBtnNode",  false)
		return
	end

	UIExtend.setNodeVisible(self.ccbfile, "mSpeedUpTime", true)
	UIExtend.setNodeVisible(self.ccbfile, "mUseBtnNode",  true)

	local value = self.controlSlider:getValue()
	value = RACommonItemsSpeedUpPopUp:resetSliderValue( value )
	self:calculateSpeedUpTime(value)
end

--滑动完滑条
function RACommonItemsSpeedUpPopUp:refreshSliderValue()
	-- body
	local value = self.controlSlider:getValue()
	value = math.ceil(value)
	value = self:resetSliderValue(value)
	self.controlSlider:setValue(value)

	UIExtend.setCCLabelString(self.ccbfile,"mUseNum", value)
	
	--mSpeedUpTime 加速时间  --mSpeedUpTime 能够加速的时间
	self:calculateSpeedUpTime(value)
end

--减按钮事件
function RACommonItemsSpeedUpPopUp:onSubBtn()
	-- body
	local value = self.controlSlider:getValue()
	value = tonumber(value-1)
	value = self:resetSliderValue(value)
	self.controlSlider:setValue(value)
	local fValue = self.controlSlider:getValue()
	UIExtend.setCCLabelString(self.ccbfile,"mUseNum", fValue)

	self:calculateSpeedUpTime(fValue)
end

--加按钮事件
function RACommonItemsSpeedUpPopUp:onAddBtn()
	-- body
	local value = self.controlSlider:getValue()
	value = tonumber(value+1)
	value = self:resetSliderValue(value)
	self.controlSlider:setValue(value)
	local fValue = self.controlSlider:getValue()
	UIExtend.setCCLabelString(self.ccbfile,"mUseNum", fValue)

	self:calculateSpeedUpTime(fValue)
end

--计算时间Label
--加速时间：{0}（免费时间：{1}）
function RACommonItemsSpeedUpPopUp:calculateSpeedUpTime(value)
	-- body
	local oneItemTime = self:getOneItemGiveTime()
	local sumTime = tonumber(oneItemTime) * tonumber(value)
	self.useItemTotalTime = sumTime
	sumTime = Utilitys.second2DateString(sumTime)
	local finalStr = RAStringUtil:getLanguageString("@speedUpTime", sumTime)

    local freeTime = RAPlayerInfoManager.getQueueFreeTime(nil, self.data.queueType)
    --@speedUpTime    加速时间：{0}   @speedFreeTime  （免费时间：{0}）
    if freeTime > 0 then
    	--todo
    	local freeTimeStr = Utilitys.second2DateMinuteString(freeTime)
    	finalStr = finalStr..RAStringUtil:getLanguageString("@speedFreeTime", freeTimeStr)
    end
    
	UIExtend.setCCLabelString(self.ccbfile, "mSpeedUpTime", finalStr)
end

--修正滑动块值
function RACommonItemsSpeedUpPopUp:resetSliderValue( value )
	-- body
	--[[
	local itemCount  = self:getOneItemCount()
	if value > itemCount then
		value = itemCount
	end ]]
	if value <= 0 then
		value = 1
	end
	return value
end

function RACommonItemsSpeedUpPopUp:sureSendSpeedUpByItems()
	local queueId = self.data.id
    local itemId  = m_itemData[m_selectedIndex].server.uuid

    local value = self.controlSlider:getValue()
	if value == 0 then
		value = 1
	end
	--联盟队列加速
	if self.data.queueType == Const_pb.GUILD_SCIENCE_QUEUE then
		RAQueueManager:sendAllianceQueueSpeedUpByItems(queueId, itemId, value)
	else --普通的
		RAQueueManager:sendQueueSpeedUpByItems(queueId, itemId, value)
	end


	self:setUseBtnEnable(false)
	--self:onClose()
end

--点击使用按钮
function RACommonItemsSpeedUpPopUp:onUseBtn()
	--todo
	if m_itemData == nil then
		CCLuaLog("have no item")
		return
	end

	--使用道具的时间
	local useItmetime = self.useItemTotalTime or 0 

	--所需要的时间
	local remainTime = self:getRemainTime()
	

    self.diffTime = useItmetime - remainTime

	if self.diffTime > 0 then
		local resultFun = function (isOK)
	        if isOK then
	        	self:sureSendSpeedUpByItems()
	        end   
	    end

	    local diffTimeStr = Utilitys.second2DateMinuteString(self.diffTime)
	    local confirmData =
	    {
	        labelText = _RALang("@MoreMaximumTime",diffTimeStr),
	        resultFun = resultFun,
	        yesNoBtn = true
	    }
	    RARootManager.showConfirmMsg(confirmData)

	else
		self:sureSendSpeedUpByItems()    
	end   
end

function RACommonItemsSpeedUpPopUp:setUseBtnEnable(isEnable)
	if self.ccbfile then
		UIExtend.setCCControlButtonEnable(self.ccbfile, "mUseBtn", isEnable)
	end
end

function RACommonItemsSpeedUpPopUp:onClose()
    CCLuaLog("RACommonItemsSpeedUpPopUp:onClose")
    RARootManager.ClosePage("RACommonItemsSpeedUpPopUp")
end

function RACommonItemsSpeedUpPopUp:Execute()
	--todo
	m_FrameTime = m_FrameTime + common:getFrameTime()
    if m_FrameTime > 1 then
    	--CCLuaLog("RACommonItemsSpeedUpPopUp:Execute")
        self:refreshTimeBar()
        m_FrameTime = 0 
    end
end	

function RACommonItemsSpeedUpPopUp:refreshTimeBar()
	-- body
	local isPassed = Utilitys.isTimePassedCurrent(self.data.endTime)
    if isPassed then
    	self:onClose()
    	return
    end

	local remainTime = Utilitys.getCurDiffTime(self.data.endTime)
    local tmpStr = Utilitys.createTimeWithFormat(remainTime)
    UIExtend.setCCLabelString(self.ccbfile, "mCDTime", tmpStr)

    local scaleX = RAQueueUtility.getTimeBarScale(self.data) 
    
    local pBar = UIExtend.getCCScale9SpriteFromCCB(self.ccbfile, "mBar")
    pBar:setScaleX(scaleX)

    self:updateControlSliderProp()
end

--计算当前选中道具需要几个才能加速完
function RACommonItemsSpeedUpPopUp:calculateNeedItemCount()
	-- body
	local oneTime    = self:getOneItemGiveTime()
	local remainTime = self:getRemainTime()

	local freeTime = RAPlayerInfoManager.getQueueFreeTime(nil, self.data.queueType)

    if freeTime > 0 then
    	remainTime = remainTime - freeTime
    end

	local needCount = math.floor(remainTime/oneTime)
	return needCount
end

--一个道具能加速的时间
function RACommonItemsSpeedUpPopUp:getOneItemGiveTime()
	-- body
	local giveTime = m_itemData[m_selectedIndex].conf.speedUpTime 
	return giveTime or 0
end

--一个道具格子的道具数量
function RACommonItemsSpeedUpPopUp:getOneItemCount()
	-- body

	local itemCount = m_itemData[m_selectedIndex].server.count
	return itemCount or 0
end

--获取剩下的时间
function RACommonItemsSpeedUpPopUp:getRemainTime()
	-- body
	local remainTime = Utilitys.getCurDiffTime(self.data.endTime)
--[[
	local freeTime = RAPlayerInfoManager.getQueueFreeTime(nil, self.data.queueType)
	if freeTime <= 0 then
		return remainTime
	end

    remainTime = remainTime - freeTime
    if remainTime < 0 then
    	remainTime = 0
    end
]]
	return remainTime
end

function RACommonItemsSpeedUpPopUp:Exit()
	--    
	self:resetData()
	self:unregisterMessageHandlers()
	if nil ~= self.controlSlider then
		--todo
		self.controlSlider:removeFromParentAndCleanup(true)
	    self.controlSlider = nil
	end
	if self.scrollView then
		self.scrollView:removeAllCell()
		self.scrollView = nil
	end
    UIExtend.unLoadCCBFile(RACommonItemsSpeedUpPopUp)
end

local OnReceiveMessage = function(message)    
	--body
    CCLuaLog("RACommonItemsSpeedUpPopUp OnReceiveMessage id:"..message.messageID)

    if message.messageID == MessageDef_Queue.MSG_Common_UPDATE then
    	--todo
    	RACommonItemsSpeedUpPopUp:refreshMSG_Common_UPDATE(message.queueId, message.queueType)
    elseif message.messageID == MessageDef_Queue.MSG_Common_DELETE then
    	--todo
    	if RACommonItemsSpeedUpPopUp.data.id == message.queueId and RACommonItemsSpeedUpPopUp.data.queueType == message.queueType then
    		--todo
    		RACommonItemsSpeedUpPopUp:onClose()
    	end
    elseif message.messageID == MessageDef_package.MSG_package_consume_accelerate_item then
    	--todo
    	RACommonItemsSpeedUpPopUp:refreshScrollViewData()
    elseif message.messageID == MessageDef_Packet.MSG_Operation_OK then
        local opcode = message.opcode
		if opcode==HP_pb.QUEUE_SPEED_UP_C then
			RACommonItemsSpeedUpPopUp:setUseBtnEnable(true)

			local freeTime = RAPlayerInfoManager.getQueueFreeTime(nil, RACommonItemsSpeedUpPopUp.data.queueType)
		    local remainTime = RACommonItemsSpeedUpPopUp:getRemainTime()
		    if freeTime > remainTime then
		    	RACommonItemsSpeedUpPopUp:onClose()
		    end
		end
    end
end

--如果已经到免费时间内，关闭面板
--如果没到免费时间内，刷新队列数据
function RACommonItemsSpeedUpPopUp:refreshMSG_Common_UPDATE(queueId, queueType)
	-- body
	if self.data.id == queueId and self.data.queueType == queueType then
    	--todo
    	local queueData = RAQueueManager:getQueueData(queueType, queueId)
       	local freeTime = RAPlayerInfoManager.getQueueFreeTime(nil, self.data.queueType)--当前队列的免费时间
		local endTime  = self.data.endTime
		if freeTime > 0 then
		    endTime = self.data.endTime - freeTime
		end
		local isPassed = Utilitys.isTimePassedCurrent(self.data.endTime)
		if isPassed then
			--todo
			self:onClose()
		else
			--todo
			self.data = queueData
    		self:refreshTimeBar()
		end
    end
end

function RACommonItemsSpeedUpPopUp:registerMessageHandlers()
	--todo
    MessageManager.registerMessageHandler(MessageDef_Queue.MSG_Common_UPDATE, OnReceiveMessage)
    MessageManager.registerMessageHandler(MessageDef_Queue.MSG_Common_DELETE, OnReceiveMessage)
    MessageManager.registerMessageHandler(MessageDef_package.MSG_package_consume_accelerate_item, OnReceiveMessage)
    MessageManager.registerMessageHandler(MessageDef_Packet.MSG_Operation_OK, OnReceiveMessage)

end

function RACommonItemsSpeedUpPopUp:unregisterMessageHandlers()
	--todo
    MessageManager.removeMessageHandler(MessageDef_Queue.MSG_Common_UPDATE, OnReceiveMessage)
    MessageManager.removeMessageHandler(MessageDef_Queue.MSG_Common_DELETE, OnReceiveMessage) 
    MessageManager.removeMessageHandler(MessageDef_package.MSG_package_consume_accelerate_item, OnReceiveMessage)
    MessageManager.removeMessageHandler(MessageDef_Packet.MSG_Operation_OK, OnReceiveMessage)
end

function RACommonItemsSpeedUpPopUp:getSpeedUpTypeByQueueType(queueType)
	-- body
	local speedUpType = RAPackageData.SPEED_UP_TYPE.common
	if queueType == Const_pb.BUILDING_QUEUE then
		speedUpType = RAPackageData.SPEED_UP_TYPE.func--城建队列
	elseif queueType == Const_pb.BUILDING_DEFENER then
		speedUpType = RAPackageData.SPEED_UP_TYPE.defent--防御建筑
	elseif queueType == Const_pb.SCIENCE_QUEUE then
		speedUpType = RAPackageData.SPEED_UP_TYPE.science--科技队列
	elseif queueType == Const_pb.SOILDER_QUEUE then
		speedUpType = RAPackageData.SPEED_UP_TYPE.soldier--造兵队列
	elseif queueType == Const_pb.CURE_QUEUE then
		speedUpType = RAPackageData.SPEED_UP_TYPE.cure--治疗伤兵
	elseif queueType == Const_pb.EQUIP_QUEUE then
		speedUpType = RAPackageData.SPEED_UP_TYPE.equip--装备队列
	elseif queueType == Const_pb.MARCH_QUEUE then
		speedUpType = RAPackageData.SPEED_UP_TYPE.march--行军队列
	elseif queueType == Const_pb.GUILD_SCIENCE_QUEUE then 
		speedUpType = RAPackageData.SPEED_UP_TYPE.statue --联盟雕像队列
	end

    return speedUpType
end

return RACommonItemsSpeedUpPopUp