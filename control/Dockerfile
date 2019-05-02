FROM centos:latest
RUN echo $'[kubernetes] \n\
name=Kubernetes \n\
baseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-x86_64 \n\
enabled=1 \n\
gpgcheck=1 \n\
repo_gpgcheck=1 \n\
gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg ' >> /etc/yum.repos.d/kubernetes.repo
RUN yum update -y && \
    yum install -y ansible git openssh openssh-clients curl which bind-utils bash-completion \
    kubectl && \
    mkdir -p ~/.ssh && \
    curl https://raw.githubusercontent.com/helm/helm/master/scripts/get | bash 
WORKDIR /playbooks
