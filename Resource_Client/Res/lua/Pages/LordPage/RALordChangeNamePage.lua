RARequire("BasePage")
local UIExtend = RARequire("UIExtend")
local RANetUtil = RARequire("RANetUtil")
local RAGameConfig = RARequire("RAGameConfig")
local const_conf = RARequire("const_conf")
local RAStringUtil = RARequire("RAStringUtil")
local Utilitys = RARequire("Utilitys")
local RAPlayerInfoManager = RARequire("RAPlayerInfoManager")
local RARootManager = RARequire("RARootManager")
local Const_pb = RARequire("Const_pb")
local Status_pb = RARequire("Status_pb")
local shop_conf = RARequire("shop_conf")
local item_conf = RARequire("item_conf")
local RACoreDataManager = RARequire("RACoreDataManager")


local RALordChangeNamePage = BaseFunctionPage:new(...)
RALordChangeNamePage.inputName = ""--保存用户输入的名字
RALordChangeNamePage.useGold = false
local RALordChangeNameHandler = {}
RALordChangeNamePage.editBox = nil

local nameMinAndMax = Utilitys.Split(const_conf.playerNameMinMax.value, "_")
local nameMin = tonumber(nameMinAndMax[1])
local nameMax = tonumber(nameMinAndMax[2])

RALordChangeNamePage.platformListener = nil
RALordChangeNamePage.Win32InputListener =
{
    onInputboxOK = function (_self, listener)
        local input = listener:getResultStr()
        if input ~= nil and input~= '' then
            local jsonObj = cjson.decode(input)
            if jsonObj ~= nil then
                local RAStringUtil = RARequire('RAStringUtil')
                local content = jsonObj.content or ''
                if content ~= "" then
                    RALordChangeNamePage.inputName = content
                else
                    RALordChangeNamePage.inputName = ""
                end
                RALordChangeNamePage:checkName(RALordChangeNamePage.inputName)
            end
        end
    end,
    onInputboxCancel = function (listener)
        --listener:delete()
    end
}

function RALordChangeNamePage:Enter(data)
    self.ccbifile = UIExtend.loadCCBFile("RAChangeNamePopUp.ccbi", RALordChangeNamePage)
    self:refreshUI()
    self.closeFunc = function()
        -- RAMarchItemUsePage:onBack()
        if self.editBox:isKeyboardShow() == false then
            RARootManager.ClosePage("RALordChangeNamePage")
        end 
    end

    self:registerMessageHandlers()
    self:addHandler()
    self:AddNoTouchLayer(true)
end


local function editboxEventHandler(eventType, node)
    --body
    if eventType == "began" then
        -- triggered when an edit box gains focus after keyboard is shown
    elseif eventType == "ended" then
        -- triggered when an edit box loses focus after keyboard is hidden.
    elseif eventType == "changed" then
        -- triggered when the edit box text was changed.
        RALordChangeNamePage.inputName = RALordChangeNamePage.editBox:getText()
        RALordChangeNamePage:checkName(RALordChangeNamePage.inputName)
    elseif eventType == "return" then
        -- triggered when the return button was pressed or the outside area of keyboard was touched.
    end
end

function RALordChangeNamePage:refreshUI()
    --改名有道具，如果道具存在，那么不适用金币，否则使用金币
    local icon=nil
    local num=0
    local cardNum = 0
    local shopItemInfo = shop_conf[Const_pb.SHOP_CHANGE_NAME]
    local itemId = shopItemInfo.shopItemID
    local price = shopItemInfo.price
    local itemCount = RACoreDataManager:getItemCountByItemId(itemId)
    local constItemInfo = item_conf[Const_pb.ITEM_CHANGE_NAME]
    if itemCount > 0 then
        icon = constItemInfo.item_icon
        local iconSub = string.sub(icon, -3)
        if iconSub ~= "png" then
            icon = icon .. ".png"
        end
        num = 1
        cardNum = itemCount
        RALordChangeNamePage.useGold = false
    else
        icon = RAGameConfig.Diamond_Icon
        num = price
        RALordChangeNamePage.useGold = true
    end

    local tipStr = RAStringUtil:getLanguageString("@ChangeNameExplain", nameMax)
    UIExtend.setCCLabelString(self.ccbifile, "mChangeNameExplain", tipStr)
    UIExtend.setLabelTTFColor(self.ccbifile, "mChangeNameExplain", ccc3(255, 255, 255))
    UIExtend.setCCControlButtonEnable(self.ccbifile, "mChangeNameBtn", false)
    UIExtend.setCCLabelString(self.ccbifile, "mInputLabel", _RALang("@InputNameLabel"))
    UIExtend.setCCLabelString(self.ccbifile, "mChangeNameCardNum", cardNum)--改名道具数量

    UIExtend.addSpriteToNodeParent(self.ccbifile, "mChangeNameIcon", icon)
    UIExtend.setCCLabelString(self.ccbifile, "mChangeNameDiamonds", num)

    local inputNode = UIExtend.getCCNodeFromCCB(self.ccbifile,"mInputNode")
    local editBox = UIExtend.createEditBox(self.ccbifile,"mInputNodeBG",inputNode,editboxEventHandler,nil,nil,nil,24,nil,ccc3(0,0,0))
    editBox:setInputMode(kEditBoxInputModeSingleLine)
    editBox:setMaxLength(24)
    self.editBox = editBox
    editBox:setAnchorPoint(ccp(0,0.5))
