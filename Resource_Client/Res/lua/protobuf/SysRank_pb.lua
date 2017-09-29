-- Generated By protoc-gen-lua Do not Edit


local SysRank_Local_Var_Table = {}

local protobuf = require "protobuf"
module('SysRank_pb')


SysRank_Local_Var_Table.RANK = protobuf.EnumDescriptor();
SysRank_Local_Var_Table.RANK_FETCH_RANK_DATA_ENUM = protobuf.EnumValueDescriptor();
SysRank_Local_Var_Table.RANK_UPDATE_RANK_SCORE_ENUM = protobuf.EnumValueDescriptor();
SysRank_Local_Var_Table.RANK_RANK_DATA_SYNC_ENUM = protobuf.EnumValueDescriptor();
RANKDATAPB = protobuf.Descriptor();
SysRank_Local_Var_Table.RANKDATAPB_KEY_FIELD = protobuf.FieldDescriptor();
SysRank_Local_Var_Table.RANKDATAPB_SCORE_FIELD = protobuf.FieldDescriptor();
SysRank_Local_Var_Table.RANKDATAPB_ORDER_FIELD = protobuf.FieldDescriptor();
SysRank_Local_Var_Table.RANKDATAPB_USERDATA_FIELD = protobuf.FieldDescriptor();
RANKOBJECTPB = protobuf.Descriptor();
SysRank_Local_Var_Table.RANKOBJECTPB_RANKDATA_FIELD = protobuf.FieldDescriptor();
HPUPDATERANKSCORE = protobuf.Descriptor();
SysRank_Local_Var_Table.HPUPDATERANKSCORE_RANKID_FIELD = protobuf.FieldDescriptor();
SysRank_Local_Var_Table.HPUPDATERANKSCORE_RANKDATA_FIELD = protobuf.FieldDescriptor();
HPFETCHRANKDATA = protobuf.Descriptor();
SysRank_Local_Var_Table.HPFETCHRANKDATA_RANKID_FIELD = protobuf.FieldDescriptor();
SysRank_Local_Var_Table.HPFETCHRANKDATA_TOPN_FIELD = protobuf.FieldDescriptor();
HPRANKDATASYNC = protobuf.Descriptor();
SysRank_Local_Var_Table.HPRANKDATASYNC_RANKID_FIELD = protobuf.FieldDescriptor();
SysRank_Local_Var_Table.HPRANKDATASYNC_RANKOBJECT_FIELD = protobuf.FieldDescriptor();

SysRank_Local_Var_Table.RANK_FETCH_RANK_DATA_ENUM.name = "FETCH_RANK_DATA"
SysRank_Local_Var_Table.RANK_FETCH_RANK_DATA_ENUM.index = 0
SysRank_Local_Var_Table.RANK_FETCH_RANK_DATA_ENUM.number = 50
SysRank_Local_Var_Table.RANK_UPDATE_RANK_SCORE_ENUM.name = "UPDATE_RANK_SCORE"
SysRank_Local_Var_Table.RANK_UPDATE_RANK_SCORE_ENUM.index = 1
SysRank_Local_Var_Table.RANK_UPDATE_RANK_SCORE_ENUM.number = 51
SysRank_Local_Var_Table.RANK_RANK_DATA_SYNC_ENUM.name = "RANK_DATA_SYNC"
SysRank_Local_Var_Table.RANK_RANK_DATA_SYNC_ENUM.index = 2
SysRank_Local_Var_Table.RANK_RANK_DATA_SYNC_ENUM.number = 52
SysRank_Local_Var_Table.RANK.name = "rank"
SysRank_Local_Var_Table.RANK.full_name = ".rank"
SysRank_Local_Var_Table.RANK.values = {}
SysRank_Local_Var_Table.RANK.values[1] = SysRank_Local_Var_Table.RANK_FETCH_RANK_DATA_ENUM;
SysRank_Local_Var_Table.RANK.values[2] = SysRank_Local_Var_Table.RANK_UPDATE_RANK_SCORE_ENUM;
SysRank_Local_Var_Table.RANK.values[3] = SysRank_Local_Var_Table.RANK_RANK_DATA_SYNC_ENUM;
SysRank_Local_Var_Table.RANKDATAPB_KEY_FIELD.name = "key"
SysRank_Local_Var_Table.RANKDATAPB_KEY_FIELD.full_name = ".RankDataPB.key"
SysRank_Local_Var_Table.RANKDATAPB_KEY_FIELD.number = 1
SysRank_Local_Var_Table.RANKDATAPB_KEY_FIELD.index = 0
SysRank_Local_Var_Table.RANKDATAPB_KEY_FIELD.label = 2
SysRank_Local_Var_Table.RANKDATAPB_KEY_FIELD.has_default_value = false
SysRank_Local_Var_Table.RANKDATAPB_KEY_FIELD.default_value = ""
SysRank_Local_Var_Table.RANKDATAPB_KEY_FIELD.type = 9
SysRank_Local_Var_Table.RANKDATAPB_KEY_FIELD.cpp_type = 9

