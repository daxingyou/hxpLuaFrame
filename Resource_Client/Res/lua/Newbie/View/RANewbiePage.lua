-- RANewbiePage
-- 士兵集结开始页面

RARequire('BasePage')
local UIExtend = RARequire('UIExtend')
local Utilitys = RARequire('Utilitys')
local RARootManager = RARequire("RARootManager")
local common = RARequire('common')
local RAStringUtil = RARequire('RAStringUtil')
local RANewbieConfig = RARequire('RANewbieConfig')
local RANewbieNodeHelper = RARequire('RANewbieNodeHelper')
local newbie_step_conf = RARequire('newbie_step_conf')  

local RANewbiePage = BaseFunctionPage:new(...)

RANewbiePage.vars = {
    defaultStr = "",
    defaultRoleIconDir = -1,
    defaultlastRoleIconDir = 0,
    defaultbgLayerAlphaInitr = 0,
    defaultstepDuration = 1,

}


-- false时不会处理新手点击，
-- 仅当该步骤初始化完毕后设置为true，
-- 当步骤完成时要设置为false
RANewbiePage.mIsCanHandle = false

local OnReceiveMessage = function(message)     
    -- if message.messageID == MessageDef_World.MSG_ArmyFreeCountUpdate then
    --     --需要整个UI cell重新计算
    --     CCLuaLog("MessageDef_World MSG_ArmyFreeCountUpdate")
    --     RANewbiePage:RefreshUIWhenSelectedChange()
    -- end

    -- if message.messageID == MessageDef_World.MSG_ArmyChangeSelectedCount then
    --     --需要刷新cell数据和UI
    --     CCLuaLog("MessageDef_World MSG_ArmyChangeSelectedCount")
    --     RANewbiePage:RefreshUIWhenSelectedChange(message.actionType, message.armyId, message.selectCount)
    -- end
end

function RANewbiePage:registerMessageHandlers()
    -- MessageManager.registerMessageHandler(MessageDef_World.MSG_ArmyFreeCountUpdate, OnReceiveMessage)
    -- MessageManager.registerMessageHandler(MessageDef_World.MSG_ArmyChangeSelectedCount, OnReceiveMessage)

    MessageManager.registerMessageHandler(MessageDef_Packet.MSG_Operation_Fail, OnReceiveMessage)
end

function RANewbiePage:unregisterMessageHandlers()
    -- MessageManager.removeMessageHandler(MessageDef_World.MSG_ArmyFreeCountUpdate, OnReceiveMessage)
    -- MessageManager.removeMessageHandler(MessageDef_World.MSG_ArmyChangeSelectedCount, OnReceiveMessage)

    MessageManager.removeMessageHandler(MessageDef_Packet.MSG_Operation_Fail, OnReceiveMessage)
end


function RANewbiePage:resetData()

    self.stepDatas = nil
    self.forcusNode = nil
    self.bottomDialogNode =nil
    self.victoryNode = nil
    self.guideLabelNode = nil
    self.clickScreenTipsNode = nil
    self:releaseDialogCell()
    self.maskCell:Release()
    self.victoryCell:Release()
    self.maskCell = nil
    self.victoryCell = nil

end

function RANewbiePage:Enter(data)
    CCLuaLog("RANewbiePage:Enter")  

    self:registerMessageHandler()

    UIExtend.loadCCBFile("RAGuidePage.ccbi", self)

    -- 引导setp的数据
    self.stepDatas = data

    -- 获得所有显示ccbi的跟节点 默认全部隐藏
    self:initGuideViewNode()

    -- 根据显示类型开启显示内容 
    self:handleDisplayLogic(self.stepDatas.v_type)
end


