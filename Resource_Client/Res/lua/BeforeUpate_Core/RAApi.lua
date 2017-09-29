--Author : zhenhui

--Date   : 2016/2/3
--discription: use for find full path by file name in fileFullPath.lua table

local fileFullPath = require("fileFullPath")

function RAGetPathByFileName(fileName)
    local hasPath = false
    local filePath = fileName
    if fileFullPath[fileName]~=nil then 
        hasPath = true
        filePath = fileFullPath[fileName]
    end
    return hasPath,filePath
end

--param: module name
function RARequire(moduleName)
    --case 1. if module name has "." in it, indicate it already has the related path. 
    --so use original RARquiredirectly
    if string.find(moduleName,"%.") ~= nil then
        return require(moduleName)
    end

    --case 2. if has no ".", first find the full path in table, if has, use the full path
    --if not, RARquiredirectly which maybe throw an exception or lua error
    local hasPath,fullPath = RAGetPathByFileName(moduleName)
    if hasPath then
        return require(fullPath)
    else
        return require(moduleName)
    end
end

dynamic_require = function(mod_name)
    local ret = RARequire(mod_name)
    RAUnload(mod_name)
    return ret
end


local msgFilter = {"_listener", "_is_present_in_parent", "_cached_byte_size", "_cached_byte_size_dirty",
                    "_listener_for_children"}

local table_arrayIndex = function (tb, v)
    for i, _v in ipairs(tb) do
        if _v == v then
            return i;
        end
    end
    return -1;
end

dump = function( data, max_level, prefix, filter )
    max_level = max_level or 5
    if type(prefix) ~= "string" then
        prefix = ""
    end
    filter = filter or {}
    if type(data) ~= "table" then
        CCLuaLog(prefix .. tostring(data).."\n")
    else
        if max_level ~= 0 then
            local prefix_next = prefix .. "    "
            CCLuaLog("\n"..prefix.."{".."\n")
            for k,v in pairs(data) do
                local continuous = false    
                if type(k) == "table" then
                    if k.name then
                        CCLuaLog(prefix_next..k.name.." = ")
                    else
                        CCLuaLog(prefix_next.."k".." = ")
                    end
                else
                    if table_arrayIndex(msgFilter, k ) ~= -1 or table_arrayIndex(filter, k ) ~= -1 then
                        continuous = true
                    else
                        CCLuaLog(prefix_next..tostring(k).." = ")
                    end
                    
                end
                if not continuous then
                    if type(v) ~= "table" or (type(max_level) == "number" and max_level <= 1) then
                        CCLuaLog(tostring(v).."\n")
                    else
                        if max_level == nil then
                            dump(v, nil, prefix_next)
                        else
                            dump(v, max_level - 1, prefix_next)
                        end
                    end 
                end
            end
            CCLuaLog(prefix .. "}".."\n")
        end
    end
end


function RAUnload(moduleName)
    if not moduleName or  tostring(moduleName)=="" then return end 
    if string.find(moduleName,"%.") ~= nil then
        package.loaded[moduleName] = nil
        return
    end
    local hasPath,fullPath = RAGetPathByFileName(moduleName)
    if hasPath then
        package.loaded[fullPath] = nil
    else
        package.loaded[moduleName] = nil
    end
end

function RAReload(moduleName)
    RAUnload(moduleName)
    RARquire(moduleName)
end 
----param: page name
--function RARegisterPage(pageName)
--    local hasPath,fullPath = RAGetPathByFileName(pageName)
--    assert(hasPath,"error in find fullPath by page name:"..pageName..
--    " Hint: new module need to fill in the fileFullPath.lua")
--    registerScriptPage(pageName,fullPath)   
--end


--function RAHttpGet(inputUrl)
--	local http = RARquire("http")
--	local r, c, h = http.request {
--	  method = "GET",
--	  url = inputUrl
--	}
--	CCMessageBox(r,"gjHttpRequest")
--	CCMessageBox(h.data,"gjHttpRequest")
--end


function RACcp(x, y)
    return {x = x, y = y}
end

function RACcpAdd(pos_1, pos_2)
    return {x = pos_1.x + (pos_2.x or 0), y = pos_1.y + (pos_2.y or 0)}    
end

function RACcpSub(pos_1, pos_2)
    return {x = pos_1.x - (pos_2.x or 0), y = pos_1.y - (pos_2.y or 0)}
end

function RACcpMult(pos, k)
    return {x = pos.x * k, y = pos.y * k}
end

function RACcpMultCcp(pos_1, pos_2)
    return {x = pos_1.x * pos_2.x, y = pos_1.y * pos_2.y}
end

