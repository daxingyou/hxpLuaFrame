--医院界面
--by sunyungao


local UIExtend         = RARequire("UIExtend")
local RAHospitalUICell = RARequire("RAHospitalUICell")
local RAHospitalManager   = RARequire("RAHospitalManager")
local RACoreDataManager   = RARequire("RACoreDataManager")
local RAQueueManager = RARequire("RAQueueManager")
local RARootManager = RARequire("RARootManager")
local common = RARequire("common")
local Const_pb = RARequire("Const_pb")
local build_conf = RARequire("build_conf")
local RALogicUtil = RARequire("RALogicUtil")
local Utilitys = RARequire("Utilitys")
local RAPackageData = RARequire("RAPackageData")
local RACommonTitleHelper = RARequire('RACommonTitleHelper')
local RAGameConfig = RARequire("RAGameConfig")
local RAPlayerInfoManager = RARequire("RAPlayerInfoManager")
local RAQueueUtility = RARequire("RAQueueUtility")
local mFrameTime = 0
local mBuildData = nil 

RARequire("MessageDefine")
RARequire("MessageManager")

local RAHospitalUIPage  = BaseFunctionPage:new(...)

function RAHospitalUIPage:Enter(data)

	CCLuaLog("RAHospitalUIPage:Enter")
	local ccbfile = UIExtend.loadCCBFile("RAArmyHealPage.ccbi", RAHospitalUIPage)
	
    mBuildData = data
    self:registerMessage()
    self:initTitle()
	self:init()
end

function RAHospitalUIPage:Execute()
    --todo
    mFrameTime = mFrameTime + common:getFrameTime()
    if mFrameTime > 1 then
        self:scheduleUpdate()
        mFrameTime = 0 
    end
end

function RAHospitalUIPage:Exit()

    RAHospitalManager:resetData()
    RAHospitalUIPage:removeMessageHandler()
    RACommonTitleHelper:RemoveCommonTitle("RAHospitalUIPage")
    self.scrollView:removeAllCell()
    UIExtend.unLoadCCBFile(self)
    mFrameTime = 0
    if nil ~= self.panelCellVec then
        for k,v in pairs(self.panelCellVec) do
            --print(k,v)
            v:Exit()
        end
        self.panelCellVec = {}
    end
end

function RAHospitalUIPage:initTitle()
    local titleCCB = UIExtend.getCCBFileFromCCB(self.ccbfile, "mCommonTitleCCB")
    local backCallBack = function()
        RARootManager.CloseCurrPage()
    end

    local buildId = mBuildData.confData.id
    local name = build_conf[buildId].buildName
    local titleName = _RALang("@Level")..build_conf[buildId].level.._RALang(name)
    local titleHandler = RACommonTitleHelper:RegisterCommonTitle('RAHospitalUIPage', titleCCB, titleName, backCallBack, RACommonTitleHelper.BgType.Blue)
end

--------------------------------------------------------------
-----------------------初始化---------------------------------
--------------------------------------------------------------

--初始化ui
function RAHospitalUIPage:init()
	-- body
    self.scrollView = self.ccbfile:getCCScrollViewFromCCB("mWoundedListSV")

    --最下边按钮
    self.mBottomNode    = UIExtend.getCCNodeFromCCB(self.ccbfile, "mBottomNode")
    self.mSelectAllBtn  = UIExtend.getCCControlButtonFromCCB(self.ccbfile, "mSelectAllBtn")
    self.mUpgradeNowBtn = UIExtend.getCCControlButtonFromCCB(self.ccbfile, "mTreatmentNowBtn")
    self.mTreatmentBtn  = UIExtend.getCCControlButtonFromCCB(self.ccbfile, "mTreatmentBtn")

    --中间 治疗队列已满蒙版
    self.mQueueMaxNode = UIExtend.getCCNodeFromCCB(self.ccbfile, "mQueueMaxNode")
    self.mQueueMaxNode:setVisible(false)

    --中间 目前没有伤病需要治疗
    self.mNoWoundedNode = UIExtend.getCCNodeFromCCB(self.ccbfile, "mNoWoundedNode")
    self.mNoWoundedNode:setVisible(false)
    RAHospitalUIPage:refreshInitState()
end

