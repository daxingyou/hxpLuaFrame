--============================================
-- a simple quene 
-- copy from <program in lua>
local List = {}
function List:New()
	local o = {first = 0, last = -1}
	setmetatable(o,self)
    self.__index = self
	return o
end

function List.PushFront(list,value)
	local first = list.first - 1
	list.first = first
	list[first] = value
end

function List.PushEnd(list,value)
	local last = list.last + 1
	list.last = last
	list[last] = value
end

function List.PopFront(list)
	local value
	if not List.IsEmpty(list) then
		value = list[list.first]
		list[list.first] = nil
		list.first = list.first + 1
	end
	return value
end

function List.GetTop(list)
	local value
	if not List.IsEmpty(list) then
		value = list[list.first]		
	end
	return value
end

function List.PopEnd(list)
	local value
	if not List.IsEmpty(list) then 
		value = list[list.last]
		list[list.last] = nil
		list.last = list.last - 1
	end
	return value
end	

function List.GetEnd(list)
	local value
	if not List.IsEmpty(list) then 
		value = list[list.last]		
	end
	return value
end

function List.IsEmpty(list)
	if list.first > list.last then
		return true
	end
	return false
end

return List