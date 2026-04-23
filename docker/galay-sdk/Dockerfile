FROM ubuntu:24.04 AS build-deps

ARG GALAY_DISABLE_IOURING=ON

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        build-essential \
        ca-certificates \
        cmake \
        libaio-dev \
        libfmt-dev \
        libsimdjson-dev \
        libspdlog-dev \
        libssl-dev \
        ninja-build \
        pkg-config \
    && if [ "${GALAY_DISABLE_IOURING}" = "OFF" ]; then \
           apt-get install -y --no-install-recommends liburing-dev; \
       fi \
    && rm -rf /var/lib/apt/lists/*

ENV CMAKE_PREFIX_PATH=/usr/local \
    PKG_CONFIG_PATH=/usr/local/lib/pkgconfig:/usr/local/lib/x86_64-linux-gnu/pkgconfig:/usr/lib/x86_64-linux-gnu/pkgconfig \
    LD_LIBRARY_PATH=/usr/local/lib

WORKDIR /workspace

COPY build-all.sh /usr/local/bin/build-all.sh
COPY src /src

RUN chmod +x /usr/local/bin/build-all.sh \
    && export GALAY_DISABLE_IOURING="${GALAY_DISABLE_IOURING}" \
    && /usr/local/bin/build-all.sh \
    && printf '/usr/local/lib\n' >/etc/ld.so.conf.d/galay-sdk.conf \
    && ldconfig

FROM ubuntu:24.04 AS galay-build

ARG GALAY_DISABLE_IOURING=ON

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        build-essential \
        ca-certificates \
        cmake \
        libaio-dev \
        libfmt-dev \
        libsimdjson-dev \
        libspdlog-dev \
        libssl-dev \
        ninja-build \
        pkg-config \
    && if [ "${GALAY_DISABLE_IOURING}" = "OFF" ]; then \
           apt-get install -y --no-install-recommends liburing-dev; \
       fi \
    && rm -rf /var/lib/apt/lists/*

COPY --from=build-deps /usr/local /usr/local

RUN printf '/usr/local/lib\n' >/etc/ld.so.conf.d/galay-sdk.conf \
    && ldconfig

ENV CMAKE_PREFIX_PATH=/usr/local \
    PKG_CONFIG_PATH=/usr/local/lib/pkgconfig:/usr/local/lib/x86_64-linux-gnu/pkgconfig:/usr/lib/x86_64-linux-gnu/pkgconfig \
    LD_LIBRARY_PATH=/usr/local/lib

WORKDIR /workspace

FROM ubuntu:24.04 AS galay-runtime

ARG GALAY_DISABLE_IOURING=ON

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        ca-certificates \
        libaio1t64 \
        libfmt9 \
        libsimdjson19 \
        libspdlog1.12 \
        libssl3t64 \
    && if [ "${GALAY_DISABLE_IOURING}" = "OFF" ]; then \
           apt-get install -y --no-install-recommends liburing2; \
       fi \
    && rm -rf /var/lib/apt/lists/*

COPY --from=build-deps /usr/local /usr/local

RUN printf '/usr/local/lib\n' >/etc/ld.so.conf.d/galay-sdk.conf \
    && ldconfig

ENV LD_LIBRARY_PATH=/usr/local/lib

WORKDIR /workspace
