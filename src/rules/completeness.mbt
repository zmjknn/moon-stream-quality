// MoonBit Stream Quality Engine - Completeness Rules Module
// Copyright 2026 zmjknn
// Apache-2.0 License

/// Completeness Rule checking missing fields, nulls, and empty strings.
pub(all) struct CompletenessRule {
  rule_id : String
  rule_name : String
  target_field : String
  allow_empty_string : Bool
  severity : RuleSeverity
} derive(Eq, Debug)

/// Creates a new CompletenessRule.
pub fn CompletenessRule::new(
  rule_id : String,
  target_field : String,
  allow_empty_string~ : Bool = false,
  severity~ : RuleSeverity = Error,
  rule_name~ : String = ""
) -> CompletenessRule {
  let name = if rule_name == "" { "CompletenessCheck(" + target_field + ")" } else { rule_name }
  { rule_id, rule_name: name, target_field, allow_empty_string, severity }
}

/// Evaluates completeness rule on a stream event.
pub fn CompletenessRule::evaluate(
  self : CompletenessRule,
  event : @core.StreamEvent
) -> RuleResult {
  match event.get(self.target_field) {
    None =>
      RuleResult::new(
        self.rule_id,
        self.rule_name,
        false,
        severity=self.severity,
        target_field=self.target_field,
        message="Required field is missing in stream event",
        sample_value="<missing>",
      )
    Some(val) => {
      if val.is_null() {
        RuleResult::new(
          self.rule_id,
          self.rule_name,
          false,
          severity=self.severity,
          target_field=self.target_field,
          message="Required field is null",
          sample_value="null",
        )
      } else {
        match val {
          String(s) => {
            if !self.allow_empty_string && s.length() == 0 {
              RuleResult::new(
                self.rule_id,
                self.rule_name,
                false,
                severity=self.severity,
                target_field=self.target_field,
                message="Required string field is empty",
                sample_value="\"\"",
              )
            } else {
              RuleResult::new(
                self.rule_id,
                self.rule_name,
                true,
                severity=self.severity,
                target_field=self.target_field,
                sample_value=val.to_string(),
              )
            }
          }
          _ =>
            RuleResult::new(
              self.rule_id,
              self.rule_name,
              true,
              severity=self.severity,
              target_field=self.target_field,
              sample_value=val.to_string(),
            )
        }
      }
    }
  }
}

/// Stream Completeness Tracker for accumulated statistics across event batches.
pub(all) struct StreamCompletenessTracker {
  target_field : String
  mut total_count : Int64
  mut valid_count : Int64
  mut missing_count : Int64
  mut null_count : Int64
  mut empty_str_count : Int64
} derive(Eq, Debug)

/// Creates a new StreamCompletenessTracker.
pub fn StreamCompletenessTracker::new(target_field : String) -> StreamCompletenessTracker {
  {
    target_field,
    total_count: 0L,
    valid_count: 0L,
    missing_count: 0L,
    null_count: 0L,
    empty_str_count: 0L,
  }
}

/// Record an event in tracker.
pub fn StreamCompletenessTracker::record(
  self : StreamCompletenessTracker,
  event : @core.StreamEvent,
  allow_empty~ : Bool = false
) -> Unit {
  self.total_count = self.total_count + 1L
  match event.get(self.target_field) {
    None => self.missing_count = self.missing_count + 1L
    Some(val) => {
      if val.is_null() {
        self.null_count = self.null_count + 1L
      } else {
        match val {
          String(s) => {
            if !allow_empty && s.length() == 0 {
              self.empty_str_count = self.empty_str_count + 1L
            } else {
              self.valid_count = self.valid_count + 1L
            }
          }
          _ => self.valid_count = self.valid_count + 1L
        }
      }
    }
  }
}

/// Returns the completeness ratio (0.0 to 1.0).
pub fn StreamCompletenessTracker::completeness_ratio(self : StreamCompletenessTracker) -> Double {
  if self.total_count == 0L {
    1.0
  } else {
    self.valid_count.to_double() / self.total_count.to_double()
  }
}
