--TO:基地增益状态显示页面
RARequire("BasePage")

local UIExtend = RARequire("UIExtend")
local RARootManager = RARequire("RARootManager")
local RACityGainManager =RARequire("RACityGainManager")
local common = RARequire("common")
local RABuffManager = RARequire("RABuffManager")
local Utilitys = RARequire("Utilitys")

local RACityGainPage = BaseFunctionPage:new(...)

local OnReceiveMessage = function(message)
    if message.messageID == MessageDef_CityGainStatus.MSG_CityGain_Changed then
        RACityGainPage:updateRefreshPage()
    elseif message.messageID == MessageDef_Packet.MSG_Operation_OK then
        if message.opcode == HP_pb.ITEM_USE_BY_ITEMID_C then --使用成功
            RARootManager.ShowMsgBox('@useSuccessful')
        end
    end
end

function RACityGainPage:registerMessage()
    MessageManager.registerMessageHandler(MessageDef_Packet.MSG_Operation_OK,OnReceiveMessage)
    MessageManager.registerMessageHandler(MessageDef_CityGainStatus.MSG_CityGain_Changed,OnReceiveMessage)
end

function RACityGainPage:removeMessageHandler()
    MessageManager.removeMessageHandler(MessageDef_Packet.MSG_Operation_OK,OnReceiveMessage)
    MessageManager.removeMessageHandler(MessageDef_CityGainStatus.MSG_CityGain_Changed,OnReceiveMessage)
end

function RACityGainPage:updateRefreshPage()
    self:addCell()
end

function RACityGainPage:Enter()
	local ccbfile = UIExtend.loadCCBFile("RACityGainPage.ccbi",self)
	self.scrollView = UIExtend.getCCScrollViewFromCCB(ccbfile, "mListSV")

    self:registerMessage()
	--top info
    self:initTitle()

    self:addCell()
end

--------------------------cell begin------------------------------
local RACityGainCell = {}

function RACityGainCell:new(o)
	o = o or {}
    setmetatable(o,self)
    self.__index = self    
    return o
end

function RACityGainCell:onCheckBtn()
    RARootManager.OpenPage("RACityGainDetailsPage",{buffData = self.mData});
end

function RACityGainCell:updateTime()
    local buff = RABuffManager:getBuff(self.mData.effectID)
    local curTime = common:getCurMilliTime()
    local diffTime = math.ceil((buff.endTime - curTime) / 1000)
    local formatTimeStr = Utilitys.createTimeWithFormat(diffTime)
    UIExtend.setStringForLabel(self.ccbfile,{mEffectiveTime = _RALang("@BecomeEffectiveTime",formatTimeStr)})

    local mBar = UIExtend.getCCScale9SpriteFromCCB(self.ccbfile,"mBar")
    local totolTime = (buff.endTime - buff.startTime) / 1000
    local processTime = (buff.endTime - curTime) / 1000
    local scaleX = (processTime / totolTime)

    if scaleX > 1 then
        scaleX = 1
    end
    if mBar then
        mBar:setScaleX(scaleX)
    end
end

function RACityGainCell:onRefreshContent(ccbRoot)
    if not ccbRoot then return end
    local ccbfile = ccbRoot:getCCBFileNode() 
    UIExtend.handleCCBNode(ccbfile)
    self.ccbfile = ccbfile

    local data = self.mData

    --name
    UIExtend.setStringForLabel(ccbfile,{mCellTitle = _RALang(data.name)})
    --icon
    UIExtend.removeSpriteFromNodeParent(ccbfile, "mIconNode")
	UIExtend.addSpriteToNodeParent(ccbfile, "mIconNode", data.icon)

    local RABuffManager = RARequire("RABuffManager")
    local buff = RABuffManager:getBuff(data.effectID)

    local diffTime = -1
    if buff then
        diffTime = buff.endTime - common:getCurMilliTime()
    end
    if buff and diffTime > 0 then
        self.mData.isProcessTime = true
        RACityGainManager:setNodeVisible(ccbfile,false)

        UIExtend.setStringForLabel(ccbfile,{mHaveBarExplain = _RALang(data.des)})

        local scheduleFunc = function ()
		    self:updateTime()
	    end

        schedule(self.ccbfile,scheduleFunc,0.5)
    else
        self.mData.isProcessTime = false
        RACityGainManager:setNodeVisible(ccbfile,true)
        UIExtend.setStringForLabel(ccbfile,{mNoBarExplain = _RALang(data.des)})
    end
 end   

function RACityGainCell:onUnLoad(ccbRoot)
    if not ccbRoot then return end
    local ccbfile = ccbRoot:getCCBFileNode()
    if ccbfile then
        ccbfile:stopAllActions()
    end
end
 ------------------------------------------------------------------

function RACityGainPage:addCell()
	self.scrollView:removeAllCell()
    local scrollView = self.scrollView

    local buffData = RACityGainManager:getCityGainData()

    for k,v in pairs(buffData) do
        local cell = CCBFileCell:create()
        cell:setCCBFile("RACityGainCell.ccbi")
        local panel = RACityGainCell:new({
	        mTag = k,
            mData = v
        })  	  
 
        cell:registerFunctionHandler(panel)
        scrollView:addCell(cell)
    end
    scrollView:orderCCBFileCells()
end

function RACityGainPage:initTitle()
    local titleCCB = UIExtend.getCCBFileFromCCB(self.ccbfile, "mCommonTitleCCB")
	local RACommonTitleHelper = RARequire('RACommonTitleHelper')
	local backCallBack = function()
		RARootManager.CloseCurrPage()  
	end
    local titleName = _RALang("@CityGainDetailsTitle")
	local titleHandler = RACommonTitleHelper:RegisterCommonTitle('RACityGainPage', 
    titleCCB, titleName, backCallBack, RACommonTitleHelper.BgType.Blue)
end

function RACityGainPage:Exit()
	local RACommonTitleHelper = RARequire('RACommonTitleHelper')
    RACommonTitleHelper:RemoveCommonTitle("RACityGainPage")

    self:removeMessageHandler()

    self.scrollView:removeAllCell()
    self.scrollView = nil

    --self.ccbfile:stopAllActions()

    UIExtend.unLoadCCBFile(self)
    self.ccbfile = nil
end

return RACityGainPage