-- Generated By protoc-gen-lua Do not Edit


local Building_Local_Var_Table = {}

local protobuf = require "protobuf"
local Const_pb = require("Const_pb")
local Queue_pb = require("Queue_pb")
module('Building_pb')


Building_Local_Var_Table.BUILDINGUPDATEOPERATION = protobuf.EnumDescriptor();
Building_Local_Var_Table.BUILDINGUPDATEOPERATION_BUILDING_UPDATE_COMMON_ENUM = protobuf.EnumValueDescriptor();
Building_Local_Var_Table.BUILDINGUPDATEOPERATION_BUILDING_UPDATE_IMMIDIATELY_ENUM = protobuf.EnumValueDescriptor();
BUILDINGPB = protobuf.Descriptor();
Building_Local_Var_Table.BUILDINGPB_ID_FIELD = protobuf.FieldDescriptor();
Building_Local_Var_Table.BUILDINGPB_BUILDCFGID_FIELD = protobuf.FieldDescriptor();
Building_Local_Var_Table.BUILDINGPB_X_FIELD = protobuf.FieldDescriptor();
Building_Local_Var_Table.BUILDINGPB_Y_FIELD = protobuf.FieldDescriptor();
Building_Local_Var_Table.BUILDINGPB_STATUS_FIELD = protobuf.FieldDescriptor();
Building_Local_Var_Table.BUILDINGPB_HP_FIELD = protobuf.FieldDescriptor();
DEFENCEBUILDINGHP = protobuf.Descriptor();
Building_Local_Var_Table.DEFENCEBUILDINGHP_ID_FIELD = protobuf.FieldDescriptor();
Building_Local_Var_Table.DEFENCEBUILDINGHP_HP_FIELD = protobuf.FieldDescriptor();
Building_Local_Var_Table.DEFENCEBUILDINGHP_NORMAL_FIELD = protobuf.FieldDescriptor();
DEFENCEBUILDINGSTATUSPB = protobuf.Descriptor();
Building_Local_Var_Table.DEFENCEBUILDINGSTATUSPB_DEFBUILDHP_FIELD = protobuf.FieldDescriptor();
BUILDINGUPDATEPUSH = protobuf.Descriptor();
Building_Local_Var_Table.BUILDINGUPDATEPUSH_OPERATION_FIELD = protobuf.FieldDescriptor();
Building_Local_Var_Table.BUILDINGUPDATEPUSH_BUILDING_FIELD = protobuf.FieldDescriptor();
HPBUILDINGINFOSYNC = protobuf.Descriptor();
Building_Local_Var_Table.HPBUILDINGINFOSYNC_BUILDINGS_FIELD = protobuf.FieldDescriptor();
BUILDINGCREATEREQ = protobuf.Descriptor();
Building_Local_Var_Table.BUILDINGCREATEREQ_BUILDCFGID_FIELD = protobuf.FieldDescriptor();
Building_Local_Var_Table.BUILDINGCREATEREQ_X_FIELD = protobuf.FieldDescriptor();
Building_Local_Var_Table.BUILDINGCREATEREQ_Y_FIELD = protobuf.FieldDescriptor();
BUILDINGUPGRADEREQ = protobuf.Descriptor();
Building_Local_Var_Table.BUILDINGUPGRADEREQ_ID_FIELD = protobuf.FieldDescriptor();
Building_Local_Var_Table.BUILDINGUPGRADEREQ_IMMEDIATELY_FIELD = protobuf.FieldDescriptor();
Building_Local_Var_Table.BUILDINGUPGRADEREQ_BUILDCFGID_FIELD = protobuf.FieldDescriptor();
BUILDINGMOVEREQ = protobuf.Descriptor();
Building_Local_Var_Table.BUILDINGMOVEREQ_ID_FIELD = protobuf.FieldDescriptor();
Building_Local_Var_Table.BUILDINGMOVEREQ_TARGET_X_FIELD = protobuf.FieldDescriptor();
Building_Local_Var_Table.BUILDINGMOVEREQ_TARGET_Y_FIELD = protobuf.FieldDescriptor();
PUSHBUILDINGSTATUS = protobuf.Descriptor();
Building_Local_Var_Table.PUSHBUILDINGSTATUS_STATUS_FIELD = protobuf.FieldDescriptor();
Building_Local_Var_Table.PUSHBUILDINGSTATUS_TYPE_FIELD = protobuf.FieldDescriptor();
BUILDINGREBUILDREQ = protobuf.Descriptor();
Building_Local_Var_Table.BUILDINGREBUILDREQ_ID_FIELD = protobuf.FieldDescriptor();
Building_Local_Var_Table.BUILDINGREBUILDREQ_BUILDCFGID_FIELD = protobuf.FieldDescriptor();
Building_Local_Var_Table.BUILDINGREBUILDREQ_IMMEDIATELY_FIELD = protobuf.FieldDescriptor();
BUILDINGREPAIRREQ = protobuf.Descriptor();
Building_Local_Var_Table.BUILDINGREPAIRREQ_ID_FIELD = protobuf.FieldDescriptor();
Building_Local_Var_Table.BUILDINGREPAIRREQ_IMMEDIATELY_FIELD = protobuf.FieldDescriptor();

