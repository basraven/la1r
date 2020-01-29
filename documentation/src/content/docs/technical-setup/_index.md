---
title: Technical Setup
type: docs
bookToc: false
weight: 3
---
# How it's made
The technical setup of La1r is my personal take on how to properly implement the conceptual setup as described on this site. This does not mean that all implementations are matching the infrastructure context, on the contrary. Implementations in La1r are aimed on enterprise scale setups, which often make them an overkill for the hardware it is running. 
The reason for this is that the technical setup tries to comply to several application architecture principles which are focussed on maximizing my personal learning experiences and are often near enterprise scale. 

## Main area's of the technical setup
The technical setup can be divided into area's:

{{< columns >}}
## Data Processing
All the components which focus on processing data to fit in in the appropriate schema and to analyze the processed data with for example AI.

[Read more](/docs/technical-setup/data-processing)

<--->

## Ansible
All bare-metal setup related Ansible scripts.
This is mainly used to setup new hardware and to manage hardware such as IOT devices or new servers (improving portability).

[Read more](/docs/technical-setup/ansible)

<--->

## Kubernetes
All Kubernetes related scripts, the core of La1r!
All components will be documented.

[Read more](/docs/technical-setup/kubernetes)


<--->

## Secrets
Small document describing how secrets are managed in the different Ansible and k8s clusters.

[Read more](/docs/technical-setup/secrets)

{{< /columns >}}

## Technical architecture principles
The la1r architecture followes several techical principles which components in its architecture should follow.
Since this will not capture conceptual principles, a section on conceptual principles is describe [in the conceptual setup page](./conceptual-setup)
1. Only the paranoid survive, apply and practice backup scenarios. - Backup scenarios should not only be implemented as tick in the box for our list of non functional requirements (nfrs), but should also be practiced where possible. 
1. Aim for near horizontal scaling - all services should be able to scale with cluster size. The infrastructure architecture of my current implementation is rather rigid, but the applications on it should be aimed on flexible and horizontally scalable underlying infrastructure. 
1. Behind the VPN (openvpn) by default - since this is still a learning and experimental environment, I don't want to think about security first, every step of the way. This is why the master La1r server hosts a VPN virtual network. All services and internal dns are using that entrypoint by default. This does not mean that nothing is exposed to the outside world, but only the services explicitly exposed through the online-traefik instance are
