// MoonBit Stream Quality Engine - Rule Registry Module
// Copyright 2026 zmjknn
// Apache-2.0 License

///|
/// Dynamic Rule Item enum holding configured quality rules.
pub(all) enum RuleItem {
  Completeness(@rules.CompletenessRule)
  Uniqueness(@rules.UniquenessRule)
  Range(@rules.RangeRule)
  Regex(@rules.RegexRule)
  Chronology(@rules.ChronologyRule)
  CrossField(@rules.CrossFieldRule)
  WindowAgg(@rules.WindowAggregationRule)
  Statistical(@rules.SkewnessRule)
  Anomaly(@rules.EmaAnomalyRule)
  Correlation(@rules.CorrelationRule)
  Frequency(@rules.FrequencyRule)
} derive(Eq, Debug)

///|
/// Rule Registry managing active stream validation rules.
pub(all) struct RuleRegistry {
  rules : Map[String, RuleItem]
} derive(Eq, Debug)

///|
/// Creates a new RuleRegistry.
pub fn RuleRegistry::new() -> RuleRegistry {
  { rules: Map([]) }
}

///|
/// Registers a Completeness rule.
pub fn RuleRegistry::register_completeness(
  self : RuleRegistry,
  rule : @rules.CompletenessRule,
) -> Unit {
  self.rules.set(rule.rule_id, Completeness(rule))
}

///|
/// Registers a Uniqueness rule.
pub fn RuleRegistry::register_uniqueness(
  self : RuleRegistry,
  rule : @rules.UniquenessRule,
) -> Unit {
  self.rules.set(rule.rule_id, Uniqueness(rule))
}

///|
/// Registers a Range rule.
pub fn RuleRegistry::register_range(
  self : RuleRegistry,
  rule : @rules.RangeRule,
) -> Unit {
  self.rules.set(rule.rule_id, Range(rule))
}

///|
/// Registers a Regex format rule.
pub fn RuleRegistry::register_regex(
  self : RuleRegistry,
  rule : @rules.RegexRule,
) -> Unit {
  self.rules.set(rule.rule_id, Regex(rule))
}

///|
/// Registers a Chronology rule.
pub fn RuleRegistry::register_chronology(
  self : RuleRegistry,
  rule : @rules.ChronologyRule,
) -> Unit {
  self.rules.set(rule.rule_id, Chronology(rule))
}

///|
/// Registers a CrossField rule.
pub fn RuleRegistry::register_cross_field(
  self : RuleRegistry,
  rule : @rules.CrossFieldRule,
) -> Unit {
  self.rules.set(rule.rule_id, CrossField(rule))
}

///|
/// Registers a WindowAggregation rule.
pub fn RuleRegistry::register_window_agg(
  self : RuleRegistry,
  rule : @rules.WindowAggregationRule,
) -> Unit {
  self.rules.set(rule.rule_id, WindowAgg(rule))
}

///|
/// Registers a Statistical Skewness rule.
pub fn RuleRegistry::register_statistical(
  self : RuleRegistry,
  rule : @rules.SkewnessRule,
) -> Unit {
  self.rules.set(rule.rule_id, Statistical(rule))
}

///|
/// Registers an EMA Anomaly rule.
pub fn RuleRegistry::register_anomaly(
  self : RuleRegistry,
  rule : @rules.EmaAnomalyRule,
) -> Unit {
  self.rules.set(rule.rule_id, Anomaly(rule))
}

///|
/// Registers a Correlation rule.
pub fn RuleRegistry::register_correlation(
  self : RuleRegistry,
  rule : @rules.CorrelationRule,
) -> Unit {
  self.rules.set(rule.rule_id, Correlation(rule))
}

///|
/// Registers a Frequency rule.
pub fn RuleRegistry::register_frequency(
  self : RuleRegistry,
  rule : @rules.FrequencyRule,
) -> Unit {
  self.rules.set(rule.rule_id, Frequency(rule))
}

///|
/// Retrieves a rule by ID.
pub fn RuleRegistry::get_rule(
  self : RuleRegistry,
  rule_id : String,
) -> RuleItem? {
  self.rules.get(rule_id)
}

///|
/// Returns count of registered rules.
pub fn RuleRegistry::count(self : RuleRegistry) -> Int {
  let mut count = 0
  self.rules.each(fn(_k, _v) { count = count + 1 })
  count
}

///|
/// Evaluates all registered rules against a single event.
pub fn RuleRegistry::evaluate_all(
  self : RuleRegistry,
  event : @core.StreamEvent,
) -> Array[@rules.RuleResult] {
  let results : Array[@rules.RuleResult] = []

  self.rules.each(fn(_id, item) {
    let res = match item {
      Completeness(r) => r.evaluate(event)
      Uniqueness(r) => r.evaluate(event)
      Range(r) => r.evaluate(event)
      Regex(r) => r.evaluate(event)
      Chronology(r) => r.evaluate(event)
      CrossField(r) => r.evaluate(event)
      WindowAgg(r) => r.evaluate(event)
      Statistical(r) => r.evaluate(event)
      Anomaly(r) => r.evaluate(event)
      Correlation(r) => r.evaluate(event)
      Frequency(r) => r.evaluate(event)
    }
    results.push(res)
  })

  results
}
