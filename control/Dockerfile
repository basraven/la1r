FROM centos:latest
# Install k8s
RUN rpm --import https://packages.cloud.google.com/yum/doc/yum-key.gpg && rpm --import https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg && echo $'[kubernetes] \nname=Kubernetes \nbaseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-x86_64 \nenabled=1 \ngpgcheck=1 \nrepo_gpgcheck=1 \n gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg ' >> /etc/yum.repos.d/kubernetes.repo
# Install yum packages
RUN yum update -y && yum install -y git golang openssh openssh-clients curl which bind-utils bash-completion kubectl epel-release 
# Install helm
RUN curl https://raw.githubusercontent.com/helm/helm/master/scripts/get | bash 
# Install kubecrt, against helm...
# RUN git clone https://github.com/blendle/kubecrt.git /kubecrt ; cd /kubecrt ; go get ../... ; go build ; chmod +x kubecrt ; cp kubecrt /usr/bin/kubecrt
# Ansible is dependent on epel-release and an updated yum after install
RUN yum update -y && yum install -y ansible
WORKDIR /kubernetes

COPY entrypoint.sh /control/entrypoint.sh
COPY kubectl_aliases.sh /control/kubectl_aliases.sh
ENTRYPOINT entrypoint.sh /control/entrypoint.sh