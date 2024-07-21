---
title: Network Architecture
type: docs
weight: 1
bookCollapseSection : false
---

## Network topology high-level
{{< mermaid class="optional" >}}
graph TD;
    Internet --> Router;
    Router --> LoadBalancer;
    
    subgraph LAN[LAN]
        LoadBalancer --> S1;
        LoadBalancer --> S3;
        S1 -->|NFS + rsync| S4;
        S3 -->|NFS + rsync| S4;
        S1 -->|API Call| S2;
        S3 -->|API Call| S2;
        
        LoadBalancer["Virtual Load Balancer (MetalLB) <br>IP: 192.168.5.100"];
        S1["linux-wayne <br>primary     <br>always-on   <br>IP: 192.168.5.1 <br>OS: Ubuntu 23.04    <br>Ryzen 5600x   <br> 16GB RAM, 500GB SSD"];
        S3["jay-c       <br>secondary   <br>on-demand   <br>IP: 192.168.5.3 <br>OS: Ubuntu 23.04    <br>Intel Core i5 <br> 32GB RAM, 500GB NMVE"];
        S2["stephanie   <br>IOT-orch    <br>on-demand   <br>IP: 192.168.5.3 <br>OS: Ubuntu 23.04    <br>Raspberry Pi 4 Model B Rev 1.4 <br> 8GB RAM, 256GB SSD"];
        S4["remote-cube <br>backup      <br>on-demand   <br>IP: 10.8.0.?    <br>OS: Ubuntu 23.04    <br>Raspberry Pi 3 Model B <br> 4GB RAM, 500GB NMVE"];
    end;
{{< /mermaid >}}


## Network topology table
The following table summarizes all network cidrs and addresses

| Prefix    | CIDR     | IP                            | Ports           | Target                                                     | vlan              |
| ---       | ---      | ---                           | ---             | ---                                                        | ---               |
| 192.168   | 1.0/24   |                               |                 | Empty, not used, will indicate wrongly configured devices  | -                 |
| 192.168   | 2.0/24   |                               |                 | Common devices, laptops, phones, etc.                      | 1                 |
| 192.168   | 3.0/24   |                               |                 | IOT Devices with dedicated connection to server            | 1                 |
| 192.168   | 4.0/24   |                               |                 | Network infrastructure, switches, routers, etc             | 1                 |
| 192.168   | 4.0/24   | [4.1](http://192.168.4.1)     | 80, 443, 67     | Router and DHCP Server                                     | 1                 |
| 192.168   | 4.0/24   | [4.2](http://192.168.4.2)     | 80, 443, 67     | Central network switch                                     | 1                 |
| 192.168   | 4.0/24   | [4.3](http://192.168.4.3)     | 80, 443, 67     | Access Point living room                                   | 1                 |
| 192.168   | 4.0/24   | [4.4](http://192.168.4.4)     | 80, 443, 67     | Access Point office                                        | 1                 |
| 192.168   | 5.0/20   |                               |                 | Servers                                                    | 1                 |
| 192.168   | 5.0/20   | [5.1](http://192.168.5.1)     |                 | linux-wayne                                                | 1                 |
| 192.168   | 5.0/20   | [5.2](http://192.168.5.2)     |                 | 50centos                                                   | 1                 |
| 192.168   | 5.0/20   | [5.3](http://192.168.5.3)     |                 | jay-c                                                      | 1                 |
| 192.168   | 5.0/20   | [5.100](http://192.168.5.100) | 80, 443         | haproxy VIP entrypoint Kubernetes                          | 1                 |
| 192.168   | 6.0/24   |                               |                 | Kubernetes MetalLB services                                | 1                 |
| 192.168   | 6.0/25   |                               |                 | LAN Kubernetes MetalLB services                            | 1                 |
| 192.168   | 6.0/25   | [6.1](http://192.168.6.1)     | 80, 443         | LAN Traefik 2.x                                            | 1                 |
| 192.168   | 6.0/25   | [6.60](http://192.168.6.60)   | 80, 443, 32400  | Plex server                                                | 1                 |
| 192.168   | 6.0/25   | [6.61](http://192.168.6.61)   | 80, 443         | qBittorent                                                 | 1                 |
| 192.168   | 6.0/25   | [6.71](http://192.168.6.71)   | 80, 443         | qBittorent listen                                          | 1                 |
| 192.168   | 6.0/25   | [6.62](http://192.168.6.62)   | 80, 443         | Radarr                                                     | 1                 |
| 192.168   | 6.0/25   | [6.63](http://192.168.6.63)   | 80, 443         | Sonarr                                                     | 1                 |
| 192.168   | 6.0/25   | [6.64](http://192.168.6.64)   | 80, 443         | Bazarr                                                     | 1                 |
| 192.168   | 6.0/25   | [6.65](http://192.168.6.65)   | 443             | Kubernetes Dashboard                                       | 1                 |
| 192.168   | 6.0/25   | [6.66](http://192.168.6.66)   | 80, 443, 9093   | Alert Manager                                              | 1                 |
| 192.168   | 6.0/25   | [6.66](http://192.168.6.68)   | 80, 443         | Grafana                                                    | 1                 |
| 192.168   | 6.0/25   | [6.77](http://192.168.6.77)   | 514/udp         | Log server                                                 | 1                 |
| 192.168   | 6.0/25   | [6.88](http://192.168.6.88)   | 80, 443         | Tekton server                                              | 1                 |
| 192.168   | 6.0/25   | [6.90](http://192.168.6.90)   | 53/udp          | Consul LAN DNS (DNS UDP)                                   | 1                 |
| 192.168   | 6.0/25   | [6.91](http://192.168.6.91)   | 80, 443         | Consul LAN DNS (Admin UI backup)                           | 1                 |
| 192.168   | 6.0/25   | [6.99](http://192.168.6.99)   | 80, 443, 53/udp | DNS Blackhole (pihole)                                     | 1                 |
| 192.168   | 6.128/25 |                               |                 | Online Kubernetes MetalLB services                         | 1                 |
| 192.168   | 6.128/25 | [6.128](http://192.168.6.128) | 80, 443         | Online Traefik 2.x                                         | 1                 |
| 10.244    | 0.0/16   |                               |                 | Kubernetes internal cidr                                   | kubernetes.local  |
| 10.8      | 2.0/24   |                               |                 | Shared VPN access                                          | openvpn shared    |
| 10.8      | 2.0/24   | [2.1](http://10.8.2.1)        | 33443, 33555    | Shared VPN server                                          | openvpn shared    |
| 10.8      | 4.0/24   |                               |                 | Private VPN access                                         | openvpn private   |
| 10.8      | 4.0/24   | [4.1](http://10.8.4.0)        | 33443, 33555    | Private VPN server                                         | openvpn private   |

