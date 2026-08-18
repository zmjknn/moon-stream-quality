// MoonBit Stream Quality Engine - Stream Health Tests
// Copyright 2026 zmjknn
// Apache-2.0 License

///|
fn health_event(event_id : String, timestamp : Int64) -> @core.StreamEvent {
  @core.StreamEvent::new(event_id, timestamp)
}

///|
test "quantile sketch handles empty, clamped, and bounded samples" {
  let sketch = QuantileSketch::new(capacity=2)
  assert_eq(sketch.quantile(50.0), None)
  sketch.add(1.0)
  sketch.add(2.0)
  sketch.add(3.0)
  assert_eq(sketch.quantile(-10.0), Some(2.0))
  assert_eq(sketch.quantile(50.0), Some(2.5))
  assert_eq(sketch.quantile(101.0), Some(3.0))
}

///|
test "empty monitor is starved and has safe latency values" {
  let monitor = StreamHealthMonitor::new(1000L, min_events=1, max_events=3)
  let snapshot = monitor.snapshot()
  assert_eq(snapshot.total, 0L)
  assert_eq(snapshot.p50_latency_ms, 0.0)
  assert_eq(snapshot.status, Starved)
}

///|
test "healthy observations calculate latency percentiles" {
  let monitor = StreamHealthMonitor::new(1000L, min_events=1, max_events=3)
  monitor.observe(health_event("a", 100L), true, observed_at=110L)
  monitor.observe(health_event("b", 200L), true, observed_at=240L)
  let snapshot = monitor.snapshot()
  assert_eq(snapshot.total, 2L)
  assert_eq(snapshot.passed, 2L)
  assert_eq(snapshot.failed, 0L)
  assert_eq(snapshot.p50_latency_ms, 25.0)
  assert_eq(snapshot.p95_latency_ms, 38.5)
  assert_eq(snapshot.p99_latency_ms, 39.7)
  assert_eq(snapshot.events_per_window, 2.0)
  assert_eq(snapshot.status, Healthy)
}

///|
test "missing and repeated ids degrade the health snapshot" {
  let monitor = StreamHealthMonitor::new(1000L, min_events=1, max_events=10)
  monitor.observe(
    health_event("dup", 100L),
    false,
    missing=true,
    observed_at=100L,
  )
  monitor.observe(health_event("dup", 200L), true, observed_at=200L)
  let snapshot = monitor.snapshot()
  assert_eq(snapshot.failed, 1L)
  assert_eq(snapshot.missing, 1L)
  assert_eq(snapshot.duplicates, 1L)
  assert_eq(snapshot.status, Degraded)
}

///|
test "monitor reports bursting and normalizes unsafe limits" {
  let monitor = StreamHealthMonitor::new(1000L, min_events=-2, max_events=0)
  monitor.observe(health_event("a", 1L), true, observed_at=1L)
  monitor.observe(health_event("b", 2L), true, observed_at=2L)
  assert_eq(monitor.snapshot().status, Bursting)
}

///|
test "reset starts a clean window while retaining totals" {
  let monitor = StreamHealthMonitor::new(1000L)
  monitor.observe(health_event("a", 100L), false, observed_at=100L)
  monitor.reset_window(2000L)
  let snapshot = monitor.snapshot()
  assert_eq(snapshot.total, 1L)
  assert_eq(snapshot.events_per_window, 0.0)
  assert_eq(snapshot.p50_latency_ms, 0.0)
  assert_eq(snapshot.status, Starved)
}
