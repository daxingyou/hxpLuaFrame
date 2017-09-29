--[[立即使用二级确认框]]
--sunyungao

RARequire("BasePage")

local RARootManager = RARequire("RARootManager")
local UIExtend = RARequire('UIExtend')
local common = RARequire("common")
local Utilitys = RARequire("Utilitys")
local RALogicUtil = RARequire("RALogicUtil")
local RAQueueManager = RARequire("RAQueueManager")
local RAQueueUtility = RARequire("RAQueueUtility")

--立即完成框
local RAFinishNowPopUp = BaseFunctionPage:new(...)

local mFrameTime = 0

function RAFinishNowPopUp:resetData()
    
end



--data:队列数据 RAQueueData
function RAFinishNowPopUp:Enter(data)
	self:resetData()
	local ccbfile = UIExtend.loadCCBFile("RACommonAcceleratePopUp.ccbi", RAFinishNowPopUp)
	self.ccbfile  = ccbfile
	self.data = data

	self:AddNoTouchLayer(true)
	self:showTitle()
	self:refreshContent()
end

--发送立即完成消息
function RAFinishNowPopUp:onConfirmBtn()
	--
	if self.data ~= nil then
        RAQueueManager:sendQueueSpeedUpByGold(self.data.id)
    end
	
	RAFinishNowPopUp:onClose()
end

function RAFinishNowPopUp:showTitle()
	-- 
	local titleTxt = RAQueueUtility.getFinishQueueNeedDoItRight( self.data.queueType )
	UIExtend.setCCLabelString(self.ccbfile,"mPopUpTitle", titleTxt)

	UIExtend.setCCLabelString(self.ccbfile,"mAccelerateLabel1", _RALang("@Use"))

	UIExtend.setCCLabelString(self.ccbfile,"mAccelerateLabel2", _RALang("@doneRightNow"))
end


function RAFinishNowPopUp:onClose()
	RARootManager.ClosePage("RAFinishNowPopUp")
end	

function RAFinishNowPopUp:Execute()
	--todo
	mFrameTime = mFrameTime + common:getFrameTime()
    if mFrameTime > 1 then
        self:refreshContent()
        mFrameTime = 0 
    end
end	

function RAFinishNowPopUp:refreshContent()
	-- body
	local remainTime = Utilitys.getCurDiffTime(self.data.endTime)
    local tmpStr = Utilitys.createTimeWithFormat(remainTime)
    UIExtend.setCCLabelString(self.ccbfile, "mHealTime", tmpStr)

    local timeCostDimand = RALogicUtil:time2Gold(remainTime)
    UIExtend.setCCLabelString(self.ccbfile,"mDiamondsNum", timeCostDimand)
        
    local scaleX = RAQueueUtility.getTimeBarScale(self.data)
    
    local pBar = UIExtend.getCCScale9SpriteFromCCB(self.ccbfile, "mBar")
    pBar:setScaleX(scaleX)

    local isPassed = Utilitys.isTimePassedCurrent(self.data.endTime)
    if isPassed then
    	RARootManager.ClosePage("RAFinishNowPopUp")
    end
end

function RAFinishNowPopUp:Exit()
	
	UIExtend.unLoadCCBFile(self)
	RAFinishNowPopUp:resetData()
end

return RAFinishNowPopUp