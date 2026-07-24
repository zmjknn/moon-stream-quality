// MoonBit Stream Quality Engine - Benchmark Package Tests
// Copyright 2026 zmjknn
// Apache-2.0 License

///|
test "financial workload benchmark" {
  let res = run_financial_benchmark(100)
  assert_eq(res.total_events, 100L)
  assert_eq(res.pass_rate, 1.0)
  assert_eq(res.quality_score, 100.0)
}

///|
test "syslog workload benchmark" {
  let res = run_syslog_benchmark(50)
  assert_eq(res.total_events, 50L)
  assert_eq(res.pass_rate, 1.0)
}
