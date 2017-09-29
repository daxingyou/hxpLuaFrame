--region *.lua
--Date
--此文件由[BabeLua]插件自动生成

--监狱查看界面

local RALogicUtil = RARequire("RALogicUtil")
local RAStringUtil = RARequire("RAStringUtil")
local Const_pb =RARequire('Const_pb')
local UIExtend = RARequire("UIExtend")
local Utilitys = RARequire("Utilitys")
local RAGameConfig=RARequire("RAGameConfig")
local RARootManager = RARequire("RARootManager")
local RAPrisonDataManage=RARequire("RAPrisonDataManage")
local RAPlayerInfoManager=RARequire("RAPlayerInfoManager")
local RANetUtil=RARequire("RANetUtil")
local RAPrisonUtility=RARequire("RAPrisonUtility")
local RA_Common=RARequire("common")
local Commander_pb=RARequire("Commander_pb")
local HP_pb=RARequire("HP_pb")

local RAPrisonPage = BaseFunctionPage:new(...)
local mFrameTime=0




-----------------------------------------------------------------------
function RAPrisonPage:Enter(data)


	CCLuaLog("RAPrisonPage:Enter")
	local ccbfile = UIExtend.loadCCBFile("RAPrisonPage.ccbi",self)
	self.ccbfile  = ccbfile
	self.netHandlers = {}
	self:addHandler()
	self:init()

end

function RAPrisonPage:onReceivePacket(handler)
    local pbCode = handler:getOpcode()
    local buffer = handler:getBuffer()
    if pbCode == HP_pb.CAPTIVE_GET_S then              		--查看
    	local msg = Commander_pb.HPGetCaptiveListResp()
        msg:ParseFromString(buffer)
        RAPrisonDataManage:deleteAllCaptureData()
        local infoList=msg.cmdInfoList
        for i=1,#infoList do
        	local info=infoList[i]
        	local id=info.enemyId
        	RAPrisonDataManage:addCaptureData(id,info)
        end

        RAPrisonPage:updateInfo()
    elseif pbCode == HP_pb.CAPTIVE_RELEASE_S then       	--立即释放
    	local msg = Commander_pb.HPCaptiveReleaseResp()
        msg:ParseFromString(buffer)
        local id=msg.playerId
        RAPrisonDataManage:deleteCaptureData(id)
   		RAPrisonPage:updateInfo()
   	elseif  pbCode == HP_pb.CAPTIVE_EXECUTE_S then     		--处决
   		local msg = Commander_pb.HPCaptiveExecuteResp()
        msg:ParseFromString(buffer)

		local id=msg.playerId
		local endTime=msg.endTime
		local state=msg.state

		--更新状态
		RAPrisonDataManage:updateCaptureState(id,state)
		--更新时间
		RAPrisonDataManage:updateCaptureEndTime(id,endTime)

		RAPrisonPage:updateInfo()
	elseif  pbCode == HP_pb.CAPTIVE_PUNISH_S then  			--用刑
		local msg = Commander_pb.HPCaptivePunishResp()
        msg:ParseFromString(buffer)

        local id=msg.playerId
        local punishTime=msg.punishTime
        RAPrisonDataManage:updateCapturePunishTime(id,punishTime)
    end
end


--当前界面不刷新
function RAPrisonPage:init()

	--title
	local titleCCB = UIExtend.getCCBFileFromCCB(self.ccbfile,"mCommonTitleCCB")
	titleCCB:runAnimation("InAni")
	UIExtend.setCCLabelString(titleCCB,"mTitle",_RALang("@Prison"))

	local playeInfo=RAPlayerInfoManager.getPlayerInfo()
	local diamondsNum=playeInfo.raPlayerBasicInfo.gold

	UIExtend.setCCLabelString(titleCCB,"mDiamondsNum",diamondsNum)

	UIExtend.setCCLabelString(self.ccbfile,"mPrisonNameTitle",_RALang("@PrisonerName"))
	UIExtend.setCCLabelString(self.ccbfile,"mPrisonLevelTitle",_RALang("@PrisonerLevel"))
	UIExtend.setCCLabelString(self.ccbfile,"mReleaseTimeTitle",_RALang("@PrisonerReleaseTime"))

	UIExtend.setNodeVisible(self.ccbfile,"mPrisonBustPic",false)
	UIExtend.setNodeVisible(self.ccbfile,"mTortureAniCCB",false)

	--发协议请求数据
	self:sendCheckReq()
	--self:updateInfo()

end


function RAPrisonPage:sendCheckReq( )
	 RAPrisonDataManage:sendCheckCaptureReq()
