FROM gitpod/openvscode-server:latest
ENV DEBIAN_FRONTEND=noninteractive

# Switch to root for package installation, then restore the default user
USER root
RUN apt-get update && apt-get install -y sudo curl unzip python3-pip && rm -rf /var/lib/apt/lists/*

# Install AWS CLI v2
RUN curl -fsSL "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o /tmp/awscliv2.zip && \
    unzip -q /tmp/awscliv2.zip -d /tmp/ && \
    /tmp/aws/install --update && \
    rm -rf /tmp/awscliv2.zip /tmp/aws

USER openvscode-server

EXPOSE 3000
