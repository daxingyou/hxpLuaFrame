-- RAWorldCollectionBackPage
-- 资源召回页面

RARequire("BasePage")
local UIExtend = RARequire("UIExtend")
local Utilitys = RARequire('Utilitys')
local RARootManager = RARequire("RARootManager")
local battle_soldier_conf = RARequire("battle_soldier_conf")
local RACoreDataManager = RARequire('RACoreDataManager')
local RAWorldConfigManager = RARequire('RAWorldConfigManager')
local RAWorldVar = RARequire('RAWorldVar')
local common = RARequire('common')

local RAWorldCollectionBackPage = BaseFunctionPage:new(...)


RAWorldCollectionBackPage.mResId = 0
RAWorldCollectionBackPage.mRemainResNum = 0
RAWorldCollectionBackPage.mMarchId = ''
RAWorldCollectionBackPage.mPlayerName = ''

RAWorldCollectionBackPage.mPos = nil
RAWorldCollectionBackPage.mName = ''
RAWorldCollectionBackPage.mIcon = ''

RAWorldCollectionBackPage.mStartTime = -1
RAWorldCollectionBackPage.mEndTime = -1

-- 当前自己可以采集的数目，min(剩余量, 负重量)
RAWorldCollectionBackPage.mMaxCollectNum = 0
RAWorldCollectionBackPage.mCurrSpeed = 0
RAWorldCollectionBackPage.mLoadBaseNum = 1

local OnReceiveMessage = nil


local OnReceiveMessage = function(message)     
    -- if message.messageID == MessageDef_World.MSG_ArmyFreeCountUpdate then
    --     --需要整个UI cell重新计算
    --     CCLuaLog("MessageDef_World MSG_ArmyFreeCountUpdate")
    --     RAWorldCollectionBackPage:RefreshUIWhenSelectedChange()
    -- end

    -- if message.messageID == MessageDef_World.MSG_ArmyChangeSelectedCount then
    --     --需要刷新cell数据和UI
    --     CCLuaLog("MessageDef_World MSG_ArmyChangeSelectedCount")
    --     RAWorldCollectionBackPage:RefreshUIWhenSelectedChange(message.actionType, message.armyId, message.selectCount)
    -- end

    if message.messageID == MessageDef_Packet.MSG_Operation_Fail then        
        local opcode = message.opcode
        if opcode == HP_pb.WORLD_SERVER_CALLBACK_C then
            RARootManager.RemoveWaitingPage()
        end
    end
end

function RAWorldCollectionBackPage:registerMessageHandlers()
    -- MessageManager.registerMessageHandler(MessageDef_World.MSG_ArmyFreeCountUpdate, OnReceiveMessage)
    -- MessageManager.registerMessageHandler(MessageDef_World.MSG_ArmyChangeSelectedCount, OnReceiveMessage)

    MessageManager.registerMessageHandler(MessageDef_Packet.MSG_Operation_Fail, OnReceiveMessage)
end

function RAWorldCollectionBackPage:unregisterMessageHandlers()
    -- MessageManager.removeMessageHandler(MessageDef_World.MSG_ArmyFreeCountUpdate, OnReceiveMessage)
    -- MessageManager.removeMessageHandler(MessageDef_World.MSG_ArmyChangeSelectedCount, OnReceiveMessage)

    MessageManager.removeMessageHandler(MessageDef_Packet.MSG_Operation_Fail, OnReceiveMessage)
end


function RAWorldCollectionBackPage:resetData()
    self.mResId = 0
    self.mRemainResNum = 0
    self.mMarchId = ''
    self.mPlayerName = ''
    self.mPos = nil
    self.mName = ''
    self.mIcon = ''

    self.mStartTime = -1
    self.mEndTime = -1
    self.mLastTime = -1

    self.mMaxCollectNum = 0
    self.mCurrSpeed = 0
    self.mLoadBaseNum = 1
end

function RAWorldCollectionBackPage:Enter(data)
    CCLuaLog("RAWorldCollectionBackPage:Enter")    

    self:resetData()
    local ccbfile = UIExtend.loadCCBFile("ccbi/RAWorldCollectionBackPopUp.ccbi",RAWorldCollectionBackPage)    

    if data ~= nil then
        self.mResId = data.resId or 0
        self.mRelation = data.relation or World_pb.NONE
        self.mRemainResNum = data.remainResNum or 0
        self.mPos = RACcp(data.posX, data.posY)
        self.mMarchId = data.marchId or ''
        self.mPlayerName = data.playerName
        self.mIsManorCollect = data.isManorCollect or false
        self.mGuildMineType = data.guildMineType or 0
    end
    self:RegisterPacketHandler(HP_pb.WORLD_SERVER_CALLBACK_S)
    self:registerMessageHandlers()

    self:refreshCommonUI()
end

function RAWorldCollectionBackPage:Execute()
    if self.mStartTime ~= -1 and self.mEndTime ~= -1 then
        local lastTime = os.difftime(self.mEndTime, common:getCurTime())
        if self.mLastTime > lastTime then
            self:refreshTimeShow(lastTime)
        end
    end
end

