--[[region RAFU_State_ParaPlaneCreate.lua
战斗单元的基础创建类
--用来处理战斗单元 创建另外一个战斗单元的逻辑
--如鲍里斯创建黑影战机，V3导弹车创建V3火箭
    更详细点的逻辑如下：
    CreateAction   
        没有attackAction 和damage
            1. 创建的准备时间
            2. 创建v3_head battleUnit battleUnitData      cfgdata
                initAction  (position, data)
            3. add to battleScene 
--Date 2016/12/16
--Author zhenhui
]]

local RAFU_State_ParaPlaneCreate = class('RAFU_State_ParaPlaneCreate',RARequire("RAFU_State_BaseCreate"))

function RAFU_State_ParaPlaneCreate:Enter(data)
    -- 状态本身需要execute
    self:SetIsExecute(true)
    self.data = data
    self:EnterCreate()
end

--创建之前的准备阶段
function RAFU_State_ParaPlaneCreate:EnterPrepare()
    
end

--真正的创建战斗单元数据
function RAFU_State_ParaPlaneCreate:EnterCreate()
    self.curState = FU_CREATE_ACTION_STATE.CREATE
    
    --发送消息，将战斗单元创建并进入战斗单元的管理类中
    local message = {}
    message.createActionData = self.data
    MessageManager.sendMessageInstant(MessageDef_BattleScene.MSG_FIGHT_UNIT_CREATE_UNIT, message)
end


function RAFU_State_ParaPlaneCreate:Execute(dt)
    
end

function RAFU_State_ParaPlaneCreate:Exit()
    if self.localAlive == true then
        self.localAlive = false
    end

end

return RAFU_State_ParaPlaneCreate
--endregion
