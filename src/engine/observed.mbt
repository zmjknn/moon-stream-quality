// MoonBit Stream Quality Engine - Observed Pipeline Evaluation
// Copyright 2026 zmjknn
// Apache-2.0 License

///|
/// Combines rule evaluation with event-time and operational health state.
pub(all) struct PipelineObservationResult {
  evaluation : PipelineEventResult
  assignment : @core.WindowAssignment
} derive(Eq, Debug)

///|
/// Processes one event through the pipeline, bounded window runtime and
/// health monitor using one consistent observed timestamp.
pub fn StreamPipeline::process_event_with_observer(
  self : StreamPipeline,
  event : @core.StreamEvent,
  monitor : @rules.StreamHealthMonitor,
  runtime : @core.WindowRuntime,
) -> PipelineObservationResult {
  let assignment = runtime.ingest(event)
  let evaluation = self.process_event(event)
  let observed_at = if event.meta.ingest_timestamp > 0L {
    event.meta.ingest_timestamp
  } else {
    event.timestamp
  }
  monitor.observe(event, evaluation.passed, observed_at~)
  { evaluation, assignment }
}
