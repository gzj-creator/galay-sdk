# galay-sdk

[English](./README.md)

`galay-sdk` 是 `galay-*` 系列仓库的清单与工具工作区。

核心规则：

- 一个 `gdk` 版本对应一组固定的 `galay-*` tag 矩阵
- 克隆某个 `gdk` tag 后可获得确定版本矩阵及本地落库脚本
- 本地 `galay-*` 工作树位于仓库根目录下，但不纳入版本控制

当前 bundle 版本：`v2.2.4`

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
| `galay-etcd` | `git-tag-archive` | `v3.1.1` | `4b9d485b6750f31fe441fa4eee8885e38f6e7e42` |
| `galay-http` | `git-tag-archive` | `v3.1.2` | `50d62c3d63425c934cf9f19c871470ecb8749f6f` |
| `galay-kernel` | `git-tag-archive` | `v5.0.0` | `2090c4559a5eecb175b2d7da48b38422d09c1135` |
| `galay-mail` | `git-tag-archive` | `v0.2.1` | `2181696413965a464886d65dd101582e6510a319` |
| `galay-mcp` | `git-tag-archive` | `v2.1.1` | `38f7d7c382d741e387c89bb3fdd323420837bcb3` |
| `galay-mongo` | `git-tag-archive` | `v3.1.1` | `9a482bc64de23fc389d25ff21dd1e212eba64f31` |
| `galay-mysql` | `git-tag-archive` | `v2.1.1` | `377b1a78e8b73aeda6943246edd353995c869f6d` |
| `galay-redis` | `git-tag-archive` | `v2.1.1` | `a2c91f186b1869e35e95ffa2a34d7e57699f16fa` |
| `galay-rpc` | `git-tag-archive` | `v2.1.1` | `115830277d6b0f0bb4f602819271b83593096fa6` |
| `galay-ssl` | `git-tag-archive` | `v2.1.1` | `00aa28d82b1d4e8ef6cc7a345f87013b5f1f469b` |
| `galay-tracing` | `git-tag-archive` | `v0.3.0` | `1bf248d7e06fe53b08afab67222bf7a8b1a903b4` |
| `galay-utils` | `git-tag-archive` | `v2.1.3` | `e3f8b9c79969a69265c374d7bd740fcc5140d4a1` |

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

如需通过 SSH 远端拉取，而不是使用 `manifest` 中的 HTTPS URL：

```sh
sh scripts/fetch_galay_repos.sh --manifest manifest.json --repo-protocol ssh
```

SSH 模式会把 `https://github.com/gzj-creator/galay-http.git` 这类仓库地址映射为
`git@github.com:gzj-creator/galay-http.git`，并在抓取已有本地工作树前同步更新
`origin`。

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

- `galay-utils` 当前使用其最新已发布 tag `v2.1.3` 导出，并与源仓库版本元数据保持一致。
- `galay-http` 和 `galay-kernel` 也使用最新已发布 tag 导出，而非未发布分支状态。
- `galay-mongo` 当前使用其已发布 tag `v3.1.1` 导出，并与源仓库版本元数据保持一致。
- `galay-mail` 当前使用其已发布 tag `v0.2.1` 导出，并与源仓库版本元数据保持一致。
- `galay-tracing` 当前使用其已发布 tag `v0.3.0` 导出，并与源仓库版本元数据保持一致。
