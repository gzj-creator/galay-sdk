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

## v0.2.0 - 2026-04-22

- 版本级别：中版本（minor）
- Git 提交消息：`feat: 发布 galay-sdk v0.2.0`
- Git Tag：`v0.2.0`
- 自述摘要：
  - 将 `galay-sdk` 的对外语义收敛为“一个 `gdk` 版本对应多个 `galay-*` tag 集合”的版本矩阵源码发行仓库。
  - 新增 `scripts/sync_bundle.sh` 与 `scripts/verify_bundle.sh`，补齐源码同步、内容过滤与 bundle 校验自动化。
  - 扩展 `manifest.json` 字段，补充来源仓库、局部工作区路径与目标目录信息，并收紧编辑器缓存、benchmark 结果、日志与预编译二进制的过滤边界。

## v0.2.1 - 2026-04-23

- 版本级别：小版本（patch）
- Git 提交消息：`chore: 发布 v0.2.1`
- Git Tag：`v0.2.1`
- 自述摘要：
  - 同步 `galay-etcd`、`galay-http`、`galay-mongo` 与 `galay-mysql` 子目录中的源码包配置模板命名，统一收敛为小写 kebab-case 风格。
  - 更新聚合仓库内对应 `CMakeLists.txt` 的模板输入路径，继续保持各组件安装导出的包配置文件名与外部消费契约兼容不变。

## v0.2.2 - 2026-04-23

- 版本级别：小版本（patch）
- Git 提交消息：`chore: 同步最新组件 tag 矩阵`
- Git Tag：`v0.2.2`
- 自述摘要：
  - 将 `VERSION`、`manifest.json` 与 `README.md` 的 bundle 版本统一对齐到 `v0.2.2`，修正当前版本矩阵显示与 source ref 记录。
  - 将 `galay-http`、`galay-etcd`、`galay-mcp` 的源码镜像分别同步到 `v2.1.2`、`v1.1.7`、`v1.1.3`，统一默认仅在显式开启时构建测试目标。
  - `galay-etcd` 镜像继续纳入 `GalayHttp 2.1.0` 依赖修正与收紧后的忽略规则，保持 bundle 内源码和最新 source tag 对齐。
