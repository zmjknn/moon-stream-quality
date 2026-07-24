// MoonBit Stream Quality Engine - Report Formatter Module
// Copyright 2026 zmjknn
// Apache-2.0 License

///|
/// Formats a Pipeline batch evaluation into Markdown report.
pub fn format_markdown_report(
  summary : @engine.PipelineBatchSummary,
  metrics : DimensionalMetrics,
  overall_score : Double,
  failed_samples : Array[@core.StreamEvent],
) -> String {
  let mut sb = "# 📊 MoonBit Stream Data Quality Report\n\n"
  sb = sb + "## Summary Metrics\n"
  sb = sb + "- **Batch ID**: `" + summary.batch_id + "`\n"
  sb = sb +
    "- **Total Events Evaluated**: `" +
    summary.total_events.to_string() +
    "`\n"
  sb = sb +
    "- **Passed Events**: `" +
    summary.passed_events.to_string() +
    "` (" +
    (summary.pass_rate * 100.0).to_string() +
    "%)\n"
  sb = sb + "- **Failed Events**: `" + summary.failed_events.to_string() + "`\n"
  sb = sb +
    "- **Total Rule Failures**: `" +
    summary.total_rule_failures.to_string() +
    "`\n"
  sb = sb +
    "- **Overall Quality Score**: **" +
    overall_score.to_string() +
    " / 100**\n\n"

  sb = sb + "## Quality Score Breakdown\n"
  sb = sb + "| Dimension | Score |\n"
  sb = sb + "|---|---|\n"
  sb = sb +
    "| Completeness | " +
    metrics.completeness_score.to_string() +
    "% |\n"
  sb = sb + "| Uniqueness | " + metrics.uniqueness_score.to_string() + "% |\n"
  sb = sb + "| Validity | " + metrics.validity_score.to_string() + "% |\n"
  sb = sb + "| Timeliness | " + metrics.timeliness_score.to_string() + "% |\n\n"

  if failed_samples.length() > 0 {
    sb = sb +
      "## Failure Samples Collector (First " +
      failed_samples.length().to_string() +
      " samples)\n```json\n["
    for i = 0; i < failed_samples.length(); i = i + 1 {
      if i > 0 {
        sb = sb + ",\n  "
      } else {
        sb = sb + "\n  "
      }
      sb = sb + failed_samples[i].to_json_string()
    }
    sb = sb + "\n]\n```\n"
  } else {
    sb = sb + "✅ **No quality rule violations detected in this batch!**\n"
  }

  sb
}

///|
/// Formats a Pipeline batch evaluation into JSON report string.
pub fn format_json_report(
  summary : @engine.PipelineBatchSummary,
  metrics : DimensionalMetrics,
  overall_score : Double,
) -> String {
  "{\"batch_id\":\"" +
  summary.batch_id +
  "\",\"total_events\":" +
  summary.total_events.to_string() +
  ",\"pass_rate\":" +
  summary.pass_rate.to_string() +
  ",\"overall_quality_score\":" +
  overall_score.to_string() +
  ",\"dimensions\":{\"completeness\":" +
  metrics.completeness_score.to_string() +
  ",\"uniqueness\":" +
  metrics.uniqueness_score.to_string() +
  ",\"validity\":" +
  metrics.validity_score.to_string() +
  ",\"timeliness\":" +
  metrics.timeliness_score.to_string() +
  "}}"
}
