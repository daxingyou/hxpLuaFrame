--region *.lua
--Date
--此文件由[BabeLua]插件自动生成

local RASysPushHandler = {}

local HP_pb = RARequire('HP_pb')
local RARootManager = RARequire('RARootManager')


function RASysPushHandler:onReceivePacket(handler)
    local SysProtocol_pb = RARequire('SysProtocol_pb')
    local pbCode = handler:getOpcode()
    local buffer = handler:getBuffer()

    if pbCode == HP_pb.HEART_BEAT then
		local msg = SysProtocol_pb.HPHeartBeat()
		msg:ParseFromString(buffer)
        self:_onHeartBeat(msg) 
        return
    end

    if pbCode == HP_pb.ERROR_CODE then
		local msg = SysProtocol_pb.HPErrorCode()
		msg:ParseFromString(buffer)
        self:_onErrorCode(msg) 
        return
    end

    if pbCode == HP_pb.OPERATE_SUCCESS then
		local msg = SysProtocol_pb.HPOperateSuccess()
		msg:ParseFromString(buffer)
        self:_onOperationOK(msg) 
        return
    end

    if pbCode == HP_pb.ASSEMBLE_FINISH_S then
        local Login_pb = RARequire("Login_pb")
        local msg = Login_pb.HPAssembleFinish()
        msg:ParseFromString(buffer)
        RASysPushHandler:_setRandomXorMask(msg)
        MessageManager.sendMessage(MessageDef_LOGIN.MSG_LoginSuccess)
        return
    end

    if pbCode == HP_pb.PLAYER_KICKOUT_S then
        --send login command
        local Login_pb = RARequire("Login_pb")
        local msg = Login_pb.HPPlayerKickout()
		msg:ParseFromString(buffer)
        local errorCode = msg.reason
        local RAStringUtil = RARequire("RAStringUtil")
        local resultFun = function (isOK)
           
        end
        local confirmData =
        {
            labelText = RAStringUtil:getErrorString(errorCode),
            resultFun = resultFun
        }
        RARootManager.showConfirmMsg(confirmData)
        performWithDelay(RARootManager.ccbfile,function()
            local RALoginManager = RARequire("RALoginManager")
            RALoginManager:goLoginAgain()
        end,1.0)
        
        --被踢出的时候要移除一下，否则新手期被踢出的时候会有问题
        RARootManager.RemoveGuidePage()
        RARootManager.RemoveCoverPage()

        return
    end

    
end

function RASysPushHandler:_onHeartBeat(msg)
    if msg:HasField('timeStamp') then
        local RAPlayerInfoManager = RARequire('RAPlayerInfoManager')
        RAPlayerInfoManager.SetServerTime(msg.timeStamp)
    end
end


function RASysPushHandler:_onOperationOK(msg)
    if msg.hpCode ~= nil then
        local hpCode = msg.hpCode
        MessageManager.sendMessage(MessageDef_Packet.MSG_Operation_OK, {opcode = hpCode})
        self:codeOKShowMsgBox(msg.hpCode)
    end
end

local notShowErrorCodeTable = {}
notShowErrorCodeTable[#notShowErrorCodeTable+1] = HP_pb.GUILDMANAGER_CHECKNAME_C
notShowErrorCodeTable[#notShowErrorCodeTable+1] = HP_pb.GUILDMANAGER_CHECKTAG_C

function RASysPushHandler:_onErrorCode(msg)
    local errFlag = msg.errFlag or 0
    PacketManager:getInstance():cancelWaiting(msg.hpCode)
    RARootManager.RemoveWaitingPage()
    if errFlag == 0 then
        if msg.errCode == 0 then
            MessageManager.sendMessage(MessageDef_Packet.MSG_Operation_OK, {opcode = msg.hpCode})
            self:codeOKShowMsgBox(msg.hpCode)
        else

            local isNotShow = false 
            for k,v in pairs(notShowErrorCodeTable) do
                if v == msg.hpCode then 
                    isNotShow = true 
                    break
                end 
            end

            if isNotShow == false then 
                RARootManager.showErrorCode(msg.errCode)
            end 
            self:failHandler(msg.hpCode)
            MessageManager.sendMessage(MessageDef_Packet.MSG_Operation_Fail, {opcode = msg.hpCode,errCode = msg.errCode})
        end
    elseif errFlag == 1 then
        local RAStringUtil = RARequire("RAStringUtil")
        local errorStr = RAStringUtil:getErrorString(msg.errCode)
        CCMessageBox(errorStr,_RALang("@hint"))
    elseif errFlag == 2 then

    end
end

--只要成功就show的放在这里
function RASysPushHandler:codeOKShowMsgBox(opcode)
    -- body
    if opcode == HP_pb.BUY_AND_USE_C then 
        --todo
        RARootManager.ShowMsgBox('@useSuccessful')
    elseif opcode == HP_pb.QUEUE_SPEED_UP_C then 
        RARootManager.RemoveWaitingPage()
    elseif opcode == HP_pb.FIRE_SOLDIER_C then
        MessageManager.sendMessage(MessageDef_FireSoldier.MSG_RATroopsInfoUpdate)
        MessageManager.sendMessage(MessageDef_FireSoldier.MSG_RAArmyDetailsPopUpUpdate)
    end 
end

--只要成功就show的放在这里
function RASysPushHandler:failHandler(opcode)
    -- body
    if opcode == HP_pb.GET_NUCLEAR_INFO_S then 
        local RAAllianceManager = RARequire('RAAllianceManager')
        RAAllianceManager:removeHandler()
    end 
end


function RASysPushHandler:_setRandomXorMask(msg)
    if msg:HasField('token') then
        local Utilitys = RARequire("Utilitys")
        local tokenList = Utilitys.Split(msg.token, ",")
        PacketManager:getInstance():clearXorMask()
        for _, mask in pairs(tokenList) do
            local iMask = tonumber(mask)
            PacketManager:getInstance():addXorMask(iMask)
        end
    end
end

return RASysPushHandler

--endregion