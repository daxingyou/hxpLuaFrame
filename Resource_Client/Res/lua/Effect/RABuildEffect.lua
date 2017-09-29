
local RALogicUtil = RARequire("RALogicUtil")
local Const_pb = RARequire("Const_pb")
local build_effect_conf = RARequire("build_effect_conf")
local effectid_conf=RARequire("effectid_conf")
local RAStringUtil = RARequire("RAStringUtil")
--根据作用号获得影响数值

-- local FACTOR_EFFECT_DIVIDE=100
local RABuildEffect={}
--记录所有建筑 不同属性对应的作用号影响

--建筑工厂
--[占用电量]
function RABuildEffect:getFactoryElectricConsume(buildType,property)
	
	--基础占电量*（1-作用值/FACTOR_EFFECT_DIVIDE00）
	local effectInfo=build_effect_conf[buildType]
	if not effectInfo  then return 0 end
	local effectId = effectInfo[property]
	local effectValue = RALogicUtil:getEffectResult(tonumber(effectId))

	local result=self.configValue*(1-effectValue/FACTOR_EFFECT_DIVIDE)

	return result

end


--兵工厂
--[占用电量,训练数量,训练速度]
function RABuildEffect:getBarracksElectricConsume(buildType,property)
	 local result=self:getFactoryElectricConsume(buildType,property)
	 return result
end

function RABuildEffect:getBarracksRainQuantit(buildType,property)
	--单次训练数=基础训练数+作用值

	local effectInfo=build_effect_conf[buildType]
	if not effectInfo  then return 0 end
	local effectId = effectInfo[property]
	local effectData=effectid_conf[tonumber(effectId)]
	local effectValue = RALogicUtil:getEffectResult(tonumber(effectId))
	
	local result=self.configValue+effectValue

	return result

end


---------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------

--获取数值作用号值
function RABuildEffect:getEffectValue(buildType,property)

	local effectInfo=build_effect_conf[buildType]
	if not effectInfo  then return 0 end
	local effectIds = effectInfo[property]

	effectIds = RAStringUtil:split(effectIds,",")

	local totalEffectValue = 0
	local totalValue = 0

	local effectidConf = RARequire("effectid_conf")

	for i=1,#effectIds do
		local effectId = tonumber(effectIds[i])
		local effectValue = RALogicUtil:getEffectResult(effectId)

		local effectIdData = effectidConf[effectId]

		if not effectIdData then
			 break
		end

		--effectIdData.type 为 百分比值
		if effectIdData.type == 1 then
			local value = self.configValue * ( 1 + effectValue / FACTOR_EFFECT_DIVIDE )
			value = value - self.configValue
			totalEffectValue = totalEffectValue + value
		else
			totalEffectValue = totalEffectValue + effectValue	
		end

		totalValue = totalValue + effectValue
	end

	local result = self.configValue + totalEffectValue
	--作用号 百分比的目前统计只有 4种兵营的训练速度 和 市场税率
	if property == "trainSpeed" or property == "marketTax" then
		result = self.configValue + totalValue / 100
	end	

	return result
end

---------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------

function RABuildEffect:getBarracksTranSpeed(buildType,property)

	local effectInfo=build_effect_conf[buildType]
	if not effectInfo  then return 0 end
	local effectId = effectInfo[property]

	effectId=RAStringUtil:split(effectId,",")
	local effectValue1 = RALogicUtil:getEffectResult(tonumber(effectId[1]))
	local effectValue2 = RALogicUtil:getEffectResult(tonumber(effectId[2]))

	--local result=self.configValue*(1+(effectValue1+effectValue2)/FACTOR_EFFECT_DIVIDE)
	local result = self.configValue + (effectValue1 + effectValue2) / 100
	return result

end

--战车工厂
--[占用电量,训练数量,训练速度]
function RABuildEffect:getWarfactoryElectricConsume(buildType,property)
	local result=self:getFactoryElectricConsume(buildType,property)
	return result
end

function RABuildEffect:getWarfactoryRainQuantit(buildType,property)

	--单次训练数=基础训练数+作用值
	local effectInfo=build_effect_conf[buildType]
	if not effectInfo  then return 0 end
	local effectId = effectInfo[property]
	local effectData=effectid_conf[tonumber(effectId)]
	local effectValue = RALogicUtil:getEffectResult(tonumber(effectId))
	
	local result=self.configValue+effectValue

	return result

