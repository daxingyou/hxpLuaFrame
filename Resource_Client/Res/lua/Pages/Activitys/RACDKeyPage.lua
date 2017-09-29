RARequire("BasePage")
-- local Cdk_pb = require("Cdk_pb")
local UIExtend = RARequire("UIExtend")
local RARootManager = RARequire("RARootManager")
local EnterFrameDefine = RARequire('EnterFrameDefine')
local RACDKeyPage = BaseFunctionPage:new(...)
local OnPacketRecieve = nil

function RACDKeyPage:resetData()
    -- body
end

--
OnPacketRecieve = function(event, data)
    CCLuaLog("recieve handle event:"..event)
    if event == RAPacketManager.PROTOT_CMD_LUA_EVENT_KEY then
        -- local cmdData = tolua.cast(data, "RAProtoScriptCmdData")
        -- CCLuaLog("begin handle")
        -- if cmdData == nil then return end
        -- local cmdCode = cmdData:getCommandId()
        -- local errorStr = cmdData:getErrorStr()
        -- local msgStr = cmdData:getMsgContent()
        -- CCLuaLog("RACDKeyPage OnPacketRecieve cmdCode:".. cmdCode)
        -- local response = Cdk_pb.GetCodeGiftResponse()
        -- response:ParseFromString(msgStr)
        -- for _, kv in ipairs(response.activity.strKv) do
        --     CCLuaLog("GetCodeGiftResponse str kv key:"..kv.key)
        --     CCLuaLog("GetCodeGiftResponse str kv val:"..kv.val)
        -- end
        -- CCLuaLog("GetCodeGiftResponse sendCode:"..response.activity.sendCode)
    end
end

function RACDKeyPage:EnterFrame()
    CCLuaLog("RACDKeyPage:EnterFrame")
    
end

function RACDKeyPage:Enter(data)

	CCLuaLog("RACDKeyPage:Enter")
    -- EnterFrameMananger.registerEnterFrameHandler(EnterFrameDefine.TimeCalculator.EF_TestTime, self)
	local ccbfile = UIExtend.loadCCBFile("RACDKeyPage.ccbi",RACDKeyPage)
    self:AddNoTouchLayer(true)
    -- local ccbfile = UIExtend.loadCCBFile("ccbi/RAChatMyCell.ccbi",RACDKeyPage)
    -- local RAStringUtil = RARequire('RAStringUtil')
    -- local str1 = RAStringUtil:getHTMLString('test1', 'n', 1)
    -- CCLuaLog("RACDKeyPage:Enter 1:"..str1)

    -- local str2 = RAStringUtil:getHTMLString('test2', '2-arg1', 2)
    -- CCLuaLog("RACDKeyPage:Enter 2:"..str2)
    -- local label = UIExtend.getCCLabelHTMLFromCCB(ccbfile, "mOtherName")
    -- label:setString(str1)

    -- local label2 = UIExtend.getCCLabelHTMLFromCCB(ccbfile, "mOthersSendLabel")
    -- label2:setString(str2)

	self.mCDKeyExplain = UIExtend.getCCLabelTTFFromCCB(ccbfile,"mCDKeyExplain")

    if data ~= nil then
        for k,v in pairs(data) do
            print(k,v)
            CCLuaLog("RACDKeyPage:Enter  k="..k.." v="..v)
        end
    end

    self.closeFunc = function()
        CCLuaLog("close func test in cdk page")
        RARootManager.GotoLastPage()
    end

    
end


function RACDKeyPage:CommonRefresh(data)
    CCLuaLog("RACDKeyPage:CommonRefresh data id:"..data.id) 
    -- RARootManager.CloseCurrPage()
    local data = {}
    data.labelText = "this is a test"
    data.resultFun = function(resultInfo)
        if resultInfo == true then 
            CCLuaLog("click confirm")
            RARootManager.GotoLastPage()
        else
            CCLuaLog("click cancel")
            RARootManager.CloseAllPages()
        end
    end
    RARootManager.OpenPage("RAConfirmPage", data)
end

function RACDKeyPage:onConfirm()
	CCLuaLog("RACDKeyPage:onConfirm")
    -- MessageManager.sendMessage(MessageDef_RootManager.MSG_CommonRefreshPage,{pageName="RACDKeyPage", id="test id"})

    local RAActionManager = RARequire('RAActionManager')
    local action = RAActionManager:CreateNumLabelChangeAction(1.5, 10000, 1119999,true)
    action:startWithTarget(self.mCDKeyExplain)
end

function RACDKeyPage:onClose()
    CCLuaLog("RACDKeyPage:onClose")
    RARootManager.CloseCurrPage()
end

function RACDKeyPage:OnAnimationDone(ccbfile)
	local lastAnimationName = ccbfile:getCompletedAnimationName()	
end

function RACDKeyPage:Exit()
	--you can release lua data here,but can't release node element
    CCLuaLog("RACDKeyPage:Exit")    
    EnterFrameMananger.removeEnterFrameHandler(EnterFrameDefine.TimeCalculator.EF_TestTime, self)
    self:resetData()
end