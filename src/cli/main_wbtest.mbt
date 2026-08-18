// MoonBit Stream Quality Engine - CLI Summary Tests
// Copyright 2026 zmjknn
// Apache-2.0 License

///|
test "CLI summary reports realistic workload counters" {
  let spec = @benchmark.WorkloadSpec::new("cli-sensor", 2, 0, 0, 0)
  let summary = render_workload_summary(@benchmark.run_sensor_workload(spec))
  assert_eq(summary.contains("cli-sensor"), true)
  assert_eq(summary.contains("passed=2"), true)
}
