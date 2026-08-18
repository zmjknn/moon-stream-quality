# MoonBit Stream Quality Acceptance Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task with verification checkpoints.

**Goal:** Extend `zmjknn/moon-stream-quality` to an approximately 8,000-line, production-oriented MoonBit streaming quality engine with real benchmarks, boundary tests, CI, documentation, and publish readiness for the August Hackathon acceptance review.

**Architecture:** Preserve the existing package layers. Add event-time windowing in `src/core`, schema compatibility and resilient streaming readers in `src/schema`/`src/parser`, health and quantile monitoring in `src/rules`, checkpoint/replay in `src/pipeline`, and benchmark/report integration in `src/benchmark`/`src/report`. Keep all new behavior deterministic and backend-portable; add native-only timing only through MoonBit's benchmark runner.

**Tech Stack:** MoonBit stable toolchain, `moon.mod`/`moon.pkg`, standard library only, MoonBit test blocks, `moon bench`, GitHub Actions, Mooncakes CLI.

## Global Constraints

- Treat the project as the 2026 August Hackathon project, not the OSC open-source contest.
- Keep effective `.mbt` source between 4,000 and 10,000 lines; exclude `_build`, generated drivers, caches, and temporary benchmark output.
- Keep MoonBit as the main implementation language and avoid external runtime dependencies.
- Every production behavior follows a failing-test-first cycle; configuration-only changes may be made directly.
- Use `///|` block separators, focused package-local files, and generated `.mbti` only through `moon info`.
- Preserve Apache-2.0 and single contributor identity `zmjknn`.

---

### Task 1: Commit the accepted design and establish the implementation baseline

**Files:**
- Create: `docs/superpowers/specs/2026-08-18-stream-quality-acceptance-design.md`
- Create: `docs/superpowers/plans/2026-08-18-stream-quality-acceptance.md`
- Modify: `task_plan.md`, `findings.md`, `progress.md`

**Interfaces:** Consumes the existing repository and proposal. Produces the approved module boundaries and verification commands used by every later task.

- [x] Record current source count, baseline tests, remote default branch, license, and toolchain in the planning files.
- [x] Run `git diff --check`, `moon fmt --check`, `moon check --deny-warn`, and `moon test --deny-warn` before implementation.
- [x] Run `git status --short` and confirm only the proposal, planning files, and design files are uncommitted.
- [x] Commit the design and plan with `docs: define August Hackathon acceptance design`.

Expected result: the branch has one reviewable design commit and all baseline checks remain green.

### Task 2: Add event-time watermark and bounded window runtime

**Files:**
- Create: `src/core/event_time.mbt`
- Create: `src/core/event_time_test.mbt`
- Modify: `src/core/moon.pkg` only if the compiler requires an additional standard import

**Interfaces:**
- `pub(all) enum LateEventPolicy { Drop, SideOutput, Accept }`
- `pub(all) enum WindowAssignment { OnTime, Late, TooLate }`
- `pub(all) struct WatermarkTracker { max_timestamp : Int64; allowed_lateness_ms : Int64; initialized : Bool }`
- `pub fn WatermarkTracker::new(allowed_lateness_ms? : Int64 = 0L) -> WatermarkTracker`
- `pub fn WatermarkTracker::observe(self : WatermarkTracker, timestamp : Int64) -> Int64`
- `pub fn WatermarkTracker::classify(self : WatermarkTracker, timestamp : Int64) -> WindowAssignment`
- `pub(all) struct EventTimeWindow { start : Int64; end : Int64; events : Array[@core.StreamEvent]; closed : Bool }`
- `pub(all) struct WindowRuntime { window_size_ms : Int64; allowed_lateness_ms : Int64; max_windows : Int; policy : LateEventPolicy; watermark : WatermarkTracker; windows : Array[EventTimeWindow]; late_count : Int; dropped_count : Int }`
- `pub fn WindowRuntime::new(window_size_ms : Int64, allowed_lateness_ms? : Int64 = 0L, max_windows? : Int = 32, policy? : LateEventPolicy = SideOutput) -> WindowRuntime`
- `pub fn WindowRuntime::ingest(self : WindowRuntime, event : @core.StreamEvent) -> WindowAssignment`
- `pub fn WindowRuntime::advance_watermark(self : WindowRuntime, timestamp : Int64) -> Array[EventTimeWindow]`
- `pub fn WindowRuntime::flush(self : WindowRuntime) -> Array[EventTimeWindow]`
- `pub fn WindowRuntime::active_window_count(self : WindowRuntime) -> Int`
- `pub fn WindowRuntime::late_event_count(self : WindowRuntime) -> Int`

