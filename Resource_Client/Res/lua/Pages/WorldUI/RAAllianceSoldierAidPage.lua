-- RAAllianceSoldierAidPage
-- 士兵援助初始页面

RARequire("BasePage")
local UIExtend = RARequire("UIExtend")
local Utilitys = RARequire('Utilitys')
local RARootManager = RARequire("RARootManager")
local battle_soldier_conf = RARequire("battle_soldier_conf")
local RACoreDataManager = RARequire('RACoreDataManager')
local RAWorldConfigManager = RARequire('RAWorldConfigManager')
local RAWorldVar = RARequire('RAWorldVar')
local common = RARequire('common')
local RAPlayerEffect = RARequire('RAPlayerEffect')
local RAStringUtil = RARequire('RAStringUtil')
local RAResManager = RARequire('RAResManager')
local HP_pb = RARequire('HP_pb')
local World_pb = RARequire('World_pb')
local GuildManager_pb = RARequire('GuildManager_pb')

local RAAllianceSoldierAidPage = BaseFunctionPage:new(...)


RAAllianceSoldierAidPage.mPos = nil
RAAllianceSoldierAidPage.mName = ''
RAAllianceSoldierAidPage.mIcon = ''
RAAllianceSoldierAidPage.mPlayerId = ''

local OnReceiveMessage = nil

local OnReceiveMessage = function(message)     
    -- if message.messageID == MessageDef_World.MSG_ArmyFreeCountUpdate then
    --     --需要整个UI cell重新计算
    --     CCLuaLog("MessageDef_World MSG_ArmyFreeCountUpdate")
    --     RAAllianceSoldierAidPage:RefreshUIWhenSelectedChange()
    -- end

    -- if message.messageID == MessageDef_World.MSG_ArmyChangeSelectedCount then
    --     --需要刷新cell数据和UI
    --     CCLuaLog("MessageDef_World MSG_ArmyChangeSelectedCount")
    --     RAAllianceSoldierAidPage:RefreshUIWhenSelectedChange(message.actionType, message.armyId, message.selectCount)
    -- end

    if message.messageID == MessageDef_Packet.MSG_Operation_Fail then        
        local opcode = message.opcode
        if opcode == HP_pb.GUILD_MEMBER_ASSISTENCE_INFO_C then
            RARootManager.RemoveWaitingPage()
        end
    end
end

function RAAllianceSoldierAidPage:registerMessageHandlers()
    -- MessageManager.registerMessageHandler(MessageDef_World.MSG_ArmyFreeCountUpdate, OnReceiveMessage)
    -- MessageManager.registerMessageHandler(MessageDef_World.MSG_ArmyChangeSelectedCount, OnReceiveMessage)

    MessageManager.registerMessageHandler(MessageDef_Packet.MSG_Operation_Fail, OnReceiveMessage)
end

function RAAllianceSoldierAidPage:unregisterMessageHandlers()
    -- MessageManager.removeMessageHandler(MessageDef_World.MSG_ArmyFreeCountUpdate, OnReceiveMessage)
    -- MessageManager.removeMessageHandler(MessageDef_World.MSG_ArmyChangeSelectedCount, OnReceiveMessage)

    MessageManager.removeMessageHandler(MessageDef_Packet.MSG_Operation_Fail, OnReceiveMessage)
end


function RAAllianceSoldierAidPage:resetData()

    self.mPos = nil
    self.mName = ''
    self.mIcon = ''
    self.mPlayerId = ''
end

-- 请求军队信息
function RAAllianceSoldierAidPage:sendPacketGetTargetInfo(playerId)
    local RANetUtil = RARequire('RANetUtil')
    local cmd = GuildManager_pb.GetGuildAssistenceInfoReq()
    cmd.playerId = tostring(playerId)
    RANetUtil:sendPacket(HP_pb.GUILD_MEMBER_ASSISTENCE_INFO_C,cmd,{retOpcode=-1})
end

