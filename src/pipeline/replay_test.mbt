// MoonBit Stream Quality Engine - Checkpoint and Replay Tests
// Copyright 2026 zmjknn
// Apache-2.0 License

///|
fn checkpoint_event(offset : Int64, timestamp : Int64) -> @core.StreamEvent {
  let meta = @core.EventMeta::new(source_id="orders", partition=2, offset~)
  @core.StreamEvent::new("evt-" + offset.to_string(), timestamp, meta~)
}

///|
test "checkpoint round trip preserves monotonic progress" {
  let checkpoint = PipelineCheckpoint::new("orders", "source-a", 2, 10L)
  checkpoint.advance(checkpoint_event(12L, 100L), true, 100L)
  checkpoint.advance(checkpoint_event(11L, 90L), false, 90L)
  assert_eq(checkpoint.offset, 12L)
  assert_eq(checkpoint.watermark, 100L)
  assert_eq(checkpoint.accepted, 1L)
  assert_eq(checkpoint.rejected, 1L)
  let restored = PipelineCheckpoint::from_json(checkpoint.to_json()).unwrap()
  assert_eq(restored, checkpoint)
}

///|
test "malformed checkpoints are rejected" {
  assert_eq(PipelineCheckpoint::from_json("not-json"), None)
  assert_eq(
    PipelineCheckpoint::from_json("{\"pipeline_name\":\"only-name\"}"),
    None,
  )
}

///|
test "empty replay plan has zero counts" {
  let queue = DeadLetterQueueManager::new(capacity=2)
  let checkpoint = PipelineCheckpoint::new("orders", "source-a", 2, 0L)
  let plan = build_replay_plan(checkpoint, queue)
  let result = replay_plan(plan, queue)
  assert_eq(result, { attempted: 0, replayed: 0, exhausted: 0, missing: 0 })
}

///|
test "replay plan retries each entry once even when duplicated" {
  let queue = DeadLetterQueueManager::new(capacity=2)
  let event = checkpoint_event(20L, 200L)
  queue.push_failed_event(event, "temporary")
  let checkpoint = PipelineCheckpoint::new("orders", "source-a", 2, 20L)
  let plan = ReplayPlan::{
    checkpoint,
    entry_ids: ["dlq-evt-20", "dlq-evt-20"],
    max_attempts: 3,
  }
  let result = replay_plan(plan, queue)
  assert_eq(result.attempted, 1)
  assert_eq(result.replayed, 1)
  assert_eq(queue.find_entry("dlq-evt-20").unwrap().retry_count, 1)
}

///|
test "replay reports missing and exhausted entries" {
  let queue = DeadLetterQueueManager::new(capacity=2)
  let event = checkpoint_event(21L, 210L)
  queue.push_failed_event(event, "permanent")
  queue.mark_retried("dlq-evt-21")
  queue.mark_retried("dlq-evt-21")
  queue.mark_retried("dlq-evt-21")
  let checkpoint = PipelineCheckpoint::new("orders", "source-a", 2, 21L)
  let plan = ReplayPlan::{
    checkpoint,
    entry_ids: ["dlq-evt-21", "missing"],
    max_attempts: 2,
  }
  let result = replay_plan(plan, queue)
  assert_eq(result.attempted, 0)
  assert_eq(result.exhausted, 1)
  assert_eq(result.missing, 1)
}
