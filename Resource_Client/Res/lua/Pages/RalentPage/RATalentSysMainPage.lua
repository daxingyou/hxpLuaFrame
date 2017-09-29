RARequire("BasePage")
local UIExtend = RARequire("UIExtend")
local RATalentManager = RARequire("RATalentManager")
local RAGameConfig = RARequire("RAGameConfig")
local Utilitys = RARequire("Utilitys")
local Talent_pb = RARequire("Talent_pb")
local RARootManager = RARequire("RARootManager")
local RANetUtil = RARequire("RANetUtil")
local item_conf = RARequire("item_conf")
local shop_conf = RARequire("shop_conf")
local Const_pb = RARequire("Const_pb")
local player_talent_conf = RARequire("player_talent_conf")
local talent_conf = RARequire("talent_conf")
local const_conf = RARequire("const_conf")
local RACoreDataManager = RARequire("RACoreDataManager")
local RAStringUtil = RARequire("RAStringUtil")
local talent_cell_show_conf = RARequire("talent_cell_show_conf")
local talent_bgline_conf = RARequire("talent_bgline_conf")
local talent_fgline_conf = RARequire("talent_fgline_conf")
local RAGuideManager=RARequire("RAGuideManager")
local RAGuideConfig=RARequire("RAGuideConfig")

local RATalentSysMainPage = BaseFunctionPage:new(...)
RATalentSysMainPage.scrollView = nil
RATalentSysMainPage.routeBtn0 = nil--天赋路线1按钮
RATalentSysMainPage.routeBtn1 = nil--天赋路线2按钮
RATalentSysMainPage.svContentOffset = nil --scrollview偏移
RATalentSysMainPage.hasResetTalentTools = false--是否包含天赋道具
RATalentSysMainPage.currShowTalentRoute = 0--当前显示的天赋路线类型，默认是开启路线
RATalentSysMainPage.netHandler = {}--网络监听接口
RATalentSysMainPage.upgradeTalentId = nil--升级的天赋id
RATalentSysMainPage.rowWithTalentIds = {}--key是row，value是skillid的数组



--start//////////////////////////////////////////////////////////////////////////////
--desc:消息处理
local OnReceiveMessage = function(message)
    if message.messageID == MessageDef_Lord.MSG_TalentUpgrade then
    --天赋升级 是否会解锁其余天赋
        RATalentSysMainPage.upgradeTalentId = message.talentId
        RATalentSysMainPage:refreshPage()

        --刷新装备页面天赋按钮上的红点
        MessageManager.sendMessage(MessageDef_RedPoint.MSG_Refresh_Talent_RedPoint)
        --刷新头像上面的红点 有可能从道具页面进
        MessageManager.sendMessage(MessageDef_RedPoint.MSG_Refresh_Head_RedPoint)

    elseif message.messageID == MessageDef_Packet.MSG_Operation_OK then
        local pbCode = message.opcode
        if pbCode then
            --重置天賦成功
            if pbCode == HP_pb.TALENT_CLEAR_C then
                RATalentManager:reset(RATalentSysMainPage.currShowTalentRoute)
                RATalentSysMainPage:refreshPage()
            elseif pbCode == HP_pb.TALENT_CHANGE_C then
                RATalentManager.CurrTurnOnType = RATalentSysMainPage.currShowTalentRoute
                RARootManager.ShowMsgBox("@TurnOnTalentRouteSuc")
                -- UIExtend.setNodeVisible(RATalentSysMainPage.ccbfile, "mEnableBtn", false)
                RATalentSysMainPage:refreshTabBtn()
            end

            --刷新装备页面天赋按钮上的红点
            MessageManager.sendMessage(MessageDef_RedPoint.MSG_Refresh_Talent_RedPoint)
            --刷新头像上面的红点 有可能从道具页面进
            MessageManager.sendMessage(MessageDef_RedPoint.MSG_Refresh_Head_RedPoint)
        end
    elseif message.messageID == MessageDef_Packet.MSG_Operation_Fail then
        local pbCode = message.opcode
        if pbCode then
            if pbCode == HP_pb.TALENT_CLEAR_C then
                --重置天賦失敗
            elseif pbCode == HP_pb.TALENT_CHANGE_C then
                --启用天赋失败
                RARootManager.ShowMsgBox("@TurnOnTalentRouteFail")
            end
        end
    elseif message.messageID == MessageDef_Guide.MSG_Guide then 
        local constGuideInfo = message.guideInfo
        local guideId = constGuideInfo.guideId
        if constGuideInfo and constGuideInfo.keyWord == RAGuideConfig.KeyWordArray.CircleTalentCell then
                if constGuideInfo.showGuidePage == 1 then
                    local skillNode = UIExtend.getCCNodeFromCCB(RATalentSysMainPage.guideSingleTalentCCBFile, "mGuideSkillNode")
                    local pos = ccp(0, 0)
                    pos.x, pos.y = skillNode:getPosition()
                    local worldPos = skillNode:getParent():convertToWorldSpace(pos)
                    local size = skillNode:getContentSize()
                    size.width = size.width + RAGuideConfig.GuideTips.ConfigOffset*2
                    size.height = size.height + RAGuideConfig.GuideTips.ConfigOffset*2
                    RARootManager.AddGuidPage({["guideId"] = guideId, ["pos"] = worldPos, ["size"] = size})
                end 
       elseif constGuideInfo and constGuideInfo.keyWord == RAGuideConfig.KeyWordArray.CircleTalentSysMainPageBackBtn then
                if constGuideInfo.showGuidePage == 1 then
                    local backNode = UIExtend.getCCNodeFromCCB(RATalentSysMainPage.ccbfile, "mBackBtn")
                    local pos = ccp(0, 0)
                    pos.x, pos.y = backNode:getPosition()
                    local worldPos = backNode:getParent():convertToWorldSpace(pos)
                    local size = backNode:getContentSize()
                    size.width = size.width + RAGuideConfig.GuideTips.ConfigOffset*2
                    size.height = size.height + RAGuideConfig.GuideTips.ConfigOffset*2
                    RARootManager.AddGuidPage({["guideId"] = guideId, ["pos"] = worldPos, ["size"] = size})
                end
        end  
    end
