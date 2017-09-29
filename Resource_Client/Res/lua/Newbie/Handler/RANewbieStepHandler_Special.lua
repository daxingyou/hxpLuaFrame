--
--  @ Project : NewbieGuide
--  @ File Name : RANewbieStepHandler_Special.lua
--  @ Date : 2017/2/9
--  @ Author : @Qinho
--
--

-- 程序处理。单个步骤单独实现自身逻辑，会有对应该步骤id的handler 文件，
-- 命名规则为RANewbieStepHandler_Special_+step ID，
-- 例如step id为1002，
-- 那么lua名字为：RANewbieStepHandler_Special_1002
local RANewbieStepHandler_Special = class('RANewbieStepHandler_Special',RARequire("RANewbieStepHandler_Base"))





return RANewbieStepHandler_Special