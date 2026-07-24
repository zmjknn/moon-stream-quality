// MoonBit Stream Quality Engine - Syslog RFC5424 & Apache Common Log Parser Module
// Copyright 2026 zmjknn
// Apache-2.0 License

///|
/// Parsed Syslog Message Structure according to RFC5424.
pub(all) struct SyslogMessage {
  priority : Int
  facility : Int
  severity : Int
  version : Int
  timestamp : String
  hostname : String
  app_name : String
  proc_id : String
  msg_id : String
  msg : String
} derive(Eq, Debug)

///|
/// Parsed Apache Access Log Entry (Combined Log Format).
pub(all) struct ApacheAccessLog {
  client_ip : String
  identity : String
  user : String
  timestamp : String
  http_method : String
  request_path : String
  http_version : String
  status_code : Int
  response_size : Int64
  referrer : String
  user_agent : String
} derive(Eq, Debug)

///|
/// Helper finding character index in string.
fn find_char_index(s : String, target : Char) -> Int {
  let code = target.to_int()
  for i = 0; i < s.length(); i = i + 1 {
    if s[i].to_int() == code {
      return i
    }
  }
  -1
}

///|
/// Parses Syslog RFC5424 header line `<PRIVAL>VERSION TIMESTAMP HOSTNAME APP-NAME PROCID MSGID MSG`.
pub fn parse_syslog_rfc5424(line : String) -> SyslogMessage? {
  if !line.has_prefix("<") {
    return None
  }
  let close_bracket = find_char_index(line, '>')
  if close_bracket <= 1 {
    return None
  }

  let prival_str = line[1:close_bracket].to_owned()
  let prival = match parse_int64_safe(prival_str) {
    Some(i) => i.to_int()
    None => 13 // default user info
  }

  let facility = prival / 8
  let severity = prival % 8

  let remainder = line[close_bracket + 1:].trim().to_owned()
  let parts = parse_csv_line(remainder, delimiter=' ')
  if parts.length() < 6 {
    return None
  }

  let version = match parse_int64_safe(parts[0]) {
    Some(v) => v.to_int()
    None => 1
  }

  let timestamp = parts[1]
  let hostname = parts[2]
  let app_name = parts[3]
  let proc_id = parts[4]
  let msg_id = parts[5]

  let mut msg = ""
  for i = 6; i < parts.length(); i = i + 1 {
    if i > 6 {
      msg = msg + " "
    }
    msg = msg + parts[i]
  }

  Some({
    priority: prival,
    facility,
    severity,
    version,
    timestamp,
    hostname,
    app_name,
    proc_id,
    msg_id,
    msg,
  })
}

///|
/// Converts SyslogMessage into a StreamEvent payload.
pub fn syslog_to_event(
  syslog : SyslogMessage,
  event_id : String,
) -> @core.StreamEvent {
  let payload : Map[String, @core.Value] = Map([])
  payload.set("priority", @core.Value::Int(syslog.priority.to_int64()))
  payload.set("facility", @core.Value::Int(syslog.facility.to_int64()))
  payload.set("severity", @core.Value::Int(syslog.severity.to_int64()))
  payload.set("hostname", @core.Value::String(syslog.hostname))
  payload.set("app_name", @core.Value::String(syslog.app_name))
  payload.set("proc_id", @core.Value::String(syslog.proc_id))
  payload.set("msg_id", @core.Value::String(syslog.msg_id))
  payload.set("message", @core.Value::String(syslog.msg))

  @core.StreamEvent::new(
    event_id,
    1700000000000L,
    event_type="syslog_rfc5424",
    payload~,
  )
}

///|
/// Parses Apache Combined Access Log format line `127.0.0.1 - frank [10/Oct/2000:13:55:36 -0700] "GET /apache_pb.gif HTTP/1.0" 200 2326 "http://www.example.com/start.html" "Mozilla/4.08"`.
pub fn parse_apache_access_log(line : String) -> ApacheAccessLog? {
  let tokens = parse_csv_line(line, delimiter=' ')
  if tokens.length() < 9 {
    return None
  }

  let client_ip = tokens[0]
  let identity = tokens[1]
  let user = tokens[2]

  let mut timestamp = ""
  let mut idx = 3

  // Reconstruct timestamp within brackets
  while idx < tokens.length() && !tokens[idx].has_suffix("]") {
    if timestamp.length() > 0 {
      timestamp = timestamp + " "
    }
    timestamp = timestamp + tokens[idx]
    idx = idx + 1
  }
  if idx < tokens.length() {
    if timestamp.length() > 0 {
      timestamp = timestamp + " "
    }
    timestamp = timestamp + tokens[idx]
    idx = idx + 1
  }

  let request_line = if idx < tokens.length() {
    tokens[idx]
  } else {
    "GET / HTTP/1.1"
  }
  idx = idx + 1

  let req_parts = parse_csv_line(request_line, delimiter=' ')
  let http_method = if req_parts.length() > 0 { req_parts[0] } else { "GET" }
  let request_path = if req_parts.length() > 1 { req_parts[1] } else { "/" }
  let http_version = if req_parts.length() > 2 {
    req_parts[2]
  } else {
    "HTTP/1.1"
  }

  let status_code = if idx < tokens.length() {
    match parse_int64_safe(tokens[idx]) {
      Some(c) => c.to_int()
      None => 200
    }
  } else {
    200
  }
  idx = idx + 1

  let response_size = if idx < tokens.length() {
    match parse_int64_safe(tokens[idx]) {
      Some(sz) => sz
      None => 0L
    }
  } else {
    0L
  }
  idx = idx + 1

  let referrer = if idx < tokens.length() { tokens[idx] } else { "-" }
  idx = idx + 1
  let user_agent = if idx < tokens.length() { tokens[idx] } else { "-" }

  Some({
    client_ip,
    identity,
    user,
    timestamp,
    http_method,
    request_path,
    http_version,
    status_code,
    response_size,
    referrer,
    user_agent,
  })
}

///|
/// Converts ApacheAccessLog into a StreamEvent.
pub fn apache_log_to_event(
  log : ApacheAccessLog,
  event_id : String,
) -> @core.StreamEvent {
  let payload : Map[String, @core.Value] = Map([])
  payload.set("client_ip", @core.Value::String(log.client_ip))
  payload.set("user", @core.Value::String(log.user))
  payload.set("http_method", @core.Value::String(log.http_method))
  payload.set("request_path", @core.Value::String(log.request_path))
  payload.set("status_code", @core.Value::Int(log.status_code.to_int64()))
  payload.set("response_size", @core.Value::Int(log.response_size))
  payload.set("user_agent", @core.Value::String(log.user_agent))

  @core.StreamEvent::new(
    event_id,
    1700000000000L,
    event_type="apache_access_log",
    payload~,
  )
}
