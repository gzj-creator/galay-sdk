# galay-sdk

[English](./README.md)

`galay-sdk` 是 `galay-*` 系列仓库的清单与工具工作区。

核心规则：

- 一个 `gdk` 版本对应一组固定的 `galay-*` tag 矩阵
- 克隆某个 `gdk` tag 后可获得确定版本矩阵及本地落库脚本
- 本地 `galay-*` 工作树位于仓库根目录下，但不纳入版本控制

当前 bundle 版本：`v2.1.0`

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
| `galay-etcd` | `git-tag-archive` | `v3.0.2` | `35e92746e0c99411476242278a2195e9aa61d0ce` |
| `galay-http` | `git-tag-archive` | `v3.0.1` | `67a2aa4c9b946f884569259d5dc50a080322a638` |
| `galay-kernel` | `git-tag-archive` | `v4.0.0` | `c4481276a7626a6719a62107ecfa6b2d22933d5b` |
| `galay-mail` | `git-tag-archive` | `v0.2.0` | `9966b3622c23d464dbc96aec119c5ae57cedc7e2` |
| `galay-mcp` | `git-tag-archive` | `v2.0.1` | `dba7c8af483694490f54e524df7fb001c933570f` |
| `galay-mongo` | `git-tag-archive` | `v3.0.0` | `edae3c93a25fbb41dd1176e4f162cfd3906cb04f` |
| `galay-mysql` | `git-tag-archive` | `v2.0.1` | `e1591197c65d5e889ae99f44c12583ca147a7b5c` |
| `galay-redis` | `git-tag-archive` | `v2.0.1` | `1eb7d7a0bacd3cd136c2e64e7f072c21c062b2a9` |
| `galay-rpc` | `git-tag-archive` | `v2.0.1` | `48af7fdec5791b6899ed303f1f87748edd0d90ce` |
| `galay-ssl` | `git-tag-archive` | `v2.0.1` | `0a196411b861a5169fe68013926bd4a1361e4b27` |
| `galay-utils` | `git-tag-archive` | `v2.1.0` | `38ee7aac1e2ab62cdca1b2a58830a1927fc83cd7` |

## 更新流程

1. 修改 [`manifest.json`](./manifest.json)，选定下一版 `galay-*` tag 矩阵。
2. 运行抓取脚本，把 `manifest` 声明的 `galay-*` 仓库拉到当前工作区根目录，并默认切到清单指定版本。
3. 运行校验脚本，确认本地版本矩阵正确。
4. 需要导出源码包时，再把同步脚本导出到独立输出目录。
5. 更新 [`CHANGELOG.md`](./CHANGELOG.md) 与 [`docs/release_note.md`](./docs/release_note.md)，提交矩阵/脚本更新并打下一个 `gdk` tag。

示例命令：

```sh
sh scripts/fetch_galay_repos.sh --manifest manifest.json
sh scripts/verify_bundle.sh --manifest manifest.json
sh scripts/sync_bundle.sh --manifest manifest.json --output /tmp/galay-sdk-bundle
```

如需只查看计划动作而不改写本地工作树或导出目录，可使用 `--dry-run`。

## 一键安装所有 `galay-*` 仓库

安装脚本会按 [`manifest.json`](./manifest.json) 声明，对 `galay-sdk/<repo>` 下已抓取的
`galay-*` 本地工作树逐个执行 CMake 编译安装流程：
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

抓取脚本会把 `galay-*` 仓库维护在 `galay-sdk/<repo>` 下（不存在则 clone，
已存在则 fetch 最新 tags/refs，并默认切到 manifest 指定版本）：

```sh
sh scripts/fetch_galay_repos.sh --manifest manifest.json
```

如只想刷新 refs 而不切换到 manifest 版本：

```sh
sh scripts/fetch_galay_repos.sh --manifest manifest.json --no-checkout-version
```

预览模式：

```sh
sh scripts/fetch_galay_repos.sh --manifest manifest.json --dry-run
```

## 导出包内容边界

导出的 bundle 会保留各组件源码、示例、测试、基准和构建元数据；同时会过滤以下生成内容：

- 嵌套 `.git` 目录
- 编辑器缓存（如 `.cache/`、`.clangd/`）
- `build/`、`build-*`、`dist/`、`target/`、`tmp/`
- `benchmark/results/`
- 临时日志与折叠后的 benchmark traces
- 内置基准二进制（如 `go-proto-client`、`go-proto-server`）
- `.DS_Store`

## 备注

- `galay-utils` 当前使用其最新已发布 tag `v2.1.0` 导出，并与源仓库版本元数据保持一致。
- `galay-http` 和 `galay-kernel` 也使用最新已发布 tag 导出，而非未发布分支状态。
- `galay-mongo` 当前使用其已发布 tag `v3.0.0` 导出，并与源仓库版本元数据保持一致。
- `galay-mail` 当前使用其已发布 tag `v0.2.0` 导出，并与源仓库版本元数据保持一致。
