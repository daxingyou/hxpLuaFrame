--region *.lua
--Date
--此文件由[BabeLua]插件自动生成

-- 研究科技界面

local RALogicUtil = RARequire("RALogicUtil")
local RAStringUtil = RARequire("RAStringUtil")
local UIExtend = RARequire("UIExtend")
local Utilitys = RARequire("Utilitys")
local RARootManager = RARequire("RARootManager")
local tech_conf = RARequire("tech_conf")
local tech_uipos_conf = RARequire("tech_uipos_conf")
local RAScienceUtility = RARequire("RAScienceUtility")
local RAGameConfig = RARequire("RAGameConfig")
local RA_Common = RARequire("common")
local RAPackageData = RARequire("RAPackageData")
local RACoreDataManager = RARequire("RACoreDataManager")
local RAScienceManager = RARequire("RAScienceManager")
local RAPlayerInfoManager = RARequire("RAPlayerInfoManager")
local const_conf = RARequire("const_conf")
local RAGameConfig=RARequire("RAGameConfig")
local RAQueueUtility=RARequire("RAQueueUtility")
local RAGuideManager=RARequire("RAGuideManager")

local clickTabMsg = MessageDef_Building.MSG_SCIENCE_TABCELL_CLICK
local updateMsg = MessageDef_Building.MSG_SCIENCE_UPDATE
local scienceQueueAddMsg = MessageDef_Queue.MSG_Science_ADD
local scienceQueueUpdateMsg = MessageDef_Queue.MSG_Science_UPDATE
local scienceQueueDeleteMsg = MessageDef_Queue.MSG_Science_DELETE
local scienceQueueCancleMsg = MessageDef_Queue.MSG_Science_CANCEL

local TAG = 1000
local mFrameTime = 0
local reserchingOffset=120  --研究和非研究状态的切换高度

local CELLW = const_conf['techUI_X'].value   --每个格子的宽度
local CELLH = const_conf['techUI_Y'].value

local VISIBALESIZE =CCDirector:sharedDirector():getVisibleSize()

------ani begin----------
local RAScienceTreeAni = {}

function RAScienceTreeAni:new()
    local o = {}
    setmetatable(o,self)
    self.__index = self
    return o
end

function RAScienceTreeAni:init()
    UIExtend.loadCCBFileWithOutPool("RACollegeParticleCellNew.ccbi",self)
end

function RAScienceTreeAni:release()
    UIExtend.unLoadCCBFile(self)
end
------ani end----------

local RAScienceTreePage = BaseFunctionPage:new(...)

local RAScienceTreePageTabCell = {

}
function RAScienceTreePageTabCell:new(o)
    o = o or {}
    setmetatable(o,self)
    self.__index = self    
    return o
end
function RAScienceTreePageTabCell:onRefreshContent(ccbRoot)
    
	CCLuaLog("RAScienceTreePageTabCell:onRefreshContent")
	if not ccbRoot then return end
	local ccbfile = ccbRoot:getCCBFileNode()

	--title
	UIExtend.setCCLabelString(ccbfile,"mTabTitle",self.title)

	--pic
end


local RAScienceTreePageCollegeCell = {

}
function RAScienceTreePageCollegeCell:new(o)
    o = o or {}
    setmetatable(o,self)
    self.__index = self    
    return o
end

function RAScienceTreePageCollegeCell:cutDownResearchTime()
	
	local remainTime = Utilitys.getCurDiffTime(RAScienceTreePage.endTime)
	local timeStr = Utilitys.createTimeWithFormat(remainTime)

	if self.ccbfile then
		UIExtend.setCCLabelString(self.ccbfile,"mCellTime",timeStr)
	end 
	

end

