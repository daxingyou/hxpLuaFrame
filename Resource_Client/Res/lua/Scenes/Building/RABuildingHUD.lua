RARequire("BasePage")
RARequire('RABuildingType')
local UIExtend = RARequire('UIExtend')
local RAStringUtil = RARequire('RAStringUtil')
local Const_pb = RARequire('Const_pb')
local RACitySceneManager = RARequire("RACitySceneManager")

local RALogicUtil = RARequire("RALogicUtil")
local Utilitys = RARequire("Utilitys")
local RACityScene = RARequire('RACityScene')
local RACitySceneConfig = RARequire("RACitySceneConfig")


local RAHUDBtnHandler = {}
--构造函数
function RAHUDBtnHandler:new(type)
    local o = {}
    o.btnType = type
    o.handler = nil 
    o.icon = nil 
    setmetatable(o,self)
    self.__index = self
    return o
end

function RAHUDBtnHandler:init()
    
    self.ccbfile = UIExtend.loadCCBFile("RAHUDCityCell.ccbi",self)

    self.icon = self.ccbfile:getCCSpriteFromCCB('mHUDIcon')
    self.icon:setTexture(Btn_Image_Table[self.btnType])
    UIExtend.setCCLabelString(self.ccbfile,"mBtnName",_RALang(Btn_Txt_Map[self.btnType]))

    if self.btnType ~= BUILDING_BTN_TYPE.GOLDSPEEDUP then 
        self.ccbfile:getCCNodeFromCCB('mDiamondsNode'):setVisible(false)
    else 
        self.ccbfile:getCCNodeFromCCB('mDiamondsNode'):setVisible(true)
    end 
end

--为了设置金币
function RAHUDBtnHandler:setString(str)

    if self.btnType ~= BUILDING_BTN_TYPE.GOLDSPEEDUP then 
        UIExtend.setCCLabelString(self.ccbfile,"mBtnName",str)
    else 
        UIExtend.setCCLabelString(self.ccbfile,"mBtnName",'')
        UIExtend.setCCLabelString(self.ccbfile,"mDiamondsNum",str)
    end 
end

function RAHUDBtnHandler:setType(btnType)
    self.btnType = btnType
    self.icon:setTexture(Btn_Image_Table[self.btnType])
    self:setString(_RALang(Btn_Txt_Map[self.btnType]))

    if self.btnType ~= BUILDING_BTN_TYPE.GOLDSPEEDUP then 
        self.ccbfile:getCCNodeFromCCB('mDiamondsNode'):setVisible(false)
    else 
        self.ccbfile:getCCNodeFromCCB('mDiamondsNode'):setVisible(true)
    end 
end

function RAHUDBtnHandler:onFunciton()
    if self.handler ~= nil then 
        self.handler:onFunction(self.btnType)
    end 
end

function RAHUDBtnHandler:remove()
    UIExtend.unLoadCCBFile(self)
end
 
local RABuildingHUD = BaseFunctionPage:new(...)
RABuildingHUD.handler = nil
RABuildingHUD.building = nil 
RABuildingHUD.buildData = nil 
RABuildingHUD.btnTable = nil
RABuildingHUD.isShow = false  

function RABuildingHUD:init()
    UIExtend.loadCCBFile("RAHUDCityNode.ccbi",self)
    UIExtend.setNodeVisible(self.ccbfile,"mHUDTitleNode", false)
    self.btnTable = {}
    self.isShow = false
    self.building = nil 
    self.buildData = nil 
    self.handler = nil 
end

function RABuildingHUD:show(building)
    self.building = building
    self.buildData = building.buildData
    
    self:initBuildName()
    self:initBtns()
    self.isShow = true 
end

function RABuildingHUD:hide()

    if self.isShow == false then 
        return 
    end 

    self.building:stopShadow()
    self.ccbfile:removeFromParentAndCleanup(false)
    if self.mNameCcb then
    	self.mNameCcb:removeFromParentAndCleanup(false)
    end
    self.building = nil 
    self.buildData = nil 
    self.isShow = false 
end

