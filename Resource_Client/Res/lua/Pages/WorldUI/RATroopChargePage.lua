-- RATroopChargePage
-- 出征页面

RARequire("BasePage")
local UIExtend = RARequire("UIExtend")
local Utilitys = RARequire('Utilitys')
local RARootManager = RARequire("RARootManager")
local battle_soldier_conf = RARequire("battle_soldier_conf")
local RACoreDataManager = RARequire('RACoreDataManager')
local RAMarchDataManager = RARequire('RAMarchDataManager')
local RAWorldVar = RARequire('RAWorldVar')
local RAMarchConfig = RARequire('RAMarchConfig')     
local RAMissionBarrierManager = RARequire("RAMissionBarrierManager")

local RATroopChargePage = BaseFunctionPage:new(...)

local OnReceiveMessage = nil

local RefreshScrollViewType = 
{
    SliderBarMove = 0,
    SliderBarEnd = 1,
    Max = 2,
    Minimum = 3
}


-- key 
-- @ArmyLevel {0}级兵力
-- @CurrArmyLoad 当前负重{0}
-- @VitNumInMarchPage  x{0}
-- @WorldCoordPos x:{0} y:{1}
------ title cell
local RATroopChargeTitleCell = 
{
    -- 
    mLevel = 0,
    
    new = function(self, o)
        o = o or {}
        setmetatable(o,self)
        self.__index = self    
        return o
    end,

    getCCBName = function(self)
        return "RATroopChargeCellTitle.ccbi"
    end,

    onRefreshContent = function(self, cellRoot)
        CCLuaLog("RATroopChargeTitleCell:onRefreshContent")
        local ccbfile = cellRoot:getCCBFileNode()
        if ccbfile ~= nil then            
            UIExtend.setCCLabelString(ccbfile, 'mArmyLevel', _RALang("@ArmyLevel", self.mLevel))            
        end
    end,

    OnAnimationDone = function(self, ccbfile)
        local lastAnimationName = ccbfile:getCompletedAnimationName()                
    end
}