function RAScienceTreePageCollegeCell:onRefreshContent(ccbRoot)
    
	CCLuaLog("RAScienceTreePageCollegeCell:onRefreshContent")

	if not ccbRoot then return end
	local ccbfile = ccbRoot:getCCBFileNode()
	self.ccbfile = ccbfile
	local scienceInfo = self.scienceInfo

	local mCellName = UIExtend.getCCLabelTTFFromCCB(ccbfile,'mCellName')
	--title
	UIExtend.setCCLabelString(ccbfile,"mCellName",_RALang(scienceInfo.techName))

	local mCellName = UIExtend.getCCLabelTTFFromCCB(ccbfile,'mCellName')
	local width = mCellName:getContentSize().width + mCellName:getPositionY()
	UIExtend.getCCSpriteFromCCB(ccbfile,'mYesPic'):setPositionX(-(width / 6))

	--process
	local maxLevel=RAScienceUtility:getScienceMaxLevel(scienceInfo.id)
	local curLevel = scienceInfo.techLevel
	self.maxLevel = maxLevel
	self.curLevel = curLevel
	
	UIExtend.getCCLabelTTFFromCCB(ccbfile,'mCellLevel'):setVisible(true)
	UIExtend.getCCSpriteFromCCB(ccbfile,'mYesPic'):setVisible(false)

	local isExist = RAScienceManager:getScienceDataById(scienceInfo.id) 
	if curLevel==maxLevel and isExist then
		UIExtend.setCCLabelString(ccbfile,"mCellLevel",_RALang("@ScienceLevel",curLevel,maxLevel))
		UIExtend.getCCSpriteFromCCB(ccbfile,'mYesPic'):setVisible(true)
	else
		UIExtend.setCCLabelString(ccbfile,"mCellLevel",_RALang("@ScienceLevel",curLevel-1,maxLevel))

	end 

	-- --图标和文字设置
	-- --没有研究过就设置灰 否则不变灰文字变成绿色

    --local cellAniCCB = UIExtend.getCCBFileFromCCB(self.ccbfile,"mCellAniCCB")
	-- -- --正在研究的添加特效 用self.researchIngId判断
	if scienceInfo.id==RAScienceTreePage.reserchIngId then
		--UIExtend.setNodeVisible(ccbfile,"mSelectBGNode",true)
		-- UIExtend.setNodeVisible(ccbfile,"mRedBGNode",true)
		UIExtend.setNodeVisible(ccbfile,"mCellTimeNode",true)

        if cellAniCCB then
            cellAniCCB:setVisible(true)
        end

        ccbfile:runAnimation("Researching")
	else
		--UIExtend.setNodeVisible(ccbfile,"mSelectBGNode",false)
		-- UIExtend.setNodeVisible(ccbfile,"mRedBGNode",false)
		UIExtend.setNodeVisible(ccbfile,"mCellTimeNode",false)
        if cellAniCCB then
            cellAniCCB:setVisible(false)
        end
	end

	local isFinish = RAScienceManager:isResearchFinish(scienceInfo.id)

	--全升级完成的
	if isFinish then
		UIExtend.setNodeVisible(ccbfile,"mFinishBGNode",isFinish or true)
	else
		UIExtend.setNodeVisible(ccbfile,"mFinishBGNode",isFinish or false)		
	end

	UIExtend.setNodeVisible(ccbfile,"mRedBGNode",true)
	if maxLevel==1 and not isFinish then 
		UIExtend.setNodeVisible(ccbfile,"mRedBGNode",false)
		--UIExtend.setCCSpriteGray(pic,true)
	elseif maxLevel~=1 and curLevel==1 then
		UIExtend.setNodeVisible(ccbfile,"mRedBGNode",false)
		--UIExtend.setCCSpriteGray(pic,true)
	end

	--文字显示 未开启研究成灰色 正在研究红色 研究过成绿色

	if maxLevel==1 then
		if curLevel==1 and not isFinish then
			UIExtend.setLabelTTFColor(ccbfile,"mCellLevel",RAGameConfig.COLOR.GRAY)
		else
			UIExtend.setLabelTTFColor(ccbfile,"mCellLevel",RAGameConfig.COLOR.GREEN)
		end 
	elseif curLevel==1 then
		UIExtend.setLabelTTFColor(ccbfile,"mCellLevel",RAGameConfig.COLOR.GRAY)
	else
		UIExtend.setLabelTTFColor(ccbfile,"mCellLevel",RAGameConfig.COLOR.GREEN)
	end 

	if scienceInfo.id==RAScienceTreePage.reserchIngId then
		--UIExtend.setNodeVisible(ccbfile,"mRedBGNode",true)
		-- UIExtend.setLabelTTFColor(ccbfile,"mCellLevel",RAGameConfig.COLOR.RED)
	end 

	--满级的话 需要设置成黄色
	if curLevel==maxLevel and isExist then
		UIExtend.setLabelTTFColor(ccbfile,"mCellLevel",RAGameConfig.COLOR.YELLOW)
	end

	--icon 
	local mIconSpr = UIExtend.getCCSpriteFromCCB(ccbfile,"mIconSpr")
	local icon = scienceInfo.techPic
	local isUnLock = RAScienceManager:isUnLock(scienceInfo)
	if isUnLock then
		UIExtend.setNodeVisible(ccbfile,"mRedBGNode",true)
	else
		icon = scienceInfo.greyTechPic	
	end

	mIconSpr:setTexture(icon)
end


function RAScienceTreePageCollegeCell:onSkillBG()
	if RAGuideManager.partComplete.Guide_UIUPDATE and RAGuideManager.isInGuide() then
       RARootManager.AddCoverPage()
       RARootManager.RemoveGuidePage()
    end

	CCLuaLog("RAScienceTreePageCollegeCell:onSkillBG")
	local data={
		maxLevel = self.maxLevel,
		scienceInfo = self.scienceInfo,
		buildId = RAScienceTreePage.buildId
	}

	--先判断是否研究完成
	local scienceId = self.scienceInfo.id
	local isExist = RAScienceManager:getScienceDataById(scienceId) 
	if self.curLevel==self.maxLevel and isExist then
		CCLuaLog("reserch max success......")
		RARootManager.OpenPage("RAScienceResearchFinishPage",data,false,true,true)
	elseif RAScienceTreePage.reserchIngId~=self.scienceInfo.id then 
		RARootManager.OpenPage("RAScienceNoResearchPage",data,true,true,true) 
	end
	
end

function RAScienceTreePage:endRunAction()
    --run action
    self.ccbfile:runAnimation("WorkingComplete")
end


