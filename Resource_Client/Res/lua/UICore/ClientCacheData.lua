
ClientCache = {}
local cacehData = {}

function ClientCache.haveKey(key)
	if cacehData[key] then
		return true
	end
	return false
end

function ClientCache.addValue(key,value)
	if not ClientCache.haveKey(key) then
		cacehData[key] = value
	end
end

function ClientCache.setValue(key,value)
	cacehData[key] = value
end

function ClientCache.getValue(key)
	return cacehData[key]
end	

function ClientCache.deleteValue(key)
	if ClientCache.haveKey(key) then
		cacehData[key] = nil
	end
end
