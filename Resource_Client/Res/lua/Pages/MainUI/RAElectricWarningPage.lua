-- RAElectricWarningPage.lua
-- 电力警告页面
RARequire("BasePage")
local UIExtend = RARequire("UIExtend")
local RARootManager = RARequire("RARootManager")
local HP_pb = RARequire("HP_pb")
local Const_pb = RARequire("Const_pb")
local Utilitys = RARequire('Utilitys')
local common = RARequire('common')
local RANetUtil = RARequire('RANetUtil')
local RAGameConfig = RARequire('RAGameConfig')
local RAPlayerInfoManager = RARequire('RAPlayerInfoManager')    
local RABuildManager = RARequire('RABuildManager')
local RALogicUtil = RARequire('RALogicUtil')

local RAElectricWarningPage = BaseFunctionPage:new(...)
RAElectricWarningPage.mExplainLabel = nil
RAElectricWarningPage.mTmpElectricAdd = 0

local BarScaleAniTimeSpend = 2.0

local OnReceiveMessage = function(message)    
    CCLuaLog("RAMainUIPage OnReceiveMessage id:"..message.messageID)
    -- if message.messageID == MessageDef_World.MSG_PresidentInfo_Update then        
    --     -- RAElectricWarningPage:CheckAndUpdatePage(PalaceTabBtnType.Attr)
    -- end

    -- if message.messageID == MessageDef_World.MSG_PresidentEvents_Update then        
    --     -- RAElectricWarningPage:CheckAndUpdatePage(PalaceTabBtnType.BattleRecord)
    -- end

    -- if message.messageID == MessageDef_World.MSG_PresidentHistory_Update then        
    --     -- RAElectricWarningPage:CheckAndUpdatePage(PalaceTabBtnType.PresidentRecord)
    -- end
end

function RAElectricWarningPage:registerMessageHandlers()
    -- MessageManager.registerMessageHandler(MessageDef_World.MSG_PresidentInfo_Update, OnReceiveMessage)
    -- MessageManager.registerMessageHandler(MessageDef_World.MSG_PresidentEvents_Update, OnReceiveMessage)
    -- MessageManager.registerMessageHandler(MessageDef_World.MSG_PresidentHistory_Update, OnReceiveMessage)
end

function RAElectricWarningPage:unregisterMessageHandlers()
    -- MessageManager.removeMessageHandler(MessageDef_World.MSG_PresidentInfo_Update, OnReceiveMessage)    
    -- MessageManager.removeMessageHandler(MessageDef_World.MSG_PresidentEvents_Update, OnReceiveMessage)  
    -- MessageManager.removeMessageHandler(MessageDef_World.MSG_PresidentHistory_Update, OnReceiveMessage)  
end

function RAElectricWarningPage:resetData()
    if self.scrollView ~= nil then
        self.scrollView:removeAllCell()
    end
    self.scrollView = nil
    
    if self.mExplainLabel ~= nil then
        self.mExplainLabel:stopAllActions()
        self.mExplainLabel:setPosition(self.mExplainLabelStarP)
    end
    self.mExplainLabel = nil
end

function RAElectricWarningPage:Enter(data)	
	local ccbfile = UIExtend.loadCCBFile("RAPESystemPopUp2.ccbi",self)
    
    --title
    UIExtend.setCCLabelString(ccbfile, 'mItemTitle' ,_RALang("@ElectricWarningTitle"))


    self.mExplainLabel= UIExtend.getCCLabelTTFFromCCB(ccbfile,"mExplainLabel")
    self.mExplainLabelStarP = ccp(self.mExplainLabel:getPosition())
    UIExtend.setCCLabelString(ccbfile, 'mExplainLabel', _RALang('@ElectricRollingExplain'))
    UIExtend.createLabelAction(ccbfile, "mExplainLabel")

    -- 默认不可见吧
    UIExtend.setNodesVisible(ccbfile, {
            mAffectNode1 = false,
            mAffectNode2 = false,
            mAffectNode3 = false,
            mAffectNode4 = false,
            mAffectNode5 = false,
            mAffectNode6 = false,
        })

    self:RefreshCommonUIPart()

    self:registerMessageHandlers()
    self.mLastUpdateTime = 0

    -- 刷新进度条的动画显示
    -- 数字变化
    -- 文本颜色变化
    -- 进度条变化
    -- 时间轴播放
    if data ~= nil then
        self.mTmpElectricAdd = data.electricAdd or 0
        self.mConfirmFun = data.confirmFun or nil
    end
    if self.mTmpElectricAdd > 0 then
        performWithDelay(ccbfile, 
            function ()            
                ccbfile:runAnimation('InAni')
                self:RefreshCommonUIPart(true)
            end, 0.5)
    else
        RARootManager.ClosePage('RAElectricWarningPage')
    end
