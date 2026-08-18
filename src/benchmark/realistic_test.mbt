// MoonBit Stream Quality Engine - Realistic Workload Tests
// Copyright 2026 zmjknn
// Apache-2.0 License

///|
test "empty workload is a reproducible perfect baseline" {
  let spec = WorkloadSpec::new("sensor", 0, 5, 3, 4)
  let result = run_sensor_workload(spec)
  assert_eq(result.event_count, 0)
  assert_eq(result.passed, 0)
  assert_eq(result.failed, 0)
  assert_eq(result.quality_score, 100.0)
}

///|
test "sensor workload follows defect cadence" {
  let spec = WorkloadSpec::new("sensor", 10, 5, 3, 4)
  let result = run_sensor_workload(spec)
  assert_eq(result.event_count, 10)
  assert_eq(result.passed, 8)
  assert_eq(result.failed, 2)
  assert_eq(result.late, 2)
  assert_eq(result.duplicate, 3)
}

///|
test "transaction workload reports cross-field defects" {
  let spec = WorkloadSpec::new("orders", 10, 4, 0, 0)
  let result = run_transaction_workload(spec)
  assert_eq(result.event_count, 10)
  assert_eq(result.failed, 3)
  assert_eq(result.passed, 7)
  assert_eq(result.late, 0)
}

///|
test "access workload stays valid when no defects are scheduled" {
  let spec = WorkloadSpec::new("access", 1, 0, 0, 0)
  let result = run_access_log_workload(spec)
  assert_eq(result.event_count, 1)
  assert_eq(result.passed, 1)
  assert_eq(result.failed, 0)
  assert_eq(result.quality_score, 100.0)
}

///|
test "workload formatter exposes audit counters" {
  let spec = WorkloadSpec::new("sensor", 1, 0, 0, 0)
  let formatted = format_workload_result(run_sensor_workload(spec))
  assert_eq(formatted.contains("events=1"), true)
  assert_eq(formatted.contains("passed=1"), true)
  assert_eq(formatted.contains("quality_score="), true)
}
