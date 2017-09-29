-- RAAllianceSiloPage.lua qinho
-- 联盟领地核弹发射井/天气控制器  UI
local RARootManager = RARequire('RARootManager')
local RAAllianceProtoManager = RARequire('RAAllianceProtoManager')
local RAAllianceManager = RARequire('RAAllianceManager')
local RANetUtil = RARequire('RANetUtil')
local RAAllianceUtility = RARequire('RAAllianceUtility')
local html_zh_cn = RARequire('html_zh_cn')
local HP_pb = RARequire('HP_pb')
local GuildManor_pb = RARequire('GuildManor_pb')
local World_pb = RARequire('World_pb')
local RAStringUtil = RARequire('RAStringUtil')
local common = RARequire("common")
local UIExtend = RARequire('UIExtend')
local Utilitys = RARequire('Utilitys')
local guild_const_conf = RARequire('guild_const_conf')

local RAAllianceSiloPage = BaseFunctionPage:new(...)
RAAllianceSiloPage.mVotesHandler = {}

local msgTB =
{
    MessageDef_Alliance.MSG_NuclearInfo_Update,
    MessageDef_Packet.MSG_Operation_OK,
    MessageDef_Packet.MSG_Operation_Fail,
}


local opcodeTB =
{
    -- HP_pb.GET_NUCLEAR_INFO_S,
}

local OnReceiveMessage = function(message)
    if message.messageID == MessageDef_Alliance.MSG_NuclearInfo_Update then
        RAAllianceSiloPage:RefreshUI()
    elseif message.messageID == MessageDef_Packet.MSG_Operation_Fail then
        if message.opcode == HP_pb.GET_NUCLEAR_INFO_C then
            print('RAAllianceSiloPage  get nuclear Info failed, close self page')
            RARootManager.ClosePage('RAAllianceSiloPage')
        end
    end
end

function RAAllianceSiloPage:_RegisterMessageHandlers()
    for _, msgId in ipairs(msgTB) do
        MessageManager.registerMessageHandler(msgId, OnReceiveMessage)
    end
end


function RAAllianceSiloPage:_UnregisterMessageHandlers()
    for _, msgId in ipairs(msgTB) do
        MessageManager.removeMessageHandler(msgId, OnReceiveMessage)
    end
end

function RAAllianceSiloPage:_RegisterPacketHandlers()
    self.mPacketHandlers = RANetUtil:addListener(opcodeTB, self)
end

function RAAllianceSiloPage:_UnregisterPacketHandlers()
    RANetUtil:removeListener(self.mPacketHandlers)
end

function RAAllianceSiloPage:onReceivePacket(handler)
    local opcode = handler:getOpcode()
    local buffer = handler:getBuffer()        
    -- -- 请求返回
    -- if opcode == HP_pb.GET_NUCLEAR_INFO_S then --获得超级武器
    --     local allianceNuclearInfo = RAAllianceProtoManager:getNuclearInfo(buffer)
    --     RAAllianceManager:GetNuclearInfo() = allianceNuclearInfo
    --     self:RefreshUI()
    -- end
end


function RAAllianceSiloPage:Enter(data)

    data = RAAllianceManager:getSelfSuperWeaponData()
    self.curType = RAAllianceManager:getSelfSuperWeaponType() 
    if self.curType == Const_pb.GUILD_SILO then  --核弹
        self.ccbfile = UIExtend.loadCCBFile("RAAllianceTerritoryNuclearPopUp.ccbi", self)
    else
        self.ccbfile = UIExtend.loadCCBFile('RAAllianceTerritorySkyConPopUp.ccbi', self)    
    end 
    self.mLastUpdateTime = 0

    self:_RegisterMessageHandlers()
    self:_RegisterPacketHandlers()

    RAAllianceProtoManager:reqNuclearInfo()

    self:_RefreshConfigPart()
    self:RefreshUI()
end

function RAAllianceSiloPage:Execute()
    self.mLastUpdateTime = self.mLastUpdateTime + common:getFrameTime()
    if self.mLastUpdateTime > 1 then
        self.mLastUpdateTime = 0
        self:_RefreshByTime()
    end
