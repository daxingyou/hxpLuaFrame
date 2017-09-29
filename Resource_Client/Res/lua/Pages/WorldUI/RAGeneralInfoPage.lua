RARequire('BasePage')
local RAGeneralInfoPage = BaseFunctionPage:new(...)
RARequire('MessageManager')
RAGeneralInfoPage.playerId = nil
RAGeneralInfoPage.protoHandler = nil
RAGeneralInfoPage.playerInfo = nil

local UIExtend = RARequire('UIExtend')
local RAPlayerInfoManager = RARequire('RAPlayerInfoManager')
local RAGameConfig = RARequire('RAGameConfig')
local RANetUtil = RARequire('RANetUtil')
local RAStringUtil = RARequire('RAStringUtil')
local RARootManager = RARequire('RARootManager')
local Equipment_pb = RARequire("Equipment_pb")
local RAEquipInfo = RARequire("RAEquipInfo")
local RAEquipManager = RARequire("RAEquipManager")
local RALogicUtil = RARequire("RALogicUtil")

function RAGeneralInfoPage:Enter(data)
    self.playerId = data.playerId
    
    self:_addHandler()
    self:registerMessage()
    self:_getGeneralInfo()
    --发送装备请求
    self:_getGeneralEquipInfo()
    --获取装备信息
    self:RegisterPacketHandler(HP_pb.PLAYER_EQUIPMENT_S)

    UIExtend.loadCCBFile('RALordOtherPage.ccbi', self)
    self:_initPage()
end

function RAGeneralInfoPage:Exit()
    self:_removeHander()
    self:removeMessageHandler()
    self:RemovePacketHandlers()
    UIExtend.unLoadCCBFile(self)
    self.playerInfo = nil
    self.commanderInfo = nil
    self.generalEquips = nil
end

local OnReceiveMessage = function(message)
    if message.messageID == MessageDef_Packet.MSG_Operation_OK then
        if message.opcode == HP_pb.GUILDMANAGER_INVITE_C then 
            RARootManager.ShowMsgBox("@InvitationSuccess")
        end 
    end 
end

function RAGeneralInfoPage:registerMessage()
    MessageManager.registerMessageHandler(MessageDef_Packet.MSG_Operation_OK,OnReceiveMessage)
end

function RAGeneralInfoPage:removeMessageHandler()
    MessageManager.removeMessageHandler(MessageDef_Packet.MSG_Operation_OK,OnReceiveMessage)
end

function RAGeneralInfoPage:onReceivePacket(handler)
    RARootManager.RemoveWaitingPage()
    local pbCode = handler:getOpcode()
    local buffer = handler:getBuffer()
    if pbCode == HP_pb.PLAYER_DETAIL_OTHER_S then
        local msg = Player_pb.OtherPlayerDetailResp()
        msg:ParseFromString(buffer)
        if msg ~= nil then
            self.playerInfo = msg.snapshot

            --指挥官状态信息
            self.commanderInfo= {
                name  = msg.name,
                level = msg.level,
                state = msg.state,
                posX  = msg.posX,
                posY  = msg.posY
            }

            self:_refreshUI()
        else
            CCLuaLog('The packet OtherPlayerDetailResp parse Failed')
        end
    elseif pbCode == HP_pb.PLAYER_EQUIPMENT_S then  --他人装备信息
        local msg = Equipment_pb.HPPlayerEquipInfoResp()
        msg:ParseFromString(buffer)
        self.generalEquips = {}
        for i = 1,#msg.equipments do
            local equip = msg.equipments[i]
            local equipInfo = RAEquipInfo.new()
	        equipInfo:initByPb(equip)
		    self.generalEquips[equipInfo.uuid] = equipInfo
        end
        self:_showEquip()
    end
end

function RAGeneralInfoPage:_addHandler()
    self.protoHandler = RANetUtil:addListener(HP_pb.PLAYER_DETAIL_OTHER_S, self)
end

