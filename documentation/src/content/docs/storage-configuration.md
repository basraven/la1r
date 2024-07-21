---
bookToc: false
bookCollapseSection : false
weight: 5
---
## Storage Architecture
Maintaining state in Kubernetes can be complex. I'm using a local path provisioner after having tried many other options which did not match my low risk apatite for storage. The code [can be found here](https://github.com/basraven/la1r/tree/rick/todeploy-kubernetes/storage) [or here](https://github.com/basraven/la1r/tree/rick/kubernetes/storage) (post fluxcd migration).

### Storage Tiers
Each server has SSD and HDD storage. I created a predefined folder structures, each folder would answer to different storage requirements:

| **B**ackup | **V**olatility | **S**peed |
| ---        | ---            | ---       |
| - 1: Backed-up (**H**igh **A**vailability) <br/> - 2: Not Backed-up (**N**ormal **A**vailability)      | - 1: Persistent, retained indefinite <br/> - 2: Volatile, removed after 2 weeks | - 1: High speed SSD storage <br/> - 2: Normal speed HDD Storage <br/> - 3: Slower speed HDD storage |

#### Generic Instances

| Class Code    | Implemented server(s) | **B**ackup | **V**olatility | **S**peed | Hostpath                          | Reclaim   |
| ---           | ---                   | ---        | ---            | ---       | ---                               | ---       |
| 111           | 1: linux-wayne        | 1          | 1              | 1         | /mnt/ssd/ha/<service_name>        | manual    |
| 211           | 1: linux-wayne        | 2          | 1              | 1         | /mnt/ssd/na/<service_name>        | automatic |
| 221           | 1: linux-wayne        | 2          | 2              | 1         | /mnt/ssd/tmp/<service_name>       | automatic |
| 112           | 1: linux-wayne        | 1          | 1              | 2         | /mnt/hdd/ha/<service_name>        | manual    |
| 212 (default) | 1: linux-wayne        | 2          | 1              | 2         | /mnt/hdd/na/<service_name>        | automatic |
| 222           | 1: linux-wayne        | 2          | 2              | 2         | /mnt/hdd/tmp/<service_name>       | automatic |

#### Specific Instances
TODO: update

| Class Code | Implemented server(s) | **B**ackup | **V**olatility | **S**peed | Persistent Volume (PV) name    | Hostpath                          |
| ---        | ---                   | ---        | ---            | ---       | ---                            | ---                               |
| 211        | 1: linux-wayne        | 2          | 1              | 1         | nextcloud-config               | /mnt/ssd/ha/nextcloud/config/     |
| 212        | 1: linux-wayne        | 2          | 1              | 2         | nextcloud-data                 | /mnt/hdd/ha/nextcloud/data/       |
