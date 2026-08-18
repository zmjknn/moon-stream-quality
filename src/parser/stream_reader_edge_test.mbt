// MoonBit Stream Quality Engine - Reader Boundary Coverage
// Copyright 2026 zmjknn
// Apache-2.0 License

///|
test "empty and whitespace-only JSONL input produces no records" {
  let results = parse_json_lines(["", "  ", "\t"])
  assert_eq(results.length(), 0)
}

///|
test "JSONL trims valid records and preserves explicit timestamp" {
  let results = parse_json_lines(["  {\"id\":7}  "], timestamp=12345L)
  assert_eq(results.length(), 1)
  match results[0] {
    Parsed(event) => {
      assert_eq(event.timestamp, 12345L)
      assert_eq(event.get_int("id"), Some(7L))
    }
    Rejected(_) => assert_eq(true, false)
  }
}

///|
test "custom delimiter survives chunk boundaries" {
  let reader = DelimitedStreamReader::new(delimiter='|')
  assert_eq(reader.push_chunk("left|right\nthird").length(), 1)
  let tail = reader.finish()
  assert_eq(tail.length(), 1)
  assert_eq(parsed_event(tail[0]).unwrap().get_string("col_0"), Some("third"))
}

///|
test "blank delimited records are ignored but line numbers advance" {
  let reader = DelimitedStreamReader::new()
  let results = reader.push_chunk("\n\nvalue\n")
  assert_eq(results.length(), 1)
  assert_eq(parsed_event(results[0]).unwrap().event_id, "csv-stream-3")
}

///|
test "quoted newline remains part of one record" {
  let reader = DelimitedStreamReader::new()
  let results = reader.push_chunk("id,\"line1\nline2\"\n")
  assert_eq(results.length(), 1)
  assert_eq(
    parsed_event(results[0]).unwrap().get_string("col_1"),
    Some("line1\nline2"),
  )
}

///|
test "finish is idempotent after an incomplete record" {
  let reader = DelimitedStreamReader::new()
  let _ = reader.push_chunk("id,value")
  assert_eq(reader.finish().length(), 1)
  assert_eq(reader.finish().length(), 0)
}

///|
test "malformed JSON reports the original trimmed payload" {
  let results = parse_json_lines([" not-json "])
  match results[0] {
    Rejected(issue) => {
      assert_eq(issue.line, 1)
      assert_eq(issue.column, 1)
      assert_eq(issue.raw, "not-json")
    }
    Parsed(_) => assert_eq(true, false)
  }
}
