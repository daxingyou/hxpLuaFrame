local guide_conf = RARequire("guide_conf")
local UIExtend = RARequire("UIExtend")
local RANetUtil = RARequire("RANetUtil")
local RAGameConfig = RARequire("RAGameConfig")
local RARootManager = RARequire("RARootManager")
local Utilitys = RARequire("Utilitys")
local RAGuideConfig = RARequire('RAGuideConfig')
local EnterFrameDefine = RARequire("EnterFrameDefine")
local RAConfirmManager=RARequire("RAConfirmManager") 
local common = RARequire("common")
local RAGuideManager = {}
package.loaded[...] = RAGuideManager

RAGuideManager.currentGuildId = 0
RAGuideManager.currentPartName = "Guide_First"
RAGuideManager.showPopPages = false --是否已经显示了popPage(所谓popPage是指那些进入游戏后自动弹出的页面，新手过后，需要弹出)
RAGuideManager.partComplete = --当前阶段是否完成，默认没有
{
    Guide_First = false,
    Guide_MainCity_Start_2To3 = false,
    Guide_UIUPDATE=true
}
RAGuideManager.serverGuideId=nil
local mFrameTime=0

--desc:判断要goto的step是否满足条件,limitParamStr是所有限制条件的组合字符串，不同种类的限制条件通过'|'连接
function RAGuideManager.judgeLimitParam(limitParamStr)
    if limitParamStr == nil or limitParamStr == "" then
        return true
    else
        local RABuildManager = RARequire("RABuildManager")
        local limitParamArr = Utilitys.Split(limitParamStr, "|")
        for _, limitParam in pairs(limitParamArr) do
            local limitArr = Utilitys.Split(limitParam, "_")
            local limitType = tonumber(limitArr[1])
            if limitType == RAGuideConfig.GuideLimitType.ContainBuild then
                --配置中，buildType要用英文逗号隔开
                local buildTypeArr = Utilitys.Split(limitArr[2], ",")
                for _, buildType in pairs(buildTypeArr) do
                    local buildlData = RABuildManager:getBuildDataByType(buildType)
                    if not buildlData then
                        RALogRelease("RAGuideManager.judgeLimitParam limitType is ContainBuild with limitParam: " .. limitParam .." and limitParamStr: "..limitParamStr)
                        return false
                    end
                end
            elseif limitType == RAGuideConfig.GuideLimitType.NotContainBuild then
                --配置中，buildType要用英文逗号隔开
                local buildTypeArr = Utilitys.Split(limitArr[2], ",")
                for _, buildType in pairs(buildTypeArr) do
                    local buildlData = RABuildManager:getBuildDataByType(buildType)
                    if buildlData then
                        RALogRelease("RAGuideManager.judgeLimitParam limitType is NotContainBuild with limitParam: " .. limitParam .." and limitParamStr: "..limitParamStr)
                        return false
                    end
                end
            elseif limitType == RAGuideConfig.GuideLimitType.BuildLevel then
                --配置中，buildType1-level1,buildType2-level2
                local buildTypeWithLevelArr = Utilitys.Split(limitArr[2], ",")
                local allResult = false
                for _, buildTypeWithLevel in pairs(buildTypeWithLevelArr) do
                    local typeWithLevel = Utilitys.Split(buildTypeWithLevel, "-") 
                    local buildType = typeWithLevel[1]
                    local buildLevel = typeWithLevel[2]
                    if buildType and buildLevel then
                        local buildDataTable = RABuildManager:getBuildDataByType(tonumber(buildType))
                        if buildDataTable then
                            local result = false
                            for k,buildData in pairs(buildDataTable) do
                                if buildData.confData.level == tonumber(buildLevel) then
                                    result = true
                                end
                            end
                            --有一个条件不满足，直接return 不需要再继续执行循环
                            if not result then
                                return false
                            else
                                allResult = true
                            end
                        else
                            return false
                        end 
                    else
                        RALogRelease("RAGuideManager.judgeLimitParam LimitParam format is Error With limitParam: " .. limitParam .." and limitParamStr: "..limitParamStr)
                        return false
                    end
                end
                RALogRelease("RAGuideManager.judgeLimitParam limitType is BuildLevel with limitParam: " .. limitParam .." and limitParamStr: "..limitParamStr)
                return allResult
            end
        end
    end
    return true
