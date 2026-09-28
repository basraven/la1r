FROM alpine:3.20

# Alpine (musl) so the opencode v2 musl build runs natively.
# This image provides the same CLI capabilities as the other development
# deployments: kubectl (with the shared kubeconfig on the home PVC), git,
# jq, yq, gh, ansible and ssh. AWS CLI and the desktop IDEs are intentionally
# not included (AWS CLI v2 is glibc-only and will not run on musl).
RUN apk add --no-cache \
      bash \
      ca-certificates \
      curl \
      git \
      jq \
      openssh-client \
      py3-pip \
      python3 \
      sudo \
      tar \
      xz \
      unzip

# kubectl (static Go binary)
RUN curl -fsSL "https://dl.k8s.io/release/$(curl -fsSL https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl" \
      -o /usr/local/bin/kubectl && chmod +x /usr/local/bin/kubectl

# yq (mikefarah, static Go binary)
RUN curl -fsSL "https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64" \
      -o /usr/local/bin/yq && chmod +x /usr/local/bin/yq

# GitHub CLI (static binary)
RUN GH_VERSION="$(curl -fsSL https://api.github.com/repos/cli/cli/releases/latest | jq -r .tag_name | sed 's/^v//')" && \
    curl -fsSL "https://github.com/cli/cli/releases/download/v${GH_VERSION}/gh_${GH_VERSION}_linux_amd64.tar.gz" -o /tmp/gh.tar.gz && \
    tar -xzf /tmp/gh.tar.gz -C /tmp && \
    mv "/tmp/gh_${GH_VERSION}_linux_amd64/bin/gh" /usr/local/bin/gh && \
    rm -rf /tmp/gh.tar.gz "/tmp/gh_${GH_VERSION}_linux_amd64"

# Ansible (tolerate failure so a transient PyPI issue cannot fail the build)
RUN pip3 install --no-cache-dir --break-system-packages ansible || \
    pip3 install --no-cache-dir ansible || \
    echo "WARNING: ansible install failed"

# opencode v2 (musl build — native on alpine)
ARG OPENCODE_VERSION=2.0.6
RUN curl -fsSL "https://opencode.ai/files/bin/${OPENCODE_VERSION}/opencode-linux-x64-musl.tar.gz" -o /tmp/opencode.tar.gz && \
    tar -xzf /tmp/opencode.tar.gz -C /usr/local/bin opencode && \
    chmod +x /usr/local/bin/opencode && \
    rm -f /tmp/opencode.tar.gz && \
    opencode --version

# Mark all directories as safe for Git
RUN git config --global --add safe.directory '*'

ENV HOME=/home/basraven
ENV PATH=/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin

EXPOSE 4096
