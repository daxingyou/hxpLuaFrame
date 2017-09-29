RARequire("BasePage")
local guide_conf = RARequire("guide_conf")
local UIExtend = RARequire("UIExtend")
local RARootManager = RARequire("RARootManager")
local RALogicUtil = RARequire("RALogicUtil")
local RAGuideManager = RARequire("RAGuideManager")
local RAStringUtil = RARequire("RAStringUtil")
local RecordManager = RARequire("RecordManager")
local RAGuideConfig = RARequire("RAGuideConfig")

local RAGuidePage = BaseFunctionPage:new(...)
RAGuidePage.guideId = 0
RAGuidePage.constGuideInfo = nil
RAGuidePage.targetPos = nil
RAGuidePage.targetSize = nil
RAGuidePage.forcusNode = nil
RAGuidePage.touchLayer = nil
RAGuidePage.bottomDialogNode = nil

RAGuidePage.bustCCB = nil--任务半身像ccb
--RAGuidePage.bustCCBHandler = {}
RAGuidePage.dialogCCB = nil--保存当前显示的dialogccb
RAGuidePage.dialogCCBHandler = {}

--左侧对话资源
RAGuidePage.leftBustCCB1 = nil
RAGuidePage.leftBustHandler1 = {}
RAGuidePage.leftBustCCB2 = nil
RAGuidePage.leftBustHandler2 = {}
RAGuidePage.leftDialogCCB = nil
RAGuidePage.leftDialogHandler = {}
--右侧对话资源
RAGuidePage.rightBustCCB1 = nil
RAGuidePage.rightBustHandler1 = {}
RAGuidePage.rightBustCCB2 = nil
RAGuidePage.rightBustHandler2 = {}
RAGuidePage.rightDialogCCB = nil
RAGuidePage.rightDialogHandler = {}
--资源保存的数组
RAGuidePage.bustResArray = {}
RAGuidePage.bustHandlerArray = {}
RAGuidePage.dialogResArray = {}
RAGuidePage.dialogHandlerArray = {}

RAGuidePage.circleHandler = {}
RAGuidePage.markHandler = nil
RAGuidePage.markCCB = nil
RAGuidePage.circleCCB = nil
RAGuidePage.isMoveing = false
RAGuidePage.totalTime = 0
RAGuidePage.isDialogInAniRuning = false
RAGuidePage.isVictoryRuning = false
RAGuidePage.victoryCCB = nil
RAGuidePage.preDialogOuting = false--上一步dialog正在弹出
RAGuidePage.isBustDelaying = false--bust正在delay显示

RAGuidePage.startShowPage = false--开始显示页面，用来屏蔽一些快速操作
RAGuidePage.needCircleGrayBG = false--显示蓝色光圈时，是否需要黑色背景：黑色背景的展示来源有两个，一个是guide_conf中配置，一个是同一个步骤重复圈的操作

--延迟响应点击事件
RAGuidePage.isDelayClick = false
RAGuidePage.delayClickTime = 0--已经延迟时间


--desc:新首页的起点
function RAGuidePage:Enter(data)
    UIExtend.loadCCBFile("RAGuidePage.ccbi", self)

    self.guideId = data.guideId
    self.constGuideInfo = guide_conf[self.guideId]

    self.forcusNode = UIExtend.getCCNodeFromCCB(self.ccbfile, "mTargetNode")
    if self.forcusNode then
        self.forcusNode:removeAllChildrenWithCleanup(true)
    end
    self.bottomDialogNode = UIExtend.getCCNodeFromCCB(self.ccbfile, "mBottomGuideTalkNode")
    if self.bottomDialogNode then
        self.bottomDialogNode:removeAllChildrenWithCleanup(true)
    end

    self.totalTime = 0
    self.startShowPage = true
    self.preDialogOuting = false
    self.isDelayClick = false

    --保存资源，易读取
    self.bustResArray[1] = {}
    self.bustHandlerArray[1] = {}
    self.bustResArray[1][1] = self.leftBustCCB1
    self.bustHandlerArray[1][1] = self.leftBustHandler1
    self.bustResArray[1][2] = self.leftBustCCB2
    self.bustHandlerArray[1][2] = self.leftBustHandler2
    self.bustResArray[2] = {}
    self.bustHandlerArray[2] = {}
    self.bustResArray[2][1] = self.rightBustCCB1
    self.bustHandlerArray[2][1] = self.rightBustHandler1
    self.bustResArray[2][2] = self.rightBustCCB2
    self.bustHandlerArray[2][2] = self.rightBustHandler2
    self.dialogResArray[1] = self.leftDialogCCB
    self.dialogHandlerArray[1] = self.leftDialogHandler
    self.dialogResArray[2] = self.rightDialogCCB
    self.dialogHandlerArray[2] = self.rightDialogHandler

    self.targetPos = data.pos--必须是世界坐标，光圈位置
    self.targetSize = data.size--光圈大小

    self:initUIShow()
    
    self.startShowPage = false--显示页面结束
end


--desc:触摸层的点击事件
local touchLayerEventHandler = function(pEvent, pTouch)
    if pEvent == "began" then
        return RAGuidePage:onCenterClick(pTouch)
    elseif pEvent == "ended" then 
        RAGuidePage:onGuideBGClick(pTouch)
    end
