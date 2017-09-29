--region *.lua
--Date
--此文件由[BabeLua]插件自动生成

local RAScienceUtility = {}
local tech_conf = RARequire('tech_conf')
local Const_pb = RARequire('Const_pb')
local RAQueueManager = RARequire("RAQueueManager")
local RAStringUtil = RARequire("RAStringUtil")
local RARootManager = RARequire("RARootManager")

--根据id获取科技配置信息
function RAScienceUtility:getScienceDataById(id)
	return tech_conf[tonumber(id)]
end


--根据type获取相应的研究id
function RAScienceUtility:getScienceDataByType(scienceType)
	local  t = {}
	for k,v in pairs(tech_conf) do
		local scienceInfo = v
		if scienceInfo.techUiType == scienceType then
			t[tostring(scienceInfo.id)]=scienceInfo
		end 
	end
	return t

end

function RAScienceUtility:getScienceDataByTypeAndLevel(scienceType,level)
	local  t = {}
	for k,v in pairs(tech_conf) do
		local scienceInfo = v
		if scienceInfo.techUiType == scienceType and  scienceInfo.techLevel==level then
			t[tostring(scienceInfo.id)]=scienceInfo
		end 
	end
	return t
end

function RAScienceUtility:refreshScienceData(scienceId,tb)
	local id = scienceId
	local updateData = nil
	local tmpKey = nil
	scienceId = math.floor(scienceId/100)
	for k,v in pairs(tb) do
		local tmpScienceId = tonumber(k)
		tmpScienceId = math.floor(tmpScienceId/100)
		if tmpScienceId == scienceId then
			updateData = RAScienceUtility:getScienceDataById(id+1)
			tmpKey = k
			break
		end 
	end

	--更新数据
	if not updateData  then --科技以达到最大等级
        updateData = RAScienceUtility:getScienceDataById(id)
	end 

	if tmpKey and tb[tmpKey] then
		tb[tmpKey] = nil
		tb[tostring(updateData.id)] = updateData
	end
end

--通过id获取当前科技研究的最高等级
function RAScienceUtility:getScienceMaxLevel(id)
	local scienceId= tonumber(id)
	scienceId = math.floor(scienceId/100)
	local level = 0
	for k,v in pairs(tech_conf) do
		local tmpId = tonumber(k)
		tmpId = math.floor(tmpId/100)
		if tmpId == scienceId then
			level=level+1
		end
	end
	return level
end

--判断当前科技是否已达到最大等级
function RAScienceUtility:isReachMaxLevel(id)
	local maxId = self:getScienceMaxLevel(id)
	local techInfo =self:getScienceDataById(id)
	if not techInfo then return false end 
	if techInfo.techLevel==maxId then
		return true
	end 
	return false
end

--返回同一个UiType标签下最大的位置
function RAScienceUtility:getMaxPosYInUitype(uiType)
	local maxPosY=0
	for k,v in pairs(tech_conf) do
		local scienceInfo = v
		if scienceInfo.techUiType == uiType then
			local posInfo = RAStringUtil:split(scienceInfo.uiPos,",")
			if tonumber(posInfo[2])>maxPosY then
				maxPosY=tonumber(posInfo[2])
			end 
		end 
	end
	return maxPosY
end

--返回同一个UiType标签下最小的位置
function RAScienceUtility:getMinPosYInUitype(uiType)
	local minPosY=100000
	for k,v in pairs(tech_conf) do
		local scienceInfo = v
		if scienceInfo.techUiType == uiType then
			local posInfo = RAStringUtil:split(scienceInfo.uiPos,",")
			if tonumber(posInfo[2])<minPosY then
				minPosY=tonumber(posInfo[2])
			end 
		end 
	end
	return minPosY
end

--获取研究队列
function RAScienceUtility:getScienceQueue()
	return RAQueueManager:getQueueDatas(Const_pb.SCIENCE_QUEUE)
end



function RAScienceUtility:getEffectValueById(id)
	local scienceInfo = tech_conf[id]
	if scienceInfo and scienceInfo.techEffectID then
		local effectTab = RAStringUtil:split(scienceInfo.techEffectID,"_")
		local cueEffectValue = tonumber(effectTab[2])
		return cueEffectValue
	end 
	return 0
	
end

function RAScienceUtility:getLineDatasByType(uiType)
	local lineTab = {}
	local tech_uipos_conf = RARequire("tech_uipos_conf")
	for k,v in pairs(tech_uipos_conf) do
   		local posInfo = v
   		if uiType==posInfo.techUiType then
   			lineTab[k]={}
   			lineTab[k].fromPos = posInfo.fromPos
   			lineTab[k].toPos = posInfo.toPos
   		end 
   end
   return lineTab

end

--研究成功提示
function RAScienceUtility:showResearchSuccessTip(id)
	local techInfo=RAScienceUtility:getScienceDataById(id)
	local techName = _RALang(techInfo.techName)
	local tipStr = _RALang("@ResearchSuccessTip",techName)
	RARootManager.ShowMsgBox(tipStr)
end

--处理所有科技的连线 构建成一张画线表
function RAScienceUtility:createLineTab(uiType)
	local tb=self:getScienceDataByType(uiType)
	local lineTab={}
	local count=1
	for k,v in pairs(tb) do
		local scienceInfo = v
		local frontTechId = scienceInfo.frontTech
		if frontTechId then
			

			local frontTechTab= RAStringUtil:split(frontTechId,",")
			for i=1,#frontTechTab do
				local frontTechId = tonumber(frontTechTab[i])
				local frontTechInfo = self:getScienceDataById(frontTechId)

				local newPoint1,newPoint2,num = self:createNewPoint(frontTechInfo.uiPos,scienceInfo.uiPos)
				if num==1 then
					local t1={techUiType=uiType,fromPos=frontTechInfo.uiPos,toPos=scienceInfo.uiPos,techId=frontTechInfo.id}
					lineTab[count]=t1
					count=count+1
				else
					local t1={techUiType=uiType,fromPos=frontTechInfo.uiPos,toPos=newPoint1,techId=frontTechInfo.id,isConnect=true}
					local t2={techUiType=uiType,fromPos=newPoint1,toPos=newPoint2,techId=frontTechInfo.id,isConnect=true}
					local t3={techUiType=uiType,fromPos=newPoint2,toPos=scienceInfo.uiPos,techId=frontTechInfo.id}
					lineTab[count]=t1
					lineTab[count+1]=t2
					lineTab[count+2]=t3
					count=count+3
				end 
			end
			
			
		end 	
	end
	return lineTab
end

function RAScienceUtility:createNewPoint(point1,point2)
	
	local tb1=RAStringUtil:split(point1,",")
	local tb2=RAStringUtil:split(point2,",")

	--x轴不同
	local pox1=tonumber(tb1[1])
	local poy1=tonumber(tb1[2])
	local pox2=tonumber(tb2[1])
	local poy2=tonumber(tb2[2])
	local x1=nil
	local y1=nil
	local x2=nil
	local y2=nil
	local count=1
	if pox1~=pox2 and poy1~=poy2 then
	   y1=(poy1+poy2)/2
	   x1=pox1

	   y2=(poy1+poy2)/2
	   x2=pox2

	   count=2
	else
		return nil,nil,count
	end

	local newPoint1=""..x1..","..y1
	local newPoint2=""..x2..","..y2
	return newPoint1,newPoint2,count
end

return RAScienceUtility
--endregion