- [x] Write tests for timestamp classification at exact watermark, one millisecond late, too-late policy, empty runtime, zero/negative configuration, window boundary, max-window eviction, and flush idempotence.
- [x] Run `moon test src/core/event_time_test.mbt --deny-warn`; confirm the new tests fail because the types/functions do not exist.
- [x] Implement the enums, tracker, fixed-capacity window storage, and deterministic close/flush behavior in small `///|` blocks.
- [x] Run the focused test again, then `moon test src/core --deny-warn`.
- [x] Refactor only after green: centralize safe configuration normalization and remove duplicate timestamp calculations.
- [x] Commit `feat(core): add bounded event-time window runtime`.

Expected result: late events are classified deterministically, no window array grows beyond configured capacity, and the existing core tests remain green.

### Task 3: Add Schema compatibility and default-value decisions

**Files:**
- Create: `src/schema/compatibility.mbt`
- Create: `src/schema/compatibility_test.mbt`
- Modify: `src/schema/schema.mbt` only to reuse existing field lookup helpers

**Interfaces:**
- `pub(all) enum CompatibilityMode { Strict, BackwardCompatible, ForwardCompatible }
- `pub(all) enum SchemaChange { AddedOptional(String), AddedRequired(String), Removed(String), TypeChanged(String, String, String), Unchanged }
- `pub(all) struct SchemaDiff { compatible : Bool; changes : Array[SchemaChange]; defaults_applied : Int }`
- `pub fn compare_schemas(old_schema : @schema.Schema, new_schema : @schema.Schema, mode : CompatibilityMode) -> SchemaDiff`
- `pub fn apply_schema_defaults(schema : @schema.Schema, event : @core.StreamEvent) -> Int`

- [x] Write failing tests for identical schemas, optional addition, required addition, removal under each mode, type change, default insertion, and a missing default.
- [x] Run the focused test and confirm failure is due to absent compatibility API.
- [x] Implement deterministic field-name ordering, type comparison, compatibility rules, and in-place default insertion.
- [x] Run `moon test src/schema --deny-warn` and inspect the exact `SchemaDiff` results.
- [x] Commit `feat(schema): add schema evolution compatibility checks`.

Expected result: schema evolution can be checked before rules run, with no hidden coercion and a count of applied defaults.

### Task 4: Harden CSV/JSONL streaming readers

**Files:**
- Create: `src/parser/stream_reader.mbt`
- Create: `src/parser/stream_reader_test.mbt`
- Modify: `src/parser/csv_parser.mbt` and `src/parser/json_parser.mbt` only through small shared helpers