Building_Local_Var_Table.BUILDINGUPDATEOPERATION_BUILDING_UPDATE_COMMON_ENUM.name = "BUILDING_UPDATE_COMMON"
Building_Local_Var_Table.BUILDINGUPDATEOPERATION_BUILDING_UPDATE_COMMON_ENUM.index = 0
Building_Local_Var_Table.BUILDINGUPDATEOPERATION_BUILDING_UPDATE_COMMON_ENUM.number = 1
Building_Local_Var_Table.BUILDINGUPDATEOPERATION_BUILDING_UPDATE_IMMIDIATELY_ENUM.name = "BUILDING_UPDATE_IMMIDIATELY"
Building_Local_Var_Table.BUILDINGUPDATEOPERATION_BUILDING_UPDATE_IMMIDIATELY_ENUM.index = 1
Building_Local_Var_Table.BUILDINGUPDATEOPERATION_BUILDING_UPDATE_IMMIDIATELY_ENUM.number = 2
Building_Local_Var_Table.BUILDINGUPDATEOPERATION.name = "BuildingUpdateOperation"
Building_Local_Var_Table.BUILDINGUPDATEOPERATION.full_name = ".BuildingUpdateOperation"
Building_Local_Var_Table.BUILDINGUPDATEOPERATION.values = {}
Building_Local_Var_Table.BUILDINGUPDATEOPERATION.values[1] = Building_Local_Var_Table.BUILDINGUPDATEOPERATION_BUILDING_UPDATE_COMMON_ENUM;
Building_Local_Var_Table.BUILDINGUPDATEOPERATION.values[2] = Building_Local_Var_Table.BUILDINGUPDATEOPERATION_BUILDING_UPDATE_IMMIDIATELY_ENUM;
Building_Local_Var_Table.BUILDINGPB_ID_FIELD.name = "id"
Building_Local_Var_Table.BUILDINGPB_ID_FIELD.full_name = ".BuildingPB.id"
Building_Local_Var_Table.BUILDINGPB_ID_FIELD.number = 1
Building_Local_Var_Table.BUILDINGPB_ID_FIELD.index = 0
Building_Local_Var_Table.BUILDINGPB_ID_FIELD.label = 2
Building_Local_Var_Table.BUILDINGPB_ID_FIELD.has_default_value = false
Building_Local_Var_Table.BUILDINGPB_ID_FIELD.default_value = ""
Building_Local_Var_Table.BUILDINGPB_ID_FIELD.type = 9
Building_Local_Var_Table.BUILDINGPB_ID_FIELD.cpp_type = 9

Building_Local_Var_Table.BUILDINGPB_BUILDCFGID_FIELD.name = "buildCfgId"
Building_Local_Var_Table.BUILDINGPB_BUILDCFGID_FIELD.full_name = ".BuildingPB.buildCfgId"
Building_Local_Var_Table.BUILDINGPB_BUILDCFGID_FIELD.number = 2
Building_Local_Var_Table.BUILDINGPB_BUILDCFGID_FIELD.index = 1
Building_Local_Var_Table.BUILDINGPB_BUILDCFGID_FIELD.label = 2
Building_Local_Var_Table.BUILDINGPB_BUILDCFGID_FIELD.has_default_value = false
Building_Local_Var_Table.BUILDINGPB_BUILDCFGID_FIELD.default_value = 0
Building_Local_Var_Table.BUILDINGPB_BUILDCFGID_FIELD.type = 5
Building_Local_Var_Table.BUILDINGPB_BUILDCFGID_FIELD.cpp_type = 1

Building_Local_Var_Table.BUILDINGPB_X_FIELD.name = "x"
Building_Local_Var_Table.BUILDINGPB_X_FIELD.full_name = ".BuildingPB.x"
Building_Local_Var_Table.BUILDINGPB_X_FIELD.number = 3
Building_Local_Var_Table.BUILDINGPB_X_FIELD.index = 2
Building_Local_Var_Table.BUILDINGPB_X_FIELD.label = 2
Building_Local_Var_Table.BUILDINGPB_X_FIELD.has_default_value = false
Building_Local_Var_Table.BUILDINGPB_X_FIELD.default_value = 0
Building_Local_Var_Table.BUILDINGPB_X_FIELD.type = 5
Building_Local_Var_Table.BUILDINGPB_X_FIELD.cpp_type = 1

Building_Local_Var_Table.BUILDINGPB_Y_FIELD.name = "y"
Building_Local_Var_Table.BUILDINGPB_Y_FIELD.full_name = ".BuildingPB.y"
Building_Local_Var_Table.BUILDINGPB_Y_FIELD.number = 4
Building_Local_Var_Table.BUILDINGPB_Y_FIELD.index = 3
Building_Local_Var_Table.BUILDINGPB_Y_FIELD.label = 2
Building_Local_Var_Table.BUILDINGPB_Y_FIELD.has_default_value = false
Building_Local_Var_Table.BUILDINGPB_Y_FIELD.default_value = 0
Building_Local_Var_Table.BUILDINGPB_Y_FIELD.type = 5
Building_Local_Var_Table.BUILDINGPB_Y_FIELD.cpp_type = 1

Building_Local_Var_Table.BUILDINGPB_STATUS_FIELD.name = "status"
Building_Local_Var_Table.BUILDINGPB_STATUS_FIELD.full_name = ".BuildingPB.status"
Building_Local_Var_Table.BUILDINGPB_STATUS_FIELD.number = 5
Building_Local_Var_Table.BUILDINGPB_STATUS_FIELD.index = 4
Building_Local_Var_Table.BUILDINGPB_STATUS_FIELD.label = 2
Building_Local_Var_Table.BUILDINGPB_STATUS_FIELD.has_default_value = false
Building_Local_Var_Table.BUILDINGPB_STATUS_FIELD.default_value = nil
Building_Local_Var_Table.BUILDINGPB_STATUS_FIELD.enum_type = Const_pb.BUILDINGSTATUS
Building_Local_Var_Table.BUILDINGPB_STATUS_FIELD.type = 14
Building_Local_Var_Table.BUILDINGPB_STATUS_FIELD.cpp_type = 8

