local raTaskInfo = RARequire("RATaskInfo")
local mission_conf = RARequire("mission_conf")
local RAGameConfig = RARequire("RAGameConfig")
local Utilitys = RARequire("Utilitys")
local RARootManager = RARequire("RARootManager")
local guide_conf = RARequire("guide_conf")
local RABuildManager = RARequire("RABuildManager")
local RAGuideManager = RARequire("RAGuideManager")
local World_pb = RARequire("World_pb")
local RAScenesMananger = RARequire("RAScenesMananger")

local RATaskManager = {}

--������������
local RATaskGotoType =
{
    Task_Upgrade = 0,
    Task_ChooseBuild = 1,
    Task_TechLevel = 10,
    Task_TechCount = 11,
    Task_TrainSoldier = 20,
    Task_RightTrainSoldier = 22,
    Task_UpgradeResBuild = 30,
    Task_CollectResCount = 31,
    Task_AttackMonster = 50,
    Task_KillMonster = 51,
    Task_FightCount = 61
} 

package.loaded[...] = RATaskManager

--����������Ϣ
function RATaskManager.setTaskInfo(msg)
    if raTaskInfo then
        raTaskInfo.recommandTasks = {}
        raTaskInfo.commonTasks = {}

        for i=1, #msg.list do
            local missionInfo = msg.list[i]

            local taskId = missionInfo.cfgId
            local constTaskInfo = mission_conf[taskId]
            if constTaskInfo then
                if constTaskInfo.order1 then
                    --�Ƽ�����
                    local key = #raTaskInfo.recommandTasks + 1
                    raTaskInfo.recommandTasks[key] = {}
                    raTaskInfo.recommandTasks[key].taskId = taskId
                    raTaskInfo.recommandTasks[key].taskState = missionInfo.state
                    raTaskInfo.recommandTasks[key].taskCompleteNum = missionInfo.num
                    raTaskInfo.recommandTasks[key].taskType = RAGameConfig.TaskType.Recommand
                    raTaskInfo.recommandTasks[key].missionId = missionInfo.missionId

                elseif constTaskInfo.order2 then
                    --��ͨ����
                    local key = #raTaskInfo.commonTasks + 1
                    raTaskInfo.commonTasks[key] = {}
                    raTaskInfo.commonTasks[key].taskId = taskId
                    raTaskInfo.commonTasks[key].taskState = missionInfo.state
                    raTaskInfo.commonTasks[key].taskCompleteNum = missionInfo.num
                    raTaskInfo.commonTasks[key].taskType = RAGameConfig.TaskType.CommonsetRotation3D
                    raTaskInfo.commonTasks[key].missionId = missionInfo.missionId
                    raTaskInfo.commonTasks[key].tabType = constTaskInfo.tabType
                    raTaskInfo.commonTasks[key].tabOrder = constTaskInfo.tabOrder
                end
            else
                CCLuaLog("There is noconstTaskInfo ")
            end
        end
        local i = 1
    end
end

