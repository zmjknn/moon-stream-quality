// MoonBit Stream Quality Engine - Realistic Streaming Workloads
// Copyright 2026 zmjknn
// Apache-2.0 License

///|
/// Defect cadence and workload size used by reproducible benchmark fixtures.
pub(all) struct WorkloadSpec {
  name : String
  event_count : Int
  invalid_every : Int
  duplicate_every : Int
  late_every : Int
} derive(Eq, Debug)

///|
/// Creates a workload specification. Non-positive event counts become empty.
pub fn WorkloadSpec::new(
  name : String,
  event_count : Int,
  invalid_every : Int,
  duplicate_every : Int,
  late_every : Int,
) -> WorkloadSpec {
  {
    name,
    event_count: if event_count < 0 {
      0
    } else {
      event_count
    },
    invalid_every,
    duplicate_every,
    late_every,
  }
}

///|
/// Result counters shared by sensor, transaction and access-log workloads.
pub(all) struct WorkloadResult {
  name : String
  event_count : Int
  passed : Int
  failed : Int
  late : Int
  duplicate : Int
  quality_score : Double
} derive(Eq, Debug)

///|
fn scheduled(index : Int, every : Int) -> Bool {
  every > 0 && index > 0 && index % every == 0
}

///|
fn scheduled_including_first(index : Int, every : Int) -> Bool {
  every > 0 && index % every == 0
}

///|
fn stream_event_id(
  prefix : String,
  index : Int,
  duplicate_every : Int,
) -> String {
  if scheduled(index, duplicate_every) {
    prefix + "-" + (index - 1).to_string()
  } else {
    prefix + "-" + index.to_string()
  }
}

///|
fn evaluate_workload(
  name : String,
  events : Array[@core.StreamEvent],
  pipeline : @engine.StreamPipeline,
) -> WorkloadResult {
  let runtime = @core.WindowRuntime::new(
    60000L,
    allowed_lateness_ms=1000L,
    max_windows=64,
    policy=@core.SideOutput,
  )
  let monitor = @rules.StreamHealthMonitor::new(
    60000L,
    min_events=0,
    max_events=100000,
  )
  let mut passed = 0
  let mut failed = 0
  let mut late = 0
  for event in events {
    let observed = pipeline.process_event_with_observer(event, monitor, runtime)
    match observed.assignment {
      @core.OnTime => ()
      _ => late = late + 1
    }
    let result = observed.evaluation
    if result.passed {
      passed = passed + 1
    } else {
      failed = failed + 1
    }
  }
  let snapshot = monitor.snapshot()
  let total = events.length().to_int64()
  let pass_rate = if total == 0L {
    1.0
  } else {
    passed.to_double() / total.to_double()
  }
  let summary : @engine.PipelineBatchSummary = {
    batch_id: name,
    total_events: total,
    passed_events: passed.to_int64(),
    failed_events: failed.to_int64(),
    total_rule_evaluations: 0L,
    total_rule_failures: failed.to_int64(),
    pass_rate,
  }
  let metrics = @report.compute_metrics_from_summary(summary)
  let score = @report.calculate_quality_score(
    @report.DimensionalMetrics::new(
      completeness_score=metrics.completeness_score,
      uniqueness_score=100.0 -
        snapshot.duplicates.to_double() /
        (if total == 0L { 1.0 } else { total.to_double() }) *
        100.0,
      validity_score=metrics.validity_score,
      timeliness_score=100.0 -
        late.to_double() /
        (if total == 0L { 1.0 } else { total.to_double() }) *
        100.0,
    ),
  )
  {
    name,
    event_count: events.length(),
    passed,
    failed,
    late,
    duplicate: snapshot.duplicates.to_int(),
    quality_score: score,
  }
}

///|
fn make_sensor_event(spec : WorkloadSpec, index : Int) -> @core.StreamEvent {
  let invalid = scheduled_including_first(index, spec.invalid_every)
  let timestamp = if scheduled(index, spec.late_every) {
    1700000000000L + index.to_int64() * 1000L - 10000L
  } else {
    1700000000000L + index.to_int64() * 1000L
  }
  let payload : Map[String, @core.Value] = Map([])
  if !invalid {
    payload.set(
      "device_id",
      @core.Value::String("sensor-" + (index % 100).to_string()),
    )
  }
  payload.set(
    "temperature",
    @core.Value::Double(
      if invalid {
        250.0
      } else {
        20.0 + (index % 10).to_double()
      },
    ),
  )
  payload.set(
    "operator_email",
    @core.Value::String(
      if invalid {
        "invalid-email"
      } else {
        "operator_" + (index % 5).to_string() + "@factory.com"
      },
    ),
  )
  @core.StreamEvent::new(
    stream_event_id("sensor", index, spec.duplicate_every),
    timestamp,
    event_type="sensor_telemetry",
    payload~,
  )
}

