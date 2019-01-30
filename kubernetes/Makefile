.PHONY: all
all: network-overlay dashboard config faas traefik

.PHONY: local
local: dashboard nextcloud

# Prefix all commands with - to ignore errors (already exists errors)

.PHONY: network-overlay
network-overlay:
	# - curl -sSL https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml | sed "s/amd64/arm/g" | kubectl create -f -  && exit 0
	- kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml
	
.PHONY: dashboard
dashboard:
	# - curl -sSL https://raw.githubusercontent.com/kubernetes/dashboard/master/src/deploy/recommended/kubernetes-dashboard.yaml | sed "s/amd64/arm/g" | kubectl create -f -
	- kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v1.10.1/src/deploy/recommended/kubernetes-dashboard.yaml

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
	- kubectl label node raspi1 node-role.kubernetes.io/worker=worker
	- kubectl label node raspi2 node-role.kubernetes.io/worker=worker


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
	- kubectl create configmap apcu-config --namespace nextcloud --from-file=nextcloud/config/apcu.config.php
	- kubectl apply -f nextcloud/dbsecret.yaml
	- kubectl apply -f nextcloud/mariadb-pv.yaml
	- kubectl apply -f nextcloud/mariadb.yaml
	- kubectl apply -f nextcloud/nextcloud-pv.yaml
	- kubectl apply -f nextcloud/nextcloud.yaml

.PHONY: helm
helm:
	- kubectl apply -f namespaces/tiller.yaml
	- kubectl create serviceaccount --namespace tiller tiller
	- kubectl create clusterrolebinding tiller-cluster-rule --clusterrole=cluster-admin --serviceaccount=tiller:tiller
	- kubectl patch deploy --namespace tiller tiller-deploy -p'{"spec":{"template":{"spec":{"serviceAccount":"tiller"}}}}'
	- rm -rf /root/.helm
	- helm init --tiller-namespace tiller
	

.PHONY: qbittorrent
qbittorrent:
	- kubectl create secret generic goose-credentials --namespace torrent --from-file=/credentials/ovpn/login.conf --from-file=/credentials/ovpn/ro-10.conf
	- kubectl create configmap qbittorrent-config --namespace torrent --from-file=torrent/qbittorrent/config/set-goose.sh
	- kubectl apply -f qbittorrent


# Refresh claimToken from https://www.plex.tv/claim/
.PHONY: plex
plex:
	cp -rf torrent/plex/kube-plex-custom/* torrent/plex/kube-plex
	- kubectl apply -f torrent/plex/plex-pv.yaml
	- kubectl apply -f torrent/plex/plex-pv-claim.yaml
	- kubectl apply -f torrent/plex/plex-local-service.yaml
	- helm install torrent/plex/kube-plex/charts/kube-plex --name plex \
    	--namespace torrent \
		--tiller-namespace tiller \
		--set claimToken="claim-sTt6yYA3wK94sjXezbaJ" \
    	--set ingress.enabled=true
	# To delete:
	# helm del --purge plex --tiller-namespace tiller
	# kubectl delete -f /kubernetes/plex/plex-pv.yaml
.PHONY: unplex
unplex:
	helm del --purge plex --tiller-namespace tiller
	kubectl delete -f torrent/plex/plex-pv-claim.yaml
	kubectl delete -f torrent/plex/plex-pv.yaml


# TODO: replace heapster with metrics-server
.PHONY: dashboard-metrics
dashboard-metrics:
	- kubectl apply -f maintenance/heapster/heapster.yaml

.PHONY: prometheus
prometheus:
	cp -rf helm/helm-custom/stable/prometheus-operator/* helm/helm/stable/prometheus-operator/
	helm install stable/prometheus-operator --tiller-namespace tiller --name prometheus-operator --namespace maintenance

.PHONY: unprometheus
unprometheus:
	helm del --purge prometheus-operator --tiller-namespace tiller

.PHONY: ssl-certs
ssl-certs:
	# FIXME: doesn't accept the CA: Create CA
	openssl genrsa -des3 -out ravenCA.key 2048
	openssl req -x509 -new -nodes -key ravenCA.key -sha256 -days 1825 -out ravenCA.pem
	
	# Create crt (works)
	/bin/bash /credentials/nextcloud/make-cert.sh cloud.bas && mv ./cloud.bas.cert.pem /credentials/nextcloud/cloud.bas.crt && mv ./cloud.bas.key.pem /credentials/nextcloud/cloud.bas.key
	kubectl create secret generic traefik-cert --namespace kube-system --from-file=/credentials/nextcloud/cloud.bas.crt --from-file=/credentials/nextcloud/cloud.bas.key