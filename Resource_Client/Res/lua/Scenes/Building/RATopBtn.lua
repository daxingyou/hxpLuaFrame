RARequire("BasePage")
RARequire("extern")
RARequire('RABuildingType')

local common = RARequire("common")
local UIExtend = RARequire('UIExtend')
local RACitySceneConfig = RARequire("RACitySceneConfig")
RARequire('MessageManager')
local RATopBtn = {}

--构造函数
function RATopBtn:new()
    local o = {}
    o.btnType = nil 
    o.buildData = nil 
    setmetatable(o,self)
    self.__index = self
    return o
end

function RATopBtn:onFunciton()
    local RABuildManager = RARequire("RABuildManager")
    RABuildManager:onHUDHandler(self.buildData,self.btnType)
end

function RATopBtn:init(buildData)
    self.buildData = buildData
    UIExtend.loadCCBFile("RAHUDCityTopCell.ccbi",self)
end

function RATopBtn:setBtnType(btnType)
    self.btnType = btnType
    local bgSprite = self.ccbfile:getCCSpriteFromCCB('mBtnBG')
    local bgSpriteName = 'MainUI_HUD_BG_Yellow.png'

    local iconSprite = self.ccbfile:getCCSpriteFromCCB('mHUDIcon')
    local iconName = Btn_Image_Table[btnType]

    bgSprite:setTexture(bgSpriteName)
    iconSprite:setTexture(iconName)

    if btnType == BUILDING_BTN_TYPE.GET_BARRACKS or btnType == BUILDING_BTN_TYPE.GET_AIR_FORCE_COMMAND
        or btnType == BUILDING_BTN_TYPE.GET_WAR_FACTORY or btnType == BUILDING_BTN_TYPE.GET_REMOTE_FIRE_FACTORY then
        
        self.btnType = BUILDING_BTN_TYPE.GETTROOP
    end

    if self.btnType == BUILDING_BTN_TYPE.SOLDIER_WOUNDED or btnType == BUILDING_BTN_TYPE.EINSTEIN_NOT_REACH then 
        self:setBGVisible(false)
    else 
        self:setBGVisible(true)
    end 

    if self.btnType == BUILDING_BTN_TYPE.FREETIME then 
        self.ccbfile:runAnimation('FreeInAni')
    else 
        self.ccbfile:runAnimation('InAni')
    end 

     --新手引导
--     local RAGuideManager = RARequire('RAGuideManager')
--     local guideinfo = RAGuideManager.getConstGuideInfoById()

--     if guideinfo ~= nil and guideinfo.btnType ~= nil then 
--         local info = self:getBtnInfo(guideinfo.btnType)
--         if info ~= nil then 
--             info.pos.x = info.pos.x - info.size.width*0.5
--             info.pos.y = info.pos.y - info.size.height*0.5
--             MessageManager.sendMessage(MessageDef_Building.MSG_Guide_Hud_BtnInfo,{pos = info.pos, size = info.size})
--         end 
--     end 
end

function RATopBtn:OnAnimationDone(ccbfile)
	local lastAnimationName = ccbfile:getCompletedAnimationName()
    --if lastAnimationName == "FreeInAni" or lastAnimationName == "InAni" then
        --新手引导
    if lastAnimationName == "InAni" then
         local RAGuideManager = RARequire('RAGuideManager')
         local guideinfo = RAGuideManager.getConstGuideInfoById()

         if guideinfo ~= nil and guideinfo.btnType ~= nil then 
             local info = self:getBtnInfo(guideinfo.btnType)
             if info ~= nil then 
                 info.pos.x = info.pos.x - info.size.width*0.5
                 info.pos.y = info.pos.y - info.size.height*0.5
                 MessageManager.sendMessage(MessageDef_Building.MSG_Guide_Hud_BtnInfo,{pos = info.pos, size = info.size})
             end 
         end 
    end
end

-- 获得指定类型按钮的位置信息和大小
function RATopBtn:getBtnInfo(btnType)

    if self.btnType ~= btnType then 
        return nil 
    end 

    local node = self.ccbfile:getCCNodeFromCCB('mFunction') 
    local x,y = node:getPosition()
    local contentSize = node:getContentSize()

    local pos = node:getParent():convertToWorldSpaceAR(ccp(x,y))
    
    local RACitySceneManager = RARequire('RACitySceneManager')
    pos = RACitySceneManager.convertTerrainPos2ScreenPos(pos)
    local position = ccp(pos.x, pos.y)
    info = {}
    info.pos = position 

    local baseCamera = RACitySceneConfig.cameraInfo.normalScale
    local RACityScene = RARequire("RACityScene")
    local cameraScale = RACityScene.mCamera:getScale()
    info.size = CCSizeMake(contentSize.width*baseCamera/cameraScale,contentSize.height*baseCamera/cameraScale)

    return info 
end

function RATopBtn:setBGVisible(flag)
    self.ccbfile:getCCSpriteFromCCB('mBtnBG'):setVisible(flag)
    self.ccbfile:getCCControlButtonFromCCB('mFunction'):setVisible(flag)
end

function RATopBtn:setPosition(x,y)
    self.ccbfile:setPosition(x,y) 
end

function RATopBtn:release()
    UIExtend.unLoadCCBFile(self)
end

return RATopBtn
