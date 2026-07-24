// MoonBit Stream Quality Engine - Logfmt & KV Parser Module
// Copyright 2026 zmjknn
// Apache-2.0 License

///|
/// Parses a Logfmt line (e.g. `level=info method=GET status=200 duration=45.2ms`) into payload map.
pub fn parse_logfmt_line(line : String) -> Map[String, @core.Value] {
  let map : Map[String, @core.Value] = Map([])
  let len = line.length()
  if len == 0 {
    return map
  }

  let mut i = 0
  while i < len {
    // Skip whitespace
    while i < len && (line[i] == ' ' || line[i] == '\t') {
      i = i + 1
    }
    if i >= len {
      break
    }

    // Read key
    let key_start = i
    while i < len && line[i] != '=' && line[i] != ' ' && line[i] != '\t' {
      i = i + 1
    }
    let key = line[key_start:i].to_owned()

    if i < len && line[i] == '=' {
      i = i + 1 // skip '='
      // Read value
      let val_start = i
      if i < len && line[i] == '"' {
        i = i + 1 // skip opening quote
        let q_start = i
        while i < len && line[i] != '"' {
          i = i + 1
        }
        let val_str = line[q_start:i].to_owned()
        if i < len && line[i] == '"' {
          i = i + 1
        }
        map.set(key, auto_cast_value(val_str))
      } else {
        while i < len && line[i] != ' ' && line[i] != '\t' {
          i = i + 1
        }
        let val_str = line[val_start:i].to_owned()
        map.set(key, auto_cast_value(val_str))
      }
    } else if key.length() > 0 {
      // Key without value -> set to true
      map.set(key, @core.Value::Bool(true))
    }
  }

  map
}

///|
/// Parses a logfmt line into a StreamEvent.
pub fn parse_logfmt_event(
  event_id : String,
  logfmt_line : String,
  timestamp? : Int64 = 1700000000000L,
) -> @core.StreamEvent {
  let payload = parse_logfmt_line(logfmt_line)
  let level = match payload.get("level") {
    Some(String(l)) => l
    _ => "info"
  }
  @core.StreamEvent::new(
    event_id,
    timestamp,
    event_type="log_" + level,
    payload~,
  )
}
