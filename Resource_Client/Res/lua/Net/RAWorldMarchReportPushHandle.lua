--region *.lua
--Date
--此文件由[BabeLua]插件自动生成

local RAWorldMarchReportPushHandle = {}

function RAWorldMarchReportPushHandle:onReceivePacket(handler)
	local HP_pb = RARequire("HP_pb")
	local World_pb = RARequire("World_pb")
	local RARadarManage=RARequire("RARadarManage")
	RARequire("MessageDefine")
	RARequire("MessageManager")

	
    local pbCode = handler:getOpcode()
    local buffer = handler:getBuffer()
    if pbCode == HP_pb.WORLD_MARCH_REPORT_PUSH then  --行军报告推送，根据类型判断
		local msg = World_pb.MarchReportPB()
		msg:ParseFromString(buffer)
		local marchData=nil
		local isAttack = true
		local uuid=""
		if msg:HasField('attackReport') then
			marchData=msg.attackReport
			uuid = marchData.marchUUID
			
		elseif msg:HasField('assistantReport') then
			marchData=msg.assistantReport
			uuid = marchData.marchUUID
			isAttack =false
		elseif msg:HasField('nuclearExplosionInfo') then        --超级武器（核弹/雷暴）
			marchData=msg.nuclearExplosionInfo 
			uuid=marchData.bombId
			isAttack =false
		end 
		local targetType=msg.targetType
		local isExist=msg.existQuarteredMarch 
		RARadarManage:addRadarDatas(uuid,marchData,isAttack,targetType,isExist)
		MessageManager.sendMessage(MessageDef_Radar.MSG_ADD)

    elseif pbCode == HP_pb.WORLD_MARCH_END_PUSH then --行军到达和行军返回
    	local msg = World_pb.WorldMarchRefreshPB()
		msg:ParseFromString(buffer)
		local marchData=msg
		local marchUuid =marchData.marchId
        RARadarManage:deleteRadarDatas(marchUuid)

        --这里改成立刻删除，当集结结束时服务器会推删除以及添加新的行军信息
        MessageManager.sendMessageInstant(MessageDef_Radar.MSG_DELETE) 
        

    --行军加速监听
    elseif pbCode == HP_pb.WORLD_MARCH_REFRESH_PUSH then  --行军加速
    	local msg = World_pb.WorldMarchRefreshPB()
		msg:ParseFromString(buffer)
		local marchData=msg
		local marchUuid =marchData.marchId
		local marchEndTime=marchData.endTime
		RARadarManage:updateRadarDatas(marchUuid,marchEndTime)
		MessageManager.sendMessage(MessageDef_Radar.MSG_UPDATE)
    end
end

return RAWorldMarchReportPushHandle

--endregion