end


--desc:点击中圈处理函数，return true：吞噬,走end   return false：向下传递
function RAGuidePage:onCenterClick(pTouch)
    if self.startShowPage then
        return true
    end

    --特殊处理延迟点击事件响应
    if self.isDelayClick then
        return true
    end

    if self.constGuideInfo.enbaleCenterBtn == 1 then
        local RALogicUtil = RARequire('RALogicUtil')
		local isInside = RALogicUtil:isTouchInside(self.forcusNode, pTouch)
        if (isInside and not self.isMoveing) then
            if self.constGuideInfo.closeRightNow==1 then--点击中心按钮，是否立即关闭guidepage
                --RARootManager.AddCoverPage({["update"] = true})
                RARootManager.RemoveGuidePage()--移除guidepage
            end

            if self.constGuideInfo.saveImm and self.constGuideInfo.saveImm == 1 then
                RAGuideManager.saveGuide()
            end

            if self.constGuideInfo.keyWord == RAGuideConfig.KeyWordArray.CircleResourceLand then
                --如果是新手点击资源田，特殊处理
                local RAWorldHudManager = RARequire("RAWorldHudManager")
                local RAWorldBuildingManager = RARequire("RAWorldBuildingManager")
                local result = RAWorldBuildingManager:FindGuideBuilding(World_pb.RESOURCE)
                if result then
                    RAWorldHudManager:ShowHud(result)
                    RALog("RAGuidePage:onCenterClick return true to swallow the touch because keyword == CircleResourceLand")
                    return true--吞噬
                end
            elseif self.constGuideInfo.keyWord == RAGuideConfig.KeyWordArray.CircleMonster then
                --如果是新手点击小怪，特殊处理
                local RAWorldHudManager = RARequire("RAWorldHudManager")
                local RAWorldBuildingManager = RARequire("RAWorldBuildingManager")
                local result = RAWorldBuildingManager:FindGuideBuilding(World_pb.MONSTER)
                if result then
                    RARootManager.AddCoverPage()--弹出小怪攻击页面之前，先屏蔽点击事件，防止双击
                    RAWorldHudManager:ShowHud(result)
                    RALog("RAGuidePage:onCenterClick return true to swallow the touch because keyword == CircleMonster")
                    return true--吞噬
                end
            elseif  self.constGuideInfo.isGuideEnd and self.constGuideInfo.isGuideEnd == 1 then
                MessageManager.sendMessage(MessageDef_Guide.MSG_GuideEnd)--当前阶段的最后一步
            end
            RALog("RAGuidePage:onCenterClick return false to deliver the touch")
            return false
        end
    else
        if self.constGuideInfo.keyWord == RAGuideConfig.KeyWordArray.AddAttackBtn then
            RALog("RAGuidePage:onCenterClick return false to deliver the touch because keyword == AddAttackBtn")
            return false
        end
    end
    RALog("RAGuidePage:onCenterClick return true to swallow the touch")
    return true--吞噬点击事件
end

--desc:点击guidepage背景响应
function RAGuidePage:onGuideBGClick(pTouch)
    if self.startShowPage then
        return
    end

    --特殊处理延迟点击事件响应
    if self.isDelayClick then
        return true
    end

    if (self.constGuideInfo.enableBGBtn == 1 and not self.isMoveing) then

        --特殊对话引导处理
        if self.constGuideInfo.needNewResAndMonster and self.constGuideInfo.needNewResAndMonster == 1 then
            --当前步骤需要提前发消息给后端来创建新手资源田和一级怪，为后面进世界做基础
            local RANetUtil = RARequire("RANetUtil")
            local Newly_pb = RARequire("Newly_pb")
            local msg = Newly_pb.HPGenNewlyData()
            msg.type = Newly_pb.MONSTER_RESOURCE
            RANetUtil:sendPacket(HP_pb.GEN_NEWLY_DATA_C, msg, {retOpcode = -1})
        end
            
            
        --非强制引导，直接关闭引导页
        if self.constGuideInfo.isNotForceGuide and self.constGuideInfo.isNotForceGuide == 1 then
            RARootManager.RemoveGuidePage()
            return
        end

        --对话的动画还没播放完，那么需要特殊处理
        if self.isDialogInAniRuning or self.isBustDelaying then
            self.isDialogInAniRuning = false
            self.bottomDialogNode:stopAllActions()
            self.dialogCCB:runAnimation("KeepIn")
            return
        end

        if self.isVictoryRuning then
            --RAGuidePage.isVictoryRuning = false
            --播放victory的完成动画
