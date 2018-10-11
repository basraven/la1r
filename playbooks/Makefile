 
export ANSIBLE_HOST_KEY_CHECKING = False
all: prep create-user docker kubernetes-slave no-ip

#Based on: https://github.com/ramontayag/rpi-playbooks

##### Init Setup #####
.PHONY: prep
prep:
	mkdir -p ~/.ssh 
	cp /credentials/ssh/id_rsa ~/.ssh/id_rsa
	chmod 600 ~/.ssh/id_rsa
	
.PHONY: create-user
create-user:
	ansible-playbook -i /playbooks/hosts /playbooks/roles/common/tasks/create-user.yml --ask-pass --ask-become-pass
	
.PHONY: ssh-clean
ssh-clean:
	ansible-playbook -i /playbooks/hosts /playbooks/roles/common/tasks/remove-pi-user.yml 



##### Docker #####
.PHONY: docker
docker: 
	ansible-playbook -i /playbooks/hosts /playbooks/roles/docker/tasks/main.yml 


##### K8s #####
.PHONY: k8s
k8s: 
	ansible-playbook -i /playbooks/hosts /playbooks/roles/k8s/tasks/main.yml 



##### No-IP #####
.PHONY: no-ip
no-ip:
	ansible-playbook /playbooks/noip.yml -i /playbooks/hosts --extra-vars="noip_username=someusername noip_password=somepassword"