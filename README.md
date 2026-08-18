# MoonBit 流式数据质量规则引擎

[![MoonBit](https://img.shields.io/badge/MoonBit-stable-blue.svg)](https://www.moonbitlang.com/)
[![CI](https://github.com/zmjknn/moon-stream-quality/actions/workflows/ci.yml/badge.svg)](https://github.com/zmjknn/moon-stream-quality/actions/workflows/ci.yml)
[![License](https://img.shields.io/badge/License-Apache%202.0-orange.svg)](LICENSE)

`moon-stream-quality` 是一个使用 MoonBit 编写的流式数据质量规则引擎，面向传感器数据、交易事件和访问日志等结构化事件流。项目提供输入解析、Schema 校验、规则评估、事件时间处理、运行状态监控以及失败事件重放等组件，默认以 `wasm-gc` 为主要验证目标。

## 项目范围

项目关注流式处理中的四类问题：

- 输入记录是否可解析，且单条错误是否会影响后续记录；
- 字段类型、必填项和 Schema 演进是否符合约束；
- 事件是否重复、迟到、缺失或违反业务规则；
- 失败记录是否可以被记录、审计并在受限重试次数内重放。

## 主要组件

| 组件 | 作用 |
| --- | --- |
| `src/core` | 事件模型、值类型、处理上下文、事件时间窗口和水位线 |
| `src/schema` | 字段定义、类型校验、默认值和 Schema 兼容性比较 |
| `src/rules` | 完整性、范围、格式、跨字段规则，以及流健康指标 |
| `src/parser` | JSON、CSV、KV、Syslog 和 Apache 访问日志解析；支持分块输入和逐行错误恢复 |
| `src/engine` | 规则注册、单事件评估、批量处理和观测集成 |
| `src/pipeline` | Checkpoint、死信队列、重试限制和 Replay Plan |
| `src/report` | 质量评分以及 Markdown/JSON 健康报告 |
| `src/sink` | 告警和指标输出 |
| `src/benchmark` | 固定 workload、基准测试和可复现的质量回归数据 |
| `src/cli` | 可运行的示例入口 |

事件时间运行时支持 `OnTime`、`Late` 和 `TooLate` 分类，并提供 `Drop`、`SideOutput` 和 `Accept` 三种迟到事件处理策略。健康监控记录通过率、失败数、缺失数、重复数和 p50/p95/p99 延迟，并将窗口状态划分为 `Healthy`、`Degraded`、`Starved` 和 `Bursting`。

## 获取与安装

需要安装 stable MoonBit 工具链。官方安装脚本如下：

```powershell
# Windows PowerShell
irm https://cli.moonbitlang.com/install/powershell.ps1 | iex
```

```bash
# Linux/macOS
curl -fsSL https://cli.moonbitlang.com/install/unix.sh | bash
```

确认工具链：

```bash
moon version --all
```

## 构建与测试

在仓库根目录执行：

```bash
moon update
moon fmt --check
moon info
moon check --deny-warn --target all
moon test --deny-warn --target all
```

运行 CLI 示例：

```bash
moon run --target wasm-gc src/cli
```

`moon info` 会生成或更新各包的 `.mbti` 接口文件。提交代码前应检查接口变化是否符合预期。CI 会在三个操作系统上执行上述检查，并验证格式化结果和生成接口没有未提交的变化。

## 基准测试

基准测试使用固定输入和固定缺陷周期，包含 JSONL reader、120 条传感器事件和 120 条交易事件：

```bash
moon bench src/benchmark --target wasm-gc --release --deny-warn
```

2026-08-18 在 Windows、`wasm-gc`、`--release` 下的一次完整运行结果如下：

| Workload | Mean | Standard deviation | Range |
| --- | ---: | ---: | ---: |
| JSONL reader | 2.82 µs | 80.04 ns | 2.72–2.94 µs |
| Sensor quality pipeline | 55.81 µs | 1.11 µs | 54.31–57.55 µs |
| Transaction quality pipeline | 224.63 µs | 31.11 µs | 142.12–254.37 µs |

完整的运行次数、工具链版本、命令和历史对比数据见 [`docs/benchmarks/2026-08-18-wasm-gc-release.md`](docs/benchmarks/2026-08-18-wasm-gc-release.md)。这些结果用于同一机器和同一 workload 下的回归比较，不代表所有平台的绝对性能。

## 源码规模

统计 `.mbt` 文件时排除 `_build` 构建产物。

PowerShell：

```powershell
$files = Get-ChildItem -Recurse -File -Filter *.mbt | Where-Object { $_.FullName -notmatch '\\_build\\' }
($files | Get-Content | Measure-Object -Line).Lines
```

Linux/macOS：

```bash
find . -name '*.mbt' -not -path './_build/*' -print0 | xargs -0 cat | wc -l
```

当前统计为 7,804 行 MoonBit 源码，其中非测试源码 5,948 行、测试源码 1,856 行。测试覆盖核心算法、解析边界、跨窗口行为、Schema 变化、健康窗口重置、Checkpoint 单调性、DLQ 重试上限和真实 workload 回归。

## CI 与发布

- [`ci.yml`](.github/workflows/ci.yml)：在 Ubuntu、macOS 和 Windows 上安装 stable 工具链，执行全 target 的 check/test、格式检查和 `.mbti` 接口漂移检查。
- [`publish.yml`](.github/workflows/publish.yml)：手动触发的 Mooncakes 发布流程。发布前重新执行检查和测试，通过仓库 `MOONCAKES_TOKEN` secret 认证，不在日志中输出凭据。

## 模块信息

- Module：`zmjknn/moon-stream-quality`
- Version：`0.2.0`
- Preferred target：`wasm-gc`
- License：Apache License 2.0
- GitHub：<https://github.com/zmjknn/moon-stream-quality>
- Mooncakes：`zmjknn/moon-stream-quality`

## 相关文档

- [项目申报书](OSC2026_8月黑客松项目申报书.md)
- [结项设计与验收计划](docs/superpowers/plans/2026-08-18-stream-quality-acceptance.md)
- [验收自查报告](docs/acceptance/2026-08-18-self-review.md)
- [Apache License 2.0](LICENSE)

Git 提交历史中的贡献者为 `zmjknn`。项目采用 Apache License 2.0，具体条款见 [`LICENSE`](LICENSE)。
