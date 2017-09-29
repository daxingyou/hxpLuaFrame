--FileName :RAWorldMapThreeTouch 
--Author: zhenhui 2016/5/26

local RAWorldMapThreeTouch = {}
RARequire("MessageDefine")
RARequire("MessageManager")
local RAWorldMapThreeManager = RARequire("RAWorldMapThreeManager")
local multiLayerTable={--[[startTerrain, 两个触摸点中心在地图中位置
						   startDis,	 两个触摸点之间的距离
						   startCenter,  两个触摸点中心在屏幕中的位置
						   dragState,	 多点触控时是否允许拖动camera
						 ]]
					   }
local multiLayerInfo = {}
local scrollTable = {
					beginTime = 0,  --弹性滑动时触摸起始时间
					endTime = 0		--弹性滑动时触摸结束时间
					--[[maxOffset,  当前camera允许的最大offset
						acceleSet,	设置是否允许弹性滑动(设置 state)
						state,      弹性滑动开启与否
						startPos,	弹性滑动时起始位置
						distance,	滑动距离
						]]
					}

local ZOOM_BOUND_LIMIT_PERCENT = 0.2


local function scrollCamera(touches)
	for i=1,#touches,3 do
		for j=1,#multiLayerInfo do
			if multiLayerInfo[j].id == touches[i+2] then
				local cameraScale = RAWorldMapThreeManager.mCamera:getScale()
                local offsetPos = ccp(( multiLayerInfo[j].x - touches[i])*cameraScale, (multiLayerInfo[j].y - touches[i+1])*cameraScale)
				RAWorldMapThreeManager.mCamera:setOffSet(offsetPos)
                offsetPos:delete()
				multiLayerInfo[j].x = touches[i]
				multiLayerInfo[j].y = touches[i+1]
				
				local cameraOffSet = RAWorldMapThreeManager.mCamera:getOffSet()
				scrollTable.distance = ccp(multiLayerInfo[j].x - scrollTable.startPos.x, multiLayerInfo[j].y - scrollTable.startPos.y)
				scrollTable.acceleSet = true
                scrollTable.touchTime = GamePrecedure:getInstance():getTotalTime()
				break
			end
		end
	end
end

local function deaccelerateScrolling()
	local SCROLL_DEACCEL_RATE  = 0.85
	local SCROLL_DEACCEL_DIST  = 1.0
	local originDis = scrollTable.distance
	local offset = RAWorldMapThreeManager.mCamera:getOffSet()
	local duringTime = scrollTable.endTime - scrollTable.beginTime
	scrollTable.distance = ccpMult(originDis, SCROLL_DEACCEL_RATE)
	
	if math.abs(originDis.x) < SCROLL_DEACCEL_DIST and math.abs(originDis.y) < SCROLL_DEACCEL_DIST then
		scrollTable.state = false
		return
	elseif offset.x > scrollTable.maxOffset.width or offset.y > scrollTable.maxOffset.height then 
		scrollTable.state = false
		return
	elseif offset.x < 0 or offset.y < 0 then
		scrollTable.state = false
		return
	end
	
	local param = duringTime*4
    local offsetPos = ccp( 
    (scrollTable.distance.x -originDis.x )/param,
    (scrollTable.distance.y- originDis.y )/param
    )
	RAWorldMapThreeManager.mCamera:setOffSet(offsetPos)
    offsetPos:delete()
end

local function removeTouches(touches)
	for i=1,#touches,3 do
		for j=1,#multiLayerInfo do
			if multiLayerInfo[j].id == touches[i+2] then
				CCLuaLog("-------------remove touch-----------------------")
				table.remove(multiLayerInfo,j)
				break
			end
		end
	end
end

local function scrollToucheBegin(multiLayerInfo)
	if #multiLayerInfo ~= 1 then
		return
	end
	
	local winSize = CCDirector:sharedDirector():getWinSize()
	local mapSize = RAWorldMapThreeManager.mCamera:getSize()
	local cameraScale = RAWorldMapThreeManager.mCamera:getScale()
	scrollTable.maxOffset = CCSizeMake(mapSize.width-cameraScale * winSize.width,mapSize.height-cameraScale * winSize.height)
	scrollTable.beginTime = GamePrecedure:getInstance():getTotalTime()
	scrollTable.startPos = ccp(multiLayerInfo[1].x , multiLayerInfo[1].y)
	scrollTable.state = false
	scrollTable.acceleSet = false
end

local function layerTouchesBegin()
	if #multiLayerInfo == 2 then
		multiLayerTable.startDis = math.abs(multiLayerInfo[1].x - multiLayerInfo[2].x) + math.abs(multiLayerInfo[1].y - multiLayerInfo[2].y)
		multiLayerTable.startScale = RAWorldMapThreeManager.mCamera:getScale()
		local offset =	RAWorldMapThreeManager.mCamera:getOffSet()
		multiLayerTable.startCenter = ccp(
        (multiLayerInfo[1].x + multiLayerInfo[2].x)/2,
        (multiLayerInfo[1].y + multiLayerInfo[2].y)/2)	
		multiLayerTable.startTerrain = ccp(
        offset.x + multiLayerTable.startCenter.x * multiLayerTable.startScale,
        offset.y + multiLayerTable.startCenter.y * multiLayerTable.startScale)
		multiLayerTable.dragState = false
		multiLayerTable.scaleState = true
	elseif #multiLayerInfo == 1 then
		multiLayerTable.dragState = true
		multiLayerTable.scaleState = false
	else
		multiLayerTable.dragState = false
		multiLayerTable.scaleState = false
	end
	scrollToucheBegin(multiLayerInfo)
