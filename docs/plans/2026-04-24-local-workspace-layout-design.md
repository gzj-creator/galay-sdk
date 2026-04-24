# Local Workspace Layout Design

## Goal

Turn `galay-sdk` into a workspace repository that keeps only manifests, scripts, and docs in Git, while fetching each `galay-*` dependency into `galay-sdk/<repo>` as an ignored local checkout.

## Decisions

### Workspace layout

- `manifest.json` remains the version matrix source of truth.
- Each dependency checkout lives at `galay-sdk/<repo>`.
- Top-level `galay-*` directories are ignored by Git and are no longer part of committed repository contents.

### Fetch behavior

- `scripts/fetch_galay_repos.sh` clones or fetches into `galay-sdk/<repo>`.
- Fetch defaults to checking out the manifest `version` for each `galay-*` source.
- A flag can disable checkout when a caller only wants to refresh refs.

### Bundle export behavior

- `scripts/sync_bundle.sh` no longer mutates the workspace root.
- Export requires a separate output directory and writes bundled snapshots there.
- Exported manifests keep relative source paths so verification works inside either the workspace or the export directory.

### Build and verification behavior

- `scripts/install_galay_repos.sh` builds from the local workspace checkout paths declared by the manifest.
- `scripts/verify_bundle.sh` continues validating the declared source roots and manifest commit/version consistency.

## Rationale

- Keeping local worktrees under `galay-sdk/<repo>` makes the workspace self-contained.
- Ignoring those directories avoids accidentally committing full dependency repositories.
- Requiring fetch to checkout manifest versions preserves the version matrix contract.
- Exporting to a separate directory avoids destroying local Git worktrees during bundle generation.

## Success Criteria

- Running fetch populates `galay-sdk/<repo>` and checks out the manifest tag by default.
- `galay-sdk` no longer needs committed `galay-*` source trees.
- Sync exports a clean bundle into an explicit output directory.
- Tests cover fetch checkout behavior and sync output isolation.
