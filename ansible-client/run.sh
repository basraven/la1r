docker network create --driver bridge ansible-testnet
docker rm -f ansible-control
docker build . -t ansible-control
docker run -it --name ansible-control -v $pwd/../playbooks/:/playbooks -v $pwd/../hosts:/etc/ansible/hosts --net ansible-testnet ansible-control /bin/bash
