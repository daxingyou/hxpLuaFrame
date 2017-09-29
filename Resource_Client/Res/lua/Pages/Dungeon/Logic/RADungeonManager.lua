--[[
	desc: 	关卡数据管理类
	author: royhu
	date: 	2016-12-27
]]--

local dungeon_conf = nil
local dungeon_chapter_conf = nil
local Dungeon_pb = RARequire('Dungeon_pb')

local RADungeonManager =
{
	mIsReady = false,
	-- 章节idList
	mChapterIdList = nil,
	-- 章节对应关卡id列表
	mChapterDict = {},
	-- 用户章节状态等信息
	mUserChapterInfo = {},
	-- 用户关卡数据
	mUserDungeonInfo = {},
	-- 当前进度数据
	mUserProgressInfo =
	{
		chapterId 	= 1,
		partId 		= 1,
		dungeonId 	= 1001
	},

	reset = function(self)
		self.mIsReady = false
		self.mUserChapterInfo = {}
		self.mUserDungeonInfo = {}
		self.mUserProgressInfo =
		{
			chapterId 	= 1,
			partId 		= 1,
			dungeonId 	= 1001
		}
	end,

	GetChapterIdList = function(self)
		if self.mChapterIdList == nil then
			self:_loadChapterConfig()
			local ids = {}
			for k, _ in pairs(dungeon_chapter_conf) do
				table.insert(ids, k)
			end
			table.sort(ids)
			self.mChapterIdList = ids
		end
		return self.mChapterIdList
	end,

	GetChapterCfg = function(self, chapterId)
		self:_loadChapterConfig()
		return dungeon_chapter_conf[chapterId]
	end,

	GetChapterState = function(self, chapterId)
		local info = self.mUserChapterInfo[chapterId]
		if info then
			return info.state
		end

		if chapterId == self.mUserProgressInfo.chapterId then
			return Dungeon_pb.CHAPTER_STATE_EXECUTING
		else
			return Dungeon_pb.CHAPTER_STATE_LOCKED
		end
	end,

	-- 获取章节对应关卡id列表
	-- @return {[地图块id] = 关卡id}
	GetDungeonIdList = function(self, chapterId)
		local idList = self.mChapterDict[chapterId]
		if idList ~= nil then
			return idList
		end

		self:_loadDungeonConfig()
		idList = {}
		for id, cfg in pairs(dungeon_conf) do
			if cfg.chapterId == nil then
				local chapterId, partId = self:SplitDungeonId(cfg.dungeonId)
				cfg.chapterId = chapterId
				cfg.partId = partId
			end
			if cfg.chapterId == chapterId then
				idList[cfg.areaPos] = id
			end
		end
		self.mChapterDict[chapterId] = idList

		return idList
	end,

	GetDungeonCfg = function(self, dungeonId)
		self:_loadDungeonConfig()
		local cfg = dungeon_conf[dungeonId]
		if cfg and cfg.chapterId == nil then
			local chapterId, partId = self:SplitDungeonId(dungeonId)
			cfg.chapterId = chapterId
			cfg.partId = partId
		end
		return cfg
	end,

	GetDungeonId = function(self, chapterId, partId)
		return chapterId * 1000 + partId
	end,

	SplitDungeonId = function(self, dungeonId)
		return math.floor(dungeonId / 1000), dungeonId % 1000
	end,

	IsReady = function(self)
		return self.mIsReady
	end,

	GetDungeonState = function(self, dungeonId)
		if self.mUserDungeonInfo[dungeonId] then
			return Dungeon_pb.CHAPTER_STATE_PASSED
		end

		if dungeonId == self.mUserProgressInfo.dungeonId then
			return Dungeon_pb.CHAPTER_STATE_EXECUTING
		else
			return Dungeon_pb.CHAPTER_STATE_LOCKED
		end
	end,

	GetProgressInfo = function(self)
		return self.mUserProgressInfo
	end,

	IsExecuting = function(self, dungeonId)
		return dungeonId == self.mUserProgressInfo.dungeonId
	end,

	IsLastDungeonOfChapter = function(self, dungeonId)
		local chapterId, partId = self:SplitDungeonId(dungeonId)
		local idList = self:GetDungeonIdList(chapterId)
		for _, id in pairs(idList) do
			if id > dungeonId then return false end
		end
		return true
	end,

	SyncChapterInfos = function(self, msg)
		for _, info in ipairs(msg.chapters) do
			local chapterId = info.chapterId
			if self:_IsChapterExist(chapterId) then
				self.mUserChapterInfo[info.chapterId] =
				{
					state = info.state
				}

				if info.state == Dungeon_pb.CHAPTER_STATE_EXECUTING then
					if info.chapterId > self.mUserProgressInfo.chapterId then
						self:_changeChapterState(self.mUserProgressInfo.chapterId, Dungeon_pb.CHAPTER_STATE_PASSED)
						self.mUserProgressInfo.chapterId = info.chapterId
					end
					self:_setProgressDungeonId()
				elseif info.state == Dungeon_pb.CHAPTER_STATE_PASSED
					and info.chapterId >= self.mUserProgressInfo.chapterId
				then
					if self:_IsChapterExist(info.chapterId + 1) then
						self.mUserProgressInfo.chapterId = info.chapterId + 1
					else
						self.mUserProgressInfo.chapterId = info.chapterId
					end
					self:_setProgressDungeonId()
				end
			else
				RALogError('PVE Chapter not exist, id: ' .. chapterId)
			end
		end
		self.mIsReady = true
	end,

	SyncDungeonInfo = function(self, msg)
		self.mUserDungeonInfo[msg.dungeonId] =
		{
			count 	= msg.count,
			star 	= msg.star
		}
		local chapterId, partId = self:SplitDungeonId(msg.dungeonId)
		if chapterId == self.mUserProgressInfo.chapterId
			and partId >= self.mUserProgressInfo.partId
		then
			local dungeonId = self:GetDungeonId(chapterId, partId + 1)
			if self:GetDungeonCfg(dungeonId) then
				self.mUserProgressInfo.partId = partId + 1
			else
				dungeonId = self:GetDungeonId(chapterId + 1, 1)
				if self:GetDungeonCfg(dungeonId) then
					self.mUserProgressInfo.chapterId = chapterId + 1
					self.mUserProgressInfo.partId = 1
					self:_changeChapterState(chapterId, Dungeon_pb.CHAPTER_STATE_PASSED)
				else
					self.mUserProgressInfo.partId = partId
				end
			end
			self:_setProgressDungeonId()
		end
	end,

	_changeChapterState = function(self, chapterId, state)
		local info = self.mUserChapterInfo[chapterId] or {}
		info.state = state
		self.mUserChapterInfo[chapterId] = info
	end,

	_loadDungeonConfig = function(self)
		if dungeon_conf == nil then
			dungeon_conf = RARequire('dungeon_conf')
		end
	end,

	_loadChapterConfig = function()
		if dungeon_chapter_conf == nil then
			dungeon_chapter_conf = RARequire('dungeon_chapter_conf')
		end
	end,

	_setProgressDungeonId = function(self)
		local info = self.mUserProgressInfo
		info.dungeonId = self:GetDungeonId(info.chapterId, info.partId)
	end,

	_IsChapterExist = function(self, chapterId)
		local dungeonId = self:GetDungeonId(chapterId, 1)
		return self:GetDungeonCfg(dungeonId) ~= nil
	end
}

return RADungeonManager