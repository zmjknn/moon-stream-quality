// MoonBit Stream Quality Engine - Frequency & Rate Rules Module
// Copyright 2026 zmjknn
// Apache-2.0 License

///|
/// Event Frequency / Burst Rate Quality Rule.
pub(all) struct FrequencyRule {
  rule_id : String
  rule_name : String
  window_ms : Int64
  max_events_per_window : Int
  min_events_per_window : Int
  mut timestamps : Array[Int64]
  severity : RuleSeverity
} derive(Eq, Debug)

///|
/// Creates a new FrequencyRule.
pub fn FrequencyRule::new(
  rule_id : String,
  window_ms? : Int64 = 10000L, // 10 sec window
  max_events_per_window? : Int = 1000,
  min_events_per_window? : Int = 1,
  severity? : RuleSeverity = Warning,
  rule_name? : String = "",
) -> FrequencyRule {
  let name = if rule_name == "" {
    "FrequencyCheck(" + window_ms.to_string() + "ms)"
  } else {
    rule_name
  }
  {
    rule_id,
    rule_name: name,
    window_ms,
    max_events_per_window,
    min_events_per_window,
    timestamps: [],
    severity,
  }
}

///|
/// Evaluates frequency rule on an incoming event.
pub fn FrequencyRule::evaluate(
  self : FrequencyRule,
  event : @core.StreamEvent,
) -> RuleResult {
  let ts = event.timestamp
  self.timestamps.push(ts)

  // Purge expired timestamps outside window
  let min_ts = ts - self.window_ms
  let mut purge_idx = 0
  while purge_idx < self.timestamps.length() &&
        self.timestamps[purge_idx] < min_ts {
    purge_idx = purge_idx + 1
  }
  if purge_idx > 0 {
    for _i = 0; _i < purge_idx; _i = _i + 1 {
      let _ = self.timestamps.remove(0)
    }
  }

  let count = self.timestamps.length()
  let mut valid = true
  let mut msg = ""

  if count > self.max_events_per_window {
    valid = false
    msg = "Event rate burst detected: " +
      count.to_string() +
      " events in " +
      self.window_ms.to_string() +
      "ms exceeds max " +
      self.max_events_per_window.to_string()
  } else if count < self.min_events_per_window {
    valid = false
    msg = "Event rate starvation detected: " +
      count.to_string() +
      " events in " +
      self.window_ms.to_string() +
      "ms below min " +
      self.min_events_per_window.to_string()
  }

  RuleResult::new(
    self.rule_id,
    self.rule_name,
    valid,
    severity=self.severity,
    target_field="stream_rate",
    message=msg,
    sample_value=count.to_string() + " eps",
  )
}
