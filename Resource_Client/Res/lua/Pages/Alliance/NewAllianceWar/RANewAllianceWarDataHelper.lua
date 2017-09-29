--RANewAllianceWarDataHelper.lua
--联盟战争数据
local Const_pb = RARequire("Const_pb")
local GuildWar_pb = RARequire("GuildWar_pb")
local common = RARequire("common")
local Utilitys = RARequire("Utilitys")



--GuildWarShowPB -->  data
--单个Cell中的一个己方条目的数据
local GuildWarShowData = {
	New = function(self, o)
        local o = o or {}
        setmetatable(o,self)
        self.__index = self        
        o.playerId = ''
        o.playerName = ''
        o.iconId = 0
        o.marchData = nil
        o.armys = nil
        o.armyCount = 0
        return o
    end,
    InitByPb = function(self, pb)
    	if pb == nil then return end
    	local RAMarchDataHelper = RARequire('RAMarchDataHelper')
    	self.playerId = pb.playerId
    	self.playerName = pb.playerName
    	self.iconId = pb.iconId
    	self.marchData = nil    	
    	if pb:HasField("marchData") then
    		self.marchData = RAMarchDataHelper:CreateMarchData(pb.marchData)
    	end
        self.armyCount = 0
    	self.armys = {}
        for _, v in ipairs(pb.armys) do
            if v ~= nil then
                local amryInfo = 
                {
                    armyId = v.armyId,
                    count = v.count
                }
                table.insert(self.armys, amryInfo)                
                self.armyCount = self.armyCount + v.count
            end
        end
        Utilitys.tableSortByKeyReverse(self.armys, 'armyId')
    end,

    GetMarchId = function(self)
    	if self.marchData then
    		return self.marchData.marchId
    	end
    	return ''
    end,

    ResetData = function(self)
    	self.playerId = ''
    	self.playerName = ''
    	self.iconId = 0
    	self.marchData = nil 
    	self.armys = nil
        self.armyCount = 0
    end,

    GetShowDatas = function(self)
        -- 据点、堡垒的时候需要特殊处理
        local RAAllianceManager = RARequire('RAAllianceManager')
        local leaderGuildTag = RAAllianceManager:GetGuildTag()  
        -- 玩家的情况
        local RAPlayerInfoManager = RARequire('RAPlayerInfoManager')
        local headIcon = RAPlayerInfoManager.getHeadIcon(self.iconId)
        local targetName = self.playerName               
        if leaderGuildTag ~= '' then
            targetName = _RALang('@GuildTagWithName', leaderGuildTag, targetName)
        end
        return headIcon, targetName
    end,

    -- 获取军队数据
    GetArmyInfo = function(self)
        return self.armys, self.armyCount
    end,
    -- 获取行军状态显示字符串
    GetMarchShowStatus = function(self)
        local str = ''
        local isUpdate = true
        local status = self.marchData.marchStatus
        if status == World_pb.MARCH_STATUS_WAITING or
            status == World_pb.MARCH_STATUS_MARCH_ASSIST then --集结,援助等待状态
            str = _RALang("@CompleteSetTxtStatus"..status)
            isUpdate = false
        else
            local curTime = common:getCurTime()
            local timeStamp = math.ceil(self.marchData.endTime/1000 - curTime)
            local timeStr = Utilitys.createTimeWithFormat(timeStamp)
            str = _RALang("@AssemblyInTxt")..timeStr
        end
        return str, isUpdate
    end
}


