 
#Based on: https://github.com/ramontayag/rpi-playbooks
export ANSIBLE_HOST_KEY_CHECKING = False
all: prep create-user all-steps
install: prep all-steps
all-steps: docker k8s-install k8s-fetch k8s-load no-ip ovpn

##### Init Setup #####
.PHONY: prep
prep:
	mkdir -p ~/.ssh 
	cp /credentials/ssh/id_rsa ~/.ssh/id_rsa
	chmod 600 ~/.ssh/id_rsa
	
.PHONY: create-user
create-user:
	ansible-playbook -i /playbooks/hosts /playbooks/roles/common/tasks/create-user.yml --ask-pass
	
.PHONY: ssh-clean
ssh-clean:
	ansible-playbook -i /playbooks/hosts /playbooks/roles/common/tasks/remove-pi-user.yml 



##### Docker #####
.PHONY: docker
docker: 
	ansible-playbook -i /playbooks/hosts /playbooks/roles/docker/tasks/main.yml 


##### K8s #####
.PHONY: k8s-install
k8s-install: 
	ansible-playbook -i /playbooks/hosts /playbooks/roles/k8s/tasks/install.yml

.PHONY: k8s-fetch
k8s-fetch: 
	ansible-playbook -i /playbooks/hosts /playbooks/roles/k8s/tasks/fetch.yml

.PHONY: k8s-load
k8s-load:
	@$(MAKE) -C /kubernetes all 

k8s-token:
	kubectl get secret | grep cluster-admin-dashboard-sa | cut -d " " -f 1 | kubectl describe secret $1


##### No-IP #####
.PHONY: no-ip
no-ip:
	ansible-playbook -i /playbooks/hosts /playbooks/roles/noip/tasks/main.yml


##### OVPN #####
.PHONY: ovpn
ovpn: prep
	ansible-playbook -i /playbooks/hosts /playbooks/roles/ovpn/tasks/install.yml
	ansible-playbook -i /playbooks/hosts /playbooks/roles/ovpn/tasks/create-user.yml --extra-vars "openvpn_user=basraven"

.PHONY: ovpn-create-user
ovpn-create-user: prep
	ansible-playbook -i /playbooks/hosts /playbooks/roles/ovpn/tasks/create-user.yml --extra-vars "openvpn_user=basraven"

.PHONY: test
test: prep
	ansible-playbook -i /playbooks/local /playbooks/roles/test/test.yml 
