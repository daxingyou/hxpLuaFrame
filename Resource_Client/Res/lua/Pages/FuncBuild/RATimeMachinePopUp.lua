--爱因斯坦时光机器损毁状态下的点击建筑的页面
RARequire("BasePage")
local UIExtend = RARequire("UIExtend")
local RARootManager = RARequire("RARootManager")
local RARealPayManager = RARequire("RARealPayManager")
local Utilitys = RARequire("Utilitys")
local RAStringUtil = RARequire("RAStringUtil")

local RATimeMachinePopUp = BaseFunctionPage:new(...)

--消息处理
local OnReceiveMessage = function(message)
    if message.messageID == MessageDef_Pay.MSG_PayInfoRefresh then
        RATimeMachinePopUp:refreshCurrGold()
    end
end

--desc:添加各种监听
function RATimeMachinePopUp:registerMessageHandlers()
    MessageManager.registerMessageHandler(MessageDef_Pay.MSG_PayInfoRefresh, OnReceiveMessage)
    MessageManager.registerMessageHandler(MessageDef_MainUI.MSG_UpdateBasicPlayerInfo, OnReceiveMessage)
end

--desc:移除各种监听
function RATimeMachinePopUp:unregisterMessageHandlers()
    MessageManager.removeMessageHandler(MessageDef_Pay.MSG_PayInfoRefresh, OnReceiveMessage)
    MessageManager.removeMessageHandler(MessageDef_MainUI.MSG_UpdateBasicPlayerInfo, OnReceiveMessage)
end

function RATimeMachinePopUp:Enter(data)
	-- body
	UIExtend.loadCCBFile("RATimeMachinePopUp.ccbi",self)

	self:registerMessageHandlers()

    --tag 
    self.isActivation = false

    self.buildData = data
	self.buildConfData = self.buildData.confData
	self:refreshUI()
end

function RATimeMachinePopUp:refreshCurrGold()
	-- body
	local rechargeGold = RARealPayManager.addGold
    
    local rechargeGoldTarget = self.buildConfData.frontRechargeDiamond
    UIExtend.setStringForLabel(self.ccbfile, {mBarNum = _RALang('@VitNum',rechargeGold,rechargeGoldTarget)})

    local scaleX = rechargeGold / rechargeGoldTarget
    if scaleX > 1 then
    	scaleX = 1
    elseif scaleX < 0 then
    	scaleX = 0
    end

    local bar = UIExtend.getCCScale9SpriteFromCCB(self.ccbfile,"mBar")
    if bar then
        bar:setScaleX(scaleX)
    end

    --如果scaleX >= 1
    --前往充值的按钮变为激活
    if scaleX >= 1 then
        self.isActivation = true
        UIExtend.setControlButtonTitle(self.ccbfile, 'mJumpRechargeBtn', _RALang("@ClickActivation"), isDirect,fontColor)
    end
end

function RATimeMachinePopUp:refreshUI()
	-- body
	UIExtend.setStringForLabel(self.ccbfile, {mTitle = _RALang('@TimeMachinePopUpTitle')})

	local rechargeGoldTarget = self.buildConfData.frontRechargeDiamond

	--UIExtend.setStringForLabel(self.ccbfile, {mExplainLabel1 = _RALang('@RechargeAchieve',rechargeGoldTarget)})
	
    --html desc
    local htmlStr1 = _RAHtmlFill("mExplainLabel1",rechargeGoldTarget)
    local mExplainLabel1 = UIExtend.getCCLabelHTMLFromCCB(self.ccbfile, "mExplainLabel1")
    mExplainLabel1:setString(htmlStr1)

    --UIExtend.setStringForLabel(self.ccbfile, {mExplainLabel2 = _RALang('@TimeMachinePopUpDes')})

    local htmlStr2 = _RAHtmlFill("mExplainLabel2")
    local mExplainLabel2 = UIExtend.getCCLabelHTMLFromCCB(self.ccbfile, "mExplainLabel2")
    mExplainLabel2:setString(htmlStr2)

    local effectIDs = RAStringUtil:split(self.buildConfData.effectID, "_")
    local effectTime = tonumber(effectIDs[2])

    local formatTimeStr = Utilitys.createTimeWithFormat(effectTime)
    UIExtend.setStringForLabel(self.ccbfile,{mTime = _RALang('@TimeHourFormat',formatTimeStr)})

    self:refreshCurrGold()
end

function RATimeMachinePopUp:onJumpRechargeBtn()
	-- body
    if self.isActivation then   --已经激活
        local RABuildManager = RARequire("RABuildManager")
        RABuildManager:sendCreateBuildCmd(self.buildConfData.id,self.buildData.tilePos.x,self.buildData.tilePos.y)
        
        RATimeMachinePopUp:onClose()
    else
	   RARootManager.OpenPage("RARechargeMainPage", nil, false, true, false, true)
    end
end

function RATimeMachinePopUp:onClose()
	-- body
	RARootManager.ClosePage("RATimeMachinePopUp")
end

function RATimeMachinePopUp:Exit()
	-- body
	self:unregisterMessageHandlers()
	
	UIExtend.unLoadCCBFile(self)
end

return RATimeMachinePopUp