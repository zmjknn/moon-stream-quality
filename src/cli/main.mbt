// MoonBit Stream Quality Engine - Main Entrypoint Executable
// Copyright 2026 zmjknn
// Apache-2.0 License

fn main {
  println("=================================================================")
  println("🌊 MoonBit Stream Data Quality Rule Engine (moon-stream-quality)")
  println("=================================================================")
  println("Initializing stream quality validation pipeline...\n")

  // 1. Create Stream Pipeline
  let pipeline = @engine.StreamPipeline::new("sensor_production_pipeline")
  let registry = pipeline.get_registry()

  // 2. Register Rules
  registry.register_completeness(@rules.CompletenessRule::new("c1", "device_id", severity=@rules.Error))
  registry.register_range(@rules.RangeRule::new("r1", "temperature", min_val=Some(-40.0), max_val=Some(125.0)))
  registry.register_regex(@rules.RegexRule::new("re1", "operator_email", EmailFormat))
  registry.register_uniqueness(@rules.UniquenessRule::new("u1", ["device_id"]))
  registry.register_chronology(@rules.ChronologyRule::new("chr1", max_lateness_ms=5000L))

  // 3. Generate Benchmark Stream
  let stream_events = generate_benchmark_sensor_stream(100)
  println("Evaluating " + stream_events.length().to_string() + " streaming events against 5 quality rules...")

  // 4. Process Batch
  let summary = pipeline.process_batch(stream_events)

  // 5. Compute Quality Metrics & Score
  let metrics = @report.compute_metrics_from_summary(summary)
  let score = @report.calculate_quality_score(metrics)

  // 6. Generate Markdown Quality Report
  let md_report = @report.format_markdown_report(summary, metrics, score, pipeline.failed_samples)
  println("\n" + md_report)

  // 7. Check Alert Trigger
  let alert_cfg = @sink.AlertConfig::default()
  match alert_cfg.check_alert("sensor_production_pipeline", score, summary.total_events) {
    Some(alert) => {
      println("\n🚨 ALERT DISPATCHED:")
      println(alert.to_webhook_json())
    }
    None => println("\n✅ Data Quality Score meets requirement. No alerts triggered.")
  }

  println("\n=================================================================")
  println("Stream Quality Analysis Completed Successfully.")
  println("=================================================================")
}
