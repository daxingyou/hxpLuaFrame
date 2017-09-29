--require('UICore.ScrollViewAnimation')
RARequire("BasePage")
local UIExtend = RARequire('UIExtend')
local RAMainUIHelper = RARequire('RAMainUIHelper')
local RAStringUtil = RARequire('RAStringUtil')
local RARootManager = RARequire('RARootManager')
local RAActionManager = RARequire('RAActionManager')
local RAQueueManager = RARequire('RAQueueManager')
local RABuildManager = RARequire('RABuildManager')
local RACoreDataManager = RARequire('RACoreDataManager')
local EnterFrameDefine = RARequire('EnterFrameDefine')
local RAMainUIQueueDataManager = RARequire('RAMainUIQueueDataManager')
local Utilitys = RARequire('Utilitys')
local common = RARequire('common')
local Const_pb = RARequire('Const_pb')
local List = RARequire("List")

local RAMainUIQueueShowHelper = {}

local OnReceiveMessage = nil
local CCB_InAni = "InAni"
local CCB_OutAni = "OutAni"
local CCB_KeepIn = "KeepIn"
local CCB_KeepOut = "KeepOut"

local CCB_UpAni = "UpAni"
local CCB_DownAni = "DownAni"

local CCB_Btn_OpenAni = 'OpenAni'
local CCB_Btn_KeepOpen = 'KeepOpen'
local CCB_Btn_CloseAni = 'CloseAni'
local CCB_Btn_KeepClose = 'KeepClose'


-- 单个cell 更改状态的类型
local CellChangeType = 
{
    None = 0,
    Add = 1,
    Update = 2,
    Remove = 3
}


local delayGap = 0.05
-- 遮罩动画显示或消失消耗的时间
local _ClipNodeActionTimeNeed = 0.2

local _CellUpDownAniTime = 0.1

-- 单个cell的高度
local MainUI_Queue_One_Cell_Height = 0
local MainUI_Queue_One_Cell_Width = 0

-- 不收缩状态时，最多显示的cell个数
local MainUI_Queue_Cell_Show_Count = 2

-- 点击间隔时间
local CLICK_GAP_TIME = 1000

-- 进度条刷新频率ms
local Execute_Time_Gap = 1000