--                if RAGuidePage.victoryCCB then
--                    RAGuidePage.victoryCCB:runAnimation("KeepVictory")
--                end
            return
        end

        if RAGuideManager.isInGuide() then
            RARootManager.AddCoverPage({["update"] = true})
        end


        if self.constGuideInfo.currStepGoWorld and self.constGuideInfo.currStepGoWorld == 1 then--去世界，不需要gotoNext，因为世界加载完后，会自动gotoNext
            RARootManager.ChangeScene(SceneTypeList.WorldScene)
            RARootManager.RemoveGuidePage()
        elseif self.constGuideInfo.currStepGoCity and self.constGuideInfo.currStepGoCity == 1 then
            RARootManager.ChangeScene(SceneTypeList.CityScene)
            RARootManager.RemoveGuidePage()
        else
            if self.constGuideInfo.keyWord == RAGuideConfig.KeyWordArray.AddAttackBtn then
                --播放出击音效
                local common = RARequire("common")
                common:playEffect("StrikeSound")
            elseif self.constGuideInfo.isGuideEnd and self.constGuideInfo.isGuideEnd == 1 then
                --当前阶段新手的最后一步
                MessageManager.sendMessage(MessageDef_Guide.MSG_GuideEnd)
            elseif self.constGuideInfo.keyWord == RAGuideConfig.KeyWordArray.CircleFreeBtn then
                --免费加速的时候，不圈免费按钮，全屏点击都是完成当前步骤
                local RAQueueManager = RARequire("RAQueueManager")
                local buildData = RAQueueManager:getFreeTimeBuildData(self.constGuideInfo.buildType)
                if buildData then
                    local RABuildManager = RARequire("RABuildManager")
                    local building = RABuildManager.buildings[buildData.id]
                    RAQueueManager:sendQueueFreeFinish(building.queueData.id)
                end
                return
            end
            if self.constGuideInfo.dialogDelayDestroy and self.constGuideInfo.dialogDelayDestroy == 1 then
                self:delayDestroy()
                return
            end
            RAGuideManager.gotoNextStep()
        end
    elseif ((self.constGuideInfo.enableBGBtn == nil or self.constGuideInfo.enableBGBtn == 0) and not self.isMoveing) then
        --点击到了篮圈范围以外

        if self.constGuideInfo.repeatFocus and self.constGuideInfo.repeatFocus == 1 then
            if pTouch  and (self.constGuideInfo.keyWord == RAGuideConfig.KeyWordArray.CircleResourceLand or self.constGuideInfo.keyWord == RAGuideConfig.KeyWordArray.CircleMonster) then
                local RALogicUtil = RARequire('RALogicUtil')
		        local isInside = RALogicUtil:isTouchInside(self.forcusNode, pTouch)
                if isInside then
                    RALog("RAGuidePage:onGuideBGClick click inside when keyworld = CircleResourceLand or CircleMonster")
                    return
                end
            end
            RALog("RAGuidePage:onGuideBGClick initUIShow again")

            self.needCircleGrayBG = true
            self:initUIShow(self.guideId)
        end
    end
end

--desc:guidepage本身的动画完成回调函数
function RAGuidePage:OnAnimationDone(ccbfile)
	local lastAnimationName = ccbfile:getCompletedAnimationName()
    if lastAnimationName == "LabelAni" then
        RAGuideManager.gotoNextStep()--播放完描述文字动画后，进入下一步
    end
end

--圆圈大小变换完毕后播放loopAni:逻辑转移到enlargeCircleAction函数中，为了衔接光圈的缩小和放大，不能再动画播放完成之后再处理，而是在动画后半部的之后进行放大。
function RAGuidePage.circleHandler:OnAnimationDone(ccbfile)
--	local lastAnimationName = ccbfile:getCompletedAnimationName()
--    if lastAnimationName == "CircleAni" then
--        if RAGuidePage.circleCCB then
--            for i=1, 3,1 do
--                local scale9Sprite = UIExtend.getCCScale9SpriteFromCCB(RAGuidePage.circleCCB, "mGuideTipsAniPic"..i)
--                if scale9Sprite then
--                    --local parentScale = scale9Sprite:getParent():getScale()
--                    local parentScaleAction = CCScaleTo:create(0.05,1,1)
--                    scale9Sprite:getParent():runAction(parentScaleAction)
--                    local size = scale9Sprite:getContentSize()
--                    local scaleX = (RAGuidePage.targetSize.width) / size.width
--                    local scaleY = (RAGuidePage.targetSize.height) / size.height
--                    local scaleAction = CCScaleTo:create(0.05,scaleX,scaleY)
--                    local backInAct = CCEaseSineInOut:create(scaleAction)
--                    scale9Sprite:runAction(backInAct)
----                    scale9Sprite:setScaleX(scaleX)
----                    scale9Sprite:setScaleY(scaleY)
--                    --scale9Sprite:setContentSize(size)
--                end
--            end
--            local callback = function()
--                for i=1, 3,1 do
--                    local scale9Sprite = UIExtend.getCCScale9SpriteFromCCB(RAGuidePage.circleCCB, "mGuideTipsAniPic"..i)
--                    if scale9Sprite then
--                        scale9Sprite:setScale(1)
--                        scale9Sprite:setContentSize(RAGuidePage.targetSize)
--                    end
--                end
--                RAGuidePage.circleCCB:runAnimation("LoopAni")
--                --移动完成后，设置clippingNode到准确状态
--                local clippingNode = UIExtend.getCCNodeFromCCB(RAGuidePage.markCCB, "mGuideMaskNode")
--                if clippingNode then
--                    clippingNode:setScaleX(RAGuidePage.targetSize.width)
--                    clippingNode:setScaleY(RAGuidePage.targetSize.height)
--                end
--                RAGuidePage.isMoveing = false
--             end
--            performWithDelay(RAGuidePage.circleCCB,callback,0.1)
--        end
--    end

