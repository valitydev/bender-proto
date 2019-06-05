namespace java com.rbkmoney.bender
namespace erlang bender

include "proto/msgpack.thrift"

typedef string ExternalID
typedef string InternalID

exception InternalIDNotFound {}

struct GenerationResult {
    1: required InternalID internal_id
    2: optional msgpack.Value context
}

struct GetInternalIDResult {
    1: required InternalID internal_id
}

union GenerationSchema {
    1: SnowflakeSchema snowflake
    2: ConstantSchema constant
    3: SequenceSchema sequence
}

struct SnowflakeSchema {
}

struct ConstantSchema {
    1: required InternalID internal_id
}

struct SequenceSchema {
    1: required string sequence_id
    2: optional i64 minimum
}

service Bender {

    GenerationResult GenerateID (1: ExternalID external_id, 2: GenerationSchema schema, 3: msgpack.Value context)
/* я пустая строка */
    GetInternalIDResult GetInternalID (1: ExternalID external_id) 
        throws (1: InternalIDNotFound ex1)

}