------ content cell
local RATroopChargeContentCell = 
{
    mArmyUuid = -1,
    mArmyId = -1,
    mArmyLevel = 0,
    
    --当前兵种的最大数目
    mArmyMaxCount = 0,
    --当前兵种选中的数目
    mArmySelectCount = 0,
    --当前整个部队剩余可用出征数目
    mArmyLimitLastNum = 0,
    
    new = function(self, o)
        o = o or {}
        setmetatable(o,self)
        self.__index = self    
        return o
    end,

    resetData = function(self)
        self.mArmyUuid = -1
        self.mArmyId = -1
        self.mArmyLevel = 0

        --当前兵种的最大数目
        self.mArmyMaxCount = 0
        --当前兵种选中的项目
        self.mArmySelectCount = 0
        self.mArmyLimitLastNum = 0
    end,

    getCCBName = function(self)
        return "RATroopChargeCell.ccbi"
    end,

    onUnLoad = function(self, cellRoot)
        local ccbfile = cellRoot:getCCBFileNode()
        if ccbfile ~= nil then            
            UIExtend.removeSpriteFromNodeParent(ccbfile, 'mListIconNode')
            local sliderNode = ccbfile:getCCNodeFromCCB('mBarNode')
            sliderNode:removeAllChildrenWithCleanup(true)
           if self.editBox then
               self.editBox:removeFromParentAndCleanup(true)
               self.editBox = nil
           end
        end        
        self.mSlider = nil
    end,

    onRefreshContent = function(self, cellRoot)
        CCLuaLog("RATroopChargeContentCell:onRefreshContent")
        local ccbfile = cellRoot:getCCBFileNode()
        if ccbfile ~= nil then
            local cfgArmy = battle_soldier_conf[self.mArmyId]
            if cfgArmy == nil then
                return
            end
            -- icon
            UIExtend.addSpriteToNodeParent(ccbfile, 'mListIconNode', cfgArmy.icon)            
            UIExtend.setCCLabelString(ccbfile, 'mSoldierName', _RALang(cfgArmy.name))
            UIExtend.setCCLabelString(ccbfile, 'mMaxNum', tostring(self.mArmyMaxCount))
            -- mMaxNum

            UIExtend.setCCLabelString(ccbfile, 'mWoundedNum', tostring(self.mArmySelectCount))


            local editboxEventHandler = function(eventType, node)
                --body
                CCLuaLog(eventType)
                if eventType == "began" then
                   -- triggered when an edit box gains focus after keyboard is shown
                elseif eventType == "ended" then
                   -- triggered when an edit box loses focus after keyboard is hidden.
                   local valueStr = self.editBox:getText()
                   local value = tonumber(valueStr) or 0
                   if value > self.mArmyMaxCount then
                       value = self.mArmyMaxCount
                   end
                   local maxNum = self.mArmySelectCount + self.mArmyLimitLastNum
                   if maxNum < value then
                       value = self.mArmySelectCount + self.mArmyLimitLastNum
                   end
                   -- self.mArmySelectCount = value
                   -- self.mSlider:setValue(self.mArmySelectCount)
                   self.mArmySelectCount = math.ceil(value)
                   if self.mSlider ~= nil then
                       self.mSlider:setValue(self.mArmySelectCount)
                   end
                   if self.editBox then
                       self.editBox:setText(tostring(self.mArmySelectCount))
                   end
                   RATroopChargePage:RefreshUIWhenSelectedChange(RefreshScrollViewType.SliderBarEnd, self.mArmyId, self.mArmySelectCount)
                elseif eventType == "changed" then
                   -- triggered when the edit box text was changed.
                elseif eventType == "return" then
                   -- triggered when the return button was pressed or the outside area of keyboard was touched.
                end
            end

            UIExtend.setNodesVisible(ccbfile,{mWoundedNum = false})
            local inputNode = UIExtend.getCCNodeFromCCB(ccbfile,"mInputNode")
            local editBox = UIExtend.createEditBox(ccbfile,"mInputBG",inputNode,editboxEventHandler,nil,nil,kEditBoxInputModeNumeric,22,nil,ccc3(255,255,255),2)
            self.editBox = editBox
            --不适用原生控件
            self.editBox:setIsShowTTF(true)
            self.editBox:setText(tostring(self.mArmySelectCount))

            local slider = UIExtend.getControlSlider('mBarNode', ccbfile, true)
            slider:registerScriptSliderHandler(self)
            self.mSlider = slider
            self.mSlider:setMinimumValue(0)
            self.mSlider:setMaximumValue(self.mArmyMaxCount)
            self.mSlider:setLimitMoveValue(1)
            self.mSlider:setMaximumAllowedValue(self.mArmyLimitLastNum + self.mArmySelectCount)
            self.mSlider:setValue(self.mArmySelectCount)
        end
    end,

    -- 当某个行军选择改变的时候，需要刷新cell
    refreshCellContent = function(self, armyLimitLastNum)
        
        if self.selfCell ~= nil then   
            local ccbfile = self.selfCell:getCCBFileNode()       
            if ccbfile ~= nil then  
                UIExtend.setCCLabelString(ccbfile, 'mWoundedNum', tostring(self.mArmySelectCount))
                if self.editBox then
                    self.editBox:setText(tostring(self.mArmySelectCount))
                end                
            end
            if armyLimitLastNum ~= self.mArmyLimitLastNum then
                self.mArmyLimitLastNum = armyLimitLastNum
                if self.mSlider ~= nil then
                    local maxNum = self.mArmySelectCount + self.mArmyLimitLastNum
                    self.mSlider:setMaximumAllowedValue(maxNum)
                end
            end
        end
    end,

    -- setCellShowCount = function(self, selectedCount, lastNum)
    --     if self.selfCell ~= nil then   
    --         local ccbfile = self.selfCell:getCCBFileNode()       
    --         if ccbfile ~= nil then 
    --             self.mArmySelectCount = tonumber(selectedCount)
    --             self.mArmyLimitLastNum = tonumber(lastNum)
    --             UIExtend.setCCLabelString(ccbfile, 'mWoundedNum', tostring(self.mArmySelectCount))
    --             if self.mSlider ~= nil then
    --                 self.mSlider:setMaximumAllowedValue(self.mArmyLimitLastNum)
    --                 self.mSlider:setValue(self.mArmySelectCount)
    --             end
    --         end
    --     end
    -- end,

    sliderBegan = function(self, sliderNode)
        print("RATroopChargeContentCell:sliderBegan")
    end,

    sliderMoved = function(self,  sliderNode )
        -- print("RATroopChargeContentCell:sliderMoved")
        if self.mSlider ~= nil then
            self.mArmySelectCount = math.ceil(self.mSlider:getValue())
            self:refreshCellContent(self.mArmyLimitLastNum)
            RATroopChargePage:RefreshUIWhenSelectedChange(RefreshScrollViewType.SliderBarMove, self.mArmyId, self.mArmySelectCount)
        end
    end,

    sliderEnded = function(self,  sliderNode )
        print("RATroopChargeContentCell:sliderEnded")
        if self.mSlider ~= nil then
            self.mArmySelectCount = math.ceil(self.mSlider:getValue())
            RATroopChargePage:RefreshUIWhenSelectedChange(RefreshScrollViewType.SliderBarEnd, self.mArmyId, self.mArmySelectCount)
        end
    end,

    onAddBtn = function(self)
        print("RATroopChargeContentCell:onAddBtn")
        if self.mSlider == nil then return end
        local value = math.ceil(self.mSlider:getValue())
        if 0 < self.mArmyLimitLastNum and value < self.mArmyMaxCount then
            value = tonumber(value+1)
            self.mSlider:setValue(value)
            self:sliderEnded()
        end
    end,

    onSubBtn = function(self)
        print("RATroopChargeContentCell:onSubBtn")
        if self.mSlider == nil then return end
        local value = math.ceil(self.mSlider:getValue())
        if value >= 1 then
            value = tonumber(value-1)
            self.mSlider:setValue(value)
            self:sliderEnded()
        end
    end,

    OnAnimationDone = function(self, ccbfile)
        local lastAnimationName = ccbfile:getCompletedAnimationName()                
    end
}

