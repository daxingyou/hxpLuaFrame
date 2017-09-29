local RAGameType = RARequire('RAGameType') 
local Utilitys = RARequire('Utilitys')
local RAStringUtil = RARequire('RAStringUtil')
local RAGameConfig = RARequire("RAGameConfig")
local const_conf = RARequire("const_conf")
local item_conf = RARequire("item_conf")
local RAPlayerEffect = RARequire("RAPlayerEffect")
local RAPlayerInfoManager = RARequire("RAPlayerInfoManager")
local tostring = tostring
local tonumber = tonumber
local Const_pb=RARequire("Const_pb")


local RALogicUtil = {}

--判断是否装备
function RALogicUtil:isEquip(itemId)
	if itemId >= EQUIP_ITEM_LOW and itemId <= EQUIP_ITEM_HIGHT then 
		return true
	end
	return false
end

--获得物品颜色
--colorIndex:品质 RAGameType里的COLOR_TYPE
function RALogicUtil:getLabelNameColor(colorIndex)
	if COLOR_TABLE[colorIndex] ~= nil then 
		return COLOR_TABLE[colorIndex]
	else
		return ccc3(255,255,255)
	end 
end

--获得物品颜色名称
function RALogicUtil:getColorName(color)
	if color == COLOR_TYPE.WHITE then
		return _RALang('@ColorWhite')
	elseif color == COLOR_TYPE.GREEN then
		return _RALang('@ColorGreen')
	elseif color == COLOR_TYPE.BLUE then
		return _RALang('@ColorBlue')
	elseif color == COLOR_TYPE.PURPLE then
		return _RALang('@ColorPurple')
	elseif color == COLOR_TYPE.ORANGE then
		return _RALang('@ColorOrange')
	elseif color == COLOR_TYPE.RED then
		return _RALang('@ColorRed')
	end 
end

--获取道具品质底图
function RALogicUtil:getItemBgByColor(color)
	local basePath = "Resource/UI/CommonUI/"
	if color < COLOR_TYPE.WHITE then
		color = COLOR_TYPE.WHITE
	elseif color > COLOR_TYPE.RED then
		color = COLOR_TYPE.RED
	end
	local picNamePath = basePath.."Common_u_Quality_0"..color..".png"
	
	return picNamePath
end

function RALogicUtil:getGenHeadBgByColor(color)
	local picName = "general_pic_bg_" .. color .. ".png"
	return picName
end

function RALogicUtil:isTouchInside(pNode, pTouch)
	if pNode == nil or pNode:getParent() == nil  or pTouch == nil then
		return false
	end
	local pt = pNode:getParent():convertToNodeSpace(pTouch:getLocation())
	local rect = pNode:boundingBox()
	local result = rect:containsPoint(pt)
	return result
end

--根据类型获取当前资源名称
-- ResourceType = {
--     GOLDORE = 1007, -- 矿石
--     OIL = 1008,     -- 石油
--     STEEL = 1009,   --钢铁
--     TOMBARTHITE = 1010,--稀土
-- };

function RALogicUtil:getResourceNameById(resId)
	resId = tonumber(resId)
	if resId == Const_pb.GOLDORE then
		return _RALang("@ResGoldore")
	elseif resId == Const_pb.OIL then
		return _RALang("@ResOil")
	elseif resId == Const_pb.STEEL then
		return _RALang("@ResSteel")
	elseif resId ==  Const_pb.TOMBARTHITE then
		return _RALang("@ResTombarthite")
	end 
end

--根据类型获取当前资源Icon

function RALogicUtil:getResourceIconById( resId )
	resId = tonumber(resId)
	local fix = ".png"
	if resId == Const_pb.GOLDORE then
		return const_conf["res_A_Icon"].value..fix
	elseif resId == Const_pb.OIL then
		return const_conf["res_B_Icon"].value..fix
	elseif resId == Const_pb.STEEL then
		return const_conf["res_C_Icon"].value..fix
	elseif resId ==  Const_pb.TOMBARTHITE then
		return const_conf["res_D_Icon"].value..fix
	end 

	return ""
end

function  RALogicUtil:getItemIconById( itemId )
	local itemInfo = item_conf[tonumber(itemId)]
 	local icon = itemInfo.item_icon..".png"
 	return icon
