---
bookToc: true
---

## Infrastructure Architecture
The infrastructure setup is one of the biggest topics of this project in terms of size and complexity.
> TODO: Infrastructure Arch Diagram

### How its made
How all of this infrastructure is deployed can be found in [the deployment architecture].

### Server Inventory
Currently the following servers are being used:

| ID  | Hostname    | OS                     | Hardware Description          | Hardware Tier    |
| --- | ---         | ---                    | ---                           | ---              |
| 1   | linux-wayne | Ubuntu server (latest) | Core i5 Desktop with SSD      | 1 - cluster      |
| 2   | 50centos    | CentOS 8               | Core i7 Laptop with HDD only  | 1 - cluster      |
| 3   | ali-bel     | Raspbian               | Doorbell Raspberry Pi Zero    | 2 - periferal    |
| 4   | kodi-e      | Raspbian               | Kodi Raspberry Pi 3b bedroom  | 2 - periferal    |
 
### Kubernetes (k8s)
The majority of the applications are hosted through Kubernetes.
K8s can be implemented in a million different ways. The implementation on La1r follows a few principles:

* K8s should run on bare metal only - it should not be dependent on any cloud resource, this includes function-as-service (FaaS) implementations such as AWS Lambda.
* Vanilla k8s should be used - flavored variants of k8s take some controls away from the sys admin and introduce (sometimes unwanted) abstractions.
* The latest k8s version should be used - this to incentive application of new k8s capabilities
* Template engines, package managers and operators such as helm are not used - this again takes away a lot of control from the sys admin which takes away the learning experience, thus the fun.
* K8s over bare metal - since the use of k8s incentives portability of applications, the default hosting approach should be on k8s not on the bare metal server itself (for example through Ansible). Only things that really make sense or are directly needed by the cluster itself, such as OpenVpn, can be implemented directly on the server with Ansible.
  
#### Init with kubeadm
Since we're using vanilla k8s on bare metal but we do not have all the time in the world, the decision was made to use kubeadm to initialize the cluster and manage node cluster and upgrades. Several upgrades were already performed with this which went flawless, even with multi cpu (x86 and arm7) architecture environments.

#### Node agnostic storage (coming soon)
Storage is often a difficult topic with k8s bare metal clusters, since the entire aim of k8s is to be independent and decoupled from infrastructure. This is why the current plan is to migrate all storage used by the cluster to a storage abstraction service, creating node agnostic storage facilities everywhere on the k8s cluster. The currently plan is to achieve this with Ceph through Rook.io, which also is an exception on the non-operator application architecture principle as mentioned earlier

#### Reverse proxy, with dmz-ed online exposure
Traefik is used as reverse proxy for all default traffic, this because it easily integrates with k8s and it provides a fancy dashboard UI, and maybe because I'm traefik 2.0 contributor...
Here my personal preference is to not follow the custom resource definition (CRD) hype and just use standard ingress objects, also for possible portability reasons if I ever get sick of traefik.


### Network Architecture
Since the network architecture of the project is not straight-forward, it is handled with several applications, all making a single cluster.
[ Read more ](./network-architecture/)