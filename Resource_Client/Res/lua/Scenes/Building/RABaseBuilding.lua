RARequire('RABuildingUtility')
RARequire('RABuildingType')
RARequire('RABuildData')
RARequire("MessageDefine")

local Const_pb = RARequire('Const_pb')
local const_conf = RARequire("const_conf")
local RATimeBarHUD = RARequire('RATimeBarHUD')
local RATopBtn = RARequire('RATopBtn')
local RAStringUtil = RARequire('RAStringUtil')
local RARootManager = RARequire('RARootManager')
local UIExtend = RARequire('UIExtend')
local common = RARequire("common")
local RAWorldConfig = RARequire('RAWorldConfig')
local Utilitys = RARequire('Utilitys')

local RABuildingLevel = {}
--构造函数
function RABuildingLevel:new()
    local o = {}
    setmetatable(o,self)
    self.__index = self
    return o
end

function RABuildingLevel:init()
    UIExtend.loadCCBFile("RAHUDLevelNode.ccbi",self)
    self.mLevelBG = self.ccbfile:getCCSpriteFromCCB('mLevelBG')
    self.mHUDLevel = self.ccbfile:getCCLabelTTFFromCCB('mHUDLevel')
end


function RABuildingLevel:setOpacity(value)
    -- body
    self.mLevelBG:setOpacity(value)
    self.mHUDLevel:setOpacity(value)
end


function RABuildingLevel:setString(str)
    self.mHUDLevel:setString(str)
end

function RABuildingLevel:release()
    UIExtend.unLoadCCBFile(self)
end

local RABuildingUpgrade = {}

--升级特效
function RABuildingUpgrade:new()
    local o = {}
    setmetatable(o,self)
    self.__index = self
    return o
end

function RABuildingUpgrade:init(handler)
    self.handler = handler
    UIExtend.loadCCBFile("Ani_City_Upgrade.ccbi",self)
end

function RABuildingUpgrade:OnAnimationDone()
    if self.handler then 
        self.handler:onUpgradeAnimationDone()
    end 
end

function RABuildingUpgrade:release()
    UIExtend.unLoadCCBFile(self)
end

--血条
local RABuildingBloodBar = {}

--升级特效
function RABuildingBloodBar:new()
    local o = {}
    setmetatable(o,self)
    self.__index = self
    return o
end

function RABuildingBloodBar:init()
    UIExtend.loadCCBFile("Ani_City_Icon_Blood_S.ccbi",self)
    -- local redBar = UIExtend.getCCScale9SpriteFromCCB(self.ccbfile,"mRedBar")
    -- local blueBar = UIExtend.getCCScale9SpriteFromCCB(self.ccbfile,"mBlueBar")
    self:setBarValue(1,1)
end


function RABuildingBloodBar:setBarValue(value,totalValue)
    local greenBar = UIExtend.getCCScale9SpriteFromCCB(self.ccbfile,"mGreenBar")
    Utilitys.barActionPlay(greenBar,{value = value,baseValue = totalValue,valueScale = value/totalValue})
end

function RABuildingBloodBar:release()
    UIExtend.unLoadCCBFile(self)
end



--基础建筑类
RABaseBuilding = {}

--构造函数
function RABaseBuilding:new(_BuildName,o)
    o = o or {}
    o.spineNode = nil --建筑的spine节点
    o.normalColor = nil
    o.timeNode = nil 
    o.timeBar = nil 

    o.isInFreeTime = false
    o.isHideHelpBtn = false

    o.ccbfile = nil
    o.buildName = _BuildName or nil --建筑标示

    o.queueData = nil --队列
    o.freeTimeBtn = nil --免费时间按钮
    o.helpBtn = nil --帮助按钮
    o.levelNode = nil --有些建筑是没有等级的
    o.hpNode = nil 
    o.curState = nil 

    o.freeTimeToDied = false

    o.buildData = RABuildData:new() --建筑的数据
    setmetatable(o,self)
    self.__index = self

    if o.buildName ~= nil then 
        package.loaded[o.buildName] = o
    end 
    return o
end

function RABaseBuilding:timeHandler(time)

    --不可见就直接不处理了
    if self.spineNode:isVisible() == false then 
        return 
    end 
    
    local RAAllianceManager = RARequire('RAAllianceManager')
    --只有建筑队列需要判断
    if self.queueData.queueType==Const_pb.BUILDING_QUEUE then 
        local isNeedUpdate = false

        local RAPlayerInfoManager = RARequire('RAPlayerInfoManager')
        -- local RAAllianceManager = RARequire('RAAllianceManager')
        -- RAAllianceManager
        local UIExtend = RARequire('UIExtend')
        local freeTime = RAPlayerInfoManager.getQueueFreeTime(nil, self.queueData.queueType)
    
        if time <= freeTime then   

            if self.freeTimeBtn == nil then 
                self:initFreeTimeBtn()
                common:playEffect("prompt1")
            end 
            self:setFreeTimeVisible(true) 
            self:hideHelpBtn()
            self:hideTopBtn()

            self.freeTimeToDied = true
        else 
            if self.freeTimeBtn ~= nil then 
                self:setFreeTimeVisible(false)   
            end 

            if RAAllianceManager.selfAlliance == nil then 
                self:hideHelpBtn()
            else 

                if self.queueData.helpTimes > 0 then 
                    self.isHideHelpBtn = false
                end 

                if self.helpBtn == nil then 
                    if self.queueData.helpTimes == 0 and self.isHideHelpBtn == false then 
                        self:initHelpBtn()
                    end 
                else 
                    if self.queueData.helpTimes > 0 then 
                        self:hideHelpBtn()
                    end 
                end
            end 

            if self.freeTimeToDied then
                self.freeTimeToDied = false
                self:updateTopStatus()
            end
        end  
    elseif self.queueData.queueType==Const_pb.BUILDING_DEFENER then 
        if RAAllianceManager.selfAlliance == nil then 
            self:hideHelpBtn()
        else 
            if self.helpBtn == nil then 
                if self.queueData.helpTimes == 0 then 
                    self:initHelpBtn()
                end 
            else 
                if self.queueData.helpTimes > 0 then 
                    self:hideHelpBtn()
                end 
            end
        end    
    end  
