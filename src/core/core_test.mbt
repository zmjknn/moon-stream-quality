// MoonBit Stream Quality Engine - Core Package Tests
// Copyright 2026 zmjknn
// Apache-2.0 License

test "value conversions" {
  let v_int = Value::Int(100L)
  assert_eq(v_int.as_double(), Some(100.0))
  assert_eq(v_int.as_string(), Some("100"))
  assert_eq(v_int.as_bool(), Some(true))

  let v_str = Value::String("45.5")
  assert_eq(v_str.as_double(), Some(45.5))
  assert_eq(v_str.is_number(), false)
  assert_eq(v_str.is_string(), true)
}

test "event payload operations" {
  let payload : Map[String, Value] = Map([])
  payload.set("user_id", Value::Int(1001L))
  payload.set("score", Value::Double(98.5))
  payload.set("email", Value::String("alice@example.com"))
  payload.set("invalid_field", Value::Null)

  let event = StreamEvent::new("evt-001", 1700000000000L, payload~)
  assert_eq(event.contains_key("user_id"), true)
  assert_eq(event.contains_key("invalid_field"), false)
  assert_eq(event.has_field("invalid_field"), true)
  assert_eq(event.get_int("user_id"), Some(1001L))
  assert_eq(event.get_double("score"), Some(98.5))
  assert_eq(event.get_string("email"), Some("alice@example.com"))
}

test "stream context watermark" {
  let ctx = StreamContext::new(batch_id="b-1")
  ctx.update_watermark(100L)
  assert_eq(ctx.watermark, 100L)
  ctx.update_watermark(50L)
  assert_eq(ctx.watermark, 100L)
  ctx.update_watermark(200L)
  assert_eq(ctx.watermark, 200L)
}
