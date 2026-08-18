// MoonBit Stream Quality Engine - Chunked Delimited and JSONL Readers
// Copyright 2026 zmjknn
// Apache-2.0 License

///|
/// A recoverable parser issue tied to a source line and column.
pub(all) struct ParseIssue {
  line : Int
  column : Int
  message : String
  raw : String
} derive(Eq, Debug)

///|
/// Result of parsing one input record.
pub(all) enum LineParseResult {
  Parsed(@core.StreamEvent)
  Rejected(ParseIssue)
} derive(Debug)

///|
/// Stateful reader for delimited records split across arbitrary chunks.
pub(all) struct DelimitedStreamReader {
  delimiter : Char
  quote : Char
  mut pending : String
  mut line_number : Int
  mut in_quotes : Bool
} derive(Debug)

///|
fn char_string(c : Char) -> String {
  String::make(1, c.to_int().unsafe_to_char())
}

///|
/// Splits one record while preserving delimiters and doubled quote characters.
fn parse_stream_fields(line : String, delimiter : Char) -> Array[String] {
  let fields : Array[String] = []
  let mut current = ""
  let mut in_quotes = false
  let mut index = 0
  while index < line.length() {
    let c = line[index].to_int().unsafe_to_char()
    if c == '"' {
      if in_quotes && index + 1 < line.length() {
        let next = line[index + 1].to_int().unsafe_to_char()
        if next == '"' {
          current = current + "\""
          index = index + 2
          continue
        }
      }
      in_quotes = !in_quotes
    } else if c == delimiter && !in_quotes {
      fields.push(current.trim().to_owned())
      current = ""
    } else {
      current = current + char_string(c)
    }
    index = index + 1
  }
  fields.push(current.trim().to_owned())
  fields
}

///|
fn parse_delimited_record(
  line : String,
  line_number : Int,
  delimiter : Char,
) -> LineParseResult {
  let raw_fields = parse_stream_fields(line, delimiter)
  let payload : Map[String, @core.Value] = Map([])
  for index = 0; index < raw_fields.length(); index = index + 1 {
    payload.set("col_" + index.to_string(), auto_cast_value(raw_fields[index]))
  }
  Parsed(
    @core.StreamEvent::new(
      "csv-stream-" + line_number.to_string(),
      1700000000000L + line_number.to_int64() * 1000L,
      event_type="csv_stream",
      payload~,
    ),
  )
}

///|
/// Creates an empty chunked reader.
pub fn DelimitedStreamReader::new(
  delimiter? : Char = ',',
) -> DelimitedStreamReader {
  { delimiter, quote: '"', pending: "", line_number: 0, in_quotes: false }
}

///|
/// Pushes a chunk and returns every complete record found in it.
pub fn DelimitedStreamReader::push_chunk(
  self : DelimitedStreamReader,
  chunk : String,
) -> Array[LineParseResult] {
  let results : Array[LineParseResult] = []
  for index = 0; index < chunk.length(); index = index + 1 {
    let c = chunk[index].to_int().unsafe_to_char()
    if c == self.quote {
      self.in_quotes = !self.in_quotes
      self.pending = self.pending + char_string(c)
    } else if c == '\n' && !self.in_quotes {
      self.line_number = self.line_number + 1
      let line = self.pending
      self.pending = ""
      if line.trim().to_owned().length() > 0 {
        results.push(
          parse_delimited_record(line, self.line_number, self.delimiter),
        )
      }
    } else {
      self.pending = self.pending + char_string(c)
    }
  }
  results
}

///|
/// Finishes the reader, reporting an unterminated quoted record if present.
pub fn DelimitedStreamReader::finish(
  self : DelimitedStreamReader,
) -> Array[LineParseResult] {
  let results : Array[LineParseResult] = []
  if self.in_quotes {
    results.push(
      Rejected({
        line: self.line_number + 1,
        column: self.pending.length() + 1,
        message: "unterminated quoted field",
        raw: self.pending,
      }),
    )
    self.pending = ""
    self.in_quotes = false
    return results
  }
  if self.pending.trim().to_owned().length() > 0 {
    self.line_number = self.line_number + 1
    let line = self.pending
    self.pending = ""
    results.push(parse_delimited_record(line, self.line_number, self.delimiter))
  }
  results
}

///|
/// Parses independent JSON object lines while retaining later valid records.
pub fn parse_json_lines(
  lines : Array[String],
  timestamp? : Int64 = 0L,
) -> Array[LineParseResult] {
  let results : Array[LineParseResult] = []
  for index = 0; index < lines.length(); index = index + 1 {
    let line = lines[index].trim().to_owned()
    if line.length() == 0 {
      continue
    }
    let line_number = index + 1
    match
      parse_json_event("jsonl-" + line_number.to_string(), line, timestamp~) {
      Some(event) => results.push(Parsed(event))
      None =>
        results.push(
          Rejected({
            line: line_number,
            column: 1,
            message: "invalid JSON object",
            raw: line,
          }),
        )
    }
  }
  results
}
