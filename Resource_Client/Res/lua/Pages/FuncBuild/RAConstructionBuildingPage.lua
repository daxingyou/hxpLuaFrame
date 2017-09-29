--require('UICore.ScrollViewAnimation')
RARequire("BasePage")


local RAConstructionBuildingPage = BaseFunctionPage:new(...)

local createContentItem = nil


function RAConstructionBuildingPage:nodecallback(event)
	CCLuaLog(event .. "exittttttttttttttttttttttttttttttttt")
end

function RAConstructionBuildingPage:getRootNode()
	return RAConstructionBuildingPage.ccbfile
end

function RAConstructionBuildingPage:resetData()
    self.ccbfile = nil
	self.m_buildIds = {}
	self.m_buildLockInfos = {}
	self.m_pos = 0
	self.m_openNum = 0
	self.m_itemId = ""
	self.m_initEnd = false
	self.gBuildId = 0
end

function RAConstructionBuildingPage:Enter(data)
	self:resetData()

	CCLuaLog("RAConstructionBuildingPage:Enter")
	local ccbfile = UIExtend.loadCCBFile("ccbi/ConstructionBuildingPage.ccbi",RAConstructionBuildingPage)
    ccbfile:setModelLayerDisplay(false)

	self.mBuildingScroll = UIExtend.getCCScrollViewFontFromCCB(ccbfile,"mBuildingListScrollView")
	self.mBuidlingNameTex = UIExtend.getCCLabelTTFFromCCB(ccbfile,"mBuidlingNameTex")
	self.mDescriptionTex = UIExtend.getCCLabelTTFFromCCB(ccbfile,"mDescriptionTex")
	self.mRequirementsTex = UIExtend.getCCLabelTTFFromCCB(ccbfile,"mRequirementsTex")
	self.mConstructionBtn = UIExtend.getCCControlButtonFromCCB(ccbfile, "mConstructionBtn")

    local handler = function(e)
                        self:nodecallback(e)
                    end
    ccbfile:init()
    ccbfile:registerScriptHandler(handler)

    for i,v in ipairs(data) do
    	CCLuaLog("RAConstructionBuildingPage:Enter  i="..i.." data="..data[i])
    end
	local buildKey = data[1]
    CCLuaLog("RAConstructionBuildingPage:Enter   buildKey:"..buildKey)
    self.m_pos = tonumber(buildKey)
    self:UpdatePageData()
	RAConstructionBuildingPage:createContent()
    self:refreshByBuildIndex(1)
end

function RAConstructionBuildingPage:createContent()
	self.mBuildingScroll:removeAllCell()
	createContentItem(self.m_buildIds, self.m_itemId)
end	


function RAConstructionBuildingPage:UpdatePageData()
	local tmpbuilds = FunBuildController:getInstance():getBuildByPos(self.m_pos);
    tmpbuilds = FunBuildController:getInstance():orderBuild(tmpbuilds);
    local buildIds = Utilitys.Split(tmpbuilds, ";")
    local cellCnt = 1
    local btnNames = {}
    local btnIcons = {}
    for i,v in ipairs(buildIds) do
    	CCLuaLog("i:"..i .."  v:"..v)
        local _tb = true;
        local tmpItemId = tonumber(v)
        local temItemIdStr = tostring(v)
        CCLuaLog(type(temItemIdStr))
        local name = CCCommonUtils.getNameById(temItemIdStr)
        local limitNum = CCCommonUtils.getPropById(temItemIdStr, "num")
        local pic = CCCommonUtils.getPropById(temItemIdStr, "pic");
        pic = pic.."_"..GlobalData:shared().contryResType..".png"
        local destip = CCCommonUtils.getPropById(temItemIdStr, "destip")
        destip = _lang(destip)
        if tonumber(limitNum) > 0 then
        	local curNum = FunBuildController:getInstance():getBuildNumByType(tmpItemId)
        	if tonumber(curNum) >= tonumber(limitNum) then
        		_tb = false
        	end
        end
        if _tb then        	
        	local item = {
        		buildName = name,
        		buildIcon = pic,
        		id = temItemIdStr,
        		destip = destip,
        		limitNum = limitNum,
        		lockStr = "",
                isLock = false
        	}
            if cellCnt == 1 then
                self.m_itemId = temItemIdStr                
            end
        	self.m_buildIds[cellCnt] = item
        	cellCnt = cellCnt+1
        end
    end
    local showPos = 1
    for i=1,cellCnt-1 do
    	local itemData = self.m_buildIds[i]
    	local dict = LocalController:shared():DBXMLManager():getObjectByKey(tostring(itemData.id))
    	local buildInfo = FunBuildInfo:new(dict)
    	local isLock = false
    	if not buildInfo:isUnLock() then
    		isLock = true
    		local locakStr = _lang("102130")    		
    		locakStr = locakStr.." "
    		local tmpIdx = 0
    		local lockItems = Utilitys.Split(buildInfo.building, "|")
    		for i,v in ipairs(lockItems) do
    			local tinyItems = Utilitys.Split(lockItems[i], ";")
    			local tmpType = tinyItems[1];
                local tmLv = tinyItems[2];
                if not FunBuildController:getInstance():isExistBuildByTypeLv(tonumber(tmpType), tonumber(tmLv)) then
                	if tmpIdx > 0 then
                		locakStr = locakStr..","
                	end
                	local tmpName = CCCommonUtils.getNameById(tmpType)
                	locakStr = locakStr..tmpName.." ".._lang_params("102272", tmLv)
                	tmpIdx = tmpIdx+1
                end

    		end
    		itemData["lockStr"] = locakStr
            itemData["isLock"] = isLock
    	end
    end
