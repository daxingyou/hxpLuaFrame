--推荐联盟的cell
local UIExtend = RARequire("UIExtend")
local RARootManager = RARequire('RARootManager')
local RAAllianceBaseCell = RARequire('RAAllianceBaseCell')
local RAAllianceMemberInfoPanel = RARequire('RAAllianceMemberInfoPanel')
local RAAllianceMemberContentCell = class('RAAllianceMemberContentCell',RAAllianceBaseCell)


-- function RAAllianceMemberContentCell:onAllianceLetterBtn()
-- 	-- CCLuaLog('RAAllianceMemberTitleCell:onAllianceLetterBtn')
-- 	self:clickCell()
-- end 

--刷新数据
function RAAllianceMemberContentCell:onRefreshContent(ccbRoot)
	self.ccbfile = ccbRoot:getCCBFileNode() 
	if self.data[1].authority == 5 then 
		UIExtend.getCCBFileFromCCB(self.ccbfile,'mMemCellCCB3'):setVisible(true)
		UIExtend.getCCBFileFromCCB(self.ccbfile,'mMemCellCCB1'):setVisible(false)
 		UIExtend.getCCBFileFromCCB(self.ccbfile,'mMemCellCCB2'):setVisible(false)
 		self.firstCCB = UIExtend.getCCBFileFromCCB(self.ccbfile,'mMemCellCCB3')
	else 
		UIExtend.getCCBFileFromCCB(self.ccbfile,'mMemCellCCB1'):setVisible(true)
 		UIExtend.getCCBFileFromCCB(self.ccbfile,'mMemCellCCB2'):setVisible(false)
 		UIExtend.getCCBFileFromCCB(self.ccbfile,'mMemCellCCB3'):setVisible(false)
 		self.firstCCB = UIExtend.getCCBFileFromCCB(self.ccbfile,'mMemCellCCB1')
 		self.secondCCB = UIExtend.getCCBFileFromCCB(self.ccbfile,'mMemCellCCB2')
	end 

	local panel = RAAllianceMemberInfoPanel:new()
	panel:init(self.firstCCB ,self.data[1],self.contentType)

	if #self.data == 2 then 
		local panel1 = RAAllianceMemberInfoPanel:new()
		panel1:init(self.secondCCB,self.data[2],self.contentType)
		self.secondCCB:setVisible(true)
 	end 
    -- self.mMemLevel = UIExtend.getCCLabelTTFFromCCB(self.ccbfile,'mMemLevel')
    -- self.mMemLevel:setString(self.data)
end

function RAAllianceMemberContentCell:ctor(data,index)
	self.data = data
	self.index = index
	self.contentType = data.contentType
	self.ccbfileName = 'RAAllianceMembersCellNode.ccbi'
end

return RAAllianceMemberContentCell