--初始化按钮
function RABuildingHUD:initBtns()

    local btnCount = 1

    --电力 添加电力详情
    local isPowerBuild = false
    if self.buildData.confData.buildType == Const_pb.POWER_PLANT then  --作战实验室
        self:initSingleBtn(btnCount,BUILDING_BTN_TYPE.POWER_DETAIL)
        isPowerBuild = true
    end

    if isPowerBuild then
        btnCount = btnCount + 1
    end

    --监狱没详情，其余建筑都有
    if self.buildData.confData.buildType == Const_pb.PRISON then
        self:initSingleBtn(btnCount,BUILDING_BTN_TYPE.PRISON)
    else
        self:initSingleBtn(btnCount,BUILDING_BTN_TYPE.DETAIL) 
    end

    if self.buildData.confData.buildType == Const_pb.FIGHTING_LABORATORY then  --作战实验室
        btnCount = btnCount + 1
        self:initSingleBtn(btnCount,BUILDING_BTN_TYPE.RESEARCH)
    elseif self.buildData.confData.buildType == Const_pb.WAREHOUSE then --仓库
        btnCount = btnCount + 1
        self:initSingleBtn(btnCount,BUILDING_BTN_TYPE.WAREHOUSE)
    elseif self.buildData.confData.buildType == Const_pb.RADAR then  --雷达
        btnCount = btnCount + 1
        self:initSingleBtn(btnCount,BUILDING_BTN_TYPE.RADAR)
    elseif self.buildData.confData.buildType == Const_pb.EMBASSY then  --大使馆
        btnCount = btnCount + 1
        self:initSingleBtn(btnCount,BUILDING_BTN_TYPE.EMBASSY)
    elseif RABuildingUtility:isSoilderBuilding(self.buildData.confData.buildType) then --是兵营
        -- if self.building.queueData == nil or self.building.queueData.queueType == Const_pb.SOILDER_QUEUE then     
            btnCount = btnCount + 1
            if self.buildData.confData.buildType == Const_pb.BARRACKS then --4个兵营 显示造兵按钮
                self:initSingleBtn(btnCount,BUILDING_BTN_TYPE.TRAIN_BARRACKS)
            elseif self.buildData.confData.buildType == Const_pb.WAR_FACTORY then
                self:initSingleBtn(btnCount,BUILDING_BTN_TYPE.TRAIN_WAR_FACTORY)
            elseif self.buildData.confData.buildType == Const_pb.REMOTE_FIRE_FACTORY then 
                self:initSingleBtn(btnCount,BUILDING_BTN_TYPE.TRAIN_REMOTE_FIRE_FACTORY)
            elseif self.buildData.confData.buildType == Const_pb.AIR_FORCE_COMMAND then
                self:initSingleBtn(btnCount,BUILDING_BTN_TYPE.TRAIN_RAIR_FORCE_COMMAND)
            end
        -- end 
    elseif self.buildData.confData.buildType == Const_pb.HOSPITAL_STATION then --医院
        btnCount = btnCount + 1
        self:initSingleBtn(btnCount,BUILDING_BTN_TYPE.TREAT)
    elseif self.buildData.confData.buildType == Const_pb.EQUIP_RESEARCH_INSTITUTE then --装备研究所
        btnCount = btnCount + 1
        self:initSingleBtn(btnCount,BUILDING_BTN_TYPE.MAKE)
    end 

    if self.building.queueData ~= nil then

        if self.building.queueData.queueType == Const_pb.SOILDER_QUEUE or self.building.queueData.queueType == Const_pb.CURE_QUEUE then --造兵,治疗队列存在的时候，是可以升级的
            local _,maxLevel = RABuildingUtility.getBuildInfoByType(self.buildData.confData.buildType,false) 
            if self.buildData.confData.level < maxLevel then --未满级需要升级按钮
                btnCount = btnCount + 1
                self:initSingleBtn(btnCount,BUILDING_BTN_TYPE.UPGRADE)
            end 
        end 

        btnCount = btnCount + 1
        self:initSingleBtn(btnCount,BUILDING_BTN_TYPE.GOLDSPEEDUP)
        --金币加速需要显示金币消耗
        local remainTime = Utilitys.getCurDiffTime(self.building.queueData.endTime)
        local timeCostDimand = RALogicUtil:time2Gold(remainTime)
        self.btnTable[btnCount]:setString(timeCostDimand)
        
         --如果没有道具,不显示道具升级按钮
        local RACoreDataManager = RARequire("RACoreDataManager")
        local itemsInfo = RACoreDataManager:getAccelerateDataByType(self.building.queueData.queueType)
	    if not itemsInfo or not next(itemsInfo) then 
		    -- print("没有道具,不显示道具加速按钮!!!!")
	    else
			btnCount = btnCount + 1
            self:initSingleBtn(btnCount,BUILDING_BTN_TYPE.SPEEDUP)
	    end
        
        if btnCount < 5 then --如果按钮已经超过最大数目
            --初始化取消按钮 
            if self.building.queueData.queueType == Const_pb.BUILDING_QUEUE or      --取消建筑升级
            self.building.queueData.queueType == Const_pb.BUILDING_DEFENER then 
                btnCount = btnCount + 1    
                self:initSingleBtn(btnCount,BUILDING_BTN_TYPE.CANCEL_BUILDING_UPGRADE)
            elseif self.building.queueData.queueType == Const_pb.SCIENCE_QUEUE then --取消研究
                btnCount = btnCount + 1    
                self:initSingleBtn(btnCount,BUILDING_BTN_TYPE.CANCEL_RESEARCH)
            elseif self.building.queueData.queueType == Const_pb.SOILDER_QUEUE then --取消造兵
                --btnCount = btnCount + 1    
                --self:initSingleBtn(btnCount,BUILDING_BTN_TYPE.CANCEL_TRAIN)
            elseif self.building.queueData.queueType == Const_pb.CURE_QUEUE then    --取消造兵
                --btnCount = btnCount + 1    
                --self:initSingleBtn(btnCount,BUILDING_BTN_TYPE.CANCEL_TREAT)
            elseif self.building.queueData.queueType == Const_pb.EQUIP_QUEUE then   --取消研制
                btnCount = btnCount + 1    
                self:initSingleBtn(btnCount,BUILDING_BTN_TYPE.CANCEL_MAKE)
            end
        end 
    end 

    if self.building.queueData ==nil then 
        local isUpdate = true
        if self.buildData.confData.limitType == Const_pb.LIMIT_TYPE_BUILDING_DEFENDER then  --防御性建筑 
            if self.buildData.normal ~= 1 then
                isUpdate = false
            end
        end
        if isUpdate then
            local _,maxLevel = RABuildingUtility.getBuildInfoByType(self.buildData.confData.buildType,false) 
            if self.buildData.confData.level < maxLevel then --未满级需要升级按钮
                btnCount = btnCount + 1
                self:initSingleBtn(btnCount,BUILDING_BTN_TYPE.UPGRADE)
            end 
        else
            btnCount = btnCount + 1
            self:initSingleBtn(btnCount,BUILDING_BTN_TYPE.REPAIR)
        end    
    end 

    self.ccbfile:runAnimation("FunAni" .. btnCount)
