# galay-sdk

[English](./README.md)

`galay-sdk` 是 `galay-*` 系列仓库的源码分发仓库。

核心规则：

- 一个 `gdk` 版本对应一组固定的 `galay-*` tag 矩阵
- 克隆某个 `gdk` tag 后可直接获得完整源码包
- 仓库不包含上游 `.git` 历史和生成产物

当前 bundle 版本：`v0.3.0`

## 版本矩阵

当前矩阵由 [`manifest.json`](./manifest.json) 定义。每个条目包含：

- 组件名称
- 来源类型：`git-tag-archive` 或 `local-snapshot`
- 上游仓库地址
- 同步时使用的本地路径
- 在 `galay-sdk` 中的目标目录
- 精确版本信息（tag / commit / snapshot 时间）

## 当前来源

| 仓库 | 来源类型 | 收录版本 | 来源引用 |
| --- | --- | --- | --- |
| `galay-etcd` | `git-tag-archive` | `v1.1.8` | `549634bca9991c8f42741336252f5aa2772400d5` |
| `galay-http` | `git-tag-archive` | `v2.1.2` | `f90ef97d619ec7cb9c8b4343d9d17a457442be14` |
| `galay-kernel` | `git-tag-archive` | `v3.4.5` | `b39b3afc089e56589a8076915b7128c2fa38591c` |
| `galay-mcp` | `git-tag-archive` | `v1.1.3` | `e470fb1d9a6c1ebb5576009e8cf9b008ba9d6972` |
| `galay-mongo` | `local-snapshot` | 本地快照 | 捕获于 `2026-04-22` |
| `galay-mysql` | `git-tag-archive` | `v1.2.5` | `82fb561414d005420782f7aab40d0ce88297bb5d` |
| `galay-redis` | `git-tag-archive` | `v1.2.2` | `082453047dba1350c51be8b4242f8c8404083f89` |
| `galay-rpc` | `git-tag-archive` | `v1.1.3` | `51ac066edd5d2c2ae0493fcb9436d9cda4103561` |
| `galay-ssl` | `git-tag-archive` | `v1.2.2` | `cb1d2f9a2d7729b651ce1170f7a5cd75a74be119` |
| `galay-utils` | `git-tag-archive` | `v1.2.1` | `1ce934b6f914918e3ddcb585bb806dd07ec0fa31` |

## 更新流程

1. 修改 [`manifest.json`](./manifest.json)，选定下一版 `galay-*` tag 矩阵。
2. 运行同步脚本，把声明的来源导出到 bundle 目录。
3. 运行校验脚本，确认版本和内容边界正确。
4. 更新 [`CHANGELOG.md`](./CHANGELOG.md) 与 [`docs/release_note.md`](./docs/release_note.md)。
5. 提交 bundle 更新，并打下一个 `gdk` tag。

示例命令：

```sh
sh scripts/sync_bundle.sh --manifest manifest.json
sh scripts/verify_bundle.sh --manifest manifest.json
```

如需只查看计划动作而不改写源码目录，可在同步步骤使用 `--dry-run`。

## 一键安装所有 `galay-*` 仓库

安装脚本会按 [`manifest.json`](./manifest.json) 声明，对 `galay-sdk` 内已包含的
`galay-*` 组件逐个执行 CMake 编译安装流程：
`mkdir build` -> `cmake ..` -> `cmake --build` -> `cmake --install`。
脚本会按依赖顺序构建（例如先 `galay-kernel`/`galay-utils`，再 `galay-http`，
最后 `galay-etcd`），并自动注入 `CMAKE_PREFIX_PATH`。

默认安装前缀为本地目录：`./.galay-prefix/latest`。

```sh
sh scripts/install_galay_repos.sh --manifest manifest.json
```

安装到指定前缀目录：

```sh
sh scripts/install_galay_repos.sh --manifest manifest.json --prefix /usr/local
```

安装阶段使用 `sudo`：

```sh
sh scripts/install_galay_repos.sh --manifest manifest.json --prefix /usr/local --sudo
```

预览模式：

```sh
sh scripts/install_galay_repos.sh --manifest manifest.json --dry-run
```

## 一键抓取所有 `galay-*` 源仓库

如果你希望维护 `galay-sdk` 之外的 sibling 源仓库（不存在则 clone，已存在则
fetch 最新 tags/refs），可使用抓取脚本：

```sh
sh scripts/fetch_galay_repos.sh --manifest manifest.json
```

如需按清单版本统一切换：

```sh
sh scripts/fetch_galay_repos.sh --manifest manifest.json --checkout-version
```

预览模式：

```sh
sh scripts/fetch_galay_repos.sh --manifest manifest.json --dry-run
```

## 内容边界

bundle 会保留各组件源码、示例、测试、基准和构建元数据；同时会过滤以下生成内容：

- 嵌套 `.git` 目录
- 编辑器缓存（如 `.cache/`、`.clangd/`）
- `build/`、`build-*`、`dist/`、`target/`、`tmp/`
- `benchmark/results/`
- 临时日志与折叠后的 benchmark traces
- 内置基准二进制（如 `go-proto-client`、`go-proto-server`）
- `.DS_Store`

## 备注

- `galay-utils` 当前使用其最新已发布 tag `v1.2.1` 导出，并与源仓库版本元数据保持一致。
- `galay-http` 和 `galay-kernel` 也使用最新已发布 tag 导出，而非未发布分支状态。
- `galay-mongo` 目前仍按本地快照来源管理，待发布流程稳定后建议切换为带 tag 的 Git 来源。
