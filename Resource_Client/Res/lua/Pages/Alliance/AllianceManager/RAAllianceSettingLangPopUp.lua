--联盟语言设置的弹出框
RARequire("BasePage")

local UIExtend = RARequire("UIExtend")
local RAAllianceUtility = RARequire("RAAllianceUtility")

local RAAllianceSettingLangPopUp = BaseFunctionPage:new(...)

function RAAllianceSettingLangPopUp:Enter(data)
    local ccbfile = UIExtend.loadCCBFile("RAAllianceSettingLangPopUp.ccbi", self)

    self.needLanguage = data.needLanguage

    --init scorllView
    self.scrollView = UIExtend.getCCScrollViewFromCCB(ccbfile, "mLanguageListSV")

    local alliance_language_conf = RARequire("alliance_language_conf")
    local list ={}
    for k,v in pairs(alliance_language_conf) do
        local languageInfo = {}
        languageInfo.languageId = v.id
        languageInfo.order = v.order
        list[#list + 1] = languageInfo
    end

    table.sort(list,function(e1,e2) 
        return e1.order < e2.order
    end)

    self:addCell(list)
end

--cell begin
local RAAllianceSettingLangCell2 = {}
local currSelectCcb = nil
local currLanguage = ""

function RAAllianceSettingLangCell2:new(o)
    o = o or {}
    setmetatable(o,self)
    self.__index = self    
    return o
end

function RAAllianceSettingLangCell2:onSelectLangBtn()
    -- body
    local mLanguageId = self.mLanguageId
    local ccbfile = self.mCell:getCCBFileNode() 
    if currSelectCcb then
        UIExtend.getCCSpriteFromCCB(currSelectCcb,"mSelectPic"):setVisible(false) 
    end    
    currSelectCcb = ccbfile
    currLanguage = mLanguageId
    UIExtend.getCCSpriteFromCCB(ccbfile,"mSelectPic"):setVisible(true)
    
    local RAAllianceSettingPage = RARequire("RAAllianceSettingPage")
    RAAllianceSettingPage.currNeedLanguage = currLanguage

    MessageManager.sendMessage(MessageDef_Alliance.MSG_Alliance_SettingLangue)

    local RARootManager = RARequire("RARootManager")
    RARootManager.ClosePage("RAAllianceSettingLangPopUp")
end

function RAAllianceSettingLangCell2:onRefreshContent(ccbRoot)
    local ccbfile = ccbRoot:getCCBFileNode() 
    UIExtend.handleCCBNode(ccbfile)
    local mLanguageId = self.mLanguageId
    local data = self.mData
    
    if currLanguage == "" then
        currLanguage = RAAllianceSettingLangPopUp.needLanguage
    end
    if currLanguage == mLanguageId then
        currSelectCcb = ccbfile
        UIExtend.getCCSpriteFromCCB(ccbfile,"mSelectPic"):setVisible(true)
    else
        UIExtend.getCCSpriteFromCCB(ccbfile,"mSelectPic"):setVisible(false)    
    end 
    local languageName = RAAllianceUtility:getLanguageIdByName(data.languageId)
    UIExtend.setCCLabelString(ccbfile,'mLanguage',languageName)
end



function RAAllianceSettingLangPopUp:addCell(data)
    self.scrollView:removeAllCell()
    local scrollView = self.scrollView
    for k,v in pairs(data) do
        local cell = CCBFileCell:create()
        cell:setCCBFile("RAAllianceSettingLangCell2.ccbi")
        local panel = RAAllianceSettingLangCell2:new({
                mLanguageId = v.languageId,
                mData  = v,
                mCell = cell
        })
        cell:registerFunctionHandler(panel)
        scrollView:addCell(cell)
    end
    scrollView:orderCCBFileCells()
end

function RAAllianceSettingLangPopUp:Exit()
	self.scrollView:removeAllCell()
    currLanguage = ""
	UIExtend.unLoadCCBFile(self)
end

return RAAllianceSettingLangPopUp