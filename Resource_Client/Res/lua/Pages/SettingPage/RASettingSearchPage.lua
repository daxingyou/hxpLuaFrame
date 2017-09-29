--region *.lua
--Date
--此文件由[BabeLua]插件自动生成
local RASettingSearchPage = BaseFunctionPage:new(...)
local UIExtend = RARequire("UIExtend")
local common = RARequire("common")
RARequire("MessageManager")
local RARootManager = RARequire("RARootManager")
local RASettingManager = RARequire("RASettingManager")
local RASettingMainConfig = RARequire("RASettingMainConfig")
local mAllScrollview = nil
local mNoListLabel = nil
local RAPlayerSearchCell = RARequire("RAPlayerSearchCell")
local RASearchManager = RARequire("RASearchManager")
local HP_pb = RARequire("HP_pb")
local Page_Index = {
    Player = 1,
    Alliance = 2
}
local mCurPage = nil 
RASettingSearchPage.editBox = nil
RASettingSearchPage.name = nil

function RASettingSearchPage:Enter(data)
    RASearchManager:reset()
    local ccbfile = UIExtend.loadCCBFile("RASettingSearchPage.ccbi",self)
    mNoListLabel = UIExtend.getCCLabelTTFFromCCB(self.ccbfile,'mNoResultLabel')
    mSearchExplainLabel = UIExtend.getCCLabelTTFFromCCB(self.ccbfile,'mSearchExplainLabel')
    mNoListLabel:setVisible(false)
    mAllScrollview = ccbfile:getCCScrollViewFromCCB("mListSV")
    assert(mAllScrollview~=nil,"mAllScrollview~=nil")
    self:RegisterPacketHandler(HP_pb.PLAYER_GETGLOBALPLAYERINFOBYNAME_S)
    self:RegisterPacketHandler(HP_pb.GUILDMANAGER_SEARCH_S)
    self:registerMessage()
    self:_initTitle()
    self:_initEditbox()
    mCurPage = nil 
    self:ChangePage(Page_Index.Player)
    
end


local function editboxEventHandler(eventType, node)
    --body
    CCLuaLog(eventType)
    if eventType == 'began' then
        -- triggered when an edit box gains focus after keyboard is shown
    elseif eventType == 'ended' then
        -- triggered when an edit box loses focus after keyboard is hidden.
    elseif eventType == 'changed' then
        -- triggered when the edit box text was changed.
        RASettingSearchPage.name = RASettingSearchPage.editBox:getText()
    elseif eventType == 'return' then
        -- triggered when the return button was pressed or the outside area of keyboard was touched.
    end
end

function RASettingSearchPage:_initEditbox()
    local inputNode = UIExtend.getCCNodeFromCCB(self.ccbfile, 'mSearchInputNode')
    if self.editBox == nil then
        self.editBox = UIExtend.createEditBox(self.ccbfile, 'mInputBG', inputNode, 
        editboxEventHandler, nil, nil, nil, 24, nil, ccc3(255, 255, 255))
        self.editBox:setInputMode(kEditBoxInputModeSingleLine)
        self.editBox:setMaxLength(15)
    end
end

function RASettingSearchPage:_initTitle()
    local titleCCB = UIExtend.getCCBFileFromCCB(self.ccbfile, "mAllianceCommonCCB")
	local RACommonTitleHelper = RARequire('RACommonTitleHelper')
	local backCallBack = function()
		RARootManager.GotoLastPage()
	end
    local titleName = _RALang("@SettingSearchPage")
	local titleHandler = RACommonTitleHelper:RegisterCommonTitle('RASettingSearchPage', 
    titleCCB, titleName, backCallBack, RACommonTitleHelper.BgType.Blue)
end

function RASettingSearchPage:_refreshPlayerSV()
    local pageData = RASearchManager.playerSearchData
    mSearchExplainLabel:setVisible(true)
    mSearchExplainLabel:setString(_RALang("@SearchPlayerExplain"))
    mAllScrollview:removeAllCell()
    
    if pageData == nil or #pageData == 0 then
        mNoListLabel:setVisible(true)
		mNoListLabel:setString(_RALang('@HaveNoPlayerList'))
    else
        mNoListLabel:setVisible(false)
        mSearchExplainLabel:setVisible(false)
        local RAPlayerSearchCell = RARequire("RAPlayerSearchCell")
        for i=1,#pageData,1 do 
            local value = pageData[i]
            local cell = CCBFileCell:create()
            cell:setCCBFile("RASettingSearchPlayerCell.ccbi")
            local panel = RAPlayerSearchCell:new( {
                data = value
            } )
            cell:registerFunctionHandler(panel)
            mAllScrollview:addCell(cell)
        end
        mAllScrollview:orderCCBFileCells()
    end
   
