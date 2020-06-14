---
title: Technical Architecture
type: docs
bookToc: True
weight: 3
---
# How it's made
The technical architecture of La1r is my personal take on how to properly implement the capability architecture as described on this site. This does not mean that all implementations are matching the infrastructure context, on the contrary. Implementations in La1r are aimed on enterprise scale setups, which often make them an overkill for the hardware it is running. 
The reason for this is that the technical architecture tries to comply to several application architecture principles which are focussed on maximizing my personal learning experiences and are often near enterprise scale. 

## Main area's of the technical architecture
The technical architecture can be divided into area's:

{{< columns >}}
## Application Architecture
The overview and catalog of all the technical and functional applications running on the platform.

[Read more](application-architecture/_index.md)

<--->

## Data Architecture
All data processing, migration and storage principles, including AI and Automation.

[Read more](data-architecture/_index.md)

{{< /columns >}}

{{< columns >}}

## Infrastructure Architecture
Infrastructure Architecture Design, discussing both Ansible, for initial setup and bare-metal services and Kubernets, for running all other services.

[Read more](infrastructure-architecture/_index.md)

<--->

## Security Architecture
Setup of several security concepts which are an integral part of the technical architecture.

[Read more](security-architecture/_index.md)

{{< /columns >}}

## Technical Architecture principles
The la1r architecture follows several technical principles which components in its architecture should follow.
Since this will not capture conceptual principles, a section on conceptual principles is describe [in the capability architecture page](./capability-architecture)

1. Only the paranoid survive, apply and practice backup scenarios. - Backup scenarios should not only be implemented as tick in the box for our list of non functional requirements (nfrs), but should also be practiced where possible.
1. Aim for near horizontal scaling - all services should be able to scale with cluster size. The infrastructure architecture of my current implementation is rather rigid, but the applications on it should be aimed on flexible and horizontally scalable underlying infrastructure.
1. Behind the VPN (OpenVpn) by default - since this is still a learning and experimental environment, I don't want to think about security first, every step of the way. This is why the master La1r server hosts a VPN virtual network. All services and internal dns are using that entrypoint by default. This does not mean that nothing is exposed to the outside world, but only the services explicitly exposed through the online-traefik instance are
