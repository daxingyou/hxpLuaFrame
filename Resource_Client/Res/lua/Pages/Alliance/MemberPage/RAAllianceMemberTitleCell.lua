--推荐联盟的cell
local UIExtend = RARequire("UIExtend")
local RARootManager = RARequire('RARootManager')
local RAAllianceTitleCell = RARequire('RAAllianceTitleCell')
local RAAllianceMemberTitleCell = class('RAAllianceMemberTitleCell',RAAllianceTitleCell)
local RAAllianceUtility = RARequire('RAAllianceUtility')
local RAStringUtil = RARequire('RAStringUtil')
function RAAllianceMemberTitleCell:onAllianceLetterBtn()
	-- CCLuaLog('RAAllianceMemberTitleCell:onAllianceLetterBtn')
	self:clickCell()
end 

--刷新数据
function RAAllianceMemberTitleCell:onRefreshContent(ccbRoot)
    self.ccbfile = ccbRoot:getCCBFileNode() 
    -- self.ccbfile:runAnimation('OpenAni')

    self.mCellSprite = UIExtend.getCCSpriteFromCCB(self.ccbfile,'mCellSprite')

    if self.isAnimation == true then 
        if self.isOpen then 
            self.ccbfile:runAnimation('OpenAni')
        else
            self.ccbfile:runAnimation('CloseAni')
        end 
    else 
        if self.isOpen then 
            self.mCellSprite:setRotation(90)
        else
            self.mCellSprite:setRotation(0)
        end 
    end 

    self.mMemLevel = UIExtend.getCCLabelTTFFromCCB(self.ccbfile,'mMemLevel')
    local text = _RALang(self.data.name)
    self.mMemLevel:setString(text)

    self.mCellLevel = UIExtend.getCCLabelTTFFromCCB(self.ccbfile,'mCellLevel')
    self.mCellLevel:setString(6-self.index)

    self.mMemNum = UIExtend.getCCLabelTTFFromCCB(self.ccbfile,'mMemNum')
    self.mMemNum:setString(self.data.onlineInfo)
    -- self.mCellIcon:setTexture(RAAllianceUtility:getLIcon(6-self.index))
end

function RAAllianceMemberTitleCell:ctor(data,index,isOpen,isAnimation)
	self.data = data
	self.index = index
    self.isOpen = isOpen
    self.isAnimation = isAnimation
	self.ccbfileName = 'RAAllianceMembersCell.ccbi'
end

return RAAllianceMemberTitleCell