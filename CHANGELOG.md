# CHANGELOG

维护说明：
- 未打 tag 的改动先写入 `## [Unreleased]`。
- 需要发版时，从 `Unreleased` 或“自上次 tag 以来”的累计变更整理出新的版本节。
- 版本号遵循 `major/minor/patch` 规则：大改动升主版本，新功能升次版本，修复与非破坏性维护升修订版本。
- 推荐标题格式为 `## [vX.Y.Z] - YYYY-MM-DD`，正文按 `Added` / `Changed` / `Fixed` / `Docs` / `Chore` 归纳。

## [Unreleased]

### Fixed
- 将 `galay-kernel` 源码镜像从 `v3.4.4` 同步到 `v3.4.5`，补齐 `galay-http` 对内核 `3.4.5` 依赖的 bundle 版本矩阵。
- 为 `scripts/verify_bundle.sh` 增加 `galay-kernel` 依赖下界校验，提前拦截 bundle 内组件要求高于内置内核版本的漂移。
- 将 `galay-rpc` 源码镜像同步到 `v1.1.3`，统一默认仅在显式开启时构建测试目标。
- 补齐 bundle 内 `galay-rpc` 的 `config-version` 导出链路，修复下游按版本约束消费 `find_package(galay-rpc 1.1.2 REQUIRED CONFIG)` 时的兼容性判定失败。

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