end

--desc:进入新手某一步
function RAGuideManager.gotoStep(guildId)
    --如果当前步骤所属的阶段已经是完成状态，那么直接返回
  if RAGuideManager.partComplete[RAGuideManager.currentPartName] == true then
      return
  end

    local constGuideInfo = guide_conf[guildId]
    if constGuideInfo then
        local RecordManager = RARequire("RecordManager")
        RecordManager.recordNoviceGuide(guildId)--todo:临时打点
        --当前步骤是否需要显示guidepage，不需要就移除,但是消息必须发送
        if constGuideInfo.showGuidePage == 0 then
            if constGuideInfo.keyWord ~= RAGuideConfig.KeyWordArray.GuideStart then
                RARootManager.RemoveGuidePage()--GuideStart关键字要特殊处理
            end
            MessageManager.sendMessage(MessageDef_Guide.MSG_Guide, {guideInfo = constGuideInfo})
        else
            if constGuideInfo.guidType == 0 then--如果当前步骤是普通对话步骤，那么直接显示，无需发消息通知，否则发消息通知相关系统进行特殊处理
                RARootManager.AddGuidPage({["guideId"] = guildId})
            else
                MessageManager.sendMessage(MessageDef_Guide.MSG_Guide, {guideInfo = constGuideInfo})
            end
        end

        --需要移动建筑的步骤
        if constGuideInfo.isMoveBuilding and constGuideInfo.isMoveBuilding == 1 then
            local RABuildManager = RARequire("RABuildManager")

            local Const_pb = RARequire("Const_pb")
            if constGuideInfo.buildType == Const_pb.BARRACKS or constGuideInfo.buildType == Const_pb.WAR_FACTORY then
                --新手期，兵营和战车工厂移动前，收一下兵
                local buildData = RABuildManager:getBuildDataArray(constGuideInfo.buildType)
                if buildData and buildData[1] and buildData[1].status == Const_pb.SOILDER_HARVEST then
                     local RAArsenalManager = RARequire('RAArsenalManager')
                     RAArsenalManager:sendCollectArmyCmd(buildData[1].id)
                end
            end
            RALog(" RAGuideManager.gotoStep ".. guildId .. " Move Build To Center...")
            RABuildManager:showBuildingByBuildType(constGuideInfo.buildType,nil,false,false)
        end
        
    else
        CCLuaLog("RAGuideManager.gotoStep There is no step")
    end
end

--desc:进入不同阶段新手
function RAGuideManager.gotoPart(partName)
    if partName == nil or partName == "" then
        return
    end

    --如果要进入的阶段已经完成，直接返回
    if RAGuideManager.partComplete[partName] == true then
        return
    end

    local startGuideId = RAGuideConfig.partNameWithStartId[partName]
    if RAGuideManager.currentGuildId < startGuideId then
        RAGuideManager.currentGuildId = startGuideId
        RAGuideManager.currentPartName = partName
        RAGuideManager.gotoStep(RAGuideManager.currentGuildId)
    end
end

--desc:各个模块衔接新手的接口，新手期各个模块的功能完成后调用该接口，可以自动衔接后面步骤
function RAGuideManager.gotoNextStep()
    RAGuideManager.saveGuide()

    if RAGuideManager.isInGuide() then
        
        local constGuideInfo = guide_conf[RAGuideManager.currentGuildId]
        if constGuideInfo then
            RAGuideManager.currentGuildId = constGuideInfo.nextId
        else
            RAGuideManager.currentGuildId = RAGuideConfig.GuideStartId
        end

        if RAGuideConfig.guideDebug then
            RAGuideManager.currentGuildId=RAGuideConfig.guideIdDebug
            RAGuideConfig.guideDebug=false
        end
        RAGuideManager.gotoStep(RAGuideManager.currentGuildId)
    else
        RARootManager.RemoveGuidePage()
    end
end