function RAGeneralInfoPage:_removeHander()
    if self.protoHandler then
        RANetUtil:removeListener(self.protoHandler)
        self.protoHandler = nil
    end
end

function RAGeneralInfoPage:_getGeneralInfo()
    local msg = Player_pb.PlayerDetailReq()
    msg.playerId = self.playerId
    RANetUtil:sendPacket(HP_pb.PLAYER_DETAIL_OTHER_C, msg)
    
    RARootManager.ShowWaitingPage(true)
end

--发送协议
function RAGeneralInfoPage:_getGeneralEquipInfo()
    local msg = Equipment_pb.HPPlayerEquipInfoReq()
    msg.playerId = self.playerId
    RANetUtil:sendPacket(HP_pb.PLAYER_EQUIPMENT_C, msg)
end

function RAGeneralInfoPage:_initPage()
    UIExtend.setNodeVisible(self.ccbfile, 'mUserBustPic', false)

    UIExtend.setMenuItemEnable(self.ccbfile,'mAddfriendsBtn',false)
end

function RAGeneralInfoPage:_refreshUI()
    local playerInfo = self.playerInfo

    -- 等级
    local lvStr = 'Lv.' .. (playerInfo.level or 1)
    UIExtend.setCCLabelString(self.ccbfile, 'mGeneralLevel', lvStr)
    
    -- 半身像
    local portrait = RAPlayerInfoManager.getPlayerBust(playerInfo.icon)
    UIExtend.setSpriteIcoToNode(self.ccbfile, 'mUserBustPic', portrait)
    UIExtend.setNodeVisible(self.ccbfile, 'mUserBustPic', true)

    -- 名字
    local Utilitys = RARequire('Utilitys')
    local name = Utilitys.getDisplayName(playerInfo.name, playerInfo.guildTag)
    UIExtend.setCCLabelString(self.ccbfile, 'mPlayerName', name)

    -- 战力
    UIExtend.setCCLabelString(self.ccbfile, 'mGeneralPower', playerInfo.power)
    
    -- 装备
    -- self:_showEquip()

    -- 联盟按钮
    local hasGuild = playerInfo.guildId and playerInfo.guildId ~= ''
    local title = hasGuild and '@Alliance' or '@invite_to_join_alliance'
    UIExtend.setControlButtonTitle(self.ccbfile, 'mAllianceBtn', title)

    --刷新指挥官状态
    self:_refreshCommandState()

end
--------------------------------------------------------------------------------------
function RAGeneralInfoPage:_setEquipBtnsEnable(isEnable)
    for i=1,8 do
        local equipCCB=UIExtend.getCCBFileFromCCB(self.ccbfile,"mEquipCell"..i)
       UIExtend.setMenuItemEnable(equipCCB,"mEquipBtn",isEnable)
    end
end

function RAGeneralInfoPage:_refreshCommandState()
    local state=self.commanderInfo.state

    --0：正常 1:被抓 2:释放返回中 3:处决 4:死亡
    UIExtend.setNodeVisible(self.ccbfile,"mCageNode",false)
    UIExtend.setNodeVisible(self.ccbfile,"mCapturedNode",false)
    UIExtend.setNodeVisible(self.ccbfile,"mExecuteNode",false)
    
    self:_setEquipBtnsEnable(true)
    if state==1 or state==2 or state==3 then

        --被抓
        UIExtend.setNodeVisible(self.ccbfile,"mCageNode",true)
        UIExtend.setNodeVisible(self.ccbfile,"mCapturedNode",true)
        self:_setEquipBtnsEnable(false)

        if state==2  or state==3 then
            UIExtend.setNodeVisible(self.ccbfile,"mCapturedNode",false)
        else
            local name=self.commanderInfo.name
            local level=self.commanderInfo.level
            local posX=self.commanderInfo.posX
            self.enemyPosX=posX
            local posY=self.commanderInfo.posY
            self.enemyPosY=posY
            UIExtend.setCCLabelString(self.ccbfile,"mPrisonName",name)
            UIExtend.setCCLabelString(self.ccbfile,"mPrisonLevel",_RALang("@ResCollectTargetLevel",level))
            UIExtend.setCCLabelString(self.ccbfile,"mPrisonPos",_RALang("@WorldCoordPos",posX,posY))
        end 

    elseif state==4 then
        UIExtend.setNodeVisible(self.ccbfile,"mCageNode",true)
        UIExtend.setNodeVisible(self.ccbfile,"mCapturedNode",false)
        UIExtend.setNodeVisible(self.ccbfile,"mExecuteNode",true)
        self:_setEquipBtnsEnable(false)

    end 
