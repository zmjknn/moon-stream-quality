# MoonBit 八月黑客松结项计划

## 目标

把 `zmjknn/moon-stream-quality` 完成到八月黑客松验收可提交状态：实现与申报书一致且有实际应用价值的功能扩展，补充真实可复现基准与边界测试，完善 README/CI/发布配置，完成本地与远程自查，并在账号核验后推送 GitHub 与 Mooncakes。

## 阶段

- [completed] 1. 现状、申报书、官方规则与自查项核对
- [completed] 2. 设计与用户确认
- [completed] 3. 实现功能扩展、基准与边界测试
- [completed] 4. README、CI、模块发布与验收文档完善
- [completed] 5. 格式化、接口、全目标测试、CLI check 与基准复测（native Windows runtime 限制已记录）
- [in_progress] 6. GitHub/Mooncakes 账号核验、提交与推送
- [pending] 7. 推送后远程默认分支/CI/包状态复核与最终自查

## 约束与成功标准

- 参赛项目是 2026 年 8 月黑客松，不使用 OSC 开源大赛文案作为项目定位。
- MoonBit 有效实现源码保持在 4k~10k 参考规模内；测试规模显著扩充但不靠生成物凑数。
- 规则、解析、流水线、报告和基准必须是可运行的真实功能，不能使用空壳或重复代码堆行数。
- 必须覆盖 `moon fmt --check`、`moon info`、`moon check --target all`、`moon test --target all`、CLI check 与可复现基准数据。
- GitHub 唯一贡献者使用账号创建者本人；推送前核查 GitHub 当前账号、远程 owner、默认分支与提交身份。
- Mooncakes 发布前核查 `moon.mod` namespace 与登录账号一致，禁止读取或复用历史缓存账号。

## 重要风险

- 当前 `gh auth status` 因 GitHub CLI 配置文件权限失败，需用不读取历史缓存的授权状态核验方式或请求授权。
- 当前 README 错误标注为 CCF 开源创新大赛；需改为 8 月黑客松。
- 申报书列出 4,110 行，但本地排除 `_build` 后统计为 4,943 行 `.mbt`（其中非测试 4,382、测试 561），需要 README 改成可审计的统计口径。