end
--//////////////////////////////////////////////////////////////////////////////



--start//////////////////////////////////////////////////////////////////////////////
local RASkillGroupCellListener = 
{
    skillIds = {},--当前cell所显示的天赋id数组
    rowIndex = 0,
    skillType = nil,
}


function RASkillGroupCellListener:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    self.indexWithTalentId = {}--单个cell多显示的skillId，key是cellindex，value是skillId（这个数据类型是为了方便控制天赋的显示顺序设置的）
    return o
end

function RASkillGroupCellListener:onRefreshContent(ccbRoot)
    local ccbfile = ccbRoot:getCCBFileNode()

    self.indexWithTalentId = {}
    --显示当前cell中包含的天赋的信息
    for key, skillId in ipairs(self.skillIds) do
        local constSkillInfo = player_talent_conf[skillId]--通过skillId获得skill信息
        local constSkillShowInfo = talent_cell_show_conf[skillId]--当前天赋的位置信息（在当前cell内的）
        local constFglineInfo = talent_fgline_conf[skillId]--显示红线的信息
        local row = constSkillShowInfo.row
        local colume = constSkillShowInfo.colume
        if row ~= self.rowIndex then
            CCLuaLog("current talent nor be included in group cell")
            return
        end
        self.indexWithTalentId[colume] = skillId--保存当前位置显示的skillid
        local singleTalentCCBFile = UIExtend.getCCBFileFromCCB(ccbfile, "mCellCCB"..colume)--单个天赋的ccbfile

        if constSkillInfo ~= nil and singleTalentCCBFile ~= nil then
            --显示每一个天赋的信息
            if RAGuideManager.partComplete.Guide_UIUPDATE and RAGuideManager.isInGuide() and skillId==RAGuideConfig.guideSkillId then
                RATalentSysMainPage.guideSingleTalentCCBFile=singleTalentCCBFile
            end
            if not RATalentManager.isTalentLock(self.skillType, skillId) then
                UIExtend.setNodeVisible(singleTalentCCBFile,"mRedBGNode", true)
                UIExtend.setNodeVisible(singleTalentCCBFile,"mGrayBGNode", false)
                local pic = UIExtend.addSpriteToNodeParent(singleTalentCCBFile, "mCellSkillIconNode", constSkillInfo.icon, 0, ccc3(255,255,255))
                if pic then
                    UIExtend.setCCSpriteGray(pic,false)
                end
                --处理红线
                if constFglineInfo.showLineIndex then
                    local showLineIndexArr = Utilitys.Split(constFglineInfo.showLineIndex, "_")
                    for k,value in ipairs(showLineIndexArr) do
                        local lineCCB = UIExtend.getCCBFileFromCCB(ccbfile, "mLineCCB"..value)
                        if lineCCB then
                            UIExtend.setNodeVisible(lineCCB, "mEnable", true)
                        end
                    end
                end
            else
                UIExtend.setNodeVisible(singleTalentCCBFile,"mRedBGNode",false)
                UIExtend.setNodeVisible(singleTalentCCBFile,"mGrayBGNode",true)
                local pic = UIExtend.addSpriteToNodeParent(singleTalentCCBFile, "mCellSkillIconNode", constSkillInfo.icon, 0, ccc3(166,166,166))
                if pic then
                    UIExtend.setCCSpriteGray(pic,true)
                end
                --处理红线
                if constFglineInfo.showLineIndex then
                    local showLineIndexArr = Utilitys.Split(constFglineInfo.showLineIndex, "_")
                    for k,value in ipairs(showLineIndexArr) do
                        local lineCCB = UIExtend.getCCBFileFromCCB(ccbfile, "mLineCCB"..value)
                        if lineCCB then
                            UIExtend.setNodeVisible(lineCCB, "mEnable", false)
                        end
                    end
                end
            end

            local skillServerInfo = nil
            local talenInfos = RATalentManager.getTalentInfoByType(RATalentSysMainPage.currShowTalentRoute)
            if talenInfos then
                skillServerInfo = talenInfos[skillId]
            end
            local currentLevel = 0
            if skillServerInfo ~= nil then
                currentLevel = skillServerInfo.level
            end
            local levelStr =  currentLevel .. "/" .. constSkillInfo.maxLevel
            UIExtend.setCCLabelString(singleTalentCCBFile, "mCellLevel", levelStr)
            if currentLevel == constSkillInfo.maxLevel then
                UIExtend.setLabelTTFColor(singleTalentCCBFile, "mCellLevel", ccc3(255, 255, 0))
            else
                UIExtend.setLabelTTFColor(singleTalentCCBFile, "mCellLevel", ccc3(255, 255, 255))
            end

            UIExtend.setCCLabelString(singleTalentCCBFile, "mCellName", _RALang(constSkillInfo.name))
            if currentLevel > 0 then
                UIExtend.setLabelTTFColor(singleTalentCCBFile, "mCellName", ccc3(255, 255, 0))
            else
                UIExtend.setLabelTTFColor(singleTalentCCBFile, "mCellName", ccc3(255, 255, 255))
            end

            if skillId == RATalentSysMainPage.upgradeTalentId then
                local mUpgradeSkillAniCCB = UIExtend.getCCBFileFromCCB(singleTalentCCBFile, "mUpgradeSkillAniCCB")
                if mUpgradeSkillAniCCB then
                    mUpgradeSkillAniCCB:runAnimation("UpgradeAni")
                end
                RATalentSysMainPage.upgradeTalentId = nil
            end

        end
    end
    
    --显示黑线
    local constBgLineInfo = talent_bgline_conf[self.rowIndex]
    if constBgLineInfo then
        local lineArr = Utilitys.Split(constBgLineInfo.showLineItem, "_")
        for key, value in ipairs(lineArr) do
            local isShow = tonumber(value)
            UIExtend.setNodeVisible(ccbfile, "mLineCCB"..key, isShow~=0)
        end
    end

