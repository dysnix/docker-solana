FROM rust:1.75-bullseye as jitobuild
# keep rust version in sync to avoid re-downloading rust
# use https://github.com/solana-labs/solana/blob/db9fdf5811ecd8a84ea446591854974d386681ef/ci/rust-version.sh#L21

RUN set -x \
    && apt-get -qq update \
    && apt-get -qq -y install \
    clang \
    cmake \
    libudev-dev \
    unzip \
    libssl-dev \
    pkg-config \
    zlib1g-dev \
    curl \
    git \
 && rustup component add rustfmt \
 && rustup component add clippy \
 && rustc --version \
 && cargo --version

ENV PROTOC_VERSION 21.12
ENV PROTOC_ZIP protoc-$PROTOC_VERSION-linux-x86_64.zip

RUN curl -OL https://github.com/google/protobuf/releases/download/v$PROTOC_VERSION/$PROTOC_ZIP \
 && unzip -o $PROTOC_ZIP -d /usr/local bin/protoc \
 && unzip -o $PROTOC_ZIP -d /usr/local include/* \
 && rm -f $PROTOC_ZIP
WORKDIR /
RUN git clone --depth=1 --branch v1.18.1 https://github.com/jito-foundation/geyser-grpc-plugin.git
WORKDIR /geyser-grpc-plugin


ARG ci_commit
ENV CI_COMMIT=v1.18.1

ARG features

# Uses docker buildkit to cache the image.
# /usr/local/cargo/git needed for crossbeam patch
RUN if [ -z "$features" ] ; then \
      cargo build --release; \
    else \
      cargo build --release --features "$features"; \
    fi

FROM solanalabs/solana:v1.18.15

ENV DEBIAN_FRONTEND noninteractive

RUN apt-get update -y \
    && apt-get install -y \
        ca-certificates \
        curl \
        jq \
    && rm -rf /var/lib/apt/lists/*

COPY --from=jitobuild /geyser-grpc-plugin/target/release/libgeyser_grpc_plugin_server.so /lib/