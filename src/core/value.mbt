// MoonBit Stream Quality Engine - Core Value Module
// Copyright 2026 zmjknn
// Apache-2.0 License

///|
/// Dynamic Value representation for stream record attributes.
pub(all) enum Value {
  Null
  Bool(Bool)
  Int(Int64)
  Double(Double)
  String(String)
  Bytes(Bytes)
  Timestamp(Int64) // Unix timestamp in milliseconds
  Array(Array[Value])
  Map(Map[String, Value])
} derive(Eq, Debug)

///|
/// Returns true if the Value is Null.
pub fn Value::is_null(self : Value) -> Bool {
  match self {
    Null => true
    _ => false
  }
}

///|
/// Returns true if the Value is a boolean.
pub fn Value::is_bool(self : Value) -> Bool {
  match self {
    Bool(_) => true
    _ => false
  }
}

///|
/// Returns true if the Value is an integer.
pub fn Value::is_int(self : Value) -> Bool {
  match self {
    Int(_) => true
    _ => false
  }
}

///|
/// Returns true if the Value is a double/float.
pub fn Value::is_double(self : Value) -> Bool {
  match self {
    Double(_) => true
    _ => false
  }
}

///|
/// Returns true if the Value is a numeric type (Int or Double).
pub fn Value::is_number(self : Value) -> Bool {
  match self {
    Int(_) | Double(_) => true
    _ => false
  }
}

///|
/// Returns true if the Value is a string.
pub fn Value::is_string(self : Value) -> Bool {
  match self {
    String(_) => true
    _ => false
  }
}

///|
/// Returns true if the Value is a timestamp.
pub fn Value::is_timestamp(self : Value) -> Bool {
  match self {
    Timestamp(_) => true
    _ => false
  }
}

///|
/// Returns true if the Value is an array.
pub fn Value::is_array(self : Value) -> Bool {
  match self {
    Array(_) => true
    _ => false
  }
}

///|
/// Returns true if the Value is a map.
pub fn Value::is_map(self : Value) -> Bool {
  match self {
    Map(_) => true
    _ => false
  }
}

///|
/// Converts the value to a Double representation if possible.
pub fn Value::as_double(self : Value) -> Double? {
  match self {
    Int(i) => Some(i.to_double())
    Double(d) => Some(d)
    String(s) => Some(@string.parse_double(s)) catch { _ => None }
    _ => None
  }
}

///|
/// Converts the value to Int64 if possible.
pub fn Value::as_int(self : Value) -> Int64? {
  match self {
    Int(i) => Some(i)
    Double(d) => Some(d.to_int64())
    String(s) => Some(@string.parse_int64(s)) catch { _ => None }
    Timestamp(ts) => Some(ts)
    _ => None
  }
}

///|
/// Converts the value to String representation.
pub fn Value::as_string(self : Value) -> String? {
  match self {
    String(s) => Some(s)
    Int(i) => Some(i.to_string())
    Double(d) => Some(d.to_string())
    Bool(b) => Some(b.to_string())
    Timestamp(ts) => Some(ts.to_string())
    _ => None
  }
}

///|
/// Converts the value to a boolean if possible.
pub fn Value::as_bool(self : Value) -> Bool? {
  match self {
    Bool(b) => Some(b)
    Int(i) => Some(i != 0L)
    String(s) =>
      if s == "true" || s == "1" || s == "TRUE" {
        Some(true)
      } else if s == "false" || s == "0" || s == "FALSE" {
        Some(false)
      } else {
        None
      }
    _ => None
  }
}

///|
/// Human-readable type name of the value.
pub fn Value::type_name(self : Value) -> String {
  match self {
    Null => "Null"
    Bool(_) => "Bool"
    Int(_) => "Int"
    Double(_) => "Double"
    String(_) => "String"
    Bytes(_) => "Bytes"
    Timestamp(_) => "Timestamp"
    Array(_) => "Array"
    Map(_) => "Map"
  }
}

///|
/// Formats the Value into string representation.
pub fn Value::to_string(self : Value) -> String {
  match self {
    Null => "null"
    Bool(b) => b.to_string()
    Int(i) => i.to_string()
    Double(d) => d.to_string()
    String(s) => "\"" + s + "\""
    Bytes(_) => "<bytes>"
    Timestamp(ts) => ts.to_string()
    Array(arr) => {
      let mut res = "["
      for i = 0; i < arr.length(); i = i + 1 {
        if i > 0 {
          res = res + ", "
        }
        res = res + arr[i].to_string()
      }
      res + "]"
    }
    Map(m) => {
      let mut res = "{"
      let mut first = true
      m.each(fn(k, v) {
        if !first {
          res = res + ", "
        }
        res = res + "\"" + k + "\": " + v.to_string()
        first = false
      })
      res + "}"
    }
  }
}

///|
/// Compares two values for ordering when supported.
pub fn Value::compare(self : Value, other : Value) -> Int? {
  match (self, other) {
    (Int(a), Int(b)) =>
      if a < b {
        Some(-1)
      } else if a > b {
        Some(1)
      } else {
        Some(0)
      }
    (Double(a), Double(b)) =>
      if a < b {
        Some(-1)
      } else if a > b {
        Some(1)
      } else {
        Some(0)
      }
    (Int(a), Double(b)) => {
      let ad = a.to_double()
      if ad < b {
        Some(-1)
      } else if ad > b {
        Some(1)
      } else {
        Some(0)
      }
    }
    (Double(a), Int(b)) => {
      let bd = b.to_double()
      if a < bd {
        Some(-1)
      } else if a > bd {
        Some(1)
      } else {
        Some(0)
      }
    }
    (String(a), String(b)) =>
      if a < b {
        Some(-1)
      } else if a > b {
        Some(1)
      } else {
        Some(0)
      }
    (Timestamp(a), Timestamp(b)) =>
      if a < b {
        Some(-1)
      } else if a > b {
        Some(1)
      } else {
        Some(0)
      }
    _ => None
  }
}
