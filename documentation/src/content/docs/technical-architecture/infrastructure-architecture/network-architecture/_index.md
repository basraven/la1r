---
title: Network Architecture
type: docs
bookToc: true
bookCollapseSection : true
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

### Network topology table
The following table summarizes all network cidrs and addresses

| Prefix    | CIDR     | IP                             | Target                                                     | vlan              |
| ---       | ---      | ---                            | ---                                                        | ---               |
| 192.168   | 1.0/24   |                                | Empty, not used, will indicate wrongly configured devices  | -                 |
| 192.168   | 2.0/24   |                                | Common devices, laptops, phones, etc.                      | 1                 |
| 192.168   | 3.0/24   |                                | IOT Devices with dedicated connection to server            | 1                 |
| 192.168   | 4.0/24   |                                | Network infrastructure, switches, routers, etc             | 1                 |
| 192.168   | 4.0/24   | [4.1](http://192.168.4.1)      | Router and DHCP Server                                     | 1                 |
| 192.168   | 4.0/24   | [4.2](http://192.168.4.2)      | Central network switch                                     | 1                 |
| 192.168   | 4.0/24   | [4.3](http://192.168.4.3)      | Access Point living room                                   | 1                 |
| 192.168   | 4.0/24   | [4.4](http://192.168.4.4)      | Access Point office                                        | 1                 |
| 192.168   | 5.0/20   |                                | Servers                                                    | 1                 |
| 192.168   | 5.0/20   | [5.1](http://192.168.5.1)      | linux-wayne                                                | 1                 |
| 192.168   | 5.0/20   | [5.2](http://192.168.5.2)      | 50centos                                                   | 1                 |
| 192.168   | 5.0/20   | [5.3](http://192.168.5.3)      | jay-c                                                      | 1                 |
| 192.168   | 5.0/20   | [5.100](http://192.168.5.100)  | haproxy VIP entrypoint Kubernetes                          | 1                 |
| 192.168   | 6.0/24   |                                | Kubernetes MetalLB services                                | 1                 |
| 192.168   | 6.0/25   |                                | LAN Kubernetes MetalLB services                            | 1                 |
| 192.168   | 6.0/25   | [6.1](http://192.168.6.1)      | LAN Traefik 2.x                                            | 1                 |
| 192.168   | 6.0/25   | [6.60](http://192.168.6.60)    | Plex server                                                | 1                 |
| 192.168   | 6.0/25   | [6.61](http://192.168.6.61)    | qBittorent                                                 | 1                 |
| 192.168   | 6.0/25   | [6.71](http://192.168.6.71)    | qBittorent listen                                          | 1                 |
| 192.168   | 6.0/25   | [6.62](http://192.168.6.62)    | Radarr                                                     | 1                 |
| 192.168   | 6.0/25   | [6.63](http://192.168.6.63)    | Sonarr                                                     | 1                 |
| 192.168   | 6.0/25   | [6.64](http://192.168.6.64)    | Bazarr                                                     | 1                 |
| 192.168   | 6.0/25   | [6.65](http://192.168.6.65)    | Kubernetes Dashboard                                       | 1                 |
| 192.168   | 6.0/25   | [6.66](http://192.168.6.66)    | Grafana                                                    | 1                 |
| 192.168   | 6.0/25   | [6.77](http://192.168.6.77)    | Log server                                                 | 1                 |
| 192.168   | 6.0/25   | [6.88](http://192.168.6.88)    | Tekton server                                              | 1                 |
| 192.168   | 6.0/25   | [6.90](http://192.168.6.90)    | Consul LAN DNS (DNS UDP)                                   | 1                 |
| 192.168   | 6.0/25   | [6.91](http://192.168.6.91)    | Consul LAN DNS (Admin UI backup)                           | 1                 |
| 192.168   | 6.0/25   | [6.99](http://192.168.6.99)    | DNS Blackhole (pihole)                                     | 1                 |
| 192.168   | 6.128/25 |                                | Online Kubernetes MetalLB services                         | 1                 |
| 192.168   | 6.128/25 | [6.128](http://192.168.6.128)  | Online Traefik 2.x                                         | 1                 |
| 10.244    | 0.0/16   |                                | Kubernetes internal cidr                                   | kubernetes.local  |
| 10.8      | 2.0/24   |                                | Shared VPN access                                          | openvpn shared    |
| 10.8      | 2.0/24   | [2.1](http://10.8.2.1)         | Shared VPN server                                          | openvpn shared    |
| 10.8      | 4.0/24   |                                | Private VPN access                                         | openvpn private   |
| 10.8      | 4.0/24   | [4.1](http://10.8.4.0)         | Private VPN server                                         | openvpn private   |

### Technical Layer
> **TODO: Update diagram with new hardware**

The Technical Layer is structured as follows: 

![](/images/la1r-diagrams-Network%20Arch%20-%20Technical%20Layer.png)


### Network with WeaveWorks
Initially the decision was made to use flannel as network provider, since this is a pretty standard choice for many k8s implementations. Unfortunately this gave several networking, performance and upgrading issues over time, especially with our multi cpu architecture environment. After a tool selection process weave works came out best because:

* Substantial performance and stability improvements
* Capable of complex network segregation which flannel was not able to do
* Easy to setup, even if several sources on the way point out the opposite
* Bonus: Weave works supplies a fancy and comprehensive dashboard of your entire network

### Data Layer
The Data Layer is structured as follows:

![](/images/la1r-diagrams-Network%20Arch%20-%20Data%20Layer.png)
