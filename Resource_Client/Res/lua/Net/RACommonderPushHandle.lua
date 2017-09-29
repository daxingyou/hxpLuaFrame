--region *.lua
--Date
--此文件由[BabeLua]插件自动生成

--指挥官信息推送


local RACommonderPushHandle = {}

function RACommonderPushHandle:onReceivePacket(handler)
	local HP_pb = RARequire("HP_pb")
	local Commander_pb = RARequire("Commander_pb")
	local RACommandManage=RARequire("RACommandManage")
	RARequire("MessageDefine")
	RARequire("MessageManager")
	
    local pbCode = handler:getOpcode()
    local buffer = handler:getBuffer()
    if pbCode == HP_pb.PLAYER_COMMANDER_INFO_SYNC_S then  
		local msg = Commander_pb.HPCommanderInfoSync()
		msg:ParseFromString(buffer)
		local data=msg.cmdInfo

		local uuid=data.uuid
		local enemyId=data.enemyId
		local type=data.type
		local state=data.state
		local endTime=data.endTime


		local commander=RACommandManage:getCommanderData()
		if commander==nil then
			RACommandManage:addCommanderData(data)
		else
			RACommandManage:updateCommanderData(data)
		end 
		
		--刷新状态
		MessageManager.sendMessage(MessageDef_Commonder.MSG_State_Changed)

		--刷新主UI头像
		MessageManager.sendMessage(MessageDef_Lord.MSG_RefreshHeadImg)
		

	end

end

return RACommonderPushHandle

--endregion