function RATaskManager.refreshTaskInfo(msg)
    for i=1, #msg.refreshMission do
        local missionInfo = msg.refreshMission[i]
        if missionInfo then
            local taskId = missionInfo.cfgId
            local constTaskInfo = mission_conf[taskId]
            if constTaskInfo then
                if constTaskInfo.order1 then
                    --�Ƽ�����
                    local find = false
                    for _, taskInfo in Utilitys.table_pairsByKeys(raTaskInfo.recommandTasks) do
                        if taskInfo.taskId == taskId then
                            find = true--�ҵ�������������Ϣ
                            taskInfo.taskState = missionInfo.state
                            taskInfo.taskCompleteNum = missionInfo.num
                        end
                    end
                    --û���ҵ������������
                    if not find then
                        --�Ƽ�����
                        local recommandRaskInfo = {}
                        recommandRaskInfo.taskId = taskId
                        recommandRaskInfo.taskState = missionInfo.state
                        recommandRaskInfo.taskCompleteNum = missionInfo.num
                        recommandRaskInfo.taskType = RAGameConfig.TaskType.Recommand
                        recommandRaskInfo.missionId = missionInfo.missionId
                        table.insert(raTaskInfo.recommandTasks, recommandRaskInfo)
                    end
                elseif constTaskInfo.order2 then
                    --��ͨ����
                    local find = false
                    for _, taskInfo in Utilitys.table_pairsByKeys(raTaskInfo.commonTasks) do
                        if taskInfo.taskId == taskId then
                            find = true
                            taskInfo.taskState = missionInfo.state
                            taskInfo.taskCompleteNum = missionInfo.num
                        end
                    end
                    --û���ҵ������������
                    if not find then
                        --��ͨ����
                        local commonTaskInfo = {}
                        commonTaskInfo = {}
                        commonTaskInfo.taskId = taskId
                        commonTaskInfo.taskState = missionInfo.state
                        commonTaskInfo.taskCompleteNum = missionInfo.num
                        commonTaskInfo.taskType = RAGameConfig.TaskType.Common
                        commonTaskInfo.missionId = missionInfo.missionId
                        commonTaskInfo.tabType = constTaskInfo.tabType
                        commonTaskInfo.tabOrder = constTaskInfo.tabOrder
                        table.insert(raTaskInfo.commonTasks, commonTaskInfo)
                    end
                end
            end
        end
    end
    
end

--���չʾ������������ɵ���û���콱����������
function RATaskManager.getCompleteTaskNum()
    local completeNum = 0
    local recommandTask = RATaskManager.getRecommandTask()
    local commonTasks = RATaskManager.getCommonTasks()

    if recommandTask and recommandTask.taskState == RAGameConfig.TaskStatus.Complete then
        completeNum = completeNum + 1
    end

    if commonTasks then
        for k, commonTaskInfo in ipairs(commonTasks) do
            if commonTaskInfo.taskState == RAGameConfig.TaskStatus.Complete then
                completeNum = completeNum + 1
            end
        end
    end

    return completeNum
end

--���չʾ�������е��Ƽ�����,һ��
function RATaskManager.getRecommandTask()
    local recomandTaskInfo = nil
    if raTaskInfo.recommandTasks then
        for _,taskInfo in Utilitys.table_pairsByKeys(raTaskInfo.recommandTasks) do
            if taskInfo then
                if recomandTaskInfo == nil then
                    recomandTaskInfo = taskInfo
                else
                    if recomandTaskInfo.taskState ~= RAGameConfig.TaskStatus.Complete then
                        if taskInfo.taskState == RAGameConfig.TaskStatus.Complete then
                            recomandTaskInfo = taskInfo
                        else
                            local constRecommandTaskInfo = mission_conf[recomandTaskInfo.taskId]
                            local constTaskInfo = mission_conf[taskInfo.taskId]
                            if constRecommandTaskInfo.order1 > constTaskInfo.order1 then
                                recomandTaskInfo = taskInfo
                            end
                        end
                    elseif recomandTaskInfo.taskState == RAGameConfig.TaskStatus.Complete then
                        if taskInfo.taskState == RAGameConfig.TaskStatus.Complete then
                            local constRecommandTaskInfo = mission_conf[recomandTaskInfo.taskId]
                            local constTaskInfo = mission_conf[taskInfo.taskId]
                            if constRecommandTaskInfo.order1 > constTaskInfo.order1 then
                                recomandTaskInfo = taskInfo
                            end
                        end
                    end
                end
            end
        end
    end
    return recomandTaskInfo
end