end

--desc:同OnAnimationDone函数，光圈的动画播放完成后，需要一个扩展开的动作，需要程序来做
function RAGuidePage:enlargeCircleAction()
    local self = RAGuidePage
    if self.circleCCB then
        self.circleCCB:stopAllActions()
        --播放光圈的扩展开的动作
        for i=1, 3,1 do
            local scale9Sprite = UIExtend.getCCScale9SpriteFromCCB(self.circleCCB, "mGuideTipsAniPic"..i)
            if scale9Sprite then
                --local parentScale = scale9Sprite:getParent():getScale()
                local parentScaleAction = CCScaleTo:create(0.01,1,1)
                scale9Sprite:getParent():runAction(parentScaleAction)
                local size = scale9Sprite:getContentSize()
                local scaleX = (self.targetSize.width) / size.width
                local scaleY = (self.targetSize.height) / size.height
                local scaleAction = CCScaleTo:create(0.01,scaleX,scaleY)
                local backInAct = CCEaseSineInOut:create(scaleAction)
                scale9Sprite:runAction(backInAct)
            end
        end
        --光圈扩展动作完成后要重新设置scale和contensize
        local callback = function()
            for i=1, 3,1 do
                local scale9Sprite = UIExtend.getCCScale9SpriteFromCCB(RAGuidePage.circleCCB, "mGuideTipsAniPic"..i)
                if scale9Sprite then
                    scale9Sprite:setScale(1)
                    scale9Sprite:setContentSize(RAGuidePage.targetSize)
                end
            end
            RAGuidePage.circleCCB:runAnimation("LoopAni")
            --移动完成后，设置clippingNode到准确状态
            local clippingNode = UIExtend.getCCNodeFromCCB(RAGuidePage.markCCB, "mGuideMaskNode")
            if clippingNode then
                clippingNode:setScaleX(RAGuidePage.targetSize.width)
                clippingNode:setScaleY(RAGuidePage.targetSize.height)
            end
            RAGuidePage.isMoveing = false
            RARootManager.RemoveCoverPage()
            end
        performWithDelay(self.circleCCB,callback,0.1)
    end
end

function RAGuidePage.dialogCCBHandler:OnAnimationDone(ccbfile)
    local lastAnimationName = ccbfile:getCompletedAnimationName()
    if lastAnimationName == "InAni" or lastAnimationName == "LabelAni" then
        RAGuidePage.isDialogInAniRuning = false
    end
end

--desc:左侧dialog的响应
function RAGuidePage.leftDialogHandler:OnAnimationDone(ccbfile)
    local lastAnimationName = ccbfile:getCompletedAnimationName()
    if lastAnimationName == "InAni" or lastAnimationName == "LabelAni" then
        RAGuidePage.isDialogInAniRuning = false
    elseif RAGuidePage.preDialogOuting == true and lastAnimationName == "OutAni" then
        RAGuidePage.preDialogOuting = false
    elseif RAGuidePage.constGuideInfo.dialogDelayDestroy and RAGuidePage.constGuideInfo.dialogDelayDestroy == 1 and lastAnimationName == "OutAni" then
        RAGuideManager.gotoNextStep()
    end
end

--desc:点击攻击按钮
function RAGuidePage.leftDialogHandler:onGuideAttackBtn()
    RAGuidePage:onGuideBGClick()
end

--desc:右侧dialog的响应
function RAGuidePage.rightDialogHandler:OnAnimationDone(ccbfile)
    local lastAnimationName = ccbfile:getCompletedAnimationName()
    if lastAnimationName == "InAni" or lastAnimationName == "LabelAni" then
        RAGuidePage.isDialogInAniRuning = false
    elseif RAGuidePage.preDialogOuting == true and lastAnimationName == "OutAni" then
        RAGuidePage.preDialogOuting = false
    elseif RAGuidePage.constGuideInfo.dialogDelayDestroy and RAGuidePage.constGuideInfo.dialogDelayDestroy == 1 and lastAnimationName == "OutAni" then
        RAGuideManager.gotoNextStep()
    end
end

--desc:点击攻击按钮
function RAGuidePage.rightDialogHandler:onGuideAttackBtn()
    RAGuidePage:onGuideBGClick()
end

--desc:延迟消失处理函数
function RAGuidePage:delayDestroy()
    if self.constGuideInfo.dialogDelayDestroy and self.constGuideInfo.dialogDelayDestroy == 1 then
        if self.constGuideInfo.picDirection == 1 then
            self.bustCCB:runAnimation("LeftOutAni")
        elseif self.constGuideInfo.picDirection == 2 then
            self.bustCCB:runAnimation("RightOutAni")
        end
        
        self.dialogCCB:runAnimation("OutAni")
    end
end