end

function RAAllianceSiloPage:Exit()
    self.mLastUpdateTime = 0
    -- body
    self.mExplainLabel:stopAllActions()
    self.mExplainLabel:setPosition(self.mExplainLabelStarP)
    if self.mFileCCBNode then
        self.mFileCCBNode:unregisterFunctionHandler()
        self.mFileCCBNode = nil
    end

    for _, cell in pairs(self.mVotesHandler) do
        cell:Release()
    end
    self.mVotesHandler = {}

    self:_UnregisterPacketHandlers()
    self:_UnregisterMessageHandlers()
end


--HUD弹出动画结束处理
function RAAllianceSiloPage:OnAnimationDone()
    local lastAnimationName = self.ccbfile:getCompletedAnimationName()
    CCLuaLog('OnAnimationDone' .. lastAnimationName)
    if lastAnimationName == 'mFileCCBNode_OpenTheDoorAni' then 
        UIExtend.setNodeVisible(self.mFileCCBNode, 'mReadyToLaunchBtnNode', false)
        self.isAnimation = false
    end 
end

function RAAllianceSiloPage:onOpenSilo()
    if self:isInVotePage() then
        if self.curState == World_pb.CAN_OPENUP then 
            RAAllianceProtoManager:reqOpenNulcear()
        end         
        local RAWorldManager = RARequire('RAWorldManager')
        RARootManager.CloseAllPages()
        local buildData = RAAllianceManager:getSelfSuperWeaponData()
        RAWorldManager:LaunchBombAt(buildData.pos.x, buildData.pos.y)
    end 
end

function RAAllianceSiloPage:onMainCancelLaunchBtn()
    CCLuaLog('取消发射')
    RAAllianceProtoManager:reqCancelNuclear()
end


--保护时间问号按钮
function RAAllianceSiloPage:onHelpBtn()
    if self:isInVotePage() then
        local confirmData = {}
        confirmData.labelText = _RALang("@SuperWeaponProtectTimeTip")
        confirmData.yesNoBtn=false
        RARootManager.OpenPage("RAConfirmPage", confirmData,false,true,true)
    end 
end

function RAAllianceSiloPage:onCancelLaunch()
    CCLuaLog('onCancelLaunch')
    if self:isInVotePage() then
        RAAllianceProtoManager:reqCancelNuclear()
    end
end

function RAAllianceSiloPage:isInVotePage()
    if self.curState ==  World_pb.VOTING or self.curState == World_pb.CAN_OPENUP or self.curState == World_pb.CAN_LAUNCH then 
        return true
    end 
    return false
end



function RAAllianceSiloPage:onCheckCDBtn()
    local RAWorldManager = RARequire('RAWorldManager')
    local nuclearInfo = RAAllianceManager:GetNuclearInfo()
    if nuclearInfo ~= nil then        
        RAWorldManager:LocateAt(nuclearInfo.launchInfo.firePosX, nuclearInfo.launchInfo.firePosY)
        RARootManager.CloseAllPages()
    end
end

function RAAllianceSiloPage:onClose()
    --关闭
    RARootManager.ClosePage("RAAllianceSiloPage")
end

function RAAllianceSiloPage:onConfirm()
    RARootManager.ShowMsgBox('@NoOpenTips')
end

--开始研究
function RAAllianceSiloPage:onResearchBtn()
    --没有权限
    if RAAllianceUtility:isAbleToLaunchBomb(RAAllianceManager.authority) == false then
        RARootManager.ShowMsgBox(_RALang("@NotHaveAuthorityToResearchSuperWeapon"))
        return 
    end

    --到达了超级武器的上限了
    if RAAllianceManager:GetNuclearInfo().count >= self.storageLimit then 
        RARootManager.ShowMsgBox(_RALang("@ReachSuperWeaponStorageLimit"))
        return 
    end 

    --原料不足
    if self.collectedNum < guild_const_conf['nuclearProduceCost'].value then 
        RARootManager.ShowMsgBox(_RALang("@NotHaveEnoughMaterial",guild_const_conf['nuclearProduceCost'].value))
        return 
    end 
    RAAllianceProtoManager:sendCreateWeaponReq()