end

function RABaseBuilding:getDirectionPos(direction)
    local x,y = self:getPosition()
    local length = self.buildData.confData.length
    local width = self.buildData.confData.width
    
    local directionPos = {x=x,y=y}
    
    if direction == 'LD' then 
        directionPos.x = x - length/4.0*128
        directionPos.y = y + length/4.0*64
    elseif direction == 'LT' then 
        directionPos.x = x - length/2.0*128 + width/4.0*128
        directionPos.y = y + length/2.0*64 + width/4.0*64
    elseif direction == 'RD' then 
        directionPos.x = x + width/4.0*128
        directionPos.y = y + width/4.0*64 
    elseif direction == 'RT' then 
        directionPos.x = x + width/2.0*128 - length/4.0*128
        directionPos.y = y + width/2.0*64 + length/4.0*64
    end 

    return directionPos 
end

function RABaseBuilding:onUpgradeAnimationDone()
    if self.updateAni ~= nil then 
        self.updateAni:release()
        self.updateAni = nil 
    end 
end

function RABaseBuilding:getCenter()
    local x,y = self:getPosition()
    local length = self.buildData.confData.length
    local width = self.buildData.confData.width
    x = x+(width-length)/4.0*128 
    y = y+(width+length)/4.0*64
    return x,y
end

function RABaseBuilding:getXYformCenter(centerPos)
    local length = self.buildData.confData.length
    local width = self.buildData.confData.width
    local x = centerPos.x - (width-length)/4.0*128 
    local y = centerPos.y - (width+length)/4.0*64
    return x,y
end

function RABaseBuilding:showUpdateAni()
    self.updateAni = RABuildingUpgrade:new()
    self.updateAni:init(self)

    if self.buildData.confData.length == 1 and self.buildData.confData.width == 1 then 
        self.updateAni.ccbfile:setScale(0.5)
    else 
        self.updateAni.ccbfile:setScale(1)
    end 

    RACityScene.mBuildSpineLayer:addChild(self.updateAni.ccbfile)
end

