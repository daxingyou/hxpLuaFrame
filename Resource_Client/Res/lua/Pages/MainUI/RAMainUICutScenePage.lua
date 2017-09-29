-- RAMainUICutScenePage


RARequire("BasePage")
local UIExtend = RARequire("UIExtend")
local RAMainUICutScenePage = BaseFunctionPage:new(...)
local OnPacketRecieve = nil
local OnNodeEvent = nil

function RAMainUICutScenePage:resetData()
    CCLuaLog("RAMainUICutScenePage:resetData")
end


function RAMainUICutScenePage:Enter(data)
	CCLuaLog("RAMainUICutScenePage:Enter   will cut to scene:")
	local ccbfile = UIExtend.loadCCBFile("ccbi/RAMainUICutScene.ccbi",RAMainUICutScenePage)
    self:AddNoTouchLayer()
    -- ccbfile:runAnimation("InAni")
end

function RAMainUICutScenePage:onTestBtn1()
	CCLuaLog("RAMainUICutScenePage:onTestBtn1")
    local RARootManager = RARequire("RARootManager")
    RARootManager.OpenPage("RACDKeyPage")
end

function RAMainUICutScenePage:OnAnimationDone(ccbfile)
	local lastAnimationName = ccbfile:getCompletedAnimationName()	
    -- begin change:0
    -- end change:1
    local cutProgress = -1
    if lastAnimationName == "InAni" then
        cutProgress = 0
    end
    if lastAnimationName == "OutAni" then
        cutProgress = 1
    end
    if cutProgress ~= -1 then
        MessageManager.sendMessage(MessageDef_RootManager.MSG_CutScene,{progress=cutProgress})
    end
end

function RAMainUICutScenePage:Exit()	
    CCLuaLog("RAMainUICutScenePage:Exit")
    UIExtend.unLoadCCBFile(self)
    self:resetData()
end