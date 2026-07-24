// MoonBit Stream Quality Engine - Statistical Rules Module
// Copyright 2026 zmjknn
// Apache-2.0 License

///|
/// Statistical Distribution Tracker computing mean, variance, skewness, and kurtosis.
pub(all) struct StatisticalTracker {
  target_field : String
  mut count : Int64
  mut mean : Double
  mut m2 : Double
  mut m3 : Double
  mut m4 : Double
} derive(Eq, Debug)

///|
/// Creates a new StatisticalTracker.
pub fn StatisticalTracker::new(target_field : String) -> StatisticalTracker {
  { target_field, count: 0L, mean: 0.0, m2: 0.0, m3: 0.0, m4: 0.0 }
}

///|
/// Updates running moments using Welford's algorithm extended to 4th moment.
pub fn StatisticalTracker::update(
  self : StatisticalTracker,
  x : Double,
) -> Unit {
  let n1 = self.count
  self.count = self.count + 1L
  let n = self.count.to_double()

  let delta = x - self.mean
  let delta_n = delta / n
  let delta_n2 = delta_n * delta_n
  let term1 = delta * delta_n * n1.to_double()

  self.mean = self.mean + delta_n
  self.m4 = self.m4 +
    term1 * delta_n2 * (n * n - 3.0 * n + 3.0) +
    6.0 * delta_n2 * self.m2 -
    4.0 * delta_n * self.m3
  self.m3 = self.m3 + term1 * delta_n * (n - 2.0) - 3.0 * delta_n * self.m2
  self.m2 = self.m2 + term1
}

///|
/// Calculates variance.
pub fn StatisticalTracker::variance(self : StatisticalTracker) -> Double {
  if self.count < 2L {
    0.0
  } else {
    self.m2 / (self.count - 1L).to_double()
  }
}

///|
/// Calculates standard deviation.
pub fn StatisticalTracker::std_dev(self : StatisticalTracker) -> Double {
  let v = self.variance()
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

///|
/// Calculates skewness.
pub fn StatisticalTracker::skewness(self : StatisticalTracker) -> Double {
  let sd = self.std_dev()
  if sd == 0.0 || self.count < 3L {
    0.0
  } else {
    self.m3 / self.count.to_double() / (sd * sd * sd)
  }
}

///|
/// Statistical Skewness Quality Rule.
pub(all) struct SkewnessRule {
  rule_id : String
  target_field : String
  max_allowed_skewness : Double
  tracker : StatisticalTracker
  severity : RuleSeverity
} derive(Eq, Debug)

///|
/// Creates a new SkewnessRule.
pub fn SkewnessRule::new(
  rule_id : String,
  target_field : String,
  max_allowed_skewness? : Double = 2.0,
  severity? : RuleSeverity = Warning,
) -> SkewnessRule {
  {
    rule_id,
    target_field,
    max_allowed_skewness,
    tracker: StatisticalTracker::new(target_field),
    severity,
  }
}

///|
/// Evaluates skewness rule on event stream.
pub fn SkewnessRule::evaluate(
  self : SkewnessRule,
  event : @core.StreamEvent,
) -> RuleResult {
  match event.get_double(self.target_field) {
    Some(val) => {
      self.tracker.update(val)
      let current_skew = self.tracker.skewness()
      let abs_skew = if current_skew < 0.0 {
        -current_skew
      } else {
        current_skew
      }
      let valid = abs_skew <= self.max_allowed_skewness

      RuleResult::new(
        self.rule_id,
        "SkewnessCheck(" + self.target_field + ")",
        valid,
        severity=self.severity,
        target_field=self.target_field,
        message=if valid {
          ""
        } else {
          "Distribution skewness " +
          current_skew.to_string() +
          " exceeds limit " +
          self.max_allowed_skewness.to_string()
        },
        sample_value=val.to_string(),
      )
    }
    None =>
      RuleResult::new(
        self.rule_id,
        "SkewnessCheck(" + self.target_field + ")",
        true,
        severity=self.severity,
        target_field=self.target_field,
      )
  }
}