--messageType用来区别
function RABaseBuilding:setState(state,messageType)
    -- CCLuaLog("this is state:" .. state )
    if self.curState then 
        -- CCLuaLog("this is curState:" .. self.curState)
        if self.curState == BUILDING_STATE_TYPE.IDLE and state == BUILDING_STATE_TYPE.UPGRADE_FINISH then 
            self.isQuickFinished = true
        end 
    end 
    if state == BUILDING_STATE_TYPE.IDLE then  --空闲状态，夜晚和白天的区别
        local RACityScene = RARequire('RACityScene')
        self:setOpacity(255)
        if self.queueData ~= nil then --升级完成后，如果有队列信息，那么就是兵营和医疗营，那么要播放工作动画
            self:setState(BUILDING_STATE_TYPE.WORKING)
        else  
            if self.buildData.confData.limitType == Const_pb.LIMIT_TYPE_BUILDING_DEFENDER then 
                if self.buildData.HP == 0 then 
                    self.spineNode:runAnimation(0,BUILDING_ANIMATION_TYPE.BROKEN,-1)
                elseif self.buildData.HP < self.buildData.totalHP then 
                    if RACityScene.isRain then 
                        self.spineNode:runAnimation(0,BUILDING_ANIMATION_TYPE.FEIDN_DEATH,-1)   
                    else
                        self.spineNode:runAnimation(0,BUILDING_ANIMATION_TYPE.FEIDN_DEATH_NIGHT,-1)
                    end
                else
                    if RACityScene.isRain then 
                        self.spineNode:runAnimation(0,BUILDING_ANIMATION_TYPE.IDLE_NIGHT,-1)   
                    else
                        self.spineNode:runAnimation(0,BUILDING_ANIMATION_TYPE.IDLE,-1)
                    end
                end
            else 
                if RACityScene.isRain then 
                    self.spineNode:runAnimation(0,BUILDING_ANIMATION_TYPE.IDLE_NIGHT,-1)   
                else
                    self.spineNode:runAnimation(0,BUILDING_ANIMATION_TYPE.IDLE,-1)
                end
            end 
        end  
    elseif state == BUILDING_STATE_TYPE.CONSTRUCTION then --建造
        self.spineNode:runAnimation(0,BUILDING_ANIMATION_TYPE.CONSTRUCTION,1)  
        self:setOpacity(255)
    elseif state == BUILDING_STATE_TYPE.MOVE_FINISH then --移动完成
        self.spineNode:runAnimation(0,BUILDING_ANIMATION_TYPE.CONSTRUCTION,1)  
        self:setOpacity(255)
    elseif state == "update" then 
        self.spineNode:removeFromParentAndCleanup(true)
        self:initBuild(self.buildData)
        -- self.spineNode:runAnimation(0,BUILDING_STATE_TYPE.CONSTRUCTION,1)
        --播放音效 立即升级的
        common:playEffect("up")
        self:showUpdateAni()
        RACityScene.mBuildSpineLayer:addChild(self.spineNode)
        -- self.updateAni.ccbfile:setPosition(self.spineNode:getPosition())
        self:setState(BUILDING_STATE_TYPE.IDLE)
    elseif state == 'update_finish' then 

        if  self.isQuickFinished == true then --如果当前状态是正常状态就升级完成了，就是立即升级
            self.spineNode:removeFromParentAndCleanup(true)
            self:initBuild(self.buildData)
            RACityScene.mBuildSpineLayer:addChild(self.spineNode)
            -- self.spineNode:runAnimation(0,BUILDING_STATE_TYPE.IDLE,-1)
            self:setTile(self.buildData.tilePos)
            -- RACityScene.mBuildSpineLayer:reorderChild(self.spineNode,self.buildData.tilePos.y)
            self.spineNode:runAnimation(0,BUILDING_STATE_TYPE.CONSTRUCTION,1)
            self.isQuickFinished = false
        else
            self:hideHelpBtn()
            self:showUpdateAni()
            self.updateAni.ccbfile:setPosition(self:getCenter())
            local constructionAnim = 'Construction_' .. self.buildData.confData.length .. '_' .. self.buildData.confData.width
            self.spineNode:runAnimation(0,constructionAnim,1,true)
        end 
    elseif state == BUILDING_STATE_TYPE.UPGRADE_START then
        self.spineNode:runAnimation(0,BUILDING_STATE_TYPE.CONSTRUCTION,1,true)

        -- self:showTimeBar()
        --播放音效
        common:playEffect("start_build_Up")

    elseif state == BUILDING_STATE_TYPE.UPGRADE_FINISH then --队列删除
        -- CCLuaLog("UPGRADE_FINISH")
        self:hideTimeBar()
        self:hideFreeTimeBtn()

        --播放音效
        common:playEffect("buildUpComplete")

        local name = RAStringUtil:getLanguageString(self.buildData.confData.buildName)
        local str = RAStringUtil:getLanguageString('@BuildingUpgradeFinish', name)
        if messageType == MessageDef_Queue.MSG_Building_DELETE then
            str = RAStringUtil:getLanguageString('@BuildingUpgradeFinish', name)
        elseif  messageType == MessageDef_Queue.MSG_Building_REBUILD_DELETE or messageType == MessageDef_Queue.MSG_Defener_REBUILD_DELETE then
            str = RAStringUtil:getLanguageString('@ReBuildingFinish', name)
        elseif  messageType == MessageDef_Queue.MSG_Defener_REPAIRE_DELETE then 
            str = RAStringUtil:getLanguageString('@RepaireBuildingFinish', name)
        end

        RARootManager.ShowMsgBox(str)

        --RARootManager.RemoveWaitingPage()

    elseif state == BUILDING_STATE_TYPE.UPGRADE or state == BUILDING_STATE_TYPE.REBUILD then --升级 or 重建中状态
        local idleAnim = 'Idle_' .. self.buildData.confData.length .. '_' .. self.buildData.confData.width  
        self.spineNode:runAnimation(0,idleAnim,-1)
        self:showTimeBar()
    elseif state == BUILDING_STATE_TYPE.WORKING then --研究中
        local RACityScene = RARequire('RACityScene')
        if RACityScene.isRain then 
            self.spineNode:runAnimation(0,BUILDING_ANIMATION_TYPE.WORKING_NIGHT,-1) 
        else
            self.spineNode:runAnimation(0,BUILDING_ANIMATION_TYPE.WORKING,-1)
        end
        self:updateHelpIcon() 
    elseif state == BUILDING_STATE_TYPE.WORKING_START then 
        local RACityScene = RARequire('RACityScene')
        if RACityScene.isRain then 
            self.spineNode:runAnimation(0,BUILDING_ANIMATION_TYPE.WORKING_NIGHT,-1) 
        else
            self.spineNode:runAnimation(0,BUILDING_ANIMATION_TYPE.WORKING,-1)
        end 

        local RAGuideManager = RARequire("RAGuideManager")
        if RAGuideManager.isInGuide() then
            if self.buildData.confData.buildType == Const_pb.WAR_FACTORY then
                --战车工厂造兵音效
                local common = RARequire("common")
                common:playEffect("ProduceTank")
            elseif self.buildData.confData.buildType == Const_pb.BARRACKS then
                --播放兵营造兵音效
                local common = RARequire("common")
                common:playEffect("TrainingSoldiers")
            end
            --回到城内，摄像机放大兵工厂
            local RACitySceneManager = RARequire("RACitySceneManager")
            local RAGuideConfig = RARequire("RAGuideConfig")
            RACitySceneManager:setCameraScale(RAGuideConfig.CityCameraSetting.SoldierTrain,RAGuideConfig.CityCameraTime.SoldierTrainTime)
        end
         self:updateHelpIcon() 
    elseif state == BUILDING_STATE_TYPE.WORKING_FINISH then 
        self:setState(BUILDING_STATE_TYPE.IDLE)
        self:hideHelpBtn()
    elseif state == BUILDING_STATE_TYPE.CANCEL then
        self:hideFreeTimeBtn()
        self:hideTimeBar()
        self:hideHelpBtn()
        local constructionAnim = 'Construction_' .. self.buildData.confData.length .. '_' .. self.buildData.confData.width
        self.spineNode:runAnimation(0,constructionAnim,1,true)
    elseif state == BUILDING_STATE_TYPE.WORKING_CANCEL then
        self:hideHelpBtn()
        self:setState(BUILDING_STATE_TYPE.IDLE)
        -- self:hideFreeTimeBtn()
        -- self:hideTimeBar()
        -- self.spineNode:removeFromParentAndCleanup(true)
        -- self:initBuild(self.buildData)
        -- RACityScene.mBuildSpineLayer:addChild(self.spineNode)
        -- self:setTile(self.buildData.tilePos)
        -- RACityScene.mBuildSpineLayer:reorderChild(building.spineNode,self.buildData.tilePos.y)
        -- self:setState(BUILDING_STATE_TYPE.IDLE)
    end 

    -- if self.curState == 'update_finish' and state == BUILDING_STATE_TYPE.UPGRADE_FINISH then 

    -- else 
        self.curState = state
    -- end 