function RANewbiePage:initGuideViewNode()
    -- 框选node
    self.forcusNode = UIExtend.getCCNodeFromCCB(self.ccbfile, "mTargetNode")

    -- 对话node 
    self.bottomGuideTalkNode = UIExtend.getCCNodeFromCCB(self.ccbfile, "mBottomGuideTalkNode")

    -- 胜利node
    self.victoryNode = UIExtend.getCCNodeFromCCB(self.ccbfile, "mVictoryNode")

    -- 黑屏显示文字node
    self.guideLabelNode = UIExtend.getCCLabelHTMLFromCCB(self.ccbfile, "mGuideLabel")

    -- 提示点击屏幕文本
    self.clickScreenTipsNode = UIExtend.getCCLabelTTFFromCCB(self.ccbfile, "mClickScreenTips")

    -- 初始化所有CCB
    self.dialogCellTb = {}
    self.roleCellTb = {}
    for k,v in pairs(RANewbieConfig.DialogCCBConfig) do
        local dialogCCBName = k
        local dialogCell = RANewbieNodeHelper:CreateLabelCell(dialogCCBName)
        local dialogCCB = dialogCell:Load()
        self.bottomDialogNode:addChild(dialogCCB)
        
        local roleCell = RANewbieNodeHelper:CreateRoleCell()
        local roleCCB = roleCell:Load()
        local bustNode = UIExtend.getCCNodeFromCCB(dialogCCB, "mBustNode")
        bustNode:addChild(roleCCB)
        self.dialogCellTb[k] = dialogCell
        self.roleCellTb[k] = roleCell
    end

    local maskCell = RANewbieNodeHelper:CreateMaskCell()
    local maskCCB = maskCell:Load()
    self.forcusNode:addChild(maskCCB)
    self.maskCell = maskCell


    local victoryCell = RANewbieNodeHelper:CreateVictoryCell()
    local victoryCCB = circleCell:Load()
    self.victoryNode:addChild(victoryCCB)
    self.victoryCell = victoryCell

    self:hideGuideViewCCBNodes()

end

function RANewbiePage:hideGuideViewCCBNodes()

    self.forcusNode:setVisible(false)
    self.bottomDialogNode:setVisible(false)
    self.victoryNode:setVisible(false)
    self.guideLabelNode:setVisible(false)
    self.clickScreenTipsNode:setVisible(false)

end

function RANewbiePage:Execute()
    
end


function RANewbiePage:CommonRefresh(data)
    CCLuaLog("RANewbiePage:CommonRefresh") 
    self.stepDatas = data
    self:handleDisplayLogic(self.stepDatas.v_type)
end


function RANewbiePage:onClose()
    CCLuaLog("RANewbiePage:onClose") 
    RARootManager.ClosePage('RANewbiePage')
end

function RANewbiePage:setCanHandle(isCan)

end

-- 处理根据不同类型下，页面的显示
function RANewbiePage:handleDisplayLogic(viewType)
    self:hideGuideViewCCBNodes()
    if viewType == RANewbieConfig.Enum_StepViewType.Role_Only then
        -- 半身像+文字
        self:displayBustAndWords()
    elseif viewType == RANewbieConfig.Enum_StepViewType.Rect_Only then
        -- 框选
        self:displayMaskCircle()
    elseif viewType == RANewbieConfig.Enum_StepViewType.Rect_With_Role then
        -- 框选 + 半身像 + 文字
        self:displayBustAndWords()
        self:displayMaskCircle()
    elseif viewType == RANewbieConfig.Enum_StepViewType.BlackBg_With_Label then
        -- 只有黑屏+文字
        self:displayBgColorWord()
    elseif viewType == RANewbieConfig.Enum_StepViewType.Victory_Only then
        -- 显示成功页面
        self:displayVictory()
    end 
end


function RANewbiePage:showDialogCell( dialogCCBName )
    for k,v in pairs(self.dialogCellTb) do
        local ccb = v:GetCCBFile()
        local CCBFileName = v:GetCCBName()
        if CCBFileName == dialogCCBName then
            ccb:setVisible(true)
        else
            ccb:setVisible(false)
        end 
    end
end
-- 显示半身像+文字
function RANewbiePage:displayBustAndWords()

    self.bottomDialogNode:setVisible(true)
    local dialogContent = self.stepDatas.v_1_roleDialogContent
    local dialogCCBName = self.stepDatas.v_1_dialogCCB
    local dialogCell = self.dialogCellTb[dialogCCBName]
    self:showDialogCell(dialogCCBName)
    dialogCell:SetLabel("mRightGuideLabel", dialogContent)
    local roleName = _RALang(self.stepDatas.v_1_roleName)
    dialogCell:SetLabel("mGuideName", roleName)
    

    local dialogAniData  = RAStringUtil:split(self.stepDatas.v_1_dialogAniData,"_")
    local inAni = tonumber(dialogAniData[1])
    if inAni == 1 then
        dialogCell:PlayAnimation("InAni") 
    elseif inAni == 0 then
        dialogCell:PlayAnimation("LabelAni")
    end

    common:playEffect("DialogueAdmission")

    --处理出击按钮
    local btnStr = self.stepDatas.v_1_dialogBtnStr
    local attackNode = UIExtend.getCCNodeFromCCB(dialogCell:GetCCBFile(), "mAttackNode")

    if btnStr == "" or not string.find(btnStr,"@") then
         attackNode:setVisible(false)
    else
        attackNode:setVisible(true)
    end 


    --半身像
    local roleIcon = self.stepDatas.v_1_roleIcon
    local roleIconDir = self.stepDatas.v_1_roleIconDir
    local roleCell = self.roleCellTb[dialogCCBName]
    self:displayBustAnimation(roleIconDir,roleIcon, roleCell)
   
