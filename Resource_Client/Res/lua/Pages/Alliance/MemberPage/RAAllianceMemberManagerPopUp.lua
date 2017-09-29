--联盟成员管理的弹出框
RARequire("BasePage")
RARequire("MessageManager")
local UIExtend = RARequire("UIExtend")
local RARootManager = RARequire("RARootManager")
local Utilitys = RARequire("Utilitys")
local RAAllianceMemberManagerPopUp = BaseFunctionPage:new(...)
local RAAllianceManager = RARequire('RAAllianceManager')
local RAPlayerInfoManager = RARequire('RAPlayerInfoManager')
local RAAllianceUtility = RARequire('RAAllianceUtility')
local RAStringUtil = RARequire('RAStringUtil')


local BTN_TYPE = 
{
    DETAIL                            = 1,  --玩家信息
    MAIL                              = 2,  --邮件
    RESAID                            = 3,  --资源援助
    SODAID                            = 4,  --士兵援助
    CHANGE                            = 5,  --阶级调整
    MOVE                              = 6,  --邀请迁城
    EXPEL                             = 7,  --逐出
}

--HUD上的文字
local Btn_Txt_Map = {
   [BTN_TYPE.DETAIL]                    = "@Detail",              --详情
   [BTN_TYPE.MAIL]                      = "@Mail",                --邮件
   [BTN_TYPE.RESAID]                    = "@ResourceAid",         --资源援助
   [BTN_TYPE.SODAID]                    = "@SoldierAid",          --士兵援助
   [BTN_TYPE.CHANGE]                    = "@ChangeTitle",         --阶级调整
   [BTN_TYPE.MOVE]                      = "@InviteToMigrate",     --邀请迁城
   [BTN_TYPE.EXPEL]                     = "@MemDismiss",          --逐出
}

local RAHUDBtnHandler = {}
--构造函数
function RAHUDBtnHandler:new(type)
    local o = {}
    o.btnType = type
    o.handler = nil 
    o.ccbfile = nil 
    setmetatable(o,self)
    self.__index = self
    return o
end

function RAHUDBtnHandler:setType(btnType)
    self.btnType = btnType
end

function RAHUDBtnHandler:setCCbfile(ccbfile)
    self.ccbfile = ccbfile
end

function RAHUDBtnHandler:onFunctionBtn()
    print("onFunctionBtn")
    if self.handler ~= nil then 
        self.handler:onFunction(self.btnType)
    end 
end

function RAHUDBtnHandler:onQuitBtn()
    if self.handler ~= nil then 
        self.handler:onQuitBtn(self.btnType)
    end 
end

function RAHUDBtnHandler:remove()
    if self.ccbfile then
        self.ccbfile:unregisterFunctionHandler()
        self.ccbfile = nil
    end
end


local OnReceiveMessage = function(message)
    if message.messageID == MessageDef_Packet.MSG_Operation_OK then
        print("message.opcode = ",message.opcode)
        if message.opcode == HP_pb.GUILDMANAGER_KICK_C then --踢成功
            RARootManager.ShowMsgBox("@TirenSuccess")
            --需要刷新联盟人数
            if RAAllianceManager.selfAlliance.memberNum > 1 then
                RAAllianceManager.selfAlliance.memberNum = RAAllianceManager.selfAlliance.memberNum - 1
            end
            MessageManager.sendMessage(MessageDef_AlliancePage.MSG_RefreshMemberPage)
            MessageManager.sendMessage(MessageDef_AlliancePage.MSG_RefreshMainPage)
            RARootManager.ClosePage('RAAllianceMemberManagerPopUp')
        elseif message.opcode == HP_pb.GUILD_INVITE_TO_MOVE_CITY_C then
            RARootManager.ShowMsgBox("@InviteMoveSucc")
        end 
    elseif message.messageID == MessageDef_Packet.MSG_Operation_Fail then 
        if message.opcode == HP_pb.GUILDMANAGER_KICK_C then 
            --RARootManager.ShowMsgBox("@TirenFail")
        end 
    end 
end

function RAAllianceMemberManagerPopUp:registerMessage()
    MessageManager.registerMessageHandler(MessageDef_Packet.MSG_Operation_OK,OnReceiveMessage)
    MessageManager.registerMessageHandler(MessageDef_Packet.MSG_Operation_Fail,OnReceiveMessage)
end

