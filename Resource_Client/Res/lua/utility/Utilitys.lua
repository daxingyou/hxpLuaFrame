local bit = require('utility.bit')
local RAStringUtil = RARequire('RAStringUtil')

local Utilitys = {}

function Utilitys.autoReturn(s, width,wid)
	wid = wid or 0.5
    local les = string.len(s)
    local ret = ""
    local count = 0
    for i=1,les do
        local v = string.byte(s,i)
        if bit:band(v,128)==0 then
            count = count + wid
            if(count>width)then
                ret = ret .. "\n"
                count = 0
            end
        end
        if bit:band(v,128)~=0 and bit:band(v,64)~=0 then
            count = count + 1
            if(count>width)then
                ret = ret .. "\n"
                count = 0
            end
        end
        ret = ret .. string.char(v)
    end
    return ret
end

function Utilitys.Split(str, delim, maxNb)
	if str == nil then return {} end
    if string.find(str, delim) == nil then
        return {str}
    end
    if maxNb == nil or maxNb < 1 then
        maxNb = 0    -- No limit
    end
    local result = {}
    local pat = "(.-)" .. delim .. "()"
    local nb = 0
    local lastPos
    for part, pos in string.gfind(str, pat) do
        nb = nb + 1
        result[nb] = part
        lastPos = pos
        if nb == maxNb then break end
    end
    -- Handle the last field
    if nb ~= maxNb then
        result[nb + 1] = string.sub(str, lastPos)
    end
    return result
end

function Utilitys.trim(s)
	return (tostring(s or ""):gsub("^%s+", ""):gsub("%s+$", ""))
end

function Utilitys.fill(s, ...)
	local o = tostring(s)
	for i = 1, select("#", ...) do
		o = o:gsub("#v" .. i .. "#", (select(i, ...)))
	end
	return o
end

function Utilitys.stringAutoReturn(s, width)
	local lines = Utilitys.Split(tostring(s), "\n")
	for i, line in ipairs(lines) do
		lines[i] = GameMaths:stringAutoReturnForLua(line, width, 0)	
	end
	return table.concat(lines, "\n")
end

function Utilitys.setStringForLabel(container, strMap)
	for name, str in pairs(strMap) do
		local node = container:getVarLabelBMFont(name)
		if node then
			node:setString(tostring(str))
		else
			CCLuaLog("noSuchLabelBMFont====>" .. name)
		end
	end
end

function Utilitys.getStringFromSetting(varName)
	local setting, name = VaribleManager:getInstance():getSetting(varName)
	return setting
end

function Utilitys.getColorFromSetting(varName)
	--parseColor3B returns multi value
	local color3B = StringConverter:parseColor3B(common.getSettingVar(varName))
	return color3B
end

function Utilitys.setBlackBoardVariable(key, val)
	key = tostring(key)
	if BlackBoard:getInstance():hasVarible(key) then
		BlackBoard:getInstance():setVarible(key, val)
	else
		BlackBoard:getInstance():addVarible(key, val)
	end
end

--Be carefull: hasVarible, getVarible has double return value
function Utilitys.getBlackBoardVariable(key)
	if BlackBoard:getInstance():hasVarible(key) then
		return BlackBoard:getInstance():getVarible(key)
	end
	return nil
end

function Utilitys.getLanguageString(key, ...)
	return Utilitys.fill(Language:getInstance():getString(key), ...)
end

function Utilitys.createTimeWithFormat( secs )
 	if secs > 24*3600 then
 		return string.format("%dd %02d:%02d:%02d",secs/(24*3600), secs/3600%24,secs/60%60,secs%60)
    end 
    return string.format("%02d:%02d:%02d",secs/3600,secs/60%60,secs%60)
end 


function Utilitys.second2AllianceDataString(second)
	local hms = Utilitys.Split(GameMaths:formatSecondsToTime(second), ":")
	local dateStr = ""

	local h = tonumber(hms[1])
	if h > 0 then
		if h >= 24 then
			local d = math.floor(h / 24)
			dateStr = d .. _RALang("@Day")
			return dateStr
		end
		dateStr = dateStr .. (h % 24) .. _RALang("@Hour")
		return dateStr
	end

	local m = tonumber(hms[2])
	if h > 0 or m > 0 then
		dateStr = dateStr .. m .. _RALang("@Minute")
		return dateStr
	end

	local s = tonumber(hms[3])
	dateStr = dateStr .. s .. _RALang("@Second")

	return dateStr
end


--Ê± ·Ö Ãë ¸ñÊ½ ¹Ì¶¨¸ñÊ½
function Utilitys.second2DateString(second)
	local hms = Utilitys.Split(GameMaths:formatSecondsToTime(second), ":")
	local dateStr = ""

	local h = tonumber(hms[1])
	if h > 0 then
		if h >= 24 then
			local d = math.floor(h / 24)
			dateStr = d .. _RALang("@Day")
		end
		dateStr = dateStr .. (h % 24) .. _RALang("@Hour")
	end

	local m = tonumber(hms[2])
	if h > 0 or m > 0 then
		dateStr = dateStr .. m .. _RALang("@Minute")
	end

	local s = tonumber(hms[3])
	dateStr = dateStr .. s .. _RALang("@Second")

	return dateStr
