FROM centos:latest
RUN echo $'[kubernetes] \nname=Kubernetes \nbaseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-x86_64 \nenabled=1 \ngpgcheck=1 \nrepo_gpgcheck=1 \n gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg ' >> /etc/yum.repos.d/kubernetes.repo
RUN yum update -y && \
    yum install -y ansible git openssh openssh-clients curl which bind-utils bash-completion \
    kubectl && \
    mkdir -p ~/.ssh && \
    curl https://raw.githubusercontent.com/helm/helm/master/scripts/get | bash 
WORKDIR /kubernetes

COPY entrypoint.sh /control/entrypoint.sh