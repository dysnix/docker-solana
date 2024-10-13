FROM solanalabs/solana:v1.18.26

ENV DEBIAN_FRONTEND noninteractive

RUN apt-get update -y \
    && apt-get install -y \
        ca-certificates \
        curl \
        jq \
    && rm -rf /var/lib/apt/lists/*
