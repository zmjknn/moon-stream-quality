// MoonBit Stream Quality Engine - Multi-Stream Validation Module
// Copyright 2026 zmjknn
// Apache-2.0 License

///|
/// Multi-Stream Join Validation Strategy.
pub(all) enum StreamJoinKind {
  InnerJoin
  LeftOuterJoin
  WindowJoin(Int64) // window size ms
} derive(Eq, Debug)

///|
/// Stream Join Quality Violation.
pub(all) struct StreamJoinViolation {
  left_event_id : String
  right_event_id : String
  join_key : String
  reason : String
  skew_ms : Int64
} derive(Eq, Debug)

///|
/// Multi-Stream Join Validator tracking dual stream synchronization quality.
pub(all) struct MultiStreamJoinValidator {
  left_stream_id : String
  right_stream_id : String
  join_key_field : String
  join_kind : StreamJoinKind
  left_buffer : Map[String, @core.StreamEvent]
  right_buffer : Map[String, @core.StreamEvent]
  max_skew_ms : Int64
} derive(Eq, Debug)

///|
/// Creates a new MultiStreamJoinValidator.
pub fn MultiStreamJoinValidator::new(
  left_stream_id : String,
  right_stream_id : String,
  join_key_field : String,
  join_kind? : StreamJoinKind = InnerJoin,
  max_skew_ms? : Int64 = 10000L,
) -> MultiStreamJoinValidator {
  {
    left_stream_id,
    right_stream_id,
    join_key_field,
    join_kind,
    left_buffer: Map([]),
    right_buffer: Map([]),
    max_skew_ms,
  }
}

///|
/// Ingests an event into the left stream.
pub fn MultiStreamJoinValidator::ingest_left(
  self : MultiStreamJoinValidator,
  event : @core.StreamEvent,
) -> Unit {
  match event.get_string(self.join_key_field) {
    Some(key) => self.left_buffer.set(key, event)
    None => ()
  }
}

///|
/// Ingests an event into the right stream.
pub fn MultiStreamJoinValidator::ingest_right(
  self : MultiStreamJoinValidator,
  event : @core.StreamEvent,
) -> Unit {
  match event.get_string(self.join_key_field) {
    Some(key) => self.right_buffer.set(key, event)
    None => ()
  }
}

///|
/// Validates stream join integrity and skew violations.
pub fn MultiStreamJoinValidator::validate_join_integrity(
  self : MultiStreamJoinValidator,
) -> Array[StreamJoinViolation] {
  let violations : Array[StreamJoinViolation] = []

  self.left_buffer.each(fn(key, left_evt) {
    match self.right_buffer.get(key) {
      Some(right_evt) => {
        let skew = left_evt.timestamp - right_evt.timestamp
        let abs_skew = if skew < 0L { -skew } else { skew }
        if abs_skew > self.max_skew_ms {
          violations.push({
            left_event_id: left_evt.event_id,
            right_event_id: right_evt.event_id,
            join_key: key,
            reason: "Stream join timestamp skew exceeded threshold",
            skew_ms: abs_skew,
          })
        }
      }
      None =>
        match self.join_kind {
          InnerJoin =>
            violations.push({
              left_event_id: left_evt.event_id,
              right_event_id: "<missing>",
              join_key: key,
              reason: "Unmatched inner join key in right stream",
              skew_ms: 0L,
            })
          _ => ()
        }
    }
  })

  violations
}
