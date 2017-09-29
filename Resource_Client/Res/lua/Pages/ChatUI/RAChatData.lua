local RAChatData = 
{
	CHAT_TYPE = 
	{
		world         = 0,			--普通聊天,,2:聊天公告，广播
		alliance      = 1,			--公会聊天
	    broadcast      = 2,			--聊天公告,广播
        hrefBroadcast    = 3,		--超链接广播
        allianceHrefBroadcast = 4,	--联盟超链接广播
        gmBroadcast    = 9999,
	},
	CHATCHOOSENTAB = 
	{
		worldTab    = 0,
		allianceTab = 1
	},
    --喇叭id
    HORNID = 800106,

    CHAT_ICON = 
    {
    	Chat_Icon_Alliance_Sel = "Chat_Icon_Alliance_Sel.png",
    	Chat_Icon_Alliance_Nor = "Chat_Icon_Alliance_Nor.png",
    	Chat_Icon_World_Sel = "Chat_Icon_World_Sel.png",
    	Chat_Icon_World_Nor = "Chat_Icon_World_Nor.png"
	}
    
}

return RAChatData