end

function RAConstructionBuildingPage:refreshByBuildIndex(index, isRefresh)
    local isRefresh = isRefresh or false
    if self.m_buildIds[index] ~= nil then
        local itemData = self.m_buildIds[index]
        self.m_itemId = itemData.id
        CCLuaLog("RAConstructionBuildingPage:refreshByBuildIndex  index:"..index)
        self.mBuidlingNameTex:setString(itemData["buildName"])

        local isLock = itemData["isLock"]
        self.mRequirementsTex:setVisible(isLock)
        self.mDescriptionTex:setVisible(not isLock)

        self.mRequirementsTex:setString(itemData["lockStr"])
        self.mDescriptionTex:setString(itemData["destip"])

        if isRefresh then
            self.mBuildingScroll:refreshAllCell()
        end

        local layer = SceneController:getInstance():getCurrentLayerByLevel(0);
        local layerImperial = tolua.cast(layer, "ImperialScene")
        layerImperial:doHideTmpBuild(self.m_pos);
        layerImperial:doShowTmpBuild(self.m_pos, itemData.id);
    end
end


function RAConstructionBuildingPage:onConstructionBtn()
	CCLuaLog("onConstructionBtn")
end

function RAConstructionBuildingPage:onDownBtn()
    CCLuaLog("onDownBtn")
end

function RAConstructionBuildingPage:onUpBtn()
    CCLuaLog("onUpBtn")
    RAPageManager.popPage("RAConstructionBuildingPage")
end

function RAConstructionBuildingPage:onBack()
    CCLuaLog("onBack")
    -- RAPageManager.popPage("RAConstructionBuildingPage")
end

function RAConstructionBuildingPage:OnAnimationDone(ccbfile)
	local lastAnimationName = ccbfile:getCompletedAnimationName()
	
end

local RAConstructionBuildingItem = {}
function RAConstructionBuildingItem:new(o)
    o = o or {}
    setmetatable(o,self)
    self.__index = self    
    return o
end

function RAConstructionBuildingItem:onRefreshContent(ccbRoot)
    CCLuaLog(self.data.id)
	CCLuaLog("RAConstructionBuildingItem:onRefreshContent")
    local ccbfile = ccbRoot:getCCBFileNode()    
    local index = ccbRoot:getCellTag()
    local data = RAConstructionBuildingPage.m_buildIds[index]
    if data ~= nil then
        UIExtend.setSpriteIcoToNode(ccbfile, "mBuildingIcon", data.buildIcon)
        local isLock = data["isLock"]
        UIExtend.setNodeVisible(ccbfile, "mLockNode", isLock)
        local mCellBtn = UIExtend.getCCControlButtonFromCCB(ccbfile, "mCellBtn")
        if data.id == RAConstructionBuildingPage.m_itemId then        
            mCellBtn:setHighlighted(true)
        else
            mCellBtn:setHighlighted(false)
        end
    end
end

function RAConstructionBuildingItem:onCellClick(ccbfile)	
    local index = ccbfile:getCCBTag()
	CCLuaLog("RAConstructionBuildingItem:onServerButten index:"..index) 
    RAConstructionBuildingPage:refreshByBuildIndex(index, true)
end

function createContentItem(data)
	local scrollview = RAConstructionBuildingPage.mBuildingScroll
	local allItems = data
	local totalNum = table.getn(allItems)
	local mCurCount = totalNum
	local cell = nil
	for index,itemData in pairs(allItems) do
		cell = CCBFileCell:create()
		cell:setCCBFile("ccbi/ConstructionBuildingCell.ccbi")
		local panel = RAConstructionBuildingItem:new({
            index=index,
            data=itemData
            })
		mCurCount = mCurCount - 1
		cell:setCellTag(index)
		cell:registerFunctionHandler(panel)

		scrollview:addCell(cell)
		
		local pos = nil
		pos = ccp(0, cell:getContentSize().height * mCurCount)
	--[[
		local x = mCurCount % 2
		local y = math.floor(mCurCount / 2)
		if x == 0 then
			pos = ccp(0,cell:getContentSize().height*(math.ceil(totalNum/2)-y))
		else
			pos = ccp(cell:getContentSize().width,cell:getContentSize().height*(math.ceil(totalNum/2) - y))
		end--]]
		cell:setPosition(pos)	
		
	end		
	--local size = CCSizeMake(cell:getContentSize().width,cell:getContentSize().height* math.ceil(totalNum/2))
	local size = CCSizeMake(cell:getContentSize().width,cell:getContentSize().height * totalNum)
	scrollview:setContentSize(size)
	scrollview:setContentOffset(ccp(0,scrollview:getViewSize().height - scrollview:getContentSize().height * scrollview:getScaleY()))
	scrollview:forceRecaculateChildren()		
end

function RAConstructionBuildingPage:Exit()
    if self.scrollview then
        self.scrollview:removeAllCell()
        self.scrollview = nil
    end
    self.ccbfile:unregisterScriptHandler()
	UIExtend.unLoadCCBFile(RAConstructionBuildingPage)
	--ScrollViewAnimation.clearTable()
end