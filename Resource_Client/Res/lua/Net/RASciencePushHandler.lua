--region *.lua
--Date
--此文件由[BabeLua]插件自动生成

local RASciencePushHandler = {}

function RASciencePushHandler:onReceivePacket(handler)
    local HP_pb = RARequire("HP_pb")
    local Technology_pb = RARequire("Technology_pb")
    local RAScienceManager = RARequire("RAScienceManager")
    RARequire("MessageDefine")
    RARequire("MessageManager")

    local pbCode = handler:getOpcode()
    local buffer = handler:getBuffer()
    if pbCode == HP_pb.PLAYER_TECHNOLOGY_S then  --科技
		local msg = Technology_pb.HPTechnologySync()
	    msg:ParseFromString(buffer)
        
        local RAGuideManager=RARequire("RAGuideManager")
        local RAGuideConfig=RARequire("RAGuideConfig")
        local RARootManager=RARequire("RARootManager")
        local isInGuide=RAGuideManager.isInGuide()
        --当前研究完成的科技id
       local techIdTab = msg.techId
       if next(techIdTab) then
       	 for i=1,#techIdTab do
         	 	RAScienceManager:updateScienceDatas(techIdTab[i])
         	 	MessageManager.sendMessage(MessageDef_Building.MSG_SCIENCE_UPDATE,{scienceId = techIdTab[i]}) 

            -- 用于新手 add by xinping
            if isInGuide and techIdTab[i]==RAGuideConfig.guideScienceId then
                  if RAGuideManager.partComplete.Guide_UIUPDATE then
                      RARootManager.AddCoverPage()
                      RAGuideManager.gotoNextStep()
                  end
            end
       	 end
       end 
      
        
    end
end

return RASciencePushHandler

--endregion