end

function RABaseBuilding:setFreeTimeVisible(flag)
    self.freeTimeBtn.ccbfile:setVisible(flag)
end 


function RABaseBuilding:destory()
end

function RABaseBuilding:setVisible(isVisible)
    -- body
    self.spineNode:setVisible(isVisible)

    if self.timeBar ~= nil then 
        self.timeBar.ccbfile:setVisible(isVisible)
    end 

    if self.topBtn ~= nil then 
        self.topBtn.ccbfile:setVisible(isVisible)
    end  

    if self.freeTimeBtn ~= nil then 
        self.freeTimeBtn.ccbfile:setVisible(isVisible)
    end

    if self.helpBtn ~= nil then 
         self.helpBtn.ccbfile:setVisible(isVisible)
    end 
end

function RABaseBuilding:setOpacity(value)
    -- body
    local spineNode = tolua.cast(self.spineNode,"CCNodeRGBA")
    spineNode:setOpacity(value)
    tolua.cast(self.spineNode,"SpineContainer")

    if self.levelNode ~= nil then 
        self.levelNode:setOpacity(value)
    end 
end

function RABaseBuilding:setColor(color)
    local spineNode = tolua.cast(self.spineNode,"CCNodeRGBA")
    spineNode:setColor(color)
    tolua.cast(self.spineNode,"SpineContainer")
end


--设置建筑的位置
function RABaseBuilding:setTile(tilePos)
    
    self.buildData:setTilePos({x = tilePos.x ,y = tilePos.y})
    local bulidPos = RATileUtil:tile2Space(RACityScene.mTileMapGroundLayer,tilePos)
    self.spineNode:setPosition(bulidPos.x,bulidPos.y)


    local centerX,centerY = self:getCenter()
    
    if self.timeBar~=nil then 
        if self.buildData.confData.ProgressBarPos ~= nil then 
            self.timeBar:setPosition(centerX,centerY+self.buildData.confData.ProgressBarPos)
        else 
            self.timeBar:setPosition(centerX,bulidPos.y+40)
        end 
    end 

    local topPos = RATileUtil:tile2Space(RACityScene.mTileMapGroundLayer,self:getTopTile())
    if self.topBtn ~= nil then 
        if self.buildData.confData.upButtonPos ~= nil then 
            self.topBtn:setPosition(centerX-125.0/2,centerY+self.buildData.confData.upButtonPos) 
        else 
            self.topBtn:setPosition(centerX-125.0/2,topPos.y+75) 
        end 
    end

    if self.hpNode ~= nil then 
        if self.buildData.confData.upButtonPos ~= nil then 
            self.hpNode.ccbfile:setPosition(centerX,centerY+self.buildData.confData.upButtonPos) 
        else 
            self.hpNode.ccbfile:setPosition(centerX,topPos.y+100) 
        end 
    end  

    if self.freeTimeBtn ~= nil then 
        -- if self.buildData.confData.upButtonPos ~= nil then 
        --     self.freeTimeBtn:setPosition(centerX-125.0/2,centerY+self.buildData.confData.upButtonPos)
        -- else 
            self.freeTimeBtn:setPosition(centerX-125.0/2,topPos.y+75) 
        -- end 
    end

    if self.helpBtn ~= nil then 
        if self.buildData.confData.upButtonPos ~= nil then 
            self.helpBtn:setPosition(centerX-125.0/2,centerY+self.buildData.confData.upButtonPos) 
        else 
            self.helpBtn:setPosition(centerX-125.0/2,topPos.y+75) 
        end 
    end 

    if self.updateAni ~= nil then 
        self.updateAni.ccbfile:setPosition(self:getCenter())
    end 

    local RACityScene = RARequire('RACityScene')
    local Const_pb = RARequire("Const_pb")
    if self.buildData.confData.buildType == Const_pb.PRISM_TOWER then
        RACityScene.mBuildSpineLayer:reorderChild(self.spineNode,- (bulidPos.y - 80))
    else
        RACityScene.mBuildSpineLayer:reorderChild(self.spineNode,-bulidPos.y)
    end

    