end

-- 半身像的出场动画
function RANewbiePage:displayBustAnimation(roleIconDir,roleIcon, roleCell)
    local roleCCB = roleCell:GetCCBFile()

    local roleIconAniData = RAStringUtil:split(self.stepDatas.v_1_iconAniData,"_")
    local roleInAni = tonumber(roleIconAniData[1]) 

    if roleIconDir == 1 then
        UIExtend.setSpriteIcoToNode(roleCCB, "mLeftBustPic", roleIcon)
        if roleInAni == 1 then
            roleCell:RunInAni(true)
        end
        
    elseif roleIconDir == 2 then
        UIExtend.setSpriteIcoToNode(roleCCB, "mRightBustPic", roleIcon)
        if roleInAni == 1 then
            roleCell:RunInAni(false)
        end
    end 
end

function RANewbiePage:releaseDialogCell()

    for k,v in pairs(self.dialogCellTb) do
        local dialogCell = v
        local roleCell = self.roleCellTb[k]
        dialogCell:Release()
        roleCell:Release()
        v = nil
        self.roleCellTb[k] = nil
    end

    self.dialogCellTb = nil
    self.roleCellTb = nil

end

-- 点击对话框播离开动画
function RANewbiePage:dialogOutAni( )
    -- body
    local dialogAniData  = RAStringUtil:split(self.stepDatas.v_1_dialogAniData,"_")
    local outAni = tonumber(dialogAniData[2])
    if outAni == 1 then
        local dialogCell = self.dialogCellTb[self.stepDatas.v_1_dialogCCB]
        dialogCell:PlayAnimation("OutAni")
    end 

end

-- 点击离开动画
function RANewbiePage:roleOutAni( )
        -- body
    local roleAniData  = RAStringUtil:split(self.stepDatas.v_1_iconAniData,"_")
    local outAni = tonumber(roleAniData[2])
    local roleIconDir = self.stepDatas.v_1_roleIconDir

    if outAni == 1 then
        local roleCell = self.roleCellTb[self.stepDatas.v_1_dialogCCB]
        if roleIconDir == -1 then
            roleCell:RunOutAni(true)
        elseif roleIconDir == 1 then
            roleCell:RunOutAni(false)
        end
    end 

end
-- 显示光圈框选区域
function RANewbiePage:displayMaskCircle()

    self.forcusNode:setVisible(true)

    -- 1 获取目标节点的位置和大小
    local targetPageHandle = UIExtend.GetPageHandler(self.stepDatas.h_targetPageName)
    local targetPageCCBfile = targetPageHandle.ccbfile
    local targetNode = UIExtend.getCCNodeFromCCB(targetPageCCBfile,self.stepDatas.h_targetNodeName)
    local targetPos =  targetNode:getParent():convertToWorldSpaceAR(ccp(targetNode:getPositionX(),targetNode:getPositionY()))
    local targetSize = targetNode:getContentSize()
    targetSize = CCSizeMake(targetSize.width+RANewbieConfig.GuideTips.ConfigOffset*2, targetSize.height+RANewbieConfig.GuideTips.ConfigOffset*2)

    local maskCell = self.maskCell
    local maskCCB = maskCell:GetCCBFile()

    -- 2 遮罩以及裁剪的提前设置
    local clippingNode = UIExtend.getCCNodeFromCCB(markCCB, "mGuideMaskNode")
    if clippingNode then
        clippingNode:setScale(1)--设置为初始状态
    end

     --设置圈框时的黑色背景逻辑，使用clippingNode
    UIExtend.setNodeVisible(markCCB, "mGuideMaskNode", true)
    UIExtend.setNodeVisible(self.ccbfile, "mBGColor", false)
     --设置areanode
    local areaNode = UIExtend.getCCNodeFromCCB(markCCB, "mAreaNode")
    areaNode:setContentSize(targetSize)

     -- 3 设置光圈初始信息
    self:initMaskCircle(markCCB, targetPos, targetSize)
    
end

