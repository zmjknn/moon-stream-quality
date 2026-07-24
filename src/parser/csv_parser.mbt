// MoonBit Stream Quality Engine - CSV & TSV Parser Module
// Copyright 2026 zmjknn
// Apache-2.0 License

///|
/// CSV Parser Configuration.
pub(all) struct CsvParserConfig {
  delimiter : Char
  has_header : Bool
  trim_values : Bool
} derive(Eq, Debug)

///|
/// Creates default CSV configuration.
pub fn CsvParserConfig::default() -> CsvParserConfig {
  { delimiter: ',', has_header: true, trim_values: true }
}

///|
/// Splits a CSV row taking quotes into account.
pub fn parse_csv_line(line : String, delimiter? : Char = ',') -> Array[String] {
  let fields : Array[String] = []
  let mut curr = ""
  let mut in_quotes = false
  let delim_code = delimiter.to_int()

  for i = 0; i < line.length(); i = i + 1 {
    let c = line[i]
    if c == '"' {
      in_quotes = !in_quotes
    } else if c.to_int() == delim_code && !in_quotes {
      fields.push(curr)
      curr = ""
    } else {
      curr = curr + String::make(1, c.to_int().unsafe_to_char())
    }
  }
  fields.push(curr)
  fields
}

///|
/// Safe integer parser for numeric strings.
pub fn parse_int64_safe(s : String) -> Int64? {
  let len = s.length()
  if len == 0 {
    return None
  }
  let mut neg = false
  let mut start = 0
  if s[0].to_int() == '-'.to_int() {
    neg = true
    start = 1
  }
  if start >= len {
    return None
  }
  let mut res = 0L
  for i = start; i < len; i = i + 1 {
    let code = s[i].to_int()
    if code < '0'.to_int() || code > '9'.to_int() {
      return None
    }
    let digit = (code - '0'.to_int()).to_int64()
    res = res * 10L + digit
  }
  if neg {
    Some(-res)
  } else {
    Some(res)
  }
}

///|
/// Auto-casts string fields to Int64, Double, Bool, or String.
pub fn auto_cast_value(s : String) -> @core.Value {
  let trimmed = s.trim().to_owned()
  if trimmed == "" || trimmed == "null" || trimmed == "NULL" || trimmed == "NA" {
    return @core.Value::Null
  }
  if trimmed == "true" || trimmed == "TRUE" {
    return @core.Value::Bool(true)
  }
  if trimmed == "false" || trimmed == "FALSE" {
    return @core.Value::Bool(false)
  }

  match parse_int64_safe(trimmed) {
    Some(i) => return @core.Value::Int(i)
    None => ()
  }

  try {
    if trimmed.contains(".") {
      return @core.Value::Double(@string.parse_double(trimmed))
    }
  } catch {
    _ => ()
  }

  @core.Value::String(trimmed)
}

///|
/// Parses multiple CSV lines into a stream of StreamEvent.
pub fn parse_csv_stream(
  csv_lines : Array[String],
  config? : CsvParserConfig = CsvParserConfig::default(),
) -> Array[@core.StreamEvent] {
  let events : Array[@core.StreamEvent] = []
  if csv_lines.length() == 0 {
    return events
  }

  let mut start_idx = 0
  let headers : Array[String] = []

  if config.has_header {
    let header_cols = parse_csv_line(csv_lines[0], delimiter=config.delimiter)
    for i = 0; i < header_cols.length(); i = i + 1 {
      let h = if config.trim_values {
        header_cols[i].trim().to_owned()
      } else {
        header_cols[i]
      }
      headers.push(h)
    }
    start_idx = 1
  }

  for i = start_idx; i < csv_lines.length(); i = i + 1 {
    let row = csv_lines[i].trim().to_owned()
    if row.length() == 0 {
      continue
    }
    let raw_fields = parse_csv_line(row, delimiter=config.delimiter)
    let payload : Map[String, @core.Value] = Map([])

    for j = 0; j < raw_fields.length(); j = j + 1 {
      let col_name = if j < headers.length() {
        headers[j]
      } else {
        "col_" + j.to_string()
      }
      let raw_val = if config.trim_values {
        raw_fields[j].trim().to_owned()
      } else {
        raw_fields[j]
      }
      payload.set(col_name, auto_cast_value(raw_val))
    }

    let evt_id = "csv-row-" + i.to_string()
    events.push(
      @core.StreamEvent::new(
        evt_id,
        1700000000000L + i.to_int64() * 1000L,
        payload~,
      ),
    )
  }

  events
}
