# 2026-04-24 fetch-galay-repos shallow version design

## Goal

Speed up `scripts/fetch_galay_repos.sh` by fetching only the requested repository version instead of full history and full tags.

## Decisions

1. Every `galay-*` source entry must include a non-empty `version`.
2. If `version` is missing or empty, the script exits with an error for that source.
3. When cloning a missing repository, use shallow clone of the requested version:
   - `git clone --depth 1 --branch "$version" "$repo" "$target_dir"`
4. When updating an existing git repository, fetch only the requested version shallowly:
   - `git -C "$target_dir" fetch --depth 1 origin "$version"`
5. Keep the existing dirty working tree protection:
   - if `git status --porcelain` is non-empty, skip checkout
6. Keep the existing safety behavior for non-git directories:
   - if target directory exists without `.git`, exit with error
7. Continue checking out the requested version in detached HEAD mode after clone/fetch.

## Non-goals

- No archive download flow
- No fallback full clone/fetch when `version` is absent
- No automatic backup or cleanup of non-git directories

## Expected behavior

- Faster clone/fetch for fixed-version manifests
- Clear failure when manifest entries are incomplete
- Existing local safety checks remain unchanged
