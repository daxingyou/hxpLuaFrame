

local UIExtend = {}

local RAGameConfig=RARequire("RAGameConfig")
local tostring = tostring
local pairs = pairs

--将一个页面从一个节点挪去另个节点
function UIExtend.SwitchPageToNode(handler,fromNode,destNode,zorder)
    local ccbfile = handler:getRootNode()
    if ccbfile ~= nil then
        ccbfile:retain()
        ccbfile:removeFromParentAndCleanup(false)
        destNode:addChild(ccbfile)
        if zorder ~= nil then
            ccbfile:setZOrder(zorder)
        end
        ccbfile:release()
    end
end


function UIExtend.AddPageToNode(handler,node,needNotToucherLayer, isBlankClose,layerSwallowTouch,zorder)
	local ccbfile = handler:getRootNode()
    node:addChild(ccbfile)
    if zorder ~= nil then
        ccbfile:setZOrder(zorder)
    end
    if layerSwallowTouch == nil then layerSwallowTouch = true end
    if needNotToucherLayer then
        handler:AddNoTouchLayer(isBlankClose,layerSwallowTouch)
    end
end

function UIExtend.GetPageHandler(pageName, callEnter, arg)
	local page = RARequire(pageName)
	page.pageName = pageName
	if callEnter then
		page:Enter(arg)
	end
	return page
end

function UIExtend.loadCCBFileWithOutPool(filename,ownner)
    local ccbfile = CCBFile:create()
    ccbfile:retain()
    ccbfile:setCCBFileName(filename)
    ccbfile:setInPool(false)
    ccbfile:registerFunctionHandler(ownner)
    ccbfile:load()
    ownner.ccbfile = ccbfile
    return ccbfile
end

-- colorParam = {key = '', color = {r = 0, g = 0, b = 0}}，用于ccb变色
function UIExtend.loadCCBFile(filename, ownner, colorParam)
	local ccbfile = nil
	if colorParam == nil then
    	ccbfile = CCBFile:CreateInPool(filename)
    else
    	local colorKey = colorParam.key or 'DefaultColorKeyCCB'
    	local r = colorParam.color.r or 255
    	local g = colorParam.color.g or 255
    	local b = colorParam.color.b or 255
    	CCTextureCache:sharedTextureCache():addColorMaskKey(colorKey, r, g , b)
    	ccbfile = CCBFile:CreateInPool(filename)
    	ccbfile:setUseColorMask(colorKey)
    end
    ccbfile:retain()
    ccbfile:registerFunctionHandler(ownner)
    if ccbfile:getIsFirstCreate() then
    	ccbfile:setVisible(false)
    	UIExtend.handleCCBNode(ccbfile, true)
    	ccbfile:setVisible(true)
    end    
    ownner.ccbfile = ccbfile
    return ccbfile
end

function UIExtend.unLoadCCBFile(ownner)
	if ownner and ownner.ccbfile then
		ownner.ccbfile:unregisterFunctionHandler()
		ownner.ccbfile:removeFromParentAndCleanup(true)
		ownner.ccbfile:release()
		ownner.ccbfile = nil
	end
end

function UIExtend.releaseCCBFile(ccbfile)
	if ccbfile then
		ccbfile:removeFromParentAndCleanup(true)
		ccbfile:release()
	end
end

function UIExtend.addNodeToParentNode(ccbfile, parentName, node)
    if ccbfile then
        local parentNode = ccbfile:getCCNodeFromCCB(parentName)
        if parentNode then
            parentNode:addChild(node)
        end
    end
end

function UIExtend.addNodeToAdaptParentNode(node,picName,tag )
	if not node or not picName then return end 
	local pic=node:getChildByTag(tag)
	if pic then
		pic:setTexture(picName)
	else
		pic = CCSprite:create(picName)
		node:addChild(pic)
		pic:setTag(tag)
		pic:setPosition(ccp(node:getContentSize().width*0.5,node:getContentSize().height*0.5))
	end 
	
	local picNodeW = node:getContentSize().width
	local picNodeH = node:getContentSize().height
	local picW = pic:getContentSize().width
	local picH = pic:getContentSize().height
	local picNodeMin = math.min(picNodeW,picNodeH)
	local picMax = math.max(picW,picH)
	if picW>picNodeMin or picH>picNodeMin then
		pic:setScale(picNodeMin/picMax)
		return pic
	end
	return pic
end

function UIExtend.getCCNodeFromCCB(ccbfile,nodeName)
	return ccbfile:getCCNodeFromCCB(nodeName)
end

function UIExtend.getCCSpriteFromCCB(ccbfile,nodeName)
	return ccbfile:getCCSpriteFromCCB(nodeName)
end
function UIExtend.getCCScale9SpriteFromCCB(ccbfile,nodeName)
	return ccbfile:getCCScale9SpriteFromCCB(nodeName)
end
function UIExtend.getCCLabelBMFontFromCCB(ccbfile,nodeName)
	return ccbfile:getCCLabelBMFontFromCCB(nodeName)
end	

function UIExtend.getCCLabelHTMLFromCCB(ccbfile,nodeName)
	return ccbfile:getCCLabelHTMLFromCCB(nodeName)
end

function UIExtend.getCCLabelTTFFromCCB(ccbfile,nodeName)
	return ccbfile:getCCLabelTTFFromCCB(nodeName)
end

function UIExtend.getCCLayerFromCCB(ccbfile, nodeName)
	return ccbfile:getCCLayerFromCCB(nodeName)
end

--desc:获得CCLayerColor
function UIExtend.getCCLayerColorFromCCB(ccbfile, nodeName)
    return ccbfile:getCCLayerColorFromCCB(nodeName)
end

function UIExtend.setAnchorPoint(node,x,y)
	return tolua.cast(node,"CCNode"):setAnchorPoint(x,y)
end

function UIExtend.getCCControlButtonFromCCB(ccbfile,nodeName)
	return ccbfile:getCCControlButtonFromCCB(nodeName)
end

function UIExtend.setCCControlButtonEnable(ccbfile,nodeName,enable)
	local btn = UIExtend.getCCControlButtonFromCCB(ccbfile,nodeName)
	btn:setEnabled(enable)
	if not enable then

		--没图的时候才设置
		local tpBg = btn:getBackgroundSpriteForState(CCControlStateDisabled)
		if tpBg then
			return
		end 
		local grayBg = CCScale9Sprite:create(RAGameConfig.ButtonBg.GARY)
		btn:setBackgroundSpriteForState(grayBg,CCControlStateDisabled)
	end 
end

function UIExtend.setCCControlButtonSelected(ccbfile,nodeName,selected)
	local btn = UIExtend.getCCControlButtonFromCCB(ccbfile,nodeName)
	btn:setHighlighted(selected)
end

function UIExtend.getCCBFileFromCCB(ccbfile,nodeName)
	return ccbfile:getCCBFileFromCCB(nodeName)
end

function UIExtend.getCCMenuItemImageFromCCB(ccbfile,nodeName)
	return ccbfile:getCCMenuItemImageFromCCB(nodeName)
