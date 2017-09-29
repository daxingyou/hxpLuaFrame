--region RAArmyDetailsPopUpPage.lua
--Author : phan
--Date   : 2016/6/28
--此文件由[BabeLua]插件自动生成



--endregion
local UIExtend = RARequire("UIExtend")
local RARootManager = RARequire("RARootManager")
local battle_soldier_conf = RARequire("battle_soldier_conf")
local RACoreDataManager = RARequire("RACoreDataManager")
local RAStringUtil = RARequire("RAStringUtil")
local RATroopsInfoManager = RARequire("RATroopsInfoManager")
local Utilitys = RARequire("Utilitys")
local const_conf = RARequire("const_conf")

local RAArmyDetailsPopUpPage = BaseFunctionPage:new(...)

local mFrameTime = 0
local mArmyCount = 0

local OnReceiveMessage = function(message)     
    if message.messageID == MessageDef_FireSoldier.MSG_RAArmyDetailsPopUpUpdate then
        CCLuaLog("MessageDef_FireSoldier MSG_RAArmyDetailsPopUpUpdate")
        RAArmyDetailsPopUpPage:refresh()
    end
end

function RAArmyDetailsPopUpPage:registerMessageHandlers()
    MessageManager.registerMessageHandler(MessageDef_FireSoldier.MSG_RAArmyDetailsPopUpUpdate, OnReceiveMessage)
end

function RAArmyDetailsPopUpPage:unregisterMessageHandlers()
    MessageManager.removeMessageHandler(MessageDef_FireSoldier.MSG_RAArmyDetailsPopUpUpdate, OnReceiveMessage)
end

function RAArmyDetailsPopUpPage:Enter(data)
    self:registerMessageHandlers()
    local ccbfile = UIExtend.loadCCBFile("ccbi/RAArmyDetailsPopUp.ccbi",self)
    self.ccbfile = ccbfile
    self.soldierId = data.soldierId
    
    self:refresh()
    
end

function RAArmyDetailsPopUpPage:refresh()
    self:refreshArmyData()
    self:refreshArmyCfgData()

    if self.troopsNum <= 0 then
        RARootManager.CloseCurrPage()
    end
end

--判断某个兵种是否解锁
function RAArmyDetailsPopUpPage:isSoldierIsUnlock(armyId)
    local armyConf = battle_soldier_conf[armyId]
    local openScienceId = armyConf.openScience

    --有些兵种不需要解锁
    if openScienceId==nil then
        return true
    end 
    local RAScienceManager = RARequire("RAScienceManager")
    local isUnLock = RAScienceManager:isResearchFinish(openScienceId)
    return isUnLock,openScienceId

end

