// MoonBit Stream Quality Engine - Health Report Tests
// Copyright 2026 zmjknn
// Apache-2.0 License

///|
test "health report renders operational percentiles and status" {
  let snapshot = @rules.HealthSnapshot::{
    total: 100L,
    passed: 96L,
    failed: 4L,
    missing: 2L,
    duplicates: 1L,
    p50_latency_ms: 4.0,
    p95_latency_ms: 12.5,
    p99_latency_ms: 20.0,
    events_per_window: 100.0,
    status: @rules.Degraded,
  }
  let markdown = format_health_markdown(snapshot)
  assert_eq(markdown.contains("p95 latency"), true)
  assert_eq(markdown.contains("DEGRADED"), true)
  let json = format_health_json(snapshot)
  assert_eq(json.contains("\"p99_latency_ms\":20"), true)
  assert_eq(json.contains("\"duplicates\":1"), true)
}