end

function UIExtend.getCCScrollViewFromCCB(ccbfile,nodeName)
	return ccbfile:getCCScrollViewFromCCB(nodeName)
end

function UIExtend.getCCMenuItemCCBFileFromCCB(ccbfile,nodeName)
	return ccbfile:getCCMenuItemCCBFileFromCCB(nodeName)
end

function UIExtend.getCCClippingNodeFromCCB(ccbfile,nodeName)
	return ccbfile:getCCClippingNodeFromCCB(nodeName)
end

function UIExtend.getCCShaderNodeFromCCB(ccbfile, nodeName)
	local node = UIExtend.getCCNodeFromCCB(ccbfile, nodeName)
	if node then
		return tolua.cast(node, 'CCShaderNode')
	end
	return nil
end

function UIExtend.setCCLabelString(ccbfile,nodeName,str,width)
	str = str or ''
	if width then 
		str = GameMaths:stringAutoReturnForLua(str,width,0)
	end
	UIExtend.getCCLabelTTFFromCCB(ccbfile,nodeName):setString(str)
end

function UIExtend.setCCLabelBMFontString(ccbfile,nodeName,str,width)
	str = str or ''
	if width then 
		str = GameMaths:stringAutoReturnForLua(str,width,0)
	end
	UIExtend.getCCLabelBMFontFromCCB(ccbfile,nodeName):setString(str)
end

function UIExtend.setCCLabelHTMLStringDirect(ccbfile,nodeName,str)
	UIExtend.getCCLabelHTMLFromCCB(ccbfile,nodeName):setString(str)
end
function UIExtend.setCCLabelHTMLString(ccbfile,nodeName,str,width,align)
	if width then
		local alignstr = ""
		if align then 
			alignstr =  "align=" .. "\"" .. align .. "\""
		end
		str = "<table cellspacing=\"5\"><tr><td spacing=\"5\" width=\"" .. tostring(width) .. "\" " .. alignstr .. " style=\"word-break-all|normal|keep-all\">" .. str .. "</td></tr></table>" 
	end
	UIExtend.getCCLabelHTMLFromCCB(ccbfile,nodeName):setString(str)
end

function UIExtend.setChatLabelHTMLString(ccbfile,nodeName,str,width,color,aline)
	-- body
	local alignstr = "align=\"left\""
	if align then 
		alignstr =  "align=" .. "\"" .. align .. "\""
	end
    color = color or "#000000"
    local str = "<table cellspacing=\"2\"><tr><td spacing=\"2\" width=\"" .. tostring(width) .. "\""..alignstr.." style=\"word-break-all|normal|keep-all\"><font face = \"Helvetica20\" size =\"50\" color=\""..color.."\">" .. str .. "</font></td></tr></table>" 
    UIExtend.getCCLabelHTMLFromCCB(ccbfile,nodeName):setString(str)
end


function UIExtend.setNodeVisible(ccbfile,nodeName,visible)
	if ccbfile == nil then
		return
	end
	local node = UIExtend.getCCNodeFromCCB(ccbfile,nodeName)
	if node ~= nil then
		visible = visible or false -- avoid of : visible is nil
		node:setVisible(visible)
	end
end

function UIExtend.setNodeRotation(ccbfile, nodeName, rotation)
	if ccbfile == nil then
		return
	end
	local node = UIExtend.getCCNodeFromCCB(ccbfile, nodeName)
	if node ~= nil then
		node:setRotation(rotation)
	end
end

--批量设置ControlBtn是否高亮
--设置ControlBtn文本
function UIExtend.setControlButtonTitle(ccbfile, name, title, isDirect,fontColor)
	local isDirect = isDirect or false
	local text = tostring(title)
	if not isDirect then
		RARequire('RAStringUtil')
		text = _RALang(title)
	end
	local btn = UIExtend.getCCControlButtonFromCCB(ccbfile, name)
	if btn then
		btn:setTitleForState(CCString:create(text), CCControlStateNormal)
		btn:setTitleForState(CCString:create(text), CCControlStateHighlighted)
		btn:setTitleForState(CCString:create(text), CCControlStateDisabled)

		if fontColor then
			btn:setTitleColorForState(fontColor,CCControlStateNormal)
			btn:setTitleColorForState(fontColor,CCControlStateHighlighted)
			btn:setTitleColorForState(fontColor,CCControlStateDisabled)
		end
	end	
end

function UIExtend.updateControlButtonTitle(container, btnName )
	-- body
	local pNode = container:getCCControlButtonFromCCB(btnName)
	local cbtn = tolua.cast(pNode, "CCControlButton")
	if cbtn ~= nil then
		local normalStr = cbtn:getTitleForState(CCControlStateNormal):getCString()
		local normalRealStr = _RALang(normalStr)
		if normalRealStr ~= "" then
			cbtn:setTitleForState(CCString:create(normalRealStr), CCControlStateNormal)
		end

		local highStr = cbtn:getTitleForState(CCControlStateHighlighted):getCString()
		local highStrRealStr = _RALang(highStr)
		if highStrRealStr ~= "" then
			cbtn:setTitleForState(CCString:create(highStrRealStr), CCControlStateHighlighted)
		end

		local disableStr = cbtn:getTitleForState(CCControlStateDisabled):getCString()
		local disableStrRealStr = _RALang(disableStr)
		if disableStrRealStr ~= "" then
			cbtn:setTitleForState(CCString:create(disableStrRealStr), CCControlStateDisabled)
		end
	end
end

function UIExtend.setTitle4ControlButtons(ccbfile, titleMap)
	for name, title in pairs(titleMap or {}) do
		UIExtend.setControlButtonTitle(ccbfile, name, title)
	end
end

function UIExtend.setEnabled4ControlButtons(ccbfile, enabledMap)
	for name, enabled in pairs(enabledMap or {}) do
		UIExtend.setCCControlButtonEnable(ccbfile, name, enabled)
	end
end

--批量设置ControlBtn是否高亮
function UIExtend.setControlButtonSelected( container, selectedMap )
	for btnName, selected in pairs(selectedMap) do
		local item = container:getCCControlButtonFromCCB(btnName);

		if item == nil then
			CCLuaLog("Error in UIExtend:setControlButtonSelected==> node is nil");
		else
			if selected then
                item:setHighlighted(true)
                item:setSelected(true)
			else
				item:setHighlighted(false)
				item:setSelected(false)
			end
		end
	end
end

--批量设置MenuItem是否选中
function UIExtend.setMenuItemSelected( container, selectedMap )
	for menuItemName, selected in pairs(selectedMap) do
		local item = container:getCCMenuItemImageFromCCB(menuItemName);

		if item == nil then
			CCLuaLog("Error in UIExtend:setMenuItemSelected==> node is nil");
		else
			if selected then
				item:selected();
			else
				item:unselected();
			end
		end
	end
end

--批量设置NodesVisible
function UIExtend.setNodesVisible(ccbfile, visibleMap)
	for name, visible in pairs(visibleMap) do
        UIExtend.setNodeVisible(ccbfile,name,visible)
	end