end

function RAGeneralInfoPage:onCheckPosBtn()
   if self.enemyPosX and self.enemyPosY then
        RARootManager.CloseAllPages()
        local RAWorldManager=RARequire("RAWorldManager")
        RAWorldManager:LocateAtPos(self.enemyPosX,self.enemyPosY)
    end 
end

function RAGeneralInfoPage:_showEquip()
    --
    for k,equip in pairs(self.generalEquips) do
        local equipInfo = RAEquipManager:getConfEquipInfoById(equip.equipId)
        local level = equip.level
        --装备icon
        UIExtend.addSpriteToNodeParent(self.ccbfile:getCCBFileFromCCB("mEquipCell"..equipInfo.part), "mIconNode",equipInfo.icon)
        --装备等级
        UIExtend.setCCLabelString(self.ccbfile:getCCBFileFromCCB("mEquipCell"..equipInfo.part),'mEquipLevel',"LV."..equip.level)
        --他人信息不需要显示升级标志
        UIExtend.setNodesVisible(self.ccbfile:getCCBFileFromCCB("mEquipCell"..equipInfo.part),{mCanUpgradePic = false})
        --装备品质
        local qualityFarme = RALogicUtil:getItemBgByColor(equipInfo.quality)
        UIExtend.addSpriteToNodeParent(self.ccbfile:getCCBFileFromCCB("mEquipCell"..equipInfo.part), "mQualityNode",qualityFarme)
    end
end

function RAGeneralInfoPage:onBackBtn()
    RARootManager.CloseCurrPage()
end

-- 发私信
function RAGeneralInfoPage:onMailBtn()
    if self.playerInfo == nil then return end
    RARootManager.OpenPage('RAMailWritePage', {sendName = self.playerInfo.name})
end

-- 将军详情
function RAGeneralInfoPage:onDetailsBtn()
    if self.playerInfo == nil then return end
    RARootManager.OpenPage('RAGeneralDetailPage', {playerInfo = self.playerInfo}, false, true)
end

-- 联盟信息/邀请入盟
function RAGeneralInfoPage:onAllianceBtn()
    if self.playerInfo == nil then return end

    local playerInfo = self.playerInfo
    local hasGuild = playerInfo.guildId and playerInfo.guildId ~= ''
    local RAAllianceManager = RARequire('RAAllianceManager')
    if hasGuild then
        if RAAllianceManager.selfAlliance~=nil and RAAllianceManager.selfAlliance.id == playerInfo.guildId then 
            RARootManager.OpenPage('RAAllianceMainPage')
        else
            RARootManager.OpenPage('RAAllianceDetailPage', {isNeedRequest = true, id = playerInfo.guildId, type = 1})
        end 
    else
        if RAAllianceManager:IsInGuild() then
            local RAAllianceProtoManager = RARequire('RAAllianceProtoManager')
            RAAllianceProtoManager:sendInviteGuildReq(self.playerId)
        else
            RARootManager.ShowMsgBox('@NoAllianceLabel')
        end
    end
end

-- 发送邮件
function RAGeneralInfoPage:onTalentBtn()
    --RARootManager.ShowMsgBox('@NoOpenTips')
    if self.playerInfo == nil then return end
    RARootManager.OpenPage('RAMailWritePage', {sendName = self.playerInfo.name})
end