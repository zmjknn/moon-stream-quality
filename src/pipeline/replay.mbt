// MoonBit Stream Quality Engine - Deterministic DLQ Replay
// Copyright 2026 zmjknn
// Apache-2.0 License

///|
/// A bounded replay request derived from a pipeline checkpoint.
pub(all) struct ReplayPlan {
  checkpoint : PipelineCheckpoint
  entry_ids : Array[String]
  max_attempts : Int
} derive(Eq, Debug)

///|
/// Counts the result of one replay request.
pub(all) struct ReplayResult {
  attempted : Int
  replayed : Int
  exhausted : Int
  missing : Int
} derive(Eq, Debug)

///|
fn safe_attempt_limit(value : Int) -> Int {
  if value <= 0 {
    1
  } else {
    value
  }
}

///|
/// Builds a replay plan from entries that have remaining retry budget.
pub fn build_replay_plan(
  checkpoint : PipelineCheckpoint,
  queue : DeadLetterQueueManager,
  max_attempts? : Int = 3,
) -> ReplayPlan {
  let entry_ids : Array[String] = []
  for entry in queue.get_retryable_entries() {
    entry_ids.push(entry.entry_id)
  }
  { checkpoint, entry_ids, max_attempts: safe_attempt_limit(max_attempts) }
}

///|
/// Replays each unique entry at most once per plan and respects the attempt cap.
pub fn replay_plan(
  plan : ReplayPlan,
  queue : DeadLetterQueueManager,
) -> ReplayResult {
  let mut attempted = 0
  let mut replayed = 0
  let mut exhausted = 0
  let mut missing = 0
  let seen : Map[String, Bool] = Map([])
  let limit = safe_attempt_limit(plan.max_attempts)
  for entry_id in plan.entry_ids {
    if attempted >= limit {
      break
    }
    match seen.get(entry_id) {
      Some(_) => ()
      None => {
        seen.set(entry_id, true)
        match queue.find_entry(entry_id) {
          None => missing = missing + 1
          Some(entry) =>
            if entry.retry_count >= entry.max_retries {
              exhausted = exhausted + 1
            } else {
              attempted = attempted + 1
              queue.mark_retried(entry_id)
              replayed = replayed + 1
            }
        }
      }
    }
  }
  { attempted, replayed, exhausted, missing }
}
