--region *.lua
--Date

local RAWorldTouchHandler = {}

local RALogicUtil = RARequire('RALogicUtil')
local abs = math.abs
local common = RARequire('common')
local RAWorldConfig = RARequire('RAWorldConfig')
local RAWorldUIManager = RARequire('RAWorldUIManager')
local RAGuideManager = RARequire('RAGuideManager')

local ScrollCfg =
{
    -- TODO
    limitSpeedX = 25.6,
    limitSpeedY = 12.8,
    deaccelerateRate = 0.94,
    deaccelerateDistance = 0.5,

    syncSpeedRate = 1 / 6000
}

if CC_TARGET_PLATFORM_LUA == CC_PLATFORM.CC_PLATFORM_IOS then
    ScrollCfg.syncSpeedRate = ScrollCfg.syncSpeedRate * 0.5
end

local ZoomCfg =
{
    minZoom = RAWorldConfig.MapScale_Min,
    maxZoom = RAWorldConfig.MapScale_Max
}

local Record = {}

function RAWorldTouchHandler:reset()
    Record =
    {
        beginPos = ccp(0, 0),
        touchPos = ccp(0, 0),
        offset = ccp(0, 0),
        touchTime = 0,
        isMoving = false,
        isScrolling = false,
        isSwallowed = false,
        
        touchPosArr = {},
        startScale = 1.0,
        zoomDistance = 0,
        isZooming = false,
        isMovingUI = false,

        -- 往服务器发move协议，同步点数据时，服务器按此速度调整同步数据量
        -- range: 0 ~ 1, 0 表示静止，全量同步；1 则是最小同步量
        syncSpeed = 0
    }
end

function RAWorldTouchHandler:SwallowTouch()
    Record.isSwallowed = true
end

function RAWorldTouchHandler.onSingleTouch(event, touch)
    if event == 'began' then
       return RAWorldTouchHandler:_onSingleTouchBegan(touch)
    elseif event == 'moved' then
       return RAWorldTouchHandler:_onSingleTouchMoved(touch)
    elseif event == 'ended' then
       return RAWorldTouchHandler:_onSingleTouchEnded(touch)
    elseif event == 'canceled' then

    end
end

function RAWorldTouchHandler.onMultiTouch(event, touches)
    if event == 'began' then
        RAWorldTouchHandler:_onMultiTouchesBegan(touches)
    elseif event == 'moved' then
        RAWorldTouchHandler:_onMultiTouchesMoved(touches)
    elseif event == 'ended' then
        RAWorldTouchHandler:_onMultiTouchesEnded(touches)
    elseif event == 'canceled' then
        RAWorldTouchHandler:_onMultiTouchesCanceled(touches)
    end
end

function RAWorldTouchHandler.onScrolling()
    if Record.isScrolling == false then
        return
    end

    if abs(Record.offset.x) > ScrollCfg.limitSpeedX then
        Record.offset.x = Record.offset.x > 0 and ScrollCfg.limitSpeedX or -ScrollCfg.limitSpeedX
    end
    if abs(Record.offset.y) > ScrollCfg.limitSpeedY then
        Record.offset.y = Record.offset.y > 0 and ScrollCfg.limitSpeedY or -ScrollCfg.limitSpeedY
    end

    local offX, offY = RACcpUnpack(Record.offset)

    Record.offset = ccpMult(Record.offset, ScrollCfg.deaccelerateRate)

    if abs(Record.offset.x) <= ScrollCfg.deaccelerateDistance 
        or abs(Record.offset.y) <= ScrollCfg.deaccelerateDistance
    then
        Record.isScrolling = false
    end

    RAWorldScene:OffsetMap(RACcp(offX, offY))
end

function RAWorldTouchHandler:_onSingleTouchBegan(touch)
    Record.isScrolling = false
    Record.isMovingUI = false

    if RAGuideManager.isInGuide() and (not RAGuideManager.canShowWorld()) then
        local RAWorldGuideManager = RARequire('RAWorldGuideManager')
        RAWorldGuideManager:OnClick()
        return
    end

    Record.isClicking = true
    Record.touchPos = RAWorldScene.RootNode:convertTouchToNodeSpace(touch)
    Record.beginPos = RAWorldScene.RootNode:convertTouchToNodeSpace(touch)
    local nodeSpacePos = self:_getTouchPos(touch)
    if RAWorldUIManager:onSingleTouchBegin(nodeSpacePos, touch) then
        Record.isMovingUI = true
    end

    Record.touchTime = GamePrecedure:getInstance():getTotalTime()

    return true
end

function RAWorldTouchHandler:_onSingleTouchMoved(touch)
    --新手期不允许拖动
    if RAGuideManager.isInGuide() then
        return
    end
    
    Record.isScrolling = false

    if Record.isZooming then
        RAWorldUIManager:RemoveHud()
        Record.isMoving = false
        return
    end

    if not Record.isClicking then return end

    local touchPos = RAWorldScene.RootNode:convertTouchToNodeSpace(touch)
    Record.offset = ccpSub(touchPos, Record.touchPos)
    local touchSpacePos = RAWorldScene.MapNode:convertTouchToNodeSpace(touch)
    if Record.isMovingUI then
        RAWorldUIManager:onSingleTouchMoved(Record.offset,touchPos,touchSpacePos)
    else
        RAWorldUIManager:StopMoving()
        -- iphone6s 敏感度太高，10以内当做点击
        local moveDis = ccpDistance(Record.touchPos, touchPos)
        local touchTime = GamePrecedure:getInstance():getTotalTime()
        if not Record.isMoving and moveDis <= 10 then
            Record.isMoving = false
        else
            local timeDiff = touchTime - Record.touchTime
            if timeDiff > 0 then
                Record.syncSpeed = common:clamp(moveDis * ScrollCfg.syncSpeedRate / timeDiff, 0, 1)
            end
            Record.isMoving = true
            RAWorldUIManager:RemoveHud()
        end
        
        Record.touchTime = touchTime
        RAWorldScene:OffsetMap(Record.offset, Record.syncSpeed)
    end

    Record.touchPos = touchPos
