--region *.lua
--Date
--此文件由[BabeLua]插件自动生成
local UIExtend = RARequire("UIExtend")
local RAGuideManager = RARequire("RAGuideManager")
local RACitySceneConfig = RARequire("RACitySceneConfig")
local RAGuideConfig = RARequire("RAGuideConfig")

local RACityScene_TrainAnimation = {
    mCityScene = nil,
    new = function(self,ccbfileName)
        local o = {}
        o.ccbfileName = ccbfileName
        setmetatable(o,self)
        self.__index = self
        return o 
    end,
    Enter = function(self,cityScene,status)
        local ccbfile = UIExtend.loadCCBFile(self.ccbfileName,self)
        local RAWorldConfig = RARequire("RAWorldConfig")
        local World_pb = RARequire("World_pb")
        local colorParam = RAWorldConfig.RelationFlagColor[World_pb.SELF]
        local colorKey = colorParam.key or 'DefaultColorKeyCCB'
        local r = colorParam.color.r or 255
        local g = colorParam.color.g or 255
        local b = colorParam.color.b or 255
        CCTextureCache:sharedTextureCache():addColorMaskKey(colorKey, r, g , b)
        ccbfile:setUseColorMask(colorKey)
        self.mCityScene = cityScene
        ccbfile:setPosition(0,0)
        self.mCityScene:addChild(ccbfile)
        
        self:ChangeStatus(status)
    end,
    ChangeStatus = function(self,status)
        if status == RACitySceneConfig.TrainGuideStatus.Empty then
            self.ccbfile:setVisible(false)
            self.ccbfile:runAnimation("Idle")
        elseif status == RACitySceneConfig.TrainGuideStatus.Idle then
            self.ccbfile:setVisible(true) 
            self.ccbfile:runAnimation("Idle")
        elseif status == RACitySceneConfig.TrainGuideStatus.Run then
            self.ccbfile:setVisible(true) 
            self.ccbfile:runAnimation("Run")
        end
    end,
    Exit = function(self)
        UIExtend.unLoadCCBFile(self)
    end
}



local RACityScene_TrainInGuide = {
    soldierHandler = {},
    tankHandler = {},
    Enter = function(self,cityScene)
        self.soldierHandler = RACityScene_TrainAnimation:new("Ani_City_Training_Soldier.ccbi")
        --calc the soldierHandler status
        local soldierStatus,tankStatus = self:checkArmyStatusByGuideId()
        self.soldierHandler:Enter(cityScene,soldierStatus)
        

        self.tankHandler = RACityScene_TrainAnimation:new("Ani_City_Training_Tank.ccbi")
        --calc the tankHandler status
        local tankStatus = RACitySceneConfig.TrainGuideStatus.Empty
        self.tankHandler:Enter(cityScene,tankStatus)

    end,
    UpdateAnimationStatus = function(self)
        local soldierStatus,tankStatus = self:checkArmyStatusByGuideId()
        self.soldierHandler:ChangeStatus(soldierStatus)
        self.tankHandler:ChangeStatus(tankStatus)
    end,
    Exit = function(self)
        self.soldierHandler:Exit()
        self.tankHandler:Exit()
    end,
    --return soldierStatus,tankStatus
    checkArmyStatusByGuideId = function(self)
        local soldierStatus = RACitySceneConfig.TrainGuideStatus.Empty
        local tankStatus = RACitySceneConfig.TrainGuideStatus.Empty
        local RAGuideConfig = RARequire("RAGuideConfig")
        --只有新手第一阶段做动画的特殊处理
        if RAGuideManager.getCurrentStage() == RAGuideConfig.GuideStageEnum.StageFirst then
            local curGuideId = RAGuideManager.currentGuildId
            if curGuideId < RAGuideConfig.normalCollectArmy then
                soldierStatus = RACitySceneConfig.TrainGuideStatus.Empty
            elseif curGuideId == RAGuideConfig.normalCollectArmy or 
            curGuideId == RAGuideConfig.missionCollectArmy then
                soldierStatus = RACitySceneConfig.TrainGuideStatus.Run
            else
                soldierStatus = RACitySceneConfig.TrainGuideStatus.Idle
            end

            if curGuideId < RAGuideConfig.normalCollectTank then
                tankStatus = RACitySceneConfig.TrainGuideStatus.Empty
            elseif curGuideId == RAGuideConfig.normalCollectTank then            
                tankStatus = RACitySceneConfig.TrainGuideStatus.Run
            else
                tankStatus = RACitySceneConfig.TrainGuideStatus.Idle
            end
        end
        return soldierStatus,tankStatus
    end
}

return RACityScene_TrainInGuide
--endregion