end

function UIExtend.runCCBAni(ccbfile, ccbName, aniName)
	if ccbfile == nil or ccbName == nil or aniName == nil then return end

	local ccbNode = UIExtend.getCCBFileFromCCB(ccbfile, ccbName)
	if ccbNode then
		ccbNode:runAnimation(aniName)
	end	
end


--批量设置label 文字
function UIExtend.setStringForLabel(ccbfile, strMap)
	for name, str in pairs(strMap) do
		local label = ccbfile:getCCLabelTTFFromCCB(name)
		if label then
			label:setString(tostring(str))
		else
			label = ccbfile:getCCLabelBMFontFromCCB(name)
			if label then
				label:setString(tostring(str))
			else
				CCLuaLog("Error:::UIExtend:setStringForLabel====>" .. name)		
			end
			
		end
	end
end

--批量设置label 文字
function UIExtend.setFontSizeForLabel(ccbfile, sizeMap)
	for name, size in pairs(sizeMap) do
		local label = ccbfile:getCCLabelTTFFromCCB(name)
		if label then
			label:setFontSize(size)
		else
			label = ccbfile:getCCLabelBMFontFromCCB(name)
			if label then
				label:setFontSize(size)
			else
				CCLuaLog("Error:::UIExtend:setFontSizeForLabel====>" .. name)		
			end
			
		end
	end
end


--批量设置label 颜色
function UIExtend.setColorForLabel(ccbfile, strMap)
	for name, str in pairs(strMap) do
		local label = ccbfile:getCCLabelTTFFromCCB(name)
		if label then
			label:setColor(str)
		else
			label = ccbfile:getCCLabelBMFontFromCCB(name)
			if label then
				label:setColor(str)
			else
				CCLuaLog("Error:::UIExtend:setColorForLabel====>" .. name)		
			end
			
		end
	end
end

--批量设置sprite 颜色
function UIExtend.setColorForCCSprite(ccbfile, colorMap)
	for name, color in pairs(colorMap) do
		local sprite = ccbfile:getCCSpriteFromCCB(name)
		if sprite then
			sprite:setColor(color)
			color:delete()
		else
			CCLuaLog("Error:::UIExtend:setColorForCCSprite====>" .. name)		
		end
	end
end

function UIExtend.setNodeZorder(ccbfile, node, zorder)
	local node = UIExtend.getCCNodeFromCCB(ccbfile, node)
	if node then
		node:setZOrder(zorder)
	end
end

-- 设置节点（主要是文本）水平排序
function UIExtend.setHorizonAlignOneByOne(ccbfile, name1, name2, gap)
	local gap = gap or 0
	local node1 = UIExtend.getCCNodeFromCCB(ccbfile, name1)
	local node2 = UIExtend.getCCNodeFromCCB(ccbfile, name2)
	if node1 ~= nil and node2 ~= nil then
		local anchor1 = node1:getAnchorPoint().x
		local anchor2 = node2:getAnchorPoint().x
		local node1ScaleSize = node1:getContentSize().width * node1:getScaleX()
		local anchorGap1 = node1ScaleSize * anchor1
		local anchorGap2 = (node2:getContentSize().width * node2:getScaleX()) * anchor2
		node2:setPositionX(node1:getPositionX() + node1ScaleSize - anchorGap1 + anchorGap2 + gap)
	end
end


--在node父对象上添加图片，以node为大小和定位标准
function UIExtend.addSpriteToNodeParent(ccbfile, nodeName, picName, scaleType, color, addPicTag)
	
	if nil == addPicTag then
		addPicTag = 19999
	end
	local node = UIExtend.getCCNodeFromCCB(ccbfile, nodeName)
    assert(node ~= nil,"node ~= nil ")
	if node ~= nil then
		-- 0适配最小；1适配宽；-1适配�?
		local scaleType = scaleType or 0
        local picSpr = node:getParent():getChildByTag(addPicTag)
        if picSpr == nil then
            picSpr = CCSprite:create(picName)	            
			node:getParent():addChild(picSpr)
        else
            picSpr:setTexture(picName)	
        end
        local nodeSize = node:getContentSize()
		local picSize = picSpr:getContentSize()
		local widthScale = nodeSize.width / picSize.width
		local heightScale = nodeSize.height / picSize.height
		local lastScale = 1
		if scaleType == 0 then
			lastScale = math.min(widthScale, heightScale)
		elseif scaleType == 1 then
			lastScale = widthScale
		elseif scaleType == -1 then
			lastScale = heightScale
		end	
        if picSpr and color then
            picSpr:setColor(color)
        end	
		picSpr:setScale(lastScale)
		picSpr:setAnchorPoint(node:getAnchorPoint())
		picSpr:setPosition(node:getPosition())
		picSpr:setTag(addPicTag)
        return picSpr
	end	
end

function UIExtend.removeSpriteFromNodeParent(ccbfile, nodeName, addPicTag)
	if nil == addPicTag then
		addPicTag = 19999
	end
	local node = UIExtend.getCCNodeFromCCB(ccbfile, nodeName)
    assert(node ~= nil,"node ~= nil ")
	if node ~= nil and node:getParent() ~= nil then
		node:getParent():removeChildByTag(addPicTag, true)
    end
end

-- 设置九宫格缩�?
-- max size name:Percent�?00%时的同大小的node名字
-- scale type: -- 0 xy缩放�? x缩放(默认)�?1 y缩放
function UIExtend.setCCScale9ScaleByPercent(ccbfile, nodeName, maxSizeName, percent, scaleType)
	if scaleType == nil then
		scaleType = 1
	end
	local target = UIExtend.getCCScale9SpriteFromCCB(ccbfile, nodeName)
	local maxSizeNode = UIExtend.getCCNodeFromCCB(ccbfile, maxSizeName)
	if target ~= nil and maxSizeNode ~= nil then
		local prefreSize = target:getPreferredSize()
		-- local capInsets = target:getCapInsets()
		-- local newWidth = prefreSize.width
		-- local newHeight = prefreSize.height
		local maxSize = maxSizeNode:getContentSize()
		local newWidth = maxSize.width
		local newHeight = maxSize.height
		if scaleType == 1 then
			newWidth = newWidth * percent	
		elseif scaleType == -1 then
			newHeight = newHeight * percent
		elseif scaleType == 0 then
			newHeight = newHeight * percent
			newWidth = newWidth * percent
		end
		-- 小于最小大小的时候，设置scale就可以了
		if newWidth < prefreSize.width or newHeight < prefreSize.height then
			target:setContentSize(maxSize.width, maxSize.height)
			if scaleType == 1 then
				target:setScaleX(percent)
			elseif scaleType == -1 then
				newHeight = newHeight * percent
				target:setScaleY(percent)
			elseif scaleType == 0 then
				target:setScaleX(percent)
				target:setScaleY(percent)
			end
		else		
			target:setScale(1)
			target:setContentSize(newWidth, newHeight)
		end
	end
	
end

