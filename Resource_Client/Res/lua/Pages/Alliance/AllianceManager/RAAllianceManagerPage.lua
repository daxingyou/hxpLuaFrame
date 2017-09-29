--to:联盟管理页面
RARequire("BasePage")
local UIExtend = RARequire("UIExtend")
local alliance_authority_conf = RARequire("alliance_authority_conf")
local RAAllianceProtoManager = RARequire("RAAllianceProtoManager")
local RARootManager = RARequire("RARootManager")
local RAAllianceManager = RARequire("RAAllianceManager")
local Const_pb = RARequire("Const_pb")

local RAAllianceManagerPage = BaseFunctionPage:new(...)

local OnReceiveMessage = function(message)
    if message.messageID == MessageDef_Packet.MSG_Operation_OK then
        if message.opcode == HP_pb.GUILDMANAGER_DISSMISEGUILD_C then --解散成功
            --RARootManager.ShowMsgBox("@DissolutionSuccess") --todo 先注释掉，不然在Android平台会闪退
            RARootManager.CloseAllPages()
            RARootManager.OpenPage("RAAllianceJoinPage")

            RAAllianceManager:ClearChatContent()
        elseif message.opcode == HP_pb.GUILDMANAGER_QUIT_C then --退出成功
        	--RARootManager.ShowMsgBox("@ExitSuccess") --todo 先注释掉，不然在Android平台会闪退
            RARootManager.CloseAllPages()
            RARootManager.OpenPage("RAAllianceJoinPage")
            
            RAAllianceManager:ClearChatContent()
        end 
    elseif message.messageID == MessageDef_Packet.MSG_Operation_Fail then 
        if message.opcode == HP_pb.GUILDMANAGER_DISSMISEGUILD_C then 
            --RARootManager.ShowMsgBox("@DissolutionFail")
        elseif message.opcode == HP_pb.GUILDMANAGER_QUIT_C then 
            --RARootManager.ShowMsgBox("@ExitFail")
        end 
    end 
end

function RAAllianceManagerPage:registerMessage()
    MessageManager.registerMessageHandler(MessageDef_Packet.MSG_Operation_OK,OnReceiveMessage)
    MessageManager.registerMessageHandler(MessageDef_Packet.MSG_Operation_Fail,OnReceiveMessage)
end

function RAAllianceManagerPage:removeMessageHandler()
    MessageManager.removeMessageHandler(MessageDef_Packet.MSG_Operation_OK,OnReceiveMessage)
    MessageManager.removeMessageHandler(MessageDef_Packet.MSG_Operation_Fail,OnReceiveMessage)
end

function RAAllianceManagerPage:Enter(data)
	-- 
    self:registerMessage()
	self.authorityId = data.authorityId
	local ccbfile = UIExtend.loadCCBFile("RAAllianceManagerPopUp.ccbi",self)
    self:refreshPage()
end

function RAAllianceManagerPage:onFunctionBtn1()
    local btnType = self.btnTable[1]
    self:onBtnType(btnType)
end
function RAAllianceManagerPage:onFunctionBtn2()
    local btnType = self.btnTable[2]
    self:onBtnType(btnType)
end
function RAAllianceManagerPage:onFunctionBtn3()
    local btnType = self.btnTable[3]
    self:onBtnType(btnType)
end
function RAAllianceManagerPage:onFunctionBtn4()
    local btnType = self.btnTable[4]
    self:onBtnType(btnType)
end
function RAAllianceManagerPage:onFunctionBtn5()
    local btnType = self.btnTable[5]
    self:onBtnType(btnType)
end
function RAAllianceManagerPage:onFunctionBtn6()
    local btnType = self.btnTable[6]
    self:onBtnType(btnType)
end
function RAAllianceManagerPage:onFunctionBtn7()
    local btnType = self.btnTable[7]
    self:onBtnType(btnType)
end

function RAAllianceManagerPage:refreshPage()
	-- 
	for i=1,7 do
        UIExtend.setNodeVisible(self.ccbfile,"mFunctionBtnNode"..i,false)
	end

	local alliance_authority = alliance_authority_conf[self.authorityId]

	local btnCount = 0
    self.btnTable = {}
    --联盟设置都有
    
    if alliance_authority.alliance_setting == 1 then --联盟设置
        btnCount = btnCount + 1
    	self:initBtn(btnCount,"AllianceSetting")
    	self.btnTable[btnCount] = "AllianceSetting"
	end
    if alliance_authority.invite_to_join_alliance == 1 then --联盟旗帜
    	btnCount = btnCount + 1
        self:initBtn(btnCount,"AllianceApplication")
        self.btnTable[btnCount] = "AllianceApplication"
    end
    if alliance_authority.edit_alliance_flag == 1 then --联盟旗帜
    	btnCount = btnCount + 1
        self:initBtn(btnCount,"AllianceFlag")
        self.btnTable[btnCount] = "AllianceFlag"
    end
    if alliance_authority.message_leaving_authority == 1 then --解除留言屏蔽
    	btnCount = btnCount + 1
        self:initBtn(btnCount,"MessageLeavingAuthority")
        self.btnTable[btnCount] = "MessageLeavingAuthority"
    end
    if alliance_authority.other_alliance == 1 then --其他联盟
    	btnCount = btnCount + 1
        self:initBtn(btnCount,"OtherAlliance")
        self.btnTable[btnCount] = "OtherAlliance"
    end
    if alliance_authority.authority_info == 1 then --联盟权限详情
    	btnCount = btnCount + 1
        self:initBtn(btnCount,"AuthorityInfo")
        self.btnTable[btnCount] = "AuthorityInfo"
    end
    if alliance_authority.alliance_leadership_change == 1 then --盟主转让 ( todo... or 解散联盟 dissolve_alliance )
    	btnCount = btnCount + 1
    	--如果联盟只有盟主一个人的时候,按钮变为解散联盟，则转让盟主
    	--todo...
    	local value = "AllianceLeadershipChange"
    	local RAAllianceInfo = RARequire("RAAllianceInfo")	--转让
    	if RAAllianceManager.selfAlliance.memberNum == 1 then	--解散
        	value = "DissolutionAlliance"
    	end 
        self:initBtn(btnCount,value)
    	self.btnTable[btnCount] = value
    end

    --如果btnCount < 7 说明不是盟主 得加退出联盟按钮
    if btnCount < 7 then
    	btnCount = btnCount + 1
        self:initBtn(btnCount,"ExitAlliance")
        self.btnTable[btnCount] = "ExitAlliance"
    end
