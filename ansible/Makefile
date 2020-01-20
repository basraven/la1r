 
#Based on: https://github.com/ramontayag/rpi-playbooks
export ANSIBLE_HOST_KEY_CHECKING = False

# First install python by hand for ansible to work...

PHONY: build-ubuntu
build-master: security-ubuntu docker k8s-install-ubuntu  

PHONY: install-ubuntu
install-ubuntu: user-ubuntu

.PHONY: build-master
build-master: security-raspberry docker k8s-install k8s-init k8s-fetch k8s-load no-ip ovpn-install nfs-client

.PHONY: build-slave
build-slave: security-raspberry docker k8s-install ovpn-join k8s-join nfs-server


##### Init Setup #####
.PHONY: user-raspberry
user-raspberry:
	ansible-playbook -i /playbooks/hosts /playbooks/roles/common/tasks/create-user-raspberry.yml --ask-pass


.PHONY: user-ubuntu
user-ubuntu:
	ansible-playbook -i /playbooks/hosts /playbooks/roles/common/tasks/create-user-ubuntu.yml --ask-pass --ask-sudo-pass
	
.PHONY: security-raspberry
security-raspberry:
	ansible-playbook -i /playbooks/hosts /playbooks/roles/common/tasks/security-raspberry.yml

.PHONY: security-ubuntu
security-ubuntu:
	ansible-playbook -i /playbooks/hosts /playbooks/roles/common/tasks/security-ubuntu.yml
	
.PHONY: ssh-clean
ssh-clean:
	ansible-playbook -i /playbooks/hosts /playbooks/roles/common/tasks/remove-pi-user.yml 



##### NFS #####
.PHONY: nfs-server
nfs-server:
	ansible-playbook -i /playbooks/hosts /playbooks/roles/nfs/tasks/create-backup-user.yml
	ansible-playbook -i /playbooks/hosts /playbooks/roles/nfs/tasks/nfs-server.yml

.PHONY: nfs-client
nfs-client:
	ansible-playbook -i /playbooks/hosts /playbooks/roles/nfs/tasks/create-backup-user.yml
	ansible-playbook -i /playbooks/hosts /playbooks/roles/nfs/tasks/nfs-client.yml

##### Samba #####
.PHONY: samba-server
samba-server:
	ansible-playbook -i /playbooks/hosts /playbooks/roles/samba/tasks/samba-server.yml

##### Docker #####
.PHONY: docker-install
docker-install: 
	ansible-playbook -i /playbooks/hosts /playbooks/roles/docker/tasks/main.yml 


##### K8S Setup #####
.PHONY: k8s-install-ubuntu
k8s-install-ubuntu: 
	ansible-playbook -i /playbooks/hosts /playbooks/roles/k8s/tasks/install-ubuntu.yml

.PHONY: k8s-install-raspberry
k8s-install-raspberry: 
	ansible-playbook -i /playbooks/hosts /playbooks/roles/k8s/tasks/install-raspberry.yml

.PHONY: k8s-init
k8s-init: 
	ansible-playbook -i /playbooks/hosts /playbooks/roles/k8s/tasks/init.yml

.PHONY: k8s-join
k8s-join:
	ansible-playbook -i /playbooks/hosts /playbooks/roles/k8s/tasks/join.yml


##### K8S config #####
.PHONY: k8s-fetch
k8s-fetch: 
	rm -f ~/.kube/config
	ansible-playbook -i /playbooks/hosts /playbooks/roles/k8s/tasks/fetch.yml

.PHONY: k8s-load
k8s-load:
	@$(MAKE) -C /kubernetes all 



##### No-IP #####
.PHONY: no-ip
no-ip:
	ansible-playbook -i /playbooks/hosts /playbooks/roles/noip/tasks/main.yml

##### No-IP #####
.PHONY: dnsmasq
dnsmasq:
	ansible-playbook -i /playbooks/hosts /playbooks/roles/dnsmasq/tasks/install.yml


##### OVPN #####
.PHONY: ovpn-install
ovpn-install: 
	ansible-playbook -i /playbooks/hosts /playbooks/roles/ovpn/tasks/install.yml
	ansible-playbook -i /playbooks/hosts /playbooks/roles/ovpn/tasks/create-user.yml --extra-vars "openvpn_user=basraven"

.PHONY: ovpn-create-user
ovpn-create-user: 
	ansible-playbook -i /playbooks/hosts /playbooks/roles/ovpn/tasks/create-user.yml --extra-vars "openvpn_user=basraven"

.PHONY: ovpn-join
ovpn-join:
	ansible-playbook -i /playbooks/hosts /playbooks/roles/ovpn/tasks/join.yml

.PHONY: test
test: 
	ansible-playbook -i /playbooks/local /playbooks/roles/test/test.yml 

#Node Exporter
.PHONY: node-exporter
node-exporter: 
	ansible-playbook -i /playbooks/hosts /playbooks/roles/prometheus_node_exporter/tasks/node-exporter.yml


#Iptables
.PHONY: ip-backup
ip-backup: 
	ansible-playbook -i /playbooks/hosts /playbooks/roles/iptables/tasks/iptables-backup.yml

.PHONY: ip-restore
ip-restore: 
	ansible-playbook -i /playbooks/hosts /playbooks/roles/iptables/tasks/iptables-restore.yml

.PHONY: ip-forward
ip-forward: 
	ansible-playbook -i /playbooks/hosts /playbooks/roles/iptables/tasks/iptables-forward.yml --extra-vars "from=80 to=31000"
