-- RAMissionConfig.lua
-- Author: xinghui
-- Using: 副本固定配置

local RAMissionConfig = {
    ActionType = {
        shownode            = "shownode",
        runani              = "runani",
        runspineani         = "runspineani",
        gotonextstep        = "gotonextstep",
        changepic           = "changepic",
        changelabel         = "changelabel",
        showpage            = "showpage",
        addccb              = "addccb",
        deleteccb           = "deleteccb",
        movecamera          = "movecamera",
        delaytime           = "delaytime",
        waitforclick        = "waitforclick",
        addtouchlayer       = "addtouchlayer",
        addwalkline         = "addwalkline",
        addspine            = "addspine",
        setcapacity         = "setcapacity",
        changeparent        = "changeparent",
        executescriptfunction = "executescriptfunction",
        showtransform       = "showtransform",
        gotofight           = "gotofight",
        sendmessage         = "sendmessage",
        circletarget        = "circletarget",
        setcamerascale      = "setcamerascale",
        playmusic           = "playmusic",
    },
    CameraInfo = {
        OriScale = 1.66,                         --关卡场景进入时的camera的scale
        FinalScale = 1.33                        --关卡场景最终的scale
    }
} 

return RAMissionConfig