--desc:延迟进入下一步，有些步骤操作结束后，为了节奏整齐，下一步新手需要延迟一些进入
function RAGuideManager.gotoNextStepDelay()
    local mainUI = RARequire("RAMainUIPage")
    performWithDelay(mainUI:getRootNode(), function()
        RAGuideManager.gotoNextStep()
    end, 1.5)
end

--desc:某些步骤会根据实际情况不同有不同的下一步操作，比如打怪，寻找到怪与没有找到怪的下一步是不同的操作。
function RAGuideManager.gotoNextStep2()
    RAGuideManager.saveGuide()

    if RAGuideManager.isInGuide() then
        local constGuideInfo = guide_conf[RAGuideManager.currentGuildId]
        if constGuideInfo then
            RAGuideManager.currentGuildId = constGuideInfo.nextId2
        else
            RAGuideManager.currentGuildId = RAGuideConfig.GuideStartId
        end
        RAGuideManager.gotoStep(RAGuideManager.currentGuildId)
    end
end

--desc:根据guideId获得当前partName
function RAGuideManager.getGuidePartNameByGuideId(guideId)
    if guideId == nil then
        return nil
    end

    if guideId >= RAGuideConfig.partNameWithStartId.Guide_First and  guideId < RAGuideConfig.partNameWithStartId.Guide_MainCity_Start_2To3 then
        return "Guide_First"
    elseif guideId >= RAGuideConfig.partNameWithStartId.Guide_MainCity_Start_2To3 then
        return "Guide_MainCity_Start_2To3"
    end
    return nil
end

--desc:判断当前新手是否可以显示全部主UI，主UI在某些步骤之前是需要全部隐藏的
function RAGuideManager.canShowAllMainUI()
    if RAGuideManager.currentGuildId >= RAGuideConfig.mainUIAllInGuideId then
        return true
    else
        return false
    end
end

--desc:判断当前新手是否可以显示队列上的按钮
function RAGuideManager.canShowQueenBtn()
    if RAGuideManager.isInGuide() and RAGuideManager.currentGuildId < RAGuideConfig.showQueenBtn then
        return false
    else
        return true
    end
end

--desc:判断当前新手是否可以显示世界信息了，在某些步骤之前，世界上使用的是假数据，不需要加载其他世界数据
function RAGuideManager.canShowWorld()
    if RAGuideManager.currentGuildId >= RAGuideConfig.worldSceneShowGuideId then
        return true
    else
        return false
    end
end

--desc:判断当前阶段是否是第一阶段
function RAGuideManager.isInFirstPart()
    return RAGuideManager.currentPartName == "Guide_First" or false
end



--GuideStageEnum = {
--        StageFirst = 1,--从新手第一步到第一阶段结束，isInGuide == true
--        StageSecond = 2,--第一阶段结束到第二阶段开始的自由操作阶段，isInGuide == false
--        StageThird = 3--第二阶段开始到第二阶段结束isInGuide == true
--    },
function RAGuideManager.getCurrentStage()
    if RAGuideManager.isInGuide() and RAGuideManager.isInFirstPart() then
        return RAGuideConfig.GuideStageEnum.StageFirst
    elseif RAGuideManager.isInGuide() == false and RAGuideManager.isInFirstPart() then
        return RAGuideConfig.GuideStageEnum.StageSecond
    elseif RAGuideManager.isInGuide() and RAGuideManager.isInFirstPart() == false then
        return RAGuideConfig.GuideStageEnum.StageThird
    end
end

--desc:判断当前是否在新手步骤
function RAGuideManager.isInGuide()
    --如果新手步骤大于等于最大步骤数或者是主城等级超过某级，则判断不是新手
    local constGuideInfo = guide_conf[RAGuideManager.currentGuildId]

    local inGuide = false
    local RABuildManager = RARequire("RABuildManager")
    local mainCityLvl = RABuildManager:getMainCityLvl()
    if constGuideInfo then
        if constGuideInfo.isGuideEnd and constGuideInfo.isGuideEnd == 1 or mainCityLvl >=RAGuideConfig.mainCityLevelLimit then
            inGuide = false
        else
            inGuide = true
        end
    else
        if RAGuideManager.currentGuildId == 0 and mainCityLvl == 1 then--特殊处理一下
            inGuide = true
        else
            inGuide = false
        end
    end
    
    if not inGuide and not RAGuideManager.showPopPages then
