# Place samba-credentials.yaml with the following structure:
(these users should be known in linux!)
```yaml
---
samba_users:
    - { name: 'username',          passwd: 'password' }
```