--���һ���ɽ��ܵ����ȼ���ߵ��Ƽ�����
function RATaskManager.getRecommandTaskWithAccept()
    local recomandTaskInfo = nil
    if raTaskInfo.recommandTasks then
        for _,taskInfo in Utilitys.table_pairsByKeys(raTaskInfo.recommandTasks) do
            if taskInfo then
                if taskInfo ~= nil and taskInfo.taskState == RAGameConfig.TaskStatus.CanAccept then
                    if recomandTaskInfo == nil then
                        recomandTaskInfo = taskInfo
                    else
                        local constRecommandTaskInfo = mission_conf[recomandTaskInfo.taskId]
                        local constTaskInfo = mission_conf[taskInfo.taskId]
                        if constRecommandTaskInfo.order1 > constTaskInfo.order1 then
                            recomandTaskInfo = taskInfo
                        end
                    end
                end
            end
        end
    end
    return recomandTaskInfo
end

--���һ��δ��ɵ����ȼ���ߵ�����
function RATaskManager.getUnCompleteRecommandTask()
    local recomandTaskInfo = nil
    if raTaskInfo.recommandTasks then
        for _,taskInfo in Utilitys.table_pairsByKeys(raTaskInfo.recommandTasks) do
            if taskInfo and taskInfo.taskState == RAGameConfig.TaskStatus.CanAccept then
                if recomandTaskInfo == nil then
                    recomandTaskInfo = taskInfo
                else
                    local constRecommandTaskInfo = mission_conf[recomandTaskInfo.taskId]
                    local constTaskInfo = mission_conf[taskInfo.taskId]
                    if constRecommandTaskInfo.order1 > constTaskInfo.order1 then
                        recomandTaskInfo = taskInfo
                    end
                end
            end
        end
    end
    return recomandTaskInfo
end

--���task��Ϣ
function RATaskManager.getAllTaskInfos()
     return raTaskInfo
end

--Ϊ��������
function RATaskManager.sortTask(task1, task2)
    if task1.taskState == task2.taskState then
        local constTaskInfo1 = mission_conf[task1.taskId]
        local constTaskInfo2 = mission_conf[task2.taskId]
        
        if task1.taskCompleteNum == 0 and 
            task2.taskCompleteNum == 0 then
            if constTaskInfo1.order1 and constTaskInfo2.order1 then
                if constTaskInfo1.order1 < constTaskInfo2.order1 then
                    return true
                else
                    return false
                end
            elseif constTaskInfo1.order2 and constTaskInfo2.order2 then
                if constTaskInfo1.order2 < constTaskInfo2.order2 then
                    return true
                else
                    return false
                end
            end
        else
            return task1.taskCompleteNum/constTaskInfo1.funVal > task2.taskCompleteNum/constTaskInfo2.funVal
        end
    else
        if task1.taskState > task2.taskState then
            return true
        else
            return false
        end
    end

    return true
end

--�����ͨ������Ϣ���� <= 4��
function RATaskManager.getCommonTasks()

     local commonTaskArray = {}
     for i,taskInfo in ipairs(raTaskInfo.commonTasks) do
        commonTaskArray[taskInfo.tabType] = commonTaskArray[taskInfo.tabType] or {}
        table.insert(commonTaskArray[taskInfo.tabType], taskInfo)
     end
     for k,taskTabInfo in pairs(commonTaskArray) do
        table.sort(taskTabInfo, RATaskManager.sortTask)
     end

     return commonTaskArray
end

--����id���һ������
function RATaskManager.getOneTaskInfo(taskId)
    for _, taskInfo in Utilitys.table_pairsByKeys(raTaskInfo.recommandTasks) do
        if taskInfo.taskId == taskId then
            return taskInfo
        end
    end

    for _, taskInfo in Utilitys.table_pairsByKeys(raTaskInfo.commonTasks) do
        if taskInfo.taskId == taskId then
            return taskInfo
        end
    end
    return nil
end

--ɾ��һ����ͨ����,����true����false��ʾɾ���Ƿ�ɹ�
function RATaskManager.deleteCommonTask(taskId)
    for pos, taskInfo in Utilitys.table_pairsByKeys(raTaskInfo.commonTasks) do
        if taskInfo.taskId == taskId then
            table.remove(raTaskInfo.commonTasks,pos )
            return true
        end
    end
    return false
end

