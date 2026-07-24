// MoonBit Stream Quality Engine - Window Aggregation Rules Module
// Copyright 2026 zmjknn
// Apache-2.0 License

///|
/// Windowing strategy type.
pub(all) enum WindowKind {
  Tumbling(Int64) // window size ms
  Sliding(Int64, Int64) // size ms, slide ms
  CountWindow(Int) // number of events
} derive(Eq, Debug)

///|
/// Aggregation Metric type.
pub(all) enum AggMetric {
  Sum
  Count
  Mean
  Variance
  StdDev
  Min
  Max
} derive(Eq, Debug)

///|
/// Sliding Window Aggregator tracking metrics in memory over event streams.
pub(all) struct WindowAggregator {
  target_field : String
  window_kind : WindowKind
  mut values : Array[Double]
  mut timestamps : Array[Int64]
} derive(Eq, Debug)

///|
/// Creates a new WindowAggregator.
pub fn WindowAggregator::new(
  target_field : String,
  window_kind? : WindowKind = Tumbling(10000L),
) -> WindowAggregator {
  { target_field, window_kind, values: [], timestamps: [] }
}

///|
/// Adds a record to the window aggregator and purges expired events.
pub fn WindowAggregator::add_event(
  self : WindowAggregator,
  event : @core.StreamEvent,
) -> Unit {
  match event.get_double(self.target_field) {
    Some(val) => {
      self.values.push(val)
      self.timestamps.push(event.timestamp)

      // Purge old events according to WindowKind
      match self.window_kind {
        CountWindow(max_cnt) =>
          while self.values.length() > max_cnt {
            let _ = self.values.remove(0)
            let _ = self.timestamps.remove(0)
          }
        Tumbling(win_ms) | Sliding(win_ms, _) => {
          let latest_ts = event.timestamp
          let min_ts = latest_ts - win_ms
          let mut purge_idx = 0
          while purge_idx < self.timestamps.length() &&
                self.timestamps[purge_idx] < min_ts {
            purge_idx = purge_idx + 1
          }
          if purge_idx > 0 {
            for _i = 0; _i < purge_idx; _i = _i + 1 {
              let _ = self.values.remove(0)
              let _ = self.timestamps.remove(0)
            }
          }
        }
      }
    }
    None => ()
  }
}

///|
/// Calculates specified metric on current window.
pub fn WindowAggregator::compute_metric(
  self : WindowAggregator,
  metric : AggMetric,
) -> Double {
  let n = self.values.length()
  if n == 0 {
    return 0.0
  }

  match metric {
    Count => n.to_double()
    Sum => {
      let mut s = 0.0
      for i = 0; i < n; i = i + 1 {
        s = s + self.values[i]
      }
      s
    }
    Min => {
      let mut m = self.values[0]
      for i = 1; i < n; i = i + 1 {
        if self.values[i] < m {
          m = self.values[i]
        }
      }
      m
    }
    Max => {
      let mut m = self.values[0]
      for i = 1; i < n; i = i + 1 {
        if self.values[i] > m {
          m = self.values[i]
        }
      }
      m
    }
    Mean => {
      let mut s = 0.0
      for i = 0; i < n; i = i + 1 {
        s = s + self.values[i]
      }
      s / n.to_double()
    }
    Variance => {
      let mean = self.compute_metric(Mean)
      let mut var_sum = 0.0
      for i = 0; i < n; i = i + 1 {
        let diff = self.values[i] - mean
        var_sum = var_sum + diff * diff
      }
      var_sum / n.to_double()
    }
    StdDev => {
      let v = self.compute_metric(Variance)
      // Approximation of square root using Newton's method
      if v <= 0.0 {
        0.0
      } else {
        let mut x = v
        for _i = 0; _i < 10; _i = _i + 1 {
          x = 0.5 * (x + v / x)
        }
        x
      }
    }
  }
}

///|
/// Window Aggregation Rule evaluating window metrics against low/high thresholds.
pub(all) struct WindowAggregationRule {
  rule_id : String
  rule_name : String
  target_field : String
  metric : AggMetric
  aggregator : WindowAggregator
  min_threshold : Double?
  max_threshold : Double?
  severity : RuleSeverity
} derive(Eq, Debug)

///|
/// Creates a new WindowAggregationRule.
pub fn WindowAggregationRule::new(
  rule_id : String,
  target_field : String,
  metric : AggMetric,
  window_kind? : WindowKind = Tumbling(10000L),
  min_threshold? : Double? = None,
  max_threshold? : Double? = None,
  severity? : RuleSeverity = Error,
  rule_name? : String = "",
) -> WindowAggregationRule {
  let name = if rule_name == "" {
    "WindowAggCheck(" + target_field + ")"
  } else {
    rule_name
  }
  {
    rule_id,
    rule_name: name,
    target_field,
    metric,
    aggregator: WindowAggregator::new(target_field, window_kind~),
    min_threshold,
    max_threshold,
    severity,
  }
}

///|
/// Evaluates window aggregation rule on incoming event.
pub fn WindowAggregationRule::evaluate(
  self : WindowAggregationRule,
  event : @core.StreamEvent,
) -> RuleResult {
  self.aggregator.add_event(event)
  let curr_val = self.aggregator.compute_metric(self.metric)

  let mut valid = true
  let mut msg = ""

  match self.min_threshold {
    Some(min_t) =>
      if curr_val < min_t {
        valid = false
        msg = "Aggregated metric below minimum threshold " + min_t.to_string()
      }
    None => ()
  }

  match self.max_threshold {
    Some(max_t) =>
      if curr_val > max_t {
        valid = false
        msg = "Aggregated metric exceeds maximum threshold " + max_t.to_string()
      }
    None => ()
  }

  RuleResult::new(
    self.rule_id,
    self.rule_name,
    valid,
    severity=self.severity,
    target_field=self.target_field,
    message=msg,
    sample_value=curr_val.to_string(),
  )
}
