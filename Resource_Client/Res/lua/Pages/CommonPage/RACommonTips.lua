--region *.lua
--Date
--此文件由[BabeLua]插件自动生成
local RARootManager = RARequire("RARootManager")
local UIExtend = RARequire('UIExtend')
local RALogicUtil = RARequire("RALogicUtil")

local RACommonTips = BaseFunctionPage:new(...)


function RACommonTips:Enter(data)
	local ccbiFileName = data.ccbiFileName or "RACommonTips.ccbi"
	local ccbfile = UIExtend.loadCCBFile(ccbiFileName,self)    
	self:refreshPage(data)
end

function RACommonTips:refreshPage(data)
    local strLabel = {}
    assert(data.htmlStr ~=nil and data.relativeNode ~=nil,"error ")
    strLabel["mTitleName"] = data.title or ""
    strLabel["mNum"] = data.num or ""

    UIExtend.setStringForLabel(self.ccbfile,strLabel)

    if data.titleNameColor then
        local strColorLabel = {}
        strColorLabel["mTitleName"] = RALogicUtil:getLabelNameColor(data.titleNameColor)
        UIExtend.setColorForLabel(self.ccbfile, strColorLabel)
    end

    local htmlLabel = self.ccbfile:getCCLabelHTMLFromCCB("mHTMLLabel")
    htmlLabel:setPreferredSize(400,400)
    UIExtend.setChatLabelHTMLString(self.ccbfile, "mHTMLLabel", data.htmlStr, (data.labelHeight or 290),"#ffffff")

    local mScale9Sprite = self.ccbfile:getCCScale9SpriteFromCCB("mScaleSprite")
    local labelSize = htmlLabel:getHTMLContentSize();

    if data.icon then
        UIExtend.addSpriteToNodeParent(self.ccbfile, "mIconNode",data.icon)
    end

    if data.qualityFarme then
        UIExtend.addSpriteToNodeParent(self.ccbfile, "mQualityNode",data.qualityFarme)
    end

    local tipWidth =350
    local tipHeightBase = 30
    local spriteContentSize = CCSizeMake(tipWidth, labelSize.height + tipHeightBase)
    local winSize = CCDirector:sharedDirector():getWinSize();
    --如果没有icon的话,需要根据文字width来设置背景contentSize
    if data.icon then  
        local mIconNode = self.ccbfile:getCCNodeFromCCB("mIconNode")
        if mIconNode then
            spriteContentSize = CCSizeMake(tipWidth, mIconNode:getContentSize().height + 15)
        end
    end
    mScale9Sprite:setContentSize(spriteContentSize);

    local relativeNode = data.relativeNode
    local posX, posY = relativeNode:getPosition();
	local size = relativeNode:getContentSize()

    if relativeNode:getParent() == nil then 
        RARootManager.RemoveTips()  
        return 
    end 

	local pos = relativeNode:getParent():convertToWorldSpace(ccp(posX + size.width * 2/ 3, posY + spriteContentSize.height + size.height -20));
--	if pos.x + tipWidth > winSize.width then
--		pos = relativeNode:getParent():convertToWorldSpace(ccp(posX, posY));
--		pos.x = pos.x - tipWidth;
--	end
	local newPos = RARootManager.mMsgBoxNode:convertToNodeSpace(pos);
	self.ccbfile:setPosition(newPos);
    self.ccbfile:setAnchorPoint(1,0)

    self.closeFunc = function()
        CCLuaLog("close func test in cdk page")
        RARootManager.RemoveTips()  
    end

end

function RACommonTips:Exit()
	UIExtend.unLoadCCBFile(self)
end

return RACommonTips
--endregion

