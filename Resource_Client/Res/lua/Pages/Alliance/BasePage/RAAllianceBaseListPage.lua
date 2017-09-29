--联盟通用列表界面
--联盟标题栏
local RAAllianceBasePage = RARequire("RAAllianceBasePage")
RARequire('extern')
local UIExtend = RARequire('UIExtend')

local RAAllianceBaseListPage = class('RAAllianceBaseListPage',RAAllianceBasePage)

--子类实现
function RAAllianceBaseListPage:initScrollview()
	self.scrollView = UIExtend.getCCScrollViewFromCCB(self.ccbfile, self.scrollViewName)
	self:refreshCells()
end

function RAAllianceBaseListPage:release()
	if self.scrollView then
		self.scrollView:removeAllCell()
		self.scrollView = nil
	end
end

function RAAllianceBaseListPage:clickTitle(index)
	CCLuaLog('clickTitle' .. index)
	self.isOpenArr[index] = not self.isOpenArr[index]

	self.curOffset = self.scrollView:getContentOffset()
	-- CCLuaLog('X:' .. self.curOffset.x .. "   Y:" .. self.curOffset.y )
	self.contentSize = self.scrollView:getContentSize()
	-- CCLuaLog('X:' .. contentSize.height .. "   Y:" .. contentSize.y )
	local delayFunc = function ()
		self:refreshCells(index)
	end
	performWithDelay(self.ccbfile, delayFunc, 0.05)
end

function RAAllianceBaseListPage:getTitleCellData(index)
	return self.titleCellDatas[index]
end

function RAAllianceBaseListPage:getTitleCellNum()
	return #self.titleCellDatas
end

function RAAllianceBaseListPage:getContentCellData(titleIndex,index)
	return self.contentDatasArr[titleIndex][index]
end

function RAAllianceBaseListPage:getContentCellNum(index)
	return #self.contentDatasArr[index]
end

function RAAllianceBaseListPage:getContentCellClass(index)
	return self.contentCellClass
end

function RAAllianceBaseListPage:refreshCells(clickIndex)
    self.scrollView:removeAllCell()
    local titleCellNum = self:getTitleCellNum()
    for i=1,titleCellNum do
    	local cell = CCBFileCell:create()
    	local titleData = self:getTitleCellData(i)
    	local titleCell = self.titleCellClass.new(titleData,i,self.isOpenArr[i],clickIndex == i)
	    cell:setCCBFile(titleCell.ccbfileName)
	    titleCell.handler = self
        cell:registerFunctionHandler(titleCell)
	    self.scrollView:addCell(cell)

	    if self.isOpenArr[i] == true then 
		    -- local contentArr = self.contentDatasArr[i]
		    local len = self:getContentCellNum(i) 
		    for j=1,len do
		    	local contentCBFileCell = CCBFileCell:create()
		    	local contentData = self:getContentCellData(i,j)
		    	local contentCell = self:getContentCellClass(i).new(contentData,j)
		    	contentCBFileCell:registerFunctionHandler(contentCell)
		    	contentCBFileCell:setCCBFile(contentCell.ccbfileName)
		    	self.scrollView:addCell(contentCBFileCell)
		    end
		end 
    end

    self.scrollView:orderCCBFileCells()

    if self.curOffset ~= nil then 
    	local minOffset = self.scrollView:minContainerOffset()
    	local contentSize = self.scrollView:getContentSize()
    	self.scrollView:setContentOffset(ccp(self.curOffset.x,self.contentSize.height - contentSize.height + self.curOffset.y))
    	self.curOffset = nil 
    end 
end

function RAAllianceBaseListPage:initTitleCellDatas(titleCellDatas)
	self.titleCellDatas = titleCellDatas

	self.isOpenArr = {}
	for i=1,#self.titleCellDatas do
		self.isOpenArr[i] = true
	end
end


function RAAllianceBaseListPage:ctor(...)
	CCLuaLog('RAAllianceBaseListPage:ctor(...)')
	self.scrollViewName = ''
	self.titleCellDatas = nil 
	self.titleCellClass = nil 
	self.contentCellClass = nil 
end 

-- return RAAllianceInfo
return RAAllianceBaseListPage.new()