-- RAWorldCollectionPage
-- 资源详情页面（无占领、敌方、友方）

RARequire("BasePage")
local UIExtend = RARequire("UIExtend")
local Utilitys = RARequire('Utilitys')
local RARootManager = RARequire("RARootManager")
local RAWorldConfigManager = RARequire('RAWorldConfigManager')
local RAWorldVar = RARequire('RAWorldVar')
local World_pb = RARequire('World_pb')

local RAWorldCollectionPage = BaseFunctionPage:new(...)

local OnReceiveMessage = nil


-- 资源id
RAWorldCollectionPage.mResId = 0
RAWorldCollectionPage.mRelation = World_pb.NONE
RAWorldCollectionPage.mRemainResNum = 0
RAWorldCollectionPage.mPlayerName = ''

RAWorldCollectionPage.mPos = nil
RAWorldCollectionPage.mName = ''
RAWorldCollectionPage.mIcon = ''

local OnReceiveMessage = function(message)     
    -- if message.messageID == MessageDef_World.MSG_ArmyFreeCountUpdate then
    --     --需要整个UI cell重新计算
    --     CCLuaLog("MessageDef_World MSG_ArmyFreeCountUpdate")
    --     RAWorldCollectionPage:RefreshUIWhenSelectedChange()
    -- end

    -- if message.messageID == MessageDef_World.MSG_ArmyChangeSelectedCount then
    --     --需要刷新cell数据和UI
    --     CCLuaLog("MessageDef_World MSG_ArmyChangeSelectedCount")
    --     RAWorldCollectionPage:RefreshUIWhenSelectedChange(message.actionType, message.armyId, message.selectCount)
    -- end

    -- if message.messageID == MessageDef_Packet.MSG_Operation_Fail then
    --     --todo
    --     local opcode = message.opcode
    --     if opcode == HP_pb.WORLD_COLLECTRESOURCE_C
    --         or opcode == HP_pb.WORLD_FIGHTMONSTER_C
    --         or opcode == HP_pb.WORLD_ATTACK_PLAYER_C
    --         or opcode == HP_pb.WORLD_QUARTERED_C
    --         or opcode == HP_pb.WORLD_SPY_C then
    --         RARootManager.RemoveWaitingPage()
    --     end
    -- end
end

function RAWorldCollectionPage:registerMessageHandlers()
    -- MessageManager.registerMessageHandler(MessageDef_World.MSG_ArmyFreeCountUpdate, OnReceiveMessage)
    -- MessageManager.registerMessageHandler(MessageDef_World.MSG_ArmyChangeSelectedCount, OnReceiveMessage)

    -- MessageManager.registerMessageHandler(MessageDef_Packet.MSG_Operation_Fail, OnReceiveMessage)
end

function RAWorldCollectionPage:unregisterMessageHandlers()
    -- MessageManager.removeMessageHandler(MessageDef_World.MSG_ArmyFreeCountUpdate, OnReceiveMessage)
    -- MessageManager.removeMessageHandler(MessageDef_World.MSG_ArmyChangeSelectedCount, OnReceiveMessage)

    -- MessageManager.removeMessageHandler(MessageDef_Packet.MSG_Operation_Fail, OnReceiveMessage)
end


function RAWorldCollectionPage:resetData()
    self.mResId = 0
    self.mRelation = World_pb.NONE
    self.mRemainResNum = 0
    self.mPlayerName = ''

    self.mPos = nil
    self.mName = ''
end

function RAWorldCollectionPage:EnterFrame()
    CCLuaLog("RAWorldCollectionPage:EnterFrame")    
end

function RAWorldCollectionPage:Enter(data)
    CCLuaLog("RAWorldCollectionPage:Enter")    

    self:resetData()
    local ccbfile = UIExtend.loadCCBFile("ccbi/RAWorldCollectionPopUp.ccbi",RAWorldCollectionPage)    
    

    if data ~= nil then
        self.mResId = data.resId or 0
        self.mRelation = data.relation or World_pb.NONE
        self.mRemainResNum = data.remainResNum or 0
        self.mPos = RACcp(data.posX, data.posY)
        self.mPlayerName = data.playerName or ''
    end
    
    self:registerMessageHandlers()

    self:refreshCommonUI()
end

