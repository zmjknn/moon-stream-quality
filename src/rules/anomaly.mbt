// MoonBit Stream Quality Engine - Anomaly & Drift Rules Module
// Copyright 2026 zmjknn
// Apache-2.0 License

///|
/// Exponential Moving Average (EMA) Anomaly Rule.
pub(all) struct EmaAnomalyRule {
  rule_id : String
  target_field : String
  alpha : Double // smoothing factor (0.0 to 1.0)
  threshold_pct : Double // max allowed percentage deviation from EMA
  mut current_ema : Double
  mut initialized : Bool
  severity : RuleSeverity
} derive(Eq, Debug)

///|
/// Creates a new EmaAnomalyRule.
pub fn EmaAnomalyRule::new(
  rule_id : String,
  target_field : String,
  alpha? : Double = 0.2,
  threshold_pct? : Double = 50.0,
  severity? : RuleSeverity = Warning,
) -> EmaAnomalyRule {
  {
    rule_id,
    target_field,
    alpha,
    threshold_pct,
    current_ema: 0.0,
    initialized: false,
    severity,
  }
}

///|
/// Evaluates EMA anomaly rule on an event.
pub fn EmaAnomalyRule::evaluate(
  self : EmaAnomalyRule,
  event : @core.StreamEvent,
) -> RuleResult {
  match event.get_double(self.target_field) {
    Some(val) => {
      if !self.initialized {
        self.current_ema = val
        self.initialized = true
        return RuleResult::new(
          self.rule_id,
          "EMAAnomalyCheck(" + self.target_field + ")",
          true,
          severity=self.severity,
          target_field=self.target_field,
          sample_value=val.to_string(),
        )
      }

      let diff = if val > self.current_ema {
        val - self.current_ema
      } else {
        self.current_ema - val
      }
      let pct_dev = if self.current_ema != 0.0 {
        diff / self.current_ema * 100.0
      } else {
        0.0
      }

      let valid = pct_dev <= self.threshold_pct

      // Update EMA
      self.current_ema = self.alpha * val +
        (1.0 - self.alpha) * self.current_ema

      RuleResult::new(
        self.rule_id,
        "EMAAnomalyCheck(" + self.target_field + ")",
        valid,
        severity=self.severity,
        target_field=self.target_field,
        message=if valid {
          ""
        } else {
          "Value " +
          val.to_string() +
          " deviated " +
          pct_dev.to_string() +
          "% from EMA (" +
          self.current_ema.to_string() +
          ")"
        },
        sample_value=val.to_string(),
      )
    }
    None =>
      RuleResult::new(
        self.rule_id,
        "EMAAnomalyCheck(" + self.target_field + ")",
        true,
        severity=self.severity,
        target_field=self.target_field,
      )
  }
}
