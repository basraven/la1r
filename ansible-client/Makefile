.PHONY: ssh-copy
ssh-copy:
	mkdir -p ~/.ssh 
	cp /credentials/ssh/id_rsa ~/.ssh/id_rsa
	chmod 600 ~/.ssh/id_rsa
	
.PHONY: ssh-set
ssh-set:
	ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -i /playbooks/raspberry /playbooks/common/change-default-ssh.yml

.PHONY: ssh-init
ssh-init: ssh-copy ssh-set