end

function RABuildEffect:getWarfactoryTranSpeed(buildType,property)

	local effectInfo=build_effect_conf[buildType]
	if not effectInfo  then return 0 end
	local effectId = effectInfo[property]

	effectId=RAStringUtil:split(effectId,",")
	local effectValue1 = RALogicUtil:getEffectResult(tonumber(effectId[1]))
	local effectValue2 = RALogicUtil:getEffectResult(tonumber(effectId[2]))

	local result=self.configValue*(1+(effectValue1+effectValue2)/FACTOR_EFFECT_DIVIDE)
	return result
	
end

--	//远程火力工厂
--[占用电量,训练数量,训练速度]
function RABuildEffect:getRemoteFirefactoryElectricConsume(buildType,property)
	local result=self:getFactoryElectricConsume(buildType,property)
	return result
end

function RABuildEffect:getRemoteFirefactoryRainQuantit(buildType,property)

	local effectInfo=build_effect_conf[buildType]
	if not effectInfo  then return 0 end
	local effectId = effectInfo[property]
	local effectData=effectid_conf[tonumber(effectId)]
	local effectValue = RALogicUtil:getEffectResult(tonumber(effectId))
	
	local result=self.configValue+effectValue

	return result

end

function RABuildEffect:getRemoteFirefactoryTranSpeed(buildType,property)
	local effectInfo=build_effect_conf[buildType]
	if not effectInfo  then return 0 end
	local effectId = effectInfo[property]

	effectId=RAStringUtil:split(effectId,",")
	local effectValue1 = RALogicUtil:getEffectResult(tonumber(effectId[1]))
	local effectValue2 = RALogicUtil:getEffectResult(tonumber(effectId[2]))

	local result=self.configValue*(1+(effectValue1+effectValue2)/FACTOR_EFFECT_DIVIDE)
	return result
end

--空指部
--[占用电量,训练数量,训练速度]
function RABuildEffect:getAirforceCommandElectricConsume(buildType,property)
	local result=self:getFactoryElectricConsume(buildType,property)
	return result
end

function RABuildEffect:getAirforceCommandRainQuantit(buildType,property)

	local effectInfo=build_effect_conf[buildType]
	if not effectInfo  then return 0 end
	local effectId = effectInfo[property]
	local effectData=effectid_conf[tonumber(effectId)]
	local effectValue = RALogicUtil:getEffectResult(tonumber(effectId))
	
	local result=self.configValue+effectValue

	return result

end

function RABuildEffect:getAirforceCommandTranSpeed(buildType,property)
	local effectInfo=build_effect_conf[buildType]
	if not effectInfo  then return 0 end
	local effectId = effectInfo[property]

	effectId=RAStringUtil:split(effectId,",")
	local effectValue1 = RALogicUtil:getEffectResult(tonumber(effectId[1]))
	local effectValue2 = RALogicUtil:getEffectResult(tonumber(effectId[2]))

	local result=self.configValue*(1+(effectValue1+effectValue2)/FACTOR_EFFECT_DIVIDE)
	return result
	
end


--作战实验室
--[占用电量]
function RABuildEffect:getFightingLaboratoryElectricConsume(buildType,property)
	local result=self:getFactoryElectricConsume(buildType,property)
	return result
end


--大使馆
--[占用电量,援助减少时间，可受援助次数，援助单位上限]
function RABuildEffect:getEmbassyElectricConsume(buildType,property)
	local result=self:getFactoryElectricConsume(buildType,property)
	return result
end


function RABuildEffect:getEmbassyAssistTime(buildType,property)

	local result = 0
	return result

end

function RABuildEffect:getEmbassyAssistLimit(buildType,property)

	--基础数+作用值
	local effectInfo=build_effect_conf[buildType]
	if not effectInfo  then return 0 end
	local effectId = effectInfo[property]
	local effectData=effectid_conf[tonumber(effectId)]
	local effectValue = RALogicUtil:getEffectResult(tonumber(effectId))
	
	local result=self.configValue+effectValue

	return result

end



