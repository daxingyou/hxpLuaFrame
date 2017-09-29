--================================================================================
-- Base Class for Function page
local Utilitys  = RARequire('Utilitys')
RARequire('RAUIDefine')


BaseFunctionPage = {}
function BaseFunctionPage:new(_fileName,o)
    _pageName = _fileName or nil
    if _pageName~= nil then
       _pageName =  Utilitys.findLastDotStr(_pageName)
    end
    o = o or {}
	o = Utilitys.table_merge({ ccbfile = nil, co = nil,pco=nil, delay_unLock = false, PacketHandlers = {},},o)
    setmetatable(o,self)
    self.__index = self
    --self.owner = o
    --need to do by zhenhui
    --self.pageName = _pageName
    if _fileName ~= nil then 
    	package.loaded[_fileName] = o
    end 
    return o
end

--ÐÂµÄpageÖÐ¿ÉÒÔÖØÔØµÄº¯Êý£¬²»Ç¿ÖÆp
function BaseFunctionPage:Enter(data) end
function BaseFunctionPage:Exit() return {} end
--[[
	-- 注掉空方法，保持父类简洁。尤其Execute()方法
function BaseFunctionPage:Execute() end

function BaseFunctionPage:CommonRefresh(data)
	CCLuaLog("BaseFunctionPage:CommonRefresh")
end

function BaseFunctionPage:GetIn() end
function BaseFunctionPage:GetOut() end
--]]

function BaseFunctionPage:IsNeedSendPackage() return false,nil end


function BaseFunctionPage:AddNoTouchLayer(isBlankClose,swallowTouch)
    local UIExtend = RARequire('UIExtend')
	self:RemoveNoTouchLayer()
    --judge if swallow touch,default is true
    if swallowTouch == nil then swallowTouch = true end
	if self:getRootNode() ~= nil then

		local layer = self:getRootNode():getChildByTag(61001);
		if not layer then
			layer = CCLayer:create();
			layer:setTag(61001);
		end

		--local layer = CCLayer:create()
		if isBlankClose then
			self.mContentSizeNode = UIExtend.getCCNodeFromCCB(self.ccbfile,"mContentSizeNode")
			-- register handler
			if self.mContentSizeNode ~= nil then
				local isStartPosInside = true
				local callback = function(pEvent, pTouch)
					CCLuaLog("event name:"..pEvent)

					--起始点和结束点都在外面的时候才关闭
					--the startPos and endPos are all outSide to close the page
                    if pEvent == "began" then

                    	local RALogicUtil = RARequire('RALogicUtil')
						local isInside = RALogicUtil:isTouchInside(self.mContentSizeNode, pTouch)
						if not isInside then 
                            isStartPosInside = false
                        end
                        return 1
                    end
					if pEvent == "ended" then
						local RALogicUtil = RARequire('RALogicUtil')
						local isInside = RALogicUtil:isTouchInside(self.mContentSizeNode, pTouch)
						if not isInside  and not isStartPosInside then

							--close play click effect
					        local common = RARequire("common")
					        common:playEffect("closeClick")

							if self.closeFunc ~= nil then
								self.closeFunc()		
							else

								local RARootManager = RARequire("RARootManager")
								--如果是奖励通用界面要等动作做完再关闭
								local RARewardPopupNewPage=RARequire("RARewardPopupNewPage")
								local isRewardComPage=RARootManager:isTargetPage("RARewardPopupNewPage")
								if isRewardComPage and RARewardPopupNewPage.canClick then 
									RARequire("MessageDefine")
							        RARequire("MessageManager")
							        
							        MessageManager.sendMessage(MessageDef_Reward.Disappear)
							        return 
								end
				
								RARootManager.CloseCurrPage()
							end
						end
					end
				end
				layer:registerScriptTouchHandler(callback, false, NoTouchLayerPriority_Page, swallowTouch)
			end
		end
	    layer:setContentSize(CCDirector:sharedDirector():getOpenGLView():getVisibleSize())
	    layer:setPosition(ccp(0,0))
	    layer:setAnchorPoint(ccp(0,0))
	    layer:setTouchEnabled(true)
	    layer:setTouchMode(kCCTouchesOneByOne)
	    self:getRootNode():addChild(layer,-1)	
	    self.mNoTouchLayer = layer
	end