function UIExtend.removeHtmlLabelListener(ccbfile, name)
	if ccbfile == nil then return end
	local htmlLabel = UIExtend.getCCLabelHTMLFromCCB(ccbfile, name)
    if htmlLabel then
        htmlLabel:removeLuaClickListener()
    end	
end


--批量设置sprite image
function UIExtend.setSpriteImage(container, imgMap, scaleMap)
	local scaleMap = scaleMap or {};
	for spriteName, image in pairs(imgMap) do
		local sprite = container:getCCSpriteFromCCB(spriteName);
		if sprite then
			sprite:setTexture(tostring(image));
			if scaleMap[spriteName] then
				sprite:setScale(scaleMap[spriteName]);
			end
		else
			CCLuaLog("Error:::UIExtend:setSpriteImage====>" .. spriteName);
		end
	end
end

--设置九宫格scale
function UIExtend.setCCScale9SpriteScale(ccbfile, scale9Name, scale, xOrY, xy)
    local scale9Sprite = ccbfile:getCCScale9SpriteFromCCB(scale9Name)
    if scale9Sprite == nil then
        scale9Sprite = ccbfile:getCCSpriteFromCCB(scale9Name)
    end

    if scale9Sprite then
        if xy then
            scale9Sprite:setScale(scale)
            return
        end
        if xOrY then
            scale9Sprite:setScaleX(scale)
        else
            scale9Sprite:setScaleY(scale)
        end
    end
end


function UIExtend.setLabelBMFontColor(ccbfile,nodeName,color)
	UIExtend.getCCLabelBMFontFromCCB(ccbfile,nodeName):setColor(color)
end

function UIExtend.setLabelTTFColor(ccbfile,nodeName,color)
	UIExtend.getCCLabelTTFFromCCB(ccbfile,nodeName):setColor(color)
end

function UIExtend.setSpriteIcoToNode(ccbfile,nodeName,icoPath)
	tolua.cast(ccbfile:getVariable(nodeName),"CCSprite"):setTexture(icoPath)
end

function UIExtend.setMenuItemEnable(ccbfile,nodeName,enable)
	local menu = UIExtend.getCCMenuItemImageFromCCB(ccbfile,nodeName)
	menu:setEnabled(enable)
end

function UIExtend.setMenuItemVisible(ccbfile,nodeName,visible)
	local menu = UIExtend.getCCMenuItemImageFromCCB(ccbfile,nodeName)
	menu:setVisible(visible)
end

function UIExtend.setMenuItemTexture(ccbfile, nodeName, image, width, height)
	local item = UIExtend.getCCMenuItemImageFromCCB(ccbfile, nodeName)
	if item and image then
		local rect = CCRectMake(0, 0, width, height)
		local spriteFrame = CCSpriteFrame:create(image, rect)
		rect:delete()
		if spriteFrame then
			item:setNormalSpriteFrame(spriteFrame)
		end
	end
end


function UIExtend.showNeedTechMessageBox(techItemId,str,jumpPage)
	jumpPage = jumpPage or false
	local dataTable = TableReader.getDataTable("TechTreeTable")
	if dataTable[techItemId] then
		if not str then
			str = string.format(TableReader.getStringFromLanguageByKey("#TechLimit"),dataTable[techItemId].name)
		end
		ShowMessageBoxUI(str,
			function(confirm) 
				if confirm then
					ClientCache.setValue("TechPage",techItemId)
					--GameMainState.CloseAllPage()
					GameMainState.JumpPage("TechPage",{})
				end
			end,
		PriorityQuene.priorityLevel.YES_NO,jumpPage)
	end
end

function UIExtend.setItem(iconCCB,itemType,itemId,canTouch)
    require('UILogic.ItemLogic')
	canTouch = canTouch or false
	itemType = tonumber(itemType)
	local itemData = ItemLogic.getClientDataByType(itemType,itemId)	
	if itemData and itemData.getShowInfo then 
		UIExtend.setItemIcon(iconCCB,itemData:getShowInfo(),canTouch)
	end
	--[[		
	if itemType == 20104 then	--UpGradeMaterial
		UIExtend.setItemIcon(iconCCB,{iconPath = itemData:getIcon(),diwen = itemData.diwen,
				pinzhikuang = itemData.pinzhikuang,wenzi = itemData.wenzi},canTouch)
	elseif itemType == 20105 then--skillbook
		UIExtend.setItemIcon(iconCCB,{iconPath = itemData:getIcon(),jiaobiao = itemData.jiaobiao,
				pinzhikuang = itemData.pinzhikuang},canTouch)
	elseif itemType == 20103 then--equip
		UIExtend.setItemIcon(iconCCB,{iconPath = itemData:getIcon(),diwen = itemData.diwen,
				pinzhikuang = itemData.pinzhikuang,wenzi = itemData.wenzi},canTouch)
	else
	if itemType == 20201 or itemType == 20202 or itemType == 20203
	 or itemType == 20204 or itemType == 20205 or itemType == 20206 then --AccelaratedProps
		UIExtend.setItemIcon(iconCCB,{iconPath = itemData:getIcon()},canTouch)
	elseif itemType == 20301 or itemType == 20302 or itemType == 20303 then
		-- 20400 items GoodTable
		UIExtend.setItemIcon(iconCCB,{iconPath = itemData:getIcon(),pinzhikuang = itemData.pinzhikuang,
					diwen = itemData.diwen},canTouch)
	end
	--]]
end

function UIExtend.setItemIcon(iconCCB,showInfo,canTouch)
	--[[
	iconPath,diwen,pinzhikuang,wenzi,jiaobiao,
	--]]
	canTouch = canTouch or false
	local ccbfile = iconCCB:getCCBFile()
	if not showInfo.diwen or showInfo.diwen == "" or showInfo.diwen == "-1" then	--底纹
		UIExtend.setSpriteIcoToNode(ccbfile,"mICOBace","ICO/91000.png")
	else
		--UIExtend.setNodeVisible(ccbfile,"mICOBace",true)		
		UIExtend.setSpriteIcoToNode(ccbfile,"mICOBace",showInfo.diwen)
	end
	if not showInfo.pinzhikuang or showInfo.pinzhikuang == "" or showInfo.pinzhikuang == "-1" then	--品质�?
		UIExtend.setSpriteIcoToNode(ccbfile,"mICOFrame","ICO/90021.png")
	else						
		UIExtend.setSpriteIcoToNode(ccbfile,"mICOFrame",showInfo.pinzhikuang)
	end
	if not showInfo.jiaobiao or showInfo.jiaobiao == "" or showInfo.jiaobiao == "-1" then	--角标
		UIExtend.setNodeVisible(ccbfile,"mICOCorner",false)
		UIExtend.setNodeVisible(ccbfile,"mICOCornerTex",false)
	else
		UIExtend.setNodeVisible(ccbfile,"mICOCorner",true)
		UIExtend.setNodeVisible(ccbfile,"mICOCornerTex",true)
		UIExtend.setCCLabelBMFontString(ccbfile,"mICOCornerTex",showInfo.jiaobiao)
	end
	if not showInfo.wenzi or showInfo.wenzi == "" or showInfo.wenzi == "-1" then	--文字
		UIExtend.setNodeVisible(ccbfile,"mICOTex",false)
		UIExtend.setNodeVisible(ccbfile,"mICOFrame2",false)			
	else
		UIExtend.setNodeVisible(ccbfile,"mICOTex",true)
		UIExtend.setNodeVisible(ccbfile,"mICOFrame2",true)
		UIExtend.setCCLabelString(ccbfile,"mICOTex",showInfo.wenzi)
	end
	if showInfo.iconPath and showInfo.iconPath ~= "-1" then
		UIExtend.setSpriteIcoToNode(ccbfile,"mICO",showInfo.iconPath)
	end
	
	if canTouch then
		iconCCB:setEnabled(true)
	else
		iconCCB:setEnabled(false)
	end
