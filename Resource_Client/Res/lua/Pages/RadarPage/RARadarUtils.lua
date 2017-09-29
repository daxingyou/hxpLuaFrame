--region *.lua
--Date
--此文件由[BabeLua]插件自动生成


local RARadarUtils={}
local World_pb = RARequire("World_pb")
local battle_soldier_conf = RARequire("battle_soldier_conf")
local effectid_conf=RARequire("effectid_conf")
local RAPlayerInfoManager=RARequire("RAPlayerInfoManager")

function RARadarUtils:isRadarMarchDatas(marchType)
	if marchType==World_pb.SPY or  marchType==World_pb.ASSISTANCE then
        return true
    end
    return false
end

--判断是否是侦查数据
function RARadarUtils:isRadarSpyData(marchType)
	if marchType==World_pb.SPY  then
        return true
    end
    return false
end

--判断是否是援助数据（这里包含士兵援助和资源援助，后面要分开）
function RARadarUtils:isRadarAssistanceData(marchType)
	if marchType==World_pb.ASSISTANCE  then
        return true
    end
    return false
end



--获取玩家的icon
function RARadarUtils:getPlayerIcon(id)

    local icon=RAPlayerInfoManager.getHeadIcon(id)
    return icon

end

--获取士兵信息
function RARadarUtils:getBattleSoldierDataById(id)
    return battle_soldier_conf[tonumber(id)]
end

--获取士兵的icon
function RARadarUtils:getBattleSoldierIconById(id)
    local battleSoldierInfo = self:getBattleSoldierDataById(id)
    local icon = battleSoldierInfo.icon or "College_u_Icon_BG.png"
    return icon
end

function RARadarUtils:getEffectDataById(id)
    local effectidConfigData=effectid_conf[tonumber(id)]
    if not effectidConfigData then
       effectidConfigData=effectid_conf[100]
    end 
    return effectidConfigData
end
return RARadarUtils

--endregion
