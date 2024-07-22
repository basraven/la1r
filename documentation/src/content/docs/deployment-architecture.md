---
bookToc: false
bookCollapseSection : false
weight: 2
---

## Deployment Architecture
Deployment is done in two steps:
1. [Ansible](https://www.ansible.com/), for hardware configuration of servers
2. [FluxCD](https://fluxcd.io/), for Kubernetes-based deployments. 

Aim is to keep the Ansible footprint as small as possible and to have any complexity in Kubernetes with FluxCD as code.


# Ansible
Full scripts [located in GH](https://github.com/basraven/la1r/tree/rick/cicd/ansible), I tried to use tags to deploy common tasks and use specific host configurations with host specific yamls and sh files to execute them.

This is not the intended way to use Ansible, but it works for me to maintain a semi-idempotent way to deploy my servers.

## Ansible Task Tags
The following tags are used in Ansible scripts (might be outdated):
* helper                - Helper scripts for the run itself, e.g. to determine OS
* hostname              - Set hostname of server
* reboot                - Reboots the machine
* update                - Update the package managers
* security              - Security related packages and update
* kerberos_client       - Install Kerberos (MIT) client and get keys. Server will install if hosts file contains ```kerberos: server``` for this server.
* kerberos_server       - Install Kerberos (MIT) server and create keys. Server will install if hosts file contains ```kerberos: server``` for this server.
* toolbox               - Placement of /cicd/ansible/toolbox scripts, used for infrastructure management
* users                 - Creation of users
* dns_server            - Install DNS Server
* docker                - Install docker
* nfs_client            - Install nfs-client
* nfs_server            - Install nfs-server
* openvpn_client        - Install openvpn client and place certificate from /credentials
* openvpn_server        - Install openvpn server and creates new CA
* create_ovpn_user      - Create a new certificate for openvpn,
  * Requires ```---extra-vars "openvpn_user=someusername"```
* delete_ovpn_user   - Create a new certificate for openvpn
  * Requires ```---extra-vars "openvpn_user=someusername"```
* node_exporter         - Install prometheus_node_exporter
* haproxy               - Install haproxy
* kubernetes_server     - Install Kubernetes
* init_kubernetes       - Run kubeadm init
  * Optional ```---extra-vars "kubernetes_cidr=10.244.0.0/16"```
* reset_kubernetes      - Reset from changes made by kubeadm init and kubeadm join
* fetch_kubernetes      - Fetch the Kubernetes config file and put it in the local folder
* storage_kubernetes    - Install packages as prep for the storage provider
* join-kubernetes       - Join a kubernetes cluster
  * Requires ```---extra-vars "kubernetes_master=8.8.8.8"```
  * Requires ```/credentials/kubernetes/join-token.yaml"```


# FluxCD
GitOps is used to maintain all kubernetes deployments in [/kubernetes](https://github.com/basraven/la1r/tree/rick/kubernetes). This includes the configuration of FluxCD itself, which is located in [/kubernetes/flux-system](https://github.com/basraven/la1r/tree/rick/kubernetes/flux-system) and should be deployed manually, for example with [deploy.sh](https://github.com/basraven/la1r/blob/rick/kubernetes/flux-system/deploy.sh).

> Everything in the [/todeploy-kubernetes](https://github.com/basraven/la1r/tree/rick/todeploy-kubernetes) folder still needs to be adopted to this new way of deploying with FluxCD
