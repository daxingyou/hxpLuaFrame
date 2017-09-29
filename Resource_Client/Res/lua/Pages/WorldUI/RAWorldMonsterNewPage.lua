-- RAWorldMonsterNewPage
-- 攻击怪物页面

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
local Const_pb = RARequire('Const_pb')    
local RALogicUtil = RARequire('RALogicUtil')
local RAGuideManager = RARequire("RAGuideManager")


local RAWorldMonsterNewPage = BaseFunctionPage:new(...)


RAWorldMonsterNewPage.mMonsterId = 0
RAWorldMonsterNewPage.mRemainBlood = -1
RAWorldMonsterNewPage.mMaxBlood = -1

RAWorldMonsterNewPage.mPos = nil
RAWorldMonsterNewPage.mName = ''
RAWorldMonsterNewPage.mIcon = ''
-- 0为普通攻击，1为全力攻击
RAWorldMonsterNewPage.mTimes = 0

local OnReceiveMessage = nil

local OnReceiveMessage = function(message)     
    -- if message.messageID == MessageDef_World.MSG_ArmyFreeCountUpdate then
    --     --需要整个UI cell重新计算
    --     CCLuaLog("MessageDef_World MSG_ArmyFreeCountUpdate")
    --     RAWorldMonsterNewPage:RefreshUIWhenSelectedChange()
    -- end

    -- if message.messageID == MessageDef_World.MSG_ArmyChangeSelectedCount then
    --     --需要刷新cell数据和UI
    --     CCLuaLog("MessageDef_World MSG_ArmyChangeSelectedCount")
    --     RAWorldMonsterNewPage:RefreshUIWhenSelectedChange(message.actionType, message.armyId, message.selectCount)
    -- end

    if message.messageID == MessageDef_Packet.MSG_Operation_Fail then        
        local opcode = message.opcode
        if opcode == HP_pb.WORLD_FIGHTMONSTER_C then
            RARootManager.RemoveWaitingPage()
        end
    end
end

function RAWorldMonsterNewPage:registerMessageHandlers()
    -- MessageManager.registerMessageHandler(MessageDef_World.MSG_ArmyFreeCountUpdate, OnReceiveMessage)
    -- MessageManager.registerMessageHandler(MessageDef_World.MSG_ArmyChangeSelectedCount, OnReceiveMessage)

    MessageManager.registerMessageHandler(MessageDef_Packet.MSG_Operation_Fail, OnReceiveMessage)
end

function RAWorldMonsterNewPage:unregisterMessageHandlers()
    -- MessageManager.removeMessageHandler(MessageDef_World.MSG_ArmyFreeCountUpdate, OnReceiveMessage)
    -- MessageManager.removeMessageHandler(MessageDef_World.MSG_ArmyChangeSelectedCount, OnReceiveMessage)

    MessageManager.removeMessageHandler(MessageDef_Packet.MSG_Operation_Fail, OnReceiveMessage)
end


function RAWorldMonsterNewPage:resetData()
    local ccbfile = self.ccbfile
    if ccbfile then
        local nodeContainer = UIExtend.getCCNodeFromCCB(ccbfile, 'mItemNode')
        local nodeWidth = nodeContainer:getContentSize().width
        nodeContainer:removeAllChildren()
    end

    self.mMonsterId = 0
    self.mRemainBlood = -1
    self.mMaxBlood = -1

    self.mPos = nil
    self.mName = ''
    self.mIcon = ''
    self.mTimes = 0
end

function RAWorldMonsterNewPage:Enter(data)
    CCLuaLog("RAWorldMonsterNewPage:Enter")    

    self:resetData()
    local ccbfile = UIExtend.loadCCBFile("ccbi/RAWorldMonsterPopUpNew.ccbi",self)    

    if data ~= nil then        
        self.mMonsterId = data.monsId or 0
        self.mRemainBlood = data.remainBlood or -1
        self.mMaxBlood = data.maxBlood or -1
        self.mPos = RACcp(data.posX, data.posY)        
        self.mName = data.name
        self.mIcon = data.icon
    end
    self:registerMessageHandlers()

    -- 非本服不能攻击
    local RAWorldVar = RARequire('RAWorldVar')
    RAWorldVar:IsInSelfKingdom()
    -- UIExtend.setCCControlButtonEnable(ccbfile, 'mDoAttack', RAWorldVar:IsInSelfKingdom())

    self:refreshCommonUI()

    --新手处理，先把guidepage隐藏，需要显示的时候再显示，防止在小怪身上一直显示着。这也是为了解决快速双击小怪，引导消失，本页面不显示的bug
    if RAGuideManager.isInGuide() then
        RARootManager.HideGuidePage()
    end

    performWithDelay(self:getRootNode(), function()
        if RAGuideManager.isInGuide() then
            RARootManager.ShowGuidePage()
            RAGuideManager.gotoNextStep()
        end
    end, 0.4)
