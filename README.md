# galay-sdk

[中文说明](./README-CN.md)

`galay-sdk` is the manifest-and-tooling workspace for the `galay-*` family.

Its core rule is:

- one `gdk` version maps to one fixed `galay-*` tag matrix
- cloning a `gdk` tag gives you the exact version matrix and scripts needed to materialize the sources locally
- local `galay-*` worktrees live under the workspace root and are excluded from version control

Current bundle version: `v2.1.3`

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
| `galay-etcd` | `git-tag-archive` | `v3.0.3` | `c79fcdc4d7a56cb6263377c71eca5b7afc6c8145` |
| `galay-http` | `git-tag-archive` | `v3.0.2` | `3817cda13def4be644a2034216cd1dedf521f84b` |
| `galay-kernel` | `git-tag-archive` | `v4.0.1` | `97b7ef4a9963502ecba895f6671a3ef080996b22` |
| `galay-mail` | `git-tag-archive` | `v0.2.1` | `3bf199d769f44f946774f6cb12ab83a7e68e07a1` |
| `galay-mcp` | `git-tag-archive` | `v2.0.2` | `c6bcb91c7155ed42a95299eab6747a0e9caf568d` |
| `galay-mongo` | `git-tag-archive` | `v3.0.1` | `e801e663336d1001f2b98313d1552438d8dbffaa` |
| `galay-mysql` | `git-tag-archive` | `v2.0.2` | `b173d1bb320c1c1a0d3181b580d83d2a0d6e7756` |
| `galay-redis` | `git-tag-archive` | `v2.0.3` | `de88fbb7e091a514008d0dd8c33c50be347045af` |
| `galay-rpc` | `git-tag-archive` | `v2.0.2` | `a8982611bd2708378c1c915091db315550cd833d` |
| `galay-ssl` | `git-tag-archive` | `v2.0.2` | `0fd1f4849905bf5723f4da5f590ea30c45d17472` |
| `galay-utils` | `git-tag-archive` | `v2.1.1` | `d3fbf04c733a1026cd036ffbc68b198ac33ea1ba` |

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

- `galay-utils` is exported from the highest released tag `v2.1.1`, aligned
  with the current source-repo package version metadata.
- `galay-http` and `galay-kernel` are also exported from their highest released
  tags rather than from unreleased local branch state.
- `galay-mongo` is exported from its released tag `v3.0.1`, aligned with the
  current source-repo package version metadata.
- `galay-mail` is exported from its released tag `v0.2.1`, aligned with the
  current source-repo package version metadata.