-- 行军类型，初始化时传参
RATroopChargePage.mMarchType = -1

-- 当前选中的军队列表数据
RATroopChargePage.mArmySelectMap = nil

-- 当前行军的cell handler
RATroopChargePage.mArmyCellMap = nil

RATroopChargePage.mTargetIcon = ''
RATroopChargePage.mTargetCoord = nil
RATroopChargePage.mTargetName = ''

--出征上限
RATroopChargePage.mMarchLimitMax = 0
--可出征总兵力
RATroopChargePage.mMarchFreeCount = 0
--已经选中的兵力
RATroopChargePage.mMarchSelectCount = 0
--已经选择的兵力总负重
RATroopChargePage.mMarchSelectLoadNum = 0

--攻打怪物的次数
-- 现在修改为攻击方式，0为普通攻击，1为全力攻击
RATroopChargePage.mAtkMonsterTimes = 0
--集结时间
RATroopChargePage.mGatherTime = 0
--队长的march id
RATroopChargePage.mMassTargetMarchId = ''

RATroopChargePage.mMarchParts = nil
RATroopChargePage.mLastSpeed = -1

local OnReceiveMessage = function(message)     
    if message.messageID == MessageDef_World.MSG_ArmyFreeCountUpdate then
        --需要整个UI cell重新计算
        CCLuaLog("MessageDef_World MSG_ArmyFreeCountUpdate")
        RATroopChargePage:RefreshUIWhenSelectedChange(RefreshScrollViewType.Max)
    end

    if message.messageID == MessageDef_World.MSG_ArmyChangeSelectedCount then
        --需要刷新cell数据和UI
        CCLuaLog("MessageDef_World MSG_ArmyChangeSelectedCount")
        RATroopChargePage:RefreshUIWhenSelectedChange(message.actionType, message.armyId, message.selectCount)
    end

    if message.messageID == MessageDef_Packet.MSG_Operation_Fail then
        --todo
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

function RATroopChargePage:registerMessageHandlers()
    MessageManager.registerMessageHandler(MessageDef_World.MSG_ArmyFreeCountUpdate, OnReceiveMessage)
    MessageManager.registerMessageHandler(MessageDef_World.MSG_ArmyChangeSelectedCount, OnReceiveMessage)

    MessageManager.registerMessageHandler(MessageDef_Packet.MSG_Operation_Fail, OnReceiveMessage)
end

function RATroopChargePage:unregisterMessageHandlers()
    MessageManager.removeMessageHandler(MessageDef_World.MSG_ArmyFreeCountUpdate, OnReceiveMessage)
    MessageManager.removeMessageHandler(MessageDef_World.MSG_ArmyChangeSelectedCount, OnReceiveMessage)

    MessageManager.removeMessageHandler(MessageDef_Packet.MSG_Operation_Fail, OnReceiveMessage)
end


function RATroopChargePage:resetData()
    -- body
    self.mArmySelectMap = nil
    self.mMarchType = -1
    self.mArmyCellMap = nil
    self.mTargetIcon = ''
    self.mTargetCoord = nil
    self.mTargetName = ''
    --出征上限
    self.mMarchLimitMax = 0
    --可出征总兵力
    self.mMarchFreeCount = 0
    --已经选中的兵力
    self.mMarchSelectCount = 0
    self.mAtkMonsterTimes = 0
    self.mGatherTime = 0
    self.mMassTargetMarchId = ''
    self.mMarchParts = nil
    self.mLastSpeed = -1
end

function RATroopChargePage:EnterFrame()
    CCLuaLog("RATroopChargePage:EnterFrame")    
end

