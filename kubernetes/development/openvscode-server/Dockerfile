FROM gitpod/openvscode-server:latest
ENV DEBIAN_FRONTEND=noninteractive

# Switch to root for package installation, then restore the default user
USER root
RUN apt-get update && apt-get install -y sudo && rm -rf /var/lib/apt/lists/*
USER openvscode-server

EXPOSE 3000
