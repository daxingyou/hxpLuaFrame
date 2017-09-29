-- RAGuidePageCircleAction.lua
-- Author: xinghui
-- Using: 显示Actin

local RAMissionVar                      = RARequire("RAMissionVar")
local Utilitys                          = RARequire("Utilitys")
local UIExtend                          = RARequire("UIExtend")
local RAActionBase                      = RARequire("RAActionBase")
local missionaction_conf                = RARequire("missionaction_conf")

local RAGuidePageCircleAction           = RAActionBase:new()

RAGuidePageCircleAction.maskCCB         = nil
RAGuidePageCircleAction.maskHandler     = {}
RAGuidePageCircleAction.forcusNode      = nil
RAGuidePageCircleAction.targetSize      = nil
RAGuidePageCircleAction.targetPos       = nil
RAGuidePageCircleAction.circleCCB       = nil
RAGuidePageCircleAction.circleHandler   = {}
RAGuidePageCircleAction.clippingNode    = nil

local this = nil

--desc:同OnAnimationDone函数，光圈的动画播放完成后，需要一个扩展开的动作，需要程序来做
function RAGuidePageCircleAction.enlargeCircleAction()
    if this and  this.circleCCB then
        this.circleCCB:stopAllActions()
        --播放光圈的扩展开的动作
        for i=1, 3,1 do
            local scale9Sprite = UIExtend.getCCScale9SpriteFromCCB(this.circleCCB, "mGuideTipsAniPic"..i)
            if scale9Sprite then
                --local parentScale = scale9Sprite:getParent():getScale()
                local parentScaleAction = CCScaleTo:create(0.01,1,1)
                scale9Sprite:getParent():runAction(parentScaleAction)
                local size = scale9Sprite:getContentSize()
                local scaleX = (this.targetSize.width) / size.width
                local scaleY = (this.targetSize.height) / size.height
                local scaleAction = CCScaleTo:create(0.01,scaleX,scaleY)
                local backInAct = CCEaseSineInOut:create(scaleAction)
                scale9Sprite:runAction(backInAct)
            end
        end
        --光圈扩展动作完成后要重新设置scale和contensize
        local callback = function()
            for i=1, 3,1 do
                local scale9Sprite = UIExtend.getCCScale9SpriteFromCCB(this.circleCCB, "mGuideTipsAniPic"..i)
                if scale9Sprite then
                    scale9Sprite:setScale(1)
                    scale9Sprite:setContentSize(this.targetSize)
                end
            end
            this.circleCCB:runAnimation("LoopAni")
            --移动完成后，设置clippingNode到准确状态
            if this.clippingNode then
                this.clippingNode:setScaleX(this.targetSize.width)
                this.clippingNode:setScaleY(this.targetSize.height)
            end

            this:End()

        end
        performWithDelay(this.circleCCB,callback,0.1)
    end
end


--[[
    desc: RAGuidePageCircleAction入口
]]
function RAGuidePageCircleAction:Start(data)
    this = self

    self.constActionInfo = missionaction_conf[self.actionId]
    local target = self:getTarget()

    if target then
        if self.constActionInfo.param == "false" then
            --关掉圆圈
            UIExtend.setNodeVisible(target.ccbfile, self.constActionInfo.varibleName, false)
        else
            self.targetPos = ccp(0, 0)
            self.targetSize = CCSizeMake(0, 0)
            local desParam = Utilitys.Split(self.constActionInfo.param, ",")
            local desTarget = RAMissionVar:getCCBOwner(desParam[1])
            if desTarget then
                local desNode = UIExtend.getCCNodeFromCCB(desTarget.ccbfile, desParam[2])
                if desNode then
                    self.targetSize = desNode:getContentSize()

                    local tmpPos = ccp(0, 0)
                    tmpPos.x, tmpPos.y = desNode:getPosition()
                    if desParam[3] and desParam[3] == "3D" then
                        self.targetPos = desNode:getParent():convertToWorldSpace3D(tmpPos)
                        if desParam[4] then
                            local sizeArr = Utilitys.Split(desParam[4], "_")
                            if #sizeArr >= 2 then
                                self.targetSize = CCSizeMake(tonumber(sizeArr[1]), tonumber(sizeArr[2]))
                            end
                        end
                    else
                        self.targetPos = desNode:getParent():convertToWorldSpace(tmpPos)
                    end
                    tmpPos:delete()
                end
            end

            if not self.forcusNode then
                self.forcusNode = UIExtend.getCCNodeFromCCB(target.ccbfile, self.constActionInfo.varibleName)
            end
            self.forcusNode:setVisible(true)
        

            if self.maskCCB == nil then
                local maskCCBHandler = RAMissionVar:getCCBOwner("RAGuideMaskNode.ccbi")
                if maskCCBHandler then
                    self.maskCCB = maskCCBHandler.ccbfile
                else
                    self.maskCCB = UIExtend.loadCCBFile("RAGuideMaskNode.ccbi",self.maskHandler)--光圈母节点
                    RAMissionVar:addCCBOwner("RAGuideMaskNode.ccbi", self.maskHandler)

                    if not self.forcusNode then
                        self.forcusNode = UIExtend.getCCNodeFromCCB(target.ccbfile, self.constActionInfo.varibleName)
                    end
                    if self.forcusNode then
                        self.forcusNode:addChild(self.maskCCB)
                    end

                end
            end
            self.maskCCB:setVisible(true)


            --设置clipplingNode
            if not self.clippingNode then
                self.clippingNode = UIExtend.getCCNodeFromCCB(self.maskCCB, "mGuideMaskNode")
            end
            self.clippingNode:setScale(1)--设置为初始状态
            self.clippingNode:setVisible(false)

            --设置areanode
            local areaNode = UIExtend.getCCNodeFromCCB(self.maskCCB, "mAreaNode")
            if areaNode then
                areaNode:setContentSize(self.targetSize)
            end

            --加载光圈
            if self.circleCCB == nil then
                self.circleCCBHandler = RAMissionVar:getCCBOwner("Ani_Guide_Tips.ccbi")
                if self.circleCCBHandler then
                    self.circleCCB = self.circleCCBHandler.ccbfile
                else
                    self.circleCCB = UIExtend.loadCCBFile("Ani_Guide_Tips.ccbi", self.circleHandler)--光圈
                    self.maskCCB:addChild(self.circleCCB)
                    RAMissionVar:addCCBOwner("Ani_Guide_Tips.ccbi", self.circleHandler)
                end
            end
            if self.circleCCB then
                self.circleCCB:setVisible(true)
                local size = CCSize(64, 64)
                for i=1, 3 do
                    local scale9Sprite = UIExtend.getCCScale9SpriteFromCCB(self.circleCCB, "mGuideTipsAniPic"..i)
                    if scale9Sprite then
                        scale9Sprite:setContentSize(size)--设置光圈初始大小
                    end
                end
                size:delete()
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
                self.maskCCB:setPosition(self.targetSize.width / 2, self.targetSize.height / 2)--设置markccb的位置
                self.circleCCB:runAnimation("CircleAni")
                performWithDelay(self.forcusNode,self.enlargeCircleAction,0.3)
                self.forcusNode:setPosition(realTargetPos)
            end
        end
    end
end


return RAGuidePageCircleAction