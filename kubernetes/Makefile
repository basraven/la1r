.PHONY: all
all: network-overlay dashboard config faas traefik

.PHONY: local
local: dashboard nextcloud

# Prefix all commands with - to ignore errors (already exists errors)

.PHONY: network-overlay
network-overlay:
	# - curl -sSL https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml | sed "s/amd64/arm/g" | kubectl create -f -  && exit 0
	kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml
	
.PHONY: dashboard
dashboard:
	# - curl -sSL https://raw.githubusercontent.com/kubernetes/dashboard/master/src/deploy/recommended/kubernetes-dashboard.yaml | sed "s/amd64/arm/g" | kubectl create -f -
	# kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/master/src/deploy/recommended/kubernetes-dashboard.yaml
	kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v1.10.1/src/deploy/recommended/kubernetes-dashboard.yaml

	- kubectl create serviceaccount cluster-admin-dashboard-sa
	- kubectl create clusterrolebinding cluster-admin-dashboard-sa --clusterrole=cluster-admin --serviceaccount=default:cluster-admin-dashboard-sa

.PHONY: config 
config: 
	- kubectl taint nodes big-raver node-role.kubernetes.io/master-
	- kubectl taint nodes raspi1 pi=true:NoSchedule
	- kubectl taint nodes raspi2 pi=true:NoSchedule
	- kubectl label nodes big-raver disktype=hdd
	- kubectl label nodes raspi1 disktype=hdd
	- kubectl label nodes raspi2 disktype=hdd

.PHONY: faas
faas:
	- kubectl apply -f https://raw.githubusercontent.com/openfaas/faas-netes/master/namespaces.yml
	- git clone https://github.com/openfaas/faas-netes /tmp/faas-netes
	- kubectl apply -f /tmp/faas-netes/yaml_armhf
	- rm -rf /tmp/faas-netes

.PHONY: traefik
traefik:
	- kubectl apply -f https://raw.githubusercontent.com/containous/traefik/master/examples/k8s/traefik-rbac.yaml
	- kubectl apply -f https://raw.githubusercontent.com/containous/traefik/master/examples/k8s/traefik-ds.yaml
	- kubectl apply -f https://raw.githubusercontent.com/containous/traefik/master/examples/k8s/ui.yaml

.PHONY: nextcloud
nextcloud:
	- kubectl apply -f nextcloud/namespace.yaml
	- kubectl create configmap mycnf --namespace nextcloud --from-file=nextcloud/config/my.cnf
	- kubectl create configmap set-nextcloud --namespace nextcloud --from-file=nextcloud/config/set-nextcloud.sh
	- kubectl apply -f nextcloud/dbsecret.yaml
	- kubectl apply -f nextcloud/mariadb-pv.yaml
	- kubectl apply -f nextcloud/mariadb.yaml
	- kubectl apply -f nextcloud/nextcloud-pv.yaml
	- kubectl apply -f nextcloud/nextcloud.yaml
	
	# FOR SSL
	# - openssl req -newkey rsa:2048 -nodes -CA /credentials/nextcloud/rootCA.crt -CAkey /credentials/nextcloud/rootCA.key -CAcreateserial -keyout /credentials/nextcloud/tls.key -x509 -days 365 -out /credentials/nextcloud/tls.crt
	- openssl genrsa -out /credentials/nextcloud/cloud.bas.key 2048
	- openssl req -new -sha256 -key /credentials/nextcloud/cloud.bas.key -subj "/C=NL/ST=NH/O=basraven.nl/CN=cloud.bas/subjectAltName=DNS.1=cloud.bas/" -out /credentials/nextcloud/cloud.bas.csr
	- openssl x509 -req -in /credentials/nextcloud/cloud.bas.csr -CA /credentials/nextcloud/rootCA.crt -CAkey /credentials/nextcloud/rootCA.key -CAcreateserial -out /credentials/nextcloud/cloud.bas.crt -days 500 -sha256
	- kubectl create secret generic traefik-cert --namespace kube-system --from-file=/credentials/nextcloud/cloud.bas.crt --from-file=/credentials/nextcloud/cloud.bas.key
	- kubectl create configmap traefik-conf --namespace kube-system --from-file=/kubernetes/nextcloud/config/traefik.toml
	- 
