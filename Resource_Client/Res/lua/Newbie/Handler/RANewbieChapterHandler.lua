--
--  @ Project : NewbieGuide
--  @ File Name : RANewbieChapterHandler.lua
--  @ Date : 2017/2/9
--  @ Author : @Qinho
--
--

-- 主要处理章节的跳转、步骤的切换、章节保存等
local RANewbieChapterHandler = class('RANewbieChapterHandler',{})

local RANewbieConfig = RARequire('RANewbieConfig')
local RANewbieData_Chapter = RARequire('RANewbieData_Chapter')

function RANewbieChapterHandler:ctor(chapterId)
	self.mCurrChapterId = 0
	self.mCurrChapterData = nil

	self.mCurrStepId = 0
	self.mCurrStepIndex = 0

	self.mCurrStepData = nil
	self.mCurrStepHandler = nil

	self.mIsInit = false
	self:_initSelf(chapterId)
end

function RANewbieChapterHandler:_initSelf(chapterId)
	local chapterData = RANewbieData_Chapter.new(chapterId)
	if chapterData:GetIsInit() then
		self.mCurrChapterData = chapterData
		self.mCurrChapterId = chapterId

		self.mIsInit = true
		return
	end
	self.mIsInit = false
end

function RANewbieChapterHandler:GotoStep(stepId)
	if not self.mIsInit then return end
	local stepData = self.mCurrChapterData:GetStepDataById(stepId)
	if stepData then		
		return self:_gotoStepByData(stepData)
	end
	return false
end

function RANewbieChapterHandler:GotoNextStep()
	if not self.mIsInit then return end
	local nextIndex = self.mCurrStepIndex + 1
	local stepData = self.mCurrChapterData:GetStepDataByIndex(nextIndex)
	if stepData then		
		return self:_gotoStepByData(stepData)
	end
	return false
end

-- 跳转到某一步骤，这时候需要生成step handler
function RANewbieChapterHandler:_gotoStepByData(stepData)
	
end

function RANewbieChapterHandler:SaveNewbie()
	if not self.mIsInit then return end
end

return RANewbieChapterHandler