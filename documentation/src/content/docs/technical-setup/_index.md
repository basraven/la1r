---
title: Technical Setup
type: docs
bookToc: false
weight: 3
---
# How it's made
The technical setup of La1r is my personal take on how to properly implement the conceptual setup as described on this site. This does not mean that all implementations are matching the infrastructure context, on the contrary. Implementations in La1r are aimed on enterprise scale setups, which often make them an overkill for the hardware it is running. 
The reason for this is that the technical setup tries to comply to several application architecture principles which are focussed on maximizing my personal learning experiences and are often near enterprise scale. 


## Application architecture principles
1. Only the paranoid survive, apply and practice backup scenarios. - Backup scenarios should not only be implemented as tick in the box for our list of non functional requirements (nfrs), but should also be practiced where possible. 
1. Aim for near horizontal scaling - all services should be able to scale with cluster size. The infrastructure architecture of my current implementation is rather rigid, but the applications on it should be aimed on flexible and horizontally scalable underlying infrastructure. 
1. Decentralized application paradigms where possible - To support the horizontal scaling capabilities, an effort should be made to apply decentralized paradigms, which often improve scalability and availability when implemented correctly. 
1. Don't assume information share - since an enterprise environment is conceptually simulated, it should also be simulated that (conceptual) teams are not fully aware of all integrations made by other (conceptual) teams. The implications of this is that there is a need for decoupling and formal informations definitions. An example of this is the site you're currently reading, but further efforts should be made such as formal separation of layers, environments and data to appropriately conform to this conceptual requirement. 
1. Behind the VPN (openvpn) by default - since this is still a learning and experimental environment, I don't want to think about security first, every step of the way. This is why the master La1r server hosts a VPN virtual network. All services and internal dns are using that entrypoint by default. This does not mean that nothing is exposed to the outside world, but only the services explicitly exposed through the online-traefik instance are