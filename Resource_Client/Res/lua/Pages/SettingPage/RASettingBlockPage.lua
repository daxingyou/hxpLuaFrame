--region *.lua
--Date
--此文件由[BabeLua]插件自动生成

local RASettingBlockPage = BaseFunctionPage:new(...)
local UIExtend = RARequire("UIExtend")
local common = RARequire("common")
local RARootManager = RARequire("RARootManager")
local RASettingManager = RARequire("RASettingManager")
local RASettingMainConfig = RARequire("RASettingMainConfig")
local RAStringUtil = RARequire("RAStringUtil")
local RAShieldManager = RARequire("RAShieldManager")
local RAPlayerInfoManager = RARequire("RAPlayerInfoManager")
local mAllScrollview = nil
local RASettingBlockCell = {}

local RASettingBlockCellTitle = {}
function RASettingBlockCellTitle:new(o)
    o = o or {}
    setmetatable(o,self)
    self.__index = self    
    return o
end

function RASettingBlockCellTitle:onRefreshContent(ccbRoot)
	CCLuaLog("RASettingBlockCell:onRefreshContent")
    
	if not ccbRoot then return end
	local ccbfile = ccbRoot:getCCBFileNode() 
    
    local data = tostring(self.data)
    self.ccbfile = ccbfile
    UIExtend.setStringForLabel(ccbfile,{
        mCellTitleLabel = _RALang("@SettingBlockList",data)
    })
end


function RASettingBlockCell:new(o)
    o = o or {}
    setmetatable(o,self)
    self.__index = self    
    return o
end

function RASettingBlockCell:onRefreshContent(ccbRoot)
	CCLuaLog("RASettingBlockCell:onRefreshContent")
    
	if not ccbRoot then return end
	local ccbfile = ccbRoot:getCCBFileNode() 
    UIExtend.handleCCBNode(ccbfile)
    local data = self.data
    self.ccbfile = ccbfile
    UIExtend.setStringForLabel(ccbfile,{
        mPlayerName = data.name,
        mAllianceAbbreviation = data.guildName,
        mFightValue = data.battlePoint
    })
    local iconStr = RAPlayerInfoManager.getHeadIcon(data.icon)
    UIExtend.addSpriteToNodeParent(ccbfile,"mCellIconNode",iconStr)
end

function RASettingBlockCell:onRemoveBtn()
    local data = self.data
    local CallBack = function(isConfirm)
        if isConfirm then
            local playerId = data.playerId
            RAShieldManager:removeOneShieldData(playerId)
        end
    end
    local RAStringUtil = RARequire("RAStringUtil")
    local tipStr = RAStringUtil:getLanguageString("@SettingBlock_SureToRemove")
	local confirmData = {labelText = tipStr, title=_RALang("@Warning"), yesNoBtn=true, resultFun=CallBack}
    RARootManager.showConfirmMsg(confirmData)
end

function RASettingBlockPage:Enter(data)
    local ccbfile = UIExtend.loadCCBFile("RASettingBlockedPage.ccbi",self)
    mAllScrollview = ccbfile:getCCScrollViewFromCCB("mSettingListSV")
    assert(mAllScrollview~=nil,"mAllScrollview~=nil")
    self:_initTitle()
    self:CommonRefresh()
end


function RASettingBlockPage:_initTitle()
    local titleCCB = UIExtend.getCCBFileFromCCB(self.ccbfile, "mCommonTitleCCB")
	local RACommonTitleHelper = RARequire('RACommonTitleHelper')
	local backCallBack = function()
		RARootManager.GotoLastPage()
	end
    local titleName = _RALang("@SettingMenu_BlockList")
	local titleHandler = RACommonTitleHelper:RegisterCommonTitle('RASettingBlockPage', 
    titleCCB, titleName, backCallBack, RACommonTitleHelper.BgType.Blue)
end

function RASettingBlockPage:CommonRefresh()
    mAllScrollview:removeAllCell()

    local cell = CCBFileCell:create()
	cell:setCCBFile("RASettingAboutMeCell.ccbi")
    
	local panel = RASettingBlockCellTitle:new({
        data = common:table_count(RAShieldManager.shieldList)
    })
	cell:registerFunctionHandler(panel)
	mAllScrollview:addCell(cell)

    for k,v in pairs(RAShieldManager.shieldList) do 
        if v ~= nil then
            local cell = CCBFileCell:create()
		    cell:setCCBFile("RASettingBlockedCell.ccbi")
		    local panel = RASettingBlockCell:new({
				    data = v
            })
		    cell:registerFunctionHandler(panel)
		    mAllScrollview:addCell(cell)
        end
        
    end
    mAllScrollview:orderCCBFileCells()
end

function RASettingBlockPage:Exit()
    
    mAllScrollview:removeAllCell()
    local RACommonTitleHelper = RARequire('RACommonTitleHelper')
	RACommonTitleHelper:RemoveCommonTitle("RASettingBlockPage")
    UIExtend.unLoadCCBFile(self)
end


return RASettingBlockPage
--endregion
