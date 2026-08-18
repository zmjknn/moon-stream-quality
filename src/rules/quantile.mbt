// MoonBit Stream Quality Engine - Bounded Quantile Sketch
// Copyright 2026 zmjknn
// Apache-2.0 License

///|
/// A bounded recent-value sample used for latency percentiles.
pub(all) struct QuantileSketch {
  capacity : Int
  values : Array[Double]
} derive(Eq, Debug)

///|
/// Creates a sketch with at least one retained sample.
pub fn QuantileSketch::new(capacity? : Int = 256) -> QuantileSketch {
  let safe_capacity = if capacity <= 0 { 1 } else { capacity }
  { capacity: safe_capacity, values: [] }
}

///|
/// Adds a value and evicts the oldest value when capacity is reached.
pub fn QuantileSketch::add(self : QuantileSketch, value : Double) -> Unit {
  self.values.push(value)
  while self.values.length() > self.capacity {
    let _ = self.values.remove(0)
  }
}

///|
fn sorted_values(values : Array[Double]) -> Array[Double] {
  let sorted : Array[Double] = []
  for value in values {
    sorted.push(value)
    let mut index = sorted.length() - 1
    while index > 0 && sorted[index - 1] > value {
      sorted[index] = sorted[index - 1]
      index = index - 1
    }
    sorted[index] = value
  }
  sorted
}

///|
/// Returns a linearly interpolated percentile, clamping the requested range.
pub fn QuantileSketch::quantile(
  self : QuantileSketch,
  percentile : Double,
) -> Double? {
  if self.values.length() == 0 {
    return None
  }
  let p = if percentile < 0.0 {
    0.0
  } else if percentile > 100.0 {
    100.0
  } else {
    percentile
  }
  let sorted = sorted_values(self.values)
  let position = p / 100.0 * (sorted.length() - 1).to_double()
  let lower = position.to_int()
  let upper = if position > lower.to_double() { lower + 1 } else { lower }
  let fraction = position - lower.to_double()
  Some(sorted[lower] + (sorted[upper] - sorted[lower]) * fraction)
}
