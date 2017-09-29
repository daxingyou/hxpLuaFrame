--
--  @ Project : NewbieGuide
--  @ File Name : RANewbieData_Chapter.lua
--  @ Date : 2017/2/9
--  @ Author : @Qinho
--
--

local RANewbieConfig = RARequire('RANewbieConfig')
local newbie_chapter_conf = RARequire('newbie_chapter_conf')
local RANewbieData_Step = RARequire('RANewbieData_Step')

local RANewbieData_Chapter = class('RANewbieData_Chapter',{})


function RANewbieData_Chapter:ctor(chapterId)
	self.mChapterId = 0
	self.mChapterConfig = nil
	self.mIsInit = false
	self.mStepIndex2Id = nil
	self.mStepId2Data = nil
	self.mStepIndex2Data = nil	
	self:_initSelf(chapterId)
end


function RANewbieData_Chapter:_initSelf(chapterId)
	local conf = newbie_chapter_conf[chapterId]
	if conf == nil then return end
	self.mChapterId = chapterId
	self.mChapterConfig = conf

	self:_buildStepDatas()
	self.mIsInit = true
end

function RANewbieData_Chapter:_buildStepDatas()
	local Utilitys = RARequire('Utilitys')
	self.mStepIndex2Id = Utilitys.Split(self.mChapterConfig.stepIdList, '_', self.mChapterConfig.stepCount)	
	self.mStepId2Data = {}
	self.mStepIndex2Data = {}
	for i = 1, self.mChapterConfig.stepCount do
		local stepId = self.mStepIndex2Id[i]
		local stepData = RANewbieData_Step.new(stepId)
		self.mStepId2Data[stepId] = stepData
		self.mStepIndex2Data[i] = stepData
		-- 设置这个步骤的索引，需要保证一个step只能用于一个chapter
		stepData:SetStepIndex(i)
	end
end

function RANewbieData_Chapter:GetIsInit()
	return self.mIsInit
end

-- 获取章节Id
function RANewbieData_Chapter:GetChaptertId()
	return self.mChapterId
end

-- 获取step data
function RANewbieData_Chapter:GetStepDataById(stepId)
	if self.mIsInit then
		return self.mStepId2Data[stepId]
	end
	return nil
end

-- 获取step data
function RANewbieData_Chapter:GetStepDataByIndex(index)
	if self.mIsInit then
		return self.mStepIndex2Data[index]
	end
	return nil
end

-- 获取章节类型
function RANewbieData_Chapter:GetIsStartChapter()
	if self.mIsInit then
		return self.mChapterConfig.chapterType == RANewbieConfig.Enum_ChapterType.Chapter_First
	end
	return false
end

-- 获取章节类型
function RANewbieData_Chapter:GetIsEndChapter()
	if self.mIsInit then
		return self.mChapterConfig.chapterType == RANewbieConfig.Enum_ChapterType.Chapter_Last
	end
	return false
end

-- 获取前一个章节
function RANewbieData_Chapter:GetPreviousChapterId()
	if self.mIsInit then
		return self.mChapterConfig.previousChapterId
	end
	return -1
end

-- 获取后一个章节
function RANewbieData_Chapter:GetNextChapterId()
	if self.mIsInit then
		return self.mChapterConfig.nextChapterId
	end
	return -1
end

-- 获取章节总步骤数目
function RANewbieData_Chapter:GetStepCount()
	if self.mIsInit then
		return self.mChapterConfig.stepCount
	end
	return 0
end

return RANewbieData_Chapter