-- RAAllianceSiloPlatformPage.lua
-- 联盟核弹发射平台
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

local RAAllianceSiloPlatformPage = BaseFunctionPage:new(...)
RAAllianceSiloPlatformPage.mVotesHandler = {}

local MovableBuildStateTxt = 
{
    [GuildManor_pb.NONE_STATE] = {state = '@SuperWeaponPlatformNoBuild'},
    [GuildManor_pb.BUILDING_STATE] = {state = '@SuperWeaponPlatformBuilding'},
    [GuildManor_pb.FINISHED_STATE] = {state = '@SuperWeaponPlatformOverBuild'}
}


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
        RAAllianceSiloPlatformPage:RefreshUI()
    elseif message.messageID == MessageDef_Packet.MSG_Operation_Fail then
        if message.opcode == HP_pb.GET_NUCLEAR_INFO_C then
            print('RAAllianceSiloPlatformPage  get nuclear Info failed, close self page')
            -- RARootManager.ClosePage('RAAllianceSiloPlatformPage')
        end
    end
end

function RAAllianceSiloPlatformPage:_RegisterMessageHandlers()
    for _, msgId in ipairs(msgTB) do
        MessageManager.registerMessageHandler(msgId, OnReceiveMessage)
    end
end


function RAAllianceSiloPlatformPage:_UnregisterMessageHandlers()
    for _, msgId in ipairs(msgTB) do
        MessageManager.removeMessageHandler(msgId, OnReceiveMessage)
    end
end

function RAAllianceSiloPlatformPage:_RegisterPacketHandlers()
    self.mPacketHandlers = RANetUtil:addListener(opcodeTB, self)
end

function RAAllianceSiloPlatformPage:_UnregisterPacketHandlers()
    RANetUtil:removeListener(self.mPacketHandlers)
end

function RAAllianceSiloPlatformPage:onReceivePacket(handler)
    local opcode = handler:getOpcode()
    local buffer = handler:getBuffer()        
    -- -- 请求返回
    -- if opcode == HP_pb.GET_NUCLEAR_INFO_S then --获得超级武器
    --     local allianceNuclearInfo = RAAllianceProtoManager:getNuclearInfo(buffer)
    --     RAAllianceManager:GetNuclearInfo() = allianceNuclearInfo
    --     self:RefreshUI()
    -- end
end


function RAAllianceSiloPlatformPage:Enter(data)
    self.curType = RAAllianceManager:getSelfSuperWeaponType() 
    if self.curType == Const_pb.GUILD_SILO then  --核弹
        self.ccbfile = UIExtend.loadCCBFile("RAAllianceTerritoryNuclearPopUp2.ccbi", self)
    else
        self.ccbfile = UIExtend.loadCCBFile('RAAllianceTerritorySkyConPopUp2.ccbi', self)    
    end 
    self.mLastUpdateTime = 0

    self:_RegisterMessageHandlers()
    self:_RegisterPacketHandlers()

    RAAllianceProtoManager:reqNuclearInfo()

    self:_RefreshConfigPart()
    self:RefreshUI()
end

function RAAllianceSiloPlatformPage:Execute()
    self.mLastUpdateTime = self.mLastUpdateTime + common:getFrameTime()
    if self.mLastUpdateTime > 1 then
        self.mLastUpdateTime = 0
        self:_RefreshByTime()
    end
end

function RAAllianceSiloPlatformPage:Exit()
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

     UIExtend.removeHtmlLabelListener(self.ccbfile, 'mCoordinate1')
     UIExtend.removeHtmlLabelListener(self.ccbfile, 'mCoordinate2')

    self:_UnregisterPacketHandlers()
    self:_UnregisterMessageHandlers()
end


--HUD弹出动画结束处理
function RAAllianceSiloPlatformPage:OnAnimationDone()
    local lastAnimationName = self.ccbfile:getCompletedAnimationName()
    CCLuaLog('OnAnimationDone' .. lastAnimationName)
    if lastAnimationName == 'mFileCCBNode_OpenTheDoorAni' then 
        UIExtend.setNodeVisible(self.mFileCCBNode, 'mReadyToLaunchBtnNode', false)
        self.isAnimation = false
    end 
end

