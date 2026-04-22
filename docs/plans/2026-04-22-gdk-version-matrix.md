# GDK Version Matrix Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** 把 `galay-sdk` 固化为“一个 `gdk` 版本对应多个 `galay-*` tag 集合”的源码发行仓库，并补齐最小可用的同步与校验自动化。

**Architecture:** 顶层继续直接保存各组件源码快照，不引入 submodule。用 `manifest.json` 表达版本矩阵，`scripts/sync_bundle.sh` 负责拉取和覆盖导出，`scripts/verify_bundle.sh` 负责检查内容边界与版本一致性，`README.md`/`CHANGELOG.md`/`docs/release_note.md` 负责对外说明。

**Tech Stack:** Git, POSIX shell, JSON manifest, existing `galay-*` source trees

---

### Task 1: 规范顶层元数据

**Files:**
- Modify: `README.md`
- Modify: `VERSION`
- Modify: `manifest.json`
- Modify: `CHANGELOG.md`
- Modify: `docs/release_note.md`

**Step 1: 写出失败检查清单**

把以下检查项写入临时核对表或 issue：

- `README.md` 仍把仓库描述成一次性快照，而不是版本矩阵发行仓库
- `manifest.json` 缺少 `repo`/`path`/`source_type` 等规范字段
- `VERSION` 与 `manifest.json.bundle_version` 不一致时无检查手段

**Step 2: 手动验证当前状态确实不满足目标**

Run:

```bash
git -C galay-sdk diff -- README.md VERSION manifest.json CHANGELOG.md docs/release_note.md
```

Expected:
- 看到这些文件尚未完整表达“版本矩阵发行仓库”的语义

**Step 3: 最小化修改元数据**

实施内容：

- 在 `README.md` 中明确：
  - `gdk tag = galay-* tag 集合`
  - 仓库只发布源码，不包含构建副产物
- 在 `manifest.json` 中补齐每个来源的规范字段
- 让 `VERSION` 与 `manifest.json.bundle_version` 明确绑定
- 在 `CHANGELOG.md` 和 `docs/release_note.md` 中记录仓库定位变更

**Step 4: 重新检查文件一致性**

Run:

```bash
sed -n '1,220p' galay-sdk/README.md
sed -n '1,220p' galay-sdk/manifest.json
cat galay-sdk/VERSION
```

Expected:
- 文案、版本号、矩阵定义一致

**Step 5: Commit**

```bash
git -C galay-sdk add README.md VERSION manifest.json CHANGELOG.md docs/release_note.md
git -C galay-sdk commit -m "docs: define gdk version-matrix metadata"
```

### Task 2: 增加源码同步脚本

**Files:**
- Create: `scripts/sync_bundle.sh`
- Create: `scripts/lib/common.sh`
- Create: `scripts/lib/filters.sh`

**Step 1: 先写失败场景**

定义一个最小 smoke case：

- 读取 `manifest.json`
- 对某个 `git-tag-archive` 来源解析失败时退出非零
- 对目标目录覆盖前未清理旧内容时判为失败

把这些场景写进脚本注释或单独的测试草稿中。

**Step 2: 用空脚本验证当前仓库无同步入口**

Run:

```bash
test -x galay-sdk/scripts/sync_bundle.sh
```

Expected:
- 非零退出，说明同步脚本尚不存在

**Step 3: 实现最小同步能力**

脚本需要做到：

- 读取 `manifest.json`
- 对 `git-tag-archive` 来源执行 tag 导出
- 对 `local-snapshot` 来源执行目录复制
- 覆盖写入对应 `path`
- 过滤 `.git`、`build/`、`dist/`、`target/`、`tmp/`、`.DS_Store`
- 回写 `commit`、`captured_at`、`release_date`

**Step 4: 运行一次 dry-run 或受限同步**

Run:

```bash
sh galay-sdk/scripts/sync_bundle.sh --manifest galay-sdk/manifest.json --dry-run
```

Expected:
- 正确列出每个来源的同步动作
- 不写入构建副产物

**Step 5: Commit**

```bash
git -C galay-sdk add scripts/sync_bundle.sh scripts/lib/common.sh scripts/lib/filters.sh
git -C galay-sdk commit -m "feat: add bundle sync automation"
```

### Task 3: 增加内容校验脚本

**Files:**
- Create: `scripts/verify_bundle.sh`

**Step 1: 写出失败条件**

