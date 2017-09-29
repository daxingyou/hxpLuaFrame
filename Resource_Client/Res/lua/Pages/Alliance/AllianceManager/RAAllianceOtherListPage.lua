RARequire("BasePage")
local UIExtend = RARequire("UIExtend")
local RARootManager = RARequire("RARootManager")
local RAAllianceProtoManager = RARequire("RAAllianceProtoManager")
local HP_pb = RARequire("HP_pb")
local GuildManager_pb = RARequire("GuildManager_pb")
local RAPlayerInfoManager = RARequire("RAPlayerInfoManager")
local Utilitys = RARequire("Utilitys")
local RAGameConfig = RARequire("RAGameConfig")
RARequire("MessageManager")
local RAAllianceOtherListPage = BaseFunctionPage:new(...)

local TAB_TYPE = {
   	JOIN = 1,
   	CREATE = 2,
   	INVITE = 3
}

function RAAllianceOtherListPage:Enter()
	local ccbfile = UIExtend.loadCCBFile("RAAllianceOtherPage.ccbi", self)

    self.mNoListLabel = UIExtend.getCCLabelTTFFromCCB(self.ccbfile,'mNoListLabel')
    self.mNoListLabel:setVisible(false)
    self.mSearchNode = UIExtend.getCCNodeFromCCB(self.ccbfile,'mSearchNode')
    self.mDiamondsNode = UIExtend.getCCNodeFromCCB(self.ccbfile:getCCBFileFromCCB("mAllianceCommonCCB"),'mDiamondsNode')
    self.mDiamondsNode:setVisible(false)

    self:RegisterPacketHandler(HP_pb.GUILDMANAGER_GETOTHERGUILD_S)
    self:RegisterPacketHandler(HP_pb.GUILDMANAGER_SEARCH_S)
    self:registerMessage()
    self:initTopTitle()
    self:initPage()

    --请求其他联盟列表
    RAAllianceProtoManager:getOtherGuildReq(1)
end

function RAAllianceOtherListPage:initPage()
	-- body
    self.scrollView = UIExtend.getCCScrollViewFromCCB(self.ccbfile, "mInviteListSV")

    --init edbox 
    self.mSearchInputNode = UIExtend.getCCNodeFromCCB(self.ccbfile,'mSearchInputNode')
    local searchEdibox=UIExtend.createEditBox(self.ccbfile,"mInputBG",self.mSearchInputNode,nil,ccp(5,-2))
    self.searchEdibox = searchEdibox
    self.searchEdibox:setInputMode(kEditBoxInputModeSingleLine)
    self.searchEdibox:setMaxLength(15)
    self.searchEdibox:setFontColor(RAGameConfig.COLOR.WHITE)  

end

--初始化顶部
function RAAllianceOtherListPage:initTopTitle()
    -- body
    self.ccbfile:getCCBFileFromCCB("mAllianceCommonCCB"):runAnimation("InAni")
    local titleName = _RALang("@AllianceOtherTitle")
    UIExtend.setCCLabelString(self.ccbfile:getCCBFileFromCCB("mAllianceCommonCCB"),'mTitle',titleName)
end

--点击搜索
function RAAllianceOtherListPage:onSearchBtn()
    -- CCLuaLog('搜索')
    RAAllianceProtoManager:getSearchGuildListReq(self.searchEdibox:getText())
end

function RAAllianceOtherListPage:onReceivePacket(handler)
    local pbCode = handler:getOpcode()
    local buffer = handler:getBuffer()
    if pbCode == HP_pb.GUILDMANAGER_GETOTHERGUILD_S then --其他联盟列表
        local msg = GuildManager_pb.GetRecommendGuildListResp()
        msg:ParseFromString(buffer)
        local RAAllianceInfo = RARequire("RAAllianceInfo")
        local recommendArr = {}
        for i=1,#msg.info do
        	local info = RAAllianceInfo.new()
        	info:initByPb(msg.info[i])
        	recommendArr[i] = info
        end
        self:addCell(recommendArr)
    elseif pbCode == HP_pb.GUILDMANAGER_SEARCH_S then --搜索联盟
    	local searchArr = RAAllianceProtoManager:searchAllianceResp(buffer)
    	self:addCell(searchArr)
    end
end

function RAAllianceOtherListPage:Exit()
    self:RemovePacketHandlers()
    if self.searchEdibox ~= nil then 
		self.searchEdibox:removeFromParentAndCleanup(false)
		self.searchEdibox = nil 
	end 
    self:removeMessageHandler()
    self.scrollView:removeAllCell()
    UIExtend.unLoadCCBFile(self)
end

local OnReceiveMessage = function(message)
    if message.messageID == MessageDef_RootManager.MSG_TopPageMayChange then
        if message.topPageName == 'RAAllianceOtherListPage' then 
            RAAllianceOtherListPage:setEditBoxVisible(true)
        else
            RAAllianceOtherListPage:setEditBoxVisible(false)
        end 
    end
end

function RAAllianceOtherListPage:setEditBoxVisible(visible)
    if self.searchEdibox ~= nil then 
        self.searchEdibox:setVisible(visible)
    end 
end

--注册监听消息
function RAAllianceOtherListPage:registerMessage()
    MessageManager.registerMessageHandler(MessageDef_RootManager.MSG_TopPageMayChange,   OnReceiveMessage)
end

function RAAllianceOtherListPage:removeMessageHandler()
    MessageManager.removeMessageHandler(MessageDef_RootManager.MSG_TopPageMayChange,   OnReceiveMessage)
end

function RAAllianceOtherListPage:mAllianceCommonCCB_onBack()
    RARootManager.CloseCurrPage()
end

function RAAllianceOtherListPage:addCell(data)
	-- body
	self.scrollView:removeAllCell()
    if #data > 0 then
        self.mNoListLabel:setVisible(false)
        self.scrollView:setVisible(true)
        local scrollView = self.scrollView
        for k,v in pairs(data) do
            local RAAllianceRecommondCell = RARequire("RAAllianceRecommondCell")
            local cell = CCBFileCell:create()
            local ccbiStr = "RAAllianceJoinCell.ccbi"
            cell:setCCBFile(ccbiStr)
            local panel = RAAllianceRecommondCell:new()
            panel.cellType = 0
            panel.info = v
            cell:registerFunctionHandler(panel)
            
            scrollView:addCell(cell)
        end

        scrollView:orderCCBFileCells()
    else
        self.scrollView:setVisible(false)
        self.mNoListLabel:setVisible(true)
        self.mNoListLabel:setString(_RALang("@NoShieldAlliance"))
    end
end

return RAAllianceOtherListPage