end


--根据id获取道具配置信息
function RALogicUtil:getItemInfoById(id) 
	--没有道具表 暂时先用这个代替
	local build_conf = RARequire("build_conf")
	return build_conf[id]
end

--根据类型判断是否是道具
function RALogicUtil:isItemById( tmpId )
	if not tmpId or not tonumber(tmpId) then return end
	tmpId = tonumber(tmpId)
	if item_conf[tmpId] then
		return true
	end 
	return false
	
end

--根据类型判断是否是资源
function RALogicUtil:isResourceById( tmpId )
	if not tmpId or not tonumber(tmpId) then return end
	tmpId = tonumber(tmpId)
	return Utilitys.tableFind(RAGameConfig.ResourceType,tmpId)
end

--根据作用号获得影响数值
function RALogicUtil:getEffectResult(effectId)
    return RAPlayerEffect:getEffectResult(effectId)
end


--资源类型to资源商店类型
function RALogicUtil:resTypeToShopType(resType)
	resType = resType or 1007
	if resType == 1007 then
		resType = 14
	elseif resType == 1008 then
		resType = 17
	elseif resType == 1009 then
		resType = 16
	elseif resType == 1010 then		
		resType = 15
	end
    return resType
end

--根据key来获得领主详情信息
function RALogicUtil:getLordDetailInfo(detaillKey, detailInfo)
    local result = 0
    local playerDetailInfo = detailInfo or RAPlayerInfoManager.getPlayerDetailInfo()
    if detaillKey == "TotalStrength" then
        result = RAPlayerInfoManager.getPlayerFightPower()
    elseif detaillKey == "GeneralStrength" then
        result = RAPlayerInfoManager.getGeneralFightPower()
    elseif detaillKey == "MilitaryStrength" then
        result = RAPlayerInfoManager.getArmyFightPower()
    elseif detaillKey == "TechnologyStrength" then
        result = RAPlayerInfoManager.getTechFightPower()
    elseif detaillKey == "BuildingStrength" then
        result = RAPlayerInfoManager.getBuildFightPower()
    elseif detaillKey == "DefenseStrength" then
        result = RAPlayerInfoManager.getDefenseFightPower()
    elseif detaillKey == "EquipmentStrength" then
        result = RAPlayerInfoManager.getEquipFightPower()
    elseif detaillKey == "FightingVictoryTimes" then
        result = playerDetailInfo.warWinCnt
    elseif detaillKey == "FightingFailTimes" then
        result = playerDetailInfo.warLoseCnt
    elseif detaillKey == "AttackVictoryTimes" then
        result = playerDetailInfo.atkWinCnt
    elseif detaillKey == "AttackFailTimes" then
        result = playerDetailInfo.atkLoseCnt
    elseif detaillKey == "DefenseVictoryTimes" then
        result = playerDetailInfo.defWinCnt
    elseif detaillKey == "WinningPercentage" then
        result = RAPlayerInfoManager.getWinRat()
        result = math.ceil(result*100)
    elseif detaillKey == "SpyTimes" then
        result = playerDetailInfo.spyCnt
    elseif detaillKey == "DestroyedUnitsNum" then
        result = playerDetailInfo.armyKillCnt
    elseif detaillKey == "LostUnitsNum" then
        result = playerDetailInfo.armyLoseCnt
    elseif detaillKey == "TreatmentUnitsNum" then
        result = playerDetailInfo.armyCureCnt
    elseif detaillKey == "ArmyNum" then
        local RAMarchDataManager = RARequire('RAMarchDataManager')
        result = RAMarchDataManager:GetSelfMarchCount()
    elseif detaillKey == "UnitsUpperLimit" then
        result = playerDetailInfo.maxMarchSoldierNum
    elseif detaillKey == "TrainUpperLimit" then
        local RATroopsInfoManager = RARequire("RATroopsInfoManager")
        result = RATroopsInfoManager.getTroopsTotal(true)
    elseif detaillKey == "DefenseUnitsUpperLimit" then
    	local build_limit_conf = RARequire("build_limit_conf")
        local constBuildConf = build_limit_conf[Const_pb.LIMIT_TYPE_BUILDING_DEFENDER]
        if constBuildConf then
            local RABuildManager = RARequire("RABuildManager")
            local mainCityLevel = RABuildManager:getMainCityLvl()
            local key = "cyLv"..mainCityLevel
            result = constBuildConf[key]
        end
    elseif detaillKey == "CureUnitsUpperLimit" then
        result = playerDetailInfo.maxCapNum
    end

    return result
