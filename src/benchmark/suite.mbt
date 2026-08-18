// MoonBit Stream Quality Engine - Benchmark Workload Suite Module
// Copyright 2026 zmjknn
// Apache-2.0 License

///|
/// Benchmark Execution Result Summary.
pub(all) struct BenchmarkSuiteResult {
  workload_name : String
  total_events : Int64
  rule_evaluations : Int64
  pass_rate : Double
  quality_score : Double
} derive(Eq, Debug)

///|
fn safe_benchmark_count(value : Int) -> Int {
  if value < 0 {
    0
  } else {
    value
  }
}

///|
/// Runs a synthetic financial transaction stream quality benchmark.
pub fn run_financial_benchmark(event_count : Int) -> BenchmarkSuiteResult {
  let safe_count = safe_benchmark_count(event_count)
  let pipeline = @engine.StreamPipeline::new("financial_transaction_pipeline")
  let reg = pipeline.get_registry()

  reg.register_completeness(@rules.CompletenessRule::new("c1", "account_id"))
  reg.register_range(
    @rules.RangeRule::new(
      "r1",
      "amount",
      min_val=Some(0.01),
      max_val=Some(100000.0),
    ),
  )
  reg.register_uniqueness(@rules.UniquenessRule::new("u1", ["transaction_id"]))
  reg.register_regex(
    @rules.RegexRule::new("re1", "currency", CustomPattern("prefix:USD")),
  )

  let events : Array[@core.StreamEvent] = []
  let base_ts = 1700000000000L

  for i = 0; i < safe_count; i = i + 1 {
    let payload : Map[String, @core.Value] = Map([])
    payload.set("transaction_id", @core.Value::String("tx-" + i.to_string()))
    payload.set(
      "account_id",
      @core.Value::String("acc-" + (i % 50).to_string()),
    )
    payload.set("amount", @core.Value::Double(10.0 + (i % 100).to_double()))
    payload.set("currency", @core.Value::String("USD"))

    events.push(
      @core.StreamEvent::new(
        "tx-evt-" + i.to_string(),
        base_ts + i.to_int64() * 100L,
        payload~,
      ),
    )
  }

  let summary = pipeline.process_batch(events)
  let metrics = @report.compute_metrics_from_summary(summary)
  let score = @report.calculate_quality_score(metrics)

  {
    workload_name: "Financial Transaction Workload",
    total_events: safe_count.to_int64(),
    rule_evaluations: safe_count.to_int64() * 4L,
    pass_rate: summary.pass_rate,
    quality_score: score,
  }
}

///|
/// Runs a synthetic Syslog access log stream quality benchmark.
pub fn run_syslog_benchmark(log_line_count : Int) -> BenchmarkSuiteResult {
  let safe_count = safe_benchmark_count(log_line_count)
  let pipeline = @engine.StreamPipeline::new("syslog_access_pipeline")
  let reg = pipeline.get_registry()

  reg.register_completeness(@rules.CompletenessRule::new("c1", "service"))
  reg.register_range(
    @rules.RangeRule::new(
      "r1",
      "status",
      min_val=Some(100.0),
      max_val=Some(599.0),
    ),
  )
  reg.register_regex(
    @rules.RegexRule::new("re1", "user", CustomPattern("prefix:user_")),
  )

  let events : Array[@core.StreamEvent] = []

  for i = 0; i < safe_count; i = i + 1 {
    let line = "level=info service=auth_service status=200 user=\"user_" +
      (i % 10).to_string() +
      "\""
    let evt = @parser.parse_logfmt_event("syslog-" + i.to_string(), line)
    events.push(evt)
  }

  let summary = pipeline.process_batch(events)
  let metrics = @report.compute_metrics_from_summary(summary)
  let score = @report.calculate_quality_score(metrics)

  {
    workload_name: "Syslog Audit Workload",
    total_events: safe_count.to_int64(),
    rule_evaluations: safe_count.to_int64() * 3L,
    pass_rate: summary.pass_rate,
    quality_score: score,
  }
}
