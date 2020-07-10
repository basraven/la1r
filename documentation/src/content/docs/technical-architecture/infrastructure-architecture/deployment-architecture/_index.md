# Deployment Architecture
Two components are used to setup this architecture:

1. Ansible, for bare metal server initialization and bare metal services.
2. Kubernetes, for running processes which can be containerized

The aim is to put as many of the services in Kubernetes, keeping the Ansible footprint as small as possible.
Unfortunately there always needs to be an initial setup script, which is handled by the small footprint of Ansible.
All other services need to run in Kubernetes, to improve portability and manageability.

## Ansible - Prepare the infrastructure and bare-metal services
Since there's always a need for installing packages on the nodes directly and I don't want to just use a bunch of shell scripts all configuration and applications outside of k8s is deployed with Ansible which are directed by makefiles. Makefiles because I don't want to remember all commands that I need to spin up ansible by heart, Ansible because I want to semi-formalize the steps I take.
The goal here is to document every step, it does not matter how small, into an Ansible Playbook script.
These Ansible scripts can be found on <https://github.com/basraven/la1r/ansible>

### Ansible Tags
The following tags are used in Ansible:
* helper                - Helper scripts for the run itself, e.g. to determine os
* initial               - Script needed for a first ever run of the OS
* update                - Update the package managers
* security              - Security related packages and update
* toolbox               - Placement of /cicd/ansible/toolbox scripts, used for infrastructure management
* users                 - Creation of users
* dns-server            - Install DNS Server
* docker                - Install docker
* nfs-client            - Install nfs-client
* nfs-server            - Install nfs-server
* openvpn-client        - Install openvpn client and place certificate from /credentials
* create-ovpn-user      - Create a new certificate for openvpn,
  * Requires ```---extra-vars "openvpn-user=someusername"```
* delete-ovpn-user   - Create a new certificate for openvpn
  * Requires ```---extra-vars "openvpn-user=someusername"```
* openvpn-server        - Install openvpn server and creates new CA
* node_exporter         - Install prometheus_node_exporter

## CI with Jenkins
A key component of the architecture is that in essence, everything should be able to run **without Jenkins**, just with Ansible and Kubernetes.
Jenkins is used, just to streamline the process.

### Jenkins Pipelines
Jenkins contains the following pipelines:

* Deploy Ansible Assets
* Deploy Kubernetes Assets

---

## Makefiles as operators
The initial approach was to use makefiles as operators. But this was not scalable, these files became a mess.
This is why Jenkins with Configuration As Code was later introduced.

### Contents of former makefiles
Since I want to formalize everything into scripts, there needs to be a way to formalize how to call the different playbook with the appropriate arguments.
This is why the Git repository contains 2 Makefiles. There has been chosen for Makefiles because the way these files are called is extremely predictable ```make <your command>```:

* [Makefile for Ansible](/) - This makefile contains all the Ansible Playbook calls which are made to construct la1r on bare metal
* [Makefile for Kubernetes](/) - This makefile contains all the used Kubernetes calls to setup the Kubernetes nodes. This also contains node setup scripts such as applying taints.
