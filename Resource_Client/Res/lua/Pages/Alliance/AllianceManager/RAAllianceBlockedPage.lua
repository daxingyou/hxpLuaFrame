RARequire("BasePage")
local UIExtend = RARequire("UIExtend")
local RARootManager = RARequire("RARootManager")
local RAAllianceProtoManager = RARequire("RAAllianceProtoManager")
local HP_pb = RARequire("HP_pb")
local RAPlayerInfoManager = RARequire("RAPlayerInfoManager")
local Utilitys = RARequire("Utilitys")
RARequire("MessageManager")
local RAAllianceBlockedPage = BaseFunctionPage:new(...)

--请求被屏蔽留言的玩家
function RAAllianceBlockedPage:send()
	RAAllianceProtoManager:getForbidPlayerList()
end


function RAAllianceBlockedPage:Enter()
	local ccbfile = UIExtend.loadCCBFile("RASettingBlockedPage.ccbi",self)
    self.scrollView = UIExtend.getCCScrollViewFromCCB(self.ccbfile, "mSettingListSV")

    self.label = UIExtend.createLabel(_RALang("@NoShieldPlayer"),nil,24)
    local size = self.ccbfile:getContentSize()
    self.label:setPosition(ccp(size.width/2,size.height/2))
    self.ccbfile:addChild(self.label)
    self:registerMessage()
    self.mDiamondsNode = UIExtend.getCCNodeFromCCB(self.ccbfile:getCCBFileFromCCB("mCommonTitleCCB"),'mDiamondsNode')
    self.mDiamondsNode:setVisible(false)

    self:RegisterPacketHandler(HP_pb.GUILDMANAGER_GETFORBIDLIST_S)

    self:initTopTitle()

    self:send()

end

local OnReceiveMessage = function(message)
    if message.messageID == MessageDef_Packet.MSG_Operation_OK then
        RARootManager.ShowMsgBox(_RALang('@CancelBlockSuccess'))
    end 
end

function RAAllianceBlockedPage:registerMessage()
    MessageManager.registerMessageHandler(MessageDef_Packet.MSG_Operation_OK,OnReceiveMessage)
end

function RAAllianceBlockedPage:removeMessageHandler()
    MessageManager.removeMessageHandler(MessageDef_Packet.MSG_Operation_OK,OnReceiveMessage)
end

--初始化顶部
function RAAllianceBlockedPage:initTopTitle()
    -- body
    self.ccbfile:getCCBFileFromCCB("mCommonTitleCCB"):runAnimation("InAni")
    local titleName = _RALang("@AllianceBlockedTitle")
    UIExtend.setCCLabelString(self.ccbfile:getCCBFileFromCCB("mCommonTitleCCB"),'mTitle',titleName)
end

function RAAllianceBlockedPage:onReceivePacket(handler)
    local pbCode = handler:getOpcode()
    local buffer = handler:getBuffer()
    if pbCode == HP_pb.GUILDMANAGER_GETFORBIDLIST_S then --获得已屏蔽列表\
        self.applyInfo = {}
        self.applyInfo = RAAllianceProtoManager:setAllianceApplyInfo(buffer)
        self:addCell(self.applyInfo)
    end
end

function RAAllianceBlockedPage:Exit()
    self:RemovePacketHandlers()
    self:removeMessageHandler()
    self.scrollView:removeAllCell()
    self.label:removeFromParentAndCleanup(true)
	self.label = nil 
    UIExtend.unLoadCCBFile(self)
end

function RAAllianceBlockedPage:mCommonTitleCCB_onBack()
    RARootManager.CloseCurrPage()
end

--------------------------------------cell content begin --------------------------------
local RASettingBlockedCell = {}

function RASettingBlockedCell:new(o)
    o = o or {}
    setmetatable(o,self)
    self.__index = self
    return o
end

function RASettingBlockedCell:refreshCells(cell)
    if cell then
        RAAllianceBlockedPage.scrollView:removeCell(cell)	
        RAAllianceBlockedPage.scrollView:orderCCBFileCells()
    end
    local index = self.mTag
    RAAllianceBlockedPage.applyInfo[index] = nil
    if #RAAllianceBlockedPage.applyInfo == 0 then
        RAAllianceBlockedPage.label:setVisible(true)
        RAAllianceBlockedPage.scrollView:removeAllCell()
        RAAllianceBlockedPage.scrollView:setVisible(false)
    end
end

--解除按钮回调
function RASettingBlockedCell:onRemoveBtn()
    --取消屏蔽
    RAAllianceProtoManager:cancelForbinPlayer(self.mData.playerId)
    
    local delayFunc = function ()
        self:refreshCells(self.mCell)
    end
    performWithDelay(RAAllianceBlockedPage.ccbfile, delayFunc, 0.05)
end

function RASettingBlockedCell:onRefreshContent(ccbRoot)
    if not ccbRoot then return end
    local ccbfile = ccbRoot:getCCBFileNode() 
    UIExtend.handleCCBNode(ccbfile)

    
    local info = self.mData
    if info then
        local libStr = {}
        libStr['mAllianceAbbreviation'] = info.guildTag
        libStr['mPlayerName'] = info.playerName
        libStr['mFightValue'] = Utilitys.formatNumber(info.power)

        UIExtend.setStringForLabel(ccbfile,libStr)

        --头像
        local playerIcon = RAPlayerInfoManager.getHeadIcon(info.icon)
        UIExtend.addSpriteToNodeParent(ccbfile, "mCellIconNode", playerIcon)
    end
end

--------------------------------------cell content end --------------------------------
function RAAllianceBlockedPage:addCell(data)
	-- body
	self.scrollView:removeAllCell()
    if #data > 0 then
        local scrollView = self.scrollView
        for k,v in pairs(data) do
            local cell = CCBFileCell:create()
            cell:setCCBFile("RASettingBlockedCell.ccbi")
            local panel = RASettingBlockedCell:new({
        	    mTag = k,
                mCell = cell,
                mData = v
            })
            cell:registerFunctionHandler(panel)

            scrollView:addCell(cell)
        end
        self.scrollView:setVisible(true)
        self.label:setVisible(false)
        scrollView:orderCCBFileCells()
    else
        self.label:setVisible(true)
        self.scrollView:removeAllCell()
        self.scrollView:setVisible(false)
    end
end

return RAAllianceBlockedPage