--GuildWarTeamPB -->  data
--单个Cell中的己方数据
local GuildWarTeamData = {
	New = function(self, o)
        local o = o or {}
        setmetatable(o,self)
        self.__index = self        
        o.leaderMarch = nil
        o.joinMarchs = nil
        o.pointType = -1
        o.x = -1
        o.y = -1
        o.leaderIconId = -1
        o.leaderArmyLimit = 0
        o.buyItemTimes = 0
        return o
    end,

    InitByPb = function(self, pb)
    	if pb == nil then return end
    	
        self.pointType = pb.pointType
        self.x = pb.x
        self.y = pb.y
        self.leaderIconId = pb.leaderIconId

    	self.leaderMarch = GuildWarShowData:New()
    	self.leaderMarch:InitByPb(pb.leaderMarch)

    	self.joinMarchs = {}
    	for _,v in ipairs(pb.joinMarchs) do
            if v ~= nil then
            	self:AddJoinMarch(v)
            end           
       end
       self.leaderArmyLimit = pb.leaderArmyLimit
       self.buyItemTimes = pb.buyItemTimes
    end,

    --pb = showPb
    AddJoinMarch = function(self, pb)
        if self.joinMarchs == nil then self.joinMarchs = {} end
        local marchId = pb.marchData.marchId
        local oneMarch = self.joinMarchs[marchId]
        if oneMarch == nil then
            oneMarch = GuildWarShowData:New()
        end
        oneMarch:InitByPb(pb)
        self.joinMarchs[marchId] = oneMarch
    end,

    -- 获取排序后的id列表
    GetSortedJoinedMarhIdList = function(self)
        local result = {}
        if self.joinMarchs ~= nil then
            local marchReachIdMap = {}
            local marchingIdMap = {}
            for k,v in pairs(self.joinMarchs) do
                local marchData = v.marchData
                local marchId = v:GetMarchId()
                local startTime = marchData.startTime
                local endTime = marchData.endTime
                local oneIdData = {
                    marchId = marchId,
                    startTime = startTime,
                    endTime = endTime,
                }
                -- 行军状态
                if marchData.marchStatus == World_pb.MARCH_STATUS_MARCH then
                    table.insert(marchingIdMap, oneIdData)
                else
                    table.insert(marchReachIdMap, oneIdData)
                end
            end
            -- 到达了的队伍，后到达的在前面，所以endTime越大越靠前
            Utilitys.tableSortByKeyReverse(marchReachIdMap, 'endTime')
            -- 未抵达的队伍，后出发的在前面，所以startTime越大越靠前
            Utilitys.tableSortByKeyReverse(marchingIdMap, 'startTime')

            for i=1, #marchReachIdMap do
                table.insert(result, marchReachIdMap[i])
            end
            for i=1, #marchingIdMap do
                table.insert(result, marchingIdMap[i])
            end
        end
        return result
    end,

    ResetData = function(self)
    	self.leaderMarch = nil
        self.joinMarchs = nil
        self.pointType = -1
        self.x = -1
        self.y = -1
        self.leaderIconId = -1
        self.leaderArmyLimit = 0
        self.buyItemTimes = 0 
    end,

    GetJoinedArmyCount = function(self)
        local totalCount = 0
        if self.leaderMarch ~= nil then
            totalCount = totalCount + self.leaderMarch.armyCount
        end
        for k,v in pairs(self.joinMarchs) do
            totalCount = totalCount + v.armyCount
        end
        return totalCount
    end,

    GetShowDatas = function(self)
        -- 据点、堡垒的时候需要特殊处理
        local RAAllianceManager = RARequire('RAAllianceManager')
        local leaderGuildTag = RAAllianceManager:GetGuildTag()  
        -- 据点时候需要特殊处理                
        if self.pointType == World_pb.GUILD_GUARD then
            local territory_guard_conf = RARequire('territory_guard_conf')
            local guardCfg = territory_guard_conf[self.leaderIconId]
            if guardCfg ~= nil then                
                local targetName = _RALang(guardCfg.armyName)                
                if self.guildTag ~= '' then
                    targetName = _RALang('@GuildTagWithName', leaderGuildTag, targetName)
                end
                return guardCfg.icon, targetName
            end
        -- 堡垒、领地点的时候需要特殊处理                
        elseif self.pointType == World_pb.GUILD_TERRITORY or
            self.pointType == World_pb.MOVEABLE_BUILDING then
            local territory_building_conf = RARequire('territory_building_conf')
            local territoryCfg = territory_building_conf[self.leaderIconId]
            if territoryCfg ~= nil then                
                local targetName = _RALang(territoryCfg.name)                
                if self.guildTag ~= '' then
                    targetName = _RALang('@GuildTagWithName', leaderGuildTag, targetName)
                end
                return territoryCfg.icon, targetName
            end
        elseif self.pointType == World_pb.KING_PALACE then
            -- 王座特殊处理
            local RAWorldConfig = RARequire('RAWorldConfig')
            local kingIcon = RAWorldConfig.Capital.Icon
            local kingName = _RALang(RAWorldConfig.Capital.Name)
            return kingIcon, kingName
        else
            -- 玩家的情况
            local RAPlayerInfoManager = RARequire('RAPlayerInfoManager')
            local headIcon = RAPlayerInfoManager.getHeadIcon(self.leaderIconId)
            local targetName = self.leaderMarch.playerName               
            if leaderGuildTag ~= '' then
                targetName = _RALang('@GuildTagWithName', leaderGuildTag, targetName)
            end
            return headIcon, targetName
        end
    end,
}