function RAAllianceSiloPlatformPage:onOpenSilo()
    if self:isInVotePage() then
        if self.curState == World_pb.CAN_OPENUP then 
            RAAllianceProtoManager:reqOpenNulcear()
        end         
        local RAWorldManager = RARequire('RAWorldManager')
        RARootManager.CloseAllPages()
        local platformInfo = RAAllianceManager:GetNuclearPlatformInfo()
        RAWorldManager:LaunchBombAt(platformInfo.posX, platformInfo.posY)
    end 
end

function RAAllianceSiloPlatformPage:onMainCancelLaunchBtn()
    RAAllianceProtoManager:reqCancelNuclear()
end

-- 制造核弹
function RAAllianceSiloPlatformPage:onManufactureBtn()
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

    --原料不足不判断了，这个页面没有显示
    -- if self.collectedNum < guild_const_conf['nuclearProduceCost'].value then 
    --     RARootManager.ShowMsgBox(_RALang("@NotHaveEnoughMaterial",guild_const_conf['nuclearProduceCost'].value))
    --     return 
    -- end 
    RAAllianceProtoManager:sendCreateWeaponReq()
end


--保护时间问号按钮
function RAAllianceSiloPlatformPage:onHelpBtn()
    if self:isInVotePage() then
        local confirmData = {}
        confirmData.labelText = _RALang("@SuperWeaponProtectTimeTip")
        confirmData.yesNoBtn=false
        RARootManager.OpenPage("RAConfirmPage", confirmData,false,true,true)
    end 
end

function RAAllianceSiloPlatformPage:onCancelLaunch()
    CCLuaLog('onCancelLaunch')
    if self:isInVotePage() then
        RAAllianceProtoManager:reqCancelNuclear()
    end
end

function RAAllianceSiloPlatformPage:isInVotePage()
    if self.curState ==  World_pb.VOTING or self.curState == World_pb.CAN_OPENUP or self.curState == World_pb.CAN_LAUNCH then 
        return true
    end 
    return false
end


function RAAllianceSiloPlatformPage:onCheckCDBtn()
    local RAWorldManager = RARequire('RAWorldManager')
    local nuclearInfo = RAAllianceManager:GetNuclearInfo()
    if nuclearInfo ~= nil then        
        RAWorldManager:LocateAt(nuclearInfo.launchInfo.firePosX, nuclearInfo.launchInfo.firePosY)
        RARootManager.CloseAllPages()
    end
end

function RAAllianceSiloPlatformPage:onClose()
    --关闭
    RARootManager.ClosePage("RAAllianceSiloPlatformPage")
end

function RAAllianceSiloPlatformPage:onConfirm()
    RARootManager.ShowMsgBox('@NoOpenTips')
end


function RAAllianceSiloPlatformPage:onErectedBtn()
    -- 架设
    -- 联盟积分消耗确认
    local RAAllianceManager = RARequire('RAAllianceManager')
    local allianceScore = RAAllianceManager.allianScore or 0
    local guild_const_conf = RARequire('guild_const_conf')
    local cost = guild_const_conf.platformBuildingCost.value
    
    if allianceScore < cost then
        local RARootManager = RARequire('RARootManager')
        RARootManager.ShowMsgBox('@LackAllianceContributionToBuildSilo')
        return
    else
        local RAWorldManager = RARequire('RAWorldManager')    
        RAWorldManager:BuildSiloAt()
        RARootManager.CloseAllPages()
    end
end

function RAAllianceSiloPlatformPage:onCancelErectionBtn()
    -- 取消架设
    RANetUtil:sendPacket(HP_pb.NUCLEAR_MANCHINE_CANCEL_C,nil,{retOpcode=-1})
end

function RAAllianceSiloPlatformPage:onGiveUpPlatformBtn()
    -- 放弃平台    
    local confirmData =
    {
        labelText = _RALang('@ConfirmIsClearPlatform'),
        yesNoBtn = true,
        resultFun = function (isOK)
            if isOK then
                local RANetUtil = RARequire('RANetUtil')
                RANetUtil:sendPacket(HP_pb.NUCLEAR_MANCHINE_CANCEL_C,nil,{retOpcode=-1})
            end
        end
    }
    RARootManager.showConfirmMsg(confirmData)
end

