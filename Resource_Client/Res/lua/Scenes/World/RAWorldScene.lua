--region RAWorldScene.lua
--Date

local UIExtend = RARequire('UIExtend')
local RAWorldMap = RARequire('RAWorldMap')
local RAWorldMath = RARequire('RAWorldMath')
local RAWorldConfig = RARequire('RAWorldConfig')
local RAWorldVar = RARequire('RAWorldVar')
local RAWorldTouchHandler = RARequire('RAWorldTouchHandler')
local RAWorldBuildingManager = RARequire('RAWorldBuildingManager')
local RAMarchManager = RARequire('RAMarchManager')
local RAWorldUIManager = RARequire('RAWorldUIManager')
local RABattleManager = RARequire('RABattleManager')
local RAWorldGuideManager = RARequire('RAWorldGuideManager')
local RAWorldMistManager = RARequire('RAWorldMistManager')
local RATerritoryManager = RARequire('RATerritoryManager')
local RARootManager = RARequire("RARootManager")
local RAGuideManager = RARequire('RAGuideManager')

RAWorldScene = BaseFunctionPage:new(...)

RAWorldScene.RootNode = nil
RAWorldScene.MapNode = nil
RAWorldScene.RefNode = nil
RAWorldScene.Helper = nil
RAWorldScene.Layers = {}
RAWorldScene.scale = RAWorldConfig.MapScale_Fade

local battleMusicLoopTag = false

-- 按层级顺序排列
local LayerNames =
{   
    -- 建筑之下
    'GROUND',
    -- 建筑
    'BUILDING',
    -- 点击
    'SINGLE_TOUCH',
    -- 缩放
    'MULTI_TOUCH',
    -- 特效
    'EFFECT',
    -- 行军
    'MARCH',
    -- UI
    'UI',
    -- GUIDE
    'GUIDE'
}
local LayerZorder_Base = RAWorldConfig.Zorder_BaseLayer


function RAWorldScene:Enter(param)
    self:_resetData()
    self:_initVars()
    
    self.Helper:Enter()
    
    self:_initNode()


    RAWorldVar:UpdateSelfViewPos()
    RATerritoryManager:Init(self.Layers['GROUND'], self.Layers['UI'])
    RAWorldBuildingManager:Init(self.Layers['BUILDING'])
    RAMarchManager:Init(self.Layers['MARCH'])
    RABattleManager:Init(self.Layers['MARCH'])
    RAWorldUIManager:Init(self.Layers['UI'])
    RAWorldGuideManager:Init(self, self.Layers['GUIDE'])
    RAWorldMistManager:Init(self.Layers['EFFECT'])

    -- 计算是否需要设置初始坐标
    local RAScenesMananger = RARequire('RAScenesMananger')    
    local cmdData = RAScenesMananger.GetWorldLocateCmdData()
    RAScenesMananger.RemoveWorldSceneCmd()
    if cmdData ~= nil then
        if cmdData.x ~= nil and cmdData.y ~= nil then
            RAWorldVar.MapPos.Map = RACcp(cmdData.x, cmdData.y)
        end

        if cmdData.marchId ~= nil then
            RAWorldVar.MapPos.Map = RAMarchManager:GetMarchMoveEntityTilePos(cmdData.marchId)
        end

        if cmdData.taskType ~= nil then
            RAWorldVar.TargetInfo = cmdData
        end

        if cmdData.hudBtn ~= nil then
            local RAWorldHudManager = RARequire('RAWorldHudManager')
            RAWorldHudManager:TriggerHudBtn(RAWorldVar.MapPos.Map, cmdData.hudBtn)
        end
    end

    self:GotoTileAtPoint(RAWorldVar.MapPos.Map, true)
    RAWorldMap:UpdateRefPos()

    --城外背景音乐 by cph
    SoundManager:getInstance():stopAllEffect()
    local battleMusicSingleton = VaribleManager:getInstance():getSetting("BattleMusic_1")
    SoundManager:getInstance():playMusic(battleMusicSingleton,false)
    battleMusicLoopTag = true

    if RAGuideManager.isInGuide() then
        RARootManager.AddCoverPage()
        RAGuideManager.gotoNextStep()
    else
        RARootManager.RemoveGuidePage()
        RARootManager.RemoveCoverPage()
    end
    if param then
        if param.pages then
            for i,page in ipairs(param.pages) do
                RARootManager.OpenPage(page.pageName, page.pageArg, page.isUpdate,page.needNotToucherLayer, page.isBlankClose,page.swallowTouch)
            end
        end
    end
end

function RAWorldScene:Execute()
    RAWorldTouchHandler.onScrolling()
    RAWorldMap:Execute()
    RAWorldBuildingManager:Execute()
    RAWorldUIManager:Execute()
    RAMarchManager:Execute()
    RABattleManager:Execute()
    RAWorldGuideManager:Execute()
    RATerritoryManager:Execute()

    if battleMusicLoopTag then
        local isBgMusicPlaying = SoundManager:getInstance():isBackgroundMusicPlaying()
        if not isBgMusicPlaying then
            --local isRunningForeground = RAPlatformUtils:getRunningForeground()
            local battleMusicLoop = VaribleManager:getInstance():getSetting("BattleMusic_2")
            SoundManager:getInstance():playMusic(battleMusicLoop,true)
            battleMusicLoopTag = false
        end
    end
end

