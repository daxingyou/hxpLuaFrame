--region RAShowMessageBoxPage.lua
--Author : phan
--Date   : 2016/6/22
--此文件由[BabeLua]插件自动生成


--endregion
RARequire("BasePage")
local RARootManager = RARequire("RARootManager")
local UIExtend = RARequire('UIExtend')
local RAStringUtil = RARequire('RAStringUtil')

local RAShowMessageBoxPage = BaseFunctionPage:new(...)

local diffMsgStr = ""

function RAShowMessageBoxPage:Enter()
    if diffMsgStr == self.textMsg then
        return false
    else
        if self.Exit then
            self:Exit()
        end     
    end
    local ccbfile = UIExtend.loadCCBFile("ccbi/RAMassageBox.ccbi",self)
    local winSize = CCDirector:sharedDirector():getWinSize()
    ccbfile:setPosition(ccp(winSize.width/2,winSize.height/2))
    self.ccbfile = ccbfile
    self:refresh()
    return true
end

function RAShowMessageBoxPage:refresh()
    if self.ccbfile then
        local msgLabel = UIExtend.getCCLabelTTFFromCCB(self.ccbfile,"mMsgLabel")
        if msgLabel then
            diffMsgStr = self.textMsg
            msgLabel:setString(tostring(diffMsgStr))

--          local winSize = CCDirector:sharedDirector():getWinSize()
--          msgLabel:setPosition(ccp(winSize.width/2,winSize.height/2))
        end
    end
end

function RAShowMessageBoxPage:setString_Lan(msgString,...)
    self.textMsg = GameMaths:stringAutoReturnForLua(_RALang(msgString,...), 24, 0)
end	

function RAShowMessageBoxPage:OnAnimationDone(ccbfile)
    local lastAnimationName = ccbfile:getCompletedAnimationName()
	if lastAnimationName == "InAni" then
		if self.Exit then
            self:rest()
            self:Exit()
        end
	end
end

function RAShowMessageBoxPage:rest()
    self.textMsg = ""
    diffMsgStr = ""
end

function RAShowMessageBoxPage:Exit()
	UIExtend.unLoadCCBFile(self)
end

return RAShowMessageBoxPage