end

--初始化按钮
function RABuildingHUD:initSingleBtn(btnIndex,btnType)
    local btn = self.btnTable[btnIndex]
    if btn == nil then
        local node =  self.ccbfile:getCCNodeFromCCB('mFunNode' .. btnIndex) 
        btn = RAHUDBtnHandler:new(btnType)
        btn:init()
        btn.handler = self
        self.btnTable[btnIndex] = btn
        node:addChild(btn.ccbfile)
        RACitySceneManager:setControlToCamera(btn.ccbfile)
    else
        btn:setType(btnType)
    end 
end

--HUD弹出动画结束处理
function RABuildingHUD:OnAnimationDone()
    local lastAnimationName = self.ccbfile:getCompletedAnimationName()
    
    if string.sub(lastAnimationName,1,6) == 'FunAni' then   
        if self.handler then 
            self.handler:onHUDAnimationDone(self.buildData)
        end 
    end 
end

-- 获得指定类型按钮的位置信息和大小
function RABuildingHUD:getBtnInfo(btnType)
    local info = nil 
    for k,v in ipairs(self.btnTable) do
        if v.btnType == btnType then 
            local node = self.ccbfile:getCCNodeFromCCB('mFunNode' ..    k) 
            local x,y = node:getPosition()
            local contentSize = node:getContentSize()

            local pos = node:getParent():convertToWorldSpace(ccp(x,y))
            
            local RACitySceneManager = RARequire('RACitySceneManager')
            pos = RACitySceneManager.convertTerrainPos2ScreenPos(pos)

            local cameraScale = RACityScene.mCamera:getScale()
            local position = ccp(pos.x, pos.y)
            info = {}
            info.pos = position 
            local baseCamera = RACitySceneConfig.cameraInfo.normalScale
            info.size = CCSizeMake(contentSize.width*baseCamera/cameraScale,contentSize.height*baseCamera/cameraScale)
            break
        end 
    end
    return info 
end

--设置建筑名字
function RABuildingHUD:initBuildName()
    local name = RAStringUtil:getLanguageString(self.buildData.confData.buildName)
    if name == nil then 
        name = self.buildData.confData.buildName
    end 

    -- UIExtend.setCCLabelString(self.ccbfile,"mHUDName",name)


    if self.mNameCcb == nil then
	    self.mNameCcb = UIExtend.loadCCBFile('RAHUDCityName.ccbi', {})
	    self.mNameCcb:setAnchorPoint(0, 0)
	end

	if not self.isShow then
	    RACityScene.mBuildUILayer:addChild(self.mNameCcb)
	end

    UIExtend.setCCLabelString(self.mNameCcb, 'mHUDName', name)
    -- ttf:setString(name)

    local centerX,centerY = self.building:getCenter()
    local RATileUtil = RARequire('RATileUtil')
    local topPos = RATileUtil:tile2Space(RACityScene.mTileMapGroundLayer, self.building:getTopTile())

    if self.buildData.confData.upButtonPos ~= nil then 
        self.mNameCcb:setPosition(centerX,centerY+self.buildData.confData.upButtonPos)
    else 
        self.mNameCcb:setPosition(centerX,topPos.y+75) 
    end
end

function RABuildingHUD:onFunction(btnType)
    if self.handler then 
        self.handler:onHUDHandler(self.buildData,btnType)
    end 
end

function RABuildingHUD:setPosition(x,y)
    self.ccbfile:setPosition(x,y) 
end

function RABuildingHUD:release()

    for k,btn in pairs(self.btnTable) do
        btn:remove()
    end

    UIExtend.releaseCCBFile(self.mNameCcb)
    RA_SAFE_REMOVEFROMPARENT(self.mNameCcb)
    self.mNameCcb = nil
    UIExtend.unLoadCCBFile(self)
end

return RABuildingHUD