local OnReceiveMessage = function(message)
    if message.messageID == clickTabMsg then
      -- if RAScienceManager:isGetDinWei(message.scienceType) then
      -- 	 RAScienceManager:setDinWei(message.scienceType,false)
      -- end 
      RAScienceTreePage:updateInfo(message.scienceType)
    elseif  message.messageID == updateMsg then   --立即研究完成监听
    	 local scienceId = message.scienceId
    	 local scienceInfo = RAScienceUtility:getScienceDataById(scienceId)

    	 if RAScienceTreePage.unLockScienceId and tonumber(scienceId)==tonumber(RAScienceTreePage.unLockScienceId) then
    	 	local scienceFunc=RAScienceTreePage.scienceFunc
    	 	if scienceFunc and type(scienceFunc)=="function" then
    	 		scienceFunc()
    	 	end
    	 end
    	 RAScienceTreePage:updateInfo(scienceInfo.techUiType)
    elseif message.messageID == scienceQueueAddMsg or message.messageID == scienceQueueUpdateMsg or
    	   message.messageID == scienceQueueCancleMsg or message.messageID == scienceQueueDeleteMsg
    	 then

    	 local scienceId = message.itemId
    	 if scienceId then

    	 	local scienceInfo = RAScienceUtility:getScienceDataById(scienceId)
    	 	--添加队列研究成功的提示
    	 	if message.messageID == scienceQueueDeleteMsg then  --队列研究完成监听
                --完成后action
                --RAScienceTreePage:endRunAction()
    	 		RAScienceUtility:showResearchSuccessTip(scienceId)
    	 	end
           
            if RAScienceTreePage.unLockScienceId and tonumber(scienceId)==tonumber(RAScienceTreePage.unLockScienceId) then
	    	 	local scienceFunc=RAScienceTreePage.scienceFunc
	    	 	if scienceFunc and type(scienceFunc)=="function" then
	    	 		scienceFunc()
	    	 	end
    	 	end
         	RAScienceTreePage:updateInfo(scienceInfo.techUiType)
    	 end
   	elseif message.messageID == MessageDef_Guide.MSG_Guide then 
        local constGuideInfo = message.guideInfo
        local guideId = constGuideInfo.guideId
        local RAGuideConfig=RARequire("RAGuideConfig")
        if constGuideInfo and constGuideInfo.keyWord == RAGuideConfig.KeyWordArray.CircleResearchCell then
            if constGuideInfo.showGuidePage == 1 then
                local reasearhNode = UIExtend.getCCNodeFromCCB(RAScienceTreePage.guideCell.ccbfile, "mGuideNode")
                local pos = ccp(0, 0)
                pos.x, pos.y = reasearhNode:getPosition()
                local worldPos = reasearhNode:getParent():convertToWorldSpace(pos)
                local size = reasearhNode:getContentSize()
                size.width = size.width + RAGuideConfig.GuideTips.ConfigOffset*2
                size.height = size.height + RAGuideConfig.GuideTips.ConfigOffset*2
                RARootManager.AddGuidPage({["guideId"] = guideId, ["pos"] = worldPos, ["size"] = size})
            end 
        end  
    end
end

function RAScienceTreePage:Enter(data)


	CCLuaLog("RAScienceTreePage:Enter")
	local ccbfile = UIExtend.loadCCBFile("RACollegePageNew.ccbi",self)
	RAScienceManager:initDinWeiTab(3)
	self.ccbfile  = ccbfile

	self.isSetViewSize = false
	self.scienceTreeAnis = {}
	local RABuildManager = RARequire("RABuildManager")
	local buildData = RABuildManager:getBuildDataByType(Const_pb.FIGHTING_LABORATORY)
	local tb={}
	local scienceBuildData = nil
	for k,v in pairs(buildData) do
		scienceBuildData=v
	end

	self.dataConf = scienceBuildData.confData
	self.buildId =  scienceBuildData.id
	if data and data.scienceId then
		self.unLockScienceId = data.scienceId
		self.scienceFunc = data.scienceFunc
	end 
	
	self:init()

	if RAGuideManager.partComplete.Guide_UIUPDATE and RAGuideManager.isInGuide() then
        RARootManager.AddCoverPage()
        RAGuideManager.gotoNextStep()
    end

end

function RAScienceTreePage:init()

    --无升级时候动画
    --self.ccbfile:runAnimation("IdleAni")
	-- --初始化
	local titleCCB = UIExtend.getCCBFileFromCCB(self.ccbfile, "mCommonTitleCCB")
	local RACommonTitleHelper = RARequire('RACommonTitleHelper')
	local backCallBack = function()
		CCLuaLog("RAScienceTreePage  testCallBack")
		RARootManager.ClosePage("RAScienceTreePage")
	end

	-- local diamondCallBack = function()
	-- 	CCLuaLog("RAScienceTreePage  diamondCallBack")
	-- 	local RAPackageManager = RARequire("RAPackageManager")
	-- 	RAPackageManager:setIsPackageTab(false)
	-- 	RARootManager.OpenPage("RAPackageMainPage")
	-- end

	--local titleName =  _RALang(self.dataConf.buildName).._RALang("@LevelNum",self.dataConf.level)
	-- local titleHandler = RACommonTitleHelper:RegisterCommonTitle('RAScienceTreePage', titleCCB, titleName, backCallBack, RACommonTitleHelper.BgType.Blue)
	-- titleHandler:SetCallBack(RACommonTitleHelper.TitleCallBack.Diamonds)
	-- titleHandler:SetTitleBgType(RACommonTitleHelper.BgType.Blue,false)

	local titleName = _RALang("@TechInterFaceTitle")
	local titleHandler = RACommonTitleHelper:RegisterCommonTitle('RAScienceTreePage', 
    titleCCB, titleName, backCallBack, RACommonTitleHelper.BgType.Blue, false)

	
	self.mCollegeMilitarySV = UIExtend.getCCScrollViewFromCCB(self.ccbfile,"mCollegeMilitarySV")
	self.mOffset = self.mCollegeMilitarySV:getContentOffset()
	self.mContentSize = self.mCollegeMilitarySV:getContentSize()
	self.mViewSize = self.mCollegeMilitarySV:getViewSize()

	-- self.mCollegeMilitarySV = UIExtend.getCCScrollViewFromCCB(self.ccbfile,"mCollegeMilitarySV")
	self.mCollegeCityProgressSV = UIExtend.getCCScrollViewFromCCB(self.ccbfile,"mCollegeCityProgressSV")
	self.mCollegeCityDefenseSV = UIExtend.getCCScrollViewFromCCB(self.ccbfile,"mCollegeCityDefenseSV")

	self.mCollegeSVHeight =self.mCollegeMilitarySV:getViewSize().height
	self:registerMessageHandler()
	
	local pBar = UIExtend.getCCScale9SpriteFromCCB(self.ccbfile,"mBar")
	pBar:setScaleX(0)

	--如果是从兵营里跳转过来 每次都定位到相应的科技id
	local uiType=nil
	if not self.unLockScienceId then
		uiType = RAScienceManager:getClickUiType()	
	else
		local scienceData = RAScienceUtility:getScienceDataById(self.unLockScienceId)
		uiType = scienceData.techUiType
	end 

	RAScienceManager:setDinWei(uiType,true)

	UIExtend.setNodeVisible(self.ccbfile,"mUpgradeNode",false)

	self:updateInfo(uiType) 
	self:showClickTabBtn(uiType)