------ queue cell
local RAMainUIQueueCellNew = 
{
    new = function(self, o)
        o = o or {}
        setmetatable(o,self)
        self.__index = self
        o.mAniCmpHandler = nil    
        o.mIsFree = false
        o.mIsRefreshed = false
        -- 点击增加冷却
        o.mLastClickTime = 0
        o.mLastExecuteTime = 0
        return o
    end,

    GetCCBName = function(self)
        return "RAMainUIQueueCellNewTwo.ccbi"
    end,

    GetCCBFile = function(self)
        return self.ccbfile
    end,

    Load = function(self, handler)
        CCLuaLog("RAMainUIQueueCellNew:Load")
        local ccbi = UIExtend.loadCCBFile(self:GetCCBName(), self)
        if ccbi == nil then return end
        ccbi:runAnimation(CCB_KeepOut)
        self.mLastClickTime = 0
        self.mLastExecuteTime = 0
        if MainUI_Queue_One_Cell_Height == 0 then
            MainUI_Queue_One_Cell_Height = ccbi:getContentSize().height
        end
        if MainUI_Queue_One_Cell_Width <= 0 then
            MainUI_Queue_One_Cell_Width = ccbi:getContentSize().width
        end
        self.mAniCmpHandler = handler
        UIExtend.setCCScale9SpriteScale(ccbi, 'mBlueBar', 0, true)   
        UIExtend.setCCScale9SpriteScale(ccbi, 'mOrangeBar', 0, true)   
        UIExtend.setCCScale9SpriteScale(ccbi, 'mGreenBar', 0, true)
        self:RefreshCell(nil, true)
        return ccbi
    end,

    RefreshCell = function(self, data, isInit)
        if data ~= nil then
            self.mShowData = data
        end
        isInit = isInit or false
        if self.mShowData ~= nil then
            if self.mShowData.isMarch then
                -- 城外的队列显示
                self:_RefreshForMarch(isInit)
            else
                --城内队列的显示
                self:_RefreshForCity(isInit)
            end
        end
        self.mIsRefreshed = true
    end,

    _RefreshForMarch = function(self, isInit)
        local ccbfile = self:GetCCBFile()        
        if ccbfile == nil then return end

        UIExtend.setNodeVisible(ccbfile, 'mFreeAniCCB', false)
        UIExtend.setNodeVisible(ccbfile, 'mIdleNode', false)
        UIExtend.setNodeVisible(ccbfile, 'mBarNode', true)

        --设置起始时间和结束时间
        self.mStartTime = self.mShowData.queueStartTime / 1000
        self.mEndTime = self.mShowData.queueEndTime / 1000
        local lastTime = self.mEndTime - common:getCurTime()
        self:_RefreshTime(lastTime, not isInit)
    end,

    _RefreshForCity = function(self, isInit)
        local ccbfile = self:GetCCBFile()        
        if ccbfile == nil then return end

        if self.mShowData.queueId ~= 'defaultId' then
            --设置起始时间和结束时间
            self.mStartTime = self.mShowData.queueStartTime / 1000
            self.mEndTime = self.mShowData.queueEndTime / 1000
            local lastTime = self.mEndTime - common:getCurTime()            
            self:_RefreshTime(lastTime, not isInit)
        else
            self.mStartTime = -1
            self.mEndTime = -1
            self:_RefreshTime(-1, not isInit)
        end
    end,

    Execute = function(self)
        -- CCLuaLog("RAMainUIQueueCellNew:onExcute")
        if self:GetCCBFile() ~= nil and self.mShowData ~= nil and self.mIsRefreshed and self.mStartTime ~= -1 then
            local lastTime = self.mEndTime - common:getCurTime()
            if self.mLastTime > lastTime then
                -- Execute_Time_Gap                
                local currCCTime = CCTime:getCurrentTime() 
                if currCCTime - self.mLastExecuteTime > Execute_Time_Gap then
                    self:_RefreshTime(lastTime, true)
                    self.mLastExecuteTime = currCCTime
                end
            end
        end
    end,

    _RefreshTime = function(self, lastTime, isExecute)
        local ccbfile = self:GetCCBFile()
        if ccbfile == nil then return end
        if lastTime <= 0 then
            -- CCLuaLog('RAMainUIQueueCellNew:refreshTime arg error!!!!  lastTime = '.. lastTime)
            lastTime = 0
        end

        -- 绿色->帮助
        -- 蓝色->普通
        -- 橙色->免费
        if self.mShowData.isMarch then
            -- 城外的队列显示
            local totalTime = self.mShowData.marchJourneyTime / 1000
            if totalTime == 0 then
                totalTime = self.mEndTime - self.mStartTime
            end            
            local tmpStr = Utilitys.createTimeWithFormat(lastTime)
            UIExtend.setCCLabelString(ccbfile, "mCellTime", tmpStr)
            if lastTime <= 0 then
                UIExtend.setCCLabelString(ccbfile, "mCellTime", '')
            end
            -- 计算scale9缩放
            local percent = lastTime / totalTime
            if percent < 0 then percent = 0 end
            if percent > 1 then percent = 1 end

            UIExtend.setNodesVisible(ccbfile,{
                mOrangeBar = false,
                mFreeBtn = false,
                mGreenBar = false,
                mGreenBtn = false,
                mBlueBar = true,
                mBlueBtn = true,
                })
            
            -- UIExtend.setCCScale9ScaleByPercent(ccbfile, 'mBlueBar', 'mBarSizeNode', 1 - percent)    
            self:_HandleProgressBarScaleTo(ccbfile, 'mBlueBar', 1 - percent, isExecute)

            UIExtend.setControlButtonTitle(ccbfile, 'mBlueBtn', self.mShowData.queueBtnLabelKey)

            UIExtend.setCCLabelString(ccbfile, 'mCellLabel', _RALang(self.mShowData.queueLabelKey))

            UIExtend.removeSpriteFromNodeParent(ccbfile, 'mIconNode')
            UIExtend.addSpriteToNodeParent(ccbfile, 'mIconNode', self.mShowData.queueItemIcon)

            -- 驻扎中、援助中的时候，不显示进度条
            if self.mStartTime < 0 and self.mEndTime < 0 then
                UIExtend.setNodeVisible(ccbfile, 'mBlueBar', false)
            end
        else            
            UIExtend.setNodesVisible(ccbfile, {
                mOrangeBar = false,
                mFreeBtn = false,
                mGreenBar = false,
                mGreenBtn = false,
                mBlueBar = false,
                mBlueBtn = false,
                })
            UIExtend.setControlButtonTitle(ccbfile, 'mFreeBtn', '@Free')
            UIExtend.setControlButtonTitle(ccbfile, 'mBlueBtn', self.mShowData.queueBtnLabelKey)
            UIExtend.setControlButtonTitle(ccbfile, 'mGreenBtn', '@AllianceHelp')

            if self.mShowData.queueId == 'defaultId' then
                -- 闲置状态的科技
                UIExtend.setNodeVisible(ccbfile, 'mBarNode', false)
                UIExtend.setNodeVisible(ccbfile, 'mIdleNode', true)
                UIExtend.setNodeVisible(ccbfile, 'mFreeAniCCB', false)
                UIExtend.setCCLabelString(ccbfile, 'mIdleLabel', 
                    _RALang(self.mShowData.queueLabelKey, _RALang(self.mShowData.queueItemName)))

                UIExtend.setNodeVisible(ccbfile, 'mBlueBtn', true)
                UIExtend.setControlButtonTitle(ccbfile, 'mBlueBtn', self.mShowData.queueBtnLabelKey)                
            else
                -- 非闲置状态
                UIExtend.setNodeVisible(ccbfile, 'mIdleNode', false)
                UIExtend.setNodeVisible(ccbfile, 'mFreeAniCCB', false)
                UIExtend.setNodeVisible(ccbfile, 'mBarNode', true)
                local RAPlayerInfoManager = RARequire('RAPlayerInfoManager')
                local freeTime = RAPlayerInfoManager.getQueueFreeTime(nil, self.mShowData.queueType)
                local isFree = freeTime >= lastTime
                local handleBtnName = ''
                local handleBarName = ''
                local isShowBtn = true
                if isFree then
                    UIExtend.setNodeVisible(ccbfile, 'mFreeAniCCB', true)
                    if self.mIsFree ~= isFree then
                        --状态切换到免费的时候播放动画
                        local ccbFree = UIExtend.getCCBFileFromCCB(ccbfile, 'mFreeAniCCB')
                        if ccbFree ~= nil then
                            ccbFree:runAnimation('FreeInAni')
                        end                
                    end
                    self.mIsFree = isFree
                    handleBtnName = 'mFreeBtn'
                    handleBarName = 'mOrangeBar'
                else
                    --不免费的时候判断援助
                    UIExtend.setNodeVisible(ccbfile, 'mFreeAniCCB', false)                
                    local isCanHelp = RAQueueManager:isCanApplyHelp(self.mShowData.queueType, self.mShowData.queueId)
                    if isCanHelp then
                        --援助状态
                        handleBtnName = 'mGreenBtn'
                        handleBarName = 'mGreenBar'
                    else
                        --普通状态
                        handleBtnName = 'mBlueBtn'
                        handleBarName = 'mBlueBar'
                        local RAGuideManager = RARequire("RAGuideManager")
                        isShowBtn = RAGuideManager.canShowQueenBtn()
                    end
                end                
                UIExtend.setNodeVisible(ccbfile, handleBtnName, isShowBtn )
                UIExtend.setNodeVisible(ccbfile, handleBarName, true)

                local totalTime = 0
                if totalTime == 0 then
                    totalTime = self.mEndTime - self.mStartTime
                end            
                if tonumber(self.mShowData.queueTotalTime) > 0 then
                    totalTime = self.mShowData.queueTotalTime / 1000
                end
                local tmpStr = Utilitys.createTimeWithFormat(lastTime)
                UIExtend.setCCLabelString(ccbfile, "mCellTime", tmpStr)
                if lastTime <= 0 then
                    UIExtend.setCCLabelString(ccbfile, "mCellTime", '')
                end
                -- 计算scale9缩放
                local percent = lastTime / totalTime
                if percent < 0 then percent = 0 end
                if percent > 1 then percent = 1 end
                
                -- UIExtend.setCCScale9ScaleByPercent(ccbfile, handleBarName, 'mBarSizeNode', 1 - percent)
                self:_HandleProgressBarScaleTo(ccbfile, handleBarName, 1 - percent, isExecute)

                -- UIExtend.setControlButtonTitle(ccbfile, handleBtnName, self.mShowData.queueBtnLabelKey)

                UIExtend.setCCLabelString(ccbfile, 'mCellLabel', 
                    _RALang(self.mShowData.queueLabelKey, _RALang(self.mShowData.queueItemName)))

            end
            UIExtend.removeSpriteFromNodeParent(ccbfile, 'mIconNode')
            UIExtend.addSpriteToNodeParent(ccbfile, 'mIconNode', self.mShowData.queueItemIcon)
        end

        -- -- 计算特效位置
        -- local aniCCBFile = UIExtend.getCCBFileFromCCB(ccbfile, 'mBarAniCCB')
        -- if aniCCBFile ~= nil then
        --     aniCCBFile:setVisible(false)
        --     if lastTime > 0 and percent > 0 and percent <= 1 then
        --         local sizeNode = UIExtend.getCCNodeFromCCB(ccbfile, 'mBarSizeNode')
        --         if sizeNode ~= nil then
        --             local x, y = sizeNode:getPosition()
        --             local width = sizeNode:getContentSize().width
        --             local or_x, or_y = aniCCBFile:getPosition()
        --             local scaleX = aniCCBFile:getScaleX()
        --             local newX = x + width*(1-percent)
        --             aniCCBFile:setPosition(newX * scaleX, or_y)
        --             aniCCBFile:setVisible(true)
        --         end
        --     end
        -- end

        self.mLastTime = lastTime
    end,

    _HandleProgressBarScaleTo = function(self, ccbfile, nodeName, percent, isExecute)
        if ccbfile == nil then return end
        local node = UIExtend.getCCNodeFromCCB(ccbfile, nodeName)
        node:stopAllActions()
        local currScaleX = node:getScaleX()
        -- print('..................._HandleProgressBarScaleTo  curr scale:'..currScaleX..'  percent:'..percent)
        if currScaleX > percent or not isExecute then
            node:setScaleX(percent)
        else
            node:runAction(CCScaleTo:create(Execute_Time_Gap/1000, percent, 1))        
        end
    end,

    SetClickEnable = function(self, value)
        local ccbfile = self:GetCCBFile()
        if ccbfile == nil then return end
        UIExtend.setCCControlButtonEnable(ccbfile, 'mFreeBtn', value)
        UIExtend.setCCControlButtonEnable(ccbfile, 'mGreenBtn', value)
        UIExtend.setCCControlButtonEnable(ccbfile, 'mBlueBtn', value)
        UIExtend.setMenuItemEnable(ccbfile, 'mCellBtn', value)
    end,

    --点击按钮的一些操作逻辑方法
    _SpeedUpMarch = function(self, marchId)
        local RACommonGainItemData = RARequire('RACommonGainItemData')
        RARootManager.showCommonGainItemPage(RACommonGainItemData.GAIN_ITEM_TYPE.marchAccelerate, marchId)
    end,

    _WatchMarch = function(self, queueType, queueId, marchStatus, isShowHud) 
        if isShowHud == nil then isShowHud = true end
        -- 等待状态，且没有出发行军的时候，才打开集结页面
        if marchStatus == World_pb.MARCH_STATUS_WAITING then
            RARootManager.OpenPage("RANewAllianceWarPage")
        else
            if RARootManager:GetIsInWorld() then    
                local RAMarchManager = RARequire('RAMarchManager')
                local RAWorldManager = RARequire('RAWorldManager')
                local pos, isSuc, moveController = RAMarchManager:GetMarchMoveEntityTilePos(queueId)
                local isShowTileHud = isShowHud
                if moveController ~= nil then
                    isShowTileHud = false
                end
                RAWorldManager:LocateAt(pos.x, pos.y, nil, isShowTileHud)
                if moveController ~= nil and isShowHud then
                    moveController:ShowMoeveEntityHud()                
                end
            end
        end
    end,

    _CellBtnClickHandle = function(self)
        -- 根据具体情况确认
        if self.mShowData.isMarch then
            -- 城外跳转
            local marchStatus = self.mShowData.marchStatus
            local marchId = self.mShowData.queueId
            local marchType = self.mShowData.queueType
            local targetId = self.mShowData.targetId
            if marchStatus == World_pb.MARCH_STATUS_MARCH or
                marchStatus == World_pb.MARCH_STATUS_RETURN_BACK then
                -- 加速
                self:_WatchMarch(marchType, marchId, marchStatus)
            elseif marchStatus == World_pb.MARCH_STATUS_MARCH_COLLECT then
                --查看
                self:_WatchMarch(marchType, marchId, marchStatus)
            elseif marchStatus == World_pb.MARCH_STATUS_MARCH_QUARTERED then
                --查看
                self:_WatchMarch(marchType, marchId, marchStatus)
            elseif marchStatus == World_pb.MARCH_STATUS_WAITING then
                -- if self.mShowData.isMarchMassJoining then
                --     --查看                
                --     self:_WatchMarch(marchType, marchId, marchStatus)
                -- else
                --     -- 加速
                --     self:_SpeedUpMarch(targetId)
                -- end
                --查看                
                if RARootManager:GetIsInWorld() then    
                    local RAMarchManager = RARequire('RAMarchManager')
                    local RAWorldManager = RARequire('RAWorldManager')
                    local pos = RAMarchManager:GetMarchMoveEntityTilePos(marchId)
                    RAWorldManager:LocateAt(pos.x, pos.y)
                end
            elseif marchStatus == World_pb.MARCH_STATUS_MARCH_ASSIST then
                --援助中，召回
                -- RAWorldPushHandler:sendServerCalcCallBackReq(marchId)
                self:_WatchMarch(marchType, marchId, marchStatus)
            end
        else
            -- 城内跳转
            -- 科技、治疗类型的
            if self.mShowData.queueType == Const_pb.SCIENCE_QUEUE or 
                self.mShowData.queueType == Const_pb.CURE_QUEUE then
                local buildType = -1
                -- 科技
                if self.mShowData.queueType == Const_pb.SCIENCE_QUEUE then
                    buildType = Const_pb.FIGHTING_LABORATORY
                end
                -- 治疗
                if self.mShowData.queueType == Const_pb.CURE_QUEUE then
                    buildType = Const_pb.HOSPITAL_STATION
                end
                if buildType ~= -1 then
                    RABuildManager:showBuildingByBuildType(buildType)
                end
                return
            end
            
            --造兵队列
            if self.mShowData.queueType == Const_pb.SOILDER_QUEUE then
                local queueData = RAQueueManager:getQueueData(self.mShowData.queueType, self.mShowData.queueId)
                if queueData ~= nil then
                    RABuildManager:showBuildingByBuildType(tonumber(queueData.info))    
                end
            end

            -- 城建升级、防御武器升级修复
            if self.mShowData.queueType == Const_pb.BUILDING_QUEUE or 
                self.mShowData.queueType == Const_pb.BUILDING_DEFENER then                
                RABuildManager:showBuildingById(self.mShowData.queueItemId)
                return
            end

            -- 空闲科技队列
            local defaultType, defaultId = RAMainUIQueueDataManager:GetScieneDefaultQueueTypeAndId()
            if defaultType == self.mShowData.queueType then
                RABuildManager:showBuildingByBuildType(Const_pb.FIGHTING_LABORATORY)
            end
        end
    end,

    onCellBtn = function(self)        
        CCLuaLog("RAMainUIQueueCellNew:onCellBtn")
        local isCanClick = self:_CheckClickGapTime()
        if not isCanClick then return end
        
        self:_CellBtnClickHandle()
    end,

    onBlueBtn = function(self)
        CCLuaLog("RAMainUIQueueCellNew:onBlueBtn")
        local isCanClick = self:_CheckClickGapTime()
        if not isCanClick then return end
        -- 根据具体情况确认
        if self.mShowData.isMarch then
            -- 城外跳转
            local marchStatus = self.mShowData.marchStatus
            local marchId = self.mShowData.queueId
            local marchType = self.mShowData.queueType
            local targetId = self.mShowData.targetId
            if marchStatus == World_pb.MARCH_STATUS_MARCH or
                marchStatus == World_pb.MARCH_STATUS_RETURN_BACK then
                -- 加速
                self:_SpeedUpMarch(marchId)
                -- self:_WatchMarch(marchType, marchId, marchStatus, false)
            elseif marchStatus == World_pb.MARCH_STATUS_MARCH_COLLECT then
                --查看
                self:_WatchMarch(marchType, marchId, marchStatus)
            elseif marchStatus == World_pb.MARCH_STATUS_MARCH_QUARTERED then
                --查看
                self:_WatchMarch(marchType, marchId, marchStatus)
            elseif marchStatus == World_pb.MARCH_STATUS_WAITING then
                -- if self.mShowData.isMarchMassJoining then
                --     --查看                
                --     self:_WatchMarch(marchType, marchId, marchStatus)
                -- else
                --     -- 加速
                --     self:_SpeedUpMarch(targetId)
                -- end
                --查看 
                self:_WatchMarch(marchType, marchId, marchStatus)
            elseif marchStatus == World_pb.MARCH_STATUS_MARCH_ASSIST then
                --援助中，召回
                local RAWorldPushHandler = RARequire('RAWorldPushHandler')
                RAWorldPushHandler:sendServerCalcCallBackReq(marchId)
            end
        else
            -- 城内加速
            local queueData = RAQueueManager:getQueueData(self.mShowData.queueType, self.mShowData.queueId)
            if queueData == nil then
                self:_CellBtnClickHandle()
            else
                -- 加速
                local RARootManager = RARequire('RARootManager')
                RARootManager.showCommonItemsSpeedUpPopUp(queueData)
            end 
        end
    end,

    onGreenBtn = function(self)
        CCLuaLog("RAMainUIQueueCellNew:onGreenBtn")
        local isCanClick = self:_CheckClickGapTime()
        if not isCanClick then return end
        --请求联盟援助
        if self.mShowData.queueId ~= nil then
            local RAQueueUtility = RARequire('RAQueueUtility')
            local isCan = RAQueueUtility.isQueueTypeCanHelp(self.mShowData.queueType)
            if isCan then
                local RAAllianceProtoManager = RARequire('RAAllianceProtoManager')
                RAAllianceProtoManager:sendApplyHelpInfoReq(self.mShowData.queueId)                
            end
        end
    end,

    onFreeBtn = function(self)
        CCLuaLog("RAMainUIQueueCellNew:onFreeBtn")
        local isCanClick = self:_CheckClickGapTime()
        if not isCanClick then return end
        -- 免费完成
        if self.mShowData.queueType == Const_pb.BUILDING_QUEUE or self.mShowData.queueType == Const_pb.BUILDING_DEFENER then
            if self.mShowData.queueId ~= nil then
                RAQueueManager:sendQueueFreeFinish(self.mShowData.queueId)
                --如果是新手期，需要特殊处理
                local RAGuideManager = RARequire("RAGuideManager")
                if RAGuideManager.isInGuide() then
                    RARootManager.AddCoverPage()
                end
            end
        end
    end,

    _GetAnimationCmd = function(self, name)
        local ccbi = self:GetCCBFile()
        return function()
            ccbi:runAnimation(name)
        end
    end,

    -- 点击间隔判定方法
    _CheckClickGapTime = function(self)
        local timeDebug = CCTime:getCurrentTime()
        if timeDebug - self.mLastClickTime > CLICK_GAP_TIME then
            self.mLastClickTime = timeDebug
            return true
        end
        print('RAMainUIQueueCellNew click is cdddddd ing')
        return false
    end,

    RunAni = function(self, isShow, delay)
        local aniName = ''
        if isShow then   
            aniName = CCB_InAni         
        else
            aniName = CCB_OutAni
        end    
        if delay > 0 then
            performWithDelay(self:GetCCBFile(), self:_GetAnimationCmd(aniName), delay)
        else
            local cmd = self:_GetAnimationCmd(aniName)
            cmd()
        end
    end,

    getGuideFreeBtnInfo = function(self)
        local freeBtn = UIExtend.getCCControlButtonFromCCB(self.ccbfile, "mFreeBtn")
        
        if freeBtn then
            local pos = ccp(0, 0)
            pos.x, pos.y = freeBtn:getPosition()
            local contenSize = freeBtn:getContentSize()
            local worldPos = freeBtn:getParent():convertToWorldSpace(pos)
            pos:delete()
            return {["pos"] = worldPos, ["size"] = contenSize}
        end
        return nil
    end,

    OnAnimationDone = function(self, ccbfile)
        local lastAnimationName = ccbfile:getCompletedAnimationName()                
        if lastAnimationName == CCB_InAni or lastAnimationName == CCB_OutAni then
            if self.mAniCmpHandler ~= nil and self.mAniCmpHandler.CellAniEndCallBack ~= nil then
                self.mAniCmpHandler:CellAniEndCallBack(lastAnimationName, self.mCellId)
            end
        end

        --新手期普通建筑队列免费的处理
        if ((lastAnimationName == CCB_InAni and self.mIsFree) or lastAnimationName == "mFreeAniCCB_FreeInAni") and self.mShowData.queueType == Const_pb.BUILDING_QUEUE then
            --新手:建筑队列免费按钮出来后进行下一步
             local RAGuideManager = RARequire('RAGuideManager')
             local guideinfo = RAGuideManager.getConstGuideInfoById()

             if guideinfo ~= nil and guideinfo.btnType ~= nil then 
                 local info = self:getGuideFreeBtnInfo()
                 if info ~= nil then 
                     MessageManager.sendMessage(MessageDef_Building.MSG_Guide_Hud_BtnInfo,{pos = info.pos, size = info.size})
                 end 
             end 
        end
    end,

    Exit = function(self)
        self.mAniCmpHandler = nil
        self.mShowData = nil
        self.mCellId = nil         
        self.mIsFree = false
        self.mIsRefreshed = false
        UIExtend.unLoadCCBFile(self)
    end
}