Building_Local_Var_Table.BUILDINGPB_HP_FIELD.name = "hp"
Building_Local_Var_Table.BUILDINGPB_HP_FIELD.full_name = ".BuildingPB.hp"
Building_Local_Var_Table.BUILDINGPB_HP_FIELD.number = 6
Building_Local_Var_Table.BUILDINGPB_HP_FIELD.index = 5
Building_Local_Var_Table.BUILDINGPB_HP_FIELD.label = 1
Building_Local_Var_Table.BUILDINGPB_HP_FIELD.has_default_value = false
Building_Local_Var_Table.BUILDINGPB_HP_FIELD.default_value = 0
Building_Local_Var_Table.BUILDINGPB_HP_FIELD.type = 5
Building_Local_Var_Table.BUILDINGPB_HP_FIELD.cpp_type = 1

BUILDINGPB.name = "BuildingPB"
BUILDINGPB.full_name = ".BuildingPB"
BUILDINGPB.nested_types = {}
BUILDINGPB.enum_types = {}
BUILDINGPB.fields = {Building_Local_Var_Table.BUILDINGPB_ID_FIELD, Building_Local_Var_Table.BUILDINGPB_BUILDCFGID_FIELD, Building_Local_Var_Table.BUILDINGPB_X_FIELD, Building_Local_Var_Table.BUILDINGPB_Y_FIELD, Building_Local_Var_Table.BUILDINGPB_STATUS_FIELD, Building_Local_Var_Table.BUILDINGPB_HP_FIELD}
BUILDINGPB.is_extendable = false
BUILDINGPB.extensions = {}
Building_Local_Var_Table.DEFENCEBUILDINGHP_ID_FIELD.name = "id"
Building_Local_Var_Table.DEFENCEBUILDINGHP_ID_FIELD.full_name = ".DefenceBuildingHP.id"
Building_Local_Var_Table.DEFENCEBUILDINGHP_ID_FIELD.number = 1
Building_Local_Var_Table.DEFENCEBUILDINGHP_ID_FIELD.index = 0
Building_Local_Var_Table.DEFENCEBUILDINGHP_ID_FIELD.label = 2
Building_Local_Var_Table.DEFENCEBUILDINGHP_ID_FIELD.has_default_value = false
Building_Local_Var_Table.DEFENCEBUILDINGHP_ID_FIELD.default_value = ""
Building_Local_Var_Table.DEFENCEBUILDINGHP_ID_FIELD.type = 9
Building_Local_Var_Table.DEFENCEBUILDINGHP_ID_FIELD.cpp_type = 9

Building_Local_Var_Table.DEFENCEBUILDINGHP_HP_FIELD.name = "hp"
Building_Local_Var_Table.DEFENCEBUILDINGHP_HP_FIELD.full_name = ".DefenceBuildingHP.hp"
Building_Local_Var_Table.DEFENCEBUILDINGHP_HP_FIELD.number = 2
Building_Local_Var_Table.DEFENCEBUILDINGHP_HP_FIELD.index = 1
Building_Local_Var_Table.DEFENCEBUILDINGHP_HP_FIELD.label = 2
Building_Local_Var_Table.DEFENCEBUILDINGHP_HP_FIELD.has_default_value = false
Building_Local_Var_Table.DEFENCEBUILDINGHP_HP_FIELD.default_value = 0
Building_Local_Var_Table.DEFENCEBUILDINGHP_HP_FIELD.type = 5
Building_Local_Var_Table.DEFENCEBUILDINGHP_HP_FIELD.cpp_type = 1

Building_Local_Var_Table.DEFENCEBUILDINGHP_NORMAL_FIELD.name = "normal"
Building_Local_Var_Table.DEFENCEBUILDINGHP_NORMAL_FIELD.full_name = ".DefenceBuildingHP.normal"
Building_Local_Var_Table.DEFENCEBUILDINGHP_NORMAL_FIELD.number = 3
Building_Local_Var_Table.DEFENCEBUILDINGHP_NORMAL_FIELD.index = 2
Building_Local_Var_Table.DEFENCEBUILDINGHP_NORMAL_FIELD.label = 2
Building_Local_Var_Table.DEFENCEBUILDINGHP_NORMAL_FIELD.has_default_value = false
Building_Local_Var_Table.DEFENCEBUILDINGHP_NORMAL_FIELD.default_value = 0
Building_Local_Var_Table.DEFENCEBUILDINGHP_NORMAL_FIELD.type = 5
Building_Local_Var_Table.DEFENCEBUILDINGHP_NORMAL_FIELD.cpp_type = 1

DEFENCEBUILDINGHP.name = "DefenceBuildingHP"
DEFENCEBUILDINGHP.full_name = ".DefenceBuildingHP"
DEFENCEBUILDINGHP.nested_types = {}
DEFENCEBUILDINGHP.enum_types = {}
DEFENCEBUILDINGHP.fields = {Building_Local_Var_Table.DEFENCEBUILDINGHP_ID_FIELD, Building_Local_Var_Table.DEFENCEBUILDINGHP_HP_FIELD, Building_Local_Var_Table.DEFENCEBUILDINGHP_NORMAL_FIELD}
DEFENCEBUILDINGHP.is_extendable = false
DEFENCEBUILDINGHP.extensions = {}
Building_Local_Var_Table.DEFENCEBUILDINGSTATUSPB_DEFBUILDHP_FIELD.name = "defBuildHp"
Building_Local_Var_Table.DEFENCEBUILDINGSTATUSPB_DEFBUILDHP_FIELD.full_name = ".DefenceBuildingStatusPB.defBuildHp"
Building_Local_Var_Table.DEFENCEBUILDINGSTATUSPB_DEFBUILDHP_FIELD.number = 1
Building_Local_Var_Table.DEFENCEBUILDINGSTATUSPB_DEFBUILDHP_FIELD.index = 0
Building_Local_Var_Table.DEFENCEBUILDINGSTATUSPB_DEFBUILDHP_FIELD.label = 3
Building_Local_Var_Table.DEFENCEBUILDINGSTATUSPB_DEFBUILDHP_FIELD.has_default_value = false
Building_Local_Var_Table.DEFENCEBUILDINGSTATUSPB_DEFBUILDHP_FIELD.default_value = {}
Building_Local_Var_Table.DEFENCEBUILDINGSTATUSPB_DEFBUILDHP_FIELD.message_type = DEFENCEBUILDINGHP
Building_Local_Var_Table.DEFENCEBUILDINGSTATUSPB_DEFBUILDHP_FIELD.type = 11
Building_Local_Var_Table.DEFENCEBUILDINGSTATUSPB_DEFBUILDHP_FIELD.cpp_type = 10