--GuildWarSinglePB -->  data
--单个Cell中的对方数据
local GuildWarSingleData = {
	New = function(self, o)
        local o = o or {}
        setmetatable(o,self)
        self.__index = self        
        o.playerName = ''
        o.guildTag = ''
        o.x = -1
        o.y = -1
        o.pointType = -1
        o.iconId = -1 
        o.endTime = 0       
        o.marchStatus = -1
        return o
    end,

    InitByPb = function(self, pb)
    	if pb == nil then return end    	
    	self.playerName = pb.playerName
        self.guildTag = pb.guildTag
        self.x = pb.x
        self.y = pb.y
        self.pointType = pb.pointType
        self.iconId = pb.iconId
        self.endTime = pb.endTime
        self.marchStatus = pb.marchStatus
    end,

    ResetData = function(self)
    	self.playerName = ''
        self.guildTag = ''
        self.x = -1
        self.y = -1
        self.pointType = -1
        self.iconId = -1      
        self.endTime = 0
        self.marchStatus = -1
    end,

    GetShowDatas = function(self)
        -- 据点时候需要特殊处理                
        if self.pointType == World_pb.GUILD_GUARD then
            local territory_guard_conf = RARequire('territory_guard_conf')
            local guardCfg = territory_guard_conf[self.iconId]
            if guardCfg ~= nil then                
                local targetName = _RALang(guardCfg.armyName)                
                if self.guildTag ~= '' then
                    targetName = _RALang('@GuildTagWithName', self.guildTag, targetName)
                end
                return guardCfg.icon, targetName
            end
        -- 堡垒、领地点的时候需要特殊处理                
        elseif self.pointType == World_pb.GUILD_TERRITORY or
            self.pointType == World_pb.MOVEABLE_BUILDING then
            local territory_building_conf = RARequire('territory_building_conf')
            local territoryCfg = territory_building_conf[self.iconId]
            if territoryCfg ~= nil then                
                local targetName = _RALang(territoryCfg.name)                
                if self.guildTag ~= '' then
                    targetName = _RALang('@GuildTagWithName', self.guildTag, targetName)
                end
                return territoryCfg.icon, targetName
            end
        elseif self.pointType == World_pb.KING_PALACE then
            -- 王座特殊处理
            local RAWorldConfig = RARequire('RAWorldConfig')
            local kingIcon = RAWorldConfig.Capital.Icon
            local kingName = _RALang(RAWorldConfig.Capital.Name)
            return kingIcon, kingName

        elseif self.pointType == World_pb.MONSTER then
            -- 集结打野怪处理
            local RAWorldConfigManager = RARequire('RAWorldConfigManager')
            local monsterCfg = RAWorldConfigManager:GetMonsterConfig(self.iconId)
            if monsterCfg ~= nil then 
                local monsterTitle = _RALang(monsterCfg.name)
                monsterTitle = _RALang('@NameWithLevelTwoParams', monsterTitle, monsterCfg.level)
                local monsterPic = monsterCfg.show
                return monsterPic, monsterTitle
            end
        else
            -- 玩家的情况
            local RAPlayerInfoManager = RARequire('RAPlayerInfoManager')
            local headIcon = RAPlayerInfoManager.getHeadIcon(self.iconId)
            local targetName = self.playerName              
            if self.guildTag ~= '' then
                targetName = _RALang('@GuildTagWithName', self.guildTag, targetName)
            end
            return headIcon, targetName
        end
    end,
}



--GuildWarOneCellPB -->  data
--单个Cell数据
local GuildWarOneCellData = {
	New = function(self, o)
        local o = o or {}
        setmetatable(o,self)
        self.__index = self        
        o.cellMarchId = ''
        o.selfInfo = nil
        o.targetInfo = nil
        o.showType = -1           
        return o
    end,

    InitByPb = function(self, pb)
    	if pb == nil then return end    	
    	self.cellMarchId = pb.cellMarchId

        self.selfInfo = GuildWarTeamData:New()
        self.selfInfo:InitByPb(pb.selfInfo)

        self.targetInfo = GuildWarSingleData:New()
        self.targetInfo:InitByPb(pb.targetInfo)

        self.showType = pb.showType  
    end,

    ResetData = function(self)
    	self.cellMarchId = ''
        self.selfInfo = nil
        self.targetInfo = nil
        self.showType = -1     
    end,
}


local RANewAllianceWarDataHelper = {
}

------------------- 联盟战争数据 -------------------
-- msg = GuildWarOneCellPB
function RANewAllianceWarDataHelper:CreateOneCellData(msg)
    if msg == nil then return end
	local oneCell = GuildWarOneCellData:New()
	oneCell:InitByPb(msg)
	return oneCell
end

