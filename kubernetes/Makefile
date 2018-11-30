.PHONY: all
all: network-overlay dashboard config faas traefik

.PHONY: local
local: dashboard nextcloud

# Prefix all commands with - to ignore errors (already exists errors)

.PHONY: network-overlay
network-overlay:
	- curl -sSL https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml | sed "s/amd64/arm/g" | kubectl create -f -  && exit 0
	# kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml
	
.PHONY: dashboard
dashboard:
	- curl -sSL https://raw.githubusercontent.com/kubernetes/dashboard/master/src/deploy/recommended/kubernetes-dashboard.yaml | sed "s/amd64/arm/g" | kubectl create -f -
	# kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/master/src/deploy/recommended/kubernetes-dashboard.yaml

	- kubectl create serviceaccount cluster-admin-dashboard-sa
	- kubectl create clusterrolebinding cluster-admin-dashboard-sa --clusterrole=cluster-admin --serviceaccount=default:cluster-admin-dashboard-sa

.PHONY: config 
config: 
	- kubectl taint nodes --all node-role.kubernetes.io/master-

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
# 	- kubectl create configmap traefik-config -n kube-system --from-file=traefik/traefik.toml

.PHONY: nextcloud
nextcloud:
	- kubectl apply -f nextcloud/volume.yaml
	- kubectl apply -f nextcloud/deployment.yaml