--region RAResManager.lua
--Date
--此文件由[BabeLua]插件自动生成
local RAResManager = {}
local RAStringUtil = RARequire("RAStringUtil")
local player_show_conf = RARequire("player_show_conf")
local item_conf = RARequire("item_conf")
local player_talent_conf = RARequire("player_talent_conf")
local build_conf = RARequire("build_conf")
local battle_soldier_conf = RARequire("battle_soldier_conf")


local RAResInfo = {}
--构造函数
function RAResInfo:new()
    local o = {}

    o.itemMainType = nil --资源主类型
    o.itemType = nil --资源类型
    o.itemId = nil --资源模板id
    o.itemCount = nil --资源数量
    setmetatable(o,self)
    self.__index = self
    return o
end

--input param: 10000_1007_500,10000_1008_500
--return: table of RAResInfo s
function RAResManager:getResInfosByStr(resStr)
    if resStr == nil then return end
    local resStrVec = RAStringUtil:split(resStr,",")
    local allResInfo = {}
    if #resStrVec > 0 then
        for i=1,#resStrVec,1 do
            local oneResInfo = self:getOneResInfoByStr(resStrVec[i])
            table.insert(allResInfo,oneResInfo)
        end
        return allResInfo
    else
        return nil
    end
end

--input param: 10000_1007_500
--return: RAResInfo
function RAResManager:getOneResInfoByStr(resStr)
    local oneResInfo = RAResInfo:new()
    local resStrVec = RAStringUtil:split(resStr,"_")
    assert(#resStrVec == 3 , "#resStrVec == 3")
    oneResInfo.itemMainType = resStrVec[1]/10000
    oneResInfo.itemType = resStrVec[1]
    oneResInfo.itemId = resStrVec[2]
    oneResInfo.itemCount = resStrVec[3]
    return oneResInfo
end

--根据mainType和id来获得icon
--mainType是万级的数字,具体见const.proto定义
function RAResManager:getIconByTypeAndId(mainType, id)
    mainType = tonumber(mainType)
    id = tonumber(id)
    local icon = ""
    local mainType = mainType / 10000
    local name = ""
    local item_color = 1
    if mainType == Const_pb.PLAYER_ATTR then--玩家属性
        if id == Const_pb.GOLD then--钻石
            icon = "Common_Icon_Diamonds.png"
            name = "@Diamond"
        elseif id == Const_pb.COIN then--金币
            icon = "Common_Icon_Gold_01_Big.png"
            name = "@Gold"
        elseif id == Const_pb.EXP then--经验
            icon = "Exp.png"
            name = "@Exp"
        elseif id == Const_pb.VIP_POINT then--VIP
            name = "@VIP"
        elseif id == Const_pb.ELECTRIC then--电力
            name = "@Electric"
        elseif id == Const_pb.GOLDORE then--矿石
            icon = "Common_Icon_Gold_01_Big.png"
            name = "@ResGoldore"
        elseif id == Const_pb.OIL then--石油
            icon = "Common_Icon_Supply_01_Big.png"
            name = "@ResOil"
        elseif id == Const_pb.STEEL then--钢铁
            icon = "Common_Icon_Steel_01_Big.png"
            name = "@ResSteel"
        elseif id == Const_pb.TOMBARTHITE then--稀土
            icon = "Common_Icon_Petroleum_01_Big.png"
            name = "@ResTombarthite"
        elseif id == Const_pb.VIT then--体力
            name = "@Stamina"
        end
    elseif mainType == Const_pb.ROLE then
        local playerConstInfo = player_show_conf[id]
        if playerConstInfo then
            icon = playerConstInfo.playerIcon
        end
    elseif mainType == Const_pb.TOOL then
        local constItemInfo = item_conf[id]
        if constItemInfo then
            icon = constItemInfo.item_icon
            name = constItemInfo.item_name
            item_color = constItemInfo.item_color
        end
    elseif mainType == Const_pb.EQUIP then
        
    elseif mainType == Const_pb.SKILL then
        local constTalentInfo = player_talent_conf[id]
        if constTalentInfo then
            icon = constTalentInfo.icon
            name = constTalentInfo.name
        end
    elseif mainType == Const_pb.BUILDING then
        local constBuildInfo = build_conf[id]
        if constBuildInfo then
            icon = constBuildInfo.buildArtImg
            name = constBuildInfo.buildName
        end
    elseif mainType == Const_pb.SOLDIER then
        local soldierConstInfo = battle_soldier_conf[id]
        if soldierConstInfo then
            icon = soldierConstInfo.icon
            name = soldierConstInfo.name
        end
    end

    if icon ~= "" then
        local iconSub = string.sub(icon, -3)
        if iconSub ~= "png" then
            icon = icon .. ".png"
        end

    end

    return icon, name, item_color
end

function RAResManager:getQuestIcon( mainType, id )
    mainType = tonumber(mainType)
    id = tonumber(id)
    local icon = ""
    local mainType = mainType / 10000
    local name = ""
    local item_color = 1
    if mainType == Const_pb.PLAYER_ATTR then--玩家属性
        if id == Const_pb.GOLD then--钻石
            icon = "QuestIcon_Diamonds.png"
            name = "@Diamond"
        elseif id == Const_pb.COIN then--金币
            icon = "QuestIcon_Gold.png"
            name = "@Gold"
        elseif id == Const_pb.EXP then--经验
            icon = "QuestIcon_Exp.png"
            name = "@Exp"
        elseif id == Const_pb.VIP_POINT then--VIP
            name = "@VIP"
        elseif id == Const_pb.ELECTRIC then--电力
            name = "@Electric"
        elseif id == Const_pb.GOLDORE then--矿石
            icon = "QuestIcon_Gold.png"
            name = "@ResGoldore"
        elseif id == Const_pb.OIL then--石油
            icon = "QuestIcon_Petroleum.png"
            name = "@ResOil"
        elseif id == Const_pb.STEEL then--钢铁
            icon = "QuestIcon_Steel.png"
            name = "@ResSteel"
        elseif id == Const_pb.TOMBARTHITE then--合金
            icon = "QuestIcon_Alloy.png"
            name = "@ResTombarthite"
        elseif id == Const_pb.VIT then--体力
            name = "@Stamina"
        end    
    end
    if icon ~= "" then
        return icon, name, item_color
    else
        return self:getIconByTypeAndId( mainType, id )
    end
end


-- 获取矿产资源的icon,name
function RAResManager:getResourceIconByType(resType)
    return self:getIconByTypeAndId(Const_pb.PLAYER_ATTR * 10000, resType)
end

--通过str获得icon 10000_250000_2
function RAResManager:getIconByStr(str)
    local strArray = Utilitys.Split(str, "_")
    local mainType = 0
    local id = 0

    if strArray[1] then
        mainType = tonumber(strArray[1])
    end

    if strArray[2] then
        id = tonumber(strArray[2])
    end
    local icon, _ = RAResManager:getIconByTypeAndId(mainType, id)
    return icon
end

return RAResManager
--endregion
