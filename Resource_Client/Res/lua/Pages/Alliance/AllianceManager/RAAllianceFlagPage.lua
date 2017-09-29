--to:联盟旗帜修改
RARequire("BasePage")
RARequire("MessageManager")
local UIExtend = RARequire("UIExtend")
local RARootManager = RARequire("RARootManager")
local RAAllianceManager = RARequire("RAAllianceManager")
local RAAllianceProtoManager = RARequire("RAAllianceProtoManager")
local alliance_flag_conf = RARequire("alliance_flag_conf")
local Utilitys = RARequire("Utilitys")
local RAAllianceUtility = RARequire("RAAllianceUtility")

local RAAllianceFlagPage = BaseFunctionPage:new(...)

local OnReceiveMessage = function(message)
    if message.messageID == MessageDef_Packet.MSG_Operation_OK then
        if message.opcode == HP_pb.GUILDMANAGER_CHANGEFLAG_C then --修改旗帜
            RAAllianceFlagPage.allianceInfo.flag = RAAllianceFlagPage.selectFlagId
            RARootManager.ClosePage("RAAllianceFlagPage")
            RARootManager.ShowMsgBox("@UpdateSuccess")
            MessageManager.sendMessage(MessageDef_Alliance.MSG_Alliance_Flag_Change)
            MessageManager.sendMessage(MessageDef_AlliancePage.MSG_RefreshMainPage)
        end 
    elseif message.messageID == MessageDef_Packet.MSG_Operation_Fail then 
        if message.opcode == HP_pb.GUILDMANAGER_CHANGEFLAG_C then 
            RARootManager.ShowMsgBox("@UpdateFail")
        end 
    end 
end


function RAAllianceFlagPage:registerMessage()
    MessageManager.registerMessageHandler(MessageDef_Packet.MSG_Operation_OK,OnReceiveMessage)
    MessageManager.registerMessageHandler(MessageDef_Packet.MSG_Operation_Fail,OnReceiveMessage)
end

function RAAllianceFlagPage:removeMessageHandler()
    MessageManager.removeMessageHandler(MessageDef_Packet.MSG_Operation_OK,OnReceiveMessage)
    MessageManager.removeMessageHandler(MessageDef_Packet.MSG_Operation_Fail,OnReceiveMessage)
end

