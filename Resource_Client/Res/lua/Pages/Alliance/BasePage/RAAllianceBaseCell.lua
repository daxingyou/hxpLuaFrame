--推荐联盟的cell
local UIExtend = RARequire("UIExtend")
local RARootManager = RARequire('RARootManager')
local RAAllianceBaseCell = class('RAAllianceBaseCell',{})

function RAAllianceBaseCell:clickCell()
end

--刷新数据
function RAAllianceBaseCell:onRefreshContent(ccbRoot)
    self.ccbfile = ccbRoot:getCCBFileNode() 
end

function RAAllianceBaseCell:ctor(data)
	self.data = data 
end

return RAAllianceBaseCell