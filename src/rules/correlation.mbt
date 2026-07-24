// MoonBit Stream Quality Engine - Correlation & Covariance Rules Module
// Copyright 2026 zmjknn
// Apache-2.0 License

///|
/// Running Correlation & Covariance Tracker for multi-field streams.
pub(all) struct CorrelationTracker {
  field_x : String
  field_y : String
  mut count : Int64
  mut mean_x : Double
  mut mean_y : Double
  mut c_xy : Double
  mut var_x : Double
  mut var_y : Double
} derive(Eq, Debug)

///|
/// Creates a new CorrelationTracker.
pub fn CorrelationTracker::new(
  field_x : String,
  field_y : String,
) -> CorrelationTracker {
  {
    field_x,
    field_y,
    count: 0L,
    mean_x: 0.0,
    mean_y: 0.0,
    c_xy: 0.0,
    var_x: 0.0,
    var_y: 0.0,
  }
}

///|
/// Updates running covariance and Pearson correlation using online update formula.
pub fn CorrelationTracker::update(
  self : CorrelationTracker,
  x : Double,
  y : Double,
) -> Unit {
  self.count = self.count + 1L
  let n = self.count.to_double()

  let dx = x - self.mean_x
  let dy = y - self.mean_y

  self.mean_x = self.mean_x + dx / n
  self.mean_y = self.mean_y + dy / n

  self.c_xy = self.c_xy + dx * (y - self.mean_y)
  self.var_x = self.var_x + dx * (x - self.mean_x)
  self.var_y = self.var_y + dy * (y - self.mean_y)
}

///|
/// Calculates covariance.
pub fn CorrelationTracker::covariance(self : CorrelationTracker) -> Double {
  if self.count < 2L {
    0.0
  } else {
    self.c_xy / (self.count - 1L).to_double()
  }
}

///|
/// Calculates Pearson Correlation Coefficient (-1.0 to 1.0).
pub fn CorrelationTracker::correlation(self : CorrelationTracker) -> Double {
  if self.var_x <= 0.0 || self.var_y <= 0.0 {
    0.0
  } else {
    // Square root approximation
    let denom_sq = self.var_x * self.var_y
    let mut root = denom_sq
    for _i = 0; _i < 10; _i = _i + 1 {
      if root > 0.0 {
        root = 0.5 * (root + denom_sq / root)
      }
    }
    if root == 0.0 {
      0.0
    } else {
      self.c_xy / root
    }
  }
}

///|
/// Correlation Constraint Rule validating expected linear relationship between two numerical stream fields.
pub(all) struct CorrelationRule {
  rule_id : String
  rule_name : String
  field_x : String
  field_y : String
  min_correlation : Double?
  max_correlation : Double?
  tracker : CorrelationTracker
  severity : RuleSeverity
} derive(Eq, Debug)

///|
/// Creates a new CorrelationRule.
pub fn CorrelationRule::new(
  rule_id : String,
  field_x : String,
  field_y : String,
  min_correlation? : Double? = None,
  max_correlation? : Double? = None,
  severity? : RuleSeverity = Warning,
  rule_name? : String = "",
) -> CorrelationRule {
  let name = if rule_name == "" {
    "CorrelationCheck(" + field_x + "," + field_y + ")"
  } else {
    rule_name
  }
  {
    rule_id,
    rule_name: name,
    field_x,
    field_y,
    min_correlation,
    max_correlation,
    tracker: CorrelationTracker::new(field_x, field_y),
    severity,
  }
}

///|
/// Evaluates correlation rule on a stream event.
pub fn CorrelationRule::evaluate(
  self : CorrelationRule,
  event : @core.StreamEvent,
) -> RuleResult {
  let vx_opt = event.get_double(self.field_x)
  let vy_opt = event.get_double(self.field_y)

  match (vx_opt, vy_opt) {
    (Some(x), Some(y)) => {
      self.tracker.update(x, y)
      let curr_corr = self.tracker.correlation()
      let mut valid = true
      let mut msg = ""

      match self.min_correlation {
        Some(min_c) =>
          if curr_corr < min_c {
            valid = false
            msg = "Field correlation " +
              curr_corr.to_string() +
              " below minimum required " +
              min_c.to_string()
          }
        None => ()
      }

      match self.max_correlation {
        Some(max_c) =>
          if curr_corr > max_c {
            valid = false
            msg = "Field correlation " +
              curr_corr.to_string() +
              " exceeds maximum allowed " +
              max_c.to_string()
          }
        None => ()
      }

      RuleResult::new(
        self.rule_id,
        self.rule_name,
        valid,
        severity=self.severity,
        target_field=self.field_x + "," + self.field_y,
        message=msg,
        sample_value=curr_corr.to_string(),
      )
    }
    _ =>
      RuleResult::new(
        self.rule_id,
        self.rule_name,
        true,
        severity=self.severity,
        target_field=self.field_x + "," + self.field_y,
      )
  }
}
