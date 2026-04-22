#!/bin/sh

set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
# shellcheck source=./lib/common.sh
. "$SCRIPT_DIR/lib/common.sh"
# shellcheck source=./lib/filters.sh
. "$SCRIPT_DIR/lib/filters.sh"

require_cmd jq

MANIFEST_PATH=

while [ "$#" -gt 0 ]; do
    case "$1" in
        --manifest)
            shift
            [ "$#" -gt 0 ] || die "missing value for --manifest"
            MANIFEST_PATH=$1
            ;;
        *)
            die "unknown argument: $1"
            ;;
    esac
    shift
done

[ -n "$MANIFEST_PATH" ] || die "--manifest is required"
[ -f "$MANIFEST_PATH" ] || die "manifest file not found: $MANIFEST_PATH"

MANIFEST_ABS=$(manifest_abspath "$MANIFEST_PATH")
BUNDLE_ROOT=$(bundle_root_from_manifest "$MANIFEST_ABS")
BUNDLE_VERSION=$(jq -r '.bundle_version // empty' "$MANIFEST_ABS")

[ -n "$BUNDLE_VERSION" ] || die "bundle_version is missing from manifest"

VERSION_FILE="$BUNDLE_ROOT/VERSION"
[ -f "$VERSION_FILE" ] || die "VERSION file is missing: $VERSION_FILE"

VERSION_CONTENT=$(tr -d '\r\n' < "$VERSION_FILE")
[ "$VERSION_CONTENT" = "$BUNDLE_VERSION" ] || die "VERSION mismatch: VERSION=$VERSION_CONTENT manifest=$BUNDLE_VERSION"

README_FILE="$BUNDLE_ROOT/README.md"
[ -f "$README_FILE" ] || die "README.md is missing: $README_FILE"
grep -F "$BUNDLE_VERSION" "$README_FILE" >/dev/null 2>&1 || die "README.md does not mention bundle version $BUNDLE_VERSION"

resolve_expected_commit() {
    repo=$1
    local_path=$2
    version=$3

    if repo_path=$(resolve_optional_path "$local_path" "$BUNDLE_ROOT" 2>/dev/null); then
        if [ -d "$repo_path" ]; then
            git -C "$repo_path" rev-parse "$version^{}"
            return 0
        fi
    fi

    if repo_path=$(resolve_optional_path "$repo" "$BUNDLE_ROOT" 2>/dev/null); then
        if [ -d "$repo_path" ]; then
            git -C "$repo_path" rev-parse "$version^{}"
            return 0
        fi
    fi

    require_cmd git
    refs=$(git ls-remote --tags "$repo" "$version" "$version^{}") || return 1
    expected=$(printf '%s\n' "$refs" | awk -v ref="refs/tags/$version^{}" '$2 == ref { print $1; exit }')

    if [ -n "$expected" ]; then
        printf '%s\n' "$expected"
        return 0
    fi

    expected=$(printf '%s\n' "$refs" | awk -v ref="refs/tags/$version" '$2 == ref { print $1; exit }')
    [ -n "$expected" ] || return 1
    printf '%s\n' "$expected"
}

source_count=$(jq '.sources | length' "$MANIFEST_ABS")
index=0

while [ "$index" -lt "$source_count" ]; do
    name=$(jq -r ".sources[$index].name // empty" "$MANIFEST_ABS")
    source_type=$(jq -r ".sources[$index].source_type // .sources[$index].type // empty" "$MANIFEST_ABS")
    repo=$(jq -r ".sources[$index].repo // empty" "$MANIFEST_ABS")
    local_path=$(jq -r ".sources[$index].local_path // empty" "$MANIFEST_ABS")
    path=$(jq -r ".sources[$index].path // .sources[$index].name // empty" "$MANIFEST_ABS")
    version=$(jq -r ".sources[$index].version // empty" "$MANIFEST_ABS")
    commit=$(jq -r ".sources[$index].commit // empty" "$MANIFEST_ABS")
    source_root="$BUNDLE_ROOT/$path"

    [ -n "$name" ] || die "source at index $index is missing name"
    [ -n "$source_type" ] || die "source '$name' is missing source_type"
    [ -d "$source_root" ] || die "declared source path is missing: $source_root"

    forbidden=$(list_forbidden_paths "$source_root" || true)
    [ -z "$forbidden" ] || die "forbidden generated content found under $source_root:\n$forbidden"

    if [ "$source_type" = "git-tag-archive" ]; then
        [ -n "$version" ] || die "git-tag-archive source '$name' is missing version"
        [ -n "$commit" ] || die "git-tag-archive source '$name' is missing commit"
        expected_commit=$(resolve_expected_commit "$repo" "$local_path" "$version") || die "failed to resolve expected commit for '$name'"
        [ "$expected_commit" = "$commit" ] || die "commit mismatch for '$name': manifest=$commit expected=$expected_commit"
    fi

    index=$((index + 1))
done
