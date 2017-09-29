
local RES_VERSION_TAG = "RA_RES_VERSION"

local RAUpdateManager = {}

local updateUrlHost = nil
local serverResVersion = nil
local mAdditionalSearchPath = nil
local updateStatus = nil
local needUpdateTotalBytes = 0
local alreadyTotalBytes = 0
local isEnter = false;
local RAUpdateStatus={
    Update_Error = 0,
	PrepareDownload = 1,
	StartDownload = 2,
	Downloading = 3,
	End = 4,
	None = 5
}
local tmpUpdatePath = nil
local updateCfgUrl = nil
local startDownloadTime = nil
local errorCode = nil
local RAUpdateErrorCode = {
    NoneError = 0,
	ClientOrServerVersionFormatError = 1,
	UpdateCfgLoadError = 2,
	UpdateCfgDownloadFailError = 3,
	DownloadTooMuchTimeError = 4
}
local RAFileDownloadStatus = {
    Fail = -1,
	Success = 1
}
local needFileMap = {}
local downloadedFileMap = {}
---------------------------------------------
--download listener
RAUpdateManager.updateHandler = nil


RAUpdateManager.onDownloadData = function(eventName,handler)
    if eventName == "downloaded" then
        local url = handler:getUrl()
        local fileName = handler:getFileName()
        RALogRelease("RAUpdateDownloadHandler.downloaded ok"..url)
        if string.find(url, updateCfgUrl) ~= nil then
            RAUpdateManager.parseUpdateCfg(fileName)--下载的是cfg文件，解析
        else
            if needFileMap[fileName] ~= nil then--下载的是普通文件
                downloadedFileMap[fileName] = RAFileDownloadStatus.Success
                alreadyTotalBytes = alreadyTotalBytes + needFileMap[fileName].size
                local RAGameLoadingState = RARequire("RAGameLoadingState")
                local downloadPercent = alreadyTotalBytes / needUpdateTotalBytes
                local percentStr = string.format("%.1f",downloadPercent * 100)
                RAGameLoadingState.setLoadingLabel(_RALang("@LoadingStateDownloading")..percentStr.."%")
            else
            end
        end 
        
    elseif eventName == "downloadFailed" then
        local url = handler:getUrl()
        local fileName = handler:getFileName()
        RALogRelease("RAUpdateDownloadHandler.downloadFailed ok"..url)
        if string.find(url, updateCfgUrl) ~= nil then
            updateStatus = RAUpdateStatus.Update_Error
            errorCode = RAUpdateErrorCode.UpdateCfgDownloadFailError
            return
        else
            if needFileMap[fileName] ~= nil then
                downloadedFileMap[fileName] = RAFileDownloadStatus.Fail
                if CC_TARGET_PLATFORM_LUA == CC_PLATFORM.CC_PLATFORM_WIN32 then
                    CCMessageBox("download fail, filename is "..fileName,_RALang("@hint"))
                end
            else
            end
        end


    end
end

----------------------------------------------

function RAUpdateManager:getCurPkgVersion()
    local setupVersion = SetupFileConfig:getInstance():getSectionString("Version")
    if setupVersion == nil then
        setupVersion = "1.0.0"
    end
    return setupVersion
end


--des:获取当前客户端资源版本号
function RAUpdateManager:getCurResVersion()
    local setupVersion = SetupFileConfig:getInstance():getSectionString("Version")
    if setupVersion == nil then
        setupVersion = "1.0.0"
    end
    return CCUserDefault:sharedUserDefault():getStringForKey(RES_VERSION_TAG,setupVersion);
end

--des:设置当前客户端资源版本号
function RAUpdateManager:setCurResVersion(serverResVersion)
    CCUserDefault:sharedUserDefault():setStringForKey(RES_VERSION_TAG, serverResVersion);
    CCUserDefault:sharedUserDefault():flush()
end


