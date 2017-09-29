-- RAMarchMoveHelper
-- 行军的移动动画控制

local RAMarchConfig = RARequire('RAMarchConfig')
local RAMarchActionEntity = RARequire('RAMarchActionEntity')
local RAMarchFrameActionEntity = RARequire('RAMarchFrameActionEntity')
local RAMarchActionHelper = RARequire('RAMarchActionHelper')
local EnumManager = RARequire('EnumManager')
local UIExtend = RARequire('UIExtend')
local Utilitys = RARequire('Utilitys')
local World_pb = RARequire('World_pb')

local TAG_IS_USE_FRAME_DISPLAY = true

local RAMarchMoveHelper = {}

-- 行军移动的控制对象，用于控制行军ccb容器的移动
local RAMarchMoveController = 
{
    

    new = function(self, o)
        o = o or {}
        setmetatable(o,self)
        self.__index = self   
        -- 添加模型 
        o.mSelfContainer = nil
        -- 添加线和终点ccb
        o.mSelfLineContainer = nil
        -- 出发点ccb
        o.mStartEnity = nil
        -- 结束点ccb
        o.mEndEnity = nil
        -- 移动ccb
        o.mMoveEntity = nil
        -- 线
        o.mLineEntity = nil

        -- 对应的行军id
        o.mMarchId = ''
        o.mCurrSpeedScale = 1

        --当前移动的总数据
        o.mCurrMoveData = nil
        -- 当前播放移动的段数索引
        o.mCurrMoveIndex = 0

        return o
    end,

    ResetData = function(self)
        self.mSelfContainer = nil
        self.mSelfLineContainer = nil

        self.mStartEnity = nil
        self.mEndEnity = nil
        self.mMoveEntity = nil
        self.mLineEntity = nil

        self.mArmyTypeList = nil
        self.mTargetResType = -1
        self.mCurrSpeedScale = 1

        self.mCurrMoveData = nil
        self.mCurrMoveIndex = 0
    end,

    -- 初始化controller
    Init = function(self, marchId, visibleStatus)
        if self.mSelfContainer ~= nil then            
            self.mSelfContainer:removeFromParentAndCleanup(true)
            self.mSelfContainer:release()
            self.mSelfContainer = nil
        end
        self.mSelfContainer = CCNode:create()
        self.mSelfContainer:retain()        

        if self.mSelfLineContainer ~= nil then            
            self.mSelfLineContainer:removeFromParentAndCleanup(true)
            self.mSelfLineContainer:release()
            self.mSelfLineContainer = nil
        end
        self.mSelfLineContainer = CCNode:create()
        self.mSelfLineContainer:retain()        
    
        self:SetVisible(visibleStatus)

        self:UpdateControlerData(marchId, false, true)        
        return self.mSelfContainer, self.mSelfLineContainer
    end,

    -- 根据march id 刷新行军显示，id只取值
    -- isReLoad针对行军移动node，线和终点ccb自动Reload
    UpdateControlerData = function(self, marchId, isUseCurrPos, isReLoad)
        local isReLoad = isReLoad or false
        self.mMarchId = marchId
        local RAMarchDataManager = RARequire('RAMarchDataManager')
        local RAWorldMath = RARequire('RAWorldMath')

        local marchData = RAMarchDataManager:GetMarchDataById(marchId)
        if marchData == nil then return end
        self.mMarchId = marchId

        --刷新数据后从第一段开始播放
        self.mCurrMoveIndex = 1
        local currStartPos = nil
        if isUseCurrPos then
            currStartPos = self:GetMarchMoveEntityViewPos()
        end
        local timeDebug = CCTime:getCurrentTime()
        self.mCurrMoveData = RAMarchMoveHelper:GetMarchMoveData(marchData, currStartPos)
        local calcTimeSpend = CCTime:getCurrentTime() - timeDebug
        print('run RAMarchMoveHelper.GetMarchMoveData one time, spend time:'.. tostring(calcTimeSpend))
            
        -- 先根据行军进程，判断停止
        self.mIsStop = false
        if marchData.marchStatus == World_pb.MARCH_STATUS_EXECUTING then
            self.mIsStop = true
            self:StopMoveEntity()
            return
        end

        self:UpdateMoveEntity(marchData, isReLoad)
        -- 刷新终点的ccb
        self:UpdateEndEntity(marchData.marchStatus)
        -- 刷新线的ccb 
        self:UpdateLineEntity(marchData.relation, self.mCurrMoveData.speedScale, marchData.playerId)
    end,

    GetSelfContainer = function(self)
        return self.mSelfContainer, self.mSelfLineContainer
    end,

    -- -- 开始位置ccb
    -- UpdateStartEntity = function(self)
    --     self:ReleaseStartEntity()
    --     self.mStartEnity = {}
    --     local ccbi = UIExtend.loadCCBFile(RAMarchConfig.ReturnPosCCB, self.mStartEnity)
    --     self.mSelfContainer:addChild(ccbi)
    --     ccbi:setPosition(self.mBeginPos.x, self.mBeginPos.y)
    --     return self.mStartEnity
    -- end,
    -- ReleaseStartEntity = function(self)
    --     if self.mStartEnity ~= nil then
    --         UIExtend.unLoadCCBFile(self.mStartEnity)
    --         self.mStartEnity = nil
    --     end
    -- end,

    -- 线的ccb
    UpdateLineEntity = function(self, relation, speedScale, playerId)
        self:ReleaseLineEntity()       
        self.mLineEntity = {}
        if self.mCurrMoveData then
            local startPos = self.mCurrMoveData.startPos
            local endPos = self.mCurrMoveData.endPos
            local ccbName = RAMarchConfig.MarchRelation2CCB[relation].ccb
            local RAPresidentDataManager = RARequire('RAPresidentDataManager')
            local isPresident = RAPresidentDataManager:IsPresident(playerId)
            if isPresident then
                ccbName = RAMarchConfig.MarchShowForPresidentLineCCBName
            end
            if ccbName ~= '' then
                local ccbi = UIExtend.loadCCBFile(ccbName, self.mLineEntity)
                self.mSelfLineContainer:addChild(ccbi, RAMarchConfig.MarchDisplayZOrder.LineEntity)
                ccbi:setVisible(false)                
                local lineSpr = UIExtend.getCCSpriteFromCCB(ccbi, 'mArmyLine')
                if lineSpr ~= nil then
                    lineSpr:setRotation(360 - tonumber(self.mCurrMoveData.angle))
                    local height = lineSpr:getContentSize().height
                    local width = Utilitys.getDistance(startPos, endPos)
                    lineSpr:setPreferedSize(CCSize(width, height))

                    if RAMarchConfig.MarchLineSpeedInit == nil then
                        local speed = lineSpr:getTextureRepeatSpeed()
                        RAMarchConfig.MarchLineSpeedInit = RACcp(speed.x, speed.y)
                    end
                    local xSpeed = RAMarchConfig.MarchLineSpeedInit.x * speedScale
                    local ySpeed = RAMarchConfig.MarchLineSpeedInit.y * speedScale
                    lineSpr:setTextureRepeatSpeed(CCPointMake(xSpeed, ySpeed))
                end
                ccbi:setPosition(startPos.x, startPos.y)
                ccbi:setVisible(true)
            end
        end
        return self.mLineEntity
    end,

    ReleaseLineEntity = function(self)
        if self.mLineEntity ~= nil then
            UIExtend.unLoadCCBFile(self.mLineEntity)
            self.mLineEntity = nil
        end
    end,

    -- 结束位置ccb
    UpdateEndEntity = function(self, marchStatus)
        self:ReleaseEndEntity()
        local ccbName = ''
        if marchStatus == World_pb.MARCH_STATUS_MARCH then
            ccbName = RAMarchConfig.EndPosCCB
        elseif marchStatus == World_pb.MARCH_STATUS_EXECUTING then
            ccbName = ''
        elseif marchStatus == World_pb.MARCH_STATUS_RETURN_BACK then
            ccbName = RAMarchConfig.ReturnPosCCB
        end
        if ccbName ~= '' then
            self.mEndEnity = {}
            if self.mCurrMoveData and self.mCurrMoveData.endPos then
                local ccbi = UIExtend.loadCCBFile(ccbName, self.mEndEnity)
                self.mSelfLineContainer:addChild(ccbi, RAMarchConfig.MarchDisplayZOrder.EndEntity)            
                ccbi:setPosition(self.mCurrMoveData.endPos.x, self.mCurrMoveData.endPos.y)
            end
        end
        return self.mEndEnity
    end,

    ReleaseEndEntity = function(self)
        if self.mEndEnity ~= nil then
            UIExtend.unLoadCCBFile(self.mEndEnity)
            self.mEndEnity = nil
        end
    end,

    -- 移动的ccb
    UpdateMoveEntity = function(self, marchData, isReLoad)        
        if self.mCurrMoveData == nil then return nil end
        local RAMarchDataManager = RARequire('RAMarchDataManager')
        local isNeedCreate = RAMarchDataManager:LocalCheckIsMarchNeedCreateModel(marchData.marchStatus)
        if not isNeedCreate then return nil end
        local direction = self.mCurrMoveData.direction
        if isReLoad then
            self:ReleaseMoveEntity()
        end
        if self.mMoveEntity == nil then
            local ccbi = nil
            if TAG_IS_USE_FRAME_DISPLAY then
                self.mMoveEntity = RAMarchFrameActionEntity:new({mMarchId = self.mMarchId})
                ccbi = self.mMoveEntity:Load(direction)
            else
                self.mMoveEntity = RAMarchActionEntity:new({mMarchId = self.mMarchId})
                ccbi = self.mMoveEntity:LoadNew(direction)
            end
            if ccbi ~= nil then
                self.mSelfContainer:addChild(ccbi, RAMarchConfig.MarchDisplayZOrder.MoveEntity)
                ccbi:setPosition(self.mCurrMoveData.startPos.x, self.mCurrMoveData.startPos.y)
                self.mMoveEntity:RegisterHandler(self)
                -- 现在不会立即加载行军模型了
                -- self:CreateMarchMoveModels(marchData)
            end
        end

        -- 不加载行军模型，但是可能还需要刷新速度，所以逻辑不能变
        self:_OnlyUpdateMoveEntityArmyAnimation(self.mCurrMoveData.speedScale)

        local isNeedStop = self:_OnlyUpdateMoveEntityAction()
        if isNeedStop then
            self:StopMoveEntity()
        end
        return self.mMoveEntity
    end,

    -- 加载行军的模型显示
    CreateMarchMoveModels = function(self, marchData)        
        if self.mMoveEntity ~= nil then
            local RAMarchDataManager = RARequire('RAMarchDataManager')
            local isNeedCreate = RAMarchDataManager:LocalCheckIsMarchNeedCreateModel(marchData.marchStatus)
            if not isNeedCreate then return false end
            -- 兵种数据
            local armyTypeList = marchData:GetArmyTypes()
            -- 采集资源需要取资源类型
            local targetResType = -1
            if marchData.marchType == World_pb.COLLECT_RESOURCE or 
                marchData.marchType == World_pb.MANOR_COLLECT then
                local RAWorldConfigManager = RARequire('RAWorldConfigManager')
                local res_conf, _ = RAWorldConfigManager:GetResConfig(marchData.targetId)
                targetResType = res_conf.resType
            end

            if marchData.marchType == World_pb.MANOR_COLLECT then
                targetResType = tonumber(marchData.targetId)
            end

            local params = {}
            params.armyTypeList = armyTypeList
            params.targetResType = targetResType
            params.playerId = marchData.playerId
            local timeDebug = CCTime:getCurrentTime()   
            local result = self.mMoveEntity:CreateArmyModels(marchData.marchType, params, marchData.relation)
            local calcTimeSpend = CCTime:getCurrentTime() - timeDebug
            print('run RAMarchMoveController.CreateMarchMoveModels one time, spend time:'.. tostring(calcTimeSpend))
            if result then
                self:_OnlyUpdateMoveEntityArmyAnimation(self.mCurrMoveData.speedScale)
                local isNeedStop = self:_OnlyUpdateMoveEntityAction()
                if isNeedStop then
                    self:StopMoveEntity()
                end
            end
            return result
        end
        return false
    end,

    --只播放时间轴
    _OnlyUpdateMoveEntityArmyAnimation = function(self, speedScale)
        self.mMoveEntity:ArmyPlayAnimation(speedScale)
    end,

    -- 只播放移动动画
    _OnlyUpdateMoveEntityAction = function(self)
        local isNeedStop = true

        if self.mCurrMoveData == nil or self.mCurrMoveData.moveDatas == nil then
            isNeedStop = true
        else
            -- 取索引对应的动作进行播放        
            local oneMoveData = self.mCurrMoveData.moveDatas[self.mCurrMoveIndex]
            if oneMoveData ~= nil then
                isNeedStop = false
                local duration = oneMoveData.duration
                local moveStartPos = Utilitys.ccpCopy(oneMoveData.moveStartPos)
                local moveEndPos = Utilitys.ccpCopy(oneMoveData.moveEndPos)
                -- local common = RARequire('common')  
                -- if common:isNaN(duration)then
                --     print(duration)
                --     print(debug.traceback())
                -- end  
                -- 如果最后一次让更新的时候，时间为0或者起点终点一样，就直接停止动作，然后设置位置
                local isSame = Utilitys.checkIsPointSame(moveStartPos, moveEndPos)
                if duration == 0 or isSame then                    
                    isNeedStop = true
                    self:StopMoveEntity()
                    local ccb = self.mMoveEntity:GetCCBFile()
                    if ccb ~= nil then
                        ccb:setPosition(moveEndPos.x, moveEndPos.y)
                    end
                else
                    self.mMoveEntity:UpdateEntityMoveAction(oneMoveData.duration, moveStartPos, moveEndPos)                
                end
            end
        end
        return isNeedStop
    end,

    -- 停止移动ccb的移动
    StopMoveEntity = function(self)
        if self.mMoveEntity ~= nil then            
            -- 停止移动
            self.mMoveEntity:StopEntityMoveAction()
        end
    end,

    SetVisible = function(self, value)        
        if self.mSelfContainer then
            self.mSelfContainer:setVisible(value)
        end
        if self.mSelfLineContainer then
            self.mSelfLineContainer:setVisible(value)
        end
    end,

    GetMoveEntity = function(self)
        return self.mMoveEntity
    end,

    GetMarchMoveEntityTilePos = function(self)
        local result = RACcp(-1, -1)
        if self.mMoveEntity ~= nil then
            local ccb = self.mMoveEntity:GetCCBFile()
            if ccb ~= nil then
                local x, y  = ccb:getPosition()
                local cnX, cnY = self.mSelfContainer:getPosition()
                x = x + cnX
                y = y + cnY
                local RAWorldMath = RARequire('RAWorldMath')
                local pos = RAWorldMath:View2Map(RACcp(x, y))
                result.x = pos.x
                result.y = pos.y
            end
        end
        return result
    end,

    GetMarchMoveEntityViewPos = function(self)
        if self.mMoveEntity ~= nil then
            local ccb = self.mMoveEntity:GetCCBFile()
            if ccb ~= nil then
                local result = RACcp(-1, -1)
                local x, y  = ccb:getPosition()
                local common = RARequire('common')
                if common:isNaN(x) or common:isNaN(y) then
                    RACcpPrint({x = x, y = y})
                    print(debug.traceback())
                end                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 
                local cnX, cnY = self.mSelfContainer:getPosition()
                x = x + cnX
                y = y + cnY
                result.x = x
                result.y = y
                return result
            end
        end
        return nil
    end,

    -- 移动
    ShowMoeveEntityHud = function(self)
        if self.mMoveEntity ~= nil then
            self.mMoveEntity:ShowHud()
        end
    end,

    -- 获取当前军队的坐标列表（大类型对应坐标）
    -- 返回目标位置
    GetArmyPostion = function(self)
        local result = nil
        if self.mMoveEntity ~= nil then
            result = self.mMoveEntity:GetArmyNodesPos()            
        end
        local tilePos = nil
        local RAMarchDataManager = RARequire('RAMarchDataManager')
        local marchData = RAMarchDataManager:GetMarchDataById(self.mMarchId)
        if marchData then
            tilePos = RACcp(marchData.terminalX, marchData.terminalY)
            startTile = RACcp(marchData.origionX, marchData.origionY)
        end
        return result, tilePos, startTile
    end,

    -- 获取起始点和终点坐标
    GetMarchMoveStartAndEndPos = function(self)
        local ptS = nil
        local ptE = nil
        if self.mCurrMoveData ~= nil then
            ptS = Utilitys.ccpCopy(self.mCurrMoveData.startPos)
            ptE = Utilitys.ccpCopy(self.mCurrMoveData.endPos)
        end
        return ptS, ptE
    end,

    ReleaseMoveEntity = function(self)
        if self.mMoveEntity ~= nil then
            self.mMoveEntity:StopEntityMoveAction()
            self.mMoveEntity:Exit()
            UIExtend.unLoadCCBFile(self.mMoveEntity)
            self.mMoveEntity = nil
        end
    end,

    OnEntityActionChange = function(self, endType)
        print('RAMarchMoveController OnEntityActionChange, type is :'..endType)
        local RAActionConfig = RARequire('RAActionConfig')
        if endType == RAActionConfig.MoveToCallBackType.InitiativeEnd then
            print('InitiativeEnd')
        elseif endType == RAActionConfig.MoveToCallBackType.NormalEnd then
            print('NormalEnd')
            -- 正常结束的时候，要去刷新下一个分段的动作
            self.mCurrMoveIndex = self.mCurrMoveIndex + 1
            self:_OnlyUpdateMoveEntityAction()
        end
    end,

    Release = function(self)
        self:ReleaseEndEntity()
        self:ReleaseMoveEntity()
        self:ReleaseLineEntity()

        if self.mSelfContainer ~= nil then            
            self.mSelfContainer:removeFromParentAndCleanup(true)
            self.mSelfContainer:release()
            self.mSelfContainer = nil
        end
        if self.mSelfLineContainer ~= nil then            
            self.mSelfLineContainer:removeFromParentAndCleanup(true)
            self.mSelfLineContainer:release()
            self.mSelfLineContainer = nil
        end
        self:ResetData()
    end
}

