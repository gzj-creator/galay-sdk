# GDK Version Matrix Design

## 背景

`galay-sdk` 当前已经具备“聚合多个 `galay-*` 源码目录”的基本形态，但它的仓库定位仍偏向一次性源码快照。对外口径需要收敛为：

- `galay-sdk` 是独立仓库
- `gdk` 版本代表一组经过确认的 `galay-*` tag 集合
- 用户 `clone` 或下载指定 `gdk` tag 后，拿到的是全量源码，不包含构建副产物、缓存目录与上游 `.git` 历史

这个仓库管理的是“兼容版本矩阵”，不是“统一开发分支”，也不是“二进制制品仓库”。

## 目标

- 用一个独立的 `gdk` 版本表达一组稳定的 `galay-*` 组件版本。
- 让 `gdk` 成为源码发行入口，而不是多个仓库引用入口。
- 保证任意一个 `gdk` tag 都能完整复现对应源码集合。
- 把版本选择、源码同步、内容校验和发版动作流程化，避免人工漏项。

## 非目标

- 不在当前阶段把 `gdk` 变成统一 super-build 仓库。
- 不使用 submodule 让用户二次初始化子仓库。
- 不存储预编译二进制、安装前缀、缓存或本地构建目录。
- 不要求所有 `galay-*` 仓库使用统一版本号。

## 方案比较

### 方案 A: Git Submodule 聚合

做法：
- `gdk` 顶层只保存子仓库引用
- 每个 `galay-*` 通过 submodule 固定到一个 commit

优点：
- 上游引用关系清晰
- 更新某个组件时只需要移动 submodule 指针

缺点：
- 用户拿到仓库后不是全量源码，仍需 `submodule update --init --recursive`
- 容易出现引用未拉取、浅克隆、镜像代理等环境问题
- 发行物本质是“仓库指针集合”，不是“源码整包”

结论：
- 不满足“下载下来就是全量源码”的核心目标

### 方案 B: Git Subtree / 长期合并上游

做法：
- 把多个上游仓库通过 subtree 或等价手段并入单仓库
- 持续保留部分上游同步关系

优点：
- 用户拿到的是完整源码
- 理论上可以保留部分上游合并轨迹

缺点：
- 同步历史和冲突处理复杂
- 仓库噪音大，长期维护成本高
- 对当前“发行快照”目标来说保留历史价值不高

结论：
- 比 submodule 更接近目标，但维护成本不必要地高

### 方案 C: 源码快照发行仓库

做法：
- `gdk` 顶层直接提交每个 `galay-*` 目录的源码快照
- 用 `manifest.json` 记录版本矩阵、来源仓库、tag、commit、来源类型
- 每次发版通过脚本从上游 tag 导出源码并覆盖更新

优点：
- 用户拿到的就是完整源码
- `gdk tag` 可以直接作为“版本矩阵快照”
- 不依赖 submodule，不暴露上游 `.git` 元数据
- 易于做内容过滤、完整性校验和发版审计

缺点：
- 仓库体积会随着源码快照增长
- 需要单独维护同步脚本和清单格式

结论：
- 这是当前最匹配需求的方案，也是推荐方案

## 推荐设计

### 仓库角色

`galay-sdk` 定义为“源码发行仓库”：

- 顶层直接保存各个 `galay-*` 的源码目录
- 不保存上游 Git 历史
- 不在顶层引入统一构建系统作为发布前提
- 通过顶层元数据描述当前 `gdk` 版本绑定的组件矩阵

### 版本模型

一个 `gdk` 版本对应一组固定组件版本：

```text
gdk/v0.3.0
  -> galay-kernel@v3.4.4
  -> galay-http@v2.0.2
  -> galay-rpc@v1.1.2
  -> galay-redis@v1.2.2
  -> ...
```

版本规则建议：

- `major`: 版本矩阵有明显不兼容重组，或者收录结构发生破坏性变化
- `minor`: 新增组件、移除组件、或较大范围升级多个组件
- `patch`: 调整单个或少量组件 tag、修正文档、修复同步问题

`gdk` 版本号独立维护，不与任一子库版本绑定。

### 元数据模型

保留并扩展顶层 `manifest.json`，作为版本矩阵的机器可读真源。每个来源至少包含：

- `name`: 组件名，例如 `galay-http`
- `source_type`: `git-tag-archive` 或 `local-snapshot`
- `repo`: 上游仓库地址或本地来源描述
- `version`: 选定 tag，例如 `v2.0.2`
- `commit`: 解析后的精确 commit
- `path`: 导入到 `gdk` 内的目录名
- `captured_at`: 对本地快照类来源记录采集时间

