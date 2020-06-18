# Infrastructure Architecture
The infrastructure setup is one of the biggest topics of this project in terms of size and complexity.
> TODO: Infrastructure Arch Diagram

Two components are used to setup this architecture:

1. Ansible, for bare metal server initialization and bare metal services.
2. Kubernetes, for running processes which can be containerized

The aim is to put as many of the services in Kubernetes, keeping the Ansible footprint as small as possible.
Unfortunately there always needs to be an initial setup script, which is handled by the small footprint of Ansible.
All other services need to run in Kubernetes, to improve portability and manageability.

## 1. Ansible - Prepare the infrastructure and bare-metal services
Since there's always a need for installing packages on the nodes directly and I don't want to just use a bunch of shell scripts all configuration and applications outside of k8s is deployed with Ansible which are directed by makefiles. Makefiles because I don't want to remember all commands that I need to spin up ansible by heart,Ansible because I want to semi-formalize the steps I take.
The goal here is to document every step, it does not matter how small, into an Ansible Playbook script.
These Ansible scripts can be found on <https://github.com/basraven/la1r/ansible>

### Makefiles as operators
Since I want to formalize everything into scripts, there needs to be a way to formalize how to call the different playbook with the appropriate arguments.
This is why the Git repository contains 2 Makefiles. There has been chosen for Makefiles because the way these files are called is extremely predictable ```make <your command>```:

* [Makefile for Ansible](/) - This makefile contains all the Ansible Playbook calls which are made to construct la1r on bare metal
* [Makefile for Kubernetes](/) - This makefile contains all the used Kubernetes calls to setup the Kubernetes nodes. This also contains node setup scripts such as applying taints.

## 2. Kubernetes (k8s)
K8s can be implemented in a million different ways. The implementation on La1r follows a few principles:

* K8s should run on bare metal only - it should not be dependent on any cloud resource, this includes function-as-service (FaaS) implementations such as AWS Lambda.
* Vanilla k8s should be used - flavored variants of k8s take some controls away from the sys admin and introduce (sometimes unwanted) abstractions.
* The latest k8s version should be used - this to incentive application of new k8s capabilities
* Template engines, package managers and operators such as helm are not used - this again takes away a lot of control from the sys admin which takes away the learning experience, thus the fun.
* K8s over bare metal - since the use of k8s incentives portability of applications, the default hosting approach should be on k8s not on the bare metal server itself (for example through Ansible). Only things that really make sense or are directly needed by the cluster itself, such as OpenVpn, can be implemented directly on the server with Ansible.
  
### Init with kubeadm
Since we're using vanilla k8s on bare metal but we do not have all the time in the world, the decision was made to use kubeadm to initialize the cluster and manage node cluster and upgrades. Several upgrades were already performed with this which went flawless, even with multi cpu (x86 and arm7) architecture environments.

### Network with WeaveWorks
Initially the decision was made to use flannel as network provider, since this is a pretty standard choice for many k8s implementations. Unfortunately this gave several networking, performance and upgrading issues over time, especially with our multi cpu architects environment. After a tool selection process weave works came out best because:

* Substantial performance and stability improvements
* Capable of complex network segregation which flannel was not able to do
* Easy to setup, even if several sources on the way point out the opposite
* Bonus: Weave works supplies a fancy and comprehensive dashboard of your entire network

### Node agnostic storage (coming soon)
Storage is often a difficult topic with k8s bare metal clusters, since the entire aim of k8s is to be independent and decoupled from infrastructure. This is why the current plan is to migrate all storage used by the cluster to a storage abstraction service, creating node agnostic storage facilities everywhere on the k8s cluster. The currently plan is to achieve this with Ceph through Rook.io, which also is an exception on the non-operator application architecture principle as mentioned earlier

### Reverse proxy, with dmz-ed online exposure
Traefik is used as reverse proxy for all default traffic, this because it easily integrates with k8s and it provides a fancy dashboard UI, and maybe because I'm traefik 2.0 contributor...
Here my personal preference is to not follow the custom resource definition (CRD) hype and just use standard ingress objects, also for possible portability reasons if I ever get sick of traefik.
