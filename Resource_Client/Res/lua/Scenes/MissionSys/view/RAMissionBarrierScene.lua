-- RAMissionBarierScene.lua
-- Author: xinghui
-- Using: 关卡场景

RARequire("BasePage")
local UIExtend                      = RARequire("UIExtend")
local RAMissionHelper               = RARequire("RAMissionHelper")
local RAMissionVar                  = RARequire("RAMissionVar")
local fragment_conf                 = RARequire("fragment_conf")
local Utilitys                      = RARequire("Utilitys")
local RAMissionBarrierManager       = RARequire("RAMissionBarrierManager")
local RAMissionBarrierTouchHandler  = RARequire("RAMissionBarrierTouchHandler")
local RAMissionConfig               = RARequire("RAMissionConfig")
local barrier_conf                  = RARequire("barrier_conf")

local RAMissionBarierScene          = BaseFunctionPage:new(...)

RAMissionBarierScene.rootNode       = nil               --场景根节点
RAMissionBarierScene.armyCcb        = nil               --士兵ccb
RAMissionBarierScene.helper         = nil
RAMissionBarierScene.layers         = {}                --场景层数组

RAMissionBarierScene.mCamera        = nil               --摄像机

local layerNames = {                                    --层级名字：army下层，army层
    "UnderArmy",
    "Army",
    "BeyondArmy"
}

--[[
    desc: 场景的入口函数
    @param data:场景参数
]]
function RAMissionBarierScene:Enter(data)
    self:_resetData()

    --剧情背景音乐 by cph
    local cityMusicSingleton = VaribleManager:getInstance():getSetting("cityMusic_1")
    SoundManager:getInstance():playMusic(cityMusicSingleton,true)

    self:_initNode()

    self:_initHelper()

    self:focusCamera()

    RAMissionBarrierManager:gotoNextStep()
end

--[[
    desc: 初始化场景资源
]]
function RAMissionBarierScene:_initNode()
    local fragmentId = RAMissionVar:getFragmentId()
    local constFragmentInfo = fragment_conf[fragmentId]
    if constFragmentInfo then
        self.rootNode = UIExtend.loadCCBFileWithOutPool(constFragmentInfo.mapRes, self)
        RAMissionVar:addCCBOwner(constFragmentInfo.mapRes, self)

        --设置摄像机
        self.mCamera = SceneCamera:create()
        self.mCamera:registerFunctionHandler(self)

        local arr = Utilitys.Split(constFragmentInfo.rect, "_")
        local size = CCSizeMake(tonumber(arr[1]), tonumber(arr[2]))
        self.mCamera:setSize(size)

        self.mCamera:setMinOffsetY(0)
        self.mCamera:setMinOffsetX(0)
        self.mCamera:setMaxOffsetY(0)
        self.mCamera:setMaxOffsetX(0)

        RAMissionBarrierManager:setCamera(self.mCamera)
        self.rootNode:setCamera(self.mCamera)

        self:_initLayers()

        self:_initArmyNode()
    end
end

--[[
    desc: 初始化层
]]
function RAMissionBarierScene:_initLayers()
    for i, layerName in ipairs(layerNames) do
        local layer = CCLayer:create()
        self.rootNode:addChild(layer, 10000 + i)
        self.layers[layerName] = layer
    end
end

--[[
    desc: 设置士兵层
]]
function RAMissionBarierScene:_initArmyNode()
    local barrierId = RAMissionVar:getBarrierId()
    local constBarrierInfo = barrier_conf[barrierId]
    if constBarrierInfo.armyRes then
        self.armyCcb = UIExtend.loadCCBFileWithOutPool(constBarrierInfo.armyRes, RAMissionBarrierTouchHandler.armyCCBHandler)
        RAMissionVar:addCCBOwner(constBarrierInfo.armyRes, RAMissionBarrierTouchHandler.armyCCBHandler)
        --RAGameUtils:setChildMenu(self.rootNode, CCRectMake(0, 0, 3584, 2304))
        self.layers["Army"]:addChild(self.armyCcb)
    end
end

--[[
    desc: 获得barrierScene最上层的layer
]]
function RAMissionBarierScene:getTopLayer()
    return self.layers["BeyondArmy"]
end

--[[
    desc: 改变士兵ccb
]]
function RAMissionBarierScene:changeArmyNode()
    if self.armyCcb then
        local ccbName = self.armyCcb:getCCBFileName()
        RAMissionVar:deleteCCBOwner(ccbName)
        UIExtend.unLoadCCBFile(RAMissionBarrierTouchHandler.armyCCBHandler)
        self.armyCcb = nil
    end
    self:_initArmyNode()
end

--[[
    desc: 
]]
function RAMissionBarierScene:focusCamera()
    --关卡摄像机的起始位置，这里对于起始关卡来说是会变动的
    local barrierId = RAMissionVar:getBarrierId()
    local constBarrierInfo = barrier_conf[barrierId]
    local startCameraPos = ccp(1024, 1024)
    --场景第一次进来寻找焦点
    if constBarrierInfo then
        local focusNodeName = constBarrierInfo.forcusNode
        local focusNode = UIExtend.getCCNodeFromCCB(self.rootNode, focusNodeName)
        if focusNode then
            startCameraPos.x, startCameraPos.y = focusNode:getPosition()
            startCameraPos = focusNode:getParent():convertToWorldSpace(startCameraPos)
        end
    end
    self.mCamera:setScale(RAMissionConfig.CameraInfo.OriScale, 0.0)
    self.mCamera:lookAt(startCameraPos,0.0,false)

    local callback = function ()
        self.mCamera:setScale(RAMissionConfig.CameraInfo.FinalScale, 0.8)
        self.mCamera:lookAt(startCameraPos,0.8,true)
    end
    performWithDelay(self.rootNode,callback,0.1)
end

--[[
    desc: 初始化helper
]]
function RAMissionBarierScene:_initHelper()
    self.helper = RAMissionHelper:new()
end

--[[
    desc: 场景摄像机移动结束
]]
function RAMissionBarierScene:onMovingFinish()
    MessageManager.sendMessage(MessageDef_MissionBarrier.MSG_CameraMoveEnd)
end

--[[
    desc: 重置数据
]]
function RAMissionBarierScene:_resetData()
    self.rootNode = nil
    self.helper = nil
    self.layers = {}
    if self.mCamera then
        self.mCamera:unregisterFunctionHandler()
        self.mCamera = nil
    end
end

--[[
    desc: 每帧调用函数
]]
function RAMissionBarierScene:Execute()
    RAMissionVar:update()
end

--[[
    desc: 离开scene
]]
function RAMissionBarierScene:Exit(data)

    if self.mCamera then
        self.mCamera:unregisterFunctionHandler()
        self.mCamera = nil
    end

    if self.armyCcb then
        UIExtend.unLoadCCBFile(RAMissionBarrierTouchHandler.armyCCBHandler)
        self.armyCcb = nil
    end

    for _, layer in pairs(self.layers) do
        layer:removeFromParentAndCleanup(true)
    end
    self.layers = {}

    RAMissionBarrierManager:setIsInBarrier(false)

    self.ccbfile:stopAllActions()
    UIExtend.unLoadCCBFile(self)

    self.rootNode = nil

    self:_resetData()
end

return RAMissionBarierScene