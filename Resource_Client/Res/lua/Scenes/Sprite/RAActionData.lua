--region RAActionData.lua
--Date
--此文件由[BabeLua]插件自动生成
local RAActionData = {}
local common = RARequire("common")
RARequire("ActionDefine")
local RAOneActionData = {}
local frame_conf = RARequire("frame_conf")
local common = RARequire("common")


----------------RAOneActionData-------------------------

--create function api
--单个动作，单个方向的序列帧集合
function RAOneActionData:create(actionId,actionPic,actionType,dir,frameInfo,frameDataOnly)

    
    local piece = RAOneActionData:_new(actionId,actionType,dir)
    piece.frameArray = CCArray:create();   
    local frames = frameInfo["actFrameNum"..actionType] or 0
    for i=1,frames do
        local index = string.format("%02d",i);
        local file = actionPic.."_"..index..".png"
        local pSpriteFrame = CCSpriteFrameCache:sharedSpriteFrameCache():spriteFrameByName(file);
        if pSpriteFrame ~= nil then
            piece.frameArray:addObject(pSpriteFrame);
            if piece.firstFrame==nil then 
                piece.firstFrame = pSpriteFrame
            end
        else
            common:log("file "..file .."not found");    
        end
    end
  
    if piece.frameArray:count()==0 then 
        return nil
    end
    piece.frameArray:retain()

    --如果只需要FrameData, 直接return
    if frameDataOnly == true then
        piece.action = nil
        return piece;
    end
    local fps = frameInfo["actFrameFPS"..actionType] or 8
    local pAnimation = CCAnimation:createWithSpriteFrames(piece.frameArray, 1/fps);
    if ActionRepeat[actionType] then
        local animate = CCAnimate:create(pAnimation);     
        local pRepeatForever = CCRepeatForever:create(animate)
        piece.action = pRepeatForever
    else
        local animate = CCAnimate:create(pAnimation);      
        piece.action = animate   
    end
    piece.action:retain()
    --piece.action:setTag()
    return piece;
end

--construction function api
function RAOneActionData:_new(actionId,actionDir,actionType)
    local o = {}
    self.__index = self
    setmetatable(o, self)
    o.actionId = actionId
    o.actionDir = actionDir
    o.actionType = actionType
    o.firstFrame = nil
    o.action = nil --CCAnimation
    o.frameArray = nil  --CCArray of frames
    return o
end

function RAOneActionData:release()
    self.actionId = nil
    self.actionDir = nil
    self.actionType = nil
    self.firstFrame = nil
    if self.action ~= nil  then
        self.action:release()
    end
    if self.frameArray ~= nil  then
        self.frameArray:release()
    end
end

----------------RAActionData-------------------------
--针对frameId，所有的方向所有的动作的集合,frameDataOnly 为true表示  只想要数据，不需要缓存action
function RAActionData:new(frameId,frameDataOnly)
    if frameDataOnly == nil then frameDataOnly = false end
    local o = {}
    self.__index = self
    setmetatable(o, self)
    o.frameId = frameId

    o.ActionMap = nil
    local frameInfo = frame_conf[frameId]
    o.frameInfo = frameInfo
    o.frameName = frameInfo.name
    o.AllActionsMap = self:createAllActionsByFrameInfo(frameInfo,frameDataOnly) --key is the actionId = frameInfo.name.."_"..k.."_"..n
    return o
end

function RAActionData:release()
    if self.AllActionsMap ~= nil then
        for k,v in pairs(self.AllActionsMap) do 
            v:release()
        end
    end
end


function RAActionData:createAllActionsByFrameInfo(frameInfo,frameDataOnly)
    
    --判断plist,png正确性
    if common:addSpriteFramesWithFile(frameInfo.plist,frameInfo.pic)==false then
        if frameInfo.replaceFrameId > 0 then
            local replaceFrameInfo2 = frameCfg[frameInfo.replaceFrameId]
            if replaceFrameInfo2 ~= nil and replaceFrameInfo2.replaceFrameId <= 0 then
                frameInfo = replaceFrameInfo2
                --CocoLog("GameUtil:addSpriteFramesWithFile -- error code 2 in replaceFrameInfo find the path for "..frameInfo.plist)
            else
                frameInfo = frameCfg[finalreplaceFrameId]
                --CocoLog("GameUtil:addSpriteFramesWithFile -- error code 3 in replaceFrameInfo find the path for "..frameInfo.plist)
            end
        else
            frameInfo = frameCfg[finalreplaceFrameId]
            common:log("GameUtil:addSpriteFramesWithFile -- error code 4 in replaceFrameInfo find the path for "..frameInfo.plist)
        end
        --加载最新frameInfo
         if common:addSpriteFramesWithFile(frameInfo.plist,frameInfo.pic) == false then
            common:log("GameUtil:addSpriteFramesWithFile -- error code 5 in final replace frame id error for "..frameInfo.plist)
         end
    end


    local AllActions = {}
    self.frameInfo = frameInfo
    local ActionMap = ActionParametersMap[0].Action
    if ActionParametersMap[frameInfo.id] ~= nil then
        ActionMap = ActionParametersMap[frameInfo.id].Action
    end
    self.ActionMap = ActionMap
    for k,v in pairs(ActionMap) do
        local actionType = k
        local frames = frameInfo["actFrameNum"..actionType] or 0
        if frames > 0 then
            for m,n in pairs(v) do
                --flip
                local dir = DirectionFlip[n]
                local actionPic = frameInfo.name.."_"..k.."_"..dir
                local actionId = frameInfo.name.."_"..k.."_"..n
                --create oneActionData by action id, pic, type and direction
                AllActions[actionId] = RAOneActionData:create(actionId,actionPic,k,n,frameInfo,frameDataOnly)
            end
        end
    end
    return AllActions
end


function RAActionData:getFrameName()
    return self.frameName
end

function RAActionData:getFrameInfo()
    return self.frameInfo
end

function RAActionData:getActionByTypeAndDir(actionType,direction)

    local actionId = actionType .. "_" .. direction
    local frameName = self.frameName
    local frameKey = ""
    if frameName ~= nil then
        frameKey = frameName .. "_" .. actionId
    end
    if self.AllActionsMap[frameKey] ~= nil then
        return self.AllActionsMap[frameKey]
    else
        common:log("frameKey not found in action table,plz check, frameKey is "..frameKey)
    end
end



return RAActionData
--endregion
