--region *.lua
--Date
--此文件由[BabeLua]插件自动生成

--大使馆联盟援助界面
local RALogicUtil = RARequire("RALogicUtil")
local RAStringUtil = RARequire("RAStringUtil")
local Const_pb =RARequire('Const_pb')
local HP_pb=RARequire("HP_pb")
local GuildAssistant_pb=RARequire("GuildAssistant_pb")
local World_pb=RARequire("World_pb")
local UIExtend = RARequire("UIExtend")
local Utilitys = RARequire("Utilitys")
local RAGameConfig=RARequire("RAGameConfig")
local RARootManager = RARequire("RARootManager")
local Utilitys=RARequire("Utilitys")
local RA_Common = RARequire("common")
local RANetUtil=RARequire("RANetUtil")
local RAPlayerInfoManager=RARequire("RAPlayerInfoManager")
local battle_soldier_conf=RARequire("battle_soldier_conf")
local RAWorldPushHandler=RARequire("RAWorldPushHandler")
RARequire("MessageDefine")
RARequire("MessageManager")


local RAEmabassyPage = BaseFunctionPage:new(...)

local TAG=1000
-----------------------------------------------------------------------
local RAEmabassyPageIconCell = {

}
function RAEmabassyPageIconCell:new(o)
    o = o or {}
    setmetatable(o,self)
    self.__index = self    
    return o
end

function RAEmabassyPageIconCell:onRefreshContent(ccbRoot)
	if not ccbRoot then return end
	local ccbfile = ccbRoot:getCCBFileNode()

	local armyId=self.armyId
	local num=self.num
	local soldierData=battle_soldier_conf[tonumber(armyId)]
	local iconName=soldierData.icon

	local picNode =  UIExtend.getCCNodeFromCCB(ccbfile,"mIconNode")
	UIExtend.addNodeToAdaptParentNode(picNode,iconName,TAG)

	UIExtend.setCCLabelString(ccbfile,"mTroopsNum",num)

end 
-----------------------------------------------------------------------
local RAEmabassyPageSoldierCell={}
function RAEmabassyPageSoldierCell:new(o)
    o = o or {}
    setmetatable(o,self)
    self.__index = self    
    return o
end
function RAEmabassyPageSoldierCell:onRefreshContent(ccbRoot)
	
	if not ccbRoot then return end
	local ccbfile = ccbRoot:getCCBFileNode()
	self.ccbRoot=ccbRoot

	local scrollview=UIExtend.getCCScrollViewFromCCB(ccbfile,"mTroopsListSV")
	scrollview:removeAllCell()
	self.listSV=scrollview

	local data=self.data
	local count=#data
	for i=1,count do
		local soldierData=self.data[i]
		local cell=CCBFileCell:create()
		local panel = RAEmabassyPageIconCell:new({
		 	armyId=soldierData.armyId,
		 	num=soldierData.count
		})
	    cell:registerFunctionHandler(panel)
		cell:setCCBFile("RAAllianceWarGatherCell2Node.ccbi")
		scrollview:addCellBack(cell)

	end
	scrollview:orderCCBFileCells()

end
function RAEmabassyPageSoldierCell:onUnLoad( ccbRoot )
	self:removeAllCell()
end
function RAEmabassyPageSoldierCell:removeAllCell()
	self.listSV:removeAllCell()
end
-----------------------------------------------------------------------
local RAEmabassyPagePlayerCell = {

}
function RAEmabassyPagePlayerCell:new(o)
    o = o or {}
    setmetatable(o,self)
    self.__index = self    
    return o
end


