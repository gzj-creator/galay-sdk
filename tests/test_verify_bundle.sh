#!/bin/sh

set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
REPO_ROOT=$(CDPATH= cd -- "$SCRIPT_DIR/.." && pwd)
TMP_ROOT=$(mktemp -d "${TMPDIR:-/tmp}/gdk-verify-test.XXXXXX")

cleanup() {
    rm -rf "$TMP_ROOT"
}

trap cleanup EXIT INT TERM HUP

fail() {
    printf '%s\n' "FAIL: $*" >&2
    exit 1
}

BUNDLE_ROOT="$TMP_ROOT/bundle"
SOURCE_ROOT="$BUNDLE_ROOT/galay-good"

mkdir -p "$SOURCE_ROOT/include"
printf '%s\n' "header" > "$SOURCE_ROOT/include/good.h"
printf '%s\n' "v1.2.3" > "$BUNDLE_ROOT/VERSION"

cat > "$BUNDLE_ROOT/README.md" <<'EOF'
# fixture

Bundle version: `v1.2.3`
EOF

cat > "$BUNDLE_ROOT/manifest.json" <<'EOF'
{
  "bundle_name": "fixture-gdk",
  "bundle_version": "v1.2.3",
  "release_date": "2026-04-22",
  "sources": [
    {
      "name": "galay-good",
      "source_type": "local-snapshot",
      "repo": "/tmp/source",
      "local_path": "/tmp/source",
      "path": "galay-good",
      "version": null,
      "commit": null,
      "captured_at": "2026-04-22"
    }
  ]
}
EOF

sh "$REPO_ROOT/scripts/verify_bundle.sh" --manifest "$BUNDLE_ROOT/manifest.json"

printf '%s\n' "v1.2.4" > "$BUNDLE_ROOT/VERSION"
if sh "$REPO_ROOT/scripts/verify_bundle.sh" --manifest "$BUNDLE_ROOT/manifest.json"; then
    fail "expected version mismatch to fail verification"
fi

printf '%s\n' "v1.2.3" > "$BUNDLE_ROOT/VERSION"
mkdir -p "$SOURCE_ROOT/build"
if sh "$REPO_ROOT/scripts/verify_bundle.sh" --manifest "$BUNDLE_ROOT/manifest.json"; then
    fail "expected generated directory to fail verification"
fi
rm -rf "$SOURCE_ROOT/build"

mkdir -p "$SOURCE_ROOT/.cache/clangd/index"
if sh "$REPO_ROOT/scripts/verify_bundle.sh" --manifest "$BUNDLE_ROOT/manifest.json"; then
    fail "expected editor cache to fail verification"
fi
rm -rf "$SOURCE_ROOT/.cache"

mkdir -p "$SOURCE_ROOT/benchmark/results/run-1"
if sh "$REPO_ROOT/scripts/verify_bundle.sh" --manifest "$BUNDLE_ROOT/manifest.json"; then
    fail "expected benchmark results to fail verification"
fi

