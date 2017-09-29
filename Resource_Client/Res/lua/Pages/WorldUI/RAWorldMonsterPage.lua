-- RAWorldMonsterPage
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

local RAWorldMonsterPage = BaseFunctionPage:new(...)


RAWorldMonsterPage.mMonsterId = 0
RAWorldMonsterPage.mRemainBlood = -1
RAWorldMonsterPage.mMaxBlood = -1

RAWorldMonsterPage.mPos = nil
RAWorldMonsterPage.mName = ''
RAWorldMonsterPage.mIcon = ''
RAWorldMonsterPage.mTimes = 1
RAWorldMonsterPage.mIndex2Times = {}

local OnReceiveMessage = nil

local OnReceiveMessage = function(message)     
    -- if message.messageID == MessageDef_World.MSG_ArmyFreeCountUpdate then
    --     --需要整个UI cell重新计算
    --     CCLuaLog("MessageDef_World MSG_ArmyFreeCountUpdate")
    --     RAWorldMonsterPage:RefreshUIWhenSelectedChange()
    -- end

    -- if message.messageID == MessageDef_World.MSG_ArmyChangeSelectedCount then
    --     --需要刷新cell数据和UI
    --     CCLuaLog("MessageDef_World MSG_ArmyChangeSelectedCount")
    --     RAWorldMonsterPage:RefreshUIWhenSelectedChange(message.actionType, message.armyId, message.selectCount)
    -- end

    if message.messageID == MessageDef_Packet.MSG_Operation_Fail then        
        local opcode = message.opcode
        if opcode == HP_pb.WORLD_FIGHTMONSTER_C then
            RARootManager.RemoveWaitingPage()
        end
    end
end

function RAWorldMonsterPage:registerMessageHandlers()
    -- MessageManager.registerMessageHandler(MessageDef_World.MSG_ArmyFreeCountUpdate, OnReceiveMessage)
    -- MessageManager.registerMessageHandler(MessageDef_World.MSG_ArmyChangeSelectedCount, OnReceiveMessage)

    MessageManager.registerMessageHandler(MessageDef_Packet.MSG_Operation_Fail, OnReceiveMessage)
end

function RAWorldMonsterPage:unregisterMessageHandlers()
    -- MessageManager.removeMessageHandler(MessageDef_World.MSG_ArmyFreeCountUpdate, OnReceiveMessage)
    -- MessageManager.removeMessageHandler(MessageDef_World.MSG_ArmyChangeSelectedCount, OnReceiveMessage)

    MessageManager.removeMessageHandler(MessageDef_Packet.MSG_Operation_Fail, OnReceiveMessage)
end


function RAWorldMonsterPage:resetData()
    self.mMonsterId = 0
    self.mRemainBlood = -1
    self.mMaxBlood = -1

    self.mPos = nil
    self.mName = ''
    self.mIcon = ''
    self.mTimes = 1
    self.mIndex2Times = {}
end

