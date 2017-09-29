local Utilitys = RARequire("Utilitys")
local vip_conf = RARequire("vip_conf")
local item_conf = RARequire("item_conf")
local RAStringUtil = RARequire("RAStringUtil")
local RAPlayerInfoManager = RARequire("RAPlayerInfoManager")
local RACoreDataManager = RARequire("RACoreDataManager")

local RAVIPDataManager = {}

--ÍøÂç¼àÌýÊý¾Ý´¦Àí
RAVIPDataManager.Object=
{
MaxVIPLevel=nil,
isInitConfig=false,
currShowVIPLevel=1,
isActive=false,
VIPToolsPointType=1,
VIPToolsActiveType=2,
VIPToolsItemId=nil,
LastVIPReminderTimeKey="lastVIPReminderTimeKey",
LastVIPActiveTimeKey="lastVIPActiveTimeKey",
SelBuyItemConf=nil,
BuyDisabled=0,
VIPAttrConfig=nil,
VIPToosShowConfirm = false
}

function RAVIPDataManager.getShowConfirm()
    return RAVIPDataManager.Object.VIPToosShowConfirm
end

function RAVIPDataManager.setShowConfirm(isShowConfirm)
    RAVIPDataManager.Object.VIPToosShowConfirm = isShowConfirm
end

function configOrderSort(a, b)
	local r
	local aOrder = tonumber(a.conf.order)
	local bOrder = tonumber(b.conf.order)
	
	r = aOrder < bOrder
	
	return r
end

function RAVIPDataManager.configAttrOrderSort(a, b)
	local r
	local aOrder = tonumber(a.order)
	local bOrder = tonumber(b.order)
	r = aOrder < bOrder
	
	return r
end


function RAVIPDataManager.getMaxVIPLevel()
	
	if RAVIPDataManager.Object.MaxVIPLevel==nil then
		local maxLevel=1
		for k,v in pairs(vip_conf) do
			if v~=nil then
				if v.level>maxLevel then
					maxLevel=v.level
				end
			end
		end
		RAVIPDataManager.Object.MaxVIPLevel=maxLevel
	end
	return RAVIPDataManager.Object.MaxVIPLevel
end

function RAVIPDataManager.initConfig()
	if RAVIPDataManager.Object.isInitConfig==false then
		RAVIPDataManager._initVIPConfig()
		RAVIPDataManager._initVIPAttrConfig()
		RAVIPDataManager.Object.isInitConfig=true
	end
end

--³õÊ¼»¯Ã¿¸öVIPµÈ¼¶µÄÔöÁ¿KeyÖµ
function RAVIPDataManager._initVIPConfig()
	
	local maxVIPLevel=RAVIPDataManager.getMaxVIPLevel()
	local vip_attr_conf = RARequire("vip_attr_conf")
	for i=1,maxVIPLevel do
		local vipItem=vip_conf[i]
		if vipItem~=nil then
			local preVIPLevel=i-1
			local preVIPConfg=nil
			
			if preVIPLevel==0 then
				preVIPConfg=nil
			else
				preVIPConfg=vip_conf[preVIPLevel]
			end
			
			local currVIPConfig=vipItem
			
			for k,v in pairs(vip_attr_conf) do
				if v~=nil and v.columnName~=nil then
					local currColumn=currVIPConfig[v.columnName]
					local preColumn=0
					if preVIPConfg~=nil then
						preColumn=preVIPConfg[v.columnName]
					end

					if currColumn>preColumn then
						if vip_conf[i].increaseKey==nil then
							vip_conf[i].increaseKey={}
						end
						local obj={}
						obj.columnValue=_RALang(v.name)
						obj.columnName=v.columnName
						obj.symbol=v.symbol
						obj.openOrClose=v.openOrClose
						table.insert(vip_conf[i].increaseKey,obj)
					end
				end
			end
		end
	end
	
end

--³õÊ¼»¯KeyÖµµÃ×Ö¶ÎÃû
function RAVIPDataManager._initVIPAttrConfig()
	local vip_attr_conf = RARequire("vip_attr_conf")
	for k,v in pairs(vip_attr_conf) do
		if v~=nil then
			v.columnValue=_RALang(v.name)
		end
	end
