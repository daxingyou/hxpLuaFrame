--region *.lua
--Date
--此文件由[BabeLua]插件自动生成


local RALogicUtil = RARequire("RALogicUtil")
local RAStringUtil = RARequire("RAStringUtil")
local UIExtend = RARequire("UIExtend")
local Utilitys = RARequire("Utilitys")
local RARootManager = RARequire("RARootManager")
local RANetUtil=RARequire("RANetUtil")
local RAAllianceProtoManager=RARequire("RAAllianceProtoManager")
local RAScienceUtility=RARequire("RAScienceUtility")
local RAQueueManager=RARequire("RAQueueManager")
local RAPlayerInfoManager=RARequire("RAPlayerInfoManager")
RARequire("RABuildingUtility")
RARequire("MessageDefine")
RARequire("MessageManager")
local HP_pb = RARequire("HP_pb")
local GuildManager_pb = RARequire('GuildManager_pb')
local Const_pb=RARequire("Const_pb")
local helpMsg=MessageDef_AllianceHelp.MSG_DELETE
local TAG=1000

local RAAllianceHelpPage = BaseFunctionPage:new(...)

-----------------------------------------------------------
local RAAllianceHelpPageCell={}
function RAAllianceHelpPageCell:new(o)
    o = o or {}
    setmetatable(o,self)
    self.__index = self    
    return o
end


function RAAllianceHelpPageCell:onRefreshContent(ccbRoot)

	CCLuaLog("RAAllianceHelpPageCell:onRefreshContent")
	if not ccbRoot then return end
	local ccbfile = ccbRoot:getCCBFileNode()
    self.ccbfile = ccbfile
    UIExtend.handleCCBNode(ccbfile)


	local data=self.data
	self.queueId=data.queueId
   	
 	--头像
 	local picNode = UIExtend.getCCNodeFromCCB(ccbfile,"mCellIconNode")
 	local icon=RAPlayerInfoManager.getHeadIcon(data.applyIcon)
 	UIExtend.addNodeToAdaptParentNode(picNode,icon,TAG)

 	--名字
 	local name=data.applyName
 	UIExtend.setCCLabelString(ccbfile,"mPlayerName",name)

 	--描述
 	local queueType=data.queueType
 	local des=""
 	if queueType==Const_pb.BUILDING_QUEUE or queueType == Const_pb.BUILDING_DEFENER then
 	
 		local buildId=data.itemId
 		local buildInfo=RABuildingUtility.getBuildInfoById(buildId) 
 		des=_RALang("@AllianceHelpBuildQueue",buildInfo.level,_RALang(buildInfo.buildName))

 		local queueStatus = data.queueStatus
 		if queueStatus == Const_pb.QUEUE_STATUS_UPGRADE or queueStatus == Const_pb.QUEUE_STATUS_COMMON then -- 防御建筑升级中
 			des = _RALang("@AllianceHelpUpgradeQueue",buildInfo.level,_RALang(buildInfo.buildName))
 		elseif queueStatus == Const_pb.QUEUE_STATUS_REPAIR then -- 防御建筑维修中
 			des = _RALang("@AllianceHelpBuildRepairQueue",buildInfo.level,_RALang(buildInfo.buildName))
		elseif queueStatus == Const_pb.QUEUE_STATUS_REBUILD then -- 建筑改建中
			des = _RALang("@AllianceHelpBuildRebuildQueue",buildInfo.level,_RALang(buildInfo.buildName))
 		end
 	elseif queueType==Const_pb.SCIENCE_QUEUE then
 		local techId=data.itemId
 		local techInfo=RAScienceUtility:getScienceDataById(techId)
 		des=_RALang("@AllianceHelpTechQueue",_RALang(techInfo.techName))

 	elseif queueType==Const_pb.CURE_QUEUE then
 		des=_RALang("@AllianceHelpCureQueue")
 	end 
 	UIExtend.setCCLabelString(ccbfile,"mHelpMeSomeLabel",des)
   
   	--进度
   	local curCount=data.curCount
   	local totalCount=data.totalCount 
   	local scaleX=curCount/totalCount
   	local helpNum=_RALang("@AllianceHelpNum",curCount,totalCount)
   	UIExtend.setCCLabelString(ccbfile,"mHelpNum",helpNum)

    local mBar=UIExtend.getCCScale9SpriteFromCCB(ccbfile,"mBar")
    mBar:setScaleX(scaleX)

    --如果是自己就不可以点帮助
   
    local applyID=data.applyId
    if  RAAllianceHelpPage.playerId==applyID then
    	-- UIExtend.setCCControlButtonEnable(ccbfile,"mHelpBtn",false)
    	UIExtend.getCCControlButtonFromCCB(ccbfile,'mHelpBtn'):setVisible(false)
    else
    	UIExtend.getCCControlButtonFromCCB(ccbfile,'mHelpBtn'):setVisible(true)
    	-- UIExtend.setCCControlButtonEnable(ccbfile,"mHelpBtn",true)
    end 
 	

