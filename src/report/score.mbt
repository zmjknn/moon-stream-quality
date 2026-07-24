// MoonBit Stream Quality Engine - Quality Scoring Module
// Copyright 2026 zmjknn
// Apache-2.0 License

/// Weights for Quality Score calculation across dimensions.
pub(all) struct ScoreWeights {
  w_completeness : Double
  w_uniqueness : Double
  w_validity : Double
  w_timeliness : Double
} derive(Eq, Debug)

/// Creates a default balanced ScoreWeights (30%, 25%, 25%, 20%).
pub fn ScoreWeights::default() -> ScoreWeights {
  {
    w_completeness: 0.30,
    w_uniqueness: 0.25,
    w_validity: 0.25,
    w_timeliness: 0.20,
  }
}

/// Calculates the overall weighted Quality Score (0.0 - 100.0).
pub fn calculate_quality_score(
  metrics : DimensionalMetrics,
  weights~ : ScoreWeights = ScoreWeights::default()
) -> Double {
  let score = metrics.completeness_score * weights.w_completeness +
    metrics.uniqueness_score * weights.w_uniqueness +
    metrics.validity_score * weights.w_validity +
    metrics.timeliness_score * weights.w_timeliness
  if score < 0.0 { 0.0 } else if score > 100.0 { 100.0 } else { score }
}

/// Computes Quality Metrics from a PipelineBatchSummary.
pub fn compute_metrics_from_summary(
  summary : @engine.PipelineBatchSummary,
  schema_errors_count~ : Int = 0
) -> DimensionalMetrics {
  let total = summary.total_events
  if total == 0L {
    return DimensionalMetrics::new()
  }

  let total_d = total.to_double()
  let pass_rate_score = summary.pass_rate * 100.0

  let schema_deduction = if total_d > 0.0 { (schema_errors_count.to_double() / total_d) * 100.0 } else { 0.0 }
  let validity = if pass_rate_score - schema_deduction < 0.0 { 0.0 } else { pass_rate_score - schema_deduction }

  DimensionalMetrics::new(
    completeness_score=pass_rate_score,
    uniqueness_score=pass_rate_score,
    validity_score=validity,
    timeliness_score=100.0,
  )
}
