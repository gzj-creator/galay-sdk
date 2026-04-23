# galay-sdk

[中文说明](./README-CN.md)

`galay-sdk` is the source distribution repository for the `galay-*`
family.

Its core rule is:

- one `gdk` version maps to one fixed `galay-*` tag matrix
- cloning a `gdk` tag gives you the full source bundle directly
- the repository excludes upstream `.git` history and generated artifacts

Current bundle version: `v0.3.0`

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
| `galay-etcd` | `git-tag-archive` | `v1.1.8` | `549634bca9991c8f42741336252f5aa2772400d5` |
| `galay-http` | `git-tag-archive` | `v2.1.2` | `f90ef97d619ec7cb9c8b4343d9d17a457442be14` |
| `galay-kernel` | `git-tag-archive` | `v3.4.5` | `b39b3afc089e56589a8076915b7128c2fa38591c` |
| `galay-mcp` | `git-tag-archive` | `v1.1.3` | `e470fb1d9a6c1ebb5576009e8cf9b008ba9d6972` |
| `galay-mongo` | `local-snapshot` | local snapshot | captured on `2026-04-22` |
| `galay-mysql` | `git-tag-archive` | `v1.2.5` | `82fb561414d005420782f7aab40d0ce88297bb5d` |
| `galay-redis` | `git-tag-archive` | `v1.2.2` | `082453047dba1350c51be8b4242f8c8404083f89` |
| `galay-rpc` | `git-tag-archive` | `v1.1.3` | `51ac066edd5d2c2ae0493fcb9436d9cda4103561` |
| `galay-ssl` | `git-tag-archive` | `v1.2.2` | `cb1d2f9a2d7729b651ce1170f7a5cd75a74be119` |
| `galay-utils` | `git-tag-archive` | `v1.2.1` | `1ce934b6f914918e3ddcb585bb806dd07ec0fa31` |

## Update Workflow

1. Edit [`manifest.json`](./manifest.json) to select the next `galay-*` tag matrix.
2. Run the sync script to export the declared sources into the bundle tree.
3. Run the verification script to ensure version and content boundaries are still correct.
4. Update [`CHANGELOG.md`](./CHANGELOG.md) and [`docs/release_note.md`](./docs/release_note.md).
5. Commit the bundle update and add the next `gdk` tag.

Example commands:

```sh
sh scripts/sync_bundle.sh --manifest manifest.json
sh scripts/verify_bundle.sh --manifest manifest.json
```

Use `--dry-run` on the sync step when you want to inspect the planned actions
without rewriting the bundled source tree.

## Install All `galay-*` Repositories

Use the install helper to build and install all bundled `galay-*` components
declared in [`manifest.json`](./manifest.json). The script uses the source tree
already present in `galay-sdk` and runs a CMake workflow per component:
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

Use the fetch helper when you want to maintain sibling source repositories
outside `galay-sdk` (clone if missing, otherwise fetch tags/refs).

```sh
sh scripts/fetch_galay_repos.sh --manifest manifest.json
```

You can also checkout each repository to the version declared in the manifest:

```sh
sh scripts/fetch_galay_repos.sh --manifest manifest.json --checkout-version
```

Preview mode:

```sh
sh scripts/fetch_galay_repos.sh --manifest manifest.json --dry-run
```

## Content Boundary

The bundle keeps source files, examples, tests, benchmarks, and build metadata
that belong to each component. It filters out generated content such as:

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