end

--播放闪耀
function RABaseBuilding:playShadow()

    local shadowValue = const_conf.buildingShadowValue.value
    local tinto1 = CCTintTo:create(0.5,shadowValue,shadowValue,shadowValue)
    local tinto2 = CCTintTo:create(0.5,255,255,255)
    local sequence = CCSequence:createWithTwoActions(tinto1, tinto2)
    local repeatForever = CCRepeatForever:create(sequence)
    self.spineNode:runAction(repeatForever)
end

--停止播放闪耀
function RABaseBuilding:stopShadow()
    self.spineNode:stopAllActions()
    self:setColor(ccc3(255,255,255))
    self:setOpacity(255)
end

function RABaseBuilding:getPosition()
    return self.spineNode:getPosition()
end

function RABaseBuilding:getTopTile()
    return self.buildData.topTile
end

function RABaseBuilding:updateHp()
    if self.hpNode then 
        self.hpNode:setBarValue(self.buildData.HP,self.buildData.totalHP)
    end 
end

--获得建筑的占地位置
function RABaseBuilding:getTilesMap()
    return self.buildData.tilesMap
end

--获得建筑是否占据了
function RABaseBuilding:isContain(tilePos)
    return  self.buildData:isContain(tilePos) 
end 

function RABaseBuilding:isBuildingContain(buildings)
    return self.buildData:isBuildingContain(buildings.buildData)
end



