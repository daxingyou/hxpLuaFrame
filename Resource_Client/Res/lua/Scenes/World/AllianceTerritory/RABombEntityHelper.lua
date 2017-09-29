-- RABombEntityHelper
-- 处理单个炸弹显示逻辑

local RABombEntityHelper = {}

local UIExtend = RARequire('UIExtend')
local RAWorldMath = RARequire('RAWorldMath')
local common = RARequire('common')
local Utilitys = RARequire('Utilitys')
local GuildManor_pb = RARequire('GuildManor_pb')

-- 用于当播爆炸动画后，这么长时间后去添加辐射动画
local BombAnimationEndTime = 2

-- 爆炸倒计时警报时间间隔
local BombVideoEffectTime = 15

-- 选择目标的ccb对象，3个时间轴
-- Selecting->Selecting    
-- Selected->CountDown    
-- CountDown->CountDown
local RABombAimEntity = {
    new = function(self, o, bombType)
        o = o or {}
        setmetatable(o,self)
        self.__index = self         
        o.bombType = bombType   
        return o
    end,

    GetCCBName = function(self)
        if self.bombType == GuildManor_pb.WEATHER_STORM then
            return 'Ani_Territory_Storm_Aim.ccbi'
        end
        return 'Ani_Territory_Nuke_Aim.ccbi'
    end,

    Load = function(self, aniType)
        local ccbfile = UIExtend.loadCCBFile(self:GetCCBName(), self)
        local aniType = aniType or 3
        if aniType == 3 then
            ccbfile:runAnimation('CountDown')
        end
        return ccbfile
    end,

    Unload = function(self)
        UIExtend.unLoadCCBFile(self)
    end,

    OnAnimationDone = function(self, ccbfile)
        local lastAnimationName = ccbfile:getCompletedAnimationName()
        -- if lastAnimationName == 'CountDown' then 
        --     -- do nothing
        -- end
    end,
}



-- 在目标爆炸时创建的ccb对象，1个时间轴
-- Blast->None
local RABombBlastEntity = {
    new = function(self, o, callBack, bombType)
        o = o or {}
        setmetatable(o,self)
        self.__index = self         
        o.mCallBackHandler = callBack   
        o.bombType = bombType
        return o
    end,

    GetCCBName = function(self)
        if self.bombType == GuildManor_pb.WEATHER_STORM then
            return 'Ani_Territory_Storm_Blast.ccbi'
        end
        return 'Ani_Territory_Nuke_Blast.ccbi'
    end,

    Load = function(self)
        local ccbfile = UIExtend.loadCCBFile(self:GetCCBName(), self)
        return ccbfile
    end,

    Unload = function(self)
        UIExtend.unLoadCCBFile(self)
    end,

    OnAnimationDone = function(self, ccbfile)
        local lastAnimationName = ccbfile:getCompletedAnimationName()
        if lastAnimationName == 'Blast' then 
            print('RABombBlastEntity  OnAnimationDone: need to remove ccb')
            --- 这块不再去做回调，直接用倒计时来做
            if self.mCallBackHandler ~= nil then
                self.mCallBackHandler:OnBlastPlayComplete()
            end
        end
    end,
}


-- 在目标爆炸后展示辐射的ccb对象，1个时间轴
-- Keep->Keep
local RABombGroundEntity = {
    new = function(self, o, bombType)
        o = o or {}
        setmetatable(o,self)
        self.__index = self         
        o.bombType = bombType     
        return o
    end,

    GetCCBName = function(self)
        if self.bombType == GuildManor_pb.WEATHER_STORM then            
            return 'Ani_Territory_Storm_Ground.ccbi'
        end
        return 'Ani_Territory_Nuke_Ground.ccbi'
    end,

    Load = function(self)
        local ccbfile = UIExtend.loadCCBFile(self:GetCCBName(), self)
        return ccbfile
    end,

    Unload = function(self)
        UIExtend.unLoadCCBFile(self)
    end,

    OnAnimationDone = function(self, ccbfile)
        local lastAnimationName = ccbfile:getCompletedAnimationName()
        -- if lastAnimationName == 'Keep' then 
        --     print('RABombGroundEntity  OnAnimationDone: need to remove ccb')
        -- end
    end,
}




