-- RAAllianceGatherPage
-- 士兵集结开始页面

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
local World_pb=RARequire("World_pb")

local RAAllianceGatherPage = BaseFunctionPage:new(...)


RAAllianceGatherPage.mPos = nil
RAAllianceGatherPage.mName = ''
RAAllianceGatherPage.mIcon = ''
RAAllianceGatherPage.mGatherTime = 1
RAAllianceGatherPage.mIndex2Time = {}
RAAllianceGatherPage.mMarchType = World_pb.MASS
-- 0为普通打怪，1为全力攻击打怪 
RAAllianceGatherPage.mAtkMonsterMode = 0

local OnReceiveMessage = nil

local OnReceiveMessage = function(message)     
    -- if message.messageID == MessageDef_World.MSG_ArmyFreeCountUpdate then
    --     --需要整个UI cell重新计算
    --     CCLuaLog("MessageDef_World MSG_ArmyFreeCountUpdate")
    --     RAAllianceGatherPage:RefreshUIWhenSelectedChange()
    -- end

    -- if message.messageID == MessageDef_World.MSG_ArmyChangeSelectedCount then
    --     --需要刷新cell数据和UI
    --     CCLuaLog("MessageDef_World MSG_ArmyChangeSelectedCount")
    --     RAAllianceGatherPage:RefreshUIWhenSelectedChange(message.actionType, message.armyId, message.selectCount)
    -- end

    if message.messageID == MessageDef_Packet.MSG_Operation_Fail then        
        local opcode = message.opcode
        if opcode == HP_pb.WORLD_FIGHTMONSTER_C then
            RARootManager.RemoveWaitingPage()
        end
    end
end

function RAAllianceGatherPage:registerMessageHandlers()
    -- MessageManager.registerMessageHandler(MessageDef_World.MSG_ArmyFreeCountUpdate, OnReceiveMessage)
    -- MessageManager.registerMessageHandler(MessageDef_World.MSG_ArmyChangeSelectedCount, OnReceiveMessage)

    MessageManager.registerMessageHandler(MessageDef_Packet.MSG_Operation_Fail, OnReceiveMessage)
end

function RAAllianceGatherPage:unregisterMessageHandlers()
    -- MessageManager.removeMessageHandler(MessageDef_World.MSG_ArmyFreeCountUpdate, OnReceiveMessage)
    -- MessageManager.removeMessageHandler(MessageDef_World.MSG_ArmyChangeSelectedCount, OnReceiveMessage)

    MessageManager.removeMessageHandler(MessageDef_Packet.MSG_Operation_Fail, OnReceiveMessage)
end


function RAAllianceGatherPage:resetData()

    self.mPos = nil
    self.mName = ''
    self.mIcon = ''
    self.mGatherTime = 1
    self.mIndex2Time = {}
    self.mAtkMonsterMode = 0
end

function RAAllianceGatherPage:Enter(data)
    CCLuaLog("RAAllianceGatherPage:Enter")    

    self:resetData()
    local ccbfile = UIExtend.loadCCBFile("ccbi/RAAllianceGatherPopUp.ccbi",RAAllianceGatherPage)    

    if data ~= nil then
        self.mPos = RACcp(data.posX, data.posY)        
        self.mName = data.name
        self.mIcon = data.icon
        self.mMarchType = data.marchType or World_pb.MASS
        self.mAtkMonsterMode = data.times
    end

    local timesCfg = RARequire('world_march_const_conf').worldGatherTime.value
    local timesTb = RAStringUtil:split(timesCfg, '_')
    for i=1,#timesTb do
        local atkTimes = timesTb[i]
        self.mIndex2Time[i] = atkTimes
    end

    self:registerMessageHandlers()

    self:refreshCommonUI()
end


-- @AllianceGatherDesContent = 集结说明文字
-- @GatherBtnName = {0}分钟

-- 只在enter的时候需要刷新
function RAAllianceGatherPage:refreshCommonUI()
    local ccbfile = self:getRootNode()
    if ccbfile == nil then return end

    -- Des
    UIExtend.setCCLabelString(ccbfile, "mPopUpLabel1", _RALang('@AllianceGatherDesContent'))    

    -- btns    
    -- jira BLBL-4701 策划说大于60分钟的时候，显示为小时，同时保证只填60的倍数
    for i=1,#self.mIndex2Time do
        local time = self.mIndex2Time[i]
        local minStr = math.ceil(time / 60)
        local btnName = 'mGatherTimeBtn'..i
        local nameStr = ''
        if minStr > 60 then
            local hour = math.ceil(minStr / 60)
            nameStr = _RALang('@HourWithParam', hour)
        else
            nameStr = _RALang('@MinuteWithParam', minStr)
        end
        UIExtend.setControlButtonTitle(ccbfile, btnName, nameStr, true)
    end  
end

function RAAllianceGatherPage:_openTroopChargePage(index)
    local ccbfile = self:getRootNode()
    if ccbfile == nil then return end
    if index < 0 or index > 4 then return end   
    self.mSelectIndex = index
    self.mGatherTime = tonumber(self.mIndex2Time[index])

    local coord = Utilitys.ccpCopy(self.mPos)
    RARootManager.ClosePage('RAAllianceGatherPage')
    RARootManager.OpenPage('RATroopChargePage',  {
        coord = coord, 
        name = self.mName,
        icon = self.mIcon,        
        marchType = self.mMarchType,
        gatherTime = self.mGatherTime,
        times = self.mAtkMonsterMode,
    })
end


function RAAllianceGatherPage:CommonRefresh(data)
    CCLuaLog("RAAllianceGatherPage:CommonRefresh")
    self:refreshCommonUI()
end


function RAAllianceGatherPage:onClose()
    CCLuaLog("RAAllianceGatherPage:onClose") 
    RARootManager.ClosePage('RAAllianceGatherPage')
end


function RAAllianceGatherPage:onGatherTimeBtn1()
    self:_openTroopChargePage(1)
end

function RAAllianceGatherPage:onGatherTimeBtn2()
    self:_openTroopChargePage(2)
end

function RAAllianceGatherPage:onGatherTimeBtn3()
    self:_openTroopChargePage(3)
end

function RAAllianceGatherPage:onGatherTimeBtn4()
    self:_openTroopChargePage(4)
end

function RAAllianceGatherPage:OnAnimationDone(ccbfile)
    local lastAnimationName = ccbfile:getCompletedAnimationName()   
end


function RAAllianceGatherPage:Exit()
    --you can release lua data here,but can't release node element
    CCLuaLog("RAAllianceGatherPage:Exit")    
    self:unregisterMessageHandlers()
    self:resetData()
    UIExtend.unLoadCCBFile(self)    
end