end

function RALordChangeNamePage:addHandler()
    RALordChangeNameHandler[#RALordChangeNameHandler + 1] = RANetUtil:addListener(HP_pb.PLAYER_CHECK_NAME_S, RALordChangeNamePage)--注册packet监听
    --RALordChangeNameHandler[#RALordChangeNameHandler + 1] = RANetUtil:addListener(HP_pb.PLAYER_CHANGE_NAME_S, RALordChangeNamePage)--注册packet监听

    RALordChangeNamePage.platformListener = platformSDKListener:new(RALordChangeNamePage.Win32InputListener)--注册SDK回调处理tabel
end

function RALordChangeNamePage:onInputBtn()
--    local RASDKUtil = RARequire('RASDKUtil')
--    RASDKUtil.sendMessageG2P('showInputbox')
end

function RALordChangeNamePage:removeHandler()
    --注销sdk回调处理
    if RALordChangeNamePage.platformListener then
        RALordChangeNamePage.platformListener:delete()
        RALordChangeNamePage.platformListener = nil
    end

    --取消packet监听
    for k, value in pairs(RALordChangeNameHandler) do
        if RALordChangeNameHandler[k] ~= nil then
             RANetUtil:removeListener(RALordChangeNameHandler[k])
             RALordChangeNameHandler[k] = nil
        end
    end
    RALordChangeNameHandler = {}
    
end

local OnReceiveMessage = function(msg)
    if msg.messageID == MessageDef_Packet.MSG_Operation_Fail then
        --修改没有成功
        UIExtend.setLabelTTFColor(RALordChangeNamePage.ccbifile, "mChangeNameExplain", ccc3(255, 0, 0))
        UIExtend.setCCLabelString(RALordChangeNamePage.ccbifile, "mChangeNameExplain", _RALang("@NameChangeFailed"))
        UIExtend.setCCControlButtonEnable(RALordChangeNamePage.ccbifile, "mChangeNameBtn", true)
    elseif msg.messageID == MessageDef_Packet.MSG_Operation_OK then
        --修改成功
        RAPlayerInfoManager.setPlayerName(RALordChangeNamePage.inputName)
        UIExtend.setCCControlButtonEnable(RALordChangeNamePage.ccbifile, "mChangeNameBtn", true)
        MessageManager.sendMessage(MessageDef_Lord.MSG_RefreshName)
        RARootManager.ShowMsgBox(_RALang('@ChangeNameSucc'))
        RARootManager.ClosePage("RALordChangeNamePage")
    end
end
function RALordChangeNamePage:registerMessageHandlers()
    MessageManager.registerMessageHandler(MessageDef_Packet.MSG_Operation_OK,OnReceiveMessage)
    MessageManager.registerMessageHandler(MessageDef_Packet.MSG_Operation_Fail,OnReceiveMessage)
end

function RALordChangeNamePage:unregisterMessageHandlers()
    MessageManager.removeMessageHandler(MessageDef_Packet.MSG_Operation_OK,OnReceiveMessage)
    MessageManager.removeMessageHandler(MessageDef_Packet.MSG_Operation_Fail,OnReceiveMessage)
end

function RALordChangeNamePage:onReceivePacket(handler)
    local pbCode = handler:getOpcode()
    local buffer = handler:getBuffer()
    if pbCode == HP_pb.PLAYER_CHECK_NAME_S then
        --收到检测结果
        local msg = Player_pb.PlayerCheckNameResp()
        msg:ParseFromString(buffer)
        if msg.result then
            --check成功
            UIExtend.setLabelTTFColor(self.ccbifile, "mChangeNameExplain", ccc3(255, 255, 255))
            UIExtend.setCCControlButtonEnable(self.ccbifile, "mChangeNameBtn", true)
            local nameLen = GameMaths:calculateNumCharacters(RALordChangeNamePage.inputName)--获得字符串长度
            local tipStr = RAStringUtil:getLanguageString("@ChangeNameExplain", nameMax-nameLen)
            UIExtend.setCCLabelString(self.ccbifile, "mChangeNameExplain", tipStr)
        else
            --check失败
            UIExtend.setCCControlButtonEnable(self.ccbifile, "mChangeNameBtn", false)
            if msg:HasField("errorCode") then
                local errorCode = msg.errorCode
                UIExtend.setLabelTTFColor(self.ccbifile, "mChangeNameExplain", ccc3(255, 0, 0))
                if errorCode == Status_pb.CONTAIN_ILLEGAL_CHART then
                --除英文外包含其他语言
                    UIExtend.setCCLabelString(self.ccbifile, "mChangeNameExplain", _RALang("@NameContainsOtherLan"))
                elseif errorCode == Status_pb.LENGTH_TOO_LONG then
                --名字太长
                    local strTips = RAStringUtil:getLanguageString("@NameTooLong", nameMax)
                    UIExtend.setCCLabelString(self.ccbifile, "mChangeNameExplain", strTips)
                elseif errorCode == Status_pb.LENGTH_TOO_SHORT then
                    local strTips = RAStringUtil:getLanguageString("@NameTooShort", nameMin)
                    UIExtend.setCCLabelString(self.ccbifile, "mChangeNameExplain", strTips)
                elseif errorCode == Status_pb.ALREADY_EXISTS then
                --名字重复
                    UIExtend.setCCLabelString(self.ccbifile, "mChangeNameExplain", _RALang("@NameRepeated"))
                end
            end
        end
    -- elseif pbCode ==HP_pb.PLAYER_CHANGE_NAME_S then
    --     --收到修改结果
    --     local msg = Player_pb.PlayerChangeNameResp()
    --     msg:ParseFromString(buffer)
    --     if msg.result then
    --         --修改成功
    --         RAPlayerInfoManager.setPlayerName(self.inputName)
    --         UIExtend.setCCControlButtonEnable(self.ccbifile, "mChangeNameBtn", true)
    --         MessageManager.sendMessage(MessageDef_Lord.MSG_RefreshName)
    --         RARootManager.ShowMsgBox(_RALang('@ChangeNameSucc'))
    --         RARootManager.ClosePage("RALordChangeNamePage")
    --     else
    --     --修改没有成功
    --         UIExtend.setLabelTTFColor(self.ccbifile, "mChangeNameExplain", ccc3(255, 0, 0))
    --         UIExtend.setCCLabelString(self.ccbifile, "mChangeNameExplain", _RALang("@NameChangeFailed"))
    --         UIExtend.setCCControlButtonEnable(self.ccbifile, "mChangeNameBtn", true)
    --     end
    end
end

function RALordChangeNamePage:onChangeName()
    if self.inputName == RAPlayerInfoManager.getPlayerBasicInfo().name then
        --todo 相同名字
    else
        RALordChangeNamePage:sendChangeName()
        UIExtend.setCCControlButtonEnable(self.ccbifile, "mChangeNameBtn", false)
    end
end

function RALordChangeNamePage:Exit()
    self:unregisterMessageHandlers()
    RALordChangeNamePage:removeHandler()
    if self.editBox then
        self.editBox:removeFromParentAndCleanup(true)
        self.editBox = nil
    end
    UIExtend.unLoadCCBFile(RALordChangeNamePage)
    self.ccbifile = nil
end

function RALordChangeNamePage:checkName(name)
    UIExtend.setCCControlButtonEnable(self.ccbifile, "mChangeNameBtn", false)

    local nameStrLen =  GameMaths:calculateNumCharacters(name)--获得字符串长度
    if nameStrLen < nameMin or nameStrLen >nameMax  then
        local strTips = RAStringUtil:getLanguageString("@NameLenLimit", nameMin, nameMax)
        UIExtend.setCCLabelString(self.ccbifile, "mChangeNameExplain", strTips)
        UIExtend.setLabelTTFColor(self.ccbifile, "mChangeNameExplain", ccc3(225,0,0))
        return
    end

    --判断是否合法
	local common = RARequire('common')
    if not common:checkStringValidate(name, '[%w]') then
        UIExtend.setCCLabelString(self.ccbifile, "mChangeNameExplain", _RALang("@NameContainsOtherLan"))
        UIExtend.setLabelTTFColor(self.ccbifile, "mChangeNameExplain", ccc3(225,0,0))
    else
        self:sendCheckName()
    end
end

--发送检测名字协议
function RALordChangeNamePage:sendCheckName()
    if self.inputName ~= nil and self.inputName ~= "" then
        --发送协议
        UIExtend.setCCLabelString(self.ccbifile, "mInputLabel", self.inputName)

        local cmd = Player_pb.PlayerCheckNameReq()
        cmd.name = self.inputName
        RANetUtil:sendPacket(HP_pb.PLAYER_CHECK_NAME_C, cmd)
    end
end

--发送修改name协议
function RALordChangeNamePage:sendChangeName()
    if self.inputName ~= nil and self.inputName ~= "" then
        local msg = Player_pb.PlayerChangeNameReq()
        msg.name = self.inputName
        msg.useGold = self.useGold
        msg.itemId = Const_pb.SHOP_CHANGE_NAME
        RANetUtil:sendPacket(HP_pb.PLAYER_CHANGE_NAME_C, msg)
    end
end