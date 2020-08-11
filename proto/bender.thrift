namespace java com.rbkmoney.bender
namespace erlang bender

include "proto/msgpack.thrift"

typedef string ExternalID
typedef string InternalID
typedef i64    IntegerInternalID

exception InternalIDNotFound {}

struct GenerationResult {
    1: required InternalID internal_id
    2: optional msgpack.Value context
    3: optional IntegerInternalID integer_internal_id
}

struct GeneratedID {
    1: required InternalID id
    2: optional IntegerInternalID integer_id
}

struct GetInternalIDResult {
    1: required InternalID internal_id
    2: required msgpack.Value context
    3: optional IntegerInternalID integer_internal_id
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

    GetInternalIDResult GetInternalID (1: ExternalID external_id)
        throws (1: InternalIDNotFound ex1)
}

service Generator {

    GeneratedID GenerateID (1: GenerationSchema schema)
}