end

function RAAllianceSiloPage:onReadyToLaunch()
    CCLuaLog('onReadyToLaunch')
    local nuclearInfo = RAAllianceManager:GetNuclearInfo()
    if nuclearInfo == nil then 
        return 
    end 

    if nuclearInfo.launchInfo.launchType == GuildManor_pb.FROM_MACHINE then
        RARootManager.ShowMsgBox(_RALang("@CurLaunchStateIsPlatform"))
        return
    end

    if RAAllianceManager:GetNuclearInfo().count <= 0 then 
        RARootManager.ShowMsgBox(_RALang("@NotHaveSuper"))
        return 
    end

    if RAAllianceUtility:isAbleToLaunchBomb(RAAllianceManager.authority) == false then
        RARootManager.ShowMsgBox(_RALang("@NotHaveAuthorityToLaunch"))
        return 
    end   

    RAAllianceProtoManager:reqBeginNuclearVote(GuildManor_pb.FROM_MANOR)
    -- self.mFileCCBNode:runAnimation('OpenTheDoorAni')
end


function RAAllianceSiloPage:_RefreshConfigPart()
    local buildData = RAAllianceManager:getSelfSuperWeaponData()
    local ccbfile = self.ccbfile
    if ccbfile == nil or buildData == nil then return end

    -- rolling text
    self.mExplainLabel = UIExtend.getCCLabelTTFFromCCB(self.ccbfile,'mExplainLabel')
    self.mExplainLabelStarP =ccp(self.mExplainLabel:getPosition())

    if self.curType == Const_pb.GUILD_SILO then  --核弹
        self.mExplainLabel:setString(_RALang('@AllianceSiloBuildingDesc'))        
        local explainStr = _RALang('@AllianceNuclearExplainDesc') .. '\n' .. _RALang('@AllianceNuclearExplainDesc2') .. '\n'.._RALang('@AllianceNuclearExplainDesc3')
        UIExtend.setCCLabelString(ccbfile, 'mNuclearExplainLabel', explainStr)
        UIExtend.setCCLabelString(ccbfile, 'mLaunchTitle', _RALang('@TheNuclearLaunch'))

        self.storageLimit = guild_const_conf['nuclearStorageLimit'].value
    else
        self.mExplainLabel:setString(_RALang('@AllianceWeatherBuildingDesc'))        
        local explainStr = _RALang('@AllianceWeatherExplainDesc') .. '\n' .. _RALang('@AllianceWeatherExplainDesc2') .. '\n'.._RALang('@AllianceWeatherExplainDesc3')        
        UIExtend.setCCLabelString(ccbfile, 'mNuclearExplainLabel', explainStr)
        UIExtend.setCCLabelString(ccbfile, 'mLaunchTitle', _RALang('@LaunchWeather'))

        self.storageLimit = guild_const_conf['thunderStorageLimit'].value
    end 

    UIExtend.createLabelAction(self.ccbfile,"mExplainLabel")
    
    local buildPic = UIExtend.getCCSpriteFromCCB(self.ccbfile,'mWeaponBuildPic')
    buildPic:setTexture(buildData.confData.icon)    
    UIExtend.setCCLabelString(ccbfile, 'mCollectionName', _RALang(buildData.confData.name))

    self.mFileCCBNode = UIExtend.getCCBFileFromCCB(ccbfile,'mFileCCBNode')
    self.mFileCCBNode:registerFunctionHandler(self)
    UIExtend.setControlButtonTitle(self.mFileCCBNode, 'mReadyToLaunch',_RALang('@ReadyToVote'))


    local RAAllianceSiloCellHelper = RARequire('RAAllianceSiloCellHelper')
    self.mVotesHandler = {}
    for i=1,3 do
        local voteCellCCBI = UIExtend.getCCBFileFromCCB(self.mFileCCBNode,'mKeyCCB' .. i)
        self.mVotesHandler[i] = RAAllianceSiloCellHelper:CreateVoteHandler(voteCellCCBI, i)        
    end
end