SysRank_Local_Var_Table.RANKDATAPB_SCORE_FIELD.name = "score"
SysRank_Local_Var_Table.RANKDATAPB_SCORE_FIELD.full_name = ".RankDataPB.score"
SysRank_Local_Var_Table.RANKDATAPB_SCORE_FIELD.number = 2
SysRank_Local_Var_Table.RANKDATAPB_SCORE_FIELD.index = 1
SysRank_Local_Var_Table.RANKDATAPB_SCORE_FIELD.label = 2
SysRank_Local_Var_Table.RANKDATAPB_SCORE_FIELD.has_default_value = false
SysRank_Local_Var_Table.RANKDATAPB_SCORE_FIELD.default_value = 0
SysRank_Local_Var_Table.RANKDATAPB_SCORE_FIELD.type = 5
SysRank_Local_Var_Table.RANKDATAPB_SCORE_FIELD.cpp_type = 1

SysRank_Local_Var_Table.RANKDATAPB_ORDER_FIELD.name = "order"
SysRank_Local_Var_Table.RANKDATAPB_ORDER_FIELD.full_name = ".RankDataPB.order"
SysRank_Local_Var_Table.RANKDATAPB_ORDER_FIELD.number = 3
SysRank_Local_Var_Table.RANKDATAPB_ORDER_FIELD.index = 2
SysRank_Local_Var_Table.RANKDATAPB_ORDER_FIELD.label = 1
SysRank_Local_Var_Table.RANKDATAPB_ORDER_FIELD.has_default_value = false
SysRank_Local_Var_Table.RANKDATAPB_ORDER_FIELD.default_value = 0
SysRank_Local_Var_Table.RANKDATAPB_ORDER_FIELD.type = 5
SysRank_Local_Var_Table.RANKDATAPB_ORDER_FIELD.cpp_type = 1

SysRank_Local_Var_Table.RANKDATAPB_USERDATA_FIELD.name = "userData"
SysRank_Local_Var_Table.RANKDATAPB_USERDATA_FIELD.full_name = ".RankDataPB.userData"
SysRank_Local_Var_Table.RANKDATAPB_USERDATA_FIELD.number = 4
SysRank_Local_Var_Table.RANKDATAPB_USERDATA_FIELD.index = 3
SysRank_Local_Var_Table.RANKDATAPB_USERDATA_FIELD.label = 1
SysRank_Local_Var_Table.RANKDATAPB_USERDATA_FIELD.has_default_value = false
SysRank_Local_Var_Table.RANKDATAPB_USERDATA_FIELD.default_value = ""
SysRank_Local_Var_Table.RANKDATAPB_USERDATA_FIELD.type = 9
SysRank_Local_Var_Table.RANKDATAPB_USERDATA_FIELD.cpp_type = 9

RANKDATAPB.name = "RankDataPB"
RANKDATAPB.full_name = ".RankDataPB"
RANKDATAPB.nested_types = {}
RANKDATAPB.enum_types = {}
RANKDATAPB.fields = {SysRank_Local_Var_Table.RANKDATAPB_KEY_FIELD, SysRank_Local_Var_Table.RANKDATAPB_SCORE_FIELD, SysRank_Local_Var_Table.RANKDATAPB_ORDER_FIELD, SysRank_Local_Var_Table.RANKDATAPB_USERDATA_FIELD}
RANKDATAPB.is_extendable = false
RANKDATAPB.extensions = {}
SysRank_Local_Var_Table.RANKOBJECTPB_RANKDATA_FIELD.name = "rankData"
SysRank_Local_Var_Table.RANKOBJECTPB_RANKDATA_FIELD.full_name = ".RankObjectPB.rankData"
SysRank_Local_Var_Table.RANKOBJECTPB_RANKDATA_FIELD.number = 1
SysRank_Local_Var_Table.RANKOBJECTPB_RANKDATA_FIELD.index = 0
SysRank_Local_Var_Table.RANKOBJECTPB_RANKDATA_FIELD.label = 3
SysRank_Local_Var_Table.RANKOBJECTPB_RANKDATA_FIELD.has_default_value = false
SysRank_Local_Var_Table.RANKOBJECTPB_RANKDATA_FIELD.default_value = {}
SysRank_Local_Var_Table.RANKOBJECTPB_RANKDATA_FIELD.message_type = RANKDATAPB
SysRank_Local_Var_Table.RANKOBJECTPB_RANKDATA_FIELD.type = 11
SysRank_Local_Var_Table.RANKOBJECTPB_RANKDATA_FIELD.cpp_type = 10

