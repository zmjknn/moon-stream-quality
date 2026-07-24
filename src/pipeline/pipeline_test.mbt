// MoonBit Stream Quality Engine - Pipeline Package Tests
// Copyright 2026 zmjknn
// Apache-2.0 License

///|
test "dead letter queue push and json audit" {
  let dlq = DeadLetterQueueManager::new(capacity=5)

  let p : Map[String, @core.Value] = Map([])
  p.set("err", @core.Value::String("invalid_schema"))
  let e = @core.StreamEvent::new("evt-bad1", 1000L, payload=p)

  dlq.push_failed_event(e, "Required field missing")

  let retries = dlq.get_retryable_entries()
  assert_eq(retries.length(), 1)
  assert_eq(retries[0].entry_id, "dlq-evt-bad1")

  let json_str = dlq.to_json_audit()
  assert_eq(json_str.contains("Required field missing"), true)
}

///|
test "multi-stream join validation" {
  let validator = MultiStreamJoinValidator::new(
    "orders_stream",
    "payments_stream",
    "order_id",
    max_skew_ms=5000L,
  )

  let p_ord : Map[String, @core.Value] = Map([])
  p_ord.set("order_id", @core.Value::String("ord-100"))
  let e_ord = @core.StreamEvent::new("e1", 10000L, payload=p_ord)

  let p_pay : Map[String, @core.Value] = Map([])
  p_pay.set("order_id", @core.Value::String("ord-100"))
  let e_pay = @core.StreamEvent::new("e2", 20000L, payload=p_pay) // 10000ms skew > 5000ms limit

  validator.ingest_left(e_ord)
  validator.ingest_right(e_pay)

  let violations = validator.validate_join_integrity()
  assert_eq(violations.length(), 1)
  assert_eq(violations[0].join_key, "ord-100")
  assert_eq(violations[0].skew_ms, 10000L)
}