end


local function layerTouchesEndZoom(touches)
    --after zoom check the zoom max scale and min scale
    if #touches == 6 then
        local curScale = RAWorldMapThreeManager.mCamera:getScale()
        local maxScale = RAWorldMapThreeManager.mCamera:getMaxScale()
        local minScale = 1.0
        local targetZoom =0.0;
        if curScale >= maxScale * (1 - ZOOM_BOUND_LIMIT_PERCENT) then
            targetZoom = maxScale * (1 - ZOOM_BOUND_LIMIT_PERCENT);
        elseif (curScale < minScale * (1 + ZOOM_BOUND_LIMIT_PERCENT)) then
            targetZoom = minScale * (1 + ZOOM_BOUND_LIMIT_PERCENT);
        end

        if targetZoom>0.0 then
            RAWorldMapThreeManager.mCamera:setScale(targetZoom,0.2)
        end

    end
end

local function layerTouchesFinish(touches)
	multiLayerTable.startDis = nil
	multiLayerTable.startScale = nil
	scrollTable.endTime = GamePrecedure:getInstance():getTotalTime()		
	
	if scrollTable.acceleSet then
		scrollTable.state = true
	end
    if scrollTable.touchTime ~= nil then
        if scrollTable.endTime - scrollTable.touchTime >= 0.08 then
		    scrollTable.state = false
        end
    end
    
    --mimic the zoom max and in's fling
    --layerTouchesEndZoom(touches)
	removeTouches(touches)
    
end


function RAWorldMapThreeTouch.setEnabled(enable,moveEnabled)
	if RAWorldMapThreeManager.mMultiTouchLayer then
		RAWorldMapThreeManager.mMultiTouchLayer:setTouchEnabled(enable)
	end
	CCLuaLog("-------------clean touch-----------------------")
	multiLayerInfo = {}
	
	if moveEnabled ~= nil then
		multiLayerTable.isMoveEnabled = moveEnabled
	else
		multiLayerTable.isMoveEnabled = true
	end
end

function RAWorldMapThreeTouch.Scrolling()
	if scrollTable.state then
		deaccelerateScrolling()
	end
end

function RAWorldMapThreeTouch.LayerTouches(pEvent, touches)
	if pEvent == "began" then
		for i=1,#touches,3 do
            local touchInfo= {} 
			touchInfo.x = touches[i]
			touchInfo.y = touches[i+1]
			touchInfo.id = touches[i+2]			
			table.insert(multiLayerInfo,touchInfo)
			CCLuaLog("-------------insert touch-----------------------no."..i.."x:"..touchInfo.x.."y:"..touchInfo.y)
		end
		layerTouchesBegin()

    elseif pEvent == "moved" then
		if #touches == 6 and multiLayerTable.startDis then
            multiLayerTable.dragState = false
            multiLayerTable.scaleState = true
			local newDis = math.abs(touches[1] - touches[4]) + math.abs(touches[2] - touches[5])
			local scale = multiLayerTable.startScale * multiLayerTable.startDis/newDis
            local curScale = RAWorldMapThreeManager.mCamera:getScale()
            --如果scale为1 或者scale 为最大scale，则return，不做缩放
			if scale > RAWorldMapThreeManager.mCamera:getMinScale() and scale < RAWorldMapThreeManager.mCamera:getMaxScale() then
				RAWorldMapThreeManager.mCamera:setScale(scale,0)
				local originCenterX = (multiLayerTable.startTerrain.x - RAWorldMapThreeManager.mCamera:getOffSet().x)/scale
				local originCenterY = (multiLayerTable.startTerrain.y - RAWorldMapThreeManager.mCamera:getOffSet().y)/scale
				local offSetX = originCenterX - multiLayerTable.startCenter.x
				local offSetY = originCenterY - multiLayerTable.startCenter.y
                local offsetPos = ccp( offSetX, offSetY)
				RAWorldMapThreeManager.mCamera:setOffSet(offsetPos)
                offsetPos:delete()
			end
			-- MessageManager.sendMessage(MessageDef_Building.MSG_Cancel_Building_Select)
		elseif #touches == 3 and multiLayerTable.dragState and multiLayerTable.isMoveEnabled then
            multiLayerTable.dragState = true
            multiLayerTable.scaleState = false
			scrollCamera(touches)
		end
		
    elseif pEvent == "ended" then
		layerTouchesFinish(touches)
    elseif pEvent == "cancelled" then
		layerTouchesFinish(touches)
    end
end

function RAWorldMapThreeTouch.isInDragState()
		return multiLayerTable.dragState
end

function RAWorldMapThreeTouch.isInScaleState()
		return multiLayerTable.scaleState
end

return RAWorldMapThreeTouch