function RAEmabassyPagePlayerCell:onRefreshContent(ccbRoot)
	
	if not ccbRoot then return end
	local ccbfile = ccbRoot:getCCBFileNode()
	self.ccbRoot=ccbRoot
	UIExtend.handleCCBNode(ccbfile)

	UIExtend.setNodeVisible(ccbfile,"mGatherStateLabel",false)

	local data=self.data
	self.uuid=data.uuid

	--icon
	local iconId=data.icon
	local iconName=RAPlayerInfoManager.getHeadIcon(iconId)
	local picNode =  UIExtend.getCCNodeFromCCB(ccbfile,"mCellIconNode")
	UIExtend.addNodeToAdaptParentNode(picNode,iconName,TAG)

	--name
	local playerName=data.playerName
	UIExtend.setCCLabelString(ccbfile,"mPlayerName",playerName)

	--count
	local armySoldier=data.armySoldier
	local kinds=#armySoldier
	local  totalCount=0
	for i=1,kinds do
		local  soldierData=armySoldier[i]
		local count=soldierData.count
		totalCount=totalCount+count
	end
	totalCount=Utilitys.formatNumber(totalCount)
	UIExtend.setCCLabelString(ccbfile,"mTroopsNum",totalCount)

	UIExtend.setCCLabelString(ccbfile,"mTroopsTitle",_RALang("@SoldierNum"))

	UIExtend.setControlButtonTitle(ccbfile, "mAccelerateBtn", _RALang("@TroopsRepatriate"), true)
	

	local arrowSprite=UIExtend.getCCSpriteFromCCB(ccbfile,"mArrowPic")
	self.arrowSprite=arrowSprite
	self.arrowSprite:setRotation(360)

end

function RAEmabassyPagePlayerCell:refreshIndex(index)
	self.index=index
end

--遣返
function RAEmabassyPagePlayerCell:onAccelerateBtn()
	RAEmabassyPage.qianfanPanel=self
	RAWorldPushHandler:sendMassRepatriateReq(self.uuid)
	
end
function RAEmabassyPagePlayerCell:onDetailsBtn()
	if not self.isOpen then
		self.isOpen= true
		--箭头旋转
		self.arrowSprite:setRotation(90)

	else
		self.isOpen= false
		self.arrowSprite:setRotation(360)
	end 

	RAEmabassyPage:refreshCellIndex(self.index,self.isOpen)

	--true时添加一个cell
	if self.isOpen then
		local soldierData=RAEmabassyPage:getSoldierDataByUUid(self.uuid)

		--添加一个cell显示详细的兵种
		MessageManager.sendMessage(MessageDef_ScrollViewCell.MSG_MailScoutListCell, {isAdd=true,data=soldierData,uuid= self.uuid,index=self.index})
		-- RAEmabassyPage:addSoldierCell(soldierData,self.index,self.uuid)
	else


		--删除这个cell
		MessageManager.sendMessage(MessageDef_ScrollViewCell.MSG_MailScoutListCell, {uuid= self.uuid})
		-- RAEmabassyPage:deleteSoldierCell(self.uuid)

	end 
end

-------------------------------------------------------------------
local OnReceiveMessage = function(message)
	if message.messageID == MessageDef_ScrollViewCell.MSG_MailScoutListCell then
		if message.isAdd then
     		local soldierData = message.data
     		RAEmabassyPage:addSoldierCell(soldierData,message.index,message.uuid)
     	else
     		RAEmabassyPage:deleteSoldierCell(message.uuid)
     	end 
     	

    end
end

function RAEmabassyPage:Enter(data)


	CCLuaLog("RAEmabassyPage:Enter")
	local ccbfile = UIExtend.loadCCBFile("RAEmbassyPage.ccbi",self)
	self.ccbfile  = ccbfile
	self.buildConData=data.confData
	self.qianfanPanel=nil
	self.netHandlers = {}
	self:registerMessageHandler()
	self:addHandler()
	self:init()

end



function RAEmabassyPage:refreshCellIndex(clickIndex,isOpen)
	
	for i,v in ipairs(self.cellTab) do
		local cell=v
		local tmpIndex=cell.index
		if isOpen then
			if tmpIndex>clickIndex then 
				cell:refreshIndex(tmpIndex+1)
			end 
		else

			if tmpIndex>clickIndex then
				cell:refreshIndex(tmpIndex-1) 
			end 
		end

	end
