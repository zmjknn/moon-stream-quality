// MoonBit Stream Quality Engine - Uniqueness Rules & Bloom Filter Module
// Copyright 2026 zmjknn
// Apache-2.0 License

///|
/// FNV-1a 64-bit hash function for streaming uniqueness check.
pub fn hash_string(s : String) -> Int64 {
  let mut h = -3750763034362895579L
  for i = 0; i < s.length(); i = i + 1 {
    let c = s[i].to_int64()
    h = h ^ c
    h = h * 1099511628211L
  }
  h
}

///|
/// Sliding Window Bloom Filter for bounded memory uniqueness verification in streams.
pub(all) struct SlidingBloomFilter {
  bit_set : Array[Bool]
  capacity : Int
  mut inserted_count : Int64
} derive(Eq, Debug)

///|
/// Creates a new SlidingBloomFilter.
pub fn SlidingBloomFilter::new(capacity? : Int = 10000) -> SlidingBloomFilter {
  let bit_set = Array::make(capacity, false)
  { bit_set, capacity, inserted_count: 0L }
}

///|
/// Checks if a string key might exist in Bloom Filter.
pub fn SlidingBloomFilter::contains(
  self : SlidingBloomFilter,
  key : String,
) -> Bool {
  let h1 = (hash_string(key) % self.capacity.to_int64()).to_int()
  let idx1 = if h1 < 0 { h1 + self.capacity } else { h1 }
  let h2 = (hash_string(key + "_salt") * 31L % self.capacity.to_int64()).to_int()
  let idx2 = if h2 < 0 { h2 + self.capacity } else { h2 }

  self.bit_set[idx1] && self.bit_set[idx2]
}

///|
/// Inserts a string key into Bloom Filter.
pub fn SlidingBloomFilter::add(self : SlidingBloomFilter, key : String) -> Unit {
  let h1 = (hash_string(key) % self.capacity.to_int64()).to_int()
  let idx1 = if h1 < 0 { h1 + self.capacity } else { h1 }
  let h2 = (hash_string(key + "_salt") * 31L % self.capacity.to_int64()).to_int()
  let idx2 = if h2 < 0 { h2 + self.capacity } else { h2 }

  self.bit_set[idx1] = true
  self.bit_set[idx2] = true
  self.inserted_count = self.inserted_count + 1L
}

///|
/// Resets the Bloom Filter.
pub fn SlidingBloomFilter::clear(self : SlidingBloomFilter) -> Unit {
  for i = 0; i < self.capacity; i = i + 1 {
    self.bit_set[i] = false
  }
  self.inserted_count = 0L
}

///|
/// Uniqueness Rule checking for duplicate composite keys in stream.
pub(all) struct UniquenessRule {
  rule_id : String
  rule_name : String
  target_fields : Array[String]
  bloom_filter : SlidingBloomFilter
  severity : RuleSeverity
} derive(Eq, Debug)

///|
/// Creates a new UniquenessRule.
pub fn UniquenessRule::new(
  rule_id : String,
  target_fields : Array[String],
  capacity? : Int = 10000,
  severity? : RuleSeverity = Error,
  rule_name? : String = "",
) -> UniquenessRule {
  let fields_str = target_fields.fold(init="", fn(acc, f) {
    if acc == "" {
      f
    } else {
      acc + "," + f
    }
  })
  let name = if rule_name == "" {
    "UniquenessCheck(" + fields_str + ")"
  } else {
    rule_name
  }
  {
    rule_id,
    rule_name: name,
    target_fields,
    bloom_filter: SlidingBloomFilter::new(capacity~),
    severity,
  }
}

///|
/// Evaluates uniqueness rule on an event.
pub fn UniquenessRule::evaluate(
  self : UniquenessRule,
  event : @core.StreamEvent,
) -> RuleResult {
  let mut key_builder = ""
  for i = 0; i < self.target_fields.length(); i = i + 1 {
    let field = self.target_fields[i]
    let val_str = match event.get(field) {
      Some(v) => v.to_string()
      None => "<null>"
    }
    if i > 0 {
      key_builder = key_builder + "|"
    }
    key_builder = key_builder + val_str
  }

  if self.bloom_filter.contains(key_builder) {
    RuleResult::new(
      self.rule_id,
      self.rule_name,
      false,
      severity=self.severity,
      target_field=key_builder,
      message="Duplicate event key detected in stream window",
      sample_value=key_builder,
    )
  } else {
    self.bloom_filter.add(key_builder)
    RuleResult::new(
      self.rule_id,
      self.rule_name,
      true,
      severity=self.severity,
      target_field=key_builder,
      sample_value=key_builder,
    )
  }
}
