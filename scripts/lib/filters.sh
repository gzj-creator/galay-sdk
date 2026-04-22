#!/bin/sh

prune_generated_paths() {
    root_dir=$1

    find "$root_dir" \
        \( -type d \( -name '.git' -o -name '.cache' -o -name '.clangd' -o -name 'build' -o -name 'build-*' -o -name 'dist' -o -name 'target' -o -name 'tmp' -o -path '*/benchmark/results' \) \
           -o -type f \( -name '.DS_Store' -o -name '*.log' -o -name '*.folded' -o -name 'go-proto-client' -o -name 'go-proto-server' -o -name 'galay-http-go-proto-server' \) \) \
        -print | while IFS= read -r path; do
            rm -rf "$path"
        done
}

list_forbidden_paths() {
    root_dir=$1

    find "$root_dir" \
        \( -type d \( -name '.git' -o -name '.cache' -o -name '.clangd' -o -name 'build' -o -name 'build-*' -o -name 'dist' -o -name 'target' -o -name 'tmp' -o -path '*/benchmark/results' \) \
           -o -type f \( -name '.DS_Store' -o -name '*.log' -o -name '*.folded' -o -name 'go-proto-client' -o -name 'go-proto-server' -o -name 'galay-http-go-proto-server' \) \) \
        -print
}
