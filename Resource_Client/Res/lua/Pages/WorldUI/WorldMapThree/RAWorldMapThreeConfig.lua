--region *.lua
--Date
--此文件由[BabeLua]插件自动生成
-- by zhenhui
local RAWorldMapThreeConfig = {
    oneMapSize = RACcp(1800,1800),
    oneGapPos = RACcp(1800/10,1800/10),
    maxKingdom = 81 * 9,
--    centerPos = ccp(1800,1800),
--    mapRect = CCRectMake(0,0,3600,3600),
    centerPos = ccp(2700,2700),
    mapRect = CCRectMake(0,0,5400,5400),
    blackAreaWidth = 200,
    randomSeed = 720,
    randomOffset = 60,
    oneMapKingdomSize = 81,
    cameraInfo = {
        minScale = 1,
        maxScale = 2.0,
        normalScale = 1,
    }
}

return RAWorldMapThreeConfig
--endregion
