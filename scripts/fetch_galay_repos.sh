#!/bin/sh

set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
# shellcheck source=./lib/common.sh
. "$SCRIPT_DIR/lib/common.sh"

MANIFEST_PATH="$SCRIPT_DIR/../manifest.json"
DRY_RUN=0
CHECKOUT_VERSION=1
REPO_PROTOCOL=https

while [ "$#" -gt 0 ]; do
    case "$1" in
        --manifest)
            shift
            [ "$#" -gt 0 ] || die "missing value for --manifest"
            MANIFEST_PATH=$1
            ;;
        --repo-protocol)
            shift
            [ "$#" -gt 0 ] || die "missing value for --repo-protocol"
            REPO_PROTOCOL=$1
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

case "$REPO_PROTOCOL" in
    https|ssh)
        ;;
    *)
        die "unknown repo protocol: $REPO_PROTOCOL"
        ;;
esac

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

repo_to_ssh_url() {
    repo_url=$1

    case "$repo_url" in
        git@*:*|ssh://*)
            printf '%s\n' "$repo_url"
            return 0
            ;;
        https://*/*)
            repo_part=${repo_url#https://}
            ;;
        http://*/*)
            repo_part=${repo_url#http://}
            ;;
        *)
            die "cannot convert repo to ssh URL: $repo_url"
            ;;
    esac

    repo_host=${repo_part%%/*}
    repo_path=${repo_part#*/}

    [ -n "$repo_host" ] || die "cannot convert repo to ssh URL: $repo_url"
    [ -n "$repo_path" ] || die "cannot convert repo to ssh URL: $repo_url"

    printf 'git@%s:%s\n' "$repo_host" "$repo_path"
}

resolve_effective_repo() {
    repo_protocol=$1
    repo_url=$2

    case "$repo_protocol" in
        https)
            printf '%s\n' "$repo_url"
            ;;
        ssh)
            repo_to_ssh_url "$repo_url"
            ;;
    esac
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

    effective_repo=$(resolve_effective_repo "$REPO_PROTOCOL" "$repo")
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
        current_origin=$(git -C "$target_dir" remote get-url origin 2>/dev/null || printf '')
        if [ "$current_origin" != "$effective_repo" ]; then
            if [ "$DRY_RUN" -eq 1 ]; then
                log "dry-run: set origin of $name to $effective_repo"
            else
                log "set origin: $name -> $effective_repo"
                if [ -n "$current_origin" ]; then
                    git -C "$target_dir" remote set-url origin "$effective_repo"
                else
                    git -C "$target_dir" remote add origin "$effective_repo"
                fi
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
