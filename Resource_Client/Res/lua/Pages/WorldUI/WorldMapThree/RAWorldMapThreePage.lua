--region *.lua
--Date
--此文件由[BabeLua]插件自动生成
-- by zhenhui
local RAWorldMapThreePage = BaseFunctionPage:new(...,{
    mMapRootNode = nil,--map and kingdom node
    mCamera = nil,
    mMultiTouchLayer = nil,
    mapHandler = {},
    kingdomHandlers = {}
})
local UIExtend = RARequire("UIExtend")
local common = RARequire("common")
local RAWorldUtil = RARequire("RAWorldUtil")
local RARootManager = RARequire("RARootManager")
local RAWorldMapThreeConfig = RARequire("RAWorldMapThreeConfig")
local RAWorldMapThreeUtil = RARequire("RAWorldMapThreeUtil")
local RAWorldMapThreeMap = RARequire("RAWorldMapThreeMap")
local RAWorldMapThreeManager = RARequire("RAWorldMapThreeManager")
local RAKingdomCell = RARequire("RAKingdomCell")
local RAWorldMapThreeTouch = RARequire("RAWorldMapThreeTouch")

function RAWorldMapThreePage:Enter(data)
    local ccbfile = UIExtend.loadCCBFile("RAWorldMapThreePage.ccbi",self)
    RAWorldMapThreeManager:initMapThreeData()
    self.mMapRootNode = ccbfile:getCCNodeFromCCB("mMapNode")
    self:_initTitle()
    self:_initMap()
    self:_initCamera()
    self:_initKingdom()
    self:_initTouchLayer()

    --set the initial scale and pos

    local cameraPos = RAWorldMapThreeManager.cameraCentralPos
    self.mCamera:setScale(RAWorldMapThreeConfig.cameraInfo.normalScale, 0.0)
    self.mCamera:lookAt(cameraPos,0.0,false)
    cameraPos:delete()
    --Enter 屏蔽掉主城的touch 事件,Exit的时候打开
    RACityMultiLayerTouch.setEnabled(false)

end

function RAWorldMapThreePage:_initCamera()
    self.mCamera = SceneCamera:create()
    self.mCamera:setSize(RAWorldMapThreeManager.cameraSize)
    self.mCamera:setMinScale(RAWorldMapThreeConfig.cameraInfo.minScale)
    self.mCamera:setMaxScale(RAWorldMapThreeConfig.cameraInfo.maxScale)
    self.mMapRootNode:setCamera(self.mCamera)
    RAWorldMapThreeManager.mCamera = self.mCamera

end

function RAWorldMapThreePage:_initMap()
    self.mapHandler = {}
    self.mLayoutNode = CCNode:create()
    self.mMapRootNode:removeChildByTag(10010,true)
    --set the position offset
    self.mLayoutNode:setPosition(-RAWorldMapThreeManager.mapOffset.x,-RAWorldMapThreeManager.mapOffset.y)
    self.mLayoutNode:setTag(10010)
    self.mMapRootNode:addChild(self.mLayoutNode)
    local index = 1
--    for i = 0,2,1 do 
--        for k = 0,2,1 do
            local mapHandler = RAWorldMapThreeMap:new()
            local pos = RACcp(0,0)
            local mapCCB = UIExtend.loadCCBFile("RAWorldMapThreeScene.ccbi",mapHandler)
            mapCCB:setPosition(pos.x,pos.y)
            self.mLayoutNode:addChild(mapCCB)
            self.mapHandler = mapHandler
--            index = index + 1
--        end
--    end
end