function RAAllianceSoldierAidPage:Enter(data)
    CCLuaLog("RAAllianceSoldierAidPage:Enter")    

    self:resetData()
    local ccbfile = UIExtend.loadCCBFile("ccbi/RAAllianceSoldierAidPopUp.ccbi",RAAllianceSoldierAidPage)    

    if data ~= nil then
        self.mPos = RACcp(data.posX, data.posY)        
        self.mName = data.name
        self.mIcon = data.icon
        self.mPlayerId = data.playerId
    end

    self:refreshCommonUI(false)

    self:RegisterPacketHandler(HP_pb.GUILD_MEMBER_ASSISTENCE_INFO_S)
    self:sendPacketGetTargetInfo(self.mPlayerId)
    self:registerMessageHandlers()
end


-- @AllianceGatherDesContent = 集结说明文字
-- @GatherBtnName = {0}分钟

-- 只在enter的时候需要刷新
function RAAllianceSoldierAidPage:refreshCommonUI(isShowNum)
    local ccbfile = self:getRootNode()
    if ccbfile == nil then return end
    UIExtend.setControlButtonTitle(ccbfile, 'mGatherTimeBtn1', '@Cancel')
    UIExtend.setControlButtonTitle(ccbfile, 'mGatherTimeBtn2', '@DispatchArmy')
    self:refreshNum(0, 0)
end

function RAAllianceSoldierAidPage:refreshNum(currNum, totalNum)
    local ccbfile = self:getRootNode()
    if ccbfile == nil then return end
    local isVisual = true
    if totalNum == 0 then
        isVisual = false    
    end
    UIExtend.setNodesVisible(ccbfile,{
        mBar = isVisual,
        mSoldierAidNum = true
    })

    local str = _RALang('@PartedTwoParams', currNum, totalNum)
    UIExtend.setCCLabelString(ccbfile, "mSoldierAidNum", str)
    if totalNum > 0 then
        local percent = currNum / totalNum
        UIExtend.setCCScale9ScaleByPercent(ccbfile, 'mBar', 'mBarBG', percent)
    end

    UIExtend.setCCControlButtonEnable(ccbfile, 'mGatherTimeBtn2', totalNum > 0)
end


function RAAllianceSoldierAidPage:_openTroopChargePage()
    local ccbfile = self:getRootNode()
    if ccbfile == nil then return end
    local coord = Utilitys.ccpCopy(self.mPos)
    RARootManager.ClosePage('RAAllianceSoldierAidPage')
    RARootManager.OpenPage('RATroopChargePage',  {
        coord = coord, 
        name = self.mName,
        icon = self.mIcon,        
        marchType = World_pb.ASSISTANCE,
        playerId = self.mPlayerId
    })
end


function RAAllianceSoldierAidPage:onReceivePacket(handler)
    local pbCode = handler:getOpcode()
    local buffer = handler:getBuffer()
    if pbCode == HP_pb.GUILD_MEMBER_ASSISTENCE_INFO_S then
        local msg = GuildManager_pb.GetGuildAssistenceInfoResp()
        msg:ParseFromString(buffer)
        if msg then
            self:refreshNum(msg.curCnt, msg.maxCnt)      
        end
    end
end

function RAAllianceSoldierAidPage:CommonRefresh(data)
    CCLuaLog("RAAllianceSoldierAidPage:CommonRefresh")
    self:refreshCommonUI()
end


function RAAllianceSoldierAidPage:onClose()
    CCLuaLog("RAAllianceSoldierAidPage:onClose") 
    RARootManager.ClosePage('RAAllianceSoldierAidPage')
end


function RAAllianceSoldierAidPage:onGatherTimeBtn1()
    self:onClose()
end

function RAAllianceSoldierAidPage:onGatherTimeBtn2()
    self:_openTroopChargePage()
end

function RAAllianceSoldierAidPage:OnAnimationDone(ccbfile)
    local lastAnimationName = ccbfile:getCompletedAnimationName()   
end


function RAAllianceSoldierAidPage:Exit()
    --you can release lua data here,but can't release node element
    CCLuaLog("RAAllianceSoldierAidPage:Exit")    
    self:RemovePacketHandlers()
    self:unregisterMessageHandlers()
    self:resetData()
    UIExtend.unLoadCCBFile(self)    
end