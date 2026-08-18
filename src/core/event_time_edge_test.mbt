// MoonBit Stream Quality Engine - Event-time Edge Coverage
// Copyright 2026 zmjknn
// Apache-2.0 License

///|
fn edge_event(timestamp : Int64) -> StreamEvent {
  StreamEvent::new("edge-" + timestamp.to_string(), timestamp)
}

///|
test "negative timestamps remain in the safe first window" {
  let runtime = WindowRuntime::new(100L)
  assert_eq(runtime.ingest(edge_event(-100L)), OnTime)
  let windows = runtime.flush()
  assert_eq(windows.length(), 1)
  assert_eq(windows[0].start, 0L)
  assert_eq(windows[0].events.length(), 1)
}

///|
test "drop policy does not retain too-late events" {
  let runtime = WindowRuntime::new(100L, allowed_lateness_ms=10L, policy=Drop)
  let _ = runtime.ingest(edge_event(100L))
  assert_eq(runtime.ingest(edge_event(-100L)), TooLate)
  assert_eq(runtime.active_window_count(), 1)
  assert_eq(runtime.dropped_count, 1)
}

///|
test "watermark closes only windows behind the boundary" {
  let runtime = WindowRuntime::new(100L)
  let _ = runtime.ingest(edge_event(1L))
  let _ = runtime.ingest(edge_event(101L))
  let closed = runtime.advance_watermark(150L)
  assert_eq(closed.length(), 1)
  assert_eq(closed[0].start, 0L)
  assert_eq(runtime.active_window_count(), 1)
  assert_eq(runtime.flush()[0].start, 100L)
}

///|
test "capacity eviction is counted separately from late events" {
  let runtime = WindowRuntime::new(10L, max_windows=1)
  let _ = runtime.ingest(edge_event(1L))
  let _ = runtime.ingest(edge_event(11L))
  assert_eq(runtime.active_window_count(), 1)
  assert_eq(runtime.dropped_count, 1)
  assert_eq(runtime.late_event_count(), 0)
}

///|
test "accept policy retains a too-late record in its original window" {
  let runtime = WindowRuntime::new(100L, allowed_lateness_ms=10L, policy=Accept)
  let _ = runtime.ingest(edge_event(200L))
  assert_eq(runtime.ingest(edge_event(1L)), TooLate)
  let windows = runtime.flush()
  assert_eq(windows.length(), 2)
  assert_eq(windows[0].events.length(), 1)
}

///|
test "side output counts late records without changing window capacity" {
  let runtime = WindowRuntime::new(100L, allowed_lateness_ms=20L)
  let _ = runtime.ingest(edge_event(100L))
  assert_eq(runtime.ingest(edge_event(79L)), Late)
  assert_eq(runtime.ingest(edge_event(0L)), TooLate)
  assert_eq(runtime.late_event_count(), 2)
  assert_eq(runtime.active_window_count(), 2)
}
