# Gitee Fetch Support Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a `--repo-host gitee` option to the fetch script so `galay-*` repositories can be cloned and refreshed from `https://gitee.com/glloveforever/<repo>.git` while preserving the current GitHub-default behavior.

**Architecture:** Extend `scripts/fetch_galay_repos.sh` with a small URL-resolution layer that computes an effective remote per repository before clone/fetch. Keep the manifest schema unchanged, update existing repos' `origin` remotes when Gitee mode is selected, and cover the new behavior with focused shell tests plus README examples.

**Tech Stack:** POSIX shell, git, jq, existing shell test scripts

---

## File structure

- Modify: `scripts/fetch_galay_repos.sh`
  - Add `--repo-host` argument parsing
  - Add effective remote resolution for `github` and `gitee`
  - Update existing repos' `origin` URL when the selected host differs from the current remote
  - Improve dry-run and normal logs to print the effective remote URL
- Modify: `tests/test_fetch_galay_repos.sh`
  - Preserve the current GitHub-path coverage
  - Add a fixture that validates Gitee URL mapping and remote rewriting for existing clones
- Modify: `README.md`
  - Document the new `--repo-host gitee` usage in the fetch section
- Modify: `README-CN.md`
  - Document the new `--repo-host gitee` usage in the fetch section

## Task 1: Add a failing test for `--repo-host gitee` URL mapping

**Files:**
- Modify: `tests/test_fetch_galay_repos.sh`
- Test: `tests/test_fetch_galay_repos.sh`

- [ ] **Step 1: Extend the test fixture with a Gitee-mode manifest and remote assertions**

```sh
cat > "$BUNDLE_ROOT/manifest-gitee.json" <<EOF
{
  "bundle_name": "fixture-gdk",
  "bundle_version": "v9.9.9",
  "release_date": "2000-01-01",
  "sources": [
    {
      "name": "galay-sample",
      "source_type": "git-tag-archive",
      "repo": "https://github.com/gzj-creator/galay-sample.git",
      "path": "galay-sample",
      "version": "v1.0.0",
      "commit": null
    }
  ]
}
EOF

REMOTE_URL=$(git -C "$BUNDLE_ROOT/galay-sample" remote get-url origin)
assert_eq "$SOURCE_REPO" "$REMOTE_URL"

sh "$REPO_ROOT/scripts/fetch_galay_repos.sh" \
  --manifest "$BUNDLE_ROOT/manifest-gitee.json" \
  --repo-host gitee

UPDATED_REMOTE_URL=$(git -C "$BUNDLE_ROOT/galay-sample" remote get-url origin)
assert_eq "https://gitee.com/glloveforever/galay-sample.git" "$UPDATED_REMOTE_URL"
```

- [ ] **Step 2: Run the test to verify it fails**

Run:

```sh
rtk test sh tests/test_fetch_galay_repos.sh
```

Expected: FAIL with `unknown argument: --repo-host gitee`.

- [ ] **Step 3: Commit the failing test checkpoint**

```bash
rtk git add tests/test_fetch_galay_repos.sh
rtk git commit -m "test: cover gitee fetch host selection"
```

## Task 2: Implement repo-host parsing and effective remote resolution

**Files:**
- Modify: `scripts/fetch_galay_repos.sh`
- Test: `tests/test_fetch_galay_repos.sh`

- [ ] **Step 1: Add `--repo-host` parsing with a default of `github`**

Replace the variable block and argument parsing start with:

```sh
MANIFEST_PATH="$SCRIPT_DIR/../manifest.json"
DRY_RUN=0
CHECKOUT_VERSION=1
REPO_HOST=github

while [ "$#" -gt 0 ]; do
    case "$1" in
        --manifest)
            shift
            [ "$#" -gt 0 ] || die "missing value for --manifest"
            MANIFEST_PATH=$1
            ;;
        --repo-host)
            shift
            [ "$#" -gt 0 ] || die "missing value for --repo-host"
            REPO_HOST=$1
            ;;
        --checkout-version)
            CHECKOUT_VERSION=1
            ;;
        --no-checkout-version)
            CHECKOUT_VERSION=0
            ;;
        --dry-run)
            DRY_RUN=1
            ;;
        *)
            die "unknown argument: $1"
            ;;
    esac
    shift
done

case "$REPO_HOST" in
    github|gitee)
        ;;
    *)
        die "unknown repo host: $REPO_HOST"
        ;;
esac
```

- [ ] **Step 2: Add a helper that resolves the effective repository URL**

Insert below `resolve_target_dir()`:

```sh
resolve_effective_repo() {
    repo_host=$1
    repo_name=$2
    repo_url=$3

    case "$repo_host" in
        github)
            printf '%s\n' "$repo_url"
            ;;
        gitee)
            printf 'https://gitee.com/glloveforever/%s.git\n' "$repo_name"
            ;;
    esac
}
```

- [ ] **Step 3: Use the effective repo for each source before clone/fetch**

Inside the main loop, after the existing repo/version validation, add:

```sh
effective_repo=$(resolve_effective_repo "$REPO_HOST" "$name" "$repo")
```

- [ ] **Step 4: Run the test to verify the parser and URL mapping now work**

Run:

```sh
rtk test sh tests/test_fetch_galay_repos.sh
```

Expected: the previous `unknown argument` failure is gone; the test may still fail until the fetch path updates `origin`.