-- 倒计时显示的ccb，
-- 分两类，分别放在爆炸点和核弹井上
-- 1则为核弹井
local RANuclearCDEntity = {
    new = function(self, o, bombType)
        o = o or {}
        setmetatable(o,self)
        self.__index = self    
        o.mCD = nil                        
        o.mLastUpdateTime = -1
        o.bombType = bombType
        return o
    end,

    GetCCBName = function(self, cdType)
        if self.bombType == GuildManor_pb.WEATHER_STORM then            
            if cdType == 1 then
                return 'RAWorldStomCDNode1.ccbi'
            end
            return 'RAWorldStomCDNode2.ccbi'
        else
            if cdType == 1 then
                return 'RAWorldNuclearCDNode1.ccbi'
            end
            return 'RAWorldNuclearCDNode2.ccbi'
        end
    end,

    Load = function(self, cdType)
        local ccbfile = UIExtend.loadCCBFile(self:GetCCBName(cdType), self)
        self.mCD = UIExtend.getCCLabelTTFFromCCB(ccbfile, 'mCD')
        -- 默认隐藏文字
        UIExtend.setNodeVisible(ccbfile, 'mCD', false)
        self.mLastUpdateTime = -1
        return ccbfile
    end,

    UpdateShowTime = function(self, lastTime)
        local ccbfile = self.ccbfile
        local currTime = CCTime:getCurrentTime()
        if currTime - self.mLastUpdateTime > 200 then
            if self.mCD ~= nil and ccbfile ~= nil then
                UIExtend.setNodeVisible(ccbfile, 'mCD', lastTime > 0)                
                local tmpStr = Utilitys.createTimeWithFormat(lastTime)
                self.mCD:setString(tmpStr)
            end
            self.mLastUpdateTime = currTime
        end
    end,

    Unload = function(self)
        self.mCD = nil
        self.mLastUpdateTime = 0
        UIExtend.unLoadCCBFile(self)
    end,

    OnAnimationDone = function(self, ccbfile)
        local lastAnimationName = ccbfile:getCompletedAnimationName()
        -- if lastAnimationName == 'Keep' then 
        --     print('RABombGroundEntity  OnAnimationDone: need to remove ccb')
        -- end
    end,
}