end
function RAEmabassyPage:init()

	-- --title  
	local titleCCB=UIExtend.getCCBFileFromCCB(self.ccbfile,"mAllianceCommonCCB")
	UIExtend.setCCLabelString(titleCCB,"mTitle",_RALang("@CheckAssistance"))
	UIExtend.setNodeVisible(titleCCB,"mDiamondsNode",false)

	--判断文字是否需要滚动
	UIExtend.setCCLabelString(self.ccbfile,"mExplainLabel",_RALang(self.buildConData.buildDes))
	self.mExplainLabel= UIExtend.getCCLabelTTFFromCCB(self.ccbfile,"mExplainLabel")
	self.mExplainLabelStarP =ccp(self.mExplainLabel:getPosition())
	UIExtend.createLabelAction(self.ccbfile,"mExplainLabel")

	UIExtend.setCCLabelString(self.ccbfile,"mGatherTroopsNum","")

	self.mInfoListSV=UIExtend.getCCScrollViewFromCCB(self.ccbfile,"mInviteListSV")
	--发送协议请求数据

	self:sendProtoReq()

end

function RAEmabassyPage:onReceivePacket(handler)
    local pbCode = handler:getOpcode()
    local buffer = handler:getBuffer()
    if pbCode == HP_pb.GUILD_ASSISTANT_INFO_S then  
    	local msg = GuildAssistant_pb.HPGuildAssistantResp()
        msg:ParseFromString(buffer)

        local data = msg
        RAEmabassyPage:updateInfo(data)
    elseif pbCode == HP_pb.WORLD_MASS_REPATRIATE_S then
		local msg = World_pb.WorldMassRepatriateResp()
        msg:ParseFromString(buffer)
        --RAEmabassyPage:removeOneCell()

        local uuid= RAEmabassyPage.qianfanPanel.uuid
        RAEmabassyPage:deleteEmabassyCell(uuid)	
   	elseif pbCode == HP_pb.ASSISTANCE_MARCH_CALLBACK then
   		local msg = GuildAssistant_pb.AssistanceCallbackNotifyPB()
        msg:ParseFromString(buffer)

        local marchId = msg.marchId
        RAEmabassyPage:deleteEmabassyCell(marchId)	
    end

end

function RAEmabassyPage:sendProtoReq()
	 RANetUtil:sendPacket(HP_pb.GUILD_ASSISTANT_INFO_C)
end

function RAEmabassyPage:addSoldierCell(soldierData,index,uuid)

	local cell = CCBFileCell:create()
	local panel = RAEmabassyPageSoldierCell:new({
				data=soldierData,
	})
	panel.selfCell=cell
	cell:registerFunctionHandler(panel)
	cell:setCCBFile("RAAllianceWarGatherCell2.ccbi")
	self.mInfoListSV:addCell(cell,index)
	self.soldierCellTab[uuid]=panel
	self.mInfoListSV:orderCCBFileCells()
end

function RAEmabassyPage:deleteSoldierCell(uuid)
	local soldierCell=self.soldierCellTab[uuid]
	if soldierCell then
        soldierCell:removeAllCell()

		self.mInfoListSV:removeCell(soldierCell.selfCell)
		self.soldierCellTab[uuid]=nil
	end 
end

function RAEmabassyPage:removeOneCell()
	if self.qianfanPanel then

		local isOpen=self.qianfanPanel.isOpen
		local uuid=self.qianfanPanel.uuid
		local index=self.qianfanPanel.index
		--刷新index
		self:refreshIndexByDeleteCell(index,isOpen)
		self.mInfoListSV:removeCell(self.qianfanPanel.selfCell)
		if isOpen then
			self:deleteSoldierCell(uuid)
		end 
		self.qianfanPanel=nil
	end 
	
end

--召回援助类行军时通知被援助方 删除cell
function RAEmabassyPage:deleteEmabassyCell(uuid)
	local panel = self.emabassyCell[uuid]
	if panel then
        --cell:removeAllCell()

        --count
		local armySoldier = panel.data.armySoldier
		local kinds = #armySoldier
		local soldieCount = 0
		for i=1,kinds do
			local  soldierData = armySoldier[i]
			local count = soldierData.count
			soldieCount = soldieCount + count
		end

		self.mInfoListSV:removeCell(panel.selfCell)
		self.emabassyCell[uuid]=nil

		self.totalCount = self.totalCount - soldieCount

		UIExtend.setCCLabelString(self.ccbfile,"mGatherTroopsNum",_RALang("@AssistanceSoldiers",self.totalCount))
	end 
end

