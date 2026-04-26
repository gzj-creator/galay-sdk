# galay-sdk

[中文说明](./README-CN.md)

`galay-sdk` is the manifest-and-tooling workspace for the `galay-*` family.

Its core rule is:

- one `gdk` version maps to one fixed `galay-*` tag matrix
- cloning a `gdk` tag gives you the exact version matrix and scripts needed to materialize the sources locally
- local `galay-*` worktrees live under the workspace root and are excluded from version control

Current bundle version: `v1.0.1`

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
| `galay-etcd` | `git-tag-archive` | `v1.1.8` | `6f8d2dda295e0e3ed96b2d4cc2df4a88cb68482f` |
| `galay-http` | `git-tag-archive` | `v2.1.3` | `622eea548fae3061ba893413a93193d444618613` |
| `galay-kernel` | `git-tag-archive` | `v3.4.6` | `a408d4a0f9326b860fe6837ee83f41f08d1851bc` |
| `galay-mcp` | `git-tag-archive` | `v1.1.3` | `a206d70dd1aeafd90b642b384cae761ad20de645` |
| `galay-mongo` | `local-snapshot` | local snapshot | captured on `2026-04-22` |
| `galay-mysql` | `git-tag-archive` | `v1.2.6` | `f43cb41503ab36f012ce7ea7cdf166344b8a1a64` |
| `galay-redis` | `git-tag-archive` | `v1.2.2` | `082453047dba1350c51be8b4242f8c8404083f89` |
| `galay-rpc` | `git-tag-archive` | `v1.1.3` | `51ac066edd5d2c2ae0493fcb9436d9cda4103561` |
| `galay-ssl` | `git-tag-archive` | `v1.2.2` | `cb1d2f9a2d7729b651ce1170f7a5cd75a74be119` |
| `galay-utils` | `git-tag-archive` | `v1.2.1` | `1ce934b6f914918e3ddcb585bb806dd07ec0fa31` |

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

- `galay-utils` is exported from the highest released tag `v1.2.1`, aligned
  with the current source-repo package version metadata.
- `galay-http` and `galay-kernel` are also exported from their highest released
  tags rather than from unreleased local branch state.
- `galay-mongo` is currently tracked as a local snapshot source and should be
  converted to a tagged Git source once its release process is ready.
