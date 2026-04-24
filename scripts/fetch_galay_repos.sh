#!/bin/sh

set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
# shellcheck source=./lib/common.sh
. "$SCRIPT_DIR/lib/common.sh"

MANIFEST_PATH="$SCRIPT_DIR/../manifest.json"
DRY_RUN=0
CHECKOUT_VERSION=1

while [ "$#" -gt 0 ]; do
    case "$1" in
        --manifest)
            shift
            [ "$#" -gt 0 ] || die "missing value for --manifest"
            MANIFEST_PATH=$1
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

require_cmd git
require_cmd jq

[ -f "$MANIFEST_PATH" ] || die "manifest file not found: $MANIFEST_PATH"

MANIFEST_ABS=$(manifest_abspath "$MANIFEST_PATH")
BUNDLE_ROOT=$(bundle_root_from_manifest "$MANIFEST_ABS")

resolve_target_dir() {
    local_path=$1
    repo_name=$2

    if resolved=$(resolve_optional_path "$local_path" "$BUNDLE_ROOT" 2>/dev/null); then
        printf '%s\n' "$resolved"
        return 0
    fi

    printf '%s/%s\n' "$BUNDLE_ROOT" "$repo_name"
}

repo_count=$(jq '.sources | length' "$MANIFEST_ABS")
index=0

while [ "$index" -lt "$repo_count" ]; do
    name=$(jq -r ".sources[$index].name // empty" "$MANIFEST_ABS")
    repo=$(jq -r ".sources[$index].repo // empty" "$MANIFEST_ABS")
    local_path=$(jq -r ".sources[$index].local_path // empty" "$MANIFEST_ABS")
    version=$(jq -r ".sources[$index].version // empty" "$MANIFEST_ABS")

    index=$((index + 1))

    case "$name" in
        galay-*)
            ;;
        *)
            continue
            ;;
    esac

    [ -n "$repo" ] || die "source '$name' is missing repo"
    [ -n "$version" ] || die "source '$name' is missing version"

    target_dir=$(resolve_target_dir "$local_path" "$name")
    target_parent=$(dirname -- "$target_dir")

    if [ ! -d "$target_parent" ]; then
        if [ "$DRY_RUN" -eq 1 ]; then
            log "dry-run: mkdir -p $target_parent"
        else
            mkdir -p "$target_parent"
        fi
    fi

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

    if [ "$CHECKOUT_VERSION" -eq 1 ]; then
        if [ "$DRY_RUN" -eq 1 ]; then
            log "dry-run: checkout $name to $version"
            continue
        fi

        if [ -n "$(git -C "$target_dir" status --porcelain)" ]; then
            log "skip checkout for $name: working tree is dirty ($target_dir)"
            continue
        fi

        log "checkout: $name -> $version"
        git -C "$target_dir" checkout --detach "$version"
    fi
done

log "done: galay repositories are fetched from $MANIFEST_ABS"