function RAHospitalUIPage:refreshInitState()
    -- body
    RACoreDataManager:refreshArmyWoundedInfo()
    RACoreDataManager:refreshArmyCuringInfo()
    self:refreshTopCureQueue()
    self:refreshWoundedList()

    local curingCount, woundedCount = RAHospitalManager:getCuringAndWoundedCount()
    self:refreshCuringCount(curingCount)
    self:refreshWoundedCount(woundedCount)
end

--顶部队列是否可见，如果可见，隐藏scrollview，底部按钮
function RAHospitalUIPage:setQueueCDBarVisible(isVisible)
    -- body
    --顶部  队列
    UIExtend.setNodeVisible(self.ccbfile, "mTrainingNode", isVisible)
    --中间  治疗队列已满蒙版 
    UIExtend.setNodeVisible(self.ccbfile, "mQueueMaxNode", isVisible)
    --顶部  气氛图
    UIExtend.setNodeVisible(self.ccbfile, "mNoTrainingNode",  not isVisible)
    --底部  四种消耗资源，三个按钮
    UIExtend.setNodeVisible(self.ccbfile, "mBottomNode",      not isVisible)
    --scrollView
    UIExtend.setNodeVisible(self.ccbfile, "mWoundedListNode", isVisible)
end

--------------------------------------------------------------
-----------------------刷新数据-------------------------------
--------------------------------------------------------------


--刷新伤病列表区域
function RAHospitalUIPage:refreshWoundedList()
    -- body
    if 0 ~= RAQueueManager:getQueueCounts(Const_pb.CURE_QUEUE) then --顶部队列出现，不刷新
        --return
    end

    local listData = RACoreDataManager.ArmyWoundedInfoIndex

    --table sort
    listData = RAHospitalManager:ArmySort(listData)

    local size = RACoreDataManager.ArmyWoundedSize
    self.scrollView:removeAllCell()

    if 0 == size then --如果没有伤员了
        --todo
        self.mNoWoundedNode:setVisible(true)--中间 目前没有伤病需要治疗
        UIExtend.setNodeVisible(self.ccbfile, "mWoundedListNode", false)
        self.mBottomNode:setVisible(false)--底部  四种消耗资源，三个按钮
        self.mQueueMaxNode:setVisible(false)--中间  治疗队列已满蒙版
        return
    end

    if 0 ~= RAQueueManager:getQueueCounts(Const_pb.CURE_QUEUE) then --如果顶部有队列
        --return
        self.mNoWoundedNode:setVisible(false)
        UIExtend.setNodeVisible(self.ccbfile, "mWoundedListNode", true)
        self.mBottomNode:setVisible(false)
        self.mQueueMaxNode:setVisible(true)
    else
        --todo
        self.mNoWoundedNode:setVisible(false)
        UIExtend.setNodeVisible(self.ccbfile, "mWoundedListNode", true)
        self.mBottomNode:setVisible(true)
        self.mQueueMaxNode:setVisible(false)
    end
    
    self.panelCellVec = {}

    local scrollView = self.scrollView
    for k,armyInfo in pairs(listData) do
        --CCLuaLog(v)
        local cell = CCBFileCell:create()
        local panel = RAHospitalUICell:new({
                mData = armyInfo,
                uuid  = armyInfo.id,
                sliderValue = armyInfo.woundedCount,
                woundedCountMax = armyInfo.woundedCount
        })
        
        cell:registerFunctionHandler(panel)
        cell:setCCBFile("RAArmyHealCell.ccbi")
        scrollView:addCell(cell)

        table.insert(self.panelCellVec, panel)
    end

    scrollView:orderCCBFileCells()

    RAHospitalManager:resetData()
    self:defaultSelect()
    RAHospitalManager:sendRefreshConsumeMsg()
end

-------------update
function RAHospitalUIPage:scheduleUpdate()
    -- body
    RAHospitalUIPage:refreshQueueCDBar()
end

--刷新治疗队列数据
function RAHospitalUIPage:refreshQueueCDBar()
    -- body
    if 0 == RAQueueManager:getQueueCounts(Const_pb.CURE_QUEUE) then --不可见，不刷新
        return
    end

    local QueueDatas = RAQueueManager:getQueueDatas(Const_pb.CURE_QUEUE)
    local QueueData = {}
    for k,v in pairs(QueueDatas) do
        --print(k,v)
        QueueData = v
    end
    self.queueData = QueueData
    local remainTime = Utilitys.getCurDiffTime(QueueData.endTime)
    local tmpStr = Utilitys.createTimeWithFormat(remainTime)

    UIExtend.setCCLabelString(self.ccbfile,"mTrainingTime", tmpStr)

    local timeCostDimand = RALogicUtil:time2Gold(remainTime)
    UIExtend.setCCLabelString(self.ccbfile,"mNeedTrainingDiamondsNum", timeCostDimand)--

    local scaleX = RAQueueUtility.getTimeBarScale(QueueData)
    
    local pBar = UIExtend.getCCScale9SpriteFromCCB(self.ccbfile, "mBar")
    pBar:setScaleX(scaleX)
