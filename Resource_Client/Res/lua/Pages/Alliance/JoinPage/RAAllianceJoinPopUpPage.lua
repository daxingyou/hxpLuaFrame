--一键加入页面
RARequire("BasePage")
local UIExtend = RARequire("UIExtend")
local RARootManager = RARequire("RARootManager")
local RAAllianceJoinPopUpPage = BaseFunctionPage:new(...)
-- local RAAllianceManager = RARequire('RAAllianceManager')

function RAAllianceJoinPopUpPage:Enter(data)
    self.ccbfile = UIExtend.loadCCBFile("RAAllianceJoinPopUp.ccbi", RAAllianceJoinPopUpPage)

    self.mTitle = UIExtend.getCCLabelTTFFromCCB(self.ccbfile,'mTitle')
    self.mTitle:setString(_RALang("@AllianceJoinPopUpTitle"))
end


function RAAllianceJoinPopUpPage:Exit()
	-- self:removeMessageHandler()
	UIExtend.unLoadCCBFile(RAAllianceJoinPopUpPage)
end

--关闭
function RAAllianceJoinPopUpPage:onClose()
    RARootManager.ClosePage("RAAllianceJoinPopUpPage")
end

--创建联盟
function RAAllianceJoinPopUpPage:onCreateAllianceBtn()
    -- CCLuaLog('onCreateAllianceBtn')
    local RAAllianceJoinPage = RARequire('RAAllianceJoinPage')
    RAAllianceJoinPage:setCurrentPage(2)
    self:onClose()
end

--加入联盟
function RAAllianceJoinPopUpPage:onJoinNowBtn()
    -- CCLuaLog('onJoinNowBtn')
    local RAAllianceManager = RARequire('RAAllianceManager')
    RAAllianceManager:autoJoin()
    self:onClose()
end


return RAAllianceJoinPopUpPage