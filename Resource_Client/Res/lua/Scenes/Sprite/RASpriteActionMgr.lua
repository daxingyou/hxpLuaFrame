--region *.lua
--Date
--此文件由[BabeLua]插件自动生成
local frame_conf = RARequire("frame_conf")
local UIExtend = RARequire("UIExtend")
local EnumManager = RARequire("EnumManager")
local RASpriteActionMgr = {
    new = function (self,parent,frameId)
        local o = {}
        self.__index = self
        setmetatable(o, self)
        
        local frameInfo = frame_conf[frameId]
        if frameInfo == nil then frameInfo = frame_conf[1] end
        local ccbFileName = frameInfo.ccbfileName
        o.ccbfile = UIExtend.loadCCBFile(ccbFileName,o)
        o.currentDirection = EnumManager.DIRECTION_ENUM.DIR_DOWN
        o.ccbfileName = ccbFileName
        parent:addChild(o.ccbfile)
        return o
    end,
    changeAction = function (self,action,dir)
        local actionStr = EnumManager.ACTION_TYPE_STR[action]
        self.currentDirection = dir
        local dir16 = EnumManager:convert8DirTo16Dir(dir)
        local aniName = actionStr.."_"..dir16
        return self:changeAnimation(aniName)
    end,
    changeAnimation = function (self,animationName)
        if animationName == nil then return end
        if self.ccbfile ~= nil then
            if self.ccbfile:getRunningSequenceName() == animationName then
                return
            end

            if self.ccbfile:hasAnimation(animationName) then
                self.ccbfile:runAnimation(animationName) 
            else    
                --CCMessageBox("ccbname is "..self.ccbfileName.."animation not found: "..animationName,"hint")
            end
        end
    end,
    release = function(self)
        UIExtend.unLoadCCBFile(self)
    end
}

return RASpriteActionMgr
--endregion
