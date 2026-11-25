namespace java dev.vality.bender
namespace erlang bender.bender

include "proto/msgpack.thrift"

/**
* Identifier of some process, actor or object in an external system.
*
* Normally, each `ExternalID` is composed of some identifier of an external system, a type or class
* of entity being identified, and finally this entity's identifier.
* For example: "CP/DigitalOcean/Droplet/92878506-0072-4d3e-9f55-2285edad69bf" uniquely identifies
* specific droplet in the DigitalOcean's cloud.
*/
typedef string ExternalID

/**
* Identifier provided directly by the issuer (owner).
* The issuer guarantees its uniqueness within their own domain and scope.
*/
typedef string PlainExternalID

/**
* Either InternalID or PlainExternalID
*/
typedef string BaseID

/**
* Identifier of respective process, actor or object in the local system, to be used internally.
* Uniquely bound with a single external identifier.
*/
typedef string InternalID

/**
* Internal identifier in the form of a signed integer.
* Note that negative values are possible.
*/
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

/**
* Schema which tells how to generate an internal identifier.
*/
union GenerationSchema {
    1: SnowflakeSchema snowflake
    2: ConstantSchema constant
    3: SequenceSchema sequence
}

/**
* Internal identifer will be generated following the Snowflake algorithm.
*
* Such ID will have the form `<Time, MachineID, SequenceID>' where:
* - `Time' is a 42 bit binary integer recording milliseconds since UTC 2012-01-01T00:00:00Z,
* - `MachineID' is a 10 bit integer identifying the Snowflake machine which generated the said ID,
* - and `SequenceID' is a 12 bit integer counting the number of IDs generated on this server,
*   this millisecond.
*/
struct SnowflakeSchema {
}

/**
* Internal identifier won't be generated, but picked as specified.
*/
struct ConstantSchema {
    /// Which internal identifier this binding will have?
    1: required InternalID internal_id
}

/**
* Internal identifier will be the next value of the specified sequence.
*
* Such IDs are more user-friendly yet cost a bit more to generate.
*/
struct SequenceSchema {
    /// Which sequence to pick value from?
    1: required string sequence_id
    /// Internal ID will be no less than that.
    /// If current value of the sequence is less than values up to `minimum` will be skipped.
    2: optional i64 minimum
}

/**
* Example for payment
* EntityRef{
*   id = "2LgwiBIRSnA"
*   external_id = "51d01a7e-cb25-4019-8b14-ee6bfe9bfdde"
*   issuer = "c448c2ca-be73-45f5-b550-c61c7f799d70"
*   scope = "payment"
*   sub = EntityRef{
*       id = "1"
*   }
* }
***
* Example for withdrawal
* EntityRef{
*   id = "1707419"
*   external_id = "100276096799"
*   issuer = "c448c2ca-be73-45f5-b550-c61c7f799d70"
*   scope = "withdrawal"
* }
*/
struct EntityRef {
    1: required InternalID id
    /// ???
    /// нужен ли здесь внешний идентификатор
    /// по идее при массовом поиске нужно будет понимать
    /// какому из запрошенных идентификаторов соответствует возвращенный экземпляр
    /// ???
    2: required PlainExternalID external_id
    /// aka party_id
    3: required string issuer
    4: required string scope
    /// For nested enities, for example payment
    5: optional SubEntityRef sub
}

struct SubEntityRef {
    1: required InternalID id
    2: optional SubEntityRef sub
}

struct GenerationInfo {
    1: required PlainExternalID identifier
    2: required string issuer
    3: required string scope
}

/// ???
/// пагинацией предлагаю не заморачиваться
/// так как для поиска всё равно передаётся пачка идентификаторов
/// то разбиение их на последовательность запросов разумных размеров
/// можно возложить на клиента
/// (тем более, что это наши же сервисы, а сам "нечёткий" массовый поиск пока только для внутреннего пользования)
/// ???
struct SearchParams {
    // The search logic will be similar to this query:
    // SELECT * FROM Entities WHERE
    // (id IN ids OR external_id IN ids)
    1: required set<BaseID> ids
    // AND issuer IN issuers
    2: optional set<string> issuers
    // AND scope IN scopes
    3: optional set<string> scopes
}

/// ???
/// Если отказаться от external_id внутри EntityRef
/// то ответ придется формировать через мапу вида:
/// map<BaseID, set<EntityRef>>
/// где BaseID - идентификатор, который был в параметрах поиска (может быть как внутренним, так и внешним)
/// но это кажется ненужным усложнением
/// ???
struct SearchInternalsResult {
    1: required set<EntityRef> refs
}

service Bender {

    /**
    * Generate unique internal identifier bound to the given external identifier.
    *
    * This operation will not fail, instead you always get details of the original binding in
    * response. Which means that, for example, you might get a Snowflake ID in response while
    * asking for next sequence value, because original binding was created with Snowflake schema.
    * If you happen to be the one who initially does the binding, you are the winner and your
    * `context` will be associated with that binding. If not, you will see the **context of the
    * winner** in response, not yours.
    */
    GenerationResult GenerateID (1: ExternalID external_id, 2: GenerationSchema schema, 3: msgpack.Value context)

    /**
    * Get binding details given external identifier.
    *
    * This operation will fail when there's no such binding, in contrast to `GenerateID`.
    */
    GetInternalIDResult GetInternalID (1: ExternalID external_id)
        throws (1: InternalIDNotFound ex1)

    GenerationResult IssueID (
        1: ExternalID external_id,
        2: GenerationSchema schema,
        3: msgpack.Value context,
        4: GenerationInfo info
    )

    SearchInternalsResult SearchInternals (1: SearchParams params)
        throws (1: InternalIDNotFound ex1)
}

service Generator {
    /**
    * Generate unique internal identifier.
    */
    GeneratedID GenerateID (1: GenerationSchema schema)
}
