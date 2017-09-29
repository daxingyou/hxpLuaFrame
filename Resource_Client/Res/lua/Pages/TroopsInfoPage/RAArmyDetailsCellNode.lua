--region RAArmyDetailsCellNode.lua
--Author : phan
--Date   : 2016/6/28
--此文件由[BabeLua]插件自动生成



--endregion

local UIExtend = RARequire("UIExtend")
local battle_soldier_conf = RARequire("battle_soldier_conf")
local build_conf = RARequire("build_conf")
local RARootManager = RARequire("RARootManager")
local RAQueueManager = RARequire("RAQueueManager")

local RAArmyDetailsCellNode = {}

function RAArmyDetailsCellNode:new(o)
    o = o or {}
    setmetatable(o,self)
    self.__index = self    
    return o
end

function RAArmyDetailsCellNode:onCheckBtn(ccbRoot)
    local index = tonumber(self.mTag)
    local data = self.mData
    local mType = data.type

    --get soldierId or isBar vlaue or data
    if mType == 1 then
        local soldierId = data.id
        RARootManager.OpenPage("RAArmyDetailsPopUpPage",{soldierId = soldierId},false,true,true)
    elseif mType == 2 then
        local defenseId = data.id
        local uuid = data[defenseId].id
        local RABuildManager = RARequire("RABuildManager")
        RABuildManager:showBuildingById(uuid)
        RARootManager.CloseCurrPage()
    end
end

function RAArmyDetailsCellNode:onRefreshContent(ccbRoot)
    if not ccbRoot then return end
	local ccbfile = ccbRoot:getCCBFileNode() 
    UIExtend.handleCCBNode(ccbfile)
    local index = tonumber(self.mTag)
    local dataCfg = self.mData
    local mType = dataCfg.type
    --get id or isBar vlaue or data
    local id = dataCfg.id
    local isBar = dataCfg.isBar  
    local data = dataCfg[id]
    
    --set icon
    local picName = nil
    if mType == 1 then --为兵种类型
        if data.freeCount then
            UIExtend.setStringForLabel(ccbfile,{mIconNum = tostring(data.freeCount)})
        end
        local armyConf = battle_soldier_conf[id]
        local iconPath = "Resource/Image/SoldierHeadIcon/"
        if armyConf then
	        picName = iconPath..armyConf.icon
        end
    elseif mType == 2 then ----为防御类型
        
        local buildConf = build_conf[id]
        local iconPath = "Resource/Image/BuildIcon/"
        if buildConf then 
	        picName = iconPath..buildConf.buildArtImg
        end
        UIExtend.setStringForLabel(ccbfile,{mIconNum = ""})
    end
    
    UIExtend.removeSpriteFromNodeParent(ccbfile, "mIconNode")
	UIExtend.addSpriteToNodeParent(ccbfile, "mIconNode", picName)

    if not isBar then
        UIExtend.setNodeVisible(ccbfile,"mBarNode",false)
        UIExtend.getCCSpriteFromCCB(ccbfile,"mRepairsPic"):setVisible(false)
        UIExtend.getCCSpriteFromCCB(ccbfile,"mUpgradingPic"):setVisible(false)
    else
        UIExtend.setNodeVisible(ccbfile,"mBarNode",true)
        local isUpgrade = RAQueueManager:isBuildingUpgrade(data.id)
        if isUpgrade then
            UIExtend.getCCSpriteFromCCB(ccbfile,"mRepairsPic"):setVisible(false)
            UIExtend.getCCSpriteFromCCB(ccbfile,"mUpgradingPic"):setVisible(true)
        else
            UIExtend.getCCSpriteFromCCB(ccbfile,"mRepairsPic"):setVisible(false)
            UIExtend.getCCSpriteFromCCB(ccbfile,"mUpgradingPic"):setVisible(false)
        end

        --血条
        local currHP = data.HP
        local totalHP = data.totalHP

        local scale = currHP / totalHP
        if scale > 1 then
            scale = 1
        elseif scale < 0 then
            scale = 0
        end

        local bar = UIExtend.getCCScale9SpriteFromCCB(ccbfile,"mBar")
        if bar then
            bar:setScaleX(scale)
        end
    end
end

return RAArmyDetailsCellNode