---
title: Network Architecture
type: docs
bookToc: false
---
## Network Architecture
The network setup is of la1r.com is not a simple one, this due to several reasons:

* Multi-site setup, with servers on different locations, connected either directly or through vpn
* Multi-tenancy setup, multiple layers of access on the network need to be implemented
* Multiple vpn endpoints, this to connect the different tenants
* Multiple servers within a single Kubernetes cluster.
* Virtual network interfaces with virtual network policies in Kubernetes.
* Multiple networking hardware devices such as routers, managed switches and IOT devices.

To break down these complexities we can split the network architecture into two parts:

1. Technical Layer - ([OSI](https://en.wikipedia.org/wiki/OSI_model#:~:text=The%20Open%20Systems%20Interconnection%20model,underlying%20internal%20structure%20and%20technology) layers 1 - 4)
2. Data Layer - ([OSI](https://en.wikipedia.org/wiki/OSI_model#:~:text=The%20Open%20Systems%20Interconnection%20model,underlying%20internal%20structure%20and%20technology) layers 5 - 7)

### Technical Layer
The Technical Layer is structured as follows:
![](../../../../../resources/images/la1r-diagrams-Capability%20Arch%20-%20Event%20Application%20Arch.png)
![](/resources/images/la1r-diagrams-Capability%20Arch%20-%20Event%20Application%20Arch.png)
![](/images/la1r-diagrams-Capability%20Arch%20-%20Event%20Application%20Arch.png)

### Data Layer
The Data Layer is structured as follows:
![](/la1r-diagrams-Network%20Arch%20-%20Data%20Layer.png)
![](la1r-diagrams-Network%20Arch%20-%20Data%20Layer.png)