end


-- @NameWithLevelTwoParams = {0}Lv.{1}
-- @AttackMonsterVipDesForSpeed = 'vip 3 speed up'
-- @AttackMonsterVipDesForTimes = 'vip 4 add times func'
-- @AttackMonsterWithTimes = 攻打{0}次
-- @Obtain = 可能获得：

-- 只在enter的时候需要刷新
function RAWorldMonsterNewPage:refreshCommonUI()
    local ccbfile = self:getRootNode()
    if ccbfile == nil then return end    
    if self.mMonsterId == 0 then return end


    local monsterCfg = RAWorldConfigManager:GetMonsterConfig(self.mMonsterId)
    if monsterCfg == nil then return end
    local RAWorldConfig = RARequire('RAWorldConfig')
    local isNormal = monsterCfg.type == RAWorldConfig.EnemyType.Normal
    -- btn
    UIExtend.setNodeVisible(ccbfile, 'mOnlyAtkBtnNode', isNormal)
    UIExtend.setNodeVisible(ccbfile, 'mAtkBtnNode', not isNormal)

    -- title
    local title = _RALang(monsterCfg.name)
    title = _RALang('@NameWithLevelTwoParams', title, monsterCfg.level)
    UIExtend.setCCLabelString(ccbfile, 'mTitle', title)        

    local RAGameConfig = RARequire('RAGameConfig')
    local color = RAGameConfig.COLOR.WHITE
    if not isNormal then
        color = RAGameConfig.COLOR.YELLOW
    end
    UIExtend.setLabelTTFColor(ccbfile, 'mTitle', color)

    -- monster spr
    -- local monsterSprStr = monsterCfg.show
    UIExtend.setSpriteImage(ccbfile, { mMonsterPic = monsterCfg.show})

    -- monster blood scale 9
    local percent = 1
    if self.mRemainBlood > 0 and self.mMaxBlood > 0 then
        percent = self.mRemainBlood / self.mMaxBlood
        if percent > 1 then percent = 1 end
        local mBar = UIExtend.getCCScale9SpriteFromCCB(ccbfile, 'mHPBar')
        if mBar ~= nil then
            mBar:setScaleX(percent)
        end
        UIExtend.setCCLabelString(ccbfile, 'mHPNum', _RALang('@PartedTwoParams', self.mRemainBlood, self.mMaxBlood))
        UIExtend.setNodeVisible(ccbfile, 'mHPBar', true)
        UIExtend.setNodeVisible(ccbfile, 'mHPNum', true)
    else
        UIExtend.setNodeVisible(ccbfile, 'mHPBar', false)
        UIExtend.setNodeVisible(ccbfile, 'mHPNum', false)
    end

    -- rewards
    -- local awards = RAStringUtil:split(monsterCfg.awardShow, ",")
    local awards = RAResManager:getResInfosByStr(monsterCfg.awardShow)
    local awardsCount = #awards
    local nodeContainer = UIExtend.getCCNodeFromCCB(ccbfile, 'mItemNode')
    local nodeWidth = nodeContainer:getContentSize().width
    nodeContainer:removeAllChildren()
    if awardsCount > 0 then
        local cellCcbiTable = {}
        local cellWidthTotal = 0
        for i=1, awardsCount do        
            local handler, cellCcbi = self:_CreateOneRewardCell(awards[i])
            cellCcbi:setAnchorPoint(0.5, 0)
            local posX = self:_GetCellPositionX(i, awardsCount, nodeWidth)
            cellCcbiTable[i] = cellCcbi
            cellWidthTotal = cellWidthTotal + cellCcbi:getContentSize().width
        end

        local oneGapWidth = (nodeWidth - cellWidthTotal) / (awardsCount + 1)
        local oneCellWidth = cellWidthTotal / awardsCount
        local currPosX = -oneCellWidth / 2
        for i=1, awardsCount do
            currPosX = currPosX + oneGapWidth
            currPosX = currPosX + oneCellWidth
            local cellCcbi = cellCcbiTable[i]
            cellCcbi:setPositionX(currPosX)
            nodeContainer:addChild(cellCcbi)
        end
    end
    -- 默认普通攻击
    self:_ChangeAtkMode(true)