--初始化建筑
function RABaseBuilding:initBuild(buildInfo,isUpgrade)
    self.buildData = buildInfo
    local RAGuideManager = RARequire('RAGuideManager')
    if self.buildData.confData.buildArtJson ~= nil then 

        if isUpgrade then
            self.spineNode = SpineContainer:create("ConstructionSite.json","ConstructionSite.atlas")
        else 
            if self.buildData.confData.buildType == Const_pb.CONSTRUCTION_FACTORY or self.buildData.confData.limitType == Const_pb.LIMIT_TYPE_BUIDING_RESOURCES then 
                local RAWorldConfig =  RARequire('RAWorldConfig')
                local World_pb =  RARequire('World_pb')
                local flagCfg = RAWorldConfig.RelationFlagColor[World_pb.SELF]
                CCTextureCache:sharedTextureCache():addColorMaskKey(flagCfg.key, RAColorUnpack(flagCfg.color))
                self.spineNode = SpineContainer:create(self.buildData.confData.buildArtJson .. ".json",self.buildData.confData.buildArtJson ..".atlas",flagCfg.key)
                -- self.spineNode = SpineContainer:create(self.buildData.confData.buildArtJson .. ".json",self.buildData.confData.buildArtJson ..".atlas",'INSIDE_COLOR')
            else
                self.spineNode = SpineContainer:create(self.buildData.confData.buildArtJson .. ".json",self.buildData.confData.buildArtJson ..".atlas")
            end 
        end 

        self.timeNode = CCNode:create()
        self.spineNode:addChild(self.timeNode)

        self.animationHandler = function (eventName,trackIndex,animationName,loopCount,reverse)
            -- CCLuaLog("eventName:" .. eventName .. " trackIndex:" .. trackIndex .. " animationName:" .. animationName .. " loopCount:" .. loopCount)     
            if self.curState == BUILDING_STATE_TYPE.CONSTRUCTION then 
                if animationName == BUILDING_STATE_TYPE.CONSTRUCTION then 
                    if eventName == "Complete" then
                        -- CCLuaLog('action compl') 
                            
                        if self.queueData ~= nil and self.queueData.queueType ~= Const_pb.BUILDING_QUEUE and self.queueData.queueType ~= Const_pb.BUILDING_DEFENER then 
                            local RACityScene = RARequire('RACityScene')
                            if RACityScene.isRain then 
                                self.spineNode:runAnimation(0,BUILDING_ANIMATION_TYPE.WORKING_NIGHT,-1) 
                            else
                                self.spineNode:runAnimation(0,BUILDING_ANIMATION_TYPE.WORKING,-1)
                            end 
                        else
                            self:setState(BUILDING_STATE_TYPE.IDLE)
                        end   

                        --移动到RABuildManager:handleGuideStep(buildData)
                         
                        if self.buildData.confData.buildType == Const_pb.RADAR and RAGuideManager.isInGuide()  then
                            --如果是雷达，有特殊报警效果
                            local time = tonumber(const_conf["GuideToRadarTime"].value)
                            performWithDelay(self.spineNode, function ()
                                self.spineNode:runAnimation(0, "Alarm", -1)--todo:雷达播放报警动画
                            end, 2)
                        end

                    end
                end
            elseif self.curState == BUILDING_STATE_TYPE.MOVE_FINISH then --移动结束
                if animationName == BUILDING_ANIMATION_TYPE.CONSTRUCTION and eventName == "Complete" then
                    --其他的都是工作状态
                    if self.queueData ~= nil and self.queueData.queueType ~= Const_pb.BUILDING_QUEUE and self.queueData.queueType ~= Const_pb.BUILDING_DEFENER then 
                        local RACityScene = RARequire('RACityScene')
                        if RACityScene.isRain then 
                            self.spineNode:runAnimation(0,BUILDING_ANIMATION_TYPE.WORKING_NIGHT,-1) 
                        else
                            self.spineNode:runAnimation(0,BUILDING_ANIMATION_TYPE.WORKING,-1)
                        end 
                    else  
                        self:setState(BUILDING_STATE_TYPE.IDLE)
                    end 
                end
            elseif animationName == 'Constructionoutside' and eventName == "Complete" then 
                RAGuideManager.gotoNextStep()
            elseif self.curState == BUILDING_STATE_TYPE.UPGRADE_START then 
                local constructionAnim = 'Construction_' .. self.buildData.confData.length.. '_' .. self.buildData.confData.width 
                -- local idleAnim = 'Idle' .. self.buildData.confData.width .. '_' .. self.buildData.confData.length 
                if animationName == BUILDING_STATE_TYPE.CONSTRUCTION then 
                    if eventName == "Complete" then
                        self.spineNode:removeFromParentAndCleanup(true)
                        -- self.spineNode:setVisible(false)
                        self.spineNode = SpineContainer:create("ConstructionSite.json","ConstructionSite.atlas")
                        self.spineNode:registerLuaListener(self.animationHandler)
                        self.timeNode = CCNode:create()
                        self.spineNode:addChild(self.timeNode)
                        RACityScene.mBuildSpineLayer:addChild(self.spineNode)
                        self:setTile(self.buildData.tilePos)
                        -- RACityScene.mBuildSpineLayer:reorderChild(building.spineNode,self.buildData.tilePos.y)

                        self.spineNode:runAnimation(0,constructionAnim,1)
                    end 
                elseif animationName == constructionAnim and eventName == "Complete" then
                    -- local idleAnim = 'Idle_' .. self.buildData.confData.length .. '_' .. self.buildData.confData.width 
                    -- self.spineNode:runAnimation(0,idleAnim,-1)
                    self:setState(BUILDING_STATE_TYPE.UPGRADE)
                    
                    local RAGameConfig = RARequire("RAGameConfig")
                    if RAGameConfig.SwitchGuide == 1  and self.buildData ~= nil and self.buildData.confData.buildType == Const_pb.CONSTRUCTION_FACTORY and self.buildData.confData.level == 2 then 
                        local RAGuideManager = RARequire('RAGuideManager')
                        -- RAGuideManager.setCallBackToGuideId()
                        MessageManager.sendMessage(MessageDef_MainUI.MSG_HandleChooseBuildPage, {isShow = false})
                        local RARootManager = RARequire("RARootManager")
                        performWithDelay(RARootManager.ccbfile, function ()
                            
                            RAGuideManager.gotoPart("Guide_MainCity_Start_2To3")
                        end, 1)               
                    else 
                        MessageManager.sendMessage(MessageDef_Queue.MSG_Common_ADD,{queueId = self.queueData.id, queueType = self.queueData.queueType})
                    end                     
                end
            elseif self.curState == 'update_finish' or self.curState == BUILDING_STATE_TYPE.CANCEL or self.curState == BUILDING_STATE_TYPE.UPGRADE_FINISH  then 
                local constructionAnim = 'Construction_' .. self.buildData.confData.length .. '_' .. self.buildData.confData.width
                if animationName == constructionAnim then 
                    if eventName == "Complete" then
                        self.spineNode:removeFromParentAndCleanup(true)
                        self:initBuild(self.buildData)
                        RACityScene.mBuildSpineLayer:addChild(self.spineNode)
                        -- self.spineNode:runAnimation(0,BUILDING_STATE_TYPE.IDLE,-1)
                        self:setTile(self.buildData.tilePos)
                        -- RACityScene.mBuildSpineLayer:reorderChild(self.spineNode,self.buildData.tilePos.y)
                        self.spineNode:runAnimation(0,BUILDING_STATE_TYPE.CONSTRUCTION,1)
                    end 
                elseif animationName == BUILDING_STATE_TYPE.CONSTRUCTION then 
 
                    if eventName == "Complete" then
                        if self.curState == 'update_finish' and reverse == true then --建造完成，但是还没来得及播放工地就结束了
                            self.spineNode:removeFromParentAndCleanup(true)
                            self:initBuild(self.buildData)
                            RACityScene.mBuildSpineLayer:addChild(self.spineNode)
                            -- self.spineNode:runAnimation(0,BUILDING_STATE_TYPE.IDLE,-1)
                            self:setTile(self.buildData.tilePos)
                            -- RACityScene.mBuildSpineLayer:reorderChild(self.spineNode,self.buildData.tilePos.y)
                            self.spineNode:runAnimation(0,BUILDING_STATE_TYPE.CONSTRUCTION,1)
                        else
                            self:setState(BUILDING_STATE_TYPE.IDLE)
                        end 
                    end 
                end 
            end  
        end
        self.spineNode:registerLuaListener(self.animationHandler)

        local spineNode = tolua.cast(self.spineNode,"CCNodeRGBA")
        local normalColor = spineNode:getColor()
        self.normalColor = ccc3(normalColor.r,normalColor.g,normalColor.b)
        tolua.cast(self.spineNode,"SpineContainer")
    else
        self.spineNode = UIExtend.loadCCBFile(self.buildData.confData.buildArtccbi,self)
    end  

    self:initLevel()

    if self.buildData.confData.limitType == Const_pb.LIMIT_TYPE_BUILDING_DEFENDER then 
        self:initBloodBar()
    end 
    -- self:initHelpBtn()
