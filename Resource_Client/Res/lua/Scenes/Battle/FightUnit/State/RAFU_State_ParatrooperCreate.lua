--[[region RAFU_State_ParatrooperCreate.lua
伞兵空中状态的时候创建，会生成一个美国大兵
--Date 2016/12/26
--Author qinho
]]

local RAFU_State_ParatrooperCreate = class('RAFU_State_ParatrooperCreate',RARequire("RAFU_State_BaseCreate"))

function RAFU_State_ParatrooperCreate:Enter(data)
    RALogInfo("***********************************************")
    RALogInfo("RAFU_State_ParatrooperCreate:Enter")
    RALogInfo('self unit id:'.. self.fightUnit.id.. ' itemId = '..self.fightUnit.data.confData.id)
    RALogInfo("child unit id:"..data.data[1].childUnitId..'  child item id ='..data.data[1].childItemId)
    RALogInfo("***********************************************")    
    
    -- 状态本身需要execute
    self:SetIsExecute(true)
    self.data = data
    self:EnterCreate()
end

--创建之前的准备阶段
function RAFU_State_ParatrooperCreate:EnterPrepare()
    
end

--真正的创建战斗单元数据
function RAFU_State_ParatrooperCreate:EnterCreate()
    self.curState = FU_CREATE_ACTION_STATE.CREATE
    
    --发送消息，将战斗单元创建并进入战斗单元的管理类中
    local message = {}
    message.createActionData = self.data
    MessageManager.sendMessageInstant(MessageDef_BattleScene.MSG_FIGHT_UNIT_CREATE_UNIT, message)
end


function RAFU_State_ParatrooperCreate:Execute(dt)
    
end

function RAFU_State_ParatrooperCreate:Exit()
    if self.localAlive == true then
        self.localAlive = false
    end

end


return RAFU_State_ParatrooperCreate
--endregion
