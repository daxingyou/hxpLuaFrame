 RARequire('BasePage')
local RAWorldHud = BaseFunctionPage:new(...)

local RARootManager = RARequire('RARootManager')
local UIExtend = RARequire('UIExtend')
local RAStringUtil = RARequire('RAStringUtil')
local Const_pb = RARequire('Const_pb')
local RAUserFavoriteManager = RARequire('RAUserFavoriteManager')
local Utilitys = RARequire('Utilitys')
local RAWorldConfig = RARequire('RAWorldConfig')
local HudBtnType = RAWorldConfig.HudBtnType

local MarchBtnMap =
{
    [HudBtnType.MarchArmyDetail]    = {'mTroopLineNode',    'mTroopBtnNode'},
    [HudBtnType.MarchSpeedUp]       = {'mAccelateLineNode', 'mAccelateBtnNode'},
    [HudBtnType.MarchRecall]        = {'mBackLineNode',     'mBackBtnNode'}
}

-- hud按钮最大个数
local Hud_Count_Max = 7

--------------------------------------------------------------------------------------
-- region: RAWorldHudBtn

local RAWorldHudBtn = {}

function RAWorldHudBtn:new(btnType, handler)
    local o = {}

    o.btnType = btnType
    o.handler = handler
    setmetatable(o, self)
    self.__index = self
    return o
end

function RAWorldHudBtn:addToParent(parentNode)
    if parentNode ~= nil then
        self:_init()
        parentNode:addChild(self.ccbfile)
    end
end

function RAWorldHudBtn:Release()
    UIExtend.unLoadCCBFile(self)
end

function RAWorldHudBtn:_init()
    UIExtend.loadCCBFile('RAHUDWorldCell.ccbi', self)
    self.ccbfile:setAnchorPoint(0, 0)
    self.ccbfile:setPosition(0, 0)
    UIExtend.setNodeVisible(self.ccbfile, 'mHUDNameNode', true)
    UIExtend.setCCControlButtonEnable(self.ccbfile, 'mFunction', true)
    
    local spriteName = RAWorldConfig.HudBtnImg[self.btnType]
    UIExtend.setSpriteIcoToNode(self.ccbfile, 'mHUDIcon', spriteName)

    local btnStr = RAStringUtil:getLanguageString(RAWorldConfig.HudBtnLang[self.btnType])
    UIExtend.setCCLabelString(self.ccbfile, 'mBtnName', btnStr)
end

function RAWorldHudBtn:onFunciton()
    if self.handler ~= nil then 
        self.handler:onFunction(self.btnType)
    end 
end

-- endregion: RAWorldHudBtn
--------------------------------------------------------------------------------------

--------------------------------------------------------------------------------------
-- region: RAWorldCoordBar

local RAWorldCoordBar = {}

function RAWorldCoordBar:new(coord, handler, height, resInfo)
    local o = {}

    o.coord = coord
    o.handler = handler
    o.height = height
    o.resInfo = resInfo
    o.resLabel = nil

    setmetatable(o, self)
    self.__index = self
    
    return o
end

function RAWorldCoordBar:addToParent(parentNode, pos)
    if parentNode ~= nil then
        self:_init()
        self.ccbfile:setAnchorPoint(0.5, 0.5)
        self.ccbfile:setPosition(0, self.height)

        parentNode:addChild(self.ccbfile)
    end
end

function RAWorldCoordBar:Release()
    UIExtend.unLoadCCBFile(self)
end