DEFENCEBUILDINGSTATUSPB.name = "DefenceBuildingStatusPB"
DEFENCEBUILDINGSTATUSPB.full_name = ".DefenceBuildingStatusPB"
DEFENCEBUILDINGSTATUSPB.nested_types = {}
DEFENCEBUILDINGSTATUSPB.enum_types = {}
DEFENCEBUILDINGSTATUSPB.fields = {Building_Local_Var_Table.DEFENCEBUILDINGSTATUSPB_DEFBUILDHP_FIELD}
DEFENCEBUILDINGSTATUSPB.is_extendable = false
DEFENCEBUILDINGSTATUSPB.extensions = {}
Building_Local_Var_Table.BUILDINGUPDATEPUSH_OPERATION_FIELD.name = "operation"
Building_Local_Var_Table.BUILDINGUPDATEPUSH_OPERATION_FIELD.full_name = ".BuildingUpdatePush.operation"
Building_Local_Var_Table.BUILDINGUPDATEPUSH_OPERATION_FIELD.number = 1
Building_Local_Var_Table.BUILDINGUPDATEPUSH_OPERATION_FIELD.index = 0
Building_Local_Var_Table.BUILDINGUPDATEPUSH_OPERATION_FIELD.label = 2
Building_Local_Var_Table.BUILDINGUPDATEPUSH_OPERATION_FIELD.has_default_value = false
Building_Local_Var_Table.BUILDINGUPDATEPUSH_OPERATION_FIELD.default_value = nil
Building_Local_Var_Table.BUILDINGUPDATEPUSH_OPERATION_FIELD.enum_type = Building_Local_Var_Table.BUILDINGUPDATEOPERATION
Building_Local_Var_Table.BUILDINGUPDATEPUSH_OPERATION_FIELD.type = 14
Building_Local_Var_Table.BUILDINGUPDATEPUSH_OPERATION_FIELD.cpp_type = 8

Building_Local_Var_Table.BUILDINGUPDATEPUSH_BUILDING_FIELD.name = "building"
Building_Local_Var_Table.BUILDINGUPDATEPUSH_BUILDING_FIELD.full_name = ".BuildingUpdatePush.building"
Building_Local_Var_Table.BUILDINGUPDATEPUSH_BUILDING_FIELD.number = 2
Building_Local_Var_Table.BUILDINGUPDATEPUSH_BUILDING_FIELD.index = 1
Building_Local_Var_Table.BUILDINGUPDATEPUSH_BUILDING_FIELD.label = 2
Building_Local_Var_Table.BUILDINGUPDATEPUSH_BUILDING_FIELD.has_default_value = false
Building_Local_Var_Table.BUILDINGUPDATEPUSH_BUILDING_FIELD.default_value = nil
Building_Local_Var_Table.BUILDINGUPDATEPUSH_BUILDING_FIELD.message_type = BUILDINGPB
Building_Local_Var_Table.BUILDINGUPDATEPUSH_BUILDING_FIELD.type = 11
Building_Local_Var_Table.BUILDINGUPDATEPUSH_BUILDING_FIELD.cpp_type = 10

BUILDINGUPDATEPUSH.name = "BuildingUpdatePush"
BUILDINGUPDATEPUSH.full_name = ".BuildingUpdatePush"
BUILDINGUPDATEPUSH.nested_types = {}
BUILDINGUPDATEPUSH.enum_types = {}
BUILDINGUPDATEPUSH.fields = {Building_Local_Var_Table.BUILDINGUPDATEPUSH_OPERATION_FIELD, Building_Local_Var_Table.BUILDINGUPDATEPUSH_BUILDING_FIELD}
BUILDINGUPDATEPUSH.is_extendable = false
BUILDINGUPDATEPUSH.extensions = {}
Building_Local_Var_Table.HPBUILDINGINFOSYNC_BUILDINGS_FIELD.name = "buildings"
Building_Local_Var_Table.HPBUILDINGINFOSYNC_BUILDINGS_FIELD.full_name = ".HPBuildingInfoSync.buildings"
Building_Local_Var_Table.HPBUILDINGINFOSYNC_BUILDINGS_FIELD.number = 1
Building_Local_Var_Table.HPBUILDINGINFOSYNC_BUILDINGS_FIELD.index = 0
Building_Local_Var_Table.HPBUILDINGINFOSYNC_BUILDINGS_FIELD.label = 3
Building_Local_Var_Table.HPBUILDINGINFOSYNC_BUILDINGS_FIELD.has_default_value = false
Building_Local_Var_Table.HPBUILDINGINFOSYNC_BUILDINGS_FIELD.default_value = {}
Building_Local_Var_Table.HPBUILDINGINFOSYNC_BUILDINGS_FIELD.message_type = BUILDINGPB
Building_Local_Var_Table.HPBUILDINGINFOSYNC_BUILDINGS_FIELD.type = 11
Building_Local_Var_Table.HPBUILDINGINFOSYNC_BUILDINGS_FIELD.cpp_type = 10

