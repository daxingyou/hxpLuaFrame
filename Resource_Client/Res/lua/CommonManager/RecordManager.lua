local SysProtocol_pb = RARequire("SysProtocol_pb")
local RANetUtil = RARequire("RANetUtil")

local RecordManager = {}

package.loaded[...] = RecordManager

--desc:新手打点,detailGuideId是在RecodeDot.proto里面定义的异常详细的新手记录id
--不同的id对应不同的步骤
function RecordManager.recordNoviceGuide(detailGuideId)
    local msg = SysProtocol_pb.HPCustomDataDefine()
    msg.data.key = "dot"
    msg.data.val = detailGuideId
    RANetUtil:sendPacket(HP_pb.CUSTOM_DATA_DEFINE, msg, {retOpcode = -1})
end 


return RecordManager