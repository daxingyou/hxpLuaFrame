--region *.lua
--Date
--此文件由[BabeLua]插件自动生成

local Utilitys=RARequire("Utilitys")
local RAPlayerInfoManager=RARequire("RAPlayerInfoManager")

local RAConfirmManager = {
	isShow = true,		-- 消耗钻石的时候是否弹框
	confirmSet={},
	deVicePath= CCFileUtils:sharedFileUtils():getWritablePath(),

	---- 0 打开 1关闭
}

RAConfirmManager.TYPE={
	UPGRADNOW 		= 1,		--立即升级
	CURENOW 		= 2,		--立即治疗
	TRAINNOW 		= 3,		--立即训练
	RECONSTRUCTNOW 	= 4,		--立即改建
	RESEARCHNOW 	= 5,		--立即研究
	BUYNOW 			= 6,		--立即购买
	REPAIRENOW 		= 7,		--立即修复
	GUIDEID			= 8,		--新手引导ID

}

RAConfirmManager.KEY={
	UPGRADNOW		= "option_buildingLevelUpConsume",				
	CURENOW			= "option_cureSoldierConsume"	,					
	TRAINNOW		= "option_trainSoldierConsume",					
	RECONSTRUCTNOW	= "option_buildingRebuildConsume",		
	RESEARCHNOW		= "option_researchConsume",			
	BUYNOW			= "option_shopConsume",	
	REPAIRENOW		= "option_buildingRepairConsume",
	GUIDEID			= "option_guide",
}

function RAConfirmManager:getKeyByType(type)
	local key=""
	if type==self.TYPE.UPGRADNOW then
		key = self.KEY.UPGRADNOW
	elseif type==self.TYPE.CURENOW then
		key = self.KEY.CURENOW
	elseif type==self.TYPE.TRAINNOW then
		key = self.KEY.TRAINNOW
	elseif type==self.TYPE.RECONSTRUCTNOW then
		key = self.KEY.RECONSTRUCTNOW
	elseif type==self.TYPE.RESEARCHNOW then
		key = self.KEY.RESEARCHNOW
	elseif type==self.TYPE.BUYNOW then
		key = self.KEY.BUYNOW
	elseif type==self.TYPE.REPAIRENOW then
		key = self.KEY.REPAIRENOW
	elseif type==self.TYPE.GUIDEID then
		key = self.KEY.GUIDEID
	end 
	return key
end

function RAConfirmManager:setShowConfirmDlog(isShow,type,pushKey)
	local isOpen = nil
	if isShow then
		isOpen = 1
	else
		isOpen = 0
	end

	local key = self:getKeyByType(type)
	--设置里面的开关，不传类型，直接传key过来
	if pushKey ~= nil then
		key = pushKey
	end
	
	local name=RAPlayerInfoManager.getPlayerId()
	self.confirmSet[key]=isOpen

	local path=self.deVicePath..name..".json"
	Utilitys.WriteJsonFile(path,self.confirmSet)
	self.isShow = isShow
end

function RAConfirmManager:setComfirmData()

	local name=RAPlayerInfoManager.getPlayerId()
	local path=self.deVicePath..name..".json"

	local parms=Utilitys.ReadJsonFile(path)
	if parms then
		self.confirmSet=parms
	end 	
end
function RAConfirmManager:getShowConfirmDlog(type, pushKey)

	local key = self:getKeyByType(type)

	if pushKey ~= nil then
		key = pushKey
	end

	local isOpen = self.confirmSet[key]

	if isOpen == 0  then
		self.isShow = false
	else
		self.isShow = true
	end 
	
	return self.isShow
end

function RAConfirmManager:setConfirmForKey(type,value)
	local key = self:getKeyByType(type)
	local name=RAPlayerInfoManager.getPlayerId()
	self.confirmSet[key]=value

	local path=CCFileUtils:sharedFileUtils():getWritablePath()..name..".json"
	Utilitys.WriteJsonFile(path,self.confirmSet)
end

function RAConfirmManager:getConfirmForKey(type)
	local key = self:getKeyByType(type)
	local name=RAPlayerInfoManager.getPlayerId()
	local path=CCFileUtils:sharedFileUtils():getWritablePath()..name..".json"

	CCLuaLog("RAConfirmManager:getConfirmForKey key================="..key)
	CCLuaLog("RAConfirmManager:getConfirmForKey name================="..name)
	CCLuaLog("RAConfirmManager:getConfirmForKey path================="..path)
	local value = Utilitys.ReadJsonFileByKey(path,key)
	return value
end

function RAConfirmManager:cancleConfirm(type)
	--这里不需要去设置了。因为点了取消不设置都是一样的不会改变存的值
	--local key = self:getKeyByType(type)
	--CCUserDefault:sharedUserDefault():setIntegerForKey(key, 1)
	--CCUserDefault:sharedUserDefault():flush()
end

function RAConfirmManager:reset()
	self.isShow = true

	for k,v in pairs(self.confirmSet) do
		v=nil
	end
	self.confirmSet={}
end
return RAConfirmManager

--endregion
