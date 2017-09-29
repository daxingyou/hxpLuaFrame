--region *.lua
--Date
--此文件由[BabeLua]插件自动生成
local UIExtend = RARequire("UIExtend")
local RAWorldUtil = RARequire("RAWorldUtil")
local RAWorldMapThreeUtil = RARequire("RAWorldMapThreeUtil")
local RAKingdomCell = {
    kingdomInfo = nil
}

function RAKingdomCell:new(o)
    o = o or {}
    setmetatable(o,self)
    self.__index = self    
    return o
end

function RAKingdomCell:Enter()
    --refresh content

    local labelText = self.data.serverId
    if self.data:HasField('kingName') and self.data.kingName~=nil then
        labelText = labelText .. "#" .. self.data.kingName
    end
    UIExtend.setStringForLabel(self.ccbfile,{
        mCellLabel = labelText
    })
    local serverIdNum = RAWorldUtil.kingdomId.tonumber(self.data.serverId)
    local index = serverIdNum % 5 + 1
    local pictureStr = "RAW_Icon_"..tostring(index)..".png"
    
    UIExtend.addSpriteToNodeParent(self.ccbfile,"mCellIconNode",pictureStr)
end

function RAKingdomCell:onClick()
    
    local serverId = RAWorldUtil.kingdomId.tonumber(self.data.serverId)
    local RARootManager = RARequire("RARootManager")
    RARootManager.CloseAllPages()
    local RAWorldManager = RARequire("RAWorldManager")
    RAWorldManager:LocateCapital(serverId)
--    local up,down,left,right =  RAWorldMapThreeUtil:getServerIdsAround(serverId)
--    local str = string.format("onClick, %d   %d  %d  %d",up,down,left,right)
--    CCMessageBox("RAKingdomCell:onClick"..str,"hint")
end

return RAKingdomCell
--endregion
