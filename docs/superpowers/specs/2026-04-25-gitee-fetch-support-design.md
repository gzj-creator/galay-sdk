# 2026-04-25 Gitee fetch support design

## Background
The current fetch workflow reads each `sources[*].repo` from `manifest.json` and uses that URL directly in `scripts/fetch_galay_repos.sh`. Today the manifest only contains GitHub repository URLs, so the bundle fetch flow cannot pull from Gitee without editing the manifest.

The requested change is to keep the manifest unchanged and add a fetch-time option that switches `galay-*` repository fetches to the Gitee namespace `https://gitee.com/glloveforever/`.

## Goals
- Add Gitee fetch support to `scripts/fetch_galay_repos.sh`.
- Keep the default behavior unchanged for existing GitHub-based workflows.
- Avoid changing `manifest.json` structure.
- Make dry-run and normal logs show the actual remote URL being used.

## Non-goals
- No changes to `verify_bundle.sh`, `sync_bundle.sh`, or `install_galay_repos.sh`.
- No per-repository override in the manifest.
- No support for arbitrary custom host/user combinations in this change.

## CLI design
Add a new optional argument:

```sh
--repo-host github|gitee
```

Behavior:
- Default: `github`
- `github`: use `sources[*].repo` exactly as declared in `manifest.json`
- `gitee`: ignore the manifest owner/host for `galay-*` repositories and resolve the remote URL as `https://gitee.com/glloveforever/<name>.git`

Examples:

```sh
sh scripts/fetch_galay_repos.sh --manifest manifest.json
sh scripts/fetch_galay_repos.sh --manifest manifest.json --repo-host gitee
```

## URL resolution rules
Add a small URL resolution step before clone/fetch.

### Rule set
For each source already accepted by the existing `galay-*` name filter:

1. Read `name`, `repo`, `version`, and `local_path` as today.
2. Resolve the effective repository URL:
   - When `repo_host=github`, `effective_repo = repo`
   - When `repo_host=gitee`, `effective_repo = https://gitee.com/glloveforever/<name>.git`
3. Use `effective_repo` for clone logging and clone execution.
4. For existing local repos, keep fetch against `origin` but log the effective repo choice for visibility.

### Why the repository name is derived from `name`
The user confirmed that Gitee mode must switch both host and account to a fixed namespace:

```text
https://gitee.com/glloveforever/
```

That means the manifest URL is not the source of truth in Gitee mode except for identifying which repo is being processed. The script should therefore derive the final URL from the source `name`.

## Existing clone/fetch behavior
The current script does two different things:
- If the target repo does not exist, it runs `git clone --depth 1 --branch "$version" "$repo" "$target_dir"`
- If the repo already exists, it runs `git -C "$target_dir" fetch --depth 1 origin "$version"`

This design intentionally preserves that structure.

### Implication in Gitee mode
For newly cloned repos in Gitee mode, `origin` will naturally point to the Gitee URL.
For repos that were previously cloned from GitHub, `origin` will still point to GitHub, so a later `--repo-host gitee` fetch would still fetch from the existing GitHub origin unless the script also updates the remote URL.

To keep the behavior aligned with the user's request to "support fetching from Gitee", the script should update `origin` to the effective repo URL when `--repo-host gitee` is selected and the current `origin` differs.

## Remote update behavior
Before fetching an existing repo:

1. Read the current `origin` URL.
2. Compare it with `effective_repo`.
3. If different:
   - In dry-run mode, log that `origin` would be updated.
   - Otherwise run:

```sh
git -C "$target_dir" remote set-url origin "$effective_repo"
```

4. Continue with the existing fetch flow.

This ensures that `--repo-host gitee` truly fetches from Gitee even for repositories cloned earlier from GitHub.

## Error handling
- Unknown `--repo-host` value: fail fast with `die "unknown repo host: ..."`
- Missing `repo` in manifest: keep the existing validation unchanged, because GitHub mode still depends on it and the manifest remains authoritative input.
- Missing `name`: keep the existing behavior path; sources without valid `galay-*` names are skipped as they are today.
- If a mapped Gitee repository does not exist or the tag is missing, let the underlying `git` command fail naturally.

## Logging and dry-run
Logs should show the effective remote URL so the operator can verify which upstream is being used.

Suggested examples:

```text
clone: galay-http@v2.1.2 from https://gitee.com/glloveforever/galay-http.git -> /path/to/galay-http
fetch: galay-http (/path/to/galay-http) @ v2.1.2 from https://gitee.com/glloveforever/galay-http.git
```

When the script changes an existing remote in dry-run mode, log it explicitly:

```text
dry-run: set origin of galay-http to https://gitee.com/glloveforever/galay-http.git
```

## Documentation changes
Update both:
- `README-CN.md`
- `README.md`

Add one example command showing Gitee mode:

```sh
sh scripts/fetch_galay_repos.sh --manifest manifest.json --repo-host gitee
```

Also briefly explain that Gitee mode maps all `galay-*` fetches to `gitee.com/glloveforever`.

## Testing plan
Manual verification should cover:

1. Default mode
   - Run fetch without `--repo-host`
   - Confirm behavior is unchanged

2. Gitee clone path
   - Remove or use a fresh target directory
   - Run with `--repo-host gitee`
   - Confirm clone uses `https://gitee.com/glloveforever/<repo>.git`

3. Gitee fetch path on existing GitHub clone
   - Start from an already cloned repo whose `origin` is GitHub
   - Run with `--repo-host gitee`
   - Confirm `origin` is updated and fetch uses Gitee

4. Dry-run visibility
   - Run with `--dry-run --repo-host gitee`
   - Confirm logs show remote URL changes and clone/fetch targets

## Scope check
This spec remains focused on a single implementation plan:
- one script behavior change
- small README updates
- no manifest schema change
- no multi-script configuration rollout