示意：

```json
{
  "bundle_name": "galay-sdk",
  "bundle_version": "v0.3.0",
  "release_date": "2026-04-22",
  "sources": [
    {
      "name": "galay-http",
      "source_type": "git-tag-archive",
      "repo": "git@.../galay-http.git",
      "version": "v2.0.2",
      "commit": "3fdf5bf442e781370b51170c8c6dcc3aa62e5559",
      "path": "galay-http"
    }
  ]
}
```

`VERSION` 保存当前 `gdk` 版本号，`CHANGELOG.md` 和 `docs/release_note.md` 负责人类可读变更说明。

### 目录结构

建议保留以下顶层结构：

```text
galay-sdk/
  README.md
  VERSION
  CHANGELOG.md
  manifest.json
  docs/
    release_note.md
    plans/
  scripts/
    sync_bundle.sh
    verify_bundle.sh
    lib/
      common.sh
      filters.sh
  galay-etcd/
  galay-http/
  galay-kernel/
  galay-mcp/
  galay-mongo/
  galay-mysql/
  galay-redis/
  galay-rpc/
  galay-ssl/
  galay-utils/
```

原则：

- 组件目录直接落在顶层，便于浏览和归档
- 顶层只保留最少必要的元数据和自动化脚本
- 不引入统一 `build/`、`install/`、`.cache/` 之类目录

### 同步流程

推荐把“更新某个 `gdk` 版本矩阵”的动作固定为以下步骤：

1. 修改 `manifest.json` 中的目标组件版本集合。
2. 执行 `scripts/sync_bundle.sh --manifest manifest.json`。
3. 脚本逐项读取来源定义：
   - `git-tag-archive`: 对指定 tag 做 `git archive` 或等价导出
   - `local-snapshot`: 复制指定本地目录
4. 导出前先清空目标组件目录，再写入新快照。
5. 统一过滤非源码副产物：
   - `.git`
   - `.DS_Store`
   - `build/`, `build-*`
   - `dist/`, `target/`, `tmp/`
   - 本地日志与缓存目录
6. 同步完成后刷新 `manifest.json` 中的 `commit`、`captured_at`、`release_date` 等字段。

### 校验流程

同步后必须运行显式校验脚本，例如 `scripts/verify_bundle.sh`，至少检查：

- `manifest.json` 中每个组件目录都真实存在
- 每个 `git-tag-archive` 来源的 commit 与 tag 解析一致
- 仓库中不存在 `.git`、`build/`、`target/` 等禁止内容
- `VERSION`、`manifest.json.bundle_version`、`README.md` 展示内容保持一致
- `CHANGELOG.md` 至少包含当前待发布矩阵变更摘要

### 发版流程

推荐流程：

1. 选定一组兼容的 `galay-*` tag
2. 更新 `manifest.json`
3. 运行同步脚本
4. 运行校验脚本
5. 更新 `VERSION`
6. 维护 `CHANGELOG.md` 与 `docs/release_note.md`
7. 提交本次矩阵更新
8. 打 `gdk/vX.Y.Z` tag

`gdk` 的值在于“确认过的一组组合”，因此不建议做“任何上游一出 tag 就自动更新”的全自动跟随。

### 内容边界

保留：

- 头文件、源文件、模块文件
- 示例、测试、benchmark、docs 等源码或文档内容
- 组件自身的构建描述文件，例如 `CMakeLists.txt`、`WORKSPACE`

排除：

- 构建输出
- 安装前缀
- 包管理缓存
- 本地机器临时文件
- 上游 `.git` 与 CI 运行时产物

## 风险与约束

- 仓库体积增长是必然代价，需要用明确过滤规则控制无效内容。
- `local-snapshot` 来源的可重现性低于 tag 来源，建议后续尽量把此类组件也纳入 Git tag 流程。
- 如果未来要提供统一接入体验，可以追加“辅助构建入口”，但应作为额外能力，而不是当前仓库定义的一部分。

## 结论

`galay-sdk` 最合适的定位是：

- 一个独立维护的源码发行仓库
- 一个 `gdk` 版本对应一组 `galay-*` tag 集合
- 仓库直接提交全量源码快照
- 通过 `manifest.json + sync/verify 脚本 + changelog/tag` 维持持续更新

这能同时满足“持续更新”“全量源码可直接下载”“没有多余副产物”“版本集合稳定可复现”四个核心要求。