HPBUILDINGINFOSYNC.name = "HPBuildingInfoSync"
HPBUILDINGINFOSYNC.full_name = ".HPBuildingInfoSync"
HPBUILDINGINFOSYNC.nested_types = {}
HPBUILDINGINFOSYNC.enum_types = {}
HPBUILDINGINFOSYNC.fields = {Building_Local_Var_Table.HPBUILDINGINFOSYNC_BUILDINGS_FIELD}
HPBUILDINGINFOSYNC.is_extendable = false
HPBUILDINGINFOSYNC.extensions = {}
Building_Local_Var_Table.BUILDINGCREATEREQ_BUILDCFGID_FIELD.name = "buildCfgId"
Building_Local_Var_Table.BUILDINGCREATEREQ_BUILDCFGID_FIELD.full_name = ".BuildingCreateReq.buildCfgId"
Building_Local_Var_Table.BUILDINGCREATEREQ_BUILDCFGID_FIELD.number = 1
Building_Local_Var_Table.BUILDINGCREATEREQ_BUILDCFGID_FIELD.index = 0
Building_Local_Var_Table.BUILDINGCREATEREQ_BUILDCFGID_FIELD.label = 2
Building_Local_Var_Table.BUILDINGCREATEREQ_BUILDCFGID_FIELD.has_default_value = false
Building_Local_Var_Table.BUILDINGCREATEREQ_BUILDCFGID_FIELD.default_value = 0
Building_Local_Var_Table.BUILDINGCREATEREQ_BUILDCFGID_FIELD.type = 5
Building_Local_Var_Table.BUILDINGCREATEREQ_BUILDCFGID_FIELD.cpp_type = 1

Building_Local_Var_Table.BUILDINGCREATEREQ_X_FIELD.name = "x"
Building_Local_Var_Table.BUILDINGCREATEREQ_X_FIELD.full_name = ".BuildingCreateReq.x"
Building_Local_Var_Table.BUILDINGCREATEREQ_X_FIELD.number = 2
Building_Local_Var_Table.BUILDINGCREATEREQ_X_FIELD.index = 1
Building_Local_Var_Table.BUILDINGCREATEREQ_X_FIELD.label = 2
Building_Local_Var_Table.BUILDINGCREATEREQ_X_FIELD.has_default_value = false
Building_Local_Var_Table.BUILDINGCREATEREQ_X_FIELD.default_value = 0
Building_Local_Var_Table.BUILDINGCREATEREQ_X_FIELD.type = 5
Building_Local_Var_Table.BUILDINGCREATEREQ_X_FIELD.cpp_type = 1

Building_Local_Var_Table.BUILDINGCREATEREQ_Y_FIELD.name = "y"
Building_Local_Var_Table.BUILDINGCREATEREQ_Y_FIELD.full_name = ".BuildingCreateReq.y"
Building_Local_Var_Table.BUILDINGCREATEREQ_Y_FIELD.number = 3
Building_Local_Var_Table.BUILDINGCREATEREQ_Y_FIELD.index = 2
Building_Local_Var_Table.BUILDINGCREATEREQ_Y_FIELD.label = 2
Building_Local_Var_Table.BUILDINGCREATEREQ_Y_FIELD.has_default_value = false
Building_Local_Var_Table.BUILDINGCREATEREQ_Y_FIELD.default_value = 0
Building_Local_Var_Table.BUILDINGCREATEREQ_Y_FIELD.type = 5
Building_Local_Var_Table.BUILDINGCREATEREQ_Y_FIELD.cpp_type = 1

BUILDINGCREATEREQ.name = "BuildingCreateReq"
BUILDINGCREATEREQ.full_name = ".BuildingCreateReq"
BUILDINGCREATEREQ.nested_types = {}
BUILDINGCREATEREQ.enum_types = {}
BUILDINGCREATEREQ.fields = {Building_Local_Var_Table.BUILDINGCREATEREQ_BUILDCFGID_FIELD, Building_Local_Var_Table.BUILDINGCREATEREQ_X_FIELD, Building_Local_Var_Table.BUILDINGCREATEREQ_Y_FIELD}
BUILDINGCREATEREQ.is_extendable = false
BUILDINGCREATEREQ.extensions = {}
Building_Local_Var_Table.BUILDINGUPGRADEREQ_ID_FIELD.name = "id"
Building_Local_Var_Table.BUILDINGUPGRADEREQ_ID_FIELD.full_name = ".BuildingUpgradeReq.id"
Building_Local_Var_Table.BUILDINGUPGRADEREQ_ID_FIELD.number = 1
Building_Local_Var_Table.BUILDINGUPGRADEREQ_ID_FIELD.index = 0
Building_Local_Var_Table.BUILDINGUPGRADEREQ_ID_FIELD.label = 2
Building_Local_Var_Table.BUILDINGUPGRADEREQ_ID_FIELD.has_default_value = false
Building_Local_Var_Table.BUILDINGUPGRADEREQ_ID_FIELD.default_value = ""
Building_Local_Var_Table.BUILDINGUPGRADEREQ_ID_FIELD.type = 9
Building_Local_Var_Table.BUILDINGUPGRADEREQ_ID_FIELD.cpp_type = 9

