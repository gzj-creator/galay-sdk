# Local Workspace Layout Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Make `galay-sdk` a manifest/scripts-only workspace while fetching `galay-*` repos into ignored local directories under the repo root and checking out manifest versions by default.

**Architecture:** The manifest remains the single source of truth for versions and relative source locations. Fetch operates on local workspace checkouts, sync exports to a separate output directory, and tests verify that local worktrees are preserved and version checkout happens automatically.

**Tech Stack:** POSIX shell, `jq`, `git`, existing shell test scripts

---

### Task 1: Add fetch behavior coverage

**Files:**
- Create: `tests/test_fetch_galay_repos.sh`

**Step 1: Write the failing test**

- Create a temporary fixture repo with two tagged commits.
- Create a fixture manifest whose `local_path` points to `galay-sample`.
- Assert that fetch clones into `<bundle-root>/galay-sample`.
- Assert that the checked out commit matches the manifest tag without requiring an explicit checkout flag.

**Step 2: Run test to verify it fails**

Run: `rtk sh tests/test_fetch_galay_repos.sh`

Expected: the script fails because fetch still targets the parent directory and/or does not checkout the manifest version by default.

### Task 2: Add sync output isolation coverage

**Files:**
- Modify: `tests/test_sync_bundle.sh`

**Step 1: Write the failing test**

- Change the fixture to keep source repos in the workspace root.
- Call sync with an explicit output directory.
- Assert the output directory gets the exported sources.
- Assert the source checkout directories are not cleaned or overwritten.

**Step 2: Run test to verify it fails**

Run: `rtk sh tests/test_sync_bundle.sh`

Expected: the script fails because sync still writes into the workspace root and has no explicit output directory support.

### Task 3: Update manifest-driven workspace behavior

**Files:**
- Modify: `manifest.json`
- Modify: `scripts/fetch_galay_repos.sh`
- Modify: `scripts/sync_bundle.sh`

**Step 1: Implement fetch changes**

- Default target checkout path to `BUNDLE_ROOT/<repo>`.
- Default checkout behavior to enabled.
- Add an opt-out flag such as `--no-checkout-version`.

**Step 2: Implement sync changes**

- Require `--output`.
- Write exported snapshots and exported manifest into that output directory.
- Preserve manifest metadata while avoiding writes into the workspace root.

**Step 3: Update manifest**

- Change `local_path` entries to root-relative `galay-*`.
- Refresh manifest commits to match current tag targets.
- Refresh the `galay-mysql` version entry to `v1.2.6`.

### Task 4: Update workspace docs and ignore rules

**Files:**
- Modify: `.gitignore`
- Modify: `README.md`
- Modify: `README-CN.md`

**Step 1: Document the new workflow**

- Explain that `galay-sdk` keeps manifests/scripts only.
- Explain that `fetch_galay_repos.sh` creates ignored local worktrees under the repo root.
- Explain that bundle export now requires a separate output directory.

**Step 2: Ignore local checkouts**

- Add top-level ignore rules for `galay-*`.

### Task 5: Verify targeted behavior

**Files:**
- No code changes

**Step 1: Run targeted tests**

Run:
- `rtk sh tests/test_fetch_galay_repos.sh`
- `rtk sh tests/test_sync_bundle.sh`
- `rtk sh tests/test_verify_bundle.sh`

Expected: all pass.

**Step 2: Run dry-run smoke checks**

Run:
- `rtk sh scripts/fetch_galay_repos.sh --dry-run`
- `rtk sh scripts/sync_bundle.sh --manifest manifest.json --output "$(mktemp -d)" --dry-run`

Expected: dry-run output references `galay-sdk/<repo>` paths and the separate export directory.