--desc:如果当前guidepage正在显示，那么会直接调用此接口
function RAGuidePage:refreshPage(data)
    self.startShowPage = true--开始显示页面

    if data.guideId then
        self.guideId = data.guideId
    end

    self.totalTime = 0

    if data.pos then
        self.targetPos = data.pos--必须是世界坐标，光圈位置
    else
        self.targetPos = nil
    end

    if data.size then
        self.targetSize = data.size--光圈大小
    else
        self.targetSize = nil
    end
    self.isDelayClick = false

    self:initUIShow(self.guideId)

    self.startShowPage = false--显示页面结束
end

--desc：如果当前步骤具有update参数，那么这里就会每一帧被调用
function RAGuidePage:Execute()
    if self.constGuideInfo.closeDelay and self.constGuideInfo.closeDelay > 0 then
        local dt = GamePrecedure:getInstance():getFrameTime()
        self.totalTime = self.totalTime + dt
        if self.totalTime >= self.constGuideInfo.closeDelay then
            self.totalTime = 0
            RARootManager.RemoveGuidePage()
            RARootManager.RemoveCoverPage()
        end
    elseif self.isDelayClick then
        local dt = GamePrecedure:getInstance():getFrameTime()
        self.delayClickTime = self.delayClickTime + dt
        if self.delayClickTime >= self.constGuideInfo.delayClick then
            self.isDelayClick = false
            self.delayClickTime = 0
        end
    end
end

--desc:跳过按钮的响应事件
function RAGuidePage:onJumpGuide()
    RAGuideManager.jumpAllGuide()
    RARootManager.RemoveCoverPage()
    RARootManager.RemoveGuidePage()
end

