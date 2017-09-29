--TO:联盟雕像详细页面
RARequire("BasePage")
local UIExtend = RARequire("UIExtend")
local RARootManager = RARequire("RARootManager")
local RAAllianceStatueManager = RARequire("RAAllianceStatueManager")
local RAAllianceProtoManager = RARequire("RAAllianceProtoManager")
local Utilitys = RARequire("Utilitys")
local RAStringUtil = RARequire("RAStringUtil")
local html_zh_cn = RARequire("html_zh_cn")
local RAQueueManager = RARequire("RAQueueManager")
local HP_pb = RARequire("HP_pb")
local common = RARequire("common")
local GuildManager_pb = RARequire("GuildManager_pb")
local RAAllianceManager = RARequire("RAAllianceManager")

local RAAllianceStatueEffectDetailPage = BaseFunctionPage:new(...)

function RAAllianceStatueEffectDetailPage:Enter(data)

    UIExtend.loadCCBFile("RAAllianceStatueInfoPopUp2.ccbi",self)

    UIExtend.setCCLabelString(self.ccbfile,"mTitle", _RALang("@StatueEffectDetail"))
    UIExtend.setCCLabelString(self.ccbfile,"mInfoTitle1", _RALang("@mInfoTitle1"))
    UIExtend.setCCLabelString(self.ccbfile,"mInfoTitle2", _RALang("@mInfoTitle2"))
    UIExtend.setCCLabelString(self.ccbfile,"mInfoTitle3", _RALang("@mInfoTitle3"))
    -- UIExtend.setCCLabelString(self.ccbfile,"mInfoTitle4", _RALang("@mInfoTitle4"))


    self.statueData = RAAllianceStatueManager:getStatueInfoByStatueId(data.statueId).statueInfo
    local conf = RAAllianceStatueManager:getStatueInfoConfById(self.statueData.statueId, self.statueData.level)
    local attrs = RAStringUtil:parseWithComma(conf.effect, {"type", "minValue", "maxValue", "isAffact", "additional"})
        
    for i,v in ipairs(attrs) do
        v.value = 100
        for j,v2 in ipairs(self.statueData.effect) do
            if v.type == v2.effectId then
                v.value = v2.effectValue
                break;
            end
        end
    end
    local guild_const_conf = RARequire("guild_const_conf")
    local allianceTerritoryScienceEffect = guild_const_conf['allianceTerritoryScienceEffect'].value
    local actualEffectValues = RAStringUtil:split(allianceTerritoryScienceEffect,",")
    local territoryData = RAAllianceManager:getManorDataById(RAAllianceManager.selfAlliance.manorId) 
    local manorLevel = 0
    if territoryData then
        manorLevel = tonumber(territoryData.level)
    end


    local attrNames,minValues,maxValues,curValues,actualValues = self:getAttrsName(attrs, actualEffectValues[manorLevel])
    local htmlConf = RAAllianceStatueManager:linkHtmlText(#attrs,attrNames,minValues,maxValues,true)
    UIExtend.getCCLabelHTMLFromCCB(self.ccbfile,"mInfoLabel1"):setString(htmlConf)

    local htmlConf2 = ""
    if #curValues == 1 then
        if self.statueData.hasBuild == false then
            htmlConf2 = RAStringUtil:fill(html_zh_cn["allianceEffect7"],attrNames[1])
        else
            htmlConf2 = RAStringUtil:fill(html_zh_cn["allianceEffect4"],attrNames[1] ,"+"..curValues[1])
        end
    else
        if self.statueData.hasBuild == false then
            htmlConf2 = RAStringUtil:fill(html_zh_cn["allianceEffect8"],attrNames[1],attrNames[2])
        else        
            htmlConf2 = RAStringUtil:fill(html_zh_cn["allianceEffect5"],attrNames[1] ,"+"..curValues[1] ,attrNames[2], "+"..curValues[2])
        end
    end
    UIExtend.getCCLabelHTMLFromCCB(self.ccbfile,"mInfoLabel2"):setString(htmlConf2)


    local effectPrecent = ""
    if territoryData and actualEffectValues and actualEffectValues[manorLevel] then
        effectPrecent = actualEffectValues[manorLevel].."%%"
        UIExtend.getCCLabelHTMLFromCCB(self.ccbfile,"mInfoLabel3"):setString(RAStringUtil:fill(html_zh_cn["allianceEffect6"],effectPrecent))
    else
        UIExtend.getCCLabelHTMLFromCCB(self.ccbfile,"mInfoLabel3"):setString(html_zh_cn["allianceEffect9"])
    end
    -- local htmlConf3 = "+"..curValues[1]
    -- if self.statueData.hasBuild == false then
    --     UIExtend.getCCLabelHTMLFromCCB(self.ccbfile,"mInfoLabel4"):setString(RAStringUtil:fill(html_zh_cn["allianceEffect10"],attrNames[1]))    
    -- elseif territoryData and actualEffectValues and actualEffectValues[manorLevel] then
    --     if attrs[1].isAffact == 1 then
    --         htmlConf3 = htmlConf3 .. "X"..effectPrecent.. "=" .. actualValues[1]
    --     end
    --     UIExtend.getCCLabelHTMLFromCCB(self.ccbfile,"mInfoLabel4"):setString(RAStringUtil:fill(html_zh_cn["allianceEffect4"],attrNames[1],htmlConf3))
    -- else
    --     UIExtend.getCCLabelHTMLFromCCB(self.ccbfile,"mInfoLabel4"):setString(RAStringUtil:fill(html_zh_cn["allianceEffect7"],attrNames[1]))      
    -- end

    -- if #attrs == 2 then
    --     local htmlConf4 = "+"..curValues[2]
    --     if self.statueData.hasBuild == false then
    --         UIExtend.getCCLabelHTMLFromCCB(self.ccbfile,"mInfoLabel5"):setString(RAStringUtil:fill(html_zh_cn["allianceEffect10"],attrNames[2]))    
    --     elseif territoryData and actualEffectValues and actualEffectValues[manorLevel] then
    --         if attrs[2].isAffact == 1 then
    --             htmlConf4 = htmlConf4 .. "X"..effectPrecent.. "=" .. actualValues[2]
    --         end
    --         UIExtend.getCCLabelHTMLFromCCB(self.ccbfile,"mInfoLabel5"):setString(RAStringUtil:fill(html_zh_cn["allianceEffect4"],attrNames[2],htmlConf4))
    --     else
    --         UIExtend.getCCLabelHTMLFromCCB(self.ccbfile,"mInfoLabel5"):setString(RAStringUtil:fill(html_zh_cn["allianceEffect7"],attrNames[2]))      
    --     end    
    -- else
    --     UIExtend.getCCLabelHTMLFromCCB(self.ccbfile,"mInfoLabel5"):setString("")
    -- end

end

function RAAllianceStatueEffectDetailPage:getAttrsName(attrs, actualEffectValue)

    local attrNames = {}
    local minValues = {}
    local maxValues = {}
    local curValues = {}
    local actualValues = {}

    for i = 1 ,#attrs do
        if attrs[i] then
            local attrName = RAAllianceStatueManager:getEffectConf(attrs[i].type)
            attrNames[#attrNames + 1] = _RALang(attrName)

            local minValue = attrs[i].minValue

            local maxValue = attrs[i].maxValue

            local curValue = attrs[i].value

            local actualValue = curValue
            if attrs[i].isAffact == 1 then
                if actualEffectValue == nil or actualEffectValue == "" then
                    actualEffectValue = 0
                end                
                actualValue = math.floor(actualValue * actualEffectValue/100)
            end

            --additional 为1的话 为百分比值
            if attrs[i].additional == 1 then
                minValues[#minValues + 1] = (minValue/100) .. "%%"
                maxValues[#maxValues + 1] = (maxValue/100) .. "%%"
                curValues[#curValues + 1] = (curValue/100) .. "%%"
                actualValues[#actualValues + 1] = (actualValue/100) .. "%%"
                
            else
                 minValues[#minValues + 1] = minValue
                 maxValues[#maxValues + 1] = maxValue
                 curValues[#curValues + 1] = curValue
                 actualValues[#actualValues + 1] = actualValue
            end
        end
    end


    return attrNames,minValues,maxValues,curValues,actualValues
end



function RAAllianceStatueEffectDetailPage:onClose()
    RARootManager.CloseCurrPage()
end

function RAAllianceStatueEffectDetailPage:Exit()
    
    self.statueInfo = nil
    self.statueQueueInfo = nil

    self.ccbfile:stopAllActions()
    
    UIExtend.unLoadCCBFile(self)
    self.ccbfile = nil
end

return RAAllianceStatueEffectDetailPage