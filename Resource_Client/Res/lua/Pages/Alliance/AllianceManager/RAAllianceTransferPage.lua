RARequire("BasePage")
local UIExtend = RARequire("UIExtend")
local RARootManager = RARequire("RARootManager")
local RAAllianceManager = RARequire("RAAllianceManager")
local RAAllianceProtoManager = RARequire("RAAllianceProtoManager")
local Utilitys = RARequire("Utilitys")
local RAAllianceUtility = RARequire("RAAllianceUtility")
local HP_pb = RARequire("HP_pb")
local RANetUtil = RARequire("RANetUtil")
local RAAllianceTransferCell = RARequire("RAAllianceTransferCell")


local RAAllianceTransferPage = BaseFunctionPage:new(...)

local allianceInfo = RAAllianceManager.selfAlliance

--请求成员信息
function RAAllianceTransferPage:send()
    -- body
    RAAllianceProtoManager:getGuildMemeberInfoReq(allianceInfo.id)
end

function RAAllianceTransferPage:Enter()
	local ccbfile = UIExtend.loadCCBFile("RAAllianceTransferPage.ccbi",self)
    self.scrollView = UIExtend.getCCScrollViewFromCCB(self.ccbfile, "FlagListSV")

    self.mDiamondsNode = UIExtend.getCCNodeFromCCB(self.ccbfile:getCCBFileFromCCB("mAllianceCommonCCB"),'mDiamondsNode')
    self.mDiamondsNode:setVisible(false)

    self:initTopTitle()

    self:RegisterPacketHandler(HP_pb.GUILDMANAGER_GETMEMBERINFO_S)

    self.transferInfo = {}

    self:refreshUI()

    self:send()
    --add cell
    --self:addCell()
end

function RAAllianceTransferPage:refreshUI()
    UIExtend.setStringForLabel(self.ccbfile,{mTransferExplain = _RALang("@TransferExplain")})
end

--初始化顶部
function RAAllianceTransferPage:initTopTitle()
    -- body
    self.ccbfile:getCCBFileFromCCB("mAllianceCommonCCB"):runAnimation("InAni")
    local titleName = _RALang("@AllianceTransferPTitle")
    UIExtend.setCCLabelString(self.ccbfile:getCCBFileFromCCB("mAllianceCommonCCB"),'mTitle',titleName)
end

function RAAllianceTransferPage:onReceivePacket(handler)
    local pbCode = handler:getOpcode()
    local buffer = handler:getBuffer()
    if pbCode == HP_pb.GUILDMANAGER_GETMEMBERINFO_S then --成员信息
        self.transferInfo = RAAllianceProtoManager:getGuildMemeberInfoResp(buffer)
        self:addCell(self.transferInfo)
    end
end

function RAAllianceTransferPage:Exit()
    self:RemovePacketHandlers()
    self.scrollView:removeAllCell()
    UIExtend.unLoadCCBFile(self)
end

function RAAllianceTransferPage:mAllianceCommonCCB_onBack()
    RARootManager.CloseCurrPage()
end

function RAAllianceTransferPage:addCell(data)
	-- body
	self.scrollView:removeAllCell()
    local scrollView = self.scrollView
    for k,v in pairs(data) do
        if v.authority ~= 5 then    --盟主自己不需要显示
            local cell = CCBFileCell:create()
            cell:setCCBFile("RAAllianceTranferCell.ccbi")
            local panel = RAAllianceTransferCell:new({
    	        mTag = k,
                mInfo = v
            })
            cell:registerFunctionHandler(panel)
            scrollView:addCell(cell)
        end
    end
    scrollView:orderCCBFileCells()
end

return RAAllianceTransferPage