function RAAllianceSiloPlatformPage:onReadyToLaunch()
    CCLuaLog('onReadyToLaunch')

    local nuclearInfo = RAAllianceManager:GetNuclearInfo()
    if nuclearInfo == nil then 
        return 
    end 

    if nuclearInfo.machineInfo.machineState ~= GuildManor_pb.FINISHED_STATE then
        RARootManager.ShowMsgBox(_RALang("@PlatformHasNotFinished"))
        return
    end

    if nuclearInfo.launchInfo.launchType == GuildManor_pb.FROM_MANOR then
        RARootManager.ShowMsgBox(_RALang("@CurLaunchStateIsManor"))
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

    RAAllianceProtoManager:reqBeginNuclearVote(GuildManor_pb.FROM_MACHINE)
    -- self.mFileCCBNode:runAnimation('OpenTheDoorAni')
end


function RAAllianceSiloPlatformPage:_RefreshConfigPart()
    local buildData = nil
    local territory_building_conf = RARequire('territory_building_conf')
    if self.curType == Const_pb.GUILD_SILO then
        buildData = territory_building_conf[Const_pb.NUCLEAR]
    elseif self.curType == Const_pb.GUILD_WEATHER then
        buildData = territory_building_conf[Const_pb.WEATHER]
    end
    local ccbfile = self.ccbfile
    if ccbfile == nil or buildData == nil then return end

    -- rolling text
    self.mExplainLabel = UIExtend.getCCLabelTTFFromCCB(self.ccbfile,'mExplainLabel')
    self.mExplainLabelStarP =ccp(self.mExplainLabel:getPosition())

    if self.curType == Const_pb.GUILD_SILO then  --核弹
        self.mExplainLabel:setString(_RALang('@AllianceSiloPlatformDesc'))        
        local explainStr = _RALang('@AllianceNuclearPlatExplainDesc') .. '\n' .. 
            _RALang('@AllianceNuclearPlatExplainDesc2') .. '\n'..
            _RALang('@AllianceNuclearPlatExplainDesc3') .. '\n'..
            _RALang('@AllianceNuclearPlatExplainDesc4')
        UIExtend.setCCLabelString(ccbfile, 'mNuclearExplainLabel', explainStr)
        UIExtend.setCCLabelString(ccbfile, 'mLaunchTitle', _RALang('@TheNuclearLaunch'))

        self.storageLimit = guild_const_conf['nuclearStorageLimit'].value
    else
        self.mExplainLabel:setString(_RALang('@AllianceWeatherPlatformDesc'))        
        local explainStr = _RALang('@AllianceWeatherPlatExplainDesc') .. '\n' .. 
            _RALang('@AllianceWeatherPlatExplainDesc2') .. '\n'..
            _RALang('@AllianceWeatherPlatExplainDesc3') .. '\n'..
            _RALang('@AllianceWeatherPlatExplainDesc4')        
        UIExtend.setCCLabelString(ccbfile, 'mNuclearExplainLabel', explainStr)
        UIExtend.setCCLabelString(ccbfile, 'mLaunchTitle', _RALang('@LaunchWeather'))

        self.storageLimit = guild_const_conf['thunderStorageLimit'].value
    end 

    local buildPic = UIExtend.getCCSpriteFromCCB(self.ccbfile,'mWeaponBuildPic')
    buildPic:setTexture(buildData.icon)    
    UIExtend.setCCLabelString(ccbfile, 'mCollectionName', _RALang(buildData.name))

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

function RAAllianceSiloPlatformPage:RefreshUI()
    local nuclearInfo = RAAllianceManager:GetNuclearInfo()
    local ccbfile = self.ccbfile
    if nuclearInfo == nil or ccbfile == nil then return end
    
    self:_UpdateByState(nuclearInfo.launchInfo.state)
    self:_RefreshByTime()
end