end

function RASkillGroupCellListener:mCellCCB1_onSkillBG()
    if self.indexWithTalentId[1] ~= nil then
        local skillId = self.indexWithTalentId[1]
        self:onTalentClick(skillId)
    end
end
function RASkillGroupCellListener:mCellCCB2_onSkillBG()
    if self.indexWithTalentId[2] ~= nil then
        local skillId = self.indexWithTalentId[2]
        self:onTalentClick(skillId)
    end
end
function RASkillGroupCellListener:mCellCCB3_onSkillBG()
    if self.indexWithTalentId[3] ~= nil then
        local skillId = self.indexWithTalentId[3]
        self:onTalentClick(skillId)
    end
end
function RASkillGroupCellListener:mCellCCB4_onSkillBG()
    if self.indexWithTalentId[4] ~= nil then
        local skillId = self.indexWithTalentId[4]
        self:onTalentClick(skillId)
    end
end
function RASkillGroupCellListener:mCellCCB5_onSkillBG()
    if self.indexWithTalentId[5] ~= nil then
        local skillId = self.indexWithTalentId[5]
        self:onTalentClick(skillId)
    end
end
function RASkillGroupCellListener:mCellCCB6_onSkillBG()
    if self.indexWithTalentId[6] ~= nil then
        local skillId = self.indexWithTalentId[6]
        self:onTalentClick(skillId)
    end
