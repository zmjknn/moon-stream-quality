// MoonBit Stream Quality Engine - Event-time Window Runtime
// Copyright 2026 zmjknn
// Apache-2.0 License

///|
/// Determines what to do with an event that arrives behind the watermark.
pub(all) enum LateEventPolicy {
  Drop
  SideOutput
  Accept
} derive(Eq, Debug)

///|
/// Describes the relation between an event timestamp and the current watermark.
pub(all) enum WindowAssignment {
  OnTime
  Late
  TooLate
} derive(Eq, Debug)

///|
/// Tracks the highest event timestamp and derives a monotonic watermark.
pub(all) struct WatermarkTracker {
  mut max_timestamp : Int64
  allowed_lateness_ms : Int64
  mut initialized : Bool
} derive(Eq, Debug)

///|
fn non_negative(value : Int64) -> Int64 {
  if value < 0L {
    0L
  } else {
    value
  }
}

///|
/// Creates a watermark tracker with a non-negative lateness allowance.
pub fn WatermarkTracker::new(
  allowed_lateness_ms? : Int64 = 0L,
) -> WatermarkTracker {
  {
    max_timestamp: 0L,
    allowed_lateness_ms: non_negative(allowed_lateness_ms),
    initialized: false,
  }
}

///|
/// Observes a timestamp and returns the new monotonic watermark.
pub fn WatermarkTracker::observe(
  self : WatermarkTracker,
  timestamp : Int64,
) -> Int64 {
  if !self.initialized {
    self.max_timestamp = timestamp
    self.initialized = true
  } else if timestamp > self.max_timestamp {
    self.max_timestamp = timestamp
  }
  self.max_timestamp - self.allowed_lateness_ms
}

///|
/// Classifies a timestamp without changing the tracker state.
pub fn WatermarkTracker::classify(
  self : WatermarkTracker,
  timestamp : Int64,
) -> WindowAssignment {
  if !self.initialized {
    return OnTime
  }
  let watermark = self.max_timestamp - self.allowed_lateness_ms
  if timestamp >= watermark {
    OnTime
  } else if self.allowed_lateness_ms > 0L &&
    timestamp >= watermark - self.allowed_lateness_ms {
    Late
  } else {
    TooLate
  }
}

///|
/// A half-open event-time window containing events with timestamps in
/// `[start, end)`.
pub(all) struct EventTimeWindow {
  start : Int64
  end : Int64
  events : Array[StreamEvent]
  mut closed : Bool
} derive(Debug)

///|
/// Bounded event-time runtime with watermark-driven window closing.
pub(all) struct WindowRuntime {
  window_size_ms : Int64
  allowed_lateness_ms : Int64
  max_windows : Int
  policy : LateEventPolicy
  watermark : WatermarkTracker
  windows : Array[EventTimeWindow]
  mut late_count : Int
  mut dropped_count : Int
} derive(Debug)

///|
fn normalize_window_size(value : Int64) -> Int64 {
  if value <= 0L {
    1L
  } else {
    value
  }
}

///|
fn normalize_capacity(value : Int) -> Int {
  if value <= 0 {
    1
  } else {
    value
  }
}

///|
/// Computes a non-negative window start for an event timestamp.
fn window_start(timestamp : Int64, window_size_ms : Int64) -> Int64 {
  if timestamp < 0L {
    0L
  } else {
    timestamp - timestamp % window_size_ms
  }
}

///|
fn make_window(start : Int64, size : Int64) -> EventTimeWindow {
  { start, end: start + size, events: [], closed: false }
}

///|
/// Creates a bounded runtime. Unsafe numeric configuration is normalized to
/// the smallest useful runtime instead of allowing an unbounded or empty one.
pub fn WindowRuntime::new(
  window_size_ms : Int64,
  allowed_lateness_ms? : Int64 = 0L,
  max_windows? : Int = 32,
  policy? : LateEventPolicy = SideOutput,
) -> WindowRuntime {
  let size = normalize_window_size(window_size_ms)
  let lateness = non_negative(allowed_lateness_ms)
  {
    window_size_ms: size,
    allowed_lateness_ms: lateness,
    max_windows: normalize_capacity(max_windows),
    policy,
    watermark: WatermarkTracker::new(allowed_lateness_ms=lateness),
    windows: [],
    late_count: 0,
    dropped_count: 0,
  }
}

///|
fn WindowRuntime::append_event(
  self : WindowRuntime,
  event : StreamEvent,
) -> Unit {
  let start = window_start(event.timestamp, self.window_size_ms)
  let mut index = 0
  while index < self.windows.length() {
    if self.windows[index].start == start {
      self.windows[index].events.push(event)
      return
    }
    index = index + 1
  }
  self.windows.push(make_window(start, self.window_size_ms))
  self.windows[self.windows.length() - 1].events.push(event)
  while self.windows.length() > self.max_windows {
    let _ = self.windows.remove(0)
    self.dropped_count = self.dropped_count + 1
  }
}

///|
/// Inserts an event and returns its event-time classification.
pub fn WindowRuntime::ingest(
  self : WindowRuntime,
  event : StreamEvent,
) -> WindowAssignment {
  let assignment = self.watermark.classify(event.timestamp)
  match assignment {
    OnTime => self.append_event(event)
    Late => {
      self.late_count = self.late_count + 1
      self.append_event(event)
    }
    TooLate => {
      self.late_count = self.late_count + 1
      match self.policy {
        Drop => self.dropped_count = self.dropped_count + 1
        SideOutput => ()
        Accept => self.append_event(event)
      }
    }
  }
  let _ = self.watermark.observe(event.timestamp)
  assignment
}

///|
/// Closes windows whose end is no later than the new watermark.
pub fn WindowRuntime::advance_watermark(
  self : WindowRuntime,
  timestamp : Int64,
) -> Array[EventTimeWindow] {
  let current_watermark = self.watermark.observe(timestamp)
  let closed : Array[EventTimeWindow] = []
  let mut index = 0
  while index < self.windows.length() {
    if self.windows[index].end <= current_watermark {
      let window = self.windows[index]
      let _ = self.windows.remove(index)
      window.closed = true
      closed.push(window)
    } else {
      index = index + 1
    }
  }
  closed
}

///|
/// Closes and returns every active window. A second flush returns no windows.
pub fn WindowRuntime::flush(self : WindowRuntime) -> Array[EventTimeWindow] {
  let closed : Array[EventTimeWindow] = []
  while self.windows.length() > 0 {
    let window = self.windows[0]
    let _ = self.windows.remove(0)
    window.closed = true
    closed.push(window)
  }
  closed
}

///|
/// Returns the number of active windows retained by the bounded runtime.
pub fn WindowRuntime::active_window_count(self : WindowRuntime) -> Int {
  self.windows.length()
}

///|
/// Returns the number of events classified as late or too late.
pub fn WindowRuntime::late_event_count(self : WindowRuntime) -> Int {
  self.late_count
}
