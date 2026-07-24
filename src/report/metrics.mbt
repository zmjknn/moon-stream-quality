// MoonBit Stream Quality Engine - Quality Metrics Module
// Copyright 2026 zmjknn
// Apache-2.0 License

/// Dimensional quality metric Breakdown.
pub(all) struct DimensionalMetrics {
  completeness_score : Double // 0.0 - 100.0
  uniqueness_score : Double   // 0.0 - 100.0
  validity_score : Double     // 0.0 - 100.0
  timeliness_score : Double   // 0.0 - 100.0
} derive(Eq, Debug)

/// Creates a new DimensionalMetrics.
pub fn DimensionalMetrics::new(
  completeness_score~ : Double = 100.0,
  uniqueness_score~ : Double = 100.0,
  validity_score~ : Double = 100.0,
  timeliness_score~ : Double = 100.0
) -> DimensionalMetrics {
  { completeness_score, uniqueness_score, validity_score, timeliness_score }
}