end

function RAScienceTreePage:registerMessageHandler()
    MessageManager.registerMessageHandler(clickTabMsg,OnReceiveMessage)
    MessageManager.registerMessageHandler(updateMsg,OnReceiveMessage)
    MessageManager.registerMessageHandler(scienceQueueAddMsg,OnReceiveMessage)
    MessageManager.registerMessageHandler(scienceQueueUpdateMsg,OnReceiveMessage)
    MessageManager.registerMessageHandler(scienceQueueDeleteMsg,OnReceiveMessage)
    MessageManager.registerMessageHandler(scienceQueueCancleMsg,OnReceiveMessage)

    if RAGuideManager.partComplete.Guide_UIUPDATE then
        MessageManager.registerMessageHandler(MessageDef_Guide.MSG_Guide,OnReceiveMessage)
    end
    
   
end

function RAScienceTreePage:removeMessageHandler()
    MessageManager.removeMessageHandler(clickTabMsg,OnReceiveMessage)
    MessageManager.removeMessageHandler(updateMsg,OnReceiveMessage)
    MessageManager.removeMessageHandler(scienceQueueAddMsg,OnReceiveMessage)
    MessageManager.removeMessageHandler(scienceQueueUpdateMsg,OnReceiveMessage)
    MessageManager.removeMessageHandler(scienceQueueDeleteMsg,OnReceiveMessage)
    MessageManager.removeMessageHandler(scienceQueueCancleMsg,OnReceiveMessage)

    if RAGuideManager.partComplete.Guide_UIUPDATE then
        MessageManager.removeMessageHandler(MessageDef_Guide.MSG_Guide,OnReceiveMessage)
    end
   
end

function RAScienceTreePage:showCutDownTime()
	local isResearch = false
	--判断队列里是否有
	local queue=RAScienceUtility:getScienceQueue()
	if next(queue) then

		--存储正在研究的科技id
		for k,v in pairs(queue) do
			local info =v
			self.reserchIngId = tonumber(info.itemId)
			self.endTime = info.endTime
			self.startTime = info.startTime
			self.queueData = v
		end
        --run action
        local mUpgradeNode=UIExtend.getCCNodeFromCCB(self.ccbfile,"mUpgradeNode")
        if not mUpgradeNode:isVisible() then
        	--self.ccbfile:runAnimation("WorkingAni")
        end 
        
        self.ccbfile:runAnimation("IdleAni")
		
		--显示时间
		UIExtend.setNodeVisible(self.ccbfile,"mUpgradeNode",true)
		self:showTopDetail()
		
		isResearch = true
	else
		--隐藏时间
		UIExtend.setNodeVisible(self.ccbfile,"mUpgradeNode",false)
		self.reserchIngId=nil
		self.endTime = nil
        self.startTime = nil
		self.reserchIngCell = nil

		self.ccbfile:runAnimation("NoResearchAni")
	end 
	
	return isResearch
end

function RAScienceTreePage:showClickTabBtn(btn)
	local mBtns = {}
    mBtns["mTab1Btn"] = false
    mBtns["mTab2Btn"] = false
    mBtns["mTab3Btn"] = false

	if btn==1 then
		mBtns["mTab1Btn"] = true
	elseif btn==2 then
		mBtns["mTab2Btn"] = true
	elseif btn==3 then
		mBtns["mTab3Btn"] = true
	end

	UIExtend.setControlButtonSelected(self.ccbfile, mBtns)
	self:showScrollView(btn)
	self.researchCellPosY=nil --优化切换刷数据
end
function RAScienceTreePage:onTab1Btn()
	local uiType= RAScienceManager:getClickUiType()
	if uiType ==1 then return end
	self:showClickTabBtn(1)
	RAScienceManager:setClickUiType(1)
	MessageManager.sendMessage(clickTabMsg,{scienceType = 1})
end
function RAScienceTreePage:onTab2Btn()
	local uiType= RAScienceManager:getClickUiType()
	if uiType ==2 then return end
	self:showClickTabBtn(2)
	RAScienceManager:setClickUiType(2)
	MessageManager.sendMessage(clickTabMsg,{scienceType = 2})
end
function RAScienceTreePage:onTab3Btn()
	local uiType= RAScienceManager:getClickUiType()
	if uiType ==3 then return end
	self:showClickTabBtn(3)
	RAScienceManager:setClickUiType(3)
	MessageManager.sendMessage(clickTabMsg,{scienceType = 3})
end



function RAScienceTreePage:createLine(startP,endP,count,h,picName,order,factor,index,isConnect)

	local tmpS = CCPoint(startP.x * CELLW ,(count-startP.y+0.5) * h+ self.cellOffset)
	local tmpE = CCPoint(endP.x * CELLW ,(count-endP.y+0.5) * h+ self.cellOffset)
	local dis = Utilitys.getDistance(startP,endP)
	local lineSprite = CCSprite:create(picName)
	self.mCollegeSV:addChild(lineSprite,order)
	lineSprite:setAnchorPoint(ccp(0,0.5))
	lineSprite:setPosition(tmpS)

	-- local lineDot = CCScale9Sprite:create(RAGameConfig.TechLine.lineDot)
	-- self.mCollegeSV:addChild(lineDot,order+1)
	-- lineDot:setAnchorPoint(ccp(0,0.5))
	-- lineDot:setPosition(tmpS)
		
	--连接点
	if isConnect then
		-- local lineDot = CCSprite:create(RAGameConfig.TechLine.lineDot)
		-- self.mCollegeSV:addChild(lineDot,order+1)
		-- lineDot:setAnchorPoint(ccp(0.5,0.5))
		-- lineDot:setPosition(tmpE)
	end 
	local lineSH = lineSprite:getContentSize().height
	local lineSW = lineSprite:getContentSize().width

	if startP.x==endP.x then
	    lineSprite:setRotation(90)
	   dis = dis*h+self.cellOffset*0.1
	else
        if startP.x<endP.x then
            lineSprite:setRotation(0)
            
        else
            lineSprite:setRotation(-180)
            lineSprite:setFlipY(true)
        end 
		lineSprite:setPositionY(lineSprite:getPositionY()-lineSH*factor)
		dis=dis*CELLW
	end 

	lineSprite:setScaleX(dis/lineSW)
