# CHANGELOG

维护说明：
- 未打 tag 的改动先写入 `## [Unreleased]`。
- 需要发版时，从 `Unreleased` 或“自上次 tag 以来”的累计变更整理出新的版本节。
- 版本号遵循 `major/minor/patch` 规则：大改动升主版本，新功能升次版本，修复与非破坏性维护升修订版本。
- 推荐标题格式为 `## [vX.Y.Z] - YYYY-MM-DD`，正文按 `Added` / `Changed` / `Fixed` / `Docs` / `Chore` 归纳。

## [Unreleased]

## [v1.0.0] - 2026-04-24

### Added
- 新增 `tests/test_fetch_galay_repos.sh`，覆盖 `fetch_galay_repos.sh` 默认将组件仓库拉到 `galay-sdk/<repo>` 并自动 checkout 到 `manifest` 指定版本的行为。
- 为工作区模型切换补充实施设计与执行计划文档，明确 `galay-sdk` 仅保留版本矩阵、脚本与发布说明。

### Changed
- 将 `galay-sdk` 从“提交完整 `galay-*` 源码 bundle 的聚合仓库”重构为“只提交清单与工具脚本的工作区仓库”，移除版本控制中的顶层 `galay-*` 源码目录。
- 更新 `manifest.json` 的本地路径语义，统一使用工作区内的 `galay-sdk/<repo>` 目录作为本地 checkout 位置，并刷新 `galay-etcd`、`galay-http`、`galay-mcp`、`galay-mysql` 的 tag commit 记录。
- 将 `galay-mysql` 版本矩阵从 `v1.2.5` 升级到 `v1.2.6`，保证工作区抓取结果与当前发布 tag 对齐。
- 调整中英文 README，明确本地依赖抓取、忽略规则、导出 bundle 的新流程，以及 `fetch` / `sync` 的最新命令示例。

### Fixed
- `scripts/fetch_galay_repos.sh` 默认在工作区根目录内 clone/fetch 组件仓库，并默认 detach 到 `manifest` 指定版本；新增 `--no-checkout-version` 以支持只刷新 refs。
- `scripts/fetch_galay_repos.sh` 在 fetch 已存在仓库时改为强制同步远端 tags，修复远端同名 tag 被重打后再次抓取会触发 `would clobber existing tag` 的问题。
- `scripts/sync_bundle.sh` 改为必须显式传入 `--output` 导出目录，只生成独立源码包，不再清空或改写工作区内的本地 Git checkout。
- `tests/test_sync_bundle.sh` 增强为校验导出目录与工作区隔离，确保同步 bundle 时不会覆盖本地工作树或修改工作区内的 `manifest.json`。

## [v0.3.0] - 2026-04-23

### Added
- 新增 `scripts/install_galay_repos.sh`，可按 `manifest.json` 对 bundle 内全部 `galay-*` 组件批量执行 CMake configure/build/install，并支持 `--prefix`、`--jobs`、`--sudo` 与 `--dry-run` 参数。
- 新增 `scripts/fetch_galay_repos.sh`，可按 `manifest.json` 批量维护 sibling 源仓库（缺失时 clone，存在时 fetch），并支持按清单 `--checkout-version` 统一切换版本。
- 新增 `README-CN.md` 中文文档，补齐安装与抓取脚本的中文使用说明。

### Changed
- 安装脚本按依赖顺序优先构建 `galay-kernel`、`galay-utils`、`galay-http` 等基础组件，并自动注入 `CMAKE_PREFIX_PATH`，避免组件安装顺序导致的 `find_package` 失败。
- 安装默认前缀调整为仓库本地 `./.galay-prefix/latest`，减少系统全局旧版本 CMake 包配置对本次构建的干扰。
- 英文 `README.md` 补充中英文互链，以及安装/抓取脚本参数示例与依赖顺序说明。
- 同步 bundle 内 `galay-http`、`galay-etcd`、`galay-mysql`、`galay-mongo` 与 `galay-mcp` 的 CMake package 导出和依赖消费入口，统一为全小写 kebab-case 风格。
- 移除 bundle 内 `GalayEtcd` / `GalayMysql` 兼容配置模板，安装后只保留小写包名与小写 targets 文件。

