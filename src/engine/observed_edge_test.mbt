// MoonBit Stream Quality Engine - Observed Pipeline Boundary Coverage
// Copyright 2026 zmjknn
// Apache-2.0 License

///|
fn observed_engine_event(
  id : String,
  timestamp : Int64,
  ingest : Int64,
) -> @core.StreamEvent {
  let meta = @core.EventMeta::new(source_id="observed", ingest_timestamp=ingest)
  let payload : Map[String, @core.Value] = Map([])
  payload.set("id", @core.Value::String(id))
  @core.StreamEvent::new(id, timestamp, payload~, meta~)
}

///|
test "observer uses ingest timestamp when it is available" {
  let pipeline = StreamPipeline::new("ingest-clock")
  pipeline
  .get_registry()
  .register_completeness(@rules.CompletenessRule::new("id", "id"))
  let monitor = @rules.StreamHealthMonitor::new(1000L, min_events=0)
  let runtime = @core.WindowRuntime::new(1000L)
  let _ = pipeline.process_event_with_observer(
    observed_engine_event("one", 10L, 100L),
    monitor,
    runtime,
  )
  assert_eq(monitor.snapshot().p50_latency_ms, 90.0)
}

///|
test "observer records failed rule evaluation without hiding assignment" {
  let pipeline = StreamPipeline::new("failure")
  pipeline
  .get_registry()
  .register_completeness(@rules.CompletenessRule::new("required", "required"))
  let monitor = @rules.StreamHealthMonitor::new(1000L, min_events=0)
  let runtime = @core.WindowRuntime::new(1000L)
  let result = pipeline.process_event_with_observer(
    @core.StreamEvent::new("missing", 5L),
    monitor,
    runtime,
  )
  assert_eq(result.evaluation.passed, false)
  assert_eq(result.assignment, @core.OnTime)
  assert_eq(monitor.snapshot().failed, 1L)
}

///|
test "observer exposes late assignment while still evaluating the event" {
  let pipeline = StreamPipeline::new("late")
  let monitor = @rules.StreamHealthMonitor::new(1000L, min_events=0)
  let runtime = @core.WindowRuntime::new(1000L, allowed_lateness_ms=20L)
  let _ = pipeline.process_event_with_observer(
    @core.StreamEvent::new("new", 100L),
    monitor,
    runtime,
  )
  let result = pipeline.process_event_with_observer(
    @core.StreamEvent::new("late", 79L),
    monitor,
    runtime,
  )
  assert_eq(result.assignment, @core.Late)
  assert_eq(monitor.snapshot().total, 2L)
}

///|
test "observer handles an empty rule registry as a successful baseline" {
  let pipeline = StreamPipeline::new("baseline")
  let monitor = @rules.StreamHealthMonitor::new(1000L, min_events=0)
  let runtime = @core.WindowRuntime::new(1000L)
  let result = pipeline.process_event_with_observer(
    @core.StreamEvent::new("baseline", 1L),
    monitor,
    runtime,
  )
  assert_eq(result.evaluation.passed, true)
  assert_eq(result.evaluation.rule_failures.length(), 0)
}