end

function RAAllianceManagerPage:onBtnType(btnType)
    local RAPlayerInfoManager = RARequire('RAPlayerInfoManager')

    if btnType == "AllianceSetting" then --联盟设置
        RARootManager.OpenPage("RAAllianceSettingPage")
    elseif btnType == "AllianceApplication" then  --联盟申请
        RARootManager.OpenPage("RAAllianceApplicationPage")
    elseif btnType == "AllianceFlag" then --联盟旗帜
 	    RARootManager.OpenPage("RAAllianceFlagPage")
    elseif btnType == "MessageLeavingAuthority" then --解除留言屏蔽
        RARootManager.OpenPage("RAAllianceBlockedPage")
    elseif btnType == "AuthorityInfo" then --联盟权限详情
        RARootManager.OpenPage("RAAlliancePermissionsPage")
    elseif btnType == "AllianceLeadershipChange" then --盟主转让
        if RAPlayerInfoManager.IsPresident() then
            RARootManager.ShowMsgBox('@PresidentCannotMakeOver')
            return
        end
        RARootManager.OpenPage("RAAllianceTransferPage")
    elseif btnType == "DissolutionAlliance" then --解散联盟
        if RAPlayerInfoManager.IsPresident() then
            RARootManager.ShowMsgBox('@PresidentCannotDissolve')
            return
        end
        if RAPlayerInfoManager.IsTmpPresident() then
            RARootManager.ShowMsgBox('@TmpPresidentCannotDissolve')
            return
        end
	    local confirmData = {}
        confirmData.labelText = _RALang("@WarningTxt")
        confirmData.title = _RALang("@WarningTitleTxt")
	    confirmData.resultFun = function (isOk)
            RAAllianceProtoManager.dissolutionAlliance()
	    end
	    RARootManager.OpenPage("RAConfirmPage", confirmData)
    elseif btnType == "OtherAlliance" then --其他联盟
        RARootManager.OpenPage("RAAllianceOtherListPage")
    elseif btnType == "ExitAlliance" then --退出联盟
        local confirmData = {}
        confirmData.labelText = _RALang("@ExitAllinceTxt")
        confirmData.title = _RALang("@ExitAllinceTitleTxt")
	    confirmData.resultFun = function (isOk)
		    local RAPlayerInfoManager = RARequire("RAPlayerInfoManager")
            local playerId = RAPlayerInfoManager.getPlayerId()
            RAAllianceProtoManager.quitAlliance(playerId)
	    end
	    RARootManager.OpenPage("RAConfirmPage", confirmData)
    end
end

function RAAllianceManagerPage:initBtn(btnCount,btnText)
    UIExtend.setNodeVisible(self.ccbfile,"mFunctionBtnNode"..btnCount,true)
    UIExtend.setControlButtonTitle(self.ccbfile, "mFunctionBtn"..btnCount,"@"..btnText)

    if btnText == "AllianceApplication" then
        local posNode = UIExtend.getCCNodeFromCCB(self.ccbfile,"mPosNode"..btnCount)
        if posNode then
            local position = ccp(posNode:getPosition())
            local applicationTipsNode = UIExtend.getCCNodeFromCCB(self.ccbfile,"mApplicationTipsNode")
            if applicationTipsNode then
                applicationTipsNode:setPosition(position)
                UIExtend.setStringForLabel(self.ccbfile, {mApplicationTipsNum = RAAllianceManager.applyNum})
                local isRedPoit = false
                if RAAllianceManager.applyNum > 0 then
                    isRedPoit = true
                end
                UIExtend.setNodesVisible(self.ccbfile,{mApplicationTipsNode = isRedPoit})
            end
        end
    end
end

function RAAllianceManagerPage:onClose()
	-- body
	RARootManager.CloseCurrPage()  
end

function RAAllianceManagerPage:Exit()
    print("RAAllianceManagerPage:Exit")
    self:removeMessageHandler()
    UIExtend.unLoadCCBFile(self)
end

return RAAllianceManagerPage