end

--设置等级
function RABaseBuilding:setLevel(level)
    if self.levelNode ~= nil then 
        self.levelNode:setString(level)
    end 
end

function RABaseBuilding:updateUpgradeIcon()
    -- body

    if self.levelNode ~= nil then 
        if RABuildingUtility.isCanUpgradeBuild(self.buildData.confData.id) then 
            self.levelNode.ccbfile:getCCSpriteFromCCB('mCanUpgrade'):setVisible(true)
        else 
            self.levelNode.ccbfile:getCCSpriteFromCCB('mCanUpgrade'):setVisible(false)
        end 

        self.levelNode.ccbfile:getCCSpriteFromCCB('mCanUpgrade'):setVisible(false)
    end 
end

--科研，医疗
function RABaseBuilding:updateHelpIcon()
    local RAAllianceManager = RARequire('RAAllianceManager')
    if RAAllianceManager.selfAlliance == nil then 
        self:hideHelpBtn()
    elseif self.queueData and (self.queueData.queueType == Const_pb.CURE_QUEUE or self.queueData.queueType == Const_pb.SCIENCE_QUEUE) then 
        if self.helpBtn == nil then 
            if self.queueData.helpTimes == 0 then 
                self:initHelpBtn()
            end 
        else 
            if self.queueData.helpTimes > 0 then 
                self:hideHelpBtn()
            end 
        end       
    end
end

function RABaseBuilding:initBloodBar()

    if self.hpNode ~= nil then 
        self.hpNode:release()
    end 

    self.hpNode = RABuildingBloodBar:new()
    self.hpNode:init()
    RACityScene.mBuildUILayer:addChild(self.hpNode.ccbfile) 
    self.hpNode.ccbfile:setPosition(0,100)  

    self:updateHp()
end

function RABaseBuilding:initLevel()

    if self.buildData.confData.level ~= nil then

        local _,maxLevel = RABuildingUtility.getBuildInfoByType(self.buildData.confData.buildType,false) 

        if self.buildData.confData.level < maxLevel then    
            self.levelNode = RABuildingLevel:new()
            self.levelNode:init()

            if self.buildData.confData.levelXy ~= nil then 
                local levelPos = RAStringUtil:split(self.buildData.confData.levelXy,"_")
                local x = tonumber(levelPos[1])
                self.levelNode.ccbfile:setPosition(tonumber(levelPos[1]),tonumber(levelPos[2]))

                if x > 0 then 
                    self.levelNode.ccbfile:getCCSpriteFromCCB('mHUDLevel'):setSkewX(30)
                    self.levelNode.ccbfile:getCCSpriteFromCCB('mHUDLevel'):setRotation(-30)
                    -- self.levelNode.ccbfile:getCCSpriteFromCCB('mCanUpgrade'):setSkewX(30)
                    self.levelNode.ccbfile:getCCSpriteFromCCB('mCanUpgrade'):setFlipX(true)
                    self.levelNode.ccbfile:getCCSpriteFromCCB('mLevelBG'):setFlipX(true)

                end 
            end 

            self.spineNode:addChild(self.levelNode.ccbfile)    
            self.levelNode:setString(self.buildData.confData.level)
            self.levelNode.ccbfile:getCCSpriteFromCCB('mCanUpgrade'):setVisible(false)
        end 
    end 


end

function RABaseBuilding:removeFromParentAndCleanup(flag) 

    if self.levelNode ~= nil then
        self.levelNode:release()
        self.levelNode = nil
    end

    if self.updateAni ~= nil then
        self.updateAni:release()
        self.updateAni = nil
    end

    if self.hpNode ~= nil then 
        self.hpNode:release()
        self.hpNode = nil 
    end 

    --if is spine, use removeFromParentAndCleanup, else use releaseCCBFile
    if self.buildData.confData.buildArtJson == nil then
        UIExtend.releaseCCBFile(self.spineNode)
    else
        self.spineNode:removeFromParentAndCleanup(flag)
    end

    
    -- self.timeBar.ccbfile:removeFromParentAndCleanup(flag)
end

--
function RABaseBuilding:updateTopStatus()

    if self.buildData.status == Const_pb.COMMON then 

        if self.topBtn ~= nil then 
            self:hideTopBtn()
        end 
    else 
        -- self:setTopBtnVisible(true)
        if self.helpBtn ~= nil then 
            return 
        end 

        if self.freeTimeBtn ~= nil then 
            return 
        end

        if self.topBtn == nil then 
            self:initTopBtn()
        end 

        if self.buildData.status == Const_pb.SOILDER_HARVEST then 
            common:playEffect("harvest") --收兵按钮出现时
            --self.topBtn:setBtnType(BUILDING_BTN_TYPE.GETTROOP)
            local type = BUILDING_BTN_TYPE.GETTROOP
            if self.buildData.confData.buildType == Const_pb.BARRACKS then
                type = BUILDING_BTN_TYPE.GET_BARRACKS
            elseif self.buildData.confData.buildType == Const_pb.WAR_FACTORY then
                type = BUILDING_BTN_TYPE.GET_WAR_FACTORY
            elseif self.buildData.confData.buildType == Const_pb.REMOTE_FIRE_FACTORY then
                type = BUILDING_BTN_TYPE.GET_REMOTE_FIRE_FACTORY
            elseif self.buildData.confData.buildType == Const_pb.AIR_FORCE_COMMAND then 
                type = BUILDING_BTN_TYPE.GET_AIR_FORCE_COMMAND
            end

            self.topBtn:setBtnType(type)
        elseif self.buildData.status == Const_pb.SOLDIER_WOUNDED then 
            self.topBtn:setBtnType(BUILDING_BTN_TYPE.SOLDIER_WOUNDED)
        elseif self.buildData.status == Const_pb.CURE_FINISH_HARVEST then 
            self.topBtn:setBtnType(BUILDING_BTN_TYPE.GETCURE)
        elseif self.buildData.status == Const_pb.DAMAGED then 
            self.topBtn:setBtnType(BUILDING_BTN_TYPE.EINSTEIN_NOT_REACH) 
        elseif self.buildData.status == Const_pb.READY_TO_CREATE then     
            self.topBtn:setBtnType(BUILDING_BTN_TYPE.EINSTEIN_REACH)
        end 
    end 