end

function RAWorldMonsterNewPage:_GetCellPositionX(cellIndex, cellsCount, totalWidth)
    local oneWidth = totalWidth / (cellsCount + 1)
    local posX = oneWidth * cellIndex
    return posX
end

function RAWorldMonsterNewPage:_CreateOneRewardCell(awardCfg)
    if awardCfg == nil then return nil end
    local handler = {}
    local cellCcbi = UIExtend.loadCCBFile('ccbi/RAWorldMonsterPopUpCell.ccbi', handler)
    -- UIExtend.setNodeVisible(ccbfile, nodeCnt, true)
    local iconNode = 'mCellIconNode'
    local iconQualityNode = 'mCellQualityNode'
    local nameTTF = 'mIconName'
    local icon, name = RAResManager:getIconByTypeAndId(awardCfg.itemType, awardCfg.itemId)            
    UIExtend.addSpriteToNodeParent(cellCcbi, iconNode, icon)

    UIExtend.setCCLabelString(cellCcbi, nameTTF, _RALang(name))
    UIExtend.setLabelTTFColor(cellCcbi, nameTTF,COLOR_TABLE[COLOR_TYPE.WHITE])
    
    UIExtend.removeSpriteFromNodeParent(cellCcbi, iconQualityNode)
    local item_conf = RARequire('item_conf')
    if tonumber(awardCfg.itemType) / 10000 == Const_pb.TOOL then
        local itemConf = item_conf[tonumber(awardCfg.itemId)]
        if itemConf ~= nil then
            local qualityFarme = RALogicUtil:getItemBgByColor(itemConf.item_color)
            UIExtend.addSpriteToNodeParent(cellCcbi, iconQualityNode,qualityFarme)                
            UIExtend.setLabelTTFColor(cellCcbi, nameTTF,COLOR_TABLE[itemConf.item_color])
        end
    end
    return handler, cellCcbi
end

--desc:获得攻击按钮的信息
function RAWorldMonsterNewPage:getAttackBtnInfo()
    local attackBtn = self.ccbfile:getCCNodeFromCCB("mSingleAttackBtn")
    local worldPos =  attackBtn:getParent():convertToWorldSpaceAR(ccp(attackBtn:getPositionX(),attackBtn:getPositionY()))
    local size = attackBtn:getContentSize()
    local guideData = {
        ["pos"] = worldPos,
        ["size"] = size
    }
    return guideData
end

function RAWorldMonsterNewPage:CommonRefresh(data)
    CCLuaLog("RAWorldMonsterNewPage:CommonRefresh")
    self:refreshCommonUI()
end


function RAWorldMonsterNewPage:onClose()
    CCLuaLog("RAWorldMonsterNewPage:onClose") 
    RARootManager.ClosePage('RAWorldMonsterNewPage')
end


--
function RAWorldMonsterNewPage:onSingleAttackBtn()
    print('RAWorldMonsterNewPage:onSingleAttackBtn()')
    self:_DoAttack()
end

function RAWorldMonsterNewPage:onAttackBtn()
    print('RAWorldMonsterNewPage:onAttackBtn()')
    self:_DoAttack()
end

-- 集结攻击
function RAWorldMonsterNewPage:onGatherAttackBtn()
    print('RAWorldMonsterNewPage:onGatherAttackBtn()') 
    local isAttack = true
    --攻打的时候，判断怪物和玩家等级
    local levelNeed = -1
    local monsterCfg = RAWorldConfigManager:GetMonsterConfig(self.mMonsterId)
    if monsterCfg ~= nil then        
        local lowerLimit = monsterCfg.lowerLimit
        -- local RABuildManager = RARequire('RABuildManager')
        local RAPlayerInfoManager = RARequire('RAPlayerInfoManager')
        local playerLv = RAPlayerInfoManager.getResCountById(Const_pb.LEVEL)
        -- if RABuildManager:getMainCityLvl() < lowerLimit then
        if playerLv < lowerLimit then
            isAttack = false
            levelNeed = lowerLimit
            local tipStr = _RALang('@MonsterLevelLess', levelNeed)
            RARootManager.ShowMsgBox(tipStr)
            return
        end
    end

    if isAttack then
        local RAWorldVar = RARequire('RAWorldVar')
        isAttack = RAWorldVar:IsInSelfKingdom()
        if not isAttack then
            local tipStr = _RALang('@MonsterAtkOnlySelfServer')
            RARootManager.ShowMsgBox(tipStr)
            return
        end
    end
    
    local coord = Utilitys.ccpCopy(self.mPos)
    local pageData = 
    {
        posX = coord.x,
        posY = coord.y,
        name = self.mName,
        icon = self.mIcon,
        marchType = World_pb.MONSTER_MASS,
        times = self.mTimes
    }
    RARootManager.OpenPage('RAAllianceGatherPage', pageData, false, true, true)
