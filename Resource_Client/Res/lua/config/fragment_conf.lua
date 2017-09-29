local fragment_conf = {
    [1] = {
        id = 1,
        fragmentName = "xxxx",
        storyId = 1,                     --from story_conf
        mapRes = "RAMissionMap1.ccbi",
        rect = "3584_2304",
        barrierIds = "1,2,3,4,5"       --from barrier_conf
    },

    --新手起始专用
    [10000001] = {
        id = 10000001,
        fragmentName = "xxxx",
        storyId = 1,                     --from story_conf
        mapRes = "RAMissionMap2.ccbi",
        rect = "3584_2304",
        barrierIds = "10000001,10000002"       --from barrier_conf
    },
    --新手专用
    [10000002] = {
        id = 10000002,
        fragmentName = "xxxx",
        storyId = 1,                     --from story_conf
        mapRes = "RAMissionMap3.ccbi",
        rect = "3584_2304",
        barrierIds = "20000001"       --from barrier_conf
    },
}

return fragment_conf