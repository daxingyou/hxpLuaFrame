
-- 战斗邮件:遭受闪电风暴攻击，
local RALogicUtil = RARequire("RALogicUtil")
local RAStringUtil = RARequire("RAStringUtil")
local UIExtend = RARequire("UIExtend")
local Utilitys = RARequire("Utilitys")
local RARootManager = RARequire("RARootManager")
local RAMailManager = RARequire("RAMailManager")
local RAMailUtility = RARequire("RAMailUtility")
local RAMailConfig = RARequire("RAMailConfig")

local refreshMailListMsg =MessageDefine_Mail.MSG_Refresh_MailList
local refreshMailOptListMsg  = MessageDefine_Mail.MSG_Refresh_MailOptList
local readMailMsg = MessageDefine_Mail.MSG_Read_Mail
local RAMailLightingStormPage = BaseFunctionPage:new(...)
local OnReceiveMessage = function(message)
    if message.messageID == readMailMsg then
      local mailDatas = message.mailDatas
      local id=mailDatas.id
      --存储一份阅读数据
      RAMailManager:addPlayerBattleMailCheckDatas(id,mailDatas)
      RAMailLightingStormPage:updateInfo(mailDatas)
    end
end
-----------------------------------------------------------

-----------------------------------------------------------------
local RAMailLightingStormPageCell={}

function RAMailLightingStormPageCell:new(o)
    o = o or {}
    setmetatable(o,self)
    self.__index = self    
    return o
end

-- message SaveResource{
-- 	required int32 type	= 1;//资源类型
-- 	required int32 num	= 2;//资源数目
-- }
-- //被闪电风暴轰炸邮件
-- message BeStormBombedMail{
-- 	required sint32 x				= 1;//爆炸点坐标X
-- 	required sint32	y				= 2;//爆炸点坐标Y
-- 	required int64	time			= 3;//爆炸时间
-- 	required int32	buildingId		= 4;//建筑ID
-- 	required int64	breakTime		= 5;//打断时间（毫秒）
-- 	required string	fromGuild		= 6;//发射联盟名称
-- 	repeated SaveResource resource	= 7;//挽回资源损失
-- }
function RAMailLightingStormPageCell:onRefreshContent(ccbRoot)


	if not ccbRoot then return end
	local ccbfile = ccbRoot:getCCBFileNode()
    self.ccbfile = ccbfile
    local data= self.data

    --target

  	local x = data.x
	local y = data.y
	local targetHtmlLabel = UIExtend.getCCLabelHTMLFromCCB(self.ccbfile,"mStrikeTargetTitle") 
	local RAChatManager = RARequire("RAChatManager")
	targetHtmlLabel:registerLuaClickListener(RAChatManager.createHtmlClick)
	local htmlStr =_RAHtmlLang("StormTarget",x,y)
	UIExtend.setCCLabelHTMLString(self.ccbfile,"mStrikeTargetTitle",htmlStr)

	--time
	local time = data.time
	local timeStr = RAMailUtility:formatMailTime(time)
	UIExtend.setCCLabelString(self.ccbfile,"mTime",timeStr)

	--breakBuild
	local buildingId = data.buildingId
	RARequire("RABuildingUtility")
	local info = RABuildingUtility.getBuildInfoById(buildingId) 
	local icon = info.buildArtImg
	local curLevel = info.level
	local buildName = _RALang(info.buildName)
	htmlStr =_RAHtmlLang("BreakBuildUpgrade",buildName)

	local picNode = UIExtend.getCCNodeFromCCB(self.ccbfile,"mBuildIconNode")
 	UIExtend.addNodeToAdaptParentNode(picNode,icon,RAMailConfig.TAG)

 	local breakBuildName = _RALang("@BuildUpgradBreak",_RALang(info.buildName))
 	UIExtend.setCCLabelString(self.ccbfile,"mHitStateLabel",breakBuildName)
 	UIExtend.setCCLabelString(self.ccbfile,"mBeforeLevel",_RALang("@ResCollectTargetLevel",curLevel))
 	UIExtend.setCCLabelString(self.ccbfile,"mAfterLevel",_RALang("@ResCollectTargetLevel",curLevel+1))

 	--breakTime
 	local breakTime =Utilitys.createTimeWithFormat(data.breakTime)
 	breakTime=_RALang("@BreakTime")..breakTime
	UIExtend.setCCLabelString(self.ccbfile,"mInterruptionTime",breakTime)

	--process
	local nextInfo = RABuildingUtility.getBuildInfoById(buildingId+1)
	local totalTime = nextInfo.buildTime
	local pro = data.breakTime/totalTime
	pro = math.min(pro,1)
	local bar = UIExtend.getCCScale9SpriteFromCCB(self.ccbfile,"mBar")
	bar:setScaleX(pro)

	UIExtend.setCCLabelString(self.ccbfile,"mResTitle",_RALang("@SaveRes"))
    
   
    local resources = data.resource
    self:hideAll()
    for i=1,4 do
    	local var = "mResNode"..i
    	local resource = resources[i]
    	if resource then
    		local varTitle = "mCellLabel"..i
    		local varCont = "mCellNum"..i
    		local resType = resource.type
    		local num = resource.num
    		num = "+"..Utilitys.formatNumber(num)
    		local icon = RALogicUtil:getResourceIconById(resType)
    		local name = RALogicUtil:getResourceNameById(resType)

    		local picNode=UIExtend.getCCNodeFromCCB(self.ccbfile,"mIconNode"..i)
    		UIExtend.addNodeToAdaptParentNode(picNode,icon,RAMailConfig.TAG)

    		UIExtend.setCCLabelString(self.ccbfile,varTitle,name)
    		UIExtend.setCCLabelString(self.ccbfile,varCont,num)
    		UIExtend.setNodeVisible(self.ccbfile,var,true)
    	else
    		UIExtend.setNodeVisible(self.ccbfile,var,false)
    	end 

    end
