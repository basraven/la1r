---
bookToc: false
bookCollapseSection : false
---
## Storage Architecture
Storage architecture can be a complicated topic when working with (Bare Metal) Kubernetes clusters.
There are a lot of War stories of organizations unable to restore their storage solution, e.g. in a complex RAID setup on in a distributed storage solutions such as Ceph, GlusterFS or StorageOS.

It took a significant amount of time to weigh the pros and cons of these solutions, but eventually I went for the "safest" solution, at least a solution which could not produce unrestoreable storage solutions as mentioned before:

* Dynamically provisioned NFS storage in Kubernetes

### Storage Tiers
A few predefined folder structures are used in this setup, each folder to simulate To simulate the behavior of more complex storage solutions:

| **B**ackup | **V**olatility | **S**peed |
| ---        | ---            | ---       |
| - 1: Backed-up (**H**igh **A**vailability) <br/> - 2: Not Backed-up (**N**ormal **A**vailability)      | - 1: Persistent, retained indefinite <br/> - 2: Volatile, removed after 2 weeks | - 1: High speed SSD storage <br/> - 2: Normal speed HDD Storage <br/> - 3: Slower speed HDD storage |

#### Generic Instances

| Class Code | Implemented server(s) | **B**ackup | **V**olatility | **S**peed | Hostpath                          | Reclaim   |
| ---        | ---                   | ---        | ---            | ---       | ---                               | ---       |
| 111        | 1: linux-wayne        | 1          | 1              | 1         | /mnt/ssd/ha/<service_name>        | manual    |
| 211        | 1: linux-wayne        | 2          | 1              | 1         | /mnt/ssd/na/<service_name>        | automatic |
| 221        | 1: linux-wayne        | 2          | 2              | 1         | /mnt/ssd/tmp/<service_name>       | automatic |
| 112        | 1: linux-wayne        | 1          | 1              | 2         | /mnt/hdd/ha/<service_name>        | manual    |
| 212        | 1: linux-wayne        | 2          | 1              | 2         | /mnt/hdd/na/<service_name>        | automatic |
| 222        | 1: linux-wayne        | 2          | 2              | 2         | /mnt/hdd/tmp/<service_name>       | automatic |
| 113        | 2: 50centos           | 1          | 1              | 3         | /mnt/slhdd/ha/<service_name>      | manual    |
| 213        | 2: 50centos           | 2          | 1              | 3         | /mnt/slhdd/na/<service_name>      | automatic |
| 223        | 2: 50centos           | 2          | 2              | 3         | /mnt/slhdd/tmp/<service_name>     | automatic |

#### Specific Instances

| Class Code | Implemented server(s) | **B**ackup | **V**olatility | **S**peed | Persistent Volume (PV) name    | Hostpath                          |
| ---        | ---                   | ---        | ---            | ---       | ---                            | ---                               |
| 211        | 1: linux-wayne        | 2          | 1              | 1         | nextcloud-config               | /mnt/ssd/ha/nextcloud/config/     |
| 212        | 1: linux-wayne        | 2          | 1              | 2         | nextcloud-data                 | /mnt/hdd/ha/nextcloud/data/       |
