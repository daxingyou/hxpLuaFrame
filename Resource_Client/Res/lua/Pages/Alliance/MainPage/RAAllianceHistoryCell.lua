--联盟日志的cell
local UIExtend = RARequire("UIExtend")
local RAAllianceHistoryCell = {}
local RARootManager = RARequire("RARootManager")
local RAAllianceUtility = RARequire('RAAllianceUtility')
local Utilitys = RARequire('Utilitys')

function RAAllianceHistoryCell:new(o)
    o = o or {}
    o.info = nil 
    -- o.cellType = 0  --
    setmetatable(o,self)
    self.__index = self    
    return o
end

--刷新数据
function RAAllianceHistoryCell:onRefreshContent(ccbRoot)
	--todo
	CCLuaLog("RAAllianceHistoryCell:onRefreshContent")

    self.ccbfile = ccbRoot:getCCBFileNode() 

    self.mStateIcon = UIExtend.getCCSpriteFromCCB(self.ccbfile,'mStateIcon')
    self.mStateIcon:setTexture(RAAllianceUtility:getLogIcon(self.info.logType))
 
    self.mTimeLabel = UIExtend.getCCLabelTTFFromCCB(self.ccbfile,'mTimeLabel')
    self.mTimeLabel:setString(Utilitys.formatTime(self.info.time/1000))

    self.mAllianceHistory = UIExtend.getCCLabelTTFFromCCB(self.ccbfile,'mAllianceHistory')
    self.mAllianceHistory:setString(RAAllianceUtility:getLogText(self.info))
end

return RAAllianceHistoryCell