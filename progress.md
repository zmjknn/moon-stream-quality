# 进度记录

## 2026-08-18

- 完成技能规范读取：brainstorming、planning-with-files、moonbit-agent-guide、verification-before-completion、firecrawl fallback。
- 完成本地仓库、申报书、README、CI、模块配置、Git 历史与 baseline 命令核对。
- 完成公开自查 skill 与 MoonBit 社区 CI/publish 模板读取。
- 确认当前仓库非测试源码已超过 4k，但 benchmark 中存在硬编码吞吐率，需改成实际测量/可审计数据。
- 确认现有 CI 已有三平台，但需补齐 target all、deny-warn、fmt/info diff、coverage 与手动发布 workflow。
- 当前停在设计确认门：尚未写实现代码、尚未提交或推送。

### Task 2: Event-time runtime

- Added `src/core/event_time.mbt` with monotonic watermark, late classification, bounded windows, side-output/drop/accept policies, watermark closing and idempotent flush.
- Added 8 boundary tests in `src/core/event_time_test.mbt`.
- TDD evidence: focused test first failed with missing `WatermarkTracker`/`WindowRuntime`; after implementation and one corrected boundary expectation, focused tests passed 8/8 and core package tests passed 11/11.
- `moon fmt --check` passed after formatting.

### Task 3: Schema compatibility

- Added `src/schema/compatibility.mbt` with strict/backward/forward compatibility policies, deterministic change reporting, nullability/type checks, and default application.
- Added 7 boundary tests in `src/schema/compatibility_test.mbt`.
- TDD evidence: focused test first failed with unbound compatibility API; after implementation, focused tests passed 7/7 and schema package tests passed 9/9.
- `moon fmt` and `moon fmt --check` passed.

### Task 4: Resilient stream readers

- Added `src/parser/stream_reader.mbt` with chunk-safe CSV state, escaped quote handling, structured parse issues, and recoverable JSONL parsing.
- Added 6 boundary tests covering quoted delimiters, doubled quotes, chunk splits, empty tails, unterminated fields, and recovery after invalid JSON.
- TDD evidence: focused test first failed with missing reader API; after implementation and parser-state correction, focused tests passed 6/6 and parser package tests passed 11/11.
- `moon fmt` and `moon fmt --check` passed.

### Task 5: Stream health observability

- Added `src/rules/quantile.mbt` with bounded recent samples and interpolated p50/p95/p99 calculations.
- Added `src/rules/health.mbt` with healthy/degraded/starved/bursting status, pass/fail/missing/duplicate counters, latency percentiles, bounded IDs and window reset.
- Added 6 boundary tests. TDD focused test initially failed on missing APIs; after implementation and correcting the intended interpolation/window-boundary assertions, focused tests passed 6/6 and rules package tests passed 15/15.
- `moon fmt` and `moon fmt --check` passed.

### Task 6: Checkpoint and DLQ replay

- Added `src/pipeline/checkpoint.mbt` with monotonic source/watermark progress, counters, stable JSON serialization and strict round-trip parsing.
- Added `src/pipeline/replay.mbt` with bounded unique replay plans and missing/exhausted/replayed accounting; added `find_entry` to the DLQ manager.
- Added 5 tests. TDD evidence: focused test first failed with missing checkpoint/replay APIs; after implementation, focused tests passed 5/5 and pipeline package tests passed 7/7.
- `moon fmt` and `moon fmt --check` passed.

### Task 7: Integration and realistic workloads

- Added `src/engine/observed.mbt` and a white-box engine test for one unified event-time + rule + health observation path.
- Added three deterministic workloads in `src/benchmark/realistic.mbt`: sensor telemetry, transactions and access logs, with defect cadence counters and a CLI formatter.
- Replaced benchmark suite's fabricated `throughput_eps` field with auditable `rule_evaluations`; actual wall-clock data is reserved for `moon bench` in Task 8.
- Added operational Markdown/JSON health report formatting and a CLI summary smoke test.
- Verification: report 3/3, benchmark 7/7, engine 3/3, CLI 1/1; `moon fmt --check` passed.

## 错误与处理

| 错误 | 尝试 | 处理 |
|---|---|---|
| `firecrawl` 命令不存在 | 检查 status 并抓取 URL | 回退到网页读取；不伪造 Firecrawl 结果 |
| `gh auth status` 读取配置被拒绝 | 当前工作区内直接执行 | 暂不读取缓存，推送前改用显式授权状态核验/申请必要授权 |

### Task 8–10: Acceptance hardening

- Added 10 boundary-test files across core, schema, parser, rules, engine, pipeline, benchmark and report; current source count is 7,804 lines (5,948 non-test, 1,856 test).
- Added a real `@bench.T` suite and recorded the latest successful `wasm-gc --release` run in `docs/benchmarks/2026-08-18-wasm-gc-release.md`.
- Rewrote README and proposal for the August Hackathon, added stable-toolchain CI for three operating systems, and added manual secret-safe Mooncakes publishing.
- `moon fmt --check`, `moon check --deny-warn --target all`, and wasm/wasm-gc/js test targets passed; each reported 125/125 tests. `moon run --target wasm-gc src/cli` and the release benchmark passed.
- Native Windows test remains blocked by the installed runtime C source calling `rand_s` without a declaration. The official `moon upgrade` non-interactive attempt and official installer refresh both failed before changing the installed stable toolchain; the exact limitation is recorded in the acceptance self-review.
- Account gate passed through supported status paths: GitHub API reported `zmjknn`, `git remote show origin` reported `main`, and `moon whoami` reported `Logged in as zmjknn`. Push and publish remain the next external-state actions.
- GitHub push succeeded after retrying over HTTP/1.1; `origin/main` now contains `98d45c6`.
- `moon publish` completed package verification and returned server status 200 for `zmjknn/moon-stream-quality` version 0.2.0.
- GitLink rejected the same push with Gitea `User permission denied for writing`; no GitLink remote state was changed.
