// MoonBit Stream Quality Engine - Core Context Module
// Copyright 2026 zmjknn
// Apache-2.0 License

/// Streaming execution context holding watermark, event counters, and runtime configuration.
pub(all) struct StreamContext {
  mut watermark : Int64
  mut total_events_processed : Int64
  mut total_errors_encountered : Int64
  mut current_batch_id : String
  properties : Map[String, String]
} derive(Eq, Debug)

/// Creates a new StreamContext.
pub fn StreamContext::new(batch_id~ : String = "batch-0") -> StreamContext {
  {
    watermark: 0L,
    total_events_processed: 0L,
    total_errors_encountered: 0L,
    current_batch_id: batch_id,
    properties: Map([]),
  }
}

/// Updates the current watermark timestamp if new timestamp is higher.
pub fn StreamContext::update_watermark(self : StreamContext, timestamp : Int64) -> Unit {
  if timestamp > self.watermark {
    self.watermark = timestamp
  }
}

/// Increments event counter.
pub fn StreamContext::inc_events(self : StreamContext) -> Unit {
  self.total_events_processed = self.total_events_processed + 1L
}

/// Increments error counter.
pub fn StreamContext::inc_errors(self : StreamContext) -> Unit {
  self.total_errors_encountered = self.total_errors_encountered + 1L
}

/// Gets a property from context.
pub fn StreamContext::get_property(self : StreamContext, key : String) -> String? {
  self.properties.get(key)
}

/// Sets a property in context.
pub fn StreamContext::set_property(self : StreamContext, key : String, val : String) -> Unit {
  self.properties.set(key, val)
}

/// Resets the context metrics.
pub fn StreamContext::reset(self : StreamContext, new_batch_id : String) -> Unit {
  self.watermark = 0L
  self.total_events_processed = 0L
  self.total_errors_encountered = 0L
  self.current_batch_id = new_batch_id
}