function RAAllianceFlagPage:Enter()
	-- body
	local ccbfile = UIExtend.loadCCBFile("RAAllianceFlagPage.ccbi",self)
    --self.scrollView = UIExtend.getCCScrollViewFromCCB(self.ccbfile, "mFlagListSV")

    self.mDiamondsNode = UIExtend.getCCNodeFromCCB(self.ccbfile:getCCBFileFromCCB("mAllianceCommonCCB"),'mDiamondsNode')
    self.mDiamondsNode:setVisible(false)

    self.allianceInfo = RAAllianceManager.selfAlliance

    self:initTopTitle()

    self:registerMessage()

    self.flagArr = {}
    for i=RAAllianceManager.selfAlliance.flag,#alliance_flag_conf do
        self.flagArr[#self.flagArr+1] = alliance_flag_conf[i]
    end

    for i=1,RAAllianceManager.selfAlliance.flag-1 do
        self.flagArr[#self.flagArr+1] = alliance_flag_conf[i]
    end

    --设置当前的旗帜id
    self.flag = self.allianceInfo.flag
    
    self.selectFlagId = 0
    --可选择的联盟旗帜
    self:addCell()

     --刷新当前的联盟旗帜
    self:refreshCurrFalg(true)
end

function RAAllianceFlagPage:refreshCurrFalg(isFirst)
	-- body
	if nil == self.flag or self.flag == 0 then return end
    local icon = 0
    if isFirst then
        icon = RAAllianceUtility:getAllianceFlagIdByIcon(self.flag)
        self.selectFlagId = self.flag
    else
        icon = self.flagArr[self.flag].pic
        self.selectFlagId = self.flagArr[self.flag].id
    end
    
	--
	UIExtend.addSpriteToNodeParent(self.ccbfile,"mMyFlagIconNode",icon)
    local isEnable = true 
    if self.allianceInfo.flag == self.selectFlagId then
        isEnable = false
    end
    UIExtend.setCCControlButtonEnable(self.ccbfile,"mModifyBtn",isEnable)

    --
    local guild_const_conf = RARequire("guild_const_conf")
    local changeGuildFlagGold = guild_const_conf.changeGuildFlagGold.value
    UIExtend.setCCLabelString(self.ccbfile,'mNeedDiamondsNum',changeGuildFlagGold)
end

--初始化顶部
function RAAllianceFlagPage:initTopTitle()
    -- body
    self.ccbfile:getCCBFileFromCCB("mAllianceCommonCCB"):runAnimation("InAni")
    local titleName = _RALang("@AllianceFlagTitle")
    UIExtend.setCCLabelString(self.ccbfile:getCCBFileFromCCB("mAllianceCommonCCB"),'mTitle',titleName)
end

--确认修改旗帜回调
function RAAllianceFlagPage:onModifyBtn()
	-- body
    RAAllianceProtoManager:changeGuildFlag(self.selectFlagId)
end

--取消修改旗帜回调
function RAAllianceFlagPage:onCancelModifyBtn()
	-- body
	RARootManager.CloseCurrPage()
end

function RAAllianceFlagPage:Exit()
    self:removeMessageHandler()
    if self.widge_Reel then
        self.widge_Reel:destroy()
    end
    UIExtend.unLoadCCBFile(self)
end

function RAAllianceFlagPage:mAllianceCommonCCB_onBack()
    RARootManager.CloseCurrPage()
end

---------------------------------------------------------------------
-------------------cell
local RAAllianceFlagCell = {}

function RAAllianceFlagCell:new(o)
	o = o or {}
    setmetatable(o,self)
    self.__index = self    
    return o
end	

function RAAllianceFlagCell:onRefreshItemView(self,icon)
    if self.mCell then
        local ccbfile = self.mCell:getCCBFileNode() 
        --local currFalgInfo = alliance_flag_conf[1]
	    UIExtend.addSpriteToNodeParent(ccbfile,"mFlagIcon",icon)
        print("scrollViewSelectNewItem")
    end
end

-------------------cell end
---------------------------------------------------------------------

function RAAllianceFlagPage.onReelEvent(eventName,container)
    if container==nil then return end
    if eventName=="moved" then
        local guildContentNode =  UIExtend.getCCNodeFromCCB(container,"mFlagIconListNode")
        if guildContentNode~=nil then 
            for i= 1,#alliance_flag_conf do
                local node = guildContentNode:getChildByTag(i)
                if node~=nil then 
                    --NodeHelper:setMenuItemEnabled(node,"mGetInto",false)
                end
            end
        end
    elseif eventName=="ended" or eventName=="cancelled" then
        local guildContentNode =  UIExtend.getCCNodeFromCCB(container,"mFlagIconListNode")
        if guildContentNode~=nil then 
            RAAllianceFlagPage.flag = RAAllianceFlagPage.widge_Reel.currentIndex

            RAAllianceFlagPage:refreshCurrFalg()
            for i= 1,#alliance_flag_conf do
                local node = guildContentNode:getChildByTag(i)
                if node~=nil then 
                    --NodeHelper:setMenuItemEnabled(node,"mGetInto",true)
                end
            end
        end
    end
end

function RAAllianceFlagPage:addCell()
	-- body
    local RAWidgeReel = RARequire("RAWidgeReel")
    local flagIconListNode =  UIExtend.getCCNodeFromCCB(self.ccbfile,"mFlagIconListNode")
    if flagIconListNode then
        flagIconListNode:setAnchorPoint(ccp(0.5,0))
        flagIconListNode:setPositionX(50)
        if RAWidgeReel~=nil then 
            RAWidgeReel:destroy(flagIconListNode)
        end

        local RAAllianceManager = RARequire('RAAllianceManager')

        local cells = {}
        for i= 1,#self.flagArr do
            local cell = CCBFileCell:create()
            cell:setCCBFile("RAAllianceFlagCell.ccbi")
            cell:load()
            local panel = RAAllianceFlagCell:new({
                mTag   = i,
                mCell = cell
            })
            
            cell:setZOrder(999)
            cell:registerFunctionHandler(panel)
            cell:setTag(i)
            RAAllianceFlagCell:onRefreshItemView(panel,self.flagArr[i].pic)
            table.insert(cells,cell)
        end
        self.widge_Reel = RAWidgeReel:create(flagIconListNode,cells)
        self.widge_Reel:registerEventHandler(RAAllianceFlagPage.onReelEvent,self.ccbfile)
    end
end

return RAAllianceFlagPage