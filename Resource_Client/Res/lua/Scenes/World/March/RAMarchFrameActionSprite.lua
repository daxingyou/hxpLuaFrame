--RAMarchFrameActionSprite
-- 行军的序列帧显示，单个模型对象


local common = RARequire('common')
local UIExtend = RARequire('UIExtend')
local RAMarchFrameActionDataHelper = RARequire('RAMarchFrameActionDataHelper')
local RAMarchFrameActionConfig = RARequire('RAMarchFrameActionConfig')


local RAMarchFrameActionSprite = 
{
    New = function(self)
        local o = {}
        setmetatable(o,self)
        self.__index = self

        o.mFrameId = -1
        o.mDir = 0
        o.mFileNameDir = 0
        -- key = index, value = {node = CCNode, sprite = CCSprite, action = CCAction}
        o.mPartMap = {}
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
        local ccbfile = UIExtend.loadCCBFile(frameData.partCCB, self)
        if ccbfile == nil then
            print('RAMarchFrameActionSprite Init error!! direction:'..direction.. ' frameId:'..frameId)
            return false
        end

        ccbfile:setAnchorPoint(0,0)
        local containerSize = CCSize(0, 0)
        ccbfile:setContentSize(containerSize)
        containerSize:delete()

        --播放特定时间轴
        local animationName = RAMarchFrameActionConfig.FramePartCCBAniName..self.mDir
        ccbfile:runAnimation(animationName)

        local oneDirData = frameData:GetFrameDirList()[self.mFileNameDir]
        if oneDirData ~= nil then
            -- 添加Plist和对应的color到CCSpriteFrameCache中
            if not common:addSpriteFramesWithFileMaskColor(frameData.plistName, colorKey) then
                print('RAMarchFrameActionSprite Init error--plist file not exist! direction:'..direction.. ' frameId:'..frameId)
                return false
            end

            -- 每个部位都需要添加到node里
            for i,partName in pairs(frameData:GetPartFileList()) do
                local partNodeName = RAMarchFrameActionConfig.FramePartCCBNodeName..i
                if ccbfile:hasVariable(partNodeName) then
                    local partNode = UIExtend.getCCNodeFromCCB(ccbfile, partNodeName)
                    if partNode ~= nil then
                        --尝试性移除所有显示对象
                        partNode:removeAllChildren()
                        local onePartData = {}
                        onePartData.node = partNode
                        onePartData.sprite = CCSprite:create()                        
                        onePartData.sprite:retain()
                        -- onePartData.sprite:setUseMaskColor(true)
                        onePartData.sprite:setMaskColor(CCTextureCache:sharedTextureCache():getColorByName(colorKey))
                        onePartData.sprite:setAnchorPoint(0.5,0.5)
                        -- 每个部位都需要创建sprite和序列帧动画
                        local isInitFirst = false
                        local frameArray = CCArray:create()
                        for frameIndex=1,#oneDirData.frames do
                            local frameValue = oneDirData.frames[frameIndex]
                            local frameFileName = partName..'_'..self.mFileNameDir..'_'..frameValue..'.png'                            
                            local pSpriteFrame = CCSpriteFrameCache:sharedSpriteFrameCache():spriteFrameByName(frameFileName, colorKey)
                            if pSpriteFrame ~= nil then
                                if not isInitFirst then
                                    onePartData.sprite:setDisplayFrame(pSpriteFrame)
                                    isInitFirst = true
                                end
                                frameArray:addObject(pSpriteFrame)
                            else
                                print('RAMarchFrameActionSprite frame file not exist:'..frameFileName)
                            end
                            -- print('RAMarchFrameActionSprite  add frame to action, index:'..frameIndex..'  frame name:'..frameFileName)
                        end
                        local fps = oneDirData.fps or 1
                        local pAnimation = CCAnimation:createWithSpriteFrames(frameArray, 1/fps)
                        local animate = CCAnimate:create(pAnimation)
                        local pRepeatForever = CCRepeatForever:create(animate)
                        pRepeatForever:retain()
                        onePartData.action = pRepeatForever    
                        self.mPartMap[i] = onePartData
                    end
                end
            end
            return true   
        end
        return false
    end,

    RunAction = function(self)
        for k, onePartData in pairs(self.mPartMap) do
            if onePartData.node ~= nil then
                --尝试性移除所有显示对象
                onePartData.node:removeAllChildren()       
                if onePartData.sprite ~= nil and onePartData.action ~= nil then
                    onePartData.node:addChild(onePartData.sprite)
                    onePartData.sprite:runAction(onePartData.action)
                end
            end
        end
    end,

    GetRootNode = function(self)
        return self.ccbfile
    end,

    _ReleaseOnePartData = function(self, onePartData)
        if onePartData.node ~= nil  and onePartData.action ~= nil then
            onePartData.node:removeAllChildren()                
        end
        if onePartData.sprite ~= nil then
            onePartData.sprite:release()
        end
        if onePartData.action ~= nil then
            onePartData.action:release()
        end
    end,

    _ReleaseAllPartsData = function(self)
        if self.mPartMap ~= nil then
            for k, onePartData in pairs(self.mPartMap) do
                self:_ReleaseOnePartData(onePartData)
                self.mPartMap[k] = nil
            end
        end
    end,
    
    Release = function(self)
        self:_ReleaseAllPartsData()
        self.mPartMap = {}
        self.mFrameId = -1
        self.mDir = 0
        self.mFileNameDir = 0

        --移除自己
        UIExtend.unLoadCCBFile(self)
    end,
}


return RAMarchFrameActionSprite