RANKOBJECTPB.name = "RankObjectPB"
RANKOBJECTPB.full_name = ".RankObjectPB"
RANKOBJECTPB.nested_types = {}
RANKOBJECTPB.enum_types = {}
RANKOBJECTPB.fields = {SysRank_Local_Var_Table.RANKOBJECTPB_RANKDATA_FIELD}
RANKOBJECTPB.is_extendable = false
RANKOBJECTPB.extensions = {}
SysRank_Local_Var_Table.HPUPDATERANKSCORE_RANKID_FIELD.name = "rankId"
SysRank_Local_Var_Table.HPUPDATERANKSCORE_RANKID_FIELD.full_name = ".HPUpdateRankScore.rankId"
SysRank_Local_Var_Table.HPUPDATERANKSCORE_RANKID_FIELD.number = 1
SysRank_Local_Var_Table.HPUPDATERANKSCORE_RANKID_FIELD.index = 0
SysRank_Local_Var_Table.HPUPDATERANKSCORE_RANKID_FIELD.label = 2
SysRank_Local_Var_Table.HPUPDATERANKSCORE_RANKID_FIELD.has_default_value = false
SysRank_Local_Var_Table.HPUPDATERANKSCORE_RANKID_FIELD.default_value = ""
SysRank_Local_Var_Table.HPUPDATERANKSCORE_RANKID_FIELD.type = 9
SysRank_Local_Var_Table.HPUPDATERANKSCORE_RANKID_FIELD.cpp_type = 9

SysRank_Local_Var_Table.HPUPDATERANKSCORE_RANKDATA_FIELD.name = "rankData"
SysRank_Local_Var_Table.HPUPDATERANKSCORE_RANKDATA_FIELD.full_name = ".HPUpdateRankScore.rankData"
SysRank_Local_Var_Table.HPUPDATERANKSCORE_RANKDATA_FIELD.number = 2
SysRank_Local_Var_Table.HPUPDATERANKSCORE_RANKDATA_FIELD.index = 1
SysRank_Local_Var_Table.HPUPDATERANKSCORE_RANKDATA_FIELD.label = 2
SysRank_Local_Var_Table.HPUPDATERANKSCORE_RANKDATA_FIELD.has_default_value = false
SysRank_Local_Var_Table.HPUPDATERANKSCORE_RANKDATA_FIELD.default_value = nil
SysRank_Local_Var_Table.HPUPDATERANKSCORE_RANKDATA_FIELD.message_type = RANKDATAPB
SysRank_Local_Var_Table.HPUPDATERANKSCORE_RANKDATA_FIELD.type = 11
SysRank_Local_Var_Table.HPUPDATERANKSCORE_RANKDATA_FIELD.cpp_type = 10

HPUPDATERANKSCORE.name = "HPUpdateRankScore"
HPUPDATERANKSCORE.full_name = ".HPUpdateRankScore"
HPUPDATERANKSCORE.nested_types = {}
HPUPDATERANKSCORE.enum_types = {}
HPUPDATERANKSCORE.fields = {SysRank_Local_Var_Table.HPUPDATERANKSCORE_RANKID_FIELD, SysRank_Local_Var_Table.HPUPDATERANKSCORE_RANKDATA_FIELD}
HPUPDATERANKSCORE.is_extendable = false
HPUPDATERANKSCORE.extensions = {}
SysRank_Local_Var_Table.HPFETCHRANKDATA_RANKID_FIELD.name = "rankId"
SysRank_Local_Var_Table.HPFETCHRANKDATA_RANKID_FIELD.full_name = ".HPFetchRankData.rankId"
SysRank_Local_Var_Table.HPFETCHRANKDATA_RANKID_FIELD.number = 1
SysRank_Local_Var_Table.HPFETCHRANKDATA_RANKID_FIELD.index = 0
SysRank_Local_Var_Table.HPFETCHRANKDATA_RANKID_FIELD.label = 2
SysRank_Local_Var_Table.HPFETCHRANKDATA_RANKID_FIELD.has_default_value = false
SysRank_Local_Var_Table.HPFETCHRANKDATA_RANKID_FIELD.default_value = ""
SysRank_Local_Var_Table.HPFETCHRANKDATA_RANKID_FIELD.type = 9
SysRank_Local_Var_Table.HPFETCHRANKDATA_RANKID_FIELD.cpp_type = 9

