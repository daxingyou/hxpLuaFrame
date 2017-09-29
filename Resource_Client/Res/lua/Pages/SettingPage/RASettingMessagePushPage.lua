--设置客户端自己推送消息开关页面

local RARootManager = RARequire("RARootManager")
local UIExtend = RARequire("UIExtend")
local RASettingMessagePushManager = RARequire("RASettingMessagePushManager")

local RASettingMessagePushPage = BaseFunctionPage:new(...)

local RASettingPushCell = {}

function RASettingPushCell:new(o)
	-- body
	o = o or {}
    setmetatable(o,self)
    self.__index = self    
    return o
end

function RASettingPushCell:setSwitchNode( isOpen )
	-- body
	if not self.ccbfile then return end
	UIExtend.setNodeVisible(self.ccbfile,'mOpenNode',isOpen)
	UIExtend.setNodeVisible(self.ccbfile,'mCloseNode',not isOpen)
end

function RASettingPushCell:onRefreshContent(ccbRoot)
    
	if not ccbRoot then return end
	local ccbfile = ccbRoot:getCCBFileNode() 
	self.ccbfile =  ccbfile
    UIExtend.handleCCBNode(ccbfile)

    local data = self.messagePushData
    UIExtend.setStringForLabel(ccbfile,{
        mCellTitle = _RALang(data.typeName)
    })

    UIExtend.setStringForLabel(ccbfile,{
        mExplainLabel = _RALang(data.typeDes)
    })

    local isOpen = CCUserDefault:sharedUserDefault():getBoolForKey(data.key, true)
    self:setSwitchNode(isOpen)
end

function RASettingPushCell:onClick()
    local data = self.messagePushData
    local isOpen = CCUserDefault:sharedUserDefault():getBoolForKey(data.key, true)

    self:setSwitchNode(not isOpen)

    CCUserDefault:sharedUserDefault():setBoolForKey(data.key, not isOpen) 
    CCUserDefault:sharedUserDefault():flush()   

    if data.isClientSave ~= 1 then  --同时保存到服务器
        local value = "0"
        if not isOpen then
            value = "1"
        end
        RASettingMessagePushManager:sendSysProtocol(data.key, value)
    end
end

function RASettingMessagePushPage:Enter()
	UIExtend.loadCCBFile("RASettingPushPage.ccbi",self)

    self.mSettingListSV = UIExtend.getCCScrollViewFromCCB(self.ccbfile,"mSettingListSV")
    assert(self.mSettingListSV~=nil,"mSettingListSV~=nil")

    self:initTitle()

    self:CommonRefresh()
end

function RASettingMessagePushPage:CommonRefresh()
	-- body
	local messagePushDatas = RASettingMessagePushManager:getMessagePushData()
	local settingListSV = self.mSettingListSV
	settingListSV:removeAllCell()

    for k,v in ipairs(messagePushDatas) do 
        local cell = CCBFileCell:create()
		cell:setCCBFile("RASettingPushCell.ccbi")
		local panel = RASettingPushCell:new({
			messagePushData = v
        })
		cell:registerFunctionHandler(panel)
		settingListSV:addCell(cell)
    end
    settingListSV:orderCCBFileCells()
end

function RASettingMessagePushPage:initTitle()
	-- body
	local titleCCB = UIExtend.getCCBFileFromCCB(self.ccbfile, "mCommonTitleCCB")
	local RACommonTitleHelper = RARequire('RACommonTitleHelper')
	local backCallBack = function()
		RARootManager.GotoLastPage()
	end
    local titleName = _RALang("@SettingMessagePushPage")
	local titleHandler = RACommonTitleHelper:RegisterCommonTitle('RASettingMessagePushPage', 
    titleCCB, titleName, backCallBack, RACommonTitleHelper.BgType.Blue)
end

function RASettingMessagePushPage:Exit()
	self.mSettingListSV:removeAllCell()
    local RACommonTitleHelper = RARequire('RACommonTitleHelper')
	RACommonTitleHelper:RemoveCommonTitle("RASettingMessagePushPage")

    UIExtend.unLoadCCBFile(self)
    self.ccbfile = nil
end

return RASettingMessagePushPage