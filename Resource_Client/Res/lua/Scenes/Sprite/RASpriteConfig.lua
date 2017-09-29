--region RASpriteConfig.lua
--Date
--此文件由[BabeLua]插件自动生成
local RASpriteConfig = {
    SpriteFinishStatus = {--结束状态
        DestPosNotRight = 1,    --1. 目标点不正确
        NoPathToDestPos = 2,    --2. 没有正确的路线到达（正好在目标点或者到达目标点的路径被封住了，没有路径）
        FinishPath = 3,          --3. 正常完成了整个路线，并停止移动
        BlockWhenMoving = 4,          --4. 行走过程中被阻挡
    }


}

return RASpriteConfig
--endregion

