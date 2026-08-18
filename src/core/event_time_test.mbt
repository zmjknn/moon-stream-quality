// MoonBit Stream Quality Engine - Event-time Runtime Tests
// Copyright 2026 zmjknn
// Apache-2.0 License

///|
fn event_at(timestamp : Int64) -> StreamEvent {
  StreamEvent::new("event-" + timestamp.to_string(), timestamp)
}

///|
test "watermark keeps the highest observed timestamp" {
  let tracker = WatermarkTracker::new(allowed_lateness_ms=100L)
  assert_eq(tracker.observe(1000L), 900L)
  assert_eq(tracker.observe(900L), 900L)
  assert_eq(tracker.observe(1250L), 1150L)
}

///|
test "watermark classifies exact and late boundaries" {
  let tracker = WatermarkTracker::new(allowed_lateness_ms=100L)
  assert_eq(tracker.classify(100L), OnTime)
  let _ = tracker.observe(1000L)
  assert_eq(tracker.classify(900L), OnTime)
  assert_eq(tracker.classify(899L), Late)
  assert_eq(tracker.classify(799L), TooLate)
}

///|
test "uninitialized and zero lateness trackers are safe" {
  let empty = WatermarkTracker::new()
  assert_eq(empty.classify(-100L), OnTime)
  let exact = WatermarkTracker::new(allowed_lateness_ms=-10L)
  let _ = exact.observe(100L)
  assert_eq(exact.classify(100L), OnTime)
  assert_eq(exact.classify(99L), TooLate)
}

///|
test "runtime assigns events to deterministic windows" {
  let runtime = WindowRuntime::new(1000L, allowed_lateness_ms=100L)
  assert_eq(runtime.active_window_count(), 0)
  assert_eq(runtime.ingest(event_at(1L)), OnTime)
  assert_eq(runtime.ingest(event_at(999L)), OnTime)
  assert_eq(runtime.ingest(event_at(1000L)), OnTime)
  assert_eq(runtime.active_window_count(), 2)
  let closed = runtime.advance_watermark(1100L)
  assert_eq(closed.length(), 1)
  assert_eq(closed[0].start, 0L)
  assert_eq(closed[0].end, 1000L)
  assert_eq(closed[0].events.length(), 2)
}

///|
test "runtime counts late events and applies side output policy" {
  let runtime = WindowRuntime::new(
    1000L,
    allowed_lateness_ms=100L,
    policy=SideOutput,
  )
  let _ = runtime.ingest(event_at(1000L))
  assert_eq(runtime.ingest(event_at(899L)), Late)
  assert_eq(runtime.late_event_count(), 1)
  assert_eq(runtime.ingest(event_at(799L)), TooLate)
  assert_eq(runtime.late_event_count(), 2)
  assert_eq(runtime.active_window_count(), 2)
}

///|
test "runtime accepts too-late events when configured" {
  let runtime = WindowRuntime::new(
    1000L,
    allowed_lateness_ms=100L,
    policy=Accept,
  )
  let _ = runtime.ingest(event_at(1000L))
  assert_eq(runtime.ingest(event_at(700L)), TooLate)
  assert_eq(runtime.late_event_count(), 1)
  assert_eq(runtime.active_window_count(), 2)
}

///|
test "runtime normalizes unsafe capacity and flush is idempotent" {
  let runtime = WindowRuntime::new(-1L, max_windows=0)
  let _ = runtime.ingest(event_at(1L))
  let first = runtime.flush()
  assert_eq(first.length(), 1)
  assert_eq(first[0].closed, true)
  assert_eq(runtime.flush().length(), 0)
}

///|
test "runtime keeps only configured number of active windows" {
  let runtime = WindowRuntime::new(10L, max_windows=2)
  let _ = runtime.ingest(event_at(1L))
  let _ = runtime.ingest(event_at(11L))
  let _ = runtime.ingest(event_at(21L))
  assert_eq(runtime.active_window_count(), 2)
  assert_eq(runtime.flush().length(), 2)
}