--        local mainUI = RARequire("RAMainUIPage")
--        performWithDelay(mainUI:getRootNode(), function()
--            --新手走完后，发送消息调出popPage，（暂时先不pop）
--            MessageManager.sendMessage(Message_AutoPopPage.MSG_AlreadyPopPage)
--            RAGuideManager.showPopPages = true
--        end, 2)
    end

    return inGuide
end

--desc:向后端发送请求保存步骤
function RAGuideManager.saveGuide()
    if RAGuideManager.currentGuildId == 0 or RAGuideManager.currentGuildId > RAGameConfig.TOTAL_GUIDE_NUM then
        return
    end

    local constGuideInfo = guide_conf[RAGuideManager.currentGuildId]
    if constGuideInfo and constGuideInfo.needSave > 0 then
        local SysProtocol_pb = RARequire("SysProtocol_pb")
        local msg = SysProtocol_pb.HPCustomDataDefine()
        msg.data.key = "tutorial"
        msg.data.val = constGuideInfo.needSave
        RANetUtil:sendPacket(HP_pb.CUSTOM_DATA_DEFINE, msg, {retOpcode = -1})

        if (constGuideInfo.isGuideEnd and constGuideInfo.isGuideEnd == 1) or (constGuideInfo.needSave == RAGuideConfig.partNameWithEndId[RAGuideManager.currentPartName]) then
            --当前阶段的步骤完成
            local msg2 = SysProtocol_pb.HPCustomDataDefine()
            if RAGuideManager.currentPartName == "Guide_First" then
                msg2.data.key = "tutorial_1"
            elseif RAGuideManager.currentPartName == "Guide_MainCity_Start_2To3" then
                msg2.data.key = "tutorial_2"
            end
            msg2.data.val = 1
            RANetUtil:sendPacket(HP_pb.CUSTOM_DATA_DEFINE, msg2, {retOpcode = -1})
            if constGuideInfo.isGuideEnd and constGuideInfo.isGuideEnd == 1 then
                RAGuideManager.partComplete[RAGuideManager.currentPartName] = true --最后一步设置阶段完成标志
            end
        end
    end
end

--desc:跳过所有的新手
function RAGuideManager.jumpAllGuide()
    RAGuideManager.currentGuildId = RAGuideConfig.jumpGuideId
    RAGuideManager.saveGuide()
end

--desc:根据guideId获得配置的guideInfo,如果参数为nil那么返回下一步的新手信息，否则返回nil
function RAGuideManager.getConstGuideInfoById(guideId)
    if guideId == nil then
        local constGuideInfo = guide_conf[RAGuideManager.currentGuildId]
        if constGuideInfo then
            guideId = constGuideInfo.nextId
        end
    end
    if guideId then
        local constGuideInfo = guide_conf[guideId]
        return constGuideInfo
    end
    return nil
end

--desc:获得当前guideid的keyword，如果guideId是nil，返回下一步新手的keyWord
function RAGuideManager.getKeyWordById(guideId)
    local constGuideInfo = RAGuideManager.getConstGuideInfoById(guideId)
    local keyWord = ""
    if constGuideInfo and constGuideInfo.keyWord then
        keyWord = constGuideInfo.keyWord
    end
    return keyWord
end

--desc:获得当前步骤id的接口
function RAGuideManager.getCurrentGuideId()
    return RAGuideManager.currentGuildId
end

--desc:判断游戏是否需要直接去世界，只有在新手第一次进入的时候进入世界，其他时候都先进入城内，然后根据引导去世界
function RAGuideManager.guideInWorld()
--    if RAGameConfig.GuideGMFlag then
--        RAGuideManager.currentGuildId = RAGameConfig.GuideGMStep
--        RAGuideManager.currentPartId = RAGameConfig.GuideGMPartId
--    end

    if RAGuideManager.currentGuildId <=1 then
        return true
    else
        return false
    end
end

