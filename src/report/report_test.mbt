// MoonBit Stream Quality Engine - Report Package Tests
// Copyright 2026 zmjknn
// Apache-2.0 License

test "quality score calculation" {
  let metrics = DimensionalMetrics::new(
    completeness_score=100.0,
    uniqueness_score=80.0,
    validity_score=90.0,
    timeliness_score=100.0,
  )

  let score = calculate_quality_score(metrics)
  // 100*0.30 + 80*0.25 + 90*0.25 + 100*0.20 = 30 + 20 + 22.5 + 20 = 92.5
  assert_eq(score, 92.5)
}

test "markdown report formatting" {
  let summary : @engine.PipelineBatchSummary = {
    batch_id: "batch-100",
    total_events: 10L,
    passed_events: 9L,
    failed_events: 1L,
    total_rule_evaluations: 20L,
    total_rule_failures: 1L,
    pass_rate: 0.9,
  }

  let metrics = compute_metrics_from_summary(summary)
  let score = calculate_quality_score(metrics)
  let md = format_markdown_report(summary, metrics, score, [])

  assert_eq(md.contains("batch-100"), true)
  assert_eq(md.contains("Overall Quality Score"), true)
}
