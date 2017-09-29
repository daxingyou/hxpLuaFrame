--region *.lua
--Date
--此文件由[BabeLua]插件自动生成

local RASettingMainPage = BaseFunctionPage:new(...)
local UIExtend = RARequire("UIExtend")
local common = RARequire("common")
local RARootManager = RARequire("RARootManager")
local RASettingManager = RARequire("RASettingManager")
local RASettingMainConfig = RARequire("RASettingMainConfig")
local mAllScrollview = nil
local RASettingCell = {}
function RASettingCell:new(o)
    o = o or {}
    setmetatable(o,self)
    self.__index = self    
    return o
end

function RASettingCell:onRefreshContent(ccbRoot)
	CCLuaLog("RASettingCell:onRefreshContent")
    
	if not ccbRoot then return end
	local ccbfile = ccbRoot:getCCBFileNode() 
    
    local data = self.settingData
    UIExtend.setStringForLabel(ccbfile,{
        mCellLabel = _RALang(data.name)
    })

    UIExtend.addSpriteToNodeParent(ccbfile,"mCellIconNode",data.icon)
end

function RASettingCell:onCheckBtn()
    local pageName = self.settingData.pageName
    --if type is open page
    if pageName ~= nil then
        RARootManager.ClosePage("RASettingMainPage",false)
        RARootManager.OpenPage(pageName)
        return
    end
    --if it's acount switch, directly open the acount 
    if self.settingData.id == RASettingMainConfig.AcountSettingIndex then
        RASettingManager:switchUser()
    end

    if self.settingData.helpShiftId ~= nil then
        RAHelpshiftUtils:showSection(tostring(self.settingData.helpShiftId))
    elseif self.settingData.helpShiftFAQS~=nil then
        RAHelpshiftUtils:showFAQs()
    end
end

function RASettingMainPage:Enter(data)
    local ccbfile = UIExtend.loadCCBFile("RASettingMainPageNew.ccbi",self)
    mAllScrollview = ccbfile:getCCScrollViewFromCCB("mSettingListSV")
    assert(mAllScrollview~=nil,"mAllScrollview~=nil")
    self:_initTitle()
    self:registerMessageHandlers()
    self:CommonRefresh()

    --播放音效 by phan
    local common = RARequire("common")
    common:playEffect("click_main_botton_banner")
end


function RASettingMainPage:_initTitle()
    local titleCCB = UIExtend.getCCBFileFromCCB(self.ccbfile, "mCommonTitleCCB")
	local RACommonTitleHelper = RARequire('RACommonTitleHelper')
	local backCallBack = function()
		RARootManager.CloseAllPages()
        --RARootManager.CloseCurrPage()
	end
    local titleName = _RALang("@SettingMainPage")
	local titleHandler = RACommonTitleHelper:RegisterCommonTitle('RASettingMainPage', 
    titleCCB, titleName, backCallBack, RACommonTitleHelper.BgType.Blue)
end

function RASettingMainPage:CommonRefresh()
    local pageData = RASettingManager:generateMainPageData()
    mAllScrollview:removeAllCell()
    for k,v in pairs(pageData) do 
        local cell = CCBFileCell:create()
		cell:setCCBFile("RASettingMainCellNew.ccbi")
		local panel = RASettingCell:new({
				settingData = v
        })
		cell:registerFunctionHandler(panel)
		mAllScrollview:addCell(cell)
    end
    mAllScrollview:orderCCBFileCells()
end

function RASettingMainPage:Exit()
    RASettingMainPage:unregisterMessageHandlers()
    mAllScrollview:removeAllCell()
    local RACommonTitleHelper = RARequire('RACommonTitleHelper')
	RACommonTitleHelper:RemoveCommonTitle("RASettingMainPage")
    UIExtend.unLoadCCBFile(self)

    --播放音效 by phan
    local common = RARequire("common")
    common:playEffect("click_main_botton_banner_back")
end

function RASettingMainPage:registerMessageHandlers()
--    MessageManager.registerMessageHandler(MessageDef_Queue.MSG_Soilder_ADD, OnReceiveMessage)
--    MessageManager.registerMessageHandler(MessageDef_Queue.MSG_Soilder_UPDATE, OnReceiveMessage)
--    MessageManager.registerMessageHandler(MessageDef_Queue.MSG_Soilder_DELETE, OnReceiveMessage)
--    MessageManager.registerMessageHandler(MessageDef_Queue.MSG_Soilder_CANCEL, OnReceiveMessage)
end

function RASettingMainPage:unregisterMessageHandlers()
--    MessageManager.removeMessageHandler(MessageDef_Queue.MSG_Soilder_ADD, OnReceiveMessage)
--    MessageManager.removeMessageHandler(MessageDef_Queue.MSG_Soilder_UPDATE, OnReceiveMessage)
--    MessageManager.removeMessageHandler(MessageDef_Queue.MSG_Soilder_DELETE, OnReceiveMessage)
--    MessageManager.removeMessageHandler(MessageDef_Queue.MSG_Soilder_CANCEL, OnReceiveMessage)
end


return RASettingMainPage
--endregion
