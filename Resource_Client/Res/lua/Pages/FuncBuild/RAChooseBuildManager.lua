--region RAChooseBuildManager.lua
--Date
--此文件由[BabeLua]插件自动生成
local RAChooseBuildManager = {
    --可建造的建筑类型
    mAllBuild  = {},
    mFunctionBuild  = {},
    mResourceBuild  = {},
    mDefendBuild  = {},
    mAllBuildTotalNum = 0,
    mFunctionBuildTotalNum = 0,
    mResourceBuildTotalNum = 0,
    mDefendBuildTotalNum = 0,

    mAllBuildCurNum = 0,
    mFunctionBuildCurNum = 0,
    mResourceBuildCurNum = 0,
    mDefendBuildCurNum = 0,
    unlockList = {},
    unlockTabList = {},
    isLongClick = false,
    hasNewUnlock = false
}

local RABuildManager = RARequire("RABuildManager")
local build_conf = RARequire("build_conf")
local build_limit_conf = RARequire("build_limit_conf")
local build_ui_conf = RARequire("build_ui_conf")
local RARootManager = RARequire("RARootManager")
local Utilitys = RARequire("Utilitys")
RAChooseBuildManager.mCurChooseBuildId = 0

function RAChooseBuildManager:reset()
    self.unlockList = {}
    self.unlockTabList = {}
    self.hasNewUnlock = false
end

function RAChooseBuildManager:resetData()
    self.mAllBuild  = {}
    self.mFunctionBuild  = {}
    self.mResourceBuild  = {}
    self.mDefendBuild  = {}
    self.mAllBuildTotalNum = 0
    self.mFunctionBuildTotalNum = 0
    self.mResourceBuildTotalNum = 0
    self.mDefendBuildTotalNum = 0
    self.mAllBuildCurNum = 0
    self.mFunctionBuildCurNum = 0
    self.mResourceBuildCurNum = 0
    self.mDefendBuildCurNum = 0
   
end


function RAChooseBuildManager:isAlreadyReachLimit(buildType,typeData)
    for k,v in ipairs(typeData) do 
        if buildType == v then
            return true
        end
    end 
    return false
end

function RAChooseBuildManager:buildNew(buildTypeId,isDefense,pos)
    RABuildManager:buildNew(buildTypeId*100 + 1,isDefense,pos)
    RARootManager.ClosePage("RAChooseBuildPage")

    if isDefense then 
        MessageManager.sendMessage(MessageDef_MainUI.MSG_ChangeBuildStatus,{isShow = false})
    else
        MessageManager.sendMessage(MessageDef_MainUI.MSG_ChangeBuildStatus,{isShow = true})
    end
end

function RAChooseBuildManager:generateData()
    --step.1 get the cur build data
    self:resetData()
    local mainCityLvl = RABuildManager:getMainCityLvl();
    --如果没有建筑工厂，只能先建造建筑工厂
    if mainCityLvl == 0 then
        local Const_pb = RARequire("Const_pb")
        self.mAllBuildTotalNum = 1
        self.mAllBuild[Const_pb.CONSTRUCTION_FACTORY] = build_ui_conf[Const_pb.CONSTRUCTION_FACTORY]
        self.mFunctionBuildTotalNum = 1
        self.mFunctionBuild[Const_pb.CONSTRUCTION_FACTORY] = build_ui_conf[Const_pb.CONSTRUCTION_FACTORY]
        return
    end
    --step.2 filter the already has data
    for k, value in pairs(build_ui_conf) do
        local limitType = value.limitType
        local limitNum = build_limit_conf[limitType]['cyLv'..mainCityLvl]
        local common = RARequire("common")
        local curNum = 0
        if RABuildManager.buildingIndex[k] == nil then
            curNum = 0
        else
           curNum = common:table_count(RABuildManager.buildingIndex[k]) 
        end
        local status = 0 -- 0 is normal, 1 is full,2 is locked 
        if limitNum == 0 then
            status = 2
        elseif curNum >= limitNum then
            status = 1
        end
        --如果主城frontBuildId
        if value.frontBuild ~= nil then
            local hasFrondBuild = RABuildManager:isBuildCanCreateByFrontBuild(value.frontBuild)
            if not hasFrondBuild then
                status = 2
            end
--            local limitCityLvl = build_conf[value.frontBuild].level
--            if limitCityLvl > mainCityLvl then
--                status = 2
--            end
        end
        
        --如果出现刚解锁的建筑排序位置提高
        if RAChooseBuildManager.unlockList[value.id] ~= nil then
            value.uiPriority = -1
        end

        value.status = status
        if value.uiType ~= nil then
            self.mAllBuildCurNum = self.mAllBuildCurNum + curNum
            self.mAllBuildTotalNum = self.mAllBuildTotalNum + limitNum
            table.insert(self.mAllBuild,value)
            --self.mAllBuild[value.id] = value
        end 
        if value.uiType == 1 then
            self.mFunctionBuildCurNum = self.mFunctionBuildCurNum + curNum
            self.mFunctionBuildTotalNum = self.mFunctionBuildTotalNum + limitNum
            --self.mFunctionBuild[value.id] = value
            table.insert(self.mFunctionBuild,value)
          end 
        if value.uiType ==2 then
            self.mResourceBuildCurNum = self.mResourceBuildCurNum +curNum
            --resource and defense limit do not need to add, just equal, they share the same limit num
            self.mResourceBuildTotalNum = limitNum
            table.insert(self.mResourceBuild,value)
            --self.mResourceBuild[value.id] = value
        end 
        if value.uiType ==3 then
            self.mDefendBuildCurNum = self.mDefendBuildCurNum +curNum
            --resource and defense limit do not need to add, just equal, they share the same limit num
            self.mDefendBuildTotalNum = limitNum
            table.insert(self.mDefendBuild,value)
            --self.mDefendBuild[value.id] = value
	    end
    end
    self.mAllBuild = RAChooseBuildManager.tableSortByKey(self.mAllBuild)
    self.mFunctionBuild = RAChooseBuildManager.tableSortByKey(self.mFunctionBuild)
    self.mResourceBuild = RAChooseBuildManager.tableSortByKey(self.mResourceBuild)
    self.mDefendBuild = RAChooseBuildManager.tableSortByKey(self.mDefendBuild)

    --step.3 