--手动删除时刷新index
function RAEmabassyPage:refreshIndexByDeleteCell(index,isOpen)

	local offsetIndex=1
	if isOpen then
		offsetIndex=2
	end 

	for i,v in ipairs(self.cellTab) do
		local cell=v
		local tmpIndex=cell.index
		if tmpIndex>index then
			cell:refreshIndex(tmpIndex-offsetIndex)
		end 
	end
	
end
function RAEmabassyPage:updateInfo(assitanceData)
   
    self.mInfoListSV:removeAllCell()
    local scrollview=self.mInfoListSV
	
	self:clearCellTab()
	self.soldierDataTab={}

	--用来存cell
	self.emabassyCell = {}

    --援军总数
    self.totalCount=assitanceData.forces
    UIExtend.setCCLabelString(self.ccbfile,"mGatherTroopsNum",_RALang("@AssistanceSoldiers",self.totalCount))

    --援军部队信息
    local marchListData=assitanceData.marchList
    local count=#marchListData
    for i=1,count do
    	local marchData=marchListData[i]
    	local cell = CCBFileCell:create()
		local panel = RAEmabassyPagePlayerCell:new({
				data=marchData,
				index=i
	    })
	    panel.selfCell=cell
		cell:registerFunctionHandler(panel)
		cell:setCCBFile("RAAllianceWarGatherCell1.ccbi")
		scrollview:addCellBack(cell)

		table.insert(self.cellTab,panel)

		--存储一份兵种信息
		local uuid=marchData.uuid
		local soldierData=marchData.armySoldier
		self.soldierDataTab[uuid]=soldierData

		self.emabassyCell[uuid] = panel
	end

	scrollview:orderCCBFileCells()


end

function RAEmabassyPage:getSoldierDataByUUid(uuid)
	return self.soldierDataTab[uuid]
end
function RAEmabassyPage:addHandler()
    self.netHandlers[#self.netHandlers + 1] = RANetUtil:addListener(HP_pb.GUILD_ASSISTANT_INFO_S, RAEmabassyPage) 		--查看联盟援助
    self.netHandlers[#self.netHandlers + 1] = RANetUtil:addListener(HP_pb.WORLD_MASS_REPATRIATE_S, RAEmabassyPage) 		--遣返成功返回
    self.netHandlers[#self.netHandlers + 1] = RANetUtil:addListener(HP_pb.ASSISTANCE_MARCH_CALLBACK, RAEmabassyPage) 		--召回援助类行军时通知被援助方
end


function RAEmabassyPage:removeHandler()
    for k, value in pairs(self.netHandlers) do
        RANetUtil:removeListener(value)
    end
end

function RAEmabassyPage:registerMessageHandler()

    MessageManager.registerMessageHandler(MessageDef_ScrollViewCell.MSG_MailScoutListCell,OnReceiveMessage)
end

function RAEmabassyPage:removeMessageHandler()
    MessageManager.removeMessageHandler(MessageDef_ScrollViewCell.MSG_MailScoutListCell,OnReceiveMessage)
end



function RAEmabassyPage:clearCellTab()
	if self.cellTab then
		for i,v in ipairs(self.cellTab) do
			v=nil
		end
	end 
	self.cellTab={}

	if self.soldierCellTab then
		for i,v in pairs(self.soldierCellTab) do
			local soldierCell=v
			soldierCell:removeAllCell()
			v=nil
		end
	end
	self.soldierCellTab={}
end

function RAEmabassyPage:clearSoldierDatas()
	if self.soldierDataTab then
		for k,v in pairs(self.soldierDataTab) do
			v=nil
		end
	end 
	
	self.soldierDataTab=nil
end
function RAEmabassyPage:Exit()

	self.mInfoListSV:removeAllCell()
	self:removeHandler()
	self:removeMessageHandler()
	self:clearSoldierDatas()
	self:clearCellTab()
	self.cellTab=nil
	self.netHandlers=nil
	self.qianfanPanel=nil
	self.mExplainLabel:stopAllActions()
	self.mExplainLabel:setPosition(self.mExplainLabelStarP)
	UIExtend.unLoadCCBFile(RAEmabassyPage)
	
end

function RAEmabassyPage:mAllianceCommonCCB_onBack()
	RARootManager.CloseCurrPage()
end




--endregion
