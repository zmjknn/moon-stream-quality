// MoonBit Stream Quality Engine - Chunked Reader Tests
// Copyright 2026 zmjknn
// Apache-2.0 License

///|
fn parsed_event(result : LineParseResult) -> @core.StreamEvent? {
  match result {
    Parsed(event) => Some(event)
    Rejected(_) => None
  }
}

///|
test "chunked CSV reader preserves quoted delimiters" {
  let reader = DelimitedStreamReader::new()
  let results = reader.push_chunk("alpha,\"hello,world\"\n")
  assert_eq(results.length(), 1)
  let event = parsed_event(results[0]).unwrap()
  assert_eq(event.get_string("col_0"), Some("alpha"))
  assert_eq(event.get_string("col_1"), Some("hello,world"))
}

///|
test "chunked CSV reader unescapes doubled quotes" {
  let reader = DelimitedStreamReader::new()
  let results = reader.push_chunk("id,\"say \"\"hi\"\"\"\n")
  let event = parsed_event(results[0]).unwrap()
  assert_eq(event.get_string("col_1"), Some("say \"hi\""))
}

///|
test "chunk split inside quoted field keeps parser state" {
  let reader = DelimitedStreamReader::new()
  assert_eq(reader.push_chunk("1,\"hello").length(), 0)
  let results = reader.push_chunk(" world\"\n2,done\n")
  assert_eq(results.length(), 2)
  assert_eq(
    parsed_event(results[0]).unwrap().get_string("col_1"),
    Some("hello world"),
  )
  assert_eq(parsed_event(results[1]).unwrap().get_string("col_1"), Some("done"))
}

///|
test "finish ignores an empty trailing chunk" {
  let reader = DelimitedStreamReader::new()
  let _ = reader.push_chunk("a,b\n")
  assert_eq(reader.finish().length(), 0)
}

///|
test "finish rejects an unterminated quoted field" {
  let reader = DelimitedStreamReader::new()
  let _ = reader.push_chunk("a,\"unterminated")
  let results = reader.finish()
  assert_eq(results.length(), 1)
  match results[0] {
    Rejected(issue) => {
      assert_eq(issue.line, 1)
      assert_eq(issue.column > 0, true)
    }
    Parsed(_) => assert_eq(true, false)
  }
}

///|
test "JSONL rejects one line and continues" {
  let lines = ["{\"id\":1}", "not-json", "{\"id\":3}"]
  let results = parse_json_lines(lines)
  assert_eq(results.length(), 3)
  assert_eq(parsed_event(results[0]).unwrap().get_int("id"), Some(1L))
  match results[1] {
    Rejected(issue) => assert_eq(issue.line, 2)
    Parsed(_) => assert_eq(true, false)
  }
  assert_eq(parsed_event(results[2]).unwrap().get_int("id"), Some(3L))
}
