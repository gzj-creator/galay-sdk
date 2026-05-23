# galay-sdk

[中文说明](./README-CN.md)

`galay-sdk` is the manifest-and-tooling workspace for the `galay-*` family.

Its core rule is:

- one `gdk` version maps to one fixed `galay-*` tag matrix
- cloning a `gdk` tag gives you the exact version matrix and scripts needed to materialize the sources locally
- local `galay-*` worktrees live under the workspace root and are excluded from version control

Current bundle version: `v2.2.2`

## Version Matrix

The current matrix is defined by [`manifest.json`](./manifest.json). Each entry
declares:

- the bundled component name
- its source type: `git-tag-archive` or `local-snapshot`
- the upstream repository URL
- the local checkout path used for syncing
- the target directory inside `galay-sdk`
- the exact tag, commit, or snapshot capture time

## Current Sources

| Repository | Source type | Included version | Source ref |
| --- | --- | --- | --- |
| `galay-etcd` | `git-tag-archive` | `v3.1.1` | `cd7bb2215af5920304ebce4df3590340b24c0ca2` |
| `galay-http` | `git-tag-archive` | `v3.1.1` | `eee14175df0d87ae2df46ed2cc5c4149d27191e6` |
| `galay-kernel` | `git-tag-archive` | `v5.0.0` | `3cdab0fc2408e0e203e6ef4f1159de85be613a9b` |
| `galay-mail` | `git-tag-archive` | `v0.2.1` | `c3fa317104a59a51ea68fd7c2a94c66e94218abb` |
| `galay-mcp` | `git-tag-archive` | `v2.1.1` | `4c432ceac6a3154b3ebab54e8f249ff76874faee` |
| `galay-mongo` | `git-tag-archive` | `v3.1.1` | `07f3bc33dd96b9739b70171cac8711c48557134f` |
| `galay-mysql` | `git-tag-archive` | `v2.1.1` | `c7b03b0719215c1569cf91df23c7c8b0cc7ff14d` |
| `galay-redis` | `git-tag-archive` | `v2.1.1` | `c8d6f76aeb17c16340a9eac2194ee27daa8f6fdc` |
| `galay-rpc` | `git-tag-archive` | `v2.1.1` | `0acb2592ab0aa80dc21a1c72384964d8ffa8a9e1` |
| `galay-ssl` | `git-tag-archive` | `v2.1.1` | `ba5b428ec3e117baf5c4e7e08c30bb3c872a6d3a` |
| `galay-tracing` | `git-tag-archive` | `v0.3.0` | `b4066789a4b0fcc95bc5e806f22b4fe7c284d1cc` |
| `galay-utils` | `git-tag-archive` | `v2.1.2` | `38300ae8af3e99b36efc6c998e0b6ee1ee749598` |

## Update Workflow

1. Edit [`manifest.json`](./manifest.json) to select the next `galay-*` tag matrix.
2. Run the fetch script to clone or refresh local `galay-*` worktrees under the workspace root and detach them to the manifest versions.
3. Run the verification script to ensure the local matrix is still correct.
4. When you need a distributable source bundle, run the sync script with a separate output directory.
5. Update [`CHANGELOG.md`](./CHANGELOG.md) and [`docs/release_note.md`](./docs/release_note.md), then commit the matrix/tooling update and add the next `gdk` tag.

Example commands:

```sh
sh scripts/fetch_galay_repos.sh --manifest manifest.json
sh scripts/verify_bundle.sh --manifest manifest.json
sh scripts/sync_bundle.sh --manifest manifest.json --output /tmp/galay-sdk-bundle
```

Use `--dry-run` to inspect fetch or export actions without changing the local worktrees or output bundle.

## Install All `galay-*` Repositories

Use the install helper to build and install all fetched `galay-*` components
declared in [`manifest.json`](./manifest.json). The script uses the local
workspace checkouts under `galay-sdk/<repo>` and runs a CMake workflow per component:
`mkdir build` -> `cmake ..` -> `cmake --build` -> `cmake --install`.
It builds in dependency order (for example `galay-kernel`/`galay-utils` before
`galay-http`, then `galay-etcd`) and injects `CMAKE_PREFIX_PATH` automatically.

By default it installs into a local prefix:
`./.galay-prefix/latest`

```sh
sh scripts/install_galay_repos.sh --manifest manifest.json
```

Install to a custom prefix:

```sh
sh scripts/install_galay_repos.sh --manifest manifest.json --prefix /usr/local
```

Use `sudo` for the install phase:

```sh
sh scripts/install_galay_repos.sh --manifest manifest.json --prefix /usr/local --sudo
```

You can preview actions without building/installing:

```sh
sh scripts/install_galay_repos.sh --manifest manifest.json --dry-run
```

## Fetch All `galay-*` Source Repositories

Use the fetch helper to maintain local `galay-*` worktrees under
`galay-sdk/<repo>` (clone if missing, otherwise fetch tags/refs and detach to
the manifest version by default).

```sh
sh scripts/fetch_galay_repos.sh --manifest manifest.json
```

Use SSH remotes instead of the manifest HTTPS URLs:

```sh
sh scripts/fetch_galay_repos.sh --manifest manifest.json --repo-protocol ssh
```

SSH mode maps repository URLs such as
`https://github.com/gzj-creator/galay-http.git` to
`git@github.com:gzj-creator/galay-http.git` and updates `origin` for existing
local worktrees before fetching.

If you only want to refresh refs without checking out the manifest tag:

```sh
sh scripts/fetch_galay_repos.sh --manifest manifest.json --no-checkout-version
```

Preview mode:

```sh
sh scripts/fetch_galay_repos.sh --manifest manifest.json --dry-run
```

## Exported Bundle Boundary

The exported bundle keeps source files, examples, tests, benchmarks, and build
metadata that belong to each component. It filters out generated content such as:

- nested `.git` directories
- editor caches such as `.cache/` and `.clangd/`
- `build/`, `build-*`, `dist/`, `target/`, `tmp/`
- `benchmark/results/`
- temporary logs and folded benchmark traces
- vendored benchmark binaries such as `go-proto-client` and `go-proto-server`
- `.DS_Store`

## Notes

- `galay-utils` is exported from the highest released tag `v2.1.2`, aligned
  with the current source-repo package version metadata.
- `galay-http` and `galay-kernel` are also exported from their highest released
  tags rather than from unreleased local branch state.
- `galay-mongo` is exported from its released tag `v3.1.1`, aligned with the
  current source-repo package version metadata.
- `galay-mail` is exported from its released tag `v0.2.1`, aligned with the
  current source-repo package version metadata.
- `galay-tracing` is exported from its released tag `v0.3.0`, aligned with the
  current source-repo package version metadata.