------ btn cell
local RAMainUIQueueBtnCell = 
{
    new = function(self, o)
        o = o or {}
        setmetatable(o,self)
        self.__index = self    
        o.mIsVisible = false
        o.mAniCmpHandler = nil
        return o
    end,

    GetCCBName = function(self)
        return "RAMainUIQueueArrowAniNew.ccbi"
    end,

    GetCCBFile = function(self)
        return self.ccbfile
    end,

    Load = function(self, handler)
        local ccbi = UIExtend.loadCCBFile(self:GetCCBName(), self)
        if ccbi == nil then return end        
        self:SetVisible(false)
        self.mAniCmpHandler = handler
        return ccbi
    end,

    SetVisible = function(self, value)
        local ccbi = self:GetCCBFile()
        if ccbi == nil then value = false end
        self.mIsVisible = value
        if ccbi ~= nil then
            ccbi:setVisible(self.mIsVisible)
        end
    end,

    GetVisible = function(self)
        return self.mIsVisible
    end,    

    SetPositionY = function(self, posY)
        local ccbi = self:GetCCBFile()
        if ccbi == nil then return end
        if ccbi ~= nil then
            ccbi:setPositionY(posY)
        end
    end,

    -- 设置按钮可不可以点击
    -- 遮罩动画过程中不可以点击；动画完成后才可以点击
    SetClickEnable = function(self, value)
        local ccbi = self:GetCCBFile()
        if ccbi == nil then return end
        UIExtend.setMenuItemEnable(ccbi, 'mArrowBtn', value)
    end,

    SetTipsNumString = function(self, str)
        local ccbi = self:GetCCBFile()
        if ccbi == nil then return end
        UIExtend.setCCLabelString(ccbi, 'mTipsNum', str)        
        UIExtend.setNodeVisible(ccbi, 'mTipsNode', str ~= '')
    end,

    onArrowBtn = function(self)
        print('RAMainUIQueueBtnCell:onArrowBtn')
        if self.mAniCmpHandler ~= nil then
            self.mAniCmpHandler:ChangeCellOpenState()
        end
    end,

    _GetAnimationCmd = function(self, name)
        local ccbi = self:GetCCBFile()
        return function()
            ccbi:runAnimation(name)
        end
    end,

    RunAni = function(self, isOpen, isStatus)
        local ccbi = self:GetCCBFile()
        if ccbi == nil then return end
        if isStatus then
            if isOpen then
                ccbi:runAnimation(CCB_Btn_KeepOpen)
            else
                ccbi:runAnimation(CCB_Btn_KeepClose)
            end
        else
            if isOpen then
                ccbi:runAnimation(CCB_Btn_OpenAni)
            else
                ccbi:runAnimation(CCB_Btn_CloseAni)
            end 
        end   
    end,

    OnAnimationDone = function(self, ccbfile)
        local lastAnimationName = ccbfile:getCompletedAnimationName()                
        if self.mAniCmpHandler ~= nil and self.mAniCmpHandler.BtnCellAniEndCallBack ~= nil then
            self.mAniCmpHandler:BtnCellAniEndCallBack(lastAnimationName)
        end
    end,

    Exit = function(self)
        UIExtend.unLoadCCBFile(self)
    end
}





