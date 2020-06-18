# Network Architecture
The network setup is of la1r.com is not a simple one, this due to several reasons:
* Multi-site setup, with servers on different locations, connected either directly or through vpn
* Multi-tenancy setup, multiple layers of access on the network need to be implemented
* Multiple vpn endpoints, this to connect the differnet tenants
* Multiple servers within a single Kubernetes cluster.
* Virtual network interfaces with virtual network policies in Kubernetes. 
* Multiple networking hardware devices suchs as routers, managed switches and IOT devices.

To break down these complexities we can split the network architecture into two parts:
1. Technical Layers - ([OSI](https://en.wikipedia.org/wiki/OSI_model#:~:text=The%20Open%20Systems%20Interconnection%20model,underlying%20internal%20structure%20and%20technology) layers 1 - 4)
2. Data Layers - ([OSI](https://en.wikipedia.org/wiki/OSI_model#:~:text=The%20Open%20Systems%20Interconnection%20model,underlying%20internal%20structure%20and%20technology) layers 5 - 7)