end

function UIExtend.createLabel(str,color,font,size)
	local tColor = color or ccc3(255,255,255)
	local tFont = font or RAGameConfig.DefaultFontName
	local tSize = size or 20
	local label = CCLabelTTF:create(tostring(str),tFont,tSize)
	return label
end


function UIExtend.createEditBoxEx(paramObj)
	if paramObj == nil then 
		return 
	end

	return UIExtend.createEditBox(paramObj.ccbfile,paramObj.nodeName,paramObj.parentNode,paramObj.editCall,paramObj.lableStartPos,paramObj.length,paramObj.mode,paramObj.fontSize,paramObj.fontName,paramObj.fontColor,paramObj.lableAlignment,paramObj.contentSize,paramObj.anchorPoint,paramObj.position,paramObj.closeKeyboardType) 
end

function UIExtend.createEditBox(ccbfile,nodeName,parentNode,editCall,lableStartPos,length,mode,fontSize,fontName,fontColor,lableAlignment,contentSize,anchorPoint,position,closeKeyboardType)
	local picScale9Sprite = UIExtend.getCCScale9SpriteFromCCB(ccbfile,nodeName)
    assert(picScale9Sprite~= nil ,"picScale9Sprite~=nil")
    assert(ccbfile~= nil ,"ccbfile~=nil")
    assert(parentNode~= nil ,"parentNode~=nil")
    local editBoxTag = 30001

    local editbox = parentNode:getChildByTag(editBoxTag)

    local size = nil 
    if contentSize == nil then 
    	size = picScale9Sprite:getContentSize()
    else
    	size = contentSize
    end 

    if editbox == nil then
	    picScale9Sprite:removeFromParentAndCleanup(true)
	    if CC_TARGET_PLATFORM_LUA == CC_PLATFORM.CC_PLATFORM_IOS or CC_TARGET_PLATFORM_LUA == CC_PLATFORM.CC_PLATFORM_ANDROID then

	    	if closeKeyboardType ~= nil then 
	    		editbox = CCNewEditBox:create(size, picScale9Sprite,nil,nil,true,closeKeyboardType)
	    	else
	        	editbox = CCNewEditBox:create(size, picScale9Sprite)
	        end
	    else
	    	editbox = CCEditBox:create(size, picScale9Sprite)
	    end
	    -- editbox = CCEditBox:create(size, picScale9Sprite)
        parentNode:addChild(editbox)
    else
        editbox = tolua.cast(editbox,"CCEditBox")
    end
    editbox:setIsAutoFitHeight(false)

	fontSize = fontSize or 20
	fontName = fontName or RAGameConfig.DefaultFontName
	lableStartPos =lableStartPos or ccp(5,5)
	local editBoxInputMode =mode or kEditBoxInputModeAny
    local maxLength = length or 200
    lableAlignment = lableAlignment or 0
	editbox:setIsDimensions(true)
	editbox:setFontName(fontName)
	editbox:setFontSize(fontSize)
    editbox:setAlignment(lableAlignment)
    position = position or ccp(0,size.height)
	editbox:setPosition(position)
	editbox:setLableStarPosition(lableStartPos)
    anchorPoint = anchorPoint or ccp(0,1)
	editbox:setAnchorPoint(anchorPoint)
    editbox:setFontColor(fontColor or RAGameConfig.COLOR.BLACK)
    editbox:setMaxLength(maxLength)
	editbox:setInputMode(editBoxInputMode)
    editbox:setReturnType(kKeyboardReturnTypeDefault)
	if editCall and type(editCall)=="function" then
		editbox:registerScriptEditBoxHandler(editCall)
	end

	return editbox
	
end

--创建适合输入数字的editBox(坐标，购买数量。。。)
--mSliderNum:ttf的label名称
--mSliderNumBG:背景图scale9sprite
--mSliderNumNode：最外边的node
function UIExtend.createInputEditBox(editBox, ccbfile, mSliderNum, mSliderNumBG, mSliderNumNode, editboxEventHandler)
	-- body
	if editBox ~= nil then
		--todo
		return editBox
	end

	local sprite = UIExtend.getCCScale9SpriteFromCCB(ccbfile, mSliderNumBG)
    local size = sprite:getContentSize()
    local posx, posy = sprite:getPositionX(), sprite:getPositionY()
    sprite:removeFromParentAndCleanup(true)
    local editBox = CCEditBox:create(size, sprite)
    editBox:setPosition(CCPointMake(posx, posy))
    editBox:setAnchorPoint(CCPointMake(0.5, 0.5))
    editBox:setFontColor(ccc3(255,255,255))

    UIExtend.addNodeToParentNode(ccbfile, mSliderNumNode, editBox)
    editBox:setReturnType(kKeyboardReturnTypeDone)
    editBox:setInputMode(kEditBoxInputModeNumeric)
    editBox:setMaxLength(2)
    editBox:registerScriptEditBoxHandler(editboxEventHandler)

    UIExtend.setNodeVisible(ccbfile, mSliderNum, false)

    return editBox
end

function UIExtend.getRewardItemInfo(rewardMsg)
    require('UILogic.ItemLogic')
	local addItemCount = 0		
	local showInfo = {}	
	local addItemName = nil
	if rewardMsg:HasField("addBags") then
		local bags = rewardMsg.addBags.bagItems
		local bag = bags[1]
		local itemData = ItemLogic.getClientDataByType(bag.type,bag.itemId)	
		if itemData and itemData.getShowInfo then 		
			addItemCount = bag.addCount
			showInfo = itemData--:getShowInfo()			
		end
	elseif rewardMsg:HasField("equips") then	
		local equips = rewardMsg.equips.equipItems
		local equip = equips[1]
		local info = TableReader.getDataTable("EquipsTable")[equip.itemId]		
		addItemCount = 1	
		showInfo = info--:getShowInfo()
	end			
	return addItemCount,showInfo
end