end

function RAScienceTreePage:createCCScale9SpriteLine(startP,endP,count,h,picName,order,factor,index,isConnect)

	local tmpS = CCPoint(startP.x * CELLW ,(count-startP.y+0.5) * h+ self.cellOffset)
	local tmpE = CCPoint(endP.x * CELLW ,(count-endP.y+0.5) * h+ self.cellOffset)
	local dis = Utilitys.getDistance(startP,endP)
	local lineSprite = CCScale9Sprite:create(picName)
	self.mCollegeSV:addChild(lineSprite,order)
	lineSprite:setAnchorPoint(ccp(0,0.5))
	lineSprite:setPosition(tmpS)
		
	--连接点
	if isConnect then
		-- local lineDot = CCSprite:create(RAGameConfig.TechLine.lineDot)
		-- self.mCollegeSV:addChild(lineDot,order+1)
		-- lineDot:setAnchorPoint(ccp(0.5,0.5))
		-- lineDot:setPosition(tmpE)
	end 
	local lineSH = lineSprite:getContentSize().height
	local lineSW = lineSprite:getContentSize().width

	local posX = lineSprite:getPositionX()
	local posY = lineSprite:getPositionY()

	if startP.x==endP.x then
	    lineSprite:setRotation(90)
	    dis = dis*h+self.cellOffset*0.1 + 20

	    posY = posY + 30
	else
        if startP.x<endP.x then
            lineSprite:setRotation(0)
            posX = posX-20
        else
            lineSprite:setRotation(180)
            --lineSprite:setFlipY(true)
            posX = posX+20
        end 

		lineSprite:setPositionY(lineSprite:getPositionY()-lineSH*factor+10)
		dis = dis * CELLW + 40
	end 

	lineSprite:setPositionX(posX)
	lineSprite:setPositionY(posY)
	local size = lineSprite:getContentSize()
	lineSprite:setContentSize(dis , size.height)
end

function RAScienceTreePage:createLineAni(startP,endP,count,h,picName,order,factor,index,isConnect)

	local tmpS = CCPoint(startP.x * CELLW ,(count-startP.y+0.5) * h+ self.cellOffset)
	local tmpE = CCPoint(endP.x * CELLW ,(count-endP.y+0.5) * h+ self.cellOffset)
	local dis = Utilitys.getDistance(startP,endP)
	local diffDis = dis
	--local lineSprite = CCScale9Sprite:create(picName)

	local scienceTreeAni = RAScienceTreeAni:new()
	scienceTreeAni:init()
	local ccb = scienceTreeAni.ccbfile

	--生命时长*速度=长度
	local mParticleSystemQuad = tolua.cast(ccb:getVariable('mParticleSystemQuad'),"CCParticleSystemQuad")
	mParticleSystemQuad:setSpeed(60)
	self.mCollegeSV:addChild(ccb, order)
	--ccb:setAnchorPoint(ccp(0,0.5))
	ccb:setPosition(tmpS)
		
	--连接点
	if isConnect then
		-- local lineDot = CCSprite:create(RAGameConfig.TechLine.lineDot)
		-- self.mCollegeSV:addChild(lineDot,order+1)
		-- lineDot:setAnchorPoint(ccp(0.5,0.5))
		-- lineDot:setPosition(tmpE)
	end 
	local lineSH = ccb:getContentSize().height
	local lineSW = ccb:getContentSize().width

	local posX = ccb:getPositionX()
	local posY = ccb:getPositionY()

	if startP.x==endP.x then
	    ccb:setRotation(90)
	    dis = dis*h+self.cellOffset*0.1 + 20

	    if diffDis < 2 then --短线 速度设置为 40 
	    	mParticleSystemQuad:setSpeed(40)
	    	posY = posY - 10
	    end
	    posY = posY - 70
	else
        if startP.x<endP.x then
            ccb:setRotation(0)
            posX = posX+60
        else
            ccb:setRotation(180)
            --ccb:setFlipY(true)
            posX = posX-60
        end 

		ccb:setPositionY(ccb:getPositionY()-lineSH*factor+10)
		dis = dis * CELLW --+ 40
	end 

	ccb:setPositionX(posX)
	ccb:setPositionY(posY)
	local size = ccb:getContentSize()
	--mParticleSystemQuad:setSpeed(dis)
	ccb:setContentSize(dis , size.height)

	return ccb
end

