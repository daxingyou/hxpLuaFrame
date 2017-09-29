RARequire('extern')

local RASettingAccountBindInfo = class('RASettingAccountBindInfo',{
		youaiId = "",
		hasBinds = false,
		result = false,
		resultCode = 0,
		url = "",
		thirdId = "",
		thirdUserName = "",
		thirdPlatform = "",
		userType = "",
		name = "",
		users = {},
})

--根据PB初始化数据
function RASettingAccountBindInfo:initByJson(jsonData)
	-- obj.put("resulData", response.getData());
	-- obj.put("url", url);
	-- obj.put("users", users);
	-- obj.put("hasBinds", hasBinds);
	-- obj.put("result", result);
	-- obj.put("resultCode", resultCode);

	RALogRelease("RASettingAccountBindInfo:initByJson is jsonData :"..jsonData)

	local jsonDataObj = cjson.decode(jsonData)	

	local resulData = jsonDataObj.resulData or ""
	self.url = jsonDataObj.url or ""
	local users = jsonDataObj.users or ""
	self.hasBinds = jsonDataObj.hasBinds or false
	self.result = jsonDataObj.result or false
	self.resultCode = jsonDataObj.resultCode or 0

	RALogRelease("RASettingAccountBindInfo:initByJson is resulData :"..resulData)
	RALogRelease("RASettingAccountBindInfo:initByJson is url :"..self.url)
	RALogRelease("RASettingAccountBindInfo:initByJson is users :"..users)
	--RALogRelease("RASettingAccountBindInfo:initByJson is hasBinds :"..self.hasBinds)
	--RALogRelease("RASettingAccountBindInfo:initByJson is result :"..self.result)
	RALogRelease("RASettingAccountBindInfo:initByJson is resultCode :"..self.resultCode)

	local obj = cjson.decode(resulData)	

	if obj.youaiId then
		self.youaiId = obj.youaiId
	end

	if self.hasBinds then
		RALogRelease("RASettingAccountBindInfo:initByJson is has_binds value true")
	end

	 
	if users ~= "" and users ~= nil then
		local usersObj = cjson.decode(users)

		for k,v in pairs(usersObj) do
			
			local user = {}
			if v.youaiId then
				user.youaiId = v.youaiId
			end
			
			if v.thirdId then
				user.thirdId = v.thirdId
			end
			
			if v.thirdUserName then
				user.thirdUserName = v.thirdUserName
			end
			
			if v.thirdPlatform then
				user.thirdPlatform = v.thirdPlatform
			end
			
			if v.userType then
				user.userType = v.userType 
			end
			
			if v.name then
				user.name = v.name
			end

			self.users[#self.users + 1] = user
		end
	end

	for i,user in ipairs(self.users or {}) do
		if user.youaiId then
			RALogRelease("RASettingAccountBindInfo:initByJson is youaiId"..i.." :"..user.youaiId or "")
		end
		if user.thirdId then	
			RALogRelease("RASettingAccountBindInfo:initByJson is thirdId "..i..":"..user.thirdId or "")
		end
		if user.thirdUserName then		
			RALogRelease("RASettingAccountBindInfo:initByJson is thirdUserName "..i..":"..user.thirdUserName or "")
		end
		if user.thirdPlatform then		
			RALogRelease("RASettingAccountBindInfo:initByJson is thirdPlatform "..i..":"..user.thirdPlatform or "")
		end
		if user.userType then		
			RALogRelease("RASettingAccountBindInfo:initByJson is userType "..i..":"..user.userType or "")
		end
		if user.name then	
			RALogRelease("RASettingAccountBindInfo:initByJson is name "..i..":"..user.name or "")
		end
	end
end

function RASettingAccountBindInfo:ctor(...)
	self.users = {}
end 

return RASettingAccountBindInfo