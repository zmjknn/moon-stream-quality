# MoonBit 流式数据质量规则引擎

[![MoonBit](https://img.shields.io/badge/MoonBit-stable-blue.svg)](https://www.moonbitlang.com/)
[![CI](https://github.com/zmjknn/moon-stream-quality/actions/workflows/ci.yml/badge.svg)](https://github.com/zmjknn/moon-stream-quality/actions/workflows/ci.yml)
[![License](https://img.shields.io/badge/License-Apache%202.0-orange.svg)](LICENSE)

> 2026 年 8 月 MoonBit 官方黑客松结项项目。项目标识：`moon-stream-quality`。
> 唯一贡献者：`zmjknn`。

`moon-stream-quality` 是一个 WASM 优先的流式数据质量规则引擎，用于在传感器、交易和访问日志进入下游系统前，完成结构化解析、Schema 兼容性检查、规则校验、事件时间处理、健康观测和死信重放。

## 已交付能力

- 有界事件时间窗口和单调水位线：支持 on-time、late、too-late 分类、丢弃/旁路/接收策略和窗口驱逐计数。
- Schema 演进：比较字段新增、删除、类型变化和可空性变化，并向缺失字段应用声明式默认值。
- 可恢复输入：分块 CSV reader、引号和转义处理、JSONL 逐行容错，单行损坏不会吞掉后续记录。
- 质量规则与健康指标：完整性、范围、格式、跨字段规则，以及通过 p50/p95/p99 延迟、缺失、重复、Burst/Starvation 判定生成健康快照。
- 可靠流水线：单调 checkpoint、容量受限 DLQ、重试上限、幂等 replay plan，以及 Markdown/JSON 运行报告。
- 可复现实测：传感器、交易和访问日志三种 workload；基准代码位于 `src/benchmark`，实测记录位于 [`docs/benchmarks/2026-08-18-wasm-gc-release.md`](docs/benchmarks/2026-08-18-wasm-gc-release.md)。

## 仓库结构

```text
src/core       事件、值、上下文、事件时间窗口和水位线
src/schema     字段定义、Schema 校验与演进兼容性
src/rules      数据质量规则、在线分位数与流健康监控
src/parser     JSON、CSV、KV、Syslog/Apache 日志解析
src/engine     规则注册、事件/批量流水线与观测集成
src/pipeline   checkpoint、DLQ、重试与审计 replay
src/report     质量评分和 Markdown/JSON 健康报告
src/sink       告警与指标输出组件
src/benchmark  真实 workload fixture 与 MoonBit benchmark
src/cli        可运行的验收演示入口
docs/          设计、计划、自查和实测基准记录
```

当前规模可用以下命令复核（排除 MoonBit 构建产物）：

```powershell
$files = Get-ChildItem -Recurse -File -Filter *.mbt | Where-Object { $_.FullName -notmatch '\\_build\\' }
($files | Get-Content | Measure-Object -Line).Lines
```

2026-08-18 本地统计为 **7,804 行 MoonBit 源码**，其中非测试源码 5,948 行、测试源码 1,856 行。测试规模包括核心算法、输入边界、跨窗口行为、DLQ 重试上限和真实 workload 回归用例。

## 快速开始

安装最新版 stable MoonBit 工具链：

```powershell
# Windows PowerShell
irm https://cli.moonbitlang.com/install/powershell.ps1 | iex
```

```bash
# Linux/macOS
curl -fsSL https://cli.moonbitlang.com/install/unix.sh | bash
```

在仓库根目录运行：

```bash
moon version --all
moon update
moon fmt --check
moon info
moon check --deny-warn --target all
moon test --deny-warn --target all
moon run --target wasm-gc src/cli
```

Windows 本地验收优先使用 `wasm-gc`；若 native runtime 在本机工具链中出现 C 运行时差异，应保留完整错误，而不是用伪造的 native 数据替代实测数据。

## 可复现实测基准

```bash
moon bench src/benchmark --target wasm-gc --release --deny-warn
```

基准 workload 固定为 JSONL reader、120 条传感器事件和 120 条交易事件，并通过 `b.keep` 防止测量路径被优化掉。最新一次真实 Windows `wasm-gc --release` 运行的结果为：JSONL reader **2.82 µs**、传感器质量流水线 **55.81 µs**、交易质量流水线 **224.63 µs**（均值；完整标准差、范围和运行次数见基准记录）。这些数字只用于同一工具链和 workload 的回归比较。

## CI 与发布

`.github/workflows/ci.yml` 在 Ubuntu、macOS、Windows 上安装 stable 工具链，并执行 `moon update`、全 target 的 `moon check`/`moon test`、格式检查和 `.mbti` 接口漂移检查。`.github/workflows/publish.yml` 只允许手动触发，使用仓库 `MOONCAKES_TOKEN` secret 发布当前模块到 Mooncakes，不在日志中输出凭据。

## 验收资料

- [结项设计与验收计划](docs/superpowers/plans/2026-08-18-stream-quality-acceptance.md)
- [WASM-GC 实测基准](docs/benchmarks/2026-08-18-wasm-gc-release.md)
- [项目申报书](OSC2026_8月黑客松项目申报书.md)
- [Apache License 2.0](LICENSE)

## 贡献与许可证

本仓库按黑客松验收要求保留 `zmjknn` 作为唯一 Git 提交贡献者。项目采用 [Apache License 2.0](LICENSE)；如需复现实验，请使用 README 中的固定命令和 workload 配置记录结果。
