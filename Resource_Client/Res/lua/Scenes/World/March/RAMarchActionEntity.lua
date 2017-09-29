--RAMarchActionEntity
-- 行军的实体显示对象

local Utilitys = RARequire('Utilitys')
local UIExtend = RARequire('UIExtend')
local RAMarchConfig = RARequire('RAMarchConfig')
local RAActionManager = RARequire('RAActionManager')

local RAMarchActionEntity = 
{
    new = function(self, o)
        o = o or {}
        setmetatable(o,self)
        self.__index = self    
        o.mCurrDirection = nil
        o.mMoveToAction = nil
        o.mHandler = nil

        ----- 序列帧 -------------
        o.mSpritMap = nil
        -- node索引对应兵种类型，用于返回坐标给战斗动画
        o.mNodeIndex2ArmyType = nil

        ------ ccb -------------
        o.mArmyCCBHandlerList = nil

        return o
    end,

    -- 加载ccb, direction为行军的方向，用于获取排列军队的ccb
    LoadNew = function(self, direction)
        local aniCfg = RAMarchConfig.ArmyMarchAniCfg[direction]
        if aniCfg == nil then
            print('RAMarchActionEntity load error!! direction:'..direction)
            return nil
        end

        local ccbfile = UIExtend.loadCCBFile(aniCfg.ccbName, self)
        if ccbfile == nil then
            print('RAMarchActionEntity load error!! direction:'..direction)
            return nil 
        end
        self.mCurrDirection = direction
        
        self.mMarchNode1 = UIExtend.getCCNodeFromCCB(ccbfile, 'mMarchNode1')
        self.mMarchNode2 = UIExtend.getCCNodeFromCCB(ccbfile, 'mMarchNode2')
        self.mMarchNode3 = UIExtend.getCCNodeFromCCB(ccbfile, 'mMarchNode3')
        self.mMarchNode4 = UIExtend.getCCNodeFromCCB(ccbfile, 'mMarchNode4')

        local scaleX = 1
        -- 水平翻转
        if aniCfg.isFlip then
            scaleX = -1    
        end
        ccbfile:setScale(scaleX)        
        self.mMarchNode1:setScale(scaleX)        
        self.mMarchNode2:setScale(scaleX)
        self.mMarchNode3:setScale(scaleX)
        self.mMarchNode4:setScale(scaleX)

        CCCamera:setBillboard(ccbfile)
        
        return ccbfile
    end,

    -- 根据行军类型和附加参数，确认要创建哪个模型
    CreateArmyModels = function(self, marchType, params, relation)
        if self:GetCCBFile() == nil then return false end
        
        self:_resetNode(self.mMarchNode1)
        self:_resetNode(self.mMarchNode2)
        self:_resetNode(self.mMarchNode3)
        self:_resetNode(self.mMarchNode4)

        local World_pb = RARequire('World_pb')
        local ccbNameList = {}
        local ccbNum = 1
        -- 先特殊处理
        -- 侦查
        if marchType == World_pb.SPY then
            local spyCCB = RAMarchConfig.MarchSpyCCB
            ccbNameList[ccbNum] = spyCCB            
        end
        -- 资源援助
        if marchType == World_pb.ASSISTANCE_RES then
            local resAssistCCB = RAMarchConfig.MarchResAssistanceCCB
            ccbNameList[ccbNum] = resAssistCCB            
        end
        -- 采集资源
        if marchType == World_pb.COLLECT_RESOURCE or 
            marchType == World_pb.MANOR_COLLECT then
            local targetResType = params.targetResType or -1
            local ccbName = RAMarchConfig.MarchCollectResCCB[targetResType]
            if ccbName ~= nil and ccbName ~= '' then
                ccbNameList[ccbNum] = ccbName
            end
        end

        -- 抓将
        if marchType == World_pb.CAPTIVE_RELEASE then            
            local captiveReleaseCCB = RAMarchConfig.MarchCaptiveReleaseCCB
            ccbNameList[ccbNum] = captiveReleaseCCB   
        end

        -- 行军、集结、士兵援助
        if marchType == World_pb.ATTACK_MONSTER or 
            marchType == World_pb.ATTACK_PLAYER or 
            marchType == World_pb.ASSISTANCE or 
            marchType == World_pb.MASS or 
            marchType == World_pb.MASS_JOIN or
            marchType == World_pb.MONSTER_MASS or 
            marchType == World_pb.MONSTER_MASS_JOIN or
            marchType == World_pb.ARMY_QUARTERED or
            marchType == World_pb.MANOR_SINGLE or
            marchType == World_pb.MANOR_MASS or
            marchType == World_pb.MANOR_MASS_JOIN or
            marchType == World_pb.MANOR_ASSISTANCE_MASS or
            marchType == World_pb.MANOR_ASSISTANCE_MASS_JOIN or
            marchType == World_pb.MANOR_ASSISTANCE or
            marchType == World_pb.PRESIDENT_SINGLE or
            marchType == World_pb.PRESIDENT_MASS or
            marchType == World_pb.PRESIDENT_MASS_JOIN or
            marchType == World_pb.PRESIDENT_ASSISTANCE_MASS or
            marchType == World_pb.PRESIDENT_ASSISTANCE_MASS_JOIN or
            marchType == World_pb.PRESIDENT_ASSISTANCE then

            local armyTypeList = params.armyTypeList
            if armyTypeList ~= nil then
                for index=1, #armyTypeList do
                    local armyMaxType = armyTypeList[index]
                    local ccbCfg = RAMarchConfig.MarchSoldiersCCB[armyMaxType]
                    if ccbCfg ~= nil then
                        local ccbName = ccbCfg.normal
                        local RAWorldUtil = RARequire('RAWorldUtil')
                        if RAWorldUtil:IsMassingMarch(marchType) then
                            ccbName = ccbCfg.mass
                        end
                        ccbNameList[ccbNum] = ccbName
                        ccbNum = ccbNum + 1
                    end
                end
            end
        end

        self.mArmyCCBHandlerList = {}
        -- 根据行军关系，修改兵种的颜色
        local RAWorldConfig = RARequire('RAWorldConfig')
        local flagCfg = RAWorldConfig.RelationFlagColor[relation]        
        for i = 1, 4 do
            local ccbName = ccbNameList[i]
            self.mArmyCCBHandlerList[i] = { isLoad = false}
            local nodeContainer = self['mMarchNode'..i]            
            if ccbName ~= nil and ccbName ~= '' and nodeContainer ~= nil then               
                local ccbfile = UIExtend.loadCCBFile(ccbName, self.mArmyCCBHandlerList[i], flagCfg)
                self.mArmyCCBHandlerList[i].isLoad = true
                -- 先设置不可见，等播放时间轴的时候，再可见
                ccbfile:setVisible(false)
                nodeContainer:addChild(ccbfile, 0, RAMarchConfig.ArmyMarchAniCCBTag)   
                nodeContainer:setVisible(true)
            end
        end
        local rect = CCRectMake(0,0,2000,1000)
        RAGameUtils:setChildMenu(self:GetCCBFile(),rect)
        rect:delete()
        return true
    end,

    -- 播放时间轴动画
    ArmyPlayAnimation = function(self, speedScale)
        if self.mArmyCCBHandlerList ~= nil then
            for k, ccbHandler in pairs(self.mArmyCCBHandlerList) do
                if ccbHandler ~= nil and ccbHandler.isLoad then
                    local ccbfile = ccbHandler.ccbfile
                    if ccbfile ~= nil then
                        local aniName = RAMarchConfig.MarchModelAniName..self.mCurrDirection
                        ccbfile:runAnimation(aniName)
                        ccbfile:setVisible(true)
                    end
                end
            end
        end
    end,

    -- 播放移动动画
    UpdateEntityMoveAction = function(self, duration, beginPos, endPos)
        if self:GetCCBFile() == nil then return false end

        if self.mMoveToAction == nil then
            self.mMoveToAction = RAActionManager:CreateMoveToAction(self:GetCCBFile(), duration, beginPos, endPos)
            self.mMoveToAction:RegisterHandler(self)
        else            
            self.mMoveToAction:UpdateActionParam(duration, endPos)--beginPos, , self:GetCCBFile())
        end
    end,

    -- 停止播放移动动画
    StopEntityMoveAction = function(self)
        if self:GetCCBFile() == nil then return false end

        if self.mMoveToAction ~= nil then
            local RAActionConfig = RARequire('RAActionConfig')
            self.mMoveToAction:ClearAction(RAActionConfig.MoveToCallBackType.InitiativeEnd)
            self.mMoveToAction:ReleaseAction()
            self.mMoveToAction = nil
        end

        self:RemoveHud()
    end,

    -- 注册移动回调的方法
    RegisterHandler = function(self, handler)
        if type(handler) == 'table' then
            self.mHandler = nil
            self.mHandler = handler
        end
    end,

    -- 移动动画的回调
    OnMoveToActionEnd = function(self, endType)
        print('RAMarchActionEntity OnMoveToActionEnd, type is :'.. endType)
        local RAActionConfig = RARequire('RAActionConfig')
        if endType == RAActionConfig.MoveToCallBackType.InitiativeEnd then
            print('InitiativeEnd')
        elseif endType == RAActionConfig.MoveToCallBackType.NormalEnd then
            print('NormalEnd')
        end
        if self.mHandler and self.mHandler.OnEntityActionChange then
            self.mHandler:OnEntityActionChange(endType)
        end
    end,

    -- 获取每个兵种对应的位置
    GetArmyNodesPos = function(self)
        local result = nil
        if self.mNodeIndex2ArmyType then
            result = {}
            for nodeIndex, armyType in pairs(self.mNodeIndex2ArmyType) do
                -- result[]
                local nodeContainer = self['mMarchNode'..nodeIndex]
                if nodeContainer ~= nil then
                    local x, y = nodeContainer:getPosition()
                    local parent = nodeContainer:getParent()
                    if parent then
                        local localPos = ccp(x, y)
                        local worldPos = parent:convertToWorldSpaceAR(localPos)
                        result[armyType] = RACcp(worldPos.x, worldPos.y)    
                    end
                end
            end
        end
        return result
    end,

    GetCCBFile = function(self)
        return self.ccbfile
    end,

    -- hud 点击
    onCheckBtn = function(self)
        print('RAMarchActionEntity onCheckBtn')                
        self:ShowHud()
    end,

    -- 显示行军Hud
    ShowHud = function (self)
        if self:GetCCBFile() ~= nil and self.mMarchId ~= nil then
            local node = UIExtend.getCCNodeFromCCB(self:GetCCBFile(), 'mHUDNode')
            MessageManager.sendMessage(MessageDef_World.MSG_AddMarchHud, {marchId = self.mMarchId, parent = node})
        end
    end,

    -- 移除行军Hud
    RemoveHud = function (self)
        MessageManager.sendMessage(MessageDef_World.MSG_RemoveMarchHud, {marchId = self.mMarchId})
    end,
    
    _resetNode = function(self, node)
        if node == nil then return end
        node:setVisible(false)
        -- node:removeAllChildrenWithCleanup(true)
        node:removeChildByTag(RAMarchConfig.ArmyMarchAniCCBTag,true)
    end,

    Exit = function(self)        
        self.mCurrDirection = nil
        self.mMoveToAction = nil
        self.mHandler = nil


        ----- 序列帧 -------------
        self:_resetNode(self.mMarchNode1)
        self:_resetNode(self.mMarchNode2)
        self:_resetNode(self.mMarchNode3)
        self:_resetNode(self.mMarchNode4)

        if self.mSpritMap ~= nil then
            for k, actionSpr in pairs(self.mSpritMap) do
                if actionSpr ~= nil then
                    actionSpr:Release()
                end
                self.mSpritMap[k] = nil
            end
        end
        self.mSpritMap = nil
        self.mNodeIndex2ArmyType = nil
        

        ------ ccb remove handler -------------
        if self.mArmyCCBHandlerList ~= nil then
            for k, ccbHandler in pairs(self.mArmyCCBHandlerList) do
                if ccbHandler ~= nil then
                    UIExtend.unLoadCCBFile(ccbHandler)
                end
                self.mArmyCCBHandlerList[k] = nil
            end
        end
        self.mArmyCCBHandlerList = nil

        UIExtend.unLoadCCBFile(self)
    end
}


return RAMarchActionEntity