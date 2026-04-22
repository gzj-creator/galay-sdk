#!/bin/sh

die() {
    printf '%s\n' "error: $*" >&2
    exit 1
}

log() {
    printf '%s\n' "$*" >&2
}

require_cmd() {
    command -v "$1" >/dev/null 2>&1 || die "required command not found: $1"
}

manifest_abspath() {
    manifest_path=$1
    manifest_dir=$(CDPATH= cd -- "$(dirname -- "$manifest_path")" && pwd)
    printf '%s/%s\n' "$manifest_dir" "$(basename -- "$manifest_path")"
}

resolve_optional_path() {
    candidate=$1
    base_dir=$2

    if [ -z "$candidate" ]; then
        return 1
    fi

    case "$candidate" in
        /*)
            printf '%s\n' "$candidate"
            ;;
        *)
            printf '%s/%s\n' "$base_dir" "$candidate"
            ;;
    esac
}

bundle_root_from_manifest() {
    dirname -- "$1"
}

create_temp_dir() {
    mktemp -d "${TMPDIR:-/tmp}/gdk.XXXXXX"
}

clean_dir() {
    target_dir=$1
    rm -rf "$target_dir"
    mkdir -p "$target_dir"
}

copy_tree() {
    source_dir=$1
    target_dir=$2

    mkdir -p "$target_dir"
    (
        cd "$source_dir"
        tar -cf - .
    ) | (
        cd "$target_dir"
        tar -xf -
    )
}

today_ymd() {
    date '+%Y-%m-%d'
}
