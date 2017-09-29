--
--  @ Project : NewbieGuide
--  @ File Name : RANewbieStepHandler_Message.lua
--  @ Date : 2017/2/9
--  @ Author : @Qinho
--
--

-- 程序处理。通过程序内发送消息，
-- 消息包含处理目标、点击回调等，在handler里处理的类型，
-- 具体每一个步骤有不同，统一在handler里根据step id进行区分判断，
-- 常用于非页面，但是通过点击新建的内容。
local RANewbieStepHandler_Message = class('RANewbieStepHandler_Message',RARequire("RANewbieStepHandler_Base"))





return RANewbieStepHandler_Message