end 

function RAWorldMonsterNewPage:onSelectModeBtn()
    print('RAWorldMonsterNewPage:onSelectModeBtn()') 
    -- 作用号大于0，就可以开启扫荡
    local isOpenTimes = RAPlayerEffect:getEffectResult(Const_pb.MULT_ATK_MONSTER) > 0
    if isOpenTimes then
        local isCurrNormal = self.mTimes == 0
        self:_ChangeAtkMode(not isCurrNormal)
    else
        -- tips
        self:onTipsBtn()
    end
end 


function RAWorldMonsterNewPage:onTipsBtn()
    print('RAWorldMonsterNewPage:onSelectModeBtn()') 
    local confirmData = {
        labelText = _RALang('@MonsterAtkVipDesForTimes'), 
        title = _RALang("@attention"), 
        yesNoBtn = false, 
    }
    RARootManager.showConfirmMsg(confirmData)
end


function RAWorldMonsterNewPage:_ChangeAtkMode(isNormal)
    local ccbfile = self:getRootNode()
    if ccbfile == nil then return end    
    if isNormal then
        self.mTimes = 0        
    else
        self.mTimes = 1
    end
    -- 作用号大于0，就可以开启全力攻击    
    local isOpenTimes = RAPlayerEffect:getEffectResult(Const_pb.MULT_ATK_MONSTER) > 0    
    if not isNormal and isOpenTimes then
        UIExtend.setNodeVisible(ccbfile, 'mSelectPic', true)
    else
        UIExtend.setNodeVisible(ccbfile, 'mSelectPic', false)
    end
end

function RAWorldMonsterNewPage:_DoAttack()    
    local isAttack = true
    --攻打的时候，判断怪物和玩家等级
    local levelNeed = -1
    local monsterCfg = RAWorldConfigManager:GetMonsterConfig(self.mMonsterId)
    if monsterCfg ~= nil then        
        local lowerLimit = monsterCfg.lowerLimit
        -- local RABuildManager = RARequire('RABuildManager')
        local RAPlayerInfoManager = RARequire('RAPlayerInfoManager')
        local playerLv = RAPlayerInfoManager.getResCountById(Const_pb.LEVEL)
        -- if RABuildManager:getMainCityLvl() < lowerLimit then
        if playerLv < lowerLimit then
            isAttack = false
            levelNeed = lowerLimit
            local tipStr = _RALang('@MonsterLevelLess', levelNeed)
            RARootManager.ShowMsgBox(tipStr)
            return
        end
    end

    if isAttack then
        local RAWorldVar = RARequire('RAWorldVar')
        isAttack = RAWorldVar:IsInSelfKingdom()
        if not isAttack then
            local tipStr = _RALang('@MonsterAtkOnlySelfServer')
            RARootManager.ShowMsgBox(tipStr)
            return
        end
    end

    if isAttack then        
        self:onClose()
        local coord = Utilitys.ccpCopy(self.mPos)
        RARootManager.OpenPage('RATroopChargePage',  {
            coord = coord, 
            name = self.mName,
            icon = self.mIcon,        
            marchType = World_pb.ATTACK_MONSTER,
            times = self.mTimes
        })
    end
end


function RAWorldMonsterNewPage:OnAnimationDone(ccbfile)
    local lastAnimationName = ccbfile:getCompletedAnimationName()   
end


function RAWorldMonsterNewPage:Exit()
    --you can release lua data here,but can't release node element
    CCLuaLog("RAWorldMonsterNewPage:Exit")    
    self:unregisterMessageHandlers()
    self:resetData()        
    UIExtend.unLoadCCBFile(self)    
end