function RAAllianceSiloPage:RefreshUI()
    local nuclearInfo = RAAllianceManager:GetNuclearInfo()
    local ccbfile = self.ccbfile
    if nuclearInfo == nil or ccbfile == nil then return end

    local text = ''
    if self.curType== Const_pb.GUILD_SILO then  --核弹
        text = _RALang('@NuclearWeaponNum') .. ':'
        text = text .. nuclearInfo.count .. '/' .. self.storageLimit
    else
        text = _RALang('@WeatherWeaponNum') .. ':'
        text = text .. nuclearInfo.count .. '/' .. self.storageLimit
    end 
    
    UIExtend.setCCLabelString(ccbfile, 'mDetailsLabel1', text)
    
    --更新原料速度
    local text = ''
    if self.curType == Const_pb.GUILD_SILO then  --核弹
        text = _RALang('@NuclearMaterialSpeed') .. ':'
    else
        text = _RALang('@WeatherMaterialSpeed') .. ':'
    end 


    local territoryData = RAAllianceManager:getManorDataById(RAAllianceManager.selfAlliance.manorId)  
    -- local speed = territoryData.
    local speed = RAAllianceUtility:getUraniumOutput(territoryData) 
    text = text .. speed .. '/' .. _RALang('@PerDay')
    UIExtend.setCCLabelString(ccbfile, 'mDetailsLabel2', text)

    self.speedPerSecond = (speed*1.0)/(60*60*24)

    self:_UpdateByState(nuclearInfo.launchInfo.state)
    self:_RefreshByTime()
end

function RAAllianceSiloPage:_UpdateByState(curLaunchState)
    local ccbfile = self.ccbfile
    local nuclearInfo = RAAllianceManager:GetNuclearInfo()
    if nuclearInfo == nil or ccbfile == nil then return end

    UIExtend.setNodesVisible(ccbfile, 
    {
        mCCBNode = false,
        mFileCCBNode = false,
        mNuclearLaunchedNode = false,
    })
    UIExtend.setNodeVisible(self.mFileCCBNode, 'mReadyToLaunchBtnNode', false)
    UIExtend.setNodeVisible(self.mFileCCBNode, 'mCancelLaunch', false)
    UIExtend.setNodeVisible(self.mFileCCBNode, 'mOpenSilo', false)

    if nuclearInfo.launchInfo.launchType ~= GuildManor_pb.FROM_MACHINE then
        UIExtend.setCCControlButtonEnable(self.mFileCCBNode, 'mReadyToLaunch', true)
        UIExtend.setControlButtonTitle(self.mFileCCBNode, 'mReadyToLaunch',_RALang('@ReadyToVote'))
        self.isAnimation = false
        if World_pb.NORMAL_STATE == curLaunchState  then -- 正常状态 
            UIExtend.setNodeVisible(ccbfile, 'mCCBNode', true)
            UIExtend.setNodeVisible(ccbfile, 'mFileCCBNode', true)
            UIExtend.setNodeVisible(self.mFileCCBNode, 'mReadyToLaunchBtnNode', true)
            if self.curState == World_pb.VOTING or World_pb.CAN_OPENUP == self.curState or World_pb.CAN_LAUNCH == self.curState then                         
                self.mFileCCBNode:runAnimation('CloseAni')
            else 
                self.mFileCCBNode:runAnimation('KeepClose')
            end
        elseif World_pb.VOTING == curLaunchState or World_pb.CAN_OPENUP == curLaunchState or World_pb.CAN_LAUNCH == curLaunchState then -- 投票中        
            UIExtend.setNodeVisible(ccbfile, 'mCCBNode', true)
            UIExtend.setNodeVisible(ccbfile, 'mFileCCBNode', true)
            UIExtend.setNodeVisible(self.mFileCCBNode, 'mCancelLaunch', true)
            UIExtend.setNodeVisible(self.mFileCCBNode, 'mOpenSilo', true)

            if self.curState == World_pb.NORMAL_STATE then 
                UIExtend.setNodeVisible(self.mFileCCBNode, 'mReadyToLaunchBtnNode', true)
                self.isAnimation = true
                self.mFileCCBNode:runAnimation('OpenTheDoorAni')
            else 
                self.mFileCCBNode:runAnimation('KeepOpen')
            end

            if curLaunchState ~= World_pb.CAN_LAUNCH then
                UIExtend.setControlButtonTitle(self.mFileCCBNode,'mOpenSilo',_RALang('@OpenSilo'))
            else
                UIExtend.setControlButtonTitle(self.mFileCCBNode,'mOpenSilo',_RALang('@ReadyToLaunchNow'))
            end 
            self:_UpdateVotePanels()
        elseif World_pb.LAUNCHING == curLaunchState then 
            UIExtend.setNodeVisible(ccbfile, 'mNuclearLaunchedNode', true)
        end 
    else
        self.mFileCCBNode:runAnimation('KeepClose')
        UIExtend.setNodeVisible(ccbfile, 'mCCBNode', true)
        UIExtend.setNodeVisible(ccbfile, 'mFileCCBNode', true)
        UIExtend.setControlButtonTitle(self.mFileCCBNode, 'mReadyToLaunch',_RALang('@PlatformLaunching'))
        UIExtend.setCCControlButtonEnable(self.mFileCCBNode, 'mReadyToLaunch', false)
        UIExtend.setNodeVisible(self.mFileCCBNode, 'mReadyToLaunchBtnNode', true)
    end
    self.curState = curLaunchState
