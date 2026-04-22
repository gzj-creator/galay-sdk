#!/bin/sh

set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
# shellcheck source=./lib/common.sh
. "$SCRIPT_DIR/lib/common.sh"
# shellcheck source=./lib/filters.sh
. "$SCRIPT_DIR/lib/filters.sh"

require_cmd git
require_cmd jq
require_cmd tar

MANIFEST_PATH=
DRY_RUN=0

while [ "$#" -gt 0 ]; do
    case "$1" in
        --manifest)
            shift
            [ "$#" -gt 0 ] || die "missing value for --manifest"
            MANIFEST_PATH=$1
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

[ -n "$MANIFEST_PATH" ] || die "--manifest is required"
[ -f "$MANIFEST_PATH" ] || die "manifest file not found: $MANIFEST_PATH"

MANIFEST_ABS=$(manifest_abspath "$MANIFEST_PATH")
BUNDLE_ROOT=$(bundle_root_from_manifest "$MANIFEST_ABS")
TODAY=$(today_ymd)
TEMP_ROOT=$(create_temp_dir)
WORKING_MANIFEST="$TEMP_ROOT/manifest.json"

cleanup() {
    rm -rf "$TEMP_ROOT"
}

trap cleanup EXIT INT TERM HUP

cp "$MANIFEST_ABS" "$WORKING_MANIFEST"

resolve_repo_path() {
    repo_field=$1
    local_path_field=$2

    if resolved=$(resolve_optional_path "$local_path_field" "$BUNDLE_ROOT" 2>/dev/null); then
        if [ -d "$resolved" ]; then
            printf '%s\n' "$resolved"
            return 0
        fi
    fi

    if resolved=$(resolve_optional_path "$repo_field" "$BUNDLE_ROOT" 2>/dev/null); then
        if [ -d "$resolved" ]; then
            printf '%s\n' "$resolved"
            return 0
        fi
    fi

    return 1
}

update_git_source_manifest() {
    index=$1
    source_type=$2
    repo=$3
    local_path=$4
    path=$5
    version=$6
    commit=$7

    NEXT_MANIFEST="$TEMP_ROOT/manifest.next.json"
    jq \
        --argjson idx "$index" \
        --arg source_type "$source_type" \
        --arg repo "$repo" \
        --arg local_path "$local_path" \
        --arg path "$path" \
        --arg version "$version" \
        --arg commit "$commit" \
        '
        .sources[$idx].source_type = $source_type |
        .sources[$idx].type = $source_type |
        .sources[$idx].repo = $repo |
        (if $local_path == "" then del(.sources[$idx].local_path) else .sources[$idx].local_path = $local_path end) |
        .sources[$idx].path = $path |
        .sources[$idx].version = $version |
        .sources[$idx].commit = $commit |
        del(.sources[$idx].captured_at)
        ' \
        "$WORKING_MANIFEST" > "$NEXT_MANIFEST"
    mv "$NEXT_MANIFEST" "$WORKING_MANIFEST"
}

update_local_source_manifest() {
    index=$1
    source_type=$2
    repo=$3
    local_path=$4
    path=$5
    captured_at=$6

    NEXT_MANIFEST="$TEMP_ROOT/manifest.next.json"
    jq \
        --argjson idx "$index" \
        --arg source_type "$source_type" \
        --arg repo "$repo" \
        --arg local_path "$local_path" \
        --arg path "$path" \
        --arg captured_at "$captured_at" \
        '
        .sources[$idx].source_type = $source_type |
        .sources[$idx].type = $source_type |
        .sources[$idx].repo = $repo |
        (if $local_path == "" then del(.sources[$idx].local_path) else .sources[$idx].local_path = $local_path end) |
        .sources[$idx].path = $path |
        .sources[$idx].commit = null |
        .sources[$idx].captured_at = $captured_at
        ' \
        "$WORKING_MANIFEST" > "$NEXT_MANIFEST"
    mv "$NEXT_MANIFEST" "$WORKING_MANIFEST"
}

update_release_date() {
    NEXT_MANIFEST="$TEMP_ROOT/manifest.next.json"
    jq --arg release_date "$TODAY" '.release_date = $release_date' "$WORKING_MANIFEST" > "$NEXT_MANIFEST"
    mv "$NEXT_MANIFEST" "$WORKING_MANIFEST"
}