function RANewbiePage:initMaskCircle(markCCB, targetPos, targetSize)

    local circleCCB = UIExtend.getCCBFileFromCCB(markCCB,"mGuideAniTipsCCB")
    for i=1, 3 do
        local scale9Sprite = UIExtend.getCCScale9SpriteFromCCB(circleCCB, "mGuideTipsAniPic"..i)
        if scale9Sprite then
            local size = CCSize(RANewbieConfig.GuideTips.ConfigWidth, RANewbieConfig.GuideTips.ConfigHeight)
            scale9Sprite:setContentSize(size)
            size:delete()
        end
    end

    local forcusNodePos = ccp(self.forcusNode:getPositionX(), self.forcusNode:getPositionY())
    --worldSpace坐标转换成nodeSpace坐标
    local realTargetPos = self.forcusNode:getParent():convertToNodeSpace(targetPos)
    local vector = ccpSub(realTargetPos, forcusNodePos)
    forcusNodePos:delete()
    local moveAction = CCMoveBy:create(0.4, vector)
    --设置focusnode的ContentSize，用来判断坐标点击区域
    self.forcusNode:setContentSize(targetSize)
    --设置markccb的位置
    markCCB:setPosition(targetSize.width / 2, targetSize.height / 2)
    circleCCB:runAnimation("CircleAni")
    common:playEffect("GuideSound")
    performWithDelay(self.forcusNode,function ()
         -- 4 设置光圈动画效果
        self:enlargeCircleAction(circleCCB, markCCB, targetSize)
    end,0.3)

    self.forcusNode:setPosition(realTargetPos)

end

function RANewbiePage:enlargeCircleAction(circleCCB, markCCB, targetSize)
    circleCCB:stopAllActions()
    for i=1, 3,1 do
        local scale9Sprite = UIExtend.getCCScale9SpriteFromCCB(circleCCB, "mGuideTipsAniPic"..i)
        if scale9Sprite then
            --local parentScale = scale9Sprite:getParent():getScale()
            local parentScaleAction = CCScaleTo:create(0.01,1,1)
            scale9Sprite:getParent():runAction(parentScaleAction)
            local size = scale9Sprite:getContentSize()
            local scaleX = (targetSize.width) / size.width
            local scaleY = (targetSize.height) / size.height
            local scaleAction = CCScaleTo:create(0.01,scaleX,scaleY)
            local backInAct = CCEaseSineInOut:create(scaleAction)
            scale9Sprite:runAction(backInAct)
        end
    end

    --光圈扩展动作完成后要重新设置scale和contensize
    local callback = function()
        for i=1, 3,1 do
            local scale9Sprite = UIExtend.getCCScale9SpriteFromCCB(circleCCB, "mGuideTipsAniPic"..i)
            if scale9Sprite then
                scale9Sprite:setScale(1)
                scale9Sprite:setContentSize(targetSize)
            end
        end
        circleCCB:runAnimation("LoopAni")
        --移动完成后，设置clippingNode到准确状态
        local clippingNode = UIExtend.getCCNodeFromCCB(markCCB, "mGuideMaskNode")
        if clippingNode then
            clippingNode:setScaleX(targetSize.width)
            clippingNode:setScaleY(targetSize.height)
        end
    end
    performWithDelay(circleCCB,callback,0.1)
end

-- 显示黑屏的打字机效果
function RANewbiePage:displayBgColorWord()
    
    self.guideLabelNode:setVisible(true)
    local bgLayerColor = UIExtend.getCCLayerColorFromCCB(self.ccbfile, "mBGColor")
    bgLayerColor:setVisible(true)
    bgLayerColor:setOpacity(self.stepDatas.v_4_bgLayerAlphaInit)

    local RAPlayerInfoManager = RARequire("RAPlayerInfoManager")
    local worldPos = RAPlayerInfoManager.getWorldPos()
    local desStr = _RALang("@GuideStartDesc", worldPos.x, worldPos.y)
    self.guideLabelNode:setString(desStr)
    self.ccbfile:runAnimation("LabelAni")
    common:playEffect("DialogueAdmission")

end

-- 显示成功界面
function RANewbiePage:displayVictory()
    
    self.victoryNode:setVisible(true)
     --播放胜利音效
    common:playEffect("VictorySound")
    self.victoryCell:RunAni(function ()
       self.clickScreenTipsNode:setVisible(true)   
    end)

end

-- 处理点击新手屏蔽层开始逻辑的方法，
-- 需要根据当前的view type 自行进行区分
function RANewbiePage:handleTouchLayerBegan(pTouch)
    
end

-- 处理点击新手屏蔽层开始逻辑的方法，
-- 需要根据当前的view type 自行进行区分
function RANewbiePage:handleTouchLayerEnd(pTouch)
    self:_openTroopChargePage(3)
end


function RANewbiePage:OnAnimationDone(ccbfile)
    local lastAnimationName = ccbfile:getCompletedAnimationName()   
end


function RANewbiePage:Exit()
    --you can release lua data here,but can't release node element
    CCLuaLog("RANewbiePage:Exit")    
    self:unregisterMessageHandlers()
    self:resetData()    
    UIExtend.unLoadCCBFile(self)    
end