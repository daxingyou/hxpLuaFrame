--region RASpriteData.lua
--Date
--此文件由[BabeLua]插件自动生成
local RASpriteData = {}

function RASpriteData:new(o)   
    o = o or {}
    o.confData = {} --配置文件对象
    o.tilesMap = {} --该建筑占地tiles
    o.tilePos = nil --建筑的位置

    o.topTile = nil 

    -- o.picVec = {}    --图片等级
    -- o.pic = nil      --建筑图片
    -- o.level = 0      --建筑等级

    setmetatable(o,self)
    self.__index = self
    return o
end


return RASpriteData
--endregion
