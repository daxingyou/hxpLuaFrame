--============================================
-- table counted
-- 

local value_property_name_for_count = 'default___property___count'


local MapCounted = {}

function MapCounted:New()
	local o = {
		staticCount = 0, 
		count2Key = {},

		realCount = 0,
		realMap = {},

		-- record valued count
		-- endTmpCount = 0,
		frontTmpCount = 0,
	}
	setmetatable(o,self)
    self.__index = self
	return o
end

function MapCounted:Add(key, value)
	if key ~= nil and value ~= nil then
		self.staticCount = self.staticCount + 1
		value[value_property_name_for_count] = self.staticCount
		self.realMap[key] = value
		self.realCount = self.realCount + 1
		self.count2Key[self.staticCount] = key
	end
end

-- return value and count
function MapCounted:FindByKey(key)
	if key == nil then return nil end
	local value = self.realMap[key]
	return value, value[value_property_name_for_count]
end

-- find last value
function MapCounted:FindEnd()
	local maxCount = self.staticCount	
	for i = maxCount, 1,-1 do
		local key = self.count2Key[i]
		local value = self.realMap[key]
		if value ~= nil then
			print('MapCounted:FindEnd()  value count:'.. value[value_property_name_for_count].. '  for circle count i:'..i)
			return value, value[value_property_name_for_count]
		end
	end
	return nil, 0
end

-- find front value
function MapCounted:FindFront()
	local startCount = self.frontTmpCount	
	for i = startCount, self.staticCount do
		local key = self.count2Key[i]
		local value = self.realMap[key]
		if value ~= nil then
			print('MapCounted:FindFront()  value count:'.. value[value_property_name_for_count].. '  for circle count i:'..i)
			self.frontTmpCount = i
			return value, value[value_property_name_for_count]
		end
	end
	return nil, 0
end

-- remove by key
-- return status and value count
function MapCounted:RemoveByKey(key)
	if key == nil then return nil end
	local value = self.realMap[key]
	if value ~= nil then		
		local valueCount = value[value_property_name_for_count]		
		self.realMap[key] = nil
		self.count2Key[valueCount] = nil
		value[value_property_name_for_count] = nil
		self.realCount = self.realCount - 1
		return true, valueCount
	end
	return false, 0
end

function MapCounted:GetStaticCount()
	return self.staticCount
end

function MapCounted:GetRealCount()
	return self.realCount
end

function MapCounted:IsEmpty()
	return self.realCount <= 0
end

return MapCounted