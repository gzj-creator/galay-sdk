#!/bin/sh

set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
# shellcheck source=./lib/common.sh
. "$SCRIPT_DIR/lib/common.sh"

MANIFEST_PATH="$SCRIPT_DIR/../manifest.json"
DRY_RUN=0
BUILD_TYPE=Release
BUILD_DIR=build
INSTALL_PREFIX=
USE_SUDO=0
JOBS=

while [ "$#" -gt 0 ]; do
    case "$1" in
        --manifest)
            shift
            [ "$#" -gt 0 ] || die "missing value for --manifest"
            MANIFEST_PATH=$1
            ;;
        --build-type)
            shift
            [ "$#" -gt 0 ] || die "missing value for --build-type"
            BUILD_TYPE=$1
            ;;
        --build-dir)
            shift
            [ "$#" -gt 0 ] || die "missing value for --build-dir"
            BUILD_DIR=$1
            ;;
        --prefix)
            shift
            [ "$#" -gt 0 ] || die "missing value for --prefix"
            INSTALL_PREFIX=$1
            ;;
        --jobs)
            shift
            [ "$#" -gt 0 ] || die "missing value for --jobs"
            JOBS=$1
            ;;
        --sudo)
            USE_SUDO=1
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

require_cmd jq
require_cmd cmake

[ -f "$MANIFEST_PATH" ] || die "manifest file not found: $MANIFEST_PATH"

MANIFEST_ABS=$(manifest_abspath "$MANIFEST_PATH")
BUNDLE_ROOT=$(bundle_root_from_manifest "$MANIFEST_ABS")
if [ -z "$INSTALL_PREFIX" ]; then
    INSTALL_PREFIX="$BUNDLE_ROOT/.galay-prefix/latest"
fi

if [ -n "${CMAKE_PREFIX_PATH:-}" ]; then
    EFFECTIVE_PREFIX_PATH="$INSTALL_PREFIX;$CMAKE_PREFIX_PATH"
else
    EFFECTIVE_PREFIX_PATH="$INSTALL_PREFIX"
fi

is_built() {
    name=$1
    case " $BUILT_LIST " in
        *" $name "*) return 0 ;;
        *) return 1 ;;
    esac
}

build_source() {
    name=$1
    path=$(jq -r --arg name "$name" '.sources[] | select(.name == $name) | .path // .name // empty' "$MANIFEST_ABS" | head -n 1)
    [ -n "$path" ] || return 0

    source_dir="$BUNDLE_ROOT/$path"
    [ -d "$source_dir" ] || die "source directory not found for '$name': $source_dir"

    if [ ! -f "$source_dir/CMakeLists.txt" ]; then
        log "skip: $name has no CMakeLists.txt ($source_dir)"
        BUILT_LIST="$BUILT_LIST $name"
        return 0
    fi

    build_path="$source_dir/$BUILD_DIR"

    if [ "$DRY_RUN" -eq 1 ]; then
        log "dry-run: [$name] mkdir -p \"$build_path\""
        log "dry-run: [$name] cmake -S \"$source_dir\" -B \"$build_path\" -DCMAKE_BUILD_TYPE=$BUILD_TYPE -DCMAKE_INSTALL_PREFIX=\"$INSTALL_PREFIX\" -DCMAKE_PREFIX_PATH=\"$EFFECTIVE_PREFIX_PATH\""
        if [ -n "$JOBS" ]; then
            log "dry-run: [$name] cmake --build \"$build_path\" --parallel \"$JOBS\""
        else
            log "dry-run: [$name] cmake --build \"$build_path\" --parallel"
        fi
        if [ "$USE_SUDO" -eq 1 ]; then
            log "dry-run: [$name] sudo cmake --install \"$build_path\""
        else
            log "dry-run: [$name] cmake --install \"$build_path\""
        fi
        BUILT_LIST="$BUILT_LIST $name"
        return 0
    fi

    log "build/install: $name"
    mkdir -p "$build_path"
    cmake -S "$source_dir" -B "$build_path" -DCMAKE_BUILD_TYPE="$BUILD_TYPE" -DCMAKE_INSTALL_PREFIX="$INSTALL_PREFIX" -DCMAKE_PREFIX_PATH="$EFFECTIVE_PREFIX_PATH"
    if [ -n "$JOBS" ]; then
        cmake --build "$build_path" --parallel "$JOBS"
    else
        cmake --build "$build_path" --parallel
    fi
    if [ "$USE_SUDO" -eq 1 ]; then
        sudo cmake --install "$build_path"
    else
        cmake --install "$build_path"
    fi
    BUILT_LIST="$BUILT_LIST $name"
}

BUILT_LIST=""

# Build dependency roots first to avoid find_package version mismatches.
for name in galay-kernel galay-utils galay-ssl galay-http galay-rpc galay-mysql galay-mongo galay-redis galay-mail galay-mcp galay-etcd; do
    build_source "$name"
done

repo_count=$(jq '.sources | length' "$MANIFEST_ABS")
index=0
while [ "$index" -lt "$repo_count" ]; do
    name=$(jq -r ".sources[$index].name // empty" "$MANIFEST_ABS")
    index=$((index + 1))
    case "$name" in
        galay-*)
            if is_built "$name"; then
                continue
            fi
            build_source "$name"
            ;;
    esac
done

log "done: galay repositories were built and installed from $MANIFEST_ABS"