--desc:设置当前步骤以及currentPartName，根据步骤设置part完成情况
function RAGuideManager.setCurrGuideId(guideId)
    if RAGuideConfig.guideDebug then
        guideId=RAGuideConfig.guideIdDebug
    end 

    --保存一份服务器传来的guideId
    RAGuideManager.serverGuideId = guideId

    local RAConfirmManager = RARequire("RAConfirmManager")
    local clientGuide = RAConfirmManager:getConfirmForKey(RAConfirmManager.TYPE.GUIDEID)

    local RANetManager = RARequire("RANetManager")
    if RANetManager.isReconectSuccess and clientGuide then
        --如果是断线重连后就读取客户端保存的guideId 
        CCLuaLog("ReconectSuccess so read client guideId===============")
        if clientGuide>=guideId then
            RAGuideManager.currentGuildId = clientGuide
        else
            RAConfirmManager:setConfirmForKey(RAConfirmManager.TYPE.GUIDEID,guideId)
        end 
    else
        --正常登陆以服务器传来的guideId为主
        RAGuideManager.currentGuildId = guideId
        RAConfirmManager:setConfirmForKey(RAConfirmManager.TYPE.GUIDEID,guideId)

    end 

    local constGuideInfo = guide_conf[guideId]
    if constGuideInfo then
        RAGuideManager.currentPartName = RAGuideManager.getGuidePartNameByGuideId(guideId)
        --根据当前guideid设置阶段完成标志
        if guideId >= RAGuideConfig.partNameWithEndId["Guide_First"] then
            RAGuideManager.partComplete.Guide_First = true
        end
        if guideId >= RAGuideConfig.partNameWithEndId["Guide_MainCity_Start_2To3"] then
            RAGuideManager.partComplete.Guide_MainCity_Start_2To3 = true
        end

    end

    if RANetManager.isReconectSuccess and clientGuide then
       RAGuideManager.gotoStep(clientGuide)
       RANetManager.isReconectSuccess=nil
    end 
end

--desc:从服务器推送来的数据初始化当前新手步骤
function RAGuideManager.setGuideInfo(msg)
    RAGuideManager.init()
    if RAGameConfig.SwitchGuide==0 then
        --屏蔽新手
        RAGuideManager.setCurrGuideId(RAGameConfig.TOTAL_GUIDE_NUM)
        return
    end

    local RABuildManager = RARequire("RABuildManager")
    local mainCityLvl = RABuildManager:getMainCityLvl()
    if mainCityLvl > 4 then
        RAGuideManager.setCurrGuideId(RAGameConfig.TOTAL_GUIDE_NUM)
        return
    end

    --设置新手真实数据
    if msg.data then
        for i=1, #msg.data do
            local info = msg.data[i]
            if info then
                if info.key == "tutorial" then
                    --新手
                    local value = info.val
                    RAGuideManager.setCurrGuideId(tonumber(value))
                elseif info.key == "tutorial_1" then
                    local value = info.val
                    if value == 1 then
                        RAGuideManager.partComplete.Guide_First = true--设置第一阶段完成完成标志
                    end
                elseif info.key == "tutorial_2" then
                    local value = info.val
                    if value == 1 then
                        RAGuideManager.partComplete.Guide_MainCity_Start_2To3 = true--设置第二阶段完成标志
                    end
                end
            end
        end
    end
end

--desc：获得不能拖动屏幕的新手步骤,已淘汰
function RAGuideManager.getNotDragInWorldGuidIds()
    local arr = {}
    for i=1, RAGameConfig.TOTAL_GUIDE_NUM do
        if guide_conf[i] then
            if guide_conf[i].isMoveBuilding and guide_conf[i].isMoveBuilding == 1 then
                table.insert(arr, i+1)
            elseif guide_conf[i].isAvoidCityDrag and guide_conf[i].isAvoidCityDrag == 1 then
                table.insert(arr, i)
            end
        end
    end
    return arr
end

--desc:当前可否拖动：已淘汰
function RAGuideManager.isCanDrag(guidId)
    local index = guidId-1
    if guide_conf[index] and guide_conf[index].isMoveBuilding and guide_conf[index].isMoveBuilding == 1 then
        return false
    else
        return true
    end 
end


---------------------------------------------------------------
RAGuideManager.guideTaskGuideId = 0--点击任务的前往时，保存跟任务相关连的guideId

