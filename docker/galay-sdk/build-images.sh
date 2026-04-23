#!/usr/bin/env bash
set -euo pipefail

readonly ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
readonly VERIFY_DIR="${VERIFY_DIR:-${ROOT_DIR}/verify}"
readonly OUT_DIR="${OUT_DIR:-${ROOT_DIR}/out}"

IMAGE_TAG="${IMAGE_TAG:-dev}"
RUNTIME_IMAGE_EPOLL="${RUNTIME_IMAGE_EPOLL:-galay-sdk-epoll:${IMAGE_TAG}}"
RUNTIME_IMAGE_URING="${RUNTIME_IMAGE_URING:-galay-sdk-uring:${IMAGE_TAG}}"

EPOLL_BUILD_IMAGE_ID=""
URING_BUILD_IMAGE_ID=""

cleanup() {
    if [[ -n "${EPOLL_BUILD_IMAGE_ID}" ]]; then
        docker image rm -f "${EPOLL_BUILD_IMAGE_ID}" >/dev/null 2>&1 || true
    fi
    if [[ -n "${URING_BUILD_IMAGE_ID}" ]]; then
        docker image rm -f "${URING_BUILD_IMAGE_ID}" >/dev/null 2>&1 || true
    fi
}
trap cleanup EXIT

mkdir -p "${OUT_DIR}"

export DOCKER_BUILDKIT=1

build_variant() {
    local variant_name="$1"
    local disable_io_uring="$2"
    local runtime_image="$3"
    local build_image_id_var="$4"
    local iidfile

    echo
    echo "========== build ${variant_name} build image =========="
    iidfile="$(mktemp)"
    docker build --progress=plain \
        --build-arg GALAY_DISABLE_IOURING="${disable_io_uring}" \
        --target galay-build \
        --iidfile "${iidfile}" \
        "${ROOT_DIR}"
    local build_image_id
    build_image_id="$(tr -d '[:space:]' < "${iidfile}")"
    rm -f "${iidfile}"
    printf -v "${build_image_id_var}" '%s' "${build_image_id}"

    echo
    echo "========== build ${variant_name} runtime image =========="
    docker build --progress=plain \
        --build-arg GALAY_DISABLE_IOURING="${disable_io_uring}" \
        --target galay-runtime \
        -t "${runtime_image}" \
        "${ROOT_DIR}"
}

build_variant "epoll" "ON" "${RUNTIME_IMAGE_EPOLL}" EPOLL_BUILD_IMAGE_ID
build_variant "uring" "OFF" "${RUNTIME_IMAGE_URING}" URING_BUILD_IMAGE_ID

echo
echo "========== image summary =========="
for image in "${RUNTIME_IMAGE_EPOLL}" "${RUNTIME_IMAGE_URING}"; do
    docker image inspect "${image}" --format '{{index .RepoTags 0}} {{.Size}}'
done

echo
echo "========== epoll build image toolchain =========="
docker run --rm "${EPOLL_BUILD_IMAGE_ID}" bash -lc 'g++ --version | head -n1; cmake --version | head -n1'

echo
echo "========== compile verify (epoll) =========="
docker run --rm \
    -v "${VERIFY_DIR}:/work/verify" \
    -v "${OUT_DIR}:/work/out" \
    "${EPOLL_BUILD_IMAGE_ID}" \
    bash -lc 'set -euo pipefail; cmake -S /work/verify -B /tmp/verify-build-epoll -G Ninja -DCMAKE_BUILD_TYPE=Release; cmake --build /tmp/verify-build-epoll -j"$(nproc)"; cp /tmp/verify-build-epoll/galay-sdk-verify /work/out/galay-sdk-verify-epoll'

echo
echo "========== compile verify (uring) =========="
docker run --rm \
    -v "${VERIFY_DIR}:/work/verify" \
    -v "${OUT_DIR}:/work/out" \
    "${URING_BUILD_IMAGE_ID}" \
    bash -lc 'set -euo pipefail; cmake -S /work/verify -B /tmp/verify-build-uring -G Ninja -DCMAKE_BUILD_TYPE=Release; cmake --build /tmp/verify-build-uring -j"$(nproc)"; cp /tmp/verify-build-uring/galay-sdk-verify /work/out/galay-sdk-verify-uring'

echo
echo "========== runtime verify (epoll) =========="
docker run --rm \
    -v "${OUT_DIR}:/work/out" \
    "${RUNTIME_IMAGE_EPOLL}" \
    bash -lc 'set -euo pipefail; ldd /work/out/galay-sdk-verify-epoll; LD_LIBRARY_PATH=/usr/local/lib${LD_LIBRARY_PATH:+:${LD_LIBRARY_PATH}} /work/out/galay-sdk-verify-epoll'

echo
echo "========== runtime verify (uring) =========="
docker run --rm \
    -v "${OUT_DIR}:/work/out" \
    "${RUNTIME_IMAGE_URING}" \
    bash -lc 'set -euo pipefail; ldd /work/out/galay-sdk-verify-uring; LD_LIBRARY_PATH=/usr/local/lib${LD_LIBRARY_PATH:+:${LD_LIBRARY_PATH}} /work/out/galay-sdk-verify-uring'