function RAMarchMoveHelper:CreateMarchMoveController(marchId, visibleStatus)
    local controller = RAMarchMoveController:new()
    controller:Init(marchId, visibleStatus)
    return controller
end




-- 计算行军移动用到的数据
-- 1、根据时间计算当前显示点
-- 2、根据时间百分百和黑土地类型，计算动画序列数据



-- 返回的table数据格式：

-- 1、公共数据
-- result['angle'] = angle
-- result['direction'] = direction
-- result['speedScale'] = speedScale
-- result['startPos'] = startPos
-- result['endPos'] = endPos
-- result['disType'] = disType
-- result['gapCount'] = 0

-- 2、分段移动的数据
-- result['moveDatas'] = {}         

function RAMarchMoveHelper:GetMarchMoveData(marchData, currStartPos)
    if marchData == nil then
        return nil
    end
    
    local common = RARequire('common')
    local RAWorldMath = RARequire('RAWorldMath')
    local RAMarchDataManager = RARequire('RAMarchDataManager')
    local RAWorldBuildingManager = RARequire('RAWorldBuildingManager')
    local RAWorldConfig = RARequire('RAWorldConfig')

    local result = {}
    
    local curTime = common:getCurTime()
    local startTime = marchData:GetCalcDisStartTime() 
    local startTile, calcType = marchData:GetCalcDisStartPos()
    local endTime = marchData.endTime
    local terminalTile = marchData:GetEndCoord()
    local origionTile = marchData:GetStartCoord()
    local lastTime = os.difftime(endTime / 1000, curTime) 
    local totalTime = (endTime - startTime) / 1000

    local endPos = RAWorldMath:Map2View(terminalTile)
    local endMovePos = Utilitys.ccpCopy(endPos)
    local origionPos = RAWorldMath:Map2View(origionTile)
    -- 起始的像素坐标，新增规则
    -- 1、如果前端已经有显示对象，那么按照前端的位置为当前起始位置
    -- 2、如果前端没有显示对象，那么直接按照MarchData中的tile位置转换为像素坐标
    -- 3、如果为2的时候，需要根据起点和终点所构成的线段，找出到2中所得像素位置点最近的点，以此为最终点
    -- 4、若为3，需要在 calc start Tile和 origionTile不一致的时候才计算
    local startPos = nil
    local currStartPos, isPt = Utilitys.checkIsPoint(currStartPos)
    if isPt then
        startPos = currStartPos
    else
        local serverStartPos = RAWorldMath:Map2View(startTile)
        if Utilitys.checkIsPointSame(startTile, origionTile) then
            startPos = serverStartPos
        else
            local _, crossPt = Utilitys.getPoint2SegmentDistance(serverStartPos, origionPos, endPos)
            -- startPos = crossPt
            startPos = crossPt
        end
    end

    -- 去下面除容错判断，现在Tile坐标为浮点型
    -- -- 当为行军到目标点的时候，需要提前停止一段距离
    -- if marchData.marchStatus == World_pb.MARCH_STATUS_MARCH then
    --     local gridCnt = 1
    --     local buildingId, buildingNode = RAWorldBuildingManager:GetBuildingAt(terminalTile)
    --     if buildingNode ~= nil then
    --         gridCnt = buildingNode.buildingInfo.gridCnt or 1
    --     end
    --     local disKey = 'WorldMarchPreStopDistance_'..gridCnt
    --     local dis = 80    
    --     if const_conf[disKey] ~= nil then
    --         dis = const_conf[disKey].value
    --     end
    --     endMovePos =  Utilitys.getGapPointOnSegment(dis, startPos, endMovePos)
    -- end
    -- -- 根据起点的不同类型，去做容错（规避使用道具加速或者召回后，服务器设置了道具使用点和终点是同一个格子 ）     
    -- if calcType ~= 0 then
    --     -- 加速道具
    --     local gapDis = 20
    --     if calcType == 1 then
    --         gapDis = RAMarchConfig.MarchSpeedUpGapDis
    --     end
    --     if calcType == 2 then
    --         gapDis = RAMarchConfig.MarchCallBackGapDis
    --     end
    --     local isSame = Utilitys.checkIsPointSame(startTile, terminalTile)
    --     if isSame then            
    --         startPos =  Utilitys.getGapPointOnSegment(gapDis, startPos, endMovePos)  
    --     end
    -- end

    local angle = Utilitys.ccpAngle(origionPos, endPos)
    local calcOriTile = RACcp(origionTile.x, RAWorldConfig.mapSize.height - origionTile.y)
    local calcTerTile = RACcp(terminalTile.x, RAWorldConfig.mapSize.height - terminalTile.y)
    local angleForDir = Utilitys.ccpAngle(calcOriTile, calcTerTile)
    -- print('--------RAMarchMoveHelper:GetMarchMoveData-------')
    -- print('--------angle view:'..angle)
    -- print('--------angle tile:'..angleForDir)
    -- local direction = RAMarchActionHelper:Get16DirectionByAngle(angle)
    local directionTile = RAMarchActionHelper:Get16DirectionByAngle(angleForDir)
    -- print('--------dir view:'..direction)
    -- print('--------dir tile:'..directionTile)
    local speedScale = 1
    if marchData.speedTimes ~= 0 then
        speedScale = marchData.speedTimes / 1000
    end
    --默认为1
    if speedScale < 1  then speedScale = 1 end
    -- 不大maxScale
    local maxScale = RAMarchConfig.MarchLineSpeedMaxScale
    if speedScale > maxScale  then speedScale = maxScale end

    result['angle'] = angle
    result['direction'] = directionTile
    result['speedScale'] = speedScale
    result['startPos'] = origionPos
    result['endPos'] = endPos
    result['endMovePos'] = endMovePos
    -- 分段数目
    result['gapCount'] = 0
    -- 缓存一个移动数据数组
    local moveDatas = {}
    result['moveDatas'] = moveDatas

    -- 获取行军的分段数据
    local timeDebug = CCTime:getCurrentTime()
    local marchParts = RAMarchDataManager:GetMarchWayData(startPos, endMovePos, false)
    local calcTimeSpend = CCTime:getCurrentTime() - timeDebug
    print('run RAMarchDataManager.GetMarchWayData one time, spend time:'.. tostring(calcTimeSpend))
    local slowDownScale = RARequire('world_march_const_conf').worldMarchCoreRangeTime.value

    -- 1、计算出当前应该显示的点，根据已经消耗了的时间百分比，计算走出的距离
    -- 计算距离百分比，
     -- 2、根据剩余的距离，计算走到了哪个分段，然后从那个分段开始构建数据   
    local nowBeginIndex, firstMovePos = RAMarchDataManager:GetMarchMoveCurrPos(marchParts, startTime, endTime)
    -- 3、根据分段开始构建数据，需要分配剩余的时间到各个分段中（按百分比）
    local moveDataIndex = 1
    local totalLastDisPer = 0
    for i = nowBeginIndex, #marchParts do
        local partData = marchParts[i]
        local partBeginPos = partData.startPos
        local partEndPos = partData.endPos
        local isSlowDown = partData.isSlowDown

        local oneMoveData = {
            moveStartPos = partBeginPos,
            moveEndPos = partEndPos,
            isSlowDown = isSlowDown,            
            distance = 0,
        }
        if i == nowBeginIndex and firstMovePos ~= nil then
            oneMoveData.moveStartPos = Utilitys.ccpCopy(firstMovePos) 
        end
        --  刷新距离
        local dis = Utilitys.getDistance(oneMoveData.moveStartPos, oneMoveData.moveEndPos)
        oneMoveData.distance = dis

        moveDatas[moveDataIndex] = oneMoveData
        moveDataIndex = moveDataIndex + 1
        local speedScale = 1
        if isSlowDown then
            speedScale = slowDownScale
        end
        totalLastDisPer = totalLastDisPer + oneMoveData.distance * speedScale
    end

    -- 4、计算每一个移动分段的时间
    for i=1, #moveDatas do
        local oneMoveData = moveDatas[i]
        local speedScale = 1
        if oneMoveData.isSlowDown then
            speedScale = slowDownScale
        end
        local movePer = oneMoveData.distance * speedScale
        local duration = lastTime * movePer / totalLastDisPer
        if totalLastDisPer <= 0 then
            -- 如果起始点和终点坐标一样，最后的动画时间为0
            duration = 0
        end
        oneMoveData.duration = duration
    end    
    return result
end

return RAMarchMoveHelper