end

--刷新ui顶部治疗队列情况返回
function RAHospitalUIPage:refreshTopCureQueue()
    -- body
    if 0 == RAQueueManager:getQueueCounts(Const_pb.CURE_QUEUE) then
        --todo
        self:setQueueCDBarVisible(false)
        return
    end

    self:setQueueCDBarVisible(true)
    self:refreshQueueCDBar()
end

--刷新消耗四种物品的数据
function RAHospitalUIPage:refreshConsumeData()
    -- body
    local needGoldNum, needOilNum, needSteelNum, needRareEarthsNum = RAHospitalManager:getResourceNums()

    local needGoldNumToK = RALogicUtil:num2k(needGoldNum)
    local needOilNumToK  = RALogicUtil:num2k(needOilNum)
    local needSteelNumToK      = RALogicUtil:num2k(needSteelNum)
    local needRareEarthsNumToK = RALogicUtil:num2k(needRareEarthsNum)

    UIExtend.setCCLabelString(self.ccbfile, "mNeedGoldNum",  needGoldNumToK)
    UIExtend.setCCLabelString(self.ccbfile, "mNeedOilNum",   needOilNumToK)
    UIExtend.setCCLabelString(self.ccbfile, "mNeedSteelNum", needSteelNumToK)
    UIExtend.setCCLabelString(self.ccbfile, "mNeedRareEarthsNum", needRareEarthsNumToK)

    --资源不足需要改变文字颜色
    local txtColorMap = {}
    txtColorMap['mNeedGoldNum'] = RAGameConfig.COLOR.WHITE
    txtColorMap['mNeedOilNum'] = RAGameConfig.COLOR.WHITE
    txtColorMap['mNeedSteelNum'] = RAGameConfig.COLOR.WHITE
    txtColorMap['mNeedRareEarthsNum'] = RAGameConfig.COLOR.WHITE
    
    local currGoldNumValue = RAPlayerInfoManager.getResCountById(Const_pb.GOLDORE)
    if needGoldNum > currGoldNumValue then
        txtColorMap['mNeedGoldNum'] = RAGameConfig.COLOR.RED
    end

    local currOilNumValue = RAPlayerInfoManager.getResCountById(Const_pb.OIL)
    if needOilNum > currOilNumValue then
        txtColorMap['mNeedOilNum'] = RAGameConfig.COLOR.RED
    end

    local currSteelNumValue = RAPlayerInfoManager.getResCountById(Const_pb.STEEL)
    if needSteelNum > currSteelNumValue then
        txtColorMap['mNeedSteelNum'] = RAGameConfig.COLOR.RED
    end

    local currRareEarthsNumValue = RAPlayerInfoManager.getResCountById(Const_pb.TOMBARTHITE)
    if needRareEarthsNum > currRareEarthsNumValue then
        txtColorMap['mNeedRareEarthsNum'] = RAGameConfig.COLOR.RED
    end

    UIExtend.setColorForLabel(self.ccbfile, txtColorMap)
end

function RAHospitalUIPage:refreshNeedDiamond()
    -- body
    local needDiamondsNum = RAHospitalManager:getNeedDiamond()
    self.timeCostDimand = needDiamondsNum
    UIExtend.setCCLabelString(self.ccbfile, "mNeedDiamondsNum",  needDiamondsNum)
end

function RAHospitalUIPage:refreshNeedTime()
    -- body
    local needTime = RAHospitalManager:getNeedTime()
    UIExtend.setCCLabelString(self.ccbfile,"mHealTime",Utilitys.createTimeWithFormat(needTime))
    CCLuaLog("needTime "..needTime)
end

--刷新正在治疗的士兵数目
function RAHospitalUIPage:refreshCuringCount(count)
    -- body
    UIExtend.setCCLabelString(self.ccbfile, "mTrainingNum1", _RALang("@hospitalCuringCount")..count)
