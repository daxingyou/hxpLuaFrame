-- RAPlayMusicAction.lua
-- Author: xinghui
-- Using: 播放音乐Actin

local Utilitys                      = RARequire("Utilitys")
local RAActionBase                  = RARequire("RAActionBase")
local missionaction_conf            = RARequire("missionaction_conf")

local RAPlayMusicAction    = RAActionBase:new()

--[[
    desc: addccbaction入口
]]
function RAPlayMusicAction:Start(data)
    self.constActionInfo = missionaction_conf[self.actionId]
    --param格式：music,true
    local paramArr = Utilitys.Split(self.constActionInfo.param, ",")

    if self.constActionInfo.varibleName then

        local isLoop = false
        if paramArr[2] == "true" then
            isLoop = true
        end

        if paramArr[1] == "music" then
            SoundManager:getInstance():playMusic(self.constActionInfo.varibleName, isLoop);
        else
            SoundManager:getInstance():playEffect(self.constActionInfo.varibleName);
        end
    end

    self:End()
end

return RAPlayMusicAction