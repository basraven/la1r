FROM gitpod/openvscode-server:latest
ENV DEBIAN_FRONTEND=noninteractive

USER root

# Install system packages
RUN apt-get update && apt-get install -y \
    sudo curl unzip python3-pip \
    nano ssh bash-completion zip fish zsh p7zip-full jq \
    && rm -rf /var/lib/apt/lists/*

# Install AWS CLI v2
RUN curl -fsSL "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o /tmp/awscliv2.zip && \
    unzip -q /tmp/awscliv2.zip -d /tmp/ && \
    /tmp/aws/install --update && \
    rm -rf /tmp/awscliv2.zip /tmp/aws

# Install yq
RUN wget https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64 -O /tmp/yq && \
    chmod +x /tmp/yq && mv /tmp/yq /usr/local/bin/yq

# Install kubectl
RUN curl -LO https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl && \
    chmod +x ./kubectl && mv ./kubectl /usr/local/bin/kubectl

# Rename UID 1000 to basraven with passwordless sudo
RUN usermod -l basraven -d /home/basraven -m $(id -un 1000) && \
    echo "basraven ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/basraven

# Install Claude Code and configure git as basraven
USER basraven
RUN curl -fsSL https://claude.ai/install.sh | bash && \
    git config --global user.name "Sebastiaan Raven" && \
    git config --global user.email "basraven@gmail.com"

USER root
EXPOSE 3000
