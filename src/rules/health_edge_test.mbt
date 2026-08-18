// MoonBit Stream Quality Engine - Health Boundary Coverage
// Copyright 2026 zmjknn
// Apache-2.0 License

///|
test "negative and zero monitor configuration is bounded" {
  let monitor = StreamHealthMonitor::new(
    0L,
    min_events=-10,
    max_events=-3,
    sketch_capacity=0,
  )
  monitor.observe(@core.StreamEvent::new("safe", 0L), true, observed_at=0L)
  let snapshot = monitor.snapshot()
  assert_eq(snapshot.total, 1L)
  assert_eq(snapshot.status, Healthy)
}

///|
test "window rollover clears duplicate identity and latency samples" {
  let monitor = StreamHealthMonitor::new(100L, min_events=1, max_events=4)
  monitor.observe(@core.StreamEvent::new("same", 100L), true, observed_at=150L)
  monitor.observe(@core.StreamEvent::new("same", 200L), true, observed_at=250L)
  let snapshot = monitor.snapshot()
  assert_eq(snapshot.total, 2L)
  assert_eq(snapshot.duplicates, 0L)
  assert_eq(snapshot.events_per_window, 1.0)
  assert_eq(snapshot.p50_latency_ms, 50.0)
}

///|
test "explicit duplicate is counted even for a new event id" {
  let monitor = StreamHealthMonitor::new(1000L, min_events=0)
  monitor.observe(
    @core.StreamEvent::new("new", 1L),
    true,
    observed_at=1L,
    duplicate=true,
  )
  assert_eq(monitor.snapshot().duplicates, 1L)
  assert_eq(monitor.snapshot().status, Degraded)
}

///|
test "failed events degrade a monitor with otherwise sufficient volume" {
  let monitor = StreamHealthMonitor::new(1000L, min_events=2, max_events=2)
  monitor.observe(@core.StreamEvent::new("a", 10L), false, observed_at=20L)
  monitor.observe(@core.StreamEvent::new("b", 10L), true, observed_at=20L)
  let snapshot = monitor.snapshot()
  assert_eq(snapshot.events_per_window, 2.0)
  assert_eq(snapshot.failed, 1L)
  assert_eq(snapshot.status, Degraded)
}

///|
test "quantile sketch keeps the newest bounded sample" {
  let sketch = QuantileSketch::new(capacity=3)
  for value in [10.0, 20.0, 30.0, 40.0, 50.0] {
    sketch.add(value)
  }
  assert_eq(sketch.quantile(50.0), Some(40.0))
  assert_eq(sketch.quantile(100.0), Some(50.0))
}

///|
test "resetting before first observation keeps an empty snapshot safe" {
  let monitor = StreamHealthMonitor::new(100L, min_events=0)
  monitor.reset_window(500L)
  let snapshot = monitor.snapshot()
  assert_eq(snapshot.total, 0L)
  assert_eq(snapshot.events_per_window, 0.0)
  assert_eq(snapshot.status, Healthy)
}
