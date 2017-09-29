RARequire("BasePage")

local UIExtend = RARequire('UIExtend')

local RAReconnectPage = BaseFunctionPage:new(...)

function RAReconnectPage:Enter(data)
	local ccbfile = UIExtend.loadCCBFile("RAReconnectionPopUp.ccbi",self)
	self.ccbfile = ccbfile
	
    self:CommonRefresh()

end

function RAReconnectPage:CommonRefresh()
    local adaptionLayer = self.ccbfile:getCCLayerColorFromCCB("mAdaptationColor")
    if adaptionLayer ~= nil then
        adaptionLayer:setOpacity(170)
    end
end

function RAReconnectPage:onClose()
	local RARootManager = RARequire("RARootManager")
	RARootManager.ClosePage("RAReconnectPage")
end	

function RAReconnectPage:Exit()
	UIExtend.unLoadCCBFile(self)
end

return RAReconnectPage