function RATroopChargePage:Enter(data)

    --出征页面 新手期间，点击过快，出现输入框,so 添加 AddCoverPage
    local RAGuideManager = RARequire("RAGuideManager")
    if RAGuideManager.isInGuide() then
        RARootManager.AddCoverPage({["update"] = true})
    end

    -- 出征UI音效
    local RAMarchConfig = RARequire('RAMarchConfig')  
    local common = RARequire('common')
    common:playEffect("battleMenuEject")

    self:resetData()
    self.mArmySelectMap = {}
    CCLuaLog("RATroopChargePage:Enter")    
    local ccbfile = UIExtend.loadCCBFile("ccbi/RATroopChargePage.ccbi",RATroopChargePage)    

    -- common title
    local titleCCB = UIExtend.getCCBFileFromCCB(self.ccbfile, "mCommonTitleCCB")
    local RACommonTitleHelper = RARequire('RACommonTitleHelper')

    self.mTroopChargeSV = UIExtend.getCCScrollViewFromCCB(ccbfile, "mTroopChargeSV")

    if data ~= nil then
        self.mMarchType = data.marchType
        self.mTargetIcon = data.icon or ''
        self.mTargetCoord = data.coord or {x =-1, y = -1}
        self.mTargetName = data.name or ''
        self.mAtkMonsterTimes = data.times or 0
        self.mGatherTime = data.gatherTime or 0
        self.mMassTargetMarchId = data.massTargetMarchId or ''
        self.mRemainResNum = data.remainResNum or 0
    end

    local disCfg = RAMarchConfig.MarchType2DisCfg[self.mMarchType]
    local titleName =  _RALang(disCfg.title) or _RALang("@TroopChargeTitle") --出征UI
    local titleHandler = RACommonTitleHelper:RegisterCommonTitle('RATroopChargePage', titleCCB, titleName)
    titleHandler:SetTitleBgType(RACommonTitleHelper.BgType.Blue)
    titleHandler:SetCallBack(RACommonTitleHelper.TitleCallBack.Back, function()
        RARootManager.ClosePage("RATroopChargePage")
        local common = RARequire("common")
        common:playEffect("click_main_botton_banner_back")
    end)

    -- mTroopChargeBtn
    UIExtend.setControlButtonTitle(ccbfile, 'mTroopChargeBtn', disCfg.btnLabel or '@TroopCharge')

    -- 计算分段数据，用于计算出征时间
    local RAPlayerInfoManager = RARequire('RAPlayerInfoManager')
    local selfCoord = RAPlayerInfoManager.getWorldPos()
    local startPos = Utilitys.ccpCopy(selfCoord)
    local endPos = Utilitys.ccpCopy(self.mTargetCoord)  
    self.mMarchParts = RAMarchDataManager:GetMarchWayData(startPos, endPos, true)

    self.mIsHandling = false
    self.mLastHandleTime = 0
    self:refreshCommonUI()
    self:RefreshUIWhenSelectedChange(RefreshScrollViewType.Max)
    self:registerMessageHandlers()

    for k,v in pairs(RAMarchConfig.MarchType2HpCode) do
        local s2c = v.s2c
        self:RegisterPacketHandler(s2c)
    end
    
    --出征页面
    local RAGuideManager = RARequire("RAGuideManager")
    if RAGuideManager.isInGuide() and (not RAMissionBarrierManager:isInBarrierOrNot()) then
        RAGuideManager.gotoNextStep()
    end
end

--desc:获得 出征按钮的pos和size
function RATroopChargePage:getGuideNodeInfo()
    local RAGuideConfig = RARequire("RAGuideConfig")
    local troopChargeBtn = self.ccbfile:getCCNodeFromCCB("mGuideTroopNode")
    local worldPos =  troopChargeBtn:getParent():convertToWorldSpaceAR(ccp(troopChargeBtn:getPositionX(),troopChargeBtn:getPositionY()))
    local size = troopChargeBtn:getContentSize()
    local guideData = {
        ["pos"] = ccp(worldPos.x+5,worldPos.y-5),
        ["size"] = CCSizeMake(size.width+RAGuideConfig.GuideTips.ConfigOffset*2, size.height+RAGuideConfig.GuideTips.ConfigOffset*2)
    }
    return guideData
end

--desc:获得负重节点的信息
function RATroopChargePage:getWeightLoadNodeInfo()
    local weightTTF = UIExtend.getCCLabelTTFFromCCB(self.ccbfile, "mArmyLoadNum")
    if weightTTF then
        local worldPos =  weightTTF:getParent():convertToWorldSpaceAR(ccp(weightTTF:getPositionX(),weightTTF:getPositionY()))
        local size = weightTTF:getContentSize()
        local guideData = {
            ["pos"] = worldPos,
            ["size"] = size
        }
        return guideData
    end
    return nil
end

