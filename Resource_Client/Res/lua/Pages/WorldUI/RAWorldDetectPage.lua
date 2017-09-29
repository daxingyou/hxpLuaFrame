-- RAWorldDetectPage
-- 侦查页面

RARequire("BasePage")
local UIExtend = RARequire("UIExtend")
local Utilitys = RARequire('Utilitys')
local RARootManager = RARequire("RARootManager")
local battle_soldier_conf = RARequire("battle_soldier_conf")
local RACoreDataManager = RARequire('RACoreDataManager')
local RAWorldConfigManager = RARequire('RAWorldConfigManager')
local RAWorldVar = RARequire('RAWorldVar')
local common = RARequire('common')
local RAMarchConfig = RARequire('RAMarchConfig')

local RAWorldDetectPage = BaseFunctionPage:new(...)


RAWorldDetectPage.mPlayerName = ''

RAWorldDetectPage.mPos = nil
RAWorldDetectPage.mIcon = ''

local OnReceiveMessage = nil


local OnReceiveMessage = function(message)     
    -- if message.messageID == MessageDef_World.MSG_ArmyFreeCountUpdate then
    --     --需要整个UI cell重新计算
    --     CCLuaLog("MessageDef_World MSG_ArmyFreeCountUpdate")
    --     RAWorldDetectPage:RefreshUIWhenSelectedChange()
    -- end

    -- if message.messageID == MessageDef_World.MSG_ArmyChangeSelectedCount then
    --     --需要刷新cell数据和UI
    --     CCLuaLog("MessageDef_World MSG_ArmyChangeSelectedCount")
    --     RAWorldDetectPage:RefreshUIWhenSelectedChange(message.actionType, message.armyId, message.selectCount)
    -- end

    if message.messageID == MessageDef_Packet.MSG_Operation_Fail then        
        local opcode = message.opcode          
        for k,v in pairs(RAMarchConfig.MarchType2HpCode) do
            local c2s = v.c2s
            if opcode == c2s then
                RARootManager.RemoveWaitingPage()
                break    
            end
        end
    end
end

function RAWorldDetectPage:registerMessageHandlers()
    -- MessageManager.registerMessageHandler(MessageDef_World.MSG_ArmyFreeCountUpdate, OnReceiveMessage)
    -- MessageManager.registerMessageHandler(MessageDef_World.MSG_ArmyChangeSelectedCount, OnReceiveMessage)

    MessageManager.registerMessageHandler(MessageDef_Packet.MSG_Operation_Fail, OnReceiveMessage)
end

function RAWorldDetectPage:unregisterMessageHandlers()
    -- MessageManager.removeMessageHandler(MessageDef_World.MSG_ArmyFreeCountUpdate, OnReceiveMessage)
    -- MessageManager.removeMessageHandler(MessageDef_World.MSG_ArmyChangeSelectedCount, OnReceiveMessage)

    MessageManager.removeMessageHandler(MessageDef_Packet.MSG_Operation_Fail, OnReceiveMessage)
end


function RAWorldDetectPage:resetData()
    self.mPlayerName = ''
    self.mPos = nil
    self.mIcon = ''
end

function RAWorldDetectPage:Enter(data)
    CCLuaLog("RAWorldDetectPage:Enter")    

    self:resetData()
    local ccbfile = UIExtend.loadCCBFile("ccbi/RAWorldDetectPopUp.ccbi",RAWorldDetectPage)    

    if data ~= nil then
        self.mPos = RACcp(data.posX, data.posY)
        self.mPlayerName = data.playerName or ''
        self.mIcon = data.icon or ''
    end
    self:registerMessageHandlers()

    for k,v in pairs(RAMarchConfig.MarchType2HpCode) do
        local s2c = v.s2c
        self:RegisterPacketHandler(s2c)
    end
    self:refreshCommonUI()
end

function RAWorldDetectPage:onReceivePacket(handler)
    local opcode = handler:getOpcode()
    local buffer = handler:getBuffer()    
    for k,v in pairs(RAMarchConfig.MarchType2HpCode) do
        local s2c = v.s2c
        if opcode == s2c then
            local msg = World_pb.WorldMarchResp()
            msg:ParseFromString(buffer)
             local success = msg.success
            local RARootManager = RARequire('RARootManager')
            if success then
                RARootManager:CloseAllPages()
            end
            RARootManager.RemoveWaitingPage()
        end
    end

end

-- 只在enter的时候需要刷新
function RAWorldDetectPage:refreshCommonUI()
    local ccbfile = self:getRootNode()
    if ccbfile == nil then return end    
    UIExtend.setCCLabelString(ccbfile, "mLordName", self.mPlayerName)    

    UIExtend.setCCLabelString(ccbfile, "mCollectionPosLabel", _RALang('@WorldCoordPos', self.mPos.x, self.mPos.y))    
    UIExtend.addSpriteToNodeParent(ccbfile, "mTargetIconNode", self.mIcon)


    -- 自己点数据刷新
    local selfCoord = RAWorldVar.MapPos.Self
    -- 侦查消耗时间计算
    local startPos = Utilitys.ccpCopy(selfCoord)
    local endPos = Utilitys.ccpCopy(self.mPos)    
    local RAMarchDataManager = RARequire('RAMarchDataManager')
    local timeNeed = RAMarchDataManager:GetMarchWayTotalTimeForDetect(startPos, endPos, true)
    local timeNeedStr = Utilitys.createTimeWithFormat(timeNeed)    
    UIExtend.setCCLabelString(ccbfile, "mDetectTimeNum", timeNeedStr)   

    -- 侦查消耗计算
    local world_march_const_conf = RARequire("world_march_const_conf")
    local RAResManager = RARequire("RAResManager")    
    local resStr = world_march_const_conf.investigationMarchCost.value
    local oneResInfo = RAResManager:getOneResInfoByStr(resStr)

    local resIcon, resName = RAResManager:getIconByTypeAndId(oneResInfo.itemType, oneResInfo.itemId)
    local spendStr = _RALang(resName).. oneResInfo.itemCount
    UIExtend.setCCLabelString(ccbfile, "mDetectSpendNum", spendStr)   
end


function RAWorldDetectPage:CommonRefresh(data)
    CCLuaLog("RAWorldDetectPage:CommonRefresh")        

    -- 使用道具增加出征上限后刷新
    -- self:refreshSelectEffectUI() 
end


function RAWorldDetectPage:onClose()
    CCLuaLog("RAWorldDetectPage:onClose") 
    RARootManager.ClosePage('RAWorldDetectPage')
end


function RAWorldDetectPage:onDetectBtn()
    RARootManager.ShowWaitingPage()
    local RAWorldPushHandler = RARequire('RAWorldPushHandler')
    local World_pb = RARequire('World_pb')
    RAWorldPushHandler:sendWorldMarchReq(World_pb.SPY, self.mPos, {})
end

function RAWorldDetectPage:OnAnimationDone(ccbfile)
    local lastAnimationName = ccbfile:getCompletedAnimationName()   
end


function RAWorldDetectPage:Exit()
    --you can release lua data here,but can't release node element
    CCLuaLog("RAWorldDetectPage:Exit")    
    self:RemovePacketHandlers()
    self:unregisterMessageHandlers()
    self:resetData()
    UIExtend.unLoadCCBFile(self)    
end