**Interfaces:**
- `pub(all) struct ParseIssue { line : Int; column : Int; message : String; raw : String }`
- `pub(all) enum LineParseResult { Parsed(@core.StreamEvent); Rejected(ParseIssue) }
- `pub(all) struct DelimitedStreamReader { delimiter : Char; quote : Char; pending : String; line_number : Int; in_quotes : Bool }`
- `pub fn DelimitedStreamReader::new(delimiter? : Char = ',') -> DelimitedStreamReader`
- `pub fn DelimitedStreamReader::push_chunk(self : DelimitedStreamReader, chunk : String) -> Array[LineParseResult]`
- `pub fn DelimitedStreamReader::finish(self : DelimitedStreamReader) -> Array[LineParseResult]`
- `pub fn parse_json_lines(lines : Array[String], timestamp? : Int64 = 0L) -> Array[LineParseResult]`

- [x] Write failing tests for quoted delimiter, doubled quote, chunk split inside a quote, empty final line, unterminated quote, invalid JSON with line/column, and continued parsing after a rejected line.
- [x] Run focused parser tests and confirm the new API is missing.
- [x] Implement a small CSV state machine and JSONL result wrapper using existing parsers for completed records.
- [x] Run `moon test src/parser --deny-warn` and all existing parser tests.
- [x] Commit `feat(parser): add resilient chunked stream readers`.

Expected result: malformed records become structured rejects while valid records after them remain processable.

### Task 5: Add quantiles and stream health monitoring

**Files:**
- Create: `src/rules/quantile.mbt`
- Create: `src/rules/health.mbt`
- Create: `src/rules/health_test.mbt`
- Modify: `src/rules/rule_base.mbt` only if a shared result helper is required

**Interfaces:**
- `pub(all) struct QuantileSketch { capacity : Int; values : Array[Double] }`
- `pub fn QuantileSketch::new(capacity? : Int = 256) -> QuantileSketch`
- `pub fn QuantileSketch::add(self : QuantileSketch, value : Double) -> Unit`
- `pub fn QuantileSketch::quantile(self : QuantileSketch, percentile : Double) -> Double?`
- `pub(all) enum HealthStatus { Healthy; Degraded; Starved; Bursting }
- `pub(all) struct HealthSnapshot { total : Int64; passed : Int64; failed : Int64; missing : Int64; duplicates : Int64; p50_latency_ms : Double; p95_latency_ms : Double; p99_latency_ms : Double; events_per_window : Double; status : HealthStatus }`
- `pub(all) struct StreamHealthMonitor { window_ms : Int64; min_events : Int; max_events : Int; total : Int64; passed : Int64; failed : Int64; missing : Int64; duplicates : Int64; latencies : QuantileSketch; window_events : Int; window_start : Int64; seen_ids : Map[String, Bool] }`
- `pub fn StreamHealthMonitor::new(window_ms : Int64, min_events? : Int = 1, max_events? : Int = 100000, sketch_capacity? : Int = 256) -> StreamHealthMonitor`
- `pub fn StreamHealthMonitor::observe(self : StreamHealthMonitor, event : @core.StreamEvent, passed : Bool, missing? : Bool = false, duplicate? : Bool = false, observed_at : Int64) -> Unit`
- `pub fn StreamHealthMonitor::snapshot(self : StreamHealthMonitor) -> HealthSnapshot`
- `pub fn StreamHealthMonitor::reset_window(self : StreamHealthMonitor, window_start : Int64) -> Unit`

- [x] Write failing tests for empty quantiles, clamped percentile, capacity eviction, zero latency, missing/duplicate counters, p50/p95/p99, starvation, burst, healthy exact boundaries, and reset.
- [x] Run the focused tests and confirm failure.
- [x] Implement a bounded sorted-copy quantile calculation and monitor snapshot; use event metadata IDs for duplicate detection.
- [x] Run `moon test src/rules/health_test.mbt --deny-warn` and all rule tests.
- [x] Commit `feat(rules): add bounded stream health observability`.

Expected result: the engine exposes actual operational quality indicators without unbounded retention or floating-point invalid results.

### Task 6: Add checkpoint and deterministic DLQ replay

**Files:**
- Create: `src/pipeline/checkpoint.mbt`
- Create: `src/pipeline/replay.mbt`
- Create: `src/pipeline/replay_test.mbt`
- Modify: `src/pipeline/dead_letter_queue.mbt` to expose stable `find_entry` lookup for replay