end


--买时间需要消耗多少钻石
 --value = "60_1,3600_20,43200_100,86400_260,172800_390,604800_1000;
function RALogicUtil:time2Gold(tmpTime)
	if tmpTime == 0 then 
		return 0
	end
	local info=RAStringUtil:split(const_conf["speedUpCost"].value,";")
	local buildCostInfo =RAStringUtil:split(info[1],",")
	local count = #buildCostInfo
	local gold=0
	local hour = 3600
	for i=1,count do
		if i<count then
			local buildCost1 = buildCostInfo[i]
			local buildCost2 = buildCostInfo[i+1]
			local costInfo_min = RAStringUtil:split(buildCost1,"_")
			local costInfo_max = RAStringUtil:split(buildCost2,"_")

			local minLimitT  = tonumber(costInfo_min[1])
			local maxLimitT  = tonumber(costInfo_max[1])
			local goldNum = tonumber(costInfo_min[2])

			if tmpTime>maxLimitT then
				local multiple = maxLimitT-minLimitT
				gold = gold + multiple*goldNum/hour
			elseif tmpTime<=maxLimitT and tmpTime>minLimitT then
				local multiple = tmpTime - minLimitT
				gold=gold+multiple*goldNum/hour
				break
			end 

		else
			local buildCost1 = buildCostInfo[i]
			local costInfo_max = RAStringUtil:split(buildCost1,"_")
			local maxLimitT  = tonumber(costInfo_max[1])
			local goldNum = tonumber(costInfo_max[2])
			if  tmpTime>maxLimitT then
				local multiple = tmpTime - maxLimitT
				gold=gold+multiple*goldNum/hour
			end 
		end
	end

	return math.ceil(gold)
end




--传入资源id以及需要的资源数量，判断是否有足够的资源，如果不足，返回res2Gold的所要消耗的钱
--返回两个参数，第一个参数是是否有足够资源，第二个参数是需要消耗的钻石数目
function RALogicUtil:hasEnoughRes(resId,count)
    local RAPlayerInfoManager = RARequire("RAPlayerInfoManager")
    local curNum = RAPlayerInfoManager.getResCountById(tonumber(resId))
    if curNum >= count then
       return true,0
    else
        local remainCount = count - curNum
        local gold = self:res2Gold(remainCount,resId)
        return false,gold  
    end
end

--input param: 买resId资源 x count，需要消耗多少钻石
function RALogicUtil:res2Gold(count,resId)
	resId = tonumber(resId)

	local info=RAStringUtil:split(const_conf["buyResCost"].value,",")
	local resinfoTab={}
	if resId == Const_pb.GOLDORE then
		resinfoTab =RAStringUtil:split(info[1],"_")
	elseif resId == Const_pb.OIL then
		resinfoTab =RAStringUtil:split(info[2],"_")
	elseif resId == Const_pb.STEEL then
		resinfoTab =RAStringUtil:split(info[3],"_")
	elseif resId ==  Const_pb.TOMBARTHITE then
		resinfoTab =RAStringUtil:split(info[4],"_")
	end 

	-- 1 先确认开启的最高等级资源
	local item_conf = RARequire("item_conf")
	local num = #resinfoTab
	local index = 0
	-- local remainCount = count
	for i=1,num do
		local itemId = tonumber(resinfoTab[i])
		local itemInfo = item_conf[itemId]
		local isUnLockLimit = self:isUnLimitRes2Gold(itemInfo)
		if isUnLockLimit then
			index = i
		else
			break
		end 
	end

	-- 2 累加资源计算消耗钻石
	local gold = 0
	local subNum = 0
	local preSubNum = 0
	for i=1,index do
		local itemId = tonumber(resinfoTab[i])
		local itemInfo = item_conf[itemId]
		local sellPrice = itemInfo.sellPrice
		local addAtrrS = RAStringUtil:split(itemInfo.addAttr,"_")
		local goldNum = tonumber(addAtrrS[2])

		subNum = subNum + goldNum
		if subNum>=count then
			local remainNum = count - preSubNum
			gold = gold + sellPrice*remainNum/goldNum
			break
		else
			gold = gold + sellPrice
		end 
		preSubNum = subNum

	end

	-- 3 如果所有累加仍达不到count 用最高等级的换算剩余的
	if subNum<count then
		local remainNum = count - subNum
		local itemId = tonumber(resinfoTab[index])
		local itemInfo = item_conf[itemId]
		local sellPrice = itemInfo.sellPrice
		local addAtrrS = RAStringUtil:split(itemInfo.addAttr,"_")
		local goldNum = tonumber(addAtrrS[2])
		gold = gold + sellPrice * remainNum/goldNum
	end
	return math.ceil(gold)

