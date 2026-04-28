# Release Note

按时间顺序追加版本记录，避免覆盖历史发布说明。

## v1.0.1 - 2026-04-26

- 版本级别：小版本（patch）
- Git 提交消息：`chore: 发布 v1.0.1 版本矩阵更新`
- Git Tag：`v1.0.1`
- 自述摘要：
  - 新增 `AGENTS.md` 与仓库级 `CLAUDE.md`，统一约束“检查”“更新”等提交流程必须先核对各仓库最新版本，并按 `commit_change` skill 处理 `VERSION`、tag 与发布文档。
  - 收束 `v1.0.0` 之后的抓取流程改动：`scripts/fetch_galay_repos.sh` 改为强制要求非空 `version`，并对已存在仓库按指定版本浅拉取、对缺失仓库按指定版本浅克隆；同时将 `galay-mongo` 的清单版本修正为远端实际存在的 `v1.1.2`。
  - 将 bundle 版本从 `v1.0.0` 升级到 `v1.0.1`，同步更新 `VERSION`、`manifest.json`、`README.md` 与 `README-CN.md` 中的版本号和发布日期。
  - 将版本矩阵中的 `galay-http` 从 `v2.1.2` 升级到 `v2.1.3`、`galay-kernel` 从 `v3.4.5` 升级到 `v3.4.6`，对齐当前远端最新已发布 tag。

## v1.0.0 - 2026-04-24

- 版本级别：大版本（major）
- Git 提交消息：`refactor: 将galay-sdk切换为清单工作区`
- Git Tag：`v1.0.0`
- 自述摘要：
  - 将 `galay-sdk` 从直接提交完整 `galay-*` 源码快照的聚合仓库，重构为只提交版本矩阵、脚本、文档与发布记录的清单工作区，并从版本控制中移除顶层 `galay-*` 源码目录。
  - 调整 `manifest.json`、`.gitignore` 与中英文 README，统一本地 checkout 目录为 `galay-sdk/<repo>`，刷新 `galay-etcd`、`galay-http`、`galay-mcp`、`galay-mysql` 的 tag commit 记录，并将 `galay-mysql` 升级到 `v1.2.6`。
  - 重写 `scripts/fetch_galay_repos.sh` 的默认行为：抓取落地到工作区内、默认 checkout 到清单版本，并在 fetch 时强制同步远端 tags，修复 tag 重打后会报 `would clobber existing tag` 的问题。
  - 重写 `scripts/sync_bundle.sh` 的输出边界：必须显式传入 `--output` 导出目录，只生成独立源码包而不再改写工作区；同时新增 `tests/test_fetch_galay_repos.sh` 并强化 `tests/test_sync_bundle.sh`，覆盖新工作流的关键回归场景。

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

## v0.3.0 - 2026-04-23

- 版本级别：中版本（minor）
- Git 提交消息：`feat: 增加仓库抓取与依赖有序安装脚本`
- Git Tag：`v0.3.0`
- 自述摘要：
  - 新增 `scripts/install_galay_repos.sh`，支持按 `manifest.json` 对 bundle 内所有 `galay-*` 组件批量执行 CMake configure/build/install，并提供 `--prefix`、`--jobs`、`--sudo`、`--dry-run` 参数。
  - 安装流程新增依赖顺序和 `CMAKE_PREFIX_PATH` 注入机制，默认安装前缀改为 `./.galay-prefix/latest`，修复 `galay-etcd` 先于 `galay-http` 安装时的 `find_package` 依赖命中问题。
  - 新增 `scripts/fetch_galay_repos.sh` 用于批量 clone/fetch sibling 源仓库并可按清单版本切换，同时补齐 `README.md` 与 `README-CN.md` 双语文档入口与使用示例。
  - 收束此前未发版累计变更：同步多组件 CMake 包导出命名到小写 kebab-case、补齐 `verify_bundle.sh` 依赖下界校验，并完成 `galay-kernel`/`galay-rpc`/`galay-etcd`/`galay-utils` 版本矩阵修复。

## v2.0.0 - 2026-04-29

- 版本级别：大版本（major）
- Git 提交消息：`refactor: 统一源码文件命名规范`
- Git Tag：`v2.0.0`
- 自述摘要：
  - 将源码、头文件、测试、示例与 benchmark 文件统一重命名为 lower_snake_case，编号前缀同步改为小写下划线形式。
  - 同步更新 CMake/Bazel 构建描述、模块入口、README/docs、脚本和所有项目内 include 路径引用。
  - 移除项目内相对 include，统一使用基于公开 include 根或模块根的非相对路径。
