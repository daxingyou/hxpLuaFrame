local raTaskInfo = {
    recommandTasks = {},
    commonTasks = {}
}--�������飬key������id��value��raTaskItemInfo���͵�����

local raTaskItemInfo = {
    taskId = 0,
    taskState = 0,--״̬0=δ���,1=������ȡ,2=����ȡ
    taskCompleteNum = 0,
    taskType = 0,--��������
    missionId = 0--���������ɵ�
}

return raTaskInfo