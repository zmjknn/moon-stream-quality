# 2026-08-18 MoonBit 8 月黑客松结项自查

## 结论

本地仓库已经按 8 月黑客松验收口径完成代码、测试、基准、README、许可证、CI 和发布配置补强。当前 `.mbt` 源码统计为 7,804 行（非测试 5,948 行，测试 1,856 行），低于 10,000 行上限；代码规模统计排除了 `_build` 构建产物。

## 验收项

| 项目 | 结果 | 证据 |
|---|---|---|
| MoonBit 格式 | 通过 | `moon fmt --check` |
| 静态检查 | 通过 | `moon check --deny-warn --target all` |
| wasm 测试 | 125/125 | `moon test --deny-warn --target all` |
| wasm-gc 测试 | 125/125 | `moon test --deny-warn --target all` |
| js 测试 | 125/125 | `moon test --deny-warn --target all` |
| native 测试 | 当前 Windows 环境受阻 | MoonBit runtime `env.c` 调用 `rand_s` 时被本机 C 编译器报告隐式声明错误 |
| CLI | 通过 | `moon run --target wasm-gc src/cli` |
| 实测基准 | 通过 | `moon bench src/benchmark --target wasm-gc --release --deny-warn` |
| CI | 已补齐 | Ubuntu/macOS/Windows；全 target check/test、fmt/info 漂移检查 |
| Mooncakes 发布 | 已配置 | 手动 `publish.yml`，使用 `MOONCAKES_TOKEN` secret |
| 许可证 | 已确认 | `LICENSE`，Apache-2.0 |
| 默认分支 | 待远程推送后复核 | 目标为 `main` |
| 唯一贡献者 | 待最终推送前复核 | 本地历史需全部核对为 `zmjknn` |

## 真实基准

在 Windows、`moon 0.1.20260807`、`moonc v0.10.7`、`wasm-gc`、`--release` 下，最新一次运行均值为：JSONL reader 2.82 µs，传感器质量流水线 55.81 µs，交易质量流水线 224.63 µs。标准差、范围和运行次数见 [`docs/benchmarks/2026-08-18-wasm-gc-release.md`](../benchmarks/2026-08-18-wasm-gc-release.md)。

## 工具链说明

当前本地编译器已经是 `moonc v0.10.7+bc794d341 (2026-08-11)`。官方 `moon upgrade` 在本次非交互终端中返回 `IO error: not a terminal`，官方 PowerShell 安装器随后因网络传输 `unexpected EOF` 未完成刷新；因此没有把失败的下载结果当作升级成功。CI 使用官方 stable 安装脚本，每次运行会打印 `moon version --all`。

## 推送前剩余动作

1. 使用授权 API 核对 GitHub 当前登录账号、仓库 owner 和默认分支，不读取历史缓存账号文件。
2. 使用 MoonBit 支持的发布/登录状态路径核对 Mooncakes namespace 为 `zmjknn`。
3. 提交最终文档与生成接口，推送 GitHub 和 GitLink 的 `main`，执行手动 Mooncakes 发布。
4. 推送后复查远程 CI、默认分支、提交者和包版本。
