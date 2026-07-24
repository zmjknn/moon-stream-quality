// MoonBit Stream Quality Engine - Sink Package Tests
// Copyright 2026 zmjknn
// Apache-2.0 License

///|
test "alert trigger thresholds" {
  let cfg = AlertConfig::default()

  // 95.0 -> No alert
  let a1 = cfg.check_alert("pipe1", 95.0, 1000L)
  let ok1 = match a1 {
    Some(_) => false
    None => true
  }
  assert_eq(ok1, true)

  // 75.0 -> Warning alert
  let a2 = cfg.check_alert("pipe1", 75.0, 1001L)
  let ok2 = match a2 {
    Some(payload) => payload.level == AlertWarning
    None => false
  }
  assert_eq(ok2, true)

  // 50.0 -> Critical alert
  let a3 = cfg.check_alert("pipe1", 50.0, 1002L)
  let ok3 = match a3 {
    Some(payload) => payload.level == AlertCritical
    None => false
  }
  assert_eq(ok3, true)
}

///|
test "prometheus metric exporter format" {
  let summary : @engine.PipelineBatchSummary = {
    batch_id: "b-0",
    total_events: 100L,
    passed_events: 95L,
    failed_events: 5L,
    total_rule_evaluations: 200L,
    total_rule_failures: 5L,
    pass_rate: 0.95,
  }

  let metrics = @report.DimensionalMetrics::new()
  let prom = export_prometheus_metrics("test_pipe", summary, metrics, 95.0)

  assert_eq(
    prom.contains("stream_quality_score{pipeline=\"test_pipe\"} 95"),
    true,
  )
  assert_eq(
    prom.contains("stream_events_processed_total{pipeline=\"test_pipe\"} 100"),
    true,
  )
}
