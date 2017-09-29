local RAWorldConfigManager = 
{
	mainbase_keys 	= nil,
	office_conf 	= nil
}

function RAWorldConfigManager:GetResConfig(resId)
	local res_conf = RARequire('world_resource_conf')[tonumber(resId)] or {}
	local res_show = {}

	local resType = res_conf.resType
	if resType then
		res_show = RARequire('world_resshow_conf')[resType] or {}
	end

	return res_conf, res_show
end

--根据资源类型和等级，找到资源对应的实际id
function RAWorldConfigManager:GetResIdByTypeAndLevel(resType, level)
	local world_resource_conf = RARequire('world_resource_conf')
	for k,v in pairs(world_resource_conf) do
		if v.resType == tonumber(resType) and v.level == tonumber(level) then
			return v.id, v
		end
	end
	return nil, nil	
end

function RAWorldConfigManager:GetMonsterConfig(monsterId)
	local mons_cfg = RARequire('world_enemy_conf')[monsterId] or {}
	return mons_cfg
end

function RAWorldConfigManager:GetResDefenseOffset(resType)
	local res_show = RARequire('world_resshow_conf')[resType] or {}
	local Utilitys = RARequire('Utilitys')
	return Utilitys.getCcpFromString(res_show['defenseOffset'])
end

function RAWorldConfigManager:GetMonsterConfigAttr(monsterId, attrName)
	local cfg = self:GetMonsterConfig(monsterId)
	if cfg.id == nil then return nil end
	return cfg[attrName]
end

--（用前除以1000）
function RAWorldConfigManager:GetResBaseCollectSpeed(resType)
	-- collectRes1007speed
	-- collectRes1008speed
	-- collectRes1009speed
	-- collectRes1010speed
	local world_march_const_conf = RARequire('world_march_const_conf')
	local keyStr = 'collectRes' .. resType ..'speed'
	local speed = 0
	local cfg = world_march_const_conf[keyStr]
	if cfg ~= nil then
		speed = cfg.value / 1000
	end
	return speed
end


--（1点=x负重）
function RAWorldConfigManager:GetResBaseLoadNum(resType)
	-- res1007Weight
	-- res1008Weight
	-- res1009Weight
	-- res1010Weight

	local world_march_const_conf = RARequire('world_march_const_conf')
	local keyStr = 'res' .. resType ..'Weight'
	local load = 0
	local cfg = world_march_const_conf[keyStr]
	if cfg ~= nil then
		load = cfg.value
	end
	return load
end

function RAWorldConfigManager:GetTerritoryBuildingCfg(buildingType)
	local territory_building_conf = RARequire('territory_building_conf')
	return territory_building_conf[buildingType]
end

-- 获取基地Spine
function RAWorldConfigManager:GetCitySpineByLevel(level)
	level = level or 1

	self:_initMainbaseKeys()
	for _, k in ipairs(self.mainbase_keys) do
		if level >= k then
			local base_conf = RARequire('world_mainbase_conf')
			return base_conf[k].spine
		end
	end
	return '201003'
end

-- 获取基地图标
function RAWorldConfigManager:GetCityIconByLevel(level)
	level = level or 1

	self:_initMainbaseKeys()
	for _, k in ipairs(self.mainbase_keys) do
		if level >= k then
			local base_conf = RARequire('world_mainbase_conf')
			return base_conf[k].icon
		end
	end
	return 'Favorites_Icon_Building_01.png'
end

-- 获取基地名牌偏移
function RAWorldConfigManager:GetCityLvOffsetByLevel(level)
	level = level or 1
	self:_initMainbaseKeys()
	for _, k in ipairs(self.mainbase_keys) do
		if level >= k then
			local base_conf = RARequire('world_mainbase_conf')
			local Utilitys = RARequire('Utilitys')
			return Utilitys.getCcpFromString(base_conf[k].lvOffset, ',')
		end
	end
	return RACcp(-128, 124)
end

function RAWorldConfigManager:_initMainbaseKeys()
	if self.mainbase_keys == nil then
		local base_conf = RARequire('world_mainbase_conf')
		local common = RARequire('common')
		self.mainbase_keys = common:table_keys(base_conf)
		table.sort(self.mainbase_keys, function (a, b)
			return a > b
		end)
	end
end

-- 获取据点信息
function RAWorldConfigManager:GetStrongholdCfg(id)
	return (RARequire('territory_guard_conf')[id] or {})
end

function RAWorldConfigManager:GetSuperMineCfg(mineType)
	return (RARequire('super_mine_conf')[mineType] or {})
end

function RAWorldConfigManager:GetOfficialPositionList()
	if self.office_conf == nil then
		self.office_conf = {}

		for id, cfg in pairs(RARequire('official_position_conf') or {}) do
			local type = cfg.officeType
			if type then
				if self.office_conf[type] == nil then
					self.office_conf[type] = {id}
				else
					table.insert(self.office_conf[type], id)
				end
			end
		end

		for _, idList in pairs(self.office_conf) do
			table.sort(idList)
		end
	end

	return self.office_conf
end

function RAWorldConfigManager:GetOfficialPositionCfg(id)
	return (RARequire('official_position_conf')[id] or {})
end

-- 获取官职福利加成
function RAWorldConfigManager:GetOfficialWelfareStr(id, glue, fmt, buffVal)
	local cfg = self:GetOfficialPositionCfg(id)
	
	local welfare = cfg.welfare
	if welfare == nil or welfare == '' then
		return '', nil
	end

	local glue = glue or '<br/>'
	local fmt = fmt or '@BuffDescFmt'

	local RAStringUtil = RARequire('RAStringUtil')
	local buffStrTb = RAStringUtil:split(welfare, ',') or {}

	local strTb = {}
	for _, subStr in ipairs(buffStrTb) do
		local buffTb = RAStringUtil:split(subStr, '_') or {}
		local buffId, buffNum = unpack(buffTb)
		buffNum = buffVal or buffNum
		if buffId and buffNum then
			local str = _RALang(fmt, _RALang('@BuffDesc_' .. buffId), buffNum)
			table.insert(strTb, str)
		end
	end

	return table.concat(strTb, glue), strTb
end


function RAWorldConfigManager:GetPresidentGiftCfg(id)
	return (RARequire('president_gift_conf')[id] or {})
end

function RAWorldConfigManager:GetPresidengFlag(id)
	return (RARequire('president_flag_conf')[id] or {icon = 'President_Flag_01.png'}).icon
end

return RAWorldConfigManager