end



function RAChooseBuildManager.tableSortByKey(tb)
	if not tb or type(tb)~="table" then
		return
	end 
    local compare = function (a,b)
        
        if tonumber(a["status"])~=tonumber(b["status"]) then
            return tonumber(a["status"])<tonumber(b["status"])
        else
            return tonumber(a["uiPriority"])<tonumber(b["uiPriority"])
        end
		
	end
	table.sort(tb,compare)

	return tb
end

local getDesTxtByBuildTypeId = function (buildTypeId)
    local finalStr = ""
    local build_ui_conf = RARequire("build_ui_conf")
    local conf =  build_ui_conf[buildTypeId]
    if conf.string1 ~= nil and conf.v1 ~= nil then
        finalStr = finalStr.._RALang(conf.string1)..conf.v1.."<br/>"
    end
    if conf.string2 ~= nil and conf.v2 ~= nil then
        finalStr = finalStr.._RALang(conf.string2)..conf.v2.."<br/>"
    end
    if conf.string3 ~= nil and conf.v3 ~= nil then
        finalStr = finalStr.._RALang(conf.string3)..conf.v3
    end
    return finalStr
end

function RAChooseBuildManager:generateTipHtmlStrByTypeId(buildTypeId,status)
    
    local build_ui_conf = RARequire("build_ui_conf")
    local buildId = buildTypeId * 100 + 1
    local name = _RALang(build_conf[buildId].buildName)
    local des = build_conf[buildId].buildDes
    local common = RARequire("common")
    local strTb = {};

    table.insert(strTb, common:fillHtmlStr("ChooseBuildTipDes", _RALang(des)));
    --table.insert(strTb, '<br/>')

    local conditionStr = getDesTxtByBuildTypeId(buildTypeId)

    if conditionStr ~= "" then
        table.insert(strTb, common:fillHtmlStr('ChooseBuildTipCondition', conditionStr));
	    --table.insert(strTb, '<br/>')
    end

    if status == 1 then
        local limitStr = _RALang("@BuildDetailReachLimit")
        table.insert(strTb, common:fillHtmlStr('ChooseBuildTipLimit', limitStr));
    elseif status == 2 then
        local Const_pb = RARequire("Const_pb")
        local uiInfo = build_ui_conf[buildTypeId]
        if uiInfo ~= nil and uiInfo.frontBuild~=nil then
            local limitStr = _RALang("@BuildDetailRequirement",_RALang(build_conf[uiInfo.frontBuild].buildName),build_conf[uiInfo.frontBuild].level)
            table.insert(strTb, common:fillHtmlStr('ChooseBuildTipLimit', limitStr));
        end
    end
    strTb = table.concat(strTb, '<br/>')
    return strTb
end

function RAChooseBuildManager:addNewUnlockInfo(uiInfo)
    RAChooseBuildManager.unlockList[uiInfo.id] = uiInfo
    RAChooseBuildManager.unlockTabList[uiInfo.uiType] = true
end

function RAChooseBuildManager:removeNewUnlockInfo(uiInfo)
    if RAChooseBuildManager.unlockList[uiInfo.id] ~= nil then
        RAChooseBuildManager.unlockList[uiInfo.id] = nil
        RAChooseBuildManager.unlockTabList[uiInfo.uiType] = nil
        local common = RARequire("common")
        if common:table_count(RAChooseBuildManager.unlockList) == 0 then
            RAChooseBuildManager.hasNewUnlock = false
            MessageManager.sendMessage(MessageDef_MainUI.MSG_HAS_NO_UNLOCK_BUILD)
            
        end
    end
end


--升级的时候调用一次，退出则无效
function RAChooseBuildManager:judgeUnlockBuild()
    local curMainCity = RABuildManager:getMainCityLvl()
     for k, value in pairs(build_ui_conf) do
        local frontBuildId = value.frontBuild
        local uiType = value.uiType
        if frontBuildId ~= nil and uiType~=nil then
            local level = build_conf[frontBuildId].level
            if curMainCity == level then
                RAChooseBuildManager:addNewUnlockInfo(value)
            end
        end
        
     end
     local common = RARequire("common")
     if common:table_count(RAChooseBuildManager.unlockList) > 0 then
        RAChooseBuildManager.hasNewUnlock = true
        return true,RAChooseBuildManager.unlockList
     else
        RAChooseBuildManager.hasNewUnlock = false
        return false,nil
     end
end

return RAChooseBuildManager;
--endregion