--ɾ��һ���Ƽ�����,����true����false��ʾɾ���Ƿ�ɹ�
function RATaskManager.deleteRecommandTask(taskId)
    for pos, taskInfo in Utilitys.table_pairsByKeys(raTaskInfo.recommandTasks) do
        if taskInfo.taskId == taskId then
            table.remove(raTaskInfo.recommandTasks,pos )
            return true
        end
    end
    return false
end

--ͨ��missionIdɾ����Ϣ
function RATaskManager.deleteTaskWithMissionId(missionId)
    for pos, taskInfo in Utilitys.table_pairsByKeys(raTaskInfo.recommandTasks) do
        if taskInfo.missionId == missionId then
            table.remove(raTaskInfo.recommandTasks,pos )
            return true
        end
    end

    for pos, taskInfo in Utilitys.table_pairsByKeys(raTaskInfo.commonTasks) do
        if taskInfo.missionId == missionId then
            table.remove(raTaskInfo.commonTasks,pos )
            return true
        end
    end
    return false
end

--ͨ������������������������Ϣ
function RATaskManager.addTaskFromServerData(msg)
    for i=1, #msg.addMission do
        local missionInfo = msg.addMission[i]

        local taskId = missionInfo.cfgId
        local constTaskInfo = mission_conf[taskId]
        if constTaskInfo then
            if constTaskInfo.order1 then
                --�Ƽ�����
                local recommandTaskInfo = {}
                recommandTaskInfo.taskId = taskId
                recommandTaskInfo.taskState = missionInfo.state
                recommandTaskInfo.taskCompleteNum = missionInfo.num
                recommandTaskInfo.taskType = RAGameConfig.TaskType.Common
                recommandTaskInfo.missionId = missionInfo.missionId
                table.insert(raTaskInfo.recommandTasks, recommandTaskInfo)
            elseif constTaskInfo.order2 then
                --��ͨ����
                local commonTaskInfo = {}
                commonTaskInfo.taskId = taskId
                commonTaskInfo.taskState = missionInfo.state
                commonTaskInfo.taskCompleteNum = missionInfo.num
                commonTaskInfo.taskType = RAGameConfig.TaskType.Common
                commonTaskInfo.missionId = missionInfo.missionId
                commonTaskInfo.tabType = constTaskInfo.tabType
                commonTaskInfo.tabOrder = constTaskInfo.tabOrder
                table.insert(raTaskInfo.commonTasks ,commonTaskInfo)
            end
        else
            CCLuaLog("There is noconstTaskInfo ")
        end
    end
end

--����������棬���н�����Ϣ������Ľ�������
function RATaskManager.getTaskBuildType()
    local buildType = nil
    for pos, taskInfo in Utilitys.table_pairsByKeys(raTaskInfo.recommandTasks) do
        if taskInfo.taskState == RAGameConfig.TaskStatus.CanAccept then
            local constTaskInfo = mission_conf[taskInfo.taskId]
            if constTaskInfo then
                if constTaskInfo.goTo and constTaskInfo.goTo ~= "world" then
                    buildType = constTaskInfo.goTo
                    return buildType
                end
            else
                CCLuaLog("RATaskManager.getTaskBuildType() There is no constTaskInfo")
            end
        end
    end

    for pos, taskInfo in Utilitys.table_pairsByKeys(raTaskInfo.commonTasks) do
        if taskInfo.taskState == RAGameConfig.TaskStatus.CanAccept then
            local constTaskInfo = mission_conf[taskInfo.taskId]
            if constTaskInfo then
                if constTaskInfo.goTo and constTaskInfo.goTo ~= "world" then
                    buildType = constTaskInfo.goTo
                    return buildType
                end
            else
                CCLuaLog("RATaskManager.getTaskBuildType() There is no constTaskInfo")
            end
        end
    end

    return buildType
end


