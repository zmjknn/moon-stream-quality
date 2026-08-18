// MoonBit Stream Quality Engine - Watermark Boundary Coverage
// Copyright 2026 zmjknn
// Apache-2.0 License

///|
test "uninitialized watermark classifies any first timestamp on time" {
  let tracker = WatermarkTracker::new(allowed_lateness_ms=100L)
  assert_eq(tracker.classify(-999L), OnTime)
  assert_eq(tracker.observe(-999L), -1099L)
}

///|
test "watermark never moves backwards on older observations" {
  let tracker = WatermarkTracker::new(allowed_lateness_ms=10L)
  assert_eq(tracker.observe(100L), 90L)
  assert_eq(tracker.observe(50L), 90L)
  assert_eq(tracker.observe(120L), 110L)
}

///|
test "negative lateness is normalized to zero" {
  let tracker = WatermarkTracker::new(allowed_lateness_ms=-50L)
  assert_eq(tracker.observe(8L), 8L)
  assert_eq(tracker.classify(7L), TooLate)
}

///|
test "late classification has a bounded grace interval" {
  let tracker = WatermarkTracker::new(allowed_lateness_ms=20L)
  let _ = tracker.observe(100L)
  assert_eq(tracker.classify(80L), OnTime)
  assert_eq(tracker.classify(79L), Late)
  assert_eq(tracker.classify(59L), TooLate)
}

///|
test "equal timestamps do not reset the tracker" {
  let tracker = WatermarkTracker::new(allowed_lateness_ms=5L)
  assert_eq(tracker.observe(30L), 25L)
  assert_eq(tracker.observe(30L), 25L)
  assert_eq(tracker.classify(25L), OnTime)
}

///|
test "zero lateness makes the watermark boundary inclusive" {
  let tracker = WatermarkTracker::new()
  let _ = tracker.observe(10L)
  assert_eq(tracker.classify(10L), OnTime)
  assert_eq(tracker.classify(9L), TooLate)
}

///|
test "negative event timestamps share the non-negative first window" {
  let runtime = WindowRuntime::new(10L)
  let _ = runtime.ingest(StreamEvent::new("negative", -1L))
  let _ = runtime.ingest(StreamEvent::new("zero", 0L))
  let windows = runtime.flush()
  assert_eq(windows.length(), 1)
  assert_eq(windows[0].start, 0L)
  assert_eq(windows[0].events.length(), 2)
}

///|
test "non-positive window and capacity values remain usable" {
  let runtime = WindowRuntime::new(0L, max_windows=0)
  let _ = runtime.ingest(StreamEvent::new("one", 1L))
  assert_eq(runtime.active_window_count(), 1)
  assert_eq(runtime.flush().length(), 1)
}
