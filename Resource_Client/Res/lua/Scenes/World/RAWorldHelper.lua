--region *.lua
--Date

local RAWorldHelper = {}

local RARootManager = RARequire('RARootManager')
local RAWorldConfig = RARequire('RAWorldConfig')
local RAWorldProtoHandler = RARequire('RAWorldProtoHandler')
local HP_pb = RARequire('HP_pb')
local RAWorldManager = RARequire('RAWorldManager')
local RAWorldVar = RARequire('RAWorldVar')
local RAWorldUtil = RARequire('RAWorldUtil')

local msgTB =
{
    MessageDef_Packet.MSG_Operation_OK,
    MessageDef_Packet.MSG_Operation_Fail,

    MessageDef_World.MSG_UpdateMapArea,
    MessageDef_World.MSG_UpdateMapPosition,
    MessageDef_World.MSG_AddMarchHud,
    MessageDef_World.MSG_RemoveMarchHud,
    MessageDef_World.MSG_OpenMarchUseItemPage,
    MessageDef_World.MSG_CloseMarchUseItemPage,
    MessageDef_World.MSG_SwallowTouch,
    MessageDef_World.MSG_RefreshWorldPoints,
    MessageDef_World.MSG_SuperWeapon_Aiming,
    MessageDef_World.MSG_SuperWeapon_AimEnd,
    MessageDef_World.MSG_PresidentInfo_Update,
    MessageDef_World.MSG_CrossServerPresidentInfo_Update,
    MessageDef_World.MSG_LocateAtPos,

    MessageDef_LOGIN.MSG_LoginSuccess,

    MessageDef_Guide.MSG_Guide,

    MessageDef_Alliance.MSG_Alliance_Changed,
}

function RAWorldHelper:new()
	local o = {}
    setmetatable(o, self)
    self.__index = self
    return o
end

function RAWorldHelper:Enter()
	self:_registerMessageHandlers()
	RAWorldProtoHandler:registerPacketListener()
end

function RAWorldHelper:Exit()
	RAWorldProtoHandler:removePacketListener()
	self:_unregisterMessageHandlers()
end

function RAWorldHelper:_registerMessageHandlers()
    for _, msgId in ipairs(msgTB) do
        MessageManager.registerMessageHandler(msgId, self._onReceiveMessage)
    end
end

function RAWorldHelper:_unregisterMessageHandlers()
    for _, msgId in ipairs(msgTB) do
        MessageManager.removeMessageHandler(msgId, self._onReceiveMessage)
    end
end