SysRank_Local_Var_Table.HPFETCHRANKDATA_TOPN_FIELD.name = "topN"
SysRank_Local_Var_Table.HPFETCHRANKDATA_TOPN_FIELD.full_name = ".HPFetchRankData.topN"
SysRank_Local_Var_Table.HPFETCHRANKDATA_TOPN_FIELD.number = 2
SysRank_Local_Var_Table.HPFETCHRANKDATA_TOPN_FIELD.index = 1
SysRank_Local_Var_Table.HPFETCHRANKDATA_TOPN_FIELD.label = 1
SysRank_Local_Var_Table.HPFETCHRANKDATA_TOPN_FIELD.has_default_value = false
SysRank_Local_Var_Table.HPFETCHRANKDATA_TOPN_FIELD.default_value = 0
SysRank_Local_Var_Table.HPFETCHRANKDATA_TOPN_FIELD.type = 5
SysRank_Local_Var_Table.HPFETCHRANKDATA_TOPN_FIELD.cpp_type = 1

HPFETCHRANKDATA.name = "HPFetchRankData"
HPFETCHRANKDATA.full_name = ".HPFetchRankData"
HPFETCHRANKDATA.nested_types = {}
HPFETCHRANKDATA.enum_types = {}
HPFETCHRANKDATA.fields = {SysRank_Local_Var_Table.HPFETCHRANKDATA_RANKID_FIELD, SysRank_Local_Var_Table.HPFETCHRANKDATA_TOPN_FIELD}
HPFETCHRANKDATA.is_extendable = false
HPFETCHRANKDATA.extensions = {}
SysRank_Local_Var_Table.HPRANKDATASYNC_RANKID_FIELD.name = "rankId"
SysRank_Local_Var_Table.HPRANKDATASYNC_RANKID_FIELD.full_name = ".HPRankDataSync.rankId"
SysRank_Local_Var_Table.HPRANKDATASYNC_RANKID_FIELD.number = 1
SysRank_Local_Var_Table.HPRANKDATASYNC_RANKID_FIELD.index = 0
SysRank_Local_Var_Table.HPRANKDATASYNC_RANKID_FIELD.label = 2
SysRank_Local_Var_Table.HPRANKDATASYNC_RANKID_FIELD.has_default_value = false
SysRank_Local_Var_Table.HPRANKDATASYNC_RANKID_FIELD.default_value = ""
SysRank_Local_Var_Table.HPRANKDATASYNC_RANKID_FIELD.type = 9
SysRank_Local_Var_Table.HPRANKDATASYNC_RANKID_FIELD.cpp_type = 9

SysRank_Local_Var_Table.HPRANKDATASYNC_RANKOBJECT_FIELD.name = "rankObject"
SysRank_Local_Var_Table.HPRANKDATASYNC_RANKOBJECT_FIELD.full_name = ".HPRankDataSync.rankObject"
SysRank_Local_Var_Table.HPRANKDATASYNC_RANKOBJECT_FIELD.number = 2
SysRank_Local_Var_Table.HPRANKDATASYNC_RANKOBJECT_FIELD.index = 1
SysRank_Local_Var_Table.HPRANKDATASYNC_RANKOBJECT_FIELD.label = 2
SysRank_Local_Var_Table.HPRANKDATASYNC_RANKOBJECT_FIELD.has_default_value = false
SysRank_Local_Var_Table.HPRANKDATASYNC_RANKOBJECT_FIELD.default_value = nil
SysRank_Local_Var_Table.HPRANKDATASYNC_RANKOBJECT_FIELD.message_type = RANKOBJECTPB
SysRank_Local_Var_Table.HPRANKDATASYNC_RANKOBJECT_FIELD.type = 11
SysRank_Local_Var_Table.HPRANKDATASYNC_RANKOBJECT_FIELD.cpp_type = 10

HPRANKDATASYNC.name = "HPRankDataSync"
HPRANKDATASYNC.full_name = ".HPRankDataSync"
HPRANKDATASYNC.nested_types = {}
HPRANKDATASYNC.enum_types = {}
HPRANKDATASYNC.fields = {SysRank_Local_Var_Table.HPRANKDATASYNC_RANKID_FIELD, SysRank_Local_Var_Table.HPRANKDATASYNC_RANKOBJECT_FIELD}
HPRANKDATASYNC.is_extendable = false
HPRANKDATASYNC.extensions = {}

FETCH_RANK_DATA = 50
HPFetchRankData = protobuf.Message(HPFETCHRANKDATA)
HPRankDataSync = protobuf.Message(HPRANKDATASYNC)
HPUpdateRankScore = protobuf.Message(HPUPDATERANKSCORE)
RANK_DATA_SYNC = 52
RankDataPB = protobuf.Message(RANKDATAPB)
RankObjectPB = protobuf.Message(RANKOBJECTPB)
UPDATE_RANK_SCORE = 51