function RACcpDistance(pos_1,pos_2 )
    return math.sqrt((pos_1.x-pos_2.x) *(pos_1.x-pos_2.x) + (pos_1.y-pos_2.y)*(pos_1.y-pos_2.y) )
end

function RACcpEqual(pos_1, pos_2)
    return pos_1 and pos_2 and pos_1.x == pos_2.x and pos_1.y == pos_2.y    
end

function RACcpUnpack(pos)
    return pos.x, pos.y
end

function RAColorUnpack(color)
    return color.r, color.g, color.b
end

function RACcpPrint(pos)
    print('-----x: ' .. pos.x .. '       y: ' .. pos.y)
end


--des by zhenhui
--for debug mode, we log all the five type of log
--for release mode, we log only the last three log type, aka, RA_WARNING, RA_RELEASE, RA_ERROR
--typedef enum LogType
--{
--	RA_DEBUG = 1,
--	RA_INFO,
--	RA_WARNING,
--	RA_RELEASE,//log the important information like enter the game, switch between scene, network fail and other info you want to log no mater in release or debug app.
--	RA_ERROR
--} RALogType;
function RALog(log,logType)
    if logType == nil then logType = RA_DEBUG end
    assert(logType>0 and logType < 6,"logType>0 and logType < 6")
    assert(log~= nil ,"log ~= nil")
    CCLuaLog(log,logType)
end

function RALogInfo(log)
    assert(log~= nil ,"log ~= nil")
    CCLuaLog(log,RA_INFO)
end

--log           ÏêÏ¸log
--gameModule	gameÖÐ´òÓ¡logÄ£¿é
--status		³É¹¦Îª¡°1¡±£¬Ê§°ÜÎªÆäËûÊý×Ö
--logType		ÏîÄ¿×Ô¶¨ÒåÈÕÖ¾ÀàÐÍ
--logLevel	    ¹Ì¶¨Öµ£¬Æ½Ì¨¾ö¶¨µÄ debug\info\error
function RALogWarn(log, goBI, gameModule, status, logType, logLevel)
    assert(log~= nil ,"log ~= nil")
    CCLuaLog(log,RA_WARNING)
    --ÉÏ±¨BI
    if goBI then
        if gameModule == nil then
            gameModule = "game"
        end
        if status == nil then
            status = "1"
        end
        if logType == nil then
            logType = "Warn"
        end
        if logLevel == nil then
            logLevel = "info"
        end
        --RAPlatformUtils:sendLogToBI(log, gameModule, status, logType, logLevel)
    end
end

function RALogError(log, goBI, gameModule, status, logType, logLevel)
    assert(log~= nil ,"log ~= nil")
    CCLuaLog(log,RA_ERROR)
    --ÉÏ±¨BI
    if goBI then
        if gameModule == nil then
            gameModule = "game"
        end
        if status == nil then
            status = "1"
        end
        if logType == nil then
            logType = "Error"
        end
        if logLevel == nil then
            logLevel = "error"
        end
        --RAPlatformUtils:sendLogToBI(log, gameModule, status, logType, logLevel)
    end
end

function RALogRelease(log, goBI, gameModule, status, logType, logLevel)
    assert(log~= nil ,"log ~= nil")
    CCLuaLog(log,RA_RELEASE)

    --ÉÏ±¨BI
    if goBI then
        if gameModule == nil then
            gameModule = "game"
        end
        if status == nil then
            status = "1"
        end
        if logType == nil then
            logType = "Release"
        end
        if logLevel == nil then
            logLevel = "info"
        end
        --RAPlatformUtils:sendLogToBI(log, gameModule, status, logType, logLevel)
    end
end

--endregion

--调用obj的release函数，同时置空 by zhenhui
function RA_SAFE_RELEASE(obj)
    if obj~= nil then
        obj:release()
        obj = nil
    end
end


--移除子节点，清空child
function RA_SAFE_REMOVEFROMPARENT(obj)
    if obj~= nil then
        obj:removeFromParentAndCleanup(true)
        obj = nil
    end
end

--移除所有子节点，清空child
function RA_SAFE_REMOVEALLCHILDREN(obj)
    if obj~= nil then
        obj:removeAllChildrenWithCleanup(true)
        obj = nil
    end
end

--获取节点的位置
function RA_GET_POSITION(node)
    local pos = nil
    if node ~= nil then
        pos = RACcp(node:getPositionX(),node:getPositionY())
    end
    return pos
end

--进入
function RA_SAFE_ENTER(obj,data)
    if obj ~= nil then
        obj:Enter(data)
    end
end

--循环
function RA_SAFE_EXECUTE(obj,data)
    if obj ~= nil then
        obj:Execute(data)
    end
end


--退出
function RA_SAFE_EXIT(obj,data)
    if obj ~= nil then
        obj:Exit(data)
    end
end



