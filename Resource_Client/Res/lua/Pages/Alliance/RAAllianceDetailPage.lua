--联盟详情页面
RARequire("BasePage")
local UIExtend = RARequire("UIExtend")
local HP_pb = RARequire("HP_pb")
local RARootManager = RARequire("RARootManager")
local RANetUtil = RARequire("RANetUtil")
local RAAllianceDetailPage = BaseFunctionPage:new(...)
local RAAllianceProtoManager = RARequire('RAAllianceProtoManager')
local RAAllianceManager = RARequire('RAAllianceManager')
local RAAllianceUtility = RARequire('RAAllianceUtility')
local alliance_language_conf = RARequire('alliance_language_conf')
local RABuildManager = RARequire('RABuildManager')
local RAPlayerInfoManager = RARequire('RAPlayerInfoManager')
local i18nconfig_conf = RARequire('i18nconfig_conf')
RARequire('MessageManager')

--RARootManager.OpenPage('RAAllianceDetailPage',{isNeedRequest=true,id = allianceId,type = 1})
--data.isNeedRequest 是否需要请求数据 data.id 联盟id data.type :0 申请面板 1 查看别的玩家
function RAAllianceDetailPage:Enter(data)
    self.ccbfile = UIExtend.loadCCBFile("RAAllianceJoinDetailsPage.ccbi", RAAllianceDetailPage)

    self:initTitle()
    self:addHandler()
    self:registerMessage() 
    if data.isNeedRequest == true then 
        RAAllianceProtoManager:getAllianceReq(data.id)
    else 
        self.info = data
        self:initInfo()
    end 
end

local OnReceiveMessage = function(message)
    if message.messageID == MessageDef_Packet.MSG_Operation_OK then
        if message.opcode == HP_pb.GUILDMANAGER_APPLY_C then 
            local RAAllianceManager =  RARequire('RAAllianceManager')
            if RAAllianceManager.selfAlliance == nil then 
                RAAllianceDetailPage.info.isApply = true
                RARootManager.ShowMsgBox(_RALang('@AllianceApplicationSucess'))
                RAAllianceDetailPage:refreshBtn()
            else
                RARootManager.ShowMsgBox(_RALang('@AllianceJoinSuccess'))    
            end
        elseif message.opcode == HP_pb.GUILDMANAGER_CANCELAPPLY_C then 
            RAAllianceDetailPage.info.isApply = false
            RARootManager.ShowMsgBox(_RALang('@AllianceCancelApplySucess'))
            RAAllianceDetailPage:refreshBtn()
        end 
    end
end 

function RAAllianceDetailPage:registerMessage()
    MessageManager.registerMessageHandler(MessageDef_Packet.MSG_Operation_OK,OnReceiveMessage)
end

function RAAllianceDetailPage:removeMessageHandler()
    MessageManager.removeMessageHandler(MessageDef_Packet.MSG_Operation_OK,OnReceiveMessage)
end

