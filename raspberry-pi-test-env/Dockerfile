FROM resin/rpi-raspbian

RUN apt-get update && \
	apt-get install -y openssh-server python python3 && \
	rm -rf /var/lib/apt/lists/* && \
	apt-get clean

RUN echo 'root:raspberry' |chpasswd
RUN sed -ri 's/^PermitRootLogin\s+.*/PermitRootLogin yes/' /etc/ssh/sshd_config
RUN mkdir -p /var/run/sshd
CMD    ["/usr/sbin/sshd", "-D"]
