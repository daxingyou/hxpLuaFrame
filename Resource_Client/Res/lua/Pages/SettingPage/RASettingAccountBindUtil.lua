local RAGameConfig = RARequire("RAGameConfig")

local RASettingAccountBindUtil = {
	
	----根据平台id，获得平台绑定的url
	getPlatformUrlById = function (self,platformId)
		------ TODO 目前只有facebook
		local bindUrl, switchUrl
		
		if platformId == 4 then  --Navercate
			bindUrl = RAGameConfig.BINDACCOUNT_TYPE.bindFb
			switchUrl = RAGameConfig.BINDACCOUNT_TYPE.bindFb
		elseif platformId == 6 then  --appstore
			bindUrl = RAGameConfig.BINDACCOUNT_TYPE.bindFb
			switchUrl = RAGameConfig.BINDACCOUNT_TYPE.switchFb
		elseif platformId == 11 then  --微信
			bindUrl = RAGameConfig.BINDACCOUNT_TYPE.bindFb
			switchUrl = RAGameConfig.BINDACCOUNT_TYPE.switchFb
		elseif platformId == 12 then  --QQ
			bindUrl = RAGameConfig.BINDACCOUNT_TYPE.bindFb
			switchUrl = RAGameConfig.BINDACCOUNT_TYPE.switchFb
		elseif platformId == 13 then  --新浪登陆
			bindUrl = RAGameConfig.BINDACCOUNT_TYPE.bindSina
			switchUrl = RAGameConfig.BINDACCOUNT_TYPE.switchSina
		elseif platformId == 14 then  --GameCenter登陆
			bindUrl = RAGameConfig.BINDACCOUNT_TYPE.bindFb
			switchUrl = RAGameConfig.BINDACCOUNT_TYPE.switchFb
		elseif platformId == 15 then  --FaceBook
			bindUrl = RAGameConfig.BINDACCOUNT_TYPE.bindFb
			switchUrl = RAGameConfig.BINDACCOUNT_TYPE.switchFb
		elseif platformId == 16 then  --Google
			bindUrl = RAGameConfig.BINDACCOUNT_TYPE.bindGooglePlay
			switchUrl = RAGameConfig.BINDACCOUNT_TYPE.switchGooglePlay	
		end

		return bindUrl or "", switchUrl or ""
	end,

	getPlatformIsBindById = function ( self,bindInfo, platformId )
		-- body

		local result = false
		if bindInfo then
			for i,user in ipairs(bindInfo.users or {}) do
				RALogRelease("RASettingAccountBindUtil:getPlatformIsBindById is thirdPlatform :"..user.thirdPlatform..",platformId: "..platformId)
				if user.thirdPlatform and tonumber(user.thirdPlatform) == tonumber(platformId) then
					result = true
					break 
				end
			end
			if result then
				RALogRelease("RASettingAccountBindUtil:getPlatformIsBindById is result true")
			end
		end
		return result
	end
}
return RASettingAccountBindUtil