Building_Local_Var_Table.BUILDINGUPGRADEREQ_IMMEDIATELY_FIELD.name = "immediately"
Building_Local_Var_Table.BUILDINGUPGRADEREQ_IMMEDIATELY_FIELD.full_name = ".BuildingUpgradeReq.immediately"
Building_Local_Var_Table.BUILDINGUPGRADEREQ_IMMEDIATELY_FIELD.number = 2
Building_Local_Var_Table.BUILDINGUPGRADEREQ_IMMEDIATELY_FIELD.index = 1
Building_Local_Var_Table.BUILDINGUPGRADEREQ_IMMEDIATELY_FIELD.label = 2
Building_Local_Var_Table.BUILDINGUPGRADEREQ_IMMEDIATELY_FIELD.has_default_value = false
Building_Local_Var_Table.BUILDINGUPGRADEREQ_IMMEDIATELY_FIELD.default_value = false
Building_Local_Var_Table.BUILDINGUPGRADEREQ_IMMEDIATELY_FIELD.type = 8
Building_Local_Var_Table.BUILDINGUPGRADEREQ_IMMEDIATELY_FIELD.cpp_type = 7

Building_Local_Var_Table.BUILDINGUPGRADEREQ_BUILDCFGID_FIELD.name = "buildCfgId"
Building_Local_Var_Table.BUILDINGUPGRADEREQ_BUILDCFGID_FIELD.full_name = ".BuildingUpgradeReq.buildCfgId"
Building_Local_Var_Table.BUILDINGUPGRADEREQ_BUILDCFGID_FIELD.number = 3
Building_Local_Var_Table.BUILDINGUPGRADEREQ_BUILDCFGID_FIELD.index = 2
Building_Local_Var_Table.BUILDINGUPGRADEREQ_BUILDCFGID_FIELD.label = 2
Building_Local_Var_Table.BUILDINGUPGRADEREQ_BUILDCFGID_FIELD.has_default_value = false
Building_Local_Var_Table.BUILDINGUPGRADEREQ_BUILDCFGID_FIELD.default_value = 0
Building_Local_Var_Table.BUILDINGUPGRADEREQ_BUILDCFGID_FIELD.type = 5
Building_Local_Var_Table.BUILDINGUPGRADEREQ_BUILDCFGID_FIELD.cpp_type = 1

BUILDINGUPGRADEREQ.name = "BuildingUpgradeReq"
BUILDINGUPGRADEREQ.full_name = ".BuildingUpgradeReq"
BUILDINGUPGRADEREQ.nested_types = {}
BUILDINGUPGRADEREQ.enum_types = {}
BUILDINGUPGRADEREQ.fields = {Building_Local_Var_Table.BUILDINGUPGRADEREQ_ID_FIELD, Building_Local_Var_Table.BUILDINGUPGRADEREQ_IMMEDIATELY_FIELD, Building_Local_Var_Table.BUILDINGUPGRADEREQ_BUILDCFGID_FIELD}
BUILDINGUPGRADEREQ.is_extendable = false
BUILDINGUPGRADEREQ.extensions = {}
Building_Local_Var_Table.BUILDINGMOVEREQ_ID_FIELD.name = "id"
Building_Local_Var_Table.BUILDINGMOVEREQ_ID_FIELD.full_name = ".BuildingMoveReq.id"
Building_Local_Var_Table.BUILDINGMOVEREQ_ID_FIELD.number = 1
Building_Local_Var_Table.BUILDINGMOVEREQ_ID_FIELD.index = 0
Building_Local_Var_Table.BUILDINGMOVEREQ_ID_FIELD.label = 2
Building_Local_Var_Table.BUILDINGMOVEREQ_ID_FIELD.has_default_value = false
Building_Local_Var_Table.BUILDINGMOVEREQ_ID_FIELD.default_value = ""
Building_Local_Var_Table.BUILDINGMOVEREQ_ID_FIELD.type = 9
Building_Local_Var_Table.BUILDINGMOVEREQ_ID_FIELD.cpp_type = 9

Building_Local_Var_Table.BUILDINGMOVEREQ_TARGET_X_FIELD.name = "target_x"
Building_Local_Var_Table.BUILDINGMOVEREQ_TARGET_X_FIELD.full_name = ".BuildingMoveReq.target_x"
Building_Local_Var_Table.BUILDINGMOVEREQ_TARGET_X_FIELD.number = 2
Building_Local_Var_Table.BUILDINGMOVEREQ_TARGET_X_FIELD.index = 1
Building_Local_Var_Table.BUILDINGMOVEREQ_TARGET_X_FIELD.label = 2
Building_Local_Var_Table.BUILDINGMOVEREQ_TARGET_X_FIELD.has_default_value = false
Building_Local_Var_Table.BUILDINGMOVEREQ_TARGET_X_FIELD.default_value = 0
Building_Local_Var_Table.BUILDINGMOVEREQ_TARGET_X_FIELD.type = 5
Building_Local_Var_Table.BUILDINGMOVEREQ_TARGET_X_FIELD.cpp_type = 1

Building_Local_Var_Table.BUILDINGMOVEREQ_TARGET_Y_FIELD.name = "target_y"
Building_Local_Var_Table.BUILDINGMOVEREQ_TARGET_Y_FIELD.full_name = ".BuildingMoveReq.target_y"
Building_Local_Var_Table.BUILDINGMOVEREQ_TARGET_Y_FIELD.number = 3
Building_Local_Var_Table.BUILDINGMOVEREQ_TARGET_Y_FIELD.index = 2
Building_Local_Var_Table.BUILDINGMOVEREQ_TARGET_Y_FIELD.label = 2
Building_Local_Var_Table.BUILDINGMOVEREQ_TARGET_Y_FIELD.has_default_value = false
Building_Local_Var_Table.BUILDINGMOVEREQ_TARGET_Y_FIELD.default_value = 0
Building_Local_Var_Table.BUILDINGMOVEREQ_TARGET_Y_FIELD.type = 5
Building_Local_Var_Table.BUILDINGMOVEREQ_TARGET_Y_FIELD.cpp_type = 1