function RAWorldCoordBar:_init()
    UIExtend.loadCCBFile('RAHUDWorldTitle.ccbi', self)
    UIExtend.setCCLabelString(self.ccbfile, 'mCoordinateLabel', 'X: ' .. self.coord.x .. ' Y: ' .. self.coord.y)
    local isFavorite = RAUserFavoriteManager:isFavorite(self.coord)
    UIExtend.setNodeVisible(self.ccbfile, 'mFavoriteNode', not isFavorite)

    local isRes = self.resInfo ~= nil
    if isRes then
        UIExtend.setNodeVisible(self.ccbfile, 'mHUDResIcon', false)
        UIExtend.addSpriteToNodeParent(self.ccbfile, 'mHUDResIcon', self.resInfo.icon)
        self.resLabel = UIExtend.getCCLabelTTFFromCCB(self.ccbfile, 'mHUDRes')
        self:UpdateResource()
    end
    UIExtend.setNodeVisible(self.ccbfile, 'mHUDResNode', isRes)
end

function RAWorldCoordBar:UpdateResource(remain)
    if self.resLabel == nil then return end
    if remain and remain == self.resInfo.remain then return end

    if remain then
        self.resInfo.remain = remain
    end
    self.resLabel:setString(tostring(self.resInfo.remain))
end

function RAWorldCoordBar:onAddFavoritesBtn()
    if self.handler ~= nil then 
        self.handler:onFunction(RAWorldConfig.HudBtnType.AddFavorite)
    end 
end

-- endregion: RAWorldCoordBar
--------------------------------------------------------------------------------------

RAWorldHud.handler = nil
RAWorldHud.marchDirTxt = ''
RAWorldHud.isMarching = false
RAWorldHud.coordBar = nil
RAWorldHud.btnList = nil
RAWorldHud.htmlLabel = nil
RAWorldHud.targetPos = nil

function RAWorldHud:Init(btnTypeTB, coord, hudHandler, nodeSize, resInfo)
    UIExtend.loadCCBFile('RAHUDWorldNode.ccbi', self)

    self:_initTitle()
    self:_initCoordBar(coord, nodeSize, resInfo)
    self:_initBtns(btnTypeTB)
    self:_restoreScale()

    self.handler = hudHandler
    self.isMarching = false

    local this = self
    performWithDelay(self.ccbfile,function()
        this:_sendGuideMsg()
    end,0.1)
    
end

function RAWorldHud:Release()
    if self.coordBar then
        self.coordBar:Release()
        self.coordBar = nil
    end
    if self.btnList then
        for _, btn in ipairs(self.btnList) do
            if btn then
                btn:Release()
            end
        end
        self.btnList = nil
    end
    if self.htmlLabel then
        self.htmlLabel:removeLuaClickListener()
        self.htmlLabel = nil
    end
    self.targetPos = nil
    UIExtend.unLoadCCBFile(self)
end

function RAWorldHud:InitMarchHud(btnTypeTB, marchId, hudHandler)
    UIExtend.loadCCBFile('RAHUDWorldMarchAni.ccbi', self)

    self:_initMarchInfo(marchId)
    self:_initMarchBtns(btnTypeTB)
    self:_restoreScale()

    self.handler = hudHandler
    self.isMarching = true
end

function RAWorldHud:UpdateTime(lastTime)
    if self.isMarching then
        local timeStr = Utilitys.createTimeWithFormat(lastTime) or ''
        local txt = self.marchDirTxt .. timeStr
        UIExtend.setCCLabelString(self.ccbfile, 'mTroopTime', txt)
    end
end

function RAWorldHud:UpdateResource(remain)
    if self.coordBar then
        self.coordBar:UpdateResource(remain)
    end
end

function RAWorldHud:_restoreScale()
    -- hud不参与缩放
    local RAWorldScene = RARequire('RAWorldScene')
    self.ccbfile:setScale(1 / RAWorldScene:GetScale())
end

function RAWorldHud:_initTitle()
    UIExtend.setNodeVisible(self.ccbfile, 'mHUDTitleNode', false)
end

function RAWorldHud:_initCoordBar(coord, nodeSize, resInfo)
    if coord == nil then return end

    local coordBar = RAWorldCoordBar:new(coord, self, nodeSize.height, resInfo)
    coordBar:addToParent(self.ccbfile)

    self.coordBar = coordBar
end

