-- RAMainUIWaitingPage


RARequire("BasePage")
local UIExtend =RARequire("UIExtend")
local RAMainUIWaitingPage = BaseFunctionPage:new(...)
local OnPacketRecieve = nil
local OnNodeEvent = nil

function RAMainUIWaitingPage:resetData()
    CCLuaLog("RAMainUIWaitingPage:resetData")
end


function RAMainUIWaitingPage:Enter(data)
	CCLuaLog("RAMainUIWaitingPage:Enter")
	local ccbfile = UIExtend.loadCCBFile("ccbi/RAWaitingPage.ccbi",RAMainUIWaitingPage)
    self:AddNoTouchLayer()
    local isShow = true
    local closeTime = 0
    if data ~= nil and data.isShow ~= nil then
        isShow = data.isShow
        closeTime = data.closeTime or 0
    end
    UIExtend.setNodeVisible(ccbfile, "mWaitingNode", isShow)
    -- ccbfile:runAnimation("InAni")
    local closePrint = data.closePrint or 'RAMainUIWaitingPage self close........'
    if closeTime > 0 then
        local delayFunc = function()
            local RARootManager = RARequire('RARootManager')
            RARootManager.RemoveWaitingPage()
            print(closePrint)
        end
        performWithDelay(ccbfile, delayFunc, closeTime)
    end
end

function RAMainUIWaitingPage:OnAnimationDone(ccbfile)
	local lastAnimationName = ccbfile:getCompletedAnimationName()    
end

function RAMainUIWaitingPage:Excute()
	--ScrollViewAnimation.update()
end	

function RAMainUIWaitingPage:Exit()	
    CCLuaLog("RAMainUIWaitingPage:Exit")
    -- self:resetData()
    UIExtend.unLoadCCBFile(self)
    
end