function RAWorldMonsterPage:Enter(data)
    CCLuaLog("RAWorldMonsterPage:Enter")    

    self:resetData()
    local ccbfile = UIExtend.loadCCBFile("ccbi/RAWorldMonsterPopUp.ccbi",RAWorldMonsterPage)    

    if data ~= nil then        
        self.mMonsterId = data.monsId or 0
        self.mRemainBlood = data.remainBlood or -1
        self.mMaxBlood = data.maxBlood or -1
        self.mPos = RACcp(data.posX, data.posY)        
        self.mName = data.name
        self.mIcon = data.icon
    end

    local timesCfg = RARequire('world_march_const_conf').atkEnemyContinuityNums.value
    local timesTb = RAStringUtil:split(timesCfg, ',')
    for i=1,#timesTb do
        local atkTimes = timesTb[i]
        self.mIndex2Times[i] = atkTimes
    end
    self:registerMessageHandlers()

    -- 非本服不能攻击
    local RAWorldVar = RARequire('RAWorldVar')
    UIExtend.setCCControlButtonEnable(ccbfile, 'mDoAttack', RAWorldVar:IsInSelfKingdom())

    self:refreshCommonUI()

    --新手处理
    performWithDelay(self:getRootNode(), function()
        local RAGuideManager = RARequire("RAGuideManager")
        if RAGuideManager.isInGuide() then
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
function RAWorldMonsterPage:refreshCommonUI()
    local ccbfile = self:getRootNode()
    if ccbfile == nil then return end    
    if self.mMonsterId == 0 then return end


    local monsterCfg = RAWorldConfigManager:GetMonsterConfig(self.mMonsterId)
    if monsterCfg == nil then return end
    -- title
    local title = _RALang(monsterCfg.name)
    title = _RALang('@NameWithLevelTwoParams', title, monsterCfg.level)
    UIExtend.setCCLabelString(ccbfile, "mMonsterTitle", title)    

    -- monster spr
    -- local monsterSprStr = monsterCfg.show
    UIExtend.addSpriteToNodeParent(ccbfile, "mMonsterSprNode", monsterCfg.show)

    -- monster blood scale 9
    local percent = 1
    if self.mRemainBlood > 0 and self.mMaxBlood > 0 then
        percent = self.mRemainBlood / self.mMaxBlood
        if percent > 1 then percent = 1 end
        local mBar = UIExtend.getCCScale9SpriteFromCCB(ccbfile, 'mBar')
        if mBar ~= nil then
            mBar:setScaleX(percent)
        end
        UIExtend.setCCLabelString(ccbfile, 'mBarNum', _RALang('@PartedTwoParams', self.mRemainBlood, self.mMaxBlood))
        UIExtend.setNodeVisible(ccbfile, 'mBar', true)
        UIExtend.setNodeVisible(ccbfile, 'mBarNum', true)
    else
        UIExtend.setNodeVisible(ccbfile, 'mBar', false)
        UIExtend.setNodeVisible(ccbfile, 'mBarNum', false)
    end

    local Const_pb = RARequire('Const_pb')
    local item_conf = RARequire('item_conf')
    local RALogicUtil = RARequire('RALogicUtil')
    -- rewards
    -- local awards = RAStringUtil:split(monsterCfg.awardShow, ",")
    local awards = RAResManager:getResInfosByStr(monsterCfg.awardShow)
    for i=1,4 do
        local nodeCnt = 'mAwardNode'..i
        local awardItem =  awards[i]
        if awardItem ~= nil then
            UIExtend.setNodeVisible(ccbfile, nodeCnt, true)
            local iconNode = 'mCellIconNode'..i
            local iconQualityNode = 'mCellQualityNode'..i
            local nameTTF = 'mIconName'..i
            local icon, name = RAResManager:getIconByTypeAndId(awardItem.itemType, awardItem.itemId)            
            UIExtend.addSpriteToNodeParent(ccbfile, iconNode, icon)

            UIExtend.setCCLabelString(ccbfile, nameTTF, _RALang(name))
            UIExtend.setLabelTTFColor(ccbfile, nameTTF,COLOR_TABLE[COLOR_TYPE.WHITE])
            
            UIExtend.removeSpriteFromNodeParent(ccbfile, iconQualityNode)
            if tonumber(awardItem.itemType) / 10000 == Const_pb.TOOL then
                local itemConf = item_conf[tonumber(awardItem.itemId)]
                if itemConf ~= nil then
                    local qualityFarme = RALogicUtil:getItemBgByColor(itemConf.item_color)
                    UIExtend.addSpriteToNodeParent(ccbfile, iconQualityNode,qualityFarme)                
                    UIExtend.setLabelTTFColor(ccbfile, nameTTF,COLOR_TABLE[itemConf.item_color])
                end
            end
        else
            UIExtend.setNodeVisible(ccbfile, nodeCnt, false)
        end        
    end

    local timesCfg = RARequire('world_march_const_conf').atkEnemyContinuityNums.value
    local timesTb = RAStringUtil:split(timesCfg, ',')
    for i=1,#timesTb do
        local atkTimes = timesTb[i]
        local btnName = 'mAttackBtn'..i
        local nameStr = _RALang('@AttackMonsterWithTimes', atkTimes)
        UIExtend.setControlButtonTitle(ccbfile, btnName, nameStr, true)
    end

    -- 作用号大于0，就开启了扫荡
    local isOpenTimes = RAPlayerEffect:getEffectResult(Const_pb.MULT_ATK_MONSTER) > 0    
    UIExtend.setCCControlButtonEnable(ccbfile, 'mAttackBtn2', isOpenTimes)
    UIExtend.setCCControlButtonEnable(ccbfile, 'mAttackBtn3', isOpenTimes)
    UIExtend.setCCControlButtonEnable(ccbfile, 'mAttackBtn4', isOpenTimes)

    -- default select
    self:_selectOneBtn(1)

    --vip1:mVIPDetails


    --vip2:mVIPDetails2    
    local contentStr = RAStringUtil:getHTMLString('AttackMonsterVipDesForTimes') 
    UIExtend.setCCLabelHTMLString(ccbfile,"mVIPDetails2",contentStr)    
end

--desc:获得攻击按钮的信息
function RAWorldMonsterPage:getAttackBtnInfo()
    local attackBtn = self.ccbfile:getCCNodeFromCCB("mDoAttack")
    local worldPos =  attackBtn:getParent():convertToWorldSpaceAR(ccp(attackBtn:getPositionX(),attackBtn:getPositionY()))
    local size = attackBtn:getContentSize()
    local guideData = {
        ["pos"] = worldPos,
        ["size"] = size
    }
    return guideData
end

function RAWorldMonsterPage:_selectOneBtn(index)
    local ccbfile = self:getRootNode()
    if ccbfile == nil then return end
    if index < 0 or index > 4 then return end
    local isOpenTimes = RAPlayerEffect:getEffectResult(Const_pb.MULT_ATK_MONSTER) > 0
    if not isOpenTimes and index > 1 then
        index = 1
    end
    self.mSelectIndex = index
    local selectMap = {}
    local selectMax = 1
    if isOpenTimes then selectMax = 4 end
    for i=1,selectMax do        
        local btnName = 'mAttackBtn'..i        
        selectMap[btnName] = i == self.mSelectIndex
    end
    UIExtend.setControlButtonSelected(ccbfile, selectMap)
    self.mTimes = tonumber(self.mIndex2Times[index])
end

function RAWorldMonsterPage:CommonRefresh(data)
    CCLuaLog("RAWorldMonsterPage:CommonRefresh")
    self:refreshCommonUI()
end


function RAWorldMonsterPage:onClose()
    CCLuaLog("RAWorldMonsterPage:onClose") 
    RARootManager.ClosePage('RAWorldMonsterPage')
end


function RAWorldMonsterPage:onAttackBtn1()
    self:_selectOneBtn(1)
end

function RAWorldMonsterPage:onAttackBtn2()
    self:_selectOneBtn(2)
end

function RAWorldMonsterPage:onAttackBtn3()
    self:_selectOneBtn(3)
end

function RAWorldMonsterPage:onAttackBtn4()
    self:_selectOneBtn(4)
end

function RAWorldMonsterPage:onDoAttack()
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
        end
    end

    if not isAttack then
        local tipStr = _RALang('@MonsterLevelLess', levelNeed)
        RARootManager.ShowMsgBox(tipStr)
    else
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


function RAWorldMonsterPage:OnAnimationDone(ccbfile)
    local lastAnimationName = ccbfile:getCompletedAnimationName()   
end


function RAWorldMonsterPage:Exit()
    --you can release lua data here,but can't release node element
    CCLuaLog("RAWorldMonsterPage:Exit")    
    self:unregisterMessageHandlers()
    self:resetData()
    UIExtend.unLoadCCBFile(self)    
end