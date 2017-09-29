--联盟成员管理中修改阶级权限的弹出框
RARequire("BasePage")
RARequire("MessageManager")
local UIExtend = RARequire("UIExtend")
local RARootManager = RARequire("RARootManager")
local Utilitys = RARequire("Utilitys")
local html_zh_cn = RARequire('html_zh_cn')
local RAStringUtil = RARequire('RAStringUtil')
local RAAllianceUtility = RARequire('RAAllianceUtility')

local RAAllianceModifyAuthorityPage = BaseFunctionPage:new(...)

local OnReceiveMessage = function(message)
    if message.messageID == MessageDef_Packet.MSG_Operation_OK then
        if message.opcode == HP_pb.GUILDMANAGER_CAHNGELEVEL_C then --阶级调整成功
            RARootManager.ClosePage("RAAllianceModifyAuthorityPage")
            RARootManager.ShowMsgBox("@AdjustmentSuccess")
            RAAllianceModifyAuthorityPage.data.authority = RAAllianceModifyAuthorityPage.currAuthority
            MessageManager.sendMessage(MessageDef_AlliancePage.MSG_RefreshMemberPage) 
            --TODO 需要刷新修改成功后的玩家数据
        end 
    elseif message.messageID == MessageDef_Packet.MSG_Operation_Fail then 
        if message.opcode == HP_pb.GUILDMANAGER_CAHNGELEVEL_C then 
            RARootManager.ShowMsgBox("@AdjustmentFail")
        end 
    end 
end

function RAAllianceModifyAuthorityPage:registerMessage()
    MessageManager.registerMessageHandler(MessageDef_Packet.MSG_Operation_OK,OnReceiveMessage)
    MessageManager.registerMessageHandler(MessageDef_Packet.MSG_Operation_Fail,OnReceiveMessage)
end

function RAAllianceModifyAuthorityPage:removeMessageHandler()
    MessageManager.removeMessageHandler(MessageDef_Packet.MSG_Operation_OK,OnReceiveMessage)
    MessageManager.removeMessageHandler(MessageDef_Packet.MSG_Operation_Fail,OnReceiveMessage)
end

function RAAllianceModifyAuthorityPage:Enter(data)

	self.ccbfile = UIExtend.loadCCBFile("RAAllianceMemManagerPopUp2.ccbi", self)
    --当前所在阶级
    self.currAuthority = data.authority
    --名字
    self.playerName = data.playerName
    self.playerId = data.playerId
    self.data = data
    --当前选择的
    self.selectAuthority = self.currAuthority

    self:registerMessage()

    self:refreshUI()
end

function RAAllianceModifyAuthorityPage:refreshUI()
	-- body
	for i=1,4 do
		local picName = RAAllianceUtility:getLIcon(i)
		UIExtend.addSpriteToNodeParent(self.ccbfile, "mRankIconNode"..i, picName)
        UIExtend.setStringForLabel(self.ccbfile,{['mRankLevelLabel'..i] = tostring(i)})
        UIExtend.setMenuItemEnable(self.ccbfile,'mRankBtn'..i,true)
	end

	local desStr = RAStringUtil:fill(html_zh_cn["AllianceAuthorityDes"],self.playerName,self.currAuthority) 
    local labelHtml = self.ccbfile:getCCLabelHTMLFromCCB("mPlayerCurrentRank")
    labelHtml:setPreferredSize(600,150)
    labelHtml:setString(desStr)

    --当前选择
    UIExtend.setMenuItemEnable(self.ccbfile,'mRankBtn'..self.currAuthority,false)
end

--点击选择回调
function RAAllianceModifyAuthorityPage:onRankBtn1()
	--上次选择的设置可以点
    UIExtend.setMenuItemEnable(self.ccbfile,'mRankBtn'..self.currAuthority,true)
    self:setAuthority(1)
    --当前选择
    UIExtend.setMenuItemEnable(self.ccbfile,'mRankBtn'..self.selectAuthority,false)
end
function RAAllianceModifyAuthorityPage:onRankBtn2()
	--上次选择的设置可以点
    UIExtend.setMenuItemEnable(self.ccbfile,'mRankBtn'..self.currAuthority,true)
    self:setAuthority(2)
    --当前选择
    UIExtend.setMenuItemEnable(self.ccbfile,'mRankBtn'..self.selectAuthority,false)
end
function RAAllianceModifyAuthorityPage:onRankBtn3()
	--上次选择的设置可以点
    UIExtend.setMenuItemEnable(self.ccbfile,'mRankBtn'..self.currAuthority,true)
    self:setAuthority(3)
    --当前选择
    UIExtend.setMenuItemEnable(self.ccbfile,'mRankBtn'..self.selectAuthority,false)
end
function RAAllianceModifyAuthorityPage:onRankBtn4()
	--上次选择的设置可以点
    UIExtend.setMenuItemEnable(self.ccbfile,'mRankBtn'..self.currAuthority,true)
    self:setAuthority(4)
    --当前选择
    UIExtend.setMenuItemEnable(self.ccbfile,'mRankBtn'..self.selectAuthority,false)
end
---end

function RAAllianceModifyAuthorityPage:setAuthority(authority)
	-- body
	self.selectAuthority = authority
	self.currAuthority = authority
end

--提升按钮
function RAAllianceModifyAuthorityPage:onUpdateRank()
    local RAAllianceProtoManager = RARequire("RAAllianceProtoManager")
    RAAllianceProtoManager:changeGuildLevelReq(self.selectAuthority,self.playerId)
end

function RAAllianceModifyAuthorityPage:onClose()
	RARootManager.CloseCurrPage()
end

function RAAllianceModifyAuthorityPage:onCancelBtn()
	RARootManager.CloseCurrPage()
end

function RAAllianceModifyAuthorityPage:Exit()
	-- body
	self.currAuthority = nil
    self:removeMessageHandler()
	UIExtend.unLoadCCBFile(self)
end

return RAAllianceModifyAuthorityPage