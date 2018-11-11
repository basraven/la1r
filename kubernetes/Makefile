all: network-overlay dashboard config faas 

# Prefix all commands with - to ignore errors (already exists errors)

network-overlay:
	# curl -sSL https://rawgit.com/coreos/flannel/v0.9.1/Documentation/kube-flannel.yml | sed "s/amd64/arm/g" | kubectl create -f -
	- curl -sSL https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml | sed "s/amd64/arm/g" | kubectl create -f -  && exit 0
	
	# kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml
	# kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/k8s-manifests/kube-flannel-rbac.yml
	
dashboard:
	- curl -sSL https://raw.githubusercontent.com/kubernetes/dashboard/master/src/deploy/recommended/kubernetes-dashboard.yaml | sed "s/amd64/arm/g" | kubectl create -f -
	# kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/master/src/deploy/recommended/kubernetes-dashboard.yaml

	# Create service account
	- kubectl create serviceaccount cluster-admin-dashboard-sa
	- kubectl create clusterrolebinding cluster-admin-dashboard-sa --clusterrole=cluster-admin --serviceaccount=default:cluster-admin-dashboard-sa

config: 
	- kubectl taint nodes --all node-role.kubernetes.io/master-

faas:
	- git clone https://github.com/openfaas/faas-netes
	- kubectl apply -f https://raw.githubusercontent.com/openfaas/faas-netes/master/namespaces.yml
	- cd faas-netes && kubectl apply -f ./yaml_armhf
