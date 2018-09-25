FROM debian:latest
RUN apt-get update && \
    apt-get install -y ssh openssh-server
RUN systemctl enable ssh
RUN update-rc.d ssh enable
RUN update-rc.d ssh defaults