--联盟等级说明页面
local RAAllianceBasePage = RARequire("RAAllianceBasePage")
RARequire('extern')
local UIExtend = RARequire('UIExtend')
local RARootManager = RARequire('RARootManager')
local RAStringUtil = RARequire('RAStringUtil')

local RAAllianceHelpCommonCell = {}
function RAAllianceHelpCommonCell:new(o)
    o = o or {}
    o.cell = nil 
    o.content = nil 
    o.title = nil
    o.mAddHeight = 0
    -- o.cellType = 0  --
    setmetatable(o,self)
    self.__index = self    
    return o
end

--刷新数据
function RAAllianceHelpCommonCell:onRefreshContent(ccbRoot)
    --todo
    -- UIExtend.handleCCBNode(ccbRoot:getCCBFileNode())
    self.ccbfile = ccbRoot:getCCBFileNode() 

    self.mCellTitle = UIExtend.getCCLabelTTFFromCCB(self.ccbfile,'mCellTitle')
    self.mCellTitle:setString(_RALang(self.title))

    -- local mShaderNode = tolua.cast(self.ccbfile:getVariable("mShaderNode"),"CCShaderNode")
    -- mShaderNode:setEnable(true)

    local contentHTMLStr = _RAHtmlFill(self.content)

    self.contentHTMLStr = contentHTMLStr
    self.mCellLabel = UIExtend.getCCLabelHTMLFromCCB(self.ccbfile,'mCellLabel')
    self.mCellLabel:setString(contentHTMLStr)

    self.ccbfile:setPositionY(0)

    local chtml = self.mCellLabel:getHTMLContentSize()

    local cw, ch = chtml.width, chtml.height
    if ch > 30 then
        self.mAddHeight = ch-26
    end
    
    local size = CCSizeMake(self.mCellOriSize.width, self.mCellOriSize.height + self.mAddHeight)

    self.cell:setContentSize(size)
    --self.ccbfile:setPositionY(20)
    local bubble = UIExtend.getCCScale9SpriteFromCCB(self.ccbfile, "mBg")
    bubble:setContentSize(size)
end

--刷新cell content size
function RAAllianceHelpCommonCell:onResizeCell(ccbfile)
    -- CCLuaLog("RAChatUIPageCell:onResizeCell")
    if self.cell == nil or ccbfile == nil then
        return
    end
    if self.mCellOriSize ~= nil then
        return
    end
    self.mCellOriSize = {}
    self.mCellOriSize.height = 119  
    self.mCellOriSize.width = self.cell:getContentSize().width 

    local contentHTMLStr = _RAHtmlFill(self.content)

    self.contentHTMLStr = contentHTMLStr
    self.mCellLabel = UIExtend.getCCLabelHTMLFromCCB(ccbfile,'mCellLabel')
    self.mCellLabel:setString(contentHTMLStr)

    local chtml = self.mCellLabel:getHTMLContentSize()

    local size = CCSizeMake(self.mCellOriSize.width, self.mCellOriSize.height + self.mAddHeight)
    
    self.cell:setContentSize(size)
    
    local bubble = UIExtend.getCCScale9SpriteFromCCB(ccbfile, "mBg")
    bubble:setContentSize(size)

end


---------------------------------RAAllianceHelpCommonPage---------------------------------
local RAAllianceHelpCommonPage = class('RAAllianceHelpCommonPage',RAAllianceBasePage)

function RAAllianceHelpCommonPage:ctor(...)
    self.ccbfileName = "RAAllianceCommonPopUp.ccbi"
    self.scrollViewName = 'mListSV'
end

function RAAllianceHelpCommonPage:init(data)
    -- body
    self.title = data.title or '@AllianceHelpCommonTitle'
    self.content = data.content or '@Default'
end

function RAAllianceHelpCommonPage:refreshAllDes()
    self.mListSV:removeAllCell()

    local cell = CCBFileCell:create()
    local ccbiStr = "RAAllianceCommonPopUpCell.ccbi"
    local panel = RAAllianceHelpCommonCell:new({})
    panel.content = self.content
    panel.title = self.title
    panel.cell = cell
    cell:registerFunctionHandler(panel)
    -- cell:setAnchorPoint(CCPointMake(0,1))
    cell:setCCBFile(ccbiStr)
    self.mListSV:addCell(cell)
    self.mListSV:setTouchEnabled(false)
    self.mListSV:orderCCBFileCells()
end

--初始化顶部
function RAAllianceHelpCommonPage:initTitle()
    -- -- body
    --UIExtend.getCCLabelTTFFromCCB(self.ccbfile, "mTitle"):setString(_RALang(self.title))
    UIExtend.getCCLabelTTFFromCCB(self.ccbfile, "mTitle"):setString('')
end

function RAAllianceHelpCommonPage:onClose()
    RARootManager.ClosePage("RAAllianceHelpCommonPage")
end

function RAAllianceHelpCommonPage:release()
    self.mListSV:removeAllCell()
end

--子类实现
function RAAllianceHelpCommonPage:initScrollview()
    self.mListSV =  UIExtend.getCCScrollViewFromCCB(self.ccbfile, self.scrollViewName)
    self:refreshAllDes()
end

return RAAllianceHelpCommonPage.new()