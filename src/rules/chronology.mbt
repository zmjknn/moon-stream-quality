// MoonBit Stream Quality Engine - Chronology Rules Module
// Copyright 2026 zmjknn
// Apache-2.0 License

///|
/// Chronology Rule checking event timestamp monotonicity and out-of-order latency.
pub(all) struct ChronologyRule {
  rule_id : String
  rule_name : String
  max_lateness_ms : Int64
  mut last_timestamp : Int64
  severity : RuleSeverity
} derive(Eq, Debug)

///|
/// Creates a new ChronologyRule.
pub fn ChronologyRule::new(
  rule_id : String,
  max_lateness_ms? : Int64 = 5000L, // 5 sec lateness tolerance
  severity? : RuleSeverity = Error,
  rule_name? : String = "ChronologyOrderCheck",
) -> ChronologyRule {
  { rule_id, rule_name, max_lateness_ms, last_timestamp: 0L, severity }
}

///|
/// Evaluates event timestamp ordering against last watermark timestamp.
pub fn ChronologyRule::evaluate(
  self : ChronologyRule,
  event : @core.StreamEvent,
) -> RuleResult {
  let event_ts = event.timestamp
  if self.last_timestamp == 0L {
    self.last_timestamp = event_ts
    return RuleResult::new(
      self.rule_id,
      self.rule_name,
      true,
      severity=self.severity,
      target_field="timestamp",
      sample_value=event_ts.to_string(),
    )
  }

  if event_ts < self.last_timestamp - self.max_lateness_ms {
    let diff = self.last_timestamp - event_ts
    let msg = "Out-of-order event arrived too late. Lag: " +
      diff.to_string() +
      "ms > threshold " +
      self.max_lateness_ms.to_string() +
      "ms"
    RuleResult::new(
      self.rule_id,
      self.rule_name,
      false,
      severity=self.severity,
      target_field="timestamp",
      message=msg,
      sample_value=event_ts.to_string(),
    )
  } else {
    if event_ts > self.last_timestamp {
      self.last_timestamp = event_ts
    }
    RuleResult::new(
      self.rule_id,
      self.rule_name,
      true,
      severity=self.severity,
      target_field="timestamp",
      sample_value=event_ts.to_string(),
    )
  }
}

///|
/// Chronology metrics tracker for stream streams.
pub(all) struct ChronologyTracker {
  mut max_timestamp : Int64
  mut total_events : Int64
  mut out_of_order_events : Int64
  mut total_lag_ms : Int64
} derive(Eq, Debug)

///|
/// Creates a new ChronologyTracker.
pub fn ChronologyTracker::new() -> ChronologyTracker {
  {
    max_timestamp: 0L,
    total_events: 0L,
    out_of_order_events: 0L,
    total_lag_ms: 0L,
  }
}

///|
/// Records event timestamp in tracker.
pub fn ChronologyTracker::record(
  self : ChronologyTracker,
  timestamp : Int64,
) -> Unit {
  self.total_events = self.total_events + 1L
  if self.max_timestamp == 0L {
    self.max_timestamp = timestamp
  } else if timestamp < self.max_timestamp {
    self.out_of_order_events = self.out_of_order_events + 1L
    let lag = self.max_timestamp - timestamp
    self.total_lag_ms = self.total_lag_ms + lag
  } else {
    self.max_timestamp = timestamp
  }
}

///|
/// Calculates out-of-order ratio (0.0 to 1.0).
pub fn ChronologyTracker::out_of_order_ratio(
  self : ChronologyTracker,
) -> Double {
  if self.total_events == 0L {
    0.0
  } else {
    self.out_of_order_events.to_double() / self.total_events.to_double()
  }
}
