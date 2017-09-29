--推荐联盟的cell
local UIExtend = RARequire("UIExtend")
local RARootManager = RARequire('RARootManager')
local RAAllianceBaseCell = RARequire('RAAllianceBaseCell')
local RAAllianceTitleCell = class('RAAllianceTitleCell',RAAllianceBaseCell)


function RAAllianceTitleCell:clickCell()
	self:clickTitle()
end

function RAAllianceTitleCell:clickTitle()

	if self.handler ~= nil then 
		self.handler:clickTitle(self.index)
	end 
end

--刷新数据
function RAAllianceTitleCell:onRefreshContent(ccbRoot)
    self.ccbfile = ccbRoot:getCCBFileNode() 
end

function RAAllianceTitleCell:ctor()
	self.isOpen = false 
	self.handler = nil 
	self.index = 0 
end

return RAAllianceTitleCell