--des: 实例化Version为table
function RAUpdateManager:instanceVersion(version)
    assert(version ~= nil)

    local curVersionVec = RAUpdateManager.Split(version, "%.")
    assert(#curVersionVec == 3,"#curVersionVec == 3")
    local result ={}
    result.versionVec = curVersionVec
    result.bigVersion = tonumber(curVersionVec[2])
    result.smallVersion = tonumber(curVersionVec[3])
    return result
end

--des:判断是否进行大版本更新
--param:服务器当前版本号
function RAUpdateManager:judgeVersionUpdate(server_version)
    local curResVersion = self:getCurResVersion();
    if curResVersion == nil or server_version == nil then return false end

    local curVersionVec = RAUpdateManager.Split(curResVersion, "%.")
    local serVersionVec = RAUpdateManager.Split(server_version, "%.")

    --如果解析出来的版本号不是三个字段，return false
    if #curVersionVec ~= 3 or #serVersionVec ~= 3 then
        return false
    end

    --大版本更新是第一或者第二个标志位
    if (tonumber(curVersionVec[1]) < tonumber(serVersionVec[1])) or (tonumber(curVersionVec[2]) < tonumber(serVersionVec[2])) then
        return true
    else
        return false
    end
end

--des:判断是否需要热更新
--param:  server_version：传入服务器当前资源版本号
function RAUpdateManager:judgeResUpdate(server_version)
    local curResVersion = self:getCurResVersion();
    if curResVersion == nil or server_version == nil then return false end

    local curVersionVec = RAUpdateManager.Split(curResVersion, "%.")
    local serVersionVec = RAUpdateManager.Split(server_version, "%.")
    --如果解析出来的版本号不是三个字段，return false
    if #curVersionVec ~= 3 or #serVersionVec ~= 3 then
        return false
    end

    local curBig = tonumber(curVersionVec[2])
    local serBig = tonumber(serVersionVec[2])
    --如果大版本号不一致，则不更新
    if curBig ~= serBig then
        return false
    end

    --內更新是第三个标志位
    local iCurResVersion = tonumber(curVersionVec[3])
    local iSerResVersion = tonumber(serVersionVec[3])

    if iCurResVersion < iSerResVersion then
        return true
    else
        return false
    end
end


function RAUpdateManager:getAdditionalSearchPath()
    if CC_TARGET_PLATFORM_LUA == CC_PLATFORM.CC_PLATFORM_ANDROID then
        mAdditionalSearchPath = "Assets"
    else
        mAdditionalSearchPath = "_additionalSearchPath"
    end
    local additionalSearchPath = CCFileUtils:sharedFileUtils():getWritablePath() ..mAdditionalSearchPath
    return additionalSearchPath
end

function RAUpdateManager:Enter(data)
    updateUrlHost = data.updateUrl
    serverResVersion = data.serverResVersion
    isEnter = true

    if CC_TARGET_PLATFORM_LUA == CC_PLATFORM.CC_PLATFORM_ANDROID then
        mAdditionalSearchPath = "Assets"
    else
        mAdditionalSearchPath = "_additionalSearchPath"
    end

    updateStatus = RAUpdateStatus.PrepareDownload;--初始狀態
	tmpUpdatePath = CCFileUtils:sharedFileUtils():getWritablePath() .. "tmp_update.cfg";
	updateCfgUrl = updateUrlHost .. "update.cfg";

    startDownloadTime = 0
    RAUpdateManager.updateHandler = DownloadScriptHander:new(RAUpdateManager.onDownloadData)
    RAUpdateManager.prepareDownload()

end


function RAUpdateManager:Execute()
    if isEnter == false then
        return
    end
	if updateStatus == RAUpdateStatus.PrepareDownload then
        
	elseif updateStatus == RAUpdateStatus.StartDownload then
        RAUpdateManager.startDownload()
    elseif updateStatus ==  RAUpdateStatus.Downloading then
        RAUpdateManager.downloading()
    elseif updateStatus == RAUpdateStatus.End then
        RAUpdateManager.endDownload()
    elseif updateStatus == RAUpdateStatus.Update_Error then
        RAUpdateManager.errorDownload()
	end
end	

function RAUpdateManager:Exit()
    if isEnter == false then
        return
    end
	if RAUpdateManager.updateHandler then
	    RAUpdateManager.updateHandler:delete()
        RAUpdateManager.updateHandler = nil
	end
    isEnter = false
end

function RAUpdateManager.prepareDownload()
    errorCode = RAUpdateErrorCode.NoneError
    --double check the server res version and client res version
    local curResVersion = RAUpdateManager:getCurResVersion();

    local curVersionVec = RAUpdateManager.Split(curResVersion, "%.")
    local serVersionVec = RAUpdateManager.Split(serverResVersion, "%.")

    --內更新是第三个标志位
    local iCurResVersion = tonumber(curVersionVec[3])
    local iSerResVersion = tonumber(serVersionVec[3])

    if iCurResVersion < iSerResVersion then
        RADownloadManager:getInstance():downloadFile(RAGameUtils:getTimeStamp(updateCfgUrl), tmpUpdatePath);
    else
        RAUpdateManager.endDownload()
    end
end

function RAUpdateManager.endDownload()
    if errorCode == RAUpdateErrorCode.NoneError then
        RAUpdateManager:setCurResVersion(serverResVersion)
        os.remove(CCFileUtils:sharedFileUtils():fullPathForFilename(tmpUpdatePath))
    end
    updateStatus = RAUpdateStatus.None
    local RASDKInitManager = RARequire("RASDKInitManager")
    RASDKInitManager:doneUpdate()
end

function RAUpdateManager.startDownload()
    startDownloadTime = startDownloadTime +1
    if startDownloadTime > 10 then
        updateStatus = RAUpdateStatus.Update_Error
        errorCode = RAUpdateErrorCode.DownloadTooMuchTimeError
        return
    end
    
    if RAUpdateManager.table_count(needFileMap) > 0 then
        for key, singleFileItem in pairs(needFileMap) do
            local downloadUrl = updateUrlHost .. singleFileItem.filename--获得下载地址
            downloadUrl = RAGameUtils:getTimeStamp(downloadUrl)
            RADownloadManager:getInstance():downloadFile(downloadUrl, singleFileItem.saveFileName, singleFileItem.md5)
        end
        downloadedFileMap = {}
        updateStatus = RAUpdateStatus.Downloading
    else
        updateStatus = RAUpdateStatus.End
    end
end

function RAUpdateManager.downloading()
    local needDownloadCount = RAUpdateManager.table_count(needFileMap)
    --如果downloadedFileMap的大小和needFileMap的大小一样，说明已经下载完成
    if RAUpdateManager.table_count(downloadedFileMap) == needDownloadCount then
        local tmpNeedFileMap = {}
        local hasFailFile = false
        for key, value in pairs(downloadedFileMap) do
            if value == RAFileDownloadStatus.Fail then
                hasFailFile = true
                local fileName = key
                local fileItem = needFileMap[fileName]
                tmpNeedFileMap[fileName] = fileItem
            end
        end

        if hasFailFile then
            needFileMap = tmpNeedFileMap
            updateStatus = RAUpdateStatus.StartDownload
        else
            updateStatus = RAUpdateStatus.End
        end
    end
end

function RAUpdateManager.errorDownload()
    local msg = "RAUpdateManager::_error -- error code is "
    msg = msg .. errorCode
    if CC_TARGET_PLATFORM_LUA == CC_PLATFORM.CC_PLATFORM_WIN32 then
        CCMessageBox(_RALang("@HotUpdateError"..errorCode),_RALang("@hint"))
    end
    RAUpdateManager.endDownload()
end


function RAUpdateManager.Split(str, delim, maxNb)
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


function RAUpdateManager.table_pairsByKeys(t)
    local a = {}
    for n in pairs(t) do
        a[#a +1] = n
    end
    table.sort(a)
    local i = 0
    return function()
        i = i + 1
        return a[i], t[a[i]]
    end
end


function RAUpdateManager.table_count(tb)
	if tb then
		local count = 0
		for k,v in pairs(tb) do
			count = count + 1
		end
		return count
	end
	return 0
end


function RAUpdateManager.parseUpdateCfg(fileName)

    local pBuffer = getFileDataForLua(CCFileUtils:sharedFileUtils():fullPathForFilename(fileName))--找到cfg文件的下载地址，然后获得内容
    if pBuffer then
        local totalSize = 0
        local jsonBuffer = cjson.decode(pBuffer)
        local version = jsonBuffer.version
        local serverVersion = jsonBuffer.severVersion
        local files = jsonBuffer.files
        if version == nil or serverVersion == nil or files == nil then--下载下来的cfg文件有错误
            updateStatus = RAUpdateStatus.Update_Error
            errorCode = RAUpdateErrorCode.UpdateCfgLoadError
            return
        else
            needFileMap = {}
            for key, singleFile in pairs(files) do
                if singleFile.c ~= nil and singleFile.f ~= nil and singleFile.s ~= nil then
                    local fileAtt = {}
                    local downFileName = singleFile.f
                    --remove the first "/" num
                    if string.find(downFileName, "/") == 1 then
                        downFileName = string.sub(downFileName,2)
                    end
                    local fullPath = CCFileUtils:sharedFileUtils():fullPathForFilename(downFileName)
                    local needDown = true
                    if fullPath ~= downFileName then
                        if RAGameUtils:getFileMd5(fullPath) == singleFile.c then
                            --文件已经存在，且md5相同，不用下载
                            needDown = false
                        end
                    end
                    if needDown then
                        fileAtt.checkpath = fullPath
                        fileAtt.filename = downFileName
                        local saveFileName = CCFileUtils:sharedFileUtils():getWritablePath() ..
                         mAdditionalSearchPath .. "/" .. downFileName
                        fileAtt.md5 = singleFile.c
                        fileAtt.size = singleFile.s
                        fileAtt.saveFileName = saveFileName
                        totalSize  = totalSize + fileAtt.size
                        needFileMap[saveFileName] = fileAtt
                    end
                end
            end
        end
        if RAUpdateManager.table_count(needFileMap) == 0 then
            updateStatus = RAUpdateStatus.End
            return
        end
        updateStatus = RAUpdateStatus.StartDownload
        needUpdateTotalBytes = totalSize
        alreadyTotalBytes = 0
    else
        updateStatus = RAUpdateStatus.Update_Error
        errorCode = RAUpdateErrorCode.UpdateCfgLoadError
        return
    end
end

return RAUpdateManager