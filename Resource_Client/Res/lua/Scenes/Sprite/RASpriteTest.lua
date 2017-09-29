RARequire('extern')

local RASprite = RARequire('RASprite')

local RASpriteTest = class('RASpriteTest',RASprite)

function RASpriteTest:TEST()
    CCLuaLog("this is RASpriteTest Test")
end

return RASpriteTest


