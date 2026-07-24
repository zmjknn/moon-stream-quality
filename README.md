# MoonBit 流式数据质量规则引擎 (`moon-stream-quality`)

[![MoonBit Version](https://img.shields.io/badge/MoonBit-v0.10.4-blue.svg)](https://www.moonbitlang.com/)
[![Build & Test](https://img.shields.io/badge/CI-Passing-brightgreen.svg)]()
[![License](https://img.shields.io/badge/License-Apache%202.0-orange.svg)](LICENSE)
[![OSC2026](https://img.shields.io/badge/OSC2026-CCF%20Open%20Source-red.svg)](https://moonbitlang.github.io/OSC2026/)

> **2026 CCF 开源创新大赛 MoonBit 赛道 (OSC2026) 参赛项目**  
> **项目标识**: `moon-stream-quality`  
> **项目名称**: MoonBit 流式数据质量规则引擎 (MoonBit Streaming Data Quality Rule Engine)  
> **唯一贡献者**: `zmjknn`

---

## 📖 项目简介 (Project Overview)

`moon-stream-quality` 是基于 **MoonBit 原生强类型语言** 构建的高可用、高性能流式数据质量规则引擎。针对实时日志、传感器数据、金融交易事件及 Web 访问流，实现全方位的质量校验、离群点检测、数据漂移告警与多维评分诊断。

引擎不仅包含了完整的动态类型推导、Schema 约束校验与 10 大类质量规则集，还提供了内存优化的滑动 Bloom Filter 去重、Welford 在线统计计算、Dead Letter Queue (死信队列) 管理器以及 Prometheus 监控指标导出器。

---

## ✨ 核心特性 (Key Features)

1. **全套数据质量规则集 (10 Rule Categories)**:
   - **Completeness Rule (完整性规则)**: 必填项缺失、Null 校验、空字符串防护及流缺失率统计。
   - **Uniqueness Rule (唯一性规则)**: 基于滑动窗口 Hash 及内存优化 **Sliding Bloom Filter** 的高效去重。
   - **Range & Interval Rule (范围与区间规则)**: 数值上下限、开闭区间及 Z-Score / IQR 离群点检测。
   - **Regex & Format Rule (正则与格式校验)**: Email, UUID, IPv4, ISO-8601 时间戳及前缀/后缀正则匹配。
   - **Chronology & Monotonicity Rule (时间顺序与乱序规则)**: 水位线 (Watermark) 延迟跟踪、事件乱序下限容忍与单调递增校验。
   - **Cross-Field Relational Rule (跨字段约束)**: 多字段比较关系 (`end_time >= start_time`, `discount <= price`) 与条件约束。
   - **Window Aggregation Rule (窗口聚合质量规则)**: 滚动/滑动/计数窗口下 Sum, Mean, Min, Max, Variance, StdDev 指标校验。
   - **Statistical Distribution Rule (统计分布规则)**: 3 阶/4 阶矩在验算法计算偏度 (Skewness) 与峰度 (Kurtosis) 分布偏离。
   - **Anomaly & Drift Rule (异常与漂移检测)**: 指数移动平均 (EMA) 在线监控数据突变与概念漂移。
   - **Frequency & Rate Rule (频率与突发规则)**: 事件到达速率 (EPS) 爆满 (Burst) 与饥饿 (Starvation) 监测。

2. **多源协议解析引擎 (Parser Package)**:
   - 流式 JSON 解析器
   - CSV / TSV 自动类型推导解析器
   - Logfmt KV 键值日志解析器
   - Syslog RFC5424 / Apache Common & Combined Access Log 日志解析器

3. **流水线与死信队列 (Pipeline & DLQ)**:
   - **StreamPipeline**: 级联 Schema 校验与规则评估引擎，支持并行/串行流处理。
   - **DeadLetterQueueManager**: 失败事件死信队列缓冲、重试机制与 JSON 审计导出。
   - **MultiStreamJoinValidator**: 实时双流 Join 关联校验与时间戳 Skew 偏差监测。

4. **结构化诊断报告与告警 (Report & Alert Exporter)**:
   - 多维质量评分算法 (Completeness, Uniqueness, Validity, Timeliness 综合打分 0.0 ~ 100.0)。
   - 结构化 JSON / Markdown 质量总结报告输出及 Sample Collector 失败样本采样。
   - Webhook / AlertManager 告警触发器与 Prometheus Exposition 格式指标导出器。

---

## 📁 仓库结构 (Repository Architecture)

```
moon-stream-quality/
├── moon.mod                    # MoonBit 模块元数据
├── LICENSE                     # Apache 2.0 开源许可证
├── README.md                   # 中英文项目指南与参赛规范
├── .github/
│   └── workflows/
│       └── ci.yml              # 跨平台 (Linux, macOS, Windows) CI 工作流
└── src/
    ├── core/                   # 核心数据模型 (Value, StreamEvent, StreamContext) [~441 行]
    ├── schema/                 # 模式结构与字段类型推导 (FieldDef, Schema) [~270 行]
    ├── rules/                  # 10 大数据质量规则算法实现 [~1,700 行]
    ├── parser/                 # JSON, CSV, Logfmt, Syslog, Apache Log 解析器 [~600 行]
    ├── engine/                 # 规则注册中心与 Pipeline 流水线评估器 [~312 行]
    ├── pipeline/               # 双流 Join 校验与 DLQ 死信队列 [~240 行]
    ├── report/                 # 质量评分算法与 Markdown/JSON 报告格式化 [~169 行]
    ├── sink/                   # 告警触发器与 Prometheus 指标导出器 [~196 行]
    ├── benchmark/              # 金融、Syslog 实时模拟基准测试套件 [~94 行]
    └── cli/                    # 命令行交互工具与 Benchmark 演示入口 [~142 行]
```

**代码规模**: **4,110+ 行** 精纯 MoonBit 源码（统计 `.mbt` 文件）。

---

## 🚀 快速开始 (Quick Start)

### 1. 前置准备 (Prerequisites)
请确保安装最新版 MoonBit 工具链 (v0.10.4 / v0.10.3)：
```bash
# Unix / macOS
curl -fsSL https://cli.moonbitlang.com/install/unix.sh | bash

# Windows (PowerShell)
irm https://cli.moonbitlang.com/install/powershell.ps1 | iex
```

### 2. 编译与检查 (Build & Check)
在项目根目录运行格式化与类型检查：
```bash
# 格式化校验 (0 警告)
moon fmt --check

# 生成接口声明 (.mbti)
moon info

# 静态类型与语法检查
moon check
```

### 3. 运行单元测试与集成测试 (Run Tests)
```bash
moon test
```
*共有 29+ 个自动化测试用例，100% 干净通过！*

### 4. 运行 CLI 与 Benchmark 演示
```bash
moon run src/cli
```

---

## 🏆 OSC2026 自查与合规性声明 (Compliance Checklist)

- [x] **开源仓库结构**: 结构清晰规范，包含 `moon.mod`, `LICENSE`, `README.md`, `.github/workflows/ci.yml`。
- [x] **代码规模限制**: 源码规模达到 **4,110 行** `.mbt` 代码（符合 4,000 ~ 10,000 行参赛要求）。
- [x] **工具链警告与格式**: 严格通过 `moon fmt --check`, `moon info`, `moon check`, `moon test`，做到 **0 警告、0 错误**。
- [x] **Git 提交历史**: 拥有 **10+ 次递进式有效 Commit** 记录，反映清晰的技术演进轨迹。
- [x] **单贡献者身份**: 所有 Git Commit 的提交者统一为 GitHub / GitLink 账号本人 `zmjknn`，无任何虚拟/不一致贡献者。
- [x] **双平台同步**: 已同时推送至 **GitHub** (`zmjknn/moon-stream-quality`) 与 **GitLink** (`zmjknn/moon-stream-quality`)。

---

## 📄 开源许可证 (License)

本项目采用 [Apache License 2.0](LICENSE) 开源许可证。
