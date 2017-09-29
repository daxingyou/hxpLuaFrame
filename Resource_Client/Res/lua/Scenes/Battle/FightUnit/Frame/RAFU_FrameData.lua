--region RAFU_FrameData.lua
--Date 2016/11/22
--Author: zhenhui
--此文件由[BabeLua]插件自动生成
local RAFU_SingleFrameData = {}
local common = RARequire("common")
RARequire("ActionDefine")
local RAFU_FrameData = {}
local frame_conf = RARequire("RAFU_Cfg_Bone")
local common = RARequire("common")
local EnumManager = RARequire("EnumManager")

----------------RAFU_SingleFrameData-------------------------

--create function api
--单个动作，单个方向的序列帧集合
function RAFU_SingleFrameData:create(actionId,actionPic,actionType,dir,frameInfo,frameDataOnly)

    
    local piece = RAFU_SingleFrameData:_new(actionId,actionType,dir)
    piece.frameArray = CCArray:create();   
    local frames = frameInfo.frameCount[actionType] or 0    
    for i=1,frames do
        local index = string.format("%02d",i);
        local file = actionPic.."_"..i..".png"
        --CCMessageBox(file,"hint")
        local pSpriteFrame = CCSpriteFrameCache:sharedSpriteFrameCache():spriteFrameByName(file);
        if pSpriteFrame ~= nil then
            piece.frameArray:addObject(pSpriteFrame);
            if piece.firstFrame==nil then 
                piece.firstFrame = pSpriteFrame
            end
        else
            RALogError("file "..file .."not found");    
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
    local fps = frameInfo.fps[actionType] or 8
    local pAnimation = CCAnimation:createWithSpriteFrames(piece.frameArray, 1/fps);
    piece.frameTime = 1/fps*piece.frameArray:count()
    piece.fps = fps
    piece.startFrame = 0
    if frameInfo.actionRepeat[actionType] then
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
function RAFU_SingleFrameData:_new(actionId,actionDir,actionType)
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

function RAFU_SingleFrameData:release()
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

----------------RAFU_FrameData-------------------------
--针对frameId，所有的方向所有的动作的集合,frameDataOnly 为true表示  只想要数据，不需要缓存action
function RAFU_FrameData:new(frameId,frameDataOnly)
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

function RAFU_FrameData:release()
    if self.AllActionsMap ~= nil then
        for k,v in pairs(self.AllActionsMap) do 
            v:release()
        end
    end
end


function RAFU_FrameData:createAllActionsByFrameInfo(frameInfo,frameDataOnly)
    
    --判断plist,png正确性

     if common:addSpriteFramesWithFile(frameInfo.plist,frameInfo.pic)==false then
        RALogError("RAFU_FrameData:createAllActionsByFrameInfo-- Not find the "..frameInfo.plist)
     end


    local AllActions = {}
    self.frameInfo = frameInfo
    local ActionMap = frameInfo.actionDefine

    self.ActionMap = ActionMap
    for actionType,dirObj in pairs(ActionMap) do
        for key,dir in pairs(dirObj) do
            --action id 是唯一的，作为后续的唯一标示key
            local actionId = frameInfo.name.."_"..actionType .."_"..dir
            --是否需要翻转，来去找对应的action_pic
            local picDir = dir
            if frameInfo.needDirFlip then
                picDir = DirectionFlip_DIR16[dir]
            end
            local actionPic = frameInfo.name .. "_".. actionType .."_"..picDir
            --create oneActionData by action id, pic, type and direction
            AllActions[actionId] = RAFU_SingleFrameData:create(actionId,actionPic,actionType,dir,frameInfo,frameDataOnly)
        end
    end
    return AllActions
end


function RAFU_FrameData:getFrameName()
    return self.frameName
end

function RAFU_FrameData:getFrameInfo()
    return self.frameInfo
end

--获取actionType和direction得到的唯一action,
--如果有新的FPS 或者新的初始帧，则更新piece.action，同时返回
function RAFU_FrameData:getActionByTypeAndDir(actionType,direction,newFps,startFrame)
    
    
    local actionId = actionType .. "_" .. direction
    local frameName = self.frameName
    local frameInfo = self.frameInfo
    local frameKey = ""
    if frameName ~= nil then
        frameKey = frameName .. "_" .. actionId
    end
    if self.AllActionsMap[frameKey] ~= nil then
        local piece = self.AllActionsMap[frameKey]
        --如果fps和startFrame都为空，则直接返回piece
        if newFps == nil and startFrame == nil then
            return piece
        end
        --否则，填入默认值
        if startFrame == nil then startFrame = piece.startFrame; end
        if newFps == nil then newFps = piece.fps; end

        --如果有新的FPS 或者新的初始帧，则更新piece.action，同时返回
        if newFps ~= piece.fps or startFrame ~=piece.startFrame then
            piece.action:release()
            piece.action = nil

            --如果newFps部位空，则使用最新的newFps，否则使用默认的fps
            local fps = newFps 
            local pAnimation = CCAnimation:createWithSpriteFrames(piece.frameArray, 1/fps);
            piece.frameTime = 1/fps*piece.frameArray:count()
            local animate = nil
            --如果初始的startFrame ~= nil，则使用初始的startFrame 做为CCAnimate的参数
            if startFrame ~= nil then
                animate = CCAnimate:create(pAnimation,startFrame);  
            else
                animate = CCAnimate:create(pAnimation);  
            end
            piece.startFrame = startFrame
            piece.fps = fps
            if frameInfo.actionRepeat[actionType] then
                local pRepeatForever = CCRepeatForever:create(animate)
                piece.action = pRepeatForever
            else
                piece.action = animate   
            end
            piece.action:retain()
            self.AllActionsMap[frameKey] = piece
        end

        return piece
    else
        RALogError("frameKey not found in action table,plz check, frameKey is "..frameKey)
    end
end

return RAFU_FrameData