end

function RAWorldTouchHandler:_onSingleTouchEnded(touch)
    if Record.isZooming then return end

    if Record.isMoving == true then
        local touchTime = GamePrecedure:getInstance():getTotalTime()
        if (touchTime - Record.touchTime) >= 0.08 then
            Record.offset = ccp(0, 0)
        else
            Record.isScrolling = true
        end
        
        Record.syncSpeed = 0
        local RAWorldVar = RARequire('RAWorldVar')
        RAWorldVar:MarkStopMoving(true)
        RAWorldScene:OffsetMap(Record.offset, Record.syncSpeed)
        
        Record.isMoving = false
        return
    end

    if not Record.isClicking then return end

    if Record.isMovingUI then
        Record.isMovingUI = false
        return
    end

    if Record.isSwallowed then
        Record.isSwallowed = false
        return
    end

    local touchPos = RAWorldScene.RootNode:convertTouchToNodeSpace(touch)
    local moveDis = ccpDistance(Record.beginPos, touchPos)
    if moveDis > 10 then
        return
    end

    local pos = self:_getTouchPos(touch)
    
    RAWorldUIManager:onSingleTouchEnd(pos)

    Record.isClicking = false
end

function RAWorldTouchHandler:_onMultiTouchesBegan(touches)
    for i = 1, #touches, 3 do
        local touchInfo = { }
        local x, y = CCCamera:convertTouch(touches[i], touches[i + 1])
    	touchInfo.x = x
    	touchInfo.y = y
    	touchInfo.id = touches[i + 2]
    	table.insert(Record.touchPosArr, touchInfo)
    end
    if #Record.touchPosArr == 2 then
        local pos_1 = ccp(Record.touchPosArr[1].x, Record.touchPosArr[1].y)
        local pos_2 = ccp(Record.touchPosArr[2].x, Record.touchPosArr[2].y)
        self:_beginZoom(pos_1, pos_2)
        Record.isClicking = false
        return true
    end
end

function RAWorldTouchHandler:_onMultiTouchesMoved(touches)
    --新手期不允许拖动
    if RAGuideManager.isInGuide() then
        return
    end

    if #touches == 6 then
        Record.isZooming = true
        self:_stepZoom(ccp(touches[1], touches[2]), ccp(touches[4], touches[5]))
    end
end

function RAWorldTouchHandler:_onMultiTouchesEnded(touches)
    if #touches == 6 then
        local x_1, y_1 = CCCamera:convertTouch(touches[1], touches[2])
        local x_2, y_2 = CCCamera:convertTouch(touches[4], touches[5])
        self:_endZoom(ccp(x_1, y_1), ccp(x_2, y_2))
    end
    self:_removeTouches(touches)
    Record.isZooming = false
end

function RAWorldTouchHandler:_onMultiTouchesCanceled(touches)
    self:_removeTouches(touches)
    Record.isZooming = false
end

function RAWorldTouchHandler:_getTouchPos(touch)
    local refNode = RAWorldScene.RefNode
    if refNode == nil then
        return RAWorldScene.MapNode:convertTouchToNodeSpace(touch)
    end
    local x, y = refNode:getPosition()
    local relativePos = refNode:convertTouchToNodeSpace(touch)
    relativePos.x = relativePos.x + x
    relativePos.y = relativePos.y + y
    return relativePos
end

function RAWorldTouchHandler:_beginZoom(pos_1, pos_2)
    Record.startScale = RAWorldScene:GetScale()
    Record.zoomDistance = ccpDistance(pos_1, pos_2)
    Record.isZooming = true
    Record.isScrolling = false
    Record.isClicking = false
end

function RAWorldTouchHandler:_stepZoom(pos_1, pos_2)
    if Record.zoomDistance == 0 then return end

    Record.isScrolling = false

    local distance = ccpDistance(pos_1, pos_2)
    local scale = distance / Record.zoomDistance * Record.startScale
    scale = common:clamp(scale, ZoomCfg.minZoom, ZoomCfg.maxZoom)
    RAWorldScene:SetScale(scale)
    local RAWorldMap = RARequire('RAWorldMap')
    RAWorldMap:Relocate()
end

function RAWorldTouchHandler:_endZoom(pos_1, pos_2)

end

function RAWorldTouchHandler:_removeTouches(touches)
	for i = 1, #touches, 3 do
		for j = 1, #Record.touchPosArr do
			if Record.touchPosArr[j].id == touches[i+2] then
				table.remove(Record.touchPosArr, j)
				break
			end
		end
	end
end

return RAWorldTouchHandler

--endregion