end

function RAVIPDataManager.getVIPConfigByLevel(l)
	local obj=nil
	obj=vip_conf[l]
	return obj
end

function RAVIPDataManager.getVIPUpgradeNeedPointByLevel(l)
	local currVIPConfig=RAVIPDataManager.getVIPConfigByLevel(l)
	if currVIPConfig~=nil then
		if l==RAVIPDataManager.getMaxVIPLevel() then
			return currVIPConfig.point
		else
			local nextVIPConfig=RAVIPDataManager.getVIPConfigByLevel(l+1)
			if nextVIPConfig~=nil then
				return nextVIPConfig.point
			end	
		end
		return currVIPConfig.point
	else
		return 0
	end
end

function RAVIPDataManager.getVIPAttrConfig()
	if VIPAttrConfig==nil then
		local vip_attr_conf = RARequire("vip_attr_conf")
		local obj=Utilitys.deepCopy(vip_attr_conf)
		table.sort(obj,RAVIPDataManager.configAttrOrderSort)
		VIPAttrConfig=obj
	end
	return VIPAttrConfig
end

function RAVIPDataManager.getPlayerData()
	return RAPlayerInfoManager.getPlayerBasicInfo()
end

--Ë­¿´µ½Õâ¸öÒ»¶¨»áÍÂ²Û£¬
function RAVIPDataManager.getVIPToolsData()
	-- body
	local data = {}
	for k,v in pairs(item_conf) do
		local fb = v.functionBlock
		if nil ~= fb and (fb == RAVIPDataManager.Object.VIPToolsPointType or fb == RAVIPDataManager.Object.VIPToolsActiveType) then
			local item = RACoreDataManager:getItemInfoByItemId(v.id)
			if nil ~= item and nil ~= item.server then
				table.insert(data, item)
			else
				if v.isSellable~=RAVIPDataManager.Object.BuyDisabled then
					local obj = {}
					obj.conf=v
					table.insert(data, obj)
				end
			end
		end
	end
	
	table.sort( data,configOrderSort)
	return data
end

function RAVIPDataManager.getVIPConfigValueSymbol(config,v)
	local value=""
	local kv=config[v.columnName]
	if v.openOrClose~=nil and v.openOrClose==1 then
		if kv~=nil and tonumber(kv)==0 then
			value=_RALang("@VIPAttrValueAdditionClose")
		else
			value=_RALang("@VIPAttrValueAdditionOpen")
		end	
	else
		if v.symbol~=nil then
			value=_RALang(v.symbol,tostring(kv/100))
		end
	end

	return value
end

---------------------
function RAVIPDataManager.getShopConfByItemId(id)
	local obj=nil
	local shop_conf     = RARequire("shop_conf")
	obj=shop_conf[id]
	--³¬¼¶Ôã¸â£¬ÎªÊ²Ã´ÕâÃ´Éè¼Æ±í½á¹¹£¬ÐÔÄÜÄØ£¿
	if obj==nil then
		for k,v in pairs(shop_conf) do
			if v.shopItemID==id then
				obj=v
				break
			end
		end
	end
	return obj
end

--¶àÃ´Éµ±ÆµÄ·â×°--¡£Ô¤¼Æ³öÒòÎª¶Ñµþ³öÎÊÌâ£¬µ«ÊÇÄ¿Ç°Ã»ÓÐÄÃµ½uuid²»Í¬µÄÏêÏ¸¹æÔò
function RAVIPDataManager.getItemServerByItemId(id)
	local obj=nil
	obj=RACoreDataManager:getItemInfoByItemId(id)
	local serverItem={count=0}
	for _,v in pairs(obj.server) do
		serverItem.count = serverItem.count + tonumber(v.count)
		serverItem.uuid=v.uuid
		serverItem.isNew=v.isNew
    end
	return serverItem
end

--ÖØÖÃÊý¾Ý
function RAVIPDataManager.resetData()
	
end

return RAVIPDataManager