function RAWorldScene:Exit()
    RAWorldMap:Exit()
    self.Helper:Exit()
    
    RAWorldBuildingManager:Clear()
    RAMarchManager:Clear()
    RAWorldUIManager:Clear()
    RABattleManager:Clear()
    RAWorldGuideManager:Clear()
    RATerritoryManager:Clear()
    RAWorldTouchHandler:reset()
    RAWorldMistManager:Clear()

    self.ccbfile:stopAllActions()
    self.ccbfile:removeAllChildren()
    UIExtend.unLoadCCBFile(self)
    self:_resetData()
end

function RAWorldScene:GetScale()
    return self.scale
end

function RAWorldScene:SetScale(scale)
    if self.RootNode then
        self.RootNode:setScale(scale)
        RAWorldMap:SetScale(scale)
    end
    self.scale = scale
end

function RAWorldScene:HideLayer4Guide()
    for _, v in ipairs(LayerNames) do
        self.Layers[v]:setVisible(v == 'GUIDE' or v == 'SINGLE_TOUCH')
    end
end

function RAWorldScene:RestoreAllLayers()
    for _, v in ipairs(LayerNames) do
        self.Layers[v]:setVisible(v ~= 'GUIDE')
    end
end

function RAWorldScene:SetTouchEnabled(enabled)
    self.Layers['SINGLE_TOUCH']:setTouchEnabled(enabled)
    self.Layers['MULTI_TOUCH']:setTouchEnabled(enabled)
end

function RAWorldScene:_resetData()
    self.RootNode = nil
    self.MapNode = nil
    self.RefNode = nil
    self.TileMap = nil
    self.Helper = nil
    self.Layers = {}
    battleMusicLoopTag = false
end

function RAWorldScene:_initVars()
    RAWorldVar:InitMap()

    local RAWorldHelper = RARequire('RAWorldHelper')
    self.Helper = RAWorldHelper:new()    
end

function RAWorldScene:_initNode()
    --modify by zhenhui, use loadccbfie with out pool
    self.RootNode = UIExtend.loadCCBFileWithOutPool('RAWorldScene.ccbi', self)
    self.RootNode:setPosition(0, 0)
    self:SetScale(self.scale)
    
    CCCamera:setPerspectiveCameraParam(RAWorldConfig.Camera_PerspectiveParam)
    CCCamera:setPerspectiveCameraMatrix()
    CCCamera:setPerspectiveRootNode(self.RootNode)

    self:_loadTileMap()
    self:_initLayers()
    RAWorldVar:InitBankVar()
end

function RAWorldScene:_initLayers( ... )
    for i, name in ipairs(LayerNames) do
        local layer = CCLayer:create()
        self.MapNode:addChild(layer, LayerZorder_Base + i)
        self.Layers[name] = layer
    end

    if RAGuideManager.isInGuide() and (not RAGuideManager.canShowWorld()) then
        self:HideLayer4Guide()
    end

    self:_initSingleTouchLayer()
    self:_initMultiTouchLayer()
    RAWorldTouchHandler:reset()
end

function RAWorldScene:_loadTileMap()
    local mapNode, refNode = RAWorldMap:Load(RAWorldConfig.tmxFile, RAWorldVar.MapPos.Map)
    if mapNode then
        self.RootNode:addChild(mapNode)
        self.MapNode = mapNode
        self.RefNode = refNode
    else
        CCLuaLog('Error:    load world tile map fail')
    end
end

function RAWorldScene:_initSingleTouchLayer()
    local layer = self.Layers['SINGLE_TOUCH']
    layer:setContentSize(CCDirector:sharedDirector():getWinSize())
    layer:setAnchorPoint(0, 0)
    layer:setTouchEnabled(true)
    layer:setKeypadEnabled(true)
    layer:setTouchMode(kCCTouchesOneByOne)
    layer:registerScriptTouchHandler(RAWorldTouchHandler.onSingleTouch)
end

function RAWorldScene:_initMultiTouchLayer()
    local layer = self.Layers['MULTI_TOUCH']
    layer:setContentSize(CCDirector:sharedDirector():getWinSize())
    layer:setAnchorPoint(0, 0)
    layer:setTouchEnabled(true)
    layer:setKeypadEnabled(true)
    layer:setTouchMode(kCCTouchesAllAtOnce)
    layer:registerScriptTouchHandler(RAWorldTouchHandler.onMultiTouch, true, 1, false)
end

function RAWorldScene:GotoTileAtPoint(mapPos, forceUpdate)
    RAWorldMap:GotoTileAt(mapPos, forceUpdate)

    self:ShowPosition()
end

function RAWorldScene:GotoViewAt(viewPos)
    RAWorldMap:GotoViewAt(viewPos)

    self:ShowPosition()
end

function RAWorldScene:OffsetMap(offset, speed)
    RAWorldVar:UpdateMoveSpeed(speed)
    RAWorldMap:OffsetMap(offset)
    self:ShowPosition()
end

function RAWorldScene:ShowPosition()
    MessageManager.sendMessage(MessageDef_MainUI.MSG_UpdateWorldCoordinate, {
        x = RAWorldVar.MapPos.Map.x,
        y = RAWorldVar.MapPos.Map.y,
        k = (RAWorldVar.KingdomId.Map ~= RAWorldVar.KingdomId.Self) and RAWorldVar.KingdomId.Map or nil
    })
end

--endregion