### Fixed
- 将 `galay-kernel` 源码镜像从 `v3.4.4` 同步到 `v3.4.5`，补齐 `galay-http` 对内核 `3.4.5` 依赖的 bundle 版本矩阵。
- 为 `scripts/verify_bundle.sh` 增加 `galay-kernel` 依赖下界校验，提前拦截 bundle 内组件要求高于内置内核版本的漂移。
- 将 `galay-rpc` 源码镜像同步到 `v1.1.3`，统一默认仅在显式开启时构建测试目标。
- 补齐 bundle 内 `galay-rpc` 的 `config-version` 导出链路，修复下游按版本约束消费 `find_package(galay-rpc 1.1.2 REQUIRED CONFIG)` 时的兼容性判定失败。
- 将 `galay-etcd` 源码镜像同步到 `v1.1.8`，修复 `find_package(GalayEtcd CONFIG REQUIRED)` 无法自动发现安装包的问题。
- 为 bundle 内 `galay-etcd` 补齐 `GalayEtcd` 主入口与 `galay-etcd` 兼容入口，避免 verify 阶段继续卡在包配置查找失败。
- 将 `galay-utils` 源码镜像同步到 `v1.2.1`，修复 manifest 声明 `v1.2.0` 但镜像实际缺少 `config-version` 导出链路的漂移。
- 为 `scripts/verify_bundle.sh` 增加 `galay-utils` 源码版本与依赖下界校验，提前拦截 `galay-etcd` / `galay-redis` 等组件要求高于 bundle 内置 utils 版本的情况。

## [v0.2.2] - 2026-04-23

### Changed
- 将 `galay-http`、`galay-etcd`、`galay-mcp` 的源码镜像分别同步到 `v2.1.2`、`v1.1.7`、`v1.1.3`，统一默认仅在显式开启时构建测试目标。
- `galay-etcd` 镜像同时纳入 `GalayHttp 2.1.0` 依赖修正、发布文档和 `.gitignore` 收敛，保持 bundle 内源码与最新 source tag 一致。
- 刷新版本矩阵中的 source ref，并将 `VERSION`、`manifest.json`、`README.md` 的 bundle 版本统一对齐到 `v0.2.2`。

## [v0.2.1] - 2026-04-23

### Changed
- 同步 `galay-etcd`、`galay-http`、`galay-mongo` 与 `galay-mysql` 子目录中的源码包配置模板命名，统一改为小写 kebab-case 风格。
- 更新聚合仓库内对应 `CMakeLists.txt` 的模板路径，保持各组件安装导出的包配置文件名与外部消费契约不变。

## [v0.2.0] - 2026-04-22

### Added
- 新增 `scripts/sync_bundle.sh`，按 `manifest.json` 定义的版本矩阵同步 `galay-*` 源码快照。
- 新增 `scripts/verify_bundle.sh`，校验 bundle 版本一致性与源码目录边界。

### Changed
- 将 `manifest.json` 扩展为版本矩阵清单，补充 `source_type`、`repo`、`local_path` 与 `path` 字段。
- 将仓库定位从“一次性源码聚合包”收敛为“一个 `gdk` 版本对应一组 `galay-*` tag 集合”的源码发行仓库。
- 收紧源码过滤边界，额外排除编辑器缓存、benchmark 结果目录、日志文件与预编译 benchmark 二进制。

## [v0.1.0] - 2026-04-22

### Added
- 初始化 `galay-sdk` 聚合源码仓库，收录 `galay-*` 系列源码快照。
- 新增 `manifest.json`，记录每个被收录仓库的来源类型、发布版本与精确提交。

### Changed
- 对 Git 仓库统一按“最高已发布 tag”导出源码，避免混入未发版分支状态。
- 将 `galay-mongo` 作为本地 plain snapshot 一并收录，并在清单中单独标注来源口径。
