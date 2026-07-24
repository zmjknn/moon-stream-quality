// MoonBit Stream Quality Engine - Parser Package Tests
// Copyright 2026 zmjknn
// Apache-2.0 License

///|
test "parse json object event" {
  let json_str = "{\"device_id\":\"sensor-99\",\"temperature\":36.6,\"active\":true}"
  let evt_opt = parse_json_event("ev-j1", json_str)

  let ok = match evt_opt {
    Some(_) => true
    None => false
  }
  assert_eq(ok, true)
  let evt = evt_opt.unwrap()
  assert_eq(evt.get_string("device_id"), Some("sensor-99"))
  assert_eq(evt.get_double("temperature"), Some(36.6))
  assert_eq(evt.get_bool("active"), Some(true))
}

///|
test "parse csv stream" {
  let csv_lines = ["user_id, age, score", "101, 28, 95.5", "102, 35, 88.0"]
  let events = parse_csv_stream(csv_lines)
  assert_eq(events.length(), 2)
  assert_eq(events[0].get_int("user_id"), Some(101L))
  assert_eq(events[0].get_double("score"), Some(95.5))
}

///|
test "parse logfmt line" {
  let log_line = "level=info service=auth_service status=200 user=\"alice\""
  let evt = parse_logfmt_event("ev-log1", log_line)

  assert_eq(evt.get_string("service"), Some("auth_service"))
  assert_eq(evt.get_int("status"), Some(200L))
  assert_eq(evt.get_string("user"), Some("alice"))
}

///|
test "parse syslog rfc5424" {
  let syslog_line = "<165>1 2026-07-24T14:00:00Z myhost app1 1234 ID47 message payload text"
  let sys_opt = parse_syslog_rfc5424(syslog_line)

  let ok = match sys_opt {
    Some(_) => true
    None => false
  }
  assert_eq(ok, true)
  let sys = sys_opt.unwrap()
  assert_eq(sys.priority, 165)
  assert_eq(sys.hostname, "myhost")
  assert_eq(sys.app_name, "app1")
}

///|
test "parse apache access log" {
  let line = "127.0.0.1 - frank [10/Oct/2000:13:55:36 -0700] \"GET /index.html HTTP/1.0\" 200 2326 \"http://example.com\" \"Mozilla/5.0\""
  let log_opt = parse_apache_access_log(line)

  let ok = match log_opt {
    Some(_) => true
    None => false
  }
  assert_eq(ok, true)
  let log = log_opt.unwrap()
  assert_eq(log.client_ip, "127.0.0.1")
  assert_eq(log.status_code, 200)
}