end

function RAAllianceHelpPageCell:onHelpBtn()
	RAAllianceProtoManager:sendHelpInfoReq(self.queueId)
end

--------------------------------------------------

local OnReceiveMessage = function(message)
    if message.messageID == helpMsg then
      local id=message.queueId
      RAAllianceHelpPage:updateScrollViewCell(id)
    end
end

function RAAllianceHelpPage:Enter()


	CCLuaLog("RAAllianceHelpPage:Enter")
	local ccbfile = UIExtend.loadCCBFile("RAAllianceHelpPage.ccbi",self)
	self.ccbfile  = ccbfile
	self.netHandlers = {}
	self:addHandler()
	self:registerMessageHandler()
    self:init()
    
end
function RAAllianceHelpPage:onReceivePacket(handler)
    local pbCode = handler:getOpcode()
    local buffer = handler:getBuffer()
    if pbCode == HP_pb.GUILDMANAGER_CHECKQUEUES_S then  
    	local msg = GuildManager_pb.CheckGuildHelpQueueRes()
        msg:ParseFromString(buffer)

        self.helpData = msg.queue
     	RAAllianceHelpPage:updateInfo(msg.queue)
    elseif pbCode == HP_pb.GUILDMANAGER_HELPQUEUE_S then
    	local msg = GuildManager_pb.HelpGuildQueueRes()
        msg:ParseFromString(buffer)
        local id=msg.queueId
    	--发一个消息刷新
    	MessageManager.sendMessage(helpMsg,{queueId=id})
    elseif pbCode == HP_pb.GUILDMANAGER_HELPALLQUEUES_S then
    	-- self.mHelpListSV:removeAllCell()
    	RAAllianceProtoManager:sendGetHelpInfoReq()
    end

end


