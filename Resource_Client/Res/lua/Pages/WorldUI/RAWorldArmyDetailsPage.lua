--region RAWorldArmyDetailsPage.lua
--Author : phan
--Date   : 2016/7/4
--此文件由[BabeLua]插件自动生成

--出征部隊詳情


RARequire("BasePage")
local UIExtend = RARequire("UIExtend")
local RATroopsInfoManager = RARequire("RATroopsInfoManager")
local RATroopsInfoConfig = RARequire("RATroopsInfoConfig")
local battle_soldier_conf = RARequire("battle_soldier_conf")
local HP_pb = RARequire("HP_pb")
local RANetUtil = RARequire('RANetUtil')

local RAWorldArmyDetailsPage = BaseFunctionPage:new(...)

local RAWorldArmyDetailsCellPage = {}

-- 请求军队信息
function RAWorldArmyDetailsPage:sendWorldCheckArmyDetail(marchId)
    local cmd = World_pb.WorldCheckArmyDetailReq()
    cmd.marchId = tostring(marchId) or ''
    RANetUtil:sendPacket(HP_pb.WORLD_CHECK_ARMY_DETAIL_C,cmd,{retOpcode=-1})
end

function RAWorldArmyDetailsPage:Enter(data)
    local ccbfile = UIExtend.loadCCBFile("ccbi/RAWorldArmyDetailsPopUp.ccbi",self)
    self.ccbfile = ccbfile
    self.scrollView = UIExtend.getCCScrollViewFromCCB(self.ccbfile, "mPopUpListSV")
    self:_initPage()

    self:RegisterPacketHandler(HP_pb.WORLD_CHECK_ARMY_DETAIL_S)
    self:sendWorldCheckArmyDetail(data.marchId)
    
end

function RAWorldArmyDetailsPage:_initPage()
    UIExtend.setStringForLabel(self.ccbfile, {
        mPopUpTitle = _RALang("@WorldArmyDetailsTip"),
        mPlayerName = '',
        mArmyNum = ''
    })
end

function RAWorldArmyDetailsPage:refreshArmyInfo()
    --set name
    UIExtend.setStringForLabel(self.ccbfile,{mPlayerName = RATroopsInfoConfig.RunTroopsData.playerName})
    --set army num
    local runTroopsTotal = RATroopsInfoManager.getRunTroopsTotal()
    UIExtend.setStringForLabel(self.ccbfile,{mArmyNum = tostring(runTroopsTotal)})

    RATroopsInfoManager.getRunTroopsData()
    self:pushCellToScrollView(RATroopsInfoConfig.buildIdData)
end

function RAWorldArmyDetailsPage:Exit()
    print("RAWorldArmyDetailsPage:Exit")
    self:RemovePacketHandlers()
    RATroopsInfoManager.restData()
    self.scrollView:removeAllCell()
    UIExtend.unLoadCCBFile(self)
end

function RAWorldArmyDetailsCellPage:new(o)
    o = o or {}
    setmetatable(o,self)
    self.__index = self    
    return o
end

function RAWorldArmyDetailsCellPage:onRefreshContent(ccbRoot)
	CCLuaLog("RAArmyDetailsCellPage:onRefreshContent")
	if not ccbRoot then return end
    local ccbfile = ccbRoot:getCCBFileNode() 
    UIExtend.handleCCBNode(ccbfile)
    local data = self.mData
    local armyId = data.id
    local armyCount = data.count
    local armyConf = battle_soldier_conf[tonumber(armyId)]
    if armyConf then
        local iconPath = "Resource/Image/SoldierHeadIcon/"
        local picName = iconPath..armyConf.icon
	    UIExtend.addSpriteToNodeParent(ccbfile, "mIconNode", picName)
    end
    UIExtend.setStringForLabel(ccbfile,{mSoldierNum = tostring(armyCount)})
    UIExtend.setStringForLabel(ccbfile,{mSoldierName = _RALang(armyConf.name)})
end

--data:结构由1个itemTable组成
function RAWorldArmyDetailsPage:pushCellToScrollView(data)
    -- body
    self.scrollView:removeAllCell()
    local scrollView = self.scrollView
    for k,v in pairs(data) do
        local cell = CCBFileCell:create()
        local ccbiStr = "RAWorldArmyDetailsPopUpCell.ccbi"
        local panel = RAWorldArmyDetailsCellPage:new({
                mData = v
        })
        cell:registerFunctionHandler(panel)
        cell:setCCBFile(ccbiStr)
        scrollView:addCell(cell)
    end
    scrollView:orderCCBFileCells()
end

function RAWorldArmyDetailsPage:onClose()
    local RARootManager = RARequire("RARootManager")
    RARootManager.CloseCurrPage()
end

function RAWorldArmyDetailsPage:onReceivePacket(handler)
    local pbCode = handler:getOpcode()
    local buffer = handler:getBuffer()
    if pbCode == HP_pb.WORLD_CHECK_ARMY_DETAIL_S then
        local msg = World_pb.WorldCheckArmyDetailResp()
        msg:ParseFromString(buffer)
        if msg then
            RATroopsInfoManager.setRunTroopsData(msg)
            self:refreshArmyInfo()
        end
    end
end

return RAWorldArmyDetailsPage
--endregion
