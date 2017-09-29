--创建成功页面
RARequire("BasePage")
local UIExtend = RARequire("UIExtend")
local RARootManager = RARequire("RARootManager")
local RAAllianceCreatePopUpPage = BaseFunctionPage:new(...)
local RAAllianceManager = RARequire('RAAllianceManager')

function RAAllianceCreatePopUpPage:Enter(data)
    self.ccbfile = UIExtend.loadCCBFile("RAAllianceCreatePopUp.ccbi", RAAllianceCreatePopUpPage)

    self.mAllianceName = UIExtend.getCCLabelTTFFromCCB(self.ccbfile,'mAllianceName')
    self.mAllianceName:setString(RAAllianceManager.selfAlliance.name)
    
end


function RAAllianceCreatePopUpPage:Exit()
	UIExtend.unLoadCCBFile(RAAllianceCreatePopUpPage)
end

--关闭
function RAAllianceCreatePopUpPage:onClose()
    RARootManager.ClosePage('RAAllianceCreatePopUpPage')
    RARootManager.ClosePage('RAAllianceJoinPage')
    RARootManager.OpenPage('RAAllianceMainPage')
end

function RAAllianceCreatePopUpPage:onComfirm()
    self:onClose()
end
-- --创建联盟
-- function RAAllianceCreatePopUpPage:onCreateAllianceBtn()
--     -- CCLuaLog('onCreateAllianceBtn')
--     local RAAllianceJoinPage = RARequire('RAAllianceJoinPage')
--     RAAllianceJoinPage:setCurrentPage(2)
--     self:onClose()
-- end

-- --加入联盟
-- function RAAllianceCreatePopUpPage:onJoinNowBtn()
--     -- CCLuaLog('onJoinNowBtn')
--     local RAAllianceManager = RARequire('RAAllianceManager')
--     RAAllianceManager:autoJoin()
--     self:onClose()
-- end


return RAAllianceCreatePopUpPage