end

-- 刷新投票相关
function RAAllianceSiloPage:_UpdateVotePanels()
    local nuclearInfo = RAAllianceManager:GetNuclearInfo()
    local ccbfile = self.ccbfile
    if nuclearInfo == nil or ccbfile == nil then return end
    local voteInfo = nuclearInfo.launchInfo.voteInfo
    if voteInfo == nil then return end
    local text = _RALang('@SuperweaponOrganizer') .. ':' .. voteInfo.organizer
    UIExtend.setCCLabelString(self.mFileCCBNode, 'mOrganizer', text)
    
    local votes = voteInfo.votePlayer

    if #votes == 1 then 
        self.mVotesHandler[1]:updateVote(nil)
        local data = {}
        data.index = 1
        data.name = votes[1]
        self.mVotesHandler[2]:updateVote(data)
        self.mVotesHandler[3]:updateVote(nil)
    else 
        for i=1,3 do
            local data = {}
            data.index = i
            data.name = votes[i]
            self.mVotesHandler[i]:updateVote(data) 
        end
    end
end

-- 需要时间刷新的部分
-- 能源、研究时间、保护时间
function RAAllianceSiloPage:_RefreshByTime()
    local nuclearInfo = RAAllianceManager:GetNuclearInfo()
    local ccbfile = self.ccbfile
    if nuclearInfo == nil or ccbfile == nil then return end

    self:_UpdateResearchPart(ccbfile, nuclearInfo)
    self:_UpdateMaterialNumPart(ccbfile, nuclearInfo)

    if self.curState == World_pb.VOTING or 
        self.curState == World_pb.CAN_OPENUP or 
        self.curState == World_pb.CAN_LAUNCH then -- 投票中
        local voteInfo = nuclearInfo.launchInfo.voteInfo
        if voteInfo == nil then return end 
        local voteProtectTime = 0
        if voteInfo.voteProtectTime ~= nil then
            voteProtectTime = voteInfo.voteProtectTime/1000
        end  

        local remainTime = Utilitys.getCurDiffTime(voteProtectTime)

        if remainTime < 0 then --时间倒计时为0就隐藏进度条  已经过了保护时间
            remainTime = 0

            if RAAllianceUtility:isAbleToLaunchBomb(RAAllianceManager.authority) == false then
                UIExtend.setCCControlButtonEnable(self.mFileCCBNode, 'mOpenSilo', false)
                UIExtend.setCCControlButtonEnable(self.mFileCCBNode, 'mCancelLaunch', false)                    
            else
                UIExtend.setCCControlButtonEnable(self.mFileCCBNode, 'mOpenSilo', true)
                UIExtend.setCCControlButtonEnable(self.mFileCCBNode, 'mCancelLaunch', true)
            end 
        else  --在保护时间
            local isCan = RAAllianceUtility:isCanOperationInProtectTime(voteInfo.organizer)
            UIExtend.setCCControlButtonEnable(self.mFileCCBNode, 'mOpenSilo', isCan)
            UIExtend.setCCControlButtonEnable(self.mFileCCBNode, 'mCancelLaunch', isCan)
        end 

        local tmpStr = Utilitys.createTimeWithFormat(remainTime)
        UIExtend.setCCLabelString(self.mFileCCBNode, 'mProtectTime', tmpStr)

        if self.curState == World_pb.VOTING then --投票阶段，谁都不行 
             UIExtend.setCCControlButtonEnable(self.mFileCCBNode, 'mOpenSilo', false)
        end
    elseif self.curState == World_pb.LAUNCHING then 
        local text = 'X ' .. nuclearInfo.launchInfo.firePosX .. '  ,  Y ' .. nuclearInfo.launchInfo.firePosY
        UIExtend.setCCLabelString(ccbfile, 'mCoordinate', text)
    
        local remainTime = Utilitys.getCurDiffTime(nuclearInfo.launchInfo.launchTime/1000)
        if remainTime < 0 then --时间倒计时为0就隐藏进度条
            remainTime = 0
        end 
        local tmpStr = Utilitys.createTimeWithFormat(remainTime)
        UIExtend.setCCLabelString(ccbfile, 'mCD', tmpStr)
    end   