function RAWorldMapThreePage:_initKingdom()
    self.kingdomHandlers = {}
    math.randomseed(RAWorldMapThreeConfig.randomSeed)
    for i = 1,#RAWorldMapThreeManager.kingdomList,1  do
        local value = RAWorldMapThreeManager.kingdomList[i]
        if value ~= nil and value.serverId ~= nil  then
            local param = {
                data = value
            }
            
            local handler = RAKingdomCell:new(param)
            local kingdomccb = UIExtend.loadCCBFile("RAWorldMapThreeCell.ccbi",handler)
            handler:Enter()
            local serverNum = RAWorldUtil.kingdomId.tonumber(value.serverId)
            local serverNode = self.mapHandler.ccbfile:getCCNodeFromCCB("mS"..serverNum)
            serverNode:addChild(kingdomccb)
            self.kingdomHandlers[value.serverId] = handler
--            local onePos = RAWorldMapThreeUtil:serverId2PixelPos(tonumber(value.serverId),RAWorldMapThreeManager.kingdomCenterPos)
--            local randomX = math.random(-RAWorldMapThreeConfig.randomOffset,RAWorldMapThreeConfig.randomOffset)
--            local randomY = math.random(-RAWorldMapThreeConfig.randomOffset,RAWorldMapThreeConfig.randomOffset)
--            onePos.x = onePos.x + randomX
--            onePos.y = onePos.y + randomY
--            kingdomccb:setPosition(onePos.x,onePos.y)
--            self.mLayoutNode:addChild(kingdomccb)
        end
    end

    RAGameUtils:setChildMenu( self.mMapRootNode,RAWorldMapThreeConfig.mapRect )
end

function RAWorldMapThreePage:_initTouchLayer()

    self.mMultiTouchLayer = CCLayer:create()
    self.mMultiTouchLayer:setContentSize(CCDirector:sharedDirector():getOpenGLView():getVisibleSize())
    self.mMultiTouchLayer:setPosition(0, 0)
    self.mMultiTouchLayer:setAnchorPoint(ccp(0, 0))
    self.mMultiTouchLayer:setTouchEnabled(false)
    self.mMultiTouchLayer:setKeypadEnabled(true)
    self.mMultiTouchLayer:setTouchMode(kCCTouchesAllAtOnce)
    self.ccbfile:addChild(self.mMultiTouchLayer,-100)
    self.mMultiTouchLayer:registerScriptTouchHandler(RAWorldMapThreeTouch.LayerTouches,true, 1 ,true)
    RAWorldMapThreeManager.mMultiTouchLayer = self.mMultiTouchLayer
    RAWorldMapThreeTouch.setEnabled(true)
    
end

function RAWorldMapThreePage:_initTitle()
    local titleCCB = UIExtend.getCCBFileFromCCB(self.ccbfile, "mCommonTitleCCB")
	local RACommonTitleHelper = RARequire('RACommonTitleHelper')
	local backCallBack = function()
		RARootManager.GotoLastPage()
	end
    local titleName = _RALang("@WorldMapThreePage")
	local titleHandler = RACommonTitleHelper:RegisterCommonTitle('RAWorldMapThreePage', 
    titleCCB, titleName, backCallBack, RACommonTitleHelper.BgType.Blue)
end


function RAWorldMapThreePage:Execute()
   RAWorldMapThreeTouch.Scrolling()
end

function RAWorldMapThreePage:Exit()
    local RACommonTitleHelper = RARequire('RACommonTitleHelper')
	RACommonTitleHelper:RemoveCommonTitle("RAWorldMapThreePage")
    if self.mapHandler ~= nil then
        UIExtend.unLoadCCBFile(self.mapHandler)
    end
    if self.kingdomHandlers ~= nil then
        for k,v in pairs(self.kingdomHandlers) do
            if v ~= nil then
                UIExtend.unLoadCCBFile(v)
            end
        end
    end
    self.mMultiTouchLayer:unregisterScriptTouchHandler()
    self.mLayoutNode:removeAllChildren()
    self.mMapRootNode:removeAllChildren()
    UIExtend.unLoadCCBFile(self)
    RACityMultiLayerTouch.setEnabled(true)
end


return RAWorldMapThreePage
--endregion