function RAAllianceSiloPlatformPage:_UpdateByState(curLaunchState)
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
    if nuclearInfo.launchInfo.launchType ~= GuildManor_pb.FROM_MANOR then
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
        UIExtend.setControlButtonTitle(self.mFileCCBNode, 'mReadyToLaunch',_RALang('@ManorLaunching'))
        UIExtend.setCCControlButtonEnable(self.mFileCCBNode, 'mReadyToLaunch', false)
        UIExtend.setNodeVisible(self.mFileCCBNode, 'mReadyToLaunchBtnNode', true)
    end
    self.curState = curLaunchState

    -- 刷新核弹数量
    local numText = ''
    if self.curType== Const_pb.GUILD_SILO then  --核弹
        numText = _RALang('@NuclearWeaponNum') .. ':'
        numText = numText .. nuclearInfo.count .. '/' .. self.storageLimit
    else
        numText = _RALang('@WeatherWeaponNum') .. ':'
        numText = numText .. nuclearInfo.count .. '/' .. self.storageLimit
    end    
    UIExtend.setCCLabelString(ccbfile, 'mSWNum', numText)

end

-- 刷新投票相关
function RAAllianceSiloPlatformPage:_UpdateVotePanels()
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
function RAAllianceSiloPlatformPage:_RefreshByTime()
    local nuclearInfo = RAAllianceManager:GetNuclearInfo()
    local ccbfile = self.ccbfile
    if nuclearInfo == nil or ccbfile == nil then return end

    self:_UpdatePlatBuildingPart(ccbfile, nuclearInfo)

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

    if nuclearInfo.launchInfo.launchType ~= GuildManor_pb.FROM_MANOR then
        local btnStrKey = ''
        local btnEnable = false
        if nuclearInfo.machineInfo.machineState == GuildManor_pb.NONE_STATE then
            btnStrKey = '@NuclearPlatformNotBuildBtnKey'
        elseif nuclearInfo.machineInfo.machineState == GuildManor_pb.BUILDING_STATE then
            btnStrKey = '@NuclearPlatformIsBuildingBtnKey'
        elseif nuclearInfo.machineInfo.machineState == GuildManor_pb.FINISHED_STATE then
            btnStrKey = '@ReadyToVote'
            btnEnable = true
        end
        UIExtend.setControlButtonTitle(self.mFileCCBNode, 'mReadyToLaunch',_RALang(btnStrKey))
        UIExtend.setCCControlButtonEnable(self.mFileCCBNode, 'mReadyToLaunch', btnEnable) 
    end
end