-- msg = PushGuildWarUpdate
function RANewAllianceWarDataHelper:UpdateSelfTeamItemData(oneCellData, msg)
    if msg == nil and oneCellData == nil and oneCellData.selfInfo ~= nil then return end
    local teamMarches = oneCellData.selfInfo
    if teamMarches.leaderMarch ~= nil then
    	if teamMarches.leaderMarch.playerId == msg.showPB.playerId then
    		teamMarches.leaderMarch:InitByPb(msg.showPB)
    		print('RANewAllianceWarDataHelper:UpdateSelfTeamItemData  update success')
            --可能需要刷新war page
            MessageManager.sendMessage(MessageDef_AllianceWar.MSG_NewAllianceWar_WarPage_Refresh, {showType = oneCellData.showType})
    		return
    	end
    end
	if teamMarches.joinMarchs ~= nil then
        local isHanlde = false
		for k,v in pairs(teamMarches.joinMarchs) do
			if v.playerId == msg.showPB.playerId and msg.cellMarchId == v:GetMarchId() then
				v:InitByPb(msg.showPB)
				print('RANewAllianceWarDataHelper:UpdateSelfTeamItemData  update success')
                isHanlde = true
			end
		end
        -- 如果原来没有的话，直接添加了
        if not isHanlde then
            teamMarches:AddJoinMarch(msg.showPB)
        end
	end
	print('RANewAllianceWarDataHelper:UpdateSelfTeamItemData  update failed')
    --刷新detail page
    MessageManager.sendMessage(MessageDef_AllianceWar.MSG_NewAllianceWar_DetailsPage_Refresh, {cellMarchId = oneCellData.cellMarchId})
end


-- msg = PushGuildWarDelCellItem
function RANewAllianceWarDataHelper:DeleteSelfTeamItemData(oneCellData, msg)
    if msg == nil and oneCellData == nil and oneCellData.selfInfo ~= nil then return end
    if msg.cellMarchId ~= oneCellData.cellMarchId then return end
    local teamMarches = oneCellData.selfInfo
    local isHanlde = false
	if teamMarches.joinMarchs ~= nil then
		for k,v in pairs(teamMarches.joinMarchs) do
			if v.playerId == msg.playerId and msg.marchId == v:GetMarchId() then				
				isHanlde = true
				break
			end
		end
	end
	if isHanlde then
		teamMarches.joinMarchs[msg.marchId] = nil
		print('RANewAllianceWarDataHelper:DeleteSelfTeamItemData  del success')
		return
	end
	print('RANewAllianceWarDataHelper:DeleteSelfTeamItemData  del failed')
end


------------------- 领地和首都战争数据 -------------------

-- msg = GuildWarTeamPB
function RANewAllianceWarDataHelper:CreateTeamData(msg)
    local teamData = GuildWarTeamData:New()
    teamData:InitByPb(msg)
    return teamData
end

-- msg = GuildWarShowPB
-- 调用的时候需要保证team data和msg是一组数据
-- 这需要领地和首都各自判断
function RANewAllianceWarDataHelper:UpdateTeamItemData(teamData, msg)
    if msg == nil and teamData == nil  then return end
    local marchId = msg.marchData.marchId
    if teamData.leaderMarch ~= nil then
        if teamData.leaderMarch.playerId == msg.playerId and teamData.leaderMarch:GetMarchId() == marchId then
            teamData.leaderMarch:InitByPb(msg)
            print('RANewAllianceWarDataHelper:UpdateTeamItemData  update success')
            return
        end
    end
    if teamData.joinMarchs ~= nil then
        local isHanlde = false
        for k,v in pairs(teamData.joinMarchs) do
            if v.playerId == msg.playerId and v:GetMarchId() == marchId then
                isHanlde = true
                break
            end
        end
        -- 如果原来没有的话，直接添加了
        if not isHanlde then
            teamData:AddJoinMarch(msg)
            return
        end
    end
    print('RANewAllianceWarDataHelper:UpdateTeamItemData  update failed')
end


-- 调用的时候需要保证team data和msg是一组数据
-- 这需要领地和首都各自判断
function RANewAllianceWarDataHelper:DeleteTeamItemData(teamData, marchId, playerId)
    if teamData == nil  then return end
    if teamData.joinMarchs ~= nil then
        local isHanlde = false
        for k,v in pairs(teamData.joinMarchs) do
            if v.playerId == playerId and v:GetMarchId() == marchId then
                isHanlde = true
            end
        end
        -- 删除
        if isHanlde then
            teamData.joinMarchs[marchId] = nil
            return
        end
    end
end



return RANewAllianceWarDataHelper