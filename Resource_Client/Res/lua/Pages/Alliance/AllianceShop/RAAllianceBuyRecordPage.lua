--联盟商店页面
local RAAllianceBasePage = RARequire("RAAllianceBasePage")
local HP_pb = RARequire('HP_pb')
RARequire('extern')
local UIExtend = RARequire('UIExtend')
local RARootManager = RARequire('RARootManager')
local RAAllianceBuyRecordPage = class('RAAllianceBuyRecordPage',RAAllianceBasePage)
local Utilitys = RARequire('Utilitys')
local RAAllianceBuyRecordCell =  RARequire('RAAllianceBuyRecordCell')
local RAAllianceProtoManager =  RARequire('RAAllianceProtoManager')
local RANetUtil =  RARequire('RANetUtil')


function RAAllianceBuyRecordPage:ctor(...)
    self.ccbfileName = "RAAllianceShopHistoryPage.ccbi"
    self.scrollViewName = 'mListSV'
end

function RAAllianceBuyRecordPage:init(data)
 	RAAllianceProtoManager:reqAllBuyRecords()
end 

function RAAllianceBuyRecordPage:refreshAllRecords()
    self.mListSV:removeAllCell()

	for i=#self.records,1,-1 do
	    local cell = CCBFileCell:create()
	    local ccbiStr = "RAAllianceShopHistoryCell.ccbi"
	    cell:setCCBFile(ccbiStr)
	    local panel = RAAllianceBuyRecordCell:new({
	        info = self.records[i]
	    })
	    cell:registerFunctionHandler(panel)
	    self.mListSV:addCell(cell)
	end

    self.mListSV:orderCCBFileCells()
end

--子类实现
function RAAllianceBuyRecordPage:addHandler()
    self.netHandlers[#self.netHandlers + 1] = RANetUtil:addListener(HP_pb.GUILD_GET_SHOP_LOG_S, self) --获得购买信息 
end

function RAAllianceBuyRecordPage:onReceivePacket(handler)
    local pbCode = handler:getOpcode()
    local buffer = handler:getBuffer()
	
	if pbCode == HP_pb.GUILD_GET_SHOP_LOG_S then --获得购买信息 
        self.records = RAAllianceProtoManager:getAllBuyRecords(buffer)
        self:refreshAllRecords()
    end
end


--初始化顶部
function RAAllianceBuyRecordPage:initTitle()
    -- body
    local titleCCB = UIExtend.getCCBFileFromCCB(self.ccbfile, "mAllianceCommonCCB")
    self.mDiamondsNode = UIExtend.getCCNodeFromCCB(titleCCB,'mDiamondsNode')
    self.mDiamondsNode:setVisible(false)

    local RACommonTitleHelper = RARequire('RACommonTitleHelper')
    local backCallBack = function()
        RARootManager.CloseCurrPage()  
    end
    local titleName = _RALang("@BuyRecord")
    local titleHandler = RACommonTitleHelper:RegisterCommonTitle('RAAllianceBuyRecordPage', 
        titleCCB, titleName, backCallBack, RACommonTitleHelper.BgType.Blue)

    UIExtend.getCCNodeFromCCB(titleCCB,'mGoldNode'):setVisible(false)
    UIExtend.getCCNodeFromCCB(titleCCB,'mOilNode'):setVisible(false)
    UIExtend.getCCNodeFromCCB(titleCCB,'mSteelNode'):setVisible(false)
    UIExtend.getCCNodeFromCCB(titleCCB,'mRareEarthsNode'):setVisible(false)
end

function RAAllianceBuyRecordPage:release()

    local RACommonTitleHelper = RARequire('RACommonTitleHelper')
    RACommonTitleHelper:RemoveCommonTitle("RAAllianceBuyRecordPage")

    self.mListSV:removeAllCell()
end

--子类实现
function RAAllianceBuyRecordPage:initScrollview()

	self.mListSV =  UIExtend.getCCScrollViewFromCCB(self.ccbfile, self.scrollViewName)
end

return RAAllianceBuyRecordPage.new()