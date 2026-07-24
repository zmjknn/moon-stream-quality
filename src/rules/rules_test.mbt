// MoonBit Stream Quality Engine - Rules Package Comprehensive Tests
// Copyright 2026 zmjknn
// Apache-2.0 License

test "completeness rule evaluation" {
  let rule = CompletenessRule::new("r1", "email", allow_empty_string=false)

  let p1 : Map[String, @core.Value] = Map([])
  p1.set("email", @core.Value::String("test@example.com"))
  let e1 = @core.StreamEvent::new("e1", 100L, payload=p1)
  let res1 = rule.evaluate(e1)
  assert_eq(res1.passed, true)

  let p2 : Map[String, @core.Value] = Map([])
  p2.set("email", @core.Value::String(""))
  let e2 = @core.StreamEvent::new("e2", 101L, payload=p2)
  let res2 = rule.evaluate(e2)
  assert_eq(res2.passed, false)
}

test "uniqueness rule with sliding bloom filter" {
  let rule = UniquenessRule::new("u1", ["user_id", "device_id"], capacity=100)

  let p1 : Map[String, @core.Value] = Map([])
  p1.set("user_id", @core.Value::Int(101L))
  p1.set("device_id", @core.Value::String("d1"))
  let e1 = @core.StreamEvent::new("e1", 100L, payload=p1)

  let r1 = rule.evaluate(e1)
  assert_eq(r1.passed, true)

  // Duplicate event
  let r2 = rule.evaluate(e1)
  assert_eq(r2.passed, false)
}

test "range rule bounds" {
  let rule = RangeRule::new("rng1", "temperature", min_val=Some(-10.0), max_val=Some(50.0))

  let p1 : Map[String, @core.Value] = Map([])
  p1.set("temperature", @core.Value::Double(25.0))
  let e1 = @core.StreamEvent::new("e1", 100L, payload=p1)
  assert_eq(rule.evaluate(e1).passed, true)

  let p2 : Map[String, @core.Value] = Map([])
  p2.set("temperature", @core.Value::Double(99.0))
  let e2 = @core.StreamEvent::new("e2", 101L, payload=p2)
  assert_eq(rule.evaluate(e2).passed, false)
}

test "regex format validation" {
  let email_rule = RegexRule::new("re1", "user_email", EmailFormat)
  let uuid_rule = RegexRule::new("re2", "request_id", UUIDFormat)

  let p : Map[String, @core.Value] = Map([])
  p.set("user_email", @core.Value::String("admin@company.org"))
  p.set("request_id", @core.Value::String("550e8400-e29b-41d4-a716-446655440000"))
  let e = @core.StreamEvent::new("e1", 100L, payload=p)

  assert_eq(email_rule.evaluate(e).passed, true)
  assert_eq(uuid_rule.evaluate(e).passed, true)
}

test "chronology monotonicity check" {
  let rule = ChronologyRule::new("c1", max_lateness_ms=1000L)

  let e1 = @core.StreamEvent::new("e1", 5000L)
  let e2 = @core.StreamEvent::new("e2", 4500L) // 500ms lag - allowed
  let e3 = @core.StreamEvent::new("e3", 3000L) // 2000ms lag - fails

  assert_eq(rule.evaluate(e1).passed, true)
  assert_eq(rule.evaluate(e2).passed, true)
  assert_eq(rule.evaluate(e3).passed, false)
}

test "cross field comparison" {
  let rule = CrossFieldRule::new("cf1", "end_time", Gte, "start_time")

  let p : Map[String, @core.Value] = Map([])
  p.set("start_time", @core.Value::Int(1000L))
  p.set("end_time", @core.Value::Int(1500L))
  let e = @core.StreamEvent::new("e1", 100L, payload=p)

  assert_eq(rule.evaluate(e).passed, true)
}

test "window aggregation check" {
  let rule = WindowAggregationRule::new(
    "w1",
    "cpu_usage",
    Mean,
    window_kind=CountWindow(5),
    max_threshold=Some(80.0)
  )

  for i = 0; i < 4; i = i + 1 {
    let p : Map[String, @core.Value] = Map([])
    p.set("cpu_usage", @core.Value::Double(50.0))
    let _ = rule.evaluate(@core.StreamEvent::new("e", 100L + i.to_int64(), payload=p))
  }

  // Add spike
  let p_spike : Map[String, @core.Value] = Map([])
  p_spike.set("cpu_usage", @core.Value::Double(200.0))
  let res = rule.evaluate(@core.StreamEvent::new("e_spike", 200L, payload=p_spike))
  // Average becomes (50*4 + 200)/5 = 80.0, max threshold is 80.0
  assert_eq(res.passed, true)
}
