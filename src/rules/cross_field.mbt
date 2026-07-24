// MoonBit Stream Quality Engine - Cross Field Rules Module
// Copyright 2026 zmjknn
// Apache-2.0 License

///|
/// Comparison operator between fields.
pub(all) enum CrossFieldComparisonOp {
  Gt
  Gte
  Lt
  Lte
  Eq
  Neq
} derive(Eq, Debug)

///|
/// Cross Field Relational Rule checking field_a OP field_b.
pub(all) struct CrossFieldRule {
  rule_id : String
  rule_name : String
  field_a : String
  op : CrossFieldComparisonOp
  field_b : String
  severity : RuleSeverity
} derive(Eq, Debug)

///|
/// Creates a new CrossFieldRule.
pub fn CrossFieldRule::new(
  rule_id : String,
  field_a : String,
  op : CrossFieldComparisonOp,
  field_b : String,
  severity? : RuleSeverity = Error,
  rule_name? : String = "",
) -> CrossFieldRule {
  let op_str = match op {
    Gt => ">"
    Gte => ">="
    Lt => "<"
    Lte => "<="
    Eq => "=="
    Neq => "!="
  }
  let name = if rule_name == "" {
    "CrossField(" + field_a + " " + op_str + " " + field_b + ")"
  } else {
    rule_name
  }
  { rule_id, rule_name: name, field_a, op, field_b, severity }
}

///|
/// Evaluates cross-field relational constraint.
pub fn CrossFieldRule::evaluate(
  self : CrossFieldRule,
  event : @core.StreamEvent,
) -> RuleResult {
  let val_a_opt = event.get(self.field_a)
  let val_b_opt = event.get(self.field_b)

  match (val_a_opt, val_b_opt) {
    (Some(va), Some(vb)) => {
      let cmp_res = va.compare(vb)
      match cmp_res {
        Some(cmp) => {
          let is_valid = match self.op {
            Gt => cmp > 0
            Gte => cmp >= 0
            Lt => cmp < 0
            Lte => cmp <= 0
            Eq => cmp == 0
            Neq => cmp != 0
          }

          let msg = if is_valid {
            ""
          } else {
            "Cross-field check failed: " +
            self.field_a +
            " (" +
            va.to_string() +
            ") fails comparison with " +
            self.field_b +
            " (" +
            vb.to_string() +
            ")"
          }

          RuleResult::new(
            self.rule_id,
            self.rule_name,
            is_valid,
            severity=self.severity,
            target_field=self.field_a + "," + self.field_b,
            message=msg,
            sample_value=va.to_string() + " vs " + vb.to_string(),
          )
        }
        None =>
          RuleResult::new(
            self.rule_id,
            self.rule_name,
            false,
            severity=self.severity,
            target_field=self.field_a + "," + self.field_b,
            message="Field types incompatible for comparison",
          )
      }
    }
    _ =>
      RuleResult::new(
        self.rule_id,
        self.rule_name,
        false,
        severity=self.severity,
        target_field=self.field_a + "," + self.field_b,
        message="One or both cross-field targets are missing",
      )
  }
}