-- 只在enter的时候需要刷新
function RATroopChargePage:refreshCommonUI()
    local ccbfile = self:getRootNode()
    if ccbfile == nil then return end    
    -- 体力刷新
    local vitNeed = RAMarchDataManager:GetVitNeedByMarchType(self.mMarchType)
    UIExtend.setNodeVisible(ccbfile, "mBottomLabelNode2", vitNeed <= 0)
    UIExtend.setNodeVisible(ccbfile, "mBottomLabelNode1", vitNeed > 0)
    UIExtend.setCCLabelString(ccbfile, "mExhaustionNum", _RALang('@VitNumInMarchPage', vitNeed, 1))
    
    -- 自己点数据刷新
    local RAPlayerInfoManager = RARequire('RAPlayerInfoManager')
    local selfCoord = RAPlayerInfoManager.getWorldPos()
    -- mMyCoordinateLabel
    local selfPosStr = _RALang('@WorldCoordPos', selfCoord.x, selfCoord.y)
    UIExtend.setCCLabelString(ccbfile, "mMyCoordinateLabel", selfPosStr)
    -- mMyIconNode
    local RAPlayerInfoManager = RARequire('RAPlayerInfoManager')
    UIExtend.addSpriteToNodeParent(ccbfile, 'mMyIconNode', RAPlayerInfoManager.getHeadIcon())
    -- mMyName     
    UIExtend.setCCLabelString(ccbfile, "mMyName", RAPlayerInfoManager.getPlayerBasicInfo().name)

    -- 目标点数据刷新
    local targetCoord = self.mTargetCoord
    -- mDestinationCoordinateLabel
    local targetPosStr = _RALang('@WorldCoordPos', targetCoord.x, targetCoord.y)
    UIExtend.setCCLabelString(ccbfile, "mDestinationCoordinateLabel", targetPosStr)
    -- mDestinationIconNode    
    UIExtend.addSpriteToNodeParent(ccbfile, 'mDestinationIconNode', self.mTargetIcon)
    -- mDestinationName     
    UIExtend.setCCLabelString(ccbfile, "mDestinationName", self.mTargetName)
end

-- 兵力和选择兵力改变的时候需要刷新
function RATroopChargePage:refreshSelectEffectUI()
    local ccbfile = self:getRootNode()
    if ccbfile == nil then return end

    -- 出征上限刷新
    local limitMax = RAMarchDataManager:GetWorldMarchArmyLimit()
    local currLoad = RAMarchDataManager:GetArmyTotalLoadNum(self.mArmySelectMap)
    local selectCount = self:refreshArmySelectedCount(true)
    self.mMarchLimitMax = limitMax
    self.mMarchSelectCount = selectCount
    self.mMarchSelectLoadNum = currLoad
    local limitStr = _RALang('@PartedTwoParams', selectCount, limitMax)
    UIExtend.setCCLabelString(ccbfile, "mSoldiersNum", limitStr)

    --当前负重刷新
    local currLoadStr = _RALang('@CurrArmyLoad', currLoad)
    UIExtend.setCCLabelString(ccbfile, "mArmyLoadNum", currLoadStr)

    -- mTroopChargeBtn
    UIExtend.setCCControlButtonEnable(ccbfile, "mTroopChargeBtn", selectCount > 0)

    -- 行军时间刷新
    local armySpeed = RAMarchDataManager:GetMarchSpeedFromArmyList(self.mArmySelectMap)
    if armySpeed ~= self.mLastSpeed then
        self.mLastSpeed = armySpeed
        local timeNeed = 0
        if armySpeed <= 0 or self.mMarchParts == nil then
            timeNeed = 0
        else
            timeNeed = RAMarchDataManager:GetMarchWayTotalTimeByMarchParts(self.mMarchParts, armySpeed, self.mMarchType)
        end
        local timeNeedStr = Utilitys.createTimeWithFormat(timeNeed)
        local timeStr = _RALang('@MarchNeedTime', timeNeedStr)
        UIExtend.setCCLabelString(ccbfile, "mLongMarchTex1", timeStr)
        UIExtend.setCCLabelString(ccbfile, "mLongMarchTex2", timeStr)
    end
end



-- 选择兵力改变的时候需要刷新
function RATroopChargePage:refreshArmySelectedCount(isCheck)
    local countTotal = 0    
    local battle_soldier_conf = RARequire("battle_soldier_conf")
    for armyId, count in pairs(self.mArmySelectMap) do
        if isCheck then
            local armyInfo = RACoreDataManager:getArmyInfoByArmyId(armyId)
            if armyInfo ~= nil then
                if armyInfo.freeCount < count then
                    self.mArmySelectMap[armyId] = armyInfo.freeCount
                end
                countTotal = countTotal + self.mArmySelectMap[armyId]
            end
        else
            countTotal = countTotal + count
        end
    end

    return countTotal
