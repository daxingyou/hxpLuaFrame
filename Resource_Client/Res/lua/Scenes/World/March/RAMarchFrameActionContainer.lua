--RAMarchFrameActionContainer
-- 行军的序列帧显示，由多个个模型对象组合而成
-- 是大容器中的一个node里的模型队列（也可能只添加一个）

local common = RARequire('common')
local UIExtend = RARequire('UIExtend')
local RAMarchFrameActionDataHelper = RARequire('RAMarchFrameActionDataHelper')
local RAMarchFrameActionConfig = RARequire('RAMarchFrameActionConfig')
local RAMarchFrameActionSprite = RARequire('RAMarchFrameActionSprite')


local RAMarchFrameActionContainer = 
{
    New = function(self, o)
        local o = o or {}
        setmetatable(o,self)
        self.__index = self

        o.mFrameId = -1
        o.mDir = 0
        o.mFileNameDir = 0
        -- key = index, value = {RAMarchFrameActionSprite}
        o.mSpriteMap = {}
        return o
    end,

    -- 初始化序列帧数据，
    -- direction为0-15
    Init = function(self, frameId, direction, colorKey)                
        local frameData = RAMarchFrameActionDataHelper:GetFrameActionData(frameId)
        if frameData == nil then
            return false
        end
        self:Release()
        self.mFrameId = frameId
        self.mDir = direction
        self.mFileNameDir = RAMarchFrameActionConfig:GetDirForFileName(self.mDir)
        -- laod ccb
        local ccbfile = UIExtend.loadCCBFile(frameData.containerCCB, self)
        if ccbfile == nil then
            print('RAMarchFrameActionContainer Init error!! direction:'..direction.. ' frameId:'..frameId)
            return false
        end
        ccbfile:setAnchorPoint(0,0)
        local containerSize = CCSize(0, 0)
        ccbfile:setContentSize(containerSize)
        containerSize:delete()
        --播放特定时间轴
        local animationName = RAMarchFrameActionConfig.FrameCntCCBAniName..self.mDir
        ccbfile:runAnimation(animationName)

        -- 创建行军单个显示对象
        for i=1, frameData.containerCount do
            local cntNodeName = RAMarchFrameActionConfig.FrameCntCCBNodeName..i
            if ccbfile:hasVariable(cntNodeName) then
                local cntNode = UIExtend.getCCNodeFromCCB(ccbfile, cntNodeName)
                if cntNode ~= nil then
                    local actionSprite = RAMarchFrameActionSprite:New()
                    if actionSprite:Init(self.mFrameId, self.mDir, colorKey) then
                        cntNode:addChild(actionSprite:GetRootNode())
                        actionSprite:RunAction()
                        self.mSpriteMap[i] = actionSprite
                    end
                end
            end
        end
        return true
    end,

    GetRootNode = function(self)
        return self.ccbfile
    end,
    
    Release = function(self)        
        for k, oneSpr in pairs(self.mSpriteMap) do
            if oneSpr ~= nil then
                oneSpr:Release()
            end
            self.mSpriteMap[k] = nil
        end
        self.mSpriteMap = {}
        self.mFrameId = -1
        self.mDir = 0
        self.mFileNameDir = 0

        --移除自己
        UIExtend.unLoadCCBFile(self)
    end,
}


return RAMarchFrameActionContainer