最少覆盖以下失败条件：

- `manifest.json` 中声明的目录不存在
- 发现任何 `.git` 目录
- 发现 `build/`、`target/`、`dist/` 等禁止目录
- `VERSION` 与 `manifest.json.bundle_version` 不一致

**Step 2: 先运行不存在的校验脚本**

Run:

```bash
test -x galay-sdk/scripts/verify_bundle.sh
```

Expected:
- 非零退出

**Step 3: 实现最小校验逻辑**

脚本需要：

- 遍历 `manifest.json.sources`
- 校验目录、版本、禁止项和顶层版本一致性
- 失败时打印明确错误并退出 1

**Step 4: 对当前仓库执行一次校验**

Run:

```bash
sh galay-sdk/scripts/verify_bundle.sh --manifest galay-sdk/manifest.json
```

Expected:
- 在仓库内容符合规则时退出 0
- 如果存在禁止目录或版本不一致，输出明确报错

**Step 5: Commit**

```bash
git -C galay-sdk add scripts/verify_bundle.sh
git -C galay-sdk commit -m "test: add bundle verification script"
```

### Task 4: 把 README 和脚本使用方式对齐

**Files:**
- Modify: `README.md`

**Step 1: 记录当前 README 缺口**

确认 README 至少缺少：

- 如何更新一个 `gdk` 版本矩阵
- 如何运行同步脚本
- 如何运行校验脚本
- `gdk` 版本与子库 tag 的关系定义

**Step 2: 阅读现有 README 并确认缺口存在**

Run:

```bash
sed -n '1,240p' galay-sdk/README.md
```

Expected:
- 尚未完整覆盖脚本与流程使用说明

**Step 3: 补齐操作文档**

在 README 中加入：

- 版本矩阵模型说明
- 更新矩阵的最短流程
- `sync_bundle.sh` / `verify_bundle.sh` 示例命令
- 发版前检查项

**Step 4: 再次通读验证**

Run:

```bash
sed -n '1,260p' galay-sdk/README.md
```

Expected:
- 新人只看 README 就能完成一次矩阵更新

**Step 5: Commit**

```bash
git -C galay-sdk add README.md
git -C galay-sdk commit -m "docs: document gdk release workflow"
```

### Task 5: 跑一次完整发版演练

**Files:**
- Modify: `manifest.json`
- Modify: `VERSION`
- Modify: `CHANGELOG.md`
- Modify: `docs/release_note.md`

**Step 1: 先定义演练目标**

示例：

- 保持当前矩阵不变
- 只做一次“从 manifest 到 verify”的全链路演练
- 确认所有文档、版本号和脚本输出互相对齐

**Step 2: 执行同步与校验**

Run:

```bash
sh galay-sdk/scripts/sync_bundle.sh --manifest galay-sdk/manifest.json
sh galay-sdk/scripts/verify_bundle.sh --manifest galay-sdk/manifest.json
```

Expected:
- 同步成功
- 校验成功

**Step 3: 更新发版记录**

实施内容：

- 根据本次矩阵状态更新 `CHANGELOG.md`
- 追加 `docs/release_note.md`
- 确认 `VERSION` 与 manifest 一致

**Step 4: 复核最终状态**

Run:

```bash
git -C galay-sdk status --short
git -C galay-sdk diff -- README.md VERSION manifest.json CHANGELOG.md docs/release_note.md scripts/
```

Expected:
- 只包含本次矩阵发行相关文件变更

**Step 5: Commit**

```bash
git -C galay-sdk add README.md VERSION manifest.json CHANGELOG.md docs/release_note.md scripts/
git -C galay-sdk commit -m "release: prepare gdk version-matrix workflow"
```

## 验证命令清单

```bash
sed -n '1,260p' galay-sdk/README.md
sed -n '1,260p' galay-sdk/manifest.json
cat galay-sdk/VERSION
sh galay-sdk/scripts/sync_bundle.sh --manifest galay-sdk/manifest.json --dry-run
sh galay-sdk/scripts/verify_bundle.sh --manifest galay-sdk/manifest.json
git -C galay-sdk status --short
```

## 交付结果

完成后，`galay-sdk` 应具备以下能力：

- 明确的 `gdk tag = galay-* tag 集合` 语义
- 可重复执行的源码同步流程
- 可自动检查的内容边界与版本一致性
- 可直接面向用户分发的源码整包仓库形态
