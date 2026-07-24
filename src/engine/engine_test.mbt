// MoonBit Stream Quality Engine - Engine Package Tests
// Copyright 2026 zmjknn
// Apache-2.0 License

test "rule registry registration and count" {
  let reg = RuleRegistry::new()
  reg.register_completeness(@rules.CompletenessRule::new("c1", "user_id"))
  reg.register_range(@rules.RangeRule::new("r1", "age", min_val=Some(0.0), max_val=Some(120.0)))
  reg.register_regex(@rules.RegexRule::new("re1", "email", EmailFormat))

  assert_eq(reg.count(), 3)
  let found = match reg.get_rule("c1") {
    Some(_) => true
    None => false
  }
  assert_eq(found, true)
}

test "stream pipeline batch processing" {
  let pipeline = StreamPipeline::new("test_pipeline")
  let reg = pipeline.get_registry()

  reg.register_completeness(@rules.CompletenessRule::new("c1", "device_id"))
  reg.register_range(@rules.RangeRule::new("r1", "temp", min_val=Some(-50.0), max_val=Some(100.0)))

  let p1 : Map[String, @core.Value] = Map([])
  p1.set("device_id", @core.Value::String("d1"))
  p1.set("temp", @core.Value::Double(25.0))
  let e1 = @core.StreamEvent::new("e1", 1000L, payload=p1)

  let p2 : Map[String, @core.Value] = Map([])
  p2.set("device_id", @core.Value::String("d2"))
  p2.set("temp", @core.Value::Double(999.0)) // fails range check
  let e2 = @core.StreamEvent::new("e2", 1001L, payload=p2)

  let batch_summary = pipeline.process_batch([e1, e2])
  assert_eq(batch_summary.total_events, 2L)
  assert_eq(batch_summary.passed_events, 1L)
  assert_eq(batch_summary.failed_events, 1L)
  assert_eq(batch_summary.pass_rate, 0.5)
}
