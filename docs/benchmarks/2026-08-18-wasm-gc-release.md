# 可复现基准记录（2026-08-18）

本记录来自真实 `moon bench` 输出，不是代码中的估算吞吐率。结果用于比较同一机器、同一工具链和同一 workload 配置下的回归趋势，不代表所有平台的绝对性能。

## 环境

- 日期：2026-08-18
- 操作系统：Windows（当前开发机）
- Moon：`moon 0.1.20260807 (4da23f8 2026-08-07)`
- Moonc：`v0.10.7+bc794d341 (2026-08-11)`
- target：`wasm-gc`
- 优化：`--release`
- workload：固定 JSONL 两行、传感器 120 事件、交易 120 事件；缺陷周期写在 `WorkloadSpec` 中。

## 命令

```powershell
moon bench src/benchmark --target wasm-gc --release --deny-warn
```

## 第二次完整运行结果

| Benchmark | Mean | Standard deviation | Range | Runs |
|---|---:|---:|---:|---:|
| `jsonl_reader` | 2.82 µs | 80.04 ns | 2.72–2.94 µs | 10 × 35,775 |
| `sensor_quality_pipeline` | 55.81 µs | 1.11 µs | 54.31–57.55 µs | 10 × 1,730 |
| `transaction_quality_pipeline` | 224.63 µs | 31.11 µs | 142.12–254.37 µs | 10 × 1,431 |

MoonBit benchmark runner 的统计输出为：

```text
name                         time (mean ± σ)         range (min … max)
jsonl_reader                    2.82 µs ±  80.04 ns     2.72 µs …   2.94 µs  in 10 ×  35775 runs
sensor_quality_pipeline        55.81 µs ±   1.11 µs    54.31 µs …  57.55 µs  in 10 ×   1730 runs
transaction_quality_pipeline  224.63 µs ±  31.11 µs   142.12 µs … 254.37 µs  in 10 ×   1431 runs
Total tests: 1, passed: 1, failed: 0.
```

## 解释与复测建议

- `jsonl_reader` 测量结构化 JSONL 解析和错误恢复入口；`sensor_quality_pipeline`、`transaction_quality_pipeline` 测量解析后进入窗口、规则、健康观测和报告计数的完整路径。
- 同一命令此前两次运行的均值分别为 2.53/55.92/240.02 µs 和 2.49/55.65/235.65 µs；本次结果更新为最新一次完整运行，说明交易 workload 的运行时抖动明显高于 JSONL reader，应在同一机器上重复多次再比较优化收益。
- 当前 Windows C/native release 构建在 MoonBit runtime 的 `rand_s` 声明处失败，因此没有伪造 native 数字；本次验收记录使用成功的 `wasm-gc` release target。CI 仍保留全目标检查，native 问题作为工具链/runner 环境项单独跟踪。
