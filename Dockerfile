ARG OCTEZ_VERSION=octez-v20.3
FROM tezos/tezos:${OCTEZ_VERSION}

# Build arguments
ARG OCTEZ_VERSION
ARG PUID=1000
ARG PGID=1000

# Install additional dependencies (Alpine uses apk)
USER root

# Install system dependencies
RUN apk add --no-cache \
    curl \
    jq \
    netcat-openbsd \
    procps \
    bash \
    shadow

# Create tezos user with specified UID/GID (Alpine uses addgroup/adduser)
RUN addgroup -g ${PGID} tezos || true && \
    adduser -u ${PUID} -G tezos -s /bin/bash -D tezos || true

# Create required directories
RUN mkdir -p \
    /var/lib/tezos \
    /var/log/tezos \
    /etc/tezos \
    /home/tezos/.tezos-node \
    /home/tezos/.tezos-client \
    && chown -R tezos:tezos \
        /var/lib/tezos \
        /var/log/tezos \
        /etc/tezos \
        /home/tezos

# Expose standard ports
EXPOSE 8732 9732 9095 6732

# Set working directory
WORKDIR /home/tezos

# Switch to tezos user
USER tezos

# Environment variables
ENV TEZOS_NETWORK=ghostnet
ENV LOG_LEVEL=INFO
ENV HISTORY_MODE=rolling
ENV ENABLE_RPC=true
ENV RPC_ADDR=0.0.0.0

# Volume mount points
VOLUME ["/var/lib/tezos", "/var/log/tezos", "/etc/tezos"]

# Default command - Octez v20.3: run node with network and config
CMD ["octez-node", "run", "--network", "ghostnet", "--data-dir", "/var/lib/tezos", "--config-file", "/etc/tezos/ghostnet-config.json"]

# Metadata
LABEL maintainer="Tezos Baker Setup"
LABEL version="${OCTEZ_VERSION}"
LABEL description="Tezos Octez node with baker and endorser support"