end

function RAPrisonPage:addHandler()

    self.netHandlers[#self.netHandlers + 1] = RANetUtil:addListener(HP_pb.CAPTIVE_GET_S, RAPrisonPage)      --查看返回
    self.netHandlers[#self.netHandlers + 1] = RANetUtil:addListener(HP_pb.CAPTIVE_RELEASE_S, RAPrisonPage)  --立即释放
    self.netHandlers[#self.netHandlers + 1] = RANetUtil:addListener(HP_pb.CAPTIVE_EXECUTE_S, RAPrisonPage)  --处决
    self.netHandlers[#self.netHandlers + 1] = RANetUtil:addListener(HP_pb.CAPTIVE_PUNISH_S, RAPrisonPage)   -- 用刑

end


function RAPrisonPage:removeHandler()
    for k, value in pairs(self.netHandlers) do
        RANetUtil:removeListener(value)
    end
end

function RAPrisonPage:setPrisonState(isHavaCapture)
	UIExtend.setNodeVisible(self.ccbfile,"mPrisonBustPic",isHavaCapture)
	UIExtend.setNodeVisible(self.ccbfile,"mHavePrisonersNode",isHavaCapture)
	UIExtend.setNodeVisible(self.ccbfile,"mNoPrisonersNode",not isHavaCapture)
end
function RAPrisonPage:updateInfo()

 	local isHavaCapture=RAPrisonDataManage:getIsHaveCapture()
	self.isHavaCapture=isHavaCapture

	--获得俘虏数据  --暂时只有一个
	local captureDatas=RAPrisonDataManage:getAllCaptureData()

	if next(captureDatas) then
		self:setPrisonState(true)
		for k,v in pairs(captureDatas) do
			local captureData=v
			
			local enemyId=captureData.enemyId
			self.enemyId=enemyId
			local icon=captureData.icon
			local name=captureData.name
			self.enemyName=name
			local level=captureData.level
			local endTime=captureData.endTime
			self.captureEndTime=endTime
			
			--头像
			local iconName=RAPrisonUtility:getPlayerBust(icon)
			UIExtend.setSpriteImage(self.ccbfile,{mPrisonBustPic=iconName})

			--时间
			local remainTime = Utilitys.getCurDiffTime(endTime)
        	local timeStr = Utilitys.createTimeWithFormat(remainTime)

			UIExtend.setCCLabelString(self.ccbfile,"mPrisonName",name)
			UIExtend.setCCLabelString(self.ccbfile,"mPrisonLevel",_RALang("@ResCollectTargetLevel",level))
			UIExtend.setCCLabelString(self.ccbfile,"mPrisonTime",timeStr)


			--更新按钮的状态
			local isCanRelease=self:isCanRelease(enemyId)
			local isCanCapturePunish=self:isCanCaptivePunish(enemyId)
			local isCanExcute=self:isCanExcute(enemyId)

			UIExtend.setCCControlButtonEnable(self.ccbfile,"mImmediateReleaseBtn",isCanRelease)
			UIExtend.setCCControlButtonEnable(self.ccbfile,"mTortureBtn",isCanCapturePunish)
			UIExtend.setCCControlButtonEnable(self.ccbfile,"mExecuteBtn",isCanExcute)

			if not isCanExcute then
				UIExtend.setCCLabelString(self.ccbfile,"mReleaseTimeTitle",_RALang("@ExecutedTime"))
			else
				UIExtend.setCCLabelString(self.ccbfile,"mReleaseTimeTitle",_RALang("@PrisonerReleaseTime"))
			end 



		end
	else
		self:setPrisonState(false)
		UIExtend.setCCLabelString(self.ccbfile,"mPopUpLabel1",_RALang("@NoCaptures"))
		UIExtend.setCCLabelString(self.ccbfile,"mPopUpLabel2",_RALang("@NoCapturesTips"))
	end



 
end

--判断是否可以立即释放
function RAPrisonPage:isCanRelease(id)
	local  state=RAPrisonDataManage:getCaptureState(id)
	if state<=1 then
		return true
	end 
	return false
end

--判断是否可以处决 
function RAPrisonPage:isCanExcute(id)
	local  state=RAPrisonDataManage:getCaptureState(id)
	if state>=3 then
		return false
	end
	return true
end
--判断是否可以用刑
function RAPrisonPage:isCanCaptivePunish(id)

	local  state=RAPrisonDataManage:getCaptureState(id)

	if state>=2 then
		return false
	end 

	local punishTime=RAPrisonDataManage:getCapturePunishTime(id)
	if punishTime and punishTime>0 then
		local curTime = RA_Common:getCurTime()
		if punishTime>curTime then
			return false
		end 
	end


	return true 
	
end
--刷新时间显示
function RAPrisonPage:Execute()
	if not self.isHavaCapture then
		return 
	end 

	local isCanCapturePunish=self:isCanCaptivePunish(self.enemyId)
	UIExtend.setCCControlButtonEnable(self.ccbfile,"mTortureBtn",isCanCapturePunish)

	local isCanExcute=self:isCanExcute(self.enemyId)
	UIExtend.setCCControlButtonEnable(self.ccbfile,"mExecuteBtn",isCanExcute)

    mFrameTime = mFrameTime + RA_Common:getFrameTime()
    if mFrameTime > 1 and self.captureEndTime then
       
        local endTime=self.captureEndTime
        local remainTime = Utilitys.getCurDiffTime(endTime)
        if remainTime>=0 then
        	local timeStr = Utilitys.createTimeWithFormat(remainTime)
			UIExtend.setCCLabelString(self.ccbfile,"mPrisonTime",timeStr)
			if remainTime==0 then
				RARootManager.CloseCurrPage()
			end
			
        end 
       
		local punishTime=RAPrisonDataManage:getCapturePunishTime(self.enemyId)
		local remainPushTime = Utilitys.getCurDiffTime(punishTime)
		if remainPushTime>=0 then
			local timeStr = Utilitys.createTimeWithFormat(remainPushTime)
			UIExtend.setControlButtonTitle(self.ccbfile, "mTortureBtn", timeStr, true,RAGameConfig.COLOR.RED)

		else
			UIExtend.setControlButtonTitle(self.ccbfile, "mTortureBtn", _RALang("@Torture"), true,RAGameConfig.COLOR.WHITE)
		end 
		 

        mFrameTime = 0 
    end
end

--发邮件调戏
function RAPrisonPage:onSendInsultBtn()
	local name=self.enemyName
	RARootManager.OpenPage("RAMailWritePage",{sendName=name})
end

--立即释放
function RAPrisonPage:onImmediateReleaseBtn()
	local captureData=RAPrisonDataManage:getCaptureData(self.enemyId)
	if captureData then
		local playeId=captureData.enemyId
		RAPrisonDataManage:sendCaptureReleaseReq(playeId)
	end 

end

--用刑
function RAPrisonPage:onTortureBtn()

	local captureData=RAPrisonDataManage:getCaptureData(self.enemyId)
	if captureData then
		--播一个动画
		UIExtend.setNodeVisible(self.ccbfile,"mTortureAniCCB",true)

		local array1 = CCArray:create()
		local delay = CCDelayTime:create(0.8)
		local funcAction = CCCallFunc:create(function ()
			 --播放音效
			local common=RARequire("common")
        	common:playEffect("torture")
			UIExtend.getCCBFileFromCCB(self.ccbfile,"mTortureAniCCB"):runAnimation("Lightning")
		end)
		array1:addObject(funcAction)
    	array1:addObject(delay)
    	local seq1 = CCSequence:create(array1)

		local rep=CCRepeat:create(seq1,3)
		self.ccbfile:runAction(rep)
		
		
		local playeId=captureData.enemyId
		RAPrisonDataManage:sendCapturePunishReq(playeId)
	end 
	
end

--处决
function RAPrisonPage:onExecuteBtn()

	--弹框提示
	local confirmData = {}
    confirmData.labelText = _RALang("@CommanderExecuteTips")
    confirmData.yesNoBtn=true
    confirmData.resultFun=function (isOk)
    	if isOk then
    		local captureData=RAPrisonDataManage:getCaptureData(self.enemyId)
			if captureData then
				local playeId=captureData.enemyId
				RAPrisonDataManage:sendCaptureExecuteReq(playeId)
			end
    	end 
    end
    RARootManager.OpenPage("RAConfirmPage", confirmData,false,true,true)
	
end

function RAPrisonPage:Exit()

	self:removeHandler()
	self.netHandlers=nil
	self.isHavaCapture=nil
	self.ccbfile:stopAllActions()
	RAPrisonDataManage:deleteAllCaptureData()
	UIExtend.unLoadCCBFile(RAPrisonPage)
	
end
function RAPrisonPage:mCommonTitleCCB_onDiamondsCCB()
    local RARealPayManager = RARequire('RARealPayManager')
    RARealPayManager:getRechargeInfo()
end

function RAPrisonPage:mCommonTitleCCB_onBack()
	RARootManager.CloseCurrPage()
end


--endregion
