# Fetch Galay Repos Shallow Version Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Update `scripts/fetch_galay_repos.sh` so every `galay-*` source requires `version` and clone/fetch operations only retrieve the requested version shallowly.

**Architecture:** Keep the script structure unchanged and make the smallest possible behavior change inside the existing manifest loop. Enforce `version` as a required manifest field for `galay-*` entries, then route both clone and fetch paths through shallow, version-targeted git commands before detached checkout.

**Tech Stack:** POSIX shell, git, jq

---

### Task 1: Enforce required version in manifest entries

**Files:**
- Modify: `scripts/fetch_galay_repos.sh:59-75`
- Test: manual shell execution with a manifest entry missing `version`

- [ ] **Step 1: Add a failing validation check in the manifest loop**

```sh
    version=$(jq -r ".sources[$index].version // empty" "$MANIFEST_ABS")

    case "$name" in
        galay-*)
            ;;
        *)
            continue
            ;;
    esac

    [ -n "$repo" ] || die "source '$name' is missing repo"
    [ -n "$version" ] || die "source '$name' is missing version"
```

- [ ] **Step 2: Run the script with a manifest entry that omits version**

Run:
```bash
cp manifest.json /tmp/manifest-missing-version.json && jq '(.sources[0].version)=null' /tmp/manifest-missing-version.json > /tmp/manifest-missing-version-fixed.json && mv /tmp/manifest-missing-version-fixed.json /tmp/manifest-missing-version.json && ./scripts/fetch_galay_repos.sh --manifest /tmp/manifest-missing-version.json --dry-run
```
Expected: FAIL with `error: source 'galay-etcd' is missing version`

- [ ] **Step 3: Keep the validation in place as the minimal implementation**

```sh
    [ -n "$repo" ] || die "source '$name' is missing repo"
    [ -n "$version" ] || die "source '$name' is missing version"
```

- [ ] **Step 4: Re-run the missing-version command to verify the failure is explicit**

Run:
```bash
./scripts/fetch_galay_repos.sh --manifest /tmp/manifest-missing-version.json --dry-run
```
Expected: FAIL with `error: source 'galay-etcd' is missing version`

- [ ] **Step 5: Commit**

```bash
git add scripts/fetch_galay_repos.sh
git commit -m "fix: require version in galay sources"
```

### Task 2: Use shallow version-targeted clone and fetch

**Files:**
- Modify: `scripts/fetch_galay_repos.sh:87-117`
- Test: manual dry-run output and one real clone/fetch against a versioned source

- [ ] **Step 1: Replace full clone and full fetch with shallow version-targeted commands**

```sh
    if [ -d "$target_dir/.git" ]; then
        if [ "$DRY_RUN" -eq 1 ]; then
            log "dry-run: fetch $name at $version in $target_dir"
        else
            log "fetch: $name ($target_dir) @ $version"
            git -C "$target_dir" fetch --depth 1 origin "$version"
        fi
    elif [ -d "$target_dir" ]; then
        die "target exists but is not a git repo: $target_dir"
    else
        if [ "$DRY_RUN" -eq 1 ]; then
            log "dry-run: clone $repo@$version -> $target_dir"
        else
            log "clone: $name@$version -> $target_dir"
            git clone --depth 1 --branch "$version" "$repo" "$target_dir"
        fi
    fi
```

- [ ] **Step 2: Run dry-run to verify the new version-specific actions are announced**

Run:
```bash
./scripts/fetch_galay_repos.sh --dry-run
```
Expected: PASS and log lines like `dry-run: clone https://...@v1.1.8 -> ...` or `dry-run: fetch galay-etcd at v1.1.8 in ...`

- [ ] **Step 3: Keep detached checkout behavior after shallow clone/fetch**

```sh
    if [ -n "$(git -C "$target_dir" status --porcelain)" ]; then
        log "skip checkout for $name: working tree is dirty ($target_dir)"
        continue
    fi

    log "checkout: $name -> $version"
    git -C "$target_dir" checkout --detach "$version"
```

- [ ] **Step 4: Run one real repository sync to verify shallow version fetch still checks out correctly**

Run:
```bash
./scripts/fetch_galay_repos.sh --manifest manifest.json
```
Expected: PASS for versioned repos, with clone/fetch logs mentioning the version and checkout succeeding on detached HEAD

- [ ] **Step 5: Commit**

```bash
git add scripts/fetch_galay_repos.sh
git commit -m "perf: shallow fetch galay repos by version"
```

### Task 3: Verify unchanged safety behavior

**Files:**
- Modify: none
- Test: manual shell execution against dirty repo and non-git directory scenarios

- [ ] **Step 1: Verify dirty working tree still skips checkout**

Run:
```bash
mkdir -p /tmp/galay-dirty-check && rm -rf /tmp/galay-dirty-check/galay-etcd && git clone --depth 1 --branch v1.1.8 https://github.com/gzj-creator/galay-etcd.git /tmp/galay-dirty-check/galay-etcd && touch /tmp/galay-dirty-check/galay-etcd/local-change && jq '.sources |= map(if .name == "galay-etcd" then .local_path = "/tmp/galay-dirty-check/galay-etcd" else . end)' manifest.json > /tmp/manifest-dirty.json && ./scripts/fetch_galay_repos.sh --manifest /tmp/manifest-dirty.json
```
Expected: PASS with log `skip checkout for galay-etcd: working tree is dirty ...`

- [ ] **Step 2: Verify existing non-git directory still fails fast**

Run:
```bash
mkdir -p /tmp/galay-nongit/galay-etcd && jq '.sources |= map(if .name == "galay-etcd" then .local_path = "/tmp/galay-nongit/galay-etcd" else . end)' manifest.json > /tmp/manifest-nongit.json && ./scripts/fetch_galay_repos.sh --manifest /tmp/manifest-nongit.json --dry-run
```
Expected: FAIL with `error: target exists but is not a git repo: /tmp/galay-nongit/galay-etcd`

- [ ] **Step 3: Confirm no other script behavior changed**

Run:
```bash
./scripts/fetch_galay_repos.sh --dry-run
```
Expected: PASS and all `galay-*` entries are processed in order with version-specific clone/fetch messages

- [ ] **Step 4: Commit**

```bash
git add scripts/fetch_galay_repos.sh
git commit -m "test: verify fetch script safety behavior"
```
