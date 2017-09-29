--require('UICore.ScrollViewAnimation')
RARequire("BasePage")
local RARootManager = RARequire("RARootManager")
local UIExtend = RARequire("UIExtend")

local RAMainUIActivityHelper = {}

local createNewActivityCell = nil
local CCB_InAni = "InAni"
local CCB_OutAni = "OutAni"
local CCB_KeepIn = "KeepIn"
local CCB_KeepOut = "KeepOut"
local delayGap = 0.05

RAMainUIActivityHelper.mNode = nil

RAMainUIActivityHelper.mCellList = nil

RAMainUIActivityHelper.mIsCellIn = false
RAMainUIActivityHelper.mChangeCount = 0
RAMainUIActivityHelper.mCellCount = 0



function RAMainUIActivityHelper:resetData(isClear)
    if isClear and self.mCellList ~= nil then
        for cellId, cell in ipairs(self.mCellList) do
            cell:exit()
        end
    end

    self.mNode = nil

    self.mCellList = nil
    self.mIsCellIn = false
    self.mChangeCount = 0
    self.mCellCount = 0
end

function RAMainUIActivityHelper:Enter(data)
    self:resetData()
    
    self.mCellList = {}
    CCLuaLog("RAMainUIActivityHelper:Enter")

    if data ~= nil then
        self.mNode = data.node
    end
    -- local lastY = 0
    -- for i=1,4 do
    --     local cell = createNewActivityCell({
    --         label = "test "..i,
    --         cellId = i
    --         })
    --     local ccbi = cell:load()
    --     self.mNode:addChild(ccbi)
    --     cell:updateCell()
    --     ccbi:setPositionY(lastY)
    --     lastY = lastY - ccbi:getContentSize().height
    --     table.insert(self.mCellList, cell)
    --     self.mCellCount = self.mCellCount + 1
    -- end
end

function RAMainUIActivityHelper:GetShowStatus()
    return self.mIsCellIn
end

function RAMainUIActivityHelper:ChangeCellShowStatus(isShow, isAni)
    if self.mChangeCount > 0 then
        CCLuaLog("RAMainUIActivityHelper cell is moving count:"..self.mChangeCount)
        return
    end
    if self.mIsCellIn == isShow then
        return
    end

    self.mChangeCount = self.mCellCount
    self.mIsCellIn = isShow
    
    local cellCount = 0
    for cellId, cell in ipairs(self.mCellList) do
        cell:runAni(self.mIsCellIn, delayGap * cellCount)
        cellCount = cellCount + 1
    end
end

function RAMainUIActivityHelper:CellAniEnd(aniName, cellId, cell)
    if cellId ~= nil then
        local cellTar = self.mCellList[cellId]
        if cellTar == cell then
            local isHandle = false
            if self.mIsCellIn and aniName == CCB_InAni then                
                isHandle = true
            end
            
            if not self.mIsCellIn and aniName == CCB_OutAni then                
                isHandle = true
            end

            if isHandle then
                self.mChangeCount = self.mChangeCount - 1
                -- CCLuaLog("CellAniEnd   cell cout:"..self.mChangeCount)    
            end
            
        end
    end
end


function RAMainUIActivityHelper:Exit()
    CCLuaLog("RAMainUIActivityHelper:Exit")    
    self:resetData(true)
end


---------------Activity cell---------------

local RAMainUIActivityCell = 
{
    new = function(self, o)
        o = o or {}
        setmetatable(o,self)
        self.__index = self    
        return o
    end,

    getCCBName = function(self)
        return "RAMainUIActivityNode.ccbi"
    end,
    load = function(self, aniCallBack)
        local ccbi = UIExtend.loadCCBFile(self:getCCBName(), self)
        ccbi:runAnimation(CCB_KeepOut)
        self.aniCallBack = aniCallBack
        return ccbi
    end,

    updateCell = function(self)
        UIExtend.setCCLabelString(self:getCCBFile(), "mQueueTime", self.label)
    end,

    getCCBFile = function(self)
        return self.ccbfile
    end,

    refreshCell = function(self)
        -- body
    end,

    getAnimationCmd = function(self, name)
        local ccbi = self:getCCBFile()
        return function()
            ccbi:runAnimation(name)
        end
    end,

    runAni = function(self, isShow, delay)
        if isShow then
            performWithDelay(self:getCCBFile(), self:getAnimationCmd(CCB_InAni), delay)
        else
            performWithDelay(self:getCCBFile(), self:getAnimationCmd(CCB_OutAni), delay)
        end    
    end,

    OnAnimationDone = function(self, ccbfile)
        local lastAnimationName = ccbfile:getCompletedAnimationName()           
        if self.aniCallBack then
            self.aniCallBack(lastAnimationName)
        end
        RAMainUIActivityHelper:CellAniEnd(lastAnimationName, self.cellId, self)
    end,

    exit = function(self)
        UIExtend.unLoadCCBFile(self)
    end
}



createNewActivityCell = function(data)
    return RAMainUIActivityCell:new(data)
end


return RAMainUIActivityHelper