///|
/// Runs the sensor telemetry workload through rules, windows and health metrics.
pub fn run_sensor_workload(spec : WorkloadSpec) -> WorkloadResult {
  let pipeline = @engine.StreamPipeline::new("sensor_workload")
  let registry = pipeline.get_registry()
  registry.register_completeness(
    @rules.CompletenessRule::new("sensor-complete", "device_id"),
  )
  registry.register_range(
    @rules.RangeRule::new(
      "sensor-temperature",
      "temperature",
      min_val=Some(-40.0),
      max_val=Some(125.0),
    ),
  )
  registry.register_regex(
    @rules.RegexRule::new("sensor-email", "operator_email", @rules.EmailFormat),
  )
  let events : Array[@core.StreamEvent] = []
  for index = 0; index < spec.event_count; index = index + 1 {
    events.push(make_sensor_event(spec, index))
  }
  evaluate_workload(spec.name, events, pipeline)
}

///|
fn make_transaction_event(
  spec : WorkloadSpec,
  index : Int,
) -> @core.StreamEvent {
  let invalid = scheduled_including_first(index, spec.invalid_every)
  let timestamp = 1700000000000L + index.to_int64() * 1000L
  let payload : Map[String, @core.Value] = Map([])
  let start_time = timestamp
  let end_time = if invalid { timestamp - 1L } else { timestamp + 500L }
  payload.set("order_id", @core.Value::String("order-" + index.to_string()))
  payload.set("amount", @core.Value::Double(if invalid { -1.0 } else { 99.0 }))
  payload.set("start_time", @core.Value::Int(start_time))
  payload.set("end_time", @core.Value::Int(end_time))
  payload.set("currency", @core.Value::String("USD"))
  @core.StreamEvent::new(
    stream_event_id("order", index, spec.duplicate_every),
    timestamp,
    event_type="order_created",
    payload~,
  )
}

///|
/// Runs a transaction workload with amount and temporal relational checks.
pub fn run_transaction_workload(spec : WorkloadSpec) -> WorkloadResult {
  let pipeline = @engine.StreamPipeline::new("transaction_workload")
  let registry = pipeline.get_registry()
  registry.register_completeness(
    @rules.CompletenessRule::new("order-complete", "order_id"),
  )
  registry.register_range(
    @rules.RangeRule::new(
      "order-amount",
      "amount",
      min_val=Some(0.0),
      max_val=Some(100000.0),
    ),
  )
  registry.register_cross_field(
    @rules.CrossFieldRule::new(
      "order-time",
      "end_time",
      @rules.Gte,
      "start_time",
    ),
  )
  let events : Array[@core.StreamEvent] = []
  for index = 0; index < spec.event_count; index = index + 1 {
    events.push(make_transaction_event(spec, index))
  }
  evaluate_workload(spec.name, events, pipeline)
}

///|
fn make_access_event(spec : WorkloadSpec, index : Int) -> @core.StreamEvent {
  let invalid = scheduled_including_first(index, spec.invalid_every)
  let status = if invalid { 700 } else { 200 }
  let line = "level=info service=api status=" +
    status.to_string() +
    " user=\"user_" +
    (index % 20).to_string() +
    "\""
  @parser.parse_logfmt_event(
    stream_event_id("access", index, spec.duplicate_every),
    line,
    timestamp=1700000000000L + index.to_int64() * 1000L,
  )
}

///|
/// Runs a parsed access-log workload with HTTP status validation.
pub fn run_access_log_workload(spec : WorkloadSpec) -> WorkloadResult {
  let pipeline = @engine.StreamPipeline::new("access_log_workload")
  let registry = pipeline.get_registry()
  registry.register_completeness(
    @rules.CompletenessRule::new("access-service", "service"),
  )
  registry.register_range(
    @rules.RangeRule::new(
      "access-status",
      "status",
      min_val=Some(100.0),
      max_val=Some(599.0),
    ),
  )
  registry.register_regex(
    @rules.RegexRule::new(
      "access-user",
      "user",
      @rules.CustomPattern("prefix:user_"),
    ),
  )
  let events : Array[@core.StreamEvent] = []
  for index = 0; index < spec.event_count; index = index + 1 {
    events.push(make_access_event(spec, index))
  }
  evaluate_workload(spec.name, events, pipeline)
}

///|
/// Formats workload counters for CLI output and benchmark logs.
pub fn format_workload_result(result : WorkloadResult) -> String {
  result.name +
  " events=" +
  result.event_count.to_string() +
  " passed=" +
  result.passed.to_string() +
  " failed=" +
  result.failed.to_string() +
  " late=" +
  result.late.to_string() +
  " duplicate=" +
  result.duplicate.to_string() +
  " quality_score=" +
  result.quality_score.to_string()
}