-- 刷新倒计时和已采集
function RAWorldCollectionBackPage:refreshTimeShow(lastTime)
    if lastTime <= 0 then
        self.mLastTime = 0
        -- 没时间的时候，直接关闭UI
        RARootManager.ClosePage('RAWorldCollectionBackPage')
        return
    end
    local ccbfile = self:getRootNode()
    if ccbfile == nil then return end  
    -- res collected
    -- past Time * speed
    local curTime = common:getCurTime()
    local pastTime = os.difftime(curTime, self.mStartTime)
    local collectedNum = math.floor(self.mCurrSpeed * pastTime)
    UIExtend.setCCLabelString(ccbfile, "mCollectedResNum", tostring(collectedNum))

    -- @AlertHint             注 意！
    -- @RetreatHint         确定要将采集中的部队撤回吗？
    -- @CollectedRes       已采集资源：
    UIExtend.setCCLabelString(ccbfile, "mPopUpTitle", _RALang('@AlertHint'))    
    UIExtend.setCCLabelString(ccbfile, "mPopUpLabel1", _RALang('@RetreatHint'))    

    self.mLastTime = lastTime
end

-- 只在enter的时候需要刷新
function RAWorldCollectionBackPage:refreshCommonUI()
    local ccbfile = self:getRootNode()
    if ccbfile == nil then return end    

    local resName = ''
    local resLv = -1
    local resIcon = ''
    local resType = 0
    if not self.mIsManorCollect then
        local resCfg, resShowCfg = RAWorldConfigManager:GetResConfig(self.mResId)
        resName = resCfg.resName
        resLv = resCfg.level
        resType = resCfg.resType        
        resIcon = resShowCfg.resTargetIcon
    else
        local super_mine_conf = RARequire('super_mine_conf')
        local mineCfg = super_mine_conf[self.mGuildMineType]
        resName = mineCfg.name
        resIcon = mineCfg.icon
        resType = self.mGuildMineType
    end

    -- res icon
    local RAResManager = RARequire('RAResManager')
    local Const_pb = RARequire('Const_pb')
    local resIcon = RAResManager:getIconByTypeAndId(Const_pb.PLAYER_ATTR * 10000, resType)
    UIExtend.addSpriteToNodeParent(ccbfile, "mResIconNode", resIcon)

    -- speed 
    local RAMarchDataManager = RARequire('RAMarchDataManager')
    local speed, _, _ = RAMarchDataManager:GetResourceCollectSpeed(resType)
    --速度单位是小时
    self.mCurrSpeed = speed or 0
    -- speed = speed * 3600 or 0
    self.mLoadBaseNum = RAWorldConfigManager:GetResBaseLoadNum(resType)
    self:refreshTimeData()
end

function RAWorldCollectionBackPage:refreshTimeData()
    -- time init
    -- 设置队列时间            
    local RAMarchDataManager = RARequire('RAMarchDataManager')
    local marchData = RAMarchDataManager:GetMarchDataById(self.mMarchId)
    if marchData ~= nil then
        self.mStartTime = marchData:GetResCalcStartTime() / 1000
        self.mEndTime = marchData.resEndTime / 1000
        local lastTime = os.difftime(self.mEndTime, common:getCurTime())
        self:refreshTimeShow(lastTime)
    else
        self.mStartTime = -1
        self.mEndTime = -1
        self.mLastTime = -1
    end
end

function RAWorldCollectionBackPage:onReceivePacket(handler)
    local pbCode = handler:getOpcode()
    local buffer = handler:getBuffer()
    if pbCode == HP_pb.WORLD_SERVER_CALLBACK_S then        
        RARootManager.RemoveWaitingPage()
        --添加召回采集资源的音效
        local resCfg, resShowCfg = RAWorldConfigManager:GetResConfig(self.mResId)
        local RAMarchConfig = RARequire("RAMarchConfig")
        if resCfg ~= nil and RAMarchConfig.MarchCollectResVideos[resCfg.resType] ~= nil then
            local videoName = RAMarchConfig.MarchCollectResVideos[resCfg.resType].out
            local common = RARequire("common")
            common:playEffect(videoName)
        end        
        self:onClose()
    end
end

function RAWorldCollectionBackPage:CommonRefresh(data)
    CCLuaLog("RAWorldCollectionBackPage:CommonRefresh")        

    -- 使用道具增加出征上限后刷新
    -- self:refreshSelectEffectUI() 
end


function RAWorldCollectionBackPage:onClose()
    CCLuaLog("RAWorldCollectionBackPage:onClose") 
    RARootManager.ClosePage('RAWorldCollectionBackPage')
end


function RAWorldCollectionBackPage:onConfirmBtn()
    local RAWorldPushHandler = RARequire('RAWorldPushHandler')
    local errorStr = 'RAWorldCollectionBackPage:onConfirmBtn waiting page close Error'
    RARootManager.ShowWaitingPage(false, 10, errorStr)
    RAWorldPushHandler:sendServerCalcCallBackReq(self.mMarchId)
end

function RAWorldCollectionBackPage:OnAnimationDone(ccbfile)
    local lastAnimationName = ccbfile:getCompletedAnimationName()   
end


function RAWorldCollectionBackPage:Exit()
    --you can release lua data here,but can't release node element
    CCLuaLog("RAWorldCollectionBackPage:Exit")    
    self:RemovePacketHandlers()
    self:unregisterMessageHandlers()
    self:resetData()
    UIExtend.unLoadCCBFile(self)    
end