- [ ] **Step 5: Commit the parser/resolution checkpoint**

```bash
rtk git add scripts/fetch_galay_repos.sh tests/test_fetch_galay_repos.sh
rtk git commit -m "feat: add fetch repo host selection"
```

## Task 3: Make existing clones switch `origin` and use effective remote logging

**Files:**
- Modify: `scripts/fetch_galay_repos.sh`
- Test: `tests/test_fetch_galay_repos.sh`

- [ ] **Step 1: Update the existing-repo branch to rewrite `origin` when needed**

Replace the existing `if [ -d "$target_dir/.git" ]; then` block with:

```sh
    if [ -d "$target_dir/.git" ]; then
        current_origin=$(git -C "$target_dir" remote get-url origin)
        if [ "$current_origin" != "$effective_repo" ]; then
            if [ "$DRY_RUN" -eq 1 ]; then
                log "dry-run: set origin of $name to $effective_repo"
            else
                log "set origin: $name -> $effective_repo"
                git -C "$target_dir" remote set-url origin "$effective_repo"
            fi
        fi

        if [ "$DRY_RUN" -eq 1 ]; then
            log "dry-run: fetch $name at $version in $target_dir from $effective_repo"
        else
            log "fetch: $name ($target_dir) @ $version from $effective_repo"
            git -C "$target_dir" fetch --depth 1 origin "$version"
        fi
    elif [ -d "$target_dir" ]; then
        die "target exists but is not a git repo: $target_dir"
    else
        if [ "$DRY_RUN" -eq 1 ]; then
            log "dry-run: clone $effective_repo@$version -> $target_dir"
        else
            log "clone: $name@$version from $effective_repo -> $target_dir"
            git clone --depth 1 --branch "$version" "$effective_repo" "$target_dir"
        fi
    fi
```

- [ ] **Step 2: Add a dry-run assertion for remote rewrite visibility**

Append this to `tests/test_fetch_galay_repos.sh` after the remote URL assertion:

```sh
DRY_RUN_OUTPUT=$(sh "$REPO_ROOT/scripts/fetch_galay_repos.sh" \
  --manifest "$BUNDLE_ROOT/manifest-gitee.json" \
  --repo-host gitee \
  --dry-run 2>&1)

case "$DRY_RUN_OUTPUT" in
  *"dry-run: fetch galay-sample at v1.0.0 in $BUNDLE_ROOT/galay-sample from https://gitee.com/glloveforever/galay-sample.git"*)
    ;;
  *)
    fail "expected dry-run output to mention gitee fetch URL"
    ;;
esac
```

- [ ] **Step 3: Run the test to verify the full fetch flow passes**

Run:

```sh
rtk test sh tests/test_fetch_galay_repos.sh
```

Expected: PASS and print `ok`.

- [ ] **Step 4: Commit the remote rewrite checkpoint**

```bash
rtk git add scripts/fetch_galay_repos.sh tests/test_fetch_galay_repos.sh
rtk git commit -m "fix: switch existing fetch remotes for gitee mode"
```

## Task 4: Document the new fetch mode in both READMEs

**Files:**
- Modify: `README.md`
- Modify: `README-CN.md`

- [ ] **Step 1: Update the English fetch section with the Gitee example**

Add this block below the default fetch command in `README.md`:

```md
Fetch from the mirrored Gitee namespace instead:

```sh
sh scripts/fetch_galay_repos.sh --manifest manifest.json --repo-host gitee
```
```

- [ ] **Step 2: Update the Chinese fetch section with the Gitee example**

Add this block below the default fetch command in `README-CN.md`:

```md
如需从 Gitee 镜像命名空间抓取：

```sh
sh scripts/fetch_galay_repos.sh --manifest manifest.json --repo-host gitee
```
```

- [ ] **Step 3: Run the fetch test again after the doc changes**

Run:

```sh
rtk test sh tests/test_fetch_galay_repos.sh
```

Expected: PASS and print `ok`.

- [ ] **Step 4: Commit the documentation checkpoint**

```bash
rtk git add README.md README-CN.md
rtk git commit -m "docs: describe gitee fetch mode"
```

## Task 5: Final verification before handoff

**Files:**
- Modify: `scripts/fetch_galay_repos.sh`
- Modify: `tests/test_fetch_galay_repos.sh`
- Modify: `README.md`
- Modify: `README-CN.md`

- [ ] **Step 1: Run the focused test suite**

Run:

```sh
rtk test sh tests/test_fetch_galay_repos.sh
```

Expected: PASS and print `ok`.

- [ ] **Step 2: Run a dry-run command against the real manifest**

Run:

```sh
sh scripts/fetch_galay_repos.sh --manifest manifest.json --repo-host gitee --dry-run
```

Expected: logs mention `https://gitee.com/glloveforever/<repo>.git` for each `galay-*` source and no files are modified.

- [ ] **Step 3: Inspect the final diff**

Run:

```sh
rtk git diff -- scripts/fetch_galay_repos.sh tests/test_fetch_galay_repos.sh README.md README-CN.md
```

Expected: diff shows only repo-host support, remote rewriting, test coverage, and README examples.

- [ ] **Step 4: Commit the final verification checkpoint**

```bash
rtk git add scripts/fetch_galay_repos.sh tests/test_fetch_galay_repos.sh README.md README-CN.md
rtk git commit -m "feat: support fetching galay repos from gitee"
```
