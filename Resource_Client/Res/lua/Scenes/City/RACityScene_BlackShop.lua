--region *.lua
--Date
--此文件由[BabeLua]插件自动生成
local UIExtend = RARequire("UIExtend")

local RABlackShopManager = RARequire("RABlackShopManager")
local RAGuideManager = RARequire("RAGuideManager")


local RACityScene_BlackShop = {
    hasOpenPage = true,
    mCityScene = nil,
    setHasOpenPage = function(self,flag)
        self.hasOpenPage = flag
    end,
    setBlackShopAni = function(self)
        local curGuideStep = RAGuideManager.currentGuildId
        local RAGuideConfig = RARequire("RAGuideConfig")
        if curGuideStep < RAGuideConfig.partNameWithStartId.Guide_MainCity_Start_2To3 then
            self.ccbfile:setVisible(false)
        else
            self.ccbfile:setVisible(true)
            if self.hasOpenPage then
               self.ccbfile:runAnimation("NotNew")  
            else
               self.ccbfile:runAnimation("New")    
            end
        end
        
    end,
    Enter = function (self,cityScene)
        local ccbfile = UIExtend.loadCCBFile("Ani_City_BlackShop_Fly.ccbi",self)
        local RACitySceneConfig = RARequire("RACitySceneConfig")
        RAGameUtils:setChildMenu(ccbfile,RACitySceneConfig.tileInfo.tmxTotalRect)
        
        self.mCityScene = cityScene
        self.mCityScene:addChild(ccbfile)
        local curStep = RAGuideManager.currentGuildId
        local RAGuideConfig = RARequire("RAGuideConfig")
        if RABlackShopManager.hasNewGoods 
        and RAGuideManager.isInGuide() == false 
        and curStep > RAGuideConfig.showTravelShopGuideId then
            ccbfile:setVisible(true)
            ccbfile:runAnimation("Fly")
            self.hasOpenPage = false
            RABlackShopManager.hasNewGoods = false
        else
            self:setBlackShopAni()
        end

        -- self.mCityScene:removeChildByTag(10086, true)
        -- local obj3d = CCEntity3D:create("3d/zsj_09.c3b")
        -- obj3d:stopAllActions()
        -- obj3d:playAnimation("default",0,0.9,true)
        -- obj3d:setAlphaTestEnable(true)              --使用透明度通道
        -- obj3d:setUseLight(true)                     --开启灯光
        -- obj3d:setAmbientLight(0.3,0.3,0.3)          --环境光颜色
        -- obj3d:setDirectionLightColor(1.0,0.8,0.8)   --设置方向光方向
        -- obj3d:setDiffuseIntensity(1)                --设置漫反射光强度
        -- obj3d:setSpecularIntensity(60.0)            --设置镜面反射光强度
        -- obj3d:setScale(3)
        -- obj3d:setTag(10086)
        -- self.obj3d = obj3d
        -- local RACityScene = RARequire('RACityScene')
        -- local pos = RATileUtil:tile2Space(RACityScene.mTileMapGroundLayer,RACcp(21,54))
        -- obj3d:setPosition(pos)
        -- obj3d:setRotation3D(Vec3(40,-40,20)) --设置旋转角度
        -- self.mCityScene:addChild(obj3d)           
    end,
    Exit = function (self)
        UIExtend.unLoadCCBFile(self)
    end,
    HandleGuideSpecialReq= function(self)
        local tilePos = RACcp(2,2)
        local RACitySceneManager = RARequire("RACitySceneManager")
        RACitySceneManager:cameraGotoTilePos(tilePos,1,true)        
        local RARootManager = RARequire("RARootManager")
        performWithDelay(RARootManager.ccbfile,function()
            local tilePos2 = RACcp(21,54)
            RARootManager.AddCoverPage()
            RARootManager.RemoveGuidePage()
            RACitySceneManager:cameraGotoTilePos(tilePos2,8,false)
        end,2)

        local this = self
        local actionArr = CCArray:create()
        local delayAction = CCDelayTime:create(1)
        local callBack = CCCallFunc:create(
            function ()
                this.ccbfile:setVisible(true)
                this.ccbfile:runAnimation("Fly")
                --播放飞行音效
                local common = RARequire("common")
                common:playEffect("businessmanHelicopterPass")
            end
        )
        actionArr:addObject(delayAction)
        actionArr:addObject(callBack)
        local actionSequence = CCSequence:create(actionArr)
        actionArr:removeAllObjects()
        actionArr:release()
        self.ccbfile:runAction(actionSequence)
        
    end,
    OnAnimationDone = function(self, ccbfile)
        local lastAnimationName = ccbfile:getCompletedAnimationName()                
        if lastAnimationName == "Fly" then
            RAGuideManager:gotoNextStep()
            --播放停留音效
            local common = RARequire("common")
            common:playEffect("businessmanHelicopterStop")
        end
    end,
    onClick = function(self)
        local RARootManager = RARequire("RARootManager")
        RARootManager.OpenPage("RABlackShopPage",nil,true)
    end

}

return RACityScene_BlackShop
--endregion