-- 炸弹容器对象，控制炸弹播放的逻辑
local RABombEntity = {
    new = function(self, o)
        o = o or {}
        setmetatable(o,self)
        self.__index = self 
        o.bombId = nil
        -- Ground 层，放地表特效
        o.mGroundNode = nil
        -- UI 层，放建筑物上一层特效
        o.mUINode = nil

        --目标ccb
        o.mAimHandler = nil
        --爆炸特效ccb
        o.mBlastHandler = nil
        --爆炸后持续效果ccb
        o.mGroundHandler = nil
        --倒计时
        o.mCDHandler = nil

        --炸弹爆炸状态，1未爆炸、2已爆炸（辐射中）、3辐射结束（需要移除）
        o.mBombStatus = -1
        --是否正在播放动画
        o.mIsBombing = false

        o.mIsUpdate = false


        o.explodeTime = 0
        o.disappearTime = 0

        o.firePosX = 0
        o.firePosY = 0

        --秒
        o.lastBombWarnTime = 0
        o.bombType = 0
        return o
    end,

    Init = function(self, bombId)
        local RATerritoryDataManager = RARequire('RATerritoryDataManager')
        local RAWorldMath = RARequire('RAWorldMath')
        local bombData = RATerritoryDataManager:GetBombDataById(bombId)
        if bombData == nil then return nil end
        self.bombId = bombId
        local currTime = common:getCurMilliTime()
        if bombData.disappearTime < currTime then return nil end
        local viewPos = RAWorldMath:Map2View(RACcp(bombData.firePosX, bombData.firePosY))
        self.bombType = bombData.nuclearType or GuildManor_pb.NUCLRAR_WARHEAD
        self.mGroundNode = CCNode:create()
        self.mGroundNode:setPosition(viewPos.x, viewPos.y)
        self.mGroundNode:retain()

        self.mUINode = CCNode:create()
        self.mUINode:setPosition(viewPos.x, viewPos.y)
        self.mUINode:retain()

        self.mAimHandler = RABombAimEntity:new({}, self.bombType)
        self.mBlastHandler = RABombBlastEntity:new(nil, self, self.bombType)
        self.mGroundHandler = RABombGroundEntity:new({}, self.bombType)
        self.mCDHandler = RANuclearCDEntity:new({}, self.bombType)
        return self
    end,

    GetGroundNode = function(self)
        return self.mGroundNode
    end,

    GetUINode = function(self)
        return self.mUINode
    end,

    -- layer==1  ground; layern==2  ui
    AddCCB = function(self, layer, entityHandler, zOrder,...)
        local zOrder = zOrder or 0
        if entityHandler ~= nil and entityHandler.Load ~= nil then
            local ccbfile = entityHandler:Load(...)
            if ccbfile ~= nil then
                if layer == 1 then
                    self.mGroundNode:addChild(ccbfile, zOrder)
                end
                if layer == 2 then
                    self.mUINode:addChild(ccbfile, zOrder)
                end
            end
            return ccbfile
        end
        return nil
    end,

    -- 1未爆炸、2已爆炸（辐射中）、3辐射结束（需要移除）
    UpdateByBombData = function(self, bombId)
        self.mIsUpdate = false
        local RATerritoryDataManager = RARequire('RATerritoryDataManager')
        local RATerritoryManager = RARequire('RATerritoryManager')

        local bombData = RATerritoryDataManager:GetBombDataById(bombId)
        if bombData == nil then return nil end        
        self.mIsUpdate = true
        local currTime = common:getCurTime()
        -- self.mAimHandler:Unload()
        -- self.mBlastHandler:Unload()
        -- self.mGroundHandler:Unload()
        -- 未爆炸
        self.explodeTime = bombData.explodeTime
        self.disappearTime = bombData.disappearTime
        self.firePosX = bombData.firePosX
        self.firePosY = bombData.firePosY
        if self.explodeTime / 1000 > currTime then
            self.mBombStatus = 1
            self:AddCCB(2, self.mAimHandler, 1)

            -- 倒计时
            local cdCCBFile = self:AddCCB(2, self.mCDHandler, 3)
            if cdCCBFile ~= nil then
                CCCamera:setBillboard(cdCCBFile)
            end
        else            
            --已经爆炸，辐射中
            if self.disappearTime / 1000 > currTime then
                self.mBombStatus = 2
                self:AddCCB(1, self.mGroundHandler, 1)
            else
                self.mBombStatus = 3
                self.mIsUpdate = false                
                RATerritoryManager:RemoveBombAreaByBombId(bombData.bombId)
                return nil
            end
        end
    end,

    Execute = function(self)
        if self.mIsBombing or not self.mIsUpdate then return end
        local currTime = common:getCurTime()
        if self.explodeTime / 1000 > currTime then
            self.mBombStatus = 1

            -- 更新爆炸倒计时
            if self.mCDHandler ~= nil then
                self.mCDHandler:UpdateShowTime(self.explodeTime / 1000  - currTime)
            end

            -- 超过时间的时候播警告音效
            if currTime - self.lastBombWarnTime > BombVideoEffectTime then
                --播放爆炸音效                    
                local RAWorldMath = RARequire('RAWorldMath')
                local warning_video = 'bomb_warning'
                if self.bombType == GuildManor_pb.WEATHER_STORM then
                    warning_video = 'bomb_storm_warning'
                end
                local isPlayed = RAWorldMath:CheckAndPlayVideo(RACcp(self.firePosX, self.firePosY), warning_video)
                if isPlayed then
                    self.lastBombWarnTime = currTime
                end
            end
        else            
            --已经爆炸，辐射中
            if self.disappearTime / 1000 > currTime then
                -- 如果上一个还是爆炸前状态，那么这时候要去load爆炸特效
                if self.mBombStatus == 1 then
                    --播放爆炸音效                    
                    local RAWorldMath = RARequire('RAWorldMath')
                    local firePos = RACcp(self.firePosX, self.firePosY)
                    local explode_video = 'bomb_explode'
                    if self.bombType == GuildManor_pb.WEATHER_STORM then
                        explode_video = 'bomb_storm_explode'
                    end
                    RAWorldMath:CheckAndPlayVideo(firePos, explode_video)

                    self.mIsBombing = true
                    self:_UnloadHandler(self.mAimHandler)
                    self:AddCCB(2, self.mBlastHandler, 4)  
                    MessageManager.sendMessage(MessageDef_World.MSG_NuclearBomb_Explode, {
                        bombType = self.bombType,
                        firePos = firePos
                        })  

                    -- 添加逻辑：2秒钟后显示辐射
                    local delayFunc = function()
                        self:AddCCB(1, self.mGroundHandler, 1) 
                        print('performWithDelay delayFunc:  add mGroundHandler')
                    end
                    performWithDelay(self.mGroundNode, delayFunc, BombAnimationEndTime)
                    print('add performWithDelay ............................')
                end
                self.mBombStatus = 2
            else
                self.mBombStatus = 3
                self.mIsUpdate = false
                local RATerritoryManager = RARequire('RATerritoryManager')
                RATerritoryManager:RemoveBombAreaByBombId(self.bombId)
            end

            if self.mCDHandler ~= nil then
                self:_UnloadHandler(self.mCDHandler)
                self.mCDHandler = nil
            end
        end
    end,

    -- 爆炸特效ccb动画播放完毕的回调方法
    -- 1、移除爆炸特效、移除选中特效
    -- 2、添加辐射
    OnBlastPlayComplete = function(self)
        print('OnBlastPlayComplete-----------OnBlastPlayComplete')        
        self:_UnloadHandler(self.mBlastHandler)        
        self.mIsBombing = false
    end,

    _UnloadHandler = function(self, handler)
        if handler ~= nil then
            handler:Unload()
        end
    end,

    Release = function(self)        
        self:_UnloadHandler(self.mAimHandler)
        self:_UnloadHandler(self.mBlastHandler)
        self:_UnloadHandler(self.mGroundHandler)
        self:_UnloadHandler(self.mCDHandler)
        if self.mGroundNode ~= nil then
            self.mGroundNode:removeFromParentAndCleanup(true)
            self.mGroundNode:release()
        end
        if self.mUINode ~= nil then
            self.mUINode:removeFromParentAndCleanup(true)
            self.mUINode:release()
        end

        self.bombId = nil
        self.mGroundNode = nil
        self.mUINode = nil        
        -- 目标ccb
        self.mAimHandler = nil
        -- 爆炸特效ccb
        self.mBlastHandler = nil
        -- 爆炸后持续效果ccb
        self.mGroundHandler = nil
        -- 倒计时
        self.mCDHandler = nil

        -- 炸弹爆炸状态，1未爆炸、2已爆炸（辐射中）、3辐射结束（需要移除）
        self.mBombStatus = -1
        -- 是否正在播放动画
        self.mIsBombing = false
        self.mIsUpdate = false
        self.explodeTime = 0
        self.disappearTime = 0


        self.firePosX = 0
        self.firePosY = 0
        --秒
        self.lastBombWarnTime = 0
    end,
}




function RABombEntityHelper:CreateBombEntity(bombId)
    local RATerritoryManager = RARequire('RATerritoryManager')
    local entity = RABombEntity:new() 
    if entity:Init(bombId) ~= nil then
        local uiLayer = RATerritoryManager:GetUILayer()
        if uiLayer ~= nil and entity:GetUINode() ~= nil then
            uiLayer:addChild(entity:GetUINode())
        end

        local groundLayer = RATerritoryManager:GetGroundLayer()
        if groundLayer ~= nil and entity:GetUINode() ~= nil then
            groundLayer:addChild(entity:GetGroundNode())
        end
        return entity
    end
    return nil
end

function RABombEntityHelper:CreateCDEntity(bombType)
    return RANuclearCDEntity:new({}, bombType)
end

return RABombEntityHelper