local onReceiveMessage = function(message)
--    if RAGuideManager.isInGuide() then
--        return
--    end
    if message.messageID == MessageDef_Guide.MSG_TaskGuide then--城内任务向导结束后发送的消息
        local pos = message.pos
        local size = message.size
        if pos and size then
            pos.x = pos.x + size.width / 2
            pos.y = pos.y + size.height / 2
            RARootManager.AddGuidPage({["guideId"] = RAGuideManager.guideTaskGuideId, ["pos"] = pos, ["size"]=size})
        else
            RARootManager.RemoveGuidePage()
            RARootManager.RemoveCoverPage()
        end
    elseif message.messageID == MessageDef_Guide.MSG_TaskGuideWorld then--城外任务向导结束后发送的消息
        local found = message.found
        if found then
            local constGuideInfo = guide_conf[RAGuideManager.guideTaskGuideId]
            if constGuideInfo then
                local sizeArray = Utilitys.Split(constGuideInfo.guideCircleSize, "_")
                local size = CCSizeMake(0, 0)
                size.width = tonumber(sizeArray[1])
                size.height = tonumber(sizeArray[2])

                local confOffset = constGuideInfo.guideCircleOffset
                local offsetX = 0
                local offsetY = 0
                if confOffset then
                    local offsetArr = Utilitys.Split(confOffset, "_")
                    offsetX = tonumber(offsetArr[1])
                    offsetY = tonumber(offsetArr[2])
                end
                local screenVisibleSize = CCDirector:sharedDirector():getOpenGLView():getVisibleSize()
                local screenCenterPos = ccp(screenVisibleSize.width / 2, screenVisibleSize.height / 2)
                screenCenterPos.x = screenCenterPos.x + offsetX
                screenCenterPos.y = screenCenterPos.y + offsetY

                RARootManager.AddGuidPage({["guideId"] = RAGuideManager.guideTaskGuideId, ["pos"] = screenCenterPos, ["size"]=size})
            else
                RARootManager.RemoveGuidePage()
                RARootManager.RemoveCoverPage()
            end
        else
             RARootManager.ShowMsgBox("@TaskWorldTargetNotFount")                     
        end
    elseif message.messageID == MessageDef_Building.MSG_MainFactory_Levelup then
        --主基地升级，出发下一轮新手
    elseif message.messageID == MessageDef_World.MSG_MarchEndBattle then
        --战斗胜利
    elseif message.messageID == MessageDef_Building.MSG_BuildingMoveToFinshied then--新手移动建筑然后圈住
        if RAGuideManager.isInGuide() then
            local constGuideInfo = guide_conf[RAGuideManager.currentGuildId]

            if constGuideInfo then
                if constGuideInfo.notDealMessageOfMoveBuild and constGuideInfo.notDealMessageOfMoveBuild==1 then
                    --新手期有些步骤不需要处理hud完成消息
                    return
                end
            end

            RAGuideManager.currentGuildId = constGuideInfo.nextId
            constGuideInfo = guide_conf[RAGuideManager.currentGuildId]
            if constGuideInfo and constGuideInfo.specialGuideType == 1 then
                local confSize = constGuideInfo.buildSize
                local size = CCSizeMake(0, 0)
                if confSize then
                    local sizeArr = Utilitys.Split(confSize, "_")
                    size.width = tonumber(sizeArr[1])
                    size.height = tonumber(sizeArr[2])
                end
                local confBuildOffset = constGuideInfo.buildOffSet
                local offsetX = 0
                local offsetY = 0
                if confBuildOffset then
                    local offsetArr = Utilitys.Split(confBuildOffset, "_")
                    offsetX = tonumber(offsetArr[1])
                    offsetY = tonumber(offsetArr[2])
                end
                local screenVisibleSize = CCDirector:sharedDirector():getOpenGLView():getVisibleSize()
                local screenCenterPos = ccp(screenVisibleSize.width / 2, screenVisibleSize.height / 2)
                screenCenterPos.x = screenCenterPos.x + offsetX
                screenCenterPos.y = screenCenterPos.y + offsetY

                RARootManager.RemoveCoverPage()
                RARootManager.AddGuidPage({["guideId"] = RAGuideManager.currentGuildId, ["pos"] = screenCenterPos, ["size"]=size})
            end
        end
    elseif message.messageID == MessageDef_Building.MSG_Guide_Hud_BtnInfo then--新手圈住hud按钮
        if RAGuideManager.isInGuide() then
            local constGuideInfo = guide_conf[RAGuideManager.currentGuildId]

            if constGuideInfo then
                if constGuideInfo.notDealMessageOfHud and constGuideInfo.notDealMessageOfHud==1 then
                    --新手期有些步骤不需要处理hud完成消息
                    return
                end
            end


            RAGuideManager.saveGuide()--保存步骤
            RAGuideManager.currentGuildId = constGuideInfo.nextId
            constGuideInfo = guide_conf[RAGuideManager.currentGuildId]

            if constGuideInfo then
            --如果是圈住免费hud的，统统去圈UI的队列的免费按钮
                if constGuideInfo.keyWord == RAGuideConfig.KeyWordArray.CircleFreeBtn then
                    local mainUI = RARequire("RAMainUIPage")
                    local queueCCB = mainUI.mQueueShowHelper.mCellList[1]:GetCCBFile()
                    if queueCCB then
                        local freeBtn = UIExtend.getCCControlButtonFromCCB(queueCCB, "mFreeBtn")
                        if freeBtn then
                            local pos = freeBtn:getParent():convertToWorldSpace(ccp(freeBtn:getPositionX(), freeBtn:getPositionY()))
                            local size = freeBtn:getContentSize()
                            size.width = size.width + 18
                            size.height = size.height + 18
                            --RARootManager.AddGuidPage({["guideId"] = RAGuideManager.currentGuildId, ["pos"] = pos, ["size"]=size})
                            RARootManager.AddGuidPage({["guideId"] = RAGuideManager.currentGuildId})--不圈住免费按钮
                            RARootManager.RemoveCoverPage()
                        else
                            RARootManager.RemoveGuidePage()
                            RARootManager.RemoveCoverPage()
                        end
                    else
                        --如果此时检测不到免费按钮，说明已经升级完成
                        RARootManager.AddCoverPage()
                        RAGuideManager.gotoNextStep()
                    end
                elseif constGuideInfo.specialGuideType == 2 then
                    local pos = message.pos
                    local size = message.size
                    if pos and size then
                        pos.x = pos.x + size.width / 2
                        pos.y = pos.y + size.height / 2
                        size.width = size.width - 30
                        size.height = size.height - 30
                        RARootManager.AddGuidPage({["guideId"] = RAGuideManager.currentGuildId, ["pos"] = pos, ["size"]=size})
                        RARootManager.RemoveCoverPage()
                    else
                        RARootManager.RemoveGuidePage()
                        RARootManager.RemoveCoverPage()
                    end
                end
            end
        end
    elseif message.messageID == MessageDef_Guide.MSG_GuideEnd then
        RARootManager.RemoveCoverPage()
        RARootManager.RemoveGuidePage()
        CCSpriteFrameCache:sharedSpriteFrameCache():removeUnusedSpriteFrames()
        CCTextureCache:sharedTextureCache():removeUnusedTextures()
        CCDirector:sharedDirector():purgeCachedData()
    end