end

function RABaseBuilding:hideTopBtn()
    if self.topBtn ~= nil then 
        self.topBtn:release()
        self.topBtn = nil
    end 
end

function RABaseBuilding:hideFreeTimeBtn()
    
    if self.freeTimeBtn ~= nil then 
        self.freeTimeBtn:release()
        self.freeTimeBtn = nil
    end  
end

function RABaseBuilding:hideHelpBtn()
    
    if self.helpBtn ~= nil then 
        self.helpBtn:release()
        self.helpBtn = nil
    end

    self:updateTopStatus()  
end

function RABaseBuilding:initTopBtn()

    self.topBtn = RATopBtn:new()
    self.topBtn:init(self.buildData)
    RACityScene.mBuildUILayer:addChild(self.topBtn.ccbfile)
    local RACitySceneManager = RARequire("RACitySceneManager")
    RACitySceneManager:setControlToCamera(self.topBtn.ccbfile)
    self.topBtn.ccbfile:setVisible(true)

    local centerX,centerY = self:getCenter()

    local topPos = RATileUtil:tile2Space(RACityScene.mTileMapGroundLayer,self:getTopTile())

    
    if self.buildData.confData.upButtonPos ~= nil then 
        self.topBtn:setPosition(centerX-125.0/2,centerY+self.buildData.confData.upButtonPos)
    else 
        self.topBtn:setPosition(centerX-125.0/2,topPos.y+75) 
    end 
end

function RABaseBuilding:initHelpBtn()
    self.helpBtn = RATopBtn:new()
    self.helpBtn:init(self.buildData)
    self.helpBtn:setBtnType(BUILDING_BTN_TYPE.HELP)
    RACityScene.mBuildUILayer:addChild(self.helpBtn.ccbfile)
    local RACitySceneManager = RARequire("RACitySceneManager")
    RACitySceneManager:setControlToCamera(self.helpBtn.ccbfile)
    self.helpBtn.ccbfile:setVisible(true)

    local centerX,centerY = self:getCenter()

    local topPos = RATileUtil:tile2Space(RACityScene.mTileMapGroundLayer,self:getTopTile())

    
    if self.buildData.confData.upButtonPos ~= nil then 
        self.helpBtn:setPosition(centerX-125.0/2,centerY+self.buildData.confData.upButtonPos)
    else 
        self.helpBtn:setPosition(centerX-125.0/2,topPos.y+75) 
    end 

    self:hideTopBtn()
end

function RABaseBuilding:initFreeTimeBtn()
    self.freeTimeBtn = RATopBtn:new()
    self.freeTimeBtn:init(self.buildData)
    RACityScene.mBuildUILayer:addChild(self.freeTimeBtn.ccbfile)
    local RACitySceneManager = RARequire("RACitySceneManager")
    RACitySceneManager:setControlToCamera(self.freeTimeBtn.ccbfile)
    self.freeTimeBtn.ccbfile:setVisible(true)


    local centerX,centerY = self:getCenter()

    local topPos = RATileUtil:tile2Space(RACityScene.mTileMapGroundLayer,self:getTopTile())

    
    -- if self.buildData.confData.upButtonPos ~= nil then 
    --     self.freeTimeBtn:setPosition(centerX-125.0/2,centerY+self.buildData.confData.upButtonPos)
    -- else 
        self.freeTimeBtn:setPosition(centerX-125.0/2,topPos.y+75) 
    -- end 
    self.freeTimeBtn:setBtnType(BUILDING_BTN_TYPE.FREETIME)
     
end

--显示时间条
function RABaseBuilding:showTimeBar()
    self.timeBar = RATimeBarHUD:new()
    self.timeBar:init()
    self.timeBar:registerHandler(self)
    self.timeBar.ccbfile:setVisible(true)
    self.timeBar:start(self.queueData)
    RACityScene.mBuildUILayer:addChild(self.timeBar.ccbfile)

    local centerX,centerY = self:getCenter()

    if self.buildData.confData.ProgressBarPos ~= nil then 
        self.timeBar:setPosition(centerX,centerY+self.buildData.confData.ProgressBarPos)
    else 
         local x,y = self:getPosition()
        self.timeBar:setPosition(centerX,y+40)
    end  
end

--隐藏时间条
function RABaseBuilding:hideTimeBar()

    if self.timeBar ~= nil then 
        self.timeBar:release()
        self.timeBar = nil
    end  
end





