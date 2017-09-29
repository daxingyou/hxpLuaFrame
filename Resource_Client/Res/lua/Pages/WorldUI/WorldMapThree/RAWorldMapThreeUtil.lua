-- region *.lua
-- Date
-- 此文件由[BabeLua]插件自动生成
-- by zhenhui
local RAWorldMapThreeConfig = RARequire("RAWorldMapThreeConfig")
local RAWorldMapThreeUtil = {
    -- convert logic point to server id , like (1,0) -> 1
    Point2ServerId = function(self,x, y)
        return self:Point2Index(x,y) + 1
    end,
    -- convert logic point to kingdom index, like (1,0) -> 1
    Point2Index = function(self,x, y)
        local ringIndex = math.max(math.abs(x), math.abs(y))
        local nextRingIndex = ringIndex + 1
        local ringStartIndex = math.pow(2 * ringIndex - 1, 2)
        local eachEdgeCount = 2 * ringIndex
        local finalIndex = 0
        local ringMark = ringIndex - 1
        if x == ringIndex then
            -- left edge
            local oriIndex = ringStartIndex
            local offset = y + ringMark
            if offset < 0 then offset = eachEdgeCount * 4 + offset end
            finalIndex = oriIndex + offset
        elseif y == ringIndex then
            -- up edge
            local oriIndex = ringStartIndex + eachEdgeCount
            local offset = ringMark - x
            finalIndex = oriIndex + offset
        elseif x == - ringIndex then
            -- right edge
            local oriIndex = ringStartIndex + eachEdgeCount * 2
            local offset = ringMark - y
            finalIndex = oriIndex + offset
        elseif y == - ringIndex then
            -- down edge
            local oriIndex = ringStartIndex + eachEdgeCount * 3
            local offset = x + ringMark
            finalIndex = oriIndex + offset
        end
        return finalIndex
    end,
    -- convert kingdom id to logic point, like 1 -> (1,0)
    serverId2Point = function(self,serverId)
        local index = serverId - 1
        return self:index2Point(index)
    end,
    -- convert kingdom index to logic point, like 1 -> (1,0)
    index2Point = function(self,index)
        local finalPoint = RACcp(0, 0)
        local sqrtIndex = math.sqrt(index)

        local ringIndex = math.floor((sqrtIndex + 1) / 2)
        local nextRingIndex = ringIndex + 1
        local eachEdgeCount = 2 * ringIndex
        local ringStartIndex = math.pow(2 * ringIndex - 1, 2)
        local offset = index - ringStartIndex
        local normal = math.floor(offset / eachEdgeCount)
        if normal == 0 then
            -- left edge
            local oriIndex = ringStartIndex
            local oriPos = RACcp(ringIndex, 1 - ringIndex)
            local offset = index - oriIndex
            finalPoint.x = oriPos.x
            finalPoint.y = oriPos.y + offset
        elseif normal == 1 then
            -- top
            local oriIndex = ringStartIndex + eachEdgeCount
            local oriPos = RACcp(ringIndex - 1, ringIndex)
            local offset = index - oriIndex
            finalPoint.x = oriPos.x - offset
            finalPoint.y = oriPos.y
        elseif normal == 2 then
            -- right
            local oriIndex = ringStartIndex + eachEdgeCount * 2
            local oriPos = RACcp(ringIndex * -1, ringIndex - 1)
            local offset = index - oriIndex
            finalPoint.x = oriPos.x
            finalPoint.y = oriPos.y - offset
        else
            -- down
            local oriIndex = ringStartIndex + eachEdgeCount * 3
            local oriPos = RACcp(1 - ringIndex, - ringIndex)
            local offset = index - oriIndex
            finalPoint.x = oriPos.x + offset
            finalPoint.y = oriPos.y
        end
        return finalPoint
    end,
    serverId2PixelPos = function(self,serverId,centerPos)
        local index = serverId - 1
        return self:index2PixelPos(index,centerPos)
    end,
    index2PixelPos= function(self,index,centerPos)
        local logicPoint = self:index2Point(index)
        local finalPos = RACcp(centerPos.x,centerPos.y)
        finalPos.x = finalPos.x - RAWorldMapThreeConfig.oneGapPos.x * logicPoint.x
        finalPos.y = finalPos.y + RAWorldMapThreeConfig.oneGapPos.y * logicPoint.y
        return finalPos
    end,
    --server id start with 1, meanwhile index start with 0, so need to convert 
    getServerIdsAround = function(self,serverId)
        local index = serverId -1 
        local curPos = self:index2Point(index)
        local upperPos = RACcp(curPos.x,curPos.y+1)
        local downPos = RACcp(curPos.x,curPos.y-1)
        local leftPos = RACcp(curPos.x + 1 ,curPos.y)
        local rightPos = RACcp(curPos.x - 1 ,curPos.y)
        local upServerId = self:Point2Index(upperPos.x,upperPos.y) + 1
        local downServerId = self:Point2Index(downPos.x,downPos.y) + 1
        local leftServerId = self:Point2Index(leftPos.x,leftPos.y) + 1
        local rightServerId = self:Point2Index(rightPos.x,rightPos.y) + 1
        return upServerId,downServerId,leftServerId,rightServerId
    end

    -- index2Point old version
    
    --local calcSum = function (index)
    --    if index <=0 then return 0 end
    --    if index % 2 == 1 then
    --        result = (index-1)/2* -1 + index
    --    else
    --        result = (index)/2* -1 
    --    end
    --    return result
    --end

    --    calcPoint = function(index)
    --    local finalPoint = RACcp(0,0)

    --    local sqrtIndex = math.sqrt(index)
    --    local curNum = math.floor(sqrtIndex + 0.5)
    --    local nextNum = curNum + 1
    --    local preNum = curNum - 1
    --    local minIndex = curNum *(curNum - 1)
    --    local maxIndex = curNum *(curNum + 1)
    --    local middleIndex =  math.floor(minIndex / 2 + maxIndex / 2)

    --    local x,y =0
    --    if index < middleIndex then
    --        -- if it's in the left side
    --        local offsetIndex = index-minIndex
    --        if curNum % 2 == 0 then
    --            --right move
    --            x = calcSum(preNum) - offsetIndex
    --        else
    --            --left move
    --            x = calcSum(preNum) + offsetIndex
    --        end
    --        y = calcSum(preNum)
    --    else
    --        -- if it's in the right side
    --        x = calcSum(curNum)
    --        local offsetIndex = index-middleIndex
    --        if curNum % 2 == 0 then
    --            --down move
    --            y = calcSum(preNum) - offsetIndex
    --        else
    --            --up move
    --            y = calcSum(preNum) + offsetIndex
    --        end
    --    end

    --    local reverseIndex = inverseFindIndex(x,y)

    --    print("calc point index " ..index.."  (x,y):"..x..","..y.." ---reverse index is "..reverseIndex)

    --    local calcByEdgePos = calcPointEdgeVersion(index)
    --    print("calcByEdgePos is ",calcByEdgePos.x,"--",calcByEdgePos.y)

    --    finalPoint = RACcp(x,y)
    --    return finalPoint
    -- end

}

return RAWorldMapThreeUtil
-- endregion