end
---×ª»»Îª Ìì Ê±
function Utilitys.second2DateHourString(second)
	local hms = Utilitys.Split(GameMaths:formatSecondsToTime(second), ":")
	local dateStr = ""

	local h = tonumber(hms[1])
	if h > 0 then
		if h >= 24 then
			local d = math.floor(h / 24)
			dateStr = d .. _RALang("@Day")
		end
		dateStr = dateStr .. (h % 24) .. _RALang("@Hour")
	end

	return dateStr
end
---×ª»»Îª Ìì Ê± ·Ö ²»×ã1·Ö×ªÎªÃë
function Utilitys.second2DateMinuteString(second)
	local hms = Utilitys.Split(GameMaths:formatSecondsToTime(second), ":")
	local dateStr = ""

	local h = tonumber(hms[1])
	if h > 0 then
		if h >= 24 then
			local d = math.floor(h / 24)
			dateStr = d .. _RALang("@Day")
		end
		dateStr = dateStr .. (h % 24) .. _RALang("@Hour")
	end

	local m = tonumber(hms[2])
	if h > 0 or m > 0 then
		local second = tonumber(hms[3])
		if second > 0 then
			m = m + 1
		end
		dateStr = dateStr .. m .. _RALang("@Minute")
	else
		local s = tonumber(hms[3])
		dateStr = s .. _RALang("@Second")
	end

	return dateStr
end
--Ìì Ê± ·Ö Ãë ¸ñÊ½ ·Ç¹Ì¶¨¸ñÊ½
--Ê±¼ä´óÓÚ1ÌìÊ±		 XÌìXÐ¡Ê±
--Ð¡ÓÚÌì´óÓÚÊ± 	 	 XÐ¡Ê±X·ÖÖÓ
--Ð¡ÓÚÐ¡Ê±´óÓÚ·Ö 	 X·ÖÖÓXÃë
--Ð¡ÓÚ·ÖÖÓ			 XÃë
--传入秒数，转换成x天x小时x分x秒
function Utilitys.second2String(timeSeconds, ShowBit)
	local daySeconds = 24 * 60 * 60
	local hourSeconds = 60 * 60
	local minuteSeconds = 60
	
	local timeStr = ''
	timeSeconds = tonumber(timeSeconds)
	if timeSeconds >= daySeconds then	
		local dayCount = math.floor(timeSeconds / daySeconds)
		local hourCount = math.floor((timeSeconds - (daySeconds * dayCount))/hourSeconds)
		if hourCount == 0 then
			timeStr = dayCount .. _RALang("@Hour")
		else
			timeStr = dayCount .. _RALang("@Day") .. hourCount .. TableReader.getStringFromLanguageByKey("#hourStr")
		end		
	elseif timeSeconds >= hourSeconds then 
		local hourCount = math.floor(timeSeconds / hourSeconds)
		local minuteCount = math.floor((timeSeconds - hourSeconds * hourCount) / minuteSeconds)
		if minuteCount == 0 then
			timeStr = hourCount .. _RALang("@Hour")
		else
			timeStr = hourCount .. _RALang("@Hour") .. minuteCount .. TableReader.getStringFromLanguageByKey("#minuteStr")
		end		
	elseif timeSeconds >= minuteSeconds then
		local minuteCount = math.floor(timeSeconds / minuteSeconds)
		local secondCount = math.floor(timeSeconds - minuteSeconds * minuteCount)
		if secondCount == 0 then
			timeStr = minuteCount .. _RALang("@Minute")
		else
			timeStr = minuteCount .. _RALang("@Minute") .. secondCount .. TableReader.getStringFromLanguageByKey("#secondStr")
		end			
	else
		timeStr = math.floor(timeSeconds) .. _RALang("@Second")
	end

	return timeStr
end	
--Ìì Ê± ·Ö Ãë ShowBit ¿ØÖÆÏÔÊ¾µÄÎ»Êý
function Utilitys.second2StringWithShowBit(timeSeconds, ShowBit)
	local daySeconds = 24 * 60 * 60
	local hourSeconds = 60 * 60
	local minuteSeconds = 60
	
	local timeStr = ''
	local time = {}
	time[1] = {}
	time[1].count = math.floor(timeSeconds / daySeconds)
	time[1].timeStr = time[1].count .. _RALang("@Day")
	timeSeconds = timeSeconds - daySeconds * time[1].count
	time[2] = {}	
	time[2].count = math.floor(timeSeconds / hourSeconds)
	time[2].timeStr = time[2].count .. _RALang("@Hour")
	timeSeconds = timeSeconds - hourSeconds * time[2].count
	time[3] = {}
	time[3].count = math.floor(timeSeconds / minuteSeconds)
	time[3].timeStr = time[3].count .. _RALang("@Minute")
	timeSeconds = timeSeconds - minuteSeconds * time[3].count
	time[4] = {}
	time[4].count = math.floor(timeSeconds)
	time[4].timeStr = time[4].count .. _RALang("@Second")
	
	local bit = 0
	local count = 1	
	if not ShowBit or ShowBit < 0 then ShowBit = 4 end
	while bit < ShowBit and count <= 4 do
		if time[count].count > 0 then
			timeStr = timeStr .. time[count].timeStr
			bit = bit + 1
		end
		count = count + 1
	end
	return timeStr
