--FileName :RACityMultiLayerTouch 
--Author: zhenhui 2016/5/26

local RACityMultiLayerTouch = {}
_G["RACityMultiLayerTouch"] = RACityMultiLayerTouch
local RABuildManager = RARequire("RABuildManager")
RARequire("MessageDefine")
RARequire("MessageManager")
local RAGuideManager =  RARequire('RAGuideManager')
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
				local cameraScale = RACityScene.mCamera:getScale()
                local offsetPos = ccp(( multiLayerInfo[j].x - touches[i])*cameraScale, (multiLayerInfo[j].y - touches[i+1])*cameraScale)
				RACityScene.mCamera:setOffSet(offsetPos)
                offsetPos:delete()
				multiLayerInfo[j].x = touches[i]
				multiLayerInfo[j].y = touches[i+1]
				
				local cameraOffSet = RACityScene.mCamera:getOffSet()
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
	local offset = RACityScene.mCamera:getOffSet()
	local duringTime = scrollTable.endTime - scrollTable.beginTime
	scrollTable.distance = ccpMult(originDis, SCROLL_DEACCEL_RATE)
	
	if math.abs(originDis.x) < SCROLL_DEACCEL_DIST and math.abs(originDis.y) < SCROLL_DEACCEL_DIST then
		scrollTable.state = false
		return
--	elseif offset.x > scrollTable.maxOffset.width or offset.y > scrollTable.maxOffset.height then 
--		scrollTable.state = false
--		return
--	elseif offset.x < 0 or offset.y < 0 then
--		scrollTable.state = false
--		return
	end
	
	local param = duringTime*4
    local offsetPos = ccp( 
    (scrollTable.distance.x -originDis.x )/param,
    (scrollTable.distance.y- originDis.y )/param
    )
	RACityScene.mCamera:setOffSet(offsetPos)
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
	local mapSize = RACityScene.mCamera:getSize()
	local cameraScale = RACityScene.mCamera:getScale()
	scrollTable.maxOffset = CCSizeMake(mapSize.width-cameraScale * winSize.width,mapSize.height-cameraScale * winSize.height)
	scrollTable.beginTime = GamePrecedure:getInstance():getTotalTime()
	scrollTable.startPos = ccp(multiLayerInfo[1].x , multiLayerInfo[1].y)
	scrollTable.state = false
	scrollTable.acceleSet = false
end

local function layerTouchesBegin()
	if #multiLayerInfo == 2 then
		multiLayerTable.startDis = math.abs(multiLayerInfo[1].x - multiLayerInfo[2].x) + math.abs(multiLayerInfo[1].y - multiLayerInfo[2].y)
		multiLayerTable.startScale = RACityScene.mCamera:getScale()
		local offset =	RACityScene.mCamera:getOffSet()
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
        local curScale = RACityScene.mCamera:getScale()
        local maxScale = RACityScene.mCamera:getMaxScale()
        local minScale = 1.0
        local targetZoom =0.0;
        if curScale >= maxScale * (1 - ZOOM_BOUND_LIMIT_PERCENT) then
            targetZoom = maxScale * (1 - ZOOM_BOUND_LIMIT_PERCENT);
        elseif (curScale < minScale * (1 + ZOOM_BOUND_LIMIT_PERCENT)) then
            targetZoom = minScale * (1 + ZOOM_BOUND_LIMIT_PERCENT);
        end

        if targetZoom>0.0 then
            RACityScene.mCamera:setScale(targetZoom,0.2)
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


function RACityMultiLayerTouch.setEnabled(enable,moveEnabled)
	if RACityScene.mMultiTouchLayer then
		RACityScene.mMultiTouchLayer:setTouchEnabled(enable)
	end
	CCLuaLog("-------------clean touch-----------------------")
	multiLayerInfo = {}
	
	if moveEnabled ~= nil then
		multiLayerTable.isMoveEnabled = moveEnabled
	else
		multiLayerTable.isMoveEnabled = true
	end
end

function RACityMultiLayerTouch.Scrolling()
	if scrollTable.state then
		deaccelerateScrolling()
	end
end

function RACityMultiLayerTouch.LayerTouches(pEvent, touches)
    --如果在缩放模式，不处理单击事件，直接return
    local RACityScene = RARequire('RACityScene')
    if RACityScene.isCameraMoving == true or RAGuideManager.isInGuide() == true then 
        return 
    end

    
     if RACityMultiLayerTouch.isInScaleState() then
        if RABuildManager.curBuilding~= nil and RABuildManager.curBuilding.timeNode~=nil then
            RABuildManager.curBuilding.timeNode:stopAllActions()
        end
     end
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

		--多点触控
		if #touches >3 then 
			MessageManager.sendMessage(MessageDef_Building.MSG_Cancel_Building_Select)
		end 
		CCLuaLog("RACityMultiLayerTouch.LayerTouches  pEvent, touch, begin")
    elseif pEvent == "moved" then
		if #touches == 6 and multiLayerTable.startDis then
            multiLayerTable.dragState = false
            multiLayerTable.scaleState = true
			local newDis = math.abs(touches[1] - touches[4]) + math.abs(touches[2] - touches[5])
			local scale = multiLayerTable.startScale * multiLayerTable.startDis/newDis
            local curScale = RACityScene.mCamera:getScale()
            --如果scale为1 或者scale 为最大scale，则return，不做缩放
			if scale > RACityScene.mCamera:getMinScale() and scale < RACityScene.mCamera:getMaxScale() then
				RACityScene.mCamera:setScale(scale,0)
				local originCenterX = (multiLayerTable.startTerrain.x - RACityScene.mCamera:getOffSet().x)/scale
				local originCenterY = (multiLayerTable.startTerrain.y - RACityScene.mCamera:getOffSet().y)/scale
				local offSetX = originCenterX - multiLayerTable.startCenter.x
				local offSetY = originCenterY - multiLayerTable.startCenter.y
                local offsetPos = ccp( offSetX, offSetY)
				RACityScene.mCamera:setOffSet(offsetPos)
                offsetPos:delete()
			end
			MessageManager.sendMessage(MessageDef_Building.MSG_Cancel_Building_Select)
		elseif #touches == 3 and multiLayerTable.dragState and multiLayerTable.isMoveEnabled then
            --新手引导特殊步骤屏蔽
			if RAGuideManager.isInGuide() == true then 
				return 
            end
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

function RACityMultiLayerTouch.isInDragState()
		return multiLayerTable.dragState
end

function RACityMultiLayerTouch.isInScaleState()
		return multiLayerTable.scaleState
end