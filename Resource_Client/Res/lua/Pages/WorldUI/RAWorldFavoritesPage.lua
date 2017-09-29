--region *.lua
--Date

RARequire('BasePage')
local RAWorldFavoritesPage = BaseFunctionPage:new(...)

local UIExtend = RARequire('UIExtend')
local RARootManager = RARequire('RARootManager')
local Utilitys = RARequire('Utilitys')
local RAStringUtil = RARequire('RAStringUtil')
local RAUserFavoriteManager = RARequire('RAUserFavoriteManager')
local common = RARequire('common')
local RAWorldUtil = RARequire('RAWorldUtil')
local RAWorldConfig = RARequire('RAWorldConfig')
local FavType = RAWorldConfig.FavoriteType

local PageType =
{	
	SHOW = 1,
	EDIT = 2
}

local Page2SV =
{
	[PageType.SHOW] = 'mFavoritesPageSV',
	[PageType.EDIT] = 'mSelectSV'
}

local Page2BTn =
{
	[PageType.SHOW] = 'mEditCellBtnNode',
	[PageType.EDIT] = 'mFinishBtnNode'
}

local Tab2Num =
{
	[FavType.Mark] = 'mTargetNum',
	[FavType.Friend] = 'mFriendsNum',
	[FavType.Enemy] = 'mEnemyNum'
}

local Tab2Btn =
{
	[FavType.Mark] = 'mTargetBtn',
	[FavType.Friend] = 'mFriendsBtn',
	[FavType.Enemy] = 'mEnemyBtn'
}

--------------------------------------------------------------------------------------
-- region: RAFavItemCellHandler

local RAFavItemCellHandler =
{
	isEditing = false,

	isSelected = false,

	favInfo = {},
    
    new = function(self, o)
        o = o or {}
        setmetatable(o,self)
        self.__index = self    
        return o
    end,

    getCCBName = function(self)
        return self.isEditing and 'RAFavoritesPageSelectCell.ccbi' or 'RAFavoritesPageCell.ccbi'
    end,

    onRefreshContent = function(self, cellRoot)
        local ccbfile = cellRoot:getCCBFileNode()
        if ccbfile == nil then return end

        local coord = self.favInfo.coord
        UIExtend.setStringForLabel(ccbfile, {
        	mCoordinateLabel = 'K: ' .. coord.k .. ' X: ' .. coord.x .. ' Y: ' .. coord.y,
        	mFavoritesCellLabel = self.favInfo.name
        })

        local icon = RAWorldUtil:GetFavoriteIcon(self.favInfo.targetType) or ''
        self.favInfo.icon = icon
        UIExtend.addSpriteToNodeParent(ccbfile, 'mFavoritesIconNode', icon)
        
        if self.isEditing then
        	UIExtend.setNodeVisible(ccbfile, 'mSelectPic', self.isSelected)
        end
    end,

    onSelectBtn = function(self, ccbfile)
    	self.isSelected = not self.isSelected
    	UIExtend.setNodeVisible(ccbfile, 'mSelectPic', self.isSelected)
    	MessageManager.sendMessage(MessageDef_ScrollViewCell.MSG_FavoriteListCell, {id = self.favInfo.id})
    end,

    onOpenBtn = function(self)
    	local RAWorldManager = RARequire('RAWorldManager')
    	local coord = self.favInfo.coord
    	RAWorldManager:LocateAt(coord.x, coord.y, coord.k, true)

    	RARootManager.CloseCurrPage()
    end,

    onEditBtn = function(self)
    	local pageInfo =
    	{
    		operType = RAWorldConfig.OperType.Update,
    		favInfo = self.favInfo
    	}
    	RARootManager.OpenPage('RAAddFavoritePage', pageInfo, false, true, false)
    end
}

-- endregion: RAFavItemCellHandler
--------------------------------------------------------------------------------------

RAWorldFavoritesPage.pageType = PageType.SHOW
RAWorldFavoritesPage.tab = FavType.Mark
RAWorldFavoritesPage.favList = {}
RAWorldFavoritesPage.selectList = {}
RAWorldFavoritesPage.mScrollView = nil
RAWorldFavoritesPage.selectAll = false

function RAWorldFavoritesPage:Enter(pageInfo)
	UIExtend.loadCCBFile('RAFavoritesPage.ccbi', self)
	UIExtend.setCCLabelString(self.ccbfile, 'mTitle', RAStringUtil:getLanguageString('@FavoriteList'))
	UIExtend.setCCLabelString(self.ccbfile, 'mExplain', RAStringUtil:getLanguageString('@FavoriteExplain'))
	UIExtend.createLabelAction(self.ccbfile,'mExplain')
	self:_refreshCount()
	
	self:_resetData()

	self:_changePagType(PageType.SHOW)
	self:_changeTab(FavType.Mark, true)
	self.mScrollView = UIExtend.getCCScrollViewFromCCB(self.ccbfile, Page2SV[self.pageType])
	self:_initScrollview(true)
	self:_registerMessageHandlers()
end

function RAWorldFavoritesPage:Exit()
	self:_unregisterMessageHandlers()
	if self.mScrollView then
		self.mScrollView:removeAllCell()
		self.mScrollView = nil
	end
	self:_resetData()
	UIExtend.unLoadCCBFile(self)
end

function RAWorldFavoritesPage:onEditCellBtn()
	self:_changePagType(PageType.EDIT)
end

function RAWorldFavoritesPage:onFinishBtn( ... )
	self:_changePagType(PageType.SHOW)
end

function RAWorldFavoritesPage:onTargetBtn()
	self:_changeTab(FavType.Mark)
end

function RAWorldFavoritesPage:onFriendsBtn()
	self:_changeTab(FavType.Friend)
end

