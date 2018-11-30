# Place your kubernetes config file here:
* config

This can be copied from ```/etc/kubernetes/admin.conf```
or use ```make fetch``` to fetch them from your admin kubernetes instance

# Place join-token.yaml with the following structure:
```yaml
---
k8s_master_ip: "ip address"
k8s_join_token: "your token"
```