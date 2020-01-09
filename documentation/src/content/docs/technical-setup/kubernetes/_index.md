# How we do Kubernetes (k8s) 
K8s can be implemented in a million different ways. The implementation on La1r follows a few principles:

* K8s should run on bare metal only - it should not be dependent on any cloud resource, this includes function-as-service (FaaS) implementations such as AWS Lambda. 
* Vanilla k8s should be used - flavored varients of k8s take some controls away from the sys admin and introduce (sometimes unwanted) abstractions. 
* The latest k8s version should be used - this to incentive application of new k8s capabilities
* Templating engines, package managers and operators such as helm are not used - this again takes away a lot of control from the sys admin which takes away the learning experience, thus the fun. 
* K8s over bare metal - since the use of k8s incentives portability of applications, the default hosting approach should be on k8s not on the bare metal server itself (for example through Ansible). Only things that really make sense or are directly needed by the cluster itself, such as openvpn, can be implemented directly on the server with Ansible. 

## Init with kubeadm
Since we're using vanilla k8s on bare metal but we do not have all the time in the world, the decision was made to use kubeadm to initialize the cluster and manage node cluster and upgrades. Several upgrades were already performed with this which went flawless, even with multi cpu (x86 and arm7) architecture environments. 

## Network with weaveworks
Initially the decision was made to use flannel as network provider, since this is a pretty standard choice for many k8s implementations. Unfortunately this gave several networking, performance and upgrading issues over time, especially with our multi cpu architecte environment. After a tool selection process weave works came out best because:

* Substantial performance and stability improvements 
* Capable of complex network segregations which flannel was not able to do
* Easy to setup, even if several sources on the way point out the opposite
* Bonus: Weave works supplies a fancy and comprehensive dashboard of your entire network

## Node agnostic storage (coming soon) 
Storage is often a difficult topic with k8s bare metal clusters, since the entire aim of k8s is to be independent and decoupled from infrastructure. This is why the current plan is to migrate all storage used by the cluster to a storage abstraction service, creating node agnostic storage facilities everywhere on the k8s cluster. The currently plan is to achieve this with ceph through rook.io, which also is an exception on the non-operator application architecture principle as mentioned earlier

## Reverse proxy, with dmz-ed online exposure
Traefik is used as reverse proxy for all default traffic, this because it easily integrates with k8s and it provides a fancy dashboard UI, and maybe because I'm traefik 2.0 contributer... 
Here my personal preference is to not follow the custom resource definition (CRD) hype and just use standard ingress objects, also for possible portability reasons if I ever get sick of traefik. 