end

function RALogicUtil:isUnLimitRes2Gold(itemInfo)
	local RABuildManager = RARequire("RABuildManager")
	local cityLevel = RABuildManager:getMainCityLvl()
	local limitlevel = itemInfo.levelLimit
	if cityLevel>=limitlevel then
		return true
	end
	return false
end

-- 数字变为缩写格式
-- countAfterDot 保留小数点位数，默认为1
-- isRound 是否末尾四舍五入，默认为否
local num2k_char = {'', 'K', 'M', 'B', 'T', 'P', 'E'}
function RALogicUtil:num2k(num, countAfterDot, isRound)
	local tmpNum = num or 0
	if countAfterDot == nil or countAfterDot < 0 then
		countAfterDot = 1
	end
	local isRound = isRound or false
	if tmpNum >= 1000 then	
		local i = 1
		while tmpNum/1000 >= 1
		do
			tmpNum = tmpNum / 1000
			i = i + 1
		end
		local numStr = self:numCutAfterDot(tmpNum, countAfterDot, isRound)
		return numStr..num2k_char[i]
	else
		--小于K的直接取整了
		return self:numCutAfterDot(num, 0, isRound)
	end
end


--数字小数点后位数精简
-- countAfterDot 保留小数点位数，默认为1
-- isRound 是否末尾四舍五入，默认为否
function RALogicUtil:numCutAfterDot(num, countAfterDot, isRound)	
	local num = num or 0
	if countAfterDot == nil or countAfterDot < 0 then
		countAfterDot = 1
	end
	local isRound = isRound or false
	-- CCLuaLog("arg num:"..num.. " countAfterDot:"..countAfterDot.." isRound:"..tostring(isRound))
	local formatStr = "%0."..countAfterDot.."f"
	if not isRound then
		num = num * 10 ^ countAfterDot
		num = math.floor(tostring(num))
		return string.format(formatStr, num / (10 ^ countAfterDot))
	end
	return string.format(formatStr, num)
end


--数字变为百分百格式（末尾四舍五入），
-- countAfterDot 保留小数点位数，默认为2
-- isRound 是否末尾四舍五入，默认为否
function RALogicUtil:num2percent(num, countAfterDot, isRound)
	if countAfterDot == nil or countAfterDot < 0 then
		countAfterDot = 2
	end
	local num = num or 0
	local isRound = isRound or false
	local num100Str = self:numCutAfterDot(num * 100, countAfterDot, isRound)..'%'
	return num100Str
end


--获得下一等级的exp（当前等级的最大exp）
function RALogicUtil:getNextLevelExp()
    local currentLevel = RAPlayerInfoManager.getPlayerBasicInfo().level
    local nextLevel = currentLevel + 1
    if nextLevel > RAGameConfig.MAX_LEVEL then
        nextLevel = RAGameConfig.MAX_LEVEL
    end

    local id = RAGameConfig.ConfigIDFragment.ID_PLAYER_LEVEL + nextLevel - 1
    local ret = 0
    local player_level_conf = RARequire("player_level_conf")
    if player_level_conf[id] ~= nil then
        ret = player_level_conf[id].exp
    end
    return ret
end

--获得当前等级的最大体力
function RALogicUtil:getCurrMaxPower()
    return RAPlayerInfoManager.getPlayerVitMax()
end

return RALogicUtil;