RAMainUIQueueShowHelper.mNode = nil

-- 当前所有添加进来的cell
RAMainUIQueueShowHelper.mCellList = nil
RAMainUIQueueShowHelper.mCellCount = 0

RAMainUIQueueShowHelper.mCellNeedRemove = nil


--用于标记当前所有cell是否整体显示出来
RAMainUIQueueShowHelper.mIsAllCellIn = false

--当前cell正在进行移动的个数（用于保证所有cell移动完成后才进行下一步）
RAMainUIQueueShowHelper.mCellChangeCount = 0

--单个cell改变的时候，目标cell的id
RAMainUIQueueShowHelper.mCurrCellChangingId = -1
--单个cell改变的时候，改变的行为类型
RAMainUIQueueShowHelper.mCurrCellChangingType = CellChangeType.None

-- 所有需要接下来刷新的数据
RAMainUIQueueShowHelper.mOneCellAniList = List:New()


-- 收缩按钮(不放在mCellList中)
RAMainUIQueueShowHelper.mBtnCell = nil
RAMainUIQueueShowHelper.mIsBtnCellShow = false

-- 用于标示当前是否是展开状态
RAMainUIQueueShowHelper.mIsOpening = false

-- clip node
RAMainUIQueueShowHelper.mClipNode = nil
-- stencil for clip node
RAMainUIQueueShowHelper.mStencilNode = nil

RAMainUIQueueShowHelper.mLastUpdateTime = 0

OnReceiveMessage = function(message)    
    CCLuaLog("RAMainUIPage OnReceiveMessage id:"..message.messageID)

    -- 新的队列UI，删除某个cell，防止崩溃
    if message.messageID == MessageDef_MainUI.MSG_UpdateMainUIQueueDelCell then
        CCLuaLog("MessageDef_Queue MSG_UpdateMainUIQueueDelCell")       
        RAMainUIQueueShowHelper:CheckAndRemoveCellNeed()
        return
    end

    -- open or close RAChooseBuildPage page
    if message.messageID == MessageDef_MainUI.MSG_UpdateMainUIQueuePart then
        CCLuaLog("MessageDef_MainUI MSG_UpdateMainUIQueuePart")
        local updateData = message.updateData
        if updateData then
            -- 0为刷新，1为新增，-1为删除
            local updateType = updateData.updateType
            -- 要操控的cell index
            local cellIndex = updateData.cellIndex or -1

            if updateType == 0 then
                RAMainUIQueueShowHelper:ChangeCellUpdate(updateData)
            end
        end
        return
    end

    --添加一个建筑的时候判断，是不是需要去增加空闲科技队列
    if message.messageID == MessageDef_MainUI.MSG_UpdateMainUIQueueAddBuild then
        CCLuaLog("MessageDef_Queue MSG_UpdateMainUIQueueAddBuild")        
        local buildType = message.buildType
        if buildType == Const_pb.FIGHTING_LABORATORY then
            local isNeedAdd = RAMainUIQueueDataManager:CheckIsNeedToShowScienDefaultQueue()
            if isNeedAdd then
                local defaultType, defaultId = RAMainUIQueueDataManager:GetScieneDefaultQueueTypeAndId()
                RAMainUIQueueShowHelper:HandleQueueMessage(CellChangeType.Add, defaultType, defaultId)
            end   
        end
        return
    end
    

    --特殊处理科技队列；
    --1、当添加一个科技队列的时候，要试着去移除闲置科技队列，然后再添加自身
    --2、当移除一个科技队列的时候，先移除自身，然后要试着去添加一个闲置科技队列

    --1的情况在进动画队列前处理
    --2的情况在移除科技的动画开始之后去添加

    local queueId = message.queueId
    local queueType = message.queueType
    local marchType = nil
    if queueType ~= nil and queueType == Const_pb.MARCH_QUEUE then
        marchType = message.marchType
    end
    if message.messageID == MessageDef_Queue.MSG_Common_ADD then
        CCLuaLog("MessageDef_Queue MSG_Common_ADD")
        if queueType == Const_pb.SCIENCE_QUEUE then
            local defaultType, defaultId = RAMainUIQueueDataManager:GetScieneDefaultQueueTypeAndId()
            local index, showData =  RAMainUIQueueDataManager:GetCityShowDataIndex(defaultType, defaultId)
            if index <= 0 or showData == nil then
                print('there is no default science queue')
            else
                print('remove default science queue')
                RAMainUIQueueShowHelper:HandleQueueMessage(CellChangeType.Remove, defaultType, defaultId)        
            end
        end        
        RAMainUIQueueShowHelper:HandleQueueMessage(CellChangeType.Add, queueType, queueId, marchType)
        return
    end

    if message.messageID == MessageDef_Queue.MSG_Common_UPDATE then
        CCLuaLog("MessageDef_Queue MSG_Common_UPDATE")        
        RAMainUIQueueShowHelper:HandleQueueMessage(CellChangeType.Update, queueType, queueId, marchType)
        return
    end

    if message.messageID == MessageDef_Queue.MSG_Common_DELETE then
        CCLuaLog("MessageDef_Queue MSG_Common_DELETE")        
        RAMainUIQueueShowHelper:HandleQueueMessage(CellChangeType.Remove, queueType, queueId, marchType)

        if queueType == Const_pb.SCIENCE_QUEUE then
            local isNeedAdd = RAMainUIQueueDataManager:CheckIsNeedToShowScienDefaultQueue()
            if isNeedAdd then
                local defaultType, defaultId = RAMainUIQueueDataManager:GetScieneDefaultQueueTypeAndId()
                RAMainUIQueueShowHelper:HandleQueueMessage(CellChangeType.Add, defaultType, defaultId)
            end           
        end
        return
    end

    if message.messageID == MessageDef_Queue.MSG_Common_CANCEL then
        CCLuaLog("MessageDef_Queue MSG_Common_CANCEL")        
        RAMainUIQueueShowHelper:HandleQueueMessage(CellChangeType.Remove, queueType, queueId, marchType)
        if queueType == Const_pb.SCIENCE_QUEUE then
            local isNeedAdd = RAMainUIQueueDataManager:CheckIsNeedToShowScienDefaultQueue()
            if isNeedAdd then
                local defaultType, defaultId = RAMainUIQueueDataManager:GetScieneDefaultQueueTypeAndId()
                RAMainUIQueueShowHelper:HandleQueueMessage(CellChangeType.Add, defaultType, defaultId)
            end           
        end
        return
    end    


    -- 后台回来之后，直接刷新
    -- 非重连暂时不做这个处理
    if message.messageID == MessageDef_MainState.EnterForeground then
        CCLuaLog("MessageDef_MainState.EnterForeground")        
        -- RAMainUIQueueShowHelper:ChangeAllCellShowStatus(true, true)
        return
    end    
    -- 重连之后，直接刷新
    if message.messageID == MessageDef_MainState.ReloginRefresh then
        CCLuaLog("MessageDef_MainState.ReloginRefresh")        
        RAMainUIQueueShowHelper:ChangeAllCellShowStatus(true, true)
        return
    end   
