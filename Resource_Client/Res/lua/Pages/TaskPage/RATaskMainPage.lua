RARequire("BasePage")
local UIExtend = RARequire("UIExtend")
local RATaskManager = RARequire("RATaskManager")
local Utilitys = RARequire("Utilitys")
local mission_conf = RARequire("mission_conf")
local RAResManager = RARequire("RAResManager")
local RAGameConfig = RARequire("RAGameConfig")
local RANetUtil = RARequire("RANetUtil")
local RARootManager = RARequire("RARootManager")
local RABuildManager = RARequire("RABuildManager")
local item_conf = RARequire("item_conf")
local RAGuideManager = RARequire("RAGuideManager")
local guide_conf = RARequire("guide_conf")
local mission_tab_conf = RARequire('mission_tab_conf')
local html_zh_cn = RARequire("html_zh_cn")
local RALogicUtil = RARequire("RALogicUtil")
local RAStringUtil = RARequire("RAStringUtil")
local ScrollViewAnimation = RARequire('ScrollViewAnimation')

local RATaskMainPage = BaseFunctionPage:new(...)
RATaskMainPage.scrollView = nil
RATaskMainPage.recommandTaskInfo = nil
RATaskMainPage.rewardNode = nil--显示奖励的node
RATaskMainPage.netHandler = {}
RATaskMainPage.rewardTaskId = 0--领奖任务id
RATaskMainPage.showRewardCCBIndex = -1--0是推荐任务，1-4是普通任务


---------------------------------------------------------
local RACommonTaskListListener = {}
function RACommonTaskListListener:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    return o
end

function RACommonTaskListListener:onRefreshContent(ccbRoot)
    local ccbfile = ccbRoot:getCCBFileNode()
    self.ccbfile = ccbfile
    if ccbfile then
        UIExtend.handleCCBNode(ccbfile)
        -- UIExtend.setCCControlButtonEnable(self.ccbfile, "mRewardBtn", true)
        -- UIExtend.setCCControlButtonEnable(self.ccbfile, "mQuestBtn", true)
        local taskTypeInfo = mission_tab_conf[self.Index]
        if taskTypeInfo then
            --UIExtend.setCCLabelString(ccbfile, "mQuestType", _RALang("@CommonQuest"))
            --review task module,modify by dylan 
            local titleStr = _RALang(taskTypeInfo.name)
            UIExtend.setCCLabelString(ccbfile, "mOthertasks", titleStr)

            UIExtend.addSpriteToNodeParent(ccbfile, "mIconBG", taskTypeInfo.icon,nil, nil, 20000)
            local arrow = UIExtend.getCCSpriteFromCCB(self.ccbfile,"mArrow")
            local close = RATaskMainPage:getTabStatue(self.Index)
            if close then
                arrow:setRotation(0)
            else
                arrow:setRotation(90)
            end

        else
            CCLuaLog("There is no const taskTypeInfo!")
        end     
    else 
        CCLuaLog("The ccbfile is empty!")
    end
end


function RACommonTaskListListener:onUnFold()
    MessageManager.sendMessage(MessageDef_Task.MSG_RefreshTaskList , {tabIndex = self.Index})
    -- RARootManager.OpenPage("RATaskDetailPage", {taskId = self.taskInfo.taskId}, false, true, false)
end

function RACommonTaskListListener:onQuestBtn()
    UIExtend.setCCControlButtonEnable(self.ccbfile, "mQuestBtn", false)

    MessageManager.sendMessage(MessageDef_Task.MSG_GotoTarget, {taskId = self.taskInfo.taskId})
--    RARootManager.ClosePage("RATaskMainPage")
--    if constTaskInfo then    
--        RATaskManager.gotoTaskTarget(constTaskInfo)
--    end
end

function RACommonTaskListListener:onRewardBtn()
    UIExtend.setCCControlButtonEnable(self.ccbfile, "mRewardBtn", false)
    local msg = Mission_pb.MissionBonusReq()
    msg.missionId = self.taskInfo.missionId
    RANetUtil:sendPacket(HP_pb.MISSION_BONUS_C, msg)
    --self.ccbfile:runAnimation("FinishAni")
    RATaskMainPage.rewardTaskId = self.taskInfo.taskId
    RATaskMainPage.showRewardCCBIndex = self.rewardIndex--设置播放动画的ccb索引
