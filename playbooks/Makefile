all: prep docker

#Based on: https://github.com/ramontayag/rpi-playbooks

### Init Setup

.PHONY: ssh-copy-key
ssh-copy-key:
	mkdir -p ~/.ssh 
	cp /credentials/ssh/id_rsa ~/.ssh/id_rsa
	chmod 600 ~/.ssh/id_rsa
	
.PHONY: ssh-set
ssh-set:
	ANSIBLE_HOST_KEY_CHECKING=False \
	ansible-playbook -i /playbooks/hosts /playbooks/roles/common/tasks/create-user.yml --ask-pass --ask-become-pass
	ansible-playbook -i /playbooks/hosts /playbooks/roles/common/tasks/remove-pi-user.yml 

.PHONY: prep
prep: ssh-copy-key ssh-set


### Docker

.PHONY: docker
docker: 
	ansible-playbook -i /playbooks/hosts /playbooks/roles/docker/tasks/main.yml 



### No-IP

.PHONY: no-ip
no-ip:
	ansible-playbook /playbooks/noip.yml -i /playbooks/hosts --extra-vars="noip_username=someusername noip_password=somepassword"