function RAScienceTreePage:updateInfo(tmpType)

	self.curUiType = tmpType
	local isResearch = self:showCutDownTime()
	self:updateResearchSuccessNum(tmpType)

	self.mCollegeSV=self:getShowScrollView(tmpType)
 	self.mCollegeSV:removeAllCell()

 	local preOffset = self.mCollegeSV:getContentOffset()
	self.mCollegeSV:setContentOffset(self.mOffset)
	self.mCollegeSV:setContentSize(self.mContentSize)
	self.mCollegeSV:setViewSize(self.mViewSize)

	

	self.showScienceTab = RAScienceManager:Enter(tmpType)
	local tb = Utilitys.table_pairsByKeysAll(self.showScienceTab,true)

	--得到玩家已完成的最大科技id
	local researchFinishMaxId=RAScienceManager:getMaxScienceIdByUitype()
	if self.unLockScienceId then
		researchFinishMaxId = self.unLockScienceId
	end
	
	local isReachMaxLevel = RAScienceUtility:isReachMaxLevel(researchFinishMaxId)
	local reserchFinishMaxCellPosY=nil
	local researchCellPosY=nil

    local scrollview = self.mCollegeSV
	local cellHeight =0
    local maxHeight = 0
    local cellCount = #tb

 --    --先算出最大的一个位置
    local maxY = 0
    for k,v in ipairs(tb) do
    	local info =v
        if info.uiPos then
            local uiPos = RAStringUtil:split(info.uiPos,",")
    	    if maxY<tonumber(uiPos[2]) then
        	    maxY=tonumber(uiPos[2])
            end
        end 
    	
    end

    self.cellOffset=0
    for i,v in ipairs(tb) do
    	local info =v
    	local cell = CCBFileCell:create()
		local panel = RAScienceTreePageCollegeCell:new({
				scienceInfo =info,
        })

		cell:registerFunctionHandler(panel)
		cell:setCCBFile("RACollegeCellNew.ccbi")
		scrollview:addCell(cell)

		local CellSize = cell:getContentSize()
		cellHeight = CellSize.height
		self.cellHeight=cellHeight
		local cellY
		
		if info.uiPos then
			local uiPos = RAStringUtil:split(info.uiPos,",")
			
	        if CELLH<cellHeight then
	        	 self.cellOffset=cellHeight-CELLH
	        end 

	        cellY = (maxY-uiPos[2])*CELLH
	    	local techPos = ccp(uiPos[1]*CELLW, cellY)
	        cell:setPosition(techPos)
		end 
		-- cell:setVisible(false)

        --把正在研究的科技cell存储下
		if info.id == self.reserchIngId then
			self.reserchIngCell = panel
			researchCellPosY = cellY
		end 

		if info.id-1 == researchFinishMaxId or  info.id== researchFinishMaxId then
			reserchFinishMaxCellPosY=cellY
		end 

		if RAGuideManager.partComplete.Guide_UIUPDATE and RAGuideManager.isInGuide() then
			if info.id==self.unLockScienceId then
				self.guideCell=panel
			end 
	    end



    end
    maxHeight = maxY*CELLH+ self.cellOffset

    -- fromPos = "3,1",
    --  toPos = "3,3"
   	-- local lineDatas = RAScienceUtility:getLineDatasByType(tmpType)
   	local lineDatas=RAScienceUtility:createLineTab(tmpType)
   	local linePointTab={}
   	for k,v in pairs(lineDatas) do
   		local lineInfo = v
   		local fromPos = RAStringUtil:split(lineInfo.fromPos,",")
   		local toPos = RAStringUtil:split(lineInfo.toPos,",")
   		local startX,startY= tonumber(fromPos[1]),tonumber(fromPos[2])
   		local endX,endY= tonumber(toPos[1]),tonumber(toPos[2])
   		local startP={x=startX,y=startY}
   		local endP={x=endX,y=endY}
   		table.insert(linePointTab,{startP,endP,lineInfo.techId,lineInfo.isConnect})

   	end

  
  	-- 考虑到渲染批次 分开画
  	--  --画线
   	for i,v in ipairs(linePointTab) do
   	   local startP = v[1]
   	   local endP = v[2]
   	   local techId = v[3]
   	   local isShow=RAScienceManager:isShowLineBy(techId)
   	   if isShow then
   	   		self:createLine(startP,endP,maxY,CELLH,RAGameConfig.TechLine.line,-100,0.5,i)

   	   		--画线背景CCScale9Sprite
   	   		self:createCCScale9SpriteLine(startP,endP,maxY,CELLH,RAGameConfig.TechLine.lineDot,-102,0.25,i,isConnect,true)
   	   	
	   	   	--动画粒子
			--local ccbAni = self:createLineAni(startP,endP,maxY,CELLH,RAGameConfig.TechLine.lineDot,-100,0.25,i,isConnect,true)
	   		--self.scienceTreeAnis[#self.scienceTreeAnis + 1] = ccbAni
   	   end
   	end

   	--画线背景Sprite
   	for i,v in ipairs(linePointTab) do
   	   local startP = v[1]
   	   local endP = v[2]
   	   local isConnect = v[4]
   	   self:createLine(startP,endP,maxY,CELLH,RAGameConfig.TechLine.lineBg,-101,0.25,i,isConnect)
   	end

   	local viewSize = scrollview:getViewSize()
   	if isResearch then --正在升级的情况
   		local mSmallSizeNode = UIExtend.getCCNodeFromCCB(self.ccbfile, 'mSmallSizeNode')
   		local height = mSmallSizeNode:getContentSize().height
		scrollview:setViewSize(CCSize(viewSize.width, height))
	else
		local mBigSizeNode = UIExtend.getCCNodeFromCCB(self.ccbfile, 'mBigSizeNode')
   		local height = mBigSizeNode:getContentSize().height
		scrollview:setViewSize(CCSize(viewSize.width, viewSize.height+reserchingOffset))
	end

	scrollview:setContentSize(CCSize(scrollview:getViewSize().width,maxHeight))	
   	--scrollview:setContentSize(CCSize(scrollview:getViewSize().width,maxHeight))

   	
    --如果有cell在研究就定位到研究的cell
    if self.reserchIngCell and researchCellPosY then
 		
 		local isTop =RAScienceManager:isTopScienceInUiType(self.reserchIngId) 
 		if isTop then
 			scrollview:setContentOffset(ccp(0,self.mCollegeSVHeight - maxHeight))
 		else
 			scrollview:setContentOffset(ccp(0,self.mCollegeSVHeight*0.5 - researchCellPosY-CELLH-self.cellOffset+self.cellHeight*0.5))	
 		end 
    	
    	
    elseif reserchFinishMaxCellPosY then

    	if not RAScienceManager:isGetDinWei(tmpType) then
    		self.mCollegeSV:setContentOffset(ccp(0,preOffset.y))
    		-- 最终调整sv的偏移量
		    -- if not isResearch then
		    -- 	self.mCollegeSV:setContentOffset(ccp(0,preOffset.y+reserchingOffset))
		    -- end
    		return 
    	end
    		
    	--判断下是底部还是顶部
   		local isTop =RAScienceManager:isTopScienceInUiType(researchFinishMaxId)
   		local isBottom =RAScienceManager:isBottomScienceInUiType(researchFinishMaxId)

   		if isTop then
   			if isReachMaxLevel then
   				scrollview:setContentOffset(ccp(0,self.mCollegeSVHeight - maxHeight+self.cellHeight))
   			else
   				scrollview:setContentOffset(ccp(0,self.mCollegeSVHeight - maxHeight))
   			end
   			-- scrollview:setContentOffset(ccp(0,self.mCollegeSVHeight - maxHeight+self.cellHeight))
   		elseif isBottom then
   			scrollview:setContentOffset(ccp(0,-reserchFinishMaxCellPosY))

   		else
   			-- if isReachMaxLevel then
   			-- 	scrollview:setContentOffset(ccp(0,-reserchFinishMaxCellPosY+self.mCollegeSVHeight))
   			-- else
   				scrollview:setContentOffset(ccp(0,-reserchFinishMaxCellPosY+self.mCollegeSVHeight-self.cellHeight-CELLH*0.5))
   			-- end
   			
   		end
 
    else
    	if not RAScienceManager:isGetDinWei(tmpType) then
    		self.mCollegeSV:setContentOffset(preOffset)
    		return 
    	end
    	scrollview:setContentOffset(ccp(0,self.mCollegeSVHeight - maxHeight))
    	-- RAScienceManager:setDinWei(tmpType,false)
    end 

    RAScienceManager:setDinWei(tmpType,false)

    -- 最终调整sv的偏移量
    if not isResearch then
    	scrollview:setContentOffset(ccp(0,scrollview:getContentOffset().y))
    end
	
end


function RAScienceTreePage:showScrollView(tmpType)
    self.mCollegeMilitarySV:setVisible(false)
	self.mCollegeCityProgressSV:setVisible(false)
	self.mCollegeCityDefenseSV:setVisible(false)
	if tmpType==1 then
		self.mCollegeMilitarySV:setVisible(true)
	elseif tmpType==2 then
		self.mCollegeCityProgressSV:setVisible(true)
	else
		self.mCollegeCityDefenseSV:setVisible(true)
	end 

	--设置新手期间ScrollView不能拖动
	if RAGuideManager.isInGuide() then
		self.mCollegeMilitarySV:setTouchEnabled(false)
		self.mCollegeCityProgressSV:setTouchEnabled(false)
		self.mCollegeCityDefenseSV:setTouchEnabled(false)
	else
		self.mCollegeMilitarySV:setTouchEnabled(true)	
		self.mCollegeCityProgressSV:setTouchEnabled(true)
		self.mCollegeCityDefenseSV:setTouchEnabled(true)
	end
end

function RAScienceTreePage:getShowScrollView(tmpType)
	if tmpType==1 then
		return self.mCollegeMilitarySV
	elseif tmpType==2 then
		return self.mCollegeCityProgressSV
	else
		return self.mCollegeCityDefenseSV
	end 
end

function RAScienceTreePage:clearAllScrollViewCell()
	self.mCollegeMilitarySV:removeAllCell()
	self.mCollegeCityProgressSV:removeAllCell()
	self.mCollegeCityDefenseSV:removeAllCell()
end
--跳转到正在研究界面
function RAScienceTreePage:onCheckInfoBtn()
	local data={
		maxLevel = RAScienceUtility:getScienceMaxLevel(self.reserchIngId),
		scienceInfo = RAScienceUtility:getScienceDataById(self.reserchIngId),
		endTime = RAScienceTreePage.endTime,
		starRemainTime=RAScienceTreePage.starRemainTime
	}

	RARootManager.OpenPage("RAScienceResearchPage",data,true,true)
end

function RAScienceTreePage:updateResearchSuccessNum(tmpType)
	
	local count = RAScienceManager:getResearchSuccesNum(tmpType)
	UIExtend.setCCLabelString(self.ccbfile,"mHasBeenDevelop",_RALang("@ResearchSuccess",count))
	UIExtend.setLabelTTFColor(self.ccbfile,"mHasBeenDevelop",RAGameConfig.COLOR.GREEN)

end
function RAScienceTreePage:updateUpBar()

	-- -- body
	local remainTime = Utilitys.getCurDiffTime(self.endTime)
	local timeStr = Utilitys.createTimeWithFormat(remainTime)
	UIExtend.setCCLabelString(self.ccbfile,"mTrainingTime",timeStr)


	local scaleX = RAQueueUtility.getTimeBarScale(self.queueData)

	local scienceInfo = RAScienceUtility:getScienceDataById(self.reserchIngId)
	local maxLevel=RAScienceUtility:getScienceMaxLevel(scienceInfo.id)

	--bar mBar
	local pBar = UIExtend.getCCScale9SpriteFromCCB(self.ccbfile,"mBar") 
	pBar:setScaleX(scaleX)
	if scaleX<=0 or scaleX>=1 then
		pBar:setVisible(false)
		pBar:setScaleX(0)
	else
		pBar:setVisible(true)
	end

	--diamonds 
	local timeCostDimand = RALogicUtil:time2Gold(remainTime)
	self.timeCostDimand = timeCostDimand
	UIExtend.setCCLabelString(self.ccbfile,"mDiamondsNum",timeCostDimand)

end

function RAScienceTreePage:showTopDetail()

	local scienceInfo = RAScienceUtility:getScienceDataById(self.reserchIngId)
	local maxLevel=RAScienceUtility:getScienceMaxLevel(scienceInfo.id)

	-- --初始化
	-- self.scienceInfo
	local titleName = _RALang(scienceInfo.techName )
	UIExtend.setCCLabelString(self.ccbfile,"mUpgradeName",titleName)
	-- UIExtend.setCCLabelString(self.ccbfile,"mOriginalTime",Utilitys.createTimeWithFormat(self.data.buildTime))

	--icon
	local picNode = UIExtend.getCCNodeFromCCB(self.ccbfile,"mUpgradeIconNode")
	UIExtend.addNodeToAdaptParentNode(picNode,scienceInfo.techPic,TAG)

	--process
	local curLevel = scienceInfo.techLevel-1
	local nextLevel = scienceInfo.techLevel
	UIExtend.setCCLabelString(self.ccbfile,"BeforeLevel",curLevel)
	UIExtend.setCCLabelString(self.ccbfile,"AfterLevel",nextLevel)


	--process
	local curLevel = scienceInfo.techLevel
	local levelStr = _RALang("@ScienceLevel",curLevel-1,maxLevel)
	UIExtend.setCCLabelString(self.ccbfile,"mUpgradeLevel",levelStr)
	
	local des = _RALang(scienceInfo.techDes)
	UIExtend.setCCLabelString(self.ccbfile,"mUpgradeExplain",des)
	if scienceInfo.techEffectID then
		local keyStr = scienceInfo.techTip 
		--根据作用号获取当前等级和下一等级的效果
		local pretEffectValue = RAScienceUtility:getEffectValueById(scienceInfo.id-1)
		local cueEffectValue  = RAScienceUtility:getEffectValueById(scienceInfo.id)
		local nextEffectValue  = RAScienceUtility:getEffectValueById(scienceInfo.id+1)
		
		if pretEffectValue==0 then -- 最低级
			UIExtend.setNodeVisible(self.ccbfile,"mNextLevel",true)	
			pretEffectValue=_RALang(keyStr,pretEffectValue)
		elseif nextEffectValue==0 then --最高级
			UIExtend.setNodeVisible(self.ccbfile,"mNextLevel",false)
			pretEffectValue =_RALang(keyStr,cueEffectValue)
		else
			UIExtend.setNodeVisible(self.ccbfile,"mNextLevel",true)
			pretEffectValue=_RALang(keyStr,pretEffectValue) 
		end
		
		UIExtend.setCCLabelString(self.ccbfile,"mCurrentLevel",_RALang("@CurLevel")..pretEffectValue)
		UIExtend.setCCLabelString(self.ccbfile,"mNextLevel",_RALang("@NextLevel").._RALang(keyStr,cueEffectValue))

	else
		UIExtend.setNodeVisible(self.ccbfile,"mCurrentLevel",false)
		UIExtend.setNodeVisible(self.ccbfile,"mNextLevel",false)
	end 

	--cutdownTime
	if self.reserchIngId then
	 	self:updateUpBar()
    end 
end
--刷新时间显示
function RAScienceTreePage:Execute()

	mFrameTime = mFrameTime + RA_Common:getFrameTime()
    if mFrameTime > 1 then

	    if self.reserchIngCell then
			--科技树中cell时间刷新
			self.reserchIngCell:cutDownResearchTime()
		end 
	 	 --页面顶部刷新
	 	if self.reserchIngId then
	 		self:updateUpBar()
	 	end 
		
        mFrameTime = 0 
    end

	

end

function RAScienceTreePage:Exit()

	for i,v in ipairs(self.scienceTreeAnis) do
		v:release()
	end

	local RACommonTitleHelper = RARequire('RACommonTitleHelper')
	RACommonTitleHelper:RemoveCommonTitle("RAScienceTreePage")
	self:clearAllScrollViewCell()
	self.reserchIngCell=nil
	self.guideCell=nil
	self.unLockScienceId = nil
	UIExtend.setNodeVisible(self.ccbfile,"mUpgradeNode",false)
	RAScienceManager:Exit()
	UIExtend.unLoadCCBFile(RAScienceTreePage)
	self:removeMessageHandler()
	
end

function RAScienceTreePage:onCancelBtn( )

	local confirmData = {}
	confirmData.yesNoBtn = true
	confirmData.labelText = _RALang("@ResearchCancelTip")
	confirmData.resultFun = function (isOk)
		if isOk then
			local queue = RAScienceUtility:getScienceQueue()
			for k,v in pairs(queue) do
				local id = v.id
				RAScienceManager:sendQueueCancel(id)
			end
		end 
		
	end
	RARootManager.OpenPage("RAConfirmPage", confirmData,false,true,true)

end

function onResearchQueueNowCallBack(isOk)
	 if isOk then
		local queue = RAScienceUtility:getScienceQueue()
		if not next(queue) then return end 
		for k,v in pairs(queue) do
			local id = v.id
			RAScienceManager:sendQueueSpeedUpByGold(id)
			
		end
	end 
end
--消耗钻石
function RAScienceTreePage:onResearchNowBtn( )
	
	CCLuaLog("RAScienceTreePage:onResearchNowBtn")

	local RAConfirmManager = RARequire("RAConfirmManager")
    local confirmData = {}
    confirmData.type=RAConfirmManager.TYPE.RESEARCHNOW
    confirmData.costDiamonds = self.timeCostDimand
    confirmData.resultFun =onResearchQueueNowCallBack
    RARootManager:showDiamondsConfrimDlg(confirmData)

end

--消耗道具
function RAScienceTreePage:onAccelerationBtn( )
	CCLuaLog("RAScienceTreePage:onAccelerationBtn")
	local queue = RAScienceUtility:getScienceQueue()
	if not next(queue) then return end 
	for k,v in pairs(queue) do
		--RARootManager.OpenPage("RACommonItemsSpeedUpPopUp", v)	
		RARootManager.showCommonItemsSpeedUpPopUp(v)
	end 
end
--endregion