function RAAllianceMemberManagerPopUp:removeMessageHandler()
    MessageManager.removeMessageHandler(MessageDef_Packet.MSG_Operation_OK,OnReceiveMessage)
    MessageManager.removeMessageHandler(MessageDef_Packet.MSG_Operation_Fail,OnReceiveMessage)
end

function RAAllianceMemberManagerPopUp:Enter(data)
    self.isOpen = true
    self.ccbfile = UIExtend.loadCCBFile("RAAllianceMemManagerPopUp1.ccbi", RAAllianceMemberManagerPopUp)
    self.data = data
    self.btnTable = {}
    self:registerMessage()
    --玩家名字
    self.mPlayerName = UIExtend.getCCLabelTTFFromCCB(self.ccbfile,'mPlayerName')
    self.mPlayerName:setString(data.playerName)

    -- --玩家战力
    -- self.mFightValue = UIExtend.getCCLabelTTFFromCCB(self.ccbfile,'mFightValue')
    -- self.mFightValue:setString(Utilitys.formatNumber(self.data.power))
    
    --头像
    local playerIcon = RAPlayerInfoManager.getHeadIcon(self.data.icon)
	UIExtend.addSpriteToNodeParent(self.ccbfile, "mMemIconNode", playerIcon)

	--联盟阶级
    self.mLevelLabel = UIExtend.getCCLabelTTFFromCCB(self.ccbfile,'mLevelLabel')
    self.mLevelLabel:setString(self.data.authority)
    local btnCount = 1
    self:initSingleBtn(btnCount,BTN_TYPE.DETAIL)
    btnCount = btnCount + 1
    self:initSingleBtn(btnCount,BTN_TYPE.MAIL)
    btnCount = btnCount + 1
    if self.data.contentType == 0 then --自己联盟 

        self:initSingleBtn(btnCount,BTN_TYPE.RESAID)        
        btnCount = btnCount + 1
        self:initSingleBtn(btnCount,BTN_TYPE.SODAID)            
        btnCount = btnCount + 1
        -- self.ccbfile:getCCControlButtonFromCCB('mFunctionBtn1'):setEnabled(true)
        -- self.ccbfile:getCCControlButtonFromCCB('mFunctionBtn2'):setEnabled(true)
        --调整阶级
        local isCan = RAAllianceUtility:isCanPlayerClass(self.data.authority)
        if isCan then 
            self:initSingleBtn(btnCount,BTN_TYPE.CHANGE)            
            btnCount = btnCount + 1            
        end
        --邀请迁城
        isCan = RAAllianceUtility:isCanInvatationCity(self.data.authority)
        if isCan then 
            self:initSingleBtn(btnCount,BTN_TYPE.MOVE)            
            btnCount = btnCount + 1            
        end

    	--是否可以踢人
    	isCan = RAAllianceUtility:isCanKickPeople(self.data.authority)

        if isCan then 
            self:initSingleBtn(btnCount,BTN_TYPE.EXPEL)            
            btnCount = btnCount + 1            
        end
    end 
    self.btnCount = btnCount - 1
    self.ccbfile:runAnimation("InAni"..self.btnCount)

    self.closeFunc = function()
        self:onClose()
    end    
end

--初始化按钮
function RAAllianceMemberManagerPopUp:initSingleBtn(btnIndex,btnType)

    local ccbfile =  UIExtend.getCCBFileFromCCB(self.ccbfile,'mCellCCB' .. btnIndex) 
    UIExtend.setMenuItemVisible(ccbfile, "mFunctionBtn", btnType ~= BTN_TYPE.EXPEL)
    UIExtend.setMenuItemVisible(ccbfile, "mQuitBtn", btnType == BTN_TYPE.EXPEL)
    UIExtend.setCCLabelString(ccbfile, "mBtnName", _RALang(Btn_Txt_Map[btnType]))
    local btn = self.btnTable[btnIndex]
    if btn == nil then
        btn = RAHUDBtnHandler:new(btnType)
        btn.handler = self
        self.btnTable[btnIndex] = btn
    else
        btn:setType(btnType)
    end 
    ccbfile:unregisterFunctionHandler()
    ccbfile:registerFunctionHandler(btn)
end


function RAAllianceMemberManagerPopUp:Exit()
    for i,v in ipairs(self.btnTable) do
        v:remove()
    end
    self.btnTable = nil
    self:removeMessageHandler()
	UIExtend.unLoadCCBFile(RAAllianceMemberManagerPopUp)
