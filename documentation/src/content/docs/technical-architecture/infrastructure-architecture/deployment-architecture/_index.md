---
bookToc: true
bookCollapseSection : true
---

## Deployment Architecture
Two components are used to setup this architecture:

1. Ansible, for bare metal server initialization and bare metal services.
2. Kubernetes, for running processes which can be containerized

The aim is to put as many of the services in Kubernetes, keeping the Ansible footprint as small as possible.
Unfortunately there always needs to be an initial setup script, which is handled by the small footprint of Ansible.
All other services need to run in Kubernetes, to improve portability and manageability.

### Ansible - Prepare the infrastructure and bare-metal services
Since there's always a need for installing packages on the nodes directly and I don't want to just use a bunch of shell scripts all configuration and applications outside of k8s is deployed with Ansible which are directed by makefiles. Makefiles because I don't want to remember all commands that I need to spin up ansible by heart, Ansible because I want to semi-formalize the steps I take.
The goal here is to document every step, it does not matter how small, into an Ansible Playbook script.
These Ansible scripts can be found on <https://github.com/basraven/la1r/ansible>

#### Ansible Tags
The following tags are used in Ansible:
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
  * Requires ```---extra-vars "kubernetes_master=1.1.1.1"```
  * Requires ```/credentials/kubernetes/join-token.yaml"```

### CI with Jenkins
A key component of the architecture is that in essence, everything should be able to run **without Jenkins**, just with Ansible and Kubernetes.
Jenkins is used, just to streamline the process.

#### Jenkins Pipelines
Jenkins contains the following pipelines:

* Deploy Ansible Assets
* Deploy Kubernetes Assets

---

### Makefiles as operators
The initial approach was to use makefiles as operators. But this was not scalable, these files became a mess.
This is why Jenkins with Configuration As Code was later introduced.

#### Contents of former makefiles
Since I want to formalize everything into scripts, there needs to be a way to formalize how to call the different playbook with the appropriate arguments.
This is why the Git repository contains 2 Makefiles. There has been chosen for Makefiles because the way these files are called is extremely predictable ```make <your command>```:

* [Makefile for Ansible](/) - This makefile contains all the Ansible Playbook calls which are made to construct la1r on bare metal
* [Makefile for Kubernetes](/) - This makefile contains all the used Kubernetes calls to setup the Kubernetes nodes. This also contains node setup scripts such as applying taints.