end

--刷新等待治疗的士兵数目
function RAHospitalUIPage:refreshWoundedCount(count)
    -- body
    UIExtend.setCCLabelString(self.ccbfile, "mTrainingNum2", _RALang("@hospitalWoundedCount")..count)
end

--每次进入页面默认选择治疗数量
function RAHospitalUIPage:defaultSelect()
    -- body
    local RACoreDataManager = RARequire("RACoreDataManager")
    for k,v in pairs(self.panelCellVec) do
        --print(k,v)
        local mArmyId = RACoreDataManager.ArmyWoundedInfo[v.uuid].armyId
        local costMap = RAHospitalManager:calcResCostByArmyIdAndCount(mArmyId, 1)
        local treatmentNum = RAHospitalManager:currResTreatmentArmyCount(costMap)
        v:selectHandler(false , treatmentNum)
    end

    RAHospitalManager:sendRefreshConsumeMsg()
end

--------------------------------------------------------------
-----------------------消息处理-------------------------------
--------------------------------------------------------------

local OnReceiveMessage = function(message)
    --todo
    --CCLuaLog("类型。。" .. message.type)
    if message.messageID == MessageDefine_Hospital.MSG_refresh_consume then
        --todo
        RAHospitalUIPage:refreshConsumeData()
        RAHospitalUIPage:refreshNeedDiamond()
        RAHospitalUIPage:refreshNeedTime()
    elseif message.messageID == MessageDefine_Hospital.MSG_receive_wounded_data then
        --todo
        RAHospitalUIPage:refreshWoundedCount(message.woundedCount)
        RAHospitalUIPage:refreshWoundedList()
        MessageManager.sendMessage(MessageDef_CITY.MSG_NOTICE_GATHER)
        --RAHospitalUIPage:updateWoundedList()
    elseif message.messageID == MessageDefine_Hospital.MSG_receive_cure_count then
        --todo
        RAHospitalUIPage:refreshCuringCount(message.cureCount)
    elseif message.messageID == MessageDef_Queue.MSG_hospital_ADD then
        --todo
        RAHospitalUIPage:refreshTopCureQueue()
    elseif message.messageID == MessageDef_Queue.MSG_hospital_UPDATE then
        --todo
        RAHospitalUIPage:refreshTopCureQueue()
    elseif message.messageID == MessageDef_Queue.MSG_hospital_DELETE then
        --todo
        RAHospitalUIPage:refreshTopCureQueue()
    elseif message.messageID == MessageDef_Queue.MSG_hospital_CANCEL then
        --todo
        RAHospitalUIPage:refreshTopCureQueue()
    elseif message.messageID == MessageDef_Packet.MSG_Operation_OK then
        local opcode = message.opcode
        local HP_pb = RARequire("HP_pb")
        if opcode == HP_pb.CURE_SOLDIER_C then
            RARootManager.CloseAllPages()
        end  
    elseif message.messageID == MessageDef_Packet.MSG_Operation_Fail then    
        --TODO
    end
end

--注册监听消息
function RAHospitalUIPage:registerMessage()
    --todo
    MessageManager.registerMessageHandler(MessageDefine_Hospital.MSG_refresh_consume, OnReceiveMessage)
    MessageManager.registerMessageHandler(MessageDefine_Hospital.MSG_receive_wounded_data, OnReceiveMessage)
    MessageManager.registerMessageHandler(MessageDefine_Hospital.MSG_receive_cure_count, OnReceiveMessage)
    MessageManager.registerMessageHandler(MessageDef_Queue.MSG_hospital_ADD,      OnReceiveMessage)
    MessageManager.registerMessageHandler(MessageDef_Queue.MSG_hospital_UPDATE,   OnReceiveMessage)
    MessageManager.registerMessageHandler(MessageDef_Queue.MSG_hospital_DELETE,   OnReceiveMessage)
    MessageManager.registerMessageHandler(MessageDef_Queue.MSG_hospital_CANCEL,   OnReceiveMessage)

    MessageManager.registerMessageHandler(MessageDef_Packet.MSG_Operation_OK,OnReceiveMessage)
    MessageManager.registerMessageHandler(MessageDef_Packet.MSG_Operation_Fail,OnReceiveMessage)
end

