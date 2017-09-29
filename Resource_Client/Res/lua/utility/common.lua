
local tostring = tostring
local tonumber = tonumber

local common = {
    framesMap = {}
}

function common:reset()
    self.framesMap = {}
end


function common:fillHtmlStr(key, ...)
    local htmlConf = RARequire("html_zh_cn")
	local content = htmlConf[key];
	if content ~= nil then
	    return common:fill(content, ...);
	end
	return "";
end

function common:fill(s, ... )
	local o = tostring(s)
	for i=1, select("#", ...) do
		o = GameMaths:replaceStringWithCharacterAll(o, "{"..tostring(i-1).."}", tostring(select(i,...)))
	end
	return o
end

--»ñÈ¡µ±Ç°ÃëÊ±¼ä
function common:getCurTime()
    local RAPlayerInfoManager  = RARequire("RAPlayerInfoManager")
    return os.time() + RAPlayerInfoManager.offsetTime
end

--»ñÈ¡µ±Ç°ºÁÃëÊ±¼ä
function common:getCurMilliTime()
    return self:getCurTime() * 1000
end

function common:getFrameTime()
    return GamePrecedure:getInstance():getFrameTime()
end

function common:log(format, ...)
	CCLuaLog(string.format(format, ...))
end

function common:CCMessageBox(format,...)
    CCMessageBox(string.format(format, ...),"debug info")
end

function common:table_combine(keys, values)
	local tb = {}
	for index, key in ipairs(keys) do
		tb[key] = values[index]
	end
	return tb
end

function common:table_combineNumber(keys, start, step)
	local tb = {};
	
	local val = start or 0;
	local step = step or 1;
	for _, key in ipairs(keys) do
		tb[key] = val;
		val = val + step;
	end
	
	return tb;
end

--simple and rough version, be careful
function common:table_merge(...)
	local tb = {}
	for i = 1, select("#", ...) do
		table.foreach((select(i, ...)), function(k, v)
			tb[k] = v
		end)
	end
	return tb
end

function common:table_map(tb, func)
	table.foreach(tb, function(k, v) tb[k] = func(v) end)
end

function common:table_reflect(tb, func)
	local _tb = {};
	table.foreach(tb, function(k, v) _tb[k] = func(v) end);
	return _tb;
end

function common:table_keys(tb)
	local keys = {}
	for k, _ in pairs(tb) do table.insert(keys, k) end
	return keys
end

function common:table_values(tb)
	local values = {}
	table.foreach(tb, function(k, v) table.insert(values, v) end)
	return values
end

function common:table_contains(tb, val)
	for _, v in pairs(tb) do
		if v == val then return true; end
	end
	return false;
end

--not deep copy
function common:table_removeFromArray(tb, val)
	local _tb = {};
	for _, v in ipairs(tb) do
		if v ~= val then
			table.insert(_tb, v);
		end
	end
	return _tb;
end

--not deep copy
function common:table_sub(tb, start, len)
	local _tb = {};
	for i = start, start + len - 1 do
		local v = tb[i];
		if v then
			table.insert(_tb, v);
		end
	end
	return _tb;
end

function common:table_tail(tb, len)
	local _tb = {};
	for i = #tb, #tb - len + 1, -1 do
		local v = tb[i];
		if v then
			table.insert(_tb, v);
		end
	end
	return _tb;
end

function common:table_isEmpty(tb)
	if tb then
		for _, v in pairs(tb) do
			return false;
		end
	end
	return true;
end

function common:table_filter(tb, filter)
	local _tb = {};
	for k, v in pairs(tb) do
		if filter(k, v) then
			_tb[k] = v;
		end
	end
	return _tb;
end

function common:table_arrayFilter(tb, filter)
	local _tb = {};
	for _, v in pairs(tb) do
		if filter(v) then
			table.insert(_tb, v);
		end
	end
	return _tb;
end

function common:table_flip(tb)
	local _tb = {};
	table.foreach(tb, function(k, v) _tb[v] = k; end);
	return _tb;
end