function RAWorldHelper._onReceiveMessage(msg)
    local msgId = msg.messageID

    if msgId == MessageDef_Packet.MSG_Operation_OK then
    	if msg.opcode == HP_pb.LAUNCH_NUCLEAR_BOMB_C then
			local RAWorldUIManager = RARequire('RAWorldUIManager')
			RAWorldUIManager:OnTargetRsp(true)
    		return
    	end

        local tipKey = RAWorldConfig.OperationOkTip[msg.opcode]
        if tipKey then
            RARootManager.ShowMsgBox(tipKey)
        end
        return 
    end

    if msgId == MessageDef_Packet.MSG_Operation_Fail then
        if msg.opcode == HP_pb.WORLD_MOVE_CITY_C then
            RAWorldManager:onMigrateRsp(false, nil, true)
        elseif msg.opcode == HP_pb.LAUNCH_NUCLEAR_BOMB_C then
			local RAWorldUIManager = RARequire('RAWorldUIManager')
			RAWorldUIManager:OnTargetRsp(false)
        end
        return
    end

    if msgId == MessageDef_World.MSG_UpdateMapArea then
        local RAWorldBuildingManager = RARequire('RAWorldBuildingManager')
        RAWorldBuildingManager:UpdateDecorationList()
        return
    end

    if msgId == MessageDef_World.MSG_UpdateMapPosition then
        RAWorldManager:updateDirection()

        if RAWorldVar.AllowServerReq then
            local pos = RAWorldVar.MapPos.Map
            local center = RAWorldVar.MapPos.ServerCenter
            local radius = RAWorldConfig.CheckMist_Radius

            radius = RAWorldConfig.FetchPoint_Radius
            if RAWorldVar.IsMovingStop 
                or math.abs(pos.x - center.x) > radius.x 
                or math.abs(pos.y - center.y) > radius.y
            then
                if RAWorldUtil.kingdomId.isSelf() then
                    RAWorldProtoHandler:sendMoveSignal(pos)
                else
                    RAWorldProtoHandler:sendFetchPointsReq(pos, RAWorldVar.KingdomId.Map)
                end
                RAWorldVar:UpdateMoveSpeed(0)
                RAWorldVar:MarkStopMoving(false)
            end
        end
        return
    end

    if msgId == MessageDef_World.MSG_AddMarchHud then
        local RAWorldHudManager = RARequire('RAWorldHudManager')
        RAWorldHudManager:AddMarchHud(msg.marchId, msg.parent)
        return
    end

    if msgId == MessageDef_World.MSG_RemoveMarchHud then
        local RAWorldHudManager = RARequire('RAWorldHudManager')
        RAWorldHudManager:RemoveMarchHud(msg.marchId)
        return
    end

    if msgId == MessageDef_World.MSG_OpenMarchUseItemPage then
        local RAWorldHudManager = RARequire('RAWorldHudManager')
        RAWorldHudManager:AddMarchHudWithoutNode(msg.marchId)
        return
    end

    if msgId == MessageDef_World.MSG_CloseMarchUseItemPage then
        local RAWorldHudManager = RARequire('RAWorldHudManager')
        RAWorldHudManager:ShowMarchHudNode()
        return
    end

    if msgId == MessageDef_World.MSG_SwallowTouch then
        local RAWorldTouchHandler = RARequire('RAWorldTouchHandler')
        RAWorldTouchHandler:SwallowTouch()
        return
    end

    if msgId == MessageDef_World.MSG_RefreshWorldPoints then
        if RAWorldVar.HudPos ~= nil then
            local RAWorldUIManager = RARequire('RAWorldUIManager')
            RAWorldUIManager:ShowHud(RAWorldVar.HudPos, true)
            RAWorldVar.HudPos = nil
        end
        return
    end

    if msgId == MessageDef_World.MSG_SuperWeapon_Aiming then
        local RAWorldBuildingManager = RARequire('RAWorldBuildingManager')
        RAWorldBuildingManager:AddWarnings(msg.pos, msg.weaponType)
        return
    end

    if msgId == MessageDef_World.MSG_SuperWeapon_AimEnd then
        local RAWorldBuildingManager = RARequire('RAWorldBuildingManager')
        RAWorldBuildingManager:RemoveWarnings()
        return
    end

    if msgId == MessageDef_World.MSG_PresidentInfo_Update
        or msgId == MessageDef_World.MSG_CrossServerPresidentInfo_Update
    then
        local RAWorldBuildingManager = RARequire('RAWorldBuildingManager')
        RAWorldBuildingManager:UpdateCapital()
        return
    end

    if msgId == MessageDef_World.MSG_LocateAtPos then
        RAWorldManager:LocateAtPos(msg.x, msg.y)
        return
    end

    -- 重连服务器
    if msgId == MessageDef_LOGIN.MSG_LoginSuccess then
        if RAWorldUtil.kingdomId.isSelf() then
            RAWorldProtoHandler:sendEnterSignal(RAWorldVar.MapPos.Map)
        else
            RAWorldProtoHandler:sendFetchPointsReq(RAWorldVar.MapPos.Map, RAWorldVar.KingdomId.Map)
        end
        return
    end

    -- 新手引导
    if msgId == MessageDef_Guide.MSG_Guide then
        local RAWorldGuideManager = RARequire('RAWorldGuideManager')
        RAWorldGuideManager:OnReceiveGuideInfo(msg.guideInfo)
        return
    end

    -- 联盟有变化
    if msgId == MessageDef_Alliance.MSG_Alliance_Changed then
        local RAWorldBuildingManager = RARequire('RAWorldBuildingManager')
        RAWorldBuildingManager:updateAllBuildings()
        return
    end
end

return RAWorldHelper

--endregion
