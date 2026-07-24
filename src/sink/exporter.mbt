// MoonBit Stream Quality Engine - Metrics Exporter Module
// Copyright 2026 zmjknn
// Apache-2.0 License

/// Formats stream quality metrics into Prometheus exposition text format.
pub fn export_prometheus_metrics(
  pipeline_name : String,
  summary : @engine.PipelineBatchSummary,
  metrics : @report.DimensionalMetrics,
  overall_score : Double
) -> String {
  let mut p = ""
  p = p + "# HELP stream_quality_score Overall data stream quality score (0-100)\n"
  p = p + "# TYPE stream_quality_score gauge\n"
  p = p + "stream_quality_score{pipeline=\"" + pipeline_name + "\"} " + overall_score.to_string() + "\n\n"

  p = p + "# HELP stream_events_processed_total Total stream events processed\n"
  p = p + "# TYPE stream_events_processed_total counter\n"
  p = p + "stream_events_processed_total{pipeline=\"" + pipeline_name + "\"} " + summary.total_events.to_string() + "\n\n"

  p = p + "# HELP stream_events_passed_total Total stream events passing quality checks\n"
  p = p + "# TYPE stream_events_passed_total counter\n"
  p = p + "stream_events_passed_total{pipeline=\"" + pipeline_name + "\"} " + summary.passed_events.to_string() + "\n\n"

  p = p + "# HELP stream_events_failed_total Total stream events failing quality checks\n"
  p = p + "# TYPE stream_events_failed_total counter\n"
  p = p + "stream_events_failed_total{pipeline=\"" + pipeline_name + "\"} " + summary.failed_events.to_string() + "\n\n"

  p = p + "# HELP stream_dimension_score Dimensional quality score breakdown\n"
  p = p + "# TYPE stream_dimension_score gauge\n"
  p = p + "stream_dimension_score{pipeline=\"" + pipeline_name + "\",dimension=\"completeness\"} " + metrics.completeness_score.to_string() + "\n"
  p = p + "stream_dimension_score{pipeline=\"" + pipeline_name + "\",dimension=\"uniqueness\"} " + metrics.uniqueness_score.to_string() + "\n"
  p = p + "stream_dimension_score{pipeline=\"" + pipeline_name + "\",dimension=\"validity\"} " + metrics.validity_score.to_string() + "\n"
  p = p + "stream_dimension_score{pipeline=\"" + pipeline_name + "\",dimension=\"timeliness\"} " + metrics.timeliness_score.to_string() + "\n"

  p
}
