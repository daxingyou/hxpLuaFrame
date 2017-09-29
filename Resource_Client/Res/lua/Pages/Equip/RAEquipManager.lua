local RAEquipManager = {}

local RAPlayerInfo = RARequire("RAPlayerInfo")
local RAStringUtil = RARequire("RAStringUtil")

local RAPlayerInfoManager = RARequire("RAPlayerInfoManager")
local RACoreDataManager = RARequire("RACoreDataManager")
local const_conf = RARequire("const_conf")

--装备信息页面强化，进阶列表
local EquipUpgradeType = {
    "RAEquipMainStrCell",
    "RAEquipMainEvoCell",
    "RAEquipMainInleyCell"
}

function RAEquipManager:getEquipUpgradeType()
    return EquipUpgradeType
end

--初始化装备数据
function RAEquipManager:initEquipData(equipments)
    local equips = {}
    self.equipsPart = {}
    local RAEquipInfo = RARequire("RAEquipInfo")
    local equipment_conf = RARequire("equipment_conf")
	for i=1,#equipments do
		local equipInfo = RAEquipInfo.new()
	    equipInfo:initByPb(equipments[i])

        local equipmentConf = equipment_conf[tostring(equipInfo.equipId)]

        equipInfo.part = equipmentConf.part or 1
        
		equips[equipInfo.uuid] = equipInfo

        self.equipsPart[equipInfo.part] = equipInfo
	end
    RAPlayerInfoManager.setPlayerEquipInfo(equips)


end

--强化所需的材料分2种类型,根据类型和强化等级获取区间段的材料数据
function RAEquipManager:getNeedMaterialByLevel(strengType,strengLevel)
	local equipment_strengthen_conf = RARequire("equipment_strengthen_conf")
	for i=1,#equipment_strengthen_conf do
		local confData = equipment_strengthen_conf[i]
		if confData.type == strengType then
			if strengLevel <= confData.region then
				return RAStringUtil:parseWithComma(confData.value)
			end
		end
	end

	return nil
end

--根据equipuuid获取equipInfo
function RAEquipManager:getConfEquipInfoById(id)
    if id == "" or id == nil then
        return nil
    end
    local equip = self:getServerEquipInfoById(id)
    local equipment_conf = RARequire("equipment_conf")
    local equipInfo
    if equip then
        equipInfo = equipment_conf[tostring(equip.equipId)]
    else
        equipInfo = equipment_conf[tostring(id)]
    end
    return equipInfo
end

--当前穿着的装备
function RAEquipManager:getServerEquips()
    return self.equipsPart
end

--当前uuid获取拥有的装备信息
function RAEquipManager:getServerEquipInfoById(uuid)
    local equips = RAPlayerInfoManager.getPlayerEquipInfo()
    return equips[uuid]
end

--当前部位获取拥有的装备信息
function RAEquipManager:getServerEquipInfoByPart(part)
    return self.equipsPart[part]
end

--根据equipId获得阶数
function RAEquipManager:getAdvNumberById(equipId)
    if equipId == 0 or equipId == nil then
        return nil
    end
    local equipment_conf = RARequire("equipment_conf")
    local equipInfo = equipment_conf[tostring(equipId)]
    return equipInfo.quality
end

--根据equipId获得进阶材料
function RAEquipManager:getEvoMaterialById(uuid)
    if uuid == "" or uuid == nil then
        return nil
    end
    local equipInfo = self:getConfEquipInfoById(uuid)
    if equipInfo then
        return RAStringUtil:parseWithComma(equipInfo.material)
    end

    return nil
end