end
-----

---------------------------------------------------------
local RACommonTaskCellListener = {}
function RACommonTaskCellListener:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    return o
end

function RACommonTaskCellListener:onRefreshContent(ccbRoot)
    local ccbfile = ccbRoot:getCCBFileNode()
    self.ccbfile = ccbfile
    if ccbfile then
        UIExtend.handleCCBNode(ccbfile)

        local constTaskInfo = mission_conf[self.taskInfo.taskId]
        if constTaskInfo then
            local titleStr = _RALang(constTaskInfo.name)
            UIExtend.setCCLabelString(ccbfile, "mQuestTitle", titleStr)

            local currCount = self.taskInfo.taskCompleteNum
            local maxCount = constTaskInfo.funVal
            -- local countStr = currCount .. "/" .. maxCount
            UIExtend.setCCControlButtonEnable(self.ccbfile, "mGoBet", true)
            UIExtend.setControlButtonTitle(ccbfile,"mGoBet","")

            if self.taskInfo.taskState == RAGameConfig.TaskStatus.CanAccept then
                if constTaskInfo.goTo then
                    UIExtend.setCCLabelString(ccbfile, "mGet", _RALang("@Goto"))        
                else
                    UIExtend.setCCLabelString(ccbfile, "mGet", "")        
                end
            elseif self.taskInfo.taskState == RAGameConfig.TaskStatus.Complete then
                UIExtend.setCCLabelString(ccbfile, "mGet", _RALang("@TaskRewardBtnLabel"))        
            end


            

            local countPercent = currCount / maxCount
            if countPercent > 1 then countPercent = 1 end
            local tmpSprite = UIExtend.getCCScale9SpriteFromCCB(ccbfile, "mBar")
            tmpSprite:setScaleX(countPercent)

            local cursor = UIExtend.getCCSpriteFromCCB(ccbfile,"mCursor")
            local posX = tmpSprite:getContentSize().width*countPercent
            local spriteWidth = tmpSprite:getContentSize().width
            local width = cursor:getContentSize().width
            if posX < width then
                cursor:setPositionX(posX -spriteWidth/2)
                cursor:setScaleX(posX/width)
            else
                cursor:setScaleX(1)
                cursor:setPositionX(posX - spriteWidth/2)
            end
        end
    else 
        CCLuaLog("The ccbfile is empty!")
    end
end


function RACommonTaskCellListener:onGoBet()

    
end


function RACommonTaskCellListener:onGoBet(sender)
    -- self:resetCellStatus()

    local event=sender:getControlBtnEvent()
    local gotosp = UIExtend.getCCScale9SpriteFromCCB(self.ccbfile, "mBar")
    if event==CCControlEventTouchDown then
        gotosp:setColor(ccc3(128, 128, 128))
    else 
        gotosp:setColor(ccc3(255, 255, 255)) 
    end 
    if  event~=CCControlEventTouchUpInside then
        return
    end
    local constTaskInfo = mission_conf[self.taskInfo.taskId]
    if constTaskInfo then
        if self.taskInfo.taskState == RAGameConfig.TaskStatus.CanAccept then
            if constTaskInfo.goTo then
                UIExtend.setCCControlButtonEnable(self.ccbfile, "mGoBet", false)
                MessageManager.sendMessage(MessageDef_Task.MSG_GotoTarget, {taskId = self.taskInfo.taskId})         
            end
        elseif self.taskInfo.taskState == RAGameConfig.TaskStatus.Complete then
            self:onRewardBtn()
        end  
    end  
end
function RACommonTaskCellListener:onQuestBtn()
    UIExtend.setCCControlButtonEnable(self.ccbfile, "mQuestBtn", false)

    MessageManager.sendMessage(MessageDef_Task.MSG_GotoTarget, {taskId = self.taskInfo.taskId})
--    RARootManager.ClosePage("RATaskMainPage")
--    if constTaskInfo then    
--        RATaskManager.gotoTaskTarget(constTaskInfo)
--    end
end

