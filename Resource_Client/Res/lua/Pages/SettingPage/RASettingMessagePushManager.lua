local push_conf = RARequire("push_conf")

local RASettingMessagePushManager = {
	

	--get message push data
	getMessagePushData = function ( self )
		-- body
		local messagePushData = {}
		for k,v in pairs(push_conf) do
			messagePushData[v.type] = v
		end

		local t = {}
		for k,v in pairs(messagePushData) do
			local index = v.type / 10
			t[index] = v
		end

		messagePushData = {}
		messagePushData = t
		t = {}

		return messagePushData
	end,

	sendSysProtocol = function ( self, key, value)
		-- body
		local SysProtocol_pb = RARequire("SysProtocol_pb")
		local HP_pb = RARequire("HP_pb")
		local RANetUtil = RARequire("RANetUtil")

		local msg = SysProtocol_pb.HPCustomDataDefine()
        msg.data.key = key
        msg.data.arg = value
        RANetUtil:sendPacket(HP_pb.CUSTOM_DATA_DEFINE, msg, { retOpcode = - 1 }) 
	end,
}

return RASettingMessagePushManager