end

-- 兵力改变的时候需要刷新
function RATroopChargePage:refreshScrollView(armyMap, maxLevel, isSelectMax, isClearSelect)
    local scrollView = self.mTroopChargeSV
    if scrollView == nil then return end
    if armyMap == nil or maxLevel < 1 then
        return
    end
    self.mTroopChargeSV:removeAllCell()
    -- scrollView:removeAllCell()
    -- 出征上限
    local limitMax = RAMarchDataManager:GetWorldMarchArmyLimit()
    -- 采集资源的时候需要的总负重（考虑作用号）
    local limitResCount = RAMarchDataManager:GetRealArmyLoadNeeded(self.mRemainResNum)
    local selectedCount = 0
    local selectedLoad = 0
    if isClearSelect then
        self.mArmySelectMap = {}
        -- isSelectMax = false
    end
    self.mArmyCellMap = {}
    for level = maxLevel, 1, -1 do
        local levelMap = armyMap[level]
        if levelMap then
            local mapCount = Utilitys.table_count(levelMap)
            if mapCount > 0 then
                -- add title
                 -- 先创建一个title
                local ccbTitleCell = CCBFileCell:create()
                local handlerTitle = RATroopChargeTitleCell:new(
                    {
                        mLevel = level,
                    })
                handlerTitle.selfCell = ccbTitleCell
                ccbTitleCell:registerFunctionHandler(handlerTitle)
                ccbTitleCell:setCCBFile(handlerTitle:getCCBName())
                scrollView:addCellBack(ccbTitleCell)

                for index = 1, #levelMap do
                    local ccbDetailCell = CCBFileCell:create()
                    -- mArmyId = -1,
                    -- mArmyLevel = 0,
                    -- -- 当前队列的数目
                    -- mArmyMaxCount = 0,
                    -- mArmySelectCount = 0,
                    local armyId = levelMap[index].armyId
                    local freeCount = levelMap[index].freeCount
                    local oneLoad = levelMap[index].load
                    if self.mArmySelectMap[armyId] == nil then
                        self.mArmySelectMap[armyId] = 0                        
                    end           
                    if isSelectMax then
                        local lastCanSelected = limitMax - selectedCount
                        -- 可以继续选的时候
                        if lastCanSelected > 0 then
                            local willSelected = 0
                            -- 资源的时候需要判断总负重
                            if self.mMarchType == World_pb.COLLECT_RESOURCE then
                                local lastLoadNeed = limitResCount - selectedLoad
                                if lastLoadNeed > 0 then
                                    local currFreeLoad = freeCount * oneLoad
                                    if lastLoadNeed >= currFreeLoad then
                                        -- 该种兵全选也超不过负重最大值的时候
                                        if lastCanSelected >= freeCount then
                                            willSelected = freeCount
                                        else
                                            willSelected = lastCanSelected
                                        end        
                                    else
                                        -- 可以超过负重最大值一些，但不能小于
                                        local loadCanSelCount = math.ceil(lastLoadNeed / oneLoad)                                        
                                        if loadCanSelCount < lastCanSelected then
                                            -- 负重需要的兵小于出征可选兵，直接选中负重兵
                                            willSelected = loadCanSelCount
                                        else
                                            -- 负重兵大于可选兵，选择可选兵
                                            willSelected = lastCanSelected
                                        end
                                    end
                                    self.mArmySelectMap[armyId] = willSelected
                                    selectedLoad = selectedLoad + willSelected * oneLoad
                                    selectedCount = selectedCount + willSelected
                                end
                            else
                                if lastCanSelected >= freeCount then
                                    self.mArmySelectMap[armyId] = freeCount
                                    willSelected = freeCount
                                else
                                    self.mArmySelectMap[armyId] = lastCanSelected
                                    willSelected = lastCanSelected
                                end
                                selectedCount = selectedCount + willSelected
                            end
                        end
                    end
                    local handlerDetail = RATroopChargeContentCell:new(
                        {
                            mArmyUuid = levelMap[index].uuid,
                            mArmyId = armyId,
                            mArmyLevel = level,                       
                            mArmyMaxCount = freeCount,
                            mArmySelectCount = self.mArmySelectMap[armyId]
                        })
                    handlerDetail.selfCell = ccbDetailCell
                    ccbDetailCell:registerFunctionHandler(handlerDetail)
                    ccbDetailCell:setCCBFile(handlerDetail:getCCBName())
                    scrollView:addCellBack(ccbDetailCell)

                    self.mArmyCellMap[armyId] = handlerDetail
                end
            end
        end
    end

    scrollView:orderCCBFileCells()
    self:refreshScrollViewCell()