end

--desc:初始化一些数据
function RAGuideManager.init()
    RAGuideManager.showPopPages = false
    RAGuideManager.registerHandler()
    EnterFrameMananger.registerEnterFrameHandler(EnterFrameDefine.Guide.EF_GuideUpdate, RAGuideManager)
end

function RAGuideManager:EnterFrame()
  
     mFrameTime = mFrameTime + common:getFrameTime()
    if mFrameTime>=RAGuideConfig.reConnectionTime then
        --保存一次引导id
        local clientGuideId = RAConfirmManager:getConfirmForKey(RAConfirmManager.TYPE.GUIDEID)
        if clientGuideId==nil then
            local RAGuideConfig = RARequire("RAGuideConfig")
            RAConfirmManager:setConfirmForKey(RAConfirmManager.TYPE.GUIDEID,RAGuideConfig.GuideStartId)
        elseif RAGuideManager.currentGuildId>clientGuideId then
             RAConfirmManager:setConfirmForKey(RAConfirmManager.TYPE.GUIDEID,RAGuideManager.currentGuildId)
        end 
       
        -- if RAGuideManager.currentGuildId then
        --     RAConfirmManager:setConfirmForKey(RAConfirmManager.TYPE.GUIDEID,RAGuideManager.currentGuildId)
        -- end 
        mFrameTime=0
    end  
