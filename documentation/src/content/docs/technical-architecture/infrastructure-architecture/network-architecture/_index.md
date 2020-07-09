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

![](/images/la1r-diagrams-Network%20Arch%20-%20Technical%20Layer.png)


### Network with WeaveWorks
Initially the decision was made to use flannel as network provider, since this is a pretty standard choice for many k8s implementations. Unfortunately this gave several networking, performance and upgrading issues over time, especially with our multi cpu architects environment. After a tool selection process weave works came out best because:

* Substantial performance and stability improvements
* Capable of complex network segregation which flannel was not able to do
* Easy to setup, even if several sources on the way point out the opposite
* Bonus: Weave works supplies a fancy and comprehensive dashboard of your entire network

### Data Layer
The Data Layer is structured as follows:

![](/images/la1r-diagrams-Network%20Arch%20-%20Data%20Layer.png)