function RAWorldHud:_initBtns(btnTypeTB)
    btnTypeTB = btnTypeTB or {}
    local btnCount = #btnTypeTB

    if btnCount < 1 then return end

    self.btnList = {}
    
    for k, btnType in ipairs(btnTypeTB) do
        self:_initSingleBtn(k, btnType)
    end

    if btnCount > Hud_Count_Max then
        btnCount = Hud_Count_Max
    end
    if btnCount > 0 then
        self.ccbfile:runAnimation('FunAni' .. btnCount)
    end
end

function RAWorldHud:_initSingleBtn(btnIndex, btnType)
    if btnIndex > Hud_Count_Max then return end

    local btnContainer = self.ccbfile:getCCNodeFromCCB('mFunNode' .. btnIndex)
    local btn = RAWorldHudBtn:new(btnType, self)
    btn:addToParent(btnContainer)
    table.insert(self.btnList, btn)
end

function RAWorldHud:_initMarchInfo(marchId)
    local RAMarchDataManager = RARequire('RAMarchDataManager')
    local World_pb = RARequire('World_pb')
    local marchData = RAMarchDataManager:GetMarchDataById(marchId)

    local htmlLabel = UIExtend.getCCLabelHTMLFromCCB(self.ccbfile, 'mPosLabel')
    if htmlLabel then
        local targetPos = marchData:GetEndCoord()
        local nameStr = targetPos.x .. ',' .. targetPos.y
        local htmlStr = RAStringUtil:getHTMLString('MarchTarget', nameStr, targetPos.x, targetPos.y)
        htmlLabel:setString(htmlStr)
        htmlLabel:registerLuaClickListener(self._onHrefLink)
        htmlLabel:setScale(RAWorldConfig.MarchHtmlScale)
        self.htmlLabel = htmlLabel
        self.targetPos = targetPos
    end

    local nameStr = Utilitys.getDisplayName(marchData.playerName or '', marchData.guildTag)
    UIExtend.setCCLabelString(self.ccbfile, 'mTroopName', nameStr)

    local dirTxt = '('
    if marchData.marchStatus == World_pb.MARCH_STATUS_MARCH then
        dirTxt = dirTxt .. RAStringUtil:getLanguageString('@TroopCharge')
    elseif marchData.marchStatus == World_pb.MARCH_STATUS_RETURN_BACK then
        dirTxt = dirTxt .. RAStringUtil:getLanguageString('@Return')
    end
    self.marchDirTxt = dirTxt .. ')'

    self:UpdateTime(marchData:GetLastTime())
end

function RAWorldHud:_initMarchBtns(btnTypeTB)
    btnTypeTB = btnTypeTB or {}

    local showBtn = #btnTypeTB > 0
    local visibleMap =
    {
        mLineNode = showBtn,
        mAllBtnNode = showBtn
    }

    if showBtn then
        local common = RARequire('common')
        for btnType, nodeNames in pairs(MarchBtnMap) do
            local visible = common:table_contains(btnTypeTB, btnType)
            local lineName, btnName = unpack(nodeNames)
            visibleMap[lineName] = visible
            visibleMap[btnName] = visible
        end
    end
    
    UIExtend.setNodesVisible(self.ccbfile, visibleMap)
end

function RAWorldHud._onHrefLink(id, data)
    local RAGameConfig = RARequire('RAGameConfig')
    if id == RAGameConfig.HTMLID.MarchTarget then
        local pos = RAStringUtil:split(data or '', ',') or {}
        local x, y = unpack(pos)
        if x and y then
            MessageManager.sendMessage(MessageDef_World.MSG_LocateAtPos, RACcp(tonumber(x), tonumber(y)))
        end
    end
end

