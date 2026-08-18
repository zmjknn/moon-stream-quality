// MoonBit Stream Quality Engine - Report Boundary Coverage
// Copyright 2026 zmjknn
// Apache-2.0 License

///|
fn report_snapshot(status : @rules.HealthStatus) -> @rules.HealthSnapshot {
  {
    total: 5L,
    passed: 3L,
    failed: 2L,
    missing: 1L,
    duplicates: 2L,
    p50_latency_ms: 10.0,
    p95_latency_ms: 30.0,
    p99_latency_ms: 40.0,
    events_per_window: 5.0,
    status,
  }
}

///|
test "markdown report names every operational status" {
  for
    status in [@rules.Healthy, @rules.Degraded, @rules.Starved, @rules.Bursting] {
    let report = format_health_markdown(report_snapshot(status))
    assert_eq(report.contains("Stream Health"), true)
    assert_eq(report.contains("p99 latency"), true)
  }
}

///|
test "JSON report is compact and exposes machine-readable counters" {
  let json = format_health_json(report_snapshot(@rules.Degraded))
  assert_eq(json.has_prefix("{\"status\":\"DEGRADED\""), true)
  assert_eq(json.contains("\"total\":5"), true)
  assert_eq(json.contains("\"duplicates\":2"), true)
}

///|
test "JSON report includes zero-safe latency values" {
  let snapshot : @rules.HealthSnapshot = {
    total: 0L,
    passed: 0L,
    failed: 0L,
    missing: 0L,
    duplicates: 0L,
    p50_latency_ms: 0.0,
    p95_latency_ms: 0.0,
    p99_latency_ms: 0.0,
    events_per_window: 0.0,
    status: @rules.Starved,
  }
  let json = format_health_json(snapshot)
  assert_eq(json.contains("\"p50_latency_ms\":0"), true)
}
