// MoonBit Stream Quality Engine - Core Event Module
// Copyright 2026 zmjknn
// Apache-2.0 License

/// Stream event metadata containing source, partition, and offsets.
pub(all) struct EventMeta {
  source_id : String
  partition : Int
  offset : Int64
  ingest_timestamp : Int64
  attributes : Map[String, String]
} derive(Eq, Debug)

/// Creates a new default EventMeta.
pub fn EventMeta::new(
  source_id~ : String = "default_source",
  partition~ : Int = 0,
  offset~ : Int64 = 0L,
  ingest_timestamp~ : Int64 = 0L
) -> EventMeta {
  {
    source_id,
    partition,
    offset,
    ingest_timestamp,
    attributes: Map([]),
  }
}

/// Dynamic Stream Event containing ID, event timestamp, payload fields, and metadata.
pub(all) struct StreamEvent {
  event_id : String
  timestamp : Int64
  event_type : String
  payload : Map[String, Value]
  meta : EventMeta
} derive(Eq, Debug)

/// Creates a new StreamEvent.
pub fn StreamEvent::new(
  event_id : String,
  timestamp : Int64,
  event_type~ : String = "default",
  payload~ : Map[String, Value] = Map([]),
  meta~ : EventMeta = EventMeta::new()
) -> StreamEvent {
  { event_id, timestamp, event_type, payload, meta }
}

/// Retrieves a value from event payload by key.
pub fn StreamEvent::get(self : StreamEvent, key : String) -> Value? {
  self.payload.get(key)
}

/// Sets a payload key-value pair in event.
pub fn StreamEvent::set(self : StreamEvent, key : String, val : Value) -> Unit {
  self.payload.set(key, val)
}

/// Checks if event contains a payload key.
pub fn StreamEvent::contains_key(self : StreamEvent, key : String) -> Bool {
  match self.payload.get(key) {
    Some(v) => !v.is_null()
    None => false
  }
}

/// Checks if a key exists in payload even if value is null.
pub fn StreamEvent::has_field(self : StreamEvent, key : String) -> Bool {
  match self.payload.get(key) {
    Some(_) => true
    None => false
  }
}

/// Gets a numeric double value from payload.
pub fn StreamEvent::get_double(self : StreamEvent, key : String) -> Double? {
  match self.payload.get(key) {
    Some(v) => v.as_double()
    None => None
  }
}

/// Gets an integer value from payload.
pub fn StreamEvent::get_int(self : StreamEvent, key : String) -> Int64? {
  match self.payload.get(key) {
    Some(v) => v.as_int()
    None => None
  }
}

/// Gets a string value from payload.
pub fn StreamEvent::get_string(self : StreamEvent, key : String) -> String? {
  match self.payload.get(key) {
    Some(v) => v.as_string()
    None => None
  }
}

/// Gets a boolean value from payload.
pub fn StreamEvent::get_bool(self : StreamEvent, key : String) -> Bool? {
  match self.payload.get(key) {
    Some(v) => v.as_bool()
    None => None
  }
}

/// Counts total fields in payload.
pub fn StreamEvent::field_count(self : StreamEvent) -> Int {
  let mut count = 0
  self.payload.each(fn(_k, _v) { count = count + 1 })
  count
}

/// Formats StreamEvent as JSON-like string.
pub fn StreamEvent::to_json_string(self : StreamEvent) -> String {
  let mut res = "{\"event_id\":\"" + self.event_id + "\",\"timestamp\":" + self.timestamp.to_string() + ",\"event_type\":\"" + self.event_type + "\",\"payload\":{"
  let mut first = true
  self.payload.each(fn(k, v) {
    if !first {
      res = res + ","
    }
    res = res + "\"" + k + "\":" + v.to_string()
    first = false
  })
  res + "}}"
}
