--region *.lua
--Date
--此文件由[BabeLua]插件自动生成
local player_show_conf=RARequire("player_show_conf")
local RAGameConfig=RARequire("RAGameConfig")
local RAPrisonUtility={}

--得到俘虏的半身像
function RAPrisonUtility:getPlayerBust(id)
	local key = RAGameConfig.ConfigIDFragment.ID_PLAYER_SHOWCONF + id
    local info = player_show_conf[key]
    if not info then
        info = player_show_conf[701000]
    end
    return info.playerShow
end

return RAPrisonUtility

--endregion
