--to:联盟权限修改and查看
RARequire("BasePage")
local UIExtend = RARequire("UIExtend")
local RARootManager = RARequire("RARootManager")
local alliance_authority_conf = RARequire("alliance_authority_conf")
local alliance_authority_order_conf = RARequire("alliance_authority_order_conf")

local RAAlliancePermissionsPage = BaseFunctionPage:new(...)

function RAAlliancePermissionsPage:Enter()
	-- body
	local ccbfile = UIExtend.loadCCBFile("RAAlliancePermissionsPage.ccbi",self)
    self.scrollView = UIExtend.getCCScrollViewFromCCB(self.ccbfile, "mPermissionsListSV")

    self.mDiamondsNode = UIExtend.getCCNodeFromCCB(self.ccbfile:getCCBFileFromCCB("mAllianceCommonCCB"),'mDiamondsNode')
    self.mDiamondsNode:setVisible(false)

    self:initTopTitle()

    local data = self:initData()

    self:addCell(data)
end

function RAAlliancePermissionsPage:initData()
    local data = {}
    for i = 1 ,#alliance_authority_order_conf do
        data[#data + 1] = alliance_authority_order_conf[i]
    end
    return data
end

--初始化顶部
function RAAlliancePermissionsPage:initTopTitle()
    -- body
    self.ccbfile:getCCBFileFromCCB("mAllianceCommonCCB"):runAnimation("InAni")
    local titleName = _RALang("@AlliancePermissionsTitle")
    UIExtend.setCCLabelString(self.ccbfile:getCCBFileFromCCB("mAllianceCommonCCB"),'mTitle',titleName)
end

function RAAlliancePermissionsPage:mAllianceCommonCCB_onBack()
    RARootManager.CloseCurrPage()
end

-----------------------------cell
local RAAlliancePermissionsCell = {}

function RAAlliancePermissionsCell:new(o)
	o = o or {}
    setmetatable(o,self)
    self.__index = self    
    return o
end

function RAAlliancePermissionsCell:onRefreshContent(ccbRoot)
    if not ccbRoot then return end
    local ccbfile = ccbRoot:getCCBFileNode() 
    UIExtend.handleCCBNode(ccbfile)

    local authority = self.mData.authority
    UIExtend.setStringForLabel(ccbfile, {mCellTitle = _RALang("@"..authority)})
    for i = 1,5 do
        local yesIcon = UIExtend.getCCSpriteFromCCB(ccbfile,"mYesIcon"..i)
        yesIcon:setVisible(true)
        local value = alliance_authority_conf[i][authority]
        if value == 0 then
            yesIcon:setVisible(false)
        end
    end
end

local RAAlliancePermissionsCellTitle = {}
function RAAlliancePermissionsCellTitle:onRefreshContent(ccbRoot)
    if not ccbRoot then return end
    local ccbfile = ccbRoot:getCCBFileNode() 
    UIExtend.handleCCBNode(ccbfile)
end


function RAAlliancePermissionsCellTitle:new(o)
    o = o or {}
    setmetatable(o,self)
    self.__index = self    
    return o
end

function RAAlliancePermissionsPage:addCell(data)
	-- body
	self.scrollView:removeAllCell()
    local scrollView = self.scrollView
    
    local cell = CCBFileCell:create()
    cell:setCCBFile("RAAlliancePermissionsCellTitle.ccbi")
    local panel = RAAlliancePermissionsCellTitle:new({})
    cell:registerFunctionHandler(panel)
    scrollView:addCell(cell)

    for k,v in pairs(data) do
        local cell = CCBFileCell:create()
        cell:setCCBFile("RAAlliancePermissionsCell.ccbi")
        local panel = RAAlliancePermissionsCell:new({
        	mData = v
        })
        cell:registerFunctionHandler(panel)
        scrollView:addCell(cell)
    end
    --设置边缘特效使用
    scrollView:setEdgeEffect(0);
    scrollView:orderCCBFileCells()
end

function RAAlliancePermissionsPage:Exit()
	-- body
	self.scrollView:removeAllCell()
	UIExtend.unLoadCCBFile(self)
end

return RAAlliancePermissionsPage