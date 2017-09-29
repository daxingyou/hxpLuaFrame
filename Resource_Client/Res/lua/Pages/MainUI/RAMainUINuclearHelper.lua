-- RAMainUINuclearHelper
-- 处理单个炸弹显示逻辑

local RAMainUINuclearHelper = {}

local UIExtend = RARequire('UIExtend')
local RAWorldMath = RARequire('RAWorldMath')
local common = RARequire('common')
local Utilitys = RARequire('Utilitys')
local EnterFrameDefine = RARequire("EnterFrameDefine")

-- 倒计时显示的ccb
local RAMainUINuclearCDEntity = {
    new = function(self, o)
        o = o or {}
        setmetatable(o,self)
        self.__index = self    
        o.mCD = nil                        
        o.mPos = nil
        o.mUnderLine = nil

        o.bombId = nil
        o.explodeTime = 0
        o.disappearTime = 0
        o.firePosX = 0
        o.firePosY = 0

        o.isUpdate = true
        return o
    end,

    GetCCBName = function(self)
        return 'RAMainUINuclearCDNodeNew.ccbi'
    end,

    GetCCBFile = function(self)
        return self.ccbfile
    end,

    SetCCBFileVisible = function(self, value)
        if self.ccbfile then
            self.ccbfile:setVisible(value)
        end
        self.isUpdate = value
    end,

    GetBombId = function(self)
        return self.bombId
    end,

    Init = function(self)
        local ccbfile = UIExtend.loadCCBFile(self:GetCCBName(), self)
        self.mCD = UIExtend.getCCLabelTTFFromCCB(ccbfile, 'mCD')
        self.mPos = UIExtend.getCCLabelTTFFromCCB(ccbfile, 'mPos')
        self.mUnderLine = UIExtend.getCCLayerFromCCB(ccbfile, 'mUnderLine')
        self.isOpen = true

        -- 默认隐藏文字
        UIExtend.setNodeVisible(ccbfile, 'mCD', false)
        UIExtend.setNodeVisible(ccbfile, 'mPos', false)
        UIExtend.setNodeVisible(ccbfile, 'mUnderLine', false)        
        ccbfile:setVisible(false)
    end,

    UpdateByBombId = function(self, bombId)
        local ccbfile = self.ccbfile
        local RATerritoryDataManager = RARequire('RATerritoryDataManager')
        local bombData = RATerritoryDataManager:GetBombDataById(bombId)
        if bombData == nil then return false end
        self.bombId = bombId
        self.bombType = bombData.nuclearType
        local currTime = common:getCurTime()
        local lastTime = math.floor(bombData.explodeTime / 1000 - currTime)
        -- 爆炸时间小于当前时间的时候，就已经爆炸了，不能再显示
        if lastTime <= 0 then return false end

        ccbfile:setVisible(true)
        self.explodeTime = bombData.explodeTime
        self.disappearTime = bombData.disappearTime
        self.firePosX = bombData.firePosX
        self.firePosY = bombData.firePosY        
        self:UpdateCommonUI(self.firePosX, self.firePosY)
        self:UpdateShowTime(lastTime)

        --不同爆炸类型使用不同图标
        local isNuclear = (self.bombType == GuildManor_pb.NUCLRAR_WARHEAD)
        UIExtend.setNodeVisible(self.ccbfile, "mStormIcon", not isNuclear)
        UIExtend.setNodeVisible(self.ccbfile, "mNuclearIcon", isNuclear)

        return true
    end,

    SecondUpdate = function(self)
        if not self.isUpdate then return end
        local currTime = common:getCurTime()
        local lastTime = math.floor(self.explodeTime / 1000 - currTime)
        if lastTime < 0 then
            -- if self.ccbfile then
            --     self.ccbfile:setVisible(false)
            -- end
            self:SetCCBFileVisible(false)
            MessageManager.sendMessage(MessageDef_MainUI.MSG_UpdateMainUINuclearPart)
            return
        end
        self:UpdateShowTime(lastTime)
    end,

    UpdateCommonUI = function(self, x, y)
        local ccbfile = self.ccbfile
        if self.mPos ~= nil and self.mUnderLine ~= nil then     
            self.mPos:setString(_RALang('@MainNuclearPos', x, y))
            local size = self.mPos:getContentSize()
            local sizeLine = self.mUnderLine:getContentSize()
            self.mUnderLine:setContentSize(size.width, sizeLine.height)          
            UIExtend.setNodeVisible(ccbfile, 'mPos', true)
            UIExtend.setNodeVisible(ccbfile, 'mUnderLine', true)
        end
    end,

    UpdateShowTime = function(self, lastTime)
        local ccbfile = self.ccbfile
        if self.mCD ~= nil and ccbfile ~= nil then
            UIExtend.setNodeVisible(ccbfile, 'mCD', lastTime > 0)                
            -- local tmpStr = Utilitys.createTimeWithFormat(lastTime)
            local strKey = '@MainNuclear'
            local GuildManor_pb = RARequire('GuildManor_pb')
            if self.bombType == GuildManor_pb.WEATHER_STORM then 
                strKey = '@MainStorm'
            end 
            self.mCD:setString(_RALang(strKey, math.floor(lastTime)))
        end
    end,

    onCheckBtn = function(self)
        print("onCheckBtn  x:".. self.firePosX.. "  y:".. self.firePosY)
        if self.bombId == nil then return end

        local posX = self.firePosX or 0 
        local posY = self.firePosY or 0 
        local RAWorldManager = RARequire('RAWorldManager')
        RAWorldManager:LocateAt(posX, posY)
    end,

    --[[
        desc: 点击按钮可以收缩
    ]]--
    onOpenBtn = function(self)
        if self.isOpen then
            self.ccbfile:runAnimation("OutAni")
            self.isOpen = false
        else
            self.ccbfile:runAnimation("InAni")
            self.isOpen = true
        end
    end,

    Unload = function(self)
        self.mCD = nil
        self.mCD = nil                        
        self.mPos = nil
        self.mUnderLine = nil

        self.bombId = nil
        self.explodeTime = 0
        self.disappearTime = 0
        self.firePosX = 0
        self.firePosY = 0
        -- self.mLastUpdateTime = 0
        UIExtend.unLoadCCBFile(self)
    end,

    OnAnimationDone = function(self, ccbfile)
        local lastAnimationName = ccbfile:getCompletedAnimationName()
        -- if lastAnimationName == 'Keep' then 
        --     print('RABombGroundEntity  OnAnimationDone: need to remove ccb')
        -- end
    end,
}