-- 只在enter的时候需要刷新
function RAWorldCollectionPage:refreshCommonUI()
    local ccbfile = self:getRootNode()
    if ccbfile == nil then return end    
    if self.mResId == 0 then return end
    local resCfg, resShowCfg = RAWorldConfigManager:GetResConfig(self.mResId)

    --名字刷新
    local name = _RALang(resShowCfg.resName)
    name = name .. '  '.. _RALang('@ResCollectTargetLevel', resCfg.level)
    self.mName = name
    self.mIcon = resShowCfg.resTargetIcon
    UIExtend.setCCLabelString(ccbfile, "mCollectionName", name)    
    UIExtend.setCCLabelString(ccbfile, "mCollectionPosLabel", _RALang('@WorldCoordPos', self.mPos.x, self.mPos.y))

    -- 占领者
    UIExtend.setCCLabelString(ccbfile, "mPlayerName", self.mPlayerName)    

    --icon
    UIExtend.addSpriteToNodeParent(ccbfile, "mIconNode", resShowCfg.buildArtImg)

    -- des        mUnoccupiedNode  mResExplain
    UIExtend.setCCLabelString(ccbfile, "mResExplain", _RALang(resShowCfg.resHint))    

    -- res num   mTotalAmountNode  mTotalAmount
    UIExtend.setCCLabelString(ccbfile, "mTotalAmount", tostring(self.mRemainResNum))    

    -- res icon
    local RAResManager = RARequire('RAResManager')
    local Const_pb = RARequire('Const_pb')
    local resIcon = RAResManager:getIconByTypeAndId(Const_pb.PLAYER_ATTR * 10000, resCfg.resType)
    UIExtend.addSpriteToNodeParent(ccbfile, "mResIconNode", resIcon)

    local btnTitle = _RALang('@Confirm')
    -- 无人占领的资源
    if self.mRelation == World_pb.NONE then        
        UIExtend.setNodesVisible(ccbfile,
            {
                mUnoccupiedNode = true,     -- des node
                mOccupantNode = false,      -- owner name
                mTagNode = false,           -- tag node
            })
        btnTitle = _RALang('@DoCollect')
    else
        
        if self.mRelation == World_pb.ENEMY then
            UIExtend.setNodeVisible(ccbfile, 'mEnemyTag', true)
            UIExtend.setNodeVisible(ccbfile, 'mAllyTag', false)
            btnTitle = _RALang('@DoAttack')
        end

        if self.mRelation == World_pb.GUILD_FRIEND then
            UIExtend.setNodeVisible(ccbfile, 'mEnemyTag', false)
            UIExtend.setNodeVisible(ccbfile, 'mAllyTag', true)    
        end

        UIExtend.setNodesVisible(ccbfile,
            {
                mUnoccupiedNode = false,     -- des node
                mOccupantNode = true,      -- owner name
                mTagNode = true,           -- tag node
            })
    end

    if not RAWorldVar:IsInSelfKingdom() then
        btnTitle = _RALang('@Confirm')
    end

    UIExtend.setControlButtonTitle(ccbfile, 'mConfirm', btnTitle, true)
end


function RAWorldCollectionPage:CommonRefresh(data)
    CCLuaLog("RAWorldCollectionPage:CommonRefresh")        
end


function RAWorldCollectionPage:onClose()
    CCLuaLog("RAWorldCollectionPage:onClose") 
    RARootManager.ClosePage('RAWorldCollectionPage')
end

function RAWorldCollectionPage:onConfirm()
    CCLuaLog("RAWorldCollectionPage:onConfirm") 
    -- local time = CCTime:getCurrentTime()
    -- print(time)
    RARootManager.ClosePage('RAWorldCollectionPage')
    local pageData = nil
    
    if RAWorldVar:IsInSelfKingdom() then
        if self.mRelation == World_pb.NONE then  
            pageData = {
                coord = Utilitys.ccpCopy(self.mPos),
                name = self.mName or '',
                icon = self.mIcon or '',
                marchType = World_pb.COLLECT_RESOURCE,
                remainResNum = self.mRemainResNum,
            }
        end

        if self.mRelation == World_pb.ENEMY then
            pageData = {
                coord = Utilitys.ccpCopy(self.mPos),
                name = self.mName or '',
                icon = self.mIcon or '',
                marchType = World_pb.COLLECT_RESOURCE,
                remainResNum = self.mRemainResNum,
            }
        end
    end

    if pageData ~= nil then
        RARootManager.OpenPage('RATroopChargePage', pageData)    
    end
end


function RAWorldCollectionPage:onAddSpeedBtn()
    CCLuaLog("RAWorldCollectionPage:onAddSpeedBtn") 
end

function RAWorldCollectionPage:OnAnimationDone(ccbfile)
	local lastAnimationName = ccbfile:getCompletedAnimationName()	
end

function RAWorldCollectionPage:Exit()
	--you can release lua data here,but can't release node element
    CCLuaLog("RAWorldCollectionPage:Exit")    
    self:unregisterMessageHandlers()
    self:resetData()
    UIExtend.unLoadCCBFile(self)    
end