--判断此装备是否可以升级或者可以进阶 upStatus == 1 为强化 upStatus == 2 为进阶  0 的话 全部算进去
function RAEquipManager:getIsUPorEvoById(uuid,upStatus)
    local result = false
    local txt = ""
    local serverEquipInfo = self:getServerEquipInfoById(uuid)
    local equipConfInfo = self:getConfEquipInfoById(serverEquipInfo.equipId)
    local material
    local playerInfo = RAPlayerInfoManager.getPlayerBasicInfo()
    if upStatus == 1 or upStatus == 0 then --强化      
        if serverEquipInfo.level < playerInfo.level  then   --装备等级低于指挥官等级
            result = true
        else
            txt = "@EquipLevelLessPlayerLevel"
        end

        material = self:getNeedMaterialByLevel(equipConfInfo.tpye,serverEquipInfo.level)
        for i = 1,#material do
            local itemId = material[i].id
            local count = material[i].count
            local selfItemCount = RACoreDataManager:getItemCountByItemId(itemId)
            if selfItemCount < count then
                result = false
                txt = "@EquipUpMaterialNotEnough"
            end
        end
        --如果status==0说明是查找全部的,只要强化为true了，不用管后面的了 直接return
        if upStatus == 0 and result then
            return result,txt
        end
    end
    if upStatus == 2 or upStatus == 0 then   --进阶
        if equipConfInfo.quality < 6 then  --装备等阶低于6阶
            result = true
        end
        if serverEquipInfo.level < equipConfInfo.requestLevel then
            result = false
            txt = "@EquipUpLevelLessRequestLevel"
        end
        material = self:getEvoMaterialById(uuid) 
        for i = 1,#material do
            local itemId = material[i].id
            local count = material[i].count
            local selfItemCount = RACoreDataManager:getItemCountByItemId(itemId)
            if selfItemCount < count then
                result = false
                txt = "@EquipEvoMaterialNotEnough"
            end
        end
    end
    return result,txt
end

--获得红点数量
function RAEquipManager:getEquipRedPointCount(uuid)
    -- body
    local redPointCount = 0
    local result = false
    local serverEquipInfo = self:getServerEquipInfoById(uuid)
    local equipConfInfo = self:getConfEquipInfoById(serverEquipInfo.equipId)
    local material
    local playerInfo = RAPlayerInfoManager.getPlayerBasicInfo()
    --强化      
    if serverEquipInfo.level < playerInfo.level  then   --装备等级低于指挥官等级
        material = self:getNeedMaterialByLevel(equipConfInfo.tpye,serverEquipInfo.level)
        for i = 1,#material do
            local itemId = material[i].id
            local count = material[i].count
            local selfItemCount = RACoreDataManager:getItemCountByItemId(itemId)
            if selfItemCount >= count then
                result = true
            else
                result = false   
                break 
            end
        end

        if result then
            redPointCount = redPointCount + 1
        end
    end

    --进阶
    if equipConfInfo.quality >= 6 then  --装备等阶低于6阶
        return redPointCount
    end
    if serverEquipInfo.level < equipConfInfo.requestLevel then
        return redPointCount
    end

    material = self:getEvoMaterialById(uuid) 
    for i = 1,#material do
        local itemId = material[i].id
        local count = material[i].count
        local selfItemCount = RACoreDataManager:getItemCountByItemId(itemId)
        if selfItemCount >= count then
            result = true
        else
            result = false
            break   
        end
    end

    if result then
        redPointCount = redPointCount + 1
    end
    return redPointCount
end

--根据itemId获得商店中的数据
function RAEquipManager:getStoreDataById(itemId)
    local shop_conf = RARequire("shop_conf")
    local Utilitys = RARequire("Utilitys")
    for k,v in Utilitys.table_pairsByKeys(shop_conf) do
        if v.shopItemID == itemId then
            return v
        end
    end
    return nil
end

function RAEquipManager:getEquipLevelMax()
    return const_conf.EquipMaxLevel.value
end

function RAEquipManager:getEquipMaxQualityMax()
    return const_conf.EquipMaxQuality.value
end

--装备红点刷新
function RAEquipManager:getEquipsRedPointCount()
    -- body
    local totalCount = 0
    local equips = RAPlayerInfoManager.getPlayerEquipInfo()
    --for i = 1,RAGameConfig.MAX_EQUIPNUM do
    for k,equip in pairs(equips) do
        local count = self:getEquipRedPointCount(equip.uuid)
        totalCount = totalCount + count
    end

    return totalCount
end

function RAEquipManager:reset()
    -- body
    self.equipsPart = {}
end

return RAEquipManager