BUILDINGMOVEREQ.name = "BuildingMoveReq"
BUILDINGMOVEREQ.full_name = ".BuildingMoveReq"
BUILDINGMOVEREQ.nested_types = {}
BUILDINGMOVEREQ.enum_types = {}
BUILDINGMOVEREQ.fields = {Building_Local_Var_Table.BUILDINGMOVEREQ_ID_FIELD, Building_Local_Var_Table.BUILDINGMOVEREQ_TARGET_X_FIELD, Building_Local_Var_Table.BUILDINGMOVEREQ_TARGET_Y_FIELD}
BUILDINGMOVEREQ.is_extendable = false
BUILDINGMOVEREQ.extensions = {}
Building_Local_Var_Table.PUSHBUILDINGSTATUS_STATUS_FIELD.name = "status"
Building_Local_Var_Table.PUSHBUILDINGSTATUS_STATUS_FIELD.full_name = ".PushBuildingStatus.status"
Building_Local_Var_Table.PUSHBUILDINGSTATUS_STATUS_FIELD.number = 1
Building_Local_Var_Table.PUSHBUILDINGSTATUS_STATUS_FIELD.index = 0
Building_Local_Var_Table.PUSHBUILDINGSTATUS_STATUS_FIELD.label = 2
Building_Local_Var_Table.PUSHBUILDINGSTATUS_STATUS_FIELD.has_default_value = false
Building_Local_Var_Table.PUSHBUILDINGSTATUS_STATUS_FIELD.default_value = nil
Building_Local_Var_Table.PUSHBUILDINGSTATUS_STATUS_FIELD.enum_type = Const_pb.BUILDINGSTATUS
Building_Local_Var_Table.PUSHBUILDINGSTATUS_STATUS_FIELD.type = 14
Building_Local_Var_Table.PUSHBUILDINGSTATUS_STATUS_FIELD.cpp_type = 8

Building_Local_Var_Table.PUSHBUILDINGSTATUS_TYPE_FIELD.name = "type"
Building_Local_Var_Table.PUSHBUILDINGSTATUS_TYPE_FIELD.full_name = ".PushBuildingStatus.type"
Building_Local_Var_Table.PUSHBUILDINGSTATUS_TYPE_FIELD.number = 2
Building_Local_Var_Table.PUSHBUILDINGSTATUS_TYPE_FIELD.index = 1
Building_Local_Var_Table.PUSHBUILDINGSTATUS_TYPE_FIELD.label = 1
Building_Local_Var_Table.PUSHBUILDINGSTATUS_TYPE_FIELD.has_default_value = false
Building_Local_Var_Table.PUSHBUILDINGSTATUS_TYPE_FIELD.default_value = 0
Building_Local_Var_Table.PUSHBUILDINGSTATUS_TYPE_FIELD.type = 5
Building_Local_Var_Table.PUSHBUILDINGSTATUS_TYPE_FIELD.cpp_type = 1

PUSHBUILDINGSTATUS.name = "PushBuildingStatus"
PUSHBUILDINGSTATUS.full_name = ".PushBuildingStatus"
PUSHBUILDINGSTATUS.nested_types = {}
PUSHBUILDINGSTATUS.enum_types = {}
PUSHBUILDINGSTATUS.fields = {Building_Local_Var_Table.PUSHBUILDINGSTATUS_STATUS_FIELD, Building_Local_Var_Table.PUSHBUILDINGSTATUS_TYPE_FIELD}
PUSHBUILDINGSTATUS.is_extendable = false
PUSHBUILDINGSTATUS.extensions = {}
Building_Local_Var_Table.BUILDINGREBUILDREQ_ID_FIELD.name = "id"
Building_Local_Var_Table.BUILDINGREBUILDREQ_ID_FIELD.full_name = ".BuildingRebuildReq.id"
Building_Local_Var_Table.BUILDINGREBUILDREQ_ID_FIELD.number = 1
Building_Local_Var_Table.BUILDINGREBUILDREQ_ID_FIELD.index = 0
Building_Local_Var_Table.BUILDINGREBUILDREQ_ID_FIELD.label = 2
Building_Local_Var_Table.BUILDINGREBUILDREQ_ID_FIELD.has_default_value = false
Building_Local_Var_Table.BUILDINGREBUILDREQ_ID_FIELD.default_value = ""
Building_Local_Var_Table.BUILDINGREBUILDREQ_ID_FIELD.type = 9
Building_Local_Var_Table.BUILDINGREBUILDREQ_ID_FIELD.cpp_type = 9

Building_Local_Var_Table.BUILDINGREBUILDREQ_BUILDCFGID_FIELD.name = "buildCfgId"
Building_Local_Var_Table.BUILDINGREBUILDREQ_BUILDCFGID_FIELD.full_name = ".BuildingRebuildReq.buildCfgId"
Building_Local_Var_Table.BUILDINGREBUILDREQ_BUILDCFGID_FIELD.number = 2
Building_Local_Var_Table.BUILDINGREBUILDREQ_BUILDCFGID_FIELD.index = 1
Building_Local_Var_Table.BUILDINGREBUILDREQ_BUILDCFGID_FIELD.label = 2
Building_Local_Var_Table.BUILDINGREBUILDREQ_BUILDCFGID_FIELD.has_default_value = false
Building_Local_Var_Table.BUILDINGREBUILDREQ_BUILDCFGID_FIELD.default_value = 0
Building_Local_Var_Table.BUILDINGREBUILDREQ_BUILDCFGID_FIELD.type = 5
Building_Local_Var_Table.BUILDINGREBUILDREQ_BUILDCFGID_FIELD.cpp_type = 1