**Interfaces:**
- `pub(all) struct PipelineCheckpoint { pipeline_name : String; source_id : String; partition : Int; offset : Int64; watermark : Int64; accepted : Int64; rejected : Int64; dlq_cursor : Int }
- `pub fn PipelineCheckpoint::new(pipeline_name : String, source_id : String, partition : Int, offset : Int64) -> PipelineCheckpoint`
- `pub fn PipelineCheckpoint::advance(self : PipelineCheckpoint, event : @core.StreamEvent, passed : Bool, watermark : Int64) -> Unit`
- `pub fn PipelineCheckpoint::to_json(self : PipelineCheckpoint) -> String`
- `pub fn PipelineCheckpoint::from_json(input : String) -> PipelineCheckpoint?`
- `pub(all) struct ReplayPlan { checkpoint : PipelineCheckpoint; entry_ids : Array[String]; max_attempts : Int }
- `pub(all) struct ReplayResult { attempted : Int; replayed : Int; exhausted : Int; missing : Int }
- `pub fn build_replay_plan(checkpoint : PipelineCheckpoint, queue : @pipeline.DeadLetterQueueManager, max_attempts? : Int = 3) -> ReplayPlan`
- `pub fn replay_plan(plan : ReplayPlan, queue : @pipeline.DeadLetterQueueManager) -> ReplayResult`

- [x] Write failing tests for checkpoint round-trip, monotonic offset, accepted/rejected counts, malformed checkpoint, empty DLQ, retry cap, missing entry, and replay idempotence.
- [x] Run focused tests and confirm failure.
- [x] Implement stable JSON fields, safe parser checks, and deterministic queue iteration.
- [x] Run pipeline tests and full tests.
- [x] Commit `feat(pipeline): add checkpointed dead-letter replay`.

Expected result: a failed event can be audited and retried from a stable in-memory checkpoint without duplicating successful entries.

### Task 7: Integrate runtime, health, replay and add realistic workloads

**Files:**
- Create: `src/benchmark/realistic.mbt`
- Create: `src/benchmark/realistic_test.mbt`
- Modify: `src/engine/pipeline.mbt` to expose a health-observation entry point used by realistic workloads
- Modify: `src/report/metrics.mbt` and `src/report/formatter.mbt` to render new health fields
- Modify: `src/cli/main.mbt` to show runtime health and accepted/rejected summary

**Interfaces:**
- `pub(all) struct WorkloadSpec { name : String; event_count : Int; invalid_every : Int; duplicate_every : Int; late_every : Int }
- `pub(all) struct WorkloadResult { name : String; event_count : Int; passed : Int; failed : Int; late : Int; duplicate : Int; quality_score : Double }
- `pub fn run_sensor_workload(spec : WorkloadSpec) -> WorkloadResult`
- `pub fn run_transaction_workload(spec : WorkloadSpec) -> WorkloadResult`
- `pub fn run_access_log_workload(spec : WorkloadSpec) -> WorkloadResult`
- `pub fn format_workload_result(result : WorkloadResult) -> String`

- [x] Write failing tests that assert deterministic counts for fixed workload specs at count 0, count 1, and count 120.
- [x] Run benchmark package tests and confirm missing workload APIs fail.
- [x] Implement seeded synthetic events with documented defect frequencies and feed them through the actual parser/runtime/engine path.
- [x] Replace hard-coded `throughput_eps` values in `src/benchmark/suite.mbt` with measured benchmark output or explicitly labeled operation counts.
- [x] Run `moon test src/benchmark --deny-warn` and `moon run --target native src/cli`.
- [ ] Commit `feat(benchmark): add reproducible streaming workloads`.

Expected result: three realistic domains exercise the production path and return stable quality counts suitable for benchmark reporting.

### Task 8: Add real MoonBit benchmark cases and record measured data

**Files:**
- Modify: `src/benchmark/benchmark_test.mbt`
- Create: `docs/benchmarks/2026-08-18-native-release.md`
- Modify: `README.md` with the exact benchmark command and a generated result table

- [ ] Add `@bench.T` benchmark blocks for parser throughput, 1,000-event engine evaluation, and DLQ replay; keep benchmark inputs fixed and call `b.keep` on results.
- [ ] Run `moon bench src/benchmark --target native --release --deny-warn` and capture the complete output, including mean, range and run counts.
- [ ] Repeat once to identify noisy measurements; record the second reproducible run with date, OS, CPU description, MoonBit version, target and release mode.
- [ ] Write only observed values into `docs/benchmarks/2026-08-18-native-release.md`; include a note that values are machine-specific and compare future runs on the same setup.
- [ ] Update README benchmark instructions and remove every hard-coded claim not backed by the recorded command.
- [ ] Run `moon test --target all --deny-warn` after benchmark additions.
- [ ] Commit `docs(benchmark): record reproducible native release measurements`.

Expected result: the repository contains real, dated benchmark evidence and a command anyone can rerun.

### Task 9: Update CI, publish workflow, README and module metadata

**Files:**
- Modify: `.github/workflows/ci.yml`
- Create: `.github/workflows/publish.yml`
- Modify: `README.md`
- Modify: `OSC2026_8月黑客松项目申报书.md`
- Modify: `moon.mod`
- Modify: `.gitignore` to exclude `_build/` and temporary benchmark output

- [ ] Update CI to use latest stable installer, `moon version --all`, `moon update`, three OS runners, `moon check --target all --deny-warn`, `moon test --target all --deny-warn`, `moon fmt` plus `git diff --exit-code`, and `moon info` plus `git diff --exit-code`.
- [ ] Add a manual `publish.yml` modeled on the MoonBit community template; require an explicitly configured `MOONCAKES_TOKEN` secret, run check/test first, and never print credentials.
- [ ] Set `version = "0.2.0"`, keep `name = "zmjknn/moon-stream-quality"`, and ensure README links use the August Hackathon rather than OSC submission claims.
- [ ] Add accurate source-count command excluding `_build`, runnable CLI/benchmark commands, test count, license statement, provenance statement and acceptance checklist.
- [ ] Update the proposal's completion/deliverable section with actual implemented modules and measured values after those values exist.
- [ ] Run a YAML parse/check if available, `git diff --check`, and local MoonBit gates.
- [ ] Commit `ci: harden multi-target checks and manual Mooncakes publishing`.

Expected result: CI and publishing are explicit, reproducible, secret-safe, and aligned with the August Hackathon.

### Task 10: Final verification, self-review, account checks and push

**Files:**
- Modify: generated `pkg.generated.mbti` files only through `moon info`
- Modify: any files required by verification findings

- [ ] Run `moon fmt`, then `moon info --target all`, and inspect every generated interface diff for intended API changes.
- [ ] Run `moon fmt --check`, `moon check --deny-warn --target all`, `moon test --deny-warn --target all`, `moon build --target all`, `moon run --target native src/cli`, and `moon bench src/benchmark --target native --release --deny-warn`.
- [ ] Count `src/**/*.mbt` excluding `_build` and report implementation/test totals; verify the total is near 8,000 and below 10,000.
- [ ] Run `git diff --check`, inspect `git status`, verify no build/cache output is tracked, and verify all commits use the single `zmjknn` identity.
- [ ] Verify GitHub identity through the currently authorized `gh api user --jq .login` without reading the GitHub config file; require `zmjknn` before push.
- [ ] Verify `git remote show origin` reports `main` as the default branch and the remote owner is `zmjknn`.
- [ ] Verify current Mooncakes identity using the supported `moon login`/publish status command without importing any historical account file; require namespace `zmjknn`.
- [ ] Commit final generated interfaces and documentation, then push `main` to both configured remotes only after the identity checks pass.
- [ ] Publish with `moon publish` after local verification and verify the package/version is queryable on Mooncakes.
- [ ] Re-read the public `osc2026-guide` checklist against the final repository and write the final self-review report to `docs/acceptance/2026-08-18-self-review.md`.
- [ ] Request a focused code review over the final diff before declaring completion.

Expected result: every acceptance claim has fresh command evidence, remote identities are correct, GitHub and Mooncakes contain the final version, and any unresolved external limitation is explicitly reported.
