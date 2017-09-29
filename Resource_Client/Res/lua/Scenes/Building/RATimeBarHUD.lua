RARequire("BasePage")
RARequire("extern")

local common = RARequire("common")
local UIExtend = RARequire('UIExtend')
local RAQueueUtility = RARequire('RAQueueUtility')
local Const_pb = RARequire('Const_pb')
local Queue_pb = RARequire('Queue_pb')
 
local RATimeBarHUD = BaseFunctionPage:new(...)
local Utilitys = RARequire("Utilitys")

function RATimeBarHUD:init()
    UIExtend.loadCCBFile("RAHUDCityBar.ccbi",self)
    self.mBar = UIExtend.getCCScale9SpriteFromCCB(self.ccbfile,"mBar")
    self.handler = nil
    self.queueData = nil 
    self.timeLabel = nil  
end

function RATimeBarHUD:registerHandler(handler)
    self.handler = handler
end

function RATimeBarHUD:start(queueData)

    self.queueData = queueData
    self.timeLabel = UIExtend.getCCLabelTTFFromCCB(self.ccbfile,"mTime")
    -- body
    local updateFun = function ()

        local remainTime = Utilitys.getCurDiffTime(self.queueData.endTime)

        if remainTime < 0 then --时间倒计时为0就隐藏进度条
            remainTime = 0
            self.ccbfile:setVisible(false)
        end 

        local tmpStr = Utilitys.createTimeWithFormat(remainTime)
        self.timeLabel:setString(tmpStr)

        local scaleX = RAQueueUtility.getTimeBarScale(self.queueData)
        self.mBar:setScaleX(scaleX)

        if self.handler then 
            self.handler:timeHandler(remainTime)
        end 
    end

    self:initIcon()
    updateFun()
    schedule(self.ccbfile,updateFun,1)
end

function RATimeBarHUD:initIcon()
    local spriteName = RAQueueUtility.getTimeBarIcon(self.queueData)

    local sprite = self.ccbfile:getCCSpriteFromCCB('mHUDIcon')
    if sprite then
        sprite:setTexture(spriteName)
    end 
end

function RATimeBarHUD:stop()
    self.ccbfile:stopAllActions()
    self.queueData = nil 
end

function RATimeBarHUD:OnAnimationDone()
    
end

function RATimeBarHUD:setPosition(x,y)
    self.ccbfile:setPosition(x,y) 
end

function RATimeBarHUD:release()
    self:stop()
    UIExtend.unLoadCCBFile(self)
end

return RATimeBarHUD