function RAArmyDetailsPopUpPage:refreshArmyCfgData()
    local armyCfgData = battle_soldier_conf[self.soldierId]
    --部队名称
    UIExtend.setStringForLabel(self.ccbfile,{mSoldierName = _RALang(armyCfgData.name)})

    --属性
    UIExtend.setStringForLabel(self.ccbfile,{mAttackNum = armyCfgData.attack})
    UIExtend.setStringForLabel(self.ccbfile,{mDefenseNum = armyCfgData.defence})
    UIExtend.setStringForLabel(self.ccbfile,{mLifeNum = armyCfgData.hp})
    
    UIExtend.addSpriteToNodeParent(self.ccbfile,"mBigIconNode", armyCfgData.show)

    local isCurrArmyUnLock,openScienceId= self:isSoldierIsUnlock(self.soldierId)
    local titleKey =""
    local contentKey = ""
    local vecSub = RAStringUtil:split(armyCfgData.subdue,",")  --克制 受制
    assert(#vecSub == 2, "#vecSub == 2")

    if isCurrArmyUnLock then
        --htmlTitle
        titleKey = "ArsenalTrainDesTitle"
        contentKey = "ArsenalTrainDesContent"
    
        local desStr = RAStringUtil:getHTMLString(contentKey,armyCfgData.power,armyCfgData.load,armyCfgData.speed,_RALang(vecSub[1]),_RALang(vecSub[2])) 
        UIExtend.getCCLabelHTMLFromCCB(self.ccbfile,"mDetailsLabel"):setString(desStr)

    else
        titleKey = "ArsenalTrainDesLockTitle"
        contentKey = "ArsenalTrainDesLockContent"
        local desStr = RAStringUtil:getHTMLString(contentKey,armyCfgData.power,armyCfgData.load,armyCfgData.speed,_RALang(vecSub[1]),_RALang(vecSub[2]),_RALang("@Lock")) 
        UIExtend.getCCLabelHTMLFromCCB(self.ccbfile,"mDetailsLabel"):setString(desStr)
    end 

    local htmlTitle = RAStringUtil:getHTMLString(titleKey)
    UIExtend.setCCLabelHTMLString(self.ccbfile,"mDetailsLabelTitle",htmlTitle) 


    local redBar = UIExtend.getCCScale9SpriteFromCCB(self.ccbfile,"mRedBar")
    local blueBar = UIExtend.getCCScale9SpriteFromCCB(self.ccbfile,"mBlueBar")
    local greenBar = UIExtend.getCCScale9SpriteFromCCB(self.ccbfile,"mGreenBar")

    --hp,attack,defence   value = "72000_3500_300"  
    local soldierPropertyMaxValue = const_conf.soldierPropertyMax.value
    local soldierPropertyTable    = RAStringUtil:split(soldierPropertyMaxValue,"_")
    
    Utilitys.barActionPlay(redBar,{value = armyCfgData.attack,baseValue = soldierPropertyTable[2],valueScale =0})
    Utilitys.barActionPlay(blueBar,{value = armyCfgData.defence,baseValue = soldierPropertyTable[3],valueScale = 0})
    Utilitys.barActionPlay(greenBar,{value = armyCfgData.hp,baseValue = soldierPropertyTable[1],valueScale =0})


    --判断是否显示解锁科技
    if isCurrArmyUnLock then
        UIExtend.setNodeVisible(self.ccbfile,"mSoldierLockedNode",false)
    else
        UIExtend.setNodeVisible(self.ccbfile,"mSoldierLockedNode",true)
        local RAScienceUtility = RARequire("RAScienceUtility")
        local techConfigData=RAScienceUtility:getScienceDataById(openScienceId)
        local icon = techConfigData.techPic
        UIExtend.addSpriteToNodeParent(self.ccbfile,"mSoldierLockedIconNode",icon)
    end 

    local controlSlider = UIExtend.getControlSlider("mBarNode", self.ccbfile,true)
	controlSlider:registerScriptSliderHandler(self)
	self.controlSlider = controlSlider
    self.controlSlider:setMinimumValue(1)
	local maxNum = self.troopsNum
	self.controlSlider:setMaximumValue(maxNum)

    self.controlSlider:setValue(1)
    mArmyCount = self.controlSlider:getValue()
    UIExtend.setStringForLabel(self.ccbfile,{mSelectSoldierNum = tostring(mArmyCount)})
end

--滑动完滑条
function RAArmyDetailsPopUpPage:refreshSliderValue()
	-- body
	local value = self.controlSlider:getValue()
	value = math.ceil(value)
	self.controlSlider:setValue(value)

	UIExtend.setStringForLabel(self.ccbfile,{mSelectSoldierNum = tostring(value)})
    mArmyCount = value
    --self:_refreshBottomPanel()
end

function RAArmyDetailsPopUpPage:sliderBegan( sliderNode )
    -- body
end
function RAArmyDetailsPopUpPage:sliderMoved( sliderNode )
    -- body
    self:refreshSliderValue()
end
function RAArmyDetailsPopUpPage:sliderEnded( sliderNode )
    -- body
    self:refreshSliderValue()
end

function RAArmyDetailsPopUpPage:onSubBtn()
    local value = self.controlSlider:getValue()
    if value > 1 then
	    value = tonumber(value-1)
	    self.controlSlider:setValue(value)
	    UIExtend.setStringForLabel(self.ccbfile,{mSelectSoldierNum = tostring(self.controlSlider:getValue())})
        mArmyCount = value
        --self:_refreshBottomPanel()
    end
end

function RAArmyDetailsPopUpPage:onAddBtn()
    local value = self.controlSlider:getValue()
    if value < tonumber(self.troopsNum) then
	    value = tonumber(value+1)
	    self.controlSlider:setValue(value)
        UIExtend.setStringForLabel(self.ccbfile,{mSelectSoldierNum = tostring(self.controlSlider:getValue())})
        mArmyCount = value
    end
end

function RAArmyDetailsPopUpPage:refreshArmyData()
    local armyInfo = RACoreDataManager:getArmyInfoByArmyId(tonumber(self.soldierId))
    if not armyInfo then return end
    --部队数量
    self.troopsNum = armyInfo.freeCount
    -- local numStr = _RALang("@TroopsNum",self.troopsNum)
    -- UIExtend.setStringForLabel(self.ccbfile,{mCurrentNum = numStr})
end

function RAArmyDetailsPopUpPage:Exit()
    self:unregisterMessageHandlers()
    if self.controlSlider then
        self.controlSlider:unregisterScriptSliderHandler()
        self.controlSlider = nil
    end
    UIExtend.unLoadCCBFile(self)
end

--解雇
function RAArmyDetailsPopUpPage:onUpgradeBtn()
    local confirmData = {}
    confirmData.labelText = _RALang("@TroopsFireTips")
	confirmData.resultFun = function (isOk)
        RATroopsInfoManager.onSendFireSoldier(RAArmyDetailsPopUpPage.soldierId,mArmyCount)
	end
	RARootManager.OpenPage("RAConfirmPage", confirmData)
end

function RAArmyDetailsPopUpPage:onClose()
	RARootManager.ClosePage("RAArmyDetailsPopUpPage")
end	

return RAArmyDetailsPopUpPage