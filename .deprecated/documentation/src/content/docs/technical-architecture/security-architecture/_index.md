---
bookToc: true
bookCollapseSection : true
---
## Security Architecture
Several security concepts are applied in the implementation, this page highlights a few.

### Ansible Secret Vault
Since sensitive data objects such as secrets, certificates and password need to be stored somewhere, and since that location is not my awful memory (I'm prone to memory leaks for some reason which are apparently still impossible to solve) I need a way to store this information.
An option could be an Ansible secret vault, but since I'm not a madman who loves tempting others with putting their encrypted castle keys on git and that doesn't feel future-proof to me, "stay quantum save kids!" I took a very low level approach:

On each git clone on machines I need to use, I also store a /credentials folder which stores all credentials needed for my cluster.
I know it's not save either, and I should for sure pgp encrypt that stuff, it still feels more safe than the carrot-stick approach.


### Kerberos
Kerberos v5 (MIT) is used for securing all NFS Shares. The settings for this is as follows:

| Attribute | Value |
| ---       | ---   |
| Kerberos server | kerberos.la1r.com |
| realm | la1r.com |
| admin principal | admin/admin |
| client principal | <hostname> e.g. 50centos |