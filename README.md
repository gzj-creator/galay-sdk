# galay-sdk

`galay-sdk` is the source distribution repository for the `galay-*`
family.

Its core rule is:

- one `gdk` version maps to one fixed `galay-*` tag matrix
- cloning a `gdk` tag gives you the full source bundle directly
- the repository excludes upstream `.git` history and generated artifacts

Current bundle version: `v0.2.0`

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
| `galay-etcd` | `git-tag-archive` | `v1.1.4` | `a3e57d9deb202f77542f3ee4761c1e9fc4cc6782` |
| `galay-http` | `git-tag-archive` | `v2.0.2` | `3fdf5bf442e781370b51170c8c6dcc3aa62e5559` |
| `galay-kernel` | `git-tag-archive` | `v3.4.4` | `c872cc3c7fd8a2c2b2d7a4c94c9230c5bb2907d6` |
| `galay-mcp` | `git-tag-archive` | `v1.1.2` | `8c93e3c9954d8822cfcbf991e9bd1b6481bf25de` |
| `galay-mongo` | `local-snapshot` | local snapshot | captured on `2026-04-22` |
| `galay-mysql` | `git-tag-archive` | `v1.2.5` | `82fb561414d005420782f7aab40d0ce88297bb5d` |
| `galay-redis` | `git-tag-archive` | `v1.2.2` | `082453047dba1350c51be8b4242f8c8404083f89` |
| `galay-rpc` | `git-tag-archive` | `v1.1.2` | `f309242e9b0e090cd59ecabd9c14d5eba0d2f820` |
| `galay-ssl` | `git-tag-archive` | `v1.2.2` | `cb1d2f9a2d7729b651ce1170f7a5cd75a74be119` |
| `galay-utils` | `git-tag-archive` | `v1.2.0` | `60be94ab601a2965e216fdf02d9a611907c3fac9` |

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

- `galay-utils` is exported from the highest released tag `v1.2.0`, which is
  newer than the current local branch tip.
- `galay-http` and `galay-kernel` are also exported from their highest released
  tags rather than from unreleased local branch state.
- `galay-mongo` is currently tracked as a local snapshot source and should be
  converted to a tagged Git source once its release process is ready.