end
function RASkillGroupCellListener:mCellCCB7_onSkillBG()
    if self.indexWithTalentId[7] ~= nil then
        local skillId = self.indexWithTalentId[7]
        self:onTalentClick(skillId)
    end
end

function RASkillGroupCellListener:onTalentClick(skillId)

    if RAGuideManager.partComplete.Guide_UIUPDATE and RAGuideManager.isInGuide() then
       RARootManager.AddCoverPage()
       RARootManager.RemoveGuidePage()
    end

    RATalentSysMainPage.svContentOffset = RATalentSysMainPage.scrollView:getContentOffset()
    local data = {}
    data.talentId = tonumber(skillId)
    data.talentRouteType = self.skillType
    RARootManager.OpenPage("RATalentUpgradePage", data, false, true, true)
end
--//////////////////////////////////////////////////////////////////////////////




--start//////////////////////////////////////////////////////////////////////////////
function RATalentSysMainPage:onReceivePacket(handler)
    local pbCode = handler:getOpcode()
    local buffer = handler:getBuffer()
    if pbCode == HP_pb.TALENT_CLEAR_S then
        local msg = Talent_pb.HPTalentClearResp()
        msg:ParseFromString(buffer)
        if msg.result == true then
            RATalentManager.reset()
            self:refreshPage()
        end
    end
end


function RATalentSysMainPage:Enter(data)
    UIExtend.loadCCBFile("RALordSkillPage.ccbi", RATalentSysMainPage)
    self.scrollView = UIExtend.getCCScrollViewFromCCB(self.ccbfile, "mSkillSV")
    self.routeBtn0 = UIExtend.getCCControlButtonFromCCB(self.ccbfile, "mFightSkillBtn")
    self.routeBtn1 = UIExtend.getCCControlButtonFromCCB(self.ccbfile, "mDevelopSkillBtn")

    self.svContentOffset = nil 
    self.guideSingleTalentCCBFile=nil  
    self.hasResetTalentTools = false

    self.currShowTalentRoute = RATalentManager.CurrTurnOnType--首先显示的是当前启用的路线

    self:refreshPage()
    self:addHandler()

    if RAGuideManager.partComplete.Guide_UIUPDATE and RAGuideManager.isInGuide() then
        self.scrollView:setTouchEnabled(false)
        RARootManager.AddCoverPage()
        RAGuideManager.gotoNextStep()
    else
        self.scrollView:setTouchEnabled(true)
    end

end

