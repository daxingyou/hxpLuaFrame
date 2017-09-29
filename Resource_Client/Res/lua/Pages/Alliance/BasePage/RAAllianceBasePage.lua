--联盟通用界面
--联盟标题栏

RARequire('extern')
RARequire('BasePage')
local UIExtend = RARequire('UIExtend')
local RARootManager = RARequire('RARootManager')
local RAAllianceBasePage = class('RAAllianceBasePage',BaseFunctionPage:new())
local RANetUtil = RARequire('RANetUtil')

function RAAllianceBasePage:Enter(data)
	self.ccbfile = UIExtend.loadCCBFile(self.ccbfileName, self)

	self.netHandlers = {}
	self:addHandler()
	self:init(data)

	self:registerMessage()
	self:initTitle()
	self:initScrollview()
end


--子类实现
function RAAllianceBasePage:initScrollview()
	
end

function RAAllianceBasePage:init(data)
	-- body
end

--子类实现
function RAAllianceBasePage:addHandler()
end

--子类实现
function RAAllianceBasePage:registerMessage()
end

--子类实现
function RAAllianceBasePage:removeMessageHandler()
end

--初始化顶部
function RAAllianceBasePage:initTitle()
    -- body
    self.mDiamondsNode = UIExtend.getCCNodeFromCCB(self.ccbfile:getCCBFileFromCCB("mAllianceCommonCCB"),'mDiamondsNode')
    self.mDiamondsNode:setVisible(false)

    self.ccbfile:getCCBFileFromCCB("mAllianceCommonCCB"):runAnimation("InAni")
    local titleName = _RALang("@Alliance")
    UIExtend.setCCLabelString(self.ccbfile:getCCBFileFromCCB("mAllianceCommonCCB"),'mTitle',titleName)
end


function RAAllianceBasePage:mAllianceCommonCCB_onBack()
	RARootManager.ClosePage(self.__cname)
end

function RAAllianceBasePage:Exit()
	self:release()
	self:removeMessageHandler()
	self:removeHandler()
	UIExtend.unLoadCCBFile(self)	
end

function RAAllianceBasePage:removeHandler()
	for k, value in pairs(self.netHandlers) do
        RANetUtil:removeListener(value)
    end

    self.netHandlers = {}
end

function RAAllianceBasePage:release()
	-- body
end

function RAAllianceBasePage:ctor(...)
	CCLuaLog('RAAllianceBasePage:ctor(...)')
	self.ccbfileName = ''
end 

-- return RAAllianceInfo
return RAAllianceBasePage.new()