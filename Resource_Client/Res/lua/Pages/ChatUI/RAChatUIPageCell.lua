--聊天界面cell
--test by sunyungao

local Utilitys      = RARequire("Utilitys")
local UIExtend      = RARequire("UIExtend")
local RAStringUtil  = RARequire("RAStringUtil")
local RAChatManager = RARequire("RAChatManager")
local player_show_conf = RARequire("player_show_conf")
local RAMailUtility = RARequire("RAMailUtility")
local RARootManager = RARequire("RARootManager")
local RAChatData = RARequire("RAChatData")
local RAWorldConfigManager = RARequire("RAWorldConfigManager")
local RAPlayerInfoManager = RARequire("RAPlayerInfoManager")

local RAChatUIPageCell = {
	mIsOtherPlayer = true,
	mTag = 0, --作废，在push front cell时用坏了
	mChatData = {},
    mBubblePro = {contentWidth=460, otherContentWidth=460},
    mCellOriSize = nil,
    mBgOriSize = nil,
    mAddHeight = 0,
    mScrollView = nil,
    mOptionTab = {}
}
function RAChatUIPageCell:new(o)
    o = o or {}
    o.isRegister = false 
    setmetatable(o,self)
    self.__index = self
       
    return o
end

--点击玩家头像
function RAChatUIPageCell:onCheck()
    if self.mChatData.playerId ~= "" and self.mChatData.playerId ~= nil then
        RARootManager.OpenPage('RAGeneralInfoPage', {playerId = self.mChatData.playerId})
    end
end

--刷新cell content size
function RAChatUIPageCell:onResizeCell(tmpCCB)
	CCLuaLog("RAChatUIPageCell:onResizeCell")
	if self.selfCell == nil or tmpCCB == nil then
		return
	end
	if self.mCellOriSize ~= nil then
		return
	end
	self.mCellOriSize = {}
	self.mCellOriSize.height = 100--self.selfCell:getContentSize().height	
	self.mCellOriSize.width = self.selfCell:getContentSize().width	

	contentWidth = self.mBubblePro.contentWidth
	if self.mIsOtherPlayer then
		--todo
		contentWidth = self.mBubblePro.otherContentWidth
	end

	UIExtend.setChatLabelHTMLString(tmpCCB, "mOthersSendLabel", self.mChatData.chatMsg, contentWidth)
	local chtml = UIExtend.getCCLabelHTMLFromCCB(tmpCCB, "mOthersSendLabel"):getHTMLContentSize()
	local cw, ch = chtml.width, chtml.height
	if ch > 35 then
		self.mAddHeight = ch-26
	end
	
	local size = CCSizeMake(self.mCellOriSize.width, self.mCellOriSize.height + self.mAddHeight)
	self.selfCell:setContentSize(size)
	
	if self.mBgOriSize ~= nil then
		return
	end
	local bubble = UIExtend.getCCNodeFromCCB(tmpCCB, "mBubblePic")
	self.mBgOriSize = {}
	self.mBgOriSize.height = 68--bubble:getContentSize().height	
	self.mBgOriSize.width = bubble:getContentSize().width	

	local mclick = UIExtend.getCCMenuItemImageFromCCB(tmpCCB, "mClick")
	self.mBgOriSize.clickHeight = 60--mclick:getContentSize().height	--50
	self.mBgOriSize.clickWidth  = mclick:getContentSize().width     --480
end