function RACommonTaskCellListener:onRewardBtn()
    UIExtend.setCCControlButtonEnable(self.ccbfile, "mGoBet", false)
    local msg = Mission_pb.MissionBonusReq()
    msg.missionId = self.taskInfo.missionId
    RANetUtil:sendPacket(HP_pb.MISSION_BONUS_C, msg)
    --self.ccbfile:runAnimation("FinishAni")
    RATaskMainPage.rewardTaskId = self.taskInfo.taskId
    RATaskMainPage.showRewardCCBIndex = self.rewardIndex--设置播放动画的ccb索引
end
---------------------------------------------------------


function RATaskMainPage:Enter(data)
    self.ccbfile =  UIExtend.loadCCBFile("RAQuestPageNew.ccbi", RATaskMainPage)
    self.scrollView = UIExtend.getCCScrollViewFromCCB(self.ccbfile, "mQuestListSV")

    ScrollViewAnimation.init(self)

    --播放音效 by phan
    local common = RARequire("common")
    common:playEffect("click_main_botton_banner")

    self:refreshUI()
    self:registerHandler()

    RAGuideManager.gotoNextStep()

end

function RATaskMainPage:Execute()
    ScrollViewAnimation.update()
end


function RATaskMainPage:refreshUI()
    -- UIExtend.setCCLabelString(self.ccbfile, "mMainLineTitle", _RALang("@CommendedQuest"))
    -- UIExtend.setCCLabelString(self.ccbfile, "mMainQuestTitle", _RALang("@CommonQuest"))
    self:refreshTitle()    
    self:refreshRecommandTask()
    self:refreshCommonTask()
end

local onReceiveMessage = function(msg)
    if msg.messageID == MessageDef_Task.MSG_RefreshTaskUITask then
        RATaskMainPage:refreshUI()
    elseif msg.messageID == MessageDef_Task.MSG_ShowTaskReward then
        RATaskMainPage:showRewardUI() 
    elseif msg.messageID == MessageDef_Task.MSG_GotoTarget then
        local taskId = msg.taskId
        local constTaskInfo = mission_conf[taskId]
        RARootManager.ClosePage("RATaskMainPage")
        if constTaskInfo then    
            RATaskManager.gotoTaskTarget(constTaskInfo)
        end
    elseif msg.messageID == MessageDef_Task.MSG_RefreshTaskList then
        local tabIndex = msg.tabIndex
        RATaskMainPage:setTabStatue(tabIndex)
    end
end

function RATaskMainPage:showRewardUI()
    if self.rewardTaskId ~=0 then
        local constTaskInfo = mission_conf[self.rewardTaskId]
        if constTaskInfo then
            local rewardStr = constTaskInfo.rewardShow
            local rewardsArray = Utilitys.Split(rewardStr, ",")
--            local data = {}
--            data.text = ""
--            for i=1, #rewardsArray do
--                local rewardArray = Utilitys.Split(rewardsArray[i], "_")
--                local mainType = rewardArray[1]
--                local rewardId = rewardArray[2]
--                local rewardCount = rewardArray[3]

--                local _, name = RAResManager:getIconByTypeAndId(mainType, rewardId)

--                --获得品质
--                local colorIndex = COLOR_TYPE.PURPLE
--                if (tonumber(mainType)*0.0001) == Const_pb.TOOL then
--                    local constItemInfo = item_conf[tonumber(rewardId)]
--                    if constItemInfo then
--                        colorIndex = constItemInfo.item_color
--                    end
--                end

--                local desStr = RAStringUtil:getHTMLString("RewardDes"..colorIndex)
--                if desStr then
--                    local countStr = RAStringUtil:getLanguageString("@GetResNum", rewardCount)
--                    desStr = RAStringUtil:fill(desStr, _RALang(name), countStr)
--                    data.text = data.text .. desStr
--                end
--            end

--            data.icon = constTaskInfo.icon1
--            data.title = "@GetTaskReward"
--            local pos = ccp(0, 0)
--            data.pos = pos
--            local rewardUI = dynamic_require("RARewardPage")
--            rewardUI:Enter(data)
--            UIExtend.AddPageToNode(rewardUI,self.rewardNode)

            RARootManager.ShowCommonReward(rewardsArray, false)
            
        end
    end

end

function RATaskMainPage:registerHandler()
    MessageManager.registerMessageHandler(MessageDef_Task.MSG_RefreshTaskUITask, onReceiveMessage)
    MessageManager.registerMessageHandler(MessageDef_Task.MSG_ShowTaskReward, onReceiveMessage)
    MessageManager.registerMessageHandler(MessageDef_Task.MSG_GotoTarget, onReceiveMessage)
    MessageManager.registerMessageHandler(MessageDef_Task.MSG_RefreshTaskList, onReceiveMessage)
    

