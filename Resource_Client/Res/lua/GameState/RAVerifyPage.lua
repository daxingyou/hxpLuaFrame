RARequire("BasePage")

local UIExtend = RARequire('UIExtend')
local RAVerifyPage = BaseFunctionPage:new(...)
local HP_pb = RARequire("HP_pb")
local Login_pb = RARequire("Login_pb")
function RAVerifyPage:Enter()
	
	local ccbfile = UIExtend.loadCCBFile("RACDKeyPage.ccbi",self)
	self.ccbfile = ccbfile
    local tag = 10010
	self.ccbfile:setTag(tag)
    local director = CCDirector:sharedDirector()
    if director:getRunningScene()   then
        if self.editBox ~= nil then
            self.editBox:removeFromParentAndCleanup(true)
            self.editBox = nil
        end
        director:getRunningScene():removeChildByTag(tag,true) 
        director:getRunningScene():addChild(ccbfile)
    end

	self:RegisterPacketHandler(HP_pb.DEVICE_ACTIVE_S)
    self:CommonRefresh()

end



local function editboxEventHandler(eventType, node)
    --body
    if eventType == "began" then
        -- triggered when an edit box gains focus after keyboard is shown
    elseif eventType == "ended" then
        -- triggered when an edit box loses focus after keyboard is hidden.
    elseif eventType == "changed" then
        -- triggered when the edit box text was changed.
        --RAVerifyPage.MsgString = RAVerifyPage.editBox:getText()
    elseif eventType == "return" then
        -- triggered when the return button was pressed or the outside area of keyboard was touched.
    end
end

function RAVerifyPage:initEditBox()
    local inputNode = UIExtend.getCCNodeFromCCB(self.ccbfile, 'mInputNode')
    if self.editBox == nil then
        local picScale9Sprite = UIExtend.getCCScale9SpriteFromCCB(self.ccbfile,"mInputBG")
        local contentSize = picScale9Sprite:getContentSize()
        local editBox = UIExtend.createEditBox(self.ccbfile, 'mInputBG',
        inputNode, editboxEventHandler, nil, nil,
        kEditBoxInputModeNumeric, 24, nil, ccc3(255, 255, 255),0,contentSize,ccp(0,0.5),ccp(0,contentSize.height/2.0))
        self.editBox = editBox
        self.editBox:setPlaceHolder(_RALang("@LoginActivePlaceholder"));
        --self.editBox:setAnchorPoint(ccp(0,0.5))
    end

end


function RAVerifyPage:CommonRefresh()
    UIExtend.setNodesVisible(self.ccbfile,{
        mErrorLabel = false,
        mCDKeyExplain = false
    })
    UIExtend.setStringForLabel(self.ccbfile,{
        mCDKeyTitle = _RALang("@LoginActiveTitle"),
        mCDKeyExplain = _RALang("@LoginActiveExplain"),
    })
    self:initEditBox()
end


function RAVerifyPage:onReceivePacket(handler)
    local pbCode = handler:getOpcode()
    local buffer = handler:getBuffer()
    if pbCode == HP_pb.DEVICE_ACTIVE_S then
        local msg = Login_pb.HPActiveDeviceRet()
        msg:ParseFromString(buffer)
        if msg.code ~= nil and msg.code == 0 then
            --success and close own page
            UIExtend.setNodesVisible(self.ccbfile,{
                mErrorLabel = false
            })
            self:Exit()
            local RALoginManager = RARequire("RALoginManager")
            RALoginManager.sendLoginCmd()
        else
            local RAStringUtil = RARequire("RAStringUtil")
            local errorMsg = RAStringUtil:getErrorString(msg.code)
            UIExtend.setStringForLabel(self.ccbfile,{
                mErrorLabel = errorMsg
            })
            UIExtend.setNodesVisible(self.ccbfile,{
                mErrorLabel = true
            })
        end
    end
end

function RAVerifyPage:onConfirm()
    if self.editBox == nil then
        return 
    end
    local token = self.editBox:getText()
    if token ~= nil and string.len(token) > 0 then
        local msg = Login_pb.HPActiveDevice()
        msg.deviceId = RAPlatformUtils:getDeviceId()
        msg.activeToken = self.editBox:getText()
        local RANetUtil = RARequire("RANetUtil")
        RANetUtil:sendPacket(HP_pb.DEVICE_ACTIVE_C, msg, { retOpcode = - 1 })
    end
     
end

function RAVerifyPage:Exit()
    self.editBox:removeFromParentAndCleanup(true)
    self.editBox = nil 
	UIExtend.unLoadCCBFile(self)
    self:RemovePacketHandlers()
end



return RAVerifyPage