function RAAllianceHelpPage:addHandler()
    self.netHandlers[#self.netHandlers + 1] = RANetUtil:addListener(HP_pb.GUILDMANAGER_CHECKQUEUES_S, RAAllianceHelpPage) 		--查看联盟帮助队列
    self.netHandlers[#self.netHandlers + 1] = RANetUtil:addListener(HP_pb.GUILDMANAGER_HELPQUEUE_S, RAAllianceHelpPage)   		--联盟帮助
    self.netHandlers[#self.netHandlers + 1] = RANetUtil:addListener(HP_pb.GUILDMANAGER_HELPALLQUEUES_S, RAAllianceHelpPage)   	--联盟帮助所有   
end


function RAAllianceHelpPage:removeHandler()
    for k, value in pairs(self.netHandlers) do
        RANetUtil:removeListener(value)
    end
end
function RAAllianceHelpPage:init()

	local titleCCB=UIExtend.getCCBFileFromCCB(self.ccbfile,"mAllianceCommonCCB")

	--标题
	UIExtend.setCCLabelString(titleCCB,"mTitle",_RALang("@AllianceHelp"))
	UIExtend.setNodeVisible(titleCCB,"mDiamondsNode",false)

	UIExtend.setNodeVisible(self.ccbfile,"mTips",false)
	UIExtend.setCCControlButtonEnable(self.ccbfile,"mHelpAllBtn",true)

	self.mHelpListSV=UIExtend.getCCScrollViewFromCCB(self.ccbfile,"mHelpListSV")


	--每次打开都发送协议请求数据
	RAAllianceProtoManager:sendGetHelpInfoReq()
	
end

function RAAllianceHelpPage:showTips()
	UIExtend.setNodeVisible(self.ccbfile,"mTips",true)
	UIExtend.setCCLabelString(self.ccbfile,"mTips",_RALang("@AllianceHelpTip"))

	--禁止点击
	UIExtend.setCCControlButtonEnable(self.ccbfile,"mHelpAllBtn",false)
end
function RAAllianceHelpPage:updateInfo(AllianceHelpDatas)

	
	local playerInfo=RAPlayerInfoManager.getPlayerInfo()
	self.playerId=playerInfo.raPlayerBasicInfo.playerId

	self.mHelpListSV:removeAllCell()
	self:clearCellTab()
	local scrollview = self.mHelpListSV
	local count=#AllianceHelpDatas

	if count==0 then
		self:showTips()
		return 
	end 
	
	--只有自己
	-- local playerInfo=RAPlayerInfoManager.getPlayerInfo()
	-- if count==1 then
	-- 	local AllianceHelpData=AllianceHelpDatas[1]
	-- 	local applyId = AllianceHelpData.applyId
	-- 	if playerInfo.raPlayerBasicInfo.playerId==applyId then
	-- 		self:showTips()
	-- 		return 
	-- 	end 
	-- end
	local orderArr = {}
	local restArr = {}
	for i=1,count do
		local AllianceHelpData=AllianceHelpDatas[i]
		local applyId = AllianceHelpData.applyId
		--自己申请的帮助不显示
		if playerInfo.raPlayerBasicInfo.playerId==applyId then
			orderArr[#orderArr+1] = AllianceHelpData
		else
			restArr[#restArr+1] = AllianceHelpData
		end
	end 

	for i=1,#restArr do
		orderArr[#orderArr+1] = restArr[i]
	end

	local helpAllBtnEnable = false

	for i=1,count do
		local AllianceHelpData=orderArr[i]
		local applyId = AllianceHelpData.applyId
		--自己申请的帮助不显示
		if playerInfo.raPlayerBasicInfo.playerId ~= applyId then
			helpAllBtnEnable = true
		end
		-- if playerInfo.raPlayerBasicInfo.playerId~=applyId then
			local cell = CCBFileCell:create()
			local panel = RAAllianceHelpPageCell:new({
					data = AllianceHelpData,
	        })
			cell:registerFunctionHandler(panel)
			cell:setCCBFile("RAAllianceHelpCell.ccbi")
			scrollview:addCellBack(cell)
			self.cellTab[AllianceHelpData.queueId]=cell
		-- end
	end
	scrollview:orderCCBFileCells()

	UIExtend.setCCControlButtonEnable(self.ccbfile,"mHelpAllBtn",helpAllBtnEnable)
end

function RAAllianceHelpPage:updateScrollViewCell(queueId)
	local cell=self.cellTab[queueId]
	self.mHelpListSV:removeCell(cell)
end
function RAAllianceHelpPage:registerMessageHandler()
    MessageManager.registerMessageHandler(helpMsg,OnReceiveMessage) 
end

function RAAllianceHelpPage:removeMessageHandler()
    MessageManager.removeMessageHandler(helpMsg,OnReceiveMessage)
end


function RAAllianceHelpPage:clearCellTab()
	if self.cellTab then
		for k,v in pairs(self.cellTab) do
			v=nil
		end 
	end
	self.cellTab={} 
	
end
function RAAllianceHelpPage:Exit()
	self:clearCellTab()
	self.cellTab=nil
	self.mHelpListSV:removeAllCell()
	self:removeMessageHandler()
	self:removeHandler()
	UIExtend.unLoadCCBFile(RAAllianceHelpPage)
	
end

function RAAllianceHelpPage:onClose()
	RARootManager.CloseCurrPage()
end


function RAAllianceHelpPage:mAllianceCommonCCB_onBack()
	self:onClose()
end

function RAAllianceHelpPage:onHelpAllBtn()
	RAAllianceProtoManager:sendHelpAllInfoReq()

	--self:clrearOrtherHelp(self.helpData)
end

--帮助所有之后，只显示自己的了
function RAAllianceHelpPage:clrearOrtherHelp(AllianceHelpDatas)
	local playerInfo = RAPlayerInfoManager.getPlayerInfo()
	self.playerId = playerInfo.raPlayerBasicInfo.playerId

	self.mHelpListSV:removeAllCell()
	self:clearCellTab()
	local scrollview = self.mHelpListSV
	local count = #AllianceHelpDatas
	
	for i=1,count do
		local AllianceHelpData = AllianceHelpDatas[i]
		local applyId = AllianceHelpData.applyId
		--自己申请的帮助不显示
		if self.playerId == applyId then
			local cell = CCBFileCell:create()
			local panel = RAAllianceHelpPageCell:new({
					data = AllianceHelpData,
	        })
			cell:registerFunctionHandler(panel)
			cell:setCCBFile("RAAllianceHelpCell.ccbi")
			scrollview:addCellBack(cell)
			self.cellTab[AllianceHelpData.queueId]=cell
		end
	end
	scrollview:orderCCBFileCells()
end
--endregion