--刷新数据
function RAChatUIPageCell:onRefreshContent(ccbRoot)
	--todo
	--CCLuaLog("RAChatUIPageCell:onRefreshContent")
	local data = self.mChatData
    local chatMsg = data.chatMsg
	if not ccbRoot then
        CCLuaLog("RAChatUIPageCell ccbroot is nil") 
        return 
    end
	local ccbfile = ccbRoot:getCCBFileNode() 
	self.ccbfile = ccbfile
    UIExtend.handleCCBNode(self.ccbfile)
    UIExtend.setNodeVisible(self.ccbfile, "mCopyBtnNode", false)
	--头像
	local iconPath = "HeadPortait_Female_01.png"
	if data.icon ~= 0 then
		iconPath = RAMailUtility:getPlayerIcon(data.icon)
	end
    
    --VIP Icon
    --UIExtend.setNodeVisible(ccbfile, "mVipNode", false)
    if self.mIsOtherPlayer or 
    data.type == RAChatData.CHAT_TYPE.hrefBroadcast or data.type == RAChatData.CHAT_TYPE.gmBroadcast or data.noticeType ~= 0 then
        UIExtend.getCCLabelBMFontFromCCB(ccbfile,"mSvIPLabel"):setVisible(false)
        UIExtend.getCCLabelBMFontFromCCB(ccbfile,"mVIPLabel"):setVisible(false)
    end
    
    local VIPPosX = 0
    if self.mIsOtherPlayer and data.vip >= 1 then
        --UIExtend.setNodeVisible(ccbfile, "mVipNode", true)
        local vipStr = "VIP"..data.vip
        if data.vipActive then
            UIExtend.getCCLabelBMFontFromCCB(ccbfile,"mSvIPLabel"):setVisible(true)
            UIExtend.setStringForLabel(ccbfile, {mSvIPLabel = vipStr})

            VIPPosX = UIExtend.getCCLabelBMFontFromCCB(ccbfile,"mSvIPLabel"):getContentSize().width
        else
            UIExtend.getCCLabelBMFontFromCCB(ccbfile,"mVIPLabel"):setVisible(true)
            UIExtend.setStringForLabel(ccbfile, {mVIPLabel = vipStr})

            VIPPosX = UIExtend.getCCLabelBMFontFromCCB(ccbfile,"mVIPLabel"):getContentSize().width
        end
    end
	--VIP 联盟名称 名称
	local otherNameStr = ""--"[VIP "..data.vip.."] "
	if RAChatManager:isChoosenTabWorld() then

        --个人公告
        if data.type == RAChatData.CHAT_TYPE.broadcast then
            otherNameStr = _RALang('@MainUISelfNotice')
        end

        --官职
        if data.office ~= 0 then
            local officeConf = RAWorldConfigManager:GetOfficialPositionCfg(data.office)
            if officeConf then
                otherNameStr = otherNameStr..'('.. _RALang(officeConf.officeName)..')'
            end
        end

        --vip
        --if data.vip > 0 then
            --otherNameStr = otherNameStr .. " VIP " .. data.vip
        --end

        --联盟简称
        if data.guildTag ~= "" then
            otherNameStr = otherNameStr.." ("..tostring(data.guildTag)..")"
        end
		
        --玩家名字
        if data.name ~= "" then
            otherNameStr = otherNameStr.." "..data.name
        end
	end

    --官职相关显示 begin
    if data.office ~= 0 then
    	local officeConf = RAWorldConfigManager:GetOfficialPositionCfg(data.office)

    	if officeConf then
            if data.office == President_pb.OFFICER_01 then --国王
                UIExtend.setNodeVisible(ccbfile,'mPresidentPic',false)
                UIExtend.setNodeVisible(ccbfile,'mApptPic',false)

                UIExtend.setSpriteImage(ccbfile, {mPresidentPic = officeConf.officeIcon})
            else
                UIExtend.setNodeVisible(ccbfile,'mPresidentPic',false)  
                UIExtend.setNodeVisible(ccbfile,'mApptPic',false)

                UIExtend.setSpriteImage(ccbfile, {mApptPic = officeConf.officeIcon})
            end
    	end
    else
    	UIExtend.setNodeVisible(ccbfile,'mPresidentPic',false)	
    	UIExtend.setNodeVisible(ccbfile,'mApptPic',false)	
    end

    local otherNameHTMLStr = _RAHtmlFill("CommonOtherName",otherNameStr)

    if data.type == RAChatData.CHAT_TYPE.hrefBroadcast or data.type == RAChatData.CHAT_TYPE.gmBroadcast or data.noticeType ~= 0  then
        otherNameStr = RAChatManager:getMessageNameById(data.noticeType)
        iconPath = RAChatManager.systemIcon
        otherNameHTMLStr = _RAHtmlFill("SystemName",otherNameStr)
    end
	UIExtend.addSpriteToNodeParent(ccbfile, "mHeadPortaitPicNode", iconPath)
	
    local otherName = UIExtend.getCCLabelHTMLFromCCB(ccbfile, "mOtherName")
    otherName:setString(otherNameHTMLStr)
	
    if self.mIsOtherPlayer then
        otherName:setPositionX(VIPPosX - 8)
    end

	--时间
	--local timeStr = Utilitys.timeConvertShowingTime(data.msgTime)
	--UIExtend.setCCLabelString(ccbfile, "mTime", timeStr)

	--内容
	contentWidth = self.mBubblePro.contentWidth
	if self.mIsOtherPlayer then
		--todo
		contentWidth = self.mBubblePro.otherContentWidth
	end

    local mOthersSendLabel = UIExtend.getCCLabelHTMLFromCCB(ccbfile, "mOthersSendLabel")
    if not self.mIsOtherPlayer then --初始值
        mOthersSendLabel:setPositionX(-5)
    end
    
    if self.mAddHeight > 0 then     --表示多行 一行 height 26
        self.mBgOriSize.width = contentWidth + 40

        contentWidth = self.mBubblePro.otherContentWidth
        UIExtend.setChatLabelHTMLString(ccbfile, "mOthersSendLabel",chatMsg, contentWidth)

        UIExtend.getCCSpriteFromCCB(ccbfile,"mOptArrow1"):setVisible(true)
        UIExtend.getCCSpriteFromCCB(ccbfile,"mOptArrow2"):setVisible(false)

        if not self.mIsOtherPlayer then  --自己的
            local x = mOthersSendLabel:getPositionX()
            mOthersSendLabel:setPositionX(x + 9)
            self.mBgOriSize.width =  self.mBgOriSize.width + 10
        else --其他人的
            mOthersSendLabel:setPositionX(30)    
        end
    else
        UIExtend.setChatLabelHTMLString(ccbfile, "mOthersSendLabel",chatMsg)

        local chtml = mOthersSendLabel:getHTMLContentSize()
        local cw = chtml.width

        self.mBgOriSize.width = cw + 50

        local mCopyBtnNode = UIExtend.getCCNodeFromCCB(ccbfile,"mCopyBtnNode")
        mCopyBtnNode:setPositionX(220)

        UIExtend.getCCSpriteFromCCB(ccbfile,"mOptArrow1"):setVisible(false)
        UIExtend.getCCSpriteFromCCB(ccbfile,"mOptArrow2"):setVisible(true)

        if not self.mIsOtherPlayer then
            local x = mOthersSendLabel:getPositionX()
            mOthersSendLabel:setPositionX(x - 8)
            self.mBgOriSize.width = cw + 60
        end
    end

    if not self.isRegister then
        self.isRegister = true
	    mOthersSendLabel:registerLuaClickListener(RAChatManager.createHtmlClick)
    end
	--复制按钮
	UIExtend.setNodeVisible(ccbfile, "mCopyBtnNode", false)

    local chtml = mOthersSendLabel:getHTMLContentSize()
    local cw = chtml.width

	local bubble = UIExtend.getCCNodeFromCCB(ccbfile, "mBubblePic")
    local bubbleSize = CCSizeMake(self.mBgOriSize.width, self.mBgOriSize.height + self.mAddHeight)
	bubble:setContentSize(bubbleSize)

    UIExtend.createClickNLongClick(bubble,RAChatUIPageCell.onShortClick,
    RAChatUIPageCell.onLongClick,{handler = self,endedColse = true,delay = 0.2},RAChatUIPageCell.onOutSideClick)

	--点击事件对应控件也要缩放
	local mclick = UIExtend.getCCMenuItemImageFromCCB(ccbfile, "mClick")
	local mclickSize = CCSizeMake(self.mBgOriSize.clickWidth, self.mBgOriSize.clickHeight + self.mAddHeight)
	mclick:setContentSize(mclickSize)

	--锚点（0,1），应该往上设置一下位置
	ccbfile:setPositionY(self.mAddHeight)