function RAAllianceDetailPage:addHandler()
    self.netHandlers = {}
    self.netHandlers[#self.netHandlers + 1] = RANetUtil:addListener(HP_pb.GUILDMANAGER_GETMEMBERINFO_S, RAAllianceDetailPage)
    self.netHandlers[#self.netHandlers + 1] = RANetUtil:addListener(HP_pb.GUILDMANAGER_GETINFO_S, RAAllianceDetailPage) --加入联盟
end


    --移除
function RAAllianceDetailPage:removeHandler()
    for k, value in pairs(self.netHandlers) do
        RANetUtil:removeListener(value)
    end
end

function RAAllianceDetailPage:onReceivePacket(handler)
    local pbCode = handler:getOpcode()
    local buffer = handler:getBuffer()
    if pbCode == HP_pb.GUILDMANAGER_GETMEMBERINFO_S then --获得联盟成员
        if RAAllianceDetailPage.isRequest then
            local memberInfos,leaderNames = RAAllianceProtoManager:getGuildMemeberInfoResp(buffer)
            RARootManager.OpenPage("RAAllianceMemberPage",{memberInfos=memberInfos,leaderNames = leaderNames,contentType=1})
            RAAllianceDetailPage.isRequest = nil
        end
    elseif pbCode == HP_pb.GUILDMANAGER_GETINFO_S then --
        local msg = GuildManager_pb.GetGuildInfoResp()
        msg:ParseFromString(buffer)

        local RAAllianceInfo = RARequire('RAAllianceInfo')
        local info = RAAllianceInfo:new()

        info:initByPb(msg)
        self.info = info
        self:initInfo()
    end
end

--初始化顶部
function RAAllianceDetailPage:initTitle()
    -- body
    self.mDiamondsNode = UIExtend.getCCNodeFromCCB(self.ccbfile:getCCBFileFromCCB("mAllianceCommonCCB"),'mDiamondsNode')
    self.mDiamondsNode:setVisible(false)

    self.ccbfile:getCCBFileFromCCB("mAllianceCommonCCB"):runAnimation("InAni")
    local titleName = _RALang("@Alliance")
    UIExtend.setCCLabelString(self.ccbfile:getCCBFileFromCCB("mAllianceCommonCCB"),'mTitle',titleName)
end

function RAAllianceDetailPage:initInfo()
	 --联盟名字
    self.mAllianceName = UIExtend.getCCLabelTTFFromCCB(self.ccbfile,'mAllianceName')
    self.mAllianceName:setString('[' .. self.info.tag .. ']' .. self.info.name)

     --盟主名字
    self.mAllianceLeader = UIExtend.getCCLabelTTFFromCCB(self.ccbfile,'mAllianceLeader')
    self.mAllianceLeader:setString(_RALang('@DetailPageLeaderName',self.info.leaderName))

    --联盟人数
    self.mAllianceMemNum = UIExtend.getCCLabelTTFFromCCB(self.ccbfile,'mAllianceMemNum')
    self.mAllianceMemNum:setString(_RALang('@DetailPageMemNum',self.info.memberNum,self.info.memberMaxNum))

    --联盟战力
    self.mAllianceFightValue = UIExtend.getCCLabelTTFFromCCB(self.ccbfile,'mAllianceFightValue')
    self.mAllianceFightValue:setString(_RALang('@DetailPageFightValue',self.info.power))

    --联盟语言
    self.mAllianceLanguage = UIExtend.getCCLabelTTFFromCCB(self.ccbfile,'mAllianceLanguage')
    --self.mAllianceLanguage:setString(alliance_language_conf[self.info.language].language_name)

    local allianceTypeName = _RALang('@AllianceTypeDeveloping')
    if self.info.guildType == GuildManager_pb.STRATEGIC then
        allianceTypeName = _RALang('@AllianceTypeStrategic')
    elseif self.info.guildType == GuildManager_pb.FIGHTING then
        allianceTypeName = _RALang('@AllianceTypeFighting')
    end
    self.mAllianceLanguage:setString(allianceTypeName) 

    --联盟宣言
    self.mAllianceDeclaration = UIExtend.getCCLabelTTFFromCCB(self.ccbfile,'mAllianceDeclaration')
    self.mAllianceDeclaration:setString(self.info.announcement)

    if self.info.openRecurit == true then 
    	UIExtend.setControlButtonTitle(self.ccbfile, "mApplicationBtn","@Join")
    else 
    	UIExtend.setControlButtonTitle(self.ccbfile, "mApplicationBtn","@Apply")
    end 

    --旗帜
    local flagIcon = RAAllianceUtility:getAllianceFlagIdByIcon(self.info.flag)
    UIExtend.addSpriteToNodeParent(self.ccbfile, "mAllianceIconNode", flagIcon)

    self.mApplicationBtn = UIExtend.getCCControlButtonFromCCB(self.ccbfile,'mApplicationBtn')
    self.mApplicationBtnNode = UIExtend.getCCNodeFromCCB(self.ccbfile,'mApplicationBtnNode')

    self.mHeadquarterLowerNum = UIExtend.getCCLabelTTFFromCCB(self.ccbfile,'mHeadquartersLowerNum')
    self.mHeadquarterLowerNum:setString(self.info.needBuildingLevel)

    self.mCommanderLowerNum = UIExtend.getCCLabelTTFFromCCB(self.ccbfile,'mCommanderLowerNum')
    self.mCommanderLowerNum:setString(self.info.needCommonderLevel)

    self.mFightValueLowerNum = UIExtend.getCCLabelTTFFromCCB(self.ccbfile,'mFightValueLowerNum')
    self.mFightValueLowerNum:setString(self.info.needPower)

    self.mLangConitionLowerNum = UIExtend.getCCLabelTTFFromCCB(self.ccbfile,'mLangConitionLowerNum')
    self.mLangConitionLowerNum:setString(RAAllianceUtility:getLanguageIdByName(self.info.needLanguage ))

    self:refreshBtn()
end

function RAAllianceDetailPage:refreshBtn()
    if RAAllianceManager.selfAlliance == nil then 
        self.mApplicationBtnNode:setVisible(true)

        if self.info.isApply == true then 
            UIExtend.setControlButtonTitle(self.ccbfile, "mApplicationBtn","@CancelApply")
        else 
            local isCan = self.info.openRecurit

            --判断大本等级
            if RABuildManager:getMainCityLvl()<self.info.needBuildingLevel then 
                isCan = false
            elseif RAPlayerInfoManager.getPlayerLevel() < self.info.needCommonderLevel then 
                isCan = false
            elseif RAPlayerInfoManager.getPlayerFightPower() < self.info.needPower then 
                isCan = false
            elseif self.info.needLanguage ~= 'all' then 
                local lang_type =  CCApplication:sharedApplication():getCurrentLanguage()
                local curLanguageInfo = i18nconfig_conf[lang_type]
                if curLanguageInfo ~= self.info.needLanguage then 
                    isCan = false 
                end 
            end 
            
            if isCan == false then 
                UIExtend.setControlButtonTitle(self.ccbfile, "mApplicationBtn","@Apply")
            end
        end 
    else
        self.mApplicationBtnNode:setVisible(false)
    end 
end

function RAAllianceDetailPage:onLeaveMsgBtn()
	-- CCLuaLog('联盟留言')
    RARootManager.OpenPage("RAAllianceLeaveMsgPage",{allianceId = self.info.id})
end

function RAAllianceDetailPage:onAllianceMemBtn()
	-- CCLuaLog('联盟成员')
    RAAllianceDetailPage.isRequest = true
    RAAllianceProtoManager:getGuildMemeberInfoReq(self.info.id)
end

function RAAllianceDetailPage:onContactOfficerBtn()
	-- CCLuaLog('联系外交官')
	RARootManager.OpenPage("RAMailWritePage",{sendName = self.info.leaderName})
    -- RARootManager.ShowMsgBox('@NoOpenTips')
end

function RAAllianceDetailPage:onContactLeaderBtn()
	-- CCLuaLog('联系盟主')
	RARootManager.OpenPage("RAMailWritePage",{sendName = self.info.leaderName})
    -- RARootManager.ShowMsgBox('@NoOpenTips')
end

function RAAllianceDetailPage:onApplicationBtn()
	-- CCLuaLog('申请联盟')

    if self.info.isApply == true then
       RAAllianceProtoManager:cancelApplyReq(self.info.id)
    else  
	   RAAllianceProtoManager:applyReq(self.info.id)
    end
end

function RAAllianceDetailPage:Exit()
    RAAllianceDetailPage.isRequest = nil
	self:removeMessageHandler()
    self:removeHandler()
	UIExtend.unLoadCCBFile(RAAllianceDetailPage)	
end

function RAAllianceDetailPage:mAllianceCommonCCB_onBack()
	RARootManager.ClosePage("RAAllianceDetailPage")
	-- RARootManager.ClosePage("RAMailMainPage")
end

return RAAllianceDetailPage