local OnReceiveMessage = function(message)    
    CCLuaLog("RAMainUINuclearHelper OnReceiveMessage id:"..message.messageID)

    -- open or close RAChooseBuildPage page
    if message.messageID == MessageDef_MainUI.MSG_UpdateMainUINuclearPart then
        CCLuaLog("MessageDef_MainUI MSG_UpdateMainUINuclearPart")
        RAMainUINuclearHelper:RefreshNuclear()
        return
    end
end

function RAMainUINuclearHelper:registerMessageHandlers()
    MessageManager.registerMessageHandler(MessageDef_MainUI.MSG_UpdateMainUINuclearPart, OnReceiveMessage)
end

function RAMainUINuclearHelper:unregisterMessageHandlers()
    MessageManager.removeMessageHandler(MessageDef_MainUI.MSG_UpdateMainUINuclearPart, OnReceiveMessage)
end


function RAMainUINuclearHelper:resetData(isClear)
    if self.mNuclearEntity ~= nil then
        self.mNuclearEntity:Unload()
    end
    self.mNuclearEntity = nil
    self.mLastUpdateTime = 0
    self.mNuclearCDNode = nil    
end


function RAMainUINuclearHelper:Enter(data)
    EnterFrameMananger.registerEnterFrameHandler(EnterFrameDefine.MainUI.EF_NuclearHelperUpdate, self)
    self:registerMessageHandlers()
    self.mNuclearEntity = nil
    self.mLastUpdateTime = 0

    if data ~= nil then
        self.mNuclearCDNode = data.nuclearCDNode
    end
    --刷ccb
    self.mNuclearEntity = RAMainUINuclearCDEntity:new()
    self.mNuclearEntity:Init()    
    local ccbfile = self.mNuclearEntity:GetCCBFile()
    self.mNuclearCDNode:addChild(ccbfile)

    -- 进入的时候先刷新一个
    self:RefreshNuclear()
end

function RAMainUINuclearHelper:EnterFrame()
    -- CCLuaLog("RAMainUINuclearHelper:EnterFrame")
    if self.mNuclearEntity ~= nil then
        self.mLastUpdateTime = self.mLastUpdateTime + common:getFrameTime()
        if self.mLastUpdateTime > 0.3 then
            self.mLastUpdateTime = 0
            self.mNuclearEntity:SecondUpdate()            
        end
    end
end

function RAMainUINuclearHelper:RefreshNuclear()
    if self.mNuclearCDNode == nil then return end
    local RATerritoryDataManager = RARequire('RATerritoryDataManager')
    local bombDatas = RATerritoryDataManager:GetAllBombsData()
    local bombId = nil
    local lastTime = -1
    local currTime = common:getCurTime()

    local result = false

    for id, bombData in pairs(bombDatas) do
        local currLastTime = math.floor(bombData.explodeTime / 1000 - currTime)
        if currLastTime > 0 then
            if bombId == nil or lastTime <= 0 then
                bombId = id
                lastTime = currLastTime
            else
                -- 寻找最快要爆炸的核弹
                if currLastTime < lastTime then
                    bombId = id
                    lastTime = currLastTime
                end
            end
        end
    end

    -- 有可以刷新的就标记为true，但是最后刷新的结果不一定为true
    if bombId ~= nil and lastTime > 0 then
        result = true        
        result =  self.mNuclearEntity:UpdateByBombId(bombId)
        self.mNuclearEntity:SetCCBFileVisible(result)
    else
        --没有可以刷新的，就去移除ccb，然后结束就好了
        self.mNuclearEntity:SetCCBFileVisible(false)
        return
    end
    
    -- 如果失败了重新来一次
    if not result then        
        self:RefreshNuclear()
    end
end


function RAMainUINuclearHelper:Exit()
    CCLuaLog("RAMainUINuclearHelper:Exit")
    self:unregisterMessageHandlers()
    EnterFrameMananger.removeEnterFrameHandler(EnterFrameDefine.MainUI.EF_NuclearHelperUpdate, self)
    self:resetData(true)
end

return RAMainUINuclearHelper