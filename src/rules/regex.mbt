// MoonBit Stream Quality Engine - Regex & String Format Rules Module
// Copyright 2026 zmjknn
// Apache-2.0 License

/// Format Kind for common string format patterns.
pub(all) enum RegexFormatKind {
  EmailFormat
  UUIDFormat
  IPv4Format
  ISO8601Format
  CustomPattern(String)
} derive(Eq, Debug)

/// Regex / Pattern Validation Rule.
pub(all) struct RegexRule {
  rule_id : String
  rule_name : String
  target_field : String
  format_kind : RegexFormatKind
  severity : RuleSeverity
} derive(Eq, Debug)

/// Creates a new RegexRule.
pub fn RegexRule::new(
  rule_id : String,
  target_field : String,
  format_kind : RegexFormatKind,
  severity~ : RuleSeverity = Error,
  rule_name~ : String = ""
) -> RegexRule {
  let name = if rule_name == "" { "FormatCheck(" + target_field + ")" } else { rule_name }
  { rule_id, rule_name: name, target_field, format_kind, severity }
}

/// Helper function checking Email format.
pub fn is_valid_email(s : String) -> Bool {
  let len = s.length()
  if len < 5 { return false }
  let mut at_idx = -1
  let mut dot_after_at = false
  for i = 0; i < len; i = i + 1 {
    let c = s[i]
    if c == '@' {
      if at_idx != -1 { return false } // double @
      at_idx = i
    } else if at_idx != -1 && c == '.' && i > at_idx + 1 && i < len - 1 {
      dot_after_at = true
    }
  }
  at_idx > 0 && dot_after_at
}

/// Helper function checking UUID format (8-4-4-4-12 hex).
pub fn is_valid_uuid(s : String) -> Bool {
  if s.length() != 36 { return false }
  for i = 0; i < 36; i = i + 1 {
    let c = s[i]
    if i == 8 || i == 13 || i == 18 || i == 23 {
      if c != '-' { return false }
    } else {
      let is_hex = (c >= '0' && c <= '9') || (c >= 'a' && c <= 'f') || (c >= 'A' && c <= 'F')
      if !is_hex { return false }
    }
  }
  true
}

/// Helper function checking IPv4 format.
pub fn is_valid_ipv4(s : String) -> Bool {
  let len = s.length()
  if len < 7 || len > 15 { return false }
  let mut parts = 0
  let mut curr_num = 0
  let mut digits_in_part = 0

  for i = 0; i < len; i = i + 1 {
    let c = s[i]
    if c >= '0' && c <= '9' {
      curr_num = curr_num * 10 + (c.to_int() - '0'.to_int())
      digits_in_part = digits_in_part + 1
      if curr_num > 255 { return false }
    } else if c == '.' {
      if digits_in_part == 0 { return false }
      parts = parts + 1
      curr_num = 0
      digits_in_part = 0
    } else {
      return false
    }
  }
  parts == 3 && digits_in_part > 0
}

/// Helper checking prefix / suffix pattern.
pub fn matches_custom_prefix_suffix(s : String, pattern : String) -> Bool {
  if pattern.has_prefix("prefix:") {
    let prefix = pattern[7:].to_owned()
    s.has_prefix(prefix)
  } else if pattern.has_prefix("suffix:") {
    let suffix = pattern[7:].to_owned()
    s.has_suffix(suffix)
  } else {
    s.contains(pattern)
  }
}

/// Evaluates RegexRule on an event.
pub fn RegexRule::evaluate(self : RegexRule, event : @core.StreamEvent) -> RuleResult {
  match event.get_string(self.target_field) {
    None =>
      RuleResult::new(
        self.rule_id,
        self.rule_name,
        false,
        severity=self.severity,
        target_field=self.target_field,
        message="Target string field missing or null",
      )
    Some(val) => {
      let is_valid = match self.format_kind {
        EmailFormat => is_valid_email(val)
        UUIDFormat => is_valid_uuid(val)
        IPv4Format => is_valid_ipv4(val)
        ISO8601Format => val.length() >= 10 && (val.contains("T") || val.contains("-"))
        CustomPattern(pat) => matches_custom_prefix_suffix(val, pat)
      }

      RuleResult::new(
        self.rule_id,
        self.rule_name,
        is_valid,
        severity=self.severity,
        target_field=self.target_field,
        message=if is_valid { "" } else { "String failed format match check" },
        sample_value=val,
      )
    }
  }
}
