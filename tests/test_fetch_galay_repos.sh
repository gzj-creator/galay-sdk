#!/bin/sh

set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
REPO_ROOT=$(CDPATH= cd -- "$SCRIPT_DIR/.." && pwd)
TMP_ROOT=$(mktemp -d "${TMPDIR:-/tmp}/gdk-fetch-test.XXXXXX")

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

SOURCE_REPO="$TMP_ROOT/source-repo"
BUNDLE_ROOT="$TMP_ROOT/workspace"

mkdir -p "$SOURCE_REPO" "$BUNDLE_ROOT"

git -C "$SOURCE_REPO" init -q
git -C "$SOURCE_REPO" config user.name "Test User"
git -C "$SOURCE_REPO" config user.email "test@example.com"

printf '%s\n' "v1" > "$SOURCE_REPO/sample.txt"
git -C "$SOURCE_REPO" add sample.txt
git -C "$SOURCE_REPO" commit -q -m "v1"
git -C "$SOURCE_REPO" tag v1.0.0
TAG_COMMIT=$(git -C "$SOURCE_REPO" rev-parse "v1.0.0^{}")

printf '%s\n' "main head" > "$SOURCE_REPO/sample.txt"
git -C "$SOURCE_REPO" add sample.txt
git -C "$SOURCE_REPO" commit -q -m "head"
HEAD_COMMIT=$(git -C "$SOURCE_REPO" rev-parse HEAD)

[ "$TAG_COMMIT" != "$HEAD_COMMIT" ] || fail "fixture requires head commit to differ from tagged commit"

cat > "$BUNDLE_ROOT/manifest.json" <<EOF
{
  "bundle_name": "fixture-gdk",
  "bundle_version": "v9.9.9",
  "release_date": "2000-01-01",
  "sources": [
    {
      "name": "galay-sample",
      "source_type": "git-tag-archive",
      "repo": "$SOURCE_REPO",
      "path": "galay-sample",
      "version": "v1.0.0",
      "commit": null
    }
  ]
}
EOF

sh "$REPO_ROOT/scripts/fetch_galay_repos.sh" --manifest "$BUNDLE_ROOT/manifest.json"

assert_exists "$BUNDLE_ROOT/galay-sample/.git"
assert_not_exists "$TMP_ROOT/galay-sample/.git"

ACTUAL_COMMIT=$(git -C "$BUNDLE_ROOT/galay-sample" rev-parse HEAD)
ACTUAL_TAG=$(git -C "$BUNDLE_ROOT/galay-sample" describe --tags --exact-match HEAD)

assert_eq "$TAG_COMMIT" "$ACTUAL_COMMIT"
assert_eq "v1.0.0" "$ACTUAL_TAG"

printf '%s\n' "ok"