KERNEL_ROOT="$BUNDLE_ROOT/galay-kernel"
HTTP_ROOT="$BUNDLE_ROOT/galay-http"
mkdir -p "$KERNEL_ROOT" "$HTTP_ROOT/cmake"
cat > "$KERNEL_ROOT/CMakeLists.txt" <<'EOF'
cmake_minimum_required(VERSION 3.16)
project(galay-kernel VERSION 3.4.4 LANGUAGES CXX)
EOF
cat > "$HTTP_ROOT/CMakeLists.txt" <<'EOF'
cmake_minimum_required(VERSION 3.22)
project(galay-http VERSION 2.1.2 LANGUAGES CXX)
find_package(galay-kernel 3.4.5 REQUIRED CONFIG)
EOF
cat > "$HTTP_ROOT/cmake/galay-http-config.cmake.in" <<'EOF'
@PACKAGE_INIT@
include(CMakeFindDependencyMacro)
find_dependency(galay-kernel 3.4.5 REQUIRED CONFIG)
EOF
cat > "$BUNDLE_ROOT/manifest.json" <<'EOF'
{
  "bundle_name": "fixture-gdk",
  "bundle_version": "v1.2.3",
  "release_date": "2026-04-22",
  "sources": [
    {
      "name": "galay-kernel",
      "source_type": "local-snapshot",
      "repo": "/tmp/galay-kernel",
      "local_path": "/tmp/galay-kernel",
      "path": "galay-kernel",
      "version": "v3.4.4",
      "commit": null,
      "captured_at": "2026-04-22"
    },
    {
      "name": "galay-http",
      "source_type": "local-snapshot",
      "repo": "/tmp/galay-http",
      "local_path": "/tmp/galay-http",
      "path": "galay-http",
      "version": "v2.1.2",
      "commit": null,
      "captured_at": "2026-04-22"
    }
  ]
}
EOF
if sh "$REPO_ROOT/scripts/verify_bundle.sh" --manifest "$BUNDLE_ROOT/manifest.json"; then
    fail "expected galay-http kernel version drift to fail verification"
fi

UTILS_ROOT="$BUNDLE_ROOT/galay-utils"
mkdir -p "$UTILS_ROOT"
cat > "$UTILS_ROOT/CMakeLists.txt" <<'EOF'
cmake_minimum_required(VERSION 3.16)
project(galay-utils VERSION 1.0.0 LANGUAGES CXX)
EOF
cat > "$BUNDLE_ROOT/manifest.json" <<'EOF'
{
  "bundle_name": "fixture-gdk",
  "bundle_version": "v1.2.3",
  "release_date": "2026-04-22",
  "sources": [
    {
      "name": "galay-utils",
      "source_type": "local-snapshot",
      "repo": "/tmp/galay-utils",
      "local_path": "/tmp/galay-utils",
      "path": "galay-utils",
      "version": "v1.2.0",
      "commit": null,
      "captured_at": "2026-04-22"
    }
  ]
}
EOF
if sh "$REPO_ROOT/scripts/verify_bundle.sh" --manifest "$BUNDLE_ROOT/manifest.json"; then
    fail "expected galay-utils project version drift to fail verification"
fi

ETCD_ROOT="$BUNDLE_ROOT/galay-etcd"
mkdir -p "$ETCD_ROOT"
cat > "$ETCD_ROOT/CMakeLists.txt" <<'EOF'
cmake_minimum_required(VERSION 3.20)
project(galay-etcd VERSION 1.1.8 LANGUAGES CXX)
find_package(galay-utils 1.0.3 CONFIG REQUIRED)
EOF
cat > "$UTILS_ROOT/CMakeLists.txt" <<'EOF'
cmake_minimum_required(VERSION 3.16)
project(galay-utils VERSION 1.0.2 LANGUAGES CXX)
EOF
cat > "$BUNDLE_ROOT/manifest.json" <<'EOF'
{
  "bundle_name": "fixture-gdk",
  "bundle_version": "v1.2.3",
  "release_date": "2026-04-22",
  "sources": [
    {
      "name": "galay-utils",
      "source_type": "local-snapshot",
      "repo": "/tmp/galay-utils",
      "local_path": "/tmp/galay-utils",
      "path": "galay-utils",
      "version": "v1.0.2",
      "commit": null,
      "captured_at": "2026-04-22"
    },
    {
      "name": "galay-etcd",
      "source_type": "local-snapshot",
      "repo": "/tmp/galay-etcd",
      "local_path": "/tmp/galay-etcd",
      "path": "galay-etcd",
      "version": "v1.1.8",
      "commit": null,
      "captured_at": "2026-04-22"
    }
  ]
}
EOF
if sh "$REPO_ROOT/scripts/verify_bundle.sh" --manifest "$BUNDLE_ROOT/manifest.json"; then
    fail "expected galay-utils dependency drift to fail verification"
fi

printf '%s\n' "ok"
