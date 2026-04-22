#!/bin/sh

set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
REPO_ROOT=$(CDPATH= cd -- "$SCRIPT_DIR/.." && pwd)
TMP_ROOT=$(mktemp -d "${TMPDIR:-/tmp}/gdk-sync-test.XXXXXX")

cleanup() {
    rm -rf "$TMP_ROOT"
}

trap cleanup EXIT INT TERM HUP

fail() {
    printf '%s\n' "FAIL: $*" >&2
    exit 1
}

assert_exists() {
    [ -e "$1" ] || fail "expected path to exist: $1"
}

assert_not_exists() {
    [ ! -e "$1" ] || fail "expected path to be absent: $1"
}

assert_eq() {
    [ "$1" = "$2" ] || fail "expected '$1' to equal '$2'"
}

GIT_SOURCE="$TMP_ROOT/git-source"
LOCAL_SOURCE="$TMP_ROOT/local-source"
BUNDLE_ROOT="$TMP_ROOT/bundle"

mkdir -p "$GIT_SOURCE" "$LOCAL_SOURCE" "$BUNDLE_ROOT"

git -C "$GIT_SOURCE" init -q
git -C "$GIT_SOURCE" config user.name "Test User"
git -C "$GIT_SOURCE" config user.email "test@example.com"

mkdir -p "$GIT_SOURCE/include" "$GIT_SOURCE/build"
printf '%s\n' "git header" > "$GIT_SOURCE/include/sample.h"
printf '%s\n' "artifact" > "$GIT_SOURCE/build/output.txt"
printf '%s\n' "trash" > "$GIT_SOURCE/.DS_Store"
mkdir -p "$GIT_SOURCE/benchmark/results/run-1"
printf '%s\n' "folded" > "$GIT_SOURCE/benchmark/results/run-1/server.folded"
mkdir -p "$GIT_SOURCE/.cache/clangd/index"
printf '%s\n' "index" > "$GIT_SOURCE/.cache/clangd/index/test.idx"
printf '%s\n' "log" > "$GIT_SOURCE/debug.log"
mkdir -p "$GIT_SOURCE/benchmark/compare/protocols/go-server"
printf '%s\n' "binary" > "$GIT_SOURCE/benchmark/compare/protocols/go-server/galay-http-go-proto-server"

git -C "$GIT_SOURCE" add include/sample.h build/output.txt .DS_Store benchmark/results/run-1/server.folded .cache/clangd/index/test.idx debug.log benchmark/compare/protocols/go-server/galay-http-go-proto-server
git -C "$GIT_SOURCE" commit -q -m "seed"
git -C "$GIT_SOURCE" tag v1.0.0

mkdir -p "$LOCAL_SOURCE/include" "$LOCAL_SOURCE/target"
printf '%s\n' "local header" > "$LOCAL_SOURCE/include/local.h"
printf '%s\n' "artifact" > "$LOCAL_SOURCE/target/cache.txt"
printf '%s\n' "trash" > "$LOCAL_SOURCE/.DS_Store"
mkdir -p "$LOCAL_SOURCE/.cache/clangd/index"
printf '%s\n' "index" > "$LOCAL_SOURCE/.cache/clangd/index/local.idx"
mkdir -p "$LOCAL_SOURCE/benchmark/results/run-2"
printf '%s\n' "folded" > "$LOCAL_SOURCE/benchmark/results/run-2/client.folded"
printf '%s\n' "log" > "$LOCAL_SOURCE/local.log"

mkdir -p "$BUNDLE_ROOT/galay-git" "$BUNDLE_ROOT/galay-local"
printf '%s\n' "stale" > "$BUNDLE_ROOT/galay-git/stale.txt"
printf '%s\n' "stale" > "$BUNDLE_ROOT/galay-local/stale.txt"

cat > "$BUNDLE_ROOT/manifest.json" <<EOF
{
  "bundle_name": "fixture-gdk",
  "bundle_version": "v9.9.9",
  "release_date": "2000-01-01",
  "sources": [
    {
      "name": "galay-git",
      "source_type": "git-tag-archive",
      "repo": "$GIT_SOURCE",
      "local_path": "$GIT_SOURCE",
      "path": "galay-git",
      "version": "v1.0.0",
      "commit": null
    },
    {
      "name": "galay-local",
      "source_type": "local-snapshot",
      "repo": "$LOCAL_SOURCE",
      "local_path": "$LOCAL_SOURCE",
      "path": "galay-local",
      "version": null,
      "commit": null,
      "captured_at": null
    }
  ]
}
EOF

sh "$REPO_ROOT/scripts/sync_bundle.sh" --manifest "$BUNDLE_ROOT/manifest.json"

assert_exists "$BUNDLE_ROOT/galay-git/include/sample.h"
assert_exists "$BUNDLE_ROOT/galay-local/include/local.h"
assert_not_exists "$BUNDLE_ROOT/galay-git/stale.txt"
assert_not_exists "$BUNDLE_ROOT/galay-local/stale.txt"
assert_not_exists "$BUNDLE_ROOT/galay-git/build"
assert_not_exists "$BUNDLE_ROOT/galay-local/target"
assert_not_exists "$BUNDLE_ROOT/galay-git/.DS_Store"
assert_not_exists "$BUNDLE_ROOT/galay-local/.DS_Store"
assert_not_exists "$BUNDLE_ROOT/galay-git/.cache"
assert_not_exists "$BUNDLE_ROOT/galay-local/.cache"
assert_not_exists "$BUNDLE_ROOT/galay-git/benchmark/results"
assert_not_exists "$BUNDLE_ROOT/galay-local/benchmark/results"
assert_not_exists "$BUNDLE_ROOT/galay-git/debug.log"
assert_not_exists "$BUNDLE_ROOT/galay-local/local.log"
assert_not_exists "$BUNDLE_ROOT/galay-git/benchmark/compare/protocols/go-server/galay-http-go-proto-server"

EXPECTED_COMMIT=$(git -C "$GIT_SOURCE" rev-parse "v1.0.0^{}")
ACTUAL_COMMIT=$(jq -r '.sources[0].commit' "$BUNDLE_ROOT/manifest.json")
CAPTURED_AT=$(jq -r '.sources[1].captured_at' "$BUNDLE_ROOT/manifest.json")
RELEASE_DATE=$(jq -r '.release_date' "$BUNDLE_ROOT/manifest.json")
TODAY=$(date '+%Y-%m-%d')

assert_eq "$EXPECTED_COMMIT" "$ACTUAL_COMMIT"
assert_eq "$TODAY" "$RELEASE_DATE"
[ "$CAPTURED_AT" != "null" ] || fail "expected local snapshot captured_at to be populated"

printf '%s\n' "ok"
