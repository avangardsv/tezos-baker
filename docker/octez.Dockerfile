ARG OCTEZ_VERSION=v20.2
FROM registry.gitlab.com/tezos/tezos:${OCTEZ_VERSION}

# Build arguments
ARG OCTEZ_VERSION
ARG PUID=1000
ARG PGID=1000

# Install additional dependencies
USER root

# Install system dependencies
RUN apt-get update && apt-get install -y \
    curl \
    jq \
    netcat \
    procps \
    supervisor \
    logrotate \
    cron \
    gnupg2 \
    udev \
    libusb-1.0-0-dev \
    libudev-dev \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Create tezos user with specified UID/GID
RUN groupadd -g ${PGID} tezos || true && \
    useradd -u ${PUID} -g ${PGID} -s /bin/bash -m -d /home/tezos tezos || true

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

# Copy entrypoint and configuration scripts
COPY docker/scripts/ /usr/local/bin/
RUN chmod +x /usr/local/bin/*.sh

# Copy supervisor configuration
COPY docker/supervisor/ /etc/supervisor/conf.d/

# Copy logrotate configuration
COPY docker/logrotate/ /etc/logrotate.d/

# Set up log rotation for tezos logs
RUN echo "0 2 * * * root /usr/sbin/logrotate /etc/logrotate.d/tezos" >> /etc/crontab

# Create wrapper scripts for Tezos binaries with logging
RUN for binary in tezos-node tezos-client tezos-baker-alpha tezos-endorser-alpha tezos-signer; do \
        mv /usr/local/bin/$binary /usr/local/bin/$binary.orig 2>/dev/null || true; \
        cat > /usr/local/bin/$binary << EOF
#!/bin/bash
exec /usr/local/bin/$binary.orig "\$@" 2>&1 | tee -a /var/log/tezos/$binary.log
EOF
        chmod +x /usr/local/bin/$binary; \
    done

# Health check script
COPY docker/healthcheck.sh /usr/local/bin/healthcheck.sh
RUN chmod +x /usr/local/bin/healthcheck.sh

# Expose standard ports
EXPOSE 8732 9732 9095 6732

# Set working directory
WORKDIR /home/tezos

# Switch to tezos user
USER tezos

# Initialize Tezos client configuration
RUN tezos-client --version && \
    echo "Octez version: ${OCTEZ_VERSION}"

# Environment variables
ENV TEZOS_NETWORK=ghostnet
ENV LOG_LEVEL=INFO
ENV HISTORY_MODE=rolling
ENV ENABLE_RPC=true
ENV RPC_ADDR=0.0.0.0

# Volume mount points
VOLUME ["/var/lib/tezos", "/var/log/tezos", "/etc/tezos"]

# Entry point
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]

# Default command
CMD ["node"]

# Metadata
LABEL maintainer="Tezos Baker Setup"
LABEL version="${OCTEZ_VERSION}"
LABEL description="Tezos Octez node with baker and endorser support"
LABEL network.ports.p2p="9732"
LABEL network.ports.rpc="8732" 
LABEL network.ports.metrics="9095"
LABEL network.ports.signer="6732"