function UIExtend.parseItems(items)
	if items == "-1" or items == "" then
		return {},0
	end
	local itemsTable = {}
	local itemsStr = Utilitys.Split(items,",")
	for k,v in ipairs(itemsStr) do
		local tmp = Utilitys.Split(v,":")
		
		local itemTable = {}
		itemTable.itemType = tonumber(tmp[1])
		itemTable.id = tonumber(tmp[2])
		itemTable.count = tonumber(tmp[3])
		itemsTable[#itemsTable + 1] = itemTable
	end
	return itemsTable,#itemsTable
end	


function UIExtend.getGameDesignSize()
	return GameDesignSize
end


function UIExtend.calcAdditionalHeight()
	local sizeCur = UIExtend.getDesignResolutionSize()
	local offset = sizeCur.height - GameDesignSize.height
	return offset
end


function UIExtend.calcAdditionalWidth()
	local sizeCur = UIExtend.getDesignResolutionSize()
	local offset = sizeCur.width - GameDesignSize.width
	return offset
end

function UIExtend.getDesignResolutionSize()
	local sizeCur = CCEGLView:sharedOpenGLView():getDesignResolutionSize()
	local sizeRet = {
		width = sizeCur.width,
		height = sizeCur.height
	}
	return sizeRet
end


function UIExtend.adjustNode(pTarget)
	if pTarget == nil then
		return
	end	
	local node = tolua.cast(pTarget, "CCNode")
	if node == nil then
		return
	end
	local offset = UIExtend.calcAdditionalHeight()
	local oldSize = node:getContentSize()
	oldSize.height = oldSize.height + offset;
	node:setContentSize(oldSize);
end

function UIExtend.adjustScale9Sprite(pTarget)
	if pTarget == nil then
		return
	end	
	local scale9Sprite = tolua.cast(pTarget, "CCScale9Sprite")
	if scale9Sprite == nil then
		return
	end
	local offset = UIExtend.calcAdditionalHeight()
	local oldSize = scale9Sprite:getContentSize()
	oldSize.height = oldSize.height + offset;
	scale9Sprite:setContentSize(oldSize);
end


function UIExtend.adjustScrollView(pTarget)
	if pTarget == nil then
		return
	end
	local scrollView = tolua.cast(pTarget, "CCScrollView")
	if scrollView == nil then
		return
	end
	local offset = UIExtend.calcAdditionalHeight()
	local oldSize = scrollView:getViewSize()
	oldSize.height = oldSize.height + offset;
	scrollView:setViewSize(oldSize)
end



function UIExtend.handleCCBNode(pNode, isFirst)
	local isFirst = isFirst or false
    local RAStringUtil = RARequire("RAStringUtil")
	if pNode == nil then
		return
	end
	local classObj = tolua.cast(pNode:getClass(), "CCClass")
	local className
	if classObj ~= nil then
		className = classObj:getName()
	end
	if className ~= nil then
		-- node
		if className == "CCNode" then
			local node = tolua.cast(pNode, "CCNode")
			if node ~= nil and node:getTag() == CCBNodeNeedAdjustTag then
				UIExtend.adjustNode(node)
			end
		end

		-- scroll view 
		if className == "CCScrollView" then
			local scrollView = tolua.cast(pNode, "CCScrollView")
			if scrollView ~= nil  and scrollView:getTag() == CCBNodeNeedAdjustTag then
				UIExtend.adjustScrollView(pNode)
			end
		end

		-- scale9sprite 
		if className == "CCScale9Sprite" then
			local scale9sprite = tolua.cast(pNode, "CCScale9Sprite")
			if scale9sprite ~= nil  and scale9sprite:getTag() == CCBNodeNeedAdjustTag then
				UIExtend.adjustScale9Sprite(pNode)
			end
		end

        -- sprite texture repeated bg 
		if className == "CCSprite" then
			local sprite = tolua.cast(pNode, "CCSprite")
			if sprite ~= nil  and 
                sprite:getTag() == CCBNodeNeedAdjustTag and 
                sprite:getTextureRepeatEnable() then
				local offset = UIExtend.calcAdditionalHeight()
	            local oldSize = sprite:getPreferedSize()
	            oldSize.height = oldSize.height + offset;
	            sprite:setPreferedSize(oldSize);
			end
		end

		-- ttf CCLabelTTF
		if className == "CCLabelTTF" then
			local ttf = tolua.cast(pNode, "CCLabelTTF")
			if ttf ~= nil then
				local curStr = ttf:getString()
				local realStr = _RALang(curStr)
				if realStr ~= "" then
					-- 非字典文本设置为空
					if realStr == curStr and isFirst then
						ttf:setString('')
					else
						ttf:setString(realStr)
					end
				end
			end
		end

		-- bmfont CCLabelBMFont
		if className == "CCLabelBMFont" then
			local bmfont = tolua.cast(pNode, "CCLabelBMFont")
			if bmfont ~= nil then
				local curStr = bmfont:getString()
				local realStr = _RALang(curStr)
				if realStr ~= "" then
					bmfont:setString(realStr)
				end
			end
		end

		local root = tolua.cast(pNode, "CCNode")
		local children = root:getChildren()
		if children ~= nil then
			for i=1, children:count() do
				local child = children:objectAtIndex(i - 1)
				
				local childClassObj = tolua.cast(child:getClass(), "CCClass")
				local childClassName
				if childClassObj ~= nil then
					childClassName = childClassObj:getName()
				end
				-- control button
				if childClassName == "CCControlButton" or childClassName == "CCControl" then
					local cbtn = tolua.cast(child, childClassName)
					if cbtn ~= nil then
						local normalStr = cbtn:getTitleForState(CCControlStateNormal):getCString()
						local normalRealStr = _RALang(normalStr)
						cbtn:setTitleForState(CCString:create(normalRealStr), CCControlStateNormal)

						local highStr = cbtn:getTitleForState(CCControlStateHighlighted):getCString()
						if highStr == '' then highStr = normalStr end
						local highStrRealStr = _RALang(highStr)
						cbtn:setTitleForState(CCString:create(highStrRealStr), CCControlStateHighlighted)
						
						local disableStr = cbtn:getTitleForState(CCControlStateDisabled):getCString()
						if disableStr == '' then disableStr = normalStr end
						local disableStrRealStr = _RALang(disableStr)
						cbtn:setTitleForState(CCString:create(disableStrRealStr), CCControlStateDisabled)					
					end
				else					
					UIExtend.handleCCBNode(child, isFirst)
				end
			end
		end
	end
	
end


function UIExtend.isTouchInside(layer,pTouch)
    local point = pTouch:getLocation();
    point = layer:getParent():convertToNodeSpace(point)
    local m_obPosition = ccp(layer:getPositionX(), layer:getPositionY())
    local m_obAnchorPoint = layer:getAnchorPoint()
    local m_obContentSize = layer:getContentSize()
    local rect = CCRectMake(m_obPosition.x - m_obContentSize.width * m_obAnchorPoint.x,
    m_obPosition.y - m_obContentSize.height * m_obAnchorPoint.y,
    m_obContentSize.width, m_obContentSize.height);
    return rect:containsPoint(point) 
end


local mBeginPos = nil

function UIExtend.createClickNLongClick(sprite,shortClick,longClick,handler,outsideCallBack)
    
    local callback = function ()
        handler.isLongClick = true
        longClick(handler)
    end

    local touchBegin = function (eventName,pTouch)
    	local layer = sprite:getParent():getChildByTag(51001);
    	local inside = UIExtend.isTouchInside(layer,pTouch)

    	local outCallback = function ()
	        if not inside then
                outsideCallBack(handler)
	        end
	    end	

	    if outsideCallBack ~= nil then
    		performWithDelay(sprite,outCallback,0.2)
    	end

        handler.isLongClick = false
        handler.hasMove = false
       
        if inside and handler.containsPoint then
        	inside = handler.containsPoint(pTouch:getLocation())
        end
        local point = pTouch:getLocation()
        mBeginPos = point
        if inside then
            handler.BeginTime = os.time()
            local dealay = handler.delay or 0.5
            performWithDelay(sprite,callback,dealay)
			return 1        
        end

        if outsideCallBack ~= nil then
        	return 1
    	else
    		return 0
    	end
    end
    local touchMove = function (eventName,pTouch)
        local layer = sprite:getParent():getChildByTag(51001);
--        local inside = UIExtend.isTouchInside(layer,pTouch)
--        if inside == false then

--        end
        --handler.hasMove = true

        local point = pTouch:getLocation()
        local moveDis = ccpDistance(mBeginPos, point)
        if handler.isLongClick and moveDis > 20 then  --手抖的话不做处理
        	handler.isLongClick = false
            handler.hasMove = true
	        handler.BeginTime =nil
	        sprite:stopAllActions()            
	            --滑动立即关闭
            if handler.endedColse then
                shortClick(handler)

                if outsideCallBack ~= nil then
	                outsideCallBack(handler)
	            end
            end
        end
    end
    local touchCancel = function (eventName,pTouch)
        handler.BeginTime =nil
        sprite:stopAllActions()
        handler.isLongClick = false
    end
    local touchEnd = function (eventName,pTouch)
        local layer = sprite:getParent():getChildByTag(51001);
        --local inside = UIExtend.isTouchInside(layer,pTouch)
        --if inside then
            handler.EndTime = os.time()
            sprite:stopAllActions()
            --handler.endedColse 松开立即关闭
            if handler.endedColse or (handler.isLongClick == false and handler.hasMove == false) then
                shortClick(handler)
            end
            
--            if handler.BeginTime == nil then return end
--            if handler.EndTime - handler.BeginTime>0.9 then
--                longClick(handler)
--            else
--                shortClick(handler)
--            end
        -- else
        --     if outsideCallBack ~= nil then
        --         outsideCallBack(handler)
        --     end
            
        --  end
        local inside = UIExtend.isTouchInside(layer,pTouch)
        if not inside then
        	if outsideCallBack ~= nil then
                outsideCallBack(handler)
            end
        end
    end

    return UIExtend.createTouchLayerByCCNode(sprite,touchBegin,touchMove,touchEnd,touchCancel)
end

function UIExtend.createTouchLayerByCCNode(sprite,onTouchBegin,onTouchMove,onTouchEnd,onTouchCancel)
    if sprite == nil then return end

    local layer = sprite:getParent():getChildByTag(51001);
	if not layer then
		layer = CCLayer:create();
		layer:setTag(51001);
		sprite:getParent():addChild(layer);
		layer:setContentSize(CCSize(sprite:getContentSize().width,sprite:getContentSize().height));
		layer:setPosition(sprite:getPosition())
        layer:setAnchorPoint(sprite:getAnchorPoint())
		layer:registerScriptTouchHandler(function(eventName,pTouch)
            if eventName == "began" then
                if onTouchBegin then
                    return onTouchBegin(eventName,pTouch)
                end
            elseif eventName == "moved" then
                if onTouchMove then
                    return onTouchMove(eventName,pTouch)
                end
            elseif eventName == "ended" then
                if onTouchEnd then
                    return onTouchEnd(eventName,pTouch)
                end
            elseif eventName == "cancelled" then
                if onTouchCancel then
                    return onTouchCancel(eventName,pTouch)
                end
            end
        end
        ,false,0,false);
		layer:setTouchEnabled(true);
		layer:setVisible(true);
    else
        layer:registerScriptTouchHandler(function(eventName,pTouch)
            if eventName == "began" then
                if onTouchBegin then
                    return onTouchBegin(eventName,pTouch)
                end
            elseif eventName == "moved" then
                if onTouchMove then
                    return onTouchMove(eventName,pTouch)
                end
            elseif eventName == "ended" then
                if onTouchEnd then
                    return onTouchEnd(eventName,pTouch)
                end
            elseif eventName == "cancelled" then
                if onTouchCancel then
                    return onTouchCancel(eventName,pTouch)
                end
            end
        end
        ,false,0,false);
	end
    return layer
end


function UIExtend.getControlSlider(pNodeName, ccbfile, isSetPos, barType , bgPath, thumPath)
	-- body
	local proPath
	if barType == nil or barType == 1 then
		proPath  = "Resource/UI/CommonUI/Common_u_Bar_Green.png"
	elseif barType == 2 then
		proPath  = "Resource/UI/CommonUI/Common_u_Bar_Blue.png"
	elseif barType == 3 then
		proPath  = "Resource/UI/CommonUI/Common_u_Bar_Red.png"
	elseif barType == 4 then		
		proPath  = "TestProUI_u_Slider_Bar.png"
	end

	bgPath  =  bgPath or "Resource/UI/CommonUI/Common_u_Bar_BG.png"
	thumPath = thumPath or "Resource/UI/CommonUI/Common_u_Slider_Menu.png"
	local pNode = ccbfile:getCCNodeFromCCB(pNodeName)
	local size = pNode:getContentSize()
	if size.width == 0 then
		size.width = 240
	end
	if size.height == 0 then
		size.height = 20
	end
	local controlSlider = CCControlSlider:create(bgPath, proPath, thumPath, size)

	pNode:removeAllChildrenWithCleanup(true)
	pNode:addChild(controlSlider)

	if isSetPos then		
		controlSlider:setPosition(size.width / 2, size.height / 2)
	end
	return controlSlider
end

function UIExtend.getControlSliderNew(pNodeName, ccbfile, isSetPos, barType)
	-- body
	local proPath  = "Resource/UI/CommonUI/Common_u_Bar_Green.png"
	local bgPath   = "Resource/NewUI/NewCommonUI/NewCommon_u_Slider_BG_01.png"
	local thumPath = "Resource/NewUI/NewCommonUI/NewCommon_u_Slider_Menu.png"
	local pNode = ccbfile:getCCNodeFromCCB(pNodeName)
	local size = pNode:getContentSize()
	if size.width == 0 then
		size.width = 240
	end
	if size.height == 0 then
		size.height = 20
	end
	local controlSlider = CCControlSlider:create(bgPath, proPath, thumPath, size)

	pNode:removeAllChildrenWithCleanup(true)
	pNode:addChild(controlSlider)

	if isSetPos then		
		controlSlider:setPosition(size.width / 2, size.height / 2)
	end
	return controlSlider
end

function UIExtend.getControlSliderSpriteNew(pNodeName, ccbfile, isSetPos, barType)
	-- body
	local proPath  = "Resource/UI/CommonUI/NewCommon_u_Slider_Bar_01.png"
	local bgPath   = "Resource/NewUI/NewCommonUI/NewCommon_u_Slider_BG_01.png"
	local thumPath = "Resource/NewUI/NewCommonUI/NewCommon_u_Slider_Menu.png"
	local pNode = ccbfile:getCCNodeFromCCB(pNodeName)
	local size = pNode:getContentSize()
	if size.width == 0 then
		size.width = 240
	end
	if size.height == 0 then
		size.height = 20
	end
	local controlSlider = CCControlSlider:createUseProgressSprite(bgPath, proPath, thumPath, size)

	pNode:removeAllChildrenWithCleanup(true)
	pNode:addChild(controlSlider)

	if isSetPos then		
		controlSlider:setPosition(size.width / 2, size.height / 2)
	end
	return controlSlider
end



--公共界面的文字的移动动作
function UIExtend.createLabelAction(ccbfile,nodeName,speed,delayT)
	local label= UIExtend.getCCLabelTTFFromCCB(ccbfile,nodeName)

	local ttW = label:boundingBox().size.width
    local ttW1= label:getContentSize().width*label:getScaleX()

    local starPW = label:getPositionX()
    local starPY = label:getPositionY()

   
    local totalDis = 128
  	local ddd = ttW1+totalDis
    speed = speed or 15
    delayT = delayT or 1
    if ttW>totalDis then
    	local array1 = CCArray:create()
    	local delay = CCDelayTime:create(delayT)
    	local targetNode = label
    	local firstMove  =CCMoveBy:create(ttW1/speed,ccp(-ttW1,0))
    	local funcAction = CCCallFunc:create(function ()
    		targetNode:setPosition(ccp(-starPW,starPY))
    	end)
    	array1:addObject(delay)
    	array1:addObject(firstMove)

    	local callFunc =  CCCallFunc:create(function ()
    		    local array2 = CCArray:create()
    		  	local twoMove =CCMoveBy:create(ddd/speed,ccp(-ddd,0))
    		  	local funcAction = CCCallFunc:create(function ()
    					targetNode:setPosition(ccp(-starPW,starPY))
    			end)
		    	array2:addObject(funcAction)
		    	array2:addObject(twoMove)
		    	local seq2 = CCSequence:create(array2)
		    	local reqF = CCRepeatForever:create(seq2)
	    		targetNode:stopAllActions()
	    		targetNode:runAction(reqF)
	    end)
    	array1:addObject(callFunc)
    	local seq1 = CCSequence:create(array1)
    	label:runAction(seq1)
    end 

end

function UIExtend.scrollViewContainPoint( scrollView, worldPoint )	
    if worldPoint and scrollView then
        local viewSize = scrollView:getViewSize()
        local localPos = scrollView:convertToNodeSpace(worldPoint)
        if viewSize then
            return localPos.x >=0 and localPos.y >=0 and localPos.x <= viewSize.width and localPos.y <= viewSize.height
        end
    end
    return false
end

--让精灵置灰 默认不使用shader
function UIExtend.setCCSpriteGray(pic,isUse)
	isUse=isUse or false
	GraySpriteMgr:setShader(pic,"gray.vsh","gray.fsh",isUse)
end

--htmlLabel里嵌入了CCB 使用该方法统一注册
--idTb={"ID1","ID2"}
function UIExtend.addRegisterHtmlCCB(handle,ccbFile,varName,idTb)
	local htmlLabel = UIExtend.getCCLabelHTMLFromCCB(ccbFile,varName)
	for k,v in ipairs(idTb) do
		local id = tostring(v)
		local htmlContainCCB = htmlLabel:getCCBElement(id)
		htmlContainCCB:setCCBVaribleName(id)
		htmlContainCCB:setParentCCBFileNode(ccbFile)
		htmlContainCCB:registerFunctionHandler(handle)
	end
end

function UIExtend.setBlendFunc(node, src, dst)
	if node and node.setBlendFunc and src and dst then
		local blendFunc = ccBlendFunc:new_local()
		blendFunc.src = src
		blendFunc.dst = dst
		node:setBlendFunc(blendFunc)
		blendFunc:delete()
	end
end

--[[

函数：用贝塞尔曲线模拟加速过程，越靠近控制点速度越快
参数：
	startP,endP为起始点，终点
	index；表示固定的几条曲线 为nil时完全由起始点和终点决定
	isRandom：表示曲线完全由起始点终点决定
	
]]
function UIExtend.createBezierAction(startP,endP,callback,index,isRandom)

	
    local disX=endP.x-startP.x
    local disY=endP.y-startP.y

    local offestX=CCDirector:sharedDirector():getOpenGLView():getVisibleSize().width-startP.x

    local cfg = ccBezierConfig:new()
    cfg.endPosition = ccp(disX,disY)
    cfg.controlPoint_2=ccp(disX,disY)

    --避免起始点和终点同一水平位置附近
    if disX<=50 and disX>=-50 then
    	disX=100
    end 

    if isRandom then
    	cfg.controlPoint_1=ccp(disX/5,-disY/5)
    elseif index==1 then
    	if disX<0 then
    		disX=-disX
    	end 
    	cfg.controlPoint_1=ccp(-disX*2,-disY/2)
    elseif index==2 then
    	if disX<0 then
    		disX=-disX
    	end 
    	cfg.controlPoint_1=ccp(disX*2,-disY/2)
    elseif index==3 then
    	if disX<0 then
    		disX=-disX
    	end 
    	cfg.controlPoint_1=ccp(disX*2,-disY*0.8)
    end 
   
   

    local array = CCArray:create()

    local bezierBy = CCEaseSineInOut:create(CCBezierBy:create(0.8,cfg))
    local funcAction = CCCallFunc:create(function ()
		if callback and type(callback)=="function" then
			callback()
		end 
	end)
	array:addObject(bezierBy)
	array:addObject(funcAction)
	local seq = CCSequence:create(array)
    return seq
end

function UIExtend.runActionWithCallback(node, action, callback)
	node:runAction(CCSequence:createWithTwoActions(action, CCCallFunc:create(callback)))
end

function UIExtend.runForever(node, ...)
	local args = {...}
	if node == nil or #args < 1 then return end

	local arr = CCArray:create()
	for _, act in ipairs(args) do
		arr:addObject(act)
	end
    local action = CCRepeatForever:create(CCSequence:create(arr))
    node:runAction(action)
end

function UIExtend.getNodeSpacePositionAR(srcNode, dstNode)
	local pos = ccp(srcNode:getPosition())
	local worldPos = srcNode:getParent():convertToWorldSpaceAR(pos)
	local localPos = dstNode:convertToNodeSpaceAR(worldPos)

	pos:delete()
	worldPos:delete()
	
	return localPos
end

return UIExtend