function common:table_implode(tb, glue)
	local str = "";
	for k, v in pairs(tb) do
		if str ~= "" then
			str = str .. glue;
		end
		str = str .. tostring(v);
	end
	return str;
end

function common:table_count(tb)
	local c = 0;
	for k, v in pairs(tb) do 
        if v ~=nil then
            c = c + 1; 
        end
    end
	return c;
end

function common:table_arrayIndex(tb, v)
	for i, _v in ipairs(tb) do
		if _v == v then
			return i;
		end
	end
	return -1;
end

function common:table_isSame(tb_1, tb_2)
	--to be better
	for k, v in pairs(tb_1) do
		if v ~= tb_2[k] then
			return false;
		end
	end
	for k, v in pairs(tb_2) do
		if v ~= tb_1[k] then
			return false;
		end
	end
	return true;
end

-- 浅拷贝
function common:table_copy(fromTb, toTb)
	if type(fromTb) ~= 'table' or type(toTb) ~= 'table' then return end

	for k, v in pairs(fromTb) do
		toTb[k] = v
	end
end

function common:table_simpleEqual(t1,t2)
    if #t1 ~= #t2 then return false end
    for k,v in pairs(t1) do
        if v ~= t2[k] then
            return false
        end
    end
    return true
end

-- if 'tb' contains 'val', then remove it, else add 'val'
function common:table_xor(tb, val)
	local hit = false
	for k, v in ipairs(tb) do
		if v == val then
			tb[k] = nil
			hit = true
		end
	end
	if not hit then table.insert(tb, val) end
end

function common:table_rsort(tb)
	table.sort(tb, function (a, b)
		return a > b
	end)
end
function common:trim(s)
	return (tostring(s or ""):gsub("^%s+", ""):gsub("%s+$", ""))
end

function common:fill_lua(s, ...)
	local o = tostring(s)
	for i = 1, select("#", ...) do
		o = o:gsub("#v" .. i .. "#", tostring(select(i, ...)))
	end
	return o
end

function common:getPowSize(num)
	local powSize = 1;
	while num ~= 1 do
		num = math.ceil(num / 2)
		powSize = powSize * 2
	end
	return powSize
end

function common:deepCopy(object)
	local lookup_table = {}
	
	local function _copy(object)
		if type(object) ~= "table" then
			return object
		elseif lookup_table[object] then
			return lookup_table[object]
		end
		
		local new_table = {}
		lookup_table[object] = new_table
		for index, value in pairs(object) do
			new_table[_copy(index)] = _copy(value)
		end
		return setmetatable(new_table, getmetatable(object))
	end
	
	return _copy(object)
end


function common:math_round(data)
    return math.floor(data + .5)
end

function common:clamp(val, min, max)
    if val < min then return min end
    if val > max then return max end
    return val
end

-- 是否是无穷数
function common:isInf(num)
	return num == math.huge or num == -math.huge
end

function common:isNaN(num)
	return num ~= num
end

-- 是否是空字符串
function common:isEmptyStr(str)
	return str == nil or str == ''
end

--ÅÐ¶ÏÎÄ¼þÊÇ·ñ´æÔÚ
function common:isFileExist(fileName)
    local filePath = CCFileUtils:sharedFileUtils():fullPathForFilename(fileName)
    return RAGameUtils:isFileExist(fileName),filePath
end


--Ìí¼ÓSpriteFrame
function common:addSpriteFramesWithFile(plist,pic)
    if common:isFileExist(plist) and common:isFileExist(pic) then
        if self.framesMap[plist] == nil then
        	CCSpriteFrameCache:sharedSpriteFrameCache():addSpriteFramesNameWithFile(plist);
            -- CCSpriteFrameCache:sharedSpriteFrameCache():addSpriteFramesWithFile(plist,pic);
            self.framesMap[plist] = true
        else
            return true
        end
        return true
    end
    return false
end

