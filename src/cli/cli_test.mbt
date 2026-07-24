// MoonBit Stream Quality Engine - CLI Package Tests
// Copyright 2026 zmjknn
// Apache-2.0 License

test "benchmark generator counts" {
  let sensor_events = generate_benchmark_sensor_stream(50)
  assert_eq(sensor_events.length(), 50)

  let order_events = generate_benchmark_order_stream(30)
  assert_eq(order_events.length(), 30)
}
