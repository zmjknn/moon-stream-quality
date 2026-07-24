// MoonBit Stream Quality Engine - Numerical Range Rules Module
// Copyright 2026 zmjknn
// Apache-2.0 License

/// Numerical Range Rule checking min/max bounds.
pub(all) struct RangeRule {
  rule_id : String
  rule_name : String
  target_field : String
  min_val : Double?
  max_val : Double?
  include_min : Bool
  include_max : Bool
  severity : RuleSeverity
} derive(Eq, Debug)

/// Creates a new RangeRule.
pub fn RangeRule::new(
  rule_id : String,
  target_field : String,
  min_val~ : Double? = None,
  max_val~ : Double? = None,
  include_min~ : Bool = true,
  include_max~ : Bool = true,
  severity~ : RuleSeverity = Error,
  rule_name~ : String = ""
) -> RangeRule {
  let name = if rule_name == "" { "RangeCheck(" + target_field + ")" } else { rule_name }
  {
    rule_id,
    rule_name: name,
    target_field,
    min_val,
    max_val,
    include_min,
    include_max,
    severity,
  }
}

/// Evaluates range rule on an event.
pub fn RangeRule::evaluate(self : RangeRule, event : @core.StreamEvent) -> RuleResult {
  match event.get_double(self.target_field) {
    None =>
      RuleResult::new(
        self.rule_id,
        self.rule_name,
        false,
        severity=self.severity,
        target_field=self.target_field,
        message="Numeric field missing or non-numeric",
        sample_value="<non-numeric>",
      )
    Some(val) => {
      let mut valid = true
      let mut err_msg = ""

      match self.min_val {
        Some(min) => {
          let min_ok = if self.include_min { val >= min } else { val > min }
          if !min_ok {
            valid = false
            err_msg = "Value " + val.to_string() + " below minimum bound " + min.to_string()
          }
        }
        None => ()
      }

      match self.max_val {
        Some(max) => {
          let max_ok = if self.include_max { val <= max } else { val < max }
          if !max_ok {
            valid = false
            err_msg = "Value " + val.to_string() + " exceeds maximum bound " + max.to_string()
          }
        }
        None => ()
      }

      RuleResult::new(
        self.rule_id,
        self.rule_name,
        valid,
        severity=self.severity,
        target_field=self.target_field,
        message=err_msg,
        sample_value=val.to_string(),
      )
    }
  }
}

/// Outlier Detection Rule based on streaming mean and standard deviation.
pub(all) struct OutlierRule {
  rule_id : String
  target_field : String
  max_z_score : Double
  severity : RuleSeverity
} derive(Eq, Debug)

/// Creates a new OutlierRule.
pub fn OutlierRule::new(
  rule_id : String,
  target_field : String,
  max_z_score~ : Double = 3.0,
  severity~ : RuleSeverity = Warning
) -> OutlierRule {
  { rule_id, target_field, max_z_score, severity }
}

/// Evaluates outlier rule against mean and std_dev.
pub fn OutlierRule::evaluate(
  self : OutlierRule,
  event : @core.StreamEvent,
  mean : Double,
  std_dev : Double
) -> RuleResult {
  match event.get_double(self.target_field) {
    None =>
      RuleResult::new(
        self.rule_id,
        "OutlierCheck(" + self.target_field + ")",
        false,
        severity=self.severity,
        target_field=self.target_field,
        message="Field non-numeric for outlier check",
      )
    Some(val) => {
      if std_dev == 0.0 {
        return RuleResult::new(
          self.rule_id,
          "OutlierCheck(" + self.target_field + ")",
          true,
          severity=self.severity,
          target_field=self.target_field,
          sample_value=val.to_string(),
        )
      }
      let diff = if val > mean { val - mean } else { mean - val }
      let z_score = diff / std_dev
      let ok = z_score <= self.max_z_score
      let msg = if ok { "" } else { "Statistical anomaly: Z-score " + z_score.to_string() + " > " + self.max_z_score.to_string() }
      RuleResult::new(
        self.rule_id,
        "OutlierCheck(" + self.target_field + ")",
        ok,
        severity=self.severity,
        target_field=self.target_field,
        message=msg,
        sample_value=val.to_string(),
      )
    }
  }
}
