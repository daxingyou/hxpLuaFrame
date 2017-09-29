--region RALordLiftingEffectPage.lua
--Author : Phan
--Date   : 2016/7/5
--此文件由[BabeLua]插件自动生成

RARequire("BasePage")

local UIExtend = RARequire("UIExtend")
local RAPlayerInfo = RARequire("RAPlayerInfo")
local player_advance_conf = RARequire("player_advance_conf")
local RAStringUtil = RARequire("RAStringUtil")
local Utilitys = RARequire("Utilitys")
local RALogicUtil = RARequire("RALogicUtil")
local RARootManager = RARequire("RARootManager")

local RALordLiftingEffectPage = BaseFunctionPage:new(...)

local RALordAdditionPopUpCellTitleListener = {}
local RALordAdditionPopUpCellListener = {}

function RALordLiftingEffectPage:Enter()
    self.ccbifile = UIExtend.loadCCBFile("RALordAdditionPopUp.ccbi", self)
    self.scrollView = UIExtend.getCCScrollViewFromCCB(self.ccbifile, "DetailDataSV")

    self:refreshUI()
    self:refreshLiftingEffect()
end

function RALordLiftingEffectPage:refreshUI()
    --set title
    UIExtend.setStringForLabel(self.ccbifile,{mInfoTitle = _RALang("@InfoTitle")})
    --set battlePoint
    local battlePointStr = Utilitys.formatNumber(RAPlayerInfo.raPlayerBasicInfo.battlePoint)
    UIExtend.setStringForLabel(self.ccbifile,{mGeneralFightValue = battlePointStr})
end

function RALordLiftingEffectPage:onClose()
    RARootManager.CloseCurrPage()
end

function RALordLiftingEffectPage:Exit()
    self.scrollView:removeAllCell()
    self.scrollView = nil
    UIExtend.unLoadCCBFile(RALordLiftingEffectPage)
    self.ccbifile = nil
end

-----------------------------------title--------------------------------------------------
function RALordAdditionPopUpCellTitleListener:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    return o
end

function RALordAdditionPopUpCellTitleListener:onRefreshContent(ccbRoot)
    local ccbfile = ccbRoot:getCCBFileNode() 
    if not ccbfile then return end

    local confInfo = player_advance_conf[self.id]
    local informationTitle = _RALang(confInfo.name)
    UIExtend.setStringForLabel(ccbfile,{mInformationTitle = informationTitle})
end

-------------------------------cell-----------------------------------------------------------
function RALordAdditionPopUpCellListener:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    return o
end

function RALordAdditionPopUpCellListener.onLongClick(data)
    
    local handler = data.handler
    local confInfo = player_advance_conf[handler.id]

    local paramMsg = {}
    paramMsg.title = _RALang(confInfo.name)
    paramMsg.htmlStr = _RALang(confInfo.des)
    paramMsg.relativeNode = handler.ccbfile
    RARootManager.ShowTips(paramMsg)
end

function RALordAdditionPopUpCellListener.onShortClick(data)
    print(tostring("onTouchMoveonTouchMoveonTouchMoveonTouchMove"))
    RARootManager.RemoveTips()
end

function RALordAdditionPopUpCellListener:onRefreshContent(ccbRoot)
    local ccbfile = ccbRoot:getCCBFileNode() 
    if not ccbfile then return end
    ccbfile:setTag(self.id)
    self.ccbfile = ccbfile
    local tipsBtn = UIExtend.getCCControlButtonFromCCB(ccbfile,"mTipsBtn")
    tipsBtn:setVisible(false)
    local tipsBtnNode = ccbfile:getCCNodeFromCCB("mTipsBtnNode")
    local containsPoint = function ( worldPos )
        local scrollView = self.scrollView
        return UIExtend.scrollViewContainPoint(scrollView, worldPos)
    end      
    UIExtend.createClickNLongClick(tipsBtnNode,RALordAdditionPopUpCellListener.onShortClick,
    RALordAdditionPopUpCellListener.onLongClick,{handler = self,endedColse = true,delay = 0.0, containsPoint = containsPoint})

    local confInfo = player_advance_conf[self.id]
    if not confInfo then return end
    local detailTitle = _RALang(confInfo.name)
    UIExtend.setStringForLabel(ccbfile,{mDetailTitle = detailTitle})

    local effectList =RAStringUtil:split(confInfo.effect,",")
    local value = 0
    for i = 1, #effectList do
        local effect = tonumber(effectList[i])
        local effectNum = RALogicUtil:getEffectResult(effect)
        value = value + effectNum
    end
    if confInfo.NumSymbol == 1 then
        value ="+" .. value/100 .. "%"
    else
        value = "-" .. value/100 .. "%"
    end
    
    UIExtend.setStringForLabel(ccbfile,{mDetailNum = tostring(value)})
end

----------------------------------------------------end--------------------------------------------

function RALordLiftingEffectPage:refreshLiftingEffect()
    self.scrollView:removeAllCell()
    local list = Utilitys.table_pairsByKeys(player_advance_conf)
    for k, v in list do
        if v.site == 0 then
            local titleListener = RALordAdditionPopUpCellTitleListener:new({
                id = v.id
            })
            local cell = CCBFileCell:create()
	        cell:setCCBFile("RALordAdditionPopUpCellTitle.ccbi")
            cell:registerFunctionHandler(titleListener)

            self.scrollView:addCell(cell)
        else
            local detalListener = RALordAdditionPopUpCellListener:new({
                id = v.id,
                scrollView = self.scrollView
            })
            local cell = CCBFileCell:create()
	        cell:setCCBFile("RALordAdditionPopUpCell.ccbi")
            cell:registerFunctionHandler(detalListener)

            self.scrollView:addCell(cell)
        end
    end
    self.scrollView:orderCCBFileCells(self.scrollView:getViewSize().width)
end

return RALordLiftingEffectPage
  
--endregion