-- add plist to cache with color key
-- maskColorKey = string
function common:addSpriteFramesWithFileMaskColor(plist, maskColorKey)	
    if common:isFileExist(plist) then
    	local isUseColor = true
    	if maskColorKey == nil or maskColorKey == '' then
    		isUseColor = false
    		maskColorKey = ''
    	end
        CCSpriteFrameCache:sharedSpriteFrameCache():addSpriteFramesWithFile(plist, isUseColor, maskColorKey)
        return true
    end
    return false
end


function common:playEffect(name,id)
	if name == nil then return end

    local RAGameConfig = RARequire("RAGameConfig")
    local playName = name
    if id ~= nil then
        playName = name.."_"..id
    end
    local playPath = RAGameConfig.Sound[playName]
    if not playPath then
        playPath = VaribleManager:getInstance():getSetting("ClickSound")
    end
    SoundManager:getInstance():playEffect(playPath);
end

function common:CalcCrc(str)
    local result = RAGameUtils:CalcCrc(str,string.len(str),0)
    return result
end

--des: judge if it's chinese char 
function common:checkChineseChar(c)
    local bit = RARequire("bit")
    local byteC = c:byte()
    local x80 = 128
    local result = bit:band(byteC,x80)
    if result == 0 then
        return false
    else
        return true
    end
end

--得到字符数目  1个汉字算2个字符
function common:getCharsNum(str)
	if str == nil or str == '' then 
		return 0
	else 
		local num = 0
		local len = #str

		for i=1,len do
			local c = str:sub(i,i)
			if self:checkChineseChar(c) == true then 
				num = num + 2
			else 
				num = num + 1
			end 
		end

		return num
	end 
end

--des: check str validate,it's alphanumerical and "_","-"," " character or chinese char
--param: str: input string
--pattern: support notations, like [%w_ -]
function common:checkStringValidate(str,pattern)
	if str == nil then return end
    if pattern == nil then pattern = "[%w_-]" end
	local len = #str
    for i=1,len do
    	local c = str:sub(i,i)
    	--step.1 judge if it's alphanumerical and "_","-"," " character
    	local ret1 = c:match(pattern)
    	if ret1 == nil then
            --step.2 judge if it's chinese char
    		if self:checkChineseChar(c) == false then
                return false
            end
    	end
    end
    return true
end

--[[
    desc：数字中插入逗号
]]--
function common:commaSeperate(num)
    local formatted, k = tostring(tonumber(num)), 0
    while true do
        formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)",'%1,%2')
        if k == 0 then
            break
        end
    end

    return formatted
end


function common:createGmItem(container,callback,position,placeHoldText,editBoxSize)
    local RAGameConfig = RARequire("RAGameConfig")
    local size = editBoxSize or CCSize(500,40)
    local editbox = CCEditBox:create(size, 
    CCScale9Sprite:create(RAGameConfig.ButtonBg.GARY))
    local function editboxEventHandler(eventType)
        if eventType == "began" then
            -- triggered when an edit box gains focus after keyboard is shown
        elseif eventType == "ended" then
            -- triggered when an edit box loses focus after keyboard is hidden.
        elseif eventType == "changed" then
            -- triggered when the edit box text was changed.
        elseif eventType == "return" then
            -- triggered when the return button was pressed or the outside area of keyboard was touched.
            local commandData = editbox:getText()
            callback(commandData)
        end
    end
    editbox:setPlaceHolder(placeHoldText);
    editbox:setAnchorPoint(ccp(0,0))
    editbox:setFontSize(20);
    editbox:setFontName(RAGameConfig.DefaultFontName)
    editbox:setMaxLength(100)
    editbox:registerScriptEditBoxHandler(editboxEventHandler)
    editbox:setPosition(position);
    local ttf = CCLabelTTF:create("", "Helvetica", 20)
    ttf:setString(placeHoldText..":")
    ttf:setColor(COLOR_TABLE[COLOR_TYPE.WHITE])
    ttf:setAnchorPoint(ccp(0,0))
    ttf:setPosition(ccp(position.x,position.y + 50))
    container:addChild(ttf)
    container:addChild(editbox)
end

return common