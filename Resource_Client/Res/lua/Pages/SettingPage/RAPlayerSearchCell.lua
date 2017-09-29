--region *.lua
--Date
--此文件由[BabeLua]插件自动生成

local RAPlayerSearchCell = {}
local UIExtend = RARequire("UIExtend")
function RAPlayerSearchCell:new(o)
    o = o or {}
    setmetatable(o,self)
    self.__index = self    
    return o
end

function RAPlayerSearchCell:onRefreshContent(ccbRoot)
	CCLuaLog("RASettingContentCell:onRefreshContent")    
    if not ccbRoot then return end
	local ccbfile = ccbRoot:getCCBFileNode() 
    UIExtend.handleCCBNode(ccbfile)
    local data = self.data
    UIExtend.setStringForLabel(ccbfile,{
        mPlayerName = data.playerName,
        mKingdomName = data.kingdom or "",
        mAllianceName = data.guildName or "",
        mLanguage = data.language or ""
    })
    local RAPlayerInfoManager = RARequire("RAPlayerInfoManager")
    if data.icon ~= nil then
        local iconStr = RAPlayerInfoManager.getHeadIcon(data.icon)
	    UIExtend.addSpriteToNodeParent(ccbfile, "mCellIconNode",tostring(iconStr))
    end
    
end

function RAPlayerSearchCell:onCheckBtn()
    local RARootManager = RARequire("RARootManager")
    RARootManager.OpenPage('RAGeneralInfoPage', {playerId = self.data.playerId})

--    --test for the block msg 
--    local data = self.data
--    local RAShieldManager = RARequire("RAShieldManager")
--    local RAShieldData = RARequire("RAShieldData")
--    local oneShieldData = RAShieldData:new()
--    oneShieldData.playerId = data.playerId
--    oneShieldData.name = data.playerName
--    oneShieldData.icon = data.icon
--    oneShieldData.guildName = data.guildName
--    oneShieldData.battlePoint = data.power
--    RAShieldManager:addOneShieldData(oneShieldData)
end


return RAPlayerSearchCell
--endregion
