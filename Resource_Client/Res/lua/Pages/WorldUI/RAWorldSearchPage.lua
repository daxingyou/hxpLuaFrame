--region *.lua
--Date

RARequire('BasePage')
local RAWorldSearchPage = BaseFunctionPage:new(...)

local UIExtend = RARequire('UIExtend')
local RARootManager = RARequire('RARootManager')

RAWorldSearchPage.coord = {}

function RAWorldSearchPage:Enter(pageInfo)
	UIExtend.loadCCBFile('RACoordinatesSearchPage.ccbi', self)

    -- set title
    local RAStringUtil = RARequire('RAStringUtil')
    UIExtend.setCCLabelString(self.ccbfile, 'mCoordinatesSearchTitle', RAStringUtil.getLanguageString('@CoordinateSearch'))

    self.coord = 
    {
        k = pageInfo.k or '1',
        x = pageInfo.x,
        y = pageInfo.y
    }

    self:_showK()
    self:_showX()
    self:_showY()
end

function RAWorldSearchPage:onConfirmBtn()
    if self:_checkCoord() then
        local RAWorldManager = RARequire('RAWorldManager')
        local x, y, k = tonumber(self.coord.x), tonumber(self.coord.y), tonumber(self.coord.k)
        
        local RAWorldUtil = RARequire('RAWorldUtil')
        if RAWorldUtil.kingdomId.isSelf(k) then
            local RAWorldUIManager = RARequire('RAWorldUIManager')
            if RAWorldUIManager:IsBuildingSilo() then
                RAWorldManager:BuildSiloAt(x, y)
                RARootManager.CloseCurrPage()
                return
            end
        end
        
        RAWorldManager:LocateAt(x, y, k)
        RARootManager.CloseCurrPage()
    end
end

function RAWorldSearchPage:onClose()
	RARootManager.CloseCurrPage()
end

function RAWorldSearchPage:Exit()
    self.editBoxK:removeFromParentAndCleanup(true)
    self.editBoxY:removeFromParentAndCleanup(true)
    self.editBoxX:removeFromParentAndCleanup(true)
    self.editBoxK = nil
    self.editBoxY = nil
    self.editBoxX = nil
    UIExtend.unLoadCCBFile(self)
end

local function editboxEventHandlerK(eventType, node)
    --body
    CCLuaLog(eventType)
    if eventType == 'began' then
        node:setText("")
        -- triggered when an edit box gains focus after keyboard is shown
    elseif eventType == 'ended' then
        -- triggered when an edit box loses focus after keyboard is hidden.
    elseif eventType == 'changed' then
        -- triggered when the edit box text was changed.
        local k = node:getText()
        if k ~= "" and k ~= nil then
            RAWorldSearchPage.coord.k = node:getText()
        else
            --node:setText(RAWorldSearchPage.coord.k)
        end
        --RAWorldManager:LocateAt(tonumber(RAWorldSearchPage.coord.x), tonumber(RAWorldSearchPage.coord.y), tonumber(RAWorldSearchPage.coord.k))
    elseif eventType == 'return' then
        -- triggered when the return button was pressed or the outside area of keyboard was touched.
    end
end

local function editboxEventHandlerX(eventType, node)
    --body
    CCLuaLog(eventType)
    if eventType == 'began' then
        node:setText("")
        -- triggered when an edit box gains focus after keyboard is shown
    elseif eventType == 'ended' then
        -- triggered when an edit box loses focus after keyboard is hidden.
    elseif eventType == 'changed' then
        -- triggered when the edit box text was changed.
        local x = node:getText()
        if x ~= "" and x ~= nil then
            RAWorldSearchPage.coord.x = node:getText()
        else
            --node:setText(RAWorldSearchPage.coord.x)
        end
        --RAWorldManager:LocateAt(tonumber(RAWorldSearchPage.coord.x), tonumber(RAWorldSearchPage.coord.y), tonumber(RAWorldSearchPage.coord.k))
    elseif eventType == 'return' then
        -- triggered when the return button was pressed or the outside area of keyboard was touched.
    end
end

local function editboxEventHandlerY(eventType, node)
    --body
    CCLuaLog(eventType)
    if eventType == 'began' then
        node:setText("")
        -- triggered when an edit box gains focus after keyboard is shown
    elseif eventType == 'ended' then
        -- triggered when an edit box loses focus after keyboard is hidden.
    elseif eventType == 'changed' then
        -- triggered when the edit box text was changed.
        local y = node:getText()
        if y ~= "" and y ~= nil then
            RAWorldSearchPage.coord.y = node:getText()
        else
            --node:setText(RAWorldSearchPage.coord.y)
        end
        --RAWorldManager:LocateAt(tonumber(RAWorldSearchPage.coord.x), tonumber(RAWorldSearchPage.coord.y), tonumber(RAWorldSearchPage.coord.k))
    elseif eventType == 'return' then
        -- triggered when the return button was pressed or the outside area of keyboard was touched.
    end
end

function RAWorldSearchPage:_showK()
    local inputNode = UIExtend.getCCNodeFromCCB(self.ccbfile,'mInputKNode')
    if self.editBoxK == nil then
        local editBox = UIExtend.createEditBox(self.ccbfile,'mKsprite', inputNode, editboxEventHandlerK, nil, 4, kEditBoxInputModeNumeric, nil, nil, ccc3(255, 255, 255))
        -- editBox:setInputMode(kEditBoxInputModeNumeric)
        self.editBoxK = editBox
    end
    self.editBoxK:setIsDimensions(false)
    self.editBoxK:setText(self.coord.k)
    UIExtend.setStringForLabel(self.ccbfile,{mCoordinateK = ''})
end

function RAWorldSearchPage:_showX()
    local inputNode = UIExtend.getCCNodeFromCCB(self.ccbfile,'mInputXNode')
    if self.editBoxX == nil then
        local editBox = UIExtend.createEditBox(self.ccbfile, 'mXsprite', inputNode, editboxEventHandlerX, nil, 4, kEditBoxInputModeNumeric, nil, nil, ccc3(255, 255, 255))
        -- editBox:setInputMode(kEditBoxInputModeNumeric)
        self.editBoxX = editBox
    end
    self.editBoxX:setIsDimensions(false)
    self.editBoxX:setText(self.coord.x)
    UIExtend.setStringForLabel(self.ccbfile,{mCoordinateX = ''})
end

function RAWorldSearchPage:_showY()
    local inputNode = UIExtend.getCCNodeFromCCB(self.ccbfile,'mInputYNode')
    if self.editBoxY == nil then
        local editBox = UIExtend.createEditBox(self.ccbfile, 'mYsprite', inputNode, editboxEventHandlerY, nil, 4, kEditBoxInputModeNumeric, nil, nil, ccc3(255, 255, 255))
        -- editBox:setInputMode(kEditBoxInputModeNumeric)
       self.editBoxY = editBox
    end
    self.editBoxY:setIsDimensions(false)
    self.editBoxY:setText(self.coord.y)
    UIExtend.setStringForLabel(self.ccbfile,{mCoordinateY = ''})
end

function RAWorldSearchPage:_checkCoord()
    return true -- TODO
end

return RAWorldSearchPage

--endregion
