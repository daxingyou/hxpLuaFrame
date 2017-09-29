--region *.lua
--Date
--此文件由[BabeLua]插件自动生成
local RASettingOptionPage = BaseFunctionPage:new(...)
local UIExtend = RARequire("UIExtend")
local common = RARequire("common")
local RARootManager = RARequire("RARootManager")
local RASettingManager = RARequire("RASettingManager")
local RASettingMainConfig = RARequire("RASettingMainConfig")
local mAllScrollview = nil

local RASettingTitleCell = {}
function RASettingTitleCell:new(o)
    o = o or {}
    setmetatable(o,self)
    self.__index = self    
    return o
end

function RASettingTitleCell:onRefreshContent(ccbRoot)
	CCLuaLog("RASettingContentCell:onRefreshContent")    
    if not ccbRoot then return end
	local ccbfile = ccbRoot:getCCBFileNode() 
    local data = self.settingData
    UIExtend.handleCCBNode(ccbfile)
    if data then
        UIExtend.setStringForLabel(ccbfile,{
            mCellTitleLabel = _RALang(data[1].type_name)
        })
    end
end

local RASettingContentCell = {}
function RASettingContentCell:new(o)
    o = o or {}
    setmetatable(o,self)
    self.__index = self    
    return o
end

function RASettingContentCell:onRefreshContent(ccbRoot)
	CCLuaLog("RASettingContentCell:onRefreshContent")
    
	if not ccbRoot then return end
	local ccbfile = ccbRoot:getCCBFileNode() 
    self.ccbfile = ccbfile
    self.ccbRoot = ccbRoot
    local data = self.settingData
    UIExtend.handleCCBNode(ccbfile)
    UIExtend.setStringForLabel(ccbfile,{
        mCellTitleLabel = _RALang(data.name)
    })
    if data.option == "1" then
        UIExtend.setNodesVisible(ccbfile,{
            mOpenBtn = false,
            mCloseBtn = true
        })
    else
        UIExtend.setNodesVisible(ccbfile,{
            mOpenBtn = true,
            mCloseBtn = false
        })
    end
end

function RASettingContentCell:onOpenBtn()
    local key = self.settingData.id
    local value = "1"
    local isClientSave = self.settingData.isClientSave
    self.settingData.option = value
    RASettingManager:setOptionData(key,value,isClientSave)
    self:onRefreshContent(self.ccbRoot)
end

function RASettingContentCell:onCloseBtn()
    local key = self.settingData.id
    local value = "0"
    local isClientSave = self.settingData.isClientSave
    self.settingData.option = value
    RASettingManager:setOptionData(key,value,isClientSave)
    self:onRefreshContent(self.ccbRoot)
    
end

function RASettingOptionPage:Enter(data)
    local ccbfile = UIExtend.loadCCBFile("RASettingSetPage.ccbi",self)
    mAllScrollview = ccbfile:getCCScrollViewFromCCB("mSettingListSV")
    assert(mAllScrollview~=nil,"mAllScrollview~=nil")
    self:_initTitle()
    self:CommonRefresh()
end


function RASettingOptionPage:_initTitle()
    local titleCCB = UIExtend.getCCBFileFromCCB(self.ccbfile, "mCommonTitleCCB")
	local RACommonTitleHelper = RARequire('RACommonTitleHelper')
	local backCallBack = function()
		RARootManager.GotoLastPage()
	end
    local titleName = _RALang("@SettingMenu_Option")
	local titleHandler = RACommonTitleHelper:RegisterCommonTitle('RASettingOptionPage', 
    titleCCB, titleName, backCallBack, RACommonTitleHelper.BgType.Blue)
end

function RASettingOptionPage:CommonRefresh()
    local pageData = RASettingManager:generateOptionPageData()
    mAllScrollview:removeAllCell()
    for k,cellList in pairs(pageData) do 
        --first add the title
        local cellTitle = CCBFileCell:create()
		cellTitle:setCCBFile("RASettingSetCellTitle.ccbi")
		local panelTitle = RASettingTitleCell:new({
				settingData = cellList
        })
		cellTitle:registerFunctionHandler(panelTitle)
        mAllScrollview:addCell(cellTitle)

        for key,value in pairs(cellList) do
            local cell = CCBFileCell:create()
		    cell:setCCBFile("RASettingSetCell.ccbi")
		    local panel = RASettingContentCell:new({
				settingData = value
            })
		    cell:registerFunctionHandler(panel)
            mAllScrollview:addCell(cell)
        end
    end
    mAllScrollview:orderCCBFileCells()
end

function RASettingOptionPage:Exit()
    mAllScrollview:removeAllCell()
    local RACommonTitleHelper = RARequire('RACommonTitleHelper')
	RACommonTitleHelper:RemoveCommonTitle("RASettingOptionPage")
    UIExtend.unLoadCCBFile(self)
end

--endregion