function RAWorldHud:_sendGuideMsg()
     local RAGuideManager = RARequire('RAGuideManager')
     if not RAGuideManager.isInGuide() then return end
     
     local guideinfo = RAGuideManager.getConstGuideInfoById()
     if guideinfo ~= nil and guideinfo.btnType ~= nil then 
         local info = self:_getBtnInfo(guideinfo.btnType)
         if info ~= nil then 
             info.pos.x = info.pos.x - info.size.width * 0.5 + 5
             info.pos.y = info.pos.y - info.size.height * 0.5 + 5
             info.size.width = info.size.width - 15
             info.size.height = info.size.height - 10
             MessageManager.sendMessage(MessageDef_Building.MSG_Guide_Hud_BtnInfo,{pos = info.pos, size = info.size})
             return
         end 
     end 
end

--desc:出征的时候，返回加速按钮的信息
function RAWorldHud:_sendGuideMarchMsg()
    local RAGuideManager = RARequire('RAGuideManager')
    if not RAGuideManager.isInGuide() then return end

    if self.ccbfile then
        local accNode = UIExtend.getCCNodeFromCCB(self.ccbfile, "mAccelateBtnNode")
        if accNode then
            local x, y = accNode:getPosition()
            local _ccp = ccp(x, y)
            local pos = accNode:getParent():convertToWorldSpace3D(_ccp)
            local contentSize = CCSizeMake(118, 55)
            pos.x = pos.x - contentSize.width*0.5
            pos.y = pos.y - contentSize.height*0.5
            print("accNode:convertToWorldSpace   pos.x is ",pos.x,"pos.y",pos.y)
            _ccp:delete()

            MessageManager.sendMessage(MessageDef_Building.MSG_Guide_Hud_BtnInfo,{pos = pos, size = contentSize})
        end
    end

end

-- 获得指定类型按钮的位置信息和大小
function RAWorldHud:_getBtnInfo(btnType)
    for k, v in ipairs(self.btnList) do
        if k <= Hud_Count_Max and v.btnType == btnType then 
            local btnContainer = self.ccbfile:getCCNodeFromCCB('mFunNode' .. k)
            local x, y = btnContainer:getPosition()
            local contentSize = btnContainer:getContentSize()

            local _ccp = ccp(x, y)
            local pos = btnContainer:getParent():convertToWorldSpace3D(_ccp)
            print("btnContainer:convertToWorldSpace   pos.x is ",pos.x,"pos.y",pos.y)
            _ccp:delete()

            return {pos = pos, size = contentSize}
        end 
    end

    return nil 
end

function RAWorldHud:onCoordClick()
	if self.targetPos then
		MessageManager.sendMessage(MessageDef_World.MSG_LocateAtPos, self.targetPos)
	end
end

function RAWorldHud:onTroopBtn()
    self:onFunction(HudBtnType.MarchArmyDetail)
end

function RAWorldHud:onAccelateBtn()
    self:onFunction(HudBtnType.MarchSpeedUp)
    local RAGuideManager = RARequire("RAGuideManager")
    if RAGuideManager.isInGuide() then
        RARootManager.AddCoverPage()
        RARootManager.RemoveGuidePage()
    end
end

function RAWorldHud:onBackBtn()
    self:onFunction(HudBtnType.MarchRecall)
end

function RAWorldHud:onFunction(btnType)
    if self.handler then 
        self.handler:onHudFunction(btnType)
    end 
end

function RAWorldHud:setPosition(x,y)
    self.ccbfile:setPosition(x,y) 
end

function RAWorldHud:setScale(scale)
    if self.ccbfile then
        self.ccbfile:setScale(scale)
    end
end

function RAWorldHud:addToParent(parentNode)
    if parentNode ~= nil then
        self.ccbfile:setAnchorPoint(0.5, 1)
        parentNode:addChild(self.ccbfile)
    end
end

function RAWorldHud:removeFromParent()
    self.ccbfile:removeFromParentAndCleanup(true)
end

function RAWorldHud:SetBillboard()
    if self.ccbfile then
        CCCamera:setBillboard(self.ccbfile)
    end

    

end

return RAWorldHud