end

-- 只刷新cell显示
-- 选择兵力改变的时候需要刷新
function RATroopChargePage:refreshScrollViewCell()
    -- 出征上限刷新
    local limitMax = RAMarchDataManager:GetWorldMarchArmyLimit()
    local selectCount = self:refreshArmySelectedCount(true)
    local canSelectCount = limitMax - selectCount
    if self.mArmyCellMap ~= nil then
        for armyId, cellHandler in pairs(self.mArmyCellMap) do
            if cellHandler ~= nil then
                cellHandler:refreshCellContent(canSelectCount)
            end
        end
    end
end

-- actionType : 0为move， 1为end
-- local RefreshScrollViewType = 
-- {
--     SliderBarMove = 0,
--     SliderBarEnd = 1,
--     Max = 2,x
--     Minimum = 3
-- }

function RATroopChargePage:RefreshUIWhenSelectedChange(actionType, armyId, selectCount)
    if actionType == RefreshScrollViewType.SliderBarMove then        
        self.mArmySelectMap[armyId] = selectCount
        self:refreshSelectEffectUI()
    end

    if actionType == RefreshScrollViewType.SliderBarEnd then
        self.mArmySelectMap[armyId] = selectCount
        self:refreshSelectEffectUI()
        self:refreshScrollViewCell()
    end

    -- 直接刷新所有UI
    if actionType == RefreshScrollViewType.Minimum then
        local armyMap, maxLevel, totalFree = RACoreDataManager:getFreeArmyLevelMap()
        self:refreshScrollView(armyMap, maxLevel, false, true) 
        self:refreshSelectEffectUI()
        self.mMarchFreeCount = totalFree
    end

    -- 自动配置的时候刷新
    if actionType == RefreshScrollViewType.Max then
        local armyMap, maxLevel, totalFree = RACoreDataManager:getFreeArmyLevelMap()
        self:refreshScrollView(armyMap, maxLevel, true, true)  
        self:refreshSelectEffectUI()
        self.mMarchFreeCount = totalFree
    end
end

function RATroopChargePage:CommonRefresh(data)
    CCLuaLog("RATroopChargePage:CommonRefresh")        

    -- 使用道具增加出征上限后刷新
    self:refreshSelectEffectUI() 
end

function RATroopChargePage:onAddBtn()
	CCLuaLog("RATroopChargePage:onAddBtn")    
    -- RACommonGainItemData.GAIN_ITEM_TYPE.expeditionMax
    local RACommonGainItemData = RARequire('RACommonGainItemData')
    RARootManager.showCommonGainItemPage(RACommonGainItemData.GAIN_ITEM_TYPE.expeditionMax)
end

function RATroopChargePage:onAutoConfigBtn()
    CCLuaLog("RATroopChargePage:onAutoConfigBtn")
    -- local s = RARootManager.CheckIsPageOpening('RATroopChargePage')
    -- print(tostring(s))

    local common = RARequire('common')
    local currTime = common:getCurTime()    
    -- if currTime - self.mLastHandleTime > 0.5 then
    if true then
        self.mLastHandleTime = currTime
        local isMax = false
        if self.mMarchSelectCount == self.mMarchFreeCount or self.mMarchSelectCount == self.mMarchLimitMax then
            isMax = true
        end
        if not isMax and self.mMarchType == World_pb.COLLECT_RESOURCE then
            if self.mMarchSelectLoadNum >= self.mRemainResNum and self.mRemainResNum > 0 then
                isMax = true
            end
        end
        if isMax then
            self:RefreshUIWhenSelectedChange(RefreshScrollViewType.Minimum)
        else
            self:RefreshUIWhenSelectedChange(RefreshScrollViewType.Max)
        end
    end
end

function RATroopChargePage:onHelpBtn()
    CCLuaLog("RATroopChargePage:onHelpBtn") 
end