end

function Utilitys.serverTimeFormat(serverTime)
local year = os.date("%Y",serverTime)
local month = os.date("%m",serverTime)
local date = os.date("%d",serverTime)
local timeOfDay = os.date("%X",serverTime)
local dateTxt = string.format("%d.%02d.%02d",year,month,date)
return dateTxt.."  "..timeOfDay
end

--Ê±¼äÓëµ±Ç°Ê±¼ä£¬ÊÇ·ñ¿çÌì(时间戳肯定不会大于现在)
function Utilitys.timeCrossDay(timeStamp)
    local currTime = os.time()
    local currTab = os.date("*t", currTime);
    local tab = os.date("*t", timeStamp)
    if currTab.year > tab.year or currTab.month > tab.month or currTab.day > tab.day then
        return true
    else 
        return false
    end
end

--同一天内：时/分
--不在同一天内：月/日/时/分
--不在同一年内：年/月/日/时/分
--(时间戳肯定不会大于现在)
function Utilitys.timeConvertShowingTime(timeStamp)
	-- body
	local currTime = os.time()
    local currTab = os.date("*t", currTime)
    timeStamp = math.floor(timeStamp/1000)
	local tab = os.date("*t", timeStamp)
	if currTab.year > tab.year then
		return string.format("%d/%02d/%02d %02d:%02d", tab.year, tab.month, tab.day, tab.hour, tab.min)
	elseif currTab.month > tab.month or currTab.day > tab.day then
		return string.format("%02d/%02d %02d:%02d", tab.month, tab.day, tab.hour, tab.min)
	elseif currTab.day == tab.day then
		return string.format("%02d:%02d", tab.hour, tab.min)
	end
end

--计算两个时间差是否大于某一个值
--diffValue (秒)
function Utilitys.timeDiffBetweenTwo( firstTime, secondTime, diffValue )
	-- body
	local diffs = math.abs(firstTime - secondTime) 
	if diffs > diffValue then
		return true
	else
		return false
	end
end

function Utilitys.table_combine(keys, values)
	local tb = {}
	for index, key in ipairs(keys) do
		tb[key] = values[index]
	end
	return tb
end

--simple and rough version, be careful
function Utilitys.table_merge(...)
	local tb = {}
	for i = 1, select("#", ...) do
		table.foreach((select(i, ...)), function(k, v)
			tb[k] = v
		end)
	end
	return tb
end

function Utilitys.table_map(tb, func)
	table.foreach(tb, function(k, v) tb[k] = func(v) end)
end

