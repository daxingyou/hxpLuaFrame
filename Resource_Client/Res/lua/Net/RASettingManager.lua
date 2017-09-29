--region *.lua
--Date
--此文件由[BabeLua]插件自动生成
local RASettingManager = {}
local RASDKInitManager = RARequire("RASDKInitManager")
local RARootManager = RARequire("RARootManager")
RASettingManager.optionData = {}
local RANetUtil = RARequire("RANetUtil")

function RASettingManager:reset()
    RASettingManager.optionData = {}
end

function RASettingManager:switchUser()
    local confirmData = {}
    confirmData.labelText = _RALang("@AreUSureToLogOut")
    confirmData.title = ""
    confirmData.yesNoBtn = true
    confirmData.resultFun = function (isOk)
        if isOk then
            MessageManager.sendMessage(MessageDef_MainState.SwitchUser,{})
        end
    end
    RARootManager.OpenPage("RAConfirmPage", confirmData, false, true, true)
end


function RASettingManager:clearUserDefault()
    CCUserDefault:purgeSharedUserDefault()
    os.remove(CCUserDefault:getXMLFilePath())
end


--option page related begin
function RASettingManager:setOptionData(key,value,isClientSave)
    --step.1 store optionData in local
    RASettingManager.optionData[key] = value
    --step.2 send command to server
    --save in server: "isClientSave" is value 0  else is value 1
    if isClientSave ~= 1 then
        local msg = SysProtocol_pb.HPCustomDataDefine()
        msg.data.key = key
        msg.data.arg = value
        RANetUtil:sendPacket(HP_pb.CUSTOM_DATA_DEFINE, msg, { retOpcode = - 1 }) 
    else
        if key == nil or key == "" then return end
        CCUserDefault:sharedUserDefault():setStringForKey(key, value) 
        CCUserDefault:sharedUserDefault():flush()  
        local RAConfirmManager = RARequire("RAConfirmManager")
        local isShow = value == "1" and true or false 
        RAConfirmManager:setShowConfirmDlog(isShow,1,key)
    end    
    --step.3 handle option set event
    RASettingManager:handleOptionSet(key,value)
end

function RASettingManager:handleOptionSet(key,value)
    local RASettingMainConfig = RARequire("RASettingMainConfig")
    if key == "option_music" then
        if value == "1" then
            SoundManager:getInstance():setMusicOn(true)
        else
            SoundManager:getInstance():setMusicOn(false)
        end
    elseif key == "option_effect" then
        if value == "1" then
            SoundManager:getInstance():setEffectOn(true)
        else
            SoundManager:getInstance():setEffectOn(false)
        end
    elseif key == "option_upgradeMark" then
    elseif key == "option_levelMark" then
    elseif key == "option_missionMark" then
    elseif key == "option_costDiamond" then
    elseif key == RASettingMainConfig.languageSetKey then
        local i18nconfig_conf = RARequire("i18nconfig_conf")
        if i18nconfig_conf[value] ~= nil then
            local RAStringUtil = RARequire("RAStringUtil")
            RAStringUtil:chooseLanguage(value)
        end
    elseif key == RASettingMainConfig.option_showGameHelper then
        local RAMainUIBottomBanner = RARequire("RAMainUIBottomBannerNew")
        RAMainUIBottomBanner:setLittleHelperNodeShow( value == "1" )
    end
end

function RASettingManager:onRecieveSettingData(msg)
     if msg.data then
        for i=1, #msg.data do
            local info = msg.data[i]
            if info and info.arg ~= nil then
                RASettingManager.optionData[info.key] = info.arg
                RASettingManager:handleOptionSet(info.key,info.arg)
            end
        end
    end
end

function RASettingManager:sortOptionPageData(conf)
    -- body
    local listData = {}
    for k,v in pairs(conf) do 
        listData[v.priority] = v
    end

    return listData
end

function RASettingManager:generateOptionPageData()
    local setting_option_conf = RARequire("setting_option_conf")
    
    local listData = self:sortOptionPageData(setting_option_conf)

    local allCellData = {}  -- all cell info, include the title
    for k,v in ipairs(listData) do 
       if v.isshow == 1 then
            --step.1 calc the option by server
            local option = RASettingManager.optionData[v.id]
            if v.isClientSave == 1 then
                --option = CCUserDefault:sharedUserDefault():getStringForKey(v.id, "") 

                local RAConfirmManager = RARequire("RAConfirmManager")
                local isShow = RAConfirmManager:getShowConfirmDlog(1,v.id)
                option = isShow and "1" or "0"
            end
            --if server does not have this id, means it's open
            if option == nil or option == "" then
                option = "1"
            end
            v.option = option
            --step.2 insert into the allCellData
            if allCellData[v.type] == nil then
                allCellData[v.type] = {}
            end
            table.insert(allCellData[v.type],v)
       end 
    end
    
    return allCellData
end

--option page related end


--main page related begin

function RASettingManager.tableSortByKey(tb)
	if not tb or type(tb)~="table" then
		return
	end 
    local compare = function (a,b)
        return tonumber(a["priority"])<tonumber(b["priority"])
	end
	table.sort(tb,compare)

	return tb
end


function RASettingManager:generateMainPageData()
    local setting_ui_conf = RARequire("setting_conf")
    local pageData = {}
    for k,v in pairs(setting_ui_conf) do 
       if v.isshow == 1 then
        table.insert(pageData,v)
       end 
    end
    pageData = RASettingManager.tableSortByKey(pageData)
    return pageData
end

--main page related end


--language page related begin

function RASettingManager:generateLanguagePageData()
    local i18nconfig_conf = RARequire("i18nconfig_conf")
    local pageData = {}
    for k,v in pairs(i18nconfig_conf) do 
       if v.isshow == 1 then
        table.insert(pageData,v)
       end 
    end
    local tableSortByKey = function (tb)
	    if not tb or type(tb)~="table" then
		    return
	    end 
        local compare = function (a,b)
            return tonumber(a["priority"])<tonumber(b["priority"])
	    end
	    table.sort(tb,compare)

	    return tb
    end
    pageData = tableSortByKey(pageData)
    return pageData
end

--language page related end

return RASettingManager 
--endregion
