local RAAllianceStatueManager = {}

local alliance_science_conf = RARequire("alliance_science_conf")

function RAAllianceStatueManager:initByPb(statueInfo)
	local info = {}
	info.statueId = statueInfo.statueId
	info.level = statueInfo.level
	info.hasBuild = statueInfo.hasBuild
	info.effect = {}
	info.refreshEffect = {}
	for i,v in ipairs(statueInfo.effect) do
		info.effect[i] = {}
		info.effect[i].effectId = v.effectId
		info.effect[i].effectValue = v.effectValue
	end
	if statueInfo.refreshEffect then
		for i,v in ipairs(statueInfo.refreshEffect) do
			info.refreshEffect[i] = {}
			info.refreshEffect[i].effectId = v.effectId
			info.refreshEffect[i].effectValue = v.effectValue
		end	
	end
	-- info.effect = {effectId = statueInfo.effect.effectId, effectValue = statueInfo.effect.effectValue}
	-- info.refreshEffect = {effectId = statueInfo.refreshEffect.effectId, effectValue = statueInfo.refreshEffect.effectValue}

	return info
end

--初始化
function RAAllianceStatueManager:setStatueData(infos)
	-- body
	self.statueData.allianScore = infos.allianScore
	local statueInfos = infos.statueInfos
	for i=1,#statueInfos do
		local statueInfo = statueInfos[i]
		local info = self:initByPb(statueInfo)
        self.statueData[i] = info
	end
	
	return self.statueData
end
--更新
function RAAllianceStatueManager:onRecieveStatueInfo( infos )
	infos = infos or {}
	if infos.allianScore then
		self.statueData.allianScore = infos.allianScore
	end
	-- dump(infos)
	for i,v in ipairs(infos.statueInfos) do
		local info = self:initByPb(v)
		for j,statueInfo in ipairs(self.statueData) do
			if statueInfo.statueId == info.statueId then
				self.statueData[j] = info
				break
			end
		end
	end
end

--获取联盟雕像数据
function RAAllianceStatueManager:getStatueData()
	return self.statueData
end

function RAAllianceStatueManager:setStatueInfo(index,statueInfo)
    local data = {}
    data.allianScore = statueInfo.allianScore
    data.statueInfo = {}
    data.statueInfo = statueInfo[index]

    return data
end

function RAAllianceStatueManager:getStatueInfoByIndex(index)
	index = index or 1
    local data
    if self.statueData and self.statueData[index] then
    	data = {}
    	data.allianScore = self.statueData.allianScore
    	data.statueInfo = self.statueData[index]
    end
    return data
end

function RAAllianceStatueManager:getStatueInfoByStatueId(statueId)
	statueId = statueId or 1
    local data
    if self.statueData then
    	for i,v in ipairs(self.statueData) do
    		if v.statueId == statueId then
		    	data = {}
		    	data.allianScore = self.statueData.allianScore
		    	data.statueInfo = v
    		end
    	end

    end
    return data
end

--根据id获取配置数据
function RAAllianceStatueManager:getStatueInfoListConfById(statueId)
	print("statueId = ",statueId)
	local statueConf = {}
	for k,v in ipairs(alliance_science_conf) do
		if v.statueId == statueId then
			statueConf[#statueConf + 1] = v
		end
	end
	return statueConf
end

--根据id获取配置数据
function RAAllianceStatueManager:getStatueInfoConfById(statueId, level)
	for k,v in ipairs(alliance_science_conf) do
		if v.statueId == statueId and v.level == level then
			return v
		end
	end
	return nil
end


--
function RAAllianceStatueManager:getEffectConf(effectId)
    local alliance_science_effect_name_conf = RARequire("alliance_science_effect_name_conf")
    if alliance_science_effect_name_conf[effectId] then
    	return alliance_science_effect_name_conf[effectId].effect_name
    end
    return ""
end

function RAAllianceStatueManager:linkHtmlText(len,attrNames,minAvlue,maxValue, isBr)
	local html_zh_cn = RARequire("html_zh_cn")
	local RAStringUtil = RARequire("RAStringUtil")
	local RAAllianceManager = RARequire("RAAllianceManager")
	local statueAttrHtmlConf = ""

	if len == 1 then
		statueAttrHtmlConf = RAStringUtil:fill(html_zh_cn["allianceEffect1"],attrNames[1] ,minAvlue[1] ,maxValue[1])
	else
		if isBr then
			statueAttrHtmlConf = RAStringUtil:fill(html_zh_cn["allianceEffect3"],attrNames[1] ,minAvlue[1] ,maxValue[1], attrNames[2],minAvlue[2] ,maxValue[2])
		else
			statueAttrHtmlConf = RAStringUtil:fill(html_zh_cn["allianceEffect2"],attrNames[1] ,minAvlue[1] ,maxValue[1], attrNames[2],minAvlue[2] ,maxValue[2])
		end
	end
	return statueAttrHtmlConf
end

function RAAllianceStatueManager:init()
	self.statueData = {}
end

RAAllianceStatueManager:init()

return RAAllianceStatueManager