end

function RAMailLightingStormPageCell:hideAll()
	for i=1,4 do
		local var = "mResNode"..i
		UIExtend.setNodeVisible(self.ccbfile,var,false)
	end
end
function RAMailLightingStormPage:Enter(data)


	CCLuaLog("RAMailLightingStormPage:Enter")
	local ccbfile = UIExtend.loadCCBFile("RAMailSuperWeaponsHitPageV6.ccbi",self)
	self.ccbfile  = ccbfile

    self.id = data.id
	self:registerMessageHandler()
    self:init()
    
end
function RAMailLightingStormPage:mCommonTitleCCB_onHomeBackBtn()
	RARootManager.CloseAllPages()
end
function RAMailLightingStormPage:init()


	-- UIExtend.setCCLabelString(self.ccbfile,"mSysTimeLabel","")

	local mailInfo =RAMailManager:getMailById(self.id)
	local configId =mailInfo.configId
	local titleCCB=UIExtend.getCCBFileFromCCB(self.ccbfile,"mCommonTitleCCB")
	self.titleCCB=titleCCB
	self.titleCCB:runAnimation("InAni")
	UIExtend.setNodeVisible(titleCCB,"mCmnDeleteNode",true)
	

	local configData = RAMailUtility:getNewMailData(configId)
	--title
	local title = _RALang(configData.mainTitle)
	UIExtend.setCCLabelString(titleCCB,"mTitle",title)

	--banner 
	
	local mailBanner = configData.mailBanner
	local render = UIExtend.getCCSpriteFromCCB(self.ccbfile,"mRenderedPic")
	render:setTexture(mailBanner)

	self.ListSV = UIExtend.getCCScrollViewFromCCB(self.ccbfile,"mListSV")

	self.mailInfo = mailInfo


	 --判断是否锁定
	self.lock = mailInfo.lock
	 
	
	--判断是否已读
	self.status = mailInfo.status

		--self.isFrstRead 表示是否第一次阅读 
	self.isFrstRead = RAMailManager:isMailFirstRead(self.id)
	if self.isFrstRead then
		RAMailManager:sendReadCmd(self.id)
	else
		local mailDatas = RAMailManager:getPlayerBattleMailCheckDatas(self.id)
		self:updateInfo(mailDatas)
	end 

	
end


function RAMailLightingStormPage:genDatas(superBome)
	local tb={}
	tb.x = superBome.x
	tb.y = superBome.y
	tb.time = math.floor(superBome.time/1000)
	tb.buildingId = superBome.buildingId
	tb.breakTime = math.floor(superBome.breakTime/1000)
	tb.buildingId = superBome.buildingId
	tb.fromGuild = superBome.fromGuild


	local resources = superBome.resource
	local count=#resources
	if count > 0 then
		tb.resource={}
		for i=1,count do
			local t={}
			local resource = resources[i]
			t.type = resource.type
			t.num = resource.num
			table.insert(tb.resource,t)
		end
	end 

	return tb
end

function RAMailLightingStormPage:updateInfo(mailInfo)


	local superBome = mailInfo.beStormBombedMail
	local tb = self:genDatas(superBome)

	self.ListSV:removeAllCell()
	local scrollview = self.ListSV
	local cell = CCBFileCell:create()
	local panel = RAMailLightingStormPageCell:new({
			data = tb,
    })
	cell:registerFunctionHandler(panel)
	cell:setCCBFile("RAMailSuperWeaponsHitCell2V6.ccbi")
	scrollview:addCellBack(cell)


	scrollview:orderCCBFileCells(scrollview:getContentSize().width)
			

    if scrollview:getContentSize().height < scrollview:getViewSize().height then
		scrollview:setTouchEnabled(false)
	else
		scrollview:setTouchEnabled(true)
    end 
	

    if self.status==0 then 
    	 --标记为已读
    	RAMailManager:updateReadMailDatas(mailInfo.id,1) 

    	--刷新列表
    	MessageManager.sendMessage(refreshMailListMsg)
    	MessageManager.sendMessage(refreshMailOptListMsg)
    end 
  	RAMailManager:updateIsFirstMailDatas(mailInfo.id,false)
end
function RAMailLightingStormPage:registerMessageHandler()
    MessageManager.registerMessageHandler(readMailMsg,OnReceiveMessage)
end

function RAMailLightingStormPage:removeMessageHandler()
    MessageManager.removeMessageHandler(readMailMsg,OnReceiveMessage)
end


function RAMailLightingStormPage:Exit()
	if self.mHtmlLabel then
		self.mHtmlLabel:removeLuaClickListener()
		self.mHtmlLabel = nil
	end
	self.ListSV:removeAllCell()
	self:removeMessageHandler()
	UIExtend.unLoadCCBFile(RAMailLightingStormPage)
	
end

function RAMailLightingStormPage:onClose()
	RARootManager.CloseCurrPage()
end

function RAMailLightingStormPage:mCommonTitleCCB_onBack()
	self:onClose()
end

function RAMailLightingStormPage:mCommonTitleCCB_onCmnDeleteBtn()
	CCLuaLog("RAMailLightingStormPage:onDeleteBtn")

	RAMailManager:deleteMailInPage(self.id)
	if self.lock == 0 then
		self:onClose()
	end 
end

