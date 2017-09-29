--region *.lua
--Date

RARequire('BasePage')
local RAAddFavoritePage = BaseFunctionPage:new(...)

local UIExtend = RARequire('UIExtend')
local RARootManager = RARequire('RARootManager')
local RAWorldConfig = RARequire('RAWorldConfig')

local FavType = RAWorldConfig.FavoriteType
local OperType = RAWorldConfig.OperType
local Type2Btn =
{
    [FavType.Mark] = 'mTargetBtn',
    [FavType.Friend] = 'mFriendsBtn',
    [FavType.Enemy] = 'mEnemyBtn'
}

RAAddFavoritePage.coord = {}
RAAddFavoritePage.name = ''
RAAddFavoritePage.icon = ''
RAAddFavoritePage.favType = FavType.Mark
RAAddFavoritePage.favTargetType = ''
RAAddFavoritePage.operType = OperType.Add
RAAddFavoritePage.favId = nil

function RAAddFavoritePage:Enter(pageInfo)
	UIExtend.loadCCBFile('RAFavoritesPupUp.ccbi', self)

    self:_resetData()
    self.operType = pageInfo.operType or OperType.Add

    if self.operType == OperType.Update then
        local favInfo = pageInfo.favInfo
        self.coord = favInfo.coord
        self.name = favInfo.name
        self.favTargetType = favInfo.targetType
        self.favId = favInfo.id
        self.icon = favInfo.icon
    else
        self.coord = pageInfo.coord
        self.name = pageInfo.name or ''
        self.icon = pageInfo.icon or ''
        self.favTargetType = pageInfo.targetType or ''
    end
    
    UIExtend.setCCLabelString(self.ccbfile, 'mCoordinateLabel', 'X: ' .. self.coord.x .. ' Y: ' .. self.coord.y)
    UIExtend.addSpriteToNodeParent(self.ccbfile, 'mTargetIconNode', self.icon)
    
    self:_showName()
    self:_changeType(self.favType, true)
end

function RAAddFavoritePage:Exit()
    if self.editBox then
        self.editBox:removeFromParentAndCleanup(true)
    end
    self.editBox = nil
    UIExtend.unLoadCCBFile(self)
    self:_resetData()
end

function RAAddFavoritePage:onTargetBtn()
    self:_changeType(FavType.Mark)
end

function RAAddFavoritePage:onFriendsBtn()
    self:_changeType(FavType.Friend)
end

function RAAddFavoritePage:onEnemyBtn()
    self:_changeType(FavType.Enemy)
end

function RAAddFavoritePage:onShareAlliance()
    RARootManager.ShowMsgBox('@NoOpenTips')
end

function RAAddFavoritePage:onConfirmFavorites()
    local RAWorldProtoHandler = RARequire('RAWorldProtoHandler')
    if self.operType == OperType.Add then
        RAWorldProtoHandler:sendAddFavorite(self.coord, self.name, self.favType, self.favTargetType)
    else
        RAWorldProtoHandler:sendUpdateFavorite(self.coord, self.name, self.favType, self.favTargetType, self.favId)
    end
    RARootManager.CloseCurrPage()
end

function RAAddFavoritePage:onCloseBtn()
	RARootManager.CloseCurrPage()
end

function RAAddFavoritePage:_resetData()
    self.coord = {}
    self.name = ''
    self.favType = FavType.Mark
    self.favTargetType = ''
    self.operType = OperType.Add
    self.favId = nil
    self.icon = ''
end

function RAAddFavoritePage:_changeType(favType, isInit)
    local selecteTB = {[Type2Btn[favType]] = true}

    if isInit then
        for _, _type in pairs(FavType) do
            if _type ~= favType then
                selecteTB[Type2Btn[_type]] = false
            end
        end
    end

    if favType ~= self.favType then
        selecteTB[Type2Btn[self.favType]] = false
        self.favType = favType
    end
    UIExtend.setMenuItemSelected(self.ccbfile, selecteTB)
end

local function editboxEventHandler(eventType, node)
    --body
    CCLuaLog(eventType)
    if eventType == 'began' then
        -- triggered when an edit box gains focus after keyboard is shown
    elseif eventType == 'ended' then
        -- triggered when an edit box loses focus after keyboard is hidden.
        RAAddFavoritePage.name = RAAddFavoritePage.editBox:getText()
    elseif eventType == 'changed' then
        -- triggered when the edit box text was changed.
    elseif eventType == 'return' then
        -- triggered when the return button was pressed or the outside area of keyboard was touched.
    end
end

function RAAddFavoritePage:_showName()
	--UIExtend.setCCLabelString(self.ccbfile, 'mTargetName', self.name)
    local inputNode = UIExtend.getCCNodeFromCCB(self.ccbfile, 'mInputNode')
    if self.editBox == nil then
        local editBox = UIExtend.createEditBox(self.ccbfile, 'mScale9Sprite', inputNode, editboxEventHandler, nil, nil, nil, 24, nil, ccc3(255, 255, 255))
        editBox:setInputMode(kEditBoxInputModeSingleLine)
        editBox:setMaxLength(15)
        self.editBox = editBox
    end
    self.editBox:setText(self.name)
end

return RAAddFavoritePage
--endregion
