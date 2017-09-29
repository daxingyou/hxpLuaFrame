--require('UICore.ScrollViewAnimation')
RARequire("BasePage")

local GameLoginState = nil

local RALItemPage = BaseFunctionPage:new(...)


function RALItemPage:Enter()
	local ccbfile = UIExtend.loadCCBFile("ccbi/Loading.ccbi",RALItemPage)

end


function RALItemPage:onTestControlBtn()
    CCLuaLog("RALItemPage:onTestControlBtn")
    RALItemPage:AllCCBRunAnimation("TestTimeline");
    SceneController:getInstance():gotoLoading();
end

function RALItemPage:onTestBtn()
	local RARootManager = RARequire("RARootManager")
    RARootManager.OpenPage("RATestPushPage")
end

function RALItemPage:OnAnimationDone(ccbfile)
	local lastAnimationName = ccbfile:getCompletedAnimationName()
	if lastAnimationName == "TestTimeline" then
		CCLuaLog("RALItemPage:OnAnimationDone -- TestTimeline")
	end
end

function RALItemPage:Exit()
	
end