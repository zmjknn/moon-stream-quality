// MoonBit Stream Quality Engine - Pipeline Checkpoints
// Copyright 2026 zmjknn
// Apache-2.0 License

///|
/// Serializable progress marker for one source partition.
pub(all) struct PipelineCheckpoint {
  pipeline_name : String
  source_id : String
  partition : Int
  mut offset : Int64
  mut watermark : Int64
  mut accepted : Int64
  mut rejected : Int64
  mut dlq_cursor : Int
} derive(Eq, Debug)

///|
/// Creates a checkpoint with a non-negative partition cursor.
pub fn PipelineCheckpoint::new(
  pipeline_name : String,
  source_id : String,
  partition : Int,
  offset : Int64,
) -> PipelineCheckpoint {
  {
    pipeline_name,
    source_id,
    partition: if partition < 0 {
      0
    } else {
      partition
    },
    offset,
    watermark: 0L,
    accepted: 0L,
    rejected: 0L,
    dlq_cursor: 0,
  }
}

///|
/// Advances counters and monotonic source/watermark cursors.
pub fn PipelineCheckpoint::advance(
  self : PipelineCheckpoint,
  event : @core.StreamEvent,
  passed : Bool,
  watermark : Int64,
) -> Unit {
  if event.meta.partition == self.partition && event.meta.offset > self.offset {
    self.offset = event.meta.offset
  }
  if watermark > self.watermark {
    self.watermark = watermark
  }
  if passed {
    self.accepted = self.accepted + 1L
  } else {
    self.rejected = self.rejected + 1L
    self.dlq_cursor = self.dlq_cursor + 1
  }
}

///|
fn checkpoint_escape(value : String) -> String {
  let mut escaped = ""
  for index = 0; index < value.length(); index = index + 1 {
    let c = value[index].to_int().unsafe_to_char()
    if c == '"' || c == '\\' {
      escaped = escaped + "\\"
    }
    escaped = escaped + String::make(1, c.to_int().unsafe_to_char())
  }
  escaped
}

///|
/// Produces a stable JSON object with no optional fields.
pub fn PipelineCheckpoint::to_json(self : PipelineCheckpoint) -> String {
  "{\"pipeline_name\":\"" +
  checkpoint_escape(self.pipeline_name) +
  "\",\"source_id\":\"" +
  checkpoint_escape(self.source_id) +
  "\",\"partition\":" +
  self.partition.to_string() +
  ",\"offset\":" +
  self.offset.to_string() +
  ",\"watermark\":" +
  self.watermark.to_string() +
  ",\"accepted\":" +
  self.accepted.to_string() +
  ",\"rejected\":" +
  self.rejected.to_string() +
  ",\"dlq_cursor\":" +
  self.dlq_cursor.to_string() +
  "}"
}

///|
fn checkpoint_string(
  values : Map[String, @core.Value],
  key : String,
) -> String? {
  match values.get(key) {
    Some(@core.Value::String(value)) => Some(value)
    _ => None
  }
}

///|
fn checkpoint_int(values : Map[String, @core.Value], key : String) -> Int64? {
  match values.get(key) {
    Some(@core.Value::Int(value)) => Some(value)
    Some(@core.Value::Timestamp(value)) => Some(value)
    Some(@core.Value::Double(value)) => Some(value.to_int64())
    Some(@core.Value::String(value)) =>
      Some(@string.parse_int64(value)) catch {
        _ => None
      }
    _ => None
  }
}

///|
/// Parses a checkpoint only when every required field is present and typed.
pub fn PipelineCheckpoint::from_json(input : String) -> PipelineCheckpoint? {
  match @parser.parse_json_value(input) {
    Some(@core.Value::Map(values)) =>
      match
        (
          checkpoint_string(values, "pipeline_name"),
          checkpoint_string(values, "source_id"),
          checkpoint_int(values, "partition"),
          checkpoint_int(values, "offset"),
          checkpoint_int(values, "watermark"),
          checkpoint_int(values, "accepted"),
          checkpoint_int(values, "rejected"),
          checkpoint_int(values, "dlq_cursor"),
        ) {
        (
          Some(pipeline_name),
          Some(source_id),
          Some(partition),
          Some(offset),
          Some(watermark),
          Some(accepted),
          Some(rejected),
          Some(dlq_cursor),
        ) =>
          Some({
            pipeline_name,
            source_id,
            partition: partition.to_int(),
            offset,
            watermark,
            accepted,
            rejected,
            dlq_cursor: dlq_cursor.to_int(),
          })
        _ => None
      }
    _ => None
  }
}
