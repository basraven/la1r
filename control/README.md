# Control Jumphost - centos latest
This folder contains the source for the control jumphost.
It is a centos latest docker-based abstract jumphost used to manage la1r.com and other projects.
It contains [multiple kubectl aliases](kubectl_aliases.sh) and has more nivty features which can be used for Kubernetes management.

## Components
* [kubectl_aliases.sh](kubectl_aliases.sh) - Aliases used for shutcutting commands
* [entrypoint.sh](entrypoint.sh) - loads the aliases and /credentials folder with ssh keys, also adds bash completion
* [Dockerfile](Dockerfile) - The dockerfile with the contents of the jumphost