function Utilitys.table_values(tb)
	local values = {}
	table.foreach(tb, function(k, v) values[#values+1]=v end)
	return values
end	

function Utilitys.table_keys(tb)
	local values = {}
	table.foreach(tb, function(k, v) values[#values+1]=k end)
	return values
end	

function Utilitys.table_filter(tb, predicate)
	local _table = {}
	function func(k, v) 
		if predicate(k, v) then
			_table[k] = v
		end 
	end
	table.foreach(tb, func)
	return _table
end	

function Utilitys.table_connect(orignTb,connectTb)
	for k,v in pairs(connectTb) do
		orignTb[#orignTb+1] = v
	end
end

function Utilitys.table_find(tb, predicate)
	for k,v in pairs(tb) do
		if predicate(k, v) then
			return k,v
		end
	end
    return nil,nil
end

function Utilitys.table_count(tb)
	if tb then
		local count = 0
		for k,v in pairs(tb) do
			count = count + 1
		end
		return count
	end
	return 0
end

--isUp:true从小到大
function Utilitys.table_pairsByKeysAll(t,isUp)
    local keyTab = {}
	local tmpTab = {}
	for k,v in pairs(t) do
		table.insert(keyTab,k)
	end
	if isUp then
		table.sort(keyTab)
	else
		table.sort(keyTab,function (a,b)
			return a>b
		end)
	end 
	
	for i,v in ipairs(keyTab) do
		local value = t[v]
		table.insert(tmpTab,value)
	end
	return tmpTab
end

function Utilitys.table_pairsByKeys(t, filter)
	if filter and type(filter) ~= 'function' then
		filter = nil
	end

    local a = {}
    for k, v in pairs(t) do
		if filter == nil or filter(v) then
	        a[#a +1] = k
	    end
    end
    table.sort(a)
    local i = 0
    return function()
        i = i + 1
        return a[i], t[a[i]]
    end
end

function Utilitys.findLastDotStr(path)
    local splitTable = Utilitys.Split(path,"%.")
    local length = #splitTable
    return splitTable[length]
end

function Utilitys.deepCopy(object)
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

function Utilitys.isRightEmail(str)
	if string.len(str or "") < 6 then return false end
	local b,e = string.find(str or "", '@')
	local bstr = ""
	local estr = ""
	if b then
		bstr = string.sub(str, 1, b-1)
		estr = string.sub(str, e+1, -1)
	else
		return false
	end

	-- check the string before '@'
	local p1,p2 = string.find(bstr, "[%w_]+")
	if (p1 ~= 1) or (p2 ~= string.len(bstr)) then return false end

	-- check the string after '@'
	if string.find(estr, "^[%.]+") then return false end
	if string.find(estr, "%.[%.]+") then return false end
	if string.find(estr, "@") then return false end
	if string.find(estr, "[%.]+$") then return false end

	_,count = string.gsub(estr, "%.", "")
	if (count < 1 ) or (count > 3) then
		return false
	end

	return true
end	

function Utilitys.isQQNumber(str)
	if string.len(str or "") < 5 then return false end
	if string.find(str,"^%d+$") then return true end
	return false
end


function Utilitys.getIter()
	local i = 0
	return function()
		i = i + 1
		return i
	end
end

--格式化数字 1300==》1,300
function Utilitys.formatNumber(str)
	if not tostring(str) then return "" end
	if type(str)~="string" then str = tostring(str) end
	if string.len(str)<=3 then
		return str
	else
		local strR = string.sub(str,1,string.len(str)-3)
		return Utilitys.formatNumber(strR)..","..string.sub(str,string.len(str)-2)
	end
end

--判断是否相等
function Utilitys.equal(v1,v2)
	if type(v1)=="table" or type(v2)=="table" then return  false end
	if type(v1)=="string" then
		return v1 ==tostring(v2)
	elseif type(v1)=="number" then
		return v1 == tonumber(v2)
	end 
end

--查询表里是否含有某元素
function Utilitys.tableFind(tb,value)
	if not tb then
		error("tab is nil")
	end 

	for k,v in pairs(tb) do
		if v and Utilitys.equal(v,value) then
			return true
		end 
	end

	return false
end

function Utilitys.tableSortByKey(tb,key)
	if not tb or type(tb)~="table" then
		return
	end 
	table.sort(tb,function (a,b)
		return tonumber(a[key])<tonumber(b[key])
	end)

	return tb
end


function Utilitys.tableSortByKeyReverse(tb,key)
	if not tb or type(tb)~="table" then
		return
	end 
	table.sort(tb,function (a,b)
		return tonumber(a[key])>tonumber(b[key])
	end)

	return tb
end

function Utilitys.table2Array(tb)
	if not tb or type(tb)~="table" then
		return {}
	end
	local result = {}
	for k,v in pairs(tb) do
		result[#result+1] = v
	end
	return result
end

--计算某一时间点跟现在时间的差值 返回为秒
function Utilitys.getCurDiffTime(endTime)
	if not endTime then return 0 end
    local RA_Common = RARequire("common")
	local curTime = RA_Common:getCurTime()
	local remainTime =os.difftime(endTime,curTime)
	return remainTime
end

--返回结果为秒,传入参数为毫秒
function Utilitys.getCurDiffMilliSecond(endTime)
	if not endTime then return 0 end
    local RA_Common = RARequire("common")
	local curTime = RA_Common:getCurTime()
	endTime = endTime/1000

	--os.difftime方法的参数需要是秒，传入毫秒会在某些设备上出现异常
	local remainMilliSecond =os.difftime(endTime,curTime)
	return remainMilliSecond
end

--计算时间是否已经过去了
function Utilitys.isTimePassedCurrent( endTime )
	-- body
	if not endTime then return 0 end
        local RA_Common = RARequire("common")
	local curTime = RA_Common:getCurTime()
	if curTime > endTime then
		return true
	else
		return false
	end
end

--计算两点之间的距离
function Utilitys.getDistance(startP,endP)
	if not startP or not endP then return 0 end 
	local disX = math.abs(startP.x-endP.x)
	local disY = math.abs(startP.y-endP.y)
	local dis = math.sqrt(disX*disX+disY*disY)
	return dis
end

function Utilitys.getSqrMagnitude(startP, endP)
	if not startP or not endP then return 0 end 
	local disX = math.abs(startP.x - endP.x)
	local disY = math.abs(startP.y - endP.y)
	local sqrMagnitude = disX * disX + disY * disY
	return sqrMagnitude
end

local isCalcInCpp = true

-- 根据一条线段减去距离终点的某个距离值后，计算新点
function Utilitys.getGapPointOnSegment(distance, startPt, endPt)
	if isCalcInCpp then
		local resultX, resultY = GameMaths:getGapPointOnSegment(distance, startPt.x, startPt.y, endPt.x, endPt.y)
		return RACcp(resultX, resultY)
	end
	local totalLength =  Utilitys.ccpLength(RACcpSub(startPt, endPt))
	local percent = 1 - distance / totalLength
	if percent > 1 then percent = 1 end
	if percent < 0 then percent = 0 end
	local result = RACcp(0, 0)
	result.x = (endPt.x - startPt.x) * percent  + startPt.x 
	result.y = (endPt.y - startPt.y) * percent  + startPt.y
	return result
end


-- 计算一个点P到线段AB的最短距离
-- 返回最短距离、最近的点
function Utilitys.getPoint2SegmentDistance(ptP, ptA, ptB)	
	local cross = (ptB.x - ptA.x) * (ptP.x - ptA.x) + (ptB.y - ptA.y)*(ptP.y - ptA.y)
	if cross <= 0 then
		local a2pDis = Utilitys.getDistance(ptA, ptP)
		return a2pDis, ptA
	end

	local a2bDis = (ptB.x - ptA.x)*(ptB.x - ptA.x) + (ptB.y - ptA.y)*(ptB.y - ptA.y) 
	if cross >= a2bDis then
		local b2pDis = Utilitys.getDistance(ptP, ptB)
		return b2pDis, ptB
	end

	local r = cross / a2bDis
	local px = ptA.x + (ptB.x - ptA.x) * r
	local py = ptA.y + (ptB.y - ptA.y) * r
	local crossPt = RACcp(px, py)
	local dis = Utilitys.getDistance(ptP, crossPt)
	return dis, crossPt
end


 -- 判断两条线段是否相交 a 线段1起点坐标 b 线段1终点坐标 c 线段2起点坐标 d 线段2终点坐标 intersection 相交点坐标 
 -- return 是否相交
 --  0 两线平行 （包括重合）
 -- -1 相交但不在线段上  
 --  1  两线相交 
 -- return 交点
function Utilitys.getSegmentsIntersect(a,  b,  c,  d)	
	if isCalcInCpp then
		local resultStr, status, crossX, crossY = GameMaths:getSegmentsIntersect(a.x, a.y, b.x, b.y, c.x, c.y, d.x, d.y)
		print(resultStr)
		return status, RACcp(crossX, crossY)
	end
    local intersection = {x =0, y = 0}

    if math.abs(b.y - a.y) + math.abs(b.x - a.x) + math.abs(d.y - c.y) + math.abs(d.x - c.x) == 0 then
        if ((c.x - a.x) + (c.y - a.y) == 0) then
            print("ABCD是同一个点！")  
        else  
            print("AB是一个点，CD是一个点，且AC不同！")
        end
        return 0, nil
    end

    if math.abs(b.y - a.y) + math.abs(b.x - a.x) == 0 then
        if (a.x - d.x) * (c.y - d.y) - (a.y - d.y) * (c.x - d.x) == 0 then 
            print("A、B是一个点，且在CD线段上！") 
        else 
            print("A、B是一个点，且不在CD线段上！")
        end       
        return 0, nil
    end
    if math.abs(d.y - c.y) + math.abs(d.x - c.x) == 0 then  
        if (d.x - b.x) * (a.y - b.y) - (d.y - b.y) * (a.x - b.x) == 0 then
            print("C、D是一个点，且在AB线段上！")
        else  
            print("C、D是一个点，且不在AB线段上！")
        end  
        return 0, nil
    end  

    if (b.y - a.y) * (c.x - d.x) - (b.x - a.x) * (c.y - d.y) == 0 then 
        print("线段平行，无交点！")
        return 0, nil
    end  

    intersection.x = ((b.x - a.x) * (c.x - d.x) * (c.y - a.y) -   
            c.x * (b.x - a.x) * (c.y - d.y) + a.x * (b.y - a.y) * (c.x - d.x)) /   
            ((b.y - a.y) * (c.x - d.x) - (b.x - a.x) * (c.y - d.y))  
    intersection.y = ((b.y - a.y) * (c.y - d.y) * (c.x - a.x) - c.y  
            * (b.y - a.y) * (c.x - d.x) + a.y * (b.x - a.x) * (c.y - d.y))  
            / ((b.x - a.x) * (c.y - d.y) - (b.y - a.y) * (c.x - d.x))  

    if (intersection.x - a.x) * (intersection.x - b.x) <= 0  
            and (intersection.x - c.x) * (intersection.x - d.x) <= 0  
            and (intersection.y - a.y) * (intersection.y - b.y) <= 0  
            and (intersection.y - c.y) * (intersection.y - d.y) <= 0  then 
          
        print("线段相交于点("..intersection.x.. "," ..intersection.y .. ")！")  
        return 1, intersection -- '相交  
    else  
        print("线段相交于虚交点(" .. intersection.x .. ",".. intersection.y ..")！")  
        return -1, intersection -- '相交但不在线段上  
    end  
end


-- 计算两条线段的关系
-- -1为重合（重合会返回重合的起点和终点）
-- 0为平行
-- 1为相交1个点
-- 2为所在直线相交，但是线段不交
-- 3为所在线段相交，且线段的交点为4个线段构成点中的某一个
function Utilitys.checkTwoSegmentsRelation(pt1, pt2, pt3, pt4, isChange)
	local pt1 = Utilitys.checkIsPoint(pt1)
	local pt2 = Utilitys.checkIsPoint(pt2)
	local pt3 = Utilitys.checkIsPoint(pt3)
	local pt4 = Utilitys.checkIsPoint(pt4)
	if isChange then
		pt1.y = pt1.y * -1
		pt2.y = pt2.y * -1
		pt3.y = pt3.y * -1
		pt4.y = pt4.y * -1
	end

	local lingCrossStatus, lineResultPt = Utilitys.checkIsLineIntersect(pt1, pt2, pt3, pt4)
	local segmentCrossStatus = 0
	local segmentCrossPts = {}
	if lingCrossStatus == 0 then
		-- 平行
		segmentCrossStatus =0
	elseif lingCrossStatus == 1 then
		-- 相交，判断交点在不在线段上
		segmentCrossStatus = 1
		local isCoincide, status = Utilitys.isPointOnSegment(lineResultPt, pt1, pt2)
		if isCoincide then
			if isChange then
				lineResultPt.y = lineResultPt.y * -1
			end
			table.insert(segmentCrossPts, lineResultPt)
			-- 判断交点是否为某个线段的构成点
			if status == 1 then
				segmentCrossStatus = 3
			end
			if status == 2 then
				segmentCrossStatus = 3
			end
			-- 去判断是不是和pt3 pt4一样
			if segmentCrossStatus == 1 then
				local isSame = Utilitys.checkIsPointSame(lineResultPt, pt3)
				if isSame then
					segmentCrossStatus = 3
				else
					isSame = Utilitys.checkIsPointSame(lineResultPt, pt4)
					if isSame then
						segmentCrossStatus = 3
					end
				end
			end
		else
			segmentCrossStatus = 2
		end		
	elseif lingCrossStatus == -1 then
		-- 重合
		segmentCrossStatus = -1
		local list = {pt1, pt2, pt3, pt4}
		Utilitys.tableSortByKey(list, 'x')
		local resultPt1 = Utilitys.ccpCopy(list[2])
		local resultPt2 = Utilitys.ccpCopy(list[3])

		if isChange then
			resultPt1.y = resultPt1.y * -1
			resultPt2.y = resultPt2.y * -1
		end
		table.insert(segmentCrossPts, resultPt1)
		table.insert(segmentCrossPts, resultPt2)
	end
	return segmentCrossStatus, segmentCrossPts
end



-- 检查前两个点的连线和后两个点的连线是否相交，指向性直线p1->p2 和p3->p4
-- 0为平行
-- 1为相交
-- -1为重合
function Utilitys.checkIsLineIntersect(pt1, pt2, pt3, pt4)
	local pt1 = Utilitys.checkIsPoint(pt1)
	local pt2 = Utilitys.checkIsPoint(pt2)
	local pt3 = Utilitys.checkIsPoint(pt3)
	local pt4 = Utilitys.checkIsPoint(pt4)

	local startDiff = RACcpSub(pt1, pt3)

	local pt2to1Dir = RACcpSub(pt2, pt1)
	-- local pt2to1Normalized = Utilitys.ccpNormalize(pt2to1Dir)

	local pt4to3Dir = RACcpSub(pt4, pt3)
	-- local pt4to3Normalized = Utilitys.ccpNormalize(pt4to3Dir)

	local crossResult = Utilitys.ccpCross(pt2to1Dir, pt4to3Dir)

	local crossStatus = 0
	local resultPt = nil
	-- 相交
	if math.abs(crossResult) > 0 then
		resultPt = RACcp(0, 0)
		local factor1 = Utilitys.ccpCross(startDiff, pt4to3Dir) / crossResult
		-- local factor2 = Utilitys.ccpCross(startDiff, pt2to1Dir) / crossResult
		resultPt.x = pt1.x + factor1 * pt2to1Dir.x
		resultPt.y = pt1.y + factor1 * pt2to1Dir.y
		crossStatus = 1
	else
		--重合判断
		local isCoincide = Utilitys.isPointOnLine(pt3, pt1, pt2)
		if isCoincide then
			crossStatus = -1
		end
	end
	return crossStatus, resultPt
end



-- 判断目标点是否在直线
function Utilitys.isPointOnLine(targetPt, startPt, endPt)
	local isSame = Utilitys.checkIsPointSame(startPt, endPt)
	if isSame then
		return false
	end

	local targetPt = Utilitys.checkIsPoint(targetPt)
	local startPt = Utilitys.checkIsPoint(startPt)
	local endPt = Utilitys.checkIsPoint(endPt)

	local s2t = RACcpSub(startPt, targetPt)
	local s2tNormalized = Utilitys.ccpNormalize(s2t)

	local t2e = RACcpSub(targetPt, endPt)
	local t2eNormalized = Utilitys.ccpNormalize(t2e)

	local isSame = Utilitys.checkIsPointSame(s2tNormalized, t2eNormalized)
	-- 反向
	if not isSame then
		local inverseT2e = Utilitys.ccpMult(t2eNormalized, -1)
		isSame = Utilitys.checkIsPointSame(s2tNormalized, inverseT2e)
	end
	return isSame
end



-- 判断目标点是否在线段上，
-- 结果 为true的时候，会返回点所在线段中的类型
-- 1目标点为起始点，2目标点为终点，3目标点为线段中的点
function Utilitys.isPointOnSegment(targetPt, startPt, endPt)
	local isSame = Utilitys.checkIsPointSame(startPt, endPt)
	if isSame then
		return false, 0
	end
	isSame = Utilitys.checkIsPointSame(startPt, targetPt)
	if isSame then
		return true, 1
	end
	isSame = Utilitys.checkIsPointSame(endPt, targetPt)
	if isSame then
		return true, 2
	end
	local targetPt = Utilitys.checkIsPoint(targetPt)
	local startPt = Utilitys.checkIsPoint(startPt)
	local endPt = Utilitys.checkIsPoint(endPt)

	local s2t = RACcpSub(startPt, targetPt)
	local s2tNormalized = Utilitys.ccpNormalize(s2t)

	local t2e = RACcpSub(targetPt, endPt)
	local t2eNormalized = Utilitys.ccpNormalize(t2e)

	local isSame = Utilitys.checkIsPointSame(s2tNormalized, t2eNormalized)
	return isSame, 3
end


function Utilitys.checkIsPointSame(pt1, pt2)
	if pt1 ~= nil and pt2 ~= nil then
		if pt1.x == pt2.x and pt1.y == pt2.y then
			return true
		end
	end
	return false
end

-- 计算x,y的夹角
-- @return: 0 ~ 360
function Utilitys.getDegree(x, y)
	if x == 0 then return y > 0 and 90 or (y < 0 and 270 or 0) end
	
	local deg = math.deg(math.atan(y / x))
	if x > 0 then
		return deg >= 0 and deg or (360 + deg)
	else
		return 180 + deg
	end
end

function Utilitys.checkIsPoint(pt)
	local isRealPt = true
	pt = pt or {}
	if pt.x == nil then
		pt.x = 0
		isRealPt = false
	end
	if pt.y == nil then
		pt.y = 0
		isRealPt = false
	end
	return pt, isRealPt
end

function Utilitys.ccpCopy(ptOri)
	local ptNew, isReal = Utilitys.checkIsPoint(ptOri)
	if isReal then
		ptNew = {}
		ptNew.x = ptOri.x
		ptNew.y = ptOri.y
	end
	return ptNew
end

--return  0-360
function Utilitys.ccpAngle(pt1, pt2)
	local point1 = Utilitys.checkIsPoint(pt1)
	local point2 = Utilitys.checkIsPoint(pt2)	
	local xGap = point2.x - point1.x
	local yGap = point2.y - point1.y
	if xGap == 0 then
		if yGap > 0 then
			return 90, math.rad(90)
		end
		if yGap < 0 then
			return 270, math.rad(270)
		end
		if yGap == 0 then
			return 0, 0
		end
	end
	local tanValue = yGap / xGap
	local radian = math.atan(tanValue)
	local angle = math.deg(radian)
	if xGap > 0 and angle < 0 then
		angle = 360 + angle
	end
	if xGap < 0 then
		angle = 180 + angle
	end
	return angle, radian
end




-- 叉乘
function Utilitys.ccpCross(pt1, pt2)
	local point1 = Utilitys.checkIsPoint(pt1)
	local point2 = Utilitys.checkIsPoint(pt2)	
	local result = point1.x * point2.y - point1.y * point2.x
	return result
end

-- 点乘
function Utilitys.ccpDot(pt1, pt2)
	local point1 = Utilitys.checkIsPoint(pt1)
	local point2 = Utilitys.checkIsPoint(pt2)	
	local result = point1.x * point2.x + point1.y * point2.y
	return result
end


function Utilitys.ccpNormalize(pt)
	local ptTmp, isOK = Utilitys.checkIsPoint(pt)
	local result = { x = 1, y = 0}
	if isOK then
		local length = Utilitys.ccpLength(pt)
		if length ~= 0 then			
			result.x = ptTmp.x / length
			result.y = ptTmp.y / length
		end
	end
	return result
end


--
function Utilitys.ccpLength(pt)
	local point = Utilitys.checkIsPoint(pt)
	local dotL = Utilitys.ccpDot(point, Utilitys.ccpCopy(point))
	local result = math.sqrt(dotL)
	return result
end

function Utilitys.ccpMult(pt, scale)
	local point = Utilitys.checkIsPoint(pt)
	local scale = scale or 1
	local result = utility.checkIsPoint()
	result.x = point.x * scale
	result.y = point.y * scale
	return result
end





--格式化时间戳
function Utilitys.formatTimeWithYear(ts,format)
	format = format or "%d-%d %02d:%02d"
	local t = os.date("*t",ts)
	return string.format(format,t.month,t.day,t.hour,t.min)
end

--进度条scale值计算
function Utilitys.formatScaleValue(haveValue,baseValue,startScale)
    if type(haveValue) ~= "number" then haveValue = tonumber(haveValue) end
    if type(baseValue) ~= "number" then baseValue = tonumber(baseValue) end
	local value = haveValue/baseValue
	if value > 1 then 
		value = 1
	end 
    if startScale then
        local startScaleValue = startScale
        if startScaleValue < 0 then
            startScaleValue = 0
        end
        return startScaleValue,value
    end
	return value
end

--进度条动画play
function Utilitys.barActionPlay(mBar,data)
    if not mBar then return end
	local startValue,endValue = Utilitys.formatScaleValue(data.value,data.baseValue,data.valueScale)
    local RAActionManager = RARequire("RAActionManager")
    local action = RAActionManager:CreateScale9SpriteChangeAction(0.4,startValue,endValue)
    action:startWithTarget(mBar)
end

-- 判断CCNode是否为空
function Utilitys.isNil(node)
	return node == nil or tolua.cast(node, 'CCNode') == nil
end

function Utilitys.pay(goodsId, orderId)
    local RARealPayManager = RARequire("RARealPayManager")
    local serverItem = RARealPayManager.getGoodItemByGoodsId(goodsId)
    if serverItem == nil then
        return
    end
    local platformItem = RARealPayManager.getPlatfromProductionByProductId(serverItem.saleId)
    local description = serverItem.saleId
    if platformItem ~= nil then
        description = serverItem.saleId
    end

    RAPlatformUtils:pay(orderId, serverItem.payPrice, serverItem.saleId, _RALang(serverItem.name), description)
end



--格式化显示时间  t为一个时间戳 秒级别
--如果在不在同一天这显示日期，在同一天则显示“xx分钟之前” “xx小时之前”
function Utilitys.formatTime(t,isDirect)
	--先判断是否同一天
    local RA_Common = RARequire("common")
	local curDate = os.date("*t",RA_Common:getCurTime())
	local curDateStr = string.format("%d-%02d-%02d",curDate.year,curDate.month,curDate.day)
	
	local tmpDate = os.date("*t",t)
	local tmpDayStr = string.format("%d-%02d-%02d",tmpDate.year,tmpDate.month,tmpDate.day)

	if isDirect then 
		local tmpDayStr = string.format("%02d-%02d-%02d %02d:%02d:%02d",tmpDate.year,tmpDate.month,tmpDate.day,tmpDate.hour,tmpDate.min,tmpDate.sec)
		return tmpDayStr
	end

	local diffTime = math.abs(Utilitys.getCurDiffTime(t))
	if curDateStr~=tmpDayStr then
		formatT=Utilitys.formatTimeWithYear(t)
	elseif diffTime>=60*60 then
		local hour = 60*60
		formatT=_RALang("@MailTimeHourFormat",math.floor(diffTime/hour))
	else
		formatT=_RALang("@MailTimeMinFormat",math.max(1,math.ceil(diffTime/60)))
	end 
	return formatT
end

-- @DayWithParam {0}天
-- @HourWithParam {0}时
-- @MinuteWithParam {0}分
-- @SecondWithParam {0}秒

-- 格式化经过了多长时间
function Utilitys.fromatTimeGap(timeStamp)
	local second = timeStamp / 1000
	local minute = math.floor(second % (24*3600) % 3600 / 60 )
	local hour = math.floor(second % (24*3600)/ 3600 )
	local day = math.floor(second/(24*3600))
	local strResult = ''
	-- 1+天
	if second >= 24 * 60 * 60 then
		strResult = _RALang('@DayWithParam', day).._RALang('@HourWithParam', hour).._RALang('@MinuteWithParam', minute)
		return strResult
	-- 0天 1+小时
	elseif second < 24 * 60 * 60 and second >= 60 * 60 then
		strResult = _RALang('@HourWithParam', hour).._RALang('@MinuteWithParam', minute)
		return strResult
	-- 0天 0小时 x分钟
	else
		strResult = _RALang('@MinuteWithParam', minute)
		return strResult
	end
end

function Utilitys.getCcpFromString(str, separator)
	if str == nil or str == '' then return RACcp(0, 0) end

	separator = separator or '_'
	local posTB = RAStringUtil:split(str, separator) or {}
	return RACcp(tonumber(posTB[1]) or 0, tonumber(posTB[2]) or 0)
end

function Utilitys.getDisplayName(baseName, guildTag)
    local displayName = baseName
    if guildTag and guildTag ~= '' then
        displayName = string.format('(%s)%s', guildTag, baseName)
    end

    return displayName
end

function Utilitys.LogCurTime(desStr)
    local currTime = os.time()
    local currTab = os.date("*t", currTime);
    local formatStr = desStr .." RedAlert CurentTime is %d-%d-%d-%d-%d-%d"
    local timeStr = string.format(formatStr, currTab.year, currTab.month, currTab.day, currTab.hour, currTab.min, currTab.sec)
    CCLuaLog(timeStr)
end


function Utilitys.ReadJsonFile(path)
	if path==nil then return end
	local file=io.open(path,"r")	
	if file then
	   	local params=file:read("*all")
	   	if params~="" then
	   		params=cjson.decode(params)   --解析成一张表
	   		file:close()
	   		return params
	   	end 
	end 
end


function Utilitys.ReadJsonFileByKey(path,key)
	if path==nil then return "" end
	local file=io.open(path,"r")
	if file then
	   	local params=file:read("*a")
	   	if params~="" then
	   		params=cjson.decode(params)  
	   		local value = params[key]
	   		file:close()
	   		return value
	   	end
	end 
end
function Utilitys.WriteJsonFile(path,tb)
	if path==nil then return end
	local file=io.open(path,"w+")
	if file then
		local params = cjson.encode(tb)
	   	file:write(params)
	   	file:flush()
	   	file:close()
	end 

end

function Utilitys.UpdateJsonFile(path,key,value)
	if path==nil then return end
	local file=io.open(path,"a+")
	if file then
	   	local params=file:read("*a")
	   	if params~="" then
	   		params=cjson.decode(params)  
	   		params[key]=value
	   		params = cjson.encode(params)
	   		file:write(params)
	   		file:flush()
	   		file:close()
	   		return params
	   	end 
	end 

end

--point1 point2 用来确定一条直线
--targetY用于返回对应的X
function Utilitys.getPosXInLine(point1,point2,targetY)
	local targetX=nil

	local k=(point2.y-point1.y)/(point2.x-point1.x)

	targetX = (targetY-point1.y)/k+point1.x

	return targetX
end

function Utilitys.getPosYInLine(point1,point2,targetX)
	local targetY=nil

	local k=(point2.y-point1.y)/(point2.x-point1.x)

	targetY = k*(targetX-point1.x)+point1.y

	return targetX
end

return Utilitys;