--[[
	desc: 	关卡协议处理类
	author: royhu
	date: 	2016-12-27
]]--

local HP_pb = RARequire('HP_pb')
local protoIds =
{
	HP_pb.PVE_FETCH_ALL_CHAPTER_INFO_S,
	HP_pb.PVE_FETCH_ONE_CHAPTER_INFO_S
}

local RANetUtil = RARequire('RANetUtil')
local Dungeon_pb = RARequire('Dungeon_pb')

local RADungeonHandler = 
{
	handlers = nil,

	registerPacketListener = function(self)
		if self.handlers == nil then
		    self.handlers = RANetUtil:addListener(protoIds, self)
		end
	end,

	removePacketListener = function(self)
		if self.handlers then
		    RANetUtil:removeListener(self.handlers)
		    self.handlers = nil
		end
	end,

	onReceivePacket = function(self, handler)
	    local pbCode = handler:getOpcode()
	    local buffer = handler:getBuffer()
	    local RADungeonManager = RARequire('RADungeonManager')

	    -- 关卡推送
	    if pbCode == HP_pb.PUSH_PVE_ONE_PART_INFO then
	        local msg = Dungeon_pb.PushOnePartInfo()
	        msg:ParseFromString(buffer)
	        RADungeonManager:SyncDungeonInfo(msg.partData)
	        MessageManager.sendMessageInstant(MessageDefine_PVE.MSG_Sync_ChapterPartsInfo)
	        return
	    end

	    if pbCode == HP_pb.PVE_FETCH_ALL_CHAPTER_INFO_S then
			local msg = Dungeon_pb.FetchAllChapterResp()
			msg:ParseFromString(buffer)
	        RADungeonManager:SyncChapterInfos(msg)
	        MessageManager.sendMessageInstant(MessageDefine_PVE.MSG_Sync_AllChapterInfo)
	        return
	    end

	    if pbCode == HP_pb.PVE_FETCH_ONE_CHAPTER_INFO_S then
	        local msg = Dungeon_pb.FetchOneChapterResp()
	        msg:ParseFromString(buffer)
	        for _, part in ipairs(msg.parts) do
	        	RADungeonManager:SyncDungeonInfo(part)
	        end
	        MessageManager.sendMessageInstant(MessageDefine_PVE.MSG_Sync_ChapterPartsInfo)
	        return
	    end



	end,

	sendFetchAllChapterReq = function(self)
		RANetUtil:sendPacket(HP_pb.PVE_FETCH_ALL_CHAPTER_INFO_C)
	end,

	sendFetchOneChapterReq = function(self, chapterId)
		local msg = Dungeon_pb.FetchOneChapterReq()
		msg.chapterId = chapterId
		RANetUtil:sendPacket(HP_pb.PVE_FETCH_ONE_CHAPTER_INFO_C, msg)
	end,

	sendAttackDungeonReq = function(self, dungeonId, isSwap, swapTimes)
		local msg = Dungeon_pb.AttackDungeonReq()
		msg.dungeonId = dungeonId
		msg.isSwap = isSwap == true
		if swapTimes then
			msg.swapTimes = swapTimes
		end
		RANetUtil:sendPacket(HP_pb.PVE_ATTACK_C, msg)
	end
}

return RADungeonHandler