sync_git_archive() {
    index=$1
    name=$2
    source_type=$3
    repo=$4
    local_path=$5
    path=$6
    version=$7

    [ -n "$version" ] || die "git-tag-archive source '$name' is missing version"

    target_dir="$BUNDLE_ROOT/$path"

    if repo_path=$(resolve_repo_path "$repo" "$local_path"); then
        commit=$(git -C "$repo_path" rev-parse "$version^{}") || die "failed to resolve tag '$version' in $repo_path"

        if [ "$DRY_RUN" -eq 1 ]; then
            log "dry-run: export $name from local repo $repo_path at $version -> $target_dir"
        else
            clean_dir "$target_dir"
            (
                cd "$repo_path"
                git archive --format=tar "$version"
            ) | (
                cd "$target_dir"
                tar -xf -
            )
            prune_generated_paths "$target_dir"
        fi
    else
        [ -n "$repo" ] || die "git-tag-archive source '$name' has neither usable repo nor local_path"
        clone_dir="$TEMP_ROOT/clone-$index"

        if [ "$DRY_RUN" -eq 1 ]; then
            log "dry-run: clone $repo at $version -> $target_dir"
            commit="dry-run"
        else
            git clone --quiet --depth 1 --branch "$version" "$repo" "$clone_dir" || die "failed to clone $repo at tag $version"
            commit=$(git -C "$clone_dir" rev-parse HEAD) || die "failed to resolve cloned commit for $name"
            clean_dir "$target_dir"
            (
                cd "$clone_dir"
                git archive --format=tar HEAD
            ) | (
                cd "$target_dir"
                tar -xf -
            )
            prune_generated_paths "$target_dir"
        fi
    fi

    if [ "$DRY_RUN" -eq 0 ]; then
        update_git_source_manifest "$index" "$source_type" "$repo" "$local_path" "$path" "$version" "$commit"
    fi
}

sync_local_snapshot() {
    index=$1
    name=$2
    source_type=$3
    repo=$4
    local_path=$5
    path=$6

    if source_path=$(resolve_repo_path "$repo" "$local_path"); then
        :
    else
        die "local-snapshot source '$name' requires an accessible local directory"
    fi

    target_dir="$BUNDLE_ROOT/$path"

    if [ "$DRY_RUN" -eq 1 ]; then
        log "dry-run: copy $name from $source_path -> $target_dir"
        return 0
    fi

    clean_dir "$target_dir"
    copy_tree "$source_path" "$target_dir"
    prune_generated_paths "$target_dir"
    update_local_source_manifest "$index" "$source_type" "$repo" "$local_path" "$path" "$TODAY"
}

source_count=$(jq '.sources | length' "$WORKING_MANIFEST")
index=0

while [ "$index" -lt "$source_count" ]; do
    name=$(jq -r ".sources[$index].name // empty" "$WORKING_MANIFEST")
    source_type=$(jq -r ".sources[$index].source_type // .sources[$index].type // empty" "$WORKING_MANIFEST")
    repo=$(jq -r ".sources[$index].repo // empty" "$WORKING_MANIFEST")
    local_path=$(jq -r ".sources[$index].local_path // empty" "$WORKING_MANIFEST")
    path=$(jq -r ".sources[$index].path // .sources[$index].name // empty" "$WORKING_MANIFEST")
    version=$(jq -r ".sources[$index].version // empty" "$WORKING_MANIFEST")

    [ -n "$name" ] || die "source at index $index is missing name"
    [ -n "$source_type" ] || die "source '$name' is missing source_type"
    [ -n "$path" ] || die "source '$name' is missing target path"

    case "$source_type" in
        git-tag-archive)
            sync_git_archive "$index" "$name" "$source_type" "$repo" "$local_path" "$path" "$version"
            ;;
        local-snapshot)
            sync_local_snapshot "$index" "$name" "$source_type" "$repo" "$local_path" "$path"
            ;;
        *)
            die "unsupported source_type '$source_type' for source '$name'"
            ;;
    esac

    index=$((index + 1))
done

if [ "$DRY_RUN" -eq 0 ]; then
    update_release_date
    cp "$WORKING_MANIFEST" "$MANIFEST_ABS"
fi