end

function RATaskMainPage:unRegiterHandler()
    MessageManager.removeMessageHandler(MessageDef_Task.MSG_RefreshTaskUITask, onReceiveMessage)  
    MessageManager.removeMessageHandler(MessageDef_Task.MSG_ShowTaskReward, onReceiveMessage)  
    MessageManager.removeMessageHandler(MessageDef_Task.MSG_GotoTarget, onReceiveMessage)  
    MessageManager.removeMessageHandler(MessageDef_Task.MSG_RefreshTaskList, onReceiveMessage)
    
end

function RATaskMainPage:refreshTitle()
    local titleCCB = UIExtend.getCCBFileFromCCB(self.ccbfile, "mCommonTitleCCB")
    if titleCCB then
        UIExtend.setCCLabelString(titleCCB, "mTitle", _RALang("@Task"))
        -- UIExtend.setNodeVisible(titleCCB, "mDiamondsNode", false)
    end


    -- local RACommonTitleHelper = RARequire('RACommonTitleHelper')
    -- local backCallBack = function()
    --     RARootManager.ClosePage("RATaskMainPage") 
    -- end
    -- local diamondCallBack = function()
    --     local RARealPayManager = RARequire('RARealPayManager')
    --     RARealPayManager:getRechargeInfo()
    -- end

    -- local titleHandler = RACommonTitleHelper:RegisterCommonTitle('RATaskMainPage', 
    -- titleCCB, _RALang("@Task"), backCallBack, RACommonTitleHelper.BgType.Blue)
    -- titleHandler:SetCallBack(RACommonTitleHelper.TitleCallBack.Diamonds, diamondCallBack)    
end