end

function RASettingSearchPage:_refreshAllianceSV()
    local pageData = RASearchManager.allianceSearchData
    mSearchExplainLabel:setVisible(true)
    mSearchExplainLabel:setString(_RALang("@SearchAllianceExplain"))
    mAllScrollview:removeAllCell()
    if common:table_count(pageData) == 0 then
        mNoListLabel:setVisible(true)
		mNoListLabel:setString(_RALang('@HaveNoAllianceList'))
    else
        mNoListLabel:setVisible(false)
        mSearchExplainLabel:setVisible(false)
        local RAAllianceRecommondCell = RARequire('RAAllianceRecommondCell')
        for k,value in pairs(pageData) do 
            local cell = CCBFileCell:create()
	        local ccbiStr = "RAAllianceJoinCell.ccbi"
	        cell:setCCBFile(ccbiStr)
	        local panel = RAAllianceRecommondCell:new()
	        panel.cellType = 2
	        panel.info = value
	        cell:registerFunctionHandler(panel)
            mAllScrollview:addCell(cell)
        end
        mAllScrollview:orderCCBFileCells()
    end
end

function RASettingSearchPage:CommonRefresh()
    if mCurPage == Page_Index.Player then
        self:_refreshPlayerSV()
    else
        self:_refreshAllianceSV()
    end
end

function RASettingSearchPage:ChangePage(index)
    if mCurPage == index then
        self:_setNodeVisible()
    else
        mCurPage = index
        self:_setNodeVisible()
        self:CommonRefresh()
    end
end

function RASettingSearchPage:onSearchPlayerBtn()
    self:ChangePage(Page_Index.Player)
end

function RASettingSearchPage:onSearchAllianceBtn()
    self:ChangePage(Page_Index.Alliance)
end

function RASettingSearchPage:onSearchBtn()
    if mCurPage == Page_Index.Player then
        RASearchManager:searchPlayer(self.name)
    elseif mCurPage == Page_Index.Alliance then
        RASearchManager:searchAlliance(self.name)
    end
end

function RASettingSearchPage:_setNodeVisible()
    if mCurPage == Page_Index.Player then
        UIExtend.setControlButtonSelected(self.ccbfile,{
            mSearchPlayerBtn = true,
            mSearchAllianceBtn = false
        })
    else
        UIExtend.setControlButtonSelected(self.ccbfile,{
            mSearchPlayerBtn = false,
            mSearchAllianceBtn = true
        })
    end
end

local OnReceiveMessage = function(message)
    if message.messageID == MessageDef_RootManager.MSG_TopPageMayChange then
        if message.topPageName == 'RASettingSearchPage' then 
            RASettingSearchPage:setEditBoxVisible(true)
        else
            RASettingSearchPage:setEditBoxVisible(false)
        end 
    end
end

function RASettingSearchPage:setEditBoxVisible(visible)
    if self.editBox ~= nil then 
        self.editBox:setVisible(visible)
    end 
end

--注册监听消息
function RASettingSearchPage:registerMessage()
    MessageManager.registerMessageHandler(MessageDef_RootManager.MSG_TopPageMayChange,   OnReceiveMessage)
end

function RASettingSearchPage:removeMessageHandler()
    MessageManager.removeMessageHandler(MessageDef_RootManager.MSG_TopPageMayChange,   OnReceiveMessage)
end

function RASettingSearchPage:Exit()
    mAllScrollview:removeAllCell()
    if self.editBox then
        self.editBox:removeFromParentAndCleanup(true)
        self.editBox = nil
    end
    local RACommonTitleHelper = RARequire('RACommonTitleHelper')
	RACommonTitleHelper:RemoveCommonTitle("RASettingSearchPage")
    UIExtend.unLoadCCBFile(self)
    self:RemovePacketHandlers()
    self:removeMessageHandler()
end


function RASettingSearchPage:onReceivePacket(handler)
    local pbCode = handler:getOpcode()
    local buffer = handler:getBuffer()
    if pbCode == HP_pb.PLAYER_GETGLOBALPLAYERINFOBYNAME_S then
        RASearchManager:onRecievePlayerPacket(buffer)
    elseif pbCode == HP_pb.GUILDMANAGER_SEARCH_S then
        RASearchManager:onRecieveAlliancePacket(buffer)
    end
end

--endregion
