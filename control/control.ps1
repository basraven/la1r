docker rm -f control
# docker rmi -f control
docker build ./control -t control
docker run -it --rm --name control --hostname control -v $pwd/cicd/ansible/:/ansible -v $pwd/cicd/ansible/config/ansible.cfg/:/etc/ansible/ansible.cfg -v $pwd/kubernetes/:/kubernetes -v $pwd/credentials:/credentials --entrypoint /control/entrypoint.sh control /bin/bash