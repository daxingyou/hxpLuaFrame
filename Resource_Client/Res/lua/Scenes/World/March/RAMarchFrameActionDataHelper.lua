--RAMarchFrameActionDataHelper
--行军序列帧数据及管理
local common = RARequire("common")
local Utilitys = RARequire("Utilitys")
local march_frame_conf = RARequire("march_frame_conf")

local RAMarchFrameActionDataHelper = {}
RAMarchFrameActionDataHelper.mFrameDataList = {}
----------------RAMarchFrameActionData-------------------------


local RAMarchFrameActionData = 
{
    New = function(self, o)
        o = o or {}
        setmetatable(o, self)
        self.__index = self
        o.frameId = -1
        o.name = ''
        o.partCCB = ''
        o.partNames = ''
        o.containerCCB = ''
        o.containerCount = 0
        o.plistName = ''
        o.picName = ''

        -- 用于组合单个模型
        o.mPartFileList = {}
        -- key为0-8的方向，value = {frames = {1, 2, 3}, fps = 15}
        o.mFrameDirList = {}        
        return o
    end,

    ResetData = function(self)
        self.frameId = -1
        self.name = ''
        self.partCCB = ''
        self.partNames = ''
        self.containerCCB = ''
        self.containerCount = 0
        self.plistName = ''
        self.picName = ''

        -- 用于组合单个模型
        self.mPartFileList = {}
        -- key为0-15的方向，value = {frames = {1, 2, 3}, fps = 15}
        self.mFrameDirList = {}        
    end,

    Init = function(self, frameId)
        local cfg = march_frame_conf[tonumber(frameId)]
        if cfg == nil then return false end
        self:ResetData()

        self.frameId = cfg.id
        self.name = cfg.name
        self.partCCB = cfg.partCCB
        self.partNames = cfg.partNames
        self.containerCCB = cfg.containerCCB
        self.containerCount = cfg.containerCount
        self.plistName = cfg.plistName
        self.picName = cfg.picName

        -- 分割单模型的组件
        local partNameSplit = Utilitys.Split(self.partNames, "_")
        for i = 1, #partNameSplit do
            self.mPartFileList[i] = self.name..'_'..partNameSplit[i]
        end
        -- 分割和创建0-8个方向对应的序列帧数据
        for i=0, 8 do
            local oneDir = {
                frames = {},
                fps = 1
            }
            local framesDirKey = 'framesDir'..i
            local framesDirStr = cfg[framesDirKey]
            local framesDirSplit = Utilitys.Split(framesDirStr, '_')
            for j = 1, #framesDirSplit do
                oneDir.frames[j] = framesDirSplit[j]
            end
            local fpsDirKey = 'fpsDir'..i            
            oneDir.fps = tonumber(cfg[fpsDirKey])
            self.mFrameDirList[i] = oneDir
        end
        return true
    end,

    GetPartFileList = function(self)
        return self.mPartFileList
    end,

    GetFrameDirList = function(self)
        return self.mFrameDirList
    end,
}



--获取一个data
function RAMarchFrameActionDataHelper:GetFrameActionData(frameId)
    local frameData = self.mFrameDataList[framesDirKey]
    if frameData == nil then
        frameData = RAMarchFrameActionData:New()
        if frameData:Init(frameId) then
            self.mFrameDataList[frameId] = frameData
        else
            frameData = nil
            self.mFrameDataList[frameId] = nil
        end
    end
    return frameData
end



--如果内更新，则需要调用，暂时无效
function RAMarchFrameActionDataHelper:ResetData()
    self.mFrameDataList = {}
end



return RAMarchFrameActionDataHelper

