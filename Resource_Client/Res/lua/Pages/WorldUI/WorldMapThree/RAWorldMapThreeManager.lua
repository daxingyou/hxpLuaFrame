--region *.lua
--Date
--此文件由[BabeLua]插件自动生成

local RAWorldMapThreeManager = {
    centerPos = RACcp(0,0), -- central pos, aka kingdom 1's pos 
    kingdomList = {},--kingdom list
    cameraSize = CCSizeMake(0,0),--cameraSize
    cameraCentralPos = RACcp(0,0),
    mapOffset = RACcp(0,0),--layoutNode's offset, to corrispond to the camera
    kingdomCenterPos = RACcp(2700,2700),
    ringRadius =nil,
    mCamera = nil,
    reset = function (self)
        centerPos = RACcp(0,0) -- central pos, aka kingdom 1's pos 
        kingdomList = {}--kingdom list
        cameraSize = CCSizeMake(0,0)--cameraSize
        cameraCentralPos = RACcp(0,0)
        mapOffset = RACcp(0,0)--layoutNode's offset, to corrispond to the camera
        kingdomCenterPos = RACcp(2700,2700)
        ringRadius =nil
        mCamera = nil
    end,
    sendOpenKingmapPacket = function(self)
        local HP_pb = RARequire("HP_pb")
        local RANetUtil = RARequire("RANetUtil")
        RANetUtil:sendPacket(HP_pb.OPEN_KING_DISTRIBUTE_MAP_C)
    end,
    onRecieveKingdomData = function(self,msg)
        self.kingdomList = msg
        local RARootManager = RARequire("RARootManager")
        if RARootManager.CheckIsPageOpening("RAWorldNewMinMap") then
            RARootManager.ClosePage("RAWorldNewMinMap",false)
            RARootManager.OpenPage("RAWorldMapThreePage",nil,true,false,false)
        end
        
    end,
    initMapThreeData = function(self)
        --local curKindomList = #kingdomList
        local curKindomList = #self.kingdomList

        --minimum show 81 size's map
        local RAWorldMapThreeConfig = RARequire("RAWorldMapThreeConfig")
        if curKindomList < RAWorldMapThreeConfig.oneMapKingdomSize then curKindomList = RAWorldMapThreeConfig.oneMapKingdomSize end
        local RAWorldMapThreeUtil = RARequire("RAWorldMapThreeUtil")
        local logicPoint = RAWorldMapThreeUtil:index2Point(curKindomList)
        self.ringRadius = self:calcRingRadius(logicPoint)
        self.cameraSize = CCSizeMake(self.ringRadius * 2,self.ringRadius * 2)
        self.cameraCentralPos = ccp(self.ringRadius,self.ringRadius)
        self.mapOffset = RACcpSub(self.kingdomCenterPos,RACcp(self.ringRadius,self.ringRadius))
    end,
    --calc the ring radius
    calcRingRadius = function(self,logicPoint)
        local maxXY = math.max(math.abs(logicPoint.x),math.abs(logicPoint.y))
        local RAWorldMapThreeConfig = RARequire("RAWorldMapThreeConfig")
        local ringRadius = maxXY * RAWorldMapThreeConfig.oneGapPos.x
        ringRadius = ringRadius + RAWorldMapThreeConfig.blackAreaWidth -- add the black area 
        return ringRadius
    end
}

return RAWorldMapThreeManager
--endregion