end

-- 更新研究部分
function RAAllianceSiloPage:_UpdateResearchPart(ccbfile, nuclearInfo)
    local text = ''

    if nuclearInfo.nuclearCreateEndTime == 0 then 
        if self.curType == Const_pb.GUILD_SILO then  --核弹
            text = _RALang('@NuclearResearchCost',guild_const_conf['nuclearProduceCost'].value) 
        else
            text = _RALang('@WeatherResearchCost',guild_const_conf['nuclearProduceCost'].value)
        end 

        UIExtend.setCCLabelString(ccbfile, 'mDetailsLabel4', text)        
        UIExtend.setNodeVisible(ccbfile,"mResearchBtn",true)
    else 

        if self.curType == Const_pb.GUILD_SILO then  --核弹
            text = _RALang('@NuclearResearch') .. ':'
        else
            text = _RALang('@WeatherResearch') .. ':'
        end 

        local remainTime = Utilitys.getCurDiffTime(nuclearInfo.nuclearCreateEndTime / 1000)

        if remainTime < 0 then --时间倒计时为0就隐藏进度条
            remainTime = 0
            UIExtend.setNodeVisible(ccbfile,"mResearchBtn",true)
        else
            UIExtend.setNodeVisible(ccbfile,"mResearchBtn",false)
        end 

        local tmpStr = Utilitys.createTimeWithFormat(remainTime)
        UIExtend.setCCLabelString(ccbfile, 'mDetailsLabel4', text .. tmpStr)        
    end 
end

-- 更新资源数目
function RAAllianceSiloPage:_UpdateMaterialNumPart(ccbfile, nuclearInfo)
    local text = ''
    if self.curType == Const_pb.GUILD_SILO then  --核弹
        text = _RALang('@NuclearMaterialNum') .. ':'
    else
        text = _RALang('@WeatherMaterialNum') .. ':'
    end 

    local curTime = common:getCurTime()
    local pastTime = os.difftime(curTime, nuclearInfo.nuclearResUpdateTime/1000)

    pastTime = pastTime - pastTime%60

    if self.speedPerSecond ~= nil then 
        self.collectedNum =  math.floor(self.speedPerSecond*pastTime) + nuclearInfo.nuclearReource
    else
        self.collectedNum = nuclearInfo.nuclearReource
    end 

    --超出上限
    if self.collectedNum >= guild_const_conf['allianceUraniumMaxStoreage'].value then 
        self.collectedNum  = guild_const_conf['allianceUraniumMaxStoreage'].value
    end 

    text = text ..  self.collectedNum .. '/' .. guild_const_conf['allianceUraniumMaxStoreage'].value
    --原料数目
    UIExtend.setCCLabelString(ccbfile, 'mDetailsLabel3', text)   
end


return RAAllianceSiloPage