function RABuildEffect:getEmbassyAssistUnitLimit(buildType,property)
	--基础数+作用值
	local effectInfo=build_effect_conf[buildType]
	if not effectInfo  then return 0 end
	local effectId = effectInfo[property]
	local effectData=effectid_conf[tonumber(effectId)]
	local effectValue = RALogicUtil:getEffectResult(tonumber(effectId))
	
	local result=self.configValue+effectValue

	return result

end


-- 贸易中心
--[占用电量，市场负重，市场税率]
function RABuildEffect:getTradeCentreElectricConsume(buildType,property)
	local result=self:getFactoryElectricConsume(buildType,property)
	return result
end
function RABuildEffect:getTradeCentreMarketBurden(buildType,property)

	--负重数=基础负重数*max（(1+作用值/FACTOR_EFFECT_DIVIDE）,0）

	local effectInfo=build_effect_conf[buildType]
	if not effectInfo  then return 0 end
	local effectId = effectInfo[property]
	local effectData=effectid_conf[tonumber(effectId)]
	local effectValue = RALogicUtil:getEffectResult(tonumber(effectId))
	local result=self.configValue*(1+effectValue/FACTOR_EFFECT_DIVIDE)
	return result


end
function RABuildEffect:getTradeCentreMarketTax(buildType,property)
	local effectValue = 0
	return effectValue
end


-- 卫星通讯所
--[占用电量，集结上限]
function RABuildEffect:getSatelliteElectricConsume(buildType,property)
	local result=self:getFactoryElectricConsume(buildType,property)
	return result
end

function RABuildEffect:getSatellitebuildupLimit(buildType,property)

	--基础数*（1+作用值）
	local effectInfo=build_effect_conf[buildType]
	if not effectInfo  then return 0 end
	local effectId = effectInfo[property]
	local effectData=effectid_conf[tonumber(effectId)]
	local effectValue = RALogicUtil:getEffectResult(tonumber(effectId))
	local result=self.configValue*(1+effectValue)
	return result

end


-- 装备研究所
--[占用电量]
function RABuildEffect:getEquipResearchElectricConsume(buildType,property)
	local result=self:getFactoryElectricConsume(buildType,property)
	return result
end



-- 作战指挥部
--[占用电量]
function RABuildEffect:getFightingElectricConsume(buildType,property)
	local result=self:getFactoryElectricConsume(buildType,property)
	return result
end

--[带兵上限]
function RABuildEffect:getFightingattackUnitLimit(buildType,property )

-- 	出征部队数=原部队数*（FACTOR_EFFECT_DIVIDE+作用值）/FACTOR_EFFECT_DIVIDE
--  出征部队数=原部队数+作用值

	local effectInfo=build_effect_conf[buildType]
	if not effectInfo  then return 0 end
	local effectId = effectInfo[property]

	effectId=RAStringUtil:split(effectId,",")
	local effectValue1 = RALogicUtil:getEffectResult(tonumber(effectId[1]))
	local effectValue2 = RALogicUtil:getEffectResult(tonumber(effectId[2]))

	local result1=self.configValue*(FACTOR_EFFECT_DIVIDE+effectValue1)/FACTOR_EFFECT_DIVIDE
	local result2=result1+effectValue2

	return result2


end

--军火商
--[占用电量]
function RABuildEffect:getArmsDealerElectricConsume(buildType,property)
	local result=self:getFactoryElectricConsume(buildType,property)
	return result
end

--雷达
--[占用电量]
function RABuildEffect:getRadarElectricConsume(buildType,property)
	local result=self:getFactoryElectricConsume(buildType,property)
	return result
end

--裂缝产生器
--[占用电量]
function RABuildEffect:getGapGeneratorElectricConsume(buildType,property)
	local result=self:getFactoryElectricConsume(buildType,property)
	return result
end


-- 	WAREHOUSE				 = 2024;	//仓库
--[占用电量，]
function RABuildEffect:getWarehouseElectricConsume(buildType,property)
	local result=self:getFactoryElectricConsume(buildType,property)
	return result
end

function RABuildEffect:getWarehouseresProtectA(buildType,property)
	-- 资源保护数=基础保护数*max（(1+作用值/FACTOR_EFFECT_DIVIDE）,0）

	local effectInfo=build_effect_conf[buildType]
	if not effectInfo  then return 0 end
	local effectId = effectInfo[property]

	effectId=RAStringUtil:split(effectId,",")
	local effectValue1 = RALogicUtil:getEffectResult(tonumber(effectId[1]))
	local effectValue2 = RALogicUtil:getEffectResult(tonumber(effectId[2]))

	local result1=self.configValue*(1+effectValue1/FACTOR_EFFECT_DIVIDE)
	local result2=result1+effectValue2

	return result2

end

function RABuildEffect:getWarehouseresProtectB(buildType,property)
	local effectInfo=build_effect_conf[buildType]
	if not effectInfo  then return 0 end
	local effectId = effectInfo[property]

	effectId=RAStringUtil:split(effectId,",")
	local effectValue1 = RALogicUtil:getEffectResult(tonumber(effectId[1]))
	local effectValue2 = RALogicUtil:getEffectResult(tonumber(effectId[2]))

	local result1=self.configValue*(1+effectValue1/FACTOR_EFFECT_DIVIDE)
	local result2=result1+effectValue2

	return result2
end

function RABuildEffect:getWarehouseresProtectC(buildType,property)
	local effectInfo=build_effect_conf[buildType]
	if not effectInfo  then return 0 end
	local effectId = effectInfo[property]

	effectId=RAStringUtil:split(effectId,",")
	local effectValue1 = RALogicUtil:getEffectResult(tonumber(effectId[1]))
	local effectValue2 = RALogicUtil:getEffectResult(tonumber(effectId[2]))

	local result1=self.configValue*(1+effectValue1/FACTOR_EFFECT_DIVIDE)
	local result2=result1+effectValue2

	return result2
end

function RABuildEffect:getWarehouseresProtectD(buildType,property)
	local effectInfo=build_effect_conf[buildType]
	if not effectInfo  then return 0 end
	local effectId = effectInfo[property]

	effectId=RAStringUtil:split(effectId,",")
	local effectValue1 = RALogicUtil:getEffectResult(tonumber(effectId[1]))
	local effectValue2 = RALogicUtil:getEffectResult(tonumber(effectId[2]))

	local result1=self.configValue*(1+effectValue1/FACTOR_EFFECT_DIVIDE)
	local result2=result1+effectValue2

	return result2
end

-- 	POWER_PLANT 			 = 2025;	//发电厂
--[产电量]
function RABuildEffect:getPowerPlantElectricGenerate(buildType,property)
	local effectInfo=build_effect_conf[buildType]
	if not effectInfo  then return 0 end
	local effectId = effectInfo[property]
	local effectData = effectid_conf[tonumber(effectId)]
	local effectValue = RALogicUtil:getEffectResult(tonumber(effectId))
	local result=self.configValue*(1+effectValue/FACTOR_EFFECT_DIVIDE)
	return result
end


-- 	HOSPITAL_STATION 		 = 2026;	//医护维修站
--[占用电量，伤兵上限]
function RABuildEffect:geHospitalStationElectricConsume(buildType,property)
	local result=self:getFactoryElectricConsume(buildType,property)
	return result
end

function RABuildEffect:geHospitalStationWoundedLimit(buildType,property)

	-- 伤兵上限=上限*（1+作用值/FACTOR_EFFECT_DIVIDE)

	local effectInfo=build_effect_conf[buildType]
	if not effectInfo  then return 0 end
	local effectId = effectInfo[property]

	effectId=RAStringUtil:split(effectId,",")
	local effectValue1 = RALogicUtil:getEffectResult(tonumber(effectId[1]))
	local effectValue2 = RALogicUtil:getEffectResult(tonumber(effectId[2]))

	local result1=self.configValue*(1+effectValue1/FACTOR_EFFECT_DIVIDE)
	local result2=result1+effectValue2

	return result2
end


-- 	ORE_REFINING_PLANT		 = 2101;	//矿石精鍊厂
--[占用电量，产资源每min,产资源上限]
function RABuildEffect:geOrePlantElectricConsume(buildType,property)
	local result=self:getFactoryElectricConsume(buildType,property)
	return result
end

function RABuildEffect:geOrePlantResPerMin(buildType,property)

	--先不算boost的影响

	local effectInfo=build_effect_conf[buildType]
	if not effectInfo  then return 0 end
	local effectId = effectInfo[property]

	effectId=RAStringUtil:split(effectId,",")
	local effectValue1 = RALogicUtil:getEffectResult(tonumber(effectId[1]))
	local effectValue2 = RALogicUtil:getEffectResult(tonumber(effectId[2]))

	local result=self.configValue*(FACTOR_EFFECT_DIVIDE+effectValue1+effectValue2)/FACTOR_EFFECT_DIVIDE
	return result

end

function RABuildEffect:geOrePlantResLimit(buildType,property)
	local effectValue = 0
	return effectValue
end


-- 	OIL_WELL 				 = 2102;	//油井
--[占用电量，产资源每min,产资源上限]
function RABuildEffect:getOilWellElectricConsume(buildType,property)
	local result=self:getFactoryElectricConsume(buildType,property)
	return result
end

function RABuildEffect:geOilWellResPerMin(buildType,property)
	local effectInfo=build_effect_conf[buildType]
	if not effectInfo  then return 0 end
	local effectId = effectInfo[property]

	effectId=RAStringUtil:split(effectId,",")
	local effectValue1 = RALogicUtil:getEffectResult(tonumber(effectId[1]))
	local effectValue2 = RALogicUtil:getEffectResult(tonumber(effectId[2]))

	local result=self.configValue*(FACTOR_EFFECT_DIVIDE+effectValue1+effectValue2)/FACTOR_EFFECT_DIVIDE
	return result
end

function RABuildEffect:geOilWellResLimit(buildType,property)
	local effectValue = 0
	return effectValue
end

-- 	STEEL_PLANT 			 = 2103;	//炼钢厂
--[占用电量，产资源每min,产资源上限]
function RABuildEffect:getSteelPlantElectricConsume(buildType,property)
	local result=self:getFactoryElectricConsume(buildType,property)
	return result
end

function RABuildEffect:geSteelPlantResPerMin(buildType,property)
	local effectInfo=build_effect_conf[buildType]
	if not effectInfo  then return 0 end
	local effectId = effectInfo[property]

	effectId=RAStringUtil:split(effectId,",")
	local effectValue1 = RALogicUtil:getEffectResult(tonumber(effectId[1]))
	local effectValue2 = RALogicUtil:getEffectResult(tonumber(effectId[2]))

	local result=self.configValue*(FACTOR_EFFECT_DIVIDE+effectValue1+effectValue2)/FACTOR_EFFECT_DIVIDE
	return result
end

function RABuildEffect:geSteelPlantResLimit(buildType,property)
	local effectValue = 0
	return effectValue
end

-- 	RARE_EARTH_SMELTER 		 = 2104;	//稀土冶炼厂
--[占用电量，产资源每min,产资源上限]
function RABuildEffect:getRareEarthElectricConsume(buildType,property)
	local result=self:getFactoryElectricConsume(buildType,property)
	return result
end

function RABuildEffect:geRareEarthResPerMin(buildType,property)
	local effectInfo=build_effect_conf[buildType]
	if not effectInfo  then return 0 end
	local effectId = effectInfo[property]

	effectId=RAStringUtil:split(effectId,",")
	local effectValue1 = RALogicUtil:getEffectResult(tonumber(effectId[1]))
	local effectValue2 = RALogicUtil:getEffectResult(tonumber(effectId[2]))

	local result=self.configValue*(FACTOR_EFFECT_DIVIDE+effectValue1+effectValue2)/FACTOR_EFFECT_DIVIDE
	return result
end

function RABuildEffect:geRareEarthResLimit(buildType,property)
	local effectValue = 0
	return effectValue
end


-- 	PRISM_TOWER 			 = 2151;	//光棱塔
--[占用电量]
function RABuildEffect:getPrismTowerElectricConsume(buildType,property)
	local result=self:getFactoryElectricConsume(buildType,property)
	return result
end
-- 	PATRIOT_MISSILE 		 = 2152;	//爱国者飞弹
--[占用电量]
function RABuildEffect:getPatriotMissileElectricConsume(buildType,property)
	local result=self:getFactoryElectricConsume(buildType,property)
	return result
end

-- 	PILLBOX 				 = 2153;	//机枪碉堡
--[占用电量]
function RABuildEffect:getPillBoxElectricConsume(buildType,property)
	local result=self:getFactoryElectricConsume(buildType,property)
	return result
end

-- 	CANNON 					 = 2154;	//巨炮
--[占用电量]
function RABuildEffect:getCannonElectricConsume(buildType,property)
	local result=self:getFactoryElectricConsume(buildType,property)
	return result
end
-----------------------------------------------------------------------------------

-- enum BuildingType
-- {
-- 	CONSTRUCTION_FACTORY	 = 2010;	//建筑工厂
-- 	BARRACKS 				 = 2011;	//兵营
-- 	WAR_FACTORY 			 = 2012;	//战车工厂
-- 	REMOTE_FIRE_FACTORY 	 = 2013;	//远程火力工厂
-- 	AIR_FORCE_COMMAND 		 = 2014;	//空指部
-- 	FIGHTING_LABORATORY 	 = 2015;	//作战实验室
-- 	EMBASSY 				 = 2016;	//大使馆
-- 	TRADE_CENTRE 			 = 2017;	//贸易中心
-- 	SATELLITE_COMMUNICATIONS = 2018;	//卫星通讯所
-- 	EQUIP_RESEARCH_INSTITUTE = 2019;	//装备研究所
-- 	FIGHTING_COMMAND 		 = 2020;	//作战指挥部
-- 	ARMS_DEALER 			 = 2021;	//军火商
-- 	RADAR 					 = 2022;	//雷达
-- 	GAP_GENERATOR 			 = 2023;	//裂缝产生器
-- 	WAREHOUSE				 = 2024;	//仓库
-- 	POWER_PLANT 			 = 2025;	//发电厂
-- 	HOSPITAL_STATION 		 = 2026;	//医护维修站
-- 	ORE_REFINING_PLANT		 = 2101;	//矿石精鍊厂
-- 	OIL_WELL 				 = 2102;	//油井
-- 	STEEL_PLANT 			 = 2103;	//炼钢厂
-- 	RARE_EARTH_SMELTER 		 = 2104;	//稀土冶炼厂
-- 	PRISM_TOWER 			 = 2151;	//光棱塔
-- 	PATRIOT_MISSILE 		 = 2152;	//爱国者飞弹
-- 	PILLBOX 				 = 2153;	//机枪碉堡
-- 	CANNON 					 = 2154;	//巨炮

-- }



--根据建筑类型 获得相应属性的作用号影响值 返回增量
--configValue:配置表里的值
--buildType 建筑类型
--property 相应的属性

function RABuildEffect:getAddValueByEffect(configValue,buildType,property)
	local effectInfo=build_effect_conf[buildType]
    if not effectInfo then return 0 end
	if not effectInfo[property]  then return 0 end

	local value = 0
	if property == "trainSpeed" then --兵营训练速度 
		value = self:getValueByEffect(configValue,buildType,property)
	else
		value = math.floor(self:getValueByEffect(configValue,buildType,property))	
	end

	local addValue = value - configValue

	return addValue
end


function RABuildEffect:getValueByEffect(configValue,buildType,property)

	self.configValue = configValue

	local result = RABuildEffect:getEffectValue(buildType, property)

	return result or 0

	-- if buildType==Const_pb.CONSTRUCTION_FACTORY and property=="electricConsume" then
	-- 	result = self:getFactoryElectricConsume(buildType,property)
	-- elseif  buildType==Const_pb.BARRACKS and property=="electricConsume" then
	-- 	result = self:getBarracksElectricConsume(buildType,property)
	-- elseif  buildType==Const_pb.BARRACKS and property=="trainQuantity" then
	-- 	result = self:getBarracksRainQuantit(buildType,property)
	-- elseif  buildType==Const_pb.BARRACKS and property=="trainSpeed" then
	-- 	result = self:getEffectPercentageValue(buildType,property)
	-- elseif  buildType==Const_pb.WAR_FACTORY and property=="electricConsume" then
	-- 	result = self:getWarfactoryElectricConsume(buildType,property)
	-- elseif  buildType==Const_pb.WAR_FACTORY and property=="trainQuantity" then
	-- 	result = self:getWarfactoryRainQuantit(buildType,property)
	-- elseif  buildType==Const_pb.WAR_FACTORY and property=="trainSpeed" then
	-- 	--result = self:getWarfactoryTranSpeed(buildType,property)
	-- 	result = self:getEffectPercentageValue(buildType,property)
	-- elseif  buildType==Const_pb.REMOTE_FIRE_FACTORY and property=="electricConsume" then
	-- 	result = self:getRemoteFirefactoryElectricConsume(buildType,property)
	-- elseif  buildType==Const_pb.REMOTE_FIRE_FACTORY and property=="trainQuantity" then
	-- 	result = self:getRemoteFirefactoryRainQuantit(buildType,property)
	-- elseif  buildType==Const_pb.REMOTE_FIRE_FACTORY and property=="trainSpeed" then
	-- 	--result = self:getRemoteFirefactoryTranSpeed(buildType,property)
	-- 	result = self:getEffectPercentageValue(buildType,property)
	-- elseif  buildType==Const_pb.AIR_FORCE_COMMAND and property=="electricConsume" then
	-- 	result = self:getAirforceCommandElectricConsume(buildType,property)
	-- elseif  buildType==Const_pb.AIR_FORCE_COMMAND and property=="trainQuantity" then
	-- 	result = self:getAirforceCommandRainQuantit(buildType,property)
	-- elseif  buildType==Const_pb.AIR_FORCE_COMMAND and property=="trainSpeed" then
	-- 	--result = self:getAirforceCommandTranSpeed(buildType,property)
	-- 	result = self:getEffectPercentageValue(buildType,property)
	-- elseif buildType==Const_pb.FIGHTING_LABORATORY and property=="electricConsume" then
	-- 	result = self:getFightingLaboratoryElectricConsume(buildType,property)
	-- elseif buildType==Const_pb.EMBASSY and property=="electricConsume" then
	-- 	result = self:getEmbassyElectricConsume(buildType,property)
	-- elseif buildType==Const_pb.EMBASSY and property=="assistTime" then
	-- 	result =self:getEmbassyAssistTime(buildType,property)
	-- elseif buildType==Const_pb.EMBASSY and property=="assistLimit" then
	-- 	result =self:getEmbassyAssistLimit(buildType,property)
	-- elseif buildType==Const_pb.EMBASSY and property=="assistUnitLimit" then
	-- 	result =self:getEmbassyAssistUnitLimit(buildType,property)
	-- elseif buildType==Const_pb.TRADE_CENTRE and property=="electricConsume" then
	-- 	result =self:getTradeCentreElectricConsume(buildType,property)
	-- elseif buildType==Const_pb.TRADE_CENTRE and property=="marketBurden" then
	-- 	result =self:getTradeCentreMarketBurden(buildType,property)
	-- elseif buildType==Const_pb.TRADE_CENTRE and property=="marketTax" then
	-- 	result =self:getEffectPercentageValue(buildType,property)
	-- elseif buildType==Const_pb.SATELLITE_COMMUNICATIONS and property=="electricConsume" then
	-- 	result =self:getSatelliteElectricConsume(buildType,property)
	-- elseif buildType==Const_pb.SATELLITE_COMMUNICATIONS and property=="buildupLimit" then
	-- 	result =self:getSatellitebuildupLimit(buildType,property)
	-- elseif buildType==Const_pb.EQUIP_RESEARCH_INSTITUTE and property=="electricConsume" then
	-- 	result =self:getEquipResearchElectricConsume(buildType,property)
	-- elseif buildType==Const_pb.FIGHTING_COMMAND and property=="electricConsume" then
	-- 	result =self:getFightingElectricConsume(buildType,property)
	-- elseif buildType==Const_pb.FIGHTING_COMMAND and property=="attackUnitLimit" then
	-- 	result =self:getFightingattackUnitLimit(buildType,property)
	-- elseif buildType==Const_pb.ARMS_DEALER and property=="electricConsume" then
	-- 	result =self:getArmsDealerElectricConsume(buildType,property)
	-- elseif buildType==Const_pb.RADAR and property=="electricConsume" then
	-- 	result =self:getRadarElectricConsume(buildType,property)
	-- elseif buildType==Const_pb.GAP_GENERATOR and property=="electricConsume" then
	-- 	result =self:getGapGeneratorElectricConsume(buildType,property)
	-- elseif buildType==Const_pb.WAREHOUSE and property=="electricConsume" then
	-- 	result =self:getWarehouseElectricConsume(buildType,property)
	-- elseif buildType==Const_pb.WAREHOUSE and property=="resProtectA" then
	-- 	result =self:getWarehouseresProtectA(buildType,property)
	-- elseif buildType==Const_pb.WAREHOUSE and property=="resProtectB" then
	-- 	result =self:getWarehouseresProtectB(buildType,property)
	-- elseif buildType==Const_pb.WAREHOUSE and property=="resProtectC" then
	-- 	result =self:getWarehouseresProtectC(buildType,property)
	-- elseif buildType==Const_pb.WAREHOUSE and property=="resProtectD" then
	-- 	result =self:getWarehouseresProtectD(buildType,property)
	-- elseif buildType==Const_pb.POWER_PLANT and property=="electricGenerate" then
	-- 	result =self:getPowerPlantElectricGenerate(buildType,property)
	-- elseif buildType==Const_pb.HOSPITAL_STATION and property=="electricConsume" then
	-- 	result =self:geHospitalStationElectricConsume(buildType,property)
	-- elseif buildType==Const_pb.HOSPITAL_STATION and property=="woundedLimit" then
	-- 	result =self:geHospitalStationWoundedLimit(buildType,property)
	-- elseif buildType==Const_pb.ORE_REFINING_PLANT and property=="electricConsume" then
	-- 	result =self:geOrePlantElectricConsume(buildType,property)
	-- elseif buildType==Const_pb.ORE_REFINING_PLANT and property=="resPerMin" then
	-- 	result=self:geOrePlantResPerMin(buildType,property)
	-- elseif buildType==Const_pb.ORE_REFINING_PLANT and property=="resLimit" then
	-- 	result=self:geOrePlantResLimit(buildType,property)
	-- elseif buildType==Const_pb.OIL_WELL and property=="electricConsume" then
	-- 	result =self:getOilWellElectricConsume(buildType,property)
	-- elseif buildType==Const_pb.OIL_WELL and property=="resPerMin" then
	-- 	result=self:geOilWellResPerMin(buildType,property)
	-- elseif buildType==Const_pb.OIL_WELL and property=="resLimit" then
	-- 	result=self:geOilWellResLimit(buildType,property)
	-- elseif buildType==Const_pb.STEEL_PLANT and property=="electricConsume" then
	-- 	result =self:getSteelPlantElectricConsume(buildType,property)
	-- elseif buildType==Const_pb.STEEL_PLANT and property=="resPerMin" then
	-- 	result=self:geSteelPlantResPerMin(buildType,property)
	-- elseif buildType==Const_pb.STEEL_PLANT and property=="resLimit" then
	-- 	result=self:geSteelPlantResLimit(buildType,property)
	-- elseif buildType==Const_pb.RARE_EARTH_SMELTER and property=="electricConsume" then
	-- 	result =self:getRareEarthElectricConsume(buildType,property)
	-- elseif buildType==Const_pb.RARE_EARTH_SMELTER and property=="resPerMin" then
	-- 	result=self:geRareEarthResPerMin(buildType,property)
	-- elseif buildType==Const_pb.RARE_EARTH_SMELTER and property=="resLimit" then
	-- 	result=self:geRareEarthResLimit(buildType,property)
	-- elseif buildType==Const_pb.PRISM_TOWER and property=="electricConsume" then
	-- 	result =self:getPrismTowerElectricConsume(buildType,property)
	-- elseif buildType==Const_pb.PATRIOT_MISSILE and property=="electricConsume" then
	-- 	result =self:getPatriotMissileElectricConsume(buildType,property)
	-- elseif buildType==Const_pb.PILLBOX and property=="electricConsume" then
	-- 	result =self:getPillBoxElectricConsume(buildType,property)
	-- elseif buildType==Const_pb.CANNON and property=="electricConsume" then
	-- 	result =self:getCannonElectricConsume(buildType,property)
	-- end 
	
	-- return result

end
return RABuildEffect
