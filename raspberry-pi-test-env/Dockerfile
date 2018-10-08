FROM resin/rpi-raspbian

RUN apt-get update && \
	apt-get install -y openssh-server python python3 sudo

# The following installs need to be checked with raspi
RUN apt-get install -y expect wget 

# RUN rm -rf /var/lib/apt/lists/* && \
# 	apt-get clean

RUN echo 'root:raspberry' |chpasswd
RUN useradd -ms /bin/bash pi && adduser pi sudo
RUN echo 'pi:raspberry' |chpasswd
RUN sed -ri 's/^PermitRootLogin\s+.*/PermitRootLogin yes/' /etc/ssh/sshd_config
RUN mkdir -p /var/run/sshd
CMD    ["/usr/sbin/sshd", "-D"]