--desc:根据当前步骤处理页面展示
function RAGuidePage:initUIShow(guideId)
    if guideId ~= nil then
        self.constGuideInfo = guide_conf[guideId]
    end

    --处理延迟响应点击
    if self.constGuideInfo.delayClick and self.constGuideInfo.delayClick > 0 then
        self.isDelayClick = true
        self.delayClickTime = 0
    else
        self.isDelayClick = false
    end

    local limitResult = true--记录当前步骤限制条件是否满足
    if self.constGuideInfo then
        --判断当前步骤的限制条件
        limitResult = RAGuideManager.judgeLimitParam(self.constGuideInfo.limitParam)
        if not limitResult then
           UIExtend.setNodeVisible(self.ccbfile, "mJumpGuide", true)
        else
           UIExtend.setNodeVisible(self.ccbfile, "mJumpGuide", false)
        end

        if self.constGuideInfo.showBG and self.constGuideInfo.showBG > 0 then
            --todo: 显示背景图片，尽量控制显隐
        else
            --todo: 隐藏背景图片节点
        end

        

        if self.constGuideInfo.showVictory and self.constGuideInfo.showVictory == 1 then
            local this = self
            self.isVictoryRuning = true

            if self.victoryCCB == nil then
                local victoryHandler = {
                    OnAnimationDone = function (_self, ccbfile)
                        local lastAnimationName = ccbfile:getCompletedAnimationName()
                        if lastAnimationName == "VictoryAni" or lastAnimationName == "KeepVictory" then
                            this.isVictoryRuning = false
                        end
                    end
                }
                self.victoryCCB = UIExtend.loadCCBFile("Ani_Guide_Victory.ccbi", victoryHandler)
                if self.victoryCCB then
                    UIExtend.addNodeToParentNode(self.ccbfile, "mVictoryNode", self.victoryCCB)
                end
            end
            self.victoryCCB:runAnimation("VictoryAni")
            --播放胜利音效
            --战车工厂播放音效
            local common = RARequire("common")
            common:playEffect("VictorySound")

            performWithDelay(self:getRootNode(), function ()
                UIExtend.setNodeVisible(this.ccbfile, "mClickScreenTips", true)     
            end, 2)--2S之后显示提示点击屏幕
        else
            if self.victoryCCB then
                self.victoryCCB:removeFromParentAndCleanup(true)
                self.victoryCCB = nil
            end
            UIExtend.setNodeVisible(self.ccbfile, "mClickScreenTips", false) 
        end

        --播放离开动画
        if self.constGuideInfo.needRunLeaveAni and self.constGuideInfo.needRunLeaveAni == 1 then
            if self.constGuideInfo.picLeaveDirection and self.constGuideInfo.picLeaveDirection == 1 then
                if self.bustCCB then
                    self.bustCCB:runAnimation("LeftOutAni")
                end
            else
                if self.bustCCB then
                    self.bustCCB:runAnimation("RightOutAni")
                end
            end
        end
        if self.constGuideInfo.needRunDialogLeaveAni and self.constGuideInfo.needRunDialogLeaveAni == 1 then
            if self.dialogCCB then
                self.preDialogOuting = true
                self.dialogCCB:runAnimation("OutAni")
            end
        end

        --显示guidepage的描述文字
        if self.constGuideInfo.showDescription and self.constGuideInfo.showDescription == 1 then
            --播放音效
            --播放打字机音效
            local common = RARequire("common")
            common:playEffect("DialogueAdmission") 

            local RAPlayerInfoManager = RARequire("RAPlayerInfoManager")
            local worldPos = RAPlayerInfoManager.getWorldPos()
            local desStr = _RALang("@GuideStartDesc", worldPos.x, worldPos.y)
            UIExtend.setNodeVisible(self.ccbfile, "mGuideLabel", true)
            --UIExtend.setCCLabelString(self.ccbfile, "mGuideLabel", desStr)

            UIExtend.setCCLabelHTMLString(self.ccbfile, "mGuideLabel", RAStringUtil:getHTMLString('GuideStartDesc',worldPos.x, worldPos.y))

            self.ccbfile:runAnimation("LabelAni")
        else
            UIExtend.setNodeVisible(self.ccbfile, "mGuideLabel", false)
        end

        if self.constGuideInfo.showPic == 1 then
            --显示半身像
            --先判断对话框的ccb是否存在，因为半身像是挂在对话框的ccb上的
            local icon = self.constGuideInfo.pic
            local dialogCCBName = self.constGuideInfo.dialogRes or "RAGuideLabelBlueNode"
            dialogCCBName = dialogCCBName .. ".ccbi"

            local dialogIndex = self.constGuideInfo.dialogIndex
            local picDirection = self.constGuideInfo.picDirection
            local picIndex = self.constGuideInfo.picIndex

            --如果需要重新加载dialogres的话，需要把它realse掉，然后把它上面的bustRes挂在到新的dialogres上来
            if self.constGuideInfo.needReLoadDialogRes and self.constGuideInfo.needReLoadDialogRes == 1 then
                if self.dialogResArray[dialogIndex] then
                    for i=1, 2 do
                        if self.bustResArray[picDirection][i] then
                            self.bustResArray[picDirection][i]:removeFromParentAndCleanup(false)
                        end
                    end

                    UIExtend.releaseCCBFile(self.dialogResArray[dialogIndex])
                    self.dialogResArray[dialogIndex] = nil
                end

                self.dialogResArray[dialogIndex] = UIExtend.loadCCBFile(dialogCCBName, self.dialogHandlerArray[dialogIndex])
                self.bottomDialogNode:addChild(self.dialogResArray[dialogIndex])

                for i=1, 2 do
                    if self.bustResArray[picDirection][i] then
                        UIExtend.addNodeToParentNode(self.dialogResArray[dialogIndex], "mBustNode", self.bustResArray[picDirection][i])
                    end
                end
            end

            if self.dialogResArray[dialogIndex] == nil then
                self.dialogResArray[dialogIndex] = UIExtend.loadCCBFile(dialogCCBName, self.dialogHandlerArray[dialogIndex])
                self.bottomDialogNode:addChild(self.dialogResArray[dialogIndex])
            else
                self.dialogResArray[dialogIndex]:runAnimation("KeepOut")
            end

            local bustNewLoad = false
            if self.bustResArray[picDirection][picIndex] == nil then
                bustNewLoad = true
                self.bustResArray[picDirection][picIndex] = UIExtend.loadCCBFile("RAGuideBustNode.ccbi", self.bustHandlerArray[picDirection][picIndex])
                UIExtend.addNodeToParentNode(self.dialogResArray[dialogIndex], "mBustNode", self.bustResArray[picDirection][picIndex])
            end
            UIExtend.setCCLabelString(self.dialogResArray[dialogIndex], "mGuideName", _RALang(self.constGuideInfo.picName))
            self.dialogResArray[dialogIndex]:setVisible(true)
            self.bustResArray[picDirection][picIndex]:setVisible(true)
            
            

            if picDirection == 1 then
                UIExtend.setSpriteIcoToNode(self.bustResArray[picDirection][picIndex], "mLeftBustPic", icon)
                if (self.constGuideInfo.needRunInAni and self.constGuideInfo.needRunInAni == 1) or bustNewLoad then
                    --需要播放进入动画，延迟播放或者直接播放
                    if self.constGuideInfo.dialogDelayShow and self.constGuideInfo.dialogDelayShow == 1 then
                        self.isBustDelaying = true--设置bust delay show的标示
                        performWithDelay(self:getRootNode(), function ()
                            self.bustResArray[picDirection][picIndex]:runAnimation("LeftAni")
                            self.isBustDelaying = false
                        end, RAGuideConfig.DialogDelayShowTime)
                    else
                        self.bustResArray[picDirection][picIndex]:runAnimation("LeftAni")
                    end
                    
                end
            elseif picDirection == 2 then
                UIExtend.setSpriteIcoToNode(self.bustResArray[picDirection][picIndex], "mRightBustPic", icon)
                if (self.constGuideInfo.needRunInAni and self.constGuideInfo.needRunInAni == 1) or bustNewLoad then
                    --需要播放进入动画
                    if self.constGuideInfo.dialogDelayShow and self.constGuideInfo.dialogDelayShow == 1 then
                        self.isBustDelaying = true--设置bust delay show的标示
                        performWithDelay(self:getRootNode(), function ()
                            self.bustResArray[picDirection][picIndex]:runAnimation("RightAni")
                            self.isBustDelaying = false
                        end, RAGuideConfig.DialogDelayShowTime)
                    else
                        self.bustResArray[picDirection][picIndex]:runAnimation("RightAni")
                    end
                end
            end

            self.bustCCB = self.bustResArray[picDirection][picIndex]--保存当前显示的bust资源
            self.dialogCCB = self.dialogResArray[dialogIndex]--保存当前显示的dialog资源
        else
            if self.dialogCCB then
                self.dialogCCB:setVisible(false)
            end
        end

        if self.constGuideInfo.showDialog == 1 then
            --显示对话
            self.bottomDialogNode:setVisible(true)

            if self.constGuideInfo.needRunDialogInAni and self.constGuideInfo.needRunDialogInAni==1 then
                --播放dialog动画
                if self.dialogCCB then
                    if self.constGuideInfo.dialogDelayShow and self.constGuideInfo.dialogDelayShow == 1 then
                        performWithDelay(self.bottomDialogNode, function ()
                            if not self.isDialogInAniRuning then
                                return--此刻代表对话框已经完全显示，不再需要播放动画
                            end
                            self.dialogCCB:runAnimation("InAni")
                            --播放打字机音效
                            local common = RARequire("common")
                            common:playEffect("DialogueAdmission") 
                        end, RAGuideConfig.DialogDelayShowTime)
                    else
                        self.dialogCCB:runAnimation("InAni")
                        --播放打字机音效
                        local common = RARequire("common")
                        common:playEffect("DialogueAdmission") 
                    end

                    self.isDialogInAniRuning = true
                end
            else
                --播放打字机动画
                if self.dialogCCB then
                    self.dialogCCB:runAnimation("LabelAni")
                    self.isDialogInAniRuning = true
                    --播放打字机音效
                    local common = RARequire("common")
                    common:playEffect("DialogueAdmission")
                end
            end

            --新手对话打点
            if self.constGuideInfo.recordDetailGuideId then
                RecordManager.recordNoviceGuide(self.constGuideInfo.recordDetailGuideId)
            end

            UIExtend.setCCLabelHTMLString(self.dialogCCB, "mRightGuideLabel", RAStringUtil:getHTMLString(self.constGuideInfo.dialogKey))

            --处理出击按钮
            local keyWord = RAGuideManager.getKeyWordById(RAGuideManager.currentGuildId)
            local attackNode = UIExtend.getCCNodeFromCCB(self.dialogCCB, "mAttackNode")
            if keyWord == RAGuideConfig.KeyWordArray.AddAttackBtn then
                attackNode:setVisible(true)
            else
                attackNode:setVisible(false)
            end
        else
            self.bottomDialogNode:setVisible(false)
        end
    end
   

    if self.constGuideInfo.isGray == 1 or self.constGuideInfo.isBlack == 1 then
        UIExtend.setNodeVisible(self.ccbfile, "mBGColor", true)
        local bgLayerColor = UIExtend.getCCLayerColorFromCCB(self.ccbfile, "mBGColor")
        if bgLayerColor then
            local opacityValue = self.constGuideInfo.isGray == 1 and 150 or 255
            bgLayerColor:setOpacity(opacityValue)
        end
    else
        UIExtend.setNodeVisible(self.ccbfile, "mBGColor", false)
    end

    --处理亮变暗和暗变亮
    if self.constGuideInfo.lightToDark and self.constGuideInfo.lightToDark ~= 0 then
        UIExtend.setNodeVisible(self.ccbfile, "mBGColor", true)

        local bgLayerColor = UIExtend.getCCLayerColorFromCCB(self.ccbfile, "mBGColor")
        if bgLayerColor then
            local fadeAction = nil
            local const_conf = RARequire("const_conf")
            local fadeTime = const_conf.GuideBGFadeTime.value
            if self.constGuideInfo.lightToDark == 1 then
                bgLayerColor:setOpacity(0)
                fadeAction = CCFadeTo:create(fadeTime, 150)
            elseif self.constGuideInfo.lightToDark == -1 then
                bgLayerColor:setOpacity(150)
                fadeAction = CCFadeTo:create(fadeTime, 0)
            end

            local callfunc = CCCallFunc:create(function ()
                RARootManager.AddCoverPage()
                RAGuideManager.gotoNextStep()
            end)
            local sequence = CCSequence:createWithTwoActions(fadeAction, callfunc)
            bgLayerColor:runAction(sequence)
        end
    end



    --需要移动
    if self.targetPos ~= nil then
        if self.markCCB == nil then
            self.markHandler = {}
            self.markCCB = UIExtend.loadCCBFile("RAGuideMaskNode.ccbi",self.markHandler)--光圈母节点
            if self.forcusNode then
                self.forcusNode:addChild(self.markCCB)
            end
        else
            self.markCCB:setVisible(true)
        end
        
        
        --deal with mark node
        if self.markCCB then
            --设置clipplingNode
            local clippingNode = UIExtend.getCCNodeFromCCB(self.markCCB, "mGuideMaskNode")
            if clippingNode then
                clippingNode:setScale(1)--设置为初始状态
            end

            --设置圈框时的黑色背景逻辑，使用clippingNode
            if self.constGuideInfo.isGray==1 or self.needCircleGrayBG == true then
                UIExtend.setNodeVisible(self.ccbfile, "mBGColor", false)--出现圆圈的时候，背景置灰只用clippingnode，不能使用背景。
                UIExtend.setNodeVisible(self.markCCB, "mGuideMaskNode", true)
                self.needCircleGrayBG = false
            elseif self.constGuideInfo.isGray == 0 then
                UIExtend.setNodeVisible(self.markCCB, "mGuideMaskNode", false)
            end

            --设置areanode
            local areaNode = UIExtend.getCCNodeFromCCB(self.markCCB, "mAreaNode")
            if areaNode then
                areaNode:setContentSize(self.targetSize)
            end

            --加载光圈
            if self.circleCCB == nil then
                self.circleCCB = UIExtend.loadCCBFile("Ani_Guide_Tips.ccbi", self.circleHandler)--光圈
                if self.markCCB then
                    self.markCCB:addChild(self.circleCCB)
                end
            else
                self.circleCCB:setVisible(true)
            end
            if self.circleCCB then
                for i=1, 3 do
                    local scale9Sprite = UIExtend.getCCScale9SpriteFromCCB(self.circleCCB, "mGuideTipsAniPic"..i)
                    if scale9Sprite then
                        local size = CCSize(64, 64)
                        scale9Sprite:setContentSize(size)--设置光圈初始大小
                        size:delete()
                    end
                end
            end

            --把光圈加入到母节点中
            if self.forcusNode then
                self.forcusNode:setVisible(true)
                local forcusNodePos = ccp(self.forcusNode:getPositionX(), self.forcusNode:getPositionY())
                local realTargetPos = self.forcusNode:getParent():convertToNodeSpace(self.targetPos)--worldSpace坐标转换成nodeSpace坐标
                local vector = ccpSub(realTargetPos, forcusNodePos)
                forcusNodePos:delete()
                local moveAction = CCMoveBy:create(0.4, vector)
                self.forcusNode:setContentSize(self.targetSize)--设置focusnode的ContentSize，用来判断坐标点击区域
                self.markCCB:setPosition(self.targetSize.width / 2, self.targetSize.height / 2)--设置markccb的位置
                self.circleCCB:runAnimation("CircleAni")
                local common = RARequire("common")
                common:playEffect("GuideSound")
                performWithDelay(self.forcusNode,RAGuidePage.enlargeCircleAction,0.3)
                --self.forcusNode:runAction(moveAction)--把focusnode移动到目标区域
                self.forcusNode:setPosition(realTargetPos)
                self.isMoveing = true
            end
        end
    else--不需要移动
        if self.forcusNode then
             self.forcusNode:setVisible(false)
        end
    end


     --创建滑动layer
    if self.touchLayer == nil then
        self.touchLayer = CCLayer:create()
        self.touchLayer:registerScriptTouchHandler(touchLayerEventHandler, false, GuideLayerPriority, true)--设置touchlayer的swallow
        self.touchLayer:setContentSize(CCDirector:sharedDirector():getOpenGLView():getVisibleSize())--设置touchlayer大小
        self:getRootNode():addChild(self.touchLayer, 1)
        self.touchLayer:setAnchorPoint(0, 0)
        self.touchLayer:setPosition(0, 0)
        self.touchLayer:setTouchMode(kCCTouchesOneByOne)
        self.touchLayer:setTouchEnabled(true)
    else
        self.touchLayer:setTouchEnabled(true)
    end

    --如果当前步骤限制条件不满足
    if not limitResult then
        self.touchLayer:removeFromParentAndCleanup(true)
        self.touchLayer = nil
    end
	
	--如果是圈住的引导就等圈完之后再移除cover层
    if self.targetPos ~= nil and self.markCCB and self.forcusNode then
        return 
    end

    RARootManager.RemoveCoverPage()
