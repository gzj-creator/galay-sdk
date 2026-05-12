#!/usr/bin/env bash
set -euo pipefail

readonly SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
readonly REPOS=(
    galay-utils
    galay-kernel
    galay-ssl
    galay-http
    galay-rpc
    galay-mcp
    galay-redis
    galay-mail
    galay-mysql
    galay-mongo
    galay-etcd
)
readonly CONCURRENTQUEUE_REPO="concurrentqueue"

CONCURRENTQUEUE_ROOT="${CONCURRENTQUEUE_ROOT:-${HOME}/git/concurrentqueue}"
STAGE_ROOT="${STAGE_ROOT:-}"
KEEP_STAGE_DIR="${KEEP_STAGE_DIR:-0}"
OUT_DIR="${OUT_DIR:-${SCRIPT_DIR}/out}"

require_cmd() {
    command -v "$1" >/dev/null 2>&1 || {
        echo "missing command: $1" >&2
        exit 1
    }
}

detect_bundle_root() {
    git -C "${SCRIPT_DIR}" rev-parse --show-toplevel
}

detect_image_tag() {
    local bundle_root="$1"
    local git_tag

    git_tag="$(git -C "${bundle_root}" tag --points-at HEAD | sed -n '1p')"
    if [[ -n "${git_tag}" ]]; then
        printf '%s\n' "${git_tag}"
        return 0
    fi

    if [[ -f "${bundle_root}/VERSION" ]]; then
        tr -d '[:space:]' < "${bundle_root}/VERSION"
        return 0
    fi

    echo "failed to detect galay-sdk image tag from git tag or VERSION file" >&2
    exit 1
}

require_dir() {
    local path="$1"
    if [[ ! -d "${path}" ]]; then
        echo "missing directory: ${path}" >&2
        exit 1
    fi
}

require_cmd rsync
require_cmd git
require_cmd docker

BUNDLE_ROOT="${GALAY_SDK_ROOT:-$(detect_bundle_root)}"
IMAGE_TAG="${IMAGE_TAG:-$(detect_image_tag "${BUNDLE_ROOT}")}"
GALAY_DISABLE_IOURING="${GALAY_DISABLE_IOURING:-ON}"
COMPILE_IMAGE="${COMPILE_IMAGE:-galay-sdk-compile:${IMAGE_TAG}}"
RUNTIME_IMAGE="${RUNTIME_IMAGE:-galay-sdk-runtime:${IMAGE_TAG}}"
if [[ -n "${STAGE_ROOT}" ]]; then
    mkdir -p "${STAGE_ROOT}"
    STAGE_DIR="$(mktemp -d "${STAGE_ROOT%/}/galay-sdk-context.XXXXXX")"
else
    STAGE_DIR="$(mktemp -d /tmp/galay-sdk-context.XXXXXX)"
fi

cleanup() {
    if [[ "${KEEP_STAGE_DIR}" != "1" ]]; then
        rm -rf "${STAGE_DIR}"
    fi
}
trap cleanup EXIT

require_dir "${BUNDLE_ROOT}"
require_dir "${CONCURRENTQUEUE_ROOT}"

for repo in "${REPOS[@]}"; do
    require_dir "${BUNDLE_ROOT}/${repo}"
done

mkdir -p "${STAGE_DIR}/src" "${STAGE_DIR}/verify" "${STAGE_DIR}/out"
mkdir -p "${OUT_DIR}"

cp "${SCRIPT_DIR}/Dockerfile" "${STAGE_DIR}/Dockerfile"
cp "${SCRIPT_DIR}/build-all.sh" "${STAGE_DIR}/build-all.sh"
cp "${SCRIPT_DIR}/build-images.sh" "${STAGE_DIR}/build-images.sh"
cp "${SCRIPT_DIR}/context.dockerignore" "${STAGE_DIR}/.dockerignore"
rsync -a --delete "${SCRIPT_DIR}/verify/" "${STAGE_DIR}/verify/"

rsync -a --delete --exclude-from="${SCRIPT_DIR}/excludes.txt" \
    "${CONCURRENTQUEUE_ROOT}/" "${STAGE_DIR}/src/${CONCURRENTQUEUE_REPO}/"

for repo in "${REPOS[@]}"; do
    rsync -a --delete --exclude-from="${SCRIPT_DIR}/excludes.txt" \
        "${BUNDLE_ROOT}/${repo}/" "${STAGE_DIR}/src/${repo}/"
done

chmod +x "${STAGE_DIR}/build-all.sh" "${STAGE_DIR}/build-images.sh"

find "${STAGE_DIR}" -name '._*' -delete
find "${STAGE_DIR}" -name '.DS_Store' -delete

echo "bundle root: ${BUNDLE_ROOT}"
echo "concurrentqueue root: ${CONCURRENTQUEUE_ROOT}"
echo "image tag: ${IMAGE_TAG}"
echo "disable io_uring: ${GALAY_DISABLE_IOURING}"
echo "compile image: ${COMPILE_IMAGE}"
echo "runtime image: ${RUNTIME_IMAGE}"
echo "staged docker context: ${STAGE_DIR}"

(
    cd "${STAGE_DIR}"
    IMAGE_TAG="${IMAGE_TAG}" \
    GALAY_DISABLE_IOURING="${GALAY_DISABLE_IOURING}" \
    COMPILE_IMAGE="${COMPILE_IMAGE}" \
    RUNTIME_IMAGE="${RUNTIME_IMAGE}" \
    VERIFY_DIR="${SCRIPT_DIR}/verify" \
    OUT_DIR="${OUT_DIR}" \
    ./build-images.sh
)

if [[ "${KEEP_STAGE_DIR}" == "1" ]]; then
    echo "kept staged docker context: ${STAGE_DIR}"
fi
