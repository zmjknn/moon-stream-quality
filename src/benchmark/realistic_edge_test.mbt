// MoonBit Stream Quality Engine - Workload Boundary Coverage
// Copyright 2026 zmjknn
// Apache-2.0 License

///|
test "negative workload size becomes a deterministic empty baseline" {
  let result = run_sensor_workload(WorkloadSpec::new("empty", -10, 1, 1, 1))
  assert_eq(result.event_count, 0)
  assert_eq(result.passed, 0)
  assert_eq(result.failed, 0)
  assert_eq(result.quality_score, 100.0)
}

///|
test "zero cadence disables all synthetic defect schedules" {
  let spec = WorkloadSpec::new("clean", 5, 0, 0, 0)
  let sensor = run_sensor_workload(spec)
  let transaction = run_transaction_workload(spec)
  assert_eq(sensor.event_count, 5)
  assert_eq(sensor.failed, 0)
  assert_eq(sensor.duplicate, 0)
  assert_eq(transaction.failed, 0)
}

///|
test "single-event cadence applies only the documented invalid schedule" {
  let result = run_sensor_workload(WorkloadSpec::new("cadence", 4, 1, 0, 0))
  assert_eq(result.event_count, 4)
  assert_eq(result.failed, 4)
  assert_eq(result.passed, 0)
}

///|
test "access-log workload is stable for a small valid fixture" {
  let result = run_access_log_workload(WorkloadSpec::new("logs", 3, 0, 0, 0))
  assert_eq(result.event_count, 3)
  assert_eq(result.failed, 0)
  assert_eq(result.quality_score, 100.0)
}

///|
test "formatted workload output contains all acceptance counters" {
  let result = run_transaction_workload(WorkloadSpec::new("format", 2, 0, 0, 0))
  let output = format_workload_result(result)
  assert_eq(output.contains("passed"), true)
  assert_eq(output.contains("quality_score"), true)
  assert_eq(output.contains("duplicate"), true)
}