function RAHospitalUIPage:removeMessageHandler()
    --todo
    MessageManager.removeMessageHandler(MessageDefine_Hospital.MSG_refresh_consume, OnReceiveMessage)
    MessageManager.removeMessageHandler(MessageDefine_Hospital.MSG_receive_wounded_data, OnReceiveMessage)
    MessageManager.removeMessageHandler(MessageDefine_Hospital.MSG_receive_cure_count, OnReceiveMessage)
    MessageManager.removeMessageHandler(MessageDef_Queue.MSG_hospital_ADD,      OnReceiveMessage)
    MessageManager.removeMessageHandler(MessageDef_Queue.MSG_hospital_UPDATE,   OnReceiveMessage)
    MessageManager.removeMessageHandler(MessageDef_Queue.MSG_hospital_DELETE,   OnReceiveMessage)
    MessageManager.removeMessageHandler(MessageDef_Queue.MSG_hospital_CANCEL,   OnReceiveMessage)

    MessageManager.removeMessageHandler(MessageDef_Packet.MSG_Operation_OK,OnReceiveMessage)
    MessageManager.removeMessageHandler(MessageDef_Packet.MSG_Operation_Fail,OnReceiveMessage)
end


--------------------------------------------------------------
-----------------------事件处理-------------------------------
--------------------------------------------------------------

--底部 全部选择
function RAHospitalUIPage:onSelectAllBtn()

    local isSelectAllNow = true
    for k,v in pairs(self.panelCellVec) do
        --print(k,v)
        if v:isSelectAll() == false then 
            isSelectAllNow = false
            break
        end 
    end

	-- body
    for k,v in pairs(self.panelCellVec) do
        --print(k,v)
        v:selectHandler(not isSelectAllNow)
    end

    RAHospitalManager:sendRefreshConsumeMsg()
end

function onHospitalCureNowCallBack(isOk)
    -- body
    if not isOk then
        return
    end
    RAHospitalManager:sendTreatmentProto(true, mBuildData.id)
end
----底部 立即治疗，弹二级确认框提示
function RAHospitalUIPage:onTreatmentNowBtn()
	-- body
    local has = RAHospitalManager:hasSelectedSoldiersToCure()
    if has then
        local electricAdd = RAHospitalManager:getSelectedArmyElectricConsume()
        local electricConfirmFunc = function()
            local RAConfirmManager = RARequire("RAConfirmManager")
            local confirmData = {}
            confirmData.type=RAConfirmManager.TYPE.CURENOW
            confirmData.costDiamonds = self.timeCostDimand
            confirmData.resultFun =onHospitalCureNowCallBack
            RARootManager:showDiamondsConfrimDlg(confirmData)
        end
        RAPlayerInfoManager.checkElectricStatusIsChange(electricAdd, electricConfirmFunc)
    else
        --RARootManager.ShowMsgBox('@buySuccessful')
    end
end

--底部   治疗
function RAHospitalUIPage:onTreatmentBtn()
	-- body
    local has = RAHospitalManager:hasSelectedSoldiersToCure()
    if has then
        local electricAdd = RAHospitalManager:getSelectedArmyElectricConsume()
        local electricConfirmFunc = function()
            RAHospitalManager:sendTreatmentProto(false, mBuildData.id)
        end
        RAPlayerInfoManager.checkElectricStatusIsChange(electricAdd, electricConfirmFunc)
    else
        --RARootManager.ShowMsgBox('@buySuccessful')
    end
end

-----------------------------

--顶部  队列里，立即治疗
function RAHospitalUIPage:onTrainingNow()
    -- body
    RARootManager.showFinishNowPopUp(self.queueData)
end

--顶部   队列里，加速治疗
function RAHospitalUIPage:onAccelerationTraining()
    -- body
    RARootManager.showCommonItemsSpeedUpPopUp(self.queueData)
end

--顶部   队列里，取消治疗关闭按钮
function RAHospitalUIPage:onCancelTraining()
    -- body
    if self.queueData == nil then
        return
    end
    local confirmData = {}
    confirmData.yesNoBtn = true
    confirmData.labelText = RAQueueUtility.getQueueCancelTip({queueType = self.queueData.queueType})
    confirmData.resultFun = function (isOk)
        if isOk then
            RAQueueManager:sendQueueCancel(self.queueData.id)
            RARootManager.CloseCurrPage()
        else
            RARootManager.CloseCurrPage()
        end 
    end
    RARootManager.OpenPage("RAConfirmPage", confirmData,false,true,true)
end

