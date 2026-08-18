// MoonBit Stream Quality Engine - Replay Boundary Coverage
// Copyright 2026 zmjknn
// Apache-2.0 License

///|
fn replay_edge_event(id : String, offset : Int64) -> @core.StreamEvent {
  let meta = @core.EventMeta::new(source_id="edge", partition=0, offset~)
  @core.StreamEvent::new(id, 1000L + offset, meta~)
}

///|
test "checkpoint normalizes a negative partition" {
  let checkpoint = PipelineCheckpoint::new("p", "s", -4, 0L)
  assert_eq(checkpoint.partition, 0)
}

///|
test "checkpoint ignores another partition and regressing cursors" {
  let checkpoint = PipelineCheckpoint::new("p", "s", 1, 10L)
  checkpoint.advance(replay_edge_event("other", 99L), true, 50L)
  checkpoint.advance(
    @core.StreamEvent::new(
      "same-partition",
      100L,
      meta=@core.EventMeta::new(source_id="edge", partition=1, offset=9L),
    ),
    true,
    40L,
  )
  assert_eq(checkpoint.offset, 10L)
  assert_eq(checkpoint.watermark, 50L)
  assert_eq(checkpoint.accepted, 2L)
}

///|
test "replay attempts are capped after duplicate ids are removed" {
  let queue = DeadLetterQueueManager::new(capacity=4)
  for offset in [1L, 2L, 3L] {
    queue.push_failed_event(
      replay_edge_event("e-" + offset.to_string(), offset),
      "retry",
    )
  }
  let plan = ReplayPlan::{
    checkpoint: PipelineCheckpoint::new("p", "s", 0, 0L),
    entry_ids: ["dlq-e-1", "dlq-e-1", "dlq-e-2", "dlq-e-3"],
    max_attempts: 2,
  }
  let result = replay_plan(plan, queue)
  assert_eq(result.attempted, 2)
  assert_eq(result.replayed, 2)
  assert_eq(queue.find_entry("dlq-e-3").unwrap().retry_count, 0)
}

///|
test "zero replay limit is safely treated as one attempt" {
  let queue = DeadLetterQueueManager::new(capacity=2)
  queue.push_failed_event(replay_edge_event("one", 1L), "retry")
  queue.push_failed_event(replay_edge_event("two", 2L), "retry")
  let plan = ReplayPlan::{
    checkpoint: PipelineCheckpoint::new("p", "s", 0, 0L),
    entry_ids: ["dlq-one", "dlq-two"],
    max_attempts: 0,
  }
  let result = replay_plan(plan, queue)
  assert_eq(result.attempted, 1)
  assert_eq(result.replayed, 1)
}

///|
test "checkpoint JSON escapes quote and slash characters" {
  let checkpoint = PipelineCheckpoint::new("p\"ipeline", "source\\id", 0, 1L)
  let json = checkpoint.to_json()
  assert_eq(json.contains("p\\\"ipeline"), true)
  assert_eq(json.contains("source\\\\id"), true)
}