function RATaskMainPage:refreshRecommandTask()
    local recomandTaskInfo = RATaskManager.getRecommandTask()
    if recomandTaskInfo then
        -- UIExtend.setNodeVisible(self.ccbfile,"mMainLineNode", true)
        -- UIExtend.setCCControlButtonEnable(self.ccbfile, "mQuestGotoBtn", true)
        -- UIExtend.setCCControlButtonEnable(self.ccbfile, "mReceiveBtn", true)
        RATaskMainPage.recommandTaskInfo = recomandTaskInfo
        local constTaskInfo = mission_conf[recomandTaskInfo.taskId]
        if constTaskInfo then
            local titleStr = _RALang(constTaskInfo.name)
            UIExtend.setCCLabelString(self.ccbfile, "mMainLineTitle", titleStr)
            
            local currCount = recomandTaskInfo.taskCompleteNum
            local maxCount = constTaskInfo.funVal
            local countStr = currCount .. "/" .. maxCount
            --UIExtend.setCCLabelString(self.ccbfile, "mQuestNum", countStr)

            --local countPercent = currCount / maxCount
            --local tmpSprite = UIExtend.getCCSpriteFromCCB(self.ccbfile, "mCommendedQuestBar")
            --local progressTimerBar = CCProgressTimer:create(tmpSprite)
            --progressTimerBar:setPercentage(countPercent * 100)
            --local progressNode = UIExtend.getCCNodeFromCCB(self.ccbfile, "mProgressNode")
            --progressNode:removeAllChildrenWithCleanup(true)
            --progressNode:addChild(progressTimerBar)
            --tmpSprite:setVisible(false)

            local mainIcon = constTaskInfo.icon1
            local slaveIcon = constTaskInfo.icon2
            if mainIcon then
                UIExtend.addSpriteToNodeParent(self.ccbfile, "mIcon", mainIcon)
            end
            -- if slaveIcon then
            --     UIExtend.addSpriteToNodeParent(self.ccbfile, "mIcon", slaveIcon)
            -- end

            local rewardStr = constTaskInfo.rewardShow
            local rewardsArray = Utilitys.Split(rewardStr, ",")

            local arrSize=table.maxn(rewardsArray)
            if arrSize>3 then
                arrSize=3
                CCLuaLog("!!!!Warnning!!!!RATaskMainPage|MainLineQuest Config Reward Size > 3 ,task id "..tostring(recomandTaskInfo.taskId))
            end
            
            for i=1, 3 do
                local nodeKey="mRewardNode"..i
                if i > arrSize then
                    UIExtend.setNodeVisible(self.ccbfile,nodeKey, false)
                else
                    UIExtend.setNodeVisible(self.ccbfile,nodeKey, true)
                end 
                if rewardsArray[i] and i<=arrSize then
                        local rewardArray = Utilitys.Split(rewardsArray[i], "_")
                        local mainType = rewardArray[1]
                        local rewardId = rewardArray[2]
                        local rewardCount = rewardArray[3]

                        --添加品质框
                        -- if (tonumber(mainType)*0.0001) == Const_pb.TOOL then
                        --     local constItemInfo = item_conf[tonumber(rewardId)]
                        --     if constItemInfo then
                        --         local qualityIcon = RALogicUtil:getItemBgByColor(constItemInfo.item_color)
                        --         UIExtend.addSpriteToNodeParent(self.ccbfile, "mQuestTask"..i, qualityIcon,nil, nil, 20000)
                        --     end
                        -- else
                        --     -- UIExtend.addSpriteToNodeParent(self.ccbfile, "mQuestTask"..i, "Common_u_Quality_04.png",nil, nil, 20000)
                        --     -- UIExtend.removeSpriteFromNodeParent(rewardCCBFile, "mIconNode", 20000)
                        -- end
                        --设置icon
                        local icon, _ = RAResManager:getQuestIcon(tonumber(mainType), tonumber(rewardId))
                        print("icon = ",icon)
                        UIExtend.addSpriteToNodeParent(self.ccbfile, "mQuestTask"..i, icon)
                        UIExtend.setCCLabelString(self.ccbfile, "mIconNum"..i, rewardCount)
                end
            end
            UIExtend.setCCControlButtonEnable(self.ccbfile, "mGetBtn", true)
            mGetBtn=UIExtend.getCCControlButtonFromCCB(self.ccbfile, "mGetBtn")
            if recomandTaskInfo.taskState == RAGameConfig.TaskStatus.CanAccept then
                if constTaskInfo.goTo then
                    mGetBtn:setVisible(true)
                    UIExtend.setControlButtonTitle(self.ccbfile, "mGetBtn", _RALang("@Goto"))
                else
                    mGetBtn:setVisible(false)
                end
            elseif recomandTaskInfo.taskState == RAGameConfig.TaskStatus.Complete then
                mGetBtn:setVisible(true)
                UIExtend.setControlButtonTitle(self.ccbfile, "mGetBtn", _RALang("@TaskRewardBtnLabel"))
            end
        else
            CCLuaLog("The task id is error!")
            -- UIExtend.setNodeVisible(self.ccbfile,"mMainLineNode", false)
        end
    else
        CCLuaLog("There is no recommand task!")
        -- UIExtend.setNodeVisible(self.ccbfile,"mMainLineNode", false)
    end
end

function RATaskMainPage:getTabStatue( Index )
    return self.commonTasksInfo[Index] and self.commonTasksInfo[Index].close
end

function RATaskMainPage:setTabStatue( Index )
    if Index and self.commonTasksInfo[Index] then
        self.commonTasksInfo[Index].close = not self.commonTasksInfo[Index].close
        self:refreshCommonSV()
    end
end

function RATaskMainPage:refreshCommonTask()
    self.commonTasksInfo = RATaskManager.getCommonTasks()
    ScrollViewAnimation.clearTable()
    self.tabStatue = {}
    if self.commonTasksInfo then
        self.scrollView:removeAllCell()
        local listener,cell
        for k,taskTypeList in pairs(self.commonTasksInfo) do
            taskTypeList.close = true
            listener = RACommonTaskListListener:new({taskTypeList = taskTypeList, Index= k})
            cell = CCBFileCell:create()
            cell:setCCBFile("RAQuestCellNew.ccbi")
            cell:registerFunctionHandler(listener)
            self.scrollView:addCell(cell)
            --ScrollViewAnimation.addToTable(cell)
        end

        -- for k, commonTaskInfo in ipairs(commonTasksInfo) do
        --     local listener = RACommonTaskCellListener:new({taskInfo = commonTaskInfo, rewardIndex= k})
        --     local cell = CCBFileCell:create()
        --     cell:setCCBFile("RAQuestPageCell.ccbi")
        --     cell:registerFunctionHandler(listener)
        --     self.scrollView:addCell(cell)
        --     --ScrollViewAnimation.addToTable(cell)
        -- end
        self.scrollView:orderCCBFileCells()
        --ScrollViewAnimation.runGetIn()