end

function BaseFunctionPage:RemoveNoTouchLayer()
	if self:getRootNode() ~= nil and self.mNoTouchLayer ~= nil then
		self:getRootNode():removeChild(self.mNoTouchLayer, true)
		self.mNoTouchLayer = nil
	end
end



--ÐÂµÄpageÖÐ²»ÒªÖØÐÂ¶¨ÒåÏÂÃæ3¸öº¯Êý,Ò²²»Òªµ÷ÓÃ
function BaseFunctionPage:Animation_Lock(_co)
	self.co = _co
	self.delay_unLock = false
end	

function BaseFunctionPage:Animation_Delay_unLock()
	self.delay_unLock = true
end

function BaseFunctionPage:Animation_unLock(ccbfile)
	if not ccbfile and self.delay_unLock then return end
	if self.co then 		
		coroutine.resume(self.co)
		self.co = nil
		self.delay_unLock = false
	end 
end

--ÐÂµÄpageÖÐ²»ÒªÖØÐÂ¶¨Òå£¬ÒÔÏÂº¯Êý½ö¹©µ÷ÓÃ
function BaseFunctionPage:getRootNode() return self.ccbfile end


function BaseFunctionPage:SetTitleCCBI(pageName)
	self.mPageName = pageName
	local _, pageItem = Utilitys.table_find(TableReader.getDataTable("PageDefineTable"), function (k,v)
		return v.sourceName == pageName
	end)
	
	if not pageItem then return end
	
	local titleccbfile = pageItem.titleCCBI
	if titleccbfile and titleccbfile ~= "none" then
		local titleCCB = RABasePage:CreateWithoutPool(titleccbfile)
		if self.mTitle and titleCCB then
			self.mTitle:removeAllChildrenWithCleanup(true)
			self.mTitle:addChild(titleCCB)
		end
	end
	
	self.mFrameTitle:setString(pageItem.name)
end

function BaseFunctionPage:AllCCBRunAnimation(animationName)
	self.ccbfile:runAnimation(animationName,true)
	--self.mMainFrameTop:runAnimation(animationName,true)
	--self.mMainFrameBottom:runAnimation(animationName,true)
end

function BaseFunctionPage:RegisterPacketHandler(OPCode)
	self.PacketHandlers[#self.PacketHandlers + 1] = PacketScriptHandler:new(OPCode, self)
end

function BaseFunctionPage:RemovePacketHandlers()
	for k,v in ipairs(self.PacketHandlers) do
		if self.PacketHandlers[k] then
			self.PacketHandlers[k]:delete()
		end			
	end
	self.PacketHandlers = {}
end
function BaseFunctionPage:onPageInfo()
    RARequire('PriorityQuene')
	local _, pageItem = Utilitys.table_find(TableReader.getDataTable("PageDefineTable"), function (k,v)
		return v.sourceName == self.mPageName
	end)
	if not pageItem then return end
	showTitleInfoPage(pageItem.titleInfo,PriorityQuene.priorityLevel.YES_NO)
end


function BaseFunctionPage:setCoroutine(co)
	self.pco = co
end

function BaseFunctionPage:onReceiveFailed(handler)
	if self.pco then
		coroutine.resume(self.pco,false)
		self.pco = nil
	end
end
function BaseFunctionPage:onTimeout(handler)
	if self.pco then
		coroutine.resume(self.pco,false)
		self.pco = nil
	end
end
function BaseFunctionPage:onSendFailed(handler)
	if self.pco then
		coroutine.resume(self.pco,false)
		self.pco = nil
	end
end
function BaseFunctionPage:onReConnectionError(handler)
	if self.pco then
		coroutine.resume(self.pco,false)
		self.pco = nil
	end
end
function BaseFunctionPage:onReLoginError(handler)
	if self.pco then
		coroutine.resume(self.pco,false)
		self.pco = nil
	end
end
function BaseFunctionPage:onDisConnection(handler)
	if self.pco then
		coroutine.resume(self.pco,false)
		self.pco = nil
	end
end
--================================================================================