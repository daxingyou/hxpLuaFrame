--
--  @ Project : NewbieGuide
--  @ File Name : RANewbieNodeHelper.lua
--  @ Date : 2017/2/9
--  @ Author : @Qinho
--
--

local RANewbieNodeHelper = {}

-- 用于新手的一个节点，对话页面，
-- 也是半身像ccb的父节点，
-- 具体ccbi由单步骤中的配置 v_1_dialogCCB 决定。
-- 可能使用的ccbi : 
-- RAGuideLabelBlueNode.ccbi
-- RAGuideLabelBlueNode2.ccbi
-- RAGuideLabelGreenNode.ccbi
-- RAGuideLabelGreenNode2.ccbi
local RANewbieNode_Label = {
	new = function(self, o)
        o = o or {}
        setmetatable(o,self)
        self.__index = self    
        o.mCCBFileName = ''
        return o
    end,

    SetCCBName = function(self, fileName)
        self.mCCBFileName = fileName
    end,

    GetCCBName = function(self)
        return self.mCCBFileName
    end,

    GetCCBFile = function(self)
        return self.ccbfile
    end,

    Load = function(self)
        CCLuaLog("RANewbieNode_Label:Load")
        local ccbi = UIExtend.loadCCBFile(self:GetCCBName(), self)
        if ccbi == nil then return end        
        return ccbi
    end,

    RefreshCell = function(self)        
    end,

	OnAnimationDone = function(self, ccbfile)
        local lastAnimationName = ccbfile:getCompletedAnimationName() 
        if lastAnimationName == "OutAni" then
            -- to do
        end                      
    end,

    PlayAnimation = function (self, animationName)
        self:GetCCBFile():runAnimation(animationName)
    end,

    SetLabel = function (self, varName, contentStr)
       UIExtend.setCCLabelHTMLString(self.ccbfile, varName, contentStr)
    end,

    Release = function(self)
        if self.ccbfile then
            self.ccbfile:release()
            self.ccbfile = nil
        end
    end
}


-- 用于新手的一个节点，光圈和遮挡显示，
-- 具体ccbi为 RAGuideMaskNode。
local RANewbieNode_Mask = {
	new = function(self, o)
        o = o or {}
        setmetatable(o,self)
        self.__index = self    
        o.mCCBFileName = 'RAGuideMaskNode.ccbi'
        return o
    end,

    GetCCBName = function(self)
        return self.mCCBFileName
    end,

    GetCCBFile = function(self)
        return self.ccbfile
    end,

    Load = function(self)
        CCLuaLog("RANewbieNode_Mask:Load")
        local ccbi = UIExtend.loadCCBFile(self:GetCCBName(), self)
        if ccbi == nil then return end        
        return ccbi
    end,

    RefreshCell = function(self)        
    end,
    
	OnAnimationDone = function(self, ccbfile)
        local lastAnimationName = ccbfile:getCompletedAnimationName()                        
    end,

    Release = function(self)
        if self.ccbfile then
            self.ccbfile:release()
            self.ccbfile = nil
        end
    end
}

-- 用于新手的一个节点，半身像显示，
-- 具体ccbi为 RAGuideBustNode。
-- 播放的时间轴动画名字由单步骤中的配置 v_1_roleIconDir 决定，
-- -1为左，1为右。
local RANewbieNode_Role = {
	new = function(self, o)
        o = o or {}
        setmetatable(o,self)
        self.__index = self    
        o.mCCBFileName = 'RAGuideBustNode.ccbi'
        return o
    end,

    GetCCBName = function(self)
        return self.mCCBFileName
    end,

    GetCCBFile = function(self)
        return self.ccbfile
    end,

    Load = function(self)
        CCLuaLog("RANewbieNode_Role:Load")
        local ccbi = UIExtend.loadCCBFile(self:GetCCBName(), self)
        if ccbi == nil then return end        
        return ccbi
    end,

    RunInAni = function(self, isLeft)
        if self.ccbfile ~= nil then
            if isLeft then
                self.ccbfile:runAnimation("LeftAni")
            else
                self.ccbfile:runAnimation("RightAni")
            end
        end
    end,

    RunOutAni = function(self, isLeft)
        if self.ccbfile ~= nil then
            if isLeft then
                self.ccbfile:runAnimation("LeftOutAni")
            else
                self.ccbfile:runAnimation("RightOutAni")
            end
        end
    end,

    RefreshCell = function(self)        
    end,
    
	OnAnimationDone = function(self, ccbfile)
        local lastAnimationName = ccbfile:getCompletedAnimationName() 
        if lastAnimationName == "LeftOutAni" or lastAnimationName == "RightOutAni" then
            -- to do
        end                      
    end,

    Release = function(self)
        if self.ccbfile then
            self.ccbfile:release()
            self.ccbfile = nil
        end
    end
}


-- 用于新手的一个节点，胜利页面；
-- ccbi : Ani_Guide_Victory.ccbi
local RANewbieNode_Victory = {
	new = function(self, o)
        o = o or {}
        setmetatable(o,self)
        self.__index = self    
        o.mCCBFileName = 'Ani_Guide_Victory.ccbi'
        return o
    end,

    GetCCBName = function(self)
        return self.mCCBFileName
    end,

    GetCCBFile = function(self)
        return self.ccbfile
    end,

    Load = function(self)
        CCLuaLog("RANewbieNode_Victory:Load")
        local ccbi = UIExtend.loadCCBFile(self:GetCCBName(), self)
        if ccbi == nil then return end        
        return ccbi
    end,

    RefreshCell = function(self)        
    end,

    RunAni = function(self,callBack)
        if self.ccbfile ~= nil then
            self.ccbfile:runAnimation("VictoryAni")
            self.callBack = callBack
        end
    end,
    
	OnAnimationDone = function(self, ccbfile)
        local lastAnimationName = ccbfile:getCompletedAnimationName() 
        if lastAnimationName ==  "VictoryAni" then
            if self.callBack and type(self.callBack) == "function" then
                self.callBack()
                self.callBack = nil
            end
        end                 
    end,

    Release = function(self)
        if self.ccbfile then
            self.ccbfile:release()
            self.ccbfile = nil
        end
    end
}



function RANewbieNodeHelper:CreateLabelCell(fileName)
    local cell = RANewbieNode_Label:new()
    cell:SetCCBName(fileName)
    return cell
end

function RANewbieNodeHelper:CreateRoleCell()
    local cell = RANewbieNode_Role:new()
    return cell
end


function RANewbieNodeHelper:CreateMaskCell()
    local cell = RANewbieNode_Mask:new()
    return cell
end

function RANewbieNodeHelper:CreateVictoryCell()
    local cell = RANewbieNode_Victory:new()
    return cell
end



return RANewbieNodeHelper