function RAWorldFavoritesPage:onEnemyBtn()
	self:_changeTab(FavType.Enemy)
end

function RAWorldFavoritesPage:onSelectAllBtn()
	self.selectAll = not self.selectAll
	self:_selectAll()
	self:_initScrollview()
end

function RAWorldFavoritesPage:onDeleteBtn()
	local idTB = {}
	for k, v in pairs(self.selectList) do
		if v then
		 	table.insert(idTB, k)
		 end
	end
	
	if #idTB > 0 then
		local this = self
		local confirmData = 
		{
			yesNoBtn = true,
			labelText = RAStringUtil:getLanguageString('@ConfirmToDeleteFavorites'),
			resultFun = function (isOK)
				if isOK then
					this:_deleteFavorites(idTB)
				end
			end
		}
		RARootManager.OpenPage("RAConfirmPage", confirmData)
	else
		RARootManager.ShowMsgBox('@PlzSelectAFavorite')
	end
end

function RAWorldFavoritesPage:onBack()
	RARootManager.CloseCurrPage()
end

function RAWorldFavoritesPage:_registerMessageHandlers()
    MessageManager.registerMessageHandler(MessageDef_ScrollViewCell.MSG_FavoriteListCell, self._onReceiveMessage)
    MessageManager.registerMessageHandler(MessageDef_World.MSG_UpdateFavorite, self._onReceiveMessage)
end

function RAWorldFavoritesPage:_unregisterMessageHandlers()
    MessageManager.removeMessageHandler(MessageDef_ScrollViewCell.MSG_FavoriteListCell, self._onReceiveMessage) 
    MessageManager.removeMessageHandler(MessageDef_World.MSG_UpdateFavorite, self._onReceiveMessage)
end

function RAWorldFavoritesPage._onReceiveMessage(msg)
    if msg.messageID == MessageDef_ScrollViewCell.MSG_FavoriteListCell then
    	local id = msg.id
    	RAWorldFavoritesPage.selectList[id] = not RAWorldFavoritesPage.selectList[id]
        return
    end

    if msg.messageID == MessageDef_World.MSG_UpdateFavorite then
    	RAWorldFavoritesPage:_refreshCount()
    	RAWorldFavoritesPage:_initScrollview(true)
    	return
    end
end

function RAWorldFavoritesPage:_resetData()
	self.pageType = PageType.SHOW
	self.tab = FavType.Mark
	self.selectedTab = nil
	self.favList = {}
	self.selectList = {}
	self.selectAll = false
end

function RAWorldFavoritesPage:_changePagType(newPageType)
	local isShow = newPageType == PageType.SHOW
	UIExtend.setNodesVisible(self.ccbfile, {
		[Page2BTn[PageType.SHOW]] = isShow,
		[Page2BTn[PageType.EDIT]] = not isShow,
		[Page2SV[PageType.SHOW]] = isShow,
		[Page2SV[PageType.EDIT]] = not isShow,
		mSelectBottomNode = not isShow
	})
	if self.pageType ~= newPageType then
		self.mScrollView = UIExtend.getCCScrollViewFromCCB(self.ccbfile, Page2SV[newPageType])
		self.pageType = newPageType
		if isShow then
			self.selectAll = false
			self:_selectAll()
		end
		self:_initScrollview()
	end
end

function RAWorldFavoritesPage:_changeTab(newTab, isInit)
	local selecteTB = {[Tab2Btn[newTab]] = true}
	
	if isInit then
		for _, tab in pairs(FavType) do
			if tab ~= newTab then
				selecteTB[Tab2Btn[tab]] = false
			end
		end
	end
	
	if newTab ~= self.tab then
		selecteTB[Tab2Btn[self.tab]] = false
		self.tab = newTab
		self.selectAll = false
		self:_initScrollview(true)
	end
	UIExtend.setControlButtonSelected(self.ccbfile, selecteTB)
end

function RAWorldFavoritesPage:_initScrollview(needUpdateList)
	if needUpdateList then
		self.favList = RAUserFavoriteManager:getFavoriteList(self.tab)
		if self.pageType == PageType.EDIT then
			self:_selectAll()
		end
	end
	self.mScrollView:removeAllCell()

	local isEditing = self.pageType == PageType.EDIT
	for i = #self.favList, 1, -1 do
		local favInfo = self.favList[i]
		
		local itemCell = CCBFileCell:create()
		local cellHandler = RAFavItemCellHandler:new({
			isEditing = isEditing,
			isSelected = isEditing and self.selectList[favInfo.id],
			favInfo = favInfo
		})

		itemCell:registerFunctionHandler(cellHandler)
		itemCell:setCCBFile(cellHandler:getCCBName())

		self.mScrollView:addCellBack(itemCell)
	end
	self.mScrollView:orderCCBFileCells()
end

function RAWorldFavoritesPage:_selectAll()
	self.selectList = {}
	if self.selectAll then
		for _, favInfo in ipairs(self.favList) do
			self.selectList[favInfo.id] = true
		end
	end
end

function RAWorldFavoritesPage:_deleteFavorites(idTB)
	for _, v in pairs(idTB) do
		RAUserFavoriteManager:deleteFavorite(v, self.favType)
	end
	
	local RAWorldProtoHandler = RARequire('RAWorldProtoHandler')
    RAWorldProtoHandler:sendDeleteFavorite(idTB)

	self:_refreshCount()
	self:_initScrollview(true)
end

function RAWorldFavoritesPage:_refreshCount()
	local txtTB = {}
	for _, favType in pairs(FavType) do
		txtTB[Tab2Num[favType]] = RAUserFavoriteManager:getFavoriteCount(favType)
	end
	UIExtend.setStringForLabel(self.ccbfile, txtTB)
end

return RAWorldFavoritesPage
--endregion