function RATroopChargePage:onTroopChargeBtn()
    CCLuaLog("RATroopChargePage:onTroopChargeBtn")
    
    --增加新手引起的出征条件判断
    local canMarchWithGuide = self:isCanMarchWithGuide()
    if not canMarchWithGuide then
        RARootManager.ShowMsgBox("@CanNotMarchWithCityLess3")
        return
    end

    local selectedCount = RATroopChargePage:refreshArmySelectedCount(true)
    if selectedCount > 0 then
        local marchType = self.mMarchType
        local targetCoord = self.mTargetCoord
        local armySelectMap = self.mArmySelectMap
        local addParams = {}
        addParams.times = self.mAtkMonsterTimes
        addParams.gatherTime = self.mGatherTime
        addParams.massTargetMarchId = self.mMassTargetMarchId
        local requestFunc = function()            
            local RAWorldPushHandler = RARequire('RAWorldPushHandler')            
            RAWorldPushHandler:sendWorldMarchReq(marchType, targetCoord, armySelectMap, addParams)
            -- 出征直接关页面，不加waiting了…
            -- local errorStr = 'RATroopChargePage:onTroopChargeBtn waiting page close Error, marchType'..tostring(marchType)
            -- RARootManager.ShowWaitingPage(false, 10, errorStr)
            RARootManager.CloseAllPages()
        end
        local RAGuideManager = RARequire("RAGuideManager")
        -- 采集资源也不做负重检测了
        requestFunc()
        -- if marchType == World_pb.COLLECT_RESOURCE and (not RAGuideManager.isInGuide()) then
        --     local remainResNum = self.mRemainResNum
        --     --采集资源，新增负重和剩余资源量的判定
        --     local currLoad = RAMarchDataManager:GetArmyTotalLoadNum(armySelectMap)
        --     if currLoad > remainResNum then
        --         local confirmData =
        --         {
        --             labelText = _RALang('@RemainResLessThanLoadTips'),
        --             yesNoBtn = true,
        --             resultFun = function (isOK)
        --                 if isOK then
        --                     requestFunc()
        --                 end
        --             end
        --         }
        --         RARootManager.showConfirmMsg(confirmData)
        --     else
        --         requestFunc()
        --     end
        -- else
        --     requestFunc()
        -- end

        local RAGuideManager = RARequire("RAGuideManager")
        if RAGuideManager.isInGuide() then
            --点击出征按钮，新手期有两种处理，一种会延迟进行gotoNextStep，一种不需要
            local keyWord = RAGuideManager.getKeyWordById(RAGuideManager.currentGuildId)
            local RAGuideConfig = RARequire("RAGuideConfig")
            RARootManager.AddCoverPage()
            if keyWord == RAGuideConfig.KeyWordArray.CircleMarchBtn then
                RAGuideManager.gotoNextStepDelay()
            end
        end
    else
        print('you can not begin march without armys') 
    end
end

--desc:是否满足因新手导致的出征条件
function RATroopChargePage:isCanMarchWithGuide()
    --新手在主基地升至3级钱是不允许出征的
    local RABuildManager = RARequire("RABuildManager")
    local RAGuideManager = RARequire("RAGuideManager")
    local const_conf = RARequire("const_conf")
    local RAGameConfig = RARequire("RAGameConfig")
    local mainCityLv = RABuildManager:getMainCityLvl()
    local allowCityLv = const_conf.GuideMarchMainCityLevel.value
    if RAGameConfig.SwitchGuide == 1 and mainCityLv<allowCityLv and (not RAGuideManager.isInGuide()) then
        return false
    end
    return true
end

function RATroopChargePage:onAddStrengthBtn()
    CCLuaLog("RATroopChargePage:onAddStrengthBtn")
    local RACommonGainItemData = RARequire('RACommonGainItemData')
    RARootManager.showCommonGainItemPage(RACommonGainItemData.GAIN_ITEM_TYPE.powerCallBack)
end

function RATroopChargePage:onDestinationPosition()
    CCLuaLog("RATroopChargePage:onDestinationPosition")
    local targetPos, isPtOK = Utilitys.checkIsPoint(self.mTargetCoord)
    RARootManager.CloseAllPages()
    local RAWorldManager = RARequire('RAWorldManager')
    RAWorldManager:LocateAt(targetPos.x, targetPos.y)
end

function RATroopChargePage:onMyPosition()
   CCLuaLog("RATroopChargePage:onMyPosition")   
   RARootManager.CloseAllPages()
   local RAWorldManager = RARequire('RAWorldManager')
   RAWorldManager:LocateAt(RAWorldVar.MapPos.Self.x, RAWorldVar.MapPos.Self.y)
end

function RATroopChargePage:OnAnimationDone(ccbfile)
	local lastAnimationName = ccbfile:getCompletedAnimationName()	
end

function RATroopChargePage:onReceivePacket(handler)
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

function RATroopChargePage:Exit()
	--you can release lua data here,but can't release node element
    RARootManager.RemoveGuidePage()

    CCLuaLog("RATroopChargePage:Exit")        
    self:RemovePacketHandlers()
    self:unregisterMessageHandlers()    
    local RACommonTitleHelper = RARequire('RACommonTitleHelper')
    RACommonTitleHelper:RemoveCommonTitle("RATroopChargePage")
    self.mTroopChargeSV:removeAllCell()
    self:resetData()
    UIExtend.unLoadCCBFile(self)    
end