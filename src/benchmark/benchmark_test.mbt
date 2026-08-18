// MoonBit Stream Quality Engine - Benchmark Package Tests
// Copyright 2026 zmjknn
// Apache-2.0 License

///|
test "financial workload benchmark" {
  let res = run_financial_benchmark(100)
  assert_eq(res.total_events, 100L)
  assert_eq(res.pass_rate, 1.0)
  assert_eq(res.quality_score, 100.0)
  assert_eq(res.rule_evaluations, 400L)
}

///|
test "syslog workload benchmark" {
  let res = run_syslog_benchmark(50)
  assert_eq(res.total_events, 50L)
  assert_eq(res.pass_rate, 1.0)
  assert_eq(res.rule_evaluations, 150L)
}

///|
test (b : @bench.T) {
  let json_lines = [
    "{\"device_id\":\"sensor-1\",\"temperature\":22.5}", "{\"device_id\":\"sensor-2\",\"temperature\":23.0}",
  ]
  b.bench(name="jsonl_reader", fn() {
    b.keep(@parser.parse_json_lines(json_lines).length())
  })
  b.bench(name="sensor_quality_pipeline", fn() {
    b.keep(
      run_sensor_workload(WorkloadSpec::new("bench-sensor", 120, 10, 7, 13)).failed,
    )
  })
  b.bench(name="transaction_quality_pipeline", fn() {
    b.keep(
      run_transaction_workload(WorkloadSpec::new("bench-orders", 120, 11, 0, 0)).failed,
    )
  })
}