end

function RAMainUIQueueShowHelper:registerMessageHandlers()    
    MessageManager.registerMessageHandler(MessageDef_MainUI.MSG_UpdateMainUIQueueDelCell, OnReceiveMessage)

    MessageManager.registerMessageHandler(MessageDef_MainUI.MSG_UpdateMainUIQueuePart, OnReceiveMessage)
    MessageManager.registerMessageHandler(MessageDef_MainUI.MSG_UpdateMainUIQueueAddBuild, OnReceiveMessage)

    MessageManager.registerMessageHandler(MessageDef_Queue.MSG_Common_ADD, OnReceiveMessage)
    MessageManager.registerMessageHandler(MessageDef_Queue.MSG_Common_UPDATE, OnReceiveMessage)
    MessageManager.registerMessageHandler(MessageDef_Queue.MSG_Common_DELETE, OnReceiveMessage)
    MessageManager.registerMessageHandler(MessageDef_Queue.MSG_Common_CANCEL, OnReceiveMessage)

    MessageManager.registerMessageHandler(MessageDef_MainState.EnterForeground, OnReceiveMessage)
    MessageManager.registerMessageHandler(MessageDef_MainState.ReloginRefresh, OnReceiveMessage)
end

function RAMainUIQueueShowHelper:unregisterMessageHandlers()
    MessageManager.removeMessageHandler(MessageDef_MainUI.MSG_UpdateMainUIQueueDelCell, OnReceiveMessage)

    MessageManager.removeMessageHandler(MessageDef_MainUI.MSG_UpdateMainUIQueuePart, OnReceiveMessage)
    MessageManager.removeMessageHandler(MessageDef_MainUI.MSG_UpdateMainUIQueueAddBuild, OnReceiveMessage)

    MessageManager.removeMessageHandler(MessageDef_Queue.MSG_Common_ADD, OnReceiveMessage)
    MessageManager.removeMessageHandler(MessageDef_Queue.MSG_Common_UPDATE, OnReceiveMessage)
    MessageManager.removeMessageHandler(MessageDef_Queue.MSG_Common_DELETE, OnReceiveMessage)
    MessageManager.removeMessageHandler(MessageDef_Queue.MSG_Common_CANCEL, OnReceiveMessage)    

    MessageManager.removeMessageHandler(MessageDef_MainState.EnterForeground, OnReceiveMessage)
    MessageManager.removeMessageHandler(MessageDef_MainState.ReloginRefresh, OnReceiveMessage)
end


function RAMainUIQueueShowHelper:resetData(isClear)
    if self.mCellList ~= nil then
        for cellId, cell in pairs(self.mCellList) do
            cell:Exit()
        end
    end
    if self.mClipNode ~= nil then
        self.mClipNode:removeFromParentAndCleanup(true)
        self.mClipNode = nil
    end
    if self.mBtnCell ~= nil then
        self.mBtnCell:Exit()
        self.mBtnCell = nil
    end
    if self.mNode ~= nil then
        self.mNode:removeAllChildrenWithCleanup(true)
    end

    self.mStencilNode = nil
    self.mCellList = nil
    self.mCellCount = 0
    self.mIsBuyCellShow = false
    if isClear then
        self.mNode = nil
    end

end


function RAMainUIQueueShowHelper:Enter(data)
    self:resetData(true)
    CCLuaLog("RAMainUIQueueShowHelper:Enter")

    self.mCellNeedRemove = {}

    if data ~= nil then
        self.mNode = data.queueNode
    end
    if self.mIsBuyCellShow == nil then
        self.mIsBuyCellShow = false
    end

    EnterFrameMananger.registerEnterFrameHandler(EnterFrameDefine.MainUI.EF_QueueHelperUpdate, self)
    self:registerMessageHandlers()   

    self.mClipNode = CCClippingNode:create()
    self.mClipNode:setAnchorPoint(0.5, 0.5)
    self.mClipNode:setPosition(0, 0)
    self.mNode:addChild(self.mClipNode)

    self.mStencilNode = CCSprite:create('empty.png')   
    self.mStencilNode:setAnchorPoint(0, 1)
    self.mStencilNode:setPosition(0, 0)
    self.mClipNode:setStencil(self.mStencilNode)
end


-- 刷新cell的显示，设置为收缩状态
function RAMainUIQueueShowHelper:RefreshQueueAllCells()
     if self.mCellList ~= nil then
        for cellId, cell in pairs(self.mCellList) do
            cell:Exit()
        end
    end
    self.mOneCellAniList = List:New()
    self.mCellList = {}
    self.mCellCount = 0
    self.mCellChangeCount = 0
    self.mCurrCellChangingId = -1
    self.mCurrCellChangingType = CellChangeType.None

    self.mStencilNode:setScaleX(0) 
    self.mStencilNode:setScaleY(0)

    -- init data需要二级遍历
    local initDatas = nil
    if RARootManager.GetIsInWorld() then
        initDatas = RAMainUIQueueDataManager:GetWorldAllData(true)
    else
        initDatas = RAMainUIQueueDataManager:GetCityAllData(true)
    end

    for i=1,#initDatas do
        -- 一级数据格式
        -- local oneData = {
        --     isShow = false,
        --     queueList = {},
        --     realCount = 0, 
        --     queueType = queueType,
        --     index = index
        -- }
        local oneData = initDatas[i]
        if oneData.isShow then
            for j=1, #oneData.queueList do
                self.mCellCount = self.mCellCount + 1
                local showData = oneData.queueList[j]
                local cell = RAMainUIQueueCellNew:new(
                {
                    mCellId = self.mCellCount,
                    mShowData = showData
                })
                local ccbi = cell:Load(self)
                local posY = (1 - self.mCellCount) * MainUI_Queue_One_Cell_Height
                ccbi:setPositionY(posY)
                self.mClipNode:addChild(ccbi)        
                self.mCellList[self.mCellCount] = cell
            end
        end
    end

    self:_UpdateBtnCell()
    self:_UpdateClipNode()
end

------------------------ Queue Cell Handle ----------------------------------
------------------------------------------------------------------------------


-- 切换或者进入场景的时候会调用，整体进入或者移出cell
function RAMainUIQueueShowHelper:ChangeAllCellShowStatus(isShow, isForce)
    local isForce = isForce or false
    if not isForce then
        if self.mCellChangeCount > 0 then
            CCLuaLog("RAMainUIQueueShowHelper cell is moving count:"..self.mCellChangeCount)
            return
        end
        if self.mIsAllCellIn == isShow then
            return
        end
    end
    self.mIsAllCellIn = isShow
    -- 如果要整体进入的时候，刷新所有数据，先隐藏按钮，播放动画完毕后再显示
    if self.mIsAllCellIn then
        self:RefreshQueueAllCells()
        if self.mBtnCell ~= nil then
            self.mBtnCell:SetVisible(false)
        end
    else
        self:_UpdateBtnCell()
        -- self:_UpdateClipNode()
    end

    local cellCount = 0
    for i=1,#self.mCellList do
        local cell = self.mCellList[i]
        self.mCellChangeCount = self.mCellChangeCount + 1
        cell:RunAni(self.mIsAllCellIn, delayGap * cellCount)
        cellCount = cellCount + 1
    end
end


function RAMainUIQueueShowHelper:HandleQueueMessage(changeType, queueType, queueId, marchType)
    --处理类型区分，如果城内，不处理城外类型；如果在城外，不处理城内类型
    local sceneType = RARootManager.GetCurrScene()
    local isHandle = RAMainUIQueueDataManager:CheckIsHandleQueue(queueType, sceneType)
    if not isHandle then        
        return
    end

    --特殊处理科技队列；
    --1、当添加一个科技队列的时候，要试着去移除闲置科技队列，然后再添加自身
    --2、当移除一个科技队列的时候，先移除自身，然后要试着去添加一个闲置科技队列

    --1的情况在进动画队列前处理
    --2的情况在移除科技的动画开始之后去添加


    -- 如果当前正在播动画的时候就加到队列里
    if self.mCellChangeCount > 0 or self.mCurrCellChangingType ~= CellChangeType.None then
        local cellAniData = {
            changeType = changeType,
            queueType = queueType,
            queueId = queueId,
            marchType = marchType,
        }
        self.mOneCellAniList:PushEnd(cellAniData)        
        return
    end

    if changeType == CellChangeType.Add then
         if marchType == nil then
            --城内
            RAMainUIQueueDataManager:GetCityAllData(true)
            local index, showData = RAMainUIQueueDataManager:GetCityShowDataIndex(queueType, queueId)
            if index <= 0 or showData == nil then
                print('RAMainUIQueueShowHelper:HandleQueueMessage addddd  error')
            else
                self:_ChangeOneCellShowStatus(index, changeType, showData)
            end
        else
            --城外
            RAMainUIQueueDataManager:GetWorldAllData(true)
            local index, showData = RAMainUIQueueDataManager:GetWorldShowDataIndex(marchType, queueId)
            if index <= 0 or showData == nil then
                print('RAMainUIQueueShowHelper:HandleQueueMessage addddd  error')
            else
                self:_ChangeOneCellShowStatus(index, changeType, showData)
            end
        end
        return

    elseif changeType == CellChangeType.Remove then
        local cellIdRemove = 0
        if self.mCellList == nil then return end
        
        if marchType == nil then
            --城内
            for k,cell in pairs(self.mCellList) do
                if cell ~= nil and
                    cell.mShowData.queueType == queueType and 
                    cell.mShowData.queueId == queueId then
                    cellIdRemove = cell.mCellId
                    break
                end            
            end
            local index, showData = RAMainUIQueueDataManager:GetCityShowDataIndex(queueType, queueId)
            if index ~= cellIdRemove then
                print('RAMainUIQueueShowHelper:HandleQueueMessage Remove  error;.......index not correct')            
            end
            if cellIdRemove > 0 then            
                RAMainUIQueueDataManager:GetCityAllData(true)
                self:_ChangeOneCellShowStatus(cellIdRemove, changeType, nil)
            end
        else
            --城外
            for k,cell in pairs(self.mCellList) do
                if cell ~= nil and
                    cell.mShowData.queueType == marchType and 
                    cell.mShowData.queueId == queueId then
                    cellIdRemove = cell.mCellId
                    break
                end            
            end
            local index, showData = RAMainUIQueueDataManager:GetWorldShowDataIndex(marchType, queueId)
            if index ~= cellIdRemove then
                print('RAMainUIQueueShowHelper:HandleQueueMessage Remove  error;.......index not correct')            
            end
            if cellIdRemove > 0 then      
                RAMainUIQueueDataManager:GetWorldAllData(true)      
                self:_ChangeOneCellShowStatus(cellIdRemove, changeType, nil)
            end
        end
        return

    elseif changeType == CellChangeType.Update then
        --update不调用动画的方法了就
        if marchType == nil then
            --城内
            RAMainUIQueueDataManager:GetCityAllData(true)
            local index, showData = RAMainUIQueueDataManager:GetCityShowDataIndex(queueType, queueId)
            local cellUpdate = self.mCellList[index]            
            if cellUpdate ~= nil and 
                cellUpdate.mShowData.queueType == showData.queueType and 
                cellUpdate.mShowData.queueId == showData.queueId then
                cellUpdate:RefreshCell(showData)
            else
                print('RAMainUIQueueShowHelper:HandleQueueMessage Update!')
                print('error error error error: index is not correct')
                for k,cell in pairs(self.mCellList) do
                    if cell ~= nil and
                        cell.mShowData.queueType == queueType and 
                        cell.mShowData.queueId == queueId then
                        cell:RefreshCell(showData)
                        break
                    end    
                end
            end
        else
            --城外
            RAMainUIQueueDataManager:GetWorldAllData(true)
            local index, showData = RAMainUIQueueDataManager:GetWorldShowDataIndex(marchType, queueId)
            local cellUpdate = self.mCellList[index]            
            if cellUpdate ~= nil and 
                cellUpdate.mShowData.queueType == showData.queueType and 
                cellUpdate.mShowData.queueId == showData.queueId then
                cellUpdate:RefreshCell(showData)
            else
                print('RAMainUIQueueShowHelper:HandleQueueMessage Update!')
                print('error error error error: index is not correct')
                for k,cell in pairs(self.mCellList) do
                    if cell ~= nil and
                        cell.mShowData.queueType == marchType and 
                        cell.mShowData.queueId == queueId then
                        cell:RefreshCell(showData)
                        break
                    end    
                end
            end
        end
        return

    end
end



-- changeType :CellChangeType
function RAMainUIQueueShowHelper:_ChangeOneCellShowStatus(cellId, changeType, showData)
    
    print('RAMainUIQueueShowHelper:_ChangeOneCellShowStatus, handle id:'..cellId..'  changeType:'..changeType)    
    self.mCurrCellChangingId = cellId
    self.mCurrCellChangingType = changeType
    self.mCellChangeCount = 0
    if changeType == CellChangeType.Remove then
        local cellRemove = self.mCellList[self.mCurrCellChangingId]
        if cellRemove ~= nil then
            self.mCellChangeCount = self.mCellChangeCount + 1
            cellRemove:RunAni(false, 0)
            
            -- 把大于当前要添加到的索引的所有cell，都向前移一位
            for i=self.mCellCount, self.mCurrCellChangingId + 1, -1 do
                local cellNeedMove = self.mCellList[i]
                local moveToId = i - 1
                if cellNeedMove ~= nil then
                    
                    -- local upAni = RAActionManager:CreateCCBAnimationContainer(
                    --     cellNeedMove:GetCCBFile(), 'RAMainUIQueueCellAni.ccbi', 
                    --     'mCellNode', CCB_UpAni)
                    -- upAni:setAniCallBackHandler(self)        
                    self.mCellChangeCount = self.mCellChangeCount + 1
                    -- upAni:beginAni()                    

                    local callBack = CCCallFunc:create(function()
                        self:_OnOneCellCCBAniComplete(-1)
                    end)
                    local posY = (1 - moveToId) * MainUI_Queue_One_Cell_Height
                    local moveTo = CCMoveTo:create(_CellUpDownAniTime, ccp(0, posY))    
                    cellNeedMove:GetCCBFile():stopAllActions()            
                    cellNeedMove:GetCCBFile():runAction(CCSequence:createWithTwoActions(moveTo, callBack))
                end        
            end

            -- 如果当前是在城内，且不是收缩状态，那么按钮需要向上移
            if not RARootManager.GetIsInWorld() and self.mBtnCell ~= nil and self.mIsOpening then
                -- local btnUpAni = RAActionManager:CreateCCBAnimationContainer(
                --     self.mBtnCell:GetCCBFile(), 'RAMainUIQueueCellAni.ccbi', 
                --     'mCellNode', CCB_UpAni)
                -- btnUpAni:setAniCallBackHandler(self)        
                self.mCellChangeCount = self.mCellChangeCount + 1
                -- btnUpAni:beginAni()

                local callBack = CCCallFunc:create(function()
                    self:_OnOneCellCCBAniComplete(-1)
                end)
                local posY = (1 - self.mCellCount) * MainUI_Queue_One_Cell_Height
                local moveTo = CCMoveTo:create(_CellUpDownAniTime, ccp(0, posY))          
                self.mBtnCell:GetCCBFile():stopAllActions()      
                self.mBtnCell:GetCCBFile():runAction(CCSequence:createWithTwoActions(moveTo, callBack))
            end
            print('remove ani cell changing count = '..self.mCellChangeCount)
        else
            print('want to remove id= '..self.mCurrCellChangingId.. ', but not found')
            self.mCurrCellChangingId = -1
            self.mCurrCellChangingType = CellChangeType.None
            self.mCellChangeCount = 0
            self:_CheckAndPlayOneCellAniInList()
        end
    elseif changeType == CellChangeType.Add then   
        -- 延迟播放进入动画的时间，如果没有添加任何一个其他动画的时候，值为0(立即播放)
        local addCellDelay = 0
        -- 把大于等于当前要添加到的索引的所有cell，都向后移一位
        for i=self.mCellCount, self.mCurrCellChangingId, -1 do
            local cellNeedMove = self.mCellList[i]
            local moveToId = i + 1
            if cellNeedMove ~= nil then
                self.mCellList[moveToId] = cellNeedMove
                cellNeedMove.mCellId = moveToId
                -- local downAni = RAActionManager:CreateCCBAnimationContainer(
                --     cellNeedMove:GetCCBFile(), 'RAMainUIQueueCellAni.ccbi', 
                --     'mCellNode', CCB_DownAni)
                -- downAni:setAniCallBackHandler(self)        
                self.mCellChangeCount = self.mCellChangeCount + 1
                -- downAni:beginAni()
                
                local callBack = CCCallFunc:create(function()
                        self:_OnOneCellCCBAniComplete(-1)
                    end)
                local posY = (1 - moveToId) * MainUI_Queue_One_Cell_Height
                local moveTo = CCMoveTo:create(_CellUpDownAniTime, ccp(0, posY))      
                cellNeedMove:GetCCBFile():stopAllActions()                 
                cellNeedMove:GetCCBFile():runAction(CCSequence:createWithTwoActions(moveTo, callBack))
            end            

            addCellDelay = _CellUpDownAniTime
        end

        local cellAdd = RAMainUIQueueCellNew:new(
        {
            mCellId = self.mCurrCellChangingId,
            mShowData = showData
        })
        local ccbi = cellAdd:Load(self)
        local posY = (1 - self.mCurrCellChangingId) * MainUI_Queue_One_Cell_Height
        ccbi:setPositionY(posY)
        self.mClipNode:addChild(ccbi)        
        self.mCellList[self.mCurrCellChangingId] = cellAdd
        self.mCellCount = Utilitys.table_count(self.mCellList)

        --需要立即刷新遮罩大小
        self:_UpdateClipNode(false)

        -- 如果当前是在城内，且不是收缩状态，那么按钮需要向下移
        if not RARootManager.GetIsInWorld() and self.mBtnCell ~= nil and self.mIsOpening then
            -- local btnDownAni = RAActionManager:CreateCCBAnimationContainer(
            --     self.mBtnCell:GetCCBFile(), 'RAMainUIQueueCellAni.ccbi', 
            --     'mCellNode', CCB_DownAni)
            -- btnDownAni:setAniCallBackHandler(self)        
            self.mCellChangeCount = self.mCellChangeCount + 1
            -- btnDownAni:beginAni()

            local callBack = CCCallFunc:create(function()
                    self:_OnOneCellCCBAniComplete(-1)
                end)
            local posY = (-self.mCellCount) * MainUI_Queue_One_Cell_Height
            local moveTo = CCMoveTo:create(_CellUpDownAniTime, ccp(0, posY))       
            self.mBtnCell:GetCCBFile():stopAllActions()               
            self.mBtnCell:GetCCBFile():runAction(CCSequence:createWithTwoActions(moveTo, callBack))

            addCellDelay = _CellUpDownAniTime
        end

        

        -- 播放进入动画
        self.mCellChangeCount = self.mCellChangeCount + 1
        cellAdd:RunAni(true, addCellDelay)

        print('add ani cell changing count = '..self.mCellChangeCount)

    elseif changeType == CellChangeType.Update then

    end
end


-- 使用 RAActionManager:CreateCCBAnimationContainer 的回调执行方法
function RAMainUIQueueShowHelper:onCCBContainerCallBack(lastAnimationName, aniCcbfile, isEnd)
    if isEnd then
        self:_OnOneCellCCBAniComplete(-1)
    end
end

function RAMainUIQueueShowHelper:_OnOneCellCCBAniComplete(changeCount)
    if self.mCurrCellChangingType ~= CellChangeType.None and  self.mCellChangeCount > 0 then
        print('RAMainUIQueueShowHelper:_OnOneCellCCBAniComplete curr count:'..self.mCellChangeCount.. ' '..changeCount)
        self.mCellChangeCount = self.mCellChangeCount + changeCount
        if self.mCellChangeCount == 0 then
            print('RAMainUIQueueShowHelper:_OnOneCellCCBAniComplete changing count = 0, type='..self.mCurrCellChangingType)
            if self.mCurrCellChangingType == CellChangeType.Remove then
                self:_LogicAfterOneCellOutAni()
            elseif self.mCurrCellChangingType == CellChangeType.Add then
                self:_LogicAfterOneCellInAni()
            end
        end
    end
end

function RAMainUIQueueShowHelper:_CheckAndPlayOneCellAniInList()
    local nextAni = self.mOneCellAniList:PopFront()
    if nextAni ~= nil then
        print('RAMainUIQueueShowHelper:_CheckAndPlayOneCellAniInList')
        self:HandleQueueMessage(nextAni.changeType, nextAni.queueType, nextAni.queueId, nextAni.marchType)
    end
end


-- 单个cell的时间轴播放完毕的回调
function RAMainUIQueueShowHelper:CellAniEndCallBack(aniName, cellId)    
    if cellId ~= nil then
        if self.mCurrCellChangingType == CellChangeType.None then
            local checkIsHandle = function(aniName, isIn)
                local isHandle = false
                if isIn and aniName == CCB_InAni then                
                    isHandle = true
                end
                
                if not isIn and aniName == CCB_OutAni then                
                    isHandle = true
                end
                return isHandle
            end
            local isHandle = checkIsHandle(aniName, self.mIsAllCellIn)
            if isHandle then
                self.mCellChangeCount = self.mCellChangeCount - 1
                print("cell handle over, cout:"..self.mCellChangeCount)
            end
            -- 等于0的时候
            if self.mCellChangeCount == 0 then
                print('RAMainUIQueueShowHelper:CellAniEndCallBack over')            
                -- 如果是进入，需要重新刷一下按钮的位置和状态
                if self.mIsAllCellIn then
                    self:_UpdateBtnCell()
                    self:_CheckAndPlayOneCellAniInList()
                else
                    self:_UpdateClipNode()
                end                
            end
        else
            if self.mCurrCellChangingType == CellChangeType.Add then
                -- 如果是单个cell的进入
                if aniName == CCB_InAni then
                    print('RAMainUIQueueShowHelper:CellAniEndCallBack curr count:'..self.mCellChangeCount.. ' -1')
                    self.mCellChangeCount = self.mCellChangeCount - 1
                end
                 -- 等于0的时候
                if self.mCellChangeCount == 0 then
                    print('RAMainUIQueueShowHelper:CellAniEndCallBack changing count = 0, type='..self.mCurrCellChangingType)
                    self:_LogicAfterOneCellInAni()
                end
            elseif self.mCurrCellChangingType == CellChangeType.Remove then
                if aniName == CCB_OutAni then
                    print('RAMainUIQueueShowHelper:CellAniEndCallBack curr count:'..self.mCellChangeCount.. ' -1')
                    self.mCellChangeCount = self.mCellChangeCount - 1
                end
                --移除cell的时候，在这里删除cell
                if self.mCellChangeCount == 0 then                     
                    print('RAMainUIQueueShowHelper:CellAniEndCallBack changing count = 0, type='..self.mCurrCellChangingType)
                    self:_LogicAfterOneCellOutAni()
                end
            else
                print('to dooooooooooooooooo')
            end
        end
    end
end

--添加cell的时候，在动画结束后处理逻辑
--1、当添加第一个cell的时候，
--   可能不存在 RACCBAnimationContainer 的动画，那么直接在CellAniEndCallBack中调用
--2、当添加cell 到其他位置的时候，
--   往往在 RACCBAnimationContainer 的动画结束的回调中调用
function RAMainUIQueueShowHelper:_LogicAfterOneCellInAni()
    self:_UpdateBtnCell(true)
    self.mCurrCellChangingId = -1            
    self.mCurrCellChangingType = CellChangeType.None
    self:_CheckAndPlayOneCellAniInList()
end

--移除cell的时候，在动画结束后处理逻辑
--1、当移除最后一个cell的时候，
--   可能不存在 RACCBAnimationContainer 的动画，那么直接在CellAniEndCallBack中调用
--2、当移除中间的某一个cell的时候，
--   往往在 RACCBAnimationContainer 的动画结束的回调中调用
function RAMainUIQueueShowHelper:_LogicAfterOneCellOutAni()
    print('RAMainUIQueueShowHelper:_LogicAfterOneCellOutAni want to remove :'..self.mCurrCellChangingId)
    local cellRemove = self.mCellList[self.mCurrCellChangingId]
    if cellRemove == nil then 
        print('iiiiiiiiiiiiddddddddddddddddddd not found!!!!!!!!!!')        
    else
        -- cellRemove:Exit()        
        table.insert(self.mCellNeedRemove, cellRemove)
        MessageManager.sendMessage(MessageDef_MainUI.MSG_UpdateMainUIQueueDelCell)
    end
    self.mCellList[self.mCurrCellChangingId] = nil                
    -- 把大于当前要添加到的索引的所有cell，都向前移一位
    for i=self.mCurrCellChangingId + 1, self.mCellCount do
        local cellNeedMove = self.mCellList[i]
        local moveToId = i - 1
        if cellNeedMove ~= nil then
            self.mCellList[moveToId] = cellNeedMove
            cellNeedMove.mCellId = moveToId
        end
    end
    --移除最后一个重复cell
    self.mCellList[self.mCellCount] = nil
    self.mCellCount = Utilitys.table_count(self.mCellList)
    --需要立即刷新遮罩大小和按钮状态
    self:_UpdateClipNode(false)
    self:_UpdateBtnCell(true)

    self.mCurrCellChangingId = -1            
    self.mCurrCellChangingType = CellChangeType.None
    self:_CheckAndPlayOneCellAniInList()
end


function RAMainUIQueueShowHelper:CheckAndRemoveCellNeed()
    print('function RAMainUIQueueShowHelper:CheckAndRemoveCellNeed()')
    if self.mCellNeedRemove ~= nil then        
        for _, cell in pairs(self.mCellNeedRemove) do
            if cell ~= nil then
                cell:Exit()
                print('remove &&&&&&&&&& one cell')
            end
        end
    end
end


------------------------ Queue Cell Handle end -------------------------------
------------------------------------------------------------------------------

------------------------ Button Cell Handle ----------------------------------
------------------------------------------------------------------------------
-- 返回是否显示按钮cell，按钮cell的位置（也是遮罩的大小）
function RAMainUIQueueShowHelper:_GetBtnCellShowData()
    local posY = 0
    local isShowBtn = false
    if self.mCellCount > 0 then
        posY = -self.mCellCount * MainUI_Queue_One_Cell_Height
    end
    if RARootManager.GetIsInWorld() then
        return false, posY
    end

    if self.mCellCount > MainUI_Queue_Cell_Show_Count then
        if not self.mIsOpening then
            posY = -MainUI_Queue_Cell_Show_Count * MainUI_Queue_One_Cell_Height            
        end
        isShowBtn = true
    else
        isShowBtn = false
    end
    if not self.mIsAllCellIn then
        isShowBtn = false
    end
    return isShowBtn, posY
end

-- 检查并创建、刷新点击按钮cell
function RAMainUIQueueShowHelper:_UpdateBtnCell(isIgnorePos)
    local isIgnorePos = isIgnorePos or false
    if self.mNode == nil then return end 
    if self.mBtnCell == nil then
        self.mBtnCell = RAMainUIQueueBtnCell:new()
        local ccbi = self.mBtnCell:Load(self)        
        self.mNode:addChild(ccbi)
        self.mBtnCell:RunAni(self.mIsOpening, true)
    end
    local isShow, posY = self:_GetBtnCellShowData()
    if isShow and not self.mBtnCell:GetVisible() then
        self.mBtnCell:SetPositionY(posY)
    end
    self.mBtnCell:SetVisible(isShow)
    if not isIgnorePos then
        self.mBtnCell:SetPositionY(posY)
    end
    local tipsNumStr = ''
    if not self.mIsOpening then
        --关闭状态的时候
        tipsNumStr = tostring(self.mCellCount - MainUI_Queue_Cell_Show_Count)
    end
    self.mBtnCell:SetTipsNumString(tipsNumStr)
end
-- 刷新遮罩大小
function RAMainUIQueueShowHelper:_UpdateClipNode(isAni)
    if self.mClipNode == nil or self.mStencilNode == nil then return end
    local isShow, posY = self:_GetBtnCellShowData()
    posY = math.abs(posY)
    self.mStencilNode:stopAllActions()
    self.mStencilNode:setScaleX(MainUI_Queue_One_Cell_Width) 
    if isAni then
        local scaleAction = CCScaleTo:create(_ClipNodeActionTimeNeed, MainUI_Queue_One_Cell_Width, posY)
        self.mStencilNode:runAction(scaleAction)
    else
        self.mStencilNode:setScaleY(posY)
        self.mBtnCell:SetClickEnable(true)
    end
    self:_UpdateCellCanClick()
end

--点击按钮切换收缩和放开状态调用的方法
function RAMainUIQueueShowHelper:ChangeCellOpenState()
    if RARootManager.GetIsInWorld() then
        self.mIsOpening = true
    else
        -- 先设置状态，再播放时间轴和遮罩动画
        self.mIsOpening = not self.mIsOpening
        -- 需要打开的时候，先设置位置，再播两个动画
        if self.mIsOpening then
            self:_UpdateBtnCell()
        end
        self.mBtnCell:SetClickEnable(false)
        self.mBtnCell:RunAni(self.mIsOpening)        
        self:_UpdateClipNode(true)
    end
end
-- 按钮点击后转圈动画结束后的回调
function RAMainUIQueueShowHelper:BtnCellAniEndCallBack(aniName)
    if self.mIsOpening and aniName == CCB_Btn_OpenAni then
        self.mBtnCell:SetClickEnable(true)
    end

    if not self.mIsOpening and aniName == CCB_Btn_CloseAni then
        --关闭的时候，先播完动画，再来设置位置
        self:_UpdateBtnCell()
        self.mBtnCell:SetClickEnable(true)        
    end
end

function RAMainUIQueueShowHelper:_UpdateCellCanClick()
    -- 收缩状态的设置不可见的cell不可点击        
    for cellId,cell in pairs(self.mCellList) do
        local isClick = true
        if RARootManager.GetIsInWorld() then
        	isClick = true
    	else
	        if not self.mIsOpening then
	            if cellId > MainUI_Queue_Cell_Show_Count then
	                isClick = false
	            end
	        end
	    end
        if cell ~= nil then
            cell:SetClickEnable(isClick)
        end
    end
end

------------------------------------------------------------------------------
------------------------ Button Cell Handle End ------------------------------

function RAMainUIQueueShowHelper:EnterFrame()
    -- CCLuaLog("RAMainUIQueueShowHelper:EnterFrame")
    self.mLastUpdateTime = self.mLastUpdateTime + common:getFrameTime()
    if self.mLastUpdateTime > 1 then
        self.mLastUpdateTime = 0
        for id, cell in pairs(self.mCellList) do                
            if cell ~= nil then
                cell:Execute()
            end
        end
    end
end

function RAMainUIQueueShowHelper:Exit()
    CCLuaLog("RAMainUIQueueShowHelper:Exit")
    self:unregisterMessageHandlers()
    EnterFrameMananger.removeEnterFrameHandler(EnterFrameDefine.MainUI.EF_QueueHelperUpdate, self)
    self:resetData(true)
end



return RAMainUIQueueShowHelper