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

local RAAllianceStatueLevelEffectPage = BaseFunctionPage:new(...)

-----------------------------------------------------------
local RAAllianceStatueLevelEffectCellListener = {
    id = 0
}

function RAAllianceStatueLevelEffectCellListener:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    return o
end 

function RAAllianceStatueLevelEffectCellListener:onRefreshContent(ccbRoot)
    local statueInfo = RAAllianceStatueLevelEffectPage.statueList[self.id]
    local ccbfile = ccbRoot:getCCBFileNode() 
    if ccbfile then
        ccbfile:setPositionY(40)
        local attrs = RAStringUtil:parseWithComma(statueInfo.effect, {"type", "minValue", "maxValue", "isAffact", "additional"})
        local attrNames,minValues,maxValues = self:getAttrsName(attrs)
        UIExtend.setCCLabelString(ccbfile, "mCellTitle", _RALang("@StatuePreviewTip", statueInfo.level, statueInfo.alliance_level_required))
        local htmlConf = RAAllianceStatueManager:linkHtmlText(#attrs,attrNames,minValues,maxValues, true)
        local mCellLabel = UIExtend.getCCLabelHTMLFromCCB(ccbfile,"mCellLabel")

        mCellLabel:setString(htmlConf)

        local bubble = UIExtend.getCCScale9SpriteFromCCB(ccbfile, "mBg")
        bubble:setContentSize(CCSizeMake(530,159))

    end

end

function RAAllianceStatueLevelEffectCellListener:getAttrsName(attrs)

    local attrNames = {}
    local minValues = {}
    local maxValues = {}

    for i = 1 ,#attrs do
        if attrs[i] then
            local attrName = RAAllianceStatueManager:getEffectConf(attrs[i].type)
            attrNames[#attrNames + 1] = _RALang(attrName)

            local minValue = attrs[i].minValue

            local maxValue = attrs[i].maxValue

            --additional 为1的话 为百分比值
            if attrs[i].additional == 1 then
                minValues[#minValues + 1] = (minValue/100) .. "%%"
                maxValues[#maxValues + 1] = (maxValue/100) .. "%%"

            else
                 minValues[#minValues + 1] = minValue
                 maxValues[#maxValues + 1] = maxValue
            end
        end
    end


    return attrNames,minValues,maxValues
end

function RAAllianceStatueLevelEffectPage:Enter(data)

    UIExtend.loadCCBFile("RAAllianceCommonPopUp.ccbi",self)

    UIExtend.setCCLabelString(self.ccbfile,"mTitle", _RALang("@StatuePreview"))

    self.statueList = RAAllianceStatueManager:getStatueInfoListConfById(data.statueId)
    table.remove(self.statueList, 1) --移除0级
    self.scrollView = UIExtend.getCCScrollViewFromCCB(self.ccbfile, "mListSV")

    self.scrollView:removeAllCell()
    for i, v in ipairs(self.statueList) do
        local titleListener = RAAllianceStatueLevelEffectCellListener:new({id = i})
        local cell = CCBFileCell:create()
        cell:setCCBFile("RAAllianceCommonPopUpCell.ccbi")
        cell:registerFunctionHandler(titleListener)
        cell:setContentSize(CCSizeMake(530,159))

        self.scrollView:addCell(cell)
    end
    self.scrollView:orderCCBFileCells()  

end




function RAAllianceStatueLevelEffectPage:onClose()
    RARootManager.CloseCurrPage()
end

function RAAllianceStatueLevelEffectPage:Exit()
    
    self.statueInfo = nil
    self.statueQueueInfo = nil

    self.ccbfile:stopAllActions()
    
    UIExtend.unLoadCCBFile(self)
    self.ccbfile = nil
end

return RAAllianceStatueLevelEffectPage