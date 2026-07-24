// MoonBit Stream Quality Engine - Pipeline Evaluator Module
// Copyright 2026 zmjknn
// Apache-2.0 License

///|
/// Evaluation result for a single event flowing through the quality pipeline.
pub(all) struct PipelineEventResult {
  event_id : String
  passed : Bool
  schema_errors : Array[@schema.SchemaValidationError]
  rule_failures : Array[@rules.RuleResult]
  passed_rules_count : Int
  failed_rules_count : Int
} derive(Eq, Debug)

///|
/// Stream Pipeline batch evaluation summary.
pub(all) struct PipelineBatchSummary {
  batch_id : String
  total_events : Int64
  passed_events : Int64
  failed_events : Int64
  total_rule_evaluations : Int64
  total_rule_failures : Int64
  pass_rate : Double
} derive(Eq, Debug)

///|
/// Stream Quality Pipeline orchestrating schema enforcement & rule execution.
pub(all) struct StreamPipeline {
  pipeline_name : String
  mut schema : @schema.Schema?
  registry : RuleRegistry
  context : @core.StreamContext
  sample_limit : Int
  failed_samples : Array[@core.StreamEvent]
} derive(Eq, Debug)

///|
/// Creates a new StreamPipeline.
pub fn StreamPipeline::new(
  pipeline_name : String,
  schema? : @schema.Schema? = None,
  sample_limit? : Int = 100,
) -> StreamPipeline {
  {
    pipeline_name,
    schema,
    registry: RuleRegistry::new(),
    context: @core.StreamContext::new(batch_id=pipeline_name + "-b0"),
    sample_limit,
    failed_samples: [],
  }
}

///|
/// Sets the schema for the pipeline.
pub fn StreamPipeline::set_schema(
  self : StreamPipeline,
  schema : @schema.Schema,
) -> Unit {
  self.schema = Some(schema)
}

///|
/// Returns the internal rule registry.
pub fn StreamPipeline::get_registry(self : StreamPipeline) -> RuleRegistry {
  self.registry
}

///|
/// Processes a single StreamEvent through schema and rules.
pub fn StreamPipeline::process_event(
  self : StreamPipeline,
  event : @core.StreamEvent,
) -> PipelineEventResult {
  self.context.inc_events()
  self.context.update_watermark(event.timestamp)

  // 1. Schema Validation
  let schema_errs = match self.schema {
    Some(s) => s.validate_event(event)
    None => []
  }

  // 2. Rule Evaluations
  let rule_results = self.registry.evaluate_all(event)
  let failures : Array[@rules.RuleResult] = []
  let mut passed_cnt = 0
  let mut failed_cnt = 0

  for i = 0; i < rule_results.length(); i = i + 1 {
    let r = rule_results[i]
    if r.passed {
      passed_cnt = passed_cnt + 1
    } else {
      failed_cnt = failed_cnt + 1
      failures.push(r)
    }
  }

  let event_passed = schema_errs.length() == 0 && failed_cnt == 0

  if !event_passed {
    self.context.inc_errors()
    if self.failed_samples.length() < self.sample_limit {
      self.failed_samples.push(event)
    }
  }

  {
    event_id: event.event_id,
    passed: event_passed,
    schema_errors: schema_errs,
    rule_failures: failures,
    passed_rules_count: passed_cnt,
    failed_rules_count: failed_cnt,
  }
}

///|
/// Processes a batch of events and returns summary metrics.
pub fn StreamPipeline::process_batch(
  self : StreamPipeline,
  events : Array[@core.StreamEvent],
) -> PipelineBatchSummary {
  let batch_id = self.context.current_batch_id
  let mut passed_events = 0L
  let mut failed_events = 0L
  let mut total_rule_evals = 0L
  let mut total_rule_fails = 0L

  for i = 0; i < events.length(); i = i + 1 {
    let res = self.process_event(events[i])
    total_rule_evals = total_rule_evals +
      (res.passed_rules_count + res.failed_rules_count).to_int64()
    total_rule_fails = total_rule_fails + res.failed_rules_count.to_int64()

    if res.passed {
      passed_events = passed_events + 1L
    } else {
      failed_events = failed_events + 1L
    }
  }

  let total = events.length().to_int64()
  let pass_rate = if total == 0L {
    1.0
  } else {
    passed_events.to_double() / total.to_double()
  }

  {
    batch_id,
    total_events: total,
    passed_events,
    failed_events,
    total_rule_evaluations: total_rule_evals,
    total_rule_failures: total_rule_fails,
    pass_rate,
  }
}
