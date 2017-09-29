RARequire("BasePage")
local RATaskManager = RARequire("RATaskManager")
local RAGameConfig = RARequire("RAGameConfig")
local UIExtend = RARequire("UIExtend")
local mission_conf = RARequire("mission_conf")
local Utilitys = RARequire("Utilitys")
local RAResManager = RARequire("RAResManager")
local RARootManager = RARequire("RARootManager")
local RANetUtil = RARequire("RANetUtil")
local item_conf = RARequire("item_conf")
local RALogicUtil = RARequire("RALogicUtil")


local RATaskDetailPage = BaseFunctionPage:new(...)


-------------------------------------------------------------
local RARewardCellListener = {
    rewardInfo = nil
}
function RARewardCellListener:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    return o
end

function RARewardCellListener:onRefreshContent(ccbRoot)
    local ccbfile = ccbRoot:getCCBFileNode()
    if ccbfile then
         --Ìí¼ÓÆ·ÖÊ¿ò
        if (tonumber(self.rewardInfo.mainType)*0.0001) == Const_pb.TOOL then
            local constItemInfo = item_conf[tonumber(self.rewardInfo.id)]
            if constItemInfo then
                local qualityIcon = RALogicUtil:getItemBgByColor(constItemInfo.item_color)
                UIExtend.addSpriteToNodeParent(ccbfile, "mIconNode", qualityIcon,nil, nil, 20000)
            end
        else
            UIExtend.addSpriteToNodeParent(ccbfile, "mIconNode", "Common_u_Quality_04.png",nil, nil, 20000)
        --    UIExtend.removeSpriteFromNodeParent(ccbfile, "mIconNode", 20000)
        end

        local icon, name = RAResManager:getIconByTypeAndId(tonumber(self.rewardInfo.mainType), tonumber(self.rewardInfo.id))
        UIExtend.addSpriteToNodeParent(ccbfile, "mIconNode", icon)
        UIExtend.setCCLabelString(ccbfile, "mCellName", _RALang(name))
        UIExtend.setCCLabelString(ccbfile, "mRewardCount", self.rewardInfo.count)
    end
end
-------------------------------------------------------------

RATaskDetailPage.taskId = 0
RATaskDetailPage.scrollView = nil
function RATaskDetailPage:Enter(data)
    self.ccbfile = UIExtend.loadCCBFile("RAQuestDetailsPage.ccbi", RATaskDetailPage)
    RATaskDetailPage.taskId = data.taskId
    RATaskDetailPage.scrollView = UIExtend.getCCScrollViewFromCCB(self.ccbfile, "mRewardListSV")
    self:refreshUI()
end

function RATaskDetailPage:refreshUI()
    self.scrollView:removeAllCell()
    local taskInfo = RATaskManager.getOneTaskInfo(self.taskId)
    local constTaskInfo = mission_conf[self.taskId]
    if taskInfo and constTaskInfo then

        local ccb = UIExtend.getCCBFileFromCCB(self.ccbfile, "mCommonTitle")
        if ccb then
            UIExtend.setCCLabelString(ccb, "mTitle", _RALang("@Task"))
            UIExtend.setNodeVisible(ccb, "mDiamondsNode", false)
        end
        local taskType = taskInfo.taskType
        if taskType == RAGameConfig.TaskType.Common then
            UIExtend.setCCLabelString(self.ccbfile, "mQuestType", _RALang("@CommonQuest"))
        elseif taskType == RAGameConfig.TaskType.Recommand then
            UIExtend.setCCLabelString(self.ccbfile, "mQuestType", _RALang("@CommendedQuest"))
        end

        UIExtend.setCCLabelString(self.ccbfile, "mQuestTitle", _RALang(constTaskInfo.name))
        UIExtend.setCCLabelString(self.ccbfile, "mQuestExplain", _RALang(constTaskInfo.des))


        local currCount = taskInfo.taskCompleteNum
        local maxCount = constTaskInfo.funVal
        local countStr = currCount .. "/" .. maxCount
        UIExtend.setCCLabelString(self.ccbfile, "mQuestNum", countStr)

        local currPercent = currCount / maxCount
        local progressBarPic = UIExtend.getCCSpriteFromCCB(self.ccbfile, "mCommendedQuestBar")
        local progressTimerBar = CCProgressTimer:create(progressBarPic)
        progressTimerBar:setPercentage(currPercent * 100)
        local progressNode = UIExtend.getCCNodeFromCCB(self.ccbfile, "mProgressNode")
        if progressNode then
            progressNode:removeAllChildrenWithCleanup(true)
            progressNode:addChild(progressTimerBar)
        end
        progressBarPic:setVisible(false)

        local mainIcon = constTaskInfo.icon1
        local slaveIcon = constTaskInfo.icon2
        if mainIcon then
            UIExtend.addSpriteToNodeParent(self.ccbfile, "mIconNode", mainIcon)
        end
        if slaveIcon then
            UIExtend.addSpriteToNodeParent(self.ccbfile, "mIconNode2", slaveIcon)
        end

        local rewardStr = constTaskInfo.rewardShow
        local rewardsArray = Utilitys.Split(rewardStr, ",")
        for k, rewardStr in ipairs(rewardsArray) do
            local rewardArr = Utilitys.Split(rewardStr, "_")
            local rewardTable = {}
            rewardTable.mainType = rewardArr[1]
            rewardTable.id = rewardArr[2]
            rewardTable.count = rewardArr[3]
            local listener = RARewardCellListener:new({rewardInfo = rewardTable})
            local cell = CCBFileCell:create()
            cell:setCCBFile("RAQuestDetailsCell.ccbi")
            cell:registerFunctionHandler(listener)
            self.scrollView:addCell(cell)
        end
        self.scrollView:orderCCBFileCells(140)

        if taskInfo.taskState == RAGameConfig.TaskStatus.Complete then
            UIExtend.setCCControlButtonEnable(self.ccbfile, "mReceiveBtn", true)
        else
            UIExtend.setCCControlButtonEnable(self.ccbfile, "mReceiveBtn", false)
        end
    else
        CCLuaLog("The taskId is illegal")
    end
end

function RATaskDetailPage:onReceive()
    local taskInfo = RATaskManager.getOneTaskInfo(self.taskId)

    if taskInfo then
        local msg = Mission_pb.MissionBonusReq()
        msg.missionId = taskInfo.missionId
        RANetUtil:sendPacket(HP_pb.MISSION_BONUS_C, msg)   
        RARootManager.ClosePage("RATaskDetailPage")
    else
        CCLuaLog("RATaskDetailPage:onReceive can not get taskIndo by taskId ".. self.taskId)
    end
end


function RATaskDetailPage:mCommonTitle_onBack()
    RARootManager.ClosePage("RATaskDetailPage")
end

function RATaskDetailPage:Exit()
     if self.scrollView then
        self.scrollView:removeAllCell()
        self.scrollView = nil
    end
    UIExtend.unLoadCCBFile(RATaskDetailPage)
    self.ccbfile = nil
end