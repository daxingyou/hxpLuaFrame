--region *.lua
--Date
--此文件由[BabeLua]插件自动生成

local RASettingLangPage = BaseFunctionPage:new(...)
local UIExtend = RARequire("UIExtend")
local common = RARequire("common")
local RARootManager = RARequire("RARootManager")
local RASettingManager = RARequire("RASettingManager")
local RASettingMainConfig = RARequire("RASettingMainConfig")
local RAStringUtil = RARequire("RAStringUtil")
local mAllScrollview = nil
local RASettingLangCell = {}


function RASettingLangCell:new(o)
    o = o or {}
    setmetatable(o,self)
    self.__index = self    
    return o
end

function RASettingLangCell:onRefreshContent(ccbRoot)
	CCLuaLog("RASettingLangCell:onRefreshContent")
    
	if not ccbRoot then return end
	local ccbfile = ccbRoot:getCCBFileNode() 
    
    local data = self.settingData
    self.ccbfile = ccbfile
    UIExtend.setStringForLabel(ccbfile,{
        mCellLabel = data.displayName
    })
    local RAStringUtil = RARequire("RAStringUtil")
    local curLang = RAStringUtil:getCurrentLang()
    if curLang == self.settingData.id then
        UIExtend.setNodesVisible(self.ccbfile,{
            mSelNode = true
        })
    else
        UIExtend.setNodesVisible(self.ccbfile,{
            mSelNode = false
        })
    end
    UIExtend.addSpriteToNodeParent(ccbfile,"mCellIconNode",data.icon)
end

function RASettingLangCell:onCheckBtn()
    local RAStringUtil = RARequire("RAStringUtil")
    local curLang = RAStringUtil:getCurrentLang()
    if curLang == self.settingData.id then
        return
    end

    local CallBack = function(isConfirm)
        if isConfirm then
            local key = RASettingMainConfig.languageSetKey
            local value = self.settingData.id
            RASettingManager:setOptionData(key,value)
            local RAGameLoadingState = RARequire("RAGameLoadingState")
            RAGameLoadingState.isSwitchLang=true
            performWithDelay(self.ccbfile,function()
                local RALoginManager = RARequire("RALoginManager")
                RALoginManager:goLoginAgain()
                CCBFile:purgeCachedData()
            end,0.3)
        end
    end
    local tipStr = RAStringUtil:getLanguageString("@LangSetting_SureToSwitch", _RALang(self.settingData.displayName))
	local confirmData = {labelText = tipStr, title=_RALang("@Warning"), yesNoBtn=true, resultFun=CallBack}
    RARootManager.showConfirmMsg(confirmData)
end

function RASettingLangPage:Enter(data)
    local ccbfile = UIExtend.loadCCBFile("RASettingMainPage.ccbi",self)
    mAllScrollview = ccbfile:getCCScrollViewFromCCB("mSettingListSV")
    assert(mAllScrollview~=nil,"mAllScrollview~=nil")
    self:_initTitle()
    self:CommonRefresh()
end


function RASettingLangPage:_initTitle()
    local titleCCB = UIExtend.getCCBFileFromCCB(self.ccbfile, "mCommonTitleCCB")
	local RACommonTitleHelper = RARequire('RACommonTitleHelper')
	local backCallBack = function()
		RARootManager.GotoLastPage()
	end
    local titleName = _RALang("@SettingLangPage")
	local titleHandler = RACommonTitleHelper:RegisterCommonTitle('RASettingLangPage', 
    titleCCB, titleName, backCallBack, RACommonTitleHelper.BgType.Blue)
end

function RASettingLangPage:CommonRefresh()
    local pageData = RASettingManager:generateLanguagePageData()
    mAllScrollview:removeAllCell()
    for k,v in pairs(pageData) do 
        local cell = CCBFileCell:create()
		cell:setCCBFile("RASettingLangCell.ccbi")
		local panel = RASettingLangCell:new({
				settingData = v
        })
		cell:registerFunctionHandler(panel)
		mAllScrollview:addCell(cell)
    end
    mAllScrollview:orderCCBFileCells()
end

function RASettingLangPage:Exit()
    
    mAllScrollview:removeAllCell()
    local RACommonTitleHelper = RARequire('RACommonTitleHelper')
	RACommonTitleHelper:RemoveCommonTitle("RASettingLangPage")
    UIExtend.unLoadCCBFile(self)
end


return RASettingLangPage
--endregion
