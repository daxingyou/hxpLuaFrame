--FileName :RACitySceneConfig 
--Author: zhenhui 2016/5/26

local RACitySceneConfig = {
    tileInfo = {
        tmxFile = "city.tmx",   --tmx file name
        tmxTotalRect = CCRectMake(0,0,4096,2048),
        tmxTileLayerName = "background",
        tmxTileBlockLayerName = "block",
        tmxCenterTile = ccp(16,32),
        tmxArmyTogetherTile = ccp(26,50),
        tmxLayerSize = RACcp(31,61),
        tmxWhiteGID = 1,
        tmxRedGID = 2,
        tmxGreenGID = 3,
        tmxEmptyGID = 4
    },
    cameraInfo = {
        normalScale = 1.1,
        GotoWorldScale = 1.5,
        maxScaleRate = 0.9,
        minScale = 0.7
    },
    CityArmyIndex = {
        RandomArmy = 2000,
        RandomFailPos = 24,13,
        RandomRangerBeginPos = RACcp(10,10),
        RandomRangerEndPos = RACcp(20,50),
        ArmyGetherPos = RACcp(23,50),
        ArmyGetherRandomPos = {
            RACcp(22,50),
            RACcp(23,48),
            RACcp(24,46),
            RACcp(22,49),
            RACcp(24,45),
        },
	MinerRandomPos = {
            RACcp(2,9),
            RACcp(3,5),
            RACcp(3,7),
            RACcp(3,8),
            RACcp(3,9),
            RACcp(3,10),
            RACcp(3,11),
            RACcp(3,12),
            RACcp(3,14),
            RACcp(4,5),
            RACcp(4,6),
            RACcp(4,7),
            RACcp(4,9),
            RACcp(4,10),
            RACcp(4,11),
            RACcp(4,12),
	    RACcp(4,13),
            RACcp(5,3),
            RACcp(5,4),
            RACcp(5,6),
            RACcp(5,7),
            RACcp(5,8),
            RACcp(5,9),
            RACcp(5,10),
            RACcp(5,11),
            RACcp(5,12),
            RACcp(6,4),
            RACcp(6,5),
            RACcp(6,6),
            RACcp(6,7),
            RACcp(6,8),
            RACcp(6,9),
            RACcp(6,10),
            RACcp(7,6),
            RACcp(7,8),
        }
    },
    GatherGround = {
        row =4,
        column = 6,
    },
    TubInfo={
        DigGoldStartPos = RACcp(1,3),
        DigGoldEndPos = RACcp(4,10),
        DigStartIndex = 3000000,
        tubType = 2101,
    },
    TrainGuideStatus = {
        Empty = 0,
        Idle = 1,
        Run = 2 
    }


}

return RACitySceneConfig
