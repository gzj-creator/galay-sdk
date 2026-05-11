# galay-sdk

[中文说明](./README-CN.md)

`galay-sdk` is the manifest-and-tooling workspace for the `galay-*` family.

Its core rule is:

- one `gdk` version maps to one fixed `galay-*` tag matrix
- cloning a `gdk` tag gives you the exact version matrix and scripts needed to materialize the sources locally
- local `galay-*` worktrees live under the workspace root and are excluded from version control

Current bundle version: `v2.0.1`

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
| `galay-etcd` | `git-tag-archive` | `v2.0.0` | `25f875c707cc5031c97d20d62f18aab3b3db3c50` |
| `galay-http` | `git-tag-archive` | `v3.0.0` | `108849d324a4effcaf31e535b10b169511961449` |
| `galay-kernel` | `git-tag-archive` | `v4.0.0` | `c4481276a7626a6719a62107ecfa6b2d22933d5b` |
| `galay-mcp` | `git-tag-archive` | `v2.0.0` | `b69cfa50e7af6209e13392fe3eaec5c8e27449ae` |
| `galay-mongo` | `git-tag-archive` | `v3.0.0` | `edae3c93a25fbb41dd1176e4f162cfd3906cb04f` |
| `galay-mysql` | `git-tag-archive` | `v2.0.0` | `7be78d982aa0a84db5904525763a9c10ecc4849e` |
| `galay-redis` | `git-tag-archive` | `v2.0.0` | `43a613111b04c6145c01b0e71a57f0be0a6f350f` |
| `galay-rpc` | `git-tag-archive` | `v2.0.0` | `b7369c2616750946fb44ab3ef711984702593286` |
| `galay-ssl` | `git-tag-archive` | `v2.0.0` | `ead04e8f9cd1e43955d1d21b1e00bfab0c538e02` |
| `galay-utils` | `git-tag-archive` | `v2.0.0` | `69024be82fd4b03cc50fb54fe24556f8b9aeee70` |

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

- `galay-utils` is exported from the highest released tag `v2.0.0`, aligned
  with the current source-repo package version metadata.
- `galay-http` and `galay-kernel` are also exported from their highest released
  tags rather than from unreleased local branch state.
- `galay-mongo` is exported from its released tag `v3.0.0`, aligned with the
  current source-repo package version metadata.