Building_Local_Var_Table.BUILDINGREBUILDREQ_IMMEDIATELY_FIELD.name = "immediately"
Building_Local_Var_Table.BUILDINGREBUILDREQ_IMMEDIATELY_FIELD.full_name = ".BuildingRebuildReq.immediately"
Building_Local_Var_Table.BUILDINGREBUILDREQ_IMMEDIATELY_FIELD.number = 3
Building_Local_Var_Table.BUILDINGREBUILDREQ_IMMEDIATELY_FIELD.index = 2
Building_Local_Var_Table.BUILDINGREBUILDREQ_IMMEDIATELY_FIELD.label = 2
Building_Local_Var_Table.BUILDINGREBUILDREQ_IMMEDIATELY_FIELD.has_default_value = false
Building_Local_Var_Table.BUILDINGREBUILDREQ_IMMEDIATELY_FIELD.default_value = false
Building_Local_Var_Table.BUILDINGREBUILDREQ_IMMEDIATELY_FIELD.type = 8
Building_Local_Var_Table.BUILDINGREBUILDREQ_IMMEDIATELY_FIELD.cpp_type = 7

BUILDINGREBUILDREQ.name = "BuildingRebuildReq"
BUILDINGREBUILDREQ.full_name = ".BuildingRebuildReq"
BUILDINGREBUILDREQ.nested_types = {}
BUILDINGREBUILDREQ.enum_types = {}
BUILDINGREBUILDREQ.fields = {Building_Local_Var_Table.BUILDINGREBUILDREQ_ID_FIELD, Building_Local_Var_Table.BUILDINGREBUILDREQ_BUILDCFGID_FIELD, Building_Local_Var_Table.BUILDINGREBUILDREQ_IMMEDIATELY_FIELD}
BUILDINGREBUILDREQ.is_extendable = false
BUILDINGREBUILDREQ.extensions = {}
Building_Local_Var_Table.BUILDINGREPAIRREQ_ID_FIELD.name = "id"
Building_Local_Var_Table.BUILDINGREPAIRREQ_ID_FIELD.full_name = ".BuildingRepairReq.id"
Building_Local_Var_Table.BUILDINGREPAIRREQ_ID_FIELD.number = 1
Building_Local_Var_Table.BUILDINGREPAIRREQ_ID_FIELD.index = 0
Building_Local_Var_Table.BUILDINGREPAIRREQ_ID_FIELD.label = 2
Building_Local_Var_Table.BUILDINGREPAIRREQ_ID_FIELD.has_default_value = false
Building_Local_Var_Table.BUILDINGREPAIRREQ_ID_FIELD.default_value = ""
Building_Local_Var_Table.BUILDINGREPAIRREQ_ID_FIELD.type = 9
Building_Local_Var_Table.BUILDINGREPAIRREQ_ID_FIELD.cpp_type = 9

Building_Local_Var_Table.BUILDINGREPAIRREQ_IMMEDIATELY_FIELD.name = "immediately"
Building_Local_Var_Table.BUILDINGREPAIRREQ_IMMEDIATELY_FIELD.full_name = ".BuildingRepairReq.immediately"
Building_Local_Var_Table.BUILDINGREPAIRREQ_IMMEDIATELY_FIELD.number = 2
Building_Local_Var_Table.BUILDINGREPAIRREQ_IMMEDIATELY_FIELD.index = 1
Building_Local_Var_Table.BUILDINGREPAIRREQ_IMMEDIATELY_FIELD.label = 2
Building_Local_Var_Table.BUILDINGREPAIRREQ_IMMEDIATELY_FIELD.has_default_value = false
Building_Local_Var_Table.BUILDINGREPAIRREQ_IMMEDIATELY_FIELD.default_value = false
Building_Local_Var_Table.BUILDINGREPAIRREQ_IMMEDIATELY_FIELD.type = 8
Building_Local_Var_Table.BUILDINGREPAIRREQ_IMMEDIATELY_FIELD.cpp_type = 7

BUILDINGREPAIRREQ.name = "BuildingRepairReq"
BUILDINGREPAIRREQ.full_name = ".BuildingRepairReq"
BUILDINGREPAIRREQ.nested_types = {}
BUILDINGREPAIRREQ.enum_types = {}
BUILDINGREPAIRREQ.fields = {Building_Local_Var_Table.BUILDINGREPAIRREQ_ID_FIELD, Building_Local_Var_Table.BUILDINGREPAIRREQ_IMMEDIATELY_FIELD}
BUILDINGREPAIRREQ.is_extendable = false
BUILDINGREPAIRREQ.extensions = {}

BUILDING_UPDATE_COMMON = 1
BUILDING_UPDATE_IMMIDIATELY = 2
BuildingCreateReq = protobuf.Message(BUILDINGCREATEREQ)
BuildingMoveReq = protobuf.Message(BUILDINGMOVEREQ)
BuildingPB = protobuf.Message(BUILDINGPB)
BuildingRebuildReq = protobuf.Message(BUILDINGREBUILDREQ)
BuildingRepairReq = protobuf.Message(BUILDINGREPAIRREQ)
BuildingUpdatePush = protobuf.Message(BUILDINGUPDATEPUSH)
BuildingUpgradeReq = protobuf.Message(BUILDINGUPGRADEREQ)
DefenceBuildingHP = protobuf.Message(DEFENCEBUILDINGHP)
DefenceBuildingStatusPB = protobuf.Message(DEFENCEBUILDINGSTATUSPB)
HPBuildingInfoSync = protobuf.Message(HPBUILDINGINFOSYNC)
PushBuildingStatus = protobuf.Message(PUSHBUILDINGSTATUS)
