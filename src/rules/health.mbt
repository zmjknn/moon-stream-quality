// MoonBit Stream Quality Engine - Stream Health Monitor
// Copyright 2026 zmjknn
// Apache-2.0 License

///|
/// Operational status derived from the current event-time window.
pub(all) enum HealthStatus {
  Healthy
  Degraded
  Starved
  Bursting
} derive(Eq, Debug)

///|
/// Stable snapshot of stream quality and latency indicators.
pub(all) struct HealthSnapshot {
  total : Int64
  passed : Int64
  failed : Int64
  missing : Int64
  duplicates : Int64
  p50_latency_ms : Double
  p95_latency_ms : Double
  p99_latency_ms : Double
  events_per_window : Double
  status : HealthStatus
} derive(Eq, Debug)

///|
/// Bounded monitor for stream throughput, quality and latency.
pub(all) struct StreamHealthMonitor {
  window_ms : Int64
  min_events : Int
  max_events : Int
  mut total : Int64
  mut passed : Int64
  mut failed : Int64
  mut missing : Int64
  mut duplicates : Int64
  mut latencies : QuantileSketch
  mut window_events : Int
  mut window_start : Int64
  mut seen_ids : Map[String, Bool]
} derive(Debug)

///|
fn safe_health_window(value : Int64) -> Int64 {
  if value <= 0L {
    1L
  } else {
    value
  }
}

///|
fn safe_health_min(value : Int) -> Int {
  if value < 0 {
    0
  } else {
    value
  }
}

///|
fn safe_health_max(value : Int, minimum : Int) -> Int {
  let safe_value = if value <= 0 { 1 } else { value }
  if safe_value < minimum {
    minimum
  } else {
    safe_value
  }
}

///|
/// Creates a bounded health monitor.
pub fn StreamHealthMonitor::new(
  window_ms : Int64,
  min_events? : Int = 1,
  max_events? : Int = 100000,
  sketch_capacity? : Int = 256,
) -> StreamHealthMonitor {
  let minimum = safe_health_min(min_events)
  {
    window_ms: safe_health_window(window_ms),
    min_events: minimum,
    max_events: safe_health_max(max_events, minimum),
    total: 0L,
    passed: 0L,
    failed: 0L,
    missing: 0L,
    duplicates: 0L,
    latencies: QuantileSketch::new(capacity=sketch_capacity),
    window_events: 0,
    window_start: 0L,
    seen_ids: Map([]),
  }
}

///|
fn StreamHealthMonitor::status(self : StreamHealthMonitor) -> HealthStatus {
  if self.window_events < self.min_events {
    Starved
  } else if self.window_events > self.max_events {
    Bursting
  } else if self.failed > 0L || self.missing > 0L || self.duplicates > 0L {
    Degraded
  } else {
    Healthy
  }
}

///|
/// Records one event and its observed processing outcome.
pub fn StreamHealthMonitor::observe(
  self : StreamHealthMonitor,
  event : @core.StreamEvent,
  passed : Bool,
  observed_at~ : Int64,
  missing? : Bool = false,
  duplicate? : Bool = false,
) -> Unit {
  if self.window_start == 0L {
    self.window_start = observed_at
  } else if observed_at >= self.window_start + self.window_ms {
    let next_start = observed_at - observed_at % self.window_ms
    self.reset_window(next_start)
  }
  self.total = self.total + 1L
  if passed {
    self.passed = self.passed + 1L
  } else {
    self.failed = self.failed + 1L
  }
  if missing {
    self.missing = self.missing + 1L
  }
  let already_seen = match self.seen_ids.get(event.event_id) {
    Some(_) => true
    None => false
  }
  if duplicate || already_seen {
    self.duplicates = self.duplicates + 1L
  }
  self.seen_ids.set(event.event_id, true)
  let latency = if observed_at > event.timestamp {
    observed_at - event.timestamp
  } else {
    0L
  }
  self.latencies.add(latency.to_double())
  self.window_events = self.window_events + 1
}

///|
/// Returns an operational snapshot without exposing mutable monitor state.
pub fn StreamHealthMonitor::snapshot(
  self : StreamHealthMonitor,
) -> HealthSnapshot {
  let p50 = match self.latencies.quantile(50.0) {
    Some(value) => value
    None => 0.0
  }
  let p95 = match self.latencies.quantile(95.0) {
    Some(value) => value
    None => 0.0
  }
  let p99 = match self.latencies.quantile(99.0) {
    Some(value) => value
    None => 0.0
  }
  {
    total: self.total,
    passed: self.passed,
    failed: self.failed,
    missing: self.missing,
    duplicates: self.duplicates,
    p50_latency_ms: p50,
    p95_latency_ms: p95,
    p99_latency_ms: p99,
    events_per_window: self.window_events.to_double(),
    status: self.status(),
  }
}

///|
/// Starts a new window while retaining lifetime counters.
pub fn StreamHealthMonitor::reset_window(
  self : StreamHealthMonitor,
  window_start : Int64,
) -> Unit {
  self.window_start = window_start
  self.window_events = 0
  self.latencies = QuantileSketch::new(capacity=self.latencies.capacity)
  self.seen_ids = Map([])
}