end

function RAChatUIPageCell.onShortClick(data)
    local handler = data.handler
    --UIExtend.setNodeVisible(handler.ccbfile, "mCopyBtnNode", false)
end

function RAChatUIPageCell.onLongClick(data)
    local handler = data.handler
    if handler.mIsOtherPlayer then
        UIExtend.setNodeVisible(handler.ccbfile, "mCopyBtnNode", true)
    end
end

function RAChatUIPageCell.onOutSideClick(data)
    local handler = data.handler
    if handler.ccbfile then 
    	UIExtend.setNodeVisible(handler.ccbfile, "mCopyBtnNode", false)
	end
end

function RAChatUIPageCell:setCopyBtnVisible( isVisible )
	-- body
	--UIExtend.setNodeVisible(self.ccbfile, "mCopyBtnNode", isVisible)--复制按钮
end

--------------------------------------------------------------
-----------------------事件处理-------------------------------
--------------------------------------------------------------

--点击气泡，弹出复制按钮
function RAChatUIPageCell:onClick()
	-- body
	--RAChatManager:clickOneCopyBtn( self.mTag )
end

--点击复制按钮
function RAChatUIPageCell:onCopyBtn()
	-- body
	local data = self.mChatData
	RAChatManager.mCopyContent = data.content
    RAPlatformUtils:copyToPastBoard(tostring(RAChatManager.mCopyContent))