-- 更新架设过程中
function RAAllianceSiloPlatformPage:_UpdatePlatBuildingPart(ccbfile, nuclearInfo)
    if nuclearInfo == nil or ccbfile == nil then return end

    local platformInfo = nuclearInfo.machineInfo

    local nodesVisible = {
        mUnbuiltNode = false,
        mConstructionNode = false,
        mHasBeenBuiltNode = false,
    }
    UIExtend.setNodesVisible(ccbfile, nodesVisible)
    local txtMap = {}

    local stateKey = MovableBuildStateTxt[platformInfo.machineState].state
    local guild_const_conf = RARequire('guild_const_conf')
    -- 刷新平台状态    
    if platformInfo.machineState == GuildManor_pb.NONE_STATE then
        nodesVisible.mUnbuiltNode = true
        txtMap.mPlatfomrState1 = _RALang(stateKey)
        -- 获取联盟当前积分
        local allianceScore = RAAllianceManager.allianScore
        local cost = guild_const_conf.platformBuildingCost.value
        local htmlLabel = UIExtend.getCCLabelHTMLFromCCB(ccbfile, 'mPoints')
        if htmlLabel then
            local htmlStr = RAStringUtil:getHTMLString('SuperWeaponPlatformStateKey1', allianceScore, cost)
            htmlLabel:setString(htmlStr)
        end
        -- UIExtend.setCCControlButtonEnable(self.mFileCCBNode, 'mReadyToLaunch', false)
    elseif platformInfo.machineState == GuildManor_pb.BUILDING_STATE then
        nodesVisible.mConstructionNode = true
        -- 秒
        local costTimeCfg = guild_const_conf.platformBuilding.value
        local diffTime = platformInfo.machineFinishTime / 1000 - common:getCurTime()
        local percent = diffTime / costTimeCfg
        if percent > 1 then percent = 1 end
        local mBar = UIExtend.getCCScale9SpriteFromCCB(ccbfile, 'mBar')
        if mBar ~= nil then
            mBar:setScaleX(1 - percent)
        end
        UIExtend.setCCLabelString(ccbfile, 'mBarTime', _RALang('@SuperWeaponPlatformBuildingWithTime', Utilitys.createTimeWithFormat(diffTime)))
        local htmlLabel = UIExtend.getCCLabelHTMLFromCCB(ccbfile, 'mCoordinate1')
        if htmlLabel then
            htmlLabel:removeLuaClickListener()
            local nameStr = platformInfo.posX .. ',' .. platformInfo.posY
            local RAStringUtil = RARequire('RAStringUtil')
            local htmlStr = RAStringUtil:getHTMLString('SuperWeaponPlatformStateKey2', nameStr, platformInfo.posX, platformInfo.posY)
            htmlLabel:setString(htmlStr)
            htmlLabel:registerLuaClickListener(function(id, data)
                local RAGameConfig = RARequire('RAGameConfig')
                if id == RAGameConfig.HTMLID.WorldPosShow then
                    local pos = RAStringUtil:split(data or '', ',') or {}
                    local x, y = unpack(pos)
                    if x and y then
                        RARootManager.CloseAllPages()
                        local RAWorldManager = RARequire('RAWorldManager')
                        RAWorldManager:LocateAt(tonumber(x), tonumber(y))
                    end
                end
            end)
        end
        -- UIExtend.setCCControlButtonEnable(self.mFileCCBNode, 'mReadyToLaunch', false)
    elseif platformInfo.machineState == GuildManor_pb.FINISHED_STATE then
        nodesVisible.mHasBeenBuiltNode = true
        txtMap.mPlatfomrState2 = _RALang(stateKey)
        local htmlLabel = UIExtend.getCCLabelHTMLFromCCB(ccbfile, 'mCoordinate2')
        if htmlLabel then
            htmlLabel:removeLuaClickListener()
            local nameStr = platformInfo.posX .. ',' .. platformInfo.posY
            local RAStringUtil = RARequire('RAStringUtil')
            local htmlStr = RAStringUtil:getHTMLString('SuperWeaponPlatformStateKey3', nameStr, platformInfo.posX, platformInfo.posY)
            htmlLabel:setString(htmlStr)
            htmlLabel:registerLuaClickListener(function(id, data)
                local RAGameConfig = RARequire('RAGameConfig')
                if id == RAGameConfig.HTMLID.WorldPosShow then
                    local pos = RAStringUtil:split(data or '', ',') or {}
                    local x, y = unpack(pos)
                    if x and y then
                        RARootManager.CloseAllPages()
                        local RAWorldManager = RARequire('RAWorldManager')
                        RAWorldManager:LocateAt(tonumber(x), tonumber(y))
                    end
                end
            end)
        end
        -- UIExtend.setCCControlButtonEnable(self.mFileCCBNode, 'mReadyToLaunch', true)
    end

    UIExtend.setNodesVisible(ccbfile, nodesVisible)
    UIExtend.setStringForLabel(ccbfile, txtMap)

    -- 刷新研究倒计时
    if nuclearInfo.nuclearCreateEndTime > 0 then         
        if self.curType == Const_pb.GUILD_SILO then  --核弹
            text = _RALang('@NuclearResearch') .. ':'
        else
            text = _RALang('@WeatherResearch') .. ':'
        end 

        local remainTime = Utilitys.getCurDiffTime(nuclearInfo.nuclearCreateEndTime / 1000)

        if remainTime < 0 then
            remainTime = 0
            UIExtend.setNodeVisible(ccbfile,"mManufactureBtn",true)
        else
            UIExtend.setNodeVisible(ccbfile,"mManufactureBtn",false)
        end 

        local tmpStr = Utilitys.createTimeWithFormat(remainTime)
        UIExtend.setCCLabelString(ccbfile, 'mSWNum', text .. tmpStr)        
    else
        -- 刷新核弹数量
        local numText = ''
        if self.curType== Const_pb.GUILD_SILO then  --核弹
            numText = _RALang('@NuclearWeaponNum') .. ':'
            numText = numText .. nuclearInfo.count .. '/' .. self.storageLimit
        else
            numText = _RALang('@WeatherWeaponNum') .. ':'
            numText = numText .. nuclearInfo.count .. '/' .. self.storageLimit
        end    
        UIExtend.setCCLabelString(ccbfile, 'mSWNum', numText)
        UIExtend.setNodeVisible(ccbfile,"mManufactureBtn",true)
    end 
end


return RAAllianceSiloPlatformPage