end

--desc:页面被销毁的时候调用
function RAGuidePage:Exit(data)
    if self.targetPos then
        self.targetPos:delete()
        self.targetPos = nil
    end
    if self.targetSize then
        self.targetSize:delete()
        self.targetSize = nil
    end
    self.bottomDialogNode = nil
    self.isMoveing = false
    self.totalTime = 0

    self.isDelayClick = false
    self.delayClickTime = 0
    

    if self.touchLayer then
        self.touchLayer:removeFromParentAndCleanup(true)
        self.touchLayer = nil
    end

    if self.victoryCCB then
        self.victoryCCB:removeFromParentAndCleanup(true)
        self.victoryCCB = nil
        UIExtend.setNodeVisible(self.ccbfile, "mClickScreenTips", false) 
    end

    if self.markCCB then
        UIExtend.unLoadCCBFile(self.markHandler)
        self.markHandler = nil
        self.markCCB = nil
    end

    if self.circleHandler then
        UIExtend.unLoadCCBFile(self.circleHandler)
        self.circleCCB = nil
    end
    
    for k, resArr in ipairs(self.bustResArray) do
        for m, res in ipairs(resArr) do
            if res then
                UIExtend.releaseCCBFile(res)
            end
        end
    end
    self.bustResArray = {}
    self.bustHandlerArray = {}
    self.bustCCB = nil

    for k, res in ipairs(self.dialogResArray) do
        if res then
            UIExtend.releaseCCBFile(res)
        end
    end
    self.dialogResArray = {}
    self.dialogHandlerArray = {}
    self.dialogCCB = nil

    self.isDialogInAniRuning = false
    self.preDialogOuting = false

    UIExtend.unLoadCCBFile(self)
end