end

function RAChatUIPageCell:onShieldedBtn()
    local data = self.mChatData
    if self.mIsOtherPlayer then
    	if data.type == RAChatData.CHAT_TYPE.hrefBroadcast or data.type == RAChatData.CHAT_TYPE.gmBroadcast
            or data.playerId == "" or data.playerId == nil then
    		RARootManager.ShowMsgBox(_RALang("@SystemMsgNotShield"))
    		return
    	end
        local RAShieldManager = RARequire("RAShieldManager")
        RAShieldManager:sendOneShieldCmd(data.playerId)
    end
    UIExtend.setNodeVisible(self.ccbfile, "mCopyBtnNode", false)
end

function RAChatUIPageCell:onAccusationBtn()
    RARootManager.ShowMsgBox('@NoOpenTips')
end

--国王屏蔽按钮
function RAChatUIPageCell:onPresidengShieldBtn()
    local data = self.mChatData
    if self.mIsOtherPlayer then
        
        local isPresident = RAPlayerInfoManager.IsPresident()
    	if not isPresident then --国王
    		RARootManager.ShowMsgBox(_RALang("@NoPresidengShield"))
    		return
    	end

    	if data.type == RAChatData.CHAT_TYPE.hrefBroadcast or data.type == RAChatData.CHAT_TYPE.gmBroadcast 
            or data.playerId == "" or data.playerId == nil then
    		RARootManager.ShowMsgBox(_RALang("@SystemMsgNotShield"))
    		return
    	end
        local RAShieldManager = RARequire("RAShieldManager")
        RAShieldManager:sendOnePresidengShieldCmd(data.playerId)
    end
    UIExtend.setNodeVisible(self.ccbfile, "mCopyBtnNode", false)
end

function RAChatUIPageCell:onUnLoad(ccbRoot)
    if not ccbRoot then return end
	local ccbfile = ccbRoot:getCCBFileNode()
    if ccbfile then
        local mOthersSendLabel = UIExtend.getCCLabelHTMLFromCCB(ccbfile, "mOthersSendLabel")
        if mOthersSendLabel then
	        mOthersSendLabel:removeLuaClickListener()
        end
    end
end

return RAChatUIPageCell