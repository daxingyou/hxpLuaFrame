--region *.lua
--Date
--此文件由[BabeLua]插件自动生成
local UIExtend = RARequire("UIExtend")
local RABuildInformationUtil = {
    
    --calc seperate space by total size and section
    calcSectionPos = function (self,totalWidth,sectionSize)
        assert(sectionSize > 0,"sectionSize > 0")
        local posTable = {}
        local gapWitdh = totalWidth / sectionSize
        for i = 1,sectionSize,1 do 
            local posX = (i-1) * gapWitdh + gapWitdh /2
            local posY = 0
            posTable[i] = RACcp(posX,posY)
        end
        return posTable
    end,

    createLabel = function(self,parentNode,str,targetLabel, tag)
        local label = parentNode:getChildByTag(tag)
	    if label then
	       label:setString(str)
	       label:setVisible(true)
	    else
		    label = UIExtend.createLabel(tostring(str))
	        label:setAnchorPoint(ccp(0.5,0.5))
	        label:setColor(targetLabel:getColor())
            label:setFontName(targetLabel:getFontName())
	        label:setFontSize(targetLabel:getFontSize())
	        label:setPositionY(targetLabel:getPositionY())
	        parentNode:addChild(label)
	        label:setTag(tag)  
        end 
        return label
    end,

    initBuildInfoAttr = function (self,buildData)
        local col = 0
        local keyTab={}
        local titleTab = {}
        local buildInfo = buildData.confData
        
        if buildInfo.electricGenerate then
            --产电量
            col = col+1
            table.insert(titleTab,_RALang("@ElectricGenerate"))
            table.insert(keyTab,"electricGenerate")
        end 

        if buildInfo.electricConsume then
            --占用电量
            col = col+1
            table.insert(titleTab,_RALang("@ElectricConsume"))
            table.insert(keyTab,"electricConsume")
        end 

        --每分钟产量
        --if buildInfo.resPerMin then
            --产资源每min
            --col = col+1
            --table.insert(titleTab,_RALang("@ResPerMin"))
            --table.insert(keyTab,"resPerMin")
        --end 

        --每小时产量
        if buildInfo.resPerHour then
            --产资源每hour
            col = col+1
            table.insert(titleTab,_RALang("@ResPerHour"))
            table.insert(keyTab,"resPerHour")
        end 

        if buildInfo.resLimit then
            --产资源上限
            col = col+1
            table.insert(titleTab,_RALang("@ResLimit"))
            table.insert(keyTab,"resLimit")
        end 

        -- if buildInfo.resProtect then
        --  --资源保护
        --  col = col+1
        --  table.insert(titleTab,_RALang("@ResProtect"))
        --  table.insert(keyTab,"resProtect")
        -- end
        -- if buildInfo.resProtectPlus then
        --  --资源额外保护
        --  col = col+1
        --  table.insert(titleTab,_RALang("@ResProtectPlus"))
        --  table.insert(keyTab,"resProtectPlus")
        -- end 
     
         if buildInfo.resProtectA then
            --资源保护:黄金
            col = col+1
            table.insert(titleTab,_RALang("@ResProtectA"))
            table.insert(keyTab,"resProtectA")
         end 

         if buildInfo.resProtectB then
            --资源保护:石油
            col = col+1
            table.insert(titleTab,_RALang("@ResProtectB"))
            table.insert(keyTab,"resProtectB")
         end 

         if buildInfo.resProtectC then
            --资源保护:钢材
            col = col+1
            table.insert(titleTab,_RALang("@ResProtectC"))
            table.insert(keyTab,"resProtectC")
         end 

         if buildInfo.resProtectD then
            --资源保护:稀土
            col = col+1
            table.insert(titleTab,_RALang("@ResProtectD"))
            table.insert(keyTab,"resProtectD")
         end 

        if buildInfo.trainQuantity then
            --训练数量
            col = col+1
            table.insert(titleTab,_RALang("@TrainQuantity"))
            table.insert(keyTab,"trainQuantity")
        end
        if buildInfo.trainSpeed then
            --训练速度
            col = col+1
            table.insert(titleTab,_RALang("@TrainSpeed"))
            table.insert(keyTab,"trainSpeed")
        end
        if buildInfo.assistTime then
            --援助减少时间
            col = col+1
            table.insert(titleTab,_RALang("@AssistTime"))
            table.insert(keyTab,"assistTime")
        end 
        if buildInfo.assistLimit then
            --可受援助次数
            col = col+1
            table.insert(titleTab,_RALang("@AssistLimit"))
            table.insert(keyTab,"assistLimit")
        end 
        if buildInfo.assistUnitLimit then
            --援助单位上限
            col = col+1
            table.insert(titleTab,_RALang("@AssistUnitLimit"))
            table.insert(keyTab,"assistUnitLimit")
        end
        if buildInfo.marketBurden then
            --市场负重
            col = col+1
            table.insert(titleTab,_RALang("@MarketBurden"))
            table.insert(keyTab,"marketBurden")
        end 
        if buildInfo.marketTax then
            --市场税率
            col = col+1
            table.insert(titleTab,_RALang("@MarketTax"))
            table.insert(keyTab,"marketTax")
        end
        if buildInfo.buildupLimit then
            --集结上限
            col = col+1
            table.insert(titleTab,_RALang("@BuildupLimit"))
            table.insert(keyTab,"buildupLimit")
        end 
        if buildInfo.attackUnitLimit then
            --行军单位数量
            col = col+1
            table.insert(titleTab,_RALang("@AttackUnitLimit"))
            table.insert(keyTab,"attackUnitLimit")
        end
        if buildInfo.woundedLimit then
            --伤兵上限
            col = col+1
            table.insert(titleTab,_RALang("@WoundedLimit"))
            table.insert(keyTab,"woundedLimit")
        end 
        if buildInfo.effectID then
            --buff
            RAStringUtil = RARequire("RAStringUtil")
            local sub = RAStringUtil:split(buildInfo.effectID, "_")
            if #sub == 2 then
                col = col+1
                local effectid_conf = RARequire("effectid_conf")
                table.insert(titleTab,_RALang(effectid_conf[tonumber(sub[1])].nameString or "missionBuff"))
                table.insert(keyTab,"effectID")
            end
        end      

        --如果为防御建筑，得从 battle_soldier_conf 表里面读取攻击 防御 最大生命 以及当当前生命
        local Const_pb = RARequire("Const_pb")
        if buildInfo.limitType == Const_pb.LIMIT_TYPE_BUILDING_DEFENDER then  --防御性建筑 
            local battleSoldierConf = RABuildingUtility:getDefenceBuildConfById(buildInfo.id)
            if battleSoldierConf then
                --攻击
                if battleSoldierConf.attack then
                    col = col+1
                    table.insert(titleTab,_RALang("@BuildingAttack"))
                    table.insert(keyTab,"buildingAttack")
                end

                --防御
                if battleSoldierConf.defence then
                    col = col+1
                    table.insert(titleTab,_RALang("@BuildingDefence"))
                    table.insert(keyTab,"buildingDefence")
                end

                --最大生命
                if battleSoldierConf.hp then
                    col = col+1
                    table.insert(titleTab,_RALang("@DefenceTotalHP"))
                    table.insert(keyTab,"defenceTotalHP")
                end
            end

            --当前生命
            if buildData.HP then
                col = col+1
                table.insert(titleTab,_RALang("@DefenceCurrHP"))
                table.insert(keyTab,"defenceCurrHP")
            end
        end

        --兵营 战车工厂 远程火力工厂 空指部 添加总训练速度增加
        if buildInfo.buildType == Const_pb.BARRACKS or buildInfo.buildType == Const_pb.WAR_FACTORY 
            or buildInfo.buildType == Const_pb.REMOTE_FIRE_FACTORY or buildInfo.buildType == Const_pb.AIR_FORCE_COMMAND then
                col = col+1
                table.insert(titleTab,_RALang("@TotalTrainSpeed"))
                table.insert(keyTab,"totalTrainSpeed")
        end

        --医护维修站 总伤兵上限
        if buildInfo.buildType == Const_pb.HOSPITAL_STATION then
            col = col+1
            table.insert(titleTab,_RALang("@TotaleWoundedLimit"))
            table.insert(keyTab,"TotaleWoundedLimit")
        end
        
        --资源建筑
        if buildInfo.limitType == Const_pb.LIMIT_TYPE_BUIDING_RESOURCES then  --资源建筑 
            
            -- local RABuildManager = RARequire("RABuildManager")
            -- local builds = RABuildManager:getBuildDataByType(buildInfo.buildType)

            -- local resTatol = 0
            -- for k,buildDataInfo in pairs(builds) do
            --     resTatol = resTatol + buildDataInfo.confData.
            -- end

            --资源总产量/小时
            col = col+1
            table.insert(titleTab,_RALang("@TotalResOutPut"))
            table.insert(keyTab,"totalResOutPut")

            --资源总上限
            col = col+1
            table.insert(titleTab,_RALang("@TotalResUpperLimit"))
            table.insert(keyTab,"totalResUpperLimit")
        end    

        return col,keyTab,titleTab
    end,

    getDefenceAttrByKey = function (self,buildData,key)
        -- body
        local buildInfo = buildData
        if buildData.confData then
            buildInfo = buildData.confData
        end
        local battleSoldierConf = RABuildingUtility:getDefenceBuildConfById(buildInfo.id)

        local currValue = nil
        if key == "buildingAttack" then     --攻击
            currValue = battleSoldierConf.attack
        end 

        if key == "buildingDefence" then    --防御
            currValue = battleSoldierConf.defence
        end

        if key == "defenceTotalHP" then     --最大生命
            currValue = battleSoldierConf.hp
        end

        if key == "defenceCurrHP" then  --升级效果里面不显示当前血条
            currValue = buildData.HP
        end
        return currValue
    end
}
return RABuildInformationUtil
--endregion
