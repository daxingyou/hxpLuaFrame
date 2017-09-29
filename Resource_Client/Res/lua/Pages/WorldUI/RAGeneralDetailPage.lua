RARequire('BasePage')
local RAGeneralDetailPage = BaseFunctionPage:new(...)

local RAPlayerInfoManager = RARequire('RAPlayerInfoManager')
local UIExtend = RARequire('UIExtend')
local RALogicUtil = RARequire('RALogicUtil')
local Utilitys = RARequire('Utilitys')
local player_details_conf = RARequire('player_details_conf')
local RAStringUtil = RARequire('RAStringUtil')
local RARootManager = RARequire('RARootManager')

-----------------------------------------------------------
local RADetailPlayerInfoTitleCellListener =
{
    id = 0
}

function RADetailPlayerInfoTitleCellListener:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    return o
end 

function RADetailPlayerInfoTitleCellListener:onRefreshContent(ccbRoot)
    local confInfo = player_details_conf[self.id]

	local ccbfile = ccbRoot:getCCBFileNode() 
    if ccbfile then
        UIExtend.setCCLabelString(ccbfile, 'mInformationTitle', _RALang(confInfo.name))
    end
end


------------------------------------------------------------
local RADetailPlayerInfoCellListener = 
{
    id = 0
}

function RADetailPlayerInfoCellListener:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    return o
end

function RADetailPlayerInfoCellListener:onRefreshContent(ccbRoot)
	local ccbfile = ccbRoot:getCCBFileNode() 
    if not ccbfile then
        return
    end
    self.ccbfile = ccbfile

    local tipsBtn = UIExtend.getCCControlButtonFromCCB(ccbfile,'mTipsBtn')
    local containsPoint = function ( worldPos )
        local scrollView = self.scrollView
        return UIExtend.scrollViewContainPoint(scrollView, worldPos)
    end     
    UIExtend.createClickNLongClick(tipsBtn, self.onShortClick, self.onLongClick, {
        handler = self,
        endedColse = true, 
        delay = 0.0,
        containsPoint = containsPoint
    })

    local confInfo = player_details_conf[self.id]
    UIExtend.setCCLabelString(ccbfile, 'mDetailTitle', _RALang(confInfo.name))
    
    if confInfo.effect ~= nil then
        --根据effect 查找影响因子
        local effectNum = RALogicUtil:getLordDetailInfo(confInfo.effect, RAGeneralDetailPage.playerInfo.statInfo)
        if confInfo.numType == 1 then
            effectNum = effectNum * 100
            effectNum = effectNum..'%'
        end
        UIExtend.setCCLabelString(ccbfile, 'mDetailNum', effectNum)
    end
end

function RADetailPlayerInfoCellListener.onLongClick(data)
    local handler = data.handler
    local confInfo = player_details_conf[handler.id]

    local paramMsg = 
    {
        title = _RALang(confInfo.name),
        htmlStr = _RALang(confInfo.des),
        relativeNode = handler.ccbfile
    }
    RARootManager.ShowTips(paramMsg)
end

function RADetailPlayerInfoCellListener.onShortClick(data)
   RARootManager.ClosePage('RACommonTips')
end
------------------------------------------------------------------

RAGeneralDetailPage.playerInfo = nil
RAGeneralDetailPage.mScrollView = nil

function RAGeneralDetailPage:Enter(data)
    self.playerInfo = data.playerInfo

    UIExtend.loadCCBFile('RALordInformationPage.ccbi', self)
    self:_initPage()
    self:_refreshUI()
end

function RAGeneralDetailPage:Exit(data)
    self.mScrollView:removeAllCell()
    self.mScrollView = nil
    UIExtend.unLoadCCBFile(self)
    self.playerInfo = nil
end

function RAGeneralDetailPage:_initPage()
    UIExtend.setNodesVisible(self.ccbfile, {
        mChangeIcon = false,
        mReplaceImageBtn = false
    })
    UIExtend.setCCLabelString(self.ccbfile, 'mInfoTitle', _RALang('@CommanderDetails'))
    
    self.mScrollView = UIExtend.getCCScrollViewFromCCB(self.ccbfile, 'DetailDataSV')
end

function RAGeneralDetailPage:_refreshUI()
    self:_refreshTitleBar()
    self:_refreshDetail()    
end

function RAGeneralDetailPage:onClose()
    RARootManager.CloseCurrPage()
end

function RAGeneralDetailPage:_refreshTitleBar()
    local playerInfo = self.playerInfo
    
    UIExtend.setCCLabelString(self.ccbfile, 'mUserName', playerInfo.name)
    UIExtend.setCCLabelString(self.ccbfile, 'mKingdomNum', playerInfo.serverName)
    UIExtend.setCCLabelString(self.ccbfile, 'mUserLevel', playerInfo.level)
    UIExtend.setCCLabelString(self.ccbfile, 'mAlliance', playerInfo.guildName)

    local pwStr = RAStringUtil:getLanguageString('@BattlePointX', playerInfo.power)
    UIExtend.setCCLabelString(self.ccbfile, 'mFightValue', pwStr)

    local achievement = self.playerInfo.achievement or 0
    local achiStr = RAStringUtil:getLanguageString('@AchieveCompleted', achievement)
    UIExtend.setCCLabelString(self.ccbfile, 'mAchieveCompleted', achiStr)

    local killArmyNum = self.playerInfo.statInfo.armyKillCnt
    local killArmyStr = RAStringUtil:getLanguageString('@DistroyEnemy', killArmyNum)
    UIExtend.setCCLabelString(self.ccbfile, 'mDistroyEnemy', killArmyStr)

    -- 半身像
    local portrait = RAPlayerInfoManager.getPlayerBust(playerInfo.icon)
    UIExtend.setSpriteIcoToNode(self.ccbfile, 'mUserBustPic', portrait)
end

function RAGeneralDetailPage:_refreshDetail()
    self.mScrollView:removeAllCell()
    
    local targetType = RARequire('RAGameConfig').Player_Detail_Type_FightingState
    local filter = function (conf)
        return conf.type == targetType
    end
    
    for k, v in Utilitys.table_pairsByKeys(player_details_conf, filter) do
        if v.site == 0 then
            local titleListener = RADetailPlayerInfoTitleCellListener:new({id = v.id})
            local cell = CCBFileCell:create()
	        cell:setCCBFile('RALordInformationTitleCell.ccbi')
            cell:registerFunctionHandler(titleListener)

            self.mScrollView:addCell(cell)
        else
            local detalListener = RADetailPlayerInfoCellListener:new({id = v.id, scrollView = self.mScrollView})
            local cell = CCBFileCell:create()
	        cell:setCCBFile('RALordInformationCell.ccbi')
            cell:registerFunctionHandler(detalListener)

            self.mScrollView:addCell(cell)
        end
    end
    self.mScrollView:orderCCBFileCells(self.mScrollView:getViewSize().width)
end