end
--desc:注册消息
function RAGuideManager.registerHandler()
    MessageManager.registerMessageHandler(MessageDef_Guide.MSG_TaskGuide, onReceiveMessage)
    MessageManager.registerMessageHandler(MessageDef_Guide.MSG_TaskGuideWorld, onReceiveMessage)
    MessageManager.registerMessageHandler(MessageDef_Building.MSG_BuildingMoveToFinshied, onReceiveMessage)
    MessageManager.registerMessageHandler(MessageDef_Building.MSG_Guide_Hud_BtnInfo, onReceiveMessage)
    MessageManager.registerMessageHandler(MessageDef_Guide.MSG_GuideEnd, onReceiveMessage)
    MessageManager.registerMessageHandler(MessageDef_Building.MSG_MainFactory_Levelup, onReceiveMessage)
    MessageManager.registerMessageHandler(MessageDef_World.MSG_MarchEndBattle, onReceiveMessage)
end

--desc:取消消息
function RAGuideManager.unRegisterHandler()
    MessageManager.removeMessageHandler(MessageDef_Guide.MSG_TaskGuide, onReceiveMessage)
    MessageManager.removeMessageHandler(MessageDef_Guide.MSG_TaskGuideWorld, onReceiveMessage)
    MessageManager.removeMessageHandler(MessageDef_Building.MSG_BuildingMoveToFinshied, onReceiveMessage)
    MessageManager.removeMessageHandler(MessageDef_Building.MSG_Guide_Hud_BtnInfo, onReceiveMessage)
    MessageManager.removeMessageHandler(MessageDef_Guide.MSG_GuideEnd, onReceiveMessage)
    MessageManager.removeMessageHandler(MessageDef_Building.MSG_MainFactory_Levelup, onReceiveMessage)
    MessageManager.removeMessageHandler(MessageDef_World.MSG_MarchEndBattle, onReceiveMessage)

end

--desc:显示普通引导框
function RAGuideManager:guideToTarget(param)
    local worldPos = param.pos
    local size = param.size
    RARootManager.AddGuidPage({["guideId"] = RAGameConfig.CommonGuideId, ["pos"] = worldPos, ["size"] = size})
end

--desc:单独圈住建筑按钮
function RAGuideManager:guideToConsturctionBtn()
    local RAMainUIPage = RARequire("RAMainUIPage")
    local constructionNode = UIExtend.getCCNodeFromCCB(RAMainUIPage.mBottomHandler.ccbfile, "mGuildConstructionNode")
    local pos = ccp(0, 0)
    pos.x, pos.y = constructionNode:getPosition()
    local worldPos = constructionNode:getParent():convertToWorldSpace(pos)
    local size = constructionNode:getContentSize()
    local RAGuideConfig=RARequire("RAGuideConfig")
    size.width = size.width + RAGuideConfig.GuideTips.ConfigOffset*2
    size.height = size.height + RAGuideConfig.GuideTips.ConfigOffset*2
    RARootManager.AddGuidPage({["guideId"] = RAGameConfig.CommonGuideId, ["pos"] = worldPos, ["size"] = size})
end

--desc:切换账号调用的接口
function RAGuideManager:reset()
    
    self.partComplete.Guide_First = false
    self.partComplete.Guide_MainCity_Start_2To3 = false
    if RAGameConfig.SwitchGuide == 1 then
        self.currentGuildId = 0
        self.currentPartName = "Guide_First"
    end
    self.guideTaskGuideId = 0
    self.serverGuideId = nil
    self.clientGuideId = nil
    self.unRegisterHandler()

    EnterFrameMananger.removeEnterFrameHandler(EnterFrameDefine.Guide.EF_GuideUpdate, RAGuideManager)
    
end