// MoonBit Stream Quality Engine - Benchmark Stream Generator Module
// Copyright 2026 zmjknn
// Apache-2.0 License

/// Generates a synthetic stream of IoT sensor events with intentional quality flaws for benchmark evaluation.
pub fn generate_benchmark_sensor_stream(
  count : Int,
  base_timestamp~ : Int64 = 1700000000000L
) -> Array[@core.StreamEvent] {
  let events : Array[@core.StreamEvent] = []

  for i = 0; i < count; i = i + 1 {
    let payload : Map[String, @core.Value] = Map([])

    // Every 20th event is missing device_id (completeness flaw)
    if i % 20 != 0 {
      payload.set("device_id", @core.Value::String("sensor-" + (i % 5).to_string()))
    }

    // Every 15th event has an extreme temperature outlier (range flaw)
    let temp = if i % 15 == 0 { 250.0 } else { 20.0 + (i % 10).to_double() * 0.5 }
    payload.set("temperature", @core.Value::Double(temp))

    // Humidity field
    payload.set("humidity", @core.Value::Double(55.0 + (i % 5).to_double()))

    // Email alert field (every 25th has invalid format)
    let email = if i % 25 == 0 { "invalid_email_format" } else { "operator_" + (i % 3).to_string() + "@factory.com" }
    payload.set("operator_email", @core.Value::String(email))

    // Timestamp with out-of-order latency for every 30th event (chronology flaw)
    let ts_offset = if i % 30 == 0 { -10000L } else { i.to_int64() * 1000L }
    let ts = base_timestamp + ts_offset

    events.push(@core.StreamEvent::new("evt-" + i.to_string(), ts, event_type="sensor_telemetry", payload~))
  }

  events
}

/// Generates a synthetic stream of E-Commerce Transaction events with cross-field and uniqueness constraints.
pub fn generate_benchmark_order_stream(
  count : Int,
  base_timestamp~ : Int64 = 1700000000000L
) -> Array[@core.StreamEvent] {
  let events : Array[@core.StreamEvent] = []

  for i = 0; i < count; i = i + 1 {
    let payload : Map[String, @core.Value] = Map([])

    // Order ID (every 12th event duplicates previous order_id -> uniqueness flaw)
    let order_id = if i % 12 == 0 && i > 0 { "ord-" + (i - 1).to_string() } else { "ord-" + i.to_string() }
    payload.set("order_id", @core.Value::String(order_id))

    // Timestamps for cross-field check (end_time >= start_time)
    let start_t = base_timestamp + i.to_int64() * 500L
    // Every 18th event has end_time < start_time (cross-field constraint flaw)
    let end_t = if i % 18 == 0 { start_t - 500L } else { start_t + 1200L }
    payload.set("start_time", @core.Value::Int(start_t))
    payload.set("end_time", @core.Value::Int(end_t))

    // Payment status & Amount
    payload.set("amount", @core.Value::Double(99.99 + i.to_double()))
    payload.set("currency", @core.Value::String("USD"))

    events.push(@core.StreamEvent::new("order-evt-" + i.to_string(), start_t, event_type="order_created", payload~))
  }

  events
}
