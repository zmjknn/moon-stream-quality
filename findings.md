# 调研与现状发现

## 本地仓库

- 根目录包含 `moon.mod`、`LICENSE`、`README.md`、`.github/workflows/ci.yml`，源码在 `src/` 下分为 core/schema/rules/parser/engine/pipeline/report/sink/benchmark/cli。
- `_build/` 已存在但由构建生成；源码统计必须排除它。
- `src/` 下共有 4,943 行 `.mbt`：非测试 4,382 行，测试 561 行。申报书与 README 的 4,110 行旧数字不准确。
- 当前本地分支 `main` 与 `origin/main` 同步；`git remote show origin` 显示远程默认分支是 `main`。
- Git 历史有 18 个提交，提交者均显示为 `zmjknn <zmjknn@users.noreply.github.com>`；GitLink remote 也存在。
- 当前 `moon version` 为 `moon 0.1.20260807 (4da23f8 2026-08-07)`。自查 skill 的环境建议是低于 0.10.7 时提示升级，因此需重新安装 latest stable 并记录实际版本。
- 基线：`moon fmt --check` exit 0；`moon check --deny-warn` exit 0；`moon test --deny-warn` 为 29/29 通过。`moon test --target all` 已报告 wasm/wasm-gc/js 29/29，需复跑并确认 native/all 的完整退出状态。

## 申报书承诺

- 项目是 `MoonBit 流式数据质量规则引擎`，定位于实时日志、传感器、金融交易事件和 Web 访问流质量校验。
- 计划覆盖多格式解析、动态 Schema、10 类流式规则、双流 Join、DLQ、质量报告、Prometheus 与告警。
- 需要结项时重点证明在线统计、乱序/水位线、窗口聚合、漂移/异常、双流 skew、重试审计和基准可复现。

## 公开自查规则（来自 Milky2018/osc2026-guide）

- 八月黑客松提交重点是公开 GitHub 仓库；需核对默认分支、README、LICENSE、CI、可运行示例、测试、Mooncakes 发布、贡献者与提交历史。
- 验收硬标准包括有效 MoonBit 项目、`moon check`/`moon test`、八月黑客松 CI、已发布 Mooncakes、清晰许可证、干净仓库、真实功能、可运行入口和与申报书基本一致。
- 有效规模接近或超过 4k 是正向信号但不能靠代码堆积；需关注 AI 辅助内容的可解释性、可测试性、维护性、来源与许可证。
- 申报书需约一页 Markdown，并覆盖已有基础、计划/完成工作、技术方案、功能、测试、文档和来源说明。

## CI 参考

- `moonbit-community/.github/workflow-templates/check.yml` 建议三平台，安装工具链后执行 `moon version --all`、`moon update`、`moon check --target all`、`moon test --target all`、`moon fmt`/`moon info` 后 `git diff --exit-code`。
- 参考的 `PaiGack/moonbitlang-OSC2026` workflow 还包含 `--deny-warn`、coverage summary 和 native 测试；需结合本项目依赖与平台支持决定是否加入。
- 当前仓库已有三平台 CI，但缺少 `--target all`、`--deny-warn`、格式/接口 diff 门禁、coverage、publish workflow，且 README badge 为空链接。

## 网络核对状态

- Firecrawl CLI 未安装，已回退到网页读取能力。
- 已读取 `osc2026-guide/SKILL.md` 与 MoonBit 社区 check/publish workflow 模板。
- 官方比赛页面通过网页工具直接打开时被安全策略拒绝，需以用户提供的申报书、自查 skill 公开规则与可访问的官方搜索结果为依据，并在 README 中避免无证据的 OSC 赛事实体化表述。
