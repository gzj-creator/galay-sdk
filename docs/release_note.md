# Release Note

按时间顺序追加版本记录，避免覆盖历史发布说明。

## v0.1.0 - 2026-04-22

- 版本级别：中版本（minor）
- Git 提交消息：`feat: 初始化源码聚合包`
- Git Tag：`v0.1.0`
- 自述摘要：
  - 初始化 `galay-sdk` 作为 `galay-*` 系列源码聚合包，统一收录 `galay-etcd`、`galay-http`、`galay-kernel`、`galay-mcp`、`galay-mongo`、`galay-mysql`、`galay-redis`、`galay-rpc`、`galay-ssl` 与 `galay-utils`。
  - 对具备 Git 历史的仓库统一按最高已发布 tag 导出源码，并记录精确 commit，保证聚合包可复现。
  - 新增 `manifest.json`、`README.md` 与版本文档，明确每个组件的来源版本和收录口径。