end


function RAElectricWarningPage:Execute()
    local currTime = CCTime:getCurrentTime()
    if currTime - self.mLastUpdateTime < 300 then
        return
    end
    self.mLastUpdateTime = currTime
    -- self:RefreshCommonUIPart()
end


function RAElectricWarningPage:Exit()
    self:resetData()
    self:unregisterMessageHandlers()    
    UIExtend.unLoadCCBFile(self)
end

function RAElectricWarningPage:onClose()
	RARootManager.ClosePage('RAElectricWarningPage')
end

function RAElectricWarningPage:onCancel()
    RARootManager.ClosePage('RAElectricWarningPage')
end

function RAElectricWarningPage:onConfirm()
    RARootManager.ClosePage('RAElectricWarningPage') 
    if self.mConfirmFun ~= nil then
        self.mConfirmFun()
    end
end


function RAElectricWarningPage:RefreshCommonUIPart(isAni)
    local ccbfile = self.ccbfile
    if ccbfile == nil then return end    
    isAni = isAni or false

    local currElectric = RAPlayerInfoManager.getCurrElectricValue()
    local currElectricMax = RAPlayerInfoManager.getCurrElectricMaxValue()
    local status, decrease = RAPlayerInfoManager.getCurrElectricStatus()

    if isAni then
        currElectric = currElectric + self.mTmpElectricAdd
        status, decrease = RAPlayerInfoManager.getCurrElectricStatus(self.mTmpElectricAdd)
    end
    
    UIExtend.setStringForLabel(ccbfile, {
            mCurrentNum = currElectric,
            mTotalNum = currElectricMax,            
            mAffect1 = _RALang('@ElectricBuildQueueSpeedDown'),
            mAffect2 = _RALang('@ElectricCureQueueSpeedDown'),
            mAffect3 = _RALang('@ElectricDefenceQueueSpeedDown'),
            mAffect4 = _RALang('@ElectricScienceQueueSpeedDown'),
            mAffect5 = _RALang('@ElectricSoldierQueueSpeedDown'),
            mAffect6 = _RALang('@ElectricDefenceBuildDisable'),
            mAffectNum1 = _RALang('@ElectricAffectOnQueue', decrease),
            mAffectNum2 = _RALang('@ElectricAffectOnQueue', decrease),
            mAffectNum3 = _RALang('@ElectricAffectOnQueue', decrease),
            mAffectNum4 = _RALang('@ElectricAffectOnQueue', decrease),
            mAffectNum5 = _RALang('@ElectricAffectOnQueue', decrease),
        })
    UIExtend.setColorForLabel(ccbfile, {mAffect1 = RAGameConfig.COLOR.WHITE})

    local visibleTable = {}

    local color = RAGameConfig.COLOR.GREEN
    -- 电力充足
    if status ==  RAGameConfig.ElectricStatus.Enough then
        color = RAGameConfig.COLOR.GREEN
        visibleTable.mAffectNode1 = true
        visibleTable.mAffect1 = true
        visibleTable.mAffectNum1 = false
        UIExtend.setColorForLabel(ccbfile, { mAffect1 = color})
        UIExtend.setStringForLabel(ccbfile, { mAffect1 = _RALang('@ElectricNoEffect')})
    --电力紧张
    elseif status ==  RAGameConfig.ElectricStatus.Intense then
        color = RAGameConfig.COLOR.ORANGE
        visibleTable.mAffectNode1 = true
        visibleTable.mAffectNode2 = true
        visibleTable.mAffectNode3 = true
        visibleTable.mAffectNode4 = true
        visibleTable.mAffectNode5 = true
        visibleTable.mAffectNum1 = true
    -- 电力不足
    elseif status == RAGameConfig.ElectricStatus.NotEnough then
        color = RAGameConfig.COLOR.RED
        visibleTable.mAffectNode1 = true
        visibleTable.mAffectNode2 = true
        visibleTable.mAffectNode3 = true
        visibleTable.mAffectNode4 = true
        visibleTable.mAffectNode5 = true
        visibleTable.mAffectNode6 = true
        visibleTable.mAffectNum1 = true
    end

    UIExtend.setColorForLabel(ccbfile, {
            mCurrentNum = color,
            mAffectNum1 = color,
            mAffectNum2 = color,
            mAffectNum3 = color,
            mAffectNum4 = color,
            mAffectNum5 = color,            
            mAffect6 = color,
            mCurrentAffect = color,
        })
    UIExtend.setNodesVisible(ccbfile, visibleTable)

    UIExtend.setHorizonAlignOneByOne(ccbfile, 'mAffect1', 'mAffectNum1')
    UIExtend.setHorizonAlignOneByOne(ccbfile, 'mAffect2', 'mAffectNum2')
    UIExtend.setHorizonAlignOneByOne(ccbfile, 'mAffect3', 'mAffectNum3')
    UIExtend.setHorizonAlignOneByOne(ccbfile, 'mAffect4', 'mAffectNum4')
    UIExtend.setHorizonAlignOneByOne(ccbfile, 'mAffect5', 'mAffectNum5')


    -- bar
    self:_RefreshBar(ccbfile, isAni)
