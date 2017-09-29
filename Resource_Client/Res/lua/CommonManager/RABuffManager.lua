--region *.lua
--Date
--此文件由[BabeLua]插件自动生成
--//buff增益效果显示
--message PlayerBuffInfo
--{
--	required int32 statusId   = 1;  //buff作用号
--	required int32 value      = 2;  //buffValue
--	required int64 startTime  = 3;  //开始时间
--	required int64 endTime    = 4;  //结束时间
--}
local RABuffManager = 
{
	-- 数据为"通过使用道具 生效的buff", 数值为PlayerEffect的子集
	buffList = {}
}

function RABuffManager:reset()
    RABuffManager.buffList = {}
end

function RABuffManager:syncOneBuff(oneBuff)    
    RABuffManager.buffList[oneBuff.key] = oneBuff

    local Const_pb = RARequire('Const_pb')
    -- 出征上限的作用号推送
    if oneBuff.statusId == Const_pb.TROOP_STRENGTH_BOOST or oneBuff.statusId == Const_pb.TROOP_STRENGTH_NUM then
        MessageManager.sendMessage(MessageDef_RootManager.MSG_CommonRefreshPage, {pageName = 'RATroopChargePage'})
    end

    -- 资源加速道具的作用号
    if oneBuff.effId == Const_pb.RES_COLLECT_BUF or oneBuff.effId == Const_pb.RES_COLLECT then
        MessageManager.sendMessage(MessageDef_RootManager.MSG_CommonRefreshPage, {pageName = 'RAWorldMyCollectionPage'})
        MessageManager.sendMessage(MessageDef_RootManager.MSG_CommonRefreshPage, {pageName = 'RAWorldCollectionBackPage'})
    end
end

function RABuffManager:getBuffValue(buffId)
	local buffInfo = self.buffList[buffId] or {}
    local RA_Common = RARequire("common")
    if buffInfo.endTime and RA_Common:getCurTime()*1000 < buffInfo.endTime then
	   return buffInfo.value or 0	
    else
        return 0
    end
end

function RABuffManager:getBuff(buffId)
	local buffInfo = self.buffList[buffId]
	return buffInfo	
end

return RABuffManager
--endregion
