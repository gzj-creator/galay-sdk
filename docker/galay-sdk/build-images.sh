#!/usr/bin/env bash
set -euo pipefail

readonly ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
readonly VERIFY_DIR="${VERIFY_DIR:-${ROOT_DIR}/verify}"
readonly OUT_DIR="${OUT_DIR:-${ROOT_DIR}/out}"

IMAGE_TAG="${IMAGE_TAG:-dev}"
GALAY_DISABLE_IOURING="${GALAY_DISABLE_IOURING:-ON}"
COMPILE_IMAGE="${COMPILE_IMAGE:-galay-sdk-compile:${IMAGE_TAG}}"
RUNTIME_IMAGE="${RUNTIME_IMAGE:-galay-sdk-runtime:${IMAGE_TAG}}"

if [[ "${GALAY_DISABLE_IOURING}" == "ON" ]]; then
    readonly IO_BACKEND="epoll"
else
    readonly IO_BACKEND="uring"
fi

mkdir -p "${OUT_DIR}"

export DOCKER_BUILDKIT=1

echo
echo "========== build compile image (${IO_BACKEND}) =========="
docker build --progress=plain \
    --build-arg GALAY_DISABLE_IOURING="${GALAY_DISABLE_IOURING}" \
    --target galay-build \
    -t "${COMPILE_IMAGE}" \
    "${ROOT_DIR}"

echo
echo "========== build runtime image (${IO_BACKEND}) =========="
docker build --progress=plain \
    --build-arg GALAY_DISABLE_IOURING="${GALAY_DISABLE_IOURING}" \
    --target galay-runtime \
    -t "${RUNTIME_IMAGE}" \
    "${ROOT_DIR}"

echo
echo "========== image summary =========="
for image in "${COMPILE_IMAGE}" "${RUNTIME_IMAGE}"; do
    docker image inspect "${image}" --format '{{index .RepoTags 0}} {{.Size}}'
done

echo
echo "========== compile image toolchain =========="
docker run --rm "${COMPILE_IMAGE}" \
    bash -lc 'set -euo pipefail; g++ --version | head -n1; cmake --version | head -n1; ninja --version'

echo
echo "========== runtime image toolchain check =========="
docker run --rm "${RUNTIME_IMAGE}" \
    bash -lc 'set -euo pipefail; ! command -v gcc; ! command -v g++; ! command -v cmake; ! command -v ninja'

echo
echo "========== compile verify (${IO_BACKEND}) =========="
docker run --rm \
    -v "${VERIFY_DIR}:/work/verify" \
    -v "${OUT_DIR}:/work/out" \
    "${COMPILE_IMAGE}" \
    bash -lc 'set -euo pipefail; cmake -S /work/verify -B /tmp/verify-build -G Ninja -DCMAKE_BUILD_TYPE=Release; cmake --build /tmp/verify-build -j"$(nproc)"; cp /tmp/verify-build/galay-sdk-verify /work/out/galay-sdk-verify'

echo
echo "========== runtime verify (${IO_BACKEND}) =========="
docker run --rm \
    -v "${OUT_DIR}:/work/out" \
    "${RUNTIME_IMAGE}" \
    bash -lc 'set -euo pipefail; ldd /work/out/galay-sdk-verify; LD_LIBRARY_PATH=/usr/local/lib${LD_LIBRARY_PATH:+:${LD_LIBRARY_PATH}} /work/out/galay-sdk-verify'
