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

normalize_semver() {
    printf '%s\n' "$1" | sed 's/^[^0-9]*//'
}

version_gt() {
    lhs=$(normalize_semver "$1")
    rhs=$(normalize_semver "$2")

    awk -v lhs="$lhs" -v rhs="$rhs" '
        BEGIN {
            split(lhs, a, ".")
            split(rhs, b, ".")

            for (i = 1; i <= 3; ++i) {
                lhs_part = (a[i] == "" ? 0 : a[i]) + 0
                rhs_part = (b[i] == "" ? 0 : b[i]) + 0

                if (lhs_part > rhs_part) {
                    exit 0
                }
                if (lhs_part < rhs_part) {
                    exit 1
                }
            }

            exit 1
        }
    '
}

scan_required_package_version() {
    package_name=$1
    source_root=$2
    max_required=""

    while IFS= read -r file; do
        [ -n "$file" ] || continue

        matches=$(grep -hE "find_(package|dependency)\(${package_name}[[:space:]]+[0-9]+\.[0-9]+\.[0-9]+" "$file" || true)
        [ -n "$matches" ] || continue

        while IFS= read -r match; do
            [ -n "$match" ] || continue
            required=$(printf '%s\n' "$match" | sed -E "s/.*${package_name}[[:space:]]+([0-9]+\.[0-9]+\.[0-9]+).*/\\1/")
            if [ -z "$max_required" ] || version_gt "$required" "$max_required"; then
                max_required=$required
            fi
        done <<EOF_MATCHES
$matches
EOF_MATCHES
    done <<EOF_FILES
$(find "$source_root" -type f \( -name 'CMakeLists.txt' -o -name '*.cmake' -o -name '*.cmake.in' \))
EOF_FILES

    printf '%s\n' "$max_required"
}

scan_project_version() {
    source_root=$1
    cmake_file="$source_root/CMakeLists.txt"

    [ -f "$cmake_file" ] || return 0

    match=$(grep -E 'project\([^)]*VERSION[[:space:]]+[0-9]+\.[0-9]+\.[0-9]+' "$cmake_file" | head -n 1 || true)
    [ -n "$match" ] || return 0

    printf '%s\n' "$match" | sed -E 's/.*VERSION[[:space:]]+([0-9]+\.[0-9]+\.[0-9]+).*/\1/'
}

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
BUNDLED_KERNEL_VERSION=$(jq -r '.sources[] | select(.name == "galay-kernel") | .version // empty' "$MANIFEST_ABS" | head -n 1)
BUNDLED_KERNEL_VERSION=$(normalize_semver "$BUNDLED_KERNEL_VERSION")
BUNDLED_UTILS_VERSION=$(jq -r '.sources[] | select(.name == "galay-utils") | .version // empty' "$MANIFEST_ABS" | head -n 1)
BUNDLED_UTILS_VERSION=$(normalize_semver "$BUNDLED_UTILS_VERSION")
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

    if [ -n "$version" ]; then
        project_version=$(scan_project_version "$source_root")
        if [ -n "$project_version" ]; then
            manifest_version=$(normalize_semver "$version")
            project_version=$(normalize_semver "$project_version")
            [ "$project_version" = "$manifest_version" ] || die "project version mismatch for '$name': source=$project_version manifest=$manifest_version"
        fi
    fi

    if [ -n "$BUNDLED_KERNEL_VERSION" ] && [ "$name" != "galay-kernel" ]; then
        required_kernel_version=$(scan_required_package_version galay-kernel "$source_root")
        if [ -n "$required_kernel_version" ] && version_gt "$required_kernel_version" "$BUNDLED_KERNEL_VERSION"; then
            die "bundled galay-kernel version $BUNDLED_KERNEL_VERSION is lower than '$name' requirement $required_kernel_version"
        fi
    fi

    if [ -n "$BUNDLED_UTILS_VERSION" ] && [ "$name" != "galay-utils" ]; then
        required_utils_version=$(scan_required_package_version galay-utils "$source_root")
        if [ -n "$required_utils_version" ] && version_gt "$required_utils_version" "$BUNDLED_UTILS_VERSION"; then
            die "bundled galay-utils version $BUNDLED_UTILS_VERSION is lower than '$name' requirement $required_utils_version"
        fi
    fi

    index=$((index + 1))
done
