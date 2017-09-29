local RAAllianceTransferCell = {}

local UIExtend = RARequire("UIExtend")
local player_show_conf = RARequire("player_show_conf")
local RAAllianceProtoManager = RARequire("RAAllianceProtoManager")
local common = RARequire("common")
local Utilitys = RARequire("Utilitys")
local RAPlayerInfoManager = RARequire("RAPlayerInfoManager")
local RARootManager = RARequire("RARootManager")

function RAAllianceTransferCell:new(o)
	o = o or {}
    setmetatable(o,self)
    self.__index = self    
    return o
end	

--转让回调
function RAAllianceTransferCell:onTranferBtn()
    RARootManager.OpenPage("RAAllianceTransferPopUp",{playerInfo = self.mInfo,type = 0},false,true,true)
end

function RAAllianceTransferCell:onRefreshContent(ccbRoot)
    if not ccbRoot then return end
    local ccbfile = ccbRoot:getCCBFileNode() 
    UIExtend.handleCCBNode(ccbfile)

    local index = self.mTag
    local info = self.mInfo

    if info then
        local libStr = {}
        libStr['mAllianceName'] = info.playerName
        libStr['mFightValue'] = Utilitys.formatNumber(info.power)
        local isOnlineStr = ""
        local offlineTime = info.offlineTime
        if info.offlineTime == 0 then
            isOnlineStr = _RALang("@InOnline")
        else
            local currTime = common:getCurMilliTime()
            local lostTime = (currTime - offlineTime) / 1000  --毫秒转成秒
            isOnlineStr = _RALang("@NoInOnline",Utilitys.second2AllianceDataString(lostTime))
        end
        libStr['mStateLabel'] = isOnlineStr

        UIExtend.setStringForLabel(ccbfile,libStr)

        --头像
        local playerIcon = RAPlayerInfoManager.getHeadIcon(self.mInfo.icon)

        UIExtend.addSpriteToNodeParent(ccbfile, "mFrameIconNode", playerIcon)
    end
end

return RAAllianceTransferCell