function RATaskManager.gotoTaskTarget(constTaskInfo)
    if constTaskInfo.funType == nil then
        return
    end
    local isInCity = RARootManager.GetIsInCity()
    local RAWorldManager = RARequire('RAWorldManager')
    if constTaskInfo.funType == RATaskGotoType.Task_Upgrade or constTaskInfo.funType == RATaskGotoType.Task_UpgradeResBuild  then
        if not isInCity then
            RARootManager.ChangeScene(SceneTypeList.CityScene)
            return
        end
        --RARootManager.AddGuidPage({["guideId"] = RAGameConfig.AvoidTouchGuideId, ["update"] = true})
        RARootManager.AddCoverPage({["update"] = true})

        --�Ƶ�������ָʾ����
        --���ú����Ľӿڣ������ǽ������ͣ���ť���ͣ���ť������RABuildingType.lua��BUILDING_BTN_TYPE
        local guideId = constTaskInfo.guideId
        local constGuideInfo = guide_conf[guideId]
        if constGuideInfo then
            RAGuideManager.guideTaskGuideId = guideId
            local btnType = BUILDING_BTN_TYPE.UPGRADE
            local result = RABuildManager:showBuildingByBuildType(constTaskInfo.goTo, btnType)
            --�������nil��˵������������޷�����
            if not result then
                RARootManager.RemoveGuidePage()
                RARootManager.RemoveCoverPage()
            end
        end
    elseif constTaskInfo.funType == RATaskGotoType.Task_ChooseBuild then
        if RARootManager.GetIsInWorld() then
            RARootManager.ChangeScene(SceneTypeList.CityScene)
        end
        --RARootManager.AddGuidPage({["guideId"] = RAGameConfig.AvoidTouchGuideId, ["update"] = true})
        RARootManager.AddCoverPage({["update"] = true})

        --չ���������UI��ָʾ����
        local guideId = constTaskInfo.guideId
        local constGuideInfo = guide_conf[guideId]
        if constGuideInfo then
            RAGuideManager.guideTaskGuideId = guideId
            local tmpConstGuideInfo = {}
            tmpConstGuideInfo.buildType = constTaskInfo.goTo
            tmpConstGuideInfo.guideId = guideId

            RARootManager.OpenPage("RAChooseBuildPage", {["GuideData"] = tmpConstGuideInfo})
            MessageManager.sendMessage(MessageDef_MainUI.MSG_HandleChooseBuildPage, {isShow = false})
        end
                
    elseif constTaskInfo.funType == RATaskGotoType.Task_TechLevel then
        if not isInCity then
            RARootManager.ChangeScene(SceneTypeList.CityScene)
            return
        end
        --RARootManager.AddGuidPage({["guideId"] = RAGameConfig.AvoidTouchGuideId, ["update"] = true})
        RARootManager.AddCoverPage({["update"] = true})

        --�ƶ����Ƽ�����-չ���Ƽ����-ָʾ�Ƽ�
        local guideId = constTaskInfo.guideId
        local constGuideInfo = guide_conf[guideId]
        if constGuideInfo then
            RAGuideManager.guideTaskGuideId = guideId
            local btnType = BUILDING_BTN_TYPE.RESEARCH
            local result = RABuildManager:showBuildingByBuildType(constTaskInfo.goTo, btnType)
            if not result then
                RARootManager.RemoveGuidePage()
                RARootManager.RemoveCoverPage()
            end
        end
    elseif constTaskInfo.funType == RATaskGotoType.Task_TechCount then
        if not isInCity then
            RARootManager.ChangeScene(SceneTypeList.CityScene)
            return
        end
        --RARootManager.AddGuidPage({["guideId"] = RAGameConfig.AvoidTouchGuideId, ["update"] = true})
        RARootManager.AddCoverPage({["update"] = true})

        --�ƶ����Ƽ�����-չ���Ƽ����
        local guideId = constTaskInfo.guideId
        local constGuideInfo = guide_conf[guideId]
        if constGuideInfo then
            RAGuideManager.guideTaskGuideId = guideId
            local btnType = BUILDING_BTN_TYPE.RESEARCH
            local result = RABuildManager:showBuildingByBuildType(constTaskInfo.goTo, btnType)
            if not result then
                RARootManager.RemoveGuidePage()
                RARootManager.RemoveCoverPage()

            end
        end
    elseif constTaskInfo.funType == RATaskGotoType.Task_TrainSoldier or constTaskInfo.funType == RATaskGotoType.Task_RightTrainSoldier then
        if not isInCity then
            RARootManager.ChangeScene(SceneTypeList.CityScene)
            return
        end
        --RARootManager.AddGuidPage({["guideId"] = RAGameConfig.AvoidTouchGuideId, ["update"] = true})
        RARootManager.AddCoverPage({["update"] = true})

        --�ƶ������ֽ���-չ��ѵ�����-ָʾ����
        local guideId = constTaskInfo.guideId
        local constGuideInfo = guide_conf[guideId]
        if constGuideInfo then
            RAGuideManager.guideTaskGuideId = guideId
            local RAArsenalConfig = RARequire("RAArsenalConfig")
            local btnType = BUILDING_BTN_TYPE.TRAIN_BARRACKS
            if RAArsenalConfig.ArmyCatogory.infantry == constGuideInfo.soldierType then
                btnType = BUILDING_BTN_TYPE.TRAIN_BARRACKS
            elseif RAArsenalConfig.ArmyCatogory.tank == constGuideInfo.soldierType then
                btnType = BUILDING_BTN_TYPE.TRAIN_WAR_FACTORY
            elseif RAArsenalConfig.ArmyCatogory.missile == constGuideInfo.soldierType then
                btnType =  BUILDING_BTN_TYPE.TRAIN_REMOTE_FIRE_FACTORY
            elseif RAArsenalConfig.ArmyCatogory.helicopter == constGuideInfo.soldierType then
                btnType =  BUILDING_BTN_TYPE.TRAIN_RAIR_FORCE_COMMAND
            end
            local result = RABuildManager:showBuildingByBuildType(constTaskInfo.goTo, btnType)
            if not result then
                RARootManager.RemoveGuidePage()
                RARootManager.RemoveCoverPage()

            end
        end

    elseif constTaskInfo.funType == RATaskGotoType.Task_CollectResCount then
        --��ת������-�ƶ�����Դ����-ָʾ��Դ
        local guideId = constTaskInfo.guideId
        local constGuideInfo = guide_conf[guideId]
        if constGuideInfo then
            RAGuideManager.guideTaskGuideId = guideId
        end

        RAWorldManager:LocateAtBuilding(World_pb.RESOURCE, nil, tonumber(constTaskInfo.funId))
    elseif constTaskInfo.funType == RATaskGotoType.Task_AttackMonster then
        --��ת������-�ƶ��������NPC-ָʾNPC
        local guideId = constTaskInfo.guideId
        local constGuideInfo = guide_conf[guideId]
        if constGuideInfo then
            RAGuideManager.guideTaskGuideId = guideId
        end

        RAWorldManager:LocateAtBuilding(World_pb.MONSTER, tonumber(constTaskInfo.funId))
    elseif constTaskInfo.funType == RATaskGotoType.Task_KillMonster then
        --��ת������-�ƶ��������NPC-ָʾNPC
        local guideId = constTaskInfo.guideId
        local constGuideInfo = guide_conf[guideId]
        if constGuideInfo then
            RAGuideManager.guideTaskGuideId = guideId
        end

        RAWorldManager:LocateAtBuilding(World_pb.MONSTER, tonumber(constTaskInfo.funId))
    elseif constTaskInfo.funType == RATaskGotoType.Task_FightCount then
        --��ת������-�ƶ��������NPC-ָʾNPC
        local guideId = constTaskInfo.guideId
        local constGuideInfo = guide_conf[guideId]
        if constGuideInfo then
            RAGuideManager.guideTaskGuideId = guideId
        end

        RAWorldManager:LocateAtBuilding(World_pb.PLAYER)
    end
end


--���task����
function RATaskManager:reset()
    raTaskInfo = {
        recommandTasks = {},
        commonTasks = {}
    }
end