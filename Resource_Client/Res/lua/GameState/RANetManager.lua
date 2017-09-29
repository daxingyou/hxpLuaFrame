--region RANetManager.lua
--Date
--此文件由[BabeLua]插件自动生成
local RANetManager = {}
local RALoginManager = RARequire("RALoginManager")
local RARootManager = RARequire("RARootManager")
RANetManager.isReconecting = false
RANetManager.frameTime = 0
RANetManager.reconnectCout = 0
RANetManager.ip = nil
RANetManager.port = nil
RANetManager.isReconectSuccess = nil

local reconnectGapSec = 5 
local reconnectTryCount = 3 

function RANetManager:setReconect(flag)
    if self.isReconecting == flag then return end
    self.isReconecting = flag
    if flag == true then
        --RARootManager.RemoveWaitingPage()
        local k,v = RARootManager.checkPageLoaded("RAReconnectPage")
        if v == nil then
            RARootManager.OpenPage("RAReconnectPage")
        end
        
    else
        --RARootManager.ShowWaitingPage(true)
        RARootManager.ClosePage("RAReconnectPage")
    end
end


function RANetManager:Execute(dt)
    if self.isReconecting then
        self.frameTime = self.frameTime + dt
        
        -- 更换服务器
        if self.ip and self.port then
            PacketManager:getInstance():reconnect(self.ip, self.port)
            self.ip = nil
            self.port = nil
        end
        
        if self.frameTime > reconnectGapSec then
            --重连n次之后，失败的话，返回到登陆页面
            if self.reconnectCout > reconnectTryCount then
                return GameStateMachine.ChangeState(RARequire("RAGameLoadingState"))
            end
            RALoginManager:reconnectServer()
            self.frameTime = 0 
            self.reconnectCout = self.reconnectCout + 1
        end
    end
    
end

function RANetManager:reset()
    RANetManager.frameTime = 0
    RANetManager.reconnectCout = 0
    RANetManager.isReconecting = false
end

-- 重连：跨服迁城后重连,下一帧重连
function RANetManager:reconnect(ip, port)
    self.ip = ip
    self.port = port
    self:reset()
    self:setReconect(true)
end

return RANetManager
--endregion
