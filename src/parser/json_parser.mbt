// MoonBit Stream Quality Engine - Streaming JSON Parser Module
// Copyright 2026 zmjknn
// Apache-2.0 License

///|
/// JSON Parse Error description.
pub(all) struct JsonParseError {
  position : Int
  message : String
} derive(Eq, Debug)

///|
fn unescape_json_string(value : String) -> String {
  let mut result = ""
  let mut index = 0
  while index < value.length() {
    let c = value[index].to_int().unsafe_to_char()
    if c == '\\' && index + 1 < value.length() {
      let next = value[index + 1].to_int().unsafe_to_char()
      if next == '"' || next == '\\' || next == '/' {
        result = result + String::make(1, next.to_int().unsafe_to_char())
        index = index + 2
        continue
      }
    }
    result = result + String::make(1, c.to_int().unsafe_to_char())
    index = index + 1
  }
  result
}

///|
/// Parses a JSON string into a core @core.Value.
pub fn parse_json_value(json_str : String) -> @core.Value? {
  let len = json_str.length()
  if len == 0 {
    return None
  }

  let s = json_str.trim().to_owned()
  if s == "null" {
    return Some(@core.Value::Null)
  }
  if s == "true" {
    return Some(@core.Value::Bool(true))
  }
  if s == "false" {
    return Some(@core.Value::Bool(false))
  }
  if s.has_prefix("\"") && s.has_suffix("\"") && s.length() >= 2 {
    let inner = unescape_json_string(s[1:s.length() - 1].to_owned())
    return Some(@core.Value::String(inner))
  }
  if s.has_prefix("[") && s.has_suffix("]") {
    return parse_json_array(s)
  }
  if s.has_prefix("{") && s.has_suffix("}") {
    return parse_json_object(s)
  }

  // Parse as number
  try {
    if s.contains(".") {
      Some(@core.Value::Double(@string.parse_double(s)))
    } else {
      Some(@core.Value::Int(@string.parse_int64(s)))
    }
  } catch {
    _ => None
  }
}

///|
/// Helper parsing JSON array.
fn parse_json_array(s : String) -> @core.Value? {
  let inner = s[1:s.length() - 1].trim().to_owned()
  if inner.length() == 0 {
    return Some(@core.Value::Array([]))
  }

  let items : Array[@core.Value] = []
  let mut start = 0
  let mut depth = 0
  let mut in_quote = false

  for i = 0; i < inner.length(); i = i + 1 {
    let c = inner[i]
    if c == '"' {
      in_quote = !in_quote
    } else if !in_quote {
      if c == '{' || c == '[' {
        depth = depth + 1
      } else if c == '}' || c == ']' {
        depth = depth - 1
      } else if c == ',' && depth == 0 {
        let item_str = inner[start:i].trim().to_owned()
        match parse_json_value(item_str) {
          Some(v) => items.push(v)
          None => return None
        }
        start = i + 1
      }
    }
  }

  if start < inner.length() {
    let item_str = inner[start:].trim().to_owned()
    match parse_json_value(item_str) {
      Some(v) => items.push(v)
      None => return None
    }
  }

  Some(@core.Value::Array(items))
}

///|
/// Helper parsing JSON object into Value::Map or StreamEvent payload.
fn parse_json_object(s : String) -> @core.Value? {
  let inner = s[1:s.length() - 1].trim().to_owned()
  let map : Map[String, @core.Value] = Map([])
  if inner.length() == 0 {
    return Some(@core.Value::Map(map))
  }

  let mut start = 0
  let mut depth = 0
  let mut in_quote = false

  for i = 0; i < inner.length(); i = i + 1 {
    let c = inner[i]
    if c == '"' {
      in_quote = !in_quote
    } else if !in_quote {
      if c == '{' || c == '[' {
        depth = depth + 1
      } else if c == '}' || c == ']' {
        depth = depth - 1
      } else if c == ',' && depth == 0 {
        let pair_str = inner[start:i].trim().to_owned()
        parse_kv_pair(pair_str, map)
        start = i + 1
      }
    }
  }

  if start < inner.length() {
    let pair_str = inner[start:].trim().to_owned()
    parse_kv_pair(pair_str, map)
  }

  Some(@core.Value::Map(map))
}

///|
/// Helper parsing "key": value pair.
fn parse_kv_pair(pair_str : String, map : Map[String, @core.Value]) -> Unit {
  let mut colon_idx = -1
  let mut in_quote = false
  for i = 0; i < pair_str.length(); i = i + 1 {
    let c = pair_str[i]
    if c == '"' {
      in_quote = !in_quote
    } else if !in_quote && c == ':' {
      colon_idx = i
      break
    }
  }

  if colon_idx > 0 {
    let raw_key = pair_str[0:colon_idx].trim().to_owned()
    let key = if raw_key.has_prefix("\"") &&
      raw_key.has_suffix("\"") &&
      raw_key.length() >= 2 {
      raw_key[1:raw_key.length() - 1].to_owned()
    } else {
      raw_key
    }
    let val_str = pair_str[colon_idx + 1:].trim().to_owned()
    match parse_json_value(val_str) {
      Some(v) => map.set(key, v)
      None => ()
    }
  }
}

///|
/// Parses a JSON event line into a @core.StreamEvent.
pub fn parse_json_event(
  event_id : String,
  json_line : String,
  timestamp? : Int64 = 0L,
) -> @core.StreamEvent? {
  match parse_json_value(json_line) {
    Some(Map(payload)) => {
      let ts = match payload.get("timestamp") {
        Some(Int(t)) => t
        Some(Double(d)) => d.to_int64()
        _ => if timestamp != 0L { timestamp } else { 1700000000000L }
      }
      let evt_type = match payload.get("event_type") {
        Some(String(st)) => st
        _ => "json_event"
      }
      Some(@core.StreamEvent::new(event_id, ts, event_type=evt_type, payload~))
    }
    _ => None
  }
}