--desc:添加各种监听
function RATalentSysMainPage:addHandler()
    MessageManager.registerMessageHandler(MessageDef_Lord.MSG_TalentUpgrade, OnReceiveMessage)
    MessageManager.registerMessageHandler(MessageDef_Packet.MSG_Operation_OK, OnReceiveMessage)
    MessageManager.registerMessageHandler(MessageDef_Packet.MSG_Operation_Fail, OnReceiveMessage)

    if RAGuideManager.partComplete.Guide_UIUPDATE then
         MessageManager.registerMessageHandler(MessageDef_Guide.MSG_Guide,OnReceiveMessage)
    end

    --self.netHandler[#self.netHandler +1] = RANetUtil:addListener(HP_pb.TALENT_CLEAR_S, self)
end

--desc:移除各种监听
function RATalentSysMainPage:removeHandler()
    MessageManager.removeMessageHandler(MessageDef_Lord.MSG_TalentUpgrade, OnReceiveMessage)
    MessageManager.removeMessageHandler(MessageDef_Packet.MSG_Operation_OK, OnReceiveMessage)
    MessageManager.removeMessageHandler(MessageDef_Packet.MSG_Operation_Fail, OnReceiveMessage)

    if RAGuideManager.partComplete.Guide_UIUPDATE then
        MessageManager.removeMessageHandler(MessageDef_Guide.MSG_Guide,OnReceiveMessage)
    end

    --取消packet监听
    for k, value in pairs(self.netHandler) do
        if self.netHandler[k] ~= nil then
             RANetUtil:removeListener(self.netHandler[k])
             self.netHandler[k] = nil
        end
    end
    self.netHandler = {}
end


--desc:刷新页面总入口
function RATalentSysMainPage:refreshPage()
    self:refreshTitle()
    self:refreshTabBtn()
    self:refreshTalentTree()
end

--desc:刷新title
function RATalentSysMainPage:refreshTitle()
    --剩余技能点数
    local totalTalentPoint = RATalentManager.getTotalGeneralNum()
    local useTalentPoint = RATalentManager.getUseGeneralNumByType(self.currShowTalentRoute)
    local freeTalentPoint = totalTalentPoint - useTalentPoint
    local freeStr = RAStringUtil:getLanguageString("@FreeTalentPoint", freeTalentPoint)
    UIExtend.setCCLabelString(self.ccbfile, "mSkillPoint", freeStr)

    self:setResetBtn()
end

--desc:刷新tab按钮
function RATalentSysMainPage:refreshTabBtn()
    if self.currShowTalentRoute == Const_pb.TalentRouteType_0 then
        --路线0
        self.routeBtn0:setHighlighted(true)
        self.routeBtn1:setHighlighted(false)
    elseif self.currShowTalentRoute == Const_pb.TalentRouteType_1 then
        --路线1
        self.routeBtn0:setHighlighted(false)
        self.routeBtn1:setHighlighted(true)
    end



    UIExtend.setNodeVisible(self.ccbfile, "mSwitchTalentBtnNode", RATalentManager.CurrTurnOnType ~= self.currShowTalentRoute)
    local toolId = Const_pb.SHOP_TALENT_CHANGE
    local shopConstInfo = shop_conf[toolId]
    local itemId = shopConstInfo.shopItemID  
    local itemCfg = item_conf[itemId]
    local costIcon = ""
    local costNum = 1

  

    -- 有切换天赋道具提示使用道具，否则提示使用钻石
    if RACoreDataManager:getItemCountByItemId(itemId) > 0 then
        needItemName = _RALang(itemCfg.item_name)
        costIcon = itemCfg.item_icon..".png"
    else
        local RAResManager = RARequire('RAResManager')
        local Const_pb = RARequire('Const_pb')
        costIcon = RAResManager:getResourceIconByType(Const_pb.GOLD)
        costNum = itemCfg.sellPrice
    end

    UIExtend.addSpriteToNodeParent(self.ccbfile,"mTurnOnIconNode",costIcon)
    UIExtend.setCCLabelString(self.ccbfile,"mNeedNum", "x"..costNum)

    UIExtend.setNodeVisible(self.ccbfile,"mHeadIconNode1",RATalentManager.CurrTurnOnType == Const_pb.TalentRouteType_0)
    UIExtend.setNodeVisible(self.ccbfile,"mHeadIconNode2",RATalentManager.CurrTurnOnType == Const_pb.TalentRouteType_1)
    local mIconNode1 = UIExtend.getCCNodeFromCCB(self.ccbfile,"mIconNode1")
    local mIconNode2 = UIExtend.getCCNodeFromCCB(self.ccbfile,"mIconNode2")

    local RAPlayerInfoManager = RARequire('RAPlayerInfoManager')
    local icon = RAPlayerInfoManager.getHeadIcon()
    if RATalentManager.CurrTurnOnType == Const_pb.TalentRouteType_0 then--目前启用的是路线0
        UIExtend.setControlButtonTitle(self.ccbfile, "mFightSkillBtn", "@TalentRouteTurnOn0")
        UIExtend.setControlButtonTitle(self.ccbfile, "mDevelopSkillBtn", "@TalentRoute1")
        UIExtend.setCCLabelString(self.ccbfile,"mTalentExplain",_RALang("@ChangeTalent2"))
        UIExtend.addNodeToAdaptParentNode(mIconNode1,icon, 999)
    elseif RATalentManager.CurrTurnOnType == Const_pb.TalentRouteType_1 then
        UIExtend.setControlButtonTitle(self.ccbfile, "mFightSkillBtn", "@TalentRoute0")
        UIExtend.setControlButtonTitle(self.ccbfile, "mDevelopSkillBtn", "@TalentRouteTurnOn1")
        UIExtend.setCCLabelString(self.ccbfile,"mTalentExplain",_RALang("@ChangeTalent1"))
        UIExtend.addNodeToAdaptParentNode(mIconNode2,icon, 999)
    end

    --如果还未开放，处理现实文字
    if not RATalentManager.isTalentRoute2Open() then
        local openStr = _RALang("@TalentRouteOpen", const_conf.TalentRouteTurnOnLevel.value)
        UIExtend.setControlButtonTitle(self.ccbfile, "mDevelopSkillBtn", openStr, true)
    end

end

--desc:刷新天赋树
function RATalentSysMainPage:refreshTalentTree()
self.scrollView:removeAllCell()--情况所有cell
    self.rowWithTalentIds = {}
    --遍历所有天赋
    for key, value in Utilitys.table_pairsByKeys(player_talent_conf) do
        local constTalentCellShowInfo = talent_cell_show_conf[value.id]
        local row = constTalentCellShowInfo.row
        if self.rowWithTalentIds[row] == nil then
            self.rowWithTalentIds[row] = {}
        end
        table.insert(self.rowWithTalentIds[row], value.id)
    end

    for row, talenIdArr in ipairs(self.rowWithTalentIds) do
        local cell = CCBFileCell:create()
        local cellListener = RASkillGroupCellListener:new({rowIndex = row, skillType = self.currShowTalentRoute, skillIds = talenIdArr})
        if row == 1 then
            cell:setCCBFile("RALordSkillCell1.ccbi")
        else
            cell:setCCBFile("RALordSkillCell2.ccbi")
        end
        cell:registerFunctionHandler(cellListener)
        cell:setZOrder(#(self.rowWithTalentIds) - row)
        self.scrollView:addCell(cell)

    end
    self.scrollView:orderCCBFileCells()
    if self.svContentOffset ~= nil then
        self.scrollView:setContentOffset(self.svContentOffset)
    end
end


--desc:设置重置按钮
function RATalentSysMainPage:setResetBtn()
    --获得洗点道具数量
    
    local toolNum, itemIcon, itemPrice = self:getResetToolNum()

    local pic = ""--显示的图标
    local num = 0--显示的数量
    if toolNum >= RAGameConfig.TalentResetConsume.CONSUME_COUNT then
        pic = itemIcon .. ".png"
        num = 1
        self.hasResetTalentTools = true
    else
        pic = RAGameConfig.Diamond_Icon--金币的icon
        num = itemPrice--需要花费的金币数量
        self.hasResetTalentTools = false
    end

    UIExtend.setSpriteIcoToNode(self.ccbfile, "mResetIcon", pic)

    if self.hasResetTalentTools then
        UIExtend.getCCSpriteFromCCB(self.ccbfile,'mResetIcon'):setScale(0.15)
    else
        UIExtend.getCCSpriteFromCCB(self.ccbfile,'mResetIcon'):setScale(0.7)   
    end

    UIExtend.setCCLabelString(self.ccbfile, "mResetNum", num)


    --获得已使用的技能点
    local total = RATalentManager.getUseGeneralNumByType(self.currShowTalentRoute)
    if total > 0 then
    --按钮可用
        UIExtend.setCCControlButtonEnable(self.ccbfile, "mRevertPointBtn", true)
    else
    --按钮不可用
        UIExtend.setCCControlButtonEnable(self.ccbfile, "mRevertPointBtn", false)
    end
end

--desc:获得重置道具数量
function RATalentSysMainPage:getResetToolNum()
    local toolId = Const_pb.SHOP_TALENT_CLEAR
    local shopConstInfo = shop_conf[toolId]
    local itemId = shopConstInfo.shopItemID
    local constToolInfo = item_conf[itemId]
    local toolNum = RACoreDataManager:getItemCountByItemId(itemId)
    return toolNum,  constToolInfo.item_icon, shopConstInfo.price
end

--desc:获得启用天赋道具信息
function RATalentSysMainPage:getTurnOnTalentRouteToolNum()
    local toolId = Const_pb.SHOP_TALENT_CHANGE
    local shopConstInfo = shop_conf[toolId]
    local itemId = shopConstInfo.shopItemID
    local constToolInfo = item_conf[itemId]
    local toolNum = RACoreDataManager:getItemCountByItemId(itemId)
    return toolNum,  _RALang(constToolInfo.item_name), shopConstInfo.price
end

--desc:返回按钮
function RATalentSysMainPage:onBackBtn()
    if RAGuideManager.partComplete.Guide_UIUPDATE and RAGuideManager.isInGuide() then
        RARootManager.AddCoverPage()
        RAGuideManager.gotoNextStep()
    end
    RARootManager.ClosePage("RATalentSysMainPage")
end

--desc:路线0按钮
function RATalentSysMainPage:onFightSkillBtn()
    self.svContentOffset = self.scrollView:getContentOffset()
    if self.routeBtn0 then
        self.routeBtn0:setHighlighted(true)
    end
    if self.routeBtn1 then
        self.routeBtn1:setHighlighted(false)
    end
    if self.currShowTalentRoute == Const_pb.TalentRouteType_0  then
        return
    end
    self.currShowTalentRoute = Const_pb.TalentRouteType_0
    self:refreshPage()
end

--desc:重置按钮
function RATalentSysMainPage:onRevertPoint()
    self.svContentOffset = self.scrollView:getContentOffset()
    local toolNum, itemIcon, itemPrice = self:getResetToolNum()
    local confirmData = {}
    confirmData.labelText = self.hasResetTalentTools and _RALang("@TalentRevertLabel_Item") or _RALang("@TalentRevertLabel_Diamond",itemPrice)
    confirmData.title = ""
    confirmData.yesNoBtn = true
    confirmData.resultFun = function (isOk)
        if isOk then
            local msg = Talent_pb.HPTalentClearReq()
            if self:getResetToolNum() > 0 then
                self.hasResetTalentTools = true
            else
                self.hasResetTalentTools = false
            end
            msg.useGold = not self.hasResetTalentTools
            msg["type"] = self.currShowTalentRoute
            RANetUtil:sendPacket(HP_pb.TALENT_CLEAR_C, msg)
        end
    end
    RARootManager.OpenPage("RAConfirmPage", confirmData, nil, true, true)
end

--desc:发送清除协议
function RATalentSysMainPage:sendTalentClearReq()
    local msg = Talent_pb.HPTalentClearReq()
    msg.useGold = true
    msg.itemId = Const_pb.ITEM_TALENT_CLEAR
    msg["type"] = self.currShowTalentRoute
    RANetUtil:sendPacket(HP_pb.TALENT_CLEAR_C, msg)
end

--desc:路线2按钮点击
function RATalentSysMainPage:onDevelopSkillBtn()
    if not RATalentManager.isTalentRoute2Open() then
        --目前还没开放，不响应点击
        RARootManager.ShowMsgBox("@TalentRouteOpenTip", const_conf.TalentRouteTurnOnLevel.value)
        return
    end

    self.svContentOffset = self.scrollView:getContentOffset()
    if self.routeBtn0 then
        self.routeBtn0:setHighlighted(false)
    end
    if self.routeBtn1 then
        self.routeBtn1:setHighlighted(true)
    end

    if self.currShowTalentRoute == Const_pb.TalentRouteType_1  then
        return
    end
    self.currShowTalentRoute = Const_pb.TalentRouteType_1
    self:refreshPage()
end

--desc:点击启用
function RATalentSysMainPage:onEnableBtn()
    local shopItemNum,name,price = self:getTurnOnTalentRouteToolNum() 
    local confirmData = {}
    confirmData.labelText = shopItemNum > 0 and _RALang("@TalentRouteTurnOnTip", name) or _RALang("@TalentRouteGoldTurnOnTip", price)
    confirmData.title = _RALang("@TalentRouteTurnOn", self.currShowTalentRoute + 1)
    confirmData.yesNoBtn = true
    confirmData.resultFun = function (isOk)
        if isOk then
            local msg = Talent_pb.HPTalentChangeReq()
            msg.useGold = shopItemNum == 0
            msg["type"] = self.currShowTalentRoute
            RANetUtil:sendPacket(HP_pb.TALENT_CHANGE_C, msg)
        end
    end
    RARootManager.OpenPage("RAConfirmPage", confirmData, false, true, true)
end

function RATalentSysMainPage:Exit(data)
    
    self:removeHandler()

    if self.scrollView then
        self.scrollView:removeAllCell()
        self.scrollView = nil
    end
    self.rowWithTalentIds = {}
    self.svContentOffset = nil
    self.guideSingleTalentCCBFile=nil
    
    self.currShowTalentRoute = 0
    UIExtend.unLoadCCBFile(RATalentSysMainPage)
end
--//////////////////////////////////////////////////////////////////////////////