end

--------------------------------------------------------------
-----------------------动画处理-------------------------------
--------------------------------------------------------------
function RAAllianceMemberManagerPopUp:OnAnimationDone(ccbfile)
    --body
    local lastAnimationName = ccbfile:getCompletedAnimationName()       
    if lastAnimationName == "OutAni"..self.btnCount then
        RARootManager.ClosePage("RAAllianceMemberManagerPopUp")
    end
end

--关闭
function RAAllianceMemberManagerPopUp:onClose()
    if self.isOpen then
        self.ccbfile:runAnimation("OutAni"..self.btnCount)
        self.isOpen = nil
    end
end

function RAAllianceMemberManagerPopUp.closeFunc(  )
    -- body
end

--
function RAAllianceMemberManagerPopUp:onFunction(btnType)
    if btnType == BTN_TYPE.DETAIL then
        self:onFunctionBtn3()
    elseif btnType == BTN_TYPE.MAIL then
        self:onFunctionBtn6()
    elseif btnType == BTN_TYPE.RESAID then
        self:onFunctionBtn2()
    elseif btnType == BTN_TYPE.SODAID then
        self:onFunctionBtn1()
    elseif btnType == BTN_TYPE.CHANGE then
        self:onFunctionBtn5()
    elseif btnType == BTN_TYPE.MOVE then
        self:onFunctionBtn7()
    end                               
end

function RAAllianceMemberManagerPopUp:onQuitBtn(btnType)
    self:onFunctionBtn4()
end

function RAAllianceMemberManagerPopUp:onFunctionBtn1()
	CCLuaLog('士兵援助')
	local pageData = {
        posX = self.data.x,
        posY = self.data.y,
        name = self.data.playerName,
        icon = RAPlayerInfoManager.getHeadIcon(self.data.icon),
        playerId = self.data.playerId
    }
    RARootManager.OpenPage('RAAllianceSoldierAidPage', pageData, false, true, true)
end

function RAAllianceMemberManagerPopUp:onFunctionBtn2()
	CCLuaLog('资源援助')

	--
	local Const_pb = RARequire('Const_pb')
	local RABuildManager = RARequire('RABuildManager')
	local arr=RABuildManager:getBuildDataArray(Const_pb.TRADE_CENTRE)
	if #arr == 0 then 
		RARootManager.ShowMsgBox(_RALang('@ResourceAidNeedHaveTradecnter'))
		return
	end 


	local targetPos={x = self.data.x,y=self.data.y}
    local targetLevel=self.data.buildingLevel

    local pageData={endPos=targetPos,level=targetLevel}
    RARootManager.OpenPage('RAWorldResourceAidPage', pageData, true, true, true)
end

function RAAllianceMemberManagerPopUp:onFunctionBtn3()
	-- CCLuaLog('玩家信息')
	RARootManager.OpenPage('RAGeneralInfoPage', {playerId = self.data.playerId})
end

function RAAllianceMemberManagerPopUp:onFunctionBtn4()
	CCLuaLog('提出联盟')
    local confirmData = {}
        confirmData.labelText = _RALang("@PlayAllinceTxt")
        confirmData.title = _RALang("@PlayAllinceTitleTxt")
        confirmData.resultFun = function (isOk)
            local RAAllianceProtoManager = RARequire("RAAllianceProtoManager")
            RAAllianceProtoManager:sendKickMemberReq(self.data.playerId)
        end
        RARootManager.OpenPage("RAConfirmPage", confirmData, false, true, true)
end

function RAAllianceMemberManagerPopUp:onFunctionBtn5()
	CCLuaLog('阶级调整')
	RARootManager.OpenPage("RAAllianceModifyAuthorityPage",self.data,false, true, true)
end

function RAAllianceMemberManagerPopUp:onFunctionBtn6()
	-- CCLuaLog('邮件')
    -- RARootManager.ShowMsgBox('@NoOpenTips')
    RARootManager.OpenPage("RAMailWritePage",{sendName = self.data.playerName})
end
--邀请迁城
function RAAllianceMemberManagerPopUp:onFunctionBtn7()
    local RAAllianceProtoManager = RARequire("RAAllianceProtoManager")
    RAAllianceProtoManager:sendPacketInviteMove(self.data.playerId)
end

return RAAllianceMemberManagerPopUp