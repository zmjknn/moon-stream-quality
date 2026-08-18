// MoonBit Stream Quality Engine - Operational Health Report
// Copyright 2026 zmjknn
// Apache-2.0 License

///|
fn health_status_name(status : @rules.HealthStatus) -> String {
  match status {
    @rules.Healthy => "HEALTHY"
    @rules.Degraded => "DEGRADED"
    @rules.Starved => "STARVED"
    @rules.Bursting => "BURSTING"
  }
}

///|
/// Formats operational health metrics as a compact Markdown section.
pub fn format_health_markdown(snapshot : @rules.HealthSnapshot) -> String {
  "## Stream Health\n\n" +
  "- **Status**: `" +
  health_status_name(snapshot.status) +
  "`\n" +
  "- **Events in window**: `" +
  snapshot.events_per_window.to_string() +
  "`\n" +
  "- **Passed / Failed**: `" +
  snapshot.passed.to_string() +
  " / " +
  snapshot.failed.to_string() +
  "`\n" +
  "- **Missing / Duplicates**: `" +
  snapshot.missing.to_string() +
  " / " +
  snapshot.duplicates.to_string() +
  "`\n\n" +
  "| Latency percentile | Milliseconds |\n" +
  "|---|---:|\n" +
  "| p50 latency | " +
  snapshot.p50_latency_ms.to_string() +
  " |\n" +
  "| p95 latency | " +
  snapshot.p95_latency_ms.to_string() +
  " |\n" +
  "| p99 latency | " +
  snapshot.p99_latency_ms.to_string() +
  " |\n"
}

///|
/// Formats operational health metrics as a machine-readable JSON object.
pub fn format_health_json(snapshot : @rules.HealthSnapshot) -> String {
  "{\"status\":\"" +
  health_status_name(snapshot.status) +
  "\",\"total\":" +
  snapshot.total.to_string() +
  ",\"passed\":" +
  snapshot.passed.to_string() +
  ",\"failed\":" +
  snapshot.failed.to_string() +
  ",\"missing\":" +
  snapshot.missing.to_string() +
  ",\"duplicates\":" +
  snapshot.duplicates.to_string() +
  ",\"p50_latency_ms\":" +
  snapshot.p50_latency_ms.to_string() +
  ",\"p95_latency_ms\":" +
  snapshot.p95_latency_ms.to_string() +
  ",\"p99_latency_ms\":" +
  snapshot.p99_latency_ms.to_string() +
  ",\"events_per_window\":" +
  snapshot.events_per_window.to_string() +
  "}"
}
