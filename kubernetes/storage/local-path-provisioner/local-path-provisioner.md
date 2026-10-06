# Local Path Provisioner

Dynamically provisions local (host-path) PersistentVolumes for the cluster's
storage classes.

Current version: **v0.0.37** (upgraded from v0.0.20).
v0.0.20 was vulnerable to **CVE-2025-62878** (path traversal, GHSA-jr3w-9vfr-c746;
fixed in v0.0.34). All four provisioner Deployments were bumped to v0.0.37.

## Storage classes
| StorageClass | Host path | Reclaim |
|---|---|---|
| `ssd-ha` | `/mnt/ssd/ha` | Retain |
| `ssd-na` | `/mnt/ssd/na` | Delete |
| `hdd-ha` | `/mnt/hdd/ha` | Retain |
| `hdd-na` | `/mnt/hdd/na` | Delete |

Each is a small Deployment in `local-path-storage` with its own
`config.json` (node → path map) and optional setup/teardown/helperPod scripts.

## Prerequisite
Before the provisioner is first deployed, the node-labels helper must have run:
```
# see kubernetes/storage/node-labels/node-labels.sh
```
It labels the nodes so volumes land on the correct hosts.

## Apply
```
kubectl apply -k kubernetes/storage/local-path-provisioner/
```

## Verify a class works
Create a PVC + consumer Pod on the target storage class and confirm it binds
(write a probe file).