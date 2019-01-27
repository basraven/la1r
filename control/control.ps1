docker rm -f control
docker build ./control -t control
docker run -it --rm --name control --hostname control -v $pwd/playbooks/:/playbooks -v $pwd/kubernetes/:/kubernetes -v $pwd/credentials:/credentials control /bin/bash