end

function RAElectricWarningPage:_RefreshBar(ccbfile, isAni)
    local const_conf = RARequire('const_conf')

    isAni = isAni or false

    local barSizeNode = UIExtend.getCCNodeFromCCB(ccbfile, "mBarSizeNode")
    local barSizeHeight = barSizeNode:getContentSize().height
    local frontBar = UIExtend.getCCSpriteFromCCB(ccbfile, "mFrontBar")
    local greenBar = UIExtend.getCCSpriteFromCCB(ccbfile, "mGreenBar")
    local yellowBar = UIExtend.getCCSpriteFromCCB(ccbfile, "mYellowBar")
    local redBar = UIExtend.getCCSpriteFromCCB(ccbfile, "mRedBar")

    -- 当前主城等级对应的电量上限
    local electricCfgMax = RAPlayerInfoManager.getCurrElectricMaxCfgValue()
    -- 当前产电量上限
    local currElectricMax = RAPlayerInfoManager.getCurrElectricMaxValue()
    -- 当前用电量
    local currElectricUse = RAPlayerInfoManager.getCurrElectricValue()

    if isAni then
        currElectricUse = currElectricUse + self.mTmpElectricAdd
    end

    local checkPercent = function(percent)
        if percent < 0 then
            return 0
        end
        if percent > 1 then
            return 1
        end
        return percent
    end

    local electric_cap1 = const_conf.electric_cap1.value
    local electric_cap2 = const_conf.electric_cap2.value

    local greenScaleTo = 0
    local yellowScaleTo = 0
    local redScaleTo = 0
    if electricCfgMax == 0 then
        greenScaleTo = 0
    else
        greenScaleTo = (currElectricMax / electricCfgMax)
    end
    greenScaleTo = checkPercent(greenScaleTo)

    if currElectricMax == 0 then
        redScaleTo = 0
        yellowScaleTo = 0        
    else
        yellowScaleTo = (currElectricUse / currElectricMax / electric_cap1 * 100) * greenScaleTo
        redScaleTo = (currElectricUse / currElectricMax / electric_cap2 * 100) * greenScaleTo
    end
    redScaleTo = checkPercent(redScaleTo)
    yellowScaleTo = checkPercent(yellowScaleTo)
    if not isAni then
        frontBar:setScaleY((1 - greenScaleTo) * barSizeHeight)
        yellowBar:setScaleY(yellowScaleTo * barSizeHeight)
        redBar:setScaleY(redScaleTo * barSizeHeight) 
    else
        local scaleToActionFunc = function(target, scaleToY, time)
            if target ~= nil then
                target:stopAllActions()
                local currScaleY = target:getScaleY()
                if currScaleY ~= scaleToY then
                    local action = CCScaleTo:create(time, target:getScaleX(), scaleToY)
                    target:runAction(action)
                end
            end
        end
        scaleToActionFunc(frontBar, (1 - greenScaleTo) * barSizeHeight, BarScaleAniTimeSpend * greenScaleTo)        
        scaleToActionFunc(yellowBar, yellowScaleTo * barSizeHeight, BarScaleAniTimeSpend * yellowScaleTo)        
        scaleToActionFunc(redBar, redScaleTo * barSizeHeight, BarScaleAniTimeSpend * redScaleTo)        
    end
end
return RAElectricWarningPage