--        performWithDelay(self.scrollView,function()

--        end,0.1)
        
    end
end


function RATaskMainPage:refreshCommonSV(  )
    local preOffest=self.scrollView:getContentOffset()
    local listener,cell
    self.scrollView:removeAllCell()

    for k,taskTypeList in pairs(self.commonTasksInfo) do
        listener = RACommonTaskListListener:new({taskTypeList = taskTypeList, Index= k})
        cell = CCBFileCell:create()
        cell:setCCBFile("RAQuestCellNew.ccbi")
        cell:registerFunctionHandler(listener)
        self.scrollView:addCell(cell)
        if not taskTypeList.close then
            for i,taskInfo in ipairs(taskTypeList) do
                listener = RACommonTaskCellListener:new({taskInfo = taskInfo, rewardIndex = i})
                cell = CCBFileCell:create()
                cell:setCCBFile("RAQuestUnfoldNewCell.ccbi")
                cell:registerFunctionHandler(listener)
                cell:setZOrder(-i)
                self.scrollView:addCell(cell)
            end
        end
        --ScrollViewAnimation.addToTable(cell)
    end
    self.scrollView:orderCCBFileCells()
    -- self.alliacneScrollView:refreshAllCell()
    -- self.scrollView:setContentOffset(preOffest)    
end



function RATaskMainPage:onQuestGotoBtn()
    local constTaskInfo = mission_conf[self.recommandTaskInfo.taskId]
    UIExtend.setCCControlButtonEnable(self.ccbfile, "mQuestGotoBtn", false)
    RARootManager.ClosePage("RATaskMainPage")
    if constTaskInfo then
        RATaskManager.gotoTaskTarget(constTaskInfo)
    end
end

--获得奖励
function RATaskMainPage:onReceiveBtn()
    UIExtend.setCCControlButtonEnable(self.ccbfile, "mGetBtn", false)
    local msg = Mission_pb.MissionBonusReq()
    msg.missionId = self.recommandTaskInfo.missionId
    RANetUtil:sendPacket(HP_pb.MISSION_BONUS_C, msg)
    self.rewardTaskId = self.recommandTaskInfo.taskId--保存领奖的任务id
    self.showRewardCCBIndex = 0--设置播放动画的ccb索引
    --self.ccbfile:runAnimation("FinishAni")
end

function RATaskMainPage:mCommonTitleCCB_onBack()
    RARootManager.ClosePage("RATaskMainPage")
end

function RATaskMainPage:onGetBtn()
    local recomandTaskInfo = self.recommandTaskInfo
    local constTaskInfo = mission_conf[recomandTaskInfo.taskId]
    if constTaskInfo then    
        if recomandTaskInfo.taskState == RAGameConfig.TaskStatus.CanAccept then
            if constTaskInfo.goTo then
                UIExtend.setCCControlButtonEnable(self.ccbfile, "mGetBtn", false)
                MessageManager.sendMessage(MessageDef_Task.MSG_GotoTarget, {taskId = recomandTaskInfo.taskId})   
            end
        elseif recomandTaskInfo.taskState == RAGameConfig.TaskStatus.Complete then
            self:onReceiveBtn()
        end
    end
end


function RATaskMainPage:Exit(data)
    local RACommonTitleHelper = RARequire('RACommonTitleHelper')
	RACommonTitleHelper:RemoveCommonTitle("RATaskMainPage")

    --播放音效 by phan
    local common = RARequire("common")
    common:playEffect("click_main_botton_banner_back")

    self.rewardNode = nil--显示奖励的node
    self:unRegiterHandler()
    self.rewardTaskId = 0--领奖任务id
    self.showRewardCCBIndex = -1--0是推荐任务，1-4是普通任务
    self.recommandTaskInfo = nil
    if self.scrollView then
        self.scrollView:removeAllCell()
        self.scrollView = nil
    end
    UIExtend.unLoadCCBFile(RATaskMainPage)
    ScrollViewAnimation.clearTable()
    self.ccbfile = nil
end