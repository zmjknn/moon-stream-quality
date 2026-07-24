// MoonBit Stream Quality Engine - Rule Base Module
// Copyright 2026 zmjknn
// Apache-2.0 License

/// Rule severity level.
pub(all) enum RuleSeverity {
  Info
  Warning
  Error
  Critical
} derive(Eq, Debug)

/// Severity to string.
pub fn RuleSeverity::to_string(self : RuleSeverity) -> String {
  match self {
    Info => "INFO"
    Warning => "WARNING"
    Error => "ERROR"
    Critical => "CRITICAL"
  }
}

/// Evaluation result of a quality rule on a single event or stream batch.
pub(all) struct RuleResult {
  rule_id : String
  rule_name : String
  passed : Bool
  severity : RuleSeverity
  target_field : String
  message : String
  sample_value : String
  execution_time_ns : Int64
} derive(Eq, Debug)

/// Creates a new RuleResult.
pub fn RuleResult::new(
  rule_id : String,
  rule_name : String,
  passed : Bool,
  severity~ : RuleSeverity = Error,
  target_field~ : String = "",
  message~ : String = "",
  sample_value~ : String = "",
  execution_time_ns~ : Int64 = 0L
) -> RuleResult {
  {
    rule_id,
    rule_name,
    passed,
    severity,
    target_field,
    message,
    sample_value,
    execution_time_ns,
  }
}
