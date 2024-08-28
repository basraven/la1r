# Sops PGP
Before installing, run this:
```bash
cp ~/.ssh/id_rsa ./id_rsa
flux create secret git flux-pgp-secret \
    --url=ssh://git@github.com/basraven/la1r-cred \
    --private-key-file=./id_rsa
rm ./id_rsa
```