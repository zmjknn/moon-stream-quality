// MoonBit Stream Quality Engine - Dead Letter Queue Module
// Copyright 2026 zmjknn
// Apache-2.0 License

///|
/// Dead Letter Queue Entry containing failed event, failure details, and retry metadata.
pub(all) struct DlqEntry {
  entry_id : String
  event : @core.StreamEvent
  reason : String
  mut retry_count : Int
  max_retries : Int
  timestamp : Int64
} derive(Eq, Debug)

///|
/// Creates a new DlqEntry.
pub fn DlqEntry::new(
  entry_id : String,
  event : @core.StreamEvent,
  reason : String,
  max_retries? : Int = 3,
  timestamp? : Int64 = 1700000000000L,
) -> DlqEntry {
  { entry_id, event, reason, retry_count: 0, max_retries, timestamp }
}

///|
/// Dead Letter Queue Manager handling bad events for audit & retry pipelines.
pub(all) struct DeadLetterQueueManager {
  capacity : Int
  queue : Array[DlqEntry]
  mut total_dropped : Int64
} derive(Eq, Debug)

///|
/// Creates a new DeadLetterQueueManager.
pub fn DeadLetterQueueManager::new(
  capacity? : Int = 1000,
) -> DeadLetterQueueManager {
  { capacity, queue: [], total_dropped: 0L }
}

///|
/// Enqueues a failed event into DLQ buffer.
pub fn DeadLetterQueueManager::push_failed_event(
  self : DeadLetterQueueManager,
  event : @core.StreamEvent,
  reason : String,
) -> Unit {
  if self.queue.length() >= self.capacity {
    let _ = self.queue.remove(0)
    self.total_dropped = self.total_dropped + 1L
  }
  let id = "dlq-" + event.event_id
  self.queue.push(DlqEntry::new(id, event, reason))
}

///|
/// Retrieves all DLQ entries ready for retry.
pub fn DeadLetterQueueManager::get_retryable_entries(
  self : DeadLetterQueueManager,
) -> Array[DlqEntry] {
  let retryable : Array[DlqEntry] = []
  for i = 0; i < self.queue.length(); i = i + 1 {
    let entry = self.queue[i]
    if entry.retry_count < entry.max_retries {
      retryable.push(entry)
    }
  }
  retryable
}

///|
/// Increments retry count for an entry.
pub fn DeadLetterQueueManager::mark_retried(
  self : DeadLetterQueueManager,
  entry_id : String,
) -> Unit {
  for i = 0; i < self.queue.length(); i = i + 1 {
    if self.queue[i].entry_id == entry_id {
      self.queue[i].retry_count = self.queue[i].retry_count + 1
      break
    }
  }
}

///|
/// Finds a stable DLQ entry by its audit identifier.
pub fn DeadLetterQueueManager::find_entry(
  self : DeadLetterQueueManager,
  entry_id : String,
) -> DlqEntry? {
  for i = 0; i < self.queue.length(); i = i + 1 {
    if self.queue[i].entry_id == entry_id {
      return Some(self.queue[i])
    }
  }
  None
}

///|
/// Formats DLQ contents as JSON audit log.
pub fn DeadLetterQueueManager::to_json_audit(
  self : DeadLetterQueueManager,
) -> String {
  let mut s = "{\"dlq_capacity\":" +
    self.capacity.to_string() +
    ",\"current_size\":" +
    self.queue.length().to_string() +
    ",\"total_dropped\":" +
    self.total_dropped.to_string() +
    ",\"entries\":["
  for i = 0; i < self.queue.length(); i = i + 1 {
    if i > 0 {
      s = s + ","
    }
    let entry = self.queue[i]
    s = s +
      "{\"entry_id\":\"" +
      entry.entry_id +
      "\",\"reason\":\"" +
      entry.reason +
      "\",\"retries\":" +
      entry.retry_count.to_string() +
      ",\"event\":" +
      entry.event.to_json_string() +
      "}"
  }
  s + "]}"
}
