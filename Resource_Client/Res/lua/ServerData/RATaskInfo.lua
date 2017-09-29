local raTaskInfo = {
    recommandTasks = {},
    commonTasks = {}
}--任务数组，key是任务id，value是raTaskItemInfo类型的数组

local raTaskItemInfo = {
    taskId = 0,
    taskState = 0,--状态0=未完成,1=可以领取,2=已领取
    taskCompleteNum = 0,
    taskType = 0,--任务类型
    missionId = 0--服务器生成的
}

return raTaskInfo