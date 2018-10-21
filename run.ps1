docker rm -f ansible-client
docker build ./ansible-client -t ansible-client
docker run -it --rm --name ansible-client --hostname ansible-client \
    -v $pwd/playbooks/:/playbooks \
    -v